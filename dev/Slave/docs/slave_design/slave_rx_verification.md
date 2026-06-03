# `slave_rx` 검증 기록

## 검증 대상

- Source: `Slave_ip/v1_0/slave_rx.v`
- Testbench: `tb/tb_slave_rx.v`
- Simulation script: `sim/slave_rx/run_xsim.tcl`

## 실행 환경

- Tool: Vivado/xsim 2019.1
- Target part: `xc7z020clg484-1`
- 실행 시간: 2026-06-03 KST

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim/slave_rx/run_xsim.tcl -journal sim/slave_rx/logs/vivado.jou -log sim/slave_rx/logs/vivado.log
```

## Testbench Coverage

| Phase | 검증 내용 | 결과 |
|---|---|---|
| idle-low 유지 | `i_SERIAL_IN == 0` 유지 시 sync/valid/error pulse 없음 | PASS |
| valid frame | `8'hAA + 42-bit codeword` 수신 후 codeword 일치 | PASS |
| sync preload | preamble 성공 시 `o_SYNC_CLK_CNT == 8 * i_BIT_DIV` | PASS |
| wrong preamble | preamble mismatch에서 `o_PREAMBLE_ERR` 1-cycle pulse | PASS |
| wrong preamble sync block | wrong preamble에서 `o_SYNC_PULSE`, `o_CODEWORD_VALID` 없음 | PASS |
| wrong 이후 resync | wrong preamble 후 valid frame으로 재동기화 가능 | PASS |
| reset 중단 | partial preamble 중 reset 후 candidate 폐기 | PASS |
| BIT_DIV boundary 1 | `i_BIT_DIV == 1`에서 valid frame 수신 | PASS |
| BIT_DIV boundary 2 | `i_BIT_DIV == 2`에서 valid frame 수신 | PASS |
| pulse width | `o_CODEWORD_VALID`, `o_SYNC_PULSE`, `o_PREAMBLE_ERR` 연속 2-cycle assert 방지 | PASS |

## 주요 로그

최종 Vivado log 기준:

```text
PASS: tb_slave_rx
```

`sim/slave_rx/logs/vivado.log`에서 `WARNING`, `CRITICAL WARNING`, `ERROR`, `FAIL:` 항목은 검출되지 않았다.

## 검증 결론

`slave_rx`는 문서화된 Slave RX 정책을 만족한다.

- idle-low 첫 `1`을 preamble candidate로만 사용한다.
- `8'hAA` 검증 성공 시에만 sync pulse를 낸다.
- sync pulse와 preload는 같은 1-cycle window에서 관측된다.
- wrong preamble은 sync와 codeword valid를 만들지 않는다.
- codeword는 MSB-first로 42 bit 수신되어 1-cycle valid pulse와 함께 출력된다.

## 남은 가정

- 정상 운용에서 `i_BIT_DIV`는 1 이상이라고 가정한다.
- Source는 defensive behavior로 `i_BIT_DIV == 0`일 때 내부 sampling period를 1 tick으로 clamp하지만, 이 값은 실제 통신 설정으로 권장하지 않는다.
