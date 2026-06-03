# Vivado 2019.1 Smoke Check 기록

## 목적

Master source의 문법/elaboration 가능 여부와 주요 synthesis warning을 확인하여, 정밀 분석에서 "소스 그대로 확인된 동작"과 "의도 추정"을 구분하기 위한 근거로 남긴다.

## 실행 결과

확인됨:

- Vivado executable: `C:\Xilinx\Vivado\2019.1\bin\vivado.bat`
- Version: `Vivado v2019.1 (64-bit)`
- `Master_ip/*.v` read/elaboration smoke check는 `0 Errors / 0 Critical Warnings`로 통과했다.
- Top은 `Master_v1_0` 기준으로 확인되었다.

생성된 확인용 파일:

| File | Purpose |
|---|---|
| `sim/master_smoke/scripts/smoke_master_ip.tcl` | Vivado smoke check Tcl |
| `sim/master_smoke/scripts/smoke_master_ip_strict_nettype.tcl` | strict nettype 재확인용 Tcl |
| `sim/master_smoke/logs/*.log` | Vivado smoke check logs |
| `sim/master_smoke/logs/*.jou` | Vivado journals |
| `sim/master_smoke/work` | Vivado working directory |

## 핵심 Warning

확인됨:

`Master_top.v`에서 `DIV_p1`이 선언되지 않았고 driver가 없다.

관련 source:

- `Master_top.v`: input `DIV[9:0]`는 존재한다.
- `Master_top.v`: `NODE_CNT_p1`만 선언되어 있고 사용되지 않는다.
- `Master_top.v`: `Master_slot`, `Master_tx`, `Master_rx`에 `.DIV(DIV_p1)`를 연결한다.

Vivado warning:

```text
WARNING: [Synth 8-3848] Net DIV_p1 in module/entity master_top does not have driver.
WARNING: [Synth 8-3331] design master_top has unconnected port DIV[9:0]
```

해석:

- PS `SET_DIV()`는 사용자 입력 `DIVi`에서 1을 뺀 값을 AXI register에 기록한다.
- Master 담당자 확인상 PL 내부에서 `DIV + 1`을 만들어 하위 모듈에 넘기는 것이 의도 사양이다.
- 그러나 현재 source는 `DIV_p1`을 선언/assign하지 않아 하위 timing module들이 PS 설정값을 정상 수신하지 못할 가능성이 높다.
- 현재 `NODE_CNT_p1 = NODE_CNT + 1` 선언은 담당자 확인상 잘못된 기입이며, 실제로 필요한 것은 `DIV_p1 = DIV + 1`이다.
- Master 통신 timing 분석은 "확인된 의도 사양인 `DIV + 1` 구조"와 "현재 source의 warning"을 분리해서 다뤄야 한다.

## 기타 Warning

확인됨:

- `error_with_hamming.v`의 `GUARD_TICKS[9:0]` input은 내부에서 사용되지 않는다.
- AXI 쪽 일부 `slv_reg*`는 write 가능하지만 read mux에서 PL 내부 상태가 우선되어 최적화될 수 있다.
- `out_sig_reg` 제거 경고 등 최적화 warning이 존재한다.

## Slave 요구사항에 주는 영향

- Slave timing parameter는 확인된 의도 사양인 effective bit period 기준으로 확정한다. 예: `main.c` 기본 사용자값 `1024`.
- 현재 source 그대로라면 하위 모듈의 `DIV` 연결이 미구동일 수 있으므로, 정상 통신 전제 자체가 깨질 수 있다.
- 이후 slave 설계/검증 전에 Master source의 `DIV_p1` 버그를 수정하거나, testbench에서 의도 동작을 별도 모델링해야 한다.

## 2026-06-02 수정 후 재확인

수정됨:

- `Master_ip/Master_top.v`에서 미선언 `DIV_p1` 사용 문제를 수정했다.
- 기존의 잘못된/미사용 `NODE_CNT_p1` 선언 대신 다음 연결을 명시했다.

```verilog
wire [9:0] DIV_p1 = DIV + 10'd1;
```

재실행:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch `
  -source sim\master_smoke\scripts\smoke_master_ip.tcl `
  -log sim\master_smoke\logs\smoke_master_ip.log `
  -journal sim\master_smoke\logs\smoke_master_ip.jou

& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch `
  -source sim\master_smoke\scripts\smoke_master_ip_strict_nettype.tcl `
  -log sim\master_smoke\logs\smoke_master_ip_strict_nettype.log `
  -journal sim\master_smoke\logs\smoke_master_ip_strict_nettype.jou
```

결과:

- 실행 로그는 `sim/master_smoke/logs`에 기록한다.
- `synth_design -rtl -top Master_v1_0 -part xc7z020clg484-1` 통과.
- `0 Critical Warnings / 0 Errors`.
- 이전 핵심 경고였던 `Net DIV_p1 ... does not have driver`는 새 실행 출력에 나타나지 않았다.
- `default_nettype none` guard를 사용한 strict 재확인도 통과했다.
- 남은 warning은 기존 unused sequential element 및 unused/unconnected port 계열이다.

해석:

- Master timing 하위 모듈 `Master_slot`, `Master_tx`, `Master_rx`는 이제 의도 사양대로 `DIV + 1` 값을 전달받는다.
- Slave timing 사양은 `BIT_DIV = DIV + 1` effective bit period 기준으로 유지한다.
