# TDMA IP 설계 개요

> 버전: 0.1 · 작성일: 2026-05-18
> 이 문서는 PHY부터 레지스터 맵까지 전체 설계를 한눈에 파악하기 위한 요약입니다.
> 각 항목의 상세 근거는 `phy_decisions.md`, `datalink_decisions.md`, `sync_decisions.md`, `fault_decisions.md`를 참조하세요.

---

## 중요?
vivado project를 git에서 공유하면 쓰레기 파일들?이 너무 많이 보이고 git 동기화가 오히려 괴로워질 것 같습니다.
project 없는(각자가 로컬로 구축하는) 환경을 만들고, v와 c코드 중점으로 동기화하면서 ip_repo까지만 공유하는 형식으로 가는 게 어떤가 싶네요(.zip으로)

## 1. 시스템 구성

```
        ┌─────────────────────────────────────────┐
        │                 Master                  │
        └──┬──────┬──────┬──── ... ────┬──────────┘
     TX 케이블 (Master → 모든 Slave, 브로드캐스트)
           │      │      │             │
     RX 케이블 (각 Slave → Master, 점대점)
           │      │      │             │
        Slave0  Slave1  Slave2  ...  Slave7
```

| 항목 | 사양 |
|------|------|
| 토폴로지 | 스타형, 마스터 1 + 슬레이브 최대 8 |
| 케이블 | TX / RX 이중 단방향 케이블 |
| 연결 방식 | 슬레이브별 점대점 (공유 버스 없음) |
| 슬레이브 주소 | 3비트 (0~7) |
| 기준 클럭 | 25 MHz (각 노드 독립 크리스탈) |

TX 케이블은 마스터가 모든 슬레이브에 동시에 브로드캐스트하는 전용선이고,
RX 케이블은 슬레이브마다 마스터에 연결된 독립선이다.
이중 케이블로 TX/RX가 물리적으로 분리되어 충돌 방지 로직이 불필요하다.

---

## 2. 물리 계층

| 항목 | 결정 |
|------|------|
| 비트 인코딩 | Manchester (셀프 클로킹, 별도 클럭선 불필요) |
| 비트 순서 | MSB first |
| 아이들 상태 | High |
| 단선 감지 | 수신 측 풀다운 저항 → 단선 시 라인이 Low로 내려감 |
| 전송 속도 | 125 kbps (DIV 설정으로 조정 가능) |

Manchester 인코딩은 비트 중간에 반드시 전이가 발생하므로, 수신 측이 클럭 선 없이 비트 타이밍을 복원한다. 각 노드가 독립 크리스탈을 사용하는 구성에서 필수적이다.

아이들을 High로 정의하면 케이블 단선(→ Low), 송신기 정지(→ High 유지), 프레임 시작(High→Low 전이) 세 가지를 명확히 구분할 수 있다.

---

## 3. 프레임 구조

### 슬레이브 → 마스터 (RX 케이블)

```
[preamble 8b][addr 3b][payload 32b][TX_TICK 32b][CRC-16 16b]
 ←──────────────────── 91비트 ────────────────────────────→
               └────────── CRC 커버 범위 ──────────────────┘
```

| 필드 | 설명 |
|------|------|
| preamble | 0x55 고정. 수신 측 비트 타이밍 복원용 |
| addr | 슬레이브 자신의 주소 (0~7). 마스터 슬롯 검증에 사용 |
| payload | 슬레이브 센서 데이터 32비트 |
| TX_TICK | 슬레이브 보정 타임스탬프 (`raw_counter + TICK_OFFSET`) |
| CRC-16 | CRC-16 CCITT (0x1021), addr부터 TX_TICK까지 커버 |

### 마스터 → 슬레이브 (TX 케이블, 브로드캐스트)

```
[preamble 8b][TX_TICK 32b][CRC-16 16b]
 ←────────────── 56비트 ─────────────→
               └── CRC 커버 범위 ────┘
```

마스터 브로드캐스트는 시간 동기용 틱 배포만이 목적이므로 최소 구조로 설계한다.

### 슬롯 내 재전송

```
[프레임][IFG 2b][프레임][IFG 2b] ... [프레임][guard time]
 ←──────────── RETRY_CNT + 1 회 ──────────────→
```

- IFG(Inter-Frame Gap) 2비트: RX 엔진이 CRC 검사 후 상태를 리셋할 여유 확보
- 재전송 시 TX_TICK 값은 첫 전송과 동일하게 유지 (타임스탬프 일관성)

---

## 4. 슬롯 타이밍

### 슬롯 길이 자동 계산

사용자가 슬롯 길이를 직접 설정하지 않는다. 하드웨어가 자동 계산한다.

