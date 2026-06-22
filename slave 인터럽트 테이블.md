# Slave 인터럽트 테이블

Slave IP(PL)는 별도 PS 연결 없이, 내부 EVENT/FAULT sticky 레지스터로 인터럽트 플래그를 생성한다.
하나라도 set되면 `o_irq`가 level-high로 유지된다.

근거: `slave_passive/rtl/slave_status_event.v:23-43` (포트 정의), `:134-149` (소스 마스크), `:204-205` (o_irq 생성)

## EVENT (EVENT_VALID_MASK = 32'h0000_00FF)

| 비트 | 신호명 | 의미 |
|---|---|---|
| 0 | `evt_sync_detected` | 동기 프리앰블 검출 |
| 1 | `evt_rx_frame_done` | 수신 프레임 완료 |
| 2 | `evt_tx_done` | 송신 완료 |
| 3 | `evt_slot_cycle_done` | 슬롯 사이클 완료 |
| 4 | `evt_preamble_err` | 프리앰블 불일치 |
| 5 | `evt_ham_1bit_err` | Hamming 1비트 오류(정정됨) |
| 6 | `evt_ham_2bit_err` | Hamming 2비트 오류(정정불가) |
| 7 | `evt_cfg_commit` | 설정 반영 완료 |

## FAULT (FAULT_VALID_MASK = 32'h0000_001F)

| 비트 | 신호명 | 의미 |
|---|---|---|
| 0 | `fault_tx_overlap` | 슬롯 간 송신 겹침 |
| 1 | `fault_slot_timing_invalid` | 슬롯 타이밍 위반(가드 틱 미충족) |
| 2 | `fault_pl_payload6_invalid` | PL 입력 payload(슬롯6) 무효 |
| 3 | `fault_pl_payload7_invalid` | PL 입력 payload(슬롯7) 무효 |
| 4 | `fault_rx_ham_2bit` | 수신 broadcast Hamming 2비트 오류 |

## 동작 원리

- EVENT/FAULT는 sticky 레지스터이며, PS(또는 상위 AXI 레지스터 인터페이스)가 `i_event_clear_mask`/`i_fault_clear_mask`로 W1C 방식으로 클리어한다. (`slave_status_event.v:38-39, 151-152`)
- 같은 clock에서 새 event/fault 발생이 W1C clear보다 우선한다 — 펄스성 이벤트가 클리어 엣지에서 사라지지 않도록 하는 정책. (`slave_status_event.v:154-160`)
- `o_irq = |((event_sticky_ff & EVENT_VALID_MASK) | (fault_sticky_ff & FAULT_VALID_MASK))` (`slave_status_event.v:204-205`)
- 이 IRQ를 직접 받아 처리하는 PS 측 코드는 Slave 쪽에 따로 없으며, 관련 GIC/ISR 코드(`slave_passive/Master_source/main.c:14-150`)는 Master의 PS 코드다. 즉 Slave는 PS 연결 없이 PL 레벨에서 플래그만 생성한다.
