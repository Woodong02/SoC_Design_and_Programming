# Implementation Decisions

This file records implementation choices made while moving from the planning documents to RTL. Keep the history light and current; when a decision is superseded, update the relevant entry instead of preserving stale alternatives.

## 2026-06-05: TX Path Leaf Timing

- `slave_tx_serializer` uses `i_CFG_BIT_PERIOD_RELOAD` directly as the bit timer reload value.
- Therefore one serial bit is held for `reload + 1` `i_CLK` cycles.
- This matches the project rule that PS writes `DIV_REG = actual_bit_period_ticks - 1`.

## 2026-06-05: Invalid Payload Slot Handling

- `slave_frame_builder` consumes a command with `o_TX_CMD_SKIP` when the selected payload is invalid.
- `slave_slot_sequencer` treats that skip as a completed slot and advances to the next slot.
- This keeps the slot cycle moving and leaves the invalid-payload fault/event path observable through the status/event block.

## 2026-06-05: Slot Sequencer Command Latency

- `slave_slot_sequencer` registers the transition from a `slot_time_match` pulse to `o_TX_CMD_VALID`.
- The command is issued one clock after the scheduler match.
- This is intentional for setup margin and matches the user allowance that a few operation-clock delays are acceptable.
- The top-level IP requires `GUARD_TICKS >= 4` for scheduled TX.
- If `GUARD_TICKS < 4`, the top-level IP latches `FAULT_SLOT_TIMING_INVALID` and blocks sync scheduling/TX.
- This follows the intended policy that very small guard values are configuration errors, rather than forcing the TX path into zero-margin back-to-back operation.

## 2026-06-05: Sync Detection During Broadcast RX

- `slave_sync_detector` masks new sync pulses while broadcast RX is active.
- This prevents rising edges inside the `8'hAA + codeword` broadcast frame from restarting the slot scheduler.
- The scheduler therefore keeps a single timing origin: the first valid idle rising edge of the master broadcast frame.

## 2026-06-05: Scheduler Idle Return

- `slave_timing_scheduler` takes `cycle_done` from `slave_slot_sequencer`.
- `schedule_active` clears when the sequencer finishes scanning slots 0..7.
- This makes `core_idle` true again after a cycle finishes.

## 2026-06-05: Halt Mask Snapshot Timing

- The top-level sequencer input uses `halt_mask_pending_ff` at the next sync boundary.
- `halt_mask_applied_ff` remains the status-facing copy that updates on the same boundary.
- This matches the documented policy that a halt decoded in one master broadcast affects the following sync cycle, not the partially decoded current cycle.

## 2026-06-05: Legacy Master Simulation Wrapper

- The checked-in `Master_source/master_top` keeps `DIV_p1` as a 3-bit wire and connects it to 10-bit child-module `DIV` ports.
- ModelSim expands the missing upper bits as unknown in this connection, so `Master_slot.total_tick` becomes `X` and the original `master_top` cannot drive a reliable communication TB as-is.
- The legacy communication TB therefore instantiates the original leaf modules (`Master_slot`, `Master_tx`, `Master_rx`, `Master_dec_ham`) through a local fixed wrapper with a 10-bit `DIV_p1`.
- The legacy source files remain unmodified. This wrapper is a simulation harness decision, not a protocol change.
