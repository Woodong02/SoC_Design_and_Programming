# AGENTS.md

## Working Rules

- Follow the local Verilog style in `Verilog_CODING_STANDARDS.md` unless an existing file already establishes a stronger local pattern.
- Keep input ports copied to internal wires before use, and drive output ports from internal signals.
- Prefer `assign` for simple combinational paths and keep sequential register groups separated by purpose.
- Do not rename public ports, parameters, or module names unless the integration target requires it and the documentation is updated in the same change.
- Preserve compatibility with the current master frame format unless the master protocol is explicitly changed:
  - Master broadcast: `8'hAA + hamming_enc({halt_cmd[7:0], GUARD_TICKS[9:0], 17'b0})`
  - Current slave response: `8'hAA + hamming_enc({NODE_ID[2:0], PAYLOAD[31:0]})`
- Treat `reuse/` modules as compatibility modules. If their behavior changes, update the current specification and add focused verification notes.
- Keep timing formulas consistent across all new documents and RTL comments:
  - `bit_period_ticks = DIV_REG + 1`
  - `frame_ticks = 50 * bit_period_ticks`
  - `slot_ticks = frame_ticks + GUARD_TICKS`
  - `tx_start[n] = frame_ticks + n * slot_ticks + (GUARD_TICKS >> 1)`
- Use 33-bit internal width for `bit_period_ticks` and 64-bit internal width for frame/slot/target tick calculations unless a documented implementation bound is introduced.
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
- The current RTL does not expose a PS register map; `ENABLE`, runtime `DIV`, runtime `GUARD_TICKS`, and `ACTIVE_SLOT` are future integration requirements.
- The current RTL uses decoded `halt_cmd[NODE_ID]` only to latch `o_HALTED` and suppress the next response when the decoded broadcast is valid.
- `constraints/slave23_passive_fpga_top.xdc` describes board pins for a wrapper named `slave23_passive_fpga_top`, but that wrapper is not present in the current file list.

