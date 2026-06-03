# Project Structure

이 문서는 정리 후 프로젝트 디렉토리의 기준 구조를 설명한다.

## Top-Level Files

| Path | Purpose |
|---|---|
| `AGENTS.md` | AI 작업 하네스 규칙 |
| `CODING_STANDARDS.md` | Verilog HDL 코딩 표준 |
| `Fault_decisions_chart.jpg` | Master-side fault decision source-of-truth image |

루트 디렉토리에는 source, 핵심 규칙, 원본 reference만 둔다. Vivado `.log`, `.jou`, `.backup.*`, `.Xil` 같은 tool artifact는 루트에 두지 않는다.

## Source Directories

| Path | Purpose |
|---|---|
| `Master_ip` | 현재 Master PL Verilog source |
| `Master_ps` | Master PS-side C source, Xilinx BSP/include/lib references |
| `Slave_ip` | Slave IP versioned source workspace |
| `Slave_ip/v1_0` | 기존 Slave 1.0 Verilog source 보존 위치 |
| `Slave_ip/v2_0` | 통신 강인성 개선용 Slave 2.0 작업 위치 |

Slave 1.0 source는 `Slave_ip/v1_0`에 보존한다. Slave 2.0 작업은 `Slave_ip/v2_0`에서 진행하며, 구조 기준은 `Slave_ip/v2_0/docs/00_slave2_robust_structure.md`를 따른다.

## Testbench and Simulation Directories

| Path | Purpose |
|---|---|
| `tb` | Slave module-level 및 integration testbench |
| `sim` | Simulation/smoke-check scripts, logs, and work directories |
| `sim/master_smoke` | Master RTL Vivado smoke check workspace |
| `sim/master_smoke/scripts` | Master smoke check Tcl scripts |
| `sim/master_smoke/logs` | Master smoke check `.log` / `.jou` output |
| `sim/master_smoke/work` | Vivado temporary working directory, created when scripts run |

Vivado batch 실행 시 `-log`와 `-journal`을 사용해 로그를 각 simulation 하위 `logs` 폴더로 보낸다. 구체적인 Master smoke 실행 명령은 `sim/master_smoke/README.md`를 따른다.

## Documentation Directories

| Path | Purpose |
|---|---|
| `docs` | 분석, 설계, handoff 문서 |
| `docs/master_analysis` | 현재 Master PL+PS 분석 문서 |
| `docs/slave_requirements` | Master 분석 기반 Slave PL-only 요구사항 |
| `docs/slave_design` | Slave module structure, slot timer decision, future module design notes |

## Current Documentation Artifacts

| Path | Purpose |
|---|---|
| `docs/Fault_decisions_chart_transcription.md` | Fault decision chart 판독 기록 |
| `docs/master_analysis/00_analysis_scope_and_method.md` | Master 분석 범위와 방법 |
| `docs/master_analysis/01_pl_module_inventory.md` | Master PL module inventory |
| `docs/master_analysis/02_axi_ps_register_map.md` | AXI register map과 PS control flow |
| `docs/master_analysis/03_operation_and_communication_protocol.md` | Master operation/communication protocol |
| `docs/master_analysis/04_fault_decision_behavior.md` | Fault decision 구현 분석 |
| `docs/master_analysis/06_vivado_smoke_check.md` | Vivado smoke check 및 `DIV_p1` 수정 기록 |
| `docs/slave_requirements/00_slave_pl_only_requirements.md` | Slave PL-only 요구사항 |
| `docs/slave_design/00_slave_spec_and_module_structure.md` | Slave 사양 및 module structure |
| `docs/slave_design/01_session_handoff_slot_timer.md` | Slot timer 결정사항 handoff |
| `docs/slave_design/10_slave_2_0_robust_structure.md` | Slave 2.0 robust communication 구조 설계 원본 |
| `Slave_ip/v2_0/docs/00_slave2_robust_structure.md` | 2.0 작업 디렉토리 내 구조 설계 사본 |
| `Slave_ip/v2_0/docs/01_reuse_and_modification_plan.md` | 1.0 재사용/수정/재설계 판단표 |

## Removed/Superseded Material

다음 항목은 최신 Master 구현 및 Slave 설계 결정과 충돌할 위험이 있어 정리했다.

| Removed Path | Reason |
|---|---|
| `이전 버전의 master와 slave 사양` | 구버전 사양. Manchester/old register map/old fault policy 등 현재 구현과 충돌 가능 |
| `docs/master_analysis/05_slave_pl_only_requirements.md` | 최신 `docs/slave_requirements` 및 `docs/slave_design` 문서로 대체됨 |
| root `*.log`, `*.jou`, `.backup.*`, `.Xil` | tool artifact. 앞으로 `sim/**/logs` 또는 `sim/**/work`에 생성 |

## Master PL Source Files

| Path | Role |
|---|---|
| `Master_ip/Master_v1_0.v` | Vivado packaged IP top wrapper |
| `Master_ip/Master_v1_0_S00_AXI.v` | AXI-Lite slave/register interface |
| `Master_ip/Master_top.v` | Master internal top-level logic |
| `Master_ip/Master_tx.v` | Master broadcast transmit path |
| `Master_ip/Master_rx.v` | Slave response receive path |
| `Master_ip/Master_slot.v` | Slot/timing scheduler |
| `Master_ip/error_with_hamming.v` | Hamming decode and fault counter handling |
| `Master_ip/hamming_enc.v` | Master Hamming encoder reference |
| `Master_ip/hamming_dec.v` | Master Hamming decoder reference |
| `Master_ip/seven_seg.v` | Seven-segment display helper |
| `Master_ip/bin2seg.v` | Binary-to-seven-segment conversion |

## Next Implementation Entry Points

다음 세션은 아래 문서를 먼저 읽고 시작한다.

1. `docs/slave_requirements/00_slave_pl_only_requirements.md`
2. `Slave_ip/v2_0/docs/00_slave2_robust_structure.md`
3. `Slave_ip/v2_0/docs/01_reuse_and_modification_plan.md`
4. `CODING_STANDARDS.md`
5. `AGENTS.md`
