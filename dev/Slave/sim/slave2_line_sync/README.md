# `slave2_line_sync` simulation

## 목적

`slave2_line_sync` leaf module의 reset, 2-stage synchronizer latency, reachable stage 조합을 Vivado 2019.1 xsim에서 검증한다.

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave2_line_sync\run_xsim.tcl
```

## 검증 항목

- reset output/stage clear
- reset 중 asynchronous high 입력 masking
- stable high 입력의 2-clock latency
- stable low 입력의 2-clock latency
- 1-clock pulse 전달 latency
- reachable stage 조합 `00`, `10`, `11`, `01`

## 결과

- 실행 일시: 2026-06-03
- 실행 명령: `& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave2_line_sync\run_xsim.tcl`
- 결과: PASS
- 근거 log: `sim/slave2_line_sync/xsim_run/xsim.log`
- terminal marker: `PASS: tb_slave2_line_sync`
