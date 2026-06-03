# Slave 2.0 Reuse Leaf Compatibility Simulation

## 목적

`tb/tb_slave2_reuse_compat.v`를 Vivado 2019.1 xsim으로 실행해 Slave 2.0에서 그대로 재사용하는 Slave 1.0 leaf module의 호환성을 검증한다.

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave2_reuse_compat\run_xsim.tcl
```

## PASS 기준

터미널 또는 `sim/slave2_reuse_compat/xsim_run/xsim.log`에 다음 문구가 있어야 한다.

```text
PASS: tb_slave2_reuse_compat completed ... checks with no failures
```

