# Slave 2.3 Passive 현재 RTL 사양서

## 1. 범위

이 문서는 현재 저장소에 존재하는 구현을 기준으로 작성한 사양서이다.

현재 RTL의 목적:

- master-to-slave 직렬 라인을 관찰한다.
- master broadcast frame의 첫 상승 edge를 timing 기준점으로 사용한다.
- master broadcast를 decode하여 현재 slave에 대한 halt 명령을 얻는다.
- halt 상태가 아니면 자신의 TDMA slot에서 고정 형식 response frame을 송신한다.

현재 RTL에 포함되지 않은 항목:

- AXI/PS register interface.
- runtime node 선택.
- runtime active-slot 선택.
- runtime `DIV` 또는 `GUARD_TICKS` write.
- recovery, holdover, rate correction, fault-management FSM.
- shared-bus tri-state 또는 output-enable 제어.

## 2. 소스 파일 역할

| File | 역할 | 현재 상태 |
| --- | --- | --- |
| `slave23_passive_top.v` | passive slave top controller. master frame start 감지, slot timer 구동, halt 상태 latch, response TX trigger 생성. | 구현됨 |
| `reuse/slave21_rx.v` | master broadcast 수신에 재사용되는 serial frame receiver. preamble 감지, 42-bit codeword sampling, valid/done/error pulse 생성. | 구현됨 |
| `reuse/slave21_tx.v` | 이전 slave 설계에서 재사용되는 serial response transmitter. `8'hAA + 42-bit codeword`를 생성해 송신. | 구현됨 |
| `reuse/slave_hamming_enc.v` | master와 호환되는 systematic Hamming SECDED encoder. 35-bit data를 42-bit codeword로 변환. | 구현됨 |
| `reuse/slave_hamming_dec.v` | master와 호환되는 Hamming SECDED decoder. broadcast codeword decode, 일부 1-bit data error correction, 2-bit error flag 생성. | 구현됨 |
| `slave_regmap.md` | 추후 PS-visible register 요구사항. | 문서만 존재, 현재 RTL 미구현 |
| `constraints/slave23_passive_fpga_top.xdc` | `slave23_passive_fpga_top` wrapper용 board pin constraint. | constraint 파일은 존재하나 wrapper source는 현재 없음 |

## 3. Top-Level Interface

Module:

```verilog
module slave23_passive_top #(
    parameter [2:0]  NODE_ID = 3'd0,
    parameter [3:0]  DIV = 4'd10,
    parameter [9:0]  GUARD_TICKS = 10'd256
) (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire        i_MASTER_SERIAL,
    input  wire [31:0] i_PAYLOAD,
    output wire        o_SLAVE_SERIAL,
    output wire        o_HALTED,
    output wire        o_TX_ACTIVE,
    output wire        o_SYNCED
);
```

### Parameters

| Parameter | Width | Default | 의미 |
| --- | ---: | ---: | --- |
| `NODE_ID` | 3 | `0` | response에 encode되는 slave node/slot id이며, `halt_cmd` bit index로도 사용된다. |
| `DIV` | 4 | `10` | bit period exponent. 현재 RTL은 `BIT_PERIOD = 1 << DIV`로 계산한다. |
| `GUARD_TICKS` | 10 | `256` | local response-slot timing에 사용하는 guard interval. |

중요 제한사항: 현재 RTL에서 `DIV`와 `GUARD_TICKS`는 compile/elaboration-time parameter이다. master broadcast나 PS register에서 load하지 않는다.

### Ports

