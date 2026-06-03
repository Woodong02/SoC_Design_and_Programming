# `slave_top` 통합 설계 노트

## 목적

`slave_top`은 검증된 slave leaf/parent 모듈을 연결해 Master broadcast 수신, Hamming decode, halt 정책, local slot timer, response TX를 하나의 PL-only slave IP로 구성한다.

## 작성 이유

Leaf 모듈은 각각 encoding, decoding, serial RX/TX, slot timing, control policy만 담당한다. 실제 board-level slave IP는 Master serial input과 Slave serial output을 하나의 top port set으로 노출해야 하므로 integration top이 필요하다.

## Interface

```verilog
module slave_top (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire        i_MASTER_SERIAL,
    input  wire [31:0] i_PAYLOAD,
    output wire        o_SLAVE_SERIAL,
    output wire        o_SYNCED,
    output wire        o_HALTED,
    output wire [9:0]  o_LATCHED_GUARD_TICKS
);
```

Parameter:

```verilog
parameter [2:0] NODE_ID = 3'd0;
parameter [2:0] NODE_CNT = 3'd4;
parameter [9:0] BIT_DIV = 10'd1024;
parameter [9:0] GUARD_TICKS_DEFAULT = 10'd256;
```

`PAYLOAD_DEFAULT`는 사용하지 않는다. 외부 payload 기본값이 필요하면 상위 wrapper에서 `i_PAYLOAD`에 constant를 연결한다.

## 내부 연결

```text
i_MASTER_SERIAL
  -> slave_rx
  -> slave_hamming_dec
  -> slave_control
       -> tx_enable, payload, latched_guard

slave_rx sync pulse
  -> slave_slot_timer
       -> tx_trigger

slave_control tx_enable + slave_slot_timer tx_trigger
  -> slave_tx
  -> o_SLAVE_SERIAL
```

## FSM

`slave_top` 자체에는 별도 FSM이 없다. 상태는 하위 모듈이 담당한다.

- `slave_rx`: `RX_IDLE`, `RX_PREAMBLE`, `RX_CODEWORD`, `RX_DONE`, `RX_ERROR`
- `slave_control`: `CTRL_WAIT_SYNC`, `CTRL_ACTIVE`, `CTRL_HALT`
- `slave_slot_timer`: `TIMER_UNSYNCED`, `TIMER_LOCKED`
- `slave_tx`: `TX_IDLE`, `TX_ACTIVE`, `TX_DONE`

## Timing 및 정책

- RX sync pulse는 preamble 검증 성공 후 timer에 직접 연결한다.
- Timer는 `GUARD_TICKS_DEFAULT` parameter를 사용한다.
- Broadcast에서 decode한 `GUARD_TICKS`는 `o_LATCHED_GUARD_TICKS`로 관측만 한다.
- 2-bit Hamming error가 있는 broadcast는 `slave_control`에서 무시된다.
- Halt 상태에서는 `slave_control`이 TX enable을 0으로 내려 response 송신을 막는다.

## Test Coverage

통합 testbench는 다음을 확인한다.

- valid broadcast 수신 후 sync/guard latch/active 진입
- 자기 slot에서 response frame 송신
- response frame payload와 node id decode 일치
- halt broadcast 이후 TX 침묵
- halt clear broadcast 이후 TX 재개
- wrong preamble 또는 2-bit error broadcast가 control policy를 흔들지 않음

