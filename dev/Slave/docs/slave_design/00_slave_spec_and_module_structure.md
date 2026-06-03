# Slave PL-only IP 사양 및 모듈 구조

## 목적

이 문서는 현재 구현된 Master IP와 통신할 Slave PL-only IP의 확정 사양과 모듈 구조를 정의한다. Slave는 PS/AXI 제어 없이 Verilog parameter, 내부 FSM, Master broadcast 수신값만으로 동작한다.

이 문서는 구현 전 기준 문서이다. 각 모듈의 실제 Verilog source를 작성하기 전에는 별도 Korean-centered module design note를 작성해야 한다.

## 기준 자료

- `Master_ip/Master_top.v`
- `Master_ip/Master_slot.v`
- `Master_ip/Master_tx.v`
- `Master_ip/Master_rx.v`
- `Master_ip/hamming_enc.v`
- `Master_ip/hamming_dec.v`
- `docs/master_analysis/03_operation_and_communication_protocol.md`
- `docs/slave_requirements/00_slave_pl_only_requirements.md`
- `CODING_STANDARDS.md`

## 확정 설계 사양

### HDL 및 코딩 규칙

- Pure Verilog만 사용한다.
- SystemVerilog-only syntax는 사용하지 않는다.
- 모든 input port는 `i_` prefix를 사용한다.
- 모든 output port는 `o_` prefix를 사용한다.
- Port signal은 logic에서 직접 사용하지 않고 internal wire로 복사한 뒤 사용한다.
- Combinational signal path는 `assign`을 사용한다.
- Sequential logic은 `always @(posedge i_CLK ...)` 형태를 사용한다.
- 하나의 `always` block은 하나의 flip-flop bus만 담당한다.
- Stateful module은 모든 reachable state를 FSM으로 정의한다.
- 각 module은 source 작성 전에 design note, source 작성 후 self-checking testbench와 verification note를 가져야 한다.

### Master 호환 통신 방식

- Line coding은 NRZ이다.
- Preamble은 `8'hAA`이다.
- Frame 길이는 50 bit이다.
- Master 기준 송신선은 `GPIO_out`, 수신선은 `GPIO_in`이다.
- Slave 기준으로는 Master `GPIO_out`을 수신하고, 자기 slot에서 Master `GPIO_in` 방향으로 response를 송신한다.
- Frame 구조는 다음과 같다.

```text
frame[49:0] = {8'hAA, codeword[41:0]}
```

- 송수신 순서는 MSB-first이다.
- Idle line은 `0`으로 본다.
- 첫 frame bit는 `8'hAA`의 MSB인 `1`이다.

### Hamming SECDED 구조

Master `hamming_enc` / `hamming_dec`와 동일한 systematic SECDED layout을 사용한다.

```text
codeword[41:0] = {data[34:0], p[5:0], p_overall}
codeword[41:7] = data[34:0]
codeword[6:1]  = p[5:0]
codeword[0]    = p_overall
```

Slave response data layout은 다음과 같다.

```text
data[34:32] = NODE_ID[2:0]
data[31:0]  = payload[31:0]
```

`payload[31:0]`은 Slave가 Master로 전달하는 32-bit 비트열이다. Slave 통신 core는 이 값을 해석하지 않는다.

### Master Broadcast 수신

Master broadcast frame도 동일하게 `8'hAA + 42-bit codeword`이다.

Master broadcast data layout은 다음과 같다.

```text
data[34:27] = halt_cmd[7:0]
data[26:17] = GUARD_TICKS[9:0]
data[16:0]  = 17'b0
```

Slave는 broadcast를 수신하면 다음을 수행한다.

- `halt_cmd[NODE_ID]`를 추출한다.
- `GUARD_TICKS[9:0]`를 별도 flip-flop에 저장한다.
- 저장한 `GUARD_TICKS`는 상태 관측 및 향후 확장용이다.
- 이번 설계 범위에서는 수신한 `GUARD_TICKS`로 slot timing을 동적으로 변경하지 않는다.

### Initial Sync

Slave initial sync는 Master broadcast의 첫 preamble 수신으로 잡는다.

정책:

- Slave RX가 idle-low 상태에서 Master broadcast preamble의 첫 `1`을 검출하면 RX 내부 sync candidate로만 기록한다.
- Preamble `8'hAA` 검증이 성공했을 때만 sync를 commit한다.
- Preamble 검증 성공 시 `slave_rx`는 `o_SYNC_PULSE`와 `o_SYNC_CLK_CNT`를 함께 출력한다.
- `o_SYNC_CLK_CNT` 기본값은 `8 * BIT_DIV`이다. 이는 sync 기준점이 첫 preamble bit였지만, sync commit 시점에는 8-bit preamble이 이미 지난 상태임을 timer에 반영하기 위한 preload 값이다.
- Sync pulse가 들어오면 `slave_slot_timer`는 `slot = 0`, `clk_cnt = i_SYNC_CLK_CNT`로 재시작한다.
- Preamble 검증이 실패하면 sync pulse를 만들지 않고 RX만 idle로 복귀한다.
- Master는 의도적으로 broadcast를 slot boundary 직전에 한 tick 앞당겨 내보낸다. Slave는 이 동작을 그대로 따른다.
- Sync pulse에 대한 별도 off-by-one 보정은 하지 않는다.
- Broadcast frame decode 결과는 halt/guard latch용 control data로만 사용하며, timing sync와 분리한다.
- Master message가 올 때마다 slave는 다시 sync한다.
- Slave에는 현재 sync drift fault를 소비할 별도 fault 처리 모듈이 없으므로, 예상 sync window나 unexpected sync event는 계산/기록하지 않는다.
- Slave local timer 추정과 다른 시점에 Master preamble이 오더라도, 해당 preamble을 기준으로 즉시 resync한다.

### Timing 기준

Master 의도 사양은 다음과 같다.

```text
DIV_EFF        = DIV + 1
BIT_DIV        = DIV_EFF
data_len_tick  = 50 * DIV_EFF
total_tick     = data_len_tick + GUARD_TICKS
normal window  = data_len_tick + (GUARD_TICKS >> 2)
                 <= clk_cnt
                 < total_tick - (GUARD_TICKS >> 2)
```

Master 원본의 `DIV_p1` no-driver 버그는 `Master_ip/Master_top.v`에서 `DIV_p1 = DIV + 1`로 수정한다. Slave 설계는 raw AXI field가 아니라 effective bit period인 `BIT_DIV` parameter를 기준으로 한다.

현재 Master 구현과 Slave 1차 설계는 `total_tick = 50 * BIT_DIV + GUARD_TICKS`를 기준으로 한다. Master 구현자 협의 결과에 따라 향후 guard에도 bit divider를 적용하는 `(50 + GUARD_TICKS) * BIT_DIV` 구조로 바뀔 수 있으므로, 구현 source의 해당 수식 근처에는 이 대안 수식을 주석으로 남긴다.

Slave response는 자기 slot 시작 후 guard 절반이 지난 시점에 송신을 시작한다.

```text
tx_start_tick = GUARD_TICKS >> 1
```

그러면 50-bit response frame 완료 시점은 guard 중앙 근처에 위치한다. Master 정상 수신 window는 guard의 `1/4`부터 `3/4` 범위이므로, 이 시작점은 현재 의도에 맞는다.

TX start offset에 대한 별도 보정 parameter는 이번 설계에 두지 않는다.

Master broadcast는 `slot == NODE_CNT`의 끝에서 trigger되고, 다음 cycle의 `slot 0` 시작부에 송신된다. Slave initial sync는 이 broadcast frame의 첫 preamble 수신을 기준으로 한다.

### Slot Index 범위

- `NODE_CNT[2:0]`는 Master와 동일하게 마지막 slot index이다.
- 허용되는 slot index 값은 3-bit 범위인 `0`부터 `7`까지이다.
- 실제 순환 범위는 `0..NODE_CNT`이다.
- `NODE_ID[2:0]`도 `0..7` 범위의 3-bit 값이다.
- `NODE_ID > NODE_CNT`이면 해당 slave는 active slot을 갖지 않으므로 TX trigger를 만들지 않는다.

### Halt 정책

`halt_cmd[NODE_ID] == 1`이면 Slave는 기본적으로 침묵한다.