| Port | Direction | 의미 |
| --- | --- | --- |
| `i_CLK` | input | system clock. constraint 파일 기준 board clock은 25 MHz이다. |
| `i_RESETN` | input | active-low asynchronous reset. 구현된 sequential block 전체에서 사용된다. |
| `i_MASTER_SERIAL` | input | master-to-slave serial broadcast line. idle은 `0`으로 예상한다. |
| `i_PAYLOAD[31:0]` | input | slave frame에 포함되는 response payload. TX start 시 `slave21_tx`에서 sample된다. |
| `o_SLAVE_SERIAL` | output | slave-to-master serial response line. idle은 능동적으로 `0`을 drive한다. |
| `o_HALTED` | output | `NODE_ID`에 대한 latched halt state. valid broadcast에서만 갱신된다. |
| `o_TX_ACTIVE` | output | `slave21_tx`가 50-bit response frame을 송신하는 동안 high. |
| `o_SYNCED` | output | top FSM이 다음 master start edge를 기다리는 상태가 아닐 때 high. |

## 4. Frame Format

### Master Broadcast Frame

현재 receiver는 다음 형식을 기대한다.

```text
총 50 bits = 8'hAA preamble + 42-bit Hamming SECDED codeword
```

decoded broadcast data layout:

```text
decoded_broadcast_data[34:27] = halt_cmd[7:0]
decoded_broadcast_data[26:17] = broadcast guard ticks
decoded_broadcast_data[16:0]  = reserved / master convention상 zero
```

현재 RTL은 `decoded_broadcast_data[34:27]`만 사용한다. decoded broadcast guard field는 timing에 사용하지 않고, local parameter `GUARD_TICKS`를 사용한다.

### Slave Response Frame

`slave21_tx`는 다음 frame을 송신한다.

```text
총 50 bits = 8'hAA preamble + hamming_enc({NODE_ID[2:0], i_PAYLOAD[31:0]})
```

frame은 MSB-first로 송신된다. idle output은 `0`이다.

## 5. Timing Model

현재 top-level timing equation:

```text
BIT_PERIOD      = 1 << DIV
frame_ticks     = 50 * BIT_PERIOD
slot_ticks      = frame_ticks + GUARD_TICKS
node_offset     = NODE_ID * slot_ticks
tx_start_ticks  = frame_ticks + node_offset
```

Top FSM은 `P23_WAIT_START` 상태에서 `i_MASTER_SERIAL` 상승 edge를 보면 `sync_timer_ff`를 시작한다. 같은 cycle에서 next timer value를 `1`로 설정하므로, 감지된 master 첫 `1`을 frame reference의 첫 tick으로 센다.

TX trigger 조건:

```text
state_ff == P23_WAIT_TX
sync_timer_ff == tx_start_ticks
halted_ff == 0
```

target tick에서 `halted_ff == 1`이면 TX를 시작하지 않고 FSM은 `P23_WAIT_START`로 돌아간다.

## 6. `slave23_passive_top` 동작

### FSM States

| State | Encoding | 의미 |
| --- | ---: | --- |
| `P23_WAIT_START` | `2'd0` | `i_MASTER_SERIAL`의 `0 -> 1` transition을 기다린다. |
| `P23_WAIT_TX` | `2'd1` | 감지된 master frame start부터 현재 node의 response slot까지 count한다. |
| `P23_TX` | `2'd2` | `slave21_tx`가 response를 송신하는 동안 대기한다. |

### Start Detection

`top_master_rise`는 다음 조건에서만 true이다.

```text
state_ff == P23_WAIT_START
serial_prev_ff == 0
master_serial == 1
tx_active == 0
```

이 조건 때문에 같은 master frame 내부의 후속 rising edge가 top-level slot timer를 다시 시작시키지 않는다.

### Halt Latch

Receiver와 decoder는 계속 동작한다. `broadcast_valid`가 true이면 top은 다음 값을 latch한다.

```text
halted_ff <= halt_cmd[NODE_ID]
```

현재 `broadcast_valid` 정의:

```text
rx_codeword_valid & ~ham_2bit_err
```

`slave21_rx`의 preamble status output들은 instantiate되어 있지만 top-level logic에서는 직접 사용하지 않는다. 현재 `slave21_rx` 구현에서는 successful preamble path 이후에만 `rx_codeword_valid`가 생성되므로 기능적으로 충분하다.

### Reset Behavior

`i_RESETN == 0`일 때:

