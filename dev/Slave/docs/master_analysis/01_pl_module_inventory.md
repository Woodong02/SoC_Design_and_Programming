# Master PL 모듈 구조 분석

## 계층 구조

확인됨:

```text
Master_v1_0
└─ Master_v1_0_S00_AXI
   └─ master_top
      ├─ Master_slot
      ├─ Master_tx
      │  └─ hamming_enc
      ├─ Master_rx
      ├─ Master_dec_ham
      │  └─ hamming_dec
      └─ seven_seg
         └─ bin2seg
```

## `Master_v1_0`

확인됨:

- Vivado packaged IP top wrapper이다.
- 외부 PL pin과 AXI-Lite slave interface를 `Master_v1_0_S00_AXI`에 연결한다.
- 주요 외부 통신 pin:
  - `GPIO_in`: slave 측 송신 신호를 master가 수신하는 입력.
  - `GPIO_out`: master broadcast 송신 출력.
  - `LED_in`, `LED_out`: `GPIO_in`, `GPIO_out` 모니터용으로 직접 연결된다.

## `Master_v1_0_S00_AXI`

확인됨:

- AXI-Lite slave register interface와 user logic bridge 역할을 한다.
- 21개 32-bit slave register decode를 가진다.
- `slv_reg0`과 `slv_reg2[15:0]`는 PS가 설정값을 쓰는 주요 register이다.
- `master_top`에서 나온 `err_cnt*`, `slot_out*`, `cycle_cnt`, `Silent_node`, `halt_cmd`를 AXI read 또는 interrupt 상태로 노출한다.

## `master_top`

확인됨:

- Master 내부 통신/판정 logic의 top module이다.
- `ENABLE`과 `resetn_bt`를 AND하여 내부 reset `resetn`을 만든다.
- `Master_slot`이 slot index, slot boundary, `rx_stat`, `cycle_cnt`를 생성한다.
- `Master_tx`는 마지막 slot에서 master broadcast frame을 송신한다.
- `Master_rx`는 slave frame을 수신하여 42-bit codeword와 `preamble_err`를 만든다.
- `Master_dec_ham`은 Hamming decode, slot_out 갱신, fault counter 갱신을 담당한다.
- `data_bus`, `sig_bus`, `preamble_err`, `rx_stat`는 `master_top` 내부 연결 신호이며 AXI register로 직접 노출되지 않는다.

확인된 구현 버그:

- `DIV_p1`이 `Master_slot`, `Master_tx`, `Master_rx`에 전달되지만, 현재 `master_top` 내 명시적 선언이 보이지 않는다.
- Vivado 2019.1 smoke check 결과 `DIV_p1` net has no driver, `DIV[9:0]` unconnected port warning이 확인되었다.
- Master 담당자 확인상 의도는 PS가 `DIV-1` 값을 register에 쓰고 PL에서 `DIV+1`로 복원하는 것이다.
- 현재 `NODE_CNT_p1 = NODE_CNT + 1` 선언은 잘못 기입된 것이며, 하위 모듈에는 `NODE_CNT` 그대로와 `DIV + 1`이 전달되어야 한다.
- 따라서 분석상 의도 사양은 `DIV_effective = DIV + 1`, `slot = 0..NODE_CNT`로 둔다.

## `Master_slot`

확인됨:

- slot scheduler이다.
- `data_len_tick = 50 * DIV`.
- `total_tick = data_len_tick + GUARD_TICKS`.
- `clk_cnt == total_tick - 1`에서 slot을 증가시키고 `slot_change`를 1 cycle assert한다.
- `slot == NODE_CNT` 이후 다음 slot은 0으로 돌아가며 `cycle_cnt`가 증가한다.
- `slot_pre_change`는 `clk_cnt == total_tick - 2`에서 1 cycle assert된다.
- `rx_stat`는 현재 slot 내부 수신 timing window를 나타낸다.

## `Master_tx`

확인됨:

- master broadcast transmitter이다.
- frame은 `{8'hAA, codeword}` 총 50 bit이다.
- `codeword`는 `hamming_enc`로 생성한다.
- 실제 data field는 `d = {halt_cmd, GUARD_TICKS, 17'b0}`이다.
- 주석에는 `DIV`도 포함된다고 쓰였지만 실제 코드에는 `DIV`가 data field에 들어가지 않는다.
- `tx_trigger`가 들어오면 frame MSB부터 `GPIO_out`으로 NRZ 송신한다.
- idle일 때 `GPIO_out = 1'b0`이다.
- 주석에는 idle이 high-Z/released라고 되어 있으나 실제 구현은 high-Z가 아니다.

## `Master_rx`

확인됨:

- slave frame receiver이다.
- `GPIO_in`이 1이 되면 preamble 수신 상태로 진입한다.
- 이전 값을 저장해 edge를 검출하지 않고, `GPIO_in == 1` level을 시작 조건으로 쓴다.
- preamble은 `8'hAA`이다.
- preamble 이후 42-bit codeword를 수신한다.
- bit sample point는 `clk_cnt == DIV >> 1`이다.
- `slot_pre_change`가 들어오면 수신 state/counter가 reset된다.

## `Master_dec_ham`

확인됨:

- `hamming_dec`를 이용해 `data_in`을 `fixed_data`로 decode한다.
- `fixed_data[34:32]`를 slave/node address로 사용한다.
- `fixed_data[31:0]`를 해당 node의 `slot_outN`에 저장한다.
- `slot_outN` 갱신 대상은 현재 TDMA `slot`이 아니라 frame 내부 address인 `fixed_data[34:32]`로 결정된다.
- silent, preamble, hamming, slot timeout counter를 node별로 관리한다.
- counter pack 순서는 `{preamble_err_cnt, slot_timeout_cnt, hamming_err_cnt, silent_cnt}`이다.

## `hamming_enc` / `hamming_dec`

확인됨:

- 35-bit data를 42-bit SECDED codeword로 encoding/decoding한다.
- codeword format은 `{data[34:0], p[5:0], p_overall}`이다.
- decoder는 1-bit error correction과 2-bit error detection을 수행한다.

## Display helper

확인됨:

- `seven_seg`, `bin2seg`는 DIP switch에 따라 `slot_out` 또는 node status를 7-segment에 표시한다.
- slave 통신 프로토콜 자체에는 직접 영향이 없다.
