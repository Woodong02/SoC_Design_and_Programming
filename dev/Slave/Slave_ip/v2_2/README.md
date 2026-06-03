# Slave IP v2.2 Work Directory

이 디렉토리는 Slave 2.2 구조 설계 및 구현 작업 영역이다.

## Status

Slave 2.1 개발 결과를 기반으로 진행한다. 2.1의 frame-complete commit 원칙은 유지하되, 두 가지 문제를 해결한다.

1. must-pass 버그: Scenario 9 — TRACKING 중 broadcast 유실 후 recovery 경로에서 TX가 발생하지 않는 문제
2. rate correction 개선: holdover 동작 추가 및 연속 miss 추적

## Why 2.2

2.1의 `slave21_timebase`는 `rate_error_event`와 `good_broadcast_commit`이 동일 클럭에 발생할 때 `period_valid`를 0으로 리셋한다. 이 시점에 `slave21_fault_fsm`은 RECOVERY → SEEN_ONCE로 진행하므로, 이후 두 번째 good broadcast에서 fault_fsm은 TRACKING(TX 허용)이지만 timebase의 `period_valid = 0`으로 인해 `tx_trigger_match`가 발생하지 않는다.

2.2는 rate_error 발생 시 마지막으로 확인된 bit period를 holdover로 유지하고, period_valid를 유지하여 recovery 경로에서도 TX trigger가 정상 발생하도록 수정한다.

## Documents

| File | Purpose |
|---|---|
| `docs/00_slave2_2_design_overview.md` | Slave 2.2 전체 구조 설계 및 변경 근거 |
| `docs/01_slave2_2_agent_work_plan.md` | 구현 순서 및 에이전트 분배 |
| `docs/02_slave2_2_verification_plan.md` | 검증 계획 |
| `docs/03_reuse_and_change_inventory.md` | 재사용 파일 및 변경 대상 목록 |

## Source Naming

- 새 2.2 모듈은 `slave22_*` 명칭을 사용한다.
- 재사용 2.1 모듈은 `reuse/` 아래에 복사하고 `slave21_*` 이름을 그대로 유지한다.
- `../v2_1` 파일을 직접 덮어쓰지 않는다.

## Imported Files

- 재사용 RTL 복사본은 `reuse/` 아래에 있다.
