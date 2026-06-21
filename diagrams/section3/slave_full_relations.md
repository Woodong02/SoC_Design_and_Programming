# 슬레이브 전체 기능 블록도 — 확정 요소/관계 (Section 3)

> 출처: `slave_passive/rtl/slave_ip_top.v`, `slave_pl_top.v` 및 하위 9개 서브모듈을
> 에이전트가 조사(포트/인스턴스 와이어링만 경량 조사). 슬레이브는 PS/AXI 없이
> PL 단독 동작(`slave_pl_top.v` 기준)이므로 PS 블록 없음.
> 원본 다이어그램 소스: `slave_full_stack.mmd` (렌더: `slave_full_stack.png`)
> 상태: 슬레이브 기능 블록도 확정 완료.

## 노드 (위치별 그룹)

### GPIO (점선 경계, PL 밖)
- GND (연결 없음)
- TX 포트 (TXP) — o_slave_serial
- RX 포트 (RXP) — i_master_serial

### PL (점선 경계)
- LED — `slave_pl_top.v`의 `o_led[1:0]` (RX/TX 라인 상태 표시)
- (Slave 블록 외 다른 PL 요소 없음 — 슬레이브는 기능적으로 PS/PL 부가 요소가 적음)

### Slave (PL 내부, 점선 경계) — 5개 기능 블록
- 수신/동기 (SYNC): slave_sync_detector, slave_broadcast_rx, slave_broadcast_decoder, slave_hamming_dec
- 타이밍/스케줄 (TIME): slave_timing_scheduler, slave_slot_sequencer
- 페이로드/송신 (TXPATH): slave_payload_table, slave_frame_builder, slave_tx_serializer, slave_hamming_enc
- 설정/보호 (CFG): slave_cfg_shadow
- 상태/이벤트 (STAT): slave_status_event

## 관계 (엣지)

| From | To | 라벨 | 비고 |
|---|---|---|---|
| RXP | SYNC | i_master_serial | GPIO → Slave |
| SYNC | TIME | sync_pulse | |
| SYNC | STAT | rx_active,frame_done | |
| CFG | TIME | cfg_guard_ticks,cfg_active_slot | |
| CFG | TXPATH | cfg_data_out0-5 | |
| TIME | TXPATH | seq_tx_cmd_valid/slot_id | |
| TIME | STAT | seq_slot_cycle_done | |
| TXPATH | TXP | o_slave_serial | Slave → GPIO |
| TXPATH | STAT | tx_done | |
| TXP | LED | | |
| RXP | LED | | |

GND는 어떤 노드와도 연결되지 않음 (GPIO 점선 블록 내 단독 노드).

## 제외/생략 사항
- AXI-Lite/PS 인터페이스: `slave_ip_top.v`에는 존재하지만(`i_reg_*`, `o_status/event/fault_reg_value`, `o_irq`), 이번 다이어그램은 PS 없는 `slave_pl_top.v` 기준 단독 PL 동작을 그리므로 제외.
- DIP Switch / Push Button / 7-Segment: `slave_pl_top.v`에 해당 포트 없음 (LED만 존재).

## 마스터-슬레이브 통합 연결도 참고
마스터와 슬레이브를 동시에 담는 통합 연결도를 그릴 경우, 두 노드 사이는
**TX/RX 라인만 연결**하면 됨 (GND는 각자 미연결 상태 유지, AXI/PS는
서로 무관). 마스터 측 대응 문서: `master_full_relations.md`.
