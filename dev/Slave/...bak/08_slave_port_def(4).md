# TDMA Slave IP — Verilog 포트 및 모듈 계층 정의

> 버전: 0.4
> 작성일: 2026-05-21
> v0.4: TX_TICK 제거, SYNC_FAULT/CLOCK_FAULT 제거, 모듈 구성 단순화

---

## 1. 모듈 계층 구조

```
tdma_slave_top
├── regfile      : AXI-Lite 레지스터 파일
├── clk_div      : clk_tick 생성 (Manchester TX/RX 타이밍 기준)
├── master_rx    : 마스터 브로드캐스트 Manchester 수신 및 파싱
├── slot_timer   : 슬롯 카운터 + watchdog (NO_BROADCAST 감지, clk 사이클 기준)
├── slave_tx     : 슬레이브 payload Manchester 송신
├── fault_fsm    : 슬레이브 fault 상태 머신
└── irq_ctrl     : IRQ_STATUS 취합 및 IRQ 핀 구동
```

> **계수 단위 원칙**: slot_timer는 raw clk 사이클 기준으로 카운팅한다. clk_div·clk_tick은 Manchester TX/RX 비트 타이밍 전용이다.

---

## 2. 최상위 모듈: `tdma_slave_top`

```verilog
module tdma_slave_top (
    // ── 클럭 / 리셋 ──────────────────────────────────────
    input  wire        clk,           // 시스템 클럭 (예: 25 MHz)
    input  wire        rst_n,         // 비동기 액티브-로우 리셋

    // ── AXI-Lite 슬레이브 포트 (레지스터 접근) ───────────
    input  wire [4:0]  s_axil_awaddr, // 쓰기 주소 (5비트: 0x00~0x1C)
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,

    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,

    output wire [1:0]  s_axil_bresp,  // OKAY=2'b00
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,

    input  wire [4:0]  s_axil_araddr, // 읽기 주소
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,

    output wire [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready,

    // ── TDMA 물리 인터페이스 ──────────────────────────────
    input  wire        tx_line,       // 마스터 브로드캐스트 수신 (← 마스터 TX)
    output wire        rx_line,       // 공유 RX 버스 구동 (→ 마스터 RX)

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
    input  wire [9:0]  div,           // LINK_CFG.DIV
    output wire        clk_tick       // Manchester 반주기 tick (1클럭 폭 펄스, 주기 = DIV+1 clk)
);
```

> 마스터의 clk_div와 동일한 모듈. clk_tick은 master_rx·slave_tx에서만 사용한다.

---

### 3.2 `master_rx` — 마스터 브로드캐스트 수신기

```verilog
module master_rx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,        // CTRL.ENABLE
    input  wire        clk_tick,      // clk_div 출력 (Manchester 비트 타이밍)
    input  wire        tx_line_sync,  // 마스터 TX 입력 (2-FF 동기화 후)

    // 액티브 에지 출력 (슬롯 타이머 트리거)
    output wire        active_edge,   // 마스터 브로드캐스트 첫 0→1 상승 에지 감지

    // 브로드캐스트 수신 결과 (프레임 완료 후 1클럭 유효)
    output wire        bc_valid,      // 유효 브로드캐스트 수신 (preamble OK, Hamming 0/1비트 오류)
    output wire        bc_preamble_ok,// preamble(0x55) 수신 성공 (Hamming 결과 무관). LINE_CNT -1 트리거
    output wire [7:0]  bc_halt_cmd,   // 수신된 HALT_CMD 필드

    // 오류 플래그 (프레임 완료 후 1클럭 유효)
    output wire        bc_hamming_err,// 브로드캐스트 Hamming 2비트 오류 → FAULT_CNT +10
    output wire        bc_preamble_err// preamble 불일치 (LINE_CNT +10, NO_BROADCAST 준용)
);
```

> `active_edge`: `(~prev_tx) & tx_line_sync` (0→1 상승 에지)
> `bc_valid`: bc_preamble_ok=1이고 bc_hamming_err=0인 경우만 1
> `bc_preamble_ok`: preamble(0x55) 수신 성공. bc_hamming_err와 무관하게 세팅 가능. LINE_CNT -1 트리거.
> 1비트 Hamming 오류는 자동 정정 후 bc_valid=1로 처리됨

---

### 3.3 `slot_timer` — 슬롯 타이머 + watchdog (clk 사이클 기준)

```verilog
module slot_timer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,        // CTRL.ENABLE
    input  wire        active_edge,   // master_rx 출력: 슬롯 카운터 리셋 기준점
    input  wire [9:0]  div,           // LINK_CFG.DIV (slot_ticks = 50×2×(DIV+1)+GUARD_TICKS)
    input  wire [9:0]  guard_ticks,   // LINK_CFG.GUARD_TICKS (clk 사이클 단위)
    input  wire [2:0]  slave_addr,    // SLAVE_CFG.SLAVE_ADDR

    // 타이밍 출력
    output wire        tx_trigger,    // TX 시작 펄스: active_edge 후 slave_addr × slot_ticks clk 경과
    output wire [31:0] slot_ticks,    // 계산된 slot_ticks (참고용 출력)

    // watchdog 출력
    output wire        no_broadcast   // CYCLE_TIMEOUT_TICKS(=9×slot_ticks) 초과: LINE_CNT +10 이벤트
);
```

