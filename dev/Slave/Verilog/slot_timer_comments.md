# slot_timer.v — 한글 주석 설명서

## 모듈 역할

마스터 브로드캐스트의 `active_edge`를 기준으로 슬레이브의 TX 시작 시점과 브로드캐스트 부재(no_broadcast) 타임아웃을 관리한다.

- **slot_ticks**: 슬롯 1개의 길이 (클럭 사이클) = `50 × 2 × (DIV+1) + GUARD_TICKS`
- **tx_trigger**: `slave_addr × slot_ticks` 클럭 후 1클럭 펄스
- **no_broadcast**: `9 × slot_ticks` 클럭 동안 active_edge 없으면 1클럭 펄스

---

## 포트

| 포트 | 방향 | 설명 |
|------|------|------|
| `clk` | 입력 | 시스템 클럭 |
| `rst_n` | 입력 | 비동기 액티브-로우 리셋 |
| `div[9:0]` | 입력 | LINK_CFG.DIV |
| `guard_ticks[9:0]` | 입력 | LINK_CFG.GUARD_TICKS (가드 타임, 클럭 사이클) |
| `slave_addr[2:0]` | 입력 | SLAVE_CFG.SLAVE_ADDR (0~7) |
| `active_edge` | 입력 | master_rx 출력. 슬롯 카운터 리셋 기준 |
| `tx_trigger` | 출력 | TX 시작 1클럭 펄스 |
| `no_broadcast` | 출력 | 브로드캐스트 타임아웃 1클럭 펄스 |

---

## slot_ticks 계산 (클럭 사이클 기준)

```verilog
wire [31:0] slot_ticks = 32'd100 * (div + 1) + guard_ticks;
```

- `50비트 × 2*(DIV+1) 클럭/비트 = 100*(DIV+1)` 클럭 = 프레임 전송 시간
- `+ GUARD_TICKS` = 슬롯 간 가드 타임
- `div=3, guard=0` → `slot_ticks = 100 × 4 = 400`

---

## 트리거 타이밍

```verilog
wire [31:0] trig_cnt = slave_addr * slot_ticks;
wire [31:0] wdog_cnt = 9 * slot_ticks;
```

| slave_addr | trig_cnt | 의미 |
|-----------|----------|------|
| 0 | 0 | active_edge 직후 1클럭에 tx_trigger |
| 1 | slot_ticks | 1 슬롯 후 tx_trigger |
| N | N × slot_ticks | N 슬롯 후 tx_trigger |

watchdog: `9 × slot_ticks` 클럭 동안 active_edge 없으면 no_broadcast

---

## 카운터 동작 (slot_cnt + armed 플래그)

```verilog
reg [31:0] slot_cnt;
reg        armed;      // 첫 active_edge 이후 활성화
```

| 조건 | 동작 |
|------|------|
| `active_edge=1` | `armed=1`, `slot_cnt=0` (리셋) |
| `armed=1, active_edge=0` | `slot_cnt += 1` (매 클럭) |
| `slot_cnt == trig_cnt` | `tx_trigger = 1` (1클럭) |
| `slot_cnt == wdog_cnt` | `no_broadcast = 1` (1클럭) |

**주의**: `armed`가 0이면 (첫 active_edge 전) slot_cnt가 증가하지 않음.
slave_addr=0인 경우 trig_cnt=0이므로, active_edge 다음 클럭에 `slot_cnt=0 == trig_cnt=0` 조건으로 tx_trigger 발생.

---

## 등록 출력의 1클럭 지연

`tx_trigger`, `no_broadcast`는 `<=` (NBA 할당)이므로 조건 만족 클럭의 **다음** 클럭에 HIGH.

```
slot_cnt = N-1  →  slot_cnt == trig_cnt 조건 미충족
slot_cnt = N    →  조건 충족, tx_trigger <= 1 스케줄
클럭 엣지 이후  →  tx_trigger = 1 (1클럭)
```

---

## 주요 한계

- `slot_cnt`는 active_edge 후 계속 증가하며 리셋 없음 (watchdog 조건이 `==`이므로 1회만 발화)
- no_broadcast 발화 후에도 slot_cnt가 증가하여 재발화하지 않음
- 스펙에서는 no_broadcast 후 watchdog 카운터를 0으로 리셋해 재발화를 지원하나, 구현에서는 다음 active_edge를 기다려야 한다
