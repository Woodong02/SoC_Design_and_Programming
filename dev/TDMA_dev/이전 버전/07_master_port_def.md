# TDMA Master IP — 모듈 포트 정의

> 버전: 0.1 · 작성일: 2026-05-18
>
> **표기 규칙**
> - `clk_tick`은 실제 클럭이 아닌 enable 펄스 (매 DIV+1 clk 사이클마다 1클럭 폭으로 High)
> - 모든 리셋은 active-low 동기 리셋 (`rst_n`)
> - 비트 범위 표기: `[MSB:LSB]`

---

## 모듈 계층

```
tdma_master_top
├── clk_div
├── slot_timer
├── master_tx
├── slave_rx_ch [×NODE_CNT, generate]
│   ├── phy_rx
│   └── frame_dec
├── fault_fsm   [×NODE_CNT, generate]
│   └── sync_monitor
├── regfile
└── irq_ctrl
```

---

## 1. `tdma_master_top`

최상위 모듈. 외부 핀과 직접 연결된다.

| 포트 | 방향 | 폭 | 설명 |
|------|------|----|------|
| `clk` | input | 1 | 시스템 클럭 (25 MHz) |
| `rst_n` | input | 1 | 시스템 리셋 (active-low) |
| `tx_line` | output | 1 | 마스터 브로드캐스트 TX 라인 (모든 슬레이브 공유) |
| `rx_line[7:0]` | input | 8 | 슬레이브 n의 RX 라인 (rx_line[n] ↔ 슬레이브 n) |
| `irq` | output | 1 | 인터럽트 핀 |
| `s_axi_awaddr[31:0]` | input | 32 | AXI-Lite 쓰기 주소 |
| `s_axi_awvalid` | input | 1 | |
| `s_axi_awready` | output | 1 | |
| `s_axi_wdata[31:0]` | input | 32 | AXI-Lite 쓰기 데이터 |
| `s_axi_wstrb[3:0]` | input | 4 | |
| `s_axi_wvalid` | input | 1 | |
| `s_axi_wready` | output | 1 | |
| `s_axi_bresp[1:0]` | output | 2 | |
| `s_axi_bvalid` | output | 1 | |
| `s_axi_bready` | input | 1 | |
| `s_axi_araddr[31:0]` | input | 32 | AXI-Lite 읽기 주소 |
| `s_axi_arvalid` | input | 1 | |
| `s_axi_arready` | output | 1 | |
| `s_axi_rdata[31:0]` | output | 32 | AXI-Lite 읽기 데이터 |
| `s_axi_rresp[1:0]` | output | 2 | |
| `s_axi_rvalid` | output | 1 | |
| `s_axi_rready` | input | 1 | |

---

## 2. `clk_div`

**책임**: 시스템 클럭을 `DIV+1`로 분주하여 `clk_tick` enable 펄스를 생성한다.

| 포트 | 방향 | 폭 | 설명 |
|------|------|----|------|
| `clk` | input | 1 | 시스템 클럭 |
| `rst_n` | input | 1 | 리셋 |
| `div[9:0]` | input | 10 | 분주비. 출력 주기 = (DIV+1) 클럭 |
| `clk_tick` | output | 1 | 틱 enable 펄스 |

---

## 3. `slot_timer`

**책임**: TDMA 사이클 및 슬롯 경계를 관리한다. `SLOT_TICKS`, `GUARD_MIN`을 자동 계산하고, 각 슬롯의 RX 윈도우 및 guard time 구간 신호를 출력한다. 마스터의 자유 진행 카운터(`tx_tick`)를 관리한다.

| 포트 | 방향 | 폭 | 설명 |
|------|------|----|------|
| `clk` | input | 1 | 시스템 클럭 |
| `rst_n` | input | 1 | 리셋 |
| `clk_tick` | input | 1 | 틱 enable |
| `enable` | input | 1 | CTRL.ENABLE |
| `div[9:0]` | input | 10 | LINK_CFG.DIV (frame_ticks 계산용) |
| `retry_cnt[2:0]` | input | 3 | LINK_CFG.RETRY_CNT |
| `guard_ticks[9:0]` | input | 10 | LINK_CFG.GUARD_TICKS |
| `node_cnt[2:0]` | input | 3 | NODE_CFG.NODE_CNT |
| `slot_ticks[31:0]` | output | 32 | 자동 계산된 슬롯 길이 → SLOT_TICKS 레지스터 |
| `guard_min[31:0]` | output | 32 | 자동 계산된 최소 guard time → GUARD_MIN 레지스터 |
| `tx_tick[31:0]` | output | 32 | 마스터 자유 진행 카운터 값 → TX_TICK 레지스터, master_tx |
| `cycle_start` | output | 1 | 사이클 시작 펄스 (master_tx 트리거) |
| `cycle_done` | output | 1 | 사이클 완료 펄스 (irq_ctrl, CYCLE_CNT 증가) |
| `slot_rx_en[7:0]` | output | 8 | 비트 n: 슬롯 n의 RX 윈도우 활성 구간 |
| `slot_guard[7:0]` | output | 8 | 비트 n: 슬롯 n의 guard time 구간 |

