# Slave 2.3 Passive Current RTL Specification

## 1. Scope

This document describes the implementation that currently exists in this repository.

Current RTL goal:

- Observe the master-to-slave serial line.
- Use the first rising edge of a master broadcast frame as the timing reference.
- Decode the master broadcast to learn the halt command for this slave.
- Transmit one fixed-format response frame in this slave's TDMA slot unless halted.

Out of scope in the current RTL:

- Runtime node selection.
- Runtime active-slot selection.
- Runtime `DIV` or `GUARD_TICKS` writes.
- Recovery, holdover, rate correction, or fault-management FSM.
- Shared-bus tri-state or output-enable control.

## 2. Source File Roles

| File | Role | Current status |
| --- | --- | --- |
| `slave23_passive_top.v` | Top-level passive slave controller. Detects master frame start, runs slot timer, latches halt state, triggers response TX. | Implemented |
| `reuse/slave21_rx.v` | Serial frame receiver reused for master broadcast. Detects preamble, samples 42-bit codeword, emits valid/done/error pulses. | Implemented |
| `reuse/slave21_tx.v` | Serial response transmitter reused from prior slave design. Builds and sends `8'hAA + 42-bit codeword`. | Implemented |
| `reuse/slave_hamming_enc.v` | Master-compatible systematic Hamming SECDED encoder for 35-bit data to 42-bit codeword. | Implemented |
| `reuse/slave_hamming_dec.v` | Master-compatible Hamming SECDED decoder for broadcast codeword. Corrects selected 1-bit data errors and flags 2-bit errors. | Implemented |
| `slave_regmap.md` | Future PS-visible register request. | Documentation only, not implemented in RTL |
| `constraints/slave23_passive_fpga_top.xdc` | Board pin constraints for a wrapper named `slave23_passive_fpga_top`. | Constraint file exists; wrapper source is not present |

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

| Parameter | Width | Default | Meaning |
| --- | ---: | ---: | --- |
| `NODE_ID` | 3 | `0` | Slave node/slot id encoded into responses and used to index `halt_cmd`. |
| `DIV` | 4 | `10` | Bit period exponent. Current RTL computes `BIT_PERIOD = 1 << DIV`. |
| `GUARD_TICKS` | 10 | `256` | Guard interval used in local response-slot timing. |

Important limitation: `DIV` and `GUARD_TICKS` are compile/elaboration-time parameters in the current RTL. They are not loaded from the master broadcast or PS registers.

### Ports

| Port | Direction | Meaning |
| --- | --- | --- |
| `i_CLK` | input | System clock. Constraint file describes a 25 MHz board clock. |
| `i_RESETN` | input | Active-low asynchronous reset used by all implemented sequential blocks. |
| `i_MASTER_SERIAL` | input | Master-to-slave serial broadcast line. Idle is expected to be `0`. |
| `i_PAYLOAD[31:0]` | input | Response payload included in the slave frame. Sampled by `slave21_tx` when TX starts. |
| `o_SLAVE_SERIAL` | output | Slave-to-master serial response line. Idle is actively driven `0`. |
| `o_HALTED` | output | Latched halt state for `NODE_ID`, updated only from valid broadcasts. |
| `o_TX_ACTIVE` | output | High while `slave21_tx` is sending the 50-bit response frame. |
| `o_SYNCED` | output | High whenever top FSM is not waiting for the next master start edge. |

## 4. Frame Formats

### Master Broadcast Frame

The current receiver expects:

```text
50 bits total = 8'hAA preamble + 42-bit Hamming SECDED codeword
```

Decoded broadcast data layout:

```text
decoded_broadcast_data[34:27] = halt_cmd[7:0]
decoded_broadcast_data[26:17] = broadcast guard ticks
decoded_broadcast_data[16:0]  = reserved / zero by master convention
```

Current RTL only uses `decoded_broadcast_data[34:27]`. The decoded broadcast guard field is not used for timing; the local `GUARD_TICKS` parameter is used instead.

### Slave Response Frame

`slave21_tx` sends:

```text
50 bits total = 8'hAA preamble + hamming_enc({NODE_ID[2:0], i_PAYLOAD[31:0]})
```

The frame is sent MSB-first. Idle output is `0`.

