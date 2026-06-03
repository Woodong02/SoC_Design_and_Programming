# Master 작동 프로토콜과 통신 프로토콜

## 전체 동작 단위

확인됨:

- Master는 TDMA slot을 순환한다.
- 각 slot 길이는 다음과 같다.

```text
data_len_tick = 50 * DIV
total_tick    = data_len_tick + GUARD_TICKS
```

- slot index는 `0`부터 `NODE_CNT`까지 순환한다.
- `NODE_CNT`는 PS에서 node 개수보다 1 작은 값으로 기록된다.
- `slot == NODE_CNT`의 slot 말미에 master broadcast 송신 trigger가 발생한다.

정정:

- 현재 source에는 `DIV_p1` 미선언 버그가 있으나, Master 담당자 확인상 의도된 effective bit period는 `DIV + 1`이다.
- `NODE_CNT + 1` 선언은 잘못된 기입이며, slot scheduler에는 `NODE_CNT`가 그대로 들어가야 한다.

## 물리 계층

확인됨:

- `GPIO_out`과 `GPIO_in`은 단일 bit NRZ 신호로 사용된다.
- `Master_tx`는 active 동안 `GPIO_out`을 frame bit 값으로 drive하고, idle 동안 `0`을 drive한다.
- `Master_rx`는 `GPIO_in == 1` level을 frame 시작 후보로 사용한다. 별도 rising-edge detector는 없다.
- sample point는 bit period 중앙인 `DIV >> 1`이다.
- 기존 문서 일부의 Manchester 또는 `0x55` preamble 흔적과 달리 현재 구현 기준은 NRZ + `8'hAA`이다.

미확인:

- 실제 board 간 연결에서 line idle이 pull-down인지, 양방향 bus인지, 충돌 방지 회로가 있는지는 현재 XDC/Verilog만으로는 확정되지 않는다.
- `Master_top`의 `DIV_p1` 미선언은 확인된 구현 버그이다. 프로토콜 사양은 담당자 확인에 따라 `DIV_effective = DIV + 1`을 기준으로 정리한다.

## Master broadcast frame

확인됨:

```text
50-bit frame = 8-bit preamble + 42-bit codeword
preamble     = 8'hAA
codeword     = hamming_enc(data[34:0])
```

`Master_tx`의 실제 data field:

```verilog
wire [34:0] d = {halt_cmd, GUARD_TICKS, 17'b0};
```

따라서 master broadcast payload 배치는 다음과 같이 확인된다.

| Data bits | Meaning |
|---|---|
| `[34:27]` | `halt_cmd[7:0]` |
| `[26:17]` | `GUARD_TICKS[9:0]` |
| `[16:0]` | zero reserved |

중요 불일치:

- `Master_tx` 주석에는 `d[34:0] = {halt_cmd, GUARD_TICKS, DIV, 17'b0}`라고 적혀 있으나, 실제 코드는 `DIV`를 포함하지 않는다.
- Slave 요구사항은 실제 코드를 기준으로 한다. 즉 slave는 master broadcast에서 `halt_cmd`와 `GUARD_TICKS`를 decode할 수 있어야 하고, `DIV` 수신은 현재 master 구현 기준으로 불가능하다.

## Slave response frame

확인됨:

`Master_rx`와 `Master_dec_ham` 기준으로 slave가 보내야 하는 frame도 다음 구조를 따라야 한다.

```text
50-bit frame = 8'hAA + 42-bit SECDED codeword
codeword     = hamming_enc(slave_data[34:0])
```

`Master_dec_ham`은 decoded `fixed_data`를 다음처럼 해석한다.

| Data bits | Meaning |
|---|---|
| `[34:32]` | slave/node address |
| `[31:0]` | node payload, `slot_outN`으로 저장 |

Slave requirement:

