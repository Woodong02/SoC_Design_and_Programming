# 슬레이브 Verilog 구현 — 스펙(v0.4) 대비 차이점

> 대상 문서: 00_overview ~ 08_slave_port_def (v0.4)
> 슬레이브 역할로 구현한 모듈 기준. 마스터 역할 파일은 이 목록에서 제외.

---

## 1. NRZ 인코딩 (스펙: Manchester)

**스펙**: 모든 비트 전송에 Manchester 인코딩(셀프 클로킹, 비트 중간에 반드시 전이 발생).

**구현**: NRZ(Non-Return-to-Zero) 인코딩. 비트 값을 `2*(DIV+1)` 클럭 사이클 동안 HIGH/LOW 레벨로 유지.

**변경 이유**: 구현 복잡도 절감. Manchester의 비트 중간 전이 감지 로직 불필요. 샘플 포인트를 비트 주기 중간(`DIV+1` 클럭)으로 고정하여 NRZ에서도 안정적 수신 가능.

**영향 범위**: `master_rx.v`, `master_tx.v`, `slave_tx.v`, `slave_rx.v` 전체의 비트 타이밍 로직.

---

## 2. 프리앰블 0xAA (스펙: 0x55)

**스펙**: `preamble = 0x55` (01010101, MSB first). Manchester 클럭 복원용.

**구현**: `preamble = 0xAA` (10101010, MSB first). 수신기에서 `buffer[7:0] == 8'hAA` 검증.

**변경 이유**: NRZ 인코딩 전환으로 인한 연쇄 변경.
- 아이들 레벨이 High-Z → 0 (TB에서 풀다운 처리)인 상태에서, 프레임 시작 시 첫 비트가 **1**(HIGH)이어야 `active_edge`(0→1 상승 에지)가 발생한다.
- 0x55(01010101)의 첫 비트는 **0**이므로 아이들 상태(0)에서 상승 에지가 발생하지 않는다.
- 0xAA(10101010)의 첫 비트는 **1**이므로 아이들 0 다음에 바로 상승 에지를 만든다.
- Manchester에서 0x55는 클럭 복원용 알터네이팅 패턴으로 적합했으나, NRZ에서는 0xAA가 `active_edge` 트리거 조건에 부합한다.

**영향 범위**: `master_rx.v`(수신 검증), `master_tx.v`, `slave_tx.v`(송신 조립), `slave_rx.v`(수신 검증).

---

## 3. master_rx / slave_tx에서 clk_tick 입력 제거

**스펙 (`08_slave_port_def` §3.2, §3.4)**: `master_rx`와 `slave_tx` 모두 `clk_tick` 입력 포트를 가짐. `clk_div`에서 생성된 `clk_tick`(주기 = DIV+1 클럭)을 비트 타이밍 기준으로 사용.

**구현**: `master_rx`, `slave_tx` 모두 `clk_tick` 포트 없음. 대신 `div[9:0]`을 직접 입력받아 각 모듈 내부에서 독립적인 비트 카운터를 운용.

```
비트 카운터: cnt_max = {div, 1'b1}  (= 2*DIV+1, 주기 = 2*(DIV+1))
샘플 포인트:  samp_point = div + 1  (비트 중간)
```

**변경 이유**: NRZ에서 비트 주기가 `2*(DIV+1)` 클럭이므로, `clk_tick`(DIV+1 주기) 두 번이 한 비트에 해당한다. clk_tick 기반으로 구현하면 2 tick = 1 bit 구조의 추가 상태가 필요해지므로, 직접 카운터 방식이 더 단순하다.

**clk_div 모듈**: 구현되어 있으나 `master_rx`, `slave_tx`에서 사용되지 않음. 향후 확장(타이머, 외부 tick 필요 로직)을 위해 `tdma_slave_top`에서 인스턴스는 유지.

---

## 4. slot_timer — enable 포트 및 slot_ticks 출력 없음

**스펙 (`08_slave_port_def` §3.3)**:
```verilog
module slot_timer (
    input  wire        enable,
    ...
    output wire [31:0] slot_ticks,   // 계산된 slot_ticks 참고용 출력
    ...
);
```

**구현**: `enable` 입력 포트 없음. `slot_ticks` 출력 포트 없음.

