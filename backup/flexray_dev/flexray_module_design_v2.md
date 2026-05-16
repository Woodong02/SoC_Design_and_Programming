# FlexRay 축약형 IP — 모듈 설계 문서 v2

> 설계 조건
> - 채널 A 단일
> - 메시지 버퍼 1개 (TX/RX 설정 고정)
> - 스타트업/콜드스타트 제외 (관련 필드는 하드코딩 후 TODO 마킹)
> - AXI4-Lite slave, 32비트 데이터 폭 (상위 16비트 0 고정)
> - PE 담당: TDMA 스케줄링 + 프레임 송수신 + 클럭 동기
> - 언어: SystemVerilog (Vivado 2019.1)
> - 페이로드 저장: mb_regs 내부 BRAM 배열
> - PCR23 = micro_per_cycle 하위 16비트

---

## 확정된 미결 사항

| # | 항목 | 결정 내용 |
|---|------|-----------|
| 1 | BSY 핸드셰이크 | `pe_cmd_ack` 포트 추가 — PE가 명령 처리 완료 시 1클럭 펄스, poc_cmd가 받아서 BSY 클리어 |
| 2 | CMT 신호 | `mb_cmt_pulse` 포트 추가 — mb_regs가 CMT 비트 감지 시 PE로 1클럭 펄스 |
| 3 | PCR23 주소 | PCR22 = micro_per_cycle[19:16], PCR23 = micro_per_cycle[15:0] |
| 4 | 페이로드 접근 구조 | mb_regs 내부 BRAM 배열 (`reg [7:0] payload_mem [0:253]`), AXI 주소로 직접 접근 |
| 5 | 합성 타겟 | SystemVerilog, Vivado 2019.1 |
| 6 | PHY 인코딩 | 미결 — phy_if 구현 시 FlexRay 물리 계층 스펙 별도 참조 필요 |

---

## 1. 모듈 리스트

| 번호 | 파일명 | 대응 블록 | 비고 |
|------|--------|-----------|------|
| 1 | `flexray_top.sv` | 최상위 래퍼 | 전체 인스턴스 연결 |
| 2 | `axi_slave.sv` | AXI slave 인터페이스 | 레지스터 R/W 중재 |
| 3 | `mod_cfg.sv` | ctrl — mod_cfg | MCR |
| 4 | `poc_cmd.sv` | ctrl — poc_cmd | POCR, BSY |
| 5 | `psr_status.sv` | ctrl — psr_status | PSR0~2 |
| 6 | `pcr_regs.sv` | pcr 전체 | PCR0~29 |
| 7 | `timing_counter.sv` | timing_counter | MTCTR, CYCTR, SLTCTAR |
| 8 | `clk_sync.sv` | corr_calc/apply/limit | RTCORVR, OFCORVR |
| 9 | `mb_regs.sv` | mb 전체 (단일 버퍼) | MBCCSRn, MBCCFRn, MBFIDRn + 페이로드 BRAM |
| 10 | `irq_ctrl.sv` | irq 전체 | GIFER, PIFR0, PIER0, CIFRR |
| 11 | `slot_monitor.sv` | slotmon 전체 | SSSR×1, SSR0~1, SSCCR, SSCR0 |
| 12 | `protocol_engine.sv` | PE | TDMA 스케줄러, 프레임 조립/분해, 클럭 동기 연산 |
| 13 | `phy_if.sv` | 물리 레이어 | TX/RX 비트 직렬화, 채널 A |

---

## 2. 포트 정의

---

### 2.1 `flexray_top.sv`

```systemverilog
module flexray_top (
    // 클럭 / 리셋
    input  logic        clk,
    input  logic        rst_n,

    // AXI4-Lite slave
    input  logic [15:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,
    input  logic [15:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // 인터럽트 출력
    output logic        irq_out,

    // 물리 레이어 — 채널 A
    output logic        txd_a,
    output logic        txen_a,
    input  logic        rxd_a
);
```

