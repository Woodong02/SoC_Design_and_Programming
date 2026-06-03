# Slave 2.1 에이전트 분배 및 구현 순서

## 목적

이 문서는 후임 세션이 Slave 2.1 구현을 시작할 때 에이전트를 어떻게 분배할지 정리한다. 2.1은 문서 우선, leaf 우선, self-checking TB 우선 원칙을 유지한다.

## 공통 규칙

- `AGENTS.md`와 `CODING_STANDARDS.md`를 따른다.
- Pure Verilog만 사용한다.
- source 작성 전 Korean-centered module design note를 작성한다.
- 수정된 module은 반드시 TB를 실행한다.
- 1.0/2.0 source는 덮어쓰지 않는다.
- 2.1 source는 `Slave_ip/v2_1` 아래에 `slave21_*` 이름으로 작성한다.
- 먼저 `Slave_ip/v2_1/docs/03_reuse_and_seed_inventory.md`를 확인한다.
- `reuse/*` 파일은 그대로 활용하고, `seed_from_v2_0/*needs_2_1_rework.v`는 참고용 seed로만 사용한다.

## 병렬 leaf 후보

### Agent A: `slave21_rx`

Write scope:

- `Slave_ip/v2_1/docs/slave21_rx_design.md`
- `Slave_ip/v2_1/slave21_rx.v`
- `tb/tb_slave21_rx.v`
- `sim/slave21_rx/run_xsim.tcl`
- `sim/slave21_rx/README.md`

핵심 검증:

- reset/idle
- valid frame 수신
- wrong preamble
- frame 중 period 변경 무시
- first bit edge acquisition
- `BIT_PERIOD=1`, 작은 period boundary

### Agent B: `slave21_tx`

Write scope:

- `Slave_ip/v2_1/docs/slave21_tx_design.md`
- `Slave_ip/v2_1/slave21_tx.v`
- `tb/tb_slave21_tx.v`
- `sim/slave21_tx/run_xsim.tcl`
- `sim/slave21_tx/README.md`

핵심 검증:

- trigger 없는 idle
- trigger 시 첫 bit full-width 보장
- snapshot period 유지
- frame bit sequence
- disabled trigger ignore
- active 중 retrigger ignore

### Agent C: `slave21_fault_fsm`

Write scope:

- `Slave_ip/v2_1/docs/slave21_fault_fsm_design.md`
- `Slave_ip/v2_1/slave21_fault_fsm.v`
- `tb/tb_slave21_fault_fsm.v`
- `sim/slave21_fault_fsm/run_xsim.tcl`
- `sim/slave21_fault_fsm/README.md`

핵심 검증:

- ACQUIRE에서 bad frame 반복 시 TX 금지 유지
- 첫 good 후 SEEN_ONCE, 아직 TX 금지
- 두 번째 good 후 TRACKING/TX 허용
- halt_for_me이면 TRACKING이어도 TX 금지
- TRACKING 중 bad frame/rate_err -> RECOVERY
- RECOVERY에서 good -> SEEN_ONCE

### Agent D: `slave21_timebase`

Write scope:

- `Slave_ip/v2_1/docs/slave21_timebase_design.md`
- `Slave_ip/v2_1/slave21_timebase.v`
- `tb/tb_slave21_timebase.v`
- `sim/slave21_timebase/run_xsim.tcl`
- `sim/slave21_timebase/README.md`

핵심 검증:

- reset/default period
- first good commit phase acquisition
- second good commit period estimate
- fast/slow interval correction
- TX trigger only when `i_TX_ALLOWED`
- `NODE_ID > NODE_CNT` trigger block
- rate error behavior

주의:

- `slave21_timebase` design note에서 RX가 제공하는 sync timing metadata를 확정해야 한다.
- 가장 단순한 초안은 `i_GOOD_BROADCAST_COMMIT` 시점 기준으로 cycle interval을 측정하되, frame done latency가 항상 50-bit로 일정하다는 점을 이용한다.

### Agent E: reuse compatibility

Write scope:

- `Slave_ip/v2_1/docs/reuse_leaf_compatibility_verification.md`
- 필요 시 `tb/tb_slave21_reuse_compat.v`
- 필요 시 `sim/slave21_reuse_compat/*`

대상:

- `slave_hamming_enc`
- `slave_hamming_dec`
- `slave_control`
- `slave2_line_sync`

정책:

- 변경 없이 재사용하면 2.0 compatibility 결과를 참조하고, top/integration에서 다시 compile한다.
- 조금이라도 wrapper나 port adaptation을 만들면 TB를 실행한다.

Seed 위치:

- `Slave_ip/v2_1/reuse/*`
- `tb/v2_1_seed/tb_slave2_line_sync_reuse.v`
- `tb/v2_1_seed/tb_slave2_reuse_compat_reuse.v`

## 순차 통합 후보

### Orchestrator: `slave21_top`

Write scope:

- `Slave_ip/v2_1/docs/slave21_top_design.md`
- `Slave_ip/v2_1/slave21_top.v`
- `tb/tb_slave21_top_smoke.v`
- `tb/tb_slave21_top_full_serial.v`
- `sim/slave21_top_smoke/*`
- `sim/slave21_top_full_serial/*`

순서:

1. 모든 leaf PASS 확인.
2. top smoke compile.
3. forced broadcast data로 control/fault/timebase wiring 확인.
4. full serial broadcast 2회 후 TX 발생 확인.
5. bad first frame recovery 확인.

## Master/Slave 통합

후임 세션은 leaf와 top이 PASS한 뒤 다음을 작성한다.

- `tb/tb_slave21_master_link.v`
- `sim/slave21_master_link/run_xsim.tcl`
- `Slave_ip/v2_1/docs/slave21_master_link_verification.md`

정상 통합 테스트는 fail이면 RTL 또는 TB 오류로 보고 수정한다.

## 가혹 테스트

정상 통합 후 다음을 작성한다.

- `tb/tb_slave21_master_harsh_link.v`
- `tb/tb_slave21_comm_worst_case.v`
- `sim/slave21_master_harsh_link/run_xsim.tcl`
- `sim/slave21_comm_worst_case/run_xsim.tcl`
- 결과 문서

가혹 테스트는 전부 돌린 뒤 결과를 보고한다. Must-pass로 명시한 일반 조건만 오류 수정 대상이고, exploratory extreme 조건은 결과 관찰 대상으로 기록한다.

## 권장 구현 순서

1. `slave21_fault_fsm`
2. `slave21_rx`
3. `slave21_tx`
4. `slave21_timebase`
5. reuse compatibility note
6. `slave21_top`
7. `slave21_top_full_serial`
8. `slave21_master_link`
9. harsh/worst-case tests

이 순서는 fault policy를 먼저 고정하고 RX/TX/timebase를 그 계약에 맞추기 위한 것이다.
