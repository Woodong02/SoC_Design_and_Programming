# TDMA Master IP — 레지스터 맵 사양

> 버전: 0.4 · 데이터 폭: 32비트 · 주소 폭: 32비트 · 엔디언: little-endian · 비트 순서: MSB first
> 최대 슬레이브: 8개 (주소 0~7)
> v0.4 변경: TX_TICK·NODE_TICK·NODE_OFFSET 삭제, FAULT_CFG 단순화 (RECOVERY_TH·SYNC 항목 삭제), 레지스터 44→27개

---

## 표기 규칙

| 기호 | 의미 |
|------|------|
| RW | 읽기/쓰기 |
| RO | 읽기 전용 |
| W1C | 쓰기 1로 클리어 |
| RW† | PS 읽기/쓰기 + HW 자동 세팅 가능 |
| reserved | 0으로 읽힘, 쓰기 무시 |

---

## 1. 제어 레지스터

### 0x00 — CTRL

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 0 | ENABLE | RW | 0 | 1: IP 동작 시작. 0: 정지 |
| 1 | SOFT_RST | RW | 0 | 1: 소프트 리셋 (자동 클리어). HALT_CMD 및 모든 카운터 초기화 |
| 31:2 | reserved | — | 0 | — |

---

### 0x04 — LINK_CFG

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 9:0 | DIV | RW | 0 | clk_tick 반주기 = clk / (DIV+1). Manchester 비트 주기 = 2×(DIV+1) clk 사이클 |
| 19:10 | GUARD_TICKS | RW | — | 슬롯 간 guard time (clk 사이클 단위). GUARD_MIN_RO 이상으로 설정 |
| 31:20 | reserved | — | 0 | — |

> 모든 노드의 LINK_CFG는 동일하게 설정해야 한다. LINK_CFG 변경 시 SLOT_TICKS_RO·GUARD_MIN_RO가 자동 갱신된다.

---

### 0x08 — NODE_CFG

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 2:0 | NODE_CNT | RW | 0 | 값 N → 슬레이브 0~N 활성 (총 N+1개). 최대 7 (8개 슬레이브) |
| 31:3 | reserved | — | 0 | — |

---

### 0x0C — FAULT_CFG

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | FAULT_TH | RW | 30 | FAULT_CNT 포화 임계값. 허용 오류 횟수 ≈ FAULT_TH / 10. 복구 소요 사이클 ≈ FAULT_TH |
| 15:8 | LINE_FAULT_TH | RW | 30 | LINE_CNT 포화 임계값. 라인 이상 허용 횟수 ≈ LINE_FAULT_TH / 10 |
| 31:16 | reserved | — | 0 | — |

> 카운터 동작: 위반 이벤트 +10 (포화), 정상 수신 −1 (하한 0). 임계값 도달 시 fault 진입. 0 복귀 시 NORMAL 복귀. 상세 규칙은 `04_fault_decisions(4).md` §2 참조.

---

### 0x10 — HALT_CMD

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | HALT_CMD | RW† | 0 | 슬레이브 중단 명령 비트맵. bit n=1이면 슬레이브 n에 다음 브로드캐스트부터 중단 명령 전달 |
| 31:8 | reserved | — | 0 | — |

> HW 자동 세팅 조건: ADDR_ERR 감지 시 addr 필드에 식별된 침범 슬레이브(rx_addr)의 비트를 자동으로 1로 세팅. PS는 언제든 읽기/쓰기 가능. SOFT_RST 시 전체 클리어.

---

## 2. 읽기 전용 계산값

### 0x14 — SLOT_TICKS_RO

| 비트 | 이름 | 접근 | 설명 |
|------|------|------|------|
| 31:0 | SLOT_TICKS | RO | 하드웨어 자동 계산 슬롯 길이 (clk 사이클). `slot_ticks = 50 × 2 × (DIV+1) + GUARD_TICKS` |

---

### 0x18 — GUARD_MIN_RO

| 비트 | 이름 | 접근 | 설명 |
|------|------|------|------|
| 31:0 | GUARD_MIN | RO | 하드웨어 계산 최소 guard time (clk 사이클). `GUARD_TICKS ≥ 이 값` 조건 확인용. `GUARD_MIN = RX_PROCESS_CYCLES + CABLE_DELAY + BUS_TURNAROUND + DRIFT_MARGIN` |

---

## 3. 글로벌 상태

### 0x1C — GLOBAL_STATUS

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | FAULT_MASK | RO | 0 | bit n=1: 슬레이브 n이 DATA_FAULT·DATA_RECOVERY·LINE_FAULT 중 하나 |
| 8 | BUS_ACTIVE | RO | 0 | 1: TDMA 버스 동작 중 (ENABLE=1, 사이클 진행 중) |
| 31:9 | reserved | — | 0 | — |

---

### 0x20 — CYCLE_CNT

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 31:0 | CYCLE_CNT | RO | 0 | 완료된 TDMA 사이클 수. 32비트 랩핑 카운터 |

---

## 4. 노드별 수신 데이터 (×8)

기준 주소: `0x24 + n × 0x04`, n = 0~7

### NODE_DATA[n]

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 31:0 | RX_DATA | RO | 0 | 슬레이브 n의 최근 수신 payload (32비트). NODE_STATUS[n].DATA_VALID 세팅 시점에 갱신 |

> 주소: [0]=0x24, [1]=0x28, [2]=0x2C, [3]=0x30, [4]=0x34, [5]=0x38, [6]=0x3C, [7]=0x40

---

## 5. 노드별 상태 (×8)

기준 주소: `0x44 + n × 0x04`, n = 0~7