**책임:** 모든 서브모듈 인스턴스 연결. 내부 로직 없음. 신호 라우팅만.

---

### 2.2 `axi_slave.sv`

```systemverilog
module axi_slave (
    input  logic        clk,
    input  logic        rst_n,

    // AXI4-Lite
    input  logic [15:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,
    input  logic [15:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // 내부 레지스터 버스
    output logic [15:0] reg_addr,
    output logic        reg_wr_en,
    output logic [15:0] reg_wr_data,   // 하위 16비트만 유효
    output logic        reg_rd_en,
    input  logic [15:0] reg_rd_data,
    input  logic        reg_rd_valid
);
```

**책임:** AXI 프로토콜 처리 (handshake, BRESP, RDATA). 주소를 디코딩해서 내부 레지스터 버스로 변환. 읽기 시 상위 16비트 0 패딩, 쓰기 시 상위 16비트 무시.

---

### 2.3 `mod_cfg.sv`

```systemverilog
module mod_cfg (
    input  logic        clk,
    input  logic        rst_n,

    // 레지스터 버스
    input  logic [15:0] reg_addr,
    input  logic        reg_wr_en,
    input  logic [15:0] reg_wr_data,
    input  logic        reg_rd_en,
    output logic [15:0] reg_rd_data,
    output logic        reg_rd_valid,

    // 출력
    output logic        mcr_men,       // 모듈 활성화 (write-once)
    output logic        mcr_scm,       // 단채널 모드 (1 고정)
    output logic        mcr_cha,       // 채널 A 활성화 (1 고정)
    output logic        mcr_sffe,      // sync frame 필터링
    output logic [2:0]  mcr_bitrate    // 비트레이트 선택
);
```

**책임:** MCR 레지스터 저장 및 제공. `mcr_men`은 write-once — 한 번 1이 되면 리셋 전까지 0 불가. `mcr_scm`, `mcr_cha`는 레지스터 유지하되 1 고정. `mcr_bitrate`는 phy_if가 참조.

---

### 2.4 `poc_cmd.sv`

```systemverilog
module poc_cmd (
    input  logic        clk,
    input  logic        rst_n,

    // 레지스터 버스
    input  logic [15:0] reg_addr,
    input  logic        reg_wr_en,
    input  logic [15:0] reg_wr_data,
    input  logic        reg_rd_en,
    output logic [15:0] reg_rd_data,
    output logic        reg_rd_valid,

    // POC 상태 입력 (psr_status로부터)
    input  logic [2:0]  poc_state,

    // PE로 명령 출력
    output logic [3:0]  poc_cmd_out,
    output logic        poc_cmd_valid,  // 1클럭 펄스

    // PE로부터 명령 완료 응답 [확정 #1]
    input  logic        pe_cmd_ack,     // 1클럭 펄스 — BSY 클리어 트리거

    // BSY 플래그 출력 (psr_status 경유로 PS 읽기)
    output logic        bsy,

    // 보정 트리거 출력 (clk_sync로)
    output logic [1:0]  eoc_ap,
    output logic [1:0]  erc_ap
);
```

**책임:** POCR 레지스터 처리. PS가 POCCMD를 쓰면 BSY 확인 후 PE로 명령 펄스 발생 및 BSY 세트. `pe_cmd_ack` 수신 시 BSY 클리어. WMC=1이면 POCCMD 쓰기 차단, WME=1이면 EOC_AP/ERC_AP 쓰기 차단.

---

### 2.5 `psr_status.sv`

