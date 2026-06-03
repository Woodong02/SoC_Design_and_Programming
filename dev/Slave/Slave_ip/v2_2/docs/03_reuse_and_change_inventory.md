# Slave 2.2 재사용 및 변경 목록

## 재사용 파일 (변경 없음)

아래 파일은 v2.1에서 복사하여 `Slave_ip/v2_2/reuse/` 아래에 배치한다. 내용을 수정하지 않는다.

| 파일 | 원본 경로 | 검증 근거 |
|---|---|---|
| `slave21_rx.v` | `Slave_ip/v2_1/slave21_rx.v` | 단독 xsim PASS |
| `slave21_tx.v` | `Slave_ip/v2_1/slave21_tx.v` | 단독 xsim PASS |
| `slave21_fault_fsm.v` | `Slave_ip/v2_1/slave21_fault_fsm.v` | 단독 xsim PASS, FSM 정책 올바름 |
| `slave_hamming_enc.v` | `Slave_ip/v2_1/reuse/slave_hamming_enc.v` | v2.1 reuse_compat xsim PASS |
| `slave_hamming_dec.v` | `Slave_ip/v2_1/reuse/slave_hamming_dec.v` | v2.1 reuse_compat xsim PASS |
| `slave_control.v` | `Slave_ip/v2_1/reuse/slave_control.v` | v2.1 reuse_compat xsim PASS |
| `slave2_line_sync.v` | `Slave_ip/v2_1/reuse/slave2_line_sync.v` | v2.1 reuse_compat xsim PASS |

---

## 새로 작성하는 파일

### slave22_timebase

| 항목 | 내용 |
|---|---|
| 경로 | `Slave_ip/v2_2/slave22_timebase.v` |
| seed | `Slave_ip/v2_1/slave21_timebase.v` |
| 변경 이유 | holdover 동작, miss_count, period_valid 정책 변경 |

포트는 slave21_timebase와 동일하게 유지한다. top 교체가 인터페이스 변경 없이 가능해야 한다.

추가 파라미터:

```verilog
parameter [3:0] MISS_RESET_LIMIT = 4'd4
```

### slave22_top

| 항목 | 내용 |
|---|---|
| 경로 | `Slave_ip/v2_2/slave22_top.v` |
| seed | `Slave_ip/v2_1/slave21_top.v` |
| 변경 이유 | slave22_timebase 인스턴스 교체 |

slave21_top 대비 변경점은 timebase 인스턴스 이름과 모듈명 교체뿐이다.

---

## TB seed

| TB 파일 | seed |
|---|---|
| `tb/tb_slave22_timebase.v` | `tb/tb_slave21_timebase.v` |
| `tb/tb_slave22_top_smoke.v` | `tb/tb_slave21_top_smoke.v` |
| `tb/tb_slave22_top_full_serial.v` | `tb/tb_slave21_top_full_serial.v` |
| `tb/tb_slave22_master_link.v` | `tb/tb_slave21_master_link.v` |
| `tb/tb_slave22_master_harsh_link.v` | `tb/tb_slave21_master_harsh_link.v` |
| `tb/tb_slave22_comm_worst_case.v` | `tb/tb_slave21_comm_worst_case.v` |

---

## 변경하지 않는 파일

v2.1 및 이전 버전의 어떤 파일도 수정하지 않는다.
Master_ip 파일을 수정하지 않는다.