```
frame_ticks = 91 × 2 × (DIV + 1)
IFG_ticks   =  2 × 2 × (DIV + 1)

slot_ticks  = (RETRY_CNT + 1) × frame_ticks
            + RETRY_CNT × IFG_ticks
            + GUARD_TICKS
```

계산 결과는 `SLOT_TICKS` (RO) 레지스터로 확인할 수 있다.
`GUARD_MIN` (RO) 레지스터는 하드웨어가 계산한 최소 guard time을 제공한다.

### 사이클 구조

```
사이클 시작
    │
    ├─ Master TX: 브로드캐스트 (TX_TICK 포함)
    │
    ├─ Slot 0: Slave 0 전송 (에지 감지 즉시)
    ├─ Slot 1: Slave 1 전송 (1 × slot_ticks 후)
    ├─ Slot 2: Slave 2 전송 (2 × slot_ticks 후)
    │   ...
    └─ Slot N: Slave N 전송 (N × slot_ticks 후)
```

슬레이브는 마스터 브로드캐스트의 첫 번째 falling edge를 감지한 순간부터 로컬 클럭으로 카운팅하여 자신의 슬롯 시작 시각을 결정한다.

fault 상태 슬레이브의 슬롯은 사이클에서 제거하지 않는다. 사이클 주기가 변하면 다른 슬레이브의 타이밍이 흔들리기 때문이다.

---

## 5. 시간 동기

마스터는 자유 진행 카운터를 기준으로 동작한다. 슬레이브가 마스터 기준에 맞춰 보정한다.

```
마스터: raw_counter (보정 없음)
슬레이브: raw_counter + TICK_OFFSET (→ 이것이 TX_TICK으로 전송됨)
```

### 드리프트 계산 (매 사이클)

**슬레이브 측:**
```
D[k]     = RX_TICK[k] - TX_TICK[k]   (수신한 마스터 틱 - 내가 보낸 틱)
drift[k] = D[k] - D[k-1]
```

**마스터 측 (슬레이브 n에 대해):**
```
D[n][k]     = NODE_TICK[n][k] - TX_TICK[k]
drift[n][k] = D[n][k] - D[n][k-1]
```

두 계산은 같은 물리적 클럭 차이를 각자 독립적으로 측정한다.

### 슬레이브 보정

guard time 진입 시 하드웨어가 자동으로:
```
TICK_OFFSET -= drift[k]
```

크리스탈 드리프트는 환경이 고정적이면 사실상 상수이므로, 전량 보정 1회 후 안정 상태가 유지된다.

---

## 6. Fault 체계

### 우선순위

```
CLOCK_FAULT > LINE_FAULT > SYNC_FAULT > DATA_FAULT
```

### Fault 종류 요약

| Fault | 감지 조건 | 감지 주체 | 복구 |
|-------|----------|----------|------|
| DATA_FAULT | PREAMBLE/FRAME/CRC/ADDR 오류 또는 타임아웃 누적 | 마스터 | 자동 (RECOVERY_TH 연속 성공) |
| SYNC_FAULT | `\|drift\| > DRIFT_TH` | 마스터 + 슬레이브 각자 | 자동 (슬레이브 1사이클 PAUSE) |
| CLOCK_FAULT | `\|D[k]\| > OFFSET_TH` (누적 오프셋 초과) | 마스터 전용 | 수동 (PS SOFT_RST) |
| LINE_FAULT | RX 라인 stuck Low (1사이클 확인) | 마스터 + 슬레이브 각자 | 자동 (LINE_RECOVERY_TH 연속 정상) |

### 마스터 상태 머신 (슬레이브 n별)

```
어느 상태에서든 CLOCK_FAULT → CLOCK_FAULT (PS 리셋만 복구)
CLOCK_FAULT 제외, 어느 상태에서든 LINE_FAULT → LINE_FAULT → (자동복구) → NORMAL

NORMAL
  ├─ FAULT_CNT ≥ FAULT_TH ──────────────▶ DATA_FAULT
  └─ SYNC_FAULT_CNT ≥ SYNC_FAULT_TH ───▶ SYNC_FAULT

DATA_FAULT ──(슬레이브 재개)──▶ DATA_RECOVERY ──(RECOVERY_TH 연속 성공)──▶ NORMAL
SYNC_FAULT ──(드리프트 정상)──▶ SYNC_RECOVERY ──(SYNC_RECOVERY_TH 연속)──▶ NORMAL
```

fault 상태에서도 슬롯은 유지하며 RX 윈도우를 열어 복구를 감시한다.

### 슬레이브 상태 머신