```systemverilog
module psr_status (
    input  logic        clk,
    input  logic        rst_n,

    // 레지스터 버스
    input  logic [15:0] reg_addr,
    input  logic        reg_wr_en,
    input  logic [15:0] reg_wr_data,
    input  logic        reg_rd_en,
    output logic [15:0] reg_rd_data,
    output logic        reg_rd_valid,

    // PE로부터 상태 수신
    input  logic [1:0]  pe_errmode,
    input  logic [1:0]  pe_slotmode,
    input  logic [2:0]  pe_protstate,
    input  logic [3:0]  pe_clkcorrfailcnt,

    // 채널 A 오류 상태 (PE로부터)
    input  logic        pe_nbva,
    input  logic        pe_nsea,
    input  logic        pe_stca,
    input  logic        pe_sbva,
    input  logic        pe_ssea,
    input  logic        pe_mta,

    // BSY 입력 (poc_cmd로부터) — PSR 읽기에 포함
    input  logic        bsy,

    // 출력 — poc_cmd로
    output logic [2:0]  poc_state

    // TODO: startup 관련 필드 하드코딩
    // psr0_startupstate = 4'b0000
    // psr0_wakeupstatus = 3'b000
    // psr1_csaa         = 1'b0
    // psr1_csp          = 1'b0
    // psr1_remcsat      = 5'd0
    // psr1_cpn          = 1'b0
    // psr1_hhr          = 1'b0
    // psr1_frz          = 1'b0
    // psr1_aptac        = 5'd0
);
```

**책임:** PSR0~2 읽기 전용 레지스터 조합 제공. PE 상태 신호를 레지스터 필드로 매핑. 스타트업 관련 필드 전부 0 하드코딩. `poc_state`를 poc_cmd로 전달.

---

### 2.6 `pcr_regs.sv`

```systemverilog
module pcr_regs (
    input  logic        clk,
    input  logic        rst_n,

    // 레지스터 버스
    input  logic [15:0] reg_addr,
    input  logic        reg_wr_en,
    input  logic [15:0] reg_wr_data,
    input  logic        reg_rd_en,
    output logic [15:0] reg_rd_data,
    output logic        reg_rd_valid,

    // 쓰기 가능 여부
    input  logic        config_mode,

    // 출력 — PE, timing_counter로
    output logic [4:0]  pcr_action_point_offset,
    output logic [10:0] pcr_static_slot_length,
    output logic [13:0] pcr_macro_after_first_static_slot,
    output logic [4:0]  pcr_minislot_after_action_point,
    output logic [10:0] pcr_number_of_static_slots,
    output logic [13:0] pcr_macro_per_cycle,
    output logic        pcr_single_slot_enabled,
    output logic [10:0] pcr_key_slot_header_crc,
    output logic [6:0]  pcr_macro_initial_offset_a,
    output logic [4:0]  pcr_extern_rate_correction,
    output logic [10:0] pcr_latest_tx,
    output logic [19:0] pcr_micro_per_cycle,   // PCR22[3:0]=상위4, PCR23[15:0]=하위16 [확정 #3]
    output logic [4:0]  pcr_extern_offset_correction,
    output logic [10:0] pcr_minislots_max,

    // TODO: startup 미사용 — 레지스터 유지, PE 미참조
    output logic [5:0]  pcr_coldstart_attempts,
    output logic [6:0]  pcr_cas_rx_low_max,
    output logic [4:0]  pcr_allow_passive_to_active,
    output logic [9:0]  pcr_comp_accepted_startup_range_a
);
```

**책임:** PCR0~29 저장. `config_mode=1`일 때만 쓰기 허용. PCR22/23을 합쳐서 `pcr_micro_per_cycle[19:0]`으로 제공. TODO 필드는 레지스터는 유지하되 PE가 참조하지 않음.

---

### 2.7 `timing_counter.sv`

```systemverilog
module timing_counter (
    input  logic        clk,
    input  logic        rst_n,

    // 레지스터 버스 (읽기 전용)
    input  logic [15:0] reg_addr,
    input  logic        reg_rd_en,
    output logic [15:0] reg_rd_data,
    output logic        reg_rd_valid,

    // PE로부터 카운터 값 수신
    input  logic [13:0] pe_mtcnt,
    input  logic [5:0]  pe_cyccnt,
    input  logic [10:0] pe_slotcnt_a,

    // 출력 — irq_ctrl, slot_monitor로
    output logic [5:0]  cyccnt_out,
    output logic [10:0] slotcnt_a_out
);
```

