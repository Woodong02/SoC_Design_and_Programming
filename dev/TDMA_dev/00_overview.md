# TDMA IP 설계 개요

> 버전: 0.4 · 작성일: 2026-05-21
> 이 문서는 PHY부터 레지스터 맵까지 전체 설계를 한눈에 파악하기 위한 요약이다.
> 각 항목의 상세 근거는 01~06 문서, 포트 정의는 07~08 문서를 참조한다.

---

## 1. 시스템 구성

```
        ┌─────────────────────────────────────────┐
        │                 Master                  │
        └────────────────────┬────────────────────┘
                             │ TX 케이블 (Master → 모든 Slave, 브로드캐스트)
              ┌──────────────┼──────────────┐
           Slave0          Slave1  ...    Slave7
              │              │              │
              └──────────────┴──────────────┘
                    공유 RX 버스 (모든 Slave → Master)
                    각 Slave는 자신의 TDMA 슬롯에서만 구동
                    슬롯 외 구간: High-Z (삼상 개방)
```

| 항목 | 사양 |
|------|------|
| 토폴로지 | 마스터 1 + 슬레이브 최대 8 |
| TX 케이블 | 마스터 브로드캐스트 전용. 슬레이브 전체 공유 |
| RX 케이블 | 슬레이브 전체가 공유하는 단일 버스. TDMA로 충돌 방지 |
| 슬레이브 주소 | 3비트 (0~7) |
| 기준 클럭 | 25 MHz. 동일 생산 공정 별도 크리스탈 (미세 주파수 편차 존재) |
| 전송 속도 | 125 kbps (DIV 설정으로 조정 가능) |

공유 RX 버스에서 High-Z는 동작의 전제 조건이다. 슬롯 외 구간에 드라이버가 능동 구동하면 버스 경합이 발생한다. TDMA 슬롯 분리가 충돌을 구조적으로 방지하므로 별도 중재 로직이 불필요하다.

---

## 2. 물리 계층

| 항목       | 결정                                                   |
| -------- | ---------------------------------------------------- |
| 비트 인코딩   | Manchester (셀프 클로킹, 별도 클럭선 불필요)                      |
| 비트 순서    | MSB first                                            |
| 아이들 상태   | High-Z (삼상 개방). 슬롯 외 구간 및 전송 미수행 시                   |
| 라인 이상 감지 | preamble(0x55) 미검출 LINE_RECOVERY_TH회 연속 → LINE_FAULT |
| 종단 저항    | 없음 (50cm 단거리, 125kbps 저속에서 불필요)                      |

Manchester 인코딩은 비트 중간에 반드시 전이가 발생하므로 수신 측이 클럭 선 없이 비트 타이밍을 복원한다. 아이들 상태를 High-Z로 정의하면 슬레이브가 공유 RX 버스를 시분할로 구동할 수 있다.

---

## 3. 프레임 구조

### 슬레이브 → 마스터 (공유 RX 버스)

```
[preamble 8b][addr 3b][payload 32b][TX_TICK 32b][Hamming 8b]
 ←────────────────────── 83비트 ──────────────────────────→
              └────────── Hamming 커버 (67비트) ──────────┘
```

| 필드 | 설명 |
|------|------|
| preamble | 0x55 고정. Manchester 클럭 복원용 |
| addr | 슬레이브 주소 (0~7). 공유 버스에서 마스터가 송신자를 식별하고 슬롯 번호와 대조 |
| payload | 슬레이브 센서 데이터 32비트 |
| TX_TICK | 슬레이브 보정 타임스탬프 (`raw_counter + TICK_OFFSET`, signed 덧셈) |
| Hamming | SEC-DED 8비트. addr + payload + TX_TICK (67비트) 커버 |

### 마스터 → 슬레이브 (TX 케이블, 브로드캐스트)

```
[preamble 8b][HALT_CMD 8b][reserved 27b][TX_TICK 32b][Hamming 8b]
 ←────────────────────────── 83비트 ──────────────────────────────→
              └──────────────── Hamming 커버 (67비트) ──────────────┘
```

| 필드 | 설명 |
|------|------|
| preamble | 0x55 고정. Manchester 클럭 복원용 |
| HALT_CMD | 슬레이브 중단 명령 비트맵. bit n=1이면 슬레이브 n 중단 |
| reserved | 0 고정. 향후 사용 예약 |
| TX_TICK | 마스터 브로드캐스트 타임스탬프 |
| Hamming | SEC-DED 8비트. 슬레이브 프레임과 동일한 67비트 커버 → 동일 Hamming 모듈 공유 |

양측 프레임이 83비트로 통일되어 슬롯 구조 계산이 단순하다. Hamming 커버 대상이 동일(67비트)하므로 인코더/디코더 로직을 마스터·슬레이브가 공유한다.