침묵 상태에서는 response TX trigger를 막고 TX line을 idle `0`으로 둔다. 단, 향후 recovery 기능을 추가할 여지를 남기기 위해 halt 처리는 `slave_control`의 정책 FSM에 격리한다.

이번 구조에서 recovery 기능은 구현하지 않는다. 대신 다음 확장 지점을 남긴다.

- `slave_control` 내부 `HALT` state
- recovery enable parameter 또는 input 후보
- recovery 조건이 만족될 때 `WAIT_SYNC` 또는 `ACTIVE`로 복귀하는 transition 후보

## 권장 Top Parameter

```verilog
parameter [2:0]  NODE_ID = 3'd0;
parameter [9:0]  BIT_DIV = 10'd1024;
parameter [9:0]  GUARD_TICKS_DEFAULT = 10'd256;
parameter [31:0] PAYLOAD_DEFAULT = 32'd0;
```

`BIT_DIV`는 Master PS register raw value가 아니라 Master 내부 effective bit period이다.

## 모듈 분해 원칙

- 한 모듈은 하나의 primary function만 가진다.
- Encoding/decoding, serial TX, serial RX, timing, policy control, top integration을 분리한다.
- Leaf module부터 검증한다.
- Parent module testbench는 child module testbench PASS 후 작성한다.
- Master 호환이 필요한 Hamming logic은 Master source와 같은 parity tree를 사용하되 slave 전용 모듈명으로 둔다.

## 모듈 구조

```text
slave_top
├─ slave_rx
│  └─ slave_hamming_dec
├─ slave_tx
│  └─ slave_hamming_enc
├─ slave_slot_timer
└─ slave_control
```

## 모듈별 책임과 포트 구조 초안

### `slave_hamming_enc`

Primary function: 35-bit data를 Master 호환 42-bit SECDED codeword로 encoding한다.

FSM: 없음.

Port 초안:

```verilog
module slave_hamming_enc (
    input  wire [34:0] i_DATA,
    output wire [41:0] o_CODEWORD
);
```

Test coverage:

- all-zero data
- all-one data
- walking-one data
- Master `hamming_enc`와 같은 output 비교

### `slave_hamming_dec`

Primary function: Master broadcast codeword를 decode하고 1-bit/2-bit error status를 만든다.

FSM: 없음.

Port 초안:

```verilog
module slave_hamming_dec (
    input  wire [41:0] i_CODEWORD,
    output wire [34:0] o_DATA,
    output wire        o_HAM_1BIT_ERR,
    output wire        o_HAM_2BIT_ERR
);
```

Test coverage:

- no-error frame
- data bit 1-bit error correction
- parity/overall parity 1-bit error
- 2-bit error detection
- Master `hamming_dec`와 같은 output 비교

### `slave_rx`

Primary function: Master broadcast serial line에서 `8'hAA` preamble과 42-bit codeword를 수신한다.

FSM 후보:

```text
RX_IDLE
RX_PREAMBLE
RX_CODEWORD
RX_DONE
RX_ERROR
```

Port 초안:

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

구현 정책:

- Idle-low line에서 `i_SERIAL_IN == 1'b1`이면 preamble 후보 수신을 시작한다.
- Preamble 첫 `1` 검출 시에는 RX 내부 candidate만 잡고 `o_SYNC_PULSE`는 아직 assert하지 않는다.
- Sample point는 bit period 중앙인 `i_BIT_DIV >> 1`이다.
- `8'hAA`를 확인한 뒤 42-bit codeword를 수신한다.
- Preamble `8'hAA` 검증 성공 시 `o_SYNC_PULSE`를 1-cycle assert하고 `o_SYNC_CLK_CNT = 8 * i_BIT_DIV`를 함께 출력한다.
- Preamble 검증 실패 시 `o_PREAMBLE_ERR`를 assert하고 sync pulse는 만들지 않는다.
- `o_CODEWORD_VALID`는 1-cycle pulse이다.

Test coverage:

- valid broadcast frame 수신
- preamble candidate 후 검증 성공 sync pulse
- sync preload `8 * BIT_DIV`
- wrong preamble
- wrong preamble sync block
- reset 중단
- `BIT_DIV` boundary
- idle-low 유지

