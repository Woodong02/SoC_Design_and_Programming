# TDMA Master IP — Verilog 포트 및 모듈 계층 정의

> 버전: 0.4
> 작성일: 2026-05-21
> v0.4: TX_TICK 제거, CLOCK_FAULT 제거, 모듈 구성 단순화

---

## 1. 모듈 계층 구조

```
tdma_master_top
├── regfile          : AXI-Lite 레지스터 파일 (읽기/쓰기 인터페이스)
├── clk_div          : clk_tick 생성 (Manchester TX/RX 타이밍 기준)
├── slot_timer       : 사이클/슬롯 카운터, BUS_ACTIVE 관리 (clk 사이클 기준)
├── master_tx        : 마스터 브로드캐스트 프레임 생성 및 Manchester 송신
├── shared_rx        : 공유 RX 버스 Manchester 수신, 프레임 파싱
├── fault_fsm[0~7]   : 슬레이브별 fault 상태 머신 (×8 인스턴스)
└── irq_ctrl         : IRQ_STATUS 취합 및 IRQ 핀 구동
```

> **계수 단위 원칙**: slot_timer는 raw clk 사이클 기준으로 카운팅한다. clk_div·clk_tick은 Manchester TX/RX 비트 타이밍 전용이다. GUARD_TICKS도 clk 사이클 단위이므로 slot_timer에 clk_tick 신호는 불필요하다.

---

## 2. 최상위 모듈: `tdma_master_top`

```verilog
module tdma_master_top (
    // ── 클럭 / 리셋 ──────────────────────────────────────
    input  wire        clk,           // 시스템 클럭 (예: 25 MHz)
    input  wire        rst_n,         // 비동기 액티브-로우 리셋

    // ── AXI-Lite 슬레이브 포트 (레지스터 접근) ───────────
    input  wire [6:0]  s_axil_awaddr, // 쓰기 주소 (7비트: 0x00~0x68)
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,

    input  wire [31:0] s_axil_wdata,  // 쓰기 데이터
    input  wire [3:0]  s_axil_wstrb,  // 바이트 스트로브
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,

    output wire [1:0]  s_axil_bresp,  // 쓰기 응답 (OKAY=2'b00)
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,

    input  wire [6:0]  s_axil_araddr, // 읽기 주소
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,

    output wire [31:0] s_axil_rdata,  // 읽기 데이터
    output wire [1:0]  s_axil_rresp,  // 읽기 응답 (OKAY=2'b00)
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready,

    // ── TDMA 물리 인터페이스 ──────────────────────────────
    output wire        tx_line,       // 마스터 브로드캐스트 TX 라인 (→ 전체 슬레이브)
    input  wire        rx_line,       // 공유 RX 버스 (← 슬레이브들)

    // ── 인터럽트 ─────────────────────────────────────────
    output wire        irq            // IRQ 핀 (레벨, 액티브-하이)
);
```

---

## 3. 서브모듈 포트 정의

### 3.1 `clk_div` — 클럭 분주기

```verilog
module clk_div (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  div,          // LINK_CFG.DIV
    output wire        clk_tick      // Manchester 반주기 tick (1클럭 폭 펄스, 주기 = DIV+1 clk)
);
```

> clk_tick은 DIV+1 clk 사이클마다 1클럭 폭 펄스를 생성한다. master_tx·shared_rx의 Manchester 비트 타이밍에만 사용된다. slot_timer는 clk_tick을 사용하지 않는다.

---

### 3.2 `slot_timer` — 사이클/슬롯 타이머 (clk 사이클 기준)

```verilog
module slot_timer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,        // CTRL.ENABLE
    input  wire [9:0]  div,           // LINK_CFG.DIV (frame_ticks = 50×2×(DIV+1) 계산용)
    input  wire [9:0]  guard_ticks,   // LINK_CFG.GUARD_TICKS (clk 사이클 단위)
    input  wire [2:0]  node_cnt,      // NODE_CFG.NODE_CNT

    output wire [31:0] slot_ticks,    // frame_ticks + GUARD_TICKS → SLOT_TICKS_RO
    output wire [31:0] guard_min,     // GUARD_MIN 계산값 → GUARD_MIN_RO
    output wire [2:0]  current_slot,  // 현재 진행 중인 슬롯 번호 (0~node_cnt)
    output wire        cycle_start,   // 새 사이클 시작 펄스 (1클럭 폭): master_tx 트리거
    output wire        slot_start,    // 슬롯 시작 펄스 (1클럭 폭): shared_rx 윈도우 오픈
    output wire        cycle_done,    // TDMA 사이클 완료 펄스 → IRQ
    output wire [31:0] cycle_cnt,     // 완료된 사이클 수 → CYCLE_CNT
    output wire        bus_active     // TDMA 버스 동작 중 → GLOBAL_STATUS.BUS_ACTIVE
);
```