**Hamming 구현**: 67비트 데이터를 Hamming(127,120) 표준 블록의 앞 67 슬롯에 MSB first 배치, 나머지 53 슬롯을 0으로 패딩. 7 패리티 비트 + 1 전체 패리티 = 8비트 추출. 1비트 오류: 자동 정정. 2비트 오류: 검출만, 프레임 폐기.

---

## 4. 슬롯 타이밍

### 슬롯 길이 자동 계산

```
frame_ticks = 83 × 2 × (DIV + 1)
slot_ticks  = frame_ticks + GUARD_TICKS
```

`SLOT_TICKS_RO` (RO 레지스터)로 확인 가능. `GUARD_MIN_RO` (RO)는 HW가 계산한 최소 guard time.

### 사이클 구조

```
사이클 시작 (cycle_start)
    │
    ├─ Master TX: 브로드캐스트 전송 시작 (preamble 첫 액티브 에지)
    │
    ├─ Slot 0: Slave 0 전송 (에지 감지 즉시, Master TX와 동시)
    ├─ Slot 1: Slave 1 전송 (1 × slot_ticks 후)
    ├─ Slot 2: Slave 2 전송 (2 × slot_ticks 후)
    │   ...
    └─ Slot N: Slave N 전송 (N × slot_ticks 후)
         └─ 전송 완료 후 guard time → guard time 정 중앙: 오프셋 보정 및 fault 판정
```

슬레이브는 마스터 브로드캐스트의 첫 번째 액티브 에지(High-Z → 첫 드라이브 전이)를 감지하여 슬롯 카운팅을 시작한다.

fault 상태 슬레이브의 슬롯은 사이클에서 제거하지 않는다. 공유 버스에서 슬롯 구조를 변경하면 전 슬레이브의 타이밍이 동시에 흔들리기 때문이다.

---

## 5. 시간 동기

마스터는 자유 진행 카운터를 기준으로 동작한다. 슬레이브가 마스터 기준에 맞춰 보정한다.

```
마스터: raw_counter (보정 없음)
슬레이브: raw_counter + TICK_OFFSET → TX_TICK으로 전송 (TICK_OFFSET: signed 32비트)
```

### 오프셋 계산 (매 사이클)

**슬레이브 측:**
```
D[k]       = RX_TICK[k] - SLV_TX_TICK[k]   (수신한 마스터 틱 - 내가 보낸 틱)
offset[k]  = D[k] - D[k-1]                 (D의 변화량 = 클럭 편차)
```

**마스터 측 (슬레이브 n에 대해):**
```
D[n][k]      = NODE_TICK[n][k] - MST_TX_TICK[k]
offset[n][k] = D[n][k] - D[n][k-1]
```

k=0 사이클: D[0]만 저장. 보정 및 fault 판정 스킵. k=1부터 정상 동작.

### 슬레이브 보정

guard time 정 중앙 시점(frame_ticks 경과 후 GUARD_TICKS/2 카운팅 완료)에 하드웨어가 자동으로:
```
TICK_OFFSET += offset[k]    // signed 덧셈. offset > 0 → 마스터가 빠름 → TICK_OFFSET 증가
```

동일 공정 크리스탈의 드리프트는 사실상 상수이므로, 보정 1회 후 안정 상태를 유지한다. guard time 정 중앙은 슬롯 카운터와 별개의 내부 카운터로 관리한다.

마스터의 offset[n][k]는 `NODE_OFFSET[n]` 레지스터(signed)로 PS에 노출된다.

---

## 6. Fault 체계

### 우선순위

```
CLOCK_FAULT > LINE_FAULT > SYNC_FAULT > DATA_FAULT
```

### Fault 종류 요약

| Fault | 감지 조건 | 감지 주체 | 동작 | 복구 |
|-------|----------|----------|------|------|
| DATA_FAULT | FRAME/HAMMING/SLOT_TIMEOUT 누적 ≥ FAULT_TH | 마스터 | 슬롯 격리 | 자동 (RECOVERY_TH 연속 정상) |
| SYNC_FAULT | `\|offset\| > GUARD_TICKS >> 2` | 마스터 + 슬레이브 | 마스터: 슬롯 격리. 슬레이브: 1사이클 PAUSE | 자동 복구 |
| CLOCK_FAULT | `\|offset\| > GUARD_TICKS >> 1` | 마스터 전용 | 영구 격리 + HALT_CMD HW 자동 세팅 | 수동 (SOFT_RST) |
| LINE_FAULT | preamble 미검출 LINE_RECOVERY_TH회 연속 | 마스터 + 슬레이브 | 격리. 마스터: PS IRQ | 자동 (LINE_RECOVERY_TH 연속 정상) |
| ADDR_ERR | addr 필드 ≠ 슬롯 번호 (슬롯 점유자 침묵 후 확인) | 마스터 | 식별 슬레이브에 HALT_CMD 즉시 자동 세팅 | 수동 |

