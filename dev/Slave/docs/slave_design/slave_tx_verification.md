# slave_tx 검증 노트

## 검증 대상

- DUT: `Slave_ip/v1_0/slave_tx.v`
- Child module: `Slave_ip/v1_0/slave_hamming_enc.v`
- Testbench: `tb/tb_slave_tx.v`
- Simulation script: `sim/slave_tx/run_xsim.tcl`

## 실행 환경

- Tool: Vivado/xsim 2019.1
- 실행 기준 디렉토리: `C:\Users\sinsu\Desktop\myproject`

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim/slave_tx/run_xsim.tcl
```

## Testbench 구조

`tb_slave_tx`는 자체 reference Hamming encoder function으로 기대 codeword를 계산한 뒤 기대 frame을 만든다.

```text
expected_frame = {8'hAA, reference_codeword({NODE_ID, PAYLOAD})}
```

각 frame check는 현재 serial bit가 기대 bit와 같은지, 그리고 그 bit가 `i_BIT_DIV` clock 동안 유지되는지를 cycle-by-cycle로 확인한다.

## 검증 항목

| 항목 | 결과 | 설명 |
|---|---|---|
| reset idle | PASS | reset 중 `o_SERIAL_OUT=0`, `o_TX_ACTIVE=0`, `o_TX_DONE=0` |
| trigger 없는 idle | PASS | trigger 없이 idle line `0` 유지 |
| disabled trigger 무시 | PASS | `i_TX_ENABLE=0`이면 trigger가 들어와도 송신하지 않음 |
| normal 50-bit frame | PASS | `{8'hAA, codeword}`를 MSB-first로 송신 |
| first bit `1` | PASS | preamble `8'hAA` MSB가 첫 bit로 출력됨 |
| bit period 유지 | PASS | 각 bit가 `i_BIT_DIV=4` clock 동안 유지됨 |
| reset 중단 | PASS | active frame 중 reset 시 즉시 idle 복귀 |
| active 중 retrigger 무시 | PASS | 진행 중 frame이 변경되지 않고 기존 frame 유지 |
| 완료 후 idle/done pulse | PASS | 마지막 bit 이후 `o_TX_DONE` 1-cycle pulse, serial idle `0` |

## 실행 결과 요약

최종 xsim 실행 결과:

```text
PASS: tb_slave_tx completed with no errors
```

## 중간 이슈와 처리

1. `run_xsim.tcl`에서 `xvlog`를 Vivado Tcl 내장 명령처럼 호출했을 때 `invalid command name "xvlog"`가 발생했다.
   - 원인: Vivado batch Tcl 환경에서 `xvlog/xelab/xsim`을 OS shell command로 실행해야 했다.
   - 처리: `$::env(XILINX_VIVADO)/bin/*.bat`을 `cmd /c`로 직접 실행하도록 script를 수정했다.

2. 첫 elaboration에서 timescale 혼재 오류가 발생했다.
   - 원인: TB에만 `` `timescale``이 있고 기존 `slave_hamming_enc.v`에는 timescale이 없었다.
   - 처리: 소유 범위 밖 encoder를 수정하지 않고 `tb_slave_tx.v`의 timescale directive를 제거했다.

3. 첫 simulation에서 frame bit mismatch가 발생했다.
   - 원인: testbench `pulse_trigger` task가 첫 bit 시작 후 1 clock 늦은 시점에 frame check를 시작했다.
   - 처리: trigger를 sampling한 posedge 직후 `#1`에 task가 반환되도록 수정하여 첫 bit부터 check하게 했다.

## 검증 결론

`slave_tx`는 현재 Master-compatible response TX 요구사항을 만족한다. Disabled trigger와 active retrigger는 설계 정책대로 무시되며, reset/idle/done pulse 동작도 self-checking testbench로 확인했다.
