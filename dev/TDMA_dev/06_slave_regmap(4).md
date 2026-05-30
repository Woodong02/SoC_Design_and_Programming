# TDMA Slave IP — 레지스터 맵 사양

> 버전: 0.6
> 작성일: 2026-05-30
> v0.6 변경 : GUARD_TICKS 수신 추가

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
| 0 | ENABLE | RW | 0 | 1: 슬레이브 동작 시작 (TX 라인 모니터링 → 액티브 에지 대기). 0: 정지 |
| 1 | SOFT_RST | RW | 0 | 1: 소프트 리셋 (자동 클리어). 모든 카운터 및 FSM 초기화 |
| 31:2 | reserved | — | 0 | — |

---

### 0x04 — LINK_CFG

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 9:0 | DIV | RW | 0 | clk_tick 반주기 = clk / (DIV+1). Manchester 비트 주기 = 2×(DIV+1) clk 사이클 |
| 19:10 | GUARD_TICKS | RW | — | 슬롯 간 guard time (clk 사이클 단위) |
| 31:20 | reserved | — | 0 | — |

> ~**모든 노드의 LINK_CFG는 마스터와 동일하게 설정해야 한다.**~ GUARD_TICKS는 매 사이클마다 Master가 Slave에게 브로드캐스팅한다. DIV 값은 노드 자체 설정을 유지한다.


---

### 0x08 — SLAVE_CFG

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 2:0 | SLAVE_ADDR | RW | 0 | 슬레이브 자신의 주소 (0~7). 전송 프레임 addr 필드에 삽입. 마스터 NODE_CNT 범위 내여야 한다 |
| 31:3 | reserved | — | 0 | — |

---

### 0x0C — FAULT_CFG

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | FAULT_TH | RW | 30 | FAULT_CNT 포화 임계값. 허용 오류 횟수 ≈ FAULT_TH / 10. 복구 소요 사이클 ≈ FAULT_TH |
| 15:8 | LINE_FAULT_TH | RW | 30 | LINE_CNT 포화 임계값. 브로드캐스트 미수신 허용 횟수 ≈ LINE_FAULT_TH / 10 |
| 31:16 | reserved | — | 0 | — |

> 카운터 동작: 위반 이벤트 +10 (포화), 정상 이벤트 −1 (하한 0). 임계값 도달 시 fault 진입. 0 복귀 시 NORMAL 복귀. 상세 규칙은 `04_fault_decisions(4).md` §2 참조.
> 마스터의 FAULT_CFG와 동일한 값으로 설정하는 것을 권장한다.

---

## 2. 송신 데이터

### 0x10 — TX_DATA

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 31:0 | TX_DATA | RW | 0 | 다음 슬롯에 전송할 32비트 payload. 슬롯 전송 직전 래치됨 |

> 슬롯이 시작되면 이 값이 내부 전송 버퍼에 복사된다. 슬롯 진행 중 TX_DATA를 변경해도 현재 슬롯 전송에는 영향 없다.

---

## 3. 상태

### 0x14 — STATUS

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 2:0 | STATE | RO | 000 | 슬레이브 FSM 현재 상태 (아래 표 참조) |
| 10:3 | FAULT_CNT | RO | 0 | 데이터 fault 카운터 현재값 (0~FAULT_TH) |
| 18:11 | LINE_CNT | RO | 0 | 라인 fault 카운터 현재값 (0~LINE_FAULT_TH) |
| 19 | DATA_SENT | W1C | 0 | 1: 직전 슬롯에서 payload 전송 완료 (TX 버퍼 전송 후 세팅) |
| 20 | NO_BROADCAST_FLAG | W1C | 0 | 1: watchdog 타임아웃 발생 (LINE_CNT +10 적용됨) |
| 21 | BROADCAST_HAMMING_ERR_FLAG | W1C | 0 | 1: 마스터 브로드캐스트에서 Hamming 2비트 오류 감지 (FAULT_CNT +10 적용됨) |
| 22 | HALT_CMD_FLAG | W1C | 0 | 1: 마스터 브로드캐스트에서 자신의 HALT_CMD 비트 수신. 즉시 FAULT 진입 |
| 31:23 | reserved | — | 0 | — |

**STATE 필드 인코딩:**