- Top FSM은 `P23_WAIT_START`로 돌아간다.
- 이전 serial sample은 `0`으로 clear된다.
- sync timer는 `0`으로 clear된다.
- halt latch는 `0`으로 clear된다.
- TX/RX child module도 각자의 reset logic을 통해 idle로 돌아간다.

## 7. `slave21_rx` 동작

목적: master broadcast serial frame 수신.

Inputs:

- `i_SERIAL_IN`: serial input.
- `i_BIT_PERIOD`: clock tick 단위 bit period. `0`이면 `1`로 normalize된다.

Outputs:

- `o_CODEWORD[41:0]`: valid preamble 및 전체 codeword 수신 후 capture된 codeword.
- `o_CODEWORD_VALID`: 42-bit codeword가 capture된 cycle에 발생하는 one-clock pulse.
- `o_FRAME_DONE`: codeword completion 또는 preamble failure 시 발생하는 one-clock pulse.
- `o_PREAMBLE_OK`: `8'hAA` preamble이 인식되었을 때 발생하는 one-clock pulse.
- `o_PREAMBLE_ERR`: 처음 sampled 8 bits가 `8'hAA`가 아닐 때 발생하는 one-clock pulse.
- `o_RX_ACTIVE`: preamble, codeword, error-drain state 동안 high.

FSM:

| State | 의미 |
| --- | --- |
| `RX21_IDLE` | serial rising edge 대기. |
| `RX21_PREAMBLE` | 8 preamble bits sampling. |
| `RX21_CODEWORD` | 42 codeword bits sampling. |
| `RX21_DONE` | successful frame capture 후 idle 복귀. |
| `RX21_ERROR` | preamble failure 후 예상 codeword 기간만큼 drain. |

Sampling:

- start candidate는 idle 상태의 `0 -> 1` transition이다.
- `i_BIT_PERIOD == 0`은 `1`로 취급한다.
- period가 1보다 크면 첫 sample은 대략 half bit period만큼 delay된다.
  - `start_sample_delay = (i_BIT_PERIOD >> 1) - 1`, minimum `0`.
- 이후 sample은 저장된 `period_snapshot_ff` tick마다 발생한다.
- bit는 MSB-first로 preamble 및 codeword shift register에 들어간다.

## 8. `slave21_tx` 동작

목적: slave response serial frame 송신.

Inputs:

- `i_NODE_ID[2:0]`
- `i_PAYLOAD[31:0]`
- `i_BIT_PERIOD[15:0]`
- `i_TX_TRIGGER`
- `i_TX_ENABLE`

Outputs:

- `o_SERIAL_OUT`
- `o_TX_ACTIVE`
- `o_TX_DONE`

TX frame:

```text
tx_frame = {8'hAA, slave_hamming_enc({i_NODE_ID, i_PAYLOAD})}
```

FSM:

| State | 의미 |
| --- | --- |
| `TX21_IDLE` | `i_TX_TRIGGER & i_TX_ENABLE` 대기. |
| `TX21_ACTIVE` | 50 frame bits를 MSB-first로 drive. |
| `TX21_DONE` | done pulse 발생 후 idle 복귀. |

Timing:

- `i_BIT_PERIOD == 0`은 `1`로 normalize된다.
- start 시 `tx_frame`의 bit 49가 먼저 drive된다.
- 각 bit는 `bit_period_sanitized` clocks 동안 유지된다.
- 마지막 bit가 끝나면 output은 `0`으로 돌아간다.
- active 중 들어온 start는 무시된다. `start_request`가 `TX21_IDLE`에서만 valid이기 때문이다.

## 9. Hamming SECDED Modules

### Encoder

Module: `slave_hamming_enc`

```text
o_CODEWORD[41:7] = i_DATA[34:0]
o_CODEWORD[6:1]  = {p5, p4, p3, p2, p1, p0}
o_CODEWORD[0]    = p_overall
```

`p_overall`은 data와 6개 parity bit 전체의 XOR reduction이다.

### Decoder

