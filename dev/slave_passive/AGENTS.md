# AGENTS.md

## Working Rules

- Follow the local Verilog style in `Verilog_CODING_STANDARDS.md` unless an existing file already establishes a stronger local pattern.
- Keep input ports copied to internal wires before use, and drive output ports from internal signals.
- Prefer `assign` for simple combinational paths and keep sequential register groups separated by purpose.
- Do not rename public ports, parameters, or module names unless the integration target requires it and the documentation is updated in the same change.
- Preserve compatibility with the current master frame format unless the master protocol is explicitly changed:
  - Master broadcast: `8'hAA + hamming_enc({halt_cmd[7:0], GUARD_TICKS[9:0], 17'b0})`
  - Current slave response: `8'hAA + hamming_enc({NODE_ID[2:0], PAYLOAD[31:0]})`
  - Next slave AXI IP response: `8'hAA + hamming_enc({slot_id[2:0], payload[31:0]})`
- Treat `reuse/` modules as compatibility modules. If their behavior changes, update the current specification and add focused verification notes.
- When making IP packaging or AXI/register-map changes, reconcile the implementation with `slave_regmap.md` and document any intentional differences.
- For the next AXI IP design, treat `slave_regmap.md` and `docs/10_*` through `docs/17_*` as the design direction. The current RTL spec remains evidence for legacy behavior, not the target behavior.
- Keep timing formulas consistent across all new documents and RTL comments:
  - `bit_period_ticks = DIV_REG + 1`
  - `frame_ticks = 50 * bit_period_ticks`
  - `slot_ticks = frame_ticks + GUARD_TICKS`
  - `tx_start[n] = frame_ticks + n * slot_ticks + (GUARD_TICKS >> 1)`
- Use 33-bit internal width for `bit_period_ticks` and 64-bit internal width for frame/slot/target tick calculations unless a documented implementation bound is introduced.
- PS raw register writes commit to core shadow only on safe idle boundaries. A write completing on the same clock as a sync edge is not part of that sync cycle.
- TX command paths should use ready/valid or equivalent accept/skip handshakes; do not silently drop active slots.
- Prefer FSM, LUT, and table-based structures for slot scheduling and payload selection so full-case testbenches can observe and cover each state directly.
- Use code comments generously at module boundaries, FSM sections, timing formula sections, and register field decode sections. Avoid historical commentary in code.

## Project Facts Learned

- Current top RTL is `slave23_passive_top.v`.
- The design is a minimal passive slave for master verification, not a full recovery/holdover/rate-correction slave.
- `slave23_passive_top` instantiates:
  - `reuse/slave21_rx.v` for master broadcast frame reception.
  - `reuse/slave_hamming_dec.v` for broadcast SECDED decode.
  - `reuse/slave21_tx.v` for slave response transmission.
  - `reuse/slave_hamming_enc.v` indirectly through `slave21_tx`.
- Timing is parameter driven:
  - `BIT_PERIOD = 1 << DIV`
  - `frame_ticks = 50 * BIT_PERIOD`
  - `slot_ticks = frame_ticks + GUARD_TICKS`
  - `tx_start_ticks = frame_ticks + NODE_ID * slot_ticks`
- The current RTL does not expose the PS register map in `slave_regmap.md`; `ENABLE`, runtime `DIV`, runtime `GUARD_TICKS`, and `ACTIVE_SLOT` are future integration requirements.
- The current RTL uses decoded `halt_cmd[NODE_ID]` only to latch `o_HALTED` and suppress the next response when the decoded broadcast is valid.
- `constraints/slave23_passive_fpga_top.xdc` describes board pins for a wrapper named `slave23_passive_fpga_top`, but that wrapper is not present in the current file list.

## Next AXI IP Direction

- The next IP is a PL module controlled by PS through AXI-Lite.
- One IP instance emulates up to eight virtual slave slots.
- `CTRL.ACTIVE_SLOT[7:0]` selects which slots can transmit.
- Slot 0 through 5 payloads come from `DATA_OUT0` through `DATA_OUT5`.
- Slot 6 and 7 payloads come from PL internal payload ports, with valid indicators.
- `DIV_REG` is not an exponent. The applied bit period is `DIV_REG + 1`, so raw zero means one clock tick per bit.
- `GUARD_TICKS` means the total non-transmitting guard time inside one slot. TX starts after `GUARD_TICKS >> 1`; odd LSB is dropped from the front guard.
- Runtime configuration is snapshot at sync boundary. A sync cycle should use a stable shadow copy of `DIV`, `GUARD_TICKS`, `ACTIVE_SLOT`, and payload values.
- Broadcast guard field is not the timing source for the next IP. PS register `CTRL.GUARD_TICKS` is the timing source.
- Broadcast halt compatibility is retained in v1. Decoded halt masks apply on the next sync cycle to avoid slot 0 decode-latency races.
