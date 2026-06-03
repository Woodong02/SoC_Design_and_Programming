# AXI Register Map과 PS 제어/판독 흐름

## 요약

Master는 PS가 AXI-Lite register를 통해 설정하고 상태를 읽는 구조이다. Slave는 PL-only이므로 이 register map을 그대로 구현할 필요는 없지만, Master가 어떤 값으로 동작하는지와 PS가 어떤 상태를 의미 있게 해석하는지를 반드시 반영해야 한다.

## Register Map

확인됨:

| Offset | AXI index | Read value | Write source | 의미 |
|---:|---:|---|---|---|
| `0x00` | `5'h00` | `slv_reg0` | PS | Master timing/control 설정 |
| `0x04` | `5'h01` | `{12'b0, GPIO_in, clk_cnt, slot}` | PL | live input/slot/counter monitor |
| `0x08` | `5'h02` | `slv_reg2` | PS + PL | threshold + interrupt latch |
| `0x0C` | `5'h03` | `err_cnt0` | PL | node 0 error counters |
| `0x10` | `5'h04` | `err_cnt1` | PL | node 1 error counters |
| `0x14` | `5'h05` | `err_cnt2` | PL | node 2 error counters |
| `0x18` | `5'h06` | `err_cnt3` | PL | node 3 error counters |
| `0x1C` | `5'h07` | `err_cnt4` | PL | node 4 error counters |
| `0x20` | `5'h08` | `err_cnt5` | PL | node 5 error counters |
| `0x24` | `5'h09` | `err_cnt6` | PL | node 6 error counters |
| `0x28` | `5'h0A` | `err_cnt7` | PL | node 7 error counters |
| `0x2C` | `5'h0B` | `slot_out0` | PL | node 0 latest payload |
| `0x30` | `5'h0C` | `slot_out1` | PL | node 1 latest payload |
| `0x34` | `5'h0D` | `slot_out2` | PL | node 2 latest payload |
| `0x38` | `5'h0E` | `slot_out3` | PL | node 3 latest payload |
| `0x3C` | `5'h0F` | `slot_out4` | PL | node 4 latest payload |
| `0x40` | `5'h10` | `slot_out5` | PL | node 5 latest payload |
| `0x44` | `5'h11` | `slot_out6` | PL | node 6 latest payload |
| `0x48` | `5'h12` | `slot_out7` | PL | node 7 latest payload |
| `0x4C` | `5'h13` | `cycle_cnt[31:0]` | PL | cycle count low |
| `0x50` | `5'h14` | `cycle_cnt[63:32]` | PL | cycle count high |

주의:

- `slv_reg1`, `slv_reg3`..`slv_reg20`은 AXI write case에서 쓰기 자체는 가능하지만, read mux는 대부분 PL 내부 신호를 반환한다.
- 따라서 PS가 해당 offset에 값을 써도 Master 통신 상태를 제어하는 의미는 확인되지 않는다.

## `slv_reg0` bit field

확인됨:

| Bits | Name | Source | Meaning |
|---|---|---|---|
| `[9:0]` | `DIV` | PS write | bit period 설정값. PS는 실제 DIV에서 1을 뺀 값을 쓴다. |
| `[19:10]` | `GUARD_TICKS` | PS write | slot guard 길이 |
| `[22:20]` | `NODE_CNT` | PS write | 마지막 slot index. PS는 node 개수에서 1을 뺀 값을 쓴다. |
| `[23]` | `ENABLE` | PS write | master internal reset release |
| `[31:24]` | unused | - | 현재 decode 없음 |

PS 초기값:

- `DIV = 1024`; `SET_DIV()`는 register에 `1023`을 쓴다.
- `GUARD_TICKS = 256`.
- `NODE_CNT = 5`; `SET_NODE_CNT()`는 register에 `4`를 쓴다.
- `ENABLE = 1`.

확인된 구현 버그:

- `master_top`은 `DIV_p1`을 하위 모듈에 넘기지만 명시 선언이 보이지 않는다.
- Vivado smoke check에서 `DIV_p1` no-driver 및 `DIV[9:0]` unconnected warning이 확인되었다.
- Master 담당자 확인상 이것은 구현 버그이다.
- 의도는 `NODE_CNT`는 그대로 사용하고, `DIV`만 `DIV + 1`로 만들어 하위 timing module에 전달하는 것이다.
- 현재 source 그대로의 실제 timing은 의도한 PS 설정값과 다를 수 있으므로, slave 설계 기준은 원본 버그가 아니라 확인된 의도 사양을 따른다.

## `slv_reg2` bit field

확인됨:

| Bits | Name | Source | Meaning |
|---|---|---|---|
| `[7:0]` | `FAULT_TH` | PS write | halt 판정 threshold |
| `[15:8]` | `SILENT_TH` | PS write | silent 판정 threshold |
| `[23:16]` | silent interrupt latch | PL set, PS clear | node별 silent event |
| `[31:24]` | halt interrupt latch | PL set, PS clear | node별 halt event |

Reset value:

- `slv_reg2 <= 32'h0000FFFF`.
- 즉 reset 직후 `FAULT_TH = 255`, `SILENT_TH = 255`, interrupt latch는 0이다.
- `main.c` 초기화 이후 `FAULT_TH = 200`, `SILENT_TH = 200`이 된다.

Interrupt:

- `intr = |slv_reg2[31:16]`.
- `present_err = {halt_cmd[7:0], Silent_node[7:0]}`.
- `before_err <= present_err`, `after_err <= before_err`로 edge-like condition을 만들고 `before_err & ~after_err`를 latch한다.
- `ServiceRoutine()`은 `slv_reg2`를 읽은 뒤 `temp & 0x0000FFFF`를 다시 써서 `[31:16]` latch를 clear한다.

## PS에서 실제 사용하는 read

확인됨:

- Main loop는 offset `0x04`를 계속 읽는다.
  - `Data & 0x7`: 현재 `slot`.
  - `(Data >> 3) & 0xFFFF`: `clk_cnt`.
  - `(Data >> 19) & 0x1`: `GPIO_in`.
- `GPIO_in`이 1이면 현재 slot에 따라 TFTLCD에 node color 점을 찍는다.
- 이 LCD 표시는 부가 시각화이며, slave 요구사항의 기준은 `master_top` 내부 수신/fault logic이다.
- Interrupt service routine은 offset `0x08`, `0x4C`, `0x50`을 읽는다.
- UART command parser는 현재 주석 처리되어 있지만, 함수들은 register read/write 방식으로 남아 있다.

## Slave 요구사항으로 이어지는 의미

확인됨:

- Slave는 Master PS register map을 구현할 필요는 없다.
- 하지만 Master가 PS에서 설정받는 `DIV`, `GUARD_TICKS`, `NODE_CNT`, threshold가 실제 PL 동작을 결정하므로 slave는 이 값들과 호환되는 parameter/default를 가져야 한다.
- Master PS는 `slot_outN`의 payload bit 의미를 직접 자세히 해석하지 않고, fault/silent/halt event와 live GPIO activity를 주로 표시한다.

추론:

- Slave payload 32-bit는 향후 확장 가능 데이터 영역이다. 현재 Master fault 판정에는 `fixed_data[34:32]` address와 timing/Hamming 결과가 더 중요하다.
