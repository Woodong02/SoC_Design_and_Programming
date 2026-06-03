# `slave_slot_timer` 설계 노트

## 목적

`slave_slot_timer`는 Master broadcast preamble 검증으로 commit된 sync event를 기준으로 slave local TDMA slot timing을 유지하고, 자기 node slot에서 response TX trigger candidate를 만든다. Halt 정책과 Hamming decode는 이 모듈의 책임이 아니다.

## 작성 이유

Master는 `0..NODE_CNT` slot을 순환하며, slave response frame 완료 시점이 guard 중앙 정상 window에 들어오기를 기대한다. Slave는 PS 제어가 없으므로 `NODE_ID`, `NODE_CNT`, `BIT_DIV`, `GUARD_TICKS` 입력을 기준으로 local slot counter를 구성해야 한다.

## Interface

```verilog
module slave_slot_timer (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [2:0]  i_NODE_ID,
    input  wire [2:0]  i_NODE_CNT,
    input  wire [9:0]  i_BIT_DIV,
    input  wire [9:0]  i_GUARD_TICKS,
    input  wire        i_SYNC_PULSE,
    input  wire [15:0] i_SYNC_CLK_CNT,
    output wire        o_SYNCED,
    output wire [2:0]  o_SLOT,
    output wire [15:0] o_CLK_CNT,
    output wire        o_TX_TRIGGER
);
```

- `i_SYNC_PULSE`: `slave_rx`가 `8'hAA` preamble 검증 성공 후 1-cycle assert한다.
- `i_SYNC_CLK_CNT`: sync 기준점이 preamble 첫 bit였음을 반영하는 preload 값이다. 기본 의도는 `8 * BIT_DIV`.
- `o_TX_TRIGGER`: 자기 slot에서 `clk_cnt == GUARD_TICKS >> 1`일 때 1-cycle pulse이다.

## FSM

상태는 `ff_synced` 1-bit로 표현한다.

| State | 의미 | 전이 |
|---|---|---|
| `TIMER_UNSYNCED` | reset 이후 또는 아직 유효 sync 없음 | `i_SYNC_PULSE=1`이면 `TIMER_LOCKED` |
| `TIMER_LOCKED` | slot/counter 동작 중 | reset 전까지 유지, 새 `i_SYNC_PULSE`가 오면 즉시 slot 0/preload로 resync |

## Counter 동작

- reset: `synced=0`, `slot=0`, `clk_cnt=0`, `tx_trigger=0`.
- sync pulse: `synced=1`, `slot=0`, `clk_cnt=i_SYNC_CLK_CNT`.
- locked 상태에서 `clk_cnt == slot_ticks - 1`이면 `clk_cnt=0`으로 돌아가고 slot을 증가시킨다.
- `slot == NODE_CNT`에서 wrap하면 다음 slot은 `0`이다.
- `NODE_CNT`는 마지막 slot index로 해석한다.

현재 slot length:

```text
slot_ticks = 50 * BIT_DIV + GUARD_TICKS
```

향후 협의 가능 대안:

```text
slot_ticks_alt = (50 + GUARD_TICKS) * BIT_DIV
```

## TX Trigger

`o_TX_TRIGGER`는 다음 조건이 모두 참일 때 1-cycle assert된다.

- timer가 locked 상태이다.
- 현재 slot이 `NODE_ID`와 같다.
- `NODE_ID <= NODE_CNT`이다.
- 현재 `clk_cnt == (GUARD_TICKS >> 1)`이다.

sync pulse가 들어오는 cycle에는 trigger를 내지 않는다. 특히 `i_SYNC_CLK_CNT=8*BIT_DIV`인 초기 sync 직후에는 default timing 기준 slot 0의 trigger point가 이미 지난 상태일 수 있으므로, `NODE_ID==0`은 다음 cycle의 slot 0부터 응답한다.

## Test Coverage

- reset 후 unsynced 상태
- sync pulse 후 slot 0/preload 진입
- locked 상태 counter 증가
- slot increment
- cycle wrap
- repeated sync pulse resync
- node slot trigger
- `NODE_ID > NODE_CNT` trigger block
- sync cycle trigger block

