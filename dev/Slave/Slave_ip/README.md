# Slave IP Versioned Source Directory

이 디렉토리는 Slave IP source를 version별로 분리해 관리한다.

## Directory Map

| Directory | Status | Purpose |
|---|---|---|
| `v1_0` | 보존 | 기존 Slave 1.0 RTL source |
| `v2_0` | 개발 중단 | tick-driven timebase 기반 Slave 2.0 실험 작업 영역 |
| `v2_1` | 설계 시작 | frame-complete commit 기반 Slave 2.1 작업 영역 |

## Version Policy

- `v1_0` source는 기준 구현으로 보존한다.
- `v2_0` source는 `slave2_*` naming을 우선 사용한다.
- `v2_0` 작업은 중단하지만 산출물은 분석/비교용으로 보존한다.
- `v2_1` source는 `slave21_*` naming을 우선 사용한다.
- 2.1 작업은 `v1_0` 또는 `v2_0` 파일을 덮어쓰지 않는다.
- 1.0 testbench와 simulation은 regression 기준으로 남긴다.

## Main References

- 1.0 구조: `docs/slave_design/00_slave_spec_and_module_structure.md`
- 2.0 구조: `Slave_ip/v2_0/docs/00_slave2_robust_structure.md`
- 2.1 구조: `Slave_ip/v2_1/docs/00_slave2_1_frame_commit_structure.md`
- Coding standard: `CODING_STANDARDS.md`
