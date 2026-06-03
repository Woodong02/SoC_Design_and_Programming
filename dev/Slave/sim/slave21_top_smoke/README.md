# `slave21_top` smoke simulation

## 대상

- Source: `Slave_ip/v2_1/slave21_top.v`
- Testbench: `tb/tb_slave21_top_smoke.v`

## 실행

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave21_top_smoke\run_xsim.tcl
```

## PASS 기준

```text
PASS: tb_slave21_top_smoke
```

## 검증 범위

- top compile
- forced valid broadcast를 통한 control/fault wiring
- first good no tracking
- second good tracking
- halt command latch
- bad frame recovery

## 2026-06-03 실행 결과

```text
PASS: tb_slave21_top_smoke
```

세부 marker:

```text
[PASS] first good seen once
[PASS] second good tracking
[PASS] halt command halted
[PASS] bad frame recovery
PASS: tb_slave21_top_smoke
```

Smoke TB는 timing 검증이 목적이 아니므로 forced frame 사이에서 `timebase_rate_err`를 0으로 force한다. RX serial timing과 TX trigger/response capture는 full serial TB에서 검증한다.

`xvlog.log` / `xelab.log`: `ERROR`, `CRITICAL`, `WARNING` pattern 없음.
