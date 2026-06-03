# slave_control 검증 노트

## 대상

- Source: `Slave_ip/v1_0/slave_control.v`
- Testbench: `tb/tb_slave_control.v`
- Simulation script: `sim/slave_control/run_xsim.tcl`
- Tool: Vivado/xsim 2019.1

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim/slave_control/run_xsim.tcl
```

## 실행 결과

최종 실행 결과는 PASS이다.

```text
PASS: tb_slave_control completed checks=28
```

생성 로그:

- `sim/slave_control/xsim_run/xvlog.log`
- `sim/slave_control/xsim_run/xelab.log`
- `sim/slave_control/xsim_run/xsim.log`

`xvlog.log` 확인 결과:

```text
INFO: [VRFC 10-2263] Analyzing Verilog file "C:/Users/sinsu/Desktop/myproject/Slave_ip/v1_0/slave_control.v" into library work
INFO: [VRFC 10-311] analyzing module slave_control
INFO: [VRFC 10-2263] Analyzing Verilog file "C:/Users/sinsu/Desktop/myproject/tb/tb_slave_control.v" into library work
INFO: [VRFC 10-311] analyzing module tb_slave_control
```

`xelab.log` 확인 결과 static elaboration, simulation data flow analysis, snapshot build가 완료되었다.

## 검증 항목

| 항목 | 결과 | 근거 |
|---|---|---|
| Reset 후 TX disabled | PASS | `reset tx disabled` |
| Reset 후 halted clear | PASS | `reset not halted` |
| Reset 후 guard clear | PASS | `reset guard clear` |
| Payload pass-through | PASS | `payload pass-through after reset`, `payload pass-through active` |
| Valid clean broadcast로 active 진입 | PASS | `active entry tx enabled`, `active entry halted clear` |
| `data[26:17]` guard latch | PASS | `guard latch active`, `guard latch halt set`, `guard latch halt clear` |
| Halt bit set 시 TX disabled / halted | PASS | `halt set disables tx`, `halt set halted` |
| Halt bit clear 시 active 재진입 | PASS | `halt clear re-enables tx`, `halt clear exits halted` |
| 2-bit error broadcast ignore | PASS | `2bit error keeps tx enabled`, `2bit error keeps halted clear`, `2bit error keeps guard` |
| 2-bit error 후 clean broadcast 반영 | PASS | `clean halt after ignored frame disables tx`, `clean halt after ignored frame latches guard` |
| `NODE_ID == 5` halt bit indexing | PASS | `node5 halt bit indexing disables tx`, `node5 halt bit indexing guard` |
| 다른 node halt bit 무시 | PASS | `node5 ignores node2 halt bit` |
| `NODE_ID == 0` halt bit indexing | PASS | `node0 halt bit indexing disables tx`, `node0 halt bit indexing halted` |

## 참고 사항

초기 simulation script는 Vivado Tcl에서 `xvlog`를 직접 Tcl command처럼 호출해 `invalid command name "xvlog"`로 실패했다. 이는 source/TB 문제가 아니라 스크립트 호출 방식 문제였고, `C:/Xilinx/Vivado/2019.1/bin/xvlog.bat`, `xelab.bat`, `xsim.bat`를 `exec`로 호출하도록 수정한 뒤 최종 PASS를 확인했다.

## 미검증/상위 책임

- `slave_control`은 `PAYLOAD_DEFAULT` parameter를 직접 갖지 않는다. payload default 선택이 필요하면 `slave_top`에서 `i_PAYLOAD_IN`에 반영해야 한다.
- Latched `GUARD_TICKS`를 `slave_slot_timer`에 동적으로 연결하는 통합 동작은 이번 leaf 검증 범위 밖이다.