**책임:** MTCTR, CYCTR, SLTCTAR를 PS 읽기용으로 노출. 값은 PE가 매 클럭 업데이트. 쓰기 접근 무시.

---

### 2.8 `clk_sync.sv`

```systemverilog
module clk_sync (
    input  logic        clk,
    input  logic        rst_n,

    // 레지스터 버스
    input  logic [15:0] reg_addr,
    input  logic        reg_wr_en,
    input  logic [15:0] reg_wr_data,
    input  logic        reg_rd_en,
    output logic [15:0] reg_rd_data,
    output logic        reg_rd_valid,

    // PE로부터 보정값 업데이트 (NIT 구간)
    input  logic        pe_ratecorr_wr,
    input  logic [15:0] pe_ratecorr_val,
    input  logic        pe_offsetcorr_wr,
    input  logic [15:0] pe_offsetcorr_val,

    // poc_cmd로부터 보정 트리거
    input  logic [1:0]  eoc_ap,
    input  logic [1:0]  erc_ap,

    // 보정 한계 (pcr_regs로부터)
    input  logic [4:0]  extern_rate_correction,
    input  logic [4:0]  extern_offset_correction,

    // 출력 — PE로 보정 적용
    output logic        corr_apply_valid,
    output logic [15:0] ratecorr_to_pe,
    output logic [15:0] offsetcorr_to_pe,
    output logic [1:0]  ratecorr_dir,     // 00=미적용, 10=빼기, 11=더하기
    output logic [1:0]  offsetcorr_dir,

    // 출력 — irq_ctrl로
    output logic        ccl_flag          // 보정값 한계 초과
);
```

**책임:** RTCORVR, OFCORVR 저장. PE(NIT 구간) 또는 PS(직접 쓰기) 양쪽에서 값 업데이트 가능. EOC_AP/ERC_AP 트리거 수신 시 방향과 함께 PE로 보정 적용 신호 전달. 한계 초과 시 `ccl_flag` 세트 → irq_ctrl로.

---

### 2.9 `mb_regs.sv`

```systemverilog
module mb_regs (
    input  logic        clk,
    input  logic        rst_n,

    // 레지스터 버스
    input  logic [15:0] reg_addr,
    input  logic        reg_wr_en,
    input  logic [15:0] reg_wr_data,
    input  logic        reg_rd_en,
    output logic [15:0] reg_rd_data,
    output logic        reg_rd_valid,

    // 쓰기 가능 조건
    input  logic        config_mode,

    // MBCCSRn 설정 출력 — PE로
    output logic        mb_mcm,
    output logic        mb_mbt,
    output logic        mb_mtd,        // 방향 (0=RX, 1=TX)
    output logic        mb_mbie,
    output logic        mb_eds,
    output logic        mb_lcks,

    // 송신 커밋 트리거 [확정 #2]
    output logic        mb_cmt_pulse,  // CMT 비트 감지 시 1클럭 펄스 → PE

    // MBCCFRn 출력 — PE로
    output logic        mb_mtm,
    output logic        mb_cha,        // 채널 A 고정 (1)
    output logic        mb_ccfe,
    output logic [5:0]  mb_ccfmsk,
    output logic [5:0]  mb_ccfval,

    // MBFIDRn 출력 — PE로
    output logic [10:0] mb_fid,

    // PE로부터 상태 갱신
    input  logic        pe_mb_dup,
    input  logic        pe_mb_dval,
    input  logic        pe_mb_lcks_set,
    input  logic        pe_mb_lcks_clr,

    // 페이로드 BRAM 인터페이스 [확정 #4]
    // AXI 접근: reg_addr >= PAYLOAD_BASE_ADDR 구간에서 직접 처리
    // PE 접근: 별도 포트
    input  logic [7:0]  pe_payload_addr,   // PE가 읽거나 쓸 바이트 주소 (0~253)
    input  logic        pe_payload_wr,     // PE 쓰기 활성화 (RX 수신 시)
    input  logic [7:0]  pe_payload_wdata,  // PE 쓰기 데이터
    output logic [7:0]  pe_payload_rdata,  // PE 읽기 데이터 (TX 송신 시)

    // 인터럽트 출력 — irq_ctrl로
    output logic        mb_mbif,
    output logic        mb_irq_valid   // MBIF & MBIE
);
```

