# Slave 2.2 전체 구조 설계

## 목적

이 문서는 Slave 2.2 구현의 설계 근거와 변경 범위를 기술한다.

## 2.1 대비 변경 범위

2.2는 2.1의 구조를 최대한 유지하며 다음 두 가지만 변경한다.

| 항목 | 2.1 | 2.2 |
|---|---|---|
| rate_error 시 period 처리 | default_period로 리셋 | holdover (마지막 good period 유지) |
| rate_error 시 period_valid | 0으로 리셋 | 유지 (holdover 중에도 valid) |
| 연속 miss 추적 | 없음 | miss_count로 추적, 임계 초과 시에만 리셋 |
| fault_fsm | 변경 없음 | 변경 없음 |

## Scenario 9 버그 분석

### 재현 순서

```
① TRACKING 중 정상 broadcast → TX 정상 발생
② corrupt broadcast 수신 → fault_fsm: TRACKING → RECOVERY
   - good_broadcast_commit 없음
   - timebase: interval_count 계속 증가 (리셋 없음)
③ 첫 번째 good broadcast (RECOVERY 중)
   - fault_fsm: RECOVERY → SEEN_ONCE
   - good_broadcast_commit 발생
   - 동시에 rate_error_event 발생 (interval이 expected의 2배)
     → timebase: bit_period = default_period, period_valid = 0 리셋
④ 두 번째 good broadcast (SEEN_ONCE 중)
   - fault_fsm: SEEN_ONCE → TRACKING, tx_allowed = 1
   - good_broadcast_commit 발생
   - timebase: period_valid = 0 → tx_trigger_match = 0 → TX 없음  ← BUG
```

### 근본 원인

`tx_trigger_match`의 조건:

```verilog
assign tx_trigger_match = period_valid_ff & tx_allowed & ...
```

`period_valid_ff`가 rate_error_event에 의해 0으로 리셋된 후, timebase가 TB21_TRACKING에 다시 도달하려면 추가 2회의 good broadcast가 필요하다. 그러나 fault_fsm은 이미 2회 만에 TRACKING으로 진입하여 TX를 허용한다. 두 FSM의 재획득 요구 횟수가 어긋나 TX trigger가 발생하지 않는다.

### 해결 방향: holdover

rate_error_event 발생 시 bit_period와 period_valid를 유지한다. 마지막으로 확인된 추정값은 명백히 틀렸다는 증거가 없으므로, reset보다 holdover가 안전하다. rate correction 측정만 재시작하여 다음 연속 good broadcast 쌍에서 보정을 재개한다.

holdover 중 period_valid는 1로 유지되므로 fault_fsm이 TX를 허용하는 즉시 tx_trigger_match가 발생할 수 있다.

## slave22_timebase 설계 요점

### 상태

```
TB22_RESET       → 초기화
TB22_WAIT_FIRST  → 첫 good broadcast 대기
TB22_HOLDOVER    → rate_error 발생, 마지막 period 유지, 재측정 대기
TB22_WAIT_SECOND → 첫 good 이후 두 번째 good 대기 (interval 측정 중)
TB22_TRACKING    → 정상 rate correction 진행 중
```

### period_valid 정책

| 상태 | period_valid |
|---|---|
| TB22_RESET | 0 |
| TB22_WAIT_FIRST | 0 |
| TB22_HOLDOVER | 1 (holdover 중에도 유지) |
| TB22_WAIT_SECOND | 1 |
| TB22_TRACKING | 1 |

### miss_count 정책

rate_error_event 발생 시 miss_count를 증가시킨다. 정상 interval이 측정되면 miss_count를 0으로 초기화한다. miss_count가 `MISS_RESET_LIMIT`을 초과하면 period를 default로 리셋하고 TB22_WAIT_FIRST로 복귀한다.

```
MISS_RESET_LIMIT = 4  (파라미터, 기본값)
```

이렇게 하면 단발성 miss는 holdover로 흡수하고, 장기 신호 손실은 결국 리셋으로 처리한다.

### slot phase 처리

good_broadcast_commit 시 slot = 0, slot_clk_cnt = frame_ticks로 re-anchor한다. 이 동작은 2.1과 동일하게 유지한다. holdover 중에는 slot counter가 마지막 period 추정값 기준으로 계속 진행한다.

### rate correction

2.1의 cycle 기반 interval 측정 방식을 유지한다. TB22_HOLDOVER에서는 interval 측정을 재시작하고, 다음 연속 두 good broadcast로 다시 rate를 추정한다.

## 재사용 모듈

다음 모듈은 변경 없이 재사용한다.

| 모듈 | 출처 | 근거 |
|---|---|---|
| `slave21_rx` | v2.1 | 단독 TB PASS, 인터페이스 변경 없음 |
| `slave21_tx` | v2.1 | 단독 TB PASS, 인터페이스 변경 없음 |
| `slave_hamming_enc` | v1.0 | v2.1에서도 재사용 확인 |
| `slave_hamming_dec` | v1.0 | v2.1에서도 재사용 확인 |
| `slave_control` | v1.0 | v2.1에서도 재사용 확인 |
| `slave2_line_sync` | v2.0 | v2.1에서도 재사용 확인 |

## 새로 작성하는 모듈

| 모듈 | 변경 이유 |
|---|---|
| `slave22_timebase` | holdover, miss_count, period_valid 정책 변경 |
| `slave22_top` | 새 timebase 연결 |

`slave22_fault_fsm`은 작성하지 않는다. 버그는 fault_fsm이 아닌 timebase에 있으며, fault_fsm 인터페이스와 FSM 자체는 올바르다.
