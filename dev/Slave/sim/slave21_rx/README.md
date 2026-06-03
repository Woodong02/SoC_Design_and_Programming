# `slave21_rx` simulation

## 대상

- Source: `Slave_ip/v2_1/slave21_rx.v`
- Testbench: `tb/tb_slave21_rx.v`

## 실행

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave21_rx\run_xsim.tcl
```

## PASS 기준

Terminal 또는 `sim/slave21_rx/xsim_run/xsim.log`에 다음 marker가 있어야 한다.

```text
PASS: tb_slave21_rx
```

## 검증 범위

- reset 후 output clear 및 idle
- idle-low 유지 시 frame 미검출
- 정상 `8'hAA + codeword` 수신
- wrong preamble discard
- `o_CODEWORD_VALID`, `o_FRAME_DONE` 1-cycle pulse
- frame 중 `i_BIT_PERIOD` 변경 무시
- `i_BIT_PERIOD=1` 작은 period boundary

## 최근 결과

- 2026-06-03: Vivado 2019.1 xsim 실행 PASS.

```text
PASS: tb_slave21_rx
```