- `enable` 없음: 모듈은 항상 활성. enable 비활성화 효과는 `rst_int_n = rst_n & ~soft_rst`로 상위에서 처리.
- `slot_ticks` 출력 없음: 내부 wire로만 존재. `SLOT_TICKS_RO` 레지스터가 스펙에 있으나 구현된 슬레이브 regfile에 포함되지 않음.

---

## 5. fault_fsm — enable 포트 없음 / 포트 이름 차이

**스펙 (`08_slave_port_def` §3.5)**: `fault_fsm`이 `enable` 입력 보유. 출력 포트명: `state`, `fault_cnt`, `line_cnt`. 입력: `bc_halt_cmd_self`.

**구현**: `enable` 없음. 출력 포트명: `fsm_state`, `fault_cnt_out`, `line_cnt_out`. 입력: `halt_cmd`.

| 스펙 포트 | 구현 포트 | 비고 |
|----------|---------|------|
| `enable` | (없음) | rst_int_n으로 대체 |
| `state` | `fsm_state` | 동일 기능 |
| `fault_cnt` | `fault_cnt_out` | 동일 기능 |
| `line_cnt` | `line_cnt_out` | 동일 기능 |
| `bc_halt_cmd_self` | `halt_cmd` | 동일 신호, 이름만 다름 |
| `no_broadcast_flag` | (없음) | `no_broadcast` 직접 irq_ctrl에 연결 |
| `bc_hamming_err_flag` | (없음) | `bc_hamming_err` 직접 irq_ctrl에 연결 |
| `halt_cmd_flag` | (없음) | `halt_cmd` 직접 irq_ctrl에 연결 |

---

## 6. fault_fsm — NORMAL→DATA_RECOVERY 추가 전이 (스펙에 없는 경로)

**스펙 (`04_fault_decisions` §5.2)**:
```
NORMAL  [FAULT_CNT < FAULT_TH]
  └─(FAULT_CNT ≥ FAULT_TH)──────────────────────▶ FAULT
```
NORMAL 상태에서 직접 DATA_RECOVERY로 가는 전이 없음. FAULT를 거쳐야 DATA_RECOVERY 진입 가능.

**구현**:
```verilog
NORMAL: begin
    ...
    end else if (fault_cnt > 8'd0) begin
        fsm_state <= DATA_RECOVERY;   // 스펙에 없는 경로
    end
end
```

NORMAL에서 fault_cnt > 0 이면 DATA_RECOVERY로 즉시 전이.

**결과적 의미**: 구현에서 NORMAL = `fault_cnt == 0`, DATA_RECOVERY = `0 < fault_cnt < fault_th`로 상태를 엄격하게 구분. 스펙에서는 NORMAL이 `fault_cnt < fault_th` 전체를 포함하고, DATA_RECOVERY는 "FAULT 이후 복구 중"이라는 의미를 가짐.

tx_enable 동작(NORMAL/DATA_RECOVERY 모두 1)은 동일하므로 외부 기능 영향 없음.

---

## 7. fault_fsm — DEAD→IDLE (스펙: DEAD→NORMAL)

**스펙 (`04_fault_decisions` §5.2)**:
```
DEAD  [LINE_CNT ≥ LINE_FAULT_TH]
  └─(LINE_CNT == 0)─────────────────────────▶ NORMAL
      (FAULT_CNT도 0으로 초기화)
```

**구현**:
```verilog
DEAD: begin
    if (line_cnt == 8'd0) begin
        fsm_state <= IDLE;   // NORMAL이 아닌 IDLE로 복귀
    end
end
```

DEAD에서 LINE_CNT가 0이 되면 NORMAL이 아닌 IDLE로 전이. IDLE에서는 다음 `active_edge`를 받아야 NORMAL로 전이.

**의미 차이**: 스펙은 LINE_CNT 회복 후 즉시 정상 동작 재개. 구현은 마스터 동기 재획득(active_edge) 후 재개. 구현이 더 보수적인 동작.

---

## 8. fault_fsm — bc_preamble_err를 별도 LINE_CNT +10 트리거로 분리

