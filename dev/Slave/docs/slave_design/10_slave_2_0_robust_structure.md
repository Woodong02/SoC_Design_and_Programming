# Slave 2.0 Robust Communication 구조 설계

## 목적

이 문서는 기존 Slave 1.0 구조를 보존한 상태에서, 통신 강인성을 높이기 위한 Slave 2.0 구조를 정의한다. 2.0의 핵심 목표는 Master/Slave가 서로 다른 board clock을 사용할 때 발생하는 phase offset, 작은 rate error, line delay, 짧은 jitter에 대해 더 안정적으로 동작하는 것이다.

이 문서는 구현 전 구조 설계 문서이다. 각 2.0 module source를 작성하기 전에는 AGENTS.md 규칙에 따라 별도 Korean-centered module design note를 작성해야 한다.

## 기준 자료

- `docs/slave_design/00_slave_spec_and_module_structure.md`
- `docs/slave_design/slave_master_harsh_link_verification.md`
- `docs/slave_design/slave_comm_worst_case_verification.md`
- `docs/master_analysis/03_operation_and_communication_protocol.md`
- `Slave_ip/v1_0/slave_rx.v`
- `Slave_ip/v1_0/slave_tx.v`
- `Slave_ip/v1_0/slave_slot_timer.v`
- `Slave_ip/v1_0/slave_top.v`

## Slave 1.0 보존 정책

Slave 1.0 source와 문서는 기준 구현으로 보존한다.

- 기존 `Slave_ip/v1_0/slave_*.v`는 1.0 구현으로 둔다.
- 2.0 구현 source는 기존 파일을 덮어쓰지 않고 `slave2_*` 또는 별도 2.0 디렉토리로 작성한다.
- 1.0 testbench는 regression 기준으로 유지한다.
- 2.0 검증은 1.0에서 드러난 harsh/worst-case 한계를 개선하는 방향으로 별도 testbench를 작성한다.

## 1.0 한계 요약

확인된 구조:

- `slave_rx`는 고정 `BIT_DIV` 기준으로 preamble/codeword를 중앙 sample한다.
- `slave_slot_timer`는 고정 `BIT_DIV`와 `GUARD_TICKS_DEFAULT`로 slot timing을 만든다.
- `slave_tx`는 고정 `BIT_DIV`로 response bit width를 만든다.
- `slave_rx`의 sync pulse로 `slave_slot_timer`가 state correction을 수행한다.

관측된 한계:

- 단순 phase offset은 대체로 견딘다.
- `+2%` fast clock scenario에서는 broadcast latch 또는 response decode가 실패했다.
- 원인은 50-bit continuous frame 동안 local clock 기준 sample point와 bit width가 누적 drift되는 것이다.

2.0 판단:

- 1.0에는 state correction은 있으나 rate correction이 없다.
- 2.0은 rate correction을 여러 모듈에 분산하지 않고, 하나의 가상 Master timebase로 통합한다.

## 2.0 핵심 원칙

### 가상 Master timebase

2.0은 실제 새 clock을 만들지 않는다. 모든 sequential logic은 여전히 `i_CLK` 하나에서 동작한다.

대신 `slave2_timebase`가 Master broadcast를 timing beacon으로 사용해 다음 enable/tick을 만든다.

```text
i_CLK
  -> slave2_timebase
       -> bit tick
       -> sample tick
       -> slot/cycle phase
       -> tx trigger
```

RX/TX/slot 동작은 이 tick을 clock enable처럼 사용한다.

```verilog
if (timebase_tick)
    /* advance one protocol step */
```

Bootstrap 조건:

- lock 전에도 RX가 첫 preamble을 검증할 수 있어야 한다.
- 따라서 `slave2_timebase`는 `TB_UNLOCKED` 상태에서도 `i_BIT_DIV_DEFAULT` 기준의 acquisition sample tick을 출력한다.
- 첫 preamble 검증 성공 후부터 sync-to-sync interval 측정과 rate correction을 시작한다.

### State correction과 rate correction 분리

State correction:

- Master broadcast preamble 검증 성공 시점에 수행한다.
- slot/cycle phase를 Master 기준으로 재정렬한다.
- frame 수신 중 또는 response 송신 중에는 state correction을 직접 적용하지 않는다.

Rate correction:

