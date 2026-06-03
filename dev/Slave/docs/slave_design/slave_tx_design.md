# slave_tx 설계 노트

## 목적

`slave_tx`는 Slave IP가 자기 slot에서 Master `GPIO_in` 방향으로 response frame을 송신하기 위한 serial NRZ transmitter이다. Master 수신부는 `8'hAA` preamble 이후 42-bit SECDED codeword를 MSB-first로 수신하므로, 이 모듈은 trigger 시점에 `{8'hAA, slave_hamming_enc({i_NODE_ID, i_PAYLOAD})}` 형태의 50-bit frame을 latch하고 `i_BIT_DIV` clock마다 1 bit씩 출력한다.

이 source를 작성하는 이유는 `slave_hamming_enc` leaf module 검증 이후, Slave response 송신 경로의 첫 stateful parent module을 구현하고 Master-compatible frame timing을 self-checking testbench로 확인하기 위해서이다.

## 기준 및 확정 동작

- Pure Verilog만 사용한다.
- Port signal은 내부 wire로 복사한 뒤 logic에서 사용한다.
- Combinational signal path는 `assign`으로 표현한다.
- Sequential register bus는 가능한 한 기능별 `always @(posedge i_CLK or negedge i_RESETN)` block으로 분리한다.
- Frame 구조는 `frame[49:0] = {8'hAA, codeword[41:0]}`이다.
- `codeword[41:0] = slave_hamming_enc({i_NODE_ID[2:0], i_PAYLOAD[31:0]})`이다.
- 송신 순서는 MSB-first이다. 첫 송신 bit는 `8'hAA[7]`이므로 `1'b1`이다.
- Idle, disabled, reset 상태에서 `o_SERIAL_OUT = 1'b0`이다.
- `o_TX_DONE`은 50번째 bit 송신 완료 후 1 clock 동안만 `1'b1`이 되는 pulse이다.
- 이미 `TX_ACTIVE`인 동안 들어오는 추가 `i_TX_TRIGGER`는 무시한다.

## active 중 retrigger 무시 정책

`TX_ACTIVE` 상태에서 `i_TX_TRIGGER`가 다시 들어오더라도 현재 frame을 유지하고 새 frame을 latch하지 않는다. 판단 이유는 다음과 같다.

- 진행 중인 50-bit frame overlap을 방지한다.
- Master 수신 FSM이 preamble과 codeword를 하나의 연속 frame으로 해석하도록 보장한다.
- `slave_tx`의 primary function을 단일 frame serializer로 유지하여 FSM을 단순하게 만든다.

## Module interface

```verilog
module slave_tx (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [9:0]  i_BIT_DIV,
    input  wire [2:0]  i_NODE_ID,
    input  wire [31:0] i_PAYLOAD,
    input  wire        i_TX_TRIGGER,
    input  wire        i_TX_ENABLE,
    output wire        o_SERIAL_OUT,
    output wire        o_TX_ACTIVE,
    output wire        o_TX_DONE
);
```

### Input

| Port | Width | 설명 |
|---|---:|---|
| `i_CLK` | 1 | 동기 clock |
| `i_RESETN` | 1 | active-low asynchronous reset |
| `i_BIT_DIV` | 10 | 1 serial bit를 유지할 clock 수 |
| `i_NODE_ID` | 3 | response frame data `[34:32]` |
| `i_PAYLOAD` | 32 | response frame data `[31:0]` |
| `i_TX_TRIGGER` | 1 | `TX_IDLE`에서 frame latch와 송신 시작 요청 |
| `i_TX_ENABLE` | 1 | 송신 허용. `0`이면 trigger를 무시하고 idle 유지 |

### Output

| Port | Width | 설명 |
|---|---:|---|
| `o_SERIAL_OUT` | 1 | NRZ serial output. idle/reset/disabled는 `0` |
| `o_TX_ACTIVE` | 1 | frame 송신 중 `1` |
| `o_TX_DONE` | 1 | frame 완료 후 1-cycle pulse |

## FSM 정의

### State

```text
TX_IDLE   = 2'd0
TX_ACTIVE = 2'd1
TX_DONE   = 2'd2
```

### State transition