---

## 4. `master_tx`

**책임**: 매 사이클 시작 시 마스터 브로드캐스트 프레임을 생성하여 TX 라인에 직렬 출력한다. 프레임 구조: `[preamble 8b][TX_TICK 32b][CRC-16 16b]`. Manchester 인코딩 포함.

| 포트 | 방향 | 폭 | 설명 |
|------|------|----|------|
| `clk` | input | 1 | 시스템 클럭 |
| `rst_n` | input | 1 | 리셋 |
| `clk_tick` | input | 1 | 틱 enable (비트 타이밍 기준) |
| `cycle_start` | input | 1 | 사이클 시작 펄스. 이 시점의 `tx_tick` 값을 프레임에 삽입 |
| `tx_tick[31:0]` | input | 32 | 삽입할 타임스탬프 |
| `tx_line` | output | 1 | Manchester 인코딩된 직렬 출력 |

---

## 5. `slave_rx_ch`

**책임**: 슬레이브 n의 RX 라인에서 Manchester 디코딩, 프레임 역직렬화, CRC-16 검증, 필드 추출을 수행한다. 슬롯 타임아웃 및 라인 stuck Low도 감지한다.

**파라미터**

| 파라미터 | 설명 |
|---------|------|
| `SLAVE_IDX` | 이 채널이 담당하는 슬레이브 번호 (0~7). addr 필드 검증에 사용 |

**포트**

| 포트 | 방향 | 폭 | 설명 |
|------|------|----|------|
| `clk` | input | 1 | 시스템 클럭 |
| `rst_n` | input | 1 | 리셋 |
| `clk_tick` | input | 1 | 틱 enable |
| `rx_line` | input | 1 | 슬레이브 SLAVE_IDX의 물리 RX 라인 |
| `slot_rx_en` | input | 1 | 이 슬롯의 RX 윈도우 활성 신호 (slot_rx_en[SLAVE_IDX]) |
| `rx_data[31:0]` | output | 32 | 수신된 payload → fault_fsm, regfile(NODE_DATA) |
| `rx_tick[31:0]` | output | 32 | 수신된 슬레이브 TX_TICK → fault_fsm(sync_monitor), regfile(NODE_TICK) |
| `rx_valid` | output | 1 | 이번 슬롯 수신 성공 (CRC OK, addr OK) |
| `preamble_err` | output | 1 | preamble 감지 실패 |
| `frame_err` | output | 1 | 프레임 구조 오류 (비트 수 불일치 등) |
| `crc_err` | output | 1 | CRC-16 불일치 |
| `addr_err` | output | 1 | addr 필드 ≠ SLAVE_IDX |
| `slot_timeout` | output | 1 | slot_rx_en 구간 내 아무것도 수신 안 됨 |
| `line_stuck` | output | 1 | RX 라인 stuck Low 감지 (1사이클 이상 지속) |

> **내부 서브모듈**
> - `phy_rx`: Manchester 디코딩. clk_tick 기준으로 비트 중간 전이를 샘플링하여 비트 스트림 출력.
> - `frame_dec`: 비트 카운팅, preamble/addr/payload/TX_TICK/CRC 필드 분리, CRC-16 CCITT 검증.

---

## 6. `fault_fsm`

**책임**: 슬레이브 n에 대한 7상태 fault 상태 머신을 운용한다. 내부 `sync_monitor`가 드리프트를 계산하고, 그 결과를 상태 전이 조건으로 사용한다. 상태에 따라 수신 데이터 수락 여부를 결정하고, 레지스터 파일에 상태 정보를 출력한다.

**파라미터**

| 파라미터 | 설명 |
|---------|------|
| `SLAVE_IDX` | 담당 슬레이브 번호 (로그용, 연결 확인용) |

**포트**

