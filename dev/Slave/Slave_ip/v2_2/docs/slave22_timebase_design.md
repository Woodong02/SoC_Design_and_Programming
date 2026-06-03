# slave22_timebase 설계 노트

## 1. 목적

`slave22_timebase`는 2.1의 `slave21_timebase`를 계승하되, 2.1 Scenario 9 버그를 해결하기 위해
rate_error 발생 시의 동작을 **holdover** 방식으로 변경한 timebase leaf 모듈이다.

2.1의 핵심 버그: rate_error_event 발생 시 `period_valid`를 0으로 리셋하면서 timebase가 다시
TRACKING에 도달하려면 2회의 good broadcast가 추가로 필요했다. 그러나 fault_fsm은 2회 good만에
TRACKING으로 진입하여 TX를 허용한다. 두 FSM의 재획득 요구 횟수가 어긋나 recovery 직후
`tx_trigger`가 발생하지 않는다.

해결: rate_error 발생 시 마지막 good period 추정값과 `period_valid=1`을 유지(holdover)하여,
fault_fsm이 TX를 허용하는 즉시 `tx_trigger_match`가 성립하도록 한다. 장기 신호 손실은
`miss_count`로 추적하여 임계 초과 시에만 default로 리셋한다.

## 2. 포트 (slave21_timebase와 완전히 동일)

| 방향 | 포트 | 폭 | 설명 |
|---|---|---|---|
| in | i_CLK | 1 | 클럭 |
| in | i_RESETN | 1 | 비동기 active-low reset |
| in | i_NODE_ID | 3 | 본 노드 ID |
| in | i_NODE_CNT | 3 | 마지막 노드 인덱스 (노드 수 = cnt+1) |
| in | i_BIT_PERIOD_DEFAULT | 16 | 기본 bit period |
| in | i_GUARD_TICKS | 10 | 프레임 간 guard tick |
| in | i_GOOD_BROADCAST_COMMIT | 1 | good broadcast 확정 pulse |
| in | i_TX_ACTIVE | 1 | 현재 TX 진행 중 |
| in | i_TX_ALLOWED | 1 | TX 허용 |
| out | o_BIT_PERIOD | 16 | 현재 bit period 추정값 |
| out | o_PERIOD_VALID | 1 | period 추정 유효 |
| out | o_SLOT | 3 | 현재 slot |
| out | o_SLOT_CLK_CNT | 16 | slot 내 tick counter |
| out | o_TX_TRIGGER | 1 | TX 시작 trigger pulse |
| out | o_RATE_ERR | 1 | rate error 발생 pulse |

추가 파라미터: `parameter [3:0] MISS_RESET_LIMIT = 4'd4` (포트 변경 아님).

## 3. FSM

### 상태

| 상태 | 코드 | period_valid | 설명 |
|---|---|---|---|
| TB22_RESET | 3'd0 | 0 | 초기화 |
| TB22_WAIT_FIRST | 3'd1 | 0 | 첫 good 대기 |
| TB22_WAIT_SECOND | 3'd2 | 1 | 두 번째 good 대기 (interval 측정 중) |
| TB22_HOLDOVER | 3'd3 | 1 | rate_error 발생, 마지막 period 유지, 재측정 대기 |
| TB22_TRACKING | 3'd4 | 1 | 정상 rate correction 진행 |

주의: WAIT_SECOND의 period_valid는 2.1에서는 0이었으나, 2.2에서는 정책표(00 문서)에 따라 1로 유지한다.
단, WAIT_FIRST에서 첫 good를 받아 WAIT_SECOND로 진입하는 그 사이클에는 아직 유효한 추정이 없으므로
period_valid는 0을 유지하고(아래 period_valid 로직 참조), 두 번째 good에서 TRACKING으로 갈 때 1이 된다.
실제 holdover 경로(TRACKING/HOLDOVER → WAIT_SECOND)에서는 이미 valid=1이 유지된다.

### period_valid 로직

