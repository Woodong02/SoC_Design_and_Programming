# TDMA Slave IP — 모듈 포트 정의

> 버전: 0.1 · 작성일: 2026-05-18
>
> **표기 규칙**
> - `clk_tick`은 실제 클럭이 아닌 enable 펄스 (매 DIV+1 clk 사이클마다 1클럭 폭으로 High)
> - 모든 리셋은 active-low 동기 리셋 (`rst_n`)
> - 비트 범위 표기: `[MSB:LSB]`

---

## 모듈 계층

```
tdma_slave_top
├── clk_div
├── master_rx
├── slot_timer
├── slave_tx
├── fault_fsm
│   └── sync_ctrl
├── regfile
└── irq_ctrl
```

---

## 1. `tdma_slave_top`

최상위 모듈. 외부 핀과 직접 연결된다.

| 포트 | 방향 | 폭 | 설명 |
|------|------|----|------|
| `clk` | input | 1 | 시스템 클럭 (25 MHz) |
| `rst_n` | input | 1 | 시스템 리셋 (active-low) |
| `rx_line` | input | 1 | 마스터 브로드캐스트 수신 라인 (TX 케이블) |
| `tx_line` | output | 1 | 슬레이브 전송 라인 (RX 케이블, 마스터로) |
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
마스터의 `clk_div`와 동일한 모듈을 재사용한다.

| 포트 | 방향 | 폭 | 설명 |
|------|------|----|------|
| `clk` | input | 1 | 시스템 클럭 |
| `rst_n` | input | 1 | 리셋 |
| `div[9:0]` | input | 10 | 분주비. 출력 주기 = (DIV+1) 클럭 |
| `clk_tick` | output | 1 | 틱 enable 펄스 |

---

## 3. `master_rx`

**책임**: 마스터 브로드캐스트 라인을 수신한다. 사이클 시작 기준이 되는 첫 번째 falling edge를 감지하고, Manchester 디코딩 후 브로드캐스트 프레임(`[preamble 8b][TX_TICK 32b][CRC-16 16b]`)을 파싱하여 CRC를 검증한다. 라인 stuck Low를 감지한다.

| 포트 | 방향 | 폭 | 설명 |
|------|------|----|------|
| `clk` | input | 1 | 시스템 클럭 |
| `rst_n` | input | 1 | 리셋 |
| `clk_tick` | input | 1 | 틱 enable |
| `rx_line` | input | 1 | 마스터 브로드캐스트 물리 라인 |
| `falling_edge_det` | output | 1 | 브로드캐스트 첫 번째 falling edge 감지 펄스 → slot_timer |
| `rx_tick[31:0]` | output | 32 | 수신된 마스터 TX_TICK → fault_fsm(sync_ctrl), regfile(RX_TICK) |
| `rx_tick_valid` | output | 1 | CRC 검증 통과, rx_tick 유효 |
| `sync_miss` | output | 1 | 예상 사이클 주기 내 falling edge 미감지 → fault_fsm |
| `broadcast_crc_err` | output | 1 | 브로드캐스트 CRC-16 불일치 → fault_fsm |
| `line_stuck` | output | 1 | RX 라인 stuck Low 감지 → fault_fsm |

---

## 4. `slot_timer`

**책임**: `master_rx`의 falling edge를 기준으로 로컬 카운터를 시작한다. `SLAVE_ADDR × slot_ticks` 후 자기 슬롯 시작 신호를 출력한다. `slot_ticks`를 자동 계산한다 (마스터와 동일한 공식).

| 포트 | 방향 | 폭 | 설명 |
|------|------|----|------|
| `clk` | input | 1 | 시스템 클럭 |
| `rst_n` | input | 1 | 리셋 |
| `clk_tick` | input | 1 | 틱 enable |
| `enable` | input | 1 | CTRL.ENABLE |
| `falling_edge_det` | input | 1 | master_rx의 사이클 시작 기준 신호 |
| `slave_addr[2:0]` | input | 3 | SLAVE_CFG.SLAVE_ADDR (슬롯 오프셋 계산) |
| `div[9:0]` | input | 10 | LINK_CFG.DIV |
| `retry_cnt[2:0]` | input | 3 | LINK_CFG.RETRY_CNT |
| `guard_ticks[9:0]` | input | 10 | LINK_CFG.GUARD_TICKS |
| `slot_ticks[31:0]` | output | 32 | 자동 계산된 슬롯 길이 (정보용, regfile 미노출) |
| `slot_start` | output | 1 | 자기 슬롯 시작 펄스 → slave_tx |
| `guard_start` | output | 1 | 자기 슬롯 guard time 시작 펄스 → fault_fsm(sync_ctrl) |

---

## 5. `slave_tx`