| 포트 | 방향 | 폭 | 설명 |
|------|------|----|------|
| `clk` | input | 1 | 시스템 클럭 |
| `rst_n` | input | 1 | 리셋 |
| `slot_rx_en` | input | 1 | 이 슬롯의 RX 윈도우 (타임아웃 판단 기준) |
| `slot_guard` | input | 1 | 이 슬롯의 guard time 구간 (드리프트 계산 타이밍) |
| `rx_valid` | input | 1 | slave_rx_ch 수신 성공 |
| `preamble_err` | input | 1 | |
| `frame_err` | input | 1 | |
| `crc_err` | input | 1 | |
| `addr_err` | input | 1 | |
| `slot_timeout` | input | 1 | |
| `line_stuck` | input | 1 | LINE_FAULT 감지 신호 |
| `rx_data[31:0]` | input | 32 | slave_rx_ch에서 수신한 payload |
| `rx_tick[31:0]` | input | 32 | slave_rx_ch에서 수신한 슬레이브 TX_TICK |
| `tx_tick[31:0]` | input | 32 | 해당 슬롯 시점의 마스터 TX_TICK (slot_timer) |
| `fault_th[3:0]` | input | 4 | FAULT_CFG.FAULT_TH |
| `recovery_th[3:0]` | input | 4 | FAULT_CFG.RECOVERY_TH |
| `sync_fault_th[3:0]` | input | 4 | FAULT_CFG.SYNC_FAULT_TH |
| `sync_recovery_th[3:0]` | input | 4 | FAULT_CFG.SYNC_RECOVERY_TH |
| `line_recovery_th[3:0]` | input | 4 | FAULT_CFG.LINE_RECOVERY_TH |
| `drift_th[31:0]` | input | 32 | DRIFT_TH |
| `offset_th[31:0]` | input | 32 | OFFSET_TH |
| `ps_clear` | input | 1 | CLOCK_FAULT 수동 클리어 (SOFT_RST 또는 명시적 클리어) |
| `state[2:0]` | output | 3 | 현재 상태 → NODE_STATUS.STATE |
| `fault_cnt[3:0]` | output | 4 | → NODE_STATUS.FAULT_CNT |
| `sync_fault_cnt[3:0]` | output | 4 | → NODE_STATUS.SYNC_FAULT_CNT |
| `recov_cnt[3:0]` | output | 4 | → NODE_STATUS.RECOV_CNT |
| `data_valid` | output | 1 | 새 payload 수락됨 → NODE_STATUS.DATA_VALID (W1C 세트) |
| `data_out[31:0]` | output | 32 | 수락된 payload → NODE_DATA 레지스터 |
| `tick_out[31:0]` | output | 32 | 수락된 rx_tick → NODE_TICK 레지스터 |
| `preamble_err_flag` | output | 1 | → NODE_STATUS.PREAMBLE_ERR (W1C 세트) |
| `frame_err_flag` | output | 1 | → NODE_STATUS.FRAME_ERR |
| `crc_err_flag` | output | 1 | → NODE_STATUS.CRC_ERR |
| `addr_err_flag` | output | 1 | → NODE_STATUS.ADDR_ERR |
| `slot_timeout_flag` | output | 1 | → NODE_STATUS.SLOT_TIMEOUT |
| `sync_fault_flag` | output | 1 | → NODE_STATUS.SYNC_FAULT_FLAG |
| `clock_fault_flag` | output | 1 | → NODE_STATUS.CLOCK_FAULT_FLAG |
| `line_fault_flag` | output | 1 | → NODE_STATUS.LINE_FAULT_FLAG |
| `in_fault` | output | 1 | 임의 fault 상태 진입 → GLOBAL_STATUS.FAULT_MASK, irq_ctrl |

> **내부 서브모듈: `sync_monitor`**
>
> 책임: `D[n][k] = rx_tick - tx_tick`, `drift[n][k] = D[n][k] - D[n][k-1]` 계산. `|drift| > DRIFT_TH` → SYNC_FAULT 조건 출력. `|D[k]| > OFFSET_TH` → CLOCK_FAULT 조건 출력. guard time 진입 시 계산 수행.

---

## 7. `regfile`

**책임**: AXI-Lite 인터페이스를 통해 PS의 읽기/쓰기 요청을 처리한다. RW 레지스터 값을 하드웨어에 출력하고, 하드웨어로부터 상태 값을 수집하여 RO/W1C 레지스터로 노출한다.

**AXI-Lite 포트**: `tdma_master_top` 포트와 동일 (내부 연결).

**하드웨어 출력 (→ 각 서브모듈)**

