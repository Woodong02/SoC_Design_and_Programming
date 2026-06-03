# Slave IP v2.1 Work Directory

이 디렉토리는 Slave 2.1 구조 설계 및 후속 구현 작업 영역이다.

## Status

Slave 2.0 개발은 중단한다. 2.1은 2.0의 강인성 목표를 유지하되, 구조를 `frame-complete commit` 방식으로 단순화한다.

## Why 2.1

2.0의 tick-driven RX/TX 구조는 timebase tick phase와 frame start phase가 얽혀 acquisition 실패와 TX 첫 bit 폭 불안정 가능성을 만들었다. 2.1은 Master broadcast를 끝까지 수신하고 검증한 뒤에만 상태를 commit한다. Slave는 확신이 없을 때 송신하지 않고 다음 Master broadcast를 기다리며, Master의 silent 처리가 치명 fault가 아닌 점을 적극적으로 이용한다. Rate correction은 frame 중이 아니라 다음 frame부터 적용한다.

## Documents

| File | Purpose |
|---|---|
| `docs/00_slave2_1_frame_commit_structure.md` | Slave 2.1 전체 구조 설계 |
| `docs/01_slave2_1_agent_work_plan.md` | 후임 세션용 에이전트 분배 및 구현 순서 |
| `docs/02_slave2_1_verification_plan.md` | 정상/통합/가혹 검증 계획 |
| `docs/03_reuse_and_seed_inventory.md` | 1.0/2.0에서 가져온 재사용 파일 및 수정 필요 seed 목록 |

## Imported Files

- Reusable RTL copies are under `reuse/`.
- Similar but not directly usable 2.0 seeds are under `seed_from_v2_0/`.
- Reusable or rework-needed TB seeds are under `../../tb/v2_1_seed/`.
- Rework-needed simulation script seeds are under `../../sim/v2_1_seed/`.

## Source Naming

- New 2.1 modules should use `slave21_*`.
- Reused 1.0 modules may keep `slave_*` names when instantiated directly.
- Do not overwrite files in `../v1_0` or `../v2_0`.
