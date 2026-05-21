# TDMA Master IP — 레지스터 맵 사양

> 버전: 0.3 (초안) · 데이터 폭: 32비트 · 주소 폭: 32비트 · 엔디언: little-endian · 비트 순서: MSB first
> 최대 슬레이브: 8개 (주소 0~7)

---

## 표기 규칙

| 기호 | 의미 |
|------|------|
| RW | 읽기/쓰기 |
| RO | 읽기 전용 |
| W1C | 쓰기 1로 클리어 |
| reserved | 0으로 읽힘, 쓰기 무시 |

---

## 1. 제어 레지스터

### 0x00 — CTRL

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 0 | ENABLE | RW | 0 | 1: IP 동작 시작. 0: 정지 |
| 1 | SOFT_RST | RW | 0 | 1: 소프트 리셋 (자동 클리어) |
| 31:2 | reserved | — | 0 | — |

---

### 0x04 — LINK_CFG

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 9:0 | DIV | RW | 0 | clk_tick = clk / (DIV + 1). 1~1024 분주 |
| 19:10 | GUARD_TICKS | RW | — | 슬롯 간 guard time 틱 수. GUARD_MIN 이상으로 설정 |
| 22:20 | RETRY_CNT | RW | 0 | 슬롯 내 재전송 횟수. 총 전송 = RETRY_CNT + 1 |
| 31:23 | reserved | — | 0 | — |

> 모든 노드의 LINK_CFG는 동일하게 설정해야 한다.

---

### 0x08 — NODE_CFG

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 2:0 | NODE_CNT | RW | 0 | 값 N → 슬레이브 0~N 활성. 최대 7 (8개) |
| 31:3 | reserved | — | 0 | — |

---

### 0x0C — FAULT_CFG

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 3:0 | FAULT_TH | RW | 3 | 데이터 fault 누적 임계값. FAULT_CNT ≥ FAULT_TH 시 격리 |
| 7:4 | RECOVERY_TH | RW | 3 | 데이터 fault 복구 연속 성공 횟수 |
| 11:8 | SYNC_FAULT_TH | RW | 3 | sync fault 누적 임계값 |
| 15:12 | SYNC_RECOVERY_TH | RW | 3 | sync fault 복구 연속 성공 횟수 |
| 19:16 | LINE_RECOVERY_TH | RW | 3 | 라인 복구 연속 정상 횟수 |
| 31:20 | reserved | — | 0 | — |

---

### 0x10 — DRIFT_TH

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 31:0 | DRIFT_TH | RW | — | 사이클 간 허용 드리프트 절댓값. `\|drift[n][k]\| > DRIFT_TH` 시 SYNC_FAULT 카운터 증가 |

---

### 0x14 — OFFSET_TH

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 31:0 | OFFSET_TH | RW | — | 허용 누적 오프셋 절댓값. `\|D[n][k]\| > OFFSET_TH` 시 즉시 CLOCK_FAULT |

---

## 2. 읽기 전용 계산값

### 0x18 — SLOT_TICKS

| 비트 | 이름 | 접근 | 설명 |
|------|------|------|------|
| 31:0 | SLOT_TICKS | RO | 하드웨어가 자동 계산한 슬롯 길이 (틱). DIV, RETRY_CNT, GUARD_TICKS로부터 산출 |

> `SLOT_TICKS = (RETRY_CNT+1) × frame_ticks + RETRY_CNT × IFG_ticks + GUARD_TICKS`
> `frame_ticks = 91 × 2 × (DIV+1)` (91비트 Manchester)
> `IFG_ticks = 2 × 2 × (DIV+1)` (2비트 idle)

---

### 0x1C — GUARD_MIN

| 비트 | 이름 | 접근 | 설명 |
|------|------|------|------|
| 31:0 | GUARD_MIN | RO | 하드웨어가 계산한 최소 guard time (틱). GUARD_TICKS는 이 값 이상으로 설정해야 함 |

> `GUARD_MIN = RX_PROCESS_CYCLES + CABLE_DELAY_TICKS + MARGIN` (구현 시 확정)

---

## 3. 타임스탬프

### 0x20 — TX_TICK

| 비트 | 이름 | 접근 | 설명 |
|------|------|------|------|
| 31:0 | TX_TICK | RO | 마스터가 가장 최근 브로드캐스트한 틱 값. 사이클마다 갱신 |

---

## 4. 노드별 수신 데이터 (×8)

기준 주소: `0x24 + n × 0x04`, n = 0~7

### NODE_DATA[n]

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 31:0 | RX_DATA | RO | 0 | 슬레이브 n의 최근 수신 payload (32비트) |

> 주소: [0]=0x24, [1]=0x28, [2]=0x2C, [3]=0x30, [4]=0x34, [5]=0x38, [6]=0x3C, [7]=0x40

---

## 5. 노드별 수신 틱 (×8)

기준 주소: `0x44 + n × 0x04`, n = 0~7

### NODE_TICK[n]

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 31:0 | RX_TICK | RO | 0 | 슬레이브 n으로부터 수신한 TX_TICK 값. 시간동기 계산에 사용 |

> 주소: [0]=0x44, [1]=0x48, [2]=0x4C, [3]=0x50, [4]=0x54, [5]=0x58, [6]=0x5C, [7]=0x60

---

## 6. 노드별 상태 (×8)

기준 주소: `0x64 + n × 0x04`, n = 0~7