> `slot_ticks = 50 × 2 × (DIV+1) + GUARD_TICKS` (clk 사이클 단위)
> `CYCLE_TIMEOUT_TICKS = 9 × slot_ticks` (NODE_CNT_MAX=8 + 1 슬롯 여유, 레지스터 불필요)
> watchdog_cnt는 active_edge에서 리셋. CYCLE_TIMEOUT_TICKS 초과 시 no_broadcast 펄스 출력 후 계속 대기.
> slave_addr=0이면 tx_trigger는 active_edge와 동시에 발생 (마스터 브로드캐스트와 TX/RX 분리 덕분에 충돌 없음)

---

### 3.4 `slave_tx` — 슬레이브 payload 송신기

```verilog
module slave_tx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        clk_tick,      // clk_div 출력 (Manchester 비트 타이밍)
    input  wire        tx_trigger,    // slot_timer 출력: TX 시작 신호
    input  wire        tx_enable,     // fault_fsm 출력: 1=TX 허용, 0=High-Z 유지
    input  wire [2:0]  slave_addr,    // SLAVE_CFG.SLAVE_ADDR (프레임 addr 필드)
    input  wire [31:0] tx_data,       // TX_DATA 레지스터 (tx_trigger 시 래치)

    output wire        rx_line,       // 공유 RX 버스 출력 (tristate)
    output wire        tx_active,     // TX 진행 중 플래그
    output wire        data_sent      // TX 완료 펄스 → STATUS.DATA_SENT, IRQ
);
```

> 프레임 구조: `[preamble 8b][addr 3b][payload 32b][Hamming 7b]` = 50비트
> tx_enable=0(FAULT/DEAD)이면 tx_trigger를 무시하고 rx_line을 High-Z로 유지
> FPGA 구현: `assign rx_line = (tx_active && tx_enable) ? tx_bit : 1'bz;`

---

### 3.5 `fault_fsm` — 슬레이브 fault 상태 머신

```verilog
module fault_fsm (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,        // CTRL.ENABLE

    // 임계값 (FAULT_CFG)
    input  wire [7:0]  fault_th,      // FAULT_CFG.FAULT_TH
    input  wire [7:0]  line_fault_th, // FAULT_CFG.LINE_FAULT_TH

    // 이벤트 입력
    input  wire        bc_valid,      // 정상 브로드캐스트 수신: FAULT_CNT -1
    input  wire        bc_preamble_ok,// preamble 수신 성공: LINE_CNT -1
    input  wire        bc_hamming_err,// 브로드캐스트 Hamming 2비트 오류: FAULT_CNT +10
    input  wire        bc_halt_cmd_self, // bc_halt_cmd[slave_addr]: 즉시 FAULT 진입
    input  wire        no_broadcast,  // watchdog 타임아웃: LINE_CNT +10
    input  wire        active_edge,   // 마스터 브로드캐스트 에지: IDLE→NORMAL 전이 트리거

    // 상태 출력
    output wire [2:0]  state,         // FSM 상태 → STATUS.STATE
    output wire [7:0]  fault_cnt,     // FAULT_CNT 현재값 → STATUS.FAULT_CNT
    output wire [7:0]  line_cnt,      // LINE_CNT 현재값 → STATUS.LINE_CNT
    output wire        tx_enable,     // 1: TX 허용 (NORMAL/DATA_RECOVERY), 0: TX 금지 (FAULT/DEAD)

    // 이벤트 플래그 출력 (W1C 레지스터용)
    output wire        no_broadcast_flag,
    output wire        bc_hamming_err_flag,
    output wire        halt_cmd_flag
);
```

> STATE 인코딩: IDLE=000, NORMAL=001, DATA_RECOVERY=010, FAULT=011, DEAD=100
> `tx_enable = (state == NORMAL || state == DATA_RECOVERY)`
> FAULT_CNT -1 트리거: `bc_valid` (정상 프레임 완수)
> LINE_CNT -1 트리거: `bc_preamble_ok` (preamble 유효 수신. bc_hamming_err가 있어도 감소 가능)
> IDLE→NORMAL 전이: `active_edge` 감지 (첫 동기 획득)
> 상세 규칙: `04_fault_decisions(4).md` §2·§5 참조

---

### 3.6 `regfile` — 레지스터 파일