| 포트 | 폭 | 목적지 | 설명 |
|------|----|--------|------|
| `enable` | 1 | slot_timer, master_tx | CTRL.ENABLE |
| `soft_rst` | 1 | 전체 | CTRL.SOFT_RST (1클럭 펄스) |
| `div[9:0]` | 10 | clk_div, slot_timer | LINK_CFG.DIV |
| `guard_ticks[9:0]` | 10 | slot_timer | LINK_CFG.GUARD_TICKS |
| `retry_cnt[2:0]` | 3 | slot_timer, master_tx | LINK_CFG.RETRY_CNT |
| `node_cnt[2:0]` | 3 | slot_timer | NODE_CFG.NODE_CNT |
| `fault_th[3:0]` | 4 | fault_fsm[n] | FAULT_CFG.FAULT_TH |
| `recovery_th[3:0]` | 4 | fault_fsm[n] | FAULT_CFG.RECOVERY_TH |
| `sync_fault_th[3:0]` | 4 | fault_fsm[n] | FAULT_CFG.SYNC_FAULT_TH |
| `sync_recovery_th[3:0]` | 4 | fault_fsm[n] | FAULT_CFG.SYNC_RECOVERY_TH |
| `line_recovery_th[3:0]` | 4 | fault_fsm[n] | FAULT_CFG.LINE_RECOVERY_TH |
| `drift_th[31:0]` | 32 | fault_fsm[n] | DRIFT_TH |
| `offset_th[31:0]` | 32 | fault_fsm[n] | OFFSET_TH |

**하드웨어 입력 (← 각 서브모듈)**

| 포트 | 폭 | 출처 | 설명 |
|------|----|------|------|
| `slot_ticks[31:0]` | 32 | slot_timer | SLOT_TICKS (RO) |
| `guard_min[31:0]` | 32 | slot_timer | GUARD_MIN (RO) |
| `tx_tick[31:0]` | 32 | slot_timer | TX_TICK (RO) |
| `cycle_done` | 1 | slot_timer | CYCLE_CNT 증가 트리거 |
| `node_data[7:0][31:0]` | 32×8 | fault_fsm[n].data_out | NODE_DATA[n] (RO) |
| `node_tick[7:0][31:0]` | 32×8 | fault_fsm[n].tick_out | NODE_TICK[n] (RO) |
| `state[7:0][2:0]` | 3×8 | fault_fsm[n] | NODE_STATUS[n].STATE |
| `fault_cnt[7:0][3:0]` | 4×8 | fault_fsm[n] | NODE_STATUS[n].FAULT_CNT |
| `sync_fault_cnt[7:0][3:0]` | 4×8 | fault_fsm[n] | NODE_STATUS[n].SYNC_FAULT_CNT |
| `recov_cnt[7:0][3:0]` | 4×8 | fault_fsm[n] | NODE_STATUS[n].RECOV_CNT |
| `w1c_flags[7:0][8:0]` | 9×8 | fault_fsm[n] | NODE_STATUS[n] W1C 플래그 9종 |
| `in_fault[7:0]` | 8 | fault_fsm[n] | GLOBAL_STATUS.FAULT_MASK |
| `irq_status[6:0]` | 7 | irq_ctrl | IRQ_STATUS (W1C) |
| `irq_mask[6:0]` | 7 | regfile 내부 | IRQ_MASK (RW) → irq_ctrl |

---

## 8. `irq_ctrl`

**책임**: 각 fault_fsm 및 slot_timer로부터 이벤트 펄스를 수집하여 IRQ_STATUS를 세트한다. IRQ_MASK와 AND하여 IRQ 핀을 구동한다. W1C 클리어는 regfile이 처리한 결과를 받아 반영한다.

| 포트 | 방향 | 폭 | 설명 |
|------|------|----|------|
| `clk` | input | 1 | 시스템 클럭 |
| `rst_n` | input | 1 | 리셋 |
| `ev_cycle_done` | input | 1 | slot_timer.cycle_done |
| `ev_node_fault[7:0]` | input | 8 | fault_fsm[n].in_fault (fault 상태 진입) |
| `ev_node_recovery[7:0]` | input | 8 | fault_fsm[n] NORMAL 복구 이벤트 |
| `ev_data_error[7:0]` | input | 8 | fault_fsm[n] 데이터 오류 발생 |
| `ev_sync_fault[7:0]` | input | 8 | fault_fsm[n] SYNC_FAULT 진입 |
| `ev_clock_fault[7:0]` | input | 8 | fault_fsm[n] CLOCK_FAULT 진입 |
| `ev_line_fault[7:0]` | input | 8 | fault_fsm[n] LINE_FAULT 진입 |
| `irq_status[6:0]` | output | 7 | 집계된 IRQ_STATUS → regfile |
| `irq_clear[6:0]` | input | 7 | regfile W1C 클리어 신호 |
| `irq_mask[6:0]` | input | 7 | IRQ_MASK → regfile에서 공급 |
| `irq` | output | 1 | IRQ 핀. `\|(irq_status & irq_mask)` |
