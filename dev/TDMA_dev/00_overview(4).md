# TDMA IP — 시스템 개요

> 버전: 0.4
> 작성일: 2026-05-21
> v0.4: TX_TICK 제거, 클럭 동기 로직 제거, 가드 타임으로 드리프트 흡수, 레지스터 44→27개(마스터)

---

## 1. 시스템 목적

이 IP는 **1 마스터 + 최대 8 슬레이브** 구성의 TDMA(Time Division Multiple Access) 통신 시스템을 구현한다. 각 노드는 독립 크리스탈 클럭을 사용하며, 마스터 브로드캐스트의 액티브 에지를 기준으로 매 사이클 타이밍을 재정렬한다. 별도 클럭 교환 없이 안정적인 다중 노드 통신을 목표로 한다.

**적용 환경 가정**

| 항목 | 값 |
|------|-----|
| 기준 클럭 | 25 MHz |
| 목표 전송 속도 | 125 kbps (Manchester 기준) |
| 케이블 길이 | 50 cm 이내 |
| 크리스탈 편차 | 최대 ±50 ppm |
| 레지스터 인터페이스 | AXI-Lite (32비트) |

---

## 2. 토폴로지

```
                    ┌──────────────┐
                    │    Master    │
                    │  (1개)        │
                    └──┬───────┬──┘
              TX 전용선 │       │ RX 공유 버스
         (브로드캐스트) │       │ (슬레이브→마스터)
                       │       │
          ┌────────────┤       ├───────────────────┐
          │            │       │                   │
     ┌────▼────┐  ┌────▼────┐  ...  ┌─────────────▼──┐
     │Slave 0  │  │Slave 1  │       │  Slave N (최대7) │
     └─────────┘  └─────────┘       └────────────────┘
```

- **TX 케이블**: 마스터 → 전체 슬레이브 브로드캐스트 전용선 (단방향)
- **RX 케이블**: 전체 슬레이브가 공유하는 단일 버스 → 마스터 (TDMA 슬롯 분리)
- 슬레이브는 자신의 TDMA 슬롯에서만 버스를 구동하고, 나머지 구간은 **High-Z** 유지

---

## 3. 프레임 구조

### 슬레이브 → 마스터 (50비트)

```
[preamble 8b][addr 3b][payload 32b][Hamming 7b]
              └──────── Hamming 커버 (35비트) ───────────┘
```

### 마스터 → 슬레이브 브로드캐스트 (50비트)

```
[preamble 8b][HALT_CMD 8b][reserved 27b][Hamming 7b]
              └──────────── Hamming 커버 (35비트) ────────┘
```

| 항목 | 내용 |
|------|------|
| 인코딩 | Manchester (셀프 클로킹, HIGH 액티브) |
| 오류 정정 | SEC-DED Hamming 7비트 (r=6, 41비트 코드워드 + 1 전체 패리티) |
| 아이들 레벨 | High-Z (풀 저항 없음, 직전 상태 유지) |
| 액티브 에지 | TX 라인의 첫 0→1 상승 에지 → 슬롯 카운터 기준점 |

---

## 4. TDMA 사이클 타이밍

```
사이클 시작 (cycle_start)
│
├── 마스터 브로드캐스트 송신 (50비트 = frame_ticks clk 사이클)
├── 슬레이브 0: cycle_start + 0 × slot_ticks + GUART_TICKS>>1 → TX (마스터 브로드캐스트 감지하고 GUARD_TICKS>>1 지난 직후 데이터 전송 시작)
├── 슬레이브 1: cycle_start + 1 × slot_ticks + GUART_TICKS>>1 → TX
│    ...
└── 슬레이브 N: cycle_start + N × slot_ticks + GUART_TICKS>>1 → TX
     └── guard time>>2 경과 → 다음 사이클 시작
```

```
frame_ticks = 50 × 2 × (DIV+1)           [clk 사이클]
slot_ticks  = frame_ticks + GUARD_TICKS   [clk 사이클]
```

**Guard time 목적**: 크리스탈 드리프트 흡수 + 공유 버스 Hi-Z 안정화 + Manchester 디코딩 지연

---

## 5. Fault 처리 개요

### 5.1 카운터 규칙 (+10 / −1)

```
위반 이벤트: counter = min(counter + 10, THRESHOLD)
정상 이벤트: counter = max(counter - 1, 0)
counter ≥ THRESHOLD → fault 진입
counter == 0        → NORMAL 복귀
```

### 5.2 마스터 관점 슬레이브 상태