> `slot_ticks = 50 × 2 × (DIV+1) + GUARD_TICKS`
> `cycle_start`는 새 사이클이 시작되는 시점의 1클럭 폭 펄스. slot 0의 `slot_start`와 동시에 발생한다.
> `guard_min`은 Verilog 파라미터(RX_PROCESS_CYCLES, CABLE_DELAY_TICKS, BUS_TURNAROUND, MAX_PPM 등)와 frame_ticks로 계산한 정적+동적 혼합 값이다. 상세 산출식은 `03_sync_decisions(4).md` §2.3 참조.

---

### 3.3 `master_tx` — 마스터 브로드캐스트 송신기

```verilog
module master_tx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,        // CTRL.ENABLE
    input  wire        clk_tick,      // clk_div 출력 (Manchester 비트 타이밍)
    input  wire        cycle_start,   // slot_timer 출력: 사이클 시작 → TX 트리거
    input  wire [7:0]  halt_cmd,      // HALT_CMD 레지스터 현재값

    output wire        tx_line,       // Manchester 인코딩 TX 출력 (tristate)
    output wire        tx_active      // TX 진행 중 플래그
);
```

> 프레임 구조: `[preamble 8b][HALT_CMD 8b][reserved 27b][Hamming 7b]` = 50비트
> 전송 구간 외 tx_line은 High-Z. FPGA 구현: `assign tx_line = tx_active ? tx_bit : 1'bz;`

---

### 3.4 `shared_rx` — 공유 RX 버스 수신기

```verilog
module shared_rx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,        // CTRL.ENABLE
    input  wire        clk_tick,      // clk_div 출력 (Manchester 비트 타이밍)
    input  wire        rx_line,       // 공유 RX 버스 입력 (2-FF 동기화 후)
    input  wire        slot_start,    // slot_timer 출력: RX 윈도우 오픈
    input  wire [2:0]  current_slot,  // 수신 기대 슬롯 번호

    // 수신 결과 (슬롯 완료 후 1클럭 유효)
    output wire        rx_valid,      // 유효 프레임 수신 완료 (preamble OK, Hamming 0/1비트 오류)
    output wire        preamble_ok,   // preamble(0x55) 수신 성공 (Hamming 결과 무관). LINE_CNT -1 트리거
    output wire [2:0]  rx_addr,       // 수신 프레임 addr 필드
    output wire [31:0] rx_data,       // 수신 payload (Hamming 1비트 정정 후)

    // 오류 플래그 (슬롯 완료 후 1클럭 유효)
    output wire        slot_timeout,  // 슬롯 내 응답 없음 → FAULT_CNT +10
    output wire        frame_err,     // Manchester 인코딩 위반 또는 비트수 불일치 → FAULT_CNT +10
    output wire        hamming_err,   // Hamming 2비트 오류 (정정 불가) → FAULT_CNT +10
    output wire        preamble_err,  // preamble 불일치 → LINE_CNT +10
    output wire        addr_err       // rx_addr ≠ current_slot → HALT_CMD 자동 세팅
);
```

> `rx_valid`: hamming_err=0이고 preamble_ok=1인 경우만 1. 1비트 Hamming 오류는 자동 정정 후 rx_valid=1.
> `preamble_ok`: Hamming 결과와 무관하게 preamble(0x55) 수신이 유효한 경우 1. LINE_CNT -1 트리거에 사용.

---

### 3.5 `fault_fsm` — 슬레이브별 fault 상태 머신 (×8 인스턴스)

