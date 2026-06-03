# Master-Slave Simulation TB 작업 보고서

> **환경**: ModelSim Intel FPGA 18.1 / Verilog-2001  
> **실행**: `vsim -c -do run.do` (Slave TB) · `vsim -c -do run_master.do` (Master TB)  
> **최종 결과**: 전체 **125 PASS, 0 FAIL**

---

## 1. 모듈별 단위 테스트

### Slave 측
| 소스 파일 | 테스트 벤치 | 주요 검증 항목 |
|---|---|---|
| `hamming_enc.v` · `hamming_dec.v` | `tb_hamming_enc.v` · `tb_hamming_dec.v` | [42,35] SECDED 인코딩/디코딩, 1비트 정정, 2비트 검출 |
| `master_rx.v` | `tb_master_rx.v` | 프리앰블 검출, bc_valid/halt_cmd/guard_ticks 추출 |
| `slave_tx.v` | `tb_slave_tx.v` | NRZ 송신 프레임 구성, tristate 동작 |
| `slot_timer.v` | `tb_slot_timer.v` | tx_trigger 타이밍, no_broadcast 워치독 |
| `fault_fsm.v` | `tb_fault_fsm.v` | IDLE→NORMAL→DEAD 전이, fault/line 카운터 |
| `irq_ctrl.v` | `tb_irq_ctrl.v` | IRQ 세트/마스크/W1C 클리어 |

### Master 측
| 소스 파일 | 테스트 벤치 | 주요 검증 항목 |
|---|---|---|
| `master_module/Master_tx.v` | `tb/tb_Master_tx.v` | 브로드캐스트 프레임(halt_cmd·GUARD_TICKS 포함), 400 clk 완료 |
| `master_module/Master_rx.v` | `tb/tb_Master_rx.v` | 슬레이브 응답 수신, slot_pre_change 리셋 동작 |
| `master_module/Master_slot.v` | `tb/tb_Master_slot.v` | 슬롯 순환·타이밍, rx_stat 구간, cycle_cnt |
| `master_module/Master_dec_ham.v` | `tb/tb_Master_dec_ham.v` | 슬롯별 데이터 저장, 해밍 오류·silent 카운터 |

---

## 2. Top 레벨 통합 통신 테스트

### Slave Top + Master 통신 모듈
**`tdma_slave_top.v`** ↔ `Master_tx.v` · `Master_rx.v` · `Master_dec_ham.v`

- 테스트 벤치: `tb/tb_integration.v`
- Master 모듈이 브로드캐스트를 보내면 Slave Top이 수신·응답하고, Master 쪽에서 데이터를 복호하는 전 과정 검증

### Master Top + Slave 통신 모듈
**`master_module/Master_top.v`** ↔ `master_rx.v` · `slave_tx.v`

- 테스트 벤치: `tb/tb_master_top.v`
- Bus A(브로드캐스트 감지) · Bus B(슬레이브 응답 주입), ENABLE=0 정지, GUARD_TICKS=200 타이밍 검증

---

## 3. 전체 시스템 통합 테스트

**`master_module/Master_top.v`** ↔ **`tdma_slave_top.v`** (최대 7개 인스턴스)

| 테스트 벤치 | NODE_CNT | 주요 검증 항목 |
|---|---|---|
| `tb/tb_sys_integration.v` | 1 · 3 · 6 | IDLE→NORMAL, 전체 slot_out 갱신, 연속 안정성, no_broadcast IRQ, 비대칭 활성화, soft_rst 재동작 |
| `tb/tbfix_n7.v` | **7** | NODE_CNT_p1 3비트 오버플로우 수정 후 7슬레이브 전체 동작 확인 |

---

## 4. 수정 이력 (사본 적용, 원본 보존)

| 파일 | 수정 내용 |
|---|---|
| `master_module/Master_top.v` | syntax error 제거, `DIV_p1` 오프셋 삭제, `NODE_CNT_p1`·`slot` wire 4비트 확장 |
| `master_module/Master_slot.v` | `NODE_CNT` 포트·`slot` 레지스터 4비트 확장 (NODE_CNT=7 오버플로우 수정) |
| `clk_div.v` | `cnt == div` → `cnt == div - 1` (비트 주기 DIV 클럭 통일) |

> 상세 이슈 로그: `master_module/MASTER_ISSUES.md`