**책임:** MBCCSRn, MBCCFRn, MBFIDRn 저장 및 제공. EDT/LCKT 토글 처리. CMT 비트 감지 시 `mb_cmt_pulse` 1클럭 펄스 발생 후 자동 클리어. 페이로드 BRAM (`logic [7:0] payload_mem [0:253]`)을 내부에 선언하고 AXI 주소 구간과 PE 포트 양쪽으로 접근 제공. MBIF는 PS가 1 써서 클리어.

---

### 2.10 `irq_ctrl.sv`

```systemverilog
module irq_ctrl (
    input  logic        clk,
    input  logic        rst_n,

    // 레지스터 버스
    input  logic [15:0] reg_addr,
    input  logic        reg_wr_en,
    input  logic [15:0] reg_wr_data,
    input  logic        reg_rd_en,
    output logic [15:0] reg_rd_data,
    output logic        reg_rd_valid,

    // 플래그 입력 소스 (PE로부터)
    input  logic        src_fatl,
    input  logic        src_intl,
    input  logic        src_ilcf,
    input  logic        src_mrc,
    input  logic        src_moc,
    input  logic        src_mxs,
    input  logic        src_mtx,
    input  logic        src_ltxa,
    input  logic        src_tbva,
    input  logic        src_cys,

    // clk_sync로부터
    input  logic        src_ccl,

    // mb_regs로부터
    input  logic        mb_irq_valid,
    input  logic        mb_mtd,        // RBIF/TBIF 분기용

    // TODO: startup 미구현
    // src_csa = 1'b0 하드코딩

    // 인터럽트 출력
    output logic        irq_out
);
```

**책임:** GIFER, PIFR0, PIER0, CIFRR 관리. 소스 플래그 → PIFR0 세트 → PIER0와 AND → GIFER 집계 → `irq_out` 구동. PS가 1 써서 플래그 클리어. CIFRR은 enable 무관 OR 합산 읽기 전용. `src_csa` 하드코딩 0.

---

### 2.11 `slot_monitor.sv`

```systemverilog
module slot_monitor (
    input  logic        clk,
    input  logic        rst_n,

    // 레지스터 버스
    input  logic [15:0] reg_addr,
    input  logic        reg_wr_en,
    input  logic [15:0] reg_wr_data,
    input  logic        reg_rd_en,
    output logic [15:0] reg_rd_data,
    output logic        reg_rd_valid,

    // 현재 사이클/슬롯
    input  logic [5:0]  cyccnt,
    input  logic [10:0] slotcnt_a,

    // PE로부터 슬롯 상태 (매 슬롯 종료 시 펄스)
    input  logic        pe_slot_valid,
    input  logic [10:0] pe_slot_num,
    input  logic        pe_ssr_vfa,
    input  logic        pe_ssr_sya,
    input  logic        pe_ssr_nfa,
    input  logic        pe_ssr_sua,
    input  logic        pe_ssr_sea,
    input  logic        pe_ssr_cea,
    input  logic        pe_ssr_bva,
    input  logic        pe_ssr_tca
);
```

**책임:** SSSR 1개 (단일 슬롯 모니터링), SSR0(짝수 사이클)/SSR1(홀수 사이클), SSCCR 1개, SSCR0 관리. PE 슬롯 종료 펄스 수신 시 SSSR 슬롯 번호와 비교, 일치하면 SSR 캡처. SSCCR 조건 충족 시 SSCR0 증가. 채널 B 필드 전부 0 고정.

---

### 2.12 `protocol_engine.sv`

