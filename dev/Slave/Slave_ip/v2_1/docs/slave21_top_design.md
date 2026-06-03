# `slave21_top` 설계 노트

## 목적

`slave21_top`은 Slave 2.1 leaf module을 연결하는 PL-only top이다. 이 source는 Master broadcast를 수신해 정상 frame일 때만 상태를 commit하고, 두 번의 연속 정상 broadcast 이후 자기 slot에서 Slave response frame을 송신하도록 구성한다.

## Interface

```verilog
module slave21_top #(
    parameter [2:0]  NODE_ID = 3'd0,
    parameter [2:0]  NODE_CNT = 3'd4,
    parameter [15:0] BIT_PERIOD_DEFAULT = 16'd1024,
    parameter [9:0]  GUARD_TICKS_DEFAULT = 10'd256
) (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire        i_MASTER_SERIAL,
    input  wire [31:0] i_PAYLOAD,
    output wire        o_SLAVE_SERIAL,
    output wire        o_LINK_TRACKING,
    output wire        o_HALTED,
    output wire        o_RATE_ERR,
    output wire [2:0]  o_FAULT_STATE,
    output wire [9:0]  o_LATCHED_GUARD_TICKS
);
```

## 내부 구조

```text
slave21_top
├─ slave2_line_sync
├─ slave21_rx
├─ slave_hamming_dec
├─ slave_control
├─ slave21_fault_fsm
├─ slave21_timebase
└─ slave21_tx
   └─ slave_hamming_enc
```

## 주요 결선

```text
good_broadcast = rx_codeword_valid && !ham_2bit_err
halt_for_me    = decoded_broadcast_data[34:27][NODE_ID]
final_tx_en    = control_tx_enable && fault_tx_allowed
```

`slave_control`은 broadcast field latch와 halt 상태를 담당한다. 실제 RTL에서는 `slave_control.i_BROADCAST_VALID`에 `rx_codeword_valid`를 연결하고, `slave_control.i_BROADCAST_2BIT_ERR`에 `ham_2bit_err`를 연결한다. 따라서 control latch는 2-bit Hamming error frame을 내부에서 거르고, 1-bit corrected frame은 정상 broadcast로 처리한다.

`slave21_fault_fsm`에는 `rx_frame_done`과 `good_broadcast`를 연결한다. `good_broadcast`는 `rx_codeword_valid && !ham_2bit_err`이므로 preamble 실패 또는 2-bit Hamming error frame은 commit되지 않는다. `slave21_fault_fsm`은 두 번의 연속 good broadcast 이후에만 `fault_tx_allowed`를 1로 만든다. 최종 TX enable은 `control_tx_enable && fault_tx_allowed`이다.

## Guard ticks 정책

`slave_control`이 latch한 `GUARD_TICKS`가 0이면 `GUARD_TICKS_DEFAULT`를 timebase에 공급한다. 0이 아니면 latch 값을 사용한다. 첫 good commit과 같은 clock edge에서는 control latch가 아직 이전 값을 내므로 timebase 첫 acquisition에는 default가 쓰일 수 있다. 두 번째 commit부터는 latch된 guard가 적용된다.

## FSM

이 module 자체는 별도 FSM을 갖지 않는다. 상태는 하위 leaf가 담당한다.

- RX FSM: `slave21_rx`
- fault/recovery FSM: `slave21_fault_fsm`
- timebase FSM: `slave21_timebase`
- control FSM: reused `slave_control`
- TX FSM: `slave21_tx`

## Test Coverage

1차 smoke test:

- reset output
- forced valid broadcast data에서 guard/halt latch
- 첫 good broadcast 후 `SEEN_ONCE`이며 TX 금지
- 두 번째 good broadcast 후 `TRACKING`
- halt command가 TX 허용을 막음
- bad frame이 recovery로 보내는지 확인

Smoke TB는 top 배선 확인 전용이다. RX serial timing을 검증하지 않으므로 `rx_codeword`, `rx_codeword_valid`, `rx_frame_done`을 force하고, forced frame 사이 timebase rate error가 배선 검증을 방해하지 않도록 `timebase_rate_err`를 0으로 force한다. 실제 serial timing과 TX response는 full serial TB에서 검증한다.

2차 full serial test:

- 실제 serial Master broadcast 2회 주입
- first good no-TX
- second good 이후 자기 slot에서 response frame 발생
- response preamble/node/payload/Hamming decode 확인
- corrupt preamble 후 recovery는 후속 recovery/integration TB에서 확장 검증 대상

현재 1차 top 인수 범위에서는 정상 path를 우선 검증했다. `tb_slave21_top_full_serial`은 Master cycle interval을 `(NODE_CNT + 1) * (50 * BIT_PERIOD + GUARD_TICKS)`로 맞춰 두 broadcast를 주입한다. response capture는 두 번째 broadcast 직후의 fixed idle delay를 제거하고, DUT가 사용하는 현재 bit period를 기준으로 sample한다. 이 수정은 TX frame 자체를 force하지 않고 real serial output만 관측한다.

## 검증 결과

- 실행 일시: 2026-06-03 09:42 KST
- Smoke command: `& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave21_top_smoke\run_xsim.tcl`
- Smoke result: `PASS: tb_slave21_top_smoke`
- Full serial command: `& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave21_top_full_serial\run_xsim.tcl`
- Full serial result: `PASS: tb_slave21_top_full_serial`
- Compile/elab logs: owned top simulations에서 `ERROR`, `CRITICAL`, `WARNING` pattern 없음.

## 확인된 사항과 가정

확인된 사항:

- Master broadcast data layout은 `{halt_cmd[7:0], GUARD_TICKS[9:0], 17'b0}`이다.
- Slave response data layout은 `{NODE_ID[2:0], payload[31:0]}`이다.

가정:

- `i_MASTER_SERIAL`은 Master-to-Slave 단방향 NRZ line이다.
- `o_SLAVE_SERIAL`은 Slave-to-Master response line이다.
- `BIT_PERIOD_DEFAULT`는 Master effective bit period와 맞춰 설정된다.
