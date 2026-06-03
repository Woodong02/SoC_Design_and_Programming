# `slave_hamming_dec` simulation

이 폴더는 `slave_hamming_dec` leaf module의 Vivado/xsim batch simulation용 파일을 보관한다.

## 실행

PowerShell에서 project root 기준으로 실행한다.

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim/slave_hamming_dec/run_xsim.tcl
```

## 포함 source

- `Master_ip/hamming_enc.v`
- `Master_ip/hamming_dec.v`
- `Slave_ip/v1_0/slave_hamming_dec.v`
- `tb/tb_slave_hamming_dec.v`

Testbench는 terminal에 phase별 progress와 최종 `PASS` 또는 `FAIL`을 출력한다.
