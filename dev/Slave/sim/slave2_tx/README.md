# slave2_tx simulation

## 실행 명령

PowerShell에서 project root 기준으로 실행한다.

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim/slave2_tx/run_xsim.tcl
```

## 구성

- DUT: `Slave_ip/v2_0/slave2_tx.v`
- Child module: `Slave_ip/v1_0/slave_hamming_enc.v`
- Testbench: `tb/tb_slave2_tx.v`
- XSIM work directory: `sim/slave2_tx/xsim_work`

Testbench는 terminal output에 `PASS: tb_slave2_tx completed with no errors` 또는 `FAIL:`을 출력한다.