## 5. Timing Model

Current top-level timing equations:

```text
BIT_PERIOD      = 1 << DIV
frame_ticks     = 50 * BIT_PERIOD
slot_ticks      = frame_ticks + GUARD_TICKS
node_offset     = NODE_ID * slot_ticks
tx_start_ticks  = frame_ticks + node_offset
```

The top FSM starts `sync_timer_ff` when it sees a rising edge on `i_MASTER_SERIAL` while in `P23_WAIT_START`. On that same cycle, the next timer value is set to `1`, so the first detected master `1` is counted as the first tick of the frame reference.

TX trigger condition:

```text
state_ff == P23_WAIT_TX
sync_timer_ff == tx_start_ticks
halted_ff == 0
```

If `halted_ff == 1` at the target tick, the FSM returns to `P23_WAIT_START` without starting TX.

## 6. `slave23_passive_top` Behavior

### FSM States

| State | Encoding | Meaning |
| --- | ---: | --- |
| `P23_WAIT_START` | `2'd0` | Wait for a `0 -> 1` transition on `i_MASTER_SERIAL`. |
| `P23_WAIT_TX` | `2'd1` | Count from the detected master frame start until this node's response slot. |
| `P23_TX` | `2'd2` | Wait while `slave21_tx` sends the response. |

### Start Detection

`top_master_rise` is true only when:

```text
state_ff == P23_WAIT_START
serial_prev_ff == 0
master_serial == 1
tx_active == 0
```

This prevents later rising edges inside the same master frame from restarting the top-level slot timer.

### Halt Latch

The receiver and decoder run continuously. When `broadcast_valid` is true, top latches:

```text
halted_ff <= halt_cmd[NODE_ID]
```

`broadcast_valid` is currently:

```text
rx_codeword_valid & ~ham_2bit_err
```

Preamble status outputs from `slave21_rx` are instantiated but not used by top-level logic. Since `rx_codeword_valid` is only generated after a successful preamble path in `slave21_rx`, this is functionally sufficient for the current receiver implementation.

### Reset Behavior

On `i_RESETN == 0`:

- Top FSM returns to `P23_WAIT_START`.
- Previous serial sample clears to `0`.
- Sync timer clears to `0`.
- Halt latch clears to `0`.
- TX and RX child modules also reset to idle through their own reset logic.

## 7. `slave21_rx` Behavior

Purpose: receive the master broadcast serial frame.

Inputs:

- `i_SERIAL_IN`: serial input.
- `i_BIT_PERIOD`: bit period in clock ticks. A value of `0` is normalized to `1`.

Outputs:

- `o_CODEWORD[41:0]`: captured codeword after a valid preamble and full codeword reception.
- `o_CODEWORD_VALID`: one-clock pulse when a 42-bit codeword has just been captured.
- `o_FRAME_DONE`: one-clock pulse on codeword completion or preamble failure.
- `o_PREAMBLE_OK`: one-clock pulse when `8'hAA` preamble is recognized.
- `o_PREAMBLE_ERR`: one-clock pulse when the first 8 sampled bits are not `8'hAA`.
- `o_RX_ACTIVE`: high during preamble, codeword, or error-drain states.

FSM:

| State | Meaning |
| --- | --- |
| `RX21_IDLE` | Wait for serial rising edge. |
| `RX21_PREAMBLE` | Sample 8 preamble bits. |
| `RX21_CODEWORD` | Sample 42 codeword bits. |
| `RX21_DONE` | Return to idle after successful frame capture. |
| `RX21_ERROR` | Drain the rest of the expected codeword period after preamble failure. |

Sampling:

- Start candidate is a `0 -> 1` transition while idle.
- `i_BIT_PERIOD == 0` is treated as `1`.
- For periods greater than 1, first sampling is delayed by roughly half a bit period:
  - `start_sample_delay = (i_BIT_PERIOD >> 1) - 1`, clamped to `0`.
- Subsequent samples occur every stored `period_snapshot_ff` ticks.
- Bits shift MSB-first into preamble and codeword shift registers.

## 8. `slave21_tx` Behavior

Purpose: transmit the slave response serial frame.

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

