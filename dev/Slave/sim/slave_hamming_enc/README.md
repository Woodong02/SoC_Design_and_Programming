# `slave_hamming_enc` simulation

## 목적

`slave_hamming_enc`가 Master `hamming_enc`와 동일한 SECDED parity tree와 codeword layout을 생성하는지 Vivado/xsim batch로 확인한다.

## 실행 명령

Project root에서 다음 명령을 실행한다.

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim/slave_hamming_enc/run_xsim.tcl
```

## 검증 내용

- `tb/tb_slave_hamming_enc.v`
- DUT: `Slave_ip/v1_0/slave_hamming_enc.v`
- Reference 1: testbench 내부 `reference_codeword` function
- Reference 2: `Master_ip/hamming_enc.v`

PASS 조건은 testbench terminal output에 `PASS: tb_slave_hamming_enc`가 출력되고 mismatch가 0개인 것이다.
