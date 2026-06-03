# Slave 2.0 Reuse and Modification Plan

## 목적

이 문서는 Slave 2.0 구현 시 Slave 1.0 산출물 중 무엇을 그대로 재사용하고, 무엇을 조금 수정하며, 무엇을 새로 설계해야 하는지 정리한다.

## 그대로 재사용 가능

| 1.0 Artifact | 2.0 Use | 판단 |
|---|---|---|
| `../v1_0/slave_hamming_enc.v` | direct instantiation 또는 `slave2_tx` 내부 재사용 | Hamming layout은 Master 호환 고정 기능이며 timing 보정과 무관하다. |
| `../v1_0/slave_hamming_dec.v` | direct instantiation 또는 `slave2_rx` decode path 재사용 | SECDED decode 기능은 frame timing과 분리되어 있다. |
| `../v1_0/slave_control.v` | 초기 2.0에서 direct instantiation 가능 | halt, guard latch, payload policy는 timebase 구조와 직접 충돌하지 않는다. |

관련 설계 문서 사본:

- `reuse_slave_hamming_enc_design_1_0.md`
- `reuse_slave_hamming_dec_design_1_0.md`
- `reuse_slave_control_design_1_0.md`

## 조금 수정하면 사용 가능

| 1.0 Artifact | 수정 방향 | 이유 |
|---|---|---|
| `slave_tx_design.md` / `../v1_0/slave_tx.v` | `BIT_DIV` counter 제거, `i_TX_BIT_TICK` 기반 진행으로 변경 | 2.0 TX는 자체 bit period를 만들지 않고 `slave2_timebase` tick을 따라야 한다. |
| `slave_rx_design.md` / `../v1_0/slave_rx.v` | input synchronizer 분리, sample tick 입력화, optional 3-sample majority 추가 | 2.0 RX는 고정 `BIT_DIV` 중앙 sample 대신 timebase sample tick을 사용한다. |
| `slave_top_design.md` / `../v1_0/slave_top.v` | `slave2_line_sync`, `slave2_timebase`, `slave2_rx`, `slave2_tx` 중심으로 재배선 | top integration 책임은 유지되지만 timing 구조가 바뀐다. |
| `tb_slave_tx.v` | expected bit sequence 검증은 유지, tick-driven TX 검증으로 stimulus 변경 | TX frame 내용 검증은 재사용 가능하나 clocking 방식이 바뀐다. |
| `tb_slave_rx.v` | valid frame/preamble error case 유지, sample tick/majority case 추가 | RX FSM coverage는 유사하지만 sampling 구조가 바뀐다. |

## 새로 설계해야 함

| New Artifact | 이유 |
|---|---|
| `slave2_line_sync.v` | 1.0에는 async serial input synchronizer가 별도 module로 없다. |
| `slave2_timebase.v` | 2.0의 핵심인 가상 Master timebase, rate correction, slot phase 생성을 담당한다. |
| `tb_slave2_timebase.v` | rate estimate, bounded correction, pending correction, lock/unlock FSM을 별도 검증해야 한다. |
| `tb_slave2_robust_link.v` | 1.0 harsh/worst-case 한계를 2.0에서 재검증해야 한다. |

## 1.0 문서 중 계속 참조할 항목

| Document | 2.0 Reference Use |
|---|---|
| `docs/slave_design/00_slave_spec_and_module_structure.md` | Master 호환 frame, Hamming layout, slot timing 기본식 |
| `docs/slave_design/slave_master_harsh_link_verification.md` | 1.0 한계 scenario |
| `docs/slave_design/slave_comm_worst_case_verification.md` | guard window와 drift 관측 결과 |
| `docs/master_analysis/03_operation_and_communication_protocol.md` | Master RX timing 판정과 frame format source of truth |

## 보류 판단

다음은 `slave2_timebase` design note 작성 시 확정한다.

- 정수 `bit_period_est`만 사용할지 fixed-point accumulator를 사용할지
- `o_RATE_ERR`를 pulse, sticky bit, counter 중 무엇으로 노출할지
- `GUARD_TICKS_DEFAULT` 대신 broadcast-latched guard를 실제 timebase에 반영할지
- majority sampling을 2.0 첫 구현에 포함할지

## 구현 순서 제안

1. `slave2_line_sync` design note/source/tb
2. `slave2_timebase` design note/source/tb
3. `slave2_tx` tick-driven 재설계
4. `slave2_rx` tick-driven 재설계
5. `slave2_top` integration
6. robust Master/Slave integration test