**책임**: `slot_start` 시점에 슬레이브 프레임을 직렬화하여 TX 라인에 출력한다. 프레임 구조: `[preamble 8b][addr 3b][payload 32b][TX_TICK 32b][CRC-16 16b]`. `RETRY_CNT`에 따라 IFG 2비트를 두고 재전송한다. TX_TICK은 첫 전송 값을 재전송 시에도 유지한다. `tx_enable`이 Low이면 전송하지 않는다.

| 포트 | 방향 | 폭 | 설명 |
|------|------|----|------|
| `clk` | input | 1 | 시스템 클럭 |
| `rst_n` | input | 1 | 리셋 |
| `clk_tick` | input | 1 | 틱 enable |
| `slot_start` | input | 1 | 슬롯 시작 펄스 (slot_timer) |
| `tx_enable` | input | 1 | 전송 허가. fault_fsm이 FAULT/DEAD/PAUSE 상태면 Low |
| `tx_data[31:0]` | input | 32 | 송신 payload (regfile.TX_DATA) |
| `tx_tick[31:0]` | input | 32 | 송신 타임스탬프 (fault_fsm.tx_tick_out) |
| `slave_addr[2:0]` | input | 3 | 프레임 addr 필드 삽입용 |
| `retry_cnt[2:0]` | input | 3 | 재전송 횟수 |
| `tx_line` | output | 1 | Manchester 인코딩된 직렬 출력 |
| `tx_done` | output | 1 | 슬롯 내 전송 완료 펄스 → fault_fsm(DATA_SENT 세트) |

---

## 6. `fault_fsm`

**책임**: 슬레이브의 5상태 fault 상태 머신을 운용한다. 내부 `sync_ctrl`이 드리프트를 계산하고 `TICK_OFFSET`을 갱신한다. 상태에 따라 `tx_enable`을 제어하고, 레지스터 파일에 상태 정보를 출력한다.

| 포트 | 방향 | 폭 | 설명 |
|------|------|----|------|
| `clk` | input | 1 | 시스템 클럭 |
| `rst_n` | input | 1 | 리셋 |
| `guard_start` | input | 1 | guard time 시작 펄스 (TICK_OFFSET 보정 타이밍) |
| `rx_tick[31:0]` | input | 32 | master_rx에서 수신한 마스터 TX_TICK |
| `rx_tick_valid` | input | 1 | rx_tick 유효 신호 |
| `tx_done` | input | 1 | slave_tx 전송 완료 (DATA_SENT 세트용) |
| `sync_miss` | input | 1 | master_rx 브로드캐스트 미수신 |
| `broadcast_crc_err` | input | 1 | master_rx 브로드캐스트 CRC 오류 |
| `line_stuck` | input | 1 | master_rx 라인 stuck Low |
| `fault_th[3:0]` | input | 4 | FAULT_CFG.FAULT_TH |
| `recovery_th[3:0]` | input | 4 | FAULT_CFG.RECOVERY_TH |
| `line_recovery_th[3:0]` | input | 4 | FAULT_CFG.LINE_RECOVERY_TH |
| `drift_th[31:0]` | input | 32 | DRIFT_TH |
| `state[2:0]` | output | 3 | 현재 상태 → STATUS.STATE |
| `fault_cnt[3:0]` | output | 4 | → STATUS.FAULT_CNT |
| `recov_cnt[3:0]` | output | 4 | → STATUS.RECOV_CNT |
| `tx_enable` | output | 1 | 전송 허가 → slave_tx |
| `tx_tick_out[31:0]` | output | 32 | `raw_counter + TICK_OFFSET` → slave_tx, regfile(TX_TICK) |
| `tick_offset_out[31:0]` | output | 32 | 현재 TICK_OFFSET → regfile(TICK_OFFSET 읽기) |
| `tick_offset_in[31:0]` | input | 32 | PS가 TICK_OFFSET에 쓰는 값 (regfile) |
| `tick_offset_we` | input | 1 | PS TICK_OFFSET 쓰기 enable |
| `data_sent_flag` | output | 1 | → STATUS.DATA_SENT (W1C 세트) |
| `sync_miss_flag` | output | 1 | → STATUS.SYNC_MISS (W1C 세트) |
| `broadcast_crc_err_flag` | output | 1 | → STATUS.BROADCAST_CRC_ERR (W1C 세트) |
| `sync_fault_flag` | output | 1 | → STATUS.SYNC_FAULT_FLAG (W1C 세트) |
| `line_fault_flag` | output | 1 | → STATUS.LINE_FAULT_FLAG (W1C 세트) |
| `ev_fault_entry` | output | 1 | FAULT 또는 DEAD 진입 이벤트 → irq_ctrl |
| `ev_recovery_done` | output | 1 | NORMAL 복구 이벤트 → irq_ctrl |
| `ev_sync_fault` | output | 1 | SYNC_FAULT 감지 이벤트 → irq_ctrl |
| `ev_line_fault` | output | 1 | LINE_FAULT 감지 이벤트 → irq_ctrl |

