# `slave2_rx` simulation

## 목적

`slave2_rx` leaf module의 tick-driven RX FSM, preamble 검증, 42-bit codeword shift, majority sampling, idle noise, preamble error, back-to-back frame 수신을 Vivado 2019.1 xsim에서 검증한다.

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave2_rx\run_xsim.tcl
```

## 검증 항목

- reset output clear
- tick 없는 idle noise 차단
- 정상 frame sync/codeword valid
- wrong preamble error
- majority sampling center glitch 보정
- reset 없는 back-to-back frame 수신

## 결과

- 2026-06-03: Vivado 2019.1 xsim 실행 PASS
- Terminal marker: `PASS: tb_slave2_rx`