- broadcast-to-broadcast interval을 이용해 `bit_period_est`를 갱신한다.
- 수신/송신 중인 frame에는 갑작스러운 보정을 적용하지 않는다.
- frame 시작 시 timing estimate를 snapshot하고, 해당 frame은 같은 estimate로 완료한다.

### 작은 오차 허용

2.0은 1~2 `i_CLK` 수준의 phase 오차를 반드시 제거하려 하지 않는다. Master normal guard window 안에서 response 완료가 유지되고, RX sample point가 bit center 근처에 머무르면 충분한 것으로 본다.

### 최소 기능 모듈 원칙

각 module은 하나의 primary function만 가진다.

- input CDC 안정화는 별도 module
- timebase/rate correction은 별도 module
- serial RX는 frame 수신만 담당
- serial TX는 frame 송신만 담당
- halt/payload policy는 control module이 담당
- Hamming encode/decode는 1.0 leaf를 재사용하거나 동일 기능의 2.0 wrapper로 둔다.

## Master 주기 기반 rate 추정

Slave는 다음 값을 알고 있다.

```text
NODE_CNT
GUARD_TICKS
FRAME_BITS = 50
```

Master broadcast는 한 TDMA cycle마다 반복된다. 따라서 sync pulse 사이의 slave clock count를 측정하면 Master cycle period를 slave clock 기준으로 추정할 수 있다.

현재 Master timing 기준:

```text
slot_ticks  = 50 * bit_period + GUARD_TICKS
cycle_ticks = (NODE_CNT + 1) * slot_ticks
```

sync-to-sync 측정:

```text
actual_cycle_ticks = sync_time_n - sync_time_n_minus_1
slot_ticks_est     = actual_cycle_ticks / (NODE_CNT + 1)
bit_period_meas    = (slot_ticks_est - GUARD_TICKS) / 50
```

2.0의 기본 rate update:

```text
cycle_error = actual_cycle_ticks - expected_cycle_ticks
bit_step    = cycle_error / ((NODE_CNT + 1) * 50)
bit_period_est_next = bit_period_est + bounded(bit_step)
```

구현 초기에는 정수 tick 기반으로 시작한다. 필요 시 `bit_period_est_qN` fixed-point와 fractional accumulator를 추가한다.

## 전송 중 correction 정책

2.0에서는 frame 도중 state correction을 하지 않는다.

```text
RX active:
  sample timing만 유지
  새 sync/event는 관측하거나 error로 기록
  state reset은 frame 완료 또는 abort boundary에서만 수행

TX active:
  tx_start 시 bit_period_est snapshot
  50-bit response 완료까지 같은 snapshot 사용
  중간 state correction 금지

Idle/frame boundary:
  pending state/rate correction 적용 가능
```

이 정책은 bit skip, bit repeat, frame length discontinuity를 막기 위한 것이다.

## 2.0 모듈 구조

권장 구조:

```text
slave2_top
├─ slave2_line_sync
├─ slave2_rx
│  └─ slave_hamming_dec
├─ slave2_timebase
├─ slave_control 또는 slave2_control
├─ slave2_tx
│  └─ slave_hamming_enc
└─ optional debug/status outputs
```

1.0의 `slave_hamming_enc`, `slave_hamming_dec`, `slave_control`은 기능적으로 재사용 가능하다. 다만 2.0 namespace를 명확히 하려면 wrapper 또는 복제 module을 둘 수 있다.

## 모듈별 책임

### `slave2_line_sync`

Primary function: 외부 serial input을 `i_CLK` domain으로 동기화한다.

FSM: 없음.

책임:

- `i_SERIAL_ASYNC`를 2-stage 또는 3-stage synchronizer로 안정화한다.
- optional glitch filter는 이 module의 2차 기능으로 넣지 않는다. 필요하면 별도 `slave2_line_filter`로 분리한다.

초안 interface:

```verilog
module slave2_line_sync (
    input  wire i_CLK,
    input  wire i_RESETN,
    input  wire i_SERIAL_ASYNC,
    output wire o_SERIAL_SYNC
);
```

### `slave2_rx`

Primary function: synchronized Master serial line에서 broadcast frame을 수신하고 sync event를 만든다.

FSM 후보:

```text
RX2_IDLE
RX2_PREAMBLE
RX2_CODEWORD
RX2_DONE
RX2_ERROR
```

책임:

