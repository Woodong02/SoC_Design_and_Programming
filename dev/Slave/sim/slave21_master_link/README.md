# `slave21_master_link` simulation

## 대상

- Master source: `Master_tx`, `Master_rx`, `hamming_enc`, `hamming_dec`
- Slave source: `Slave_ip/v2_1/slave21_top.v` 및 하위 Slave 2.1 leaf/reuse modules
- Testbench: `tb/tb_slave21_master_link.v`

## 실행

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave21_master_link\run_xsim.tcl
```

## PASS 기준

```text
PASS: tb_slave21_master_link
```

## 검증 범위

- nominal same clock 조건
- 실제 `Master_tx` broadcast frame 2회 후 Slave 응답 확인
- first good broadcast 후 Slave silent 확인
- second good broadcast 후 `TRACKING` 진입 및 response 확인
- 실제 `Master_rx` + `hamming_dec`로 response node id/payload decode 확인
- TB monitor가 Master `rx_stat`와 같은 식으로 계산한 guard-center 정상 window 확인
- halt command 수신 후 Slave silence 확인
- corrupt first broadcast 후 good broadcast 2회로 acquisition recovery 확인

## 2026-06-03 실행 결과

```text
PASS: tb_slave21_master_link
```

주요 marker:

```text
[PASS] first good slave stays silent
[PASS] second good response node id
[PASS] second good response payload
[PASS] second good response normal rx_stat
[PASS] halt command causes silence
[PASS] bad first broadcast causes silence
[PASS] recovery first good still silent
[PASS] recovery second good response payload
[PASS] recovery second good response normal rx_stat
PASS: tb_slave21_master_link
```

Log check:

- `sim/slave21_master_link/xsim_run/xvlog.log`: `ERROR`, `CRITICAL`, `WARNING` pattern 없음
- `sim/slave21_master_link/xsim_run/xelab.log`: `ERROR`, `CRITICAL`, `WARNING` pattern 없음

## Timing note

TB는 `Master_slot`을 직접 instantiate하지 않고, 문서화된 Master `rx_stat` 식을 monitor로 동일하게 계산한다.

```text
rx_stat = 2 if slot_clk_cnt < 50 * DIV
rx_stat = 0 if 50 * DIV + GUARD_TICKS/4 <= slot_clk_cnt < slot_ticks - GUARD_TICKS/4
rx_stat = 1 otherwise
```

정상 response는 두 번 모두 `slot=1`, `slot_clk_cnt=809`, `rx_stat=0`에서 `Master_rx.out_sig`가 발생했다. 본 TB의 목적은 normal integration timing 확인이므로 이 monitor는 `Master_dec_ham`이 `in_sig` 시점에 사용하는 timing 판정과 동등하다.

## Remaining risk

Tracking 상태에서 bad broadcast가 들어온 뒤의 prolonged recovery는 이 normal TB의 인수 범위에서 제외했다. 디버깅 중 확인된 관찰은 다음과 같다.

- TRACKING 중 bad frame 뒤 첫 good commit에서 `slave21_timebase`가 큰 interval error를 보고 `o_RATE_ERR`를 낼 수 있다.
- 이 경우 `fault_fsm`과 `timebase`의 recovery phase가 한 broadcast만큼 어긋날 수 있어, "bad 이후 second good 즉시 TX"는 별도 harsh/recovery TB에서 정책을 확정하고 검증해야 한다.

