# Master/Slave Link 검증 기록

## 대상

- Master source: `Master_ip/Master_tx.v`, `Master_ip/Master_rx.v`, `Master_ip/hamming_enc.v`, `Master_ip/hamming_dec.v`
- Slave source: `Slave_ip/v1_0/slave_top.v` 및 하위 slave modules
- Testbench: `tb/tb_slave_master_link.v`
- Script: `sim/slave_master_link/run_xsim.tcl`

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave_master_link\run_xsim.tcl
```

## 검증 구조

```text
Master_tx.GPIO_out -> slave_top.i_MASTER_SERIAL
slave_top.o_SLAVE_SERIAL -> Master_rx.GPIO_in -> hamming_dec
```

Master slot/fault 판정 전체를 넣지는 않았지만, 실제 Master TX/RX serial FSM과 Hamming decoder를 사용해 frame 호환성을 확인했다.

## 검증 항목

- Master_tx broadcast를 slave_top이 수신
- Slave가 Master broadcast의 `GUARD_TICKS`를 latch
- Slave가 sync 후 active 상태 진입
- Slave response를 Master_rx가 수신
- Master `hamming_dec` 기준 decoded node id/payload 일치
- Halt broadcast 이후 slave silence
- Halt clear broadcast 이후 response 재개

## 결과

PASS.

주요 terminal 출력:

```text
[PASS] Slave latched Master_tx guard got=0x0000007b
[PASS] Slave synced by Master_tx got=1
[WAVE] Master_rx valid data=0x155aa33cc node=1 payload=0x55aa33cc
[PASS] Master_rx decoded node id got=0x00000001
[PASS] Master_rx decoded payload got=0x55aa33cc
[PASS] No Master_rx response while halted got=0x00000000
[WAVE] Master_rx valid data=0x1a5a55a5a node=1 payload=0xa5a55a5a
PASS: tb_slave_master_link
```

## 잔여 범위

- `Master_slot`의 `rx_stat` fault 판정까지 포함한 full-system timing testbench는 아직 별도 항목이다.
- 현재 link TB는 실제 serial frame compatibility와 halt/response policy를 확인하는 단계이다.

