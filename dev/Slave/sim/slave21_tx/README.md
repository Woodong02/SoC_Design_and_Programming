# `slave21_tx` simulation

## 대상

- Source: `Slave_ip/v2_1/slave21_tx.v`
- Reuse dependency: `Slave_ip/v2_1/reuse/slave_hamming_enc.v`
- Testbench: `tb/tb_slave21_tx.v`

## 실행

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave21_tx\run_xsim.tcl
```

## PASS 기준

Terminal 또는 `sim/slave21_tx/xsim_run/xsim.log`에 다음 marker가 있어야 한다.

```text
PASS: tb_slave21_tx
```

## 검증 범위

- reset/idle
- disabled trigger ignore
- normal frame bit sequence
- first bit immediate 및 full-width
- active retrigger ignore
- mid-frame `i_BIT_PERIOD` snapshot 유지
- done pulse 후 idle 0 복귀

## 검증 결과

- 작성/실행 시점: 2026-06-03 09:16 KST
- 실행 명령: 위 xsim batch command
- 결과: PASS
- Log: `sim/slave21_tx/xsim_run/xsim.log`
- Marker:

```text
PASS: tb_slave21_tx
```
