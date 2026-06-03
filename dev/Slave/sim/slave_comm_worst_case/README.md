# slave_comm_worst_case simulation

## 목적

실제 연결 시 발생할 수 있는 통신 worst case를 넓게 관찰한다. RTL을 바로잡지 않고 pass/fail을 그대로 보고하기 위한 testbench이다.

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave_comm_worst_case\run_xsim.tcl
```

## 포함 시험

- Master/Slave 별도 clock period
- reset/broadcast start phase offset
- 양방향 전송 지연
- deterministic transition jitter
- Master normal guard window 경계 sweep
- 탐색용 extreme drift case

시뮬레이터는 관찰 매트릭스를 끝까지 출력하기 위해, 기대 pass case 실패가 있어도 process exit은 강제로 실패시키지 않는다.

