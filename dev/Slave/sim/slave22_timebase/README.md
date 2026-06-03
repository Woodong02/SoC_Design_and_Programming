# sim/slave22_timebase

`slave22_timebase` 단독(leaf) xsim 검증.

## 대상 파일

- RTL: `Slave_ip/v2_2/slave22_timebase.v`
- TB:  `tb/tb_slave22_timebase.v`

## 실행

PowerShell에서:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source 'C:\Users\sinsu\Desktop\myproject\sim\slave22_timebase\run_xsim.tcl' -nojournal -nolog
```

`run_xsim.tcl`은 `xsim_run/` 작업 디렉토리를 만들고 xvlog → xelab → xsim을 순서대로 호출한다.
결과 로그는 `xsim_run/xsim.log`에 남는다.

## 결과 요약 (최신 실행)

전체 PASS. `xsim.log` 마지막 줄:

```
PASS: tb_slave22_timebase
```

검증 케이스: T1(reset), T2(첫 good→WAIT_SECOND), T3(둘째 good→TRACKING),
T4(TRACKING 중 rate_error→HOLDOVER, period_valid/bit_period 유지),
T5/T6(HOLDOVER 복구), T7(Scenario 9: rate_error+good 동시→HOLDOVER, 다음 good에서 tx_trigger),
T8(miss_count 초과→default 리셋+period_valid=0+WAIT_FIRST),
T9(정상 interval 후 miss_count=0, 이후 단발 miss는 holdover로 흡수),
T10(invalid node), T11(tx active), T12(tx_allowed=0), T13(rate correction fast/slow),
그리고 2.1 regression(slot hold, 첫/둘째 good acquisition, gating).