LINE_FAULT는 공유 RX 버스 전체에 영향을 미친다. 모든 슬레이브 슬롯이 동시에 preamble 미검출 패턴을 보이면 버스 수준 장애로 판별할 수 있다.

ADDR_ERR 시나리오: A가 슬롯 B 침범 → 충돌로 Hamming 오류 → FAULT_CNT[B] 누적 → HALT_CMD[B] → B 침묵 → A 단독 전송 → addr 불일치 확인 → 즉시 HALT_CMD[A].

### HALT_CMD

마스터 브로드캐스트 프레임에 포함된 8비트 비트맵. 슬레이브는 자신의 비트가 1인 브로드캐스트 수신 시 즉시 공유 버스 구동을 중단(High-Z)하고 FAULT 진입.

| HW 자동 세팅 조건    | 대상 비트               |
| -------------- | ------------------- |
| CLOCK_FAULT 진입 | 해당 슬레이브(n)          |
| ADDR_ERR 감지    | 침범 식별 슬레이브(rx_addr) |

PS는 언제든 HALT_CMD 레지스터를 읽기/쓰기 가능. SOFT_RST 시 전체 클리어. 브로드캐스트 반영은 다음 사이클부터 (최대 1사이클 지연, 허용됨).

### 마스터 상태 머신 (슬레이브 n별, 7상태)

```
어느 상태에서든: |offset|>GUARD_TICKS/2 → CLOCK_FAULT (HALT_CMD HW 자동)
               LINE_FAULT 감지 → LINE_FAULT → (자동복구) → NORMAL

NORMAL
  ├─ FAULT_CNT ≥ FAULT_TH ──────────────▶ DATA_FAULT
  └─ SYNC_FAULT_CNT ≥ SYNC_FAULT_TH ───▶ SYNC_FAULT

DATA_FAULT ──(재개 감지)──▶ DATA_RECOVERY ──(RECOVERY_TH 연속 정상)──▶ NORMAL
SYNC_FAULT ──(offset 정상)──▶ SYNC_RECOVERY ──(SYNC_RECOVERY_TH 연속)──▶ NORMAL
```

### 슬레이브 상태 머신 (5상태)

```
어느 상태에서든: LINE_FAULT → DEAD → (자동복구) → NORMAL
               HALT_CMD 수신 → FAULT 즉시 진입 (공유 버스 High-Z)

NORMAL
  ├─ |offset[k]| > GUARD_TICKS>>2 ──▶ PAUSE (1사이클 전송 중단) ──▶ NORMAL
  └─ FAULT_CNT ≥ FAULT_TH ──────────▶ FAULT

FAULT ──(유효 브로드캐스트, HALT_CMD=0)──▶ RECOVERY ──(RECOVERY_TH 연속)──▶ NORMAL
```

---

## 7. 레지스터 맵 요약

### 마스터 (총 44개, 0x00~0xB0)

| 범위 | 그룹 |
|------|------|
| 0x00~0x10 | 제어: CTRL, LINK_CFG, NODE_CFG, FAULT_CFG, HALT_CMD |
| 0x18~0x1C | 계산값 (RO): SLOT_TICKS_RO, GUARD_MIN_RO |
| 0x20 | 타임스탬프: TX_TICK (RO) |
| 0x24~0x40 | 노드별 수신 데이터: NODE_DATA[0~7] (RO) |
| 0x44~0x60 | 노드별 수신 틱: NODE_TICK[0~7] (RO) |
| 0x64~0x80 | 노드별 오프셋: NODE_OFFSET[0~7] (RO, signed) |
| 0x84~0xA0 | 노드별 상태: NODE_STATUS[0~7] (RO/W1C) |
| 0xA4~0xA8 | 글로벌 상태: GLOBAL_STATUS, CYCLE_CNT (RO) |
| 0xAC~0xB0 | 인터럽트: IRQ_STATUS (W1C), IRQ_MASK (RW) |

NODE_STATUS[n].STATE 인코딩:
`000`=INACTIVE · `001`=NORMAL · `010`=DATA_FAULT · `011`=DATA_RECOVERY
`100`=SYNC_FAULT · `101`=SYNC_RECOVERY · `110`=LINE_FAULT · `111`=CLOCK_FAULT

### 슬레이브 (총 11개, 0x00~0x28)