```verilog
module fault_fsm #(
    parameter SLAVE_IDX = 0          // 슬레이브 인덱스 (0~7)
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,        // CTRL.ENABLE
    input  wire        active,        // 이 슬레이브가 NODE_CNT 범위 내 (active = SLAVE_IDX <= node_cnt)

    // 임계값 (FAULT_CFG)
    input  wire [7:0]  fault_th,      // FAULT_CFG.FAULT_TH
    input  wire [7:0]  line_fault_th, // FAULT_CFG.LINE_FAULT_TH

    // 이벤트 입력 (shared_rx에서)
    input  wire        rx_valid,      // 정상 수신: FAULT_CNT -1
    input  wire        preamble_ok,   // preamble 수신 성공: LINE_CNT -1
    input  wire        slot_timeout,  // SLOT_TIMEOUT: FAULT_CNT +10
    input  wire        frame_err,     // FRAME_ERR: FAULT_CNT +10
    input  wire        hamming_err,   // HAMMING_ERR: FAULT_CNT +10
    input  wire        preamble_err,  // PREAMBLE_ERR: LINE_CNT +10
    input  wire        addr_err,      // ADDR_ERR: HALT_CMD 자동 세팅

    // 상태 출력
    output wire [2:0]  state,         // FSM 상태 → NODE_STATUS[n].STATE
    output wire [7:0]  fault_cnt,     // FAULT_CNT 현재값 → NODE_STATUS[n].FAULT_CNT
    output wire [7:0]  line_cnt,      // LINE_CNT 현재값 → NODE_STATUS[n].LINE_CNT

    // 이벤트 플래그 출력 (W1C 레지스터로 전달)
    output wire        data_valid,    // 유효 데이터 수신 완료 → NODE_STATUS[n].DATA_VALID
    output wire        slot_timeout_flag,
    output wire        frame_err_flag,
    output wire        hamming_err_flag,
    output wire        preamble_err_flag,
    output wire        addr_err_flag,

    // HALT_CMD 자동 세팅 요청
    output wire        halt_cmd_req   // 1클럭 폭 펄스 → regfile: HALT_CMD[SLAVE_IDX] = 1
);
```

> STATE 인코딩: INACTIVE=000, NORMAL=001, DATA_RECOVERY=010, DATA_FAULT=011, LINE_FAULT=100
> FAULT_CNT -1 트리거: `rx_valid` (정상 프레임 완수)
> LINE_CNT -1 트리거: `preamble_ok` (preamble 유효 수신. rx_valid가 0이어도 감소 가능)
> 상세 규칙: `04_fault_decisions(4).md` §2·§4 참조

---

### 3.6 `regfile` — 레지스터 파일

```verilog
module regfile (
    input  wire        clk,
    input  wire        rst_n,

    // AXI-Lite 인터페이스 (tdma_master_top 포트에서 연결, 생략)

    // 제어 출력 (→ 각 서브모듈)
    output wire        enable,
    output wire        soft_rst,
    output wire [9:0]  div,
    output wire [9:0]  guard_ticks,
    output wire [2:0]  node_cnt,
    output wire [7:0]  fault_th,
    output wire [7:0]  line_fault_th,
    output wire [7:0]  halt_cmd_out,  // HALT_CMD 레지스터 현재값 → master_tx

    // 상태 입력 (← 각 서브모듈)
    input  wire [31:0] slot_ticks_in,
    input  wire [31:0] guard_min_in,
    input  wire [7:0]  fault_mask_in, // GLOBAL_STATUS.FAULT_MASK
    input  wire        bus_active_in,
    input  wire [31:0] cycle_cnt_in,
    input  wire [31:0] node_data_in  [0:7], // NODE_DATA[0~7]
    input  wire [31:0] node_status_in[0:7], // NODE_STATUS[0~7] 원시값

    // HALT_CMD 자동 세팅 (← fault_fsm[n].halt_cmd_req)
    input  wire [7:0]  halt_cmd_set,  // 비트 n=1: HALT_CMD[n] 세팅 요청

    // IRQ 인터페이스 (→ irq_ctrl)
    output wire [5:0]  irq_mask_out,
    input  wire [5:0]  irq_status_in
);
```

---

### 3.7 `irq_ctrl` — 인터럽트 컨트롤러

