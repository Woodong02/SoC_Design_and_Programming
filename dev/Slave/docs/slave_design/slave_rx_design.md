# `slave_rx` 설계 노트

## 목적

`slave_rx`는 Master broadcast 직렬선에서 NRZ `8'hAA + 42-bit codeword` frame을 수신하는 Slave-side receiver이다. 이 source는 Slave local sync의 기준을 제공해야 하므로, idle-low line에서 첫 `1`을 보더라도 즉시 sync하지 않고 preamble `8'hAA` 검증이 끝난 뒤에만 sync를 commit한다.

## 기준과 확정 동작

- Pure Verilog로 작성한다.
- 입력 port는 내부 wire로 복사한 뒤 사용한다.
- Frame은 MSB-first 순서의 `{8'hAA, codeword[41:0]}`이다.
- Idle line은 `1'b0`이다.
- `i_SERIAL_IN == 1'b1`을 idle 상태의 frame candidate 시작으로 본다.
- Sample point는 `i_BIT_DIV >> 1`이다.
- Preamble 검증 성공 시에만 `o_SYNC_PULSE`를 1 cycle assert한다.
- Preamble 검증 성공 cycle에 `o_SYNC_CLK_CNT = 8 * i_BIT_DIV`를 함께 출력한다.
- Preamble 검증 실패 시 `o_PREAMBLE_ERR`를 1 cycle assert하고, `o_SYNC_PULSE`와 `o_CODEWORD_VALID`는 만들지 않는다.
- Codeword 42 bit 수신 완료 후 `o_CODEWORD_VALID`를 1 cycle assert한다.

## Module Interface

```verilog
module slave_rx (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [9:0]  i_BIT_DIV,
    input  wire        i_SERIAL_IN,
    output wire [41:0] o_CODEWORD,
    output wire        o_CODEWORD_VALID,
    output wire        o_SYNC_PULSE,
    output wire [15:0] o_SYNC_CLK_CNT,
    output wire        o_PREAMBLE_ERR
);
```

| Port | 방향 | 설명 |
|---|---:|---|
| `i_CLK` | input | 수신 FSM clock |
| `i_RESETN` | input | Active-low reset |
| `i_BIT_DIV` | input | 1 bit를 구성하는 clock tick 수 |
| `i_SERIAL_IN` | input | Master `GPIO_out`에서 들어오는 NRZ serial input |
| `o_CODEWORD` | output | 수신 완료된 42-bit codeword |
| `o_CODEWORD_VALID` | output | codeword 완료 1-cycle pulse |
| `o_SYNC_PULSE` | output | preamble `8'hAA` 검증 성공 1-cycle pulse |
| `o_SYNC_CLK_CNT` | output | sync commit 시 timer preload 값, `8 * i_BIT_DIV` |
| `o_PREAMBLE_ERR` | output | preamble mismatch 1-cycle pulse |

## FSM 정의

### `RX_IDLE`

- Reset 후 기본 상태이다.
- `i_SERIAL_IN == 1'b0`이면 계속 idle이다.
- `i_SERIAL_IN == 1'b1`이면 preamble candidate로 보고 `RX_PREAMBLE`로 이동한다.
- 단, `i_BIT_DIV >> 1 == 0`인 작은 divider에서는 시작 cycle 자체가 첫 bit sample point가 될 수 있으므로 첫 `1`을 즉시 preamble shift register에 반영한다.

### `RX_PREAMBLE`

- `sample_point = i_BIT_DIV >> 1`에서 serial bit를 MSB-first shift한다.
- 8번째 preamble bit sample 후 `{previous[6:0], sampled_bit}`가 `8'hAA`이면 `RX_CODEWORD`로 이동한다.
- 이 성공 sample cycle에 `o_SYNC_PULSE = 1'b1`, `o_SYNC_CLK_CNT = 8 * i_BIT_DIV`를 출력한다.
- 값이 `8'hAA`가 아니면 `RX_ERROR`로 이동한다.

### `RX_CODEWORD`

- 42 bit codeword를 MSB-first로 shift한다.
- 42번째 bit sample 후 `o_CODEWORD`에 complete codeword를 latch하고 `RX_DONE`으로 이동한다.

### `RX_DONE`

- Terminal pulse state이다.
- `o_CODEWORD_VALID = 1'b1`을 1 cycle assert한다.
- 다음 cycle에 `RX_IDLE`로 복귀한다.

### `RX_ERROR`

- Terminal pulse state이다.
- `o_PREAMBLE_ERR = 1'b1`을 1 cycle assert한다.
- `o_SYNC_PULSE`와 `o_CODEWORD_VALID`는 assert하지 않는다.
- 다음 cycle에 `RX_IDLE`로 복귀한다.

## Counter와 Sampling

- `clk_cnt`는 active 수신 상태에서 `0..i_BIT_DIV-1` 범위로 순환한다.
- `i_BIT_DIV == 0`은 유효한 통신 설정으로 보지 않지만, simulation 안정성을 위해 내부 bit period 계산은 1 tick으로 clamp한다.
- `o_SYNC_CLK_CNT`는 사양 그대로 raw `i_BIT_DIV` 기준의 `8 * i_BIT_DIV`를 사용한다.
- Shift 방향은 `{shift_reg[N-2:0], sampled_bit}`이므로 송신 MSB-first frame이 register에 자연 순서로 쌓인다.

## Test Coverage

- Valid frame 수신과 `o_CODEWORD` 비교
- Preamble 성공 시 sync pulse 발생
- `o_SYNC_CLK_CNT == 8 * i_BIT_DIV`
- Wrong preamble에서 `o_PREAMBLE_ERR` 1-cycle pulse
- Wrong preamble에서 sync pulse와 codeword valid가 차단되는지 확인
- Reset 중단 후 partial candidate가 폐기되는지 확인
- `i_BIT_DIV` 작은 값(`1`, `2`)에서 valid frame 수신
- Idle-low 유지 시 pulse가 발생하지 않는지 확인
- `o_CODEWORD_VALID`가 1 cycle pulse인지 확인

## 확인된 사항과 가정

- 확인됨: Master protocol 문서와 `Master_rx.v` 모두 NRZ, `8'hAA`, MSB-first, sample point `DIV >> 1` 구조이다.
- 확인됨: Slave sync는 preamble 첫 `1`이 아니라 preamble 검증 성공 시점에 commit해야 한다.
- 가정: `i_BIT_DIV`는 정상 운용에서 1 이상이다. 0 입력은 testbench hang 방지와 defensive behavior를 위해 1 tick처럼 처리한다.
