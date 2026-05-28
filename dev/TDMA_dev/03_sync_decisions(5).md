# TDMA IP — 슬롯 타이밍 기준 및 가드 타임 설계 결정

> 버전: 0.4
> 작성일: 2026-05-21
> v0.4: TX_TICK 기반 클럭 보정 삭제. 액티브 에지 감지를 단일 동기 기준으로 확정.
>       guard time으로 크리스탈 드리프트를 흡수하는 방식 채택.

---

## 1. 동기 기준: 액티브 에지 감지

### 1.1 동작 원리

슬레이브는 매 사이클 마스터 브로드캐스트의 **첫 번째 액티브 에지**(TX 라인이 High-Z 상태에서 드라이버가 처음 전이를 일으키는 시점)를 감지하여 슬롯 카운터를 리셋한다.

```
TX 라인 (아이들 = High-Z, float):
─ float ─┬─ 전이 ─ ... Manchester 비트스트림 ... ─ float ─
          ↑
    액티브 에지: 슬롯 카운터 시작
```

이 에지가 슬레이브 슬롯 타이밍의 유일한 기준점이다. 별도 클럭 교환 없이 매 사이클 마스터와 슬레이브의 타이밍을 재정렬한다.

### 1.2 Verilog 구현 참고

별도 풀 저항 없이 라인이 직전 전송 종료 상태를 유지한다. 수신 회로는 **0→1 상승 에지**를 액티브 에지로 인식한다.

```verilog
// active_edge: 이전 사이클이 0으로 끝난 상태에서 첫 HIGH 전이
reg prev_rx;
always @(posedge clk) prev_rx <= rx_line;
wire active_edge = (~prev_rx) & rx_line;  // 0→1 상승 에지
```

라인이 1로 끝난 직전 사이클 다음에 동일한 드라이버가 재개하는 경우, 첫 전이가 상승 에지가 되지 않을 수 있다. preamble 0x55는 이러한 모호성을 Manchester 전이 패턴으로 자연스럽게 해소한다. 수신기는 첫 상승 에지 이후 preamble 패턴 검증으로 유효 사이클 시작을 확정한다.

### 1.3 슬롯 시작 오프셋

```
slot_start[n] = cycle_start + n × slot_ticks + GUARD_TICKS   (n = SLAVE_ADDR)
```

<<<<<<< HEAD:dev/TDMA_dev/03_sync_decisions(4).md
슬레이브는 에지 감지 후 자신의 SLAVE_ADDR × slot_ticks + GUARD_TICKS 카운트 완료 시점에 전송을 시작한다. n=0 슬레이브는 에지 감지 즉시 전송을 시작한다.
=======
~슬레이브는 에지 감지 후 자신의 SLAVE_ADDR × slot_ticks 카운트 완료 시점에 전송을 시작한다. n=0 슬레이브는 에지 감지 즉시 전송을 시작한다.~
슬레이브는 에지 감지 후 자신의 SLAVE_ADDR × slot_ticks + (guard_ticks>>1) 카운트 완료 시점에 전송을 시작한다. n=0 슬레이브는 에지 감지 후 guard_ticks>>1 만큼의 카운트 후 전송을 시작한다. (슬롯의 양쪽 끝이 가드타임/2씩 차지하므로)
>>>>>>> b80b4809321903281d7ee22f72d904a546ce606b:dev/TDMA_dev/03_sync_decisions(5).md

---

## 2. 크리스탈 드리프트 분석 및 가드 타임 산출

### 2.1 드리프트 발생 원인

각 노드는 동일 생산 공정의 별도 크리스탈 소스를 사용한다. 공칭 주파수는 동일하나 제조 공차로 인해 미세한 주파수 편차가 존재한다.

```
마스터: f_mst = f_nom × (1 + ε_mst)
슬레이브: f_slv = f_nom × (1 + ε_slv)
드리프트: Δf = f_mst - f_slv = f_nom × (ε_mst - ε_slv)
```

두 크리스탈의 편차가 최악의 경우 반대 방향으로 누적되면 유효 드리프트는 최대 `2 × MAX_PPM`이다.

### 2.2 사이클 내 누적 드리프트

