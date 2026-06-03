# Slave 2.1 Frame-Complete Commit 구조 설계

## 목적

Slave 2.1은 Master/Slave 별도 board clock, phase offset, 작은 rate error, line delay, jitter 조건에서 Slave 1.0보다 안정적인 통신을 목표로 한다. 2.1의 핵심 원칙은 **Master broadcast frame을 끝까지 수신하고 검증한 뒤에만 상태를 commit하고, commit 결과가 정상일 때만 다음 자기 slot에서 송신한다**는 것이다.

## 2.0에서 2.1로 전환한 이유

Slave 2.0의 tick-driven RX/TX 구조는 `slave2_timebase`가 RX sample tick과 TX bit tick까지 만들었다. 이 방식은 lock 전 acquisition sample phase가 Master frame start와 어긋날 수 있고, TX trigger와 bit tick phase가 다르면 첫 bit 폭이 짧아질 수 있다. 2.1은 RX/TX가 frame 시작 시 bit period를 snapshot하고 자체 frame-local timer로 동작하게 하여 phase 결합을 제거한다. 또한 Slave가 확신 없는 상태에서 송신하지 않고 다음 Master broadcast를 기다리게 하여 Master의 severe slot fault를 피한다.

## 기준 자료

- `docs/master_analysis/03_operation_and_communication_protocol.md`
- `docs/master_analysis/04_fault_decision_behavior.md`
- `docs/Fault_decisions_chart_transcription.md`
- `docs/slave_requirements/00_slave_pl_only_requirements.md`
- `docs/slave_design/00_slave_spec_and_module_structure.md`
- `Slave_ip/v2_0/docs/00_slave2_robust_structure.md`
- `Slave_ip/v2_0/docs/slave2_top_full_serial_verification.md`

## Master 동작과의 정합성

확인된 Master 기대사항:

- Master broadcast frame은 `8'hAA + 42-bit codeword`이다.
- Master broadcast data는 `{halt_cmd[7:0], GUARD_TICKS[9:0], 17'b0}`이다.
- Master broadcast에는 `DIV`가 포함되지 않는다.
- Slave response frame은 `8'hAA + hamming_enc({NODE_ID[2:0], payload[31:0]})`이다.
- Master RX는 frame 완료 pulse `in_sig/out_sig` 시점의 `rx_stat`와 decoded address를 기준으로 fault를 판정한다.
- `rx_stat == 0`이고 decoded address가 현재 slot과 같으면 정상이다.
- wrong slot/address 또는 data window 내부 완료는 severe slot timeout으로 볼 수 있다.
- Master silent counter는 존재하지만 `halt_cmd` 산출 합계에는 포함되지 않는다.

2.1 정책:

- Slave가 불확실할 때는 송신하지 않는다.
- 송신하지 않는 것은 Master silent 쪽으로 관측될 수 있으나, 잘못된 timing 송신보다 안전하다.
- Slave fault FSM은 영구 정지기가 아니라 recovery/acquisition 상태기로 동작한다.
- TX 허용은 좋은 Master broadcast를 frame 단위로 commit한 뒤에만 발생한다.

## 핵심 원칙

### Frame-complete commit

Slave는 Master broadcast를 수신하는 도중에는 halt, guard, rate, TX enable 상태를 바꾸지 않는다.

```text
Master broadcast frame start
  -> RX frame-local timer로 50-bit 수신
  -> preamble/codeword/Hamming 검사
  -> good_broadcast이면 상태 commit
  -> bad_broadcast이면 상태 commit 금지, TX 금지, 다음 broadcast 대기
```

### RX/TX frame-local timer

RX와 TX는 외부 tick을 소비하지 않는다. 둘 다 frame 시작 시 `i_BIT_PERIOD`를 snapshot하고, frame 완료까지 snapshot period를 고정한다.

```text
slave21_rx:
  edge detect -> bit_period_snapshot -> 50-bit receive

slave21_tx:
  trigger -> bit_period_snapshot -> 50-bit transmit
```

### Rate correction은 다음 frame부터

Rate correction은 현재 수신/송신 중인 frame에 적용하지 않는다. Master broadcast 간 interval로 estimate를 갱신하고, 갱신된 period는 다음 RX/TX frame 시작 시 snapshot된다.

### 송신 보수성

Slave는 최소 두 번의 정상 Master broadcast 관측 후 송신 가능 상태가 된다.

```text
첫 good broadcast:
  phase acquisition, first sync time 저장, TX 금지

두 번째 good broadcast:
  sync interval로 bit_period_est 생성, TRACKING 진입, 이후 TX 허용 가능
```

이 정책은 설정 대상이 아니라 안정 통신을 위한 불가침 영역이다.

## 전체 모듈 구조

권장 구조:

