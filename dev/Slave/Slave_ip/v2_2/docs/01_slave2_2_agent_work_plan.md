# Slave 2.2 구현 순서 및 에이전트 분배

## 목적

이 문서는 Slave 2.2 구현 순서와 에이전트 분배를 정리한다.

## 공통 규칙

- `AGENTS.md`와 `CODING_STANDARDS.md`를 따른다.
- Pure Verilog만 사용한다.
- source 작성 전 Korean-centered module design note를 작성한다.
- 수정된 module은 반드시 TB를 실행한다.
- v2.1 source를 덮어쓰지 않는다.
- 2.2 source는 `Slave_ip/v2_2` 아래에 `slave22_*` 이름으로 작성한다.
- 재사용 파일은 `Slave_ip/v2_2/reuse/` 아래에 복사한다.

## 구현 대상

변경이 필요한 모듈은 `slave22_timebase`와 `slave22_top` 두 개다.

`slave22_fault_fsm`은 작성하지 않는다. v2.1의 `slave21_fault_fsm`을 top에서 그대로 인스턴스한다.

---

## Step 1: slave22_timebase (단독 구현)

Write scope:

- `Slave_ip/v2_2/docs/slave22_timebase_design.md`
- `Slave_ip/v2_2/slave22_timebase.v`
- `tb/tb_slave22_timebase.v`
- `sim/slave22_timebase/run_xsim.tcl`
- `sim/slave22_timebase/README.md`

seed:

- `Slave_ip/v2_1/slave21_timebase.v` — 구조와 port를 대부분 계승한다.
- `tb/tb_slave21_timebase.v` — TB seed로 활용하되 holdover/miss_count 케이스를 추가한다.

### 핵심 변경 사항

2.1 대비 변경 내용:

**상태 추가**

```
TB22_HOLDOVER 추가
TB21_WAIT_FIRST → TB22_WAIT_FIRST
TB21_WAIT_SECOND → TB22_WAIT_SECOND
TB21_TRACKING → TB22_TRACKING
```

**period_valid 정책**

- rate_error_event 시 period_valid를 0으로 리셋하지 않는다.
- TB22_HOLDOVER 진입 시에도 period_valid = 1 유지.
- TB22_WAIT_FIRST에서만 period_valid = 0.

**holdover period 정책**

- rate_error_event 시 bit_period를 default로 리셋하지 않는다.
- 마지막 good period 추정값을 유지한다.
- miss_count가 MISS_RESET_LIMIT 초과 시에만 default로 리셋.

**miss_count**

```
파라미터: MISS_RESET_LIMIT (기본 4)
rate_error_event 발생 → miss_count + 1
연속 good interval 측정 성공 → miss_count = 0
miss_count > MISS_RESET_LIMIT → bit_period = default, period_valid = 0, TB22_WAIT_FIRST
```

**상태 전이**

```
TB22_RESET:
  → TB22_WAIT_FIRST

TB22_WAIT_FIRST:
  good_broadcast_commit → TB22_WAIT_SECOND

TB22_WAIT_SECOND:
  rate_error_event (miss_count <= limit) → TB22_HOLDOVER
  rate_error_event (miss_count > limit)  → TB22_WAIT_FIRST
  good_broadcast_commit (정상 interval)  → TB22_TRACKING

TB22_HOLDOVER:
  good_broadcast_commit → TB22_WAIT_SECOND (interval 재측정 시작)
  miss_count > limit    → TB22_WAIT_FIRST

TB22_TRACKING:
  rate_error_event (miss_count <= limit) → TB22_HOLDOVER
  rate_error_event (miss_count > limit)  → TB22_WAIT_FIRST
```

### 핵심 검증 케이스

- reset 후 초기화
- 첫 good → WAIT_SECOND, period_valid = 0 유지
- 두 번째 good → TRACKING, period_valid = 1
- TRACKING 중 rate_error → HOLDOVER, period_valid 유지, bit_period 유지
- HOLDOVER 후 good → WAIT_SECOND, TX trigger 발생 가능
- **Scenario 9 재현: TRACKING → rate_error + good 동시 → HOLDOVER, 다음 good에서 TX trigger 발생**
- miss_count 누적 후 WAIT_FIRST 복귀
- rate correction 정확도 (2.1 동등 수준)

---

## Step 2: slave22_top (Step 1 완료 후)

Write scope:

- `Slave_ip/v2_2/docs/slave22_top_design.md`
- `Slave_ip/v2_2/slave22_top.v`
- `tb/tb_slave22_top_smoke.v`
- `tb/tb_slave22_top_full_serial.v`
- `sim/slave22_top_smoke/run_xsim.tcl`
- `sim/slave22_top_full_serial/run_xsim.tcl`

seed:

- `Slave_ip/v2_1/slave21_top.v` — 구조 그대로 계승. slave22_timebase로 인스턴스 교체.
- `tb/tb_slave21_top_smoke.v`, `tb/tb_slave21_top_full_serial.v` — seed로 활용.

### 포트 차이

slave22_top은 slave21_top 대비 다음을 변경한다.

- `slave21_timebase` 인스턴스를 `slave22_timebase`로 교체
- `slave21_fault_fsm`은 그대로 유지
- 재사용 leaf는 `reuse/` 경로에서 참조

---

## Step 3: 통합 검증 (Step 2 완료 후)

Write scope:

- `tb/tb_slave22_master_link.v`
- `sim/slave22_master_link/run_xsim.tcl`
- `Slave_ip/v2_2/docs/slave22_master_link_verification.md`

seed:

- `tb/tb_slave21_master_link.v`

Scenario 9 재현 및 PASS 확인이 이 단계의 핵심 목표다.

---

## Step 4: 가혹 테스트 (Step 3 PASS 후)

Write scope:

- `tb/tb_slave22_master_harsh_link.v`
- `tb/tb_slave22_comm_worst_case.v`
- `sim/slave22_master_harsh_link/run_xsim.tcl`
- `sim/slave22_comm_worst_case/run_xsim.tcl`
- 결과 문서

seed:

- `tb/tb_slave21_master_harsh_link.v`
- `tb/tb_slave21_comm_worst_case.v`

목표:

- 2.1에서 must-pass 실패했던 Scenario 9 → PASS
- 2.1에서 exploratory 실패했던 ±1% 클럭 → 결과 관찰 및 기록
- 2.1 PASS 항목 regression 없음 확인

---

## 권장 구현 순서

1. `slave22_timebase` 설계 노트 작성
2. `slave22_timebase.v` 구현
3. `tb_slave22_timebase` 작성 및 xsim PASS 확인
4. `slave22_top.v` 구현 (smoke TB)
5. `slave22_top` full serial TB
6. `slave22_master_link` 통합 검증
7. 가혹 테스트
