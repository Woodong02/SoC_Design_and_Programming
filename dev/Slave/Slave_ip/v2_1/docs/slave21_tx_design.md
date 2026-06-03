# `slave21_tx` 설계 노트

## 목적

`slave21_tx`는 Slave 2.1의 응답 frame을 송신하는 leaf module이다. 2.1 구조에서 TX는 외부 tick을 사용하지 않고, trigger를 받은 순간 `i_BIT_PERIOD`, `i_NODE_ID`, `i_PAYLOAD`를 snapshot한 뒤 frame-local timer로 50-bit response를 끝까지 송신한다.

이 source를 작성하는 이유는 2.0의 tick-driven TX가 trigger와 tick phase에 따라 첫 bit 폭이 짧아질 수 있기 때문이다. 2.1 TX는 trigger accept clock에서 첫 bit를 즉시 출력하고, snapshot period 전체 폭을 보장한다.

## Interface

```verilog
module slave21_tx (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [2:0]  i_NODE_ID,
    input  wire [31:0] i_PAYLOAD,
    input  wire [15:0] i_BIT_PERIOD,
    input  wire        i_TX_TRIGGER,
    input  wire        i_TX_ENABLE,
    output wire        o_SERIAL_OUT,
    output wire        o_TX_ACTIVE,
    output wire        o_TX_DONE
);
```

### 입력

| Port | 의미 |
|---|---|
| `i_CLK` | 동기 clock |
| `i_RESETN` | active-low reset |
| `i_NODE_ID` | Slave response address, frame 시작 시 snapshot |
| `i_PAYLOAD` | Slave response payload, frame 시작 시 snapshot |
| `i_BIT_PERIOD` | bit 폭 clock cycle 수, frame 시작 시 snapshot |
| `i_TX_TRIGGER` | 1-cycle 송신 요청 |
| `i_TX_ENABLE` | IDLE 상태에서 trigger accept 허용 |

### 출력

| Port | 의미 |
|---|---|
| `o_SERIAL_OUT` | NRZ serial output. IDLE/DONE에서는 0 |
| `o_TX_ACTIVE` | frame 송신 중 1 |
| `o_TX_DONE` | 50번째 bit 폭이 끝난 직후 1-cycle pulse |

## Frame Format

Slave response frame은 Master가 기대하는 형식과 동일하다.

```text
{8'hAA, slave_hamming_enc({NODE_ID[2:0], PAYLOAD[31:0]})}
```

`slave_hamming_enc`의 codeword layout은 `Slave_ip/v2_1/reuse/slave_hamming_enc.v`를 따른다.

```text
codeword[41:0] = {data[34:0], parity[5:0], parity_overall}
data[34:0]     = {NODE_ID[2:0], PAYLOAD[31:0]}
```

송신 순서는 50-bit frame의 MSB first이다. 따라서 첫 preamble bit는 `8'hAA[7] == 1'b1`이다.

## FSM

상태 encoding:

```text
TX21_IDLE   = 2'd0
TX21_ACTIVE = 2'd1
TX21_DONE   = 2'd2
```

## 전이

```text
IDLE:
  i_TX_TRIGGER && i_TX_ENABLE -> ACTIVE
  otherwise                   -> IDLE

ACTIVE:
  current bit timer expired && bit_index == 49 -> DONE
  current bit timer expired && bit_index < 49  -> ACTIVE, next bit
  otherwise                                    -> ACTIVE

DONE:
  -> IDLE
```

## 동작

- IDLE에서 `i_TX_TRIGGER && i_TX_ENABLE`이 1이면 frame, bit period, node id, payload를 latch한다.
- trigger를 accept한 같은 clock edge 이후 `o_SERIAL_OUT`은 첫 bit `1`을 즉시 출력한다.
- `period_snapshot`은 frame 완료까지 고정하며, frame 중 `i_BIT_PERIOD` 변화는 무시한다.
- 첫 bit를 포함한 모든 bit는 snapshot period만큼 유지된다.
- ACTIVE 중 `i_TX_TRIGGER`는 무시한다. NODE_ID/PAYLOAD/BIT_PERIOD 변경도 현재 frame에 반영하지 않는다.
- IDLE과 DONE에서는 serial output을 0으로 구동한다.
- `o_TX_DONE`은 마지막 bit 폭이 끝나는 clock에서 1-cycle pulse로 출력된다.

정책 결정:

- `i_TX_ENABLE`은 frame 시작 gate로만 사용한다. 일단 trigger가 accept되면 frame 중 enable 변화로 현재 송신을 abort하지 않는다.
- `i_BIT_PERIOD == 0`은 비정상 입력이지만, timer stuck을 막기 위해 내부 snapshot은 1로 보정한다. 정상 system integration에서는 timebase가 1 이상 period를 제공해야 한다.

## Test Coverage

`tb_slave21_tx`는 다음을 self-checking으로 검증한다.

- reset 후 idle 출력
- trigger 없는 idle 유지
- `i_TX_ENABLE == 0` 상태의 trigger ignore
- 정상 frame bit sequence: `8'hAA + hamming_enc({NODE_ID, PAYLOAD})`
- trigger accept 직후 첫 bit 즉시 출력 및 full-width 유지
- ACTIVE 중 retrigger가 현재 frame을 바꾸지 않음
- frame 중 `i_BIT_PERIOD` 변경이 현재 frame timing에 영향을 주지 않음
- 마지막 bit 이후 `o_TX_DONE` 1-cycle pulse와 idle 0 복귀

## 확인된 사항과 가정

확인된 사항:

- Master response frame은 `8'hAA + hamming_enc({NODE_ID[2:0], payload[31:0]})`이다.
- 재사용 encoder의 codeword layout은 `reuse/slave_hamming_enc.v`에서 확인했다.

가정:

- `i_TX_TRIGGER`는 timebase에서 자기 slot 위치에 맞춰 1-cycle pulse로 들어온다.
- `i_BIT_PERIOD`는 정상 동작에서 1 이상이다.
- ACTIVE 중 enable deassert는 상위 fault/control 정책이 다음 trigger를 막는 방식으로 처리하고, 이미 시작한 frame은 송신 완료한다.

## 검증 결과

- 실행 일시: 2026-06-03 09:16 KST
- 실행 명령: `& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave21_tx\run_xsim.tcl`
- 결과: PASS
- 근거: `sim/slave21_tx/xsim_run/xsim.log`에 `PASS: tb_slave21_tx` marker 확인.
