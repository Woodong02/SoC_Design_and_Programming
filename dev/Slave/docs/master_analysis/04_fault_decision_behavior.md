# Fault Decision 동작 분석

## Counter packing

확인됨:

각 node의 `err_cntN`은 다음 순서로 packing된다.

```verilog
err_cntN = {preamble_err_cntN, slot_timeout_cntN, hamming_err_cntN, silent_cntN};
```

PS `READ_ERR_CNT()`도 같은 순서로 해석한다.

| Bits | Counter |
|---|---|
| `[7:0]` | `silent_cnt` |
| `[15:8]` | `hamming_err_cnt` |
| `[23:16]` | `slot_timeout_cnt` |
| `[31:24]` | `preamble_err_cnt` |

## Silent counter

확인됨:

- `GPIO_in`이 어떤 slot에서든 1이면 해당 `slot`의 `received[slot]`가 1로 set된다.
- `slot_change && slot == 0`에서 모든 node의 `received` bitmap을 평가한다.
- `received[N] == 0`이고 `silent_cntN < SILENT_TH`이면 `silent_cntN += 6`.
- 그렇지 않고 `silent_cntN != 0`이면 `silent_cntN -= 1`.
- 이 평가 후 `received <= 0`으로 clear된다.

주의:

- Silent 판정은 valid frame이 아니라 해당 slot 중 `GPIO_in` activity 존재 여부를 기준으로 한다.
- `silent_cnt`는 `halt_cmd` 산출 합계에서는 제외된다.
- `silent_cnt` 감소는 `halt_cmd`와 무관하게 발생할 수 있다.

## Preamble error counter

확인됨:

- `Master_rx`가 preamble check 시점에 `buffer[7:0] != 8'hAA`이면 `preamble_err`를 1 cycle assert한다.
- `Master_dec_ham`은 `preamble_err`가 발생한 현재 `slot`의 `preamble_err_cnt`를 `+6`한다.
- `slot_change && slot == 0`에서 각 preamble counter가 0보다 크고 해당 node가 halt 상태가 아니면 `-1`한다.

Chart 대조:

- 전사 문서에는 preamble error가 `+1`로 적혀 있었으나 현재 구현은 `+6`이다. chart 판독 오류이거나 구현 변경 가능성이 있다.

## Hamming error counter와 frame discard

확인됨:

- `hamming_dec`는 `ham_1bit_err`, `ham_2bit_err`, `fixed_data`를 생성한다.
- `in_sig`가 들어왔을 때 `ham_2bit_err == 0`이면 Master는 `slot_out[fixed_data[34:32]] <= fixed_data[31:0]`로 payload를 저장한다.
- 이때 `ham_1bit_err == 1`이면 해당 node의 `hamming_err_cnt += 4`.
- `ham_2bit_err == 1`이면 `slot_out`은 갱신하지 않고 해당 node의 `hamming_err_cnt += 8`.
- `slot_change && slot == 0`에서 해당 node가 halt 상태가 아니면 hamming counter는 0까지 `-1`로 decay된다.

Frame discard:

- 2-bit Hamming error frame은 `slot_out`을 갱신하지 않으므로 폐기된다.
- 1-bit Hamming error frame은 corrected `fixed_data`로 `slot_out`이 갱신되므로 폐기되지 않는다.
- `slot_out` 갱신 대상은 현재 `slot`이 아니라 `fixed_data[34:32]` address이다. 이 점은 fault chart의 "다른 슬롯이더라도 ... slv_addr 비트" 메모와 일치한다.

## Slot timeout counter

확인됨:

```text
severe_err = (rx_stat == 2) || (fixed_data[34:32] != slot)
weak_err   = (rx_stat == 1)
```

- `in_sig` 시 decoded address `fixed_data[34:32]`가 가리키는 node counter를 갱신한다.
- `severe_err`이면 해당 node의 `slot_timeout_cnt <= 255`.
- `weak_err`이면 해당 node의 `slot_timeout_cnt += 6`.
- 정상이고 counter가 0보다 크며 해당 node가 halt 상태가 아니면 `-1`한다.

해석:

- 현재 slot과 frame address가 다르면 즉시 severe slot timeout/invasion으로 본다.
- frame 완료 시점이 data window 내부이면 severe error이다.
- frame 완료 시점이 guard edge 부근이면 weak error이다.
- severe/weak slot timeout counter의 갱신 대상도 frame 내부 address인 `fixed_data[34:32]` 기준이다.

## Halt command

확인됨:

`master_top`의 `halt_cmd[N]`:

```text
halt_cmd[N] = (preamble_err_cntN + slot_timeout_cntN + hamming_err_cntN) > FAULT_TH
```

- `silent_cnt`는 halt 합계에서 제외된다.
- PS 초기 설정 기준 `FAULT_TH = 200`.
- `halt_cmd`는 `Master_tx` broadcast frame의 상위 8-bit field로 전송된다.

Chart 대조:

- 전사 문서의 halt equation은 silent까지 포함하는 것으로 적혀 있었으나, 현재 구현은 silent를 제외한다. `Master_top.v` 주석에도 `except silent_cnt!!`가 있다.

## Silent_node와 interrupt

확인됨:

`Silent_node[N] = (silent_cntN > SILENT_TH)`.

`present_err` packing:

```text
present_err[7:0]   = Silent_node[7:0]
present_err[15:8]  = halt_cmd[7:0]
```

`slv_reg2[31:16]` latch:

| Bits | Meaning |
|---|---|
| `[23:16]` | Silent event bits for node 0..7 |
| `[31:24]` | Halt event bits for node 0..7 |

PS `ServiceRoutine()`:

- offset `0x08`를 읽어 interrupt latch를 확인한다.
- `temp & 0x0000FFFF`를 다시 써서 interrupt latch를 clear한다.
- `[24+i]`가 1이면 `Node i is Halted.`
- `[16+i]`가 1이면 `Node i is Silent.`

## 미확인/검증 필요

- `preamble_err_cnt += 6`이 chart의 최종 의도와 완전히 일치하는지 구현자 확인 또는 chart 재판독이 필요하다.
- counter overflow protection이 모든 counter에 있는 것은 아니다. `silent_cnt`는 threshold 조건이 있으나, preamble/hamming/weak slot increment는 8-bit overflow 가능성이 있다.
- `ham_2bit_err`가 있을 때도 `fixed_data[34:32]`로 node를 선택한다. 2-bit error 상황에서 address field 신뢰성이 낮을 수 있다.
- `slot_timeout_cnt` 감소는 정상 `in_sig`가 들어오는 경우에만 발생한다. chart 전사본의 일반적 "cycle마다 감소"와는 다르다.
