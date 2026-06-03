# `slave21_fault_fsm` 설계 노트

## 목적

`slave21_fault_fsm`은 Slave 2.1의 link recovery 및 TX 허용 정책을 담당하는 leaf FSM이다. 2.1 구조에서는 Master broadcast frame을 끝까지 수신하고 검증한 뒤에만 상태를 commit한다. 이 모듈은 그 commit 결과를 바탕으로 Slave가 응답 slot에서 송신해도 되는지 결정한다.

이 source를 먼저 작성하는 이유는 RX, TX, timebase가 모두 이 정책의 출력 계약에 맞춰 연결되어야 하기 때문이다.

## Interface

```verilog
module slave21_fault_fsm (
    input  wire       i_CLK,
    input  wire       i_RESETN,
    input  wire       i_FRAME_DONE,
    input  wire       i_GOOD_BROADCAST,
    input  wire       i_HALT_FOR_ME,
    input  wire       i_RATE_ERR,
    output wire       o_TX_ALLOWED,
    output wire       o_GOOD_BROADCAST_COMMIT,
    output wire [2:0] o_FAULT_STATE
);
```

### 입력

| Port | 의미 |
|---|---|
| `i_CLK` | 동기 clock |
| `i_RESETN` | active-low reset |
| `i_FRAME_DONE` | RX가 하나의 Master broadcast 후보 frame 처리를 끝냈다는 1-cycle pulse |
| `i_GOOD_BROADCAST` | 해당 frame이 preamble/Hamming 기준 정상이라는 판정 |
| `i_HALT_FOR_ME` | decoded halt command가 현재 slave를 halt 대상으로 지정 |
| `i_RATE_ERR` | timebase가 허용 범위 밖 rate error를 감지 |

### 출력

| Port | 의미 |
|---|---|
| `o_TX_ALLOWED` | TRACKING 상태이고 halt 대상이 아닐 때 1 |
| `o_GOOD_BROADCAST_COMMIT` | `i_FRAME_DONE && i_GOOD_BROADCAST` pulse |
| `o_FAULT_STATE` | debug/status용 현재 FSM 상태 |

## FSM

상태 encoding:

```text
FLT21_RESET     = 3'd0
FLT21_ACQUIRE   = 3'd1
FLT21_SEEN_ONCE = 3'd2
FLT21_TRACKING  = 3'd3
FLT21_RECOVERY  = 3'd4
```

`FLT21_RESET`은 reset release 직후 한 cycle 동안만 머무르는 reachable state이다. 이후 `FLT21_ACQUIRE`로 이동한다.

## 전이

```text
RESET:
  -> ACQUIRE

ACQUIRE:
  frame_done && good_broadcast -> SEEN_ONCE
  frame_done && bad_broadcast  -> ACQUIRE
  no frame_done                -> ACQUIRE

SEEN_ONCE:
  frame_done && good_broadcast -> TRACKING
  frame_done && bad_broadcast  -> ACQUIRE
  no frame_done                -> SEEN_ONCE

TRACKING:
  rate_err                     -> RECOVERY
  frame_done && bad_broadcast  -> RECOVERY
  frame_done && good_broadcast -> TRACKING
  no event                     -> TRACKING

RECOVERY:
  frame_done && good_broadcast -> SEEN_ONCE
  frame_done && bad_broadcast  -> RECOVERY
  no frame_done                -> RECOVERY
```

## 출력 정책

```text
o_TX_ALLOWED = (state == FLT21_TRACKING) && !i_HALT_FOR_ME
o_GOOD_BROADCAST_COMMIT = i_FRAME_DONE && i_GOOD_BROADCAST
```

중요한 정책:

- 첫 정상 broadcast만으로는 송신하지 않는다.
- 두 번째 연속 정상 broadcast 이후에만 TRACKING으로 진입한다.
- TRACKING 중 bad frame 또는 rate error가 발생하면 TX를 금지하고 recovery로 이동한다.
- halt command는 TRACKING 상태를 깨지는 않지만, `o_TX_ALLOWED`를 0으로 만든다.

## Test Coverage

`tb_slave21_fault_fsm`은 다음을 self-checking으로 검증한다.

- reset 후 `FLT21_RESET`, 이후 `FLT21_ACQUIRE`
- ACQUIRE에서 bad frame 반복 시 TX 금지
- 첫 good frame 후 `FLT21_SEEN_ONCE`, TX 금지
- 두 번째 연속 good frame 후 `FLT21_TRACKING`, TX 허용
- halt_for_me 입력 시 TRACKING이어도 TX 금지
- TRACKING 중 bad frame -> `FLT21_RECOVERY`
- RECOVERY에서 첫 good -> `FLT21_SEEN_ONCE`
- RECOVERY에서 두 번째 good -> `FLT21_TRACKING`
- TRACKING 중 rate_err -> `FLT21_RECOVERY`
- `o_GOOD_BROADCAST_COMMIT` pulse는 good frame done에서만 발생

## 확인된 사항과 가정

확인된 사항:

- Master 쪽 silent는 즉시 halt 합계에 들어가지 않으므로, 불확실할 때 Slave가 송신하지 않는 정책이 안전하다.
- Master 정상 응답 조건은 valid response frame과 slot/address 정합이다.

가정:

- `i_GOOD_BROADCAST`는 RX preamble check와 Hamming 2-bit error 판정이 끝난 뒤 top에서 생성한다.
- `i_HALT_FOR_ME`는 decoded broadcast data에서 top 또는 control 경로가 만든다.
- `i_RATE_ERR`는 timebase leaf가 생성하며, 이 모듈에서는 level 입력으로 취급한다.
