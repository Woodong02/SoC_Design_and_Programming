# `slave_top` 통합 검증 기록

## 대상

- Source: `Slave_ip/v1_0/slave_top.v`
- Testbench: `tb/tb_slave_top.v`
- Script: `sim/slave_top/run_xsim.tcl`

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave_top\run_xsim.tcl
```

## 검증 항목

- reset 후 unsynced/not halted
- valid master-style serial frame 수신
- `o_SYNCED` assert
- decoded broadcast `GUARD_TICKS` latch
- active 상태에서 slave response frame 송신
- response frame preamble `8'hAA`
- response codeword decode 후 `NODE_ID`, payload 일치
- halt broadcast 이후 TX silence
- halt clear broadcast 이후 TX 재개
- wrong preamble frame이 halt/guard latch를 변경하지 않음

## 결과

PASS.

주요 terminal 출력:

```text
[PASS] valid broadcast synced got=1
[PASS] response preamble got=0x000000aa
[PASS] response node id got=0x00000001
[PASS] response payload got=0x1234abcd
[PASS] halted slave stayed silent
[PASS] response payload got=0xcafef00d
[PASS] wrong preamble guard unchanged got=0x00000063
PASS: tb_slave_top
```

## 결론

`slave_top`은 leaf modules를 요구사항대로 연결한다. Broadcast 수신, sync, control latch, slot timer trigger, TX response 경로가 통합 상태에서 동작함을 확인했다.