| State | Meaning |
| --- | --- |
| `TX21_IDLE` | Wait for `i_TX_TRIGGER & i_TX_ENABLE`. |
| `TX21_ACTIVE` | Drive 50 frame bits MSB-first. |
| `TX21_DONE` | Emit done pulse and return to idle. |

Timing:

- `i_BIT_PERIOD == 0` is normalized to `1`.
- On start, bit 49 of `tx_frame` is driven first.
- Each bit is held for `bit_period_sanitized` clocks.
- After the last bit completes, output returns to `0`.
- Starts asserted while active are ignored because `start_request` is only valid in `TX21_IDLE`.

## 9. Hamming SECDED Modules

### Encoder

Module: `slave_hamming_enc`

```text
o_CODEWORD[41:7] = i_DATA[34:0]
o_CODEWORD[6:1]  = {p5, p4, p3, p2, p1, p0}
o_CODEWORD[0]    = p_overall
```

`p_overall` is the XOR reduction of data and the six parity bits.

### Decoder

Module: `slave_hamming_dec`

Behavior:

- Splits `i_CODEWORD[41:7]` as data and `[6:1]` as parity.
- Recomputes six parity checks.
- Builds a 6-bit syndrome.
- Uses `^i_CODEWORD` as overall parity.
- Flags:
  - `o_HAM_1BIT_ERR = syndrome != 0 && overall parity mismatch`
  - `o_HAM_2BIT_ERR = syndrome != 0 && no overall parity mismatch`
- For 1-bit errors with syndrome values in `1..35`, the decoder flips `corrected_data[syndrome - 1]`, except syndrome values `1, 2, 4, 8, 16, 32`, which are treated as parity-bit errors by comment and are not data-corrected.

Note: This correction policy is intentionally described as current behavior. Before changing it, compare against the master-side encoder/decoder vectors.

## 10. Current Implementation Summary

- The design is a minimal passive slave for master verification.
- Frame size is 50 bits: `8'hAA + 42-bit Hamming codeword`.
- Slave response data is `{NODE_ID, PAYLOAD}`.
- Master broadcast halt command suppresses slave TX for the matching node.
- Recovery, holdover, rate correction, and fault FSMs are not implemented.
- Timing target uses `50*BIT_PERIOD + NODE_ID*(50*BIT_PERIOD + GUARD_TICKS)`.

### Future Integration Items

- `slave_regmap.md` requests PS registers (`ENABLE`, `DIV`, `ACTIVE_SLOT`, `data_out0..5`), but no register interface exists in current RTL.
- Current RTL ignores decoded broadcast `GUARD_TICKS` and uses the parameter `GUARD_TICKS`.
- The current top module has parameterized `NODE_ID`, not runtime `i_NODE_ID`.
- The current top module has parameterized `DIV`, not runtime `i_BIT_PERIOD` or PS `DIV`.
- The constraint file references `slave23_passive_fpga_top`, but the current repository file list only contains `slave23_passive_top.v`.

## 11. Integration Implications For IP Conversion

To convert this design into a configurable IP matching `slave_regmap.md`, the likely first changes are:

- Convert or wrap `DIV`, `GUARD_TICKS`, and `NODE_ID` from parameters to runtime inputs where needed.
- Add `ENABLE` gating so the slave can ignore master input and hold TX idle when disabled.
- Implement `ACTIVE_SLOT` behavior if one hardware instance must emulate multiple node slots.
- Map `data_out0..5` to payload selection logic.
- Decide how PL-only slots 6 and 7 provide payloads and whether PS can still control their active bits.
- Add or restore simulation sources so register and timing behavior can be verified before packaging.

## 12. Open Questions

- Should the IP expose one physical slave node, or emulate multiple active slots from one hardware instance?
- Should `GUARD_TICKS` always come from PS registers, from decoded master broadcast, or from a selectable source?
- Should `DIV` follow the master's `DIV_ticks` rule exactly, including `DIV > 10 ? 1024 : (1 << DIV[3:0])` behavior?
- Is a tri-state output enable required at board/IP boundary, or is active push-pull idle `0` correct for the final hardware connection?
- Should the existing `reuse/` modules remain as-is for compatibility, or should they be renamed/versioned as `slave23_*` before IP packaging?