### NODE_STATUS[n]

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 2:0 | STATE | RO | 000 | 슬레이브 n의 현재 마스터 FSM 상태 (아래 표 참조) |
| 10:3 | FAULT_CNT | RO | 0 | 데이터 fault 카운터 현재값 (0~FAULT_TH) |
| 18:11 | LINE_CNT | RO | 0 | 라인 fault 카운터 현재값 (0~LINE_FAULT_TH) |
| 19 | DATA_VALID | W1C | 0 | 1: 새 유효 payload 수신 완료 (NODE_DATA[n] 갱신됨) |
| 20 | SLOT_TIMEOUT_FLAG | W1C | 0 | 최근 슬롯에서 SLOT_TIMEOUT 발생 (FAULT_CNT +10 적용됨) |
| 21 | FRAME_ERR_FLAG | W1C | 0 | 최근 슬롯에서 FRAME_ERR 발생 |
| 22 | HAMMING_ERR_FLAG | W1C | 0 | 최근 슬롯에서 Hamming 2비트 오류 발생 |
| 23 | PREAMBLE_ERR_FLAG | W1C | 0 | 최근 슬롯에서 PREAMBLE_ERR 발생 (LINE_CNT +10 적용됨) |
| 24 | ADDR_ERR_FLAG | W1C | 0 | 최근 슬롯에서 ADDR_ERR 발생. 침범 슬레이브에 HALT_CMD 자동 세팅됨 |
| 31:25 | reserved | — | 0 | — |

**STATE 필드 인코딩:**

| 값 | 상태 | 설명 |
|----|------|------|
| 000 | INACTIVE | NODE_CNT 범위 밖, 비활성 |
| 001 | NORMAL | 정상 동작 (FAULT_CNT < FAULT_TH) |
| 010 | DATA_RECOVERY | FAULT_CNT < FAULT_TH, DATA_FAULT에서 복구 중 |
| 011 | DATA_FAULT | FAULT_CNT ≥ FAULT_TH, 슬롯 격리 |
| 100 | LINE_FAULT | LINE_CNT ≥ LINE_FAULT_TH, 공유 버스 이상 |
| 101~111 | reserved | — |

> 주소: [0]=0x44, [1]=0x48, [2]=0x4C, [3]=0x50, [4]=0x54, [5]=0x58, [6]=0x5C, [7]=0x60

---

## 6. 인터럽트

### 0x64 — IRQ_STATUS

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 0 | CYCLE_DONE | W1C | 0 | TDMA 사이클 1회 완료 |
| 1 | NODE_FAULT | W1C | 0 | 임의 노드가 DATA_FAULT 또는 LINE_FAULT 상태 진입 |
| 2 | NODE_RECOVERY | W1C | 0 | 임의 노드가 NORMAL 복귀 (DATA_RECOVERY → NORMAL) |
| 3 | DATA_ERROR | W1C | 0 | 임의 노드에서 SLOT_TIMEOUT·FRAME_ERR·HAMMING_ERR 발생 |
| 4 | LINE_FAULT_IRQ | W1C | 0 | 임의 노드가 LINE_FAULT 상태 진입 |
| 5 | ADDR_ERR_IRQ | W1C | 0 | ADDR_ERR 감지. HALT_CMD 자동 세팅됨 |
| 31:6 | reserved | — | 0 | — |

---

### 0x68 — IRQ_MASK

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 0 | CYCLE_DONE_EN | RW | 0 | 1: CYCLE_DONE IRQ 활성화 |
| 1 | NODE_FAULT_EN | RW | 0 | 1: NODE_FAULT IRQ 활성화 |
| 2 | NODE_RECOVERY_EN | RW | 0 | 1: NODE_RECOVERY IRQ 활성화 |
| 3 | DATA_ERROR_EN | RW | 0 | 1: DATA_ERROR IRQ 활성화 |
| 4 | LINE_FAULT_EN | RW | 0 | 1: LINE_FAULT_IRQ 활성화 |
| 5 | ADDR_ERR_EN | RW | 0 | 1: ADDR_ERR_IRQ 활성화 |
| 31:6 | reserved | — | 0 | — |

> IRQ 핀 = OR(IRQ_STATUS & IRQ_MASK)
> 원인 파악 순서: IRQ_STATUS → GLOBAL_STATUS.FAULT_MASK → NODE_STATUS[n]

---

## 주소 맵 요약

| 범위 | 그룹 | 레지스터 수 |
|------|------|-------------|
| 0x00~0x10 | 제어 (CTRL, LINK_CFG, NODE_CFG, FAULT_CFG, HALT_CMD) | 5 |
| 0x14~0x18 | 읽기 전용 계산값 (SLOT_TICKS_RO, GUARD_MIN_RO) | 2 |
| 0x1C~0x20 | 글로벌 상태 (GLOBAL_STATUS, CYCLE_CNT) | 2 |
| 0x24~0x40 | 노드별 수신 데이터 ×8 (NODE_DATA) | 8 |
| 0x44~0x60 | 노드별 상태 ×8 (NODE_STATUS) | 8 |
| 0x64~0x68 | 인터럽트 (IRQ_STATUS, IRQ_MASK) | 2 |
| **합계** | | **27개** |

---

## 설정 초기화 순서

```
1. LINK_CFG 설정 (모든 노드 동일: DIV, GUARD_TICKS)
2. GUARD_MIN_RO 확인 → GUARD_TICKS ≥ GUARD_MIN_RO 검증
3. NODE_CFG.NODE_CNT 설정
4. FAULT_CFG 설정 (FAULT_TH, LINE_FAULT_TH)
5. IRQ_MASK 설정 (필요한 인터럽트 활성화)
6. CTRL.ENABLE = 1
```