```text
slave21_top
├─ slave2_line_sync 또는 slave21_line_sync
├─ slave21_rx
├─ slave_hamming_dec
├─ slave21_fault_fsm
├─ slave21_timebase
├─ slave_control 또는 slave21_control
├─ slave21_tx
│  └─ slave_hamming_enc
└─ optional debug/status outputs
```

### 재사용 정책

- `slave_hamming_enc`: 1.0 direct reuse 가능.
- `slave_hamming_dec`: 1.0 direct reuse 가능.
- `slave2_line_sync`: 2.0 구현을 direct reuse 가능. 변경 없으면 별도 TB 재실행은 smoke/integration에서 충분하다.
- `slave_control`: 1.0 direct reuse 가능하지만 최종 TX enable은 `fault_fsm`과 AND 되어야 한다.

## 모듈별 책임

### `slave21_rx`

Primary function: synchronized Master serial line에서 50-bit broadcast frame을 수신한다.

FSM:

```text
RX21_IDLE
RX21_PREAMBLE
RX21_CODEWORD
RX21_DONE
RX21_ERROR
```

초안 interface:

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

동작:

- IDLE에서 `i_SERIAL_IN == 1'b1`이면 preamble 후보로 보고 `i_BIT_PERIOD`를 snapshot한다.
- snapshot period의 중앙에서 첫 bit를 sample한다.
- 이후 snapshot period마다 bit를 sample한다.
- preamble `8'hAA` 검증 성공 시 codeword 수신으로 진행한다.
- preamble 실패 시 `o_FRAME_DONE=1`, `o_PREAMBLE_ERR=1`, `o_CODEWORD_VALID=0`.
- codeword 42-bit 수신 완료 시 `o_FRAME_DONE=1`, `o_CODEWORD_VALID=1`.
- frame 중 `i_BIT_PERIOD` 변화는 무시한다.

비고:

- 3-sample majority는 내부 counter에서 `center-1/center/center+1`을 찍는 optional 확장으로 둘 수 있다.
- 초기 2.1 구현에서는 단일 center sample을 우선 권장한다.

### `slave21_timebase`

Primary function: good broadcast commit event를 기준으로 bit period estimate, slot phase, TX trigger를 생성한다.

FSM은 rate/phase 상태만 담당한다. link readiness/fault policy는 `slave21_fault_fsm`이 담당한다.

상태 후보:

```text
TB21_RESET
TB21_WAIT_FIRST
TB21_WAIT_SECOND
TB21_TRACKING
```

초안 interface:

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

동작:

- reset 후 `o_BIT_PERIOD = i_BIT_PERIOD_DEFAULT`.
- 첫 `i_GOOD_BROADCAST_COMMIT`은 phase acquisition으로 사용한다.
- 두 번째 good commit부터 sync-to-sync interval로 `bit_period_est`를 계산한다.
- `o_PERIOD_VALID`은 두 번째 good commit 이후 1.
- slot phase는 good commit 시점에 `8 * current_bit_period`를 preload한다. commit은 preamble 이후 frame 완료 시점이므로, 구현 시 sync 기준을 명확히 해야 한다.
- 더 단순한 대안: RX가 frame start time counter를 따로 제공하면 그 값을 timebase commit 기준으로 사용한다. 초기 구현에서는 RX가 `o_FRAME_START_PULSE` 또는 `o_SYNC_AGE_TICKS`를 제공하는지 module note에서 결정한다.
- `o_TX_TRIGGER`는 `i_TX_ALLOWED`가 1이고 `NODE_ID <= NODE_CNT`이며 자기 slot guard 중앙에 도달했을 때만 발생한다.

중요:

- Timebase는 RX sample tick과 TX bit tick을 만들지 않는다.
- Timebase는 policy decision을 하지 않는다.

### `slave21_fault_fsm`

Primary function: Master broadcast frame 결과를 바탕으로 Slave link 상태와 TX 허용 여부를 결정한다.

이름은 `fault_fsm`을 유지한다. 단, Slave의 fault는 영구 정지가 아니라 recovery/acquisition 상태이다.

FSM:

```text
FLT21_RESET
FLT21_ACQUIRE
FLT21_SEEN_ONCE
FLT21_TRACKING
FLT21_RECOVERY
```

초안 interface:

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

전이:

```text
RESET -> ACQUIRE

ACQUIRE:
  good_broadcast -> SEEN_ONCE
  bad frame      -> ACQUIRE

SEEN_ONCE:
  good_broadcast -> TRACKING
  bad frame      -> ACQUIRE

TRACKING:
  good_broadcast -> TRACKING
  bad frame or rate_err -> RECOVERY

RECOVERY:
  good_broadcast -> SEEN_ONCE
  bad frame      -> RECOVERY
```