- `8'hAA` preamble을 검증한다.
- codeword 42-bit를 수신한다.
- preamble 성공 시 `o_SYNC_PULSE`를 낸다.
- frame 수신 중 state correction을 적용하지 않는다.
- sample timing은 자체 `BIT_DIV` counter가 아니라 `slave2_timebase`가 제공하는 sample tick 또는 captured bit period를 따른다.
- 3-sample majority는 RX 내부 선택 기능으로 둘 수 있다.

초안 interface:

```verilog
module slave2_rx (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire        i_SERIAL_IN,
    input  wire        i_SAMPLE_TICK,
    input  wire        i_SAMPLE_EARLY_TICK,
    input  wire        i_SAMPLE_LATE_TICK,
    output wire [41:0] o_CODEWORD,
    output wire        o_CODEWORD_VALID,
    output wire        o_SYNC_PULSE,
    output wire        o_RX_ACTIVE,
    output wire        o_PREAMBLE_ERR
);
```

비고:

- 초기 구현에서 majority sampling을 보류하면 `i_SAMPLE_TICK`만 사용하고 early/late tick은 제거할 수 있다.
- 다만 강인성 목적상 3-point sampling은 2.0 검증 대상에 포함하는 것이 좋다.

### `slave2_timebase`

Primary function: Master broadcast sync를 기준으로 가상 Master timebase를 생성한다.

FSM 후보:

```text
TB_UNLOCKED
TB_ACQUIRE
TB_TRACKING
TB_HOLDOVER
```

책임:

- sync-to-sync interval을 측정한다.
- `bit_period_est`를 유지한다.
- 예상 cycle period와 실제 sync interval의 차이로 rate correction을 수행한다.
- slot index와 slot count를 생성한다.
- `tx_trigger`를 생성한다.
- RX/TX에 필요한 bit/sample tick을 생성한다.
- correction은 frame boundary에서만 적용한다.
- unlocked 상태에서는 `i_BIT_DIV_DEFAULT`로 RX acquisition tick을 생성한다.

초안 interface:

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

정책:

- 첫 sync는 phase acquisition으로 사용한다.
- 두 번째 sync부터 cycle interval rate estimate가 가능하다.
- lock 전 sample/tick은 `i_BIT_DIV_DEFAULT`를 따른다.
- lock 후 sample/tick은 `bit_period_est`를 따른다.
- `i_RX_ACTIVE` 또는 `i_TX_ACTIVE` 중에는 pending correction으로 보류한다.
- `NODE_ID > NODE_CNT`이면 `o_TX_TRIGGER`를 만들지 않는다.
- `o_RATE_ERR`는 cycle interval이 허용 범위를 크게 벗어난 경우 pulse 또는 sticky status로 정의한다.

### `slave2_tx`

Primary function: timebase tick을 사용해 50-bit response frame을 송신한다.

FSM 후보:

```text
TX2_IDLE
TX2_ACTIVE
TX2_DONE
```

책임:

- trigger 시 frame을 latch한다.
- trigger 시점의 TX timing을 implicit snapshot한다. 즉 active frame 중 timebase correction이 생겨도 bit skip/repeat 없이 50-bit를 완료한다.
- `i_TX_BIT_TICK`에서만 다음 bit로 진행한다.
- disabled/halted 상태에서는 idle `0`을 유지한다.

초안 interface:

```verilog
module slave2_tx (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [2:0]  i_NODE_ID,
    input  wire [31:0] i_PAYLOAD,
    input  wire        i_TX_TRIGGER,
    input  wire        i_TX_BIT_TICK,
    input  wire        i_TX_ENABLE,
    output wire        o_SERIAL_OUT,
    output wire        o_TX_ACTIVE,
    output wire        o_TX_DONE
);
```

### `slave2_control`

Primary function: broadcast decode 결과를 바탕으로 halt, guard latch, payload policy를 관리한다.

1.0 `slave_control`을 그대로 사용할 수 있다. 2.0에서 추가해야 할 수 있는 책임은 다음뿐이다.

- `o_LATCHED_GUARD_TICKS`를 `slave2_timebase`에 실제 timing input으로 연결할지 결정
- `rate_err` 또는 `lock_lost` 상태를 external status로 노출할지 결정

초기 2.0 권장:

- 기존 `slave_control`을 재사용한다.
- `slave2_timebase`의 `i_GUARD_TICKS`에는 우선 `GUARD_TICKS_DEFAULT`를 연결한다.
- latched guard를 timebase에 반영하는 기능은 별도 design note에서 적용 시점 정책을 확정한 뒤 추가한다.