- Slave parameter `NODE_ID`는 `fixed_data[34:32]`로 송신되어야 한다.
- 해당 node의 32-bit payload는 `fixed_data[31:0]`에 들어가야 한다.
- 2-bit Hamming error가 아니면 Master는 `fixed_data[34:32]`가 가리키는 `slot_outN`에 payload를 저장한다.
- 따라서 다른 slot에서 송신되더라도 Hamming 2-bit error가 아니면 `slot_out` 자체는 frame 내부 address 기준으로 갱신될 수 있다. 다만 address와 현재 slot이 다르면 timing fault 측면에서는 severe error이다.

## Slot timing과 수신 판정

확인됨:

`Master_slot`의 `rx_stat`:

```text
rx_stat = 2 if clk_cnt < data_len_tick
rx_stat = 0 if data_len_tick + GUARD_TICKS/4 <= clk_cnt < total_tick - GUARD_TICKS/4
rx_stat = 1 otherwise
```

`Master_dec_ham`의 timing error:

```text
severe_err = (rx_stat == 2) || (fixed_data[34:32] != slot)
weak_err   = (rx_stat == 1)
```

해석:

- Master는 slave frame 완료 시점(`in_sig`)을 기준으로 timing을 판정한다.
- `rx_stat == 0`인 guard 중앙 영역에서 frame 완료가 발생해야 정상 timing으로 본다.
- `rx_stat == 1`은 guard edge 부근의 약한 timeout error이다.
- `rx_stat == 2`는 data window 내부이므로 severe timing error이다.
- decoded node address가 현재 `slot`과 다르면 severe error이다.
- 즉 정상 조건은 "frame 시작이 slot 시작과 일치"가 아니라, Master `out_sig`가 guard 중앙 정상 window에 도착하도록 전체 50-bit frame timing이 맞는 것이다.

Slave 송신 요구:

- Slave는 자신의 slot에서 `8'hAA + 42-bit codeword`를 송신해야 한다.
- Master가 frame 완료를 `rx_stat == 0` 영역에서 보도록 송신 시작 시점을 맞춰야 한다.
- Master `DIV`와 동일한 bit period를 사용해야 한다.
- `fixed_data[34:32]`는 현재 slot과 일치해야 한다.
- frame 첫 bit는 `8'hAA`의 MSB인 `1`이어야 receiver가 level-start 조건을 안정적으로 만족한다.

미확인:

- Slave가 slot 시작을 어떻게 동기화하는지는 Master 구현만으로는 완전히 확정되지 않는다. Master broadcast frame 또는 외부 reset/sync 기준을 slave 설계에서 별도로 정의해야 한다.

## Preamble 수신 FSM

확인됨:

- `Master_rx` state `0`: idle. `GPIO_in == 1`이면 preamble 수신 시작.
- state `1`: 8-bit preamble 수신. `buffer[7:0] == 8'hAA`이면 data 수신 상태로 이동.
- state `2`: 42-bit codeword 수신.
- `slot_pre_change`가 들어오면 state/counter가 reset된다.
- `out_sig`는 codeword 수신 완료 후 valid pulse로 쓰이며, fault/timing 판정은 이 pulse 시점의 `rx_stat`를 본다.

주의:

- Preamble error는 현재 slot 기준으로 카운트된다.
- slot 말미 직전에는 `slot_pre_change`가 receiver를 reset하므로, slave frame은 이 시점 전에 Master 수신 FSM이 완료해야 한다.

## 기존 사양 문서와 구현 차이

확인됨:

| 항목 | 기존 문서 흔적 | 현재 구현 |
|---|---|---|
| Line coding | Manchester 흔적 | NRZ |
| Frame tick | `50 * 2 * (DIV + 1)` 흔적 | `50 * DIV_effective` |
| Preamble | 일부 `0x55` 흔적 | `8'hAA` |
| Hamming layout | 전통적 parity-position 설명 | systematic `{data, parity}` |
| Master TX idle | high-Z/released 주석 | `0` drive |
| Start detect | rising edge 표현 | `GPIO_in == 1` level detect |