**스펙 (`04_fault_decisions` §1.2)**: 슬레이브 도메인에서 `NO_BROADCAST`는 "CYCLE_TIMEOUT_TICKS 내 액티브 에지 미감지, **또는** preamble(0x55) 패턴 불일치" 둘 다 포함. 모두 slot_timer의 `no_broadcast` 신호로 통합.

**구현**: slot_timer의 `no_broadcast`(watchdog 타임아웃)와 master_rx의 `bc_preamble_err`(preamble 불일치)를 fault_fsm에서 별도 입력으로 처리. 둘 다 LINE_CNT +10 적용.

```verilog
if (no_broadcast || bc_preamble_err) begin
    line_cnt <= ... + 10;
end
```

**기능 차이 없음**: 결과적으로 LINE_CNT 동작은 스펙과 동일. 다만 스펙의 `no_broadcast` 단일 신호 대신 두 신호의 OR로 처리.

---

## 9. slot_timer — watchdog 재발화 없음

**스펙 (`03_sync_decisions` §4.2)**:
```
watchdog_cnt >= 9 × slot_ticks → NO_BROADCAST 이벤트
→ watchdog_cnt = 0으로 리셋, 다음 에지 대기
```
NO_BROADCAST 발생 후 watchdog_cnt가 0으로 리셋되어 다음 9×slot_ticks 후 재발화.

**구현**: `slot_cnt`는 active_edge에서만 리셋. NO_BROADCAST 후에도 계속 증가. `slot_cnt == wdog_cnt` 조건으로 1회만 발화. slot_cnt가 wdog_cnt를 넘어서면 재발화 없음.

**영향**: 마스터가 2사이클 이상 브로드캐스트를 하지 않아도 LINE_CNT는 1회 +10만 발생. 스펙은 브로드캐스트 부재 지속 시간에 비례해 LINE_CNT가 누적되어야 함.

---

## 10. regfile — 포트 이름 차이

스펙의 `regfile` 포트 중 일부가 구현에서 다른 이름으로 연결됨 (기능은 동일).

| 스펙 포트명 | 구현 포트명 |
|-----------|-----------|
| `tx_data_out` | `tx_data` |
| `state_in` | `fsm_state` |
| `fault_cnt_in` | `fault_cnt` |
| `line_cnt_in` | `line_cnt` |
| `data_sent_in` | `ev_data_sent` |
| `no_broadcast_flag_in` | `ev_no_broadcast` |
| `bc_hamming_err_flag_in` | `ev_hamming_err` |
| `halt_cmd_flag_in` | `ev_halt_cmd` |
| `irq_mask_out` | `irq_mask` |
| `irq_status_in` | `irq_status` |
| `slave_addr` (출력) | `slave_addr_cfg` |

---

## 11. master_rx — bc_preamble_ok 세팅 시점

**스펙 (`08_slave_port_def` §3.2)**: `bc_preamble_ok`: "preamble(0x55) 수신 성공. bc_hamming_err와 무관하게 세팅 가능."

**구현**: `bc_preamble_ok`는 PREAMBLE 상태에서 bit_cnt==8 시점에 `buffer[7:0] == 8'hAA`이면 1클럭 펄스. 이후 DATA 상태 종료 시 `preamble_ok_latch`가 1이어야 bc_valid가 세팅됨.

Hamming 오류가 있어도 `bc_preamble_ok`는 독립적으로 세팅 — 스펙과 동일.

---

## 12. master_tx / slave_rx — 스펙에 별도 모듈 정의 없음

**상황**: `master_tx.v`와 `slave_rx.v`는 이 슬레이브 폴더에서 구현되었으나, 스펙의 `07_master_port_def(4).md`는 마스터 모듈 구성을 정의하고 있어 슬레이브 IP 범위가 아님.

**구현 내용**:
- `master_tx.v`: 마스터 브로드캐스트 NRZ 송신. 프레임 `{8'hAA, halt_cmd[7:0], 27'b0, hamming[6:0]}`. slave_tx와 동일 타이밍.
- `slave_rx.v`: 슬레이브 프레임 NRZ 수신 (마스터 측). 프레임 역파싱: `buffer[41:39]=addr`, `buffer[38:7]=payload`. master_rx와 동일 FSM 구조.

양쪽 모두 slave_tx/master_rx와 동일한 Hamming SEC-DED 로직 공유.
