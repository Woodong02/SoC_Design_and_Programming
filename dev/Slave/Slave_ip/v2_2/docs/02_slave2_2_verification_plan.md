# Slave 2.2 검증 계획

## 원칙

- bottom-up 검증. leaf 단독 PASS 후 top 통합.
- 모든 TB는 self-checking. PASS/FAIL을 $display로 명시.
- 2.1에서 PASS한 항목은 regression 확인 대상이다.

---

## slave22_timebase 단독 검증

### must-pass 케이스

| 번호 | 시나리오 | 기대 결과 |
|---|---|---|
| T1 | reset 후 초기화 | period_valid=0, state=WAIT_FIRST |
| T2 | 첫 good broadcast | WAIT_SECOND 진입, period_valid=0 유지 |
| T3 | 두 번째 연속 good | TRACKING 진입, period_valid=1 |
| T4 | TRACKING 중 rate_error | HOLDOVER 진입, period_valid=1 유지, bit_period 유지 |
| T5 | HOLDOVER 후 첫 good | WAIT_SECOND 진입, TX trigger 발생 가능 |
| T6 | HOLDOVER 후 두 번째 good | TRACKING 복귀, rate correction 재개 |
| T7 | **Scenario 9 재현** | rate_error + good 동시 → HOLDOVER, 다음 good에서 tx_trigger 발생 |
| T8 | miss_count 누적 (초과) | bit_period = default, period_valid=0, WAIT_FIRST 복귀 |
| T9 | 정상 interval 후 miss_count 초기화 | miss_count = 0 |
| T10 | NODE_ID > NODE_CNT | tx_trigger 발생 안 함 |
| T11 | TX 활성 중 | tx_trigger 발생 안 함 |
| T12 | TX_ALLOWED = 0 | tx_trigger 발생 안 함 |
| T13 | rate correction 정확도 | ±0.25% 클럭 차이에서 period 추정값 수렴 |

### 2.1 regression 케이스

tb_slave21_timebase의 must-pass 케이스를 slave22_timebase에도 동일하게 적용한다.

---

## slave22_top smoke 검증

- slave22_timebase, slave21_fault_fsm, slave21_rx, slave21_tx 포함 compile
- forced broadcast data로 control/fault/timebase wiring 확인
- period_valid, tx_allowed, tx_trigger 연결 확인

---

## slave22_top full serial 검증

- Master broadcast 2회 수신 후 TX 발생 확인
- bad first frame 후 recovery 확인
- TRACKING 중 유실 후 recovery TX 확인 (Scenario 9 해당)

---

## slave22_master_link 통합 검증

### must-pass 시나리오

| 번호 | 시나리오 |
|---|---|
| L1 | nominal 클럭, 지연 없음 |
| L2 | 임의 start phase |
| L3 | 슬레이브 클럭 +0.25% |
| L4 | 슬레이브 클럭 -0.25% |
| L5 | 슬레이브 클럭 +0.50% |
| L6 | 슬레이브 클럭 -0.50% |
| L7 | 전파 지연 + 결정적 지터 |
| L8 | 첫 frame corrupt, 이후 recovery |
| **L9** | **TRACKING 중 유실 후 recovery (Scenario 9)** |

L9는 2.1에서 must-pass 실패한 항목이다. 2.2에서 PASS가 목표다.

---

## 가혹 테스트 (exploratory)

2.1 대비 개선 여부를 관찰한다. must-pass 지정 없음.

| 번호 | 시나리오 | 2.1 결과 | 2.2 목표 |
|---|---|---|---|
| H1 | 슬레이브 클럭 +1.00% | FAIL | 관찰 |
| H2 | 슬레이브 클럭 -1.00% | FAIL | 관찰 |
| H3 | 반 비트 수준 전파 지연 | FAIL | 관찰 |

결과가 FAIL이어도 수정 대상이 아니다. 단, 2.1에서 PASS였던 exploratory 항목이 FAIL로 바뀌면 regression으로 처리한다.
