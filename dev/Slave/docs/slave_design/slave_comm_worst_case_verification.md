# Slave Communication Worst Case 검증 기록

## 목적

실제 구현/연결 시 발생할 수 있는 통신 worst case를 넓게 관찰한다. 이 검증은 RTL을 바로 수정하지 않고, pass/fail 및 한계 지점을 있는 그대로 기록하기 위한 것이다.

## 대상

- Testbench: `tb/tb_slave_comm_worst_case.v`
- Script: `sim/slave_comm_worst_case/run_xsim.tcl`
- Log: `sim/slave_comm_worst_case/xsim_run/xsim.log`

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave_comm_worst_case\run_xsim.tcl
```

## Testbench 구성

### 실제 link matrix

```text
Master_tx / Master_rx: master_clk
slave_top:              slave_clk

Master_tx.GPIO_out -> delayed/jittered line -> slave_top.i_MASTER_SERIAL
slave_top.o_SLAVE_SERIAL -> delayed/jittered line -> Master_rx.GPIO_in
```

포함 조건:

- Master/Slave 별도 clock period
- broadcast 시작 phase offset
- 양방향 propagation delay
- transition별 deterministic jitter
- Master normal guard window 안에서 response completion 여부 판정

### Guard window sweep

`slave_top` 대신 manual response frame을 `Master_rx`에 직접 주입해서, response start count를 guard 주변에서 sweep한다.

기준:

```text
BIT_DIV = 16
GUARD_TICKS = 128
data_len_tick = 800
slot_ticks = 928
Master normal done window = clk_cnt 832..895
```

## Link Matrix 결과

| Case | 조건 | 결과 |
|---:|---|---|
| 1 | nominal shared rate, arbitrary reset phase | PASS |
| 2 | slave +0.10% fast | PASS |
| 3 | slave -0.10% slow | PASS |
| 4 | slave +0.25% fast | PASS |
| 5 | slave -0.25% slow | PASS |
| 6 | slave +0.50% fast | PASS |
| 7 | slave -0.50% slow | PASS |
| 8 | quarter-bit symmetric delay plus jitter | PASS |
| 9 | asymmetric delay close to half-bit on return | PASS |
| 10 | +0.25% fast + asymmetric delayed line | PASS |
| 11 | exploratory +1.00% fast | PASS |
| 12 | exploratory -1.00% slow | PASS |
| 13 | exploratory +2.00% fast | FAIL observed |

실패 관측:

```text
[LINK CASE 13] exploratory +2.00 percent fast
[FAIL] observed link case failure decoded_ok=0 timing_ok=0 valid_count=0
```

## Guard Sweep 결과

Sweep 범위:

- Continuous: response start count `24..104`
- Extra: `0`, `1`, `127`

관측 결과:

- `response_start_cnt = 24..29`: frame decode는 되지만 Master normal done window 밖, done count `826..831`.
- `response_start_cnt = 30..93`: Master normal done window 안, 모두 decode PASS, done count `832..895`.
- `response_start_cnt = 94..104`: frame decode는 되지만 Master normal done window 밖, done count `896..906`.
- `response_start_cnt = 127`: slot boundary/reset edge에 걸려 valid 없음.

중요 관측:

문서상 이상적인 response start window는 `GUARD_TICKS/4 .. 3*GUARD_TICKS/4 - 1`, 즉 `32..95`로 계산되지만, 실제 `Master_rx`의 `out_sig` 관측 지연을 포함한 이번 TB에서는 `start_cnt=30..93`이 Master normal done window `832..895`에 대응되었다.

따라서 "Master normal guard done window 안에 valid가 발생한 frame"은 모두 decode 성공했다. 반대로 window 밖 frame도 일부는 Hamming decode 자체는 성공하지만, Master fault 정책상 timing weak/outside로 분류되어야 한다.

## Summary

최종 로그:

```text
SUMMARY: link_cases=13 guard_cases=84 observed_failures=1 expected_pass_failures=0
PASS: tb_slave_comm_worst_case expected-pass cases survived
```

## 해석

- 현재 구조는 `BIT_DIV=16`, `GUARD_TICKS=128` 조건에서 ±1% clock drift까지 이번 scenario set에서는 Master normal window 안 response를 유지했다.
- +2% fast case는 broadcast 수신 또는 response 수신이 실패했다. 이 조건은 현재 구조의 관측된 한계로 기록한다.
- Guard sweep에서는 Master normal done window에 들어간 모든 frame이 decode 성공했다.
- 더 강인성이 필요하다면 clock drift 보정, oversampling RX, dynamic BIT_DIV tracking, sync quality monitor가 다음 설계 후보가 된다.

