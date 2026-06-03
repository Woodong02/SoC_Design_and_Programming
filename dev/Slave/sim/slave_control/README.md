# slave_control simulation

Vivado 2019.1 기준 batch 실행:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim/slave_control/run_xsim.tcl
```

주요 산출물:

- `sim/slave_control/xsim_run/xvlog.log`
- `sim/slave_control/xsim_run/xelab.log`
- `sim/slave_control/xsim_run/xsim.log`

`tb_slave_control`은 reset, active 진입, guard latch, halt set/clear, 2-bit error ignore, `NODE_ID`별 halt bit indexing, payload pass-through를 self-checking으로 검증하고 최종 `PASS: tb_slave_control completed` 또는 `FAIL: tb_slave_control`을 출력한다.