### NODE_STATUS[n]

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 2:0 | STATE | RO | 000 | 슬레이브 n의 현재 상태 (아래 표 참조) |
| 6:3 | FAULT_CNT | RO | 0 | 데이터 fault 누적 카운터 |
| 10:7 | SYNC_FAULT_CNT | RO | 0 | sync fault 누적 카운터 |
| 14:11 | RECOV_CNT | RO | 0 | 복구 확인 연속 성공 카운터 |
| 15 | DATA_VALID | W1C | 0 | 1: 새 payload 수신됨 |
| 16 | PREAMBLE_ERR | W1C | 0 | 최근 슬롯 preamble 오류 |
| 17 | FRAME_ERR | W1C | 0 | 최근 슬롯 프레임 구조 오류 |
| 18 | CRC_ERR | W1C | 0 | 최근 슬롯 CRC 불일치 |
| 19 | ADDR_ERR | W1C | 0 | 최근 슬롯 주소 불일치 |
| 20 | SLOT_TIMEOUT | W1C | 0 | 최근 슬롯 무응답 |
| 21 | SYNC_FAULT_FLAG | W1C | 0 | sync fault 발생 |
| 22 | CLOCK_FAULT_FLAG | W1C | 0 | clock fault 발생 |
| 23 | LINE_FAULT_FLAG | W1C | 0 | 라인 fault 발생 |
| 31:24 | reserved | — | 0 | — |

**STATE 필드 인코딩:**

| 값 | 상태 | 설명 |
|----|------|------|
| 000 | INACTIVE | NODE_CNT 범위 밖, 비활성 |
| 001 | NORMAL | 정상 동작 |
| 010 | DATA_FAULT | 데이터 오류 누적, 격리 중 |
| 011 | DATA_RECOVERY | 데이터 복구 확인 중 |
| 100 | SYNC_FAULT | 드리프트 이상, 격리 중 |
| 101 | SYNC_RECOVERY | 드리프트 복구 확인 중 |
| 110 | LINE_FAULT | 물리 라인 이상, 격리 중 |
| 111 | CLOCK_FAULT | 클럭 근본 불일치, 영구 격리 |

> 주소: [0]=0x64, [1]=0x68, [2]=0x6C, [3]=0x70, [4]=0x74, [5]=0x78, [6]=0x7C, [7]=0x80

---

## 7. 글로벌 상태

### 0x84 — GLOBAL_STATUS

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | FAULT_MASK | RO | 0 | 비트 n = 1: 슬레이브 n이 임의 fault 상태 |
| 8 | BUS_ACTIVE | RO | 0 | 1: TDMA 버스 동작 중 |
| 31:9 | reserved | — | 0 | — |

---

### 0x88 — CYCLE_CNT

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 31:0 | CYCLE_CNT | RO | 0 | 완료된 TDMA 사이클 수. 래핑 카운터 |

---

## 8. 인터럽트

### 0x8C — IRQ_STATUS

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 0 | CYCLE_DONE | W1C | 0 | TDMA 사이클 1회 완료 |
| 1 | NODE_FAULT | W1C | 0 | 임의 노드 fault 상태 진입 |
| 2 | NODE_RECOVERY | W1C | 0 | 임의 노드 NORMAL 복구 |
| 3 | DATA_ERROR | W1C | 0 | 임의 노드 데이터 오류 (PREAMBLE/FRAME/CRC/ADDR/TIMEOUT) |
| 4 | SYNC_FAULT | W1C | 0 | 임의 노드 SYNC_FAULT 진입 |
| 5 | CLOCK_FAULT | W1C | 0 | 임의 노드 CLOCK_FAULT 진입 |
| 6 | LINE_FAULT | W1C | 0 | 임의 노드 LINE_FAULT 진입 |
| 31:7 | reserved | — | 0 | — |

---

### 0x90 — IRQ_MASK

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 0 | CYCLE_DONE_EN | RW | 0 | 1: CYCLE_DONE IRQ 활성화 |
| 1 | NODE_FAULT_EN | RW | 0 | 1: NODE_FAULT IRQ 활성화 |
| 2 | NODE_RECOVERY_EN | RW | 0 | 1: NODE_RECOVERY IRQ 활성화 |
| 3 | DATA_ERROR_EN | RW | 0 | 1: DATA_ERROR IRQ 활성화 |
| 4 | SYNC_FAULT_EN | RW | 0 | 1: SYNC_FAULT IRQ 활성화 |
| 5 | CLOCK_FAULT_EN | RW | 0 | 1: CLOCK_FAULT IRQ 활성화 |
| 6 | LINE_FAULT_EN | RW | 0 | 1: LINE_FAULT IRQ 활성화 |
| 31:7 | reserved | — | 0 | — |

> IRQ 핀 = OR(IRQ_STATUS & IRQ_MASK)
> 원인 파악 순서: IRQ_STATUS → GLOBAL_STATUS.FAULT_MASK → NODE_STATUS[n]

---

## 주소 맵 요약

| 범위 | 그룹 | 레지스터 수 |
|------|------|-------------|
| 0x00 ~ 0x14 | 제어 (CTRL, LINK_CFG, NODE_CFG, FAULT_CFG, DRIFT_TH, OFFSET_TH) | 6 |
| 0x18 ~ 0x1C | 읽기 전용 계산값 (SLOT_TICKS, GUARD_MIN) | 2 |
| 0x20 | 타임스탬프 (TX_TICK) | 1 |
| 0x24 ~ 0x40 | 노드별 수신 데이터 ×8 (NODE_DATA) | 8 |
| 0x44 ~ 0x60 | 노드별 수신 틱 ×8 (NODE_TICK) | 8 |
| 0x64 ~ 0x80 | 노드별 상태 ×8 (NODE_STATUS) | 8 |
| 0x84 ~ 0x88 | 글로벌 상태 (GLOBAL_STATUS, CYCLE_CNT) | 2 |
| 0x8C ~ 0x90 | 인터럽트 (IRQ_STATUS, IRQ_MASK) | 2 |
| **합계** | | **37개** |