```verilog
module regfile (
    input  wire        clk,
    input  wire        rst_n,

    // AXI-Lite 인터페이스 (생략 — tdma_slave_top과 동일)

    // 제어 출력
    output wire        enable,
    output wire        soft_rst,
    output wire [9:0]  div,
    output wire [9:0]  guard_ticks,
    output wire [2:0]  slave_addr,
    output wire [7:0]  fault_th,
    output wire [7:0]  line_fault_th,
    output wire [31:0] tx_data_out,   // TX_DATA 레지스터 → slave_tx

    // 상태 입력 (← 서브모듈)
    input  wire [2:0]  state_in,
    input  wire [7:0]  fault_cnt_in,
    input  wire [7:0]  line_cnt_in,
    input  wire        data_sent_in,
    input  wire        no_broadcast_flag_in,
    input  wire        bc_hamming_err_flag_in,
    input  wire        halt_cmd_flag_in,

    // IRQ 인터페이스 (→ irq_ctrl)
    output wire [4:0]  irq_mask_out,
    input  wire [4:0]  irq_status_in
);
```

---

### 3.7 `irq_ctrl` — 인터럽트 컨트롤러

```verilog
module irq_ctrl (
    input  wire        clk,
    input  wire        rst_n,

    // 이벤트 입력
    input  wire        data_sent,
    input  wire        no_broadcast,
    input  wire        bc_hamming_err,
    input  wire        halt_cmd,
    input  wire        state_change,  // fault_fsm 상태 전이 발생

    // IRQ_MASK
    input  wire [4:0]  irq_mask,

    // 출력
    output wire [4:0]  irq_status,
    output wire        irq
);
```

---

## 4. 인터페이스 연결 다이어그램

```
                ┌─────────────────────────────────────┐
 AXI-Lite ─────►│             regfile                 │
                │  enable/div/guard_ticks/             │
                │  slave_addr/fault_th/tx_data_out     │
                └───┬─────────────────────────────────┘
                    │ enable, div
                ┌───▼──────┐
                │ clk_div  │──── clk_tick ────────────┬──────────────┐
                └──────────┘                          │              │
                                                      ▼              ▼
                     tx_line ──(2-FF sync)──► master_rx          slave_tx ──► rx_line
                                                   │                  ▲
                                         active_edge│           tx_trigger│
                                                   │                  │
                                   div, guard_ticks, slave_addr       │
                                              ┌────▼─────────┐        │
                                              │  slot_timer  │────────┘
                                              │  (clk cycle) │──no_broadcast──► fault_fsm
                                              └──────────────┘
                                                        
              bc_valid, bc_preamble_ok,                              
              bc_halt_cmd, bc_hamming_err ──────────► fault_fsm
              active_edge ──────────────────────────► fault_fsm
                                                           │
                            state/fault_cnt/line_cnt ──► regfile ──► irq_ctrl ──► irq
                            tx_enable ──────────────────► slave_tx
                            flags ──────────────────────► regfile
```

> bc_halt_cmd_self = bc_halt_cmd[slave_addr] (1비트 추출)

---

## 5. 파라미터 목록

| 파라미터 | 기본값 | 설명 |
|----------|--------|------|
| `CLK_FREQ_MHZ` | 25 | 시스템 클럭 주파수 (MHz) |
| `NODE_CNT_MAX` | 8 | 최대 슬레이브 수 (CYCLE_TIMEOUT_TICKS 계산용, 고정) |

> 슬레이브는 GUARD_MIN을 독립적으로 계산하지 않는다. LINK_CFG는 마스터의 설정을 그대로 따른다.

---

## 6. 설계 주의사항

1. **tristate 구동**: rx_line은 tx_enable=1이고 tx_active=1인 구간에서만 구동. 나머지 High-Z. FPGA: `assign rx_line = (tx_active && tx_enable) ? tx_bit : 1'bz;`
2. **tx_line 동기화**: 마스터 TX는 비동기 입력. 2-FF 동기화 체인(`tx_line → tx_ff1 → tx_ff2`)을 거쳐 master_rx에 연결. active_edge 검출은 동기화된 신호 기준.
3. **bc_halt_cmd_self 생성**: slave_tx 또는 tdma_slave_top에서 `bc_halt_cmd[slave_addr]` 비트를 1비트로 추출하여 fault_fsm에 전달.
4. **SOFT_RST**: fault_fsm을 IDLE로, 모든 카운터를 0으로 동기 클리어. CTRL.ENABLE 비트는 클리어하지 않음.
5. **AXI-Lite 주소 폭**: 0x00~0x1C 범위이므로 5비트 주소 버스 충분.
6. **초기 기동**: ENABLE=1 이후 IDLE 상태. 첫 active_edge 감지 시 NORMAL로 전이하고 slot_timer가 tx_trigger 카운팅 시작.
7. **clk_tick과 slot_timer 분리**: slot_timer는 clk 기준으로 카운팅. DIV 변경 시 slot_ticks·CYCLE_TIMEOUT_TICKS가 자동 재계산됨.
