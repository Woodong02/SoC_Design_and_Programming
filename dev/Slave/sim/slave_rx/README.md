# `slave_rx` simulation

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim/slave_rx/run_xsim.tcl -journal sim/slave_rx/logs/vivado.jou -log sim/slave_rx/logs/vivado.log
```

## 포함 파일

- `Slave_ip/v1_0/slave_rx.v`
- `tb/tb_slave_rx.v`

## 기대 결과

Terminal log에 다음 문구가 출력되어야 한다.

```text
PASS: tb_slave_rx
```