슬레이브는 매 사이클 액티브 에지에서 동기를 재정렬하므로, **한 사이클 내에서 누적되는 드리프트만 가드 타임이 흡수하면 된다**.

```
drift_ticks[n] = n × slot_ticks × (2 × MAX_PPM) / 1_000_000

최악의 경우 (슬레이브 7, NODE_CNT = 7):
  drift_max = 7 × slot_ticks × 2 × MAX_PPM / 1_000_000
```

수치 예 (DIV=99, 25MHz → 250kHz tick, GUARD_TICKS=100, MAX_PPM=50):
```
frame_ticks = 50 × 2 × 100 = 10,000
slot_ticks  = 10,000 + 100 = 10,100
drift_max   = 7 × 10,100 × 2 × 50 / 1,000,000 = 7.07 ticks ≈ 8 ticks (올림)
```

GUARD_TICKS=100 기준으로 드리프트 여유는 8%이며, 안전하게 흡수된다.

### 2.3 GUARD_MIN 산출

```verilog
parameter CABLE_LENGTH_CM   = 50;
parameter CLK_FREQ_MHZ      = 25;
parameter CLK_PERIOD_NS     = 1_000 / CLK_FREQ_MHZ;              // 40 ns
parameter CABLE_DELAY_NS    = (CABLE_LENGTH_CM * 5 + 99) / 100;  // 5ns/m, 올림
parameter CABLE_DELAY_TICKS = (CABLE_DELAY_NS + CLK_PERIOD_NS - 1) / CLK_PERIOD_NS;
// 50cm → 약 2.5ns → 0 ticks (25MHz 1클럭 = 40ns 이하)

parameter RX_PROCESS_CYCLES = 8;     // Manchester 디코딩 + Hamming 파이프라인 지연
parameter BUS_TURNAROUND    = 4;     // 공유 버스 Hi-Z 전환 후 구동까지 여유 클럭
parameter MAX_PPM           = 50;    // 크리스탈 최대 편차 (단측)
parameter NODE_CNT_MAX      = 8;

// slot_ticks는 frame_ticks + GUARD_TICKS이므로 반복 계산 필요. 보수적으로:
// DRIFT_MARGIN ≈ NODE_CNT_MAX × frame_ticks × 2 × MAX_PPM / 1_000_000 (올림)
parameter DRIFT_MARGIN = (NODE_CNT_MAX * FRAME_TICKS * 2 * MAX_PPM + 999_999) / 1_000_000;

parameter GUARD_MIN = RX_PROCESS_CYCLES + CABLE_DELAY_TICKS + BUS_TURNAROUND + DRIFT_MARGIN;
```

> DRIFT_MARGIN은 slot_ticks가 아닌 frame_ticks 기준으로 계산하면 보수적이지만 GUARD_TICKS 의존성을 제거할 수 있다. 실제 구현에서는 파라미터 순환 참조를 피하기 위해 이 방식을 권장한다.

### 2.4 GUARD_TICKS 설정 기준 요약

| 조건 | 설명 |
|------|------|
| `GUARD_TICKS ≥ GUARD_MIN_RO` | HW 계산 최솟값 이상으로 설정 |
| `GUARD_TICKS ≥ DRIFT_MARGIN × 안전계수` | 드리프트 흡수를 위한 추가 여유. 안전계수 2 이상 권장 |
| 모든 노드 동일 설정 | 마스터와 슬레이브의 GUARD_TICKS는 반드시 동일하게 구성 |

---

## 3. 슬레이브 슬롯 카운터 동작

### 3.1 카운터 구조

슬레이브의 slot_timer는 두 개의 카운터로 구성된다.

| 카운터 | 역할 |
|--------|------|
| `slot_cnt` | 현재 사이클 내 경과 ticks. 액티브 에지에서 리셋. `SLAVE_ADDR × slot_ticks`에 TX 트리거 |
| `watchdog_cnt` | 마지막 액티브 에지로부터 경과 ticks. `CYCLE_TIMEOUT_TICKS` 초과 시 NO_BROADCAST 이벤트 발생 |

### 3.2 슬롯 카운터 타이밍

