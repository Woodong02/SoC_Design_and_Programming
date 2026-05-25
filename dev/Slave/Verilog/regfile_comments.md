# regfile.v — 한글 주석 설명서

## 모듈 역할

AXI-Lite 슬레이브 인터페이스를 통해 PS(ARM)와 TDMA 슬레이브 IP 사이의 레지스터를 관리한다.

- **8개 레지스터**: 0x00~0x1C (5비트 주소)
- **단순화된 AXI-Lite**: `awready=wready=arready=1` 항상 허용. awvalid+wvalid 동시 가정.
- **읽기 경로**: arvalid 후 1클럭에 rvalid+rdata 응답

---

## 레지스터 맵

| 주소 | 이름 | 접근 | 설명 |
|------|------|------|------|
| 0x00 | CTRL | RW | `[0]=enable`, `[1]=soft_rst` (자동 클리어) |
| 0x04 | LINK_CFG | RW | `[9:0]=div`, `[19:10]=guard_ticks` |
| 0x08 | SLAVE_CFG | RW | `[2:0]=slave_addr_cfg` |
| 0x0C | FAULT_CFG | RW | `[7:0]=fault_th`, `[15:8]=line_fault_th` (기본값 30) |
| 0x10 | TX_DATA | RW | 32비트 송신 페이로드 |
| 0x14 | STATUS | RO+W1C | `[2:0]=fsm_state`, `[10:3]=fault_cnt`, `[18:11]=line_cnt`, `[22:19]=이벤트 플래그` |
| 0x18 | IRQ_STATUS | W1C | `[4:0]` 이벤트 래치 (irq_ctrl에서 관리) |
| 0x1C | IRQ_MASK | RW | `[4:0]` IRQ 활성화 마스크 |

---

## 포트

### AXI-Lite (쓰기 채널)
| 신호 | 방향 | 설명 |
|------|------|------|
| `s_axil_awaddr[4:0]` | 입력 | 쓰기 주소 |
| `s_axil_awvalid` | 입력 | 쓰기 주소 유효 |
| `s_axil_awready` | 출력 | 항상 1 |
| `s_axil_wdata[31:0]` | 입력 | 쓰기 데이터 |
| `s_axil_wstrb[3:0]` | 입력 | 바이트 스트로브 |
| `s_axil_wvalid` | 입력 | 쓰기 데이터 유효 |
| `s_axil_wready` | 출력 | 항상 1 |
| `s_axil_bresp[1:0]` | 출력 | 응답 코드 (항상 OKAY=00) |
| `s_axil_bvalid` | 출력 | 쓰기 응답 유효 |
| `s_axil_bready` | 입력 | 응답 수신 준비 |

### AXI-Lite (읽기 채널)
| 신호 | 방향 | 설명 |
|------|------|------|
| `s_axil_araddr[4:0]` | 입력 | 읽기 주소 |
| `s_axil_arvalid` | 입력 | 읽기 주소 유효 |
| `s_axil_arready` | 출력 | 항상 1 |
| `s_axil_rdata[31:0]` | 출력 | 읽기 데이터 |
| `s_axil_rresp[1:0]` | 출력 | 읽기 응답 (항상 OKAY=00) |
| `s_axil_rvalid` | 출력 | 읽기 데이터 유효 |
| `s_axil_rready` | 입력 | 읽기 수신 준비 |

---

## 쓰기 로직 핵심

### wr_en 조건
```verilog
wire wr_en = s_axil_awvalid & s_axil_wvalid; // 동시 유효 → 단일 사이클 쓰기
```

### 바이트 스트로브 처리
```verilog
function [31:0] apply_strb(old_val, new_val, strb);
    // 각 바이트를 strb 비트에 따라 선택적으로 갱신
```
`wstrb=0xF`이면 전체 32비트 갱신, `wstrb=0x1`이면 [7:0]만 갱신.

### SOFT_RST 자동 클리어
```verilog
if (soft_rst) soft_rst <= 1'b0; // 매 클럭 자동 0으로 리셋 (1클럭 펄스 효과)
```

### IRQ_CLR 자동 클리어
```verilog
irq_clr <= 5'd0; // 매 클럭 0으로 초기화 (W1C 쓰기 클럭에만 1 유지)
```

---

## STATUS[22:19] — W1C 이벤트 플래그

```verilog
st_data_sent <= (st_data_sent | ev_data_sent)
                & ~(wr_en && wr_addr[4:2]==3'd5 && wr_masked[19]);
```

- `ev_data_sent=1` → 비트 세팅
- STATUS(0x14)에 bit[19]=1을 쓰면 → 비트 클리어
- 세팅과 클리어 동시 발생 시: **클리어 우선**

STATUS 비트 레이아웃:
```
[2:0]   = fsm_state  (RO)
[10:3]  = fault_cnt  (RO)
[18:11] = line_cnt   (RO)
[19]    = st_data_sent    (W1C)
[20]    = st_no_broadcast (W1C)
[21]    = st_hamming_err  (W1C)
[22]    = st_halt_cmd     (W1C)
```

---

## 읽기 로직

```verilog
if (s_axil_arvalid && !s_axil_rvalid) begin
    s_axil_rvalid <= 1'b1;
    case (s_axil_araddr[4:2])   // 주소 상위 3비트로 레지스터 선택
        ...
    endcase
end else if (s_axil_rready) begin
    s_axil_rvalid <= 1'b0;      // 핸드셰이크 완료 후 rvalid 클리어
end
```

- arvalid 어서트 후 1클럭에 rvalid=1, rdata 안정
- rready 감지 시 rvalid 클리어

---

## 리셋 초기값

| 레지스터 | 초기값 |
|---------|--------|
| CTRL | 0 (enable=0) |
| LINK_CFG | 0 (div=0, guard=0) |
| FAULT_CFG | 0x1E1E (fault_th=30, line_fault_th=30) |
| 그 외 | 0 |
