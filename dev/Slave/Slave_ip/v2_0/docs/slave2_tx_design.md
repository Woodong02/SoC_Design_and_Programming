# slave2_tx 설계 노트

## 목적

`slave2_tx`는 Slave 2.0에서 timebase가 제공하는 `i_TX_BIT_TICK`을 기준으로 Master 방향 response frame을 송신하는 leaf transmitter이다.

이 source를 작성하는 이유는 Slave 1.0 `slave_tx`의 Master-compatible frame/Hamming layout은 유지하면서, 자체 `BIT_DIV` counter를 제거하고 Slave 2.0의 가상 Master timebase에 종속되는 TX 경로를 만들기 위해서이다.

## 기준 및 확정 동작

- Pure Verilog만 사용한다.
- Port signal은 내부 wire로 복사한 뒤 logic에서 사용한다.
- Combinational signal path는 `assign`으로 표현한다.
- Stateful register bus는 기능별 `always @(posedge clk or negedge resetn)` block으로 분리한다.
- Frame 구조는 Slave 1.0과 동일하게 `frame[49:0] = {8'hAA, codeword[41:0]}`이다.
- `codeword[41:0] = slave_hamming_enc({i_NODE_ID[2:0], i_PAYLOAD[31:0]})`이다.
- 송신 순서는 MSB-first이다. 첫 송신 bit는 `frame[49]`, 즉 `8'hAA[7]`이다.
- `i_TX_BIT_TICK`이 들어올 때만 bit index를 진행한다.
- 자체 `BIT_DIV` counter는 없다.
- Idle, reset, disabled 상태에서 `o_SERIAL_OUT = 1'b0`이다.
- `i_TX_ENABLE == 1'b0`은 disabled/halted equivalent이다. 이때 trigger는 무시되고, active 중이면 즉시 idle로 복귀한다.
- `TX2_ACTIVE` 중 retrigger는 현재 frame을 보존하기 위해 무시한다.
- `o_TX_DONE`은 50번째 bit 완료 tick 후 1 clock 동안만 `1'b1`이 되는 pulse이다.

## Module interface

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

### Input

| Port | Width | 설명 |
|---|---:|---|
| `i_CLK` | 1 | 동기 clock |
| `i_RESETN` | 1 | active-low asynchronous reset |
| `i_NODE_ID` | 3 | response frame data `[34:32]` |
| `i_PAYLOAD` | 32 | response frame data `[31:0]` |
| `i_TX_TRIGGER` | 1 | `TX2_IDLE`에서 frame latch와 송신 시작 요청 |
| `i_TX_BIT_TICK` | 1 | timebase가 제공하는 TX bit advance tick |
| `i_TX_ENABLE` | 1 | 송신 허용. `0`이면 idle `0` 유지 및 trigger 무시 |

### Output

| Port | Width | 설명 |
|---|---:|---|
| `o_SERIAL_OUT` | 1 | NRZ serial output. idle/reset/disabled는 `0` |
| `o_TX_ACTIVE` | 1 | frame 송신 중 `1` |
| `o_TX_DONE` | 1 | frame 완료 후 1-cycle pulse |

## FSM 정의

### State

```text
TX2_IDLE   = 2'd0
TX2_ACTIVE = 2'd1
TX2_DONE   = 2'd2
```

### State transition

| Current | 조건 | Next | 설명 |
|---|---|---|---|
| any | reset | `TX2_IDLE` | output idle 0 |
| any | `i_TX_ENABLE == 0` | `TX2_IDLE` | disabled/halted equivalent, active frame abort |
| `TX2_IDLE` | `i_TX_ENABLE && i_TX_TRIGGER` | `TX2_ACTIVE` | 50-bit frame latch, first bit 출력 시작 |
| `TX2_IDLE` | 그 외 | `TX2_IDLE` | idle 유지 |
| `TX2_ACTIVE` | `i_TX_BIT_TICK && bit_cnt == 49` | `TX2_DONE` | 마지막 bit 완료 |
| `TX2_ACTIVE` | 그 외 | `TX2_ACTIVE` | tick 전에는 현재 bit 유지, tick 시 다음 bit로 이동 |
| `TX2_DONE` | always | `TX2_IDLE` | done pulse 1 cycle 후 idle 복귀 |
| invalid state | always | `TX2_IDLE` | terminal recovery |

