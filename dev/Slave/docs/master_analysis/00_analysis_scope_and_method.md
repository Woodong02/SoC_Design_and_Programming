# Master IP + PS 정밀 분석 범위와 방법

## 목적

이번 분석의 목적은 기존 `Master_ip` Verilog와 `Master_ps/main.c`를 함께 읽어, slave PL-only IP가 따라야 할 작동 프로토콜과 통신 프로토콜을 정확히 도출하는 것이다.

Master는 PL 단독 IP가 아니라 PS가 AXI register를 통해 설정값을 쓰고 상태값을 읽는 구조이다. 따라서 Verilog 내부 신호만으로 master 사양을 확정하지 않는다. 모든 주요 값은 다음 경로를 기준으로 추적한다.

```text
PS main.c write -> AXI register -> Master PL internal logic
Master PL internal logic -> AXI register/status/interrupt -> PS main.c read/interpret
Master PL GPIO_out/GPIO_in -> external slave communication
```

## 분석 구분

각 문서는 가능한 한 아래 세 범주를 구분한다.

| 구분 | 의미 |
|---|---|
| 확인됨 | 현재 소스 코드에서 직접 확인되는 동작 |
| 추론 | 소스 연결 관계와 주석으로부터 합리적으로 도출한 동작 |
| 미확인 | 시뮬레이션, Vivado compile, 구현자 확인, 또는 보드 실험이 필요한 항목 |

## Slave 설계에 반영할 전제

확정된 사용자 요구사항:

- Slave IP는 PL 단독으로 동작한다.
- Slave `node_id`는 Verilog source 내 parameter로 기입받는다.
- 동일한 slave IP를 parameter만 바꾸어 여러 node에 재사용한다.
- Master broadcast frame에 포함된 `GUARD_TICKS`는 slave가 수신하고 파싱하는 것까지 고려한다.
- 단, `GUARD_TICKS`를 이용한 slave timing 동적 변경 기능은 복잡도 때문에 보류한다.

## 산출 문서

| 문서 | 목적 |
|---|---|
| `01_pl_module_inventory.md` | Master PL 모듈 구조와 연결 관계 |
| `02_axi_ps_register_map.md` | AXI register map과 PS write/read 의미 |
| `03_operation_and_communication_protocol.md` | slot, frame, PHY, Hamming, timing 프로토콜 |
| `04_fault_decision_behavior.md` | fault counter, halt, silent, interrupt 판정 |
| `05_slave_pl_only_requirements.md` | Master 분석 기반 slave 요구사항 |

## 현재까지 발견한 중요 확인 포인트

- `Master_v1_0_S00_AXI.v`는 21개 32-bit register address를 decode한다.
- `main.c`는 register 0과 2에 설정값을 쓰고, register 1/2/3..0x14를 읽는다.
- 통신 frame은 `8'hAA` preamble + 42-bit Hamming codeword, 총 50 bit로 보인다.
- `Master_slot`의 slot 길이는 `50 * DIV + GUARD_TICKS`이다.
- `Master_tx`와 `Master_rx`는 기존 문서의 Manchester 흔적과 달리 NRZ 구현이다.
- `Master_tx` idle은 주석의 high-Z/released와 달리 `0` drive이다.
- `Master_top.v`의 `DIV_p1` 미선언은 Master 담당자 확인상 구현 버그이다.
- 의도 사양은 `DIV + 1`을 하위 timing module에 전달하고, `NODE_CNT`는 그대로 전달하는 것이다.
- 현재 source는 이를 `NODE_CNT + 1` 선언과 미선언 `DIV_p1` 사용으로 잘못 기입한 상태이다.
- Vivado 2019.1 smoke check는 elaboration 자체는 통과했지만 `DIV_p1` no-driver 및 `DIV[9:0]` unconnected warning을 보고했다.
- `Master_tx` 주석에는 broadcast data에 `DIV`가 포함된다고 적혀 있으나 실제 코드에는 `DIV`가 포함되지 않는다.
