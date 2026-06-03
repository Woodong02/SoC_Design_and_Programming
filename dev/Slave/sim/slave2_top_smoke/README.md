# `slave2_top` smoke simulation

이 디렉토리는 `slave2_top` 배선 확인용 smoke simulation을 위한 공간이다.

## 범위

- `Slave_ip/v2_0/slave2_top.v`
- `Slave_ip/v2_0/slave2_line_sync.v`
- `Slave_ip/v2_0/slave2_rx.v`
- `Slave_ip/v2_0/slave2_timebase.v`
- `Slave_ip/v2_0/slave2_tx.v`
- `Slave_ip/v1_0/slave_hamming_enc.v`
- `Slave_ip/v1_0/slave_hamming_dec.v`
- `Slave_ip/v1_0/slave_control.v`
- `tb/tb_slave2_top_smoke.v`

이 simulation은 실제 2.0 leaf source를 사용한다. Testbench는 top 내부 RX codeword/status wire를 `force`하여 control 경로와 status 배선을 smoke 검증한다. 전체 serial 통신 검증은 별도 robust integration test에서 수행해야 한다.

## 실행

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave2_top_smoke\run_xsim.tcl
```

## 판정

Terminal 또는 `xsim.log`에 다음이 있으면 smoke PASS이다.

```text
PASS: tb_slave2_top_smoke
```

## 최근 결과

2026-06-03 실행 결과:

```text
PASS: tb_slave2_top_smoke
```