| 값 | 상태 | 설명 |
|----|------|------|
| 000 | IDLE | ENABLE=0 또는 액티브 에지 미수신, 동기 미획득 |
| 001 | NORMAL | 정상 동작 (FAULT_CNT < FAULT_TH, LINE_CNT < LINE_FAULT_TH) |
| 010 | DATA_RECOVERY | DATA_FAULT 복구 중 (FAULT_CNT < FAULT_TH로 하강, 아직 0 미도달) |
| 011 | FAULT | FAULT_CNT ≥ FAULT_TH. 슬롯에서 TX 중단 (High-Z 유지) |
| 100 | DEAD | LINE_CNT ≥ LINE_FAULT_TH. 공유 버스 이상, TX 중단 |
| 101~111 | reserved | — |

---

## 4. 인터럽트

### 0x18 — IRQ_STATUS

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 0 | DATA_SENT_IRQ | W1C | 0 | payload 전송 완료 |
| 1 | NO_BROADCAST_IRQ | W1C | 0 | 브로드캐스트 미수신 (watchdog 타임아웃) |
| 2 | BROADCAST_HAMMING_ERR_IRQ | W1C | 0 | 마스터 브로드캐스트 Hamming 2비트 오류 |
| 3 | HALT_CMD_IRQ | W1C | 0 | 마스터로부터 HALT_CMD 수신 |
| 4 | STATE_CHANGE_IRQ | W1C | 0 | FSM 상태 전이 발생 (NORMAL↔DATA_RECOVERY↔FAULT, DEAD 진입/복귀 포함) |
| 31:5 | reserved | — | 0 | — |

---

### 0x1C — IRQ_MASK

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 0 | DATA_SENT_EN | RW | 0 | 1: DATA_SENT_IRQ 활성화 |
| 1 | NO_BROADCAST_EN | RW | 0 | 1: NO_BROADCAST_IRQ 활성화 |
| 2 | BROADCAST_HAMMING_ERR_EN | RW | 0 | 1: BROADCAST_HAMMING_ERR_IRQ 활성화 |
| 3 | HALT_CMD_EN | RW | 0 | 1: HALT_CMD_IRQ 활성화 |
| 4 | STATE_CHANGE_EN | RW | 0 | 1: STATE_CHANGE_IRQ 활성화 |
| 31:5 | reserved | — | 0 | — |

> IRQ 핀 = OR(IRQ_STATUS & IRQ_MASK)
> 원인 파악 순서: IRQ_STATUS → STATUS.STATE → STATUS.FAULT_CNT / LINE_CNT

---

## 주소 맵 요약

| 주소 | 레지스터 | 접근 | 설명 |
|------|----------|------|------|
| 0x00 | CTRL | RW | ENABLE, SOFT_RST |
| 0x04 | LINK_CFG | RW | DIV, GUARD_TICKS (마스터와 동일 설정 필수) |
| 0x08 | SLAVE_CFG | RW | SLAVE_ADDR |
| 0x0C | FAULT_CFG | RW | FAULT_TH, LINE_FAULT_TH |
| 0x10 | TX_DATA | RW | 송신 payload (32비트) |
| 0x14 | STATUS | RO/W1C | STATE, FAULT_CNT, LINE_CNT, 이벤트 플래그 |
| 0x18 | IRQ_STATUS | W1C | 인터럽트 상태 |
| 0x1C | IRQ_MASK | RW | 인터럽트 마스크 |
| **합계** | | | **8개** |

---

## 설정 초기화 순서

```
1. LINK_CFG 설정 (마스터와 동일: DIV, GUARD_TICKS)
2. SLAVE_CFG.SLAVE_ADDR 설정 (마스터 NODE_CNT 범위 내)
3. FAULT_CFG 설정 (FAULT_TH, LINE_FAULT_TH)
4. TX_DATA 초기값 설정
5. IRQ_MASK 설정 (필요한 인터럽트 활성화)
6. CTRL.ENABLE = 1 → TX 라인 모니터링 시작, 첫 액티브 에지 대기
```

> ENABLE 이후 마스터의 첫 번째 브로드캐스트에서 액티브 에지를 감지하면 자동으로 동기가 성립한다 (STATUS.STATE: IDLE → NORMAL).
