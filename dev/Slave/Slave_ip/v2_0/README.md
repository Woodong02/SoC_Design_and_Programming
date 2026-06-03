# Slave IP v2.0 Work Directory

이 디렉토리는 통신 강인성 개선을 목표로 하는 Slave 2.0 작업 영역이다.

## Goal

Slave 2.0은 Master/Slave 별도 board clock, phase offset, 작은 rate error, line delay, jitter 조건에서 1.0보다 안정적인 통신을 목표로 한다.

핵심 구조는 `slave2_timebase`이다. 실제 새 clock을 만들지 않고, `i_CLK` domain 안에서 Master broadcast를 timing beacon으로 해석해 RX sample tick, TX bit tick, slot phase, TX trigger를 생성한다.

## Documents

| File | Purpose |
|---|---|
| `docs/00_slave2_robust_structure.md` | Slave 2.0 전체 구조 설계 |
| `docs/01_reuse_and_modification_plan.md` | 1.0 재사용/수정/재설계 판단표 |
| `docs/reuse_slave_hamming_enc_design_1_0.md` | 1.0 Hamming encoder 설계 사본 |
| `docs/reuse_slave_hamming_dec_design_1_0.md` | 1.0 Hamming decoder 설계 사본 |
| `docs/reuse_slave_control_design_1_0.md` | 1.0 control 설계 사본 |

## Source Naming

- New 2.0 modules should use `slave2_*`.
- Reused 1.0 modules may keep `slave_*` names when instantiated directly.
- Do not overwrite files in `../v1_0`.

## First Implementation Candidates

1. `slave2_line_sync`
2. `slave2_timebase`
3. `slave2_rx`
4. `slave2_tx`
5. `slave2_top`