```systemverilog
module protocol_engine (
    input  logic        clk,
    input  logic        rst_n,

    // POC 제어
    input  logic [3:0]  poc_cmd_in,
    input  logic        poc_cmd_valid,
    output logic        pe_cmd_ack,      // 명령 처리 완료 펄스 [확정 #1]
    output logic [2:0]  pe_protstate,
    output logic [1:0]  pe_errmode,
    output logic [1:0]  pe_slotmode,

    // PCR 파라미터
    input  logic [13:0] macro_per_cycle,
    input  logic [10:0] static_slot_length,
    input  logic [10:0] number_of_static_slots,
    input  logic [4:0]  action_point_offset,
    input  logic [4:0]  minislot_after_action_point,
    input  logic [10:0] minislots_max,
    input  logic [19:0] micro_per_cycle,
    input  logic [13:0] macro_after_first_static_slot,
    input  logic [10:0] latest_tx,
    input  logic        single_slot_enabled,

    // 타이밍 카운터 출력
    output logic [13:0] pe_mtcnt,
    output logic [5:0]  pe_cyccnt,
    output logic [10:0] pe_slotcnt_a,

    // 클럭 동기 (clk_sync 양방향)
    output logic        pe_ratecorr_wr,
    output logic [15:0] pe_ratecorr_val,
    output logic        pe_offsetcorr_wr,
    output logic [15:0] pe_offsetcorr_val,
    input  logic        corr_apply_valid,
    input  logic [15:0] ratecorr_to_pe,
    input  logic [15:0] offsetcorr_to_pe,
    input  logic [1:0]  ratecorr_dir,
    input  logic [1:0]  offsetcorr_dir,

    // 메시지 버퍼 인터페이스
    input  logic        mb_mtd,
    input  logic [10:0] mb_fid,
    input  logic        mb_eds,
    input  logic        mb_ccfe,
    input  logic [5:0]  mb_ccfmsk,
    input  logic [5:0]  mb_ccfval,
    input  logic        mb_cmt_pulse,    // TX 커밋 트리거 [확정 #2]
    output logic        pe_mb_dup,
    output logic        pe_mb_dval,
    output logic        pe_mb_lcks_set,
    output logic        pe_mb_lcks_clr,

    // 페이로드 BRAM 접근 (mb_regs로)
    output logic [7:0]  pe_payload_addr,
    output logic        pe_payload_wr,
    output logic [7:0]  pe_payload_wdata,
    input  logic [7:0]  pe_payload_rdata,

    // 슬롯 모니터 출력
    output logic        pe_slot_valid,
    output logic [10:0] pe_slot_num,
    output logic        pe_ssr_vfa,
    output logic        pe_ssr_sya,
    output logic        pe_ssr_nfa,
    output logic        pe_ssr_sua,
    output logic        pe_ssr_sea,
    output logic        pe_ssr_cea,
    output logic        pe_ssr_bva,
    output logic        pe_ssr_tca,

    // 인터럽트 소스 출력
    output logic        irq_fatl,
    output logic        irq_intl,
    output logic        irq_ilcf,
    output logic        irq_mrc,
    output logic        irq_moc,
    output logic        irq_mxs,
    output logic        irq_mtx,
    output logic        irq_ltxa,
    output logic        irq_tbva,
    output logic        irq_cys,

    // PSR 오류 상태 출력
    output logic [3:0]  pe_clkcorrfailcnt,
    output logic        pe_nbva,
    output logic        pe_nsea,
    output logic        pe_stca,
    output logic        pe_sbva,
    output logic        pe_ssea,
    output logic        pe_mta,

    // 물리 레이어 인터페이스
    output logic        pe_tx_valid,
    output logic [7:0]  pe_tx_byte,
    output logic        pe_tx_last,
    input  logic        phy_tx_ready,
    input  logic        phy_rx_valid,
    input  logic [7:0]  phy_rx_byte,
    input  logic        phy_rx_last,
    input  logic        phy_rx_error
);
```