### `slave_tx`

Primary function: trigger 시점에 50-bit response frame을 serial NRZ로 송신한다.

FSM 후보:

```text
TX_IDLE
TX_ACTIVE
TX_DONE
```

Port 초안:

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

구현 정책:

- `i_TX_TRIGGER && i_TX_ENABLE`일 때 frame을 latch한다.
- Frame은 `{8'hAA, slave_hamming_enc({i_NODE_ID, i_PAYLOAD})}`이다.
- MSB-first로 송신한다.
- Idle과 disabled 상태는 `o_SERIAL_OUT = 1'b0`이다.
- `o_TX_DONE`은 frame 완료 후 1-cycle pulse이다.

Test coverage:

- trigger 없는 idle
- normal 50-bit frame
- disabled trigger 무시
- reset 중단
- frame first bit `1`
- frame 완료 후 idle `0`

### `slave_slot_timer`

Primary function: Master broadcast sync 이후 local TDMA slot/cycle timing과 response trigger candidate를 생성한다.

FSM 후보:

```text
TIMER_UNSYNCED
TIMER_LOCKED
```

Port 초안:

```verilog
module slave_slot_timer (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [2:0]  i_NODE_ID,
    input  wire [2:0]  i_NODE_CNT,
    input  wire [9:0]  i_BIT_DIV,
    input  wire [9:0]  i_GUARD_TICKS,
    input  wire        i_SYNC_PULSE,
    input  wire [15:0] i_SYNC_CLK_CNT,
    output wire        o_SYNCED,
    output wire [2:0]  o_SLOT,
    output wire [15:0] o_CLK_CNT,
    output wire        o_TX_TRIGGER
);
```

구현 정책:

- `i_SYNC_PULSE`는 Master broadcast preamble `8'hAA` 검증 성공 시 생성되는 sync commit event이다.
- `i_SYNC_PULSE`가 들어오면 `o_SLOT = 0`, `o_CLK_CNT = i_SYNC_CLK_CNT` 기준으로 timer를 재시작한다.
- `i_SYNC_CLK_CNT`는 RX가 preamble 첫 bit 기준 sync를 유지하기 위해 제공하는 preload 값이며, 기본값은 `8 * i_BIT_DIV`이다.
- Sync pulse는 매 Master message마다 timer를 재동기화한다.
- 예상 sync window, sync fault counter, unexpected sync status는 이번 설계에 두지 않는다.
- `i_GUARD_TICKS`는 parameter/default timing 값이다. Broadcast에서 latch한 값은 이번 범위에서 timer에 직접 연결하지 않는다.
- `o_TX_TRIGGER`는 `o_SLOT == i_NODE_ID`이고 `o_CLK_CNT == (i_GUARD_TICKS >> 1)`일 때 1-cycle pulse로 발생한다.
- `i_NODE_ID > i_NODE_CNT`이면 `o_TX_TRIGGER`를 만들지 않는다.
- Slot length는 현재 Master 구현 기준 `50 * i_BIT_DIV + i_GUARD_TICKS`이다.
- 향후 협의 결과에 따라 `(50 + i_GUARD_TICKS) * i_BIT_DIV` 구조로 바뀔 수 있음을 source 주석에 남긴다.
- TX start offset에 대한 별도 보정은 하지 않는다.

Test coverage:

- unsynced reset 상태
- sync pulse 후 slot 0 기준 진입
- repeated sync pulse resync
- slot increment
- cycle wrap
- node slot trigger
- `NODE_ID > NODE_CNT` trigger block
- boundary near normal window

### `slave_control`

Primary function: decoded broadcast 결과를 바탕으로 halt state, latched broadcast fields, TX enable, payload source를 관리한다.

FSM 후보:

```text
CTRL_WAIT_SYNC
CTRL_ACTIVE
CTRL_HALT
```

Port 초안:

```verilog
module slave_control (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [2:0]  i_NODE_ID,
    input  wire [34:0] i_BROADCAST_DATA,
    input  wire        i_BROADCAST_VALID,
    input  wire        i_BROADCAST_2BIT_ERR,
    input  wire [31:0] i_PAYLOAD_IN,
    output wire        o_TX_ENABLE,
    output wire [9:0]  o_LATCHED_GUARD_TICKS,
    output wire [31:0] o_PAYLOAD,
    output wire        o_HALTED
);
```