| Current | 조건 | Next | 설명 |
|---|---|---|---|
| `TX_IDLE` | reset | `TX_IDLE` | output idle 0 |
| `TX_IDLE` | `i_TX_TRIGGER && i_TX_ENABLE` | `TX_ACTIVE` | 50-bit frame latch, first bit 출력 시작 |
| `TX_IDLE` | 그 외 | `TX_IDLE` | idle 유지 |
| `TX_ACTIVE` | `bit_cnt == 49 && bit_tick_last` | `TX_DONE` | 마지막 bit period 완료 |
| `TX_ACTIVE` | 그 외 | `TX_ACTIVE` | 현재 bit 유지 또는 다음 bit로 이동 |
| `TX_DONE` | always | `TX_IDLE` | done pulse 1 cycle 후 idle 복귀 |

`TX_ACTIVE` 중 `i_TX_TRIGGER`는 state transition에 영향을 주지 않으며 frame latch도 발생하지 않는다.

### Counter behavior

- `tx_clk_cnt`는 현재 bit 안에서 `0 .. bit_div_effective - 1` 범위를 센다.
- `bit_div_effective`는 `i_BIT_DIV == 0`인 비정상 입력에서도 zero-width period를 만들지 않기 위해 내부에서 `1`로 보정한다.
- `bit_cnt`는 frame bit index `0 .. 49`를 나타낸다.
- `TX_ACTIVE` 진입 시 `bit_cnt = 0`, `tx_clk_cnt = 0`, `serial_bit = frame[49]`이다.
- `bit_tick_last`마다 다음 bit로 이동한다.

## Terminal/error case

- Reset 중에는 state, counters, frame latch, serial output, done pulse가 모두 초기화된다.
- `i_TX_ENABLE == 0`이면 `TX_IDLE`에서 trigger가 들어와도 송신하지 않는다.
- `TX_ACTIVE` 도중 reset이 들어오면 송신을 즉시 중단하고 `o_SERIAL_OUT = 0`으로 복귀한다.
- 별도 error output은 없다. Disabled trigger와 active retrigger는 정책적으로 무시되는 valid input class이다.

## 기대 동작

1. Reset 해제 후 trigger가 없으면 `o_SERIAL_OUT = 0`, `o_TX_ACTIVE = 0`, `o_TX_DONE = 0`이다.
2. Disabled 상태에서 trigger가 들어오면 frame을 latch하지 않고 idle을 유지한다.
3. Enabled trigger가 들어오면 50-bit frame을 latch하고 첫 bit `1`을 즉시 출력한다.
4. 각 bit는 정확히 `i_BIT_DIV` clock 동안 유지된다.
5. Frame은 MSB-first로 출력된다.
6. 마지막 bit period가 끝난 뒤 `o_TX_DONE`은 1 cycle pulse가 되고, 다음 cycle에는 idle `0`으로 돌아간다.
7. Active 중 retrigger는 현재 frame에 영향을 주지 않는다.

## Test coverage

`tb/tb_slave_tx.v`는 self-checking PASS/FAIL testbench로 다음을 검증한다.

- trigger 없는 idle 유지
- disabled trigger 무시
- normal 50-bit frame 송신
- 첫 bit가 `1`인지 확인
- 모든 bit가 `i_BIT_DIV` clock 동안 유지되는지 확인
- reset 중단 시 active 해제와 serial idle `0`
- active 중 retrigger 무시 및 원래 frame 유지
- 완료 후 idle `0` 복귀와 `o_TX_DONE` 1-cycle pulse

## 확인된 사항과 가정

### Source로 확인됨

- Master protocol 문서와 `Master_ip/Master_tx.v`는 NRZ, `8'hAA`, 50-bit, MSB-first 구조를 사용한다.
- `slave_hamming_enc.v`는 `{data[34:0], p[5:0], p_overall}` 형태의 42-bit codeword를 출력한다.

### 설계 가정

- `i_BIT_DIV`는 Master effective bit period와 같은 값이다.
- `i_TX_TRIGGER`는 slot timer 또는 control logic에서 1-cycle pulse로 들어온다. 여러 cycle 동안 유지되어도 `TX_ACTIVE` 중에는 무시된다.
- `i_BIT_DIV == 0`은 정상 설정이 아니지만, test/synthesis 안정성을 위해 내부에서 1 clock bit period로 보정한다.

### 미확인

- Board-level electrical idle/pull-down 특성은 이 모듈 범위에서 확인하지 않는다. 설계상 idle drive는 `0`이다.
