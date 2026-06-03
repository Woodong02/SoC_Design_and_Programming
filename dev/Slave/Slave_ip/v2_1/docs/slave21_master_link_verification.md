# Slave 2.1 Master/Slave Normal Integration Verification

## 목적

이 검증은 Slave 2.1 top이 실제 Master leaf source와 normal same-clock 조건에서 통신 가능한지 확인한다. Master broadcast 생성에는 `Master_tx`를 사용하고, Slave response 수신/해석에는 `Master_rx`와 `hamming_dec`를 사용한다.

## 대상 Source

Master:

- `Master_ip/Master_tx.v`
- `Master_ip/Master_rx.v`
- `Master_ip/hamming_enc.v`
- `Master_ip/hamming_dec.v`

Slave:

- `Slave_ip/v2_1/slave21_top.v`
- `Slave_ip/v2_1/slave21_rx.v`
- `Slave_ip/v2_1/slave21_fault_fsm.v`
- `Slave_ip/v2_1/slave21_timebase.v`
- `Slave_ip/v2_1/slave21_tx.v`
- `Slave_ip/v2_1/reuse/*`

Testbench:

- `tb/tb_slave21_master_link.v`

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave21_master_link\run_xsim.tcl
```

## Testbench 구성

확인된 연결:

- `Master_tx.GPIO_out` -> corruption mux -> `slave21_top.i_MASTER_SERIAL`
- `slave21_top.o_SLAVE_SERIAL` -> `Master_rx.GPIO_in`
- `Master_rx.data_out` -> `hamming_dec.codeword`

Parameter:

| 항목 | 값 |
|---|---:|
| `NODE_ID` | `1` |
| `NODE_CNT` | `1` |
| `DIV` / `BIT_PERIOD_DEFAULT` | `16` |
| `GUARD_TICKS` | `20` |
| slot ticks | `820` |
| Master cycle ticks | `1640` |

## 검증 Scenario

### Case 1: first good broadcast silence

확인:

- 첫 good broadcast 후 `o_LINK_TRACKING == 0`
- `GUARD_TICKS` latch 확인
- 다음 Master broadcast 시점까지 `Master_rx.out_sig` 없음

결과: PASS

### Case 2: second good broadcast response

확인:

- 두 번째 good broadcast 후 `o_LINK_TRACKING == 1`
- `Master_rx`가 Slave response frame 수신
- `hamming_dec.data[34:32] == NODE_ID`
- `hamming_dec.data[31:0] == 32'hcafef00d`
- 2-bit Hamming error 없음
- preamble error 없음

결과: PASS

### Case 3: Master receive timing

`Master_slot`은 직접 instantiate하지 않고, Master 분석 문서의 `rx_stat` 식을 TB monitor로 동일하게 계산했다.

```text
data_len_tick = 50 * DIV
slot_ticks    = data_len_tick + GUARD_TICKS

rx_stat = 2 if slot_clk_cnt < data_len_tick
rx_stat = 0 if data_len_tick + GUARD_TICKS/4 <= slot_clk_cnt < slot_ticks - GUARD_TICKS/4
rx_stat = 1 otherwise
```

이 monitor는 `Master_dec_ham`이 `Master_rx.out_sig` 시점에 보는 `rx_stat` 판정과 동등하다. 본 TB는 `Master_rx.out_sig` 발생 cycle에서 monitor 값을 latch해 검사한다.

확인된 response timing:

| Scenario | slot | slot clk cnt | rx_stat |
|---|---:|---:|---:|
| normal second good response | `1` | `809` | `0` |
| acquisition recovery response | `1` | `809` | `0` |

결과: PASS

### Case 4: halt command silence

확인:

- `halt_cmd[1] == 1` broadcast 후 `o_HALTED == 1`
- 다음 Master broadcast 시점까지 `Master_rx.out_sig` 증가 없음

결과: PASS

### Case 5: bad first broadcast acquisition recovery

방법:

- `Master_tx` 출력 전체 frame 구간을 corruption mux로 invert하여 wrong preamble/bad frame을 만든다.
- reset 후 첫 broadcast를 corrupt한다.
- 다음 good broadcast 1회는 `SEEN_ONCE`/silent로 확인한다.
- 두 번째 good broadcast 후 response decode와 normal rx_stat를 확인한다.

결과: PASS

## 실행 결과

실행 일시: 2026-06-03 09:53 KST

```text
PASS: tb_slave21_master_link
```

주요 log:

```text
[PASS] first good slave stays silent
[PASS] second good response node id got=0x00000001
[PASS] second good response payload got=0xcafef00d
[PASS] second good response normal rx_stat got=0x00000000
[PASS] halt command causes silence
[PASS] bad first broadcast causes silence
[PASS] recovery first good still silent
[PASS] recovery second good response payload got=0x0badcafe
[PASS] recovery second good response normal rx_stat got=0x00000000
PASS: tb_slave21_master_link
```

Compile/elaboration log check:

- `xvlog.log`: `ERROR`, `CRITICAL`, `WARNING` pattern 없음
- `xelab.log`: `ERROR`, `CRITICAL`, `WARNING` pattern 없음

## 확인된 사항

- Slave 2.1은 Master broadcast를 두 번 정상 수신하기 전까지 response를 내지 않는다.
- 두 번째 good broadcast 이후 Slave response는 실제 `Master_rx`로 수신 가능하다.
- Master decoder 기준 response node id와 payload가 기대값과 일치한다.
- response complete 시점은 Master normal guard window에 들어간다.
- halt command는 정상 tracking 상태에서도 response를 막는다.
- corrupt first broadcast 뒤에는 good broadcast 2회로 acquisition recovery가 가능하다.

## 남은 Risk

TRACKING 상태에서 bad broadcast가 발생한 뒤의 recovery는 별도 harsh/recovery scope로 남긴다.

디버깅 중 관찰:

- TRACKING 중 bad frame 뒤 첫 good commit에서 `slave21_timebase`가 큰 interval error로 `o_RATE_ERR`를 낼 수 있다.
- 이때 `fault_fsm`은 good frame count 기준으로 recovery하지만, `timebase`는 period 재획득을 다시 시작한다.
- 따라서 "tracking 중 bad frame 이후 두 번째 good frame에서 즉시 response" 정책은 현재 normal TB에서 PASS 대상으로 두지 않았다.

권장 후속:

- `slave21_tracking_bad_recovery` TB를 별도로 만들고, expected behavior를 "몇 번째 good broadcast부터 TX 재개해야 하는가"로 명확히 고정한다.
- 이 정책이 두 good recovery여야 한다면 `fault_fsm`과 `timebase` recovery phase 정합성을 RTL 수정 대상으로 분류한다.