### `slave2_top`

Primary function: 2.0 module integration.

초안 interface:

```verilog
module slave2_top (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire        i_MASTER_SERIAL,
    input  wire [31:0] i_PAYLOAD,
    output wire        o_SLAVE_SERIAL,
    output wire        o_SYNCED,
    output wire        o_HALTED,
    output wire        o_RATE_LOCKED,
    output wire        o_RATE_ERR,
    output wire [9:0]  o_LATCHED_GUARD_TICKS
);
```

## 동작 시퀀스

### 초기 acquisition

```text
1. line_sync가 Master serial input을 i_CLK domain으로 동기화한다.
2. timebase는 unlocked 상태에서 default BIT_DIV 기반 acquisition sample tick을 낸다.
3. rx가 preamble 후보를 검출하고 default tick으로 preamble을 검증한다.
4. preamble 검증 성공 시 sync pulse를 낸다.
5. timebase는 첫 sync에서 phase를 잡고 ACQUIRE 상태로 간다.
6. rx는 frame codeword를 수신하고 control은 halt/guard를 latch한다.
```

### 두 번째 broadcast 이후 tracking

```text
1. 다음 sync pulse가 들어온다.
2. timebase는 이전 sync와 현재 sync 사이 cycle count를 측정한다.
3. expected cycle과 비교해 bit_period_est를 갱신한다.
4. 이후 sample/tx/slot tick은 갱신된 estimate를 따른다.
```

### Response 송신

```text
1. timebase가 NODE_ID slot의 guard 중앙 부근에서 tx_trigger를 낸다.
2. control이 halt가 아니면 tx가 frame을 latch한다.
3. tx는 timebase의 tx bit tick마다 다음 bit를 송신한다.
4. active 중 correction은 frame boundary까지 보류한다.
```

## 검증 전략

2.0 검증은 1.0 module-level discipline을 유지하되, timing 강인성 test를 추가한다.

### Leaf 검증 순서

1. `slave2_line_sync`
2. `slave2_timebase`
3. `slave2_rx`
4. `slave2_tx`
5. reused `slave_control` compatibility check
6. `slave2_top`
7. Master/Slave robust integration

### `slave2_timebase` 필수 test class

- reset 후 unlocked
- 첫 sync acquisition
- 두 번째 sync에서 rate estimate 생성
- expected cycle과 같은 interval
- actual cycle이 빠른 경우 bit period 감소
- actual cycle이 느린 경우 bit period 증가
- bounded correction
- RX/TX active 중 correction 보류
- frame boundary에서 pending correction 적용
- `NODE_ID > NODE_CNT` trigger block
- large cycle error에서 `o_RATE_ERR`

### Integration test class

- nominal separate clocks
- arbitrary phase offset
- `+0.25%`, `-0.25%`, `+0.5%`, `-0.5%` drift
- 기존 1.0 한계였던 exploratory `+2%` 조건 재관찰
- propagation delay + deterministic jitter
- repeated broadcast tracking convergence
- TX active 중 sync-like disturbance가 frame을 깨지 않는지 확인

## 보류 결정

다음 항목은 2.0 구조 설계에서는 위치만 정하고 구현 여부는 module design note에서 결정한다.

- fixed-point fractional accumulator 사용 여부
- 3-sample majority를 2.0 초기 구현에 반드시 포함할지 여부
- latched broadcast `GUARD_TICKS`를 timebase에 동적으로 반영할지 여부
- `o_RATE_ERR`를 pulse, sticky bit, counter 중 어떤 형태로 노출할지 여부
- `slave_control`을 1.0 재사용할지 `slave2_control`로 복제할지 여부

## 결론

Slave 2.0의 중심 구조는 `slave2_timebase`이다. Master에 별도 clock/counter input을 추가하지 않고, Slave 내부에서 Master broadcast를 timing beacon으로 해석해 가상 Master timebase를 만든다.

이 timebase가 RX sample timing, TX bit timing, slot timing, tx trigger를 모두 생성한다. 따라서 rate correction은 한 곳에서만 수행되고, RX/TX는 동일한 Master 추종 기준을 공유한다. 전송 도중 state correction을 금지하고 frame boundary에서만 correction을 적용해, 통신 강인성과 구조적 직관성을 동시에 확보한다.
