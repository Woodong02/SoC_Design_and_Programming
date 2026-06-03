# `slave21_timebase` simulation

## 대상

- Source: `Slave_ip/v2_1/slave21_timebase.v`
- Testbench: `tb/tb_slave21_timebase.v`

## 실행

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave21_timebase\run_xsim.tcl
```

## PASS 기준

Terminal 또는 `sim/slave21_timebase/xsim_run/xsim.log`에 다음 marker가 있어야 한다.

```text
PASS: tb_slave21_timebase
```

## 검증 범위

- reset/default period
- slot hold regression: commit 직후 slot boundary 전에는 `o_SLOT` 유지
- first good commit acquisition
- second good commit period valid/tracking
- expected interval period 유지
- fast/slow interval bounded correction
- `i_TX_ALLOWED` gating
- `NODE_ID > NODE_CNT` trigger block
- `i_TX_ACTIVE` trigger block
- large rate error pulse 및 period invalid

## 결과

- 2026-06-03: PASS. `slot hold regression check` 추가 후 재실행.
  - Command: `& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave21_timebase\run_xsim.tcl`
  - Marker: `PASS: tb_slave21_timebase`
  - `xvlog.log` / `xelab.log`: `ERROR`, `CRITICAL`, `WARNING` match 없음.