`TX2_ACTIVE` 중 `i_TX_TRIGGER`는 state transition에 영향을 주지 않으며 frame latch도 발생하지 않는다.

## Counter behavior

- `bit_cnt`는 현재 출력 중인 frame bit index `0 .. 49`를 나타낸다.
- `TX2_IDLE`에서 start request가 수락되면 `bit_cnt = 0`, `serial_bit = tx_frame[49]`가 된다.
- `TX2_ACTIVE`에서 `i_TX_BIT_TICK == 0`이면 `bit_cnt`와 `serial_bit`는 유지된다.
- `TX2_ACTIVE`에서 `i_TX_BIT_TICK == 1`이고 `bit_cnt < 49`이면 `bit_cnt`는 1 증가하고 `serial_bit`는 다음 frame bit로 갱신된다.
- `TX2_ACTIVE`에서 `i_TX_BIT_TICK == 1`이고 `bit_cnt == 49`이면 `TX2_DONE`으로 이동하고 serial output은 idle `0`이 된다.
- trigger와 bit tick이 같은 clock edge에 들어온 경우, `TX2_IDLE`의 start request만 처리하고 같은 edge에서 bit index를 추가 진행하지 않는다.

## Terminal/error case

- Reset 중에는 state, bit counter, frame latch, serial bit, done pulse가 초기화된다.
- `i_TX_ENABLE == 0`이면 모든 state에서 idle `0`으로 복귀한다.
- Disabled trigger는 valid input class로 보고 무시한다.
- Active 중 retrigger는 valid input class로 보고 무시한다.
- Invalid state는 `TX2_IDLE`로 복구한다.
- 별도 error output은 없다.

## 기대 동작

1. Reset 해제 후 trigger가 없으면 `o_SERIAL_OUT = 0`, `o_TX_ACTIVE = 0`, `o_TX_DONE = 0`이다.
2. Disabled 상태에서 trigger가 들어오면 frame을 latch하지 않고 idle을 유지한다.
3. Enabled trigger가 들어오면 frame을 latch하고 첫 bit `1`을 출력한다.
4. `i_TX_BIT_TICK`이 없는 동안 현재 bit와 active 상태는 유지된다.
5. 각 `i_TX_BIT_TICK`에서 다음 bit로 진행한다.
6. Frame은 50-bit MSB-first로 출력된다.
7. 50번째 bit 완료 tick 후 `o_TX_DONE`은 1 cycle pulse가 되고 다음 cycle에는 idle `0`으로 돌아간다.
8. Active 중 retrigger는 현재 frame에 영향을 주지 않는다.
9. Active 중 `i_TX_ENABLE`이 `0`이 되면 송신을 중단하고 idle `0`으로 복귀한다.

## Test coverage

`tb/tb_slave2_tx.v`는 self-checking PASS/FAIL testbench로 다음을 검증한다.

- reset behavior
- trigger 없는 idle 유지
- disabled trigger 무시
- trigger와 tick 동시 입력 시 start만 수행
- tick 없는 동안 bit hold
- normal 50-bit frame 송신 및 MSB-first frame layout
- active 중 retrigger 무시 및 원래 frame 유지
- active 중 enable low abort
- reset 중단 시 active 해제와 serial idle `0`
- `TX2_DONE` 1-cycle pulse 및 idle 복귀

## 확인된 사항과 가정

### Source로 확인됨

- Slave 1.0 `slave_tx.v`는 `{8'hAA, slave_hamming_enc({node_id, payload})}` 50-bit frame을 MSB-first로 송신한다.
- Slave 1.0 `slave_hamming_enc.v`는 `{data[34:0], p[5:0], p_overall}` 형태의 42-bit codeword를 출력한다.

### 설계 가정

- `i_TX_BIT_TICK`은 `i_CLK` domain의 1-cycle clock enable pulse이다.
- Timebase correction은 TX frame boundary에서 관리되며, `slave2_tx`는 들어온 tick을 그대로 신뢰한다.
- `i_TX_TRIGGER`는 보통 1-cycle pulse이지만, active 중 여러 cycle 유지되어도 무시된다.

### 미확인

- Board-level electrical idle/pull-down 특성은 이 모듈 범위에서 확인하지 않는다. 설계상 idle drive는 `0`이다.
