# `slave21_timebase` 설계 노트

## 목적

`slave21_timebase`는 Slave 2.1에서 good Master broadcast commit event를 기준으로 bit period estimate와 slot phase를 유지하고, 자기 slot의 guard 중앙에서 `o_TX_TRIGGER`를 생성하는 leaf module이다.

이 source를 작성하는 이유는 2.1 구조에서 RX/TX가 더 이상 외부 bit tick을 사용하지 않기 때문이다. RX와 TX는 frame 시작 시 `o_BIT_PERIOD`를 snapshot하고 각자 frame-local timer로 동작한다. 따라서 timebase는 RX sample tick이나 TX bit tick을 만들지 않고, 다음 frame에서 사용할 period estimate와 보수적으로 gated 된 TX 시작 pulse만 제공한다.

## 기준 입력 선택

초기 구현은 추가 sync timing input을 만들지 않고 `i_GOOD_BROADCAST_COMMIT`의 frame-done 시점 간격을 사용한다.

근거:

- Master broadcast frame 길이는 고정 50-bit이다.
- good commit은 RX가 frame 끝까지 수신하고 검증한 뒤 1-cycle pulse로 발생한다.
- 연속 good broadcast의 frame-done latency가 같은 RX frame 구조를 통과하므로, frame-done-to-frame-done interval은 frame-start-to-frame-start interval 추정에 사용할 수 있다.
- RX/TX phase 결합을 피하는 것이 2.1의 핵심이므로, timebase가 RX 내부 sample phase를 직접 요구하지 않는다.

한계:

- 첫 acquisition 직후 slot phase는 commit이 Master frame 끝이라는 가정으로 preload한다.
- 향후 top integration에서 frame-start metadata가 필요하다고 확인되면 `i_SYNC_AGE_TICKS` 같은 입력을 추가할 수 있지만, 현재 leaf 구현에서는 요구하지 않는다.

## Interface

```verilog
module slave21_timebase (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [2:0]  i_NODE_ID,
    input  wire [2:0]  i_NODE_CNT,
    input  wire [15:0] i_BIT_PERIOD_DEFAULT,
    input  wire [9:0]  i_GUARD_TICKS,
    input  wire        i_GOOD_BROADCAST_COMMIT,
    input  wire        i_TX_ACTIVE,
    input  wire        i_TX_ALLOWED,
    output wire [15:0] o_BIT_PERIOD,
    output wire        o_PERIOD_VALID,
    output wire [2:0]  o_SLOT,
    output wire [15:0] o_SLOT_CLK_CNT,
    output wire        o_TX_TRIGGER,
    output wire        o_RATE_ERR
);
```

### 입력

| Port | 의미 |
|---|---|
| `i_CLK` | 동기 clock |
| `i_RESETN` | active-low reset |
| `i_NODE_ID` | 현재 slave node id |
| `i_NODE_CNT` | Master가 운용하는 마지막 node id |
| `i_BIT_PERIOD_DEFAULT` | reset/acquisition 중 사용하는 기본 bit period |
| `i_GUARD_TICKS` | slot마다 frame 전 guard tick 수 |
| `i_GOOD_BROADCAST_COMMIT` | 정상 Master broadcast frame-done commit 1-cycle pulse |
| `i_TX_ACTIVE` | TX가 현재 frame 송신 중임을 나타내는 입력 |
| `i_TX_ALLOWED` | fault/control policy가 송신을 허용한다는 입력 |

### 출력

| Port | 의미 |
|---|---|
| `o_BIT_PERIOD` | RX/TX가 frame 시작 시 snapshot할 현재 bit period estimate |
| `o_PERIOD_VALID` | 두 번째 good commit으로 period estimate가 유효해진 뒤 1 |
| `o_SLOT` | debug/status용 현재 slot index |
| `o_SLOT_CLK_CNT` | debug/status용 현재 slot 내부 clock count 하위 16-bit |
| `o_TX_TRIGGER` | 자기 slot guard 중앙에서 1-cycle pulse |
| `o_RATE_ERR` | commit interval이 허용 범위를 크게 벗어난 경우 1-cycle pulse |

## FSM

상태 encoding:

```text
TB21_RESET       = 3'd0
TB21_WAIT_FIRST  = 3'd1
TB21_WAIT_SECOND = 3'd2
TB21_TRACKING    = 3'd3
```

`TB21_RESET`은 reset release 직후 한 cycle 동안만 머무르는 reachable state이다.

