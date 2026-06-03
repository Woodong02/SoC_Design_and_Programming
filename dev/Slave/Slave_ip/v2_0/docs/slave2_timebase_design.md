# `slave2_timebase` 설계 노트

## 목적

`slave2_timebase`는 Slave 2.0의 timing 기준을 한 곳에서 만든다. 실제 clock을 새로 생성하지 않고 `i_CLK` domain 안에서 Master broadcast preamble 검증 event인 `i_SYNC_PULSE`를 timing beacon으로 사용한다.

이 모듈은 RX sample tick, TX bit tick, slot phase, TX trigger, rate lock 상태를 생성한다. RX/TX leaf가 자체 `BIT_DIV` counter를 갖지 않도록 만드는 것이 작성 목적이다.

## 인터페이스

```verilog
module slave2_timebase (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [2:0]  i_NODE_ID,
    input  wire [2:0]  i_NODE_CNT,
    input  wire [9:0]  i_BIT_DIV_DEFAULT,
    input  wire [9:0]  i_GUARD_TICKS,
    input  wire        i_SYNC_PULSE,
    input  wire        i_RX_ACTIVE,
    input  wire        i_TX_ACTIVE,
    output wire        o_LOCKED,
    output wire [15:0] o_BIT_PERIOD_EST,
    output wire [2:0]  o_SLOT,
    output wire [15:0] o_SLOT_CLK_CNT,
    output wire        o_SAMPLE_TICK,
    output wire        o_SAMPLE_EARLY_TICK,
    output wire        o_SAMPLE_LATE_TICK,
    output wire        o_TX_BIT_TICK,
    output wire        o_TX_TRIGGER,
    output wire        o_RATE_ERR
);
```

## FSM

상태는 4개이다.

| State | 의미 |
|---|---|
| `TB_UNLOCKED` | reset 직후. `i_BIT_DIV_DEFAULT`로 acquisition tick을 만든다. |
| `TB_ACQUIRE` | 첫 sync를 받은 상태. phase는 잡았지만 sync-to-sync interval은 아직 1회뿐이라 rate lock은 아니다. |
| `TB_TRACKING` | 두 번째 sync 이후. sync interval로 `bit_period_est`를 보정하며 `o_LOCKED=1`이다. |
| `TB_HOLDOVER` | 큰 cycle error가 관측된 상태. 마지막 estimate로 tick은 유지하고 다음 정상 sync를 기다린다. |

전이:

- reset: 모든 상태에서 `TB_UNLOCKED`
- `TB_UNLOCKED + i_SYNC_PULSE`: `TB_ACQUIRE`
- `TB_ACQUIRE + i_SYNC_PULSE`: 정상 interval이면 `TB_TRACKING`, 큰 error면 `TB_HOLDOVER`
- `TB_TRACKING + i_SYNC_PULSE`: 정상 interval이면 유지, 큰 error면 `TB_HOLDOVER`
- `TB_HOLDOVER + i_SYNC_PULSE`: 정상 interval이면 `TB_TRACKING`, 큰 error면 유지

## 동작 정책

`i_SYNC_PULSE`는 `slave2_rx`가 `8'hAA` preamble을 검증한 뒤 내는 event이다. 따라서 sync cycle은 Master frame의 첫 8 bit가 이미 지난 시점이다. 이 모듈은 sync 시 slot counter를 `8 * bit_period_est`로 preload한다. 이는 Slave 1.0의 `o_SYNC_CLK_CNT = 8 * BIT_DIV` 정책과 같은 의미이다.

sample tick은 counter가 `bit_period_est / 2`일 때 발생한다. early/late tick은 center tick의 앞뒤 1 clock이다. TX bit tick은 bit period의 마지막 count에서 발생한다.

rate correction은 sync-to-sync interval에서 계산한다.

```text
slot_ticks_estimate = 50 * bit_period_est + guard_ticks
cycle_ticks_expect  = (node_cnt + 1) * slot_ticks_estimate
cycle_error         = measured_cycle_ticks - cycle_ticks_expect
bit_step            = cycle_error / ((node_cnt + 1) * 50)
```

`bit_step`은 초기 구현에서 정수 tick이며 `-2..+2`로 제한한다. 계산 결과가 1 tick 미만이면 estimate를 유지한다.

`i_RX_ACTIVE` 또는 `i_TX_ACTIVE`가 1일 때 들어온 sync의 rate correction은 pending으로 저장하고 active가 모두 0인 cycle에서 적용한다. 단, sync event 자체는 preamble boundary로 취급하여 slot phase reset은 즉시 수행한다. 이 정책은 frame 중 bit skip/repeat를 막기 위한 것이며, RX가 preamble 검증 cycle에 active를 유지하는 구현과도 호환된다.

`i_NODE_ID > i_NODE_CNT`이면 `o_TX_TRIGGER`는 발생하지 않는다.

## 출력

- `o_LOCKED`: `TB_TRACKING`일 때 1
- `o_BIT_PERIOD_EST`: 현재 bit period estimate
- `o_SAMPLE_*_TICK`: RX sampling용 1-cycle pulse
- `o_TX_BIT_TICK`: TX bit advance용 1-cycle pulse
- `o_TX_TRIGGER`: 현재 slot이 `i_NODE_ID`이고 guard 중앙 tick에 도달했을 때 1-cycle pulse
- `o_RATE_ERR`: 큰 cycle error가 관측된 cycle 또는 holdover 상태에서 1

## 테스트 범위

TB는 다음을 검증한다.

- reset 후 unlocked/default period
- default sample/tx tick 발생
- 첫 sync acquisition과 slot preload
- 두 번째 sync에서 lock 진입
- expected interval에서 estimate 유지
- 빠른 cycle에서 period 감소
- 느린 cycle에서 period 증가
- correction bounding
- active 중 pending correction 저장과 boundary 적용
- `NODE_ID > NODE_CNT` trigger block
- large cycle error에서 holdover/rate error

## Verification Result

2026-06-03에 Vivado 2019.1 xsim으로 단독 검증을 실행했다.

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave2_timebase\run_xsim.tcl
```

결과:

```text
PASS: tb_slave2_timebase
```