**책임:** POC 상태 머신 (default_config → config → ready → normal_active → halt). TDMA 스케줄러 (매크로틱/슬롯 카운터 구동, 정적/동적 세그먼트 경계 관리). 프레임 조립 (헤더 구성, 헤더 CRC 계산, 페이로드 BRAM 읽기). 프레임 분해 (수신 프레임 파싱, 슬롯 매칭, 페이로드 BRAM 쓰기). 클럭 동기 연산 (레이트/오프셋 보정값 계산, NIT 구간 업데이트). `pe_cmd_ack`는 POC 상태 전이 완료 시 1클럭 펄스 발생.

**TODO:** startup 상태 (FSM 상태 정의만, 전이 조건 미구현).

---

### 2.13 `phy_if.sv`

```systemverilog
module phy_if (
    input  logic        clk,
    input  logic        rst_n,

    // 비트레이트 설정
    input  logic [2:0]  bitrate,       // 000=10Mbps, 001=5Mbps, 010=2.5Mbps

    // PE 인터페이스
    input  logic        pe_tx_valid,
    input  logic [7:0]  pe_tx_byte,
    input  logic        pe_tx_last,
    output logic        phy_tx_ready,
    output logic        phy_rx_valid,
    output logic [7:0]  phy_rx_byte,
    output logic        phy_rx_last,
    output logic        phy_rx_error,

    // 물리 핀 — 채널 A
    output logic        txd_a,
    output logic        txen_a,
    input  logic        rxd_a
);
```

**책임:** 바이트 스트림 ↔ NRZ 비트 직렬화/역직렬화. 비트레이트에 따라 분주비 설정. BSS/FES 심볼 처리. 수신 시 바이트 경계 검출 및 프레임 종료 감지. CRC는 PE 담당.

**미결 #6:** FlexRay 물리 계층 인코딩 상세 규칙 — phy_if 구현 시 별도 스펙 참조 필요.

---

## 3. 모듈 간 주요 신호 흐름

```
PS (AXI)
  ↕
axi_slave — reg_addr / reg_wr_en / reg_wr_data / reg_rd_data
  │
  ├── mod_cfg       → mcr_men, mcr_bitrate            → protocol_engine, phy_if
  │
  ├── poc_cmd       → poc_cmd_out, poc_cmd_valid       → protocol_engine
  │               ← pe_cmd_ack                        ← protocol_engine
  │                 → eoc_ap, erc_ap                  → clk_sync
  │
  ├── psr_status   ← pe_protstate, pe_errmode 등      ← protocol_engine
  │                 → poc_state                       → poc_cmd
  │
  ├── pcr_regs      → PCR 파라미터 전체               → protocol_engine
  │
  ├── timing_counter ← pe_mtcnt, pe_cyccnt, pe_slotcnt ← protocol_engine
  │                   → cyccnt_out, slotcnt_a_out     → slot_monitor
  │
  ├── clk_sync     ↔ 보정값 / 보정 트리거            ↔ protocol_engine
  │                 → ccl_flag                        → irq_ctrl
  │
  ├── mb_regs       → mb_fid, mb_mtd, mb_eds 등       → protocol_engine
  │               ← pe_mb_dup, pe_mb_dval 등          ← protocol_engine
  │                 → mb_cmt_pulse                    → protocol_engine
  │               ↔ 페이로드 BRAM                    ↔ protocol_engine
  │                 → mb_irq_valid, mb_mtd            → irq_ctrl
  │
  ├── irq_ctrl     ← 인터럽트 소스 전체               ← protocol_engine, clk_sync, mb_regs
  │                 → irq_out
  │
  ├── slot_monitor ← pe_slot_valid, pe_slot_num 등    ← protocol_engine
  │               ← cyccnt, slotcnt_a                ← timing_counter
  │
  └── protocol_engine ↔ phy_if (바이트 스트림)
                        → txd_a, txen_a / ← rxd_a
```

---

## 4. 미결 사항

| # | 항목 | 내용 |
|---|------|-------|
| 6 | PHY 인코딩 | FlexRay 물리 계층 BSS 인코딩 규칙 — phy_if 구현 시 별도 스펙 참조 필요 |