출력:

```text
o_TX_ALLOWED = (state == TRACKING) && !i_HALT_FOR_ME
o_GOOD_BROADCAST_COMMIT = i_FRAME_DONE && i_GOOD_BROADCAST
```

정책:

- 첫 정상 broadcast만으로는 TX를 허용하지 않는다.
- 두 번째 연속 정상 broadcast 이후부터 TX를 허용한다.
- bad frame에서는 TX 금지 상태로 회복 대기한다.
- `halt_cmd[NODE_ID]`가 1이면 TRACKING이어도 TX 금지.

### `slave21_tx`

Primary function: trigger 시점에 50-bit response frame을 snapshot bit period로 송신한다.

FSM:

```text
TX21_IDLE
TX21_ACTIVE
TX21_DONE
```

초안 interface:

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

동작:

- `i_TX_TRIGGER && i_TX_ENABLE`일 때 frame과 bit period를 latch한다.
- 첫 bit `1`을 즉시 출력하고, 내부 counter로 full-width를 보장한다.
- 이후 snapshot period마다 다음 bit로 진행한다.
- frame 중 `i_BIT_PERIOD` 변화는 무시한다.
- disabled/idle은 `0`.

### `slave21_control` 또는 reused `slave_control`

Primary function: good broadcast data에서 halt bit, guard latch, payload path를 관리한다.

초기 권장:

- 1.0 `slave_control`을 재사용하되 `i_BROADCAST_VALID`에는 `good_broadcast_commit`만 연결한다.
- `slave_control.o_TX_ENABLE`과 `fault_fsm.o_TX_ALLOWED`를 AND 해서 `slave21_tx.i_TX_ENABLE`에 연결한다.

### `slave21_top`

Primary function: 2.1 module integration.

초안 interface:

```verilog
module slave21_top (
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

권장 parameter:

```verilog
parameter [2:0]  NODE_ID = 3'd0;
parameter [2:0]  NODE_CNT = 3'd4;
parameter [15:0] BIT_PERIOD_DEFAULT = 16'd1024;
parameter [9:0]  GUARD_TICKS_DEFAULT = 10'd256;
```

상위 조합:

```text
good_broadcast = rx_codeword_valid && !ham_2bit_err
halt_for_me    = decoded_broadcast_data[34:27][NODE_ID]
```

주의:

- `GUARD_TICKS`는 초기 구현에서 default parameter를 timebase에 연결한다.
- Broadcast-latched guard를 timebase에 동적으로 반영하는 기능은 별도 정책 확정 후 추가한다.

## 정상 동작 시퀀스

### 초기 acquisition

```text
1. line_sync가 Master serial input을 동기화한다.
2. rx는 default bit period로 첫 Master broadcast frame을 수신한다.
3. frame 완료 후 preamble/Hamming이 정상이면 fault_fsm은 SEEN_ONCE로 간다.
4. timebase는 first sync time/phase를 기록한다.
5. TX는 아직 금지된다.
```

### tracking 진입

```text
1. 다음 Master broadcast frame을 수신한다.
2. 두 번째 good broadcast commit이 들어온다.
3. timebase는 sync interval로 bit period estimate를 갱신한다.
4. fault_fsm은 TRACKING으로 간다.
5. halt가 아니면 다음 자기 slot TX가 허용된다.
```

### recovery

```text
1. TRACKING 중 bad frame 또는 rate error가 발생한다.
2. fault_fsm은 RECOVERY로 이동하고 TX를 금지한다.
3. 다음 good broadcast를 기다린다.
4. good broadcast가 들어오면 SEEN_ONCE로 돌아가고, 한 번 더 good broadcast 후 TRACKING으로 복귀한다.
```

## 보류 결정

- RX가 timebase에 제공할 sync timing 정보: `o_FRAME_START_PULSE`, `o_SYNC_AGE_TICKS`, 또는 frame done 시점 기준 보정 중 module note에서 확정.
- 3-sample majority sampling 적용 여부.
- latched `GUARD_TICKS`를 timebase에 동적 반영할지 여부.
- rate estimate integer vs fixed-point.
- `o_RATE_ERR` pulse/sticky/counter 형태.

## 결론

Slave 2.1은 “마스터 메시지를 다 보고, 멀쩡하면 쏜다”를 하드웨어 구조의 중심 규칙으로 삼는다. RX/TX는 frame-local timer로 단순화하고, timebase는 period/slot 추정만 담당하며, fault FSM은 정지기가 아니라 송신 보류와 재획득을 관리한다. 이 구조는 확신 없는 TX를 방지해 Master의 severe timing fault를 줄이고, silent가 즉시 halt 원인이 아닌 Master 구조를 안정 통신에 적극 활용한다.

