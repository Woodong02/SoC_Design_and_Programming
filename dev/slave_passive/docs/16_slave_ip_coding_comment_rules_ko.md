# Slave AXI IP 작명 및 주석 규칙

## 1. 기준

기본 Verilog 스타일은 `Verilog_CODING_STANDARDS.md`를 따른다. 다만 차기 IP는 여러 모듈이 협업하므로, 신호 prefix와 주석 섹션 규칙을 더 구체화한다.

프로젝트 기존 표준의 “모든 신호 signed [31:0]” 예시는 제어/연산 예제에서 온 규칙이다. 이 IP에서는 protocol, frame, timing, slot 신호가 명확한 의미 폭을 가지므로 unsigned 의미 폭을 우선한다. 예: 1-bit valid, 3-bit slot id, 8-bit active mask, 10-bit guard, 33-bit bit period, 50-bit frame, 64-bit timing tick.

## 2. Module Naming

| 종류 | 이름 예 |
| --- | --- |
| AXI top | `slave_axi_ip_top` |
| register block | `slave_axi_lite_regs` |
| config shadow | `slave_cfg_shadow` |
| sync detector | `slave_sync_detector` |
| timing scheduler | `slave_timing_scheduler` |
| slot sequencer | `slave_slot_sequencer` |
| payload table | `slave_payload_table` |
| frame builder | `slave_frame_builder` |
| serializer | `slave_tx_serializer` |
| status/event | `slave_status_event` |

기존 호환 모듈은 `reuse/` 아래에 두고 새 모듈 이름과 섞지 않는다.

## 3. Signal Prefix

| Prefix | 의미 |
| --- | --- |
| `i_` | module input port |
| `o_` | module output port |
| `reg_` | AXI raw register file 값 |
| `cfg_` | shadow에 commit된 core 설정 |
| `sts_` | status level |
| `evt_` | one-clock event pulse |
| `fault_` | fault source 또는 sticky fault |
| `tx_` | transmit path |
| `rx_` | receive path |
| `slot_` | slot scheduler/sequencer |
| `frame_` | 50-bit frame 관련 |
| `ham_` | Hamming SECDED 관련 |
| `dbg_` | debug/bring-up observable |

register에는 `_ff`, next-state에는 `_next`, combinational wire에는 prefix 없이 의미 중심 이름을 사용한다. 예:

```verilog
reg  [31:0] sync_tick_counter_ff;
reg  [31:0] sync_tick_counter_next;
wire [31:0] frame_ticks;
```

## 4. State Naming

FSM state는 모듈 약어를 prefix로 붙인다.

```verilog
localparam [2:0] SEQ_IDLE         = 3'd0;
localparam [2:0] SEQ_WAIT_TARGET  = 3'd1;
localparam [2:0] SEQ_ISSUE_TX     = 3'd2;
localparam [2:0] SEQ_WAIT_TX_DONE = 3'd3;
```

state 이름은 waveform에서 바로 읽히도록 동사보다 상태 의미를 우선한다.

## 5. Code Section Comment 규칙

각 모듈은 아래 섹션 순서를 지킨다. 주석은 다소 길어도 코드 리딩을 쉽게 만드는 방향을 우선한다.

```verilog
// ---------------------------------------------------------------------------
// Parameter and localparam declarations
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Port buffering
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Register-file or configuration decode
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Combinational datapath
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// FSM next-state logic
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Sequential registers
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Output assignments
// ---------------------------------------------------------------------------
```

## 6. 주석 작성 규칙

주석은 “무엇을 하는가”보다 “왜 이 경계와 타이밍을 택했는가”를 설명한다. 하지만 이 프로젝트는 인수인계 가독성을 중요하게 보므로, FSM과 register field에는 무엇을 의미하는지도 명확히 적는다.

권장 주석:

- timing formula가 나오는 곳에는 공식과 기준 tick을 적는다.
- snapshot 정책이 있는 곳에는 “현재 cycle 고정, 다음 sync 반영”을 적는다.
- `GUARD_TICKS >> 1`에는 홀수 LSB 버림을 적는다.
- `DIV_REG + 1`에는 `DIV_REG=0`이 정상 1 tick임을 적는다.
- W1C register에는 clear 동작을 bit 단위로 적는다.
- fault latch에는 clear 조건과 latch 조건을 적는다.

피해야 할 주석:

- 코드 한 줄을 그대로 한국어로 반복하는 주석.
- 과거 구현 이력 설명.
- 문서와 충돌하는 임시 변명성 주석.

## 7. FSM 작성 규칙

- FSM은 state register, next-state logic, output pulse logic을 분리한다.
- 한 `always` block에는 하나의 FF bus를 두는 것을 기본으로 한다. 예외적으로 AXI handshake처럼 protocol상 같은 enable/reset 조건으로 함께 움직여야 하는 register group만 한 block에 둘 수 있으며, 이 경우 섹션 주석에 group 이유를 적는다.
- slot 0~7 순회는 nested condition보다 `slot_index_ff`와 table을 우선 사용한다.
- 예외 조건은 fault/event로 관측 가능하게 만든다.

## 8. LUT/Table 작성 규칙

검증 친화 구조를 위해 아래 항목은 table화한다.

- `slot_target_tick[0:7]`
- `payload_table[0:7]`
- `active_slot_snapshot[7:0]`
- optional `halt_mask_snapshot[7:0]`

table 생성부에는 table index와 slot id가 동일하다는 점을 주석으로 명시한다.

## 9. 문서 갱신 규칙

RTL에서 다음을 바꾸면 관련 문서를 같은 변경에 갱신한다.

- register offset 또는 bit field.
- timing formula.
- slot 6/7 payload policy.
- Hamming frame layout.
- config snapshot 시점.
- output enable 또는 serial idle 정책.
