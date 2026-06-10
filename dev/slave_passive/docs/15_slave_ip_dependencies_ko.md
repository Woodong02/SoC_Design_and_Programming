# Slave AXI IP 종속성 및 리스크 문서

## 1. RTL 종속성

| 항목 | 현재 상태 | 차기 설계 영향 |
| --- | --- | --- |
| `slave23_passive_top.v` | parameter 기반 단일 slot top | 동작 참고용. 새 top은 재구성 필요 |
| `reuse/slave21_rx.v` | preamble/codeword RX 구현 | 새 `slave_broadcast_rx`의 참고 또는 wrapper 후보 |
| `reuse/slave21_tx.v` | frame build와 serializer 결합 | 분리 필요. 직접 재사용보다 기능 추출 권장 |
| `reuse/slave_hamming_enc.v` | master-compatible encoder | 우선 재사용 |
| `reuse/slave_hamming_dec.v` | master-compatible decoder | 우선 재사용, vector 재검증 필요 |
| `constraints/slave23_passive_fpga_top.xdc` | 존재하지 않는 wrapper 참조 | FPGA top wrapper 또는 constraint 정리 필요 |

## 2. AXI/Vivado 종속성

- AXI-Lite slave wrapper가 필요하다.
- Vivado IP packager용 top, component metadata, address map이 필요하다.
- PS driver/header export를 위해 register offset과 bit field가 고정되어야 한다.
- interrupt를 사용할 경우 PS interrupt controller 연결과 enable/mask register가 추가로 필요할 수 있다.
- board-level pin constraint와 AXI-integrated block design constraint를 분리해야 한다.

## 3. 시스템 종속성

| 항목 | 결정 필요 사항 |
| --- | --- |
| master serial input | PL clock과 비동기이면 2FF synchronizer 필요 |
| slave serial output | push-pull idle 0인지, output enable/tri-state가 필요한지 |
| slot 6/7 payload | PL payload source, valid timing, invalid 시 동작 |
| broadcast halt | v1에서 유지. decode된 halt mask는 다음 sync cycle부터 적용 |
| timing bounds | `DIV_REG`, computed ticks, counter width의 최대값 |

## 4. Timing 리스크

긴 조합 경로 후보:

- `50 * bit_period_ticks`
- `slot_index * slot_ticks`
- 8개 slot target tick 생성
- active/halt/payload valid 조건 결합

완화 기준:

- `cfg_shadow` 또는 sync 직후 precompute FF stage를 둔다.
- `slot_target_tick[0:7]` table을 register로 보관한다.
- slot sequencer는 현재 slot 하나만 비교하거나, 8-bit match vector를 register stage로 분리한다.
- 몇 clock의 scheduling latency는 허용하되, 그 latency가 timing formula에 반영되어 문서화되어야 한다.
- v1 기준 내부 timing 값은 33-bit bit period와 64-bit tick counter/table로 표현한다.
- raw sync edge와 AXI write가 같은 clock에 겹치면 write는 다음 sync 후보로 보낸다.
- TX command path는 ready/valid handshake를 사용하고 payload invalid는 skip/fault/event로 관측 가능해야 한다.

## 5. 문서 간 충돌 해결 기준

| 충돌 | 해결 기준 |
| --- | --- |
| 기존 `1 << DIV` vs 새 직접 분주 | 차기 IP는 `DIV_REG + 1`만 사용 |
| 기존 단일 `NODE_ID` vs 새 8-slot | `slot_id`가 response id가 됨 |
| 기존 `GUARD_TICKS` 위치 vs 새 중앙 송신 | `slot_ticks=frame_ticks+guard`, `tx_start=slot_base+guard/2` |
| broadcast guard vs PS guard | PS `CTRL.GUARD_TICKS`가 timing source |
| 즉시 halt vs snapshot halt | v1 확정: 다음 sync cycle부터 적용 |
| 현재 README vs 차기 설계 | README는 현재 RTL 설명과 차기 문서 링크를 분리 표기 |

## 6. 구현 전 확인 목록

- AXI top module naming.
- AXI address width 및 base address.
- interrupt 사용 여부.
- slot 6/7 PL payload port 이름과 valid 정책.
- output enable 필요 여부.
- Hamming encoder/decoder master vector 확보.
- counter width 및 max timing bound.

혼란스러운 항목이 남더라도 기본 설계는 진행 가능하다. 기본 정책은 PS register snapshot, 8-slot table, `DIV_REG+1`, 중앙 송신이다.
