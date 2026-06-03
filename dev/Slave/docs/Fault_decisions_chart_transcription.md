# Fault Decisions Chart Transcription

Source image: `../Fault_decisions_chart.jpg`

This document is a best-effort transcription and cleanup of the handwritten fault decision chart.

User confirmation: this fault decision chart is the final confirmed behavior, and the master-side fault handling is implemented to match it. If a detail is unclear in this transcription, verify it against the master source code.

## High-Level Meaning

The chart describes master-side error detection for each TDMA timeslot.

For each timeslot, the receiver checks:

1. Whether `GPIO_in` indicates any incoming signal.
2. Whether the preamble is valid.
3. Whether the Hamming check reports an error.
4. Whether the frame timing falls inside the expected slot window.

Several error counters are accumulated. A global halt decision is derived from their sum:

```verilog
halt = (silent_cnt + preamble_err_cnt + hamming_err_cnt + slot_timeout_cnt) > 200 ? 1 : 0;
```

The comparison threshold appears to be `200`.

## Per-Timeslot Decision Flow

### 1. Signal Presence Check

Decision:

```text
GPIO_in 감지?
```

If no signal is detected:

```text
silent_cnt += 6
```

If signal is detected, continue to preamble check.

### 2. Preamble Check

Decision:

```text
preamble 검사
```

If preamble is invalid:

```text
preamble_err_cnt += 1
```

The handwritten note says:

```text
(연쇄 작용 가능성)
```

Interpretation: a preamble error may cascade into additional downstream errors if the frame parser continues or loses alignment.

The invalid preamble path points to:

```text
프레임 폐기
```

If preamble is valid, continue to Hamming check.

### 3. Hamming Check

Decision:

```text
hamming 검사
```

If no Hamming error:

```text
clk_cnt 및 slot 비교
```

If a 1-bit Hamming error is detected:

```text
hamming_err_cnt += 4
```

If a 2-bit-or-more Hamming error is detected:

```text
hamming_err_cnt += 8
```

The 2-bit-or-more path points to:

```text
프레임 폐기
```

The 1-bit error path appears to continue toward timing/slot validation, implying that the frame may still be usable after correction. This should be confirmed in source.

### 4. Slot Timing Check

After a valid preamble and acceptable Hamming result, compare:

```text
clk_cnt 및 slot 비교
```

The chart draws an expected frame inside a timeslot:

```text
time slot
  expected first edge
  expected frame
```

The expected first edge appears to be placed after a fraction of the slot/guard interval. The handwritten marks around the timing diagram look like fractional divisions, but the exact values are uncertain from the image.

If timing is outside the valid slot window:

```text
time_out_cnt += 6
```

If the frame is inside the expected slot window:

```text
slot_out 정상수신 완료
```

## Timeout / Critical Invasion Note

The chart includes:

```text
time_out_cnt = 8'd255
critical invasion
```

Interpretation: in a severe slot invasion case, the timeout counter may be forced directly to `255` rather than incremented by `6`.

This likely corresponds to a slave transmitting in another slave's slot or otherwise invading a critical timing region.

## Frame Discard Policy

The chart explicitly sends these paths to `프레임 폐기`:

| Condition | Action |
|-----------|--------|
| invalid preamble | discard frame |
| Hamming 2-bit-or-more error | discard frame |

The chart also contains a red note:

```text
현재: 폐기하지 않음
```

This is connected near the lower timing/slot logic, not the main preamble/Hamming discard arrows. Best-effort interpretation:

- Some slot-out or address-related error path may currently not discard the frame in implementation.
- The intended policy may be under debate.

This must be checked against `Master_ip/Master_rx.v`, `Master_ip/error_with_hamming.v`, and `Master_ip/Master_top.v`.

## Other-Slot Error Note

The red handwritten note says:

```text
다른 슬롯이더라도 hamming 1비트이하 오류시 slot_out
(slv_addr 비트에 의한)
```

Best-effort interpretation:

- Even if a received frame appears in another slot, if the Hamming result is clean or correctable to within 1 bit, the system may identify the sender from the `slv_addr` field.
- The slot-out decision may then be assigned using the slave address bits rather than only the current slot index.
- This may be related to detecting which slave invaded another slot.

This part is uncertain and should be verified from implementation.

## Counter Summary

| Counter | Increment / Assignment | Trigger |
|---------|------------------------|---------|
| `silent_cnt` | `+6` | no signal detected in timeslot |
| `preamble_err_cnt` | `+1` | signal exists but preamble invalid |
| `hamming_err_cnt` | `+4` | Hamming 1-bit error |
| `hamming_err_cnt` | `+8` | Hamming 2-bit-or-more error |
| `time_out_cnt` or `slot_timeout_cnt` | `+6` | frame timing outside expected slot window |
| `time_out_cnt` or `slot_timeout_cnt` | `8'd255` | critical invasion |

The image uses both `time_out_cnt` and the halt equation's `slot_timeout_cnt`. These may refer to the same counter, but that is not confirmed.

## Open Questions

1. Are `time_out_cnt` and `slot_timeout_cnt` the same signal?
2. Does a corrected 1-bit Hamming error allow the frame to continue into slot/address validation?
3. Which exact timing boundaries define the expected first edge and expected frame window?
4. What condition forces `time_out_cnt = 8'd255`?
5. Does slot invasion cause immediate halt/shutdown, or only a counter increase?
6. Which error paths discard the frame in the actual master source?
7. Does the current implementation intentionally avoid discarding some slot-out frames?

## Source Files to Check Next

The following files are likely relevant:

- `Master_ip/Master_rx.v`
- `Master_ip/error_with_hamming.v`
- `Master_ip/Master_slot.v`
- `Master_ip/Master_top.v`
- `Master_ip/Master_v1_0_S00_AXI.v`
- `Master_ps/main.c`
