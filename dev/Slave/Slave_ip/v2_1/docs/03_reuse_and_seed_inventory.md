# Slave 2.1 재사용/Seed 파일 목록

## 목적

후임 세션이 같은 파일을 다시 만들지 않도록, 1.0/2.0에서 가져온 파일과 수정 필요 여부를 정리한다.

## 그대로 재사용 가능한 RTL

아래 파일은 2.1 작업 영역에 복사되어 있다.

| Source copy | Original | 2.1 판단 |
|---|---|---|
| `Slave_ip/v2_1/reuse/slave_hamming_enc.v` | `Slave_ip/v1_0/slave_hamming_enc.v` | Master 호환 Hamming encoder. 그대로 사용 가능. |
| `Slave_ip/v2_1/reuse/slave_hamming_dec.v` | `Slave_ip/v1_0/slave_hamming_dec.v` | Master 호환 Hamming decoder. 그대로 사용 가능. |
| `Slave_ip/v2_1/reuse/slave_control.v` | `Slave_ip/v1_0/slave_control.v` | broadcast field latch/halt policy로 사용 가능. 최종 TX enable은 `slave21_fault_fsm`과 AND 해야 함. |
| `Slave_ip/v2_1/reuse/slave2_line_sync.v` | `Slave_ip/v2_0/slave2_line_sync.v` | 2-stage line synchronizer. 그대로 사용 가능. 이름을 `slave21_line_sync`로 바꿀지는 top 설계 시 결정. |

## 그대로 당겨온 TB

| TB copy | Original | 2.1 판단 |
|---|---|---|
| `tb/v2_1_seed/tb_slave2_line_sync_reuse.v` | `tb/tb_slave2_line_sync.v` | line sync 재사용 검증에 활용 가능. module name/path만 조정하면 됨. |
| `tb/v2_1_seed/tb_slave2_reuse_compat_reuse.v` | `tb/tb_slave2_reuse_compat.v` | Hamming/control 재사용 검증에 활용 가능. 2.1 path로 조정 필요. |

관련 실행 script seed:

| Script copy | Original | 판단 |
|---|---|---|
| `sim/v2_1_seed/run_slave2_line_sync_reuse_xsim.tcl` | `sim/slave2_line_sync/run_xsim.tcl` | source/TB path만 2.1 seed 경로로 조정 필요. |
| `sim/v2_1_seed/run_slave2_reuse_compat_reuse_xsim.tcl` | `sim/slave2_reuse_compat/run_xsim.tcl` | source/TB path만 2.1 seed 경로로 조정 필요. |

## 유사하지만 수정 필요한 RTL Seed

아래 파일은 새로 만들지 않도록 seed로 복사했지만, 2.1 구조와 직접 호환되지 않는다. 반드시 design note를 먼저 갱신한 뒤 수정해야 한다.

| Seed copy | Original | 수정 필요 이유 |
|---|---|---|
| `Slave_ip/v2_1/seed_from_v2_0/slave2_rx__needs_2_1_rework.v` | `Slave_ip/v2_0/slave2_rx.v` | 2.0 RX는 external sample tick 기반이다. 2.1 RX는 `i_BIT_PERIOD` snapshot + internal frame-local timer 구조로 바꿔야 한다. |
| `Slave_ip/v2_1/seed_from_v2_0/slave2_tx__needs_2_1_rework.v` | `Slave_ip/v2_0/slave2_tx.v` | 2.0 TX는 `i_TX_BIT_TICK` 기반이다. 2.1 TX는 `i_BIT_PERIOD` snapshot + internal full-width bit timer 구조로 바꿔야 한다. |
| `Slave_ip/v2_1/seed_from_v2_0/slave2_timebase__needs_2_1_rework.v` | `Slave_ip/v2_0/slave2_timebase.v` | 2.0 timebase는 RX/TX ticks를 생성한다. 2.1 timebase는 period estimate, slot phase, gated TX trigger만 담당해야 한다. |
| `Slave_ip/v2_1/seed_from_v2_0/slave2_top__needs_2_1_rework.v` | `Slave_ip/v2_0/slave2_top.v` | 2.0 top에는 `slave21_fault_fsm`이 없고 tick 기반 배선이다. 2.1 frame-complete commit 구조로 재배선해야 한다. |

## 유사하지만 수정 필요한 TB Seed

| Seed copy | Original | 수정 필요 이유 |
|---|---|---|
| `tb/v2_1_seed/tb_slave2_rx__needs_2_1_rework.v` | `tb/tb_slave2_rx.v` | sample tick stimulus를 bit period snapshot 검증으로 변경해야 한다. |
| `tb/v2_1_seed/tb_slave2_tx__needs_2_1_rework.v` | `tb/tb_slave2_tx.v` | `i_TX_BIT_TICK` stimulus를 제거하고 first bit full-width와 period snapshot을 검증해야 한다. |
| `tb/v2_1_seed/tb_slave2_timebase__needs_2_1_rework.v` | `tb/tb_slave2_timebase.v` | tick output 검증을 제거하고 commit interval/rate/trigger gating 검증으로 변경해야 한다. |
| `tb/v2_1_seed/tb_slave2_top_smoke__needs_2_1_rework.v` | `tb/tb_slave2_top_smoke.v` | `slave21_fault_fsm`, two-good-broadcast TX gating을 반영해야 한다. |
| `tb/v2_1_seed/tb_slave2_top_full_serial__needs_2_1_rework.v` | `tb/tb_slave2_top_full_serial.v` | 2.0 실패 관측 TB이다. 2.1에서는 first good no-TX, second good TX, bad frame recovery를 검증하도록 재작성해야 한다. |

관련 실행 script seed:

| Script copy | 판단 |
|---|---|
| `sim/v2_1_seed/run_slave2_rx__needs_2_1_rework_xsim.tcl` | 2.1 source/TB 경로로 수정 필요 |
| `sim/v2_1_seed/run_slave2_tx__needs_2_1_rework_xsim.tcl` | 2.1 source/TB 경로로 수정 필요 |
| `sim/v2_1_seed/run_slave2_timebase__needs_2_1_rework_xsim.tcl` | 2.1 source/TB 경로로 수정 필요 |
| `sim/v2_1_seed/run_slave2_top_smoke__needs_2_1_rework_xsim.tcl` | 2.1 source/TB 경로로 수정 필요 |
| `sim/v2_1_seed/run_slave2_top_full_serial__needs_2_1_rework_xsim.tcl` | 2.1 source/TB 경로로 수정 필요 |

## 후임 작업 주의사항

- Seed 파일명에 `needs_2_1_rework`가 있으면 그대로 compile target에 넣지 않는다.
- 해당 seed는 새 `slave21_*` source를 만들 때 참고용으로만 사용한다.
- 그대로 재사용 가능한 `reuse/*` 파일도 top integration에서 다시 compile하여 호환성을 확인한다.
- 2.1 구현 파일은 `Slave_ip/v2_1/slave21_*.v`로 새로 작성한다.