| 상태 | 코드 | 조건 |
|------|------|------|
| INACTIVE | 000 | NODE_CNT 범위 밖 | (최우선, 에러 카운트 don't care)
| NORMAL | 001 | FAULT_CNT < FAULT_TH | (FAULT_TH ~=200)
~| DATA_RECOVERY | 010 | DATA_FAULT 복구 중 (FAULT_CNT < FAULT_TH, 아직 0 미도달) |~ (NO RECOVERY, SEND SHUTDOWN MSG)
| DATA_FAULT | 011 | FAULT_CNT ≥ FAULT_TH (슬롯 격리) | (해밍 비트 1비트 오류시 ERR_CNT 4 증가, 2비트 이상 오류시 ERR_CNT 8증가 후 프레임 폐기)
~| LINE_FAULT | 100 | LINE_CNT ≥ LINE_FAULT_TH (공유 버스 이상) |~

요약: preamble 수신 오류시마다 preamble_err_cnt 1씩 증가. 보통 preamble 수신 오류시 한 사이클당 여러 번의 오류가 나오기도 하고, silent_cnt까지 올라갈 확률이 크므로 유지해야할지도 미지수
     매 사이클마다 할당된 타임 슬롯에서 너무 늦지 않게 preamble 비트 수신 성공하고 엉뚱한 데이터라도 수신하게 된다면 received 상태로 전환. 사이클 종료 1클럭 후 참고하여 silent_cnt 6 증가 혹은 1감소
     할당된 슬롯 안에서 정확한 preamble 및 모든 데이터 수신시 hamming 검사 시작. 해밍 비트 1비트 오류시 ERR_CNT 4 증가, 2비트 이상 오류시 ERR_CNT 8증가 후 프레임 폐기.
     위 모든 과정이 완벽하게 진행되었는데 슬레이브의 addr 확인시 슬롯과 맞지 않을 때 slot_timeout_cnt 6 증가 : 확률 거의 없음.

     사실상 preamble err의 비중이 너무 크고, silent_cnt의 정의가 애매함. hamming 오류 잡는 건 무난하고, timeout의 경우 silent한 다른 슬롯에 데이터를 완벽하게 보내야하므로 의미가 별로 없을 것.


### 5.3 슬레이브 자체 상태

| 상태 | 코드 | 조건 |
|------|------|------|
| IDLE | 000 | 동기 미획득 |
| NORMAL | 001 | FAULT_CNT < FAULT_TH |
| DATA_RECOVERY | 010 | FAULT 복구 중 |
| FAULT | 011 | FAULT_CNT ≥ FAULT_TH (TX 중단) |
| DEAD | 100 | LINE_CNT ≥ LINE_FAULT_TH (TX 중단) |

### 5.4 HALT_CMD

마스터 브로드캐스트의 8비트 필드. bit n=1이면 슬레이브 n에 TX 중단 명령 전달.
HW 자동 세팅 조건: **ADDR_ERR 감지 시** (슬롯 침범 슬레이브의 비트를 자동으로 1로 세팅).

---

## 6. 레지스터 맵 요약

### 마스터 IP (27개 레지스터, 0x00~0x68)

| 범위 | 그룹 | 수 |
|------|------|----|
| 0x00~0x10 | 제어 (CTRL, LINK_CFG, NODE_CFG, FAULT_CFG, HALT_CMD) | 5 |
| 0x14~0x18 | 읽기 전용 계산값 (SLOT_TICKS_RO, GUARD_MIN_RO) | 2 |
| 0x1C~0x20 | 글로벌 상태 (GLOBAL_STATUS, CYCLE_CNT) | 2 |
| 0x24~0x40 | 노드별 수신 데이터 ×8 (NODE_DATA) | 8 |
| 0x44~0x60 | 노드별 상태 ×8 (NODE_STATUS) | 8 |
| 0x64~0x68 | 인터럽트 (IRQ_STATUS, IRQ_MASK) | 2 |

### 슬레이브 IP (8개 레지스터, 0x00~0x1C)

| 주소 | 레지스터 |
|------|----------|
| 0x00 | CTRL |
| 0x04 | LINK_CFG |
| 0x08 | SLAVE_CFG |
| 0x0C | FAULT_CFG |
| 0x10 | TX_DATA |
| 0x14 | STATUS |
| 0x18 | IRQ_STATUS |
| 0x1C | IRQ_MASK |

---

## 7. 모듈 구성 요약

### 마스터 IP (`tdma_master_top`)

```
clk_div       DIV → clk_tick ~(Manchester 타이밍)~ Unipolar NRZ
slot_timer    DIV+GUARD_TICKS → slot_ticks, cycle_start, slot_start, SLOT_TICKS_RO, GUARD_MIN_RO
master_tx     cycle_start → TX 브로드캐스트 (Manchester)
shared_rx     slot_start → RX 수신 및 파싱 (preamble/addr/data/Hamming)
fault_fsm ×8  이벤트 → STATE/FAULT_CNT/LINE_CNT/HALT_CMD 자동 세팅
regfile       AXI-Lite ↔ 내부 신호 매핑
irq_ctrl      이벤트 OR → IRQ 핀
```

### 슬레이브 IP (`tdma_slave_top`)

```
clk_div       DIV → clk_tick (Manchester 타이밍)
master_rx     tx_line → active_edge, bc_valid, bc_preamble_ok, bc_halt_cmd, 오류 플래그
slot_timer    active_edge+DIV → tx_trigger, no_broadcast (CYCLE_TIMEOUT = 9×slot_ticks)
slave_tx      tx_trigger → RX 버스 구동 (~Manchester~, Hamming 인코딩)
fault_fsm     이벤트 → STATE/tx_enable/플래그
regfile       AXI-Lite ↔ 내부 신호 매핑
irq_ctrl      이벤트 OR → IRQ 핀
```

---

## 8. 초기화 절차

### 마스터

```
1. LINK_CFG 설정: DIV (전송 속도), GUARD_TICKS (guard time)
2. GUARD_MIN_RO 확인 → GUARD_TICKS ≥ GUARD_MIN_RO 검증
3. NODE_CFG.NODE_CNT 설정 (슬레이브 수 - 1)
4. FAULT_CFG 설정 (FAULT_TH, LINE_FAULT_TH, 기본값 30)
5. IRQ_MASK 설정 (필요한 인터럽트 활성화)
6. CTRL.ENABLE = 1 → 사이클 0 시작, 첫 브로드캐스트 송신
```

### 슬레이브

```
1. LINK_CFG 설정: 마스터와 동일한 DIV, GUARD_TICKS
2. SLAVE_CFG.SLAVE_ADDR 설정 (마스터 NODE_CNT 범위 내)
3. FAULT_CFG 설정 (마스터와 동일 권장)
4. TX_DATA 초기값 설정
5. IRQ_MASK 설정
6. CTRL.ENABLE = 1 → TX 라인 모니터링 시작
   → 첫 액티브 에지 감지 시 자동 동기 획득 (IDLE → NORMAL)
```

---

## 9. 설계 결정 문서 목록

| 파일 | 내용 |
|------|------|
| `01_phy_decisions(5).md` | 물리 계층: 케이블 분리, Manchester 인코딩, High-Z 아이들, 액티브 에지 기준 |
| `02_datalink_decisions(5).md` | 데이터링크: 50비트 프레임 구조, Hamming SEC-DED 7비트, 슬롯 길이 자동 계산 |
| `03_sync_decisions(4).md` | 슬롯 타이밍: 액티브 에지 동기, 크리스탈 드리프트 분석, GUARD_MIN 산출, CYCLE_TIMEOUT |
| `04_fault_decisions(4).md` | Fault 처리: +10/−1 카운터, 마스터/슬레이브 FSM, HALT_CMD, ADDR_ERR 시나리오 |
| `05_master_regmap(4).md` | 마스터 레지스터 맵 상세 (27개) |
| `06_slave_regmap(4).md` | 슬레이브 레지스터 맵 상세 (8개) |
| `07_master_port_def(4).md` | 마스터 Verilog 모듈 계층 및 포트 정의 |
| `08_slave_port_def(4).md` | 슬레이브 Verilog 모듈 계층 및 포트 정의 |

---

## 10. v0.3 → v0.4 주요 변경사항

| 항목 | v0.3 | v0.4 |
|------|------|------|
| 프레임 길이 | 83비트 | 50비트 (−40%) |
| TX_TICK 필드 | 있음 (클럭 보정용) | 제거 |
| 클럭 동기 보정 | TICK_OFFSET 보정 로직 | 없음. 가드 타임으로 흡수 |
| SYNC_FAULT / CLOCK_FAULT | 있음 | 없음 |
| Hamming | 67비트 데이터, 8비트 패리티 | 35비트 데이터, 7비트 패리티 |
| 마스터 FSM 상태 수 | 7개 | 5개 (INACTIVE 포함) |
| 슬레이브 FSM 상태 수 | 6개 (PAUSE 포함) | 5개 (DATA_RECOVERY 포함, PAUSE 삭제) |
| Fault 카운터 방식 | 연속 횟수 기반 | +10/−1 점수 기반 |
| 마스터 레지스터 수 | 44개 | 27개 (−39%) |
| 슬레이브 레지스터 수 | ~11개 | 8개 |