구현 정책:

- Valid broadcast이고 2-bit Hamming error가 없을 때만 broadcast data를 정책에 반영한다.
- `data[26:17]`의 `GUARD_TICKS`는 별도 FF에 저장한다.
- `halt_cmd[NODE_ID] == 1`이면 `CTRL_HALT`로 진입하고 `o_TX_ENABLE = 1'b0`이 된다.
- Recovery 확장은 `CTRL_HALT`에서 빠져나오는 조건으로 추가할 수 있게 FSM을 유지한다.
- `payload[31:0]`은 해석하지 않고 `i_PAYLOAD_IN` 또는 default parameter 값을 전달한다.

Test coverage:

- reset 후 wait sync
- valid broadcast로 active 진입
- GUARD_TICKS latch
- halt bit clear 상태
- halt bit set 상태
- 2-bit error broadcast 무시
- recovery extension hook 유지 여부

### `slave_top`

Primary function: Slave IP 외부 port와 하위 모듈을 연결한다.

Port 초안:

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

Parameter 초안:

```verilog
parameter [2:0]  NODE_ID = 3'd0;
parameter [2:0]  NODE_CNT = 3'd4;
parameter [9:0]  BIT_DIV = 10'd1024;
parameter [9:0]  GUARD_TICKS_DEFAULT = 10'd256;
parameter [31:0] PAYLOAD_DEFAULT = 32'd0;
```

구현 정책:

- `slave_rx`가 Master broadcast를 수신한다.
- `slave_rx`의 preamble first-bit sync pulse가 `slave_slot_timer`로 직접 들어간다.
- `slave_hamming_dec` 결과를 `slave_control`에 전달한다.
- `slave_control`은 halt/latched guard/payload를 관리한다.
- `slave_slot_timer`는 sync 이후 response trigger를 만든다.
- `slave_tx`는 `slave_control`이 허용한 경우에만 response를 송신한다.

## 구현 순서

1. `slave_hamming_enc` design note 작성
2. `slave_hamming_enc.v` 작성
3. `tb_slave_hamming_enc.v` 작성 및 Vivado/xsim 실행
4. verification note 기록
5. `slave_hamming_dec` 반복
6. `slave_tx` 반복
7. `slave_rx` 반복
8. `slave_control` 반복
9. `slave_slot_timer` 반복
10. `slave_top` integration design note 작성
11. `slave_top` integration testbench 작성
12. Master/Slave communication testbench 작성

## 공통 구현 체크리스트

각 slave module 구현 전후로 다음을 확인한다.

- Source 작성 전에 Korean-centered design note를 작성했는가.
- Module purpose와 source 작성 이유가 설명되어 있는가.
- Interface와 port width 선택 이유가 정의되어 있는가.
- Stateful module의 FSM state, transition, output, terminal/error case가 정의되어 있는가.
- Expected behavior와 test coverage가 정의되어 있는가.
- Pure Verilog만 사용했는가.
- 모든 input port가 `i_` prefix를 사용하는가.
- 모든 output port가 `o_` prefix를 사용하는가.
- Port signal을 logic에서 직접 사용하지 않았는가.
- Input port는 internal wire로 복사했는가.
- Output port는 internal signal에서 assign되는가.
- `assign`은 combinational path에만 사용했는가.
- 각 `always` block이 하나의 flip-flop bus만 담당하는가.
- 최소 기능 모듈 원칙을 지켰는가.
- Child module 검증 후 parent module 검증으로 올라갔는가.
- Self-checking testbench가 terminal에 명확한 PASS/FAIL을 출력하는가.
- Simulation/lint 결과를 Markdown verification note에 기록했는가.

## 현재 보류 항목

- Recovery 기능의 실제 조건과 동작
- Board-level line electrical topology 세부
- Latched `GUARD_TICKS`를 동적 timing에 반영하는 기능
- Master/Slave 통합 testbench에서 Master source를 직접 사용할지, 의도 사양의 behavioral master model을 먼저 사용할지
