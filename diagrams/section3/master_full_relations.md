# 마스터 전체 기능 블록도 — 확정 요소/관계 (Section 3)

> 시각적 배치(layout)는 이후에도 조정될 수 있으나, 아래 요소와 관계는 확정됨.
> 원본 다이어그램 소스: `master_full_stack.mmd` (렌더: `master_full_stack.png`)
> 상태: 마스터 기능 블록도 확정 완료.

## 노드 (위치별 그룹)

### 외부
- 외부 테스트 장치 (EXT)

### GPIO (점선 경계, PS·PL 밖)
- GND (연결 없음)
- TX 포트 (TXP)
- RX 포트 (RXP)

### PS (점선 경계, main.c 기반)
- 인터럽트 초기화 (INIT)
- 마스터 설정 (CFG)
- UART 명령 인터페이스 (UARTCMD)
- 인터럽트 처리 (ISR)
- 상태 폴링 루프 (POLL)

### PL (점선 경계)
- LED
- DIP Switch
- Push Button (PB)
- 7-Segment (SEG)
- (TX/RX 포트는 GPIO 점선 블록 소속이며, LED·Master IP로의 연결만 PL 경계를 가로지름)

### Master IP (PL 내부, 점선 경계)
- AXI-Lite 레지스터 (AXI)
- 슬롯 스케줄러 (SLOT)
- NRZ 수신 (RX)
- Hamming 복호 (DEC)
- halt_cmd 판정 (HALT)
- NRZ 송신 (TX)

## 관계 (엣지)

| From | To | 라벨 | 비고 |
|---|---|---|---|
| EXT | UARTCMD | UART | 양방향 |
| CFG | AXI | AXI4-Lite (설정) | |
| POLL | AXI | AXI4-Lite (폴링) | 양방향 |
| ISR | AXI | AXI4-Lite (인터럽트) | 양방향 |
| INIT | CFG | | PS 내부 흐름 |
| CFG | POLL | | PS 내부 흐름 |
| UARTCMD | CFG | | PS 내부, 점선 |
| ISR | UARTCMD | 상태 로그 | PS 내부, 점선 |
| AXI | SLOT | DIV,GUARD_TICKS.. | |
| SLOT | RX | rx_stat | |
| RX | DEC | data_out | |
| DEC | HALT | err_cnt | |
| HALT | TX | halt_cmd | |
| HALT | DEC | halt_cmd | |
| SLOT | TX | slot,cycle_cnt | |
| DEC | AXI | slot_out,err_cnt | 점선(readback) |
| PB | AXI | resetn | |
| DIP | SEG | | |
| SLOT | SEG | | |
| DEC | SEG | | |
| TXP | LED | | |
| RXP | LED | | |
| TX | TXP | GPIO_out | |
| RXP | RX | GPIO_in | |

GND는 어떤 노드와도 연결되지 않음 (GPIO 점선 블록 내 단독 노드).

## 제외 사항
- 디스플레이/TFTLCD 관련 기능 (main.c의 픽셀 쓰기 로직 등) — 지원 중단으로 다이어그램에서 완전히 제외.

## 마스터-슬레이브 통합 연결도 참고
마스터와 슬레이브를 동시에 담는 통합 연결도를 그릴 경우, 두 노드 사이는
**TX/RX 라인만 연결**하면 됨 (GND는 각자 미연결 상태 유지, AXI/PS는
서로 무관). 슬레이브 측 대응 문서: `slave_full_relations.md`.