```verilog
module irq_ctrl (
    input  wire        clk,
    input  wire        rst_n,

    // 이벤트 입력
    input  wire        cycle_done,        // slot_timer
    input  wire        any_node_fault,    // OR(fault_fsm[n] → DATA_FAULT/LINE_FAULT 진입)
    input  wire        any_node_recovery, // OR(fault_fsm[n]: DATA_RECOVERY → NORMAL 전이)
    input  wire        any_data_error,    // OR(slot_timeout/frame_err/hamming_err 발생)
    input  wire        any_line_fault,    // OR(fault_fsm[n] → LINE_FAULT 진입)
    input  wire        any_addr_err,      // OR(fault_fsm[n].addr_err_flag)

    // IRQ_MASK (regfile에서)
    input  wire [5:0]  irq_mask,

    // IRQ_STATUS 출력 (→ regfile W1C 처리)
    output wire [5:0]  irq_status,

    // IRQ 핀
    output wire        irq              // OR(irq_status & irq_mask)
);
```

---

## 4. 인터페이스 연결 다이어그램

```
                ┌─────────────────────────────────────┐
 AXI-Lite ─────►│             regfile                 │◄── halt_cmd_set[7:0]
                │  enable/div/guard_ticks/             │    (fault_fsm[n].halt_cmd_req)
                │  node_cnt/fault_th/halt_cmd_out      │
                └───┬─────────────────────────────────┘
                    │ enable, div
                ┌───▼──────┐
                │ clk_div  │──── clk_tick ────────────┬──────────────┐
                └──────────┘                          │              │
                                                      ▼              ▼
              div, guard_ticks, node_cnt         master_tx      shared_rx
                ┌───▼──────────────┐                  ▲              │
                │   slot_timer     │──cycle_start─────┘              │
                │   (clk cycle 기준)│──slot_start──────────────────►  │
                │                  │──current_slot──────────────────► │
                │                  │──cycle_done──► irq_ctrl         │
                │                  │──slot_ticks──► regfile          │
                │                  │──guard_min───► regfile          │
                └──────────────────┘                                  │
                                                                      │
                              rx_valid, preamble_ok, rx_addr,         │
                              rx_data, slot_timeout, frame_err,       │
                              hamming_err, preamble_err, addr_err     │
                                                                      ▼
                                             fault_fsm[0] ~ fault_fsm[7] (×8)
                                                      │
                                    state/fault_cnt/line_cnt/flags ──► regfile
                                    halt_cmd_req ──────────────────► regfile
                                    state change ──────────────────► irq_ctrl
                                                      │
                                                   irq_ctrl ──► irq
```

---

## 5. 파라미터 목록

| 파라미터 | 기본값 | 설명 |
|----------|--------|------|
| `CLK_FREQ_MHZ` | 25 | 시스템 클럭 주파수 (MHz) |
| `CABLE_LENGTH_CM` | 50 | 케이블 길이 (cm). GUARD_MIN 자동 계산에 사용 |
| `RX_PROCESS_CYCLES` | 8 | Manchester 디코딩 + Hamming 파이프라인 지연 (clk 사이클) |
| `BUS_TURNAROUND` | 4 | 공유 버스 Hi-Z 전환 여유 (clk 사이클) |
| `MAX_PPM` | 50 | 크리스탈 최대 편차 (단측 ppm) |
| `NODE_CNT_MAX` | 8 | 지원 최대 슬레이브 수 (고정) |

---

## 6. 설계 주의사항

1. **tristate 구동**: tx_line은 전송 구간 외 High-Z. FPGA: `assign tx_line = tx_active ? tx_bit : 1'bz;`
2. **rx_line 동기화**: 비동기 입력. 2-FF 동기화 체인 후 shared_rx에 연결.
3. **fault_fsm 인스턴스화**: `generate` 블록으로 `SLAVE_IDX=0~7` 파라미터를 각각 지정하여 8개 인스턴스 생성.
4. **SOFT_RST**: HALT_CMD 포함 모든 내부 상태를 동기 클리어. CTRL.ENABLE 비트는 클리어하지 않음.
5. **AXI-Lite 주소 폭**: 0x00~0x68 범위이므로 7비트 주소 버스 충분.
6. **clk_tick과 slot_timer 분리**: slot_timer는 clk 기준으로 카운팅하여 clk_tick과 독립적. DIV 변경 시 slot_ticks가 자동 재계산됨.
