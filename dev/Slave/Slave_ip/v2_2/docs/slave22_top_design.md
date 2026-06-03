# slave22_top 설계 노트

## 목적

`slave22_top`은 v2.1의 `slave21_top` 구조를 그대로 계승하며, **타임베이스 leaf만 `slave22_timebase`로 교체**한 통합 top 모듈이다. 인터페이스(파라미터/포트)는 `slave21_top`과 완전히 동일하다.

## slave21_top 대비 차이 (단 하나)

| 항목 | slave21_top | slave22_top |
|---|---|---|
| 모듈명 | `slave21_top` | `slave22_top` |
| 타임베이스 인스턴스 모듈 | `slave21_timebase` | `slave22_timebase` |
| 타임베이스 인스턴스 이름 | `u_timebase` | `u_timebase` (동일) |
| 타임베이스 포트 연결 | 동일 | 동일 (인터페이스 변경 없음) |
| fault FSM | `slave21_fault_fsm` | `slave21_fault_fsm` (유지) |
| 그 외 모든 leaf/파라미터/포트/wiring | - | 변경 없음 |

`slave22_timebase`는 `slave21_timebase`와 포트가 완전히 동일하고, 추가 파라미터 `MISS_RESET_LIMIT`(기본 4'd4)만 갖는다. top에서는 이 파라미터를 명시적으로 지정하지 않고 기본값을 사용한다. 따라서 인스턴스화 시 포트 연결 코드는 한 글자도 바뀌지 않으며, **모듈명만** `slave21_timebase` → `slave22_timebase`로 교체된다.

## 인스턴스 / wiring 표

| 인스턴스 | 모듈 | 비고 |
|---|---|---|
| `u_line_sync` | `slave2_line_sync` | reuse, 변경 없음 |
| `u_rx` | `slave21_rx` | reuse, 변경 없음 |
| `u_hamming_dec` | `slave_hamming_dec` | reuse, 변경 없음 |
| `u_control` | `slave_control` | reuse, 변경 없음 |
| `u_fault_fsm` | `slave21_fault_fsm` | reuse, 변경 없음 |
| `u_timebase` | **`slave22_timebase`** | **교체된 부분** |
| `u_tx` | `slave21_tx` | reuse, 변경 없음 |

타임베이스 포트 연결 (slave21_top와 동일):

| 포트 | 연결 wire |
|---|---|
| `i_CLK` | `clk` |
| `i_RESETN` | `resetn` |
| `i_NODE_ID` | `NODE_ID` |
| `i_NODE_CNT` | `NODE_CNT` |
| `i_BIT_PERIOD_DEFAULT` | `BIT_PERIOD_DEFAULT` |
| `i_GUARD_TICKS` | `timebase_guard_ticks` |
| `i_GOOD_BROADCAST_COMMIT` | `good_broadcast_commit` |
| `i_TX_ACTIVE` | `tx_active` |
| `i_TX_ALLOWED` | `final_tx_enable` |
| `o_BIT_PERIOD` | `timebase_bit_period` |
| `o_PERIOD_VALID` | `timebase_period_valid` |
| `o_SLOT` | `timebase_slot` |
| `o_SLOT_CLK_CNT` | `timebase_slot_clk_cnt` |
| `o_TX_TRIGGER` | `timebase_tx_trigger` |
| `o_RATE_ERR` | `timebase_rate_err` |

## 파일 참조 경로 (sim run_xsim.tcl)

- reuse leaf: `Slave_ip/v2_2/reuse/` 하위
- 신규: `Slave_ip/v2_2/slave22_timebase.v`, `Slave_ip/v2_2/slave22_top.v`

## TB 정책

- `tb_slave22_top_smoke`, `tb_slave22_top_full_serial`은 seed TB(slave21)의 DUT 인스턴스만 `slave22_top`으로 교체한다. timebase의 holdover/period_valid 정책 변경은 smoke/full_serial seed의 정상 흐름(연속 good broadcast) 시나리오에서는 동작이 동등하게 유지되므로 기대값을 그대로 둔다.
- self-checking: `$display`로 PASS/FAIL, 마지막에 전체 요약.
