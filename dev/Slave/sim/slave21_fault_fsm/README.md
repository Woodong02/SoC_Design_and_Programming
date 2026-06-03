# `slave21_fault_fsm` simulation

## 대상

- Source: `Slave_ip/v2_1/slave21_fault_fsm.v`
- Testbench: `tb/tb_slave21_fault_fsm.v`

## 실행

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave21_fault_fsm\run_xsim.tcl
```

## PASS 기준

Terminal 또는 `sim/slave21_fault_fsm/xsim_run/xsim.log`에 다음 marker가 있어야 한다.

```text
PASS: tb_slave21_fault_fsm
```

## 검증 범위

- reset 및 ACQUIRE 진입
- bad frame 반복
- first good / second good tracking 진입
- halt gating
- tracking bad frame recovery
- recovery 재획득
- rate error recovery
- good broadcast commit pulse

## 2026-06-03 실행 결과

실행 명령:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave21_fault_fsm\run_xsim.tcl
```

결과:

```text
PASS: tb_slave21_fault_fsm
```

`xvlog`, `xelab`, `xsim` 단계에서 fatal error 또는 critical warning은 관측되지 않았다.