Module: `slave_hamming_dec`

동작:

- `i_CODEWORD[41:7]`을 data, `[6:1]`을 parity로 분리한다.
- 6개 parity check를 재계산한다.
- 6-bit syndrome을 만든다.
- `^i_CODEWORD`를 overall parity로 사용한다.
- flags:
  - `o_HAM_1BIT_ERR = syndrome != 0 && overall parity mismatch`
  - `o_HAM_2BIT_ERR = syndrome != 0 && no overall parity mismatch`
- syndrome 값이 `1..35`인 1-bit error에 대해 `corrected_data[syndrome - 1]`를 flip한다. 단, syndrome 값 `1, 2, 4, 8, 16, 32`는 comment 기준 parity-bit error로 취급되어 data correction을 하지 않는다.

주의: 이 correction policy는 현재 구현 동작을 그대로 설명한 것이다. 변경하기 전에 master-side encoder/decoder vector와 반드시 비교해야 한다.

## 10. 현재 구현 요약

- 이 설계는 master 검증용 최소 passive slave이다.
- frame size는 50 bits: `8'hAA + 42-bit Hamming codeword`.
- slave response data는 `{NODE_ID, PAYLOAD}`이다.
- master broadcast halt command는 matching node의 slave TX를 억제한다.
- recovery, holdover, rate correction, fault FSM은 구현되어 있지 않다.
- timing target은 `50*BIT_PERIOD + NODE_ID*(50*BIT_PERIOD + GUARD_TICKS)`이다.

### 향후 통합 항목

- `slave_regmap.md`는 PS register (`ENABLE`, `DIV`, `ACTIVE_SLOT`, `data_out0..5`)를 요구하지만 현재 RTL에는 register interface가 없다.
- 현재 RTL은 decoded broadcast `GUARD_TICKS`를 무시하고 parameter `GUARD_TICKS`를 사용한다.
- 현재 top module은 runtime `i_NODE_ID`가 아니라 parameterized `NODE_ID`를 가진다.
- 현재 top module은 runtime `i_BIT_PERIOD` 또는 PS `DIV`가 아니라 parameterized `DIV`를 가진다.
- constraint file은 `slave23_passive_fpga_top`을 참조하지만, 현재 repository file list에는 `slave23_passive_top.v`만 있다.

## 11. IP 변환 시 통합 방향

이 설계를 `slave_regmap.md`와 일치하는 configurable IP로 변환하려면 다음 변경이 우선 필요하다.

- `slave23_passive_top` 주변에 AXI-lite/register wrapper 또는 별도 top wrapper 추가.
- 필요 시 `DIV`, `GUARD_TICKS`, `NODE_ID`를 parameter에서 runtime input으로 변환하거나 wrapper에서 처리.
- slave disabled 상태에서 master input을 무시하고 TX idle을 유지하도록 `ENABLE` gating 추가.
- 하나의 hardware instance가 여러 node slot을 emulate해야 한다면 `ACTIVE_SLOT` 동작 구현.
- `data_out0..5`를 payload selection logic에 연결.
- PL-only slot 6, 7의 payload source와 PS active bit 제어 허용 여부 결정.
- packaging 전 register 및 timing behavior를 검증할 simulation source 추가 또는 복구.

## 12. 미결정 사항

- IP가 하나의 physical slave node만 노출할 것인지, 하나의 instance로 여러 active slot을 emulate할 것인지.
- `GUARD_TICKS`를 PS register, decoded master broadcast, 또는 selectable source 중 어디에서 가져올 것인지.
- `DIV`가 master의 `DIV_ticks` rule을 정확히 따라야 하는지. 예: `DIV > 10 ? 1024 : (1 << DIV[3:0])`.
- 최종 hardware connection에서 tri-state output enable이 필요한지, 아니면 active push-pull idle `0`이 맞는지.
- 기존 `reuse/` module을 compatibility 목적으로 유지할지, IP packaging 전에 `slave23_*` 이름으로 rename/versioning할지.