- rate_error_event에 의해 0으로 리셋하지 않는다 (2.1 버그 제거).
- 정상 interval 측정 성공(interval_ready & ~rate_error_event) 시 1.
- miss_count_next > MISS_RESET_LIMIT (장기 손실) 시 0.
- TB22_RESET 시 0.
- 그 외에는 현재 값 유지.

### bit_period 로직

- TB22_RESET 시 default_period.
- miss_count_next > MISS_RESET_LIMIT 시 default_period (장기 손실 리셋).
- rate_error_event(이고 아직 limit 이내) 시 **유지** (holdover, default 리셋 안 함).
- 정상 interval 측정 성공 시 period_adjusted (rate correction).
- period_valid_ff==0 (미획득) 시 default_period.

### miss_count 로직

- TB22_RESET 시 0.
- rate_error_event 시 +1.
- 정상 interval 측정 성공(interval_ready & ~rate_error_event) 시 0.
- miss_count_next > MISS_RESET_LIMIT로 리셋 발생 시 0.

`miss_count_next`(증가 반영된 값)를 FSM 전이/리셋 판단에 사용한다.

### 상태 전이표 (01 문서 그대로)

```
TB22_RESET:
  → TB22_WAIT_FIRST

TB22_WAIT_FIRST:
  good_broadcast_commit → TB22_WAIT_SECOND

TB22_WAIT_SECOND:
  rate_error_event, miss_count_next <= limit → TB22_HOLDOVER
  rate_error_event, miss_count_next >  limit → TB22_WAIT_FIRST
  good_broadcast_commit (정상 interval)      → TB22_TRACKING

TB22_HOLDOVER:
  miss_count_next > limit → TB22_WAIT_FIRST
  good_broadcast_commit   → TB22_WAIT_SECOND (interval 재측정 시작)

TB22_TRACKING:
  rate_error_event, miss_count_next <= limit → TB22_HOLDOVER
  rate_error_event, miss_count_next >  limit → TB22_WAIT_FIRST
```

rate_error_event는 interval_ready(= interval_seen & good_broadcast_commit)와 함께만 발생하므로,
rate_error_event와 good_broadcast_commit이 같은 사이클에 동시에 일어난다. 따라서 HOLDOVER 진입은
good와 동시에 일어나며, 다음 good에서 다시 WAIT_SECOND→측정으로 이어진다.

## 4. slot phase / rate correction

- good_broadcast_commit 시 slot=0, slot_clk_cnt=frame_ticks로 re-anchor (2.1 동일).
- holdover 중 slot counter는 마지막 period 추정값 기준으로 계속 진행.
- rate correction의 interval 측정/보정 산식은 2.1과 완전히 동일.
- HOLDOVER에서 다음 good를 받으면 interval_seen을 재시작(rate_error 시 0)하여 다음 연속 두 good로
  rate를 재추정한다.

## 5. 검증 커버리지

| 케이스 | 내용 |
|---|---|
| T1 | reset 초기화: period_valid=0 |
| T2 | 첫 good → WAIT_SECOND, period_valid 유지 |
| T3 | 두 번째 good → TRACKING, period_valid=1 |
| T4 | TRACKING 중 rate_error → HOLDOVER, period_valid/bit_period 유지 |
| T5 | HOLDOVER 후 good → WAIT_SECOND, TX trigger 가능 |
| T6 | HOLDOVER 후 두 번째 good → TRACKING, correction 재개 |
| T7 | Scenario 9: rate_error+good 동시 → HOLDOVER, 다음 good에서 tx_trigger |
| T8 | miss_count 누적 초과 → default 리셋, period_valid=0, WAIT_FIRST |
| T9 | 정상 interval 후 miss_count=0 (이후 단발 miss를 다시 holdover로 흡수) |
| T10 | NODE_ID > NODE_CNT → tx_trigger 없음 |
| T11 | TX_ACTIVE 중 → tx_trigger 없음 |
| T12 | TX_ALLOWED=0 → tx_trigger 없음 |
| T13 | rate correction 정확도 (fast/slow interval 보정) |
| 2.1 regression | tb_slave21_timebase must-pass 케이스 (단, holdover 정책으로 결과가 바뀌는 항목은 2.2 정책에 맞춰 기대값 조정) |