```
어느 상태에서든 LINE_FAULT → DEAD → (자동복구) → NORMAL

NORMAL
  ├─ |drift| > DRIFT_TH ──▶ PAUSE (1사이클) ──▶ NORMAL (자동 복귀)
  └─ FAULT_CNT ≥ FAULT_TH ▶ FAULT ──(유효 브로드캐스트)──▶ RECOVERY ──▶ NORMAL
```

---

## 7. 레지스터 맵 요약

### 마스터 (총 37개, 0x00~0x90)

| 범위 | 그룹 |
|------|------|
| 0x00~0x14 | 제어: CTRL, LINK_CFG, NODE_CFG, FAULT_CFG, DRIFT_TH, OFFSET_TH |
| 0x18~0x1C | 읽기 전용 계산값: SLOT_TICKS, GUARD_MIN |
| 0x20 | 타임스탬프: TX_TICK |
| 0x24~0x40 | 노드별 수신 데이터: NODE_DATA[0~7] |
| 0x44~0x60 | 노드별 수신 틱: NODE_TICK[0~7] |
| 0x64~0x80 | 노드별 상태: NODE_STATUS[0~7] |
| 0x84~0x88 | 글로벌 상태: GLOBAL_STATUS, CYCLE_CNT |
| 0x8C~0x90 | 인터럽트: IRQ_STATUS, IRQ_MASK |

NODE_STATUS[n]의 STATE 인코딩:
`000`=INACTIVE · `001`=NORMAL · `010`=DATA_FAULT · `011`=DATA_RECOVERY
`100`=SYNC_FAULT · `101`=SYNC_RECOVERY · `110`=LINE_FAULT · `111`=CLOCK_FAULT

### 슬레이브 (총 12개, 0x00~0x2C)

| 주소 | 레지스터 | 설명 |
|------|---------|------|
| 0x00 | CTRL | ENABLE, SOFT_RST |
| 0x04 | LINK_CFG | DIV, GUARD_TICKS, RETRY_CNT (마스터와 동일 설정) |
| 0x08 | SLAVE_CFG | SLAVE_ADDR[2:0] |
| 0x0C | FAULT_CFG | FAULT_TH, RECOVERY_TH, LINE_RECOVERY_TH |
| 0x10 | DRIFT_TH | 드리프트 허용 임계값 |
| 0x14 | TX_DATA | 송신 payload (PS 갱신) |
| 0x18 | TX_TICK | 최근 전송 타임스탬프 (RO) |
| 0x1C | RX_TICK | 최근 수신 마스터 틱 (RO) |
| 0x20 | TICK_OFFSET | 보정 오프셋 (HW 자동 갱신, PS 읽기/쓰기 가능) |
| 0x24 | STATUS | STATE, FAULT_CNT, RECOV_CNT, 오류 플래그 |
| 0x28 | IRQ_STATUS | 인터럽트 상태 |
| 0x2C | IRQ_MASK | 인터럽트 마스크 |

STATUS의 STATE 인코딩:
`000`=IDLE · `001`=NORMAL · `010`=PAUSE · `011`=FAULT · `100`=RECOVERY · `101`=DEAD

---

## 8. 설정 초기화 순서 (예시)

```
1. LINK_CFG 설정 (모든 노드 동일: DIV, GUARD_TICKS, RETRY_CNT)
2. 마스터: NODE_CFG.NODE_CNT 설정 (활성 슬레이브 수)
3. 마스터: FAULT_CFG, DRIFT_TH, OFFSET_TH 설정
4. 슬레이브: SLAVE_CFG.SLAVE_ADDR 설정 (각자 다르게)
5. 슬레이브: FAULT_CFG, DRIFT_TH 설정
6. CTRL.ENABLE = 1 (마스터 먼저, 이후 슬레이브 순서 무관)
   → 슬레이브는 첫 브로드캐스트 falling edge 감지 시 자동 동기 획득
```

---

## 9. 관련 문서

| 문서 | 내용 |
|------|------|
| `01_phy_decisions.md` | 물리 계층 설계 근거 (케이블, Manchester, 아이들 상태) |
| `02_datalink_decisions.md` | 프레임 구조, CRC, 슬롯 타이밍, MAC 결정 근거 |
| `03_sync_decisions.md` | 시간 동기 메커니즘, TICK_OFFSET 보정, Fault 분류 근거 |
| `04_fault_decisions.md` | Fault 분류 체계, 상태 머신 상세, 임계값 레지스터 목록 |
| `05_master_regmap.md` | 마스터 레지스터 맵 전체 사양 |
| `06_slave_regmap.md` | 슬레이브 레지스터 맵 전체 사양 |
