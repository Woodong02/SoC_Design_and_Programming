# slave2_timebase simulation

Run:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave2_timebase\run_xsim.tcl
```

Expected terminal result:

```text
PASS: tb_slave2_timebase
```

## 최근 결과

2026-06-03 실행 결과:

```text
PASS: tb_slave2_timebase
```

검증 범위:

- reset/default period
- acquisition sync
- tracking lock
- expected/fast/slow interval rate correction
- bounded correction
- active 중 pending correction
- invalid node trigger block
- large error holdover/rate error