| 주소 | 레지스터 | 설명 |
|------|---------|------|
| 0x00 | CTRL | ENABLE, SOFT_RST |
| 0x04 | LINK_CFG | DIV, GUARD_TICKS (마스터와 동일 설정) |
| 0x08 | SLAVE_CFG | SLAVE_ADDR[2:0] |
| 0x0C | FAULT_CFG | FAULT_TH, RECOVERY_TH, LINE_RECOVERY_TH |
| 0x10 | TX_DATA | 송신 payload (PS 갱신) |
| 0x14 | TX_TICK | 최근 전송 타임스탬프 (RO) |
| 0x18 | RX_TICK | 최근 수신 마스터 틱 (RO) |
| 0x1C | TICK_OFFSET | 보정 오프셋 (RW, signed, HW 자동 갱신) |
| 0x20 | STATUS | STATE, FAULT_CNT, RECOV_CNT, 오류 플래그 (RO/W1C) |
| 0x24 | IRQ_STATUS | 인터럽트 상태 (W1C) |
| 0x28 | IRQ_MASK | 인터럽트 마스크 (RW) |

STATUS.STATE 인코딩:
`000`=IDLE · `001`=NORMAL · `010`=PAUSE · `011`=FAULT · `100`=RECOVERY · `101`=DEAD

---

## 8. 설정 초기화 순서

```
1. LINK_CFG 설정 (모든 노드 동일: DIV, GUARD_TICKS)
2. 마스터: NODE_CFG.NODE_CNT 설정 (활성 슬레이브 수)
3. 마스터: FAULT_CFG 설정 (FAULT_TH, RECOVERY_TH, SYNC_FAULT_TH, SYNC_RECOVERY_TH, LINE_RECOVERY_TH)
4. 슬레이브: SLAVE_CFG.SLAVE_ADDR 설정 (각자 다르게)
5. 슬레이브: FAULT_CFG 설정 (FAULT_TH, RECOVERY_TH, LINE_RECOVERY_TH)
6. CTRL.ENABLE = 1 (마스터 먼저, 이후 슬레이브 순서 무관)
   → 슬레이브는 첫 브로드캐스트 액티브 에지 감지 시 자동 동기 획득
```

GUARD_TICKS 설정 기준:
- `GUARD_TICKS ≥ GUARD_MIN_RO` (HW 계산 최솟값)
- SYNC_FAULT 임계값 = `GUARD_TICKS >> 2`, CLOCK_FAULT 임계값 = `GUARD_TICKS >> 1` (하드와이어드)
- 4의 배수가 아닐 경우 하위 비트 내림 처리 (보수적, 의도된 동작)

---

## 9. 모듈 구조 요약

### 마스터

```
tdma_master_top
├── clk_div          : 클럭 분주 (DIV+1)
├── slot_timer       : TDMA 사이클·슬롯 관리. tx_tick cycle_start 래치 출력
├── master_tx        : 브로드캐스트 프레임 생성 (83비트, Hamming 포함)
├── shared_rx        : 공유 RX 버스 수신. Manchester 디코딩 + Hamming 검증
│   ├── phy_rx
│   └── frame_dec
├── fault_fsm [×8]   : 슬레이브별 7상태 FSM + sync_monitor (오프셋 계산)
├── regfile          : AXI-Lite. HALT_CMD HW 자동 세팅 OR 처리 포함
└── irq_ctrl         : IRQ 집계
```

### 슬레이브

```
tdma_slave_top
├── clk_div          : 클럭 분주 (마스터와 동일 모듈)
├── master_rx        : 마스터 브로드캐스트 수신. 액티브 에지 감지. Hamming 검증. LINE_FAULT 카운터
├── slot_timer       : 액티브 에지 기준 슬롯 카운팅. guard_mid 펄스 생성
├── slave_tx         : 슬레이브 프레임 직렬 출력 (83비트, Hamming). tx_oe로 삼상 제어
├── fault_fsm        : 5상태 FSM + sync_ctrl (오프셋 계산, TICK_OFFSET += offset[k])
├── regfile          : AXI-Lite
└── irq_ctrl         : IRQ 집계
```

---

## 10. 관련 문서

| 문서 | 내용 |
|------|------|
| `01_phy_decisions(3).md` | 물리 계층: TX/RX 케이블 분리, 공유 RX 버스, Manchester, High-Z |
| `02_datalink_decisions(3).md` | 프레임 구조, Hamming, 슬롯 타이밍, MAC 결정 근거 |
| `03_sync_decisions(3).md` | 시간 동기 메커니즘, TICK_OFFSET 보정, 동기 관련 fault |
| `04_fault_decisions(3).md` | Fault 분류 체계, 상태 머신, HALT_CMD, 임계값 레지스터 |
| `05_master_regmap.md` | 마스터 레지스터 맵 사양 (v0.4) |
| `06_slave_regmap.md` | 슬레이브 레지스터 맵 사양 (v0.2) |
| `07_master_port_def.md` | 마스터 모듈 포트 정의 (v0.2) |
| `08_slave_port_def.md` | 슬레이브 모듈 포트 정의 (v0.2) |