```
액티브 에지
    │
    ├─ slot_cnt = 0 리셋
    ├─ watchdog_cnt = 0 리셋
    │
    ├─ (slot_cnt == SLAVE_ADDR × slot_ticks) → TX 시작
    │
    └─ 다음 액티브 에지 대기
         if watchdog_cnt >= CYCLE_TIMEOUT_TICKS → NO_BROADCAST 이벤트
```

### 3.3 브로드캐스트 수신 중 카운팅

슬레이브는 액티브 에지 감지 직후부터 Manchester 디코딩 및 Hamming 검증을 slot_cnt와 **병렬**로 수행한다. 검증 결과(HALT_CMD, Hamming OK/ERR)는 이후 사이클 동작에 반영되며, 카운터 진행을 막지 않는다.

---

## 4. CYCLE_TIMEOUT 및 NO_BROADCAST 처리

### 4.1 CYCLE_TIMEOUT_TICKS 설정

슬레이브는 마지막 액티브 에지로부터 아래 시간 이내에 다음 액티브 에지가 감지되지 않으면 NO_BROADCAST 이벤트를 발생시킨다.

```
CYCLE_TIMEOUT_TICKS = (NODE_CNT_MAX + 1) × slot_ticks
                    = 9 × slot_ticks   (NODE_CNT_MAX = 8 고정)
```

별도 레지스터 없이 slot_ticks에서 HW가 자동 계산한다. NODE_CNT_MAX를 8로 고정하여 실제 노드 수를 슬레이브가 알지 않아도 된다. 최악의 경우(8 슬레이브 사이클) + 1 슬롯 여유를 더한 보수적 값이다.

### 4.2 NO_BROADCAST 이벤트 처리

NO_BROADCAST 발생 시 슬레이브의 LINE_CNT에 +10을 적용한다. LINE_CNT ≥ LINE_FAULT_TH에 도달하면 DEAD 상태로 진입한다. 유효 액티브 에지 + 유효 preamble 수신 시마다 LINE_CNT −1 적용. 카운터 포화 및 히스테리시스 상세는 `04_fault_decisions(4).md` §2 참조.

watchdog_cnt는 NO_BROADCAST 이후에도 계속 증가한다. 다음 액티브 에지가 감지되면 즉시 리셋하고 정상 동작을 재개한다.

```
NO_BROADCAST 발생 예시:
  watchdog_cnt >= 9 × slot_ticks
      → LINE_CNT = min(LINE_CNT + 10, LINE_FAULT_TH)
      → watchdog_cnt = 0으로 리셋, 다음 에지 대기
      → LINE_CNT >= LINE_FAULT_TH → DEAD
  유효 preamble 수신:
      → LINE_CNT = max(LINE_CNT - 1, 0)
      → LINE_CNT == 0 → NORMAL 복귀
```

---

## 5. TX_TICK 제거 근거 요약

| 항목 | v0.3 (TX_TICK 있음) | v0.4 (TX_TICK 없음) |
|------|-------------------|-------------------|
| 프레임 길이 | 83비트 | 50비트 (-40%) |
| 클럭 보정 | TICK_OFFSET += offset[k] | 없음 |
| 동기 오차 흡수 | 보정 로직이 흡수 | 가드 타임이 흡수 |
| SYNC_FAULT / CLOCK_FAULT | 있음 (2개 fault 상태) | 없음 |
| Hamming 복잡도 | 67비트 데이터, 8비트 패리티 | 35비트 데이터, 7비트 패리티 |
| 슬레이브 FSM 상태 | 6개 (IDLE+PAUSE 포함) | 5개 (IDLE+DATA_RECOVERY 포함, PAUSE 삭제) |
| 마스터 FSM 상태 | 7개 (INACTIVE 제외) | 5개 (INACTIVE 포함) |
| 구현 필요 레지스터 | 마스터 44개, 슬레이브 11개 | 마스터 ~30개, 슬레이브 ~7개 (예상) |

동일 생산 공정 크리스탈의 드리프트는 사이클 내에서 수 틱 수준이며, GUARD_TICKS를 충분히 설정하면 보정 로직 없이도 안정적인 동작이 가능하다.
