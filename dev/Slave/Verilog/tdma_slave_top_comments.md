# tdma_slave_top.v — 한글 주석 설명서

## 모듈 역할

TDMA 슬레이브 IP의 최상위 래퍼. 7개의 서브모듈을 연결하고 물리 인터페이스를 제공한다.

- **tx_line 동기화**: 비동기 마스터 TX 입력을 2-FF 동기화 체인으로 처리
- **soft_rst**: CTRL.SOFT_RST 1클럭 펄스를 내부 리셋(`rst_int_n`)으로 변환
- **halt_cmd 추출**: 수신된 8비트 HALT_CMD에서 자신의 슬레이브 주소 비트를 추출

---

## 포트

### 클럭/리셋
| 포트 | 방향 | 설명 |
|------|------|------|
| `clk` | 입력 | 시스템 클럭 (예: 25 MHz) |
| `rst_n` | 입력 | 비동기 액티브-로우 리셋 |

### AXI-Lite (상세 포트는 regfile_comments.md 참조)
5비트 주소, 32비트 데이터의 AXI-Lite 슬레이브 인터페이스.
PS(ARM 프로세서)와 통신하여 설정/상태 조회.

### TDMA 물리 인터페이스
| 포트 | 방향 | 설명 |
|------|------|------|
| `tx_line` | 입력 | 마스터 TX 케이블 (비동기, 내부에서 2-FF 동기화) |
| `rx_line` | 출력 | 공유 RX 버스 (tristate). slave_tx가 구동 |
| `irq` | 출력 | 인터럽트 핀 (레벨, 액티브-하이) |

---

## 2-FF 동기화 체인 (tx_line)

```verilog
reg tx_ff1, tx_ff2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) {tx_ff2, tx_ff1} <= 2'b0;
    else        {tx_ff2, tx_ff1} <= {tx_ff1, tx_line};
end
wire tx_line_sync = tx_ff2;
```

- `tx_line` (비동기) → `tx_ff1` → `tx_ff2` → `tx_line_sync` (2클럭 지연)
- 메타스태빌리티 방지를 위한 표준 2-FF 동기화
- 리셋 시 두 FF 모두 0으로 초기화

---

## 내부 리셋 처리 (rst_int_n)

```verilog
wire rst_int_n = rst_n & ~soft_rst;
```

- `soft_rst`: CTRL[1] 비트. 1클럭 자동 클리어 펄스
- `rst_n & ~soft_rst`: SOFT_RST 발생 시 1클럭 동안 내부 모든 서브모듈 리셋
- **예외**: `regfile`은 `rst_n`을 직접 사용. SOFT_RST로 설정값이 지워지지 않음

---

## halt_cmd 비트 추출

```verilog
wire halt_cmd = bc_halt_cmd[slave_addr_cfg];
```

- 마스터 브로드캐스트의 8비트 HALT_CMD에서 자신의 슬레이브 주소(0~7) 비트만 추출  
- `slave_addr_cfg=3`이면 `bc_halt_cmd[3]`이 halt_cmd
- 이 신호가 `fault_fsm`에 전달되어 즉시 FAULT 진입 가능

---

## 서브모듈 연결 구조

```
                 [tx_line]
                     │ 2-FF sync
                     ▼
              [master_rx] ───────────────────────┐
                  │ active_edge                   │ bc_valid, bc_preamble_ok,
                  ▼                               │ bc_hamming_err, bc_preamble_err
              [slot_timer] ─── tx_trigger ──────► │
                  │ no_broadcast                  │
                  └───────────────────────────────▼
                                              [fault_fsm]
                                                  │ tx_enable    │ fsm_state
                                                  │              │ fault_cnt_out
                                                  ▼              │ line_cnt_out
                                           [slave_tx]            │
                                                  │ rx_line → [rx_line 출력]
                                                  │ data_sent
                                                  ▼
                                          [irq_ctrl]
                                                  │ irq → [irq 출력]
                                                  │ irq_status
                                                  ▼
                                           [regfile] ← AXI-Lite → PS
```

---

## 모듈별 리셋 연결 요약

| 서브모듈 | 리셋 신호 | 이유 |
|---------|----------|------|
| `regfile` | `rst_n` | SOFT_RST로 설정 레지스터 초기화 방지 |
| `clk_div` | `rst_int_n` | SOFT_RST 시 카운터 클리어 |
| `master_rx` | `rst_int_n` | SOFT_RST 시 FSM/버퍼 클리어 |
| `slot_timer` | `rst_int_n` | SOFT_RST 시 슬롯 카운터 클리어 |
| `fault_fsm` | `rst_int_n` | SOFT_RST 시 FSM/카운터 IDLE로 리셋 |
| `slave_tx` | `rst_int_n` | SOFT_RST 시 TX 강제 종료 |
| `irq_ctrl` | `rst_int_n` | SOFT_RST 시 IRQ_STATUS 클리어 |

---

## clk_div 사용 현황

`clk_div`는 인스턴스화되어 있으나, `master_rx`, `slave_tx`는 `clk_tick`을 사용하지 않는다.
각 모듈이 `div`를 직접 입력받아 내부적으로 NRZ 비트 타이밍을 계산하기 때문이다.
향후 확장 모듈을 위해 연결은 유지.
