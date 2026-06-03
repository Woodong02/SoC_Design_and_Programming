# slave_master_link simulation

## 목적

실제 `Master_tx`, `Master_rx`, `hamming_dec`와 `slave_top`을 함께 연결해 구현 호환성을 확인한다.

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave_master_link\run_xsim.tcl
```

## 검증 범위

- Master_tx broadcast를 slave_top이 수신하고 guard/halt를 latch
- slave_top response를 Master_rx가 수신
- Master hamming_dec 기준 node id/payload 일치
- halt broadcast 이후 slave 침묵
- halt clear 이후 slave response 재개