> **내부 서브모듈: `sync_ctrl`**
>
> 책임:
> - 슬레이브 `raw_counter` (자유 진행) 관리
> - `D[k] = rx_tick - tx_tick_own`, `drift[k] = D[k] - D[k-1]` 계산
> - guard time(`guard_start`) 진입 시 `TICK_OFFSET -= drift[k]` 자동 적용
> - `|drift[k]| > DRIFT_TH` → SYNC_FAULT 조건을 fault_fsm 상태 머신에 전달
> - `tx_tick_out = raw_counter + TICK_OFFSET` 출력

---

## 7. `regfile`

**책임**: AXI-Lite 인터페이스를 통해 PS의 읽기/쓰기 요청을 처리한다. RW 레지스터 값을 하드웨어에 출력하고, 하드웨어로부터 상태 값을 수집하여 RO/W1C 레지스터로 노출한다.

**AXI-Lite 포트**: `tdma_slave_top` 포트와 동일 (내부 연결).

**하드웨어 출력 (→ 각 서브모듈)**

| 포트 | 폭 | 목적지 | 설명 |
|------|----|--------|------|
| `enable` | 1 | slot_timer | CTRL.ENABLE |
| `soft_rst` | 1 | 전체 | CTRL.SOFT_RST (1클럭 펄스) |
| `div[9:0]` | 10 | clk_div, slot_timer | LINK_CFG.DIV |
| `guard_ticks[9:0]` | 10 | slot_timer | LINK_CFG.GUARD_TICKS |
| `retry_cnt[2:0]` | 3 | slot_timer, slave_tx | LINK_CFG.RETRY_CNT |
| `slave_addr[2:0]` | 3 | slot_timer, slave_tx | SLAVE_CFG.SLAVE_ADDR |
| `fault_th[3:0]` | 4 | fault_fsm | FAULT_CFG.FAULT_TH |
| `recovery_th[3:0]` | 4 | fault_fsm | FAULT_CFG.RECOVERY_TH |
| `line_recovery_th[3:0]` | 4 | fault_fsm | FAULT_CFG.LINE_RECOVERY_TH |
| `drift_th[31:0]` | 32 | fault_fsm | DRIFT_TH |
| `tx_data[31:0]` | 32 | slave_tx | TX_DATA |
| `tick_offset_in[31:0]` | 32 | fault_fsm | TICK_OFFSET PS 쓰기 값 |
| `tick_offset_we` | 1 | fault_fsm | TICK_OFFSET PS 쓰기 enable |

**하드웨어 입력 (← 각 서브모듈)**

| 포트 | 폭 | 출처 | 설명 |
|------|----|------|------|
| `tx_tick[31:0]` | 32 | fault_fsm.tx_tick_out | TX_TICK (RO) |
| `rx_tick[31:0]` | 32 | master_rx.rx_tick | RX_TICK (RO) |
| `tick_offset[31:0]` | 32 | fault_fsm.tick_offset_out | TICK_OFFSET (RW, HW 갱신) |
| `state[2:0]` | 3 | fault_fsm | STATUS.STATE |
| `fault_cnt[3:0]` | 4 | fault_fsm | STATUS.FAULT_CNT |
| `recov_cnt[3:0]` | 4 | fault_fsm | STATUS.RECOV_CNT |
| `w1c_flags[4:0]` | 5 | fault_fsm | STATUS W1C 플래그 5종 |
| `irq_status[5:0]` | 6 | irq_ctrl | IRQ_STATUS (W1C) |
| `irq_mask[5:0]` | 6 | regfile 내부 | IRQ_MASK (RW) → irq_ctrl |

---

## 8. `irq_ctrl`

**책임**: `fault_fsm` 및 `master_rx`로부터 이벤트 펄스를 수집하여 IRQ_STATUS를 세트한다. IRQ_MASK와 AND하여 IRQ 핀을 구동한다.

| 포트 | 방향 | 폭 | 설명 |
|------|------|----|------|
| `clk` | input | 1 | 시스템 클럭 |
| `rst_n` | input | 1 | 리셋 |
| `ev_slot_done` | input | 1 | slave_tx.tx_done |
| `ev_sync_acquired` | input | 1 | master_rx 첫 falling edge 감지 (동기 획득) |
| `ev_fault_entry` | input | 1 | fault_fsm.ev_fault_entry |
| `ev_recovery_done` | input | 1 | fault_fsm.ev_recovery_done |
| `ev_sync_fault` | input | 1 | fault_fsm.ev_sync_fault |
| `ev_line_fault` | input | 1 | fault_fsm.ev_line_fault |
| `irq_status[5:0]` | output | 6 | 집계된 IRQ_STATUS → regfile |
| `irq_clear[5:0]` | input | 6 | regfile W1C 클리어 신호 |
| `irq_mask[5:0]` | input | 6 | IRQ_MASK → regfile에서 공급 |
| `irq` | output | 1 | IRQ 핀. `\|(irq_status & irq_mask)` |
