# `slave21_rx` 설계 노트

## 목적

`slave21_rx`는 Slave 2.1의 Master broadcast 수신 leaf module이다. Master serial line이 idle-low 상태에서 high로 올라가는 순간을 frame 후보 시작으로 보고, 그 시점의 `i_BIT_PERIOD`를 snapshot한 뒤 8-bit preamble과 42-bit codeword를 frame-local timer로 수신한다.

이 source를 작성하는 이유는 2.1 구조가 외부 sample tick을 쓰지 않고 RX frame마다 독립된 bit timer를 사용해야 하기 때문이다. frame 중 `i_BIT_PERIOD`가 바뀌어도 현재 frame은 시작 시 snapshot한 period로 끝까지 처리한다.

## Interface

```verilog
module slave21_rx (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire        i_SERIAL_IN,
    input  wire [15:0] i_BIT_PERIOD,
    output wire [41:0] o_CODEWORD,
    output wire        o_CODEWORD_VALID,
    output wire        o_FRAME_DONE,
    output wire        o_PREAMBLE_OK,
    output wire        o_PREAMBLE_ERR,
    output wire        o_RX_ACTIVE
);
```

### 입력

| Port | 의미 |
|---|---|
| `i_CLK` | 동기 clock |
| `i_RESETN` | active-low reset |
| `i_SERIAL_IN` | line sync 이후의 Master serial input |
| `i_BIT_PERIOD` | frame 시작 시 snapshot할 bit width, clock cycle 단위 |

### 출력

| Port | 의미 |
|---|---|
| `o_CODEWORD` | 마지막으로 정상 수신 완료된 42-bit codeword |
| `o_CODEWORD_VALID` | codeword 42-bit 수신 완료 시 1-cycle pulse |
| `o_FRAME_DONE` | 정상 codeword 완료 또는 preamble 실패 시 1-cycle pulse |
| `o_PREAMBLE_OK` | `8'hAA` preamble 확인 시 1-cycle pulse |
| `o_PREAMBLE_ERR` | preamble mismatch discard 시 1-cycle pulse |
| `o_RX_ACTIVE` | preamble 또는 codeword 수신 중 level |

## Frame Format

Master broadcast 후보 frame은 MSB-first serial stream으로 처리한다.

```text
8'hAA + 42-bit codeword
```

`slave21_rx`는 Hamming decode를 하지 않는다. `o_CODEWORD_VALID`은 preamble이 정상이고 42-bit codeword를 모두 수신했다는 의미이며, Hamming 정상 여부는 상위 module에서 판정한다.

## FSM

상태 encoding:

```text
RX21_IDLE     = 3'd0
RX21_PREAMBLE = 3'd1
RX21_CODEWORD = 3'd2
RX21_DONE     = 3'd3
RX21_ERROR    = 3'd4
```

### 상태별 책임

| State | 책임 |
|---|---|
| `RX21_IDLE` | idle-low를 유지하다가 `serial_prev == 0 && serial_in == 1`이면 frame 후보 시작 |
| `RX21_PREAMBLE` | snapshot period 기반 sample로 8-bit preamble shift |
| `RX21_CODEWORD` | snapshot period 기반 sample로 42-bit codeword shift |
| `RX21_DONE` | 정상 frame 완료 후 1 cycle 머문 뒤 idle 복귀 |
| `RX21_ERROR` | preamble 실패 pulse를 낸 뒤 snapshot period로 남은 42-bit 후보 frame의 나머지 bit를 discard하고 idle 복귀 |

### 전이

```text
IDLE:
  rising candidate -> PREAMBLE
  otherwise        -> IDLE

PREAMBLE:
  8th sampled bit makes 8'hAA -> CODEWORD
  8th sampled bit mismatch    -> ERROR
  otherwise                   -> PREAMBLE

CODEWORD:
  42nd sampled bit -> DONE
  otherwise        -> CODEWORD

DONE:
  -> IDLE

ERROR:
  remaining 42 candidate bits discarded -> IDLE
  otherwise                             -> ERROR
```

## Timer 정책

- frame 시작 순간 `i_BIT_PERIOD`를 `period_snapshot`에 저장한다.
- `i_BIT_PERIOD == 0`은 비정상 입력이므로 최소값 `1`로 normalize한다.
- `period_snapshot == 1`이면 첫 high 후보 bit를 시작 cycle에 즉시 sample한다. 1-cycle bit에서는 더 늦은 center sample point가 없기 때문이다.
- `period_snapshot >= 2`이면 첫 bit는 `period_snapshot / 2` 근처에서 sample한다.
- 이후 bit는 항상 `period_snapshot` 간격으로 sample한다.
- frame 중 `i_BIT_PERIOD` 변화는 `period_snapshot`에 반영하지 않는다.

## 출력 정책

```text
preamble success:
  o_PREAMBLE_OK = 1 for 1 cycle
  o_FRAME_DONE = 0
  o_CODEWORD_VALID = 0

preamble failure:
  o_PREAMBLE_ERR = 1 for 1 cycle
  o_FRAME_DONE = 1 for 1 cycle
  o_CODEWORD_VALID = 0
  RX21_ERROR에서 나머지 42-bit 후보 frame을 consume하여 payload 내부 edge를 새 frame으로 오검출하지 않음

codeword complete:
  o_CODEWORD_VALID = 1 for 1 cycle
  o_FRAME_DONE = 1 for 1 cycle
  o_PREAMBLE_ERR = 0
```

`o_CODEWORD`는 정상 codeword 완료 시에만 갱신한다. preamble 실패 frame은 이전 정상 codeword를 덮어쓰지 않는다.

## Test Coverage

`tb_slave21_rx`는 다음을 self-checking으로 검증한다.

- reset 후 output clear 및 idle 상태
- idle-low 유지 시 frame 미검출
- 정상 `8'hAA + codeword` frame 수신
- wrong preamble discard와 `o_PREAMBLE_ERR`/`o_FRAME_DONE` pulse
- `o_CODEWORD_VALID` 및 `o_FRAME_DONE` 1-cycle pulse
- frame 중 `i_BIT_PERIOD` 변경 무시
- 작은 bit period boundary, 특히 `i_BIT_PERIOD=1`

## 확인된 사항과 가정

확인된 사항:

- Master broadcast frame은 `8'hAA + 42-bit codeword`이다.
- 2.1 RX/TX는 frame 시작 시 bit period를 snapshot하고 현재 frame 중 변경을 무시해야 한다.
- 초기 2.1 RX는 단일 center sample을 우선 적용한다.

가정:

- `i_SERIAL_IN`은 상위의 line synchronizer를 지난 신호이다.
- serial stream은 MSB-first이다.
- idle은 low이며, idle-low에서 high로 올라가는 edge가 후보 frame 시작이다.
- `o_PREAMBLE_OK`은 상위 sync/acquisition debug용 pulse이고, commit 여부는 `o_FRAME_DONE`, `o_CODEWORD_VALID`, Hamming decode 결과로 상위에서 결정한다.
