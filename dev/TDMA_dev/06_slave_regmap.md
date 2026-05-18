# TDMA Slave IP — 레지스터 맵 사양

> 버전: 0.1 (초안) · 데이터 폭: 32비트 · 주소 폭: 32비트 · 엔디언: little-endian · 비트 순서: MSB first

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
| 9:0 | DIV | RW | 0 | clk_tick = clk / (DIV + 1). 마스터와 동일하게 설정 |
| 19:10 | GUARD_TICKS | RW | — | 슬롯 간 guard time 틱 수. 마스터와 동일하게 설정 |
| 22:20 | RETRY_CNT | RW | 0 | 슬롯 내 재전송 횟수. 마스터와 동일하게 설정 |
| 31:23 | reserved | — | 0 | — |

> 모든 노드의 LINK_CFG는 동일하게 설정해야 한다.

---

### 0x08 — SLAVE_CFG

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 2:0 | SLAVE_ADDR | RW | 0 | 이 슬레이브의 주소 (0~7). 프레임 addr 필드 및 슬롯 오프셋 계산에 사용 |
| 31:3 | reserved | — | 0 | — |

---

### 0x0C — FAULT_CFG

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 3:0 | FAULT_TH | RW | 3 | FAULT_CNT 임계값. FAULT_CNT ≥ FAULT_TH 시 FAULT 진입 |
| 7:4 | RECOVERY_TH | RW | 3 | 복구 확인 연속 성공 횟수 |
| 11:8 | LINE_RECOVERY_TH | RW | 3 | 라인 복구 연속 정상 횟수 |
| 31:12 | reserved | — | 0 | — |

---

### 0x10 — DRIFT_TH

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 31:0 | DRIFT_TH | RW | — | 사이클 간 허용 드리프트 절댓값. `\|drift[k]\| > DRIFT_TH` 시 SYNC_FAULT |

---

## 2. 송신 데이터

### 0x14 — TX_DATA

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 31:0 | TX_DATA | RW | 0 | 다음 슬롯에 전송할 payload (32비트). 슬롯 시작 전 갱신 |

---

## 3. 타임스탬프

### 0x18 — TX_TICK

| 비트 | 이름 | 접근 | 설명 |
|------|------|------|------|
| 31:0 | TX_TICK | RO | 가장 최근 슬롯에 전송한 타임스탬프 값. `raw_counter + TICK_OFFSET` |

---

### 0x1C — RX_TICK

| 비트 | 이름 | 접근 | 설명 |
|------|------|------|------|
| 31:0 | RX_TICK | RO | 가장 최근 수신한 마스터 브로드캐스트의 TX_TICK 값 |

---

### 0x20 — TICK_OFFSET

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 31:0 | TICK_OFFSET | RW | 0 | 슬레이브 로컬 카운터 보정 오프셋. guard time마다 하드웨어 자동 갱신. PS도 읽기/쓰기 가능 |

> `TX_TICK = raw_counter + TICK_OFFSET`
>
> guard time 진입 시 하드웨어가 자동으로 `TICK_OFFSET -= drift[k]` 적용.
> 초기값은 0. 첫 브로드캐스트 수신 시 자동 보정 시작.

---

## 4. 상태

### 0x24 — STATUS

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 2:0 | STATE | RO | 000 | 슬레이브 현재 상태 (아래 표 참조) |
| 6:3 | FAULT_CNT | RO | 0 | fault 누적 카운터 (SYNC_MISS + BROADCAST_CRC_ERR 통합) |
| 10:7 | RECOV_CNT | RO | 0 | 복구 확인 연속 성공 카운터 |
| 11 | DATA_SENT | W1C | 0 | 1: 직전 슬롯 전송 완료 |
| 12 | SYNC_MISS | W1C | 0 | 예상 사이클 내 마스터 브로드캐스트 미수신 |
| 13 | BROADCAST_CRC_ERR | W1C | 0 | 마스터 브로드캐스트 CRC-16 불일치 |
| 14 | SYNC_FAULT_FLAG | W1C | 0 | SYNC_FAULT 감지 (`\|drift[k]\| > DRIFT_TH`) |
| 15 | LINE_FAULT_FLAG | W1C | 0 | LINE_FAULT 감지 (RX 라인 stuck Low) |
| 31:16 | reserved | — | 0 | — |

**STATE 필드 인코딩:**

| 값 | 상태 | 설명 |
|----|------|------|
| 000 | IDLE | ENABLE 비활성, 대기 중 |
| 001 | NORMAL | 정상 동작, 매 슬롯 전송, 드리프트 보정 |
| 010 | PAUSE | SYNC_FAULT 자율 감지, 1사이클 전송 중단 |
| 011 | FAULT | FAULT_CNT ≥ FAULT_TH, 전송 중단 |
| 100 | RECOVERY | 복구 확인 중 |
| 101 | DEAD | LINE_FAULT, RX 라인 이상 |
| 110 | reserved | — |
| 111 | reserved | — |

---

## 5. 인터럽트

### 0x28 — IRQ_STATUS

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 0 | SLOT_DONE | W1C | 0 | 슬롯 전송 1회 완료 |
| 1 | SYNC_ACQUIRED | W1C | 0 | 첫 브로드캐스트 수신, 동기 획득 |
| 2 | FAULT_ENTRY | W1C | 0 | FAULT 또는 DEAD 상태 진입 |
| 3 | RECOVERY_DONE | W1C | 0 | NORMAL 복구 완료 |
| 4 | SYNC_FAULT | W1C | 0 | SYNC_FAULT 감지 (PAUSE 진입) |
| 5 | LINE_FAULT | W1C | 0 | LINE_FAULT 감지 (DEAD 진입) |
| 31:6 | reserved | — | 0 | — |

---

### 0x2C — IRQ_MASK

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 0 | SLOT_DONE_EN | RW | 0 | 1: SLOT_DONE IRQ 활성화 |
| 1 | SYNC_ACQUIRED_EN | RW | 0 | 1: SYNC_ACQUIRED IRQ 활성화 |
| 2 | FAULT_ENTRY_EN | RW | 0 | 1: FAULT_ENTRY IRQ 활성화 |
| 3 | RECOVERY_DONE_EN | RW | 0 | 1: RECOVERY_DONE IRQ 활성화 |
| 4 | SYNC_FAULT_EN | RW | 0 | 1: SYNC_FAULT IRQ 활성화 |
| 5 | LINE_FAULT_EN | RW | 0 | 1: LINE_FAULT IRQ 활성화 |
| 31:6 | reserved | — | 0 | — |

> IRQ 핀 = OR(IRQ_STATUS & IRQ_MASK)

---

## 주소 맵 요약

| 주소 | 레지스터 | 접근 |
|------|---------|------|
| 0x00 | CTRL | RW |
| 0x04 | LINK_CFG | RW |
| 0x08 | SLAVE_CFG | RW |
| 0x0C | FAULT_CFG | RW |
| 0x10 | DRIFT_TH | RW |
| 0x14 | TX_DATA | RW |
| 0x18 | TX_TICK | RO |
| 0x1C | RX_TICK | RO |
| 0x20 | TICK_OFFSET | RW (HW 자동 갱신) |
| 0x24 | STATUS | RO / W1C |
| 0x28 | IRQ_STATUS | W1C |
| 0x2C | IRQ_MASK | RW |

**합계: 12개**