## 전이

```text
RESET:
  -> WAIT_FIRST

WAIT_FIRST:
  good_commit -> WAIT_SECOND
  no commit   -> WAIT_FIRST

WAIT_SECOND:
  good_commit && rate_ok  -> TRACKING
  good_commit && rate_err -> WAIT_FIRST
  no commit               -> WAIT_SECOND

TRACKING:
  good_commit && rate_ok  -> TRACKING
  good_commit && rate_err -> WAIT_FIRST
  no commit               -> TRACKING
```

## Period estimate

측정 interval:

```text
measured_interval = 연속 good commit pulse 사이 clock 수
```

예상 cycle:

```text
slot_ticks          = (FRAME_BITS * current_bit_period) + GUARD_TICKS
expected_interval   = (NODE_CNT + 1) * slot_ticks
denominator_bits    = (NODE_CNT + 1) * FRAME_BITS
raw_period_step     = (measured_interval - expected_interval) / denominator_bits
limited_period_step = raw_period_step를 [-MAX_PERIOD_STEP, +MAX_PERIOD_STEP]로 제한
next_bit_period     = current_bit_period + limited_period_step
```

기본 parameter:

```text
FRAME_BITS          = 50
MAX_PERIOD_STEP     = 2
RATE_ERR_LIMIT_TICKS = 512
```

`abs(measured_interval - expected_interval) > RATE_ERR_LIMIT_TICKS`이면 `o_RATE_ERR`를 1-cycle assert하고 period valid를 해제한다. 작은 fast/slow interval은 bounded correction으로 추적한다.

## Slot phase

good commit은 Master broadcast frame-done 시점이다. 따라서 commit 시 현재 slot은 Master slot `0`이고, slot 내부 count는 이미 `FRAME_BITS * current_bit_period`가 지난 지점으로 preload한다.

```text
commit:
  slot = 0
  slot_clk_cnt = FRAME_BITS * current_bit_period
```

각 slot 길이는 다음과 같다.

```text
slot_ticks = FRAME_BITS * current_bit_period + GUARD_TICKS
```

slot 끝에 도달하면 `slot`은 증가하고, `NODE_CNT` 이후에는 `0`으로 wrap한다.

## TX trigger policy

`o_TX_TRIGGER`는 다음 조건을 모두 만족할 때만 1-cycle assert한다.

```text
o_PERIOD_VALID == 1
i_TX_ALLOWED == 1
i_TX_ACTIVE == 0
i_NODE_ID <= i_NODE_CNT
o_SLOT == i_NODE_ID
o_SLOT_CLK_CNT == GUARD_TICKS / 2
```

중요:

- Timebase는 link/fault policy를 판단하지 않는다.
- 첫 good commit만으로는 `o_PERIOD_VALID`가 0이므로 TX trigger가 나오지 않는다.
- 두 번째 good commit 이후라도 `i_TX_ALLOWED`가 0이면 trigger가 나오지 않는다.
- TX active 중에는 retrigger를 만들지 않는다.

## Test Coverage

`tb_slave21_timebase`는 다음을 self-checking으로 검증한다.

- reset/default period
- 첫 good commit acquisition, 아직 period invalid
- 두 번째 good commit 후 period valid/tracking
- expected interval에서 period 유지
- fast interval에서 bounded period 감소
- slow interval에서 bounded period 증가
- `i_TX_ALLOWED` gating
- `i_NODE_ID > i_NODE_CNT` trigger block
- `i_TX_ACTIVE` 중 trigger block
- 큰 interval error에서 `o_RATE_ERR` pulse 및 period invalid

## 확인된 사항과 가정

확인된 사항:

- 2.1 구조에서 timebase는 RX/TX bit tick을 생성하지 않는다.
- 첫 정상 broadcast는 acquisition 전용이며, 두 번째 정상 broadcast 이후부터 송신 가능 상태가 된다.
- `i_TX_ALLOWED`는 `slave21_fault_fsm` 및 control 정책 결과로 외부에서 들어온다.

가정:

- `i_GOOD_BROADCAST_COMMIT`는 정상 frame에 대해서만 1-cycle pulse로 들어온다.
- Master cycle은 `(NODE_CNT + 1)`개의 slot으로 구성되고 각 slot은 `50-bit frame + guard`로 모델링한다.
- frame-done commit interval은 초기 leaf 구현의 period estimate 기준으로 충분하다.
