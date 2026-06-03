# TDMA Master/Slave 설정 가이드

## 1. 설정 항목 대응표

| 항목 | Slave (Verilog parameter) | Master (main.c 함수) | 값 범위 | 주의 |
|------|--------------------------|----------------------|---------|------|
| 비트 주기 | `DIV` | `SET_DIV(N)` | 1~1024 | **오프셋 다름** (아래 참조) |
| 가드 구간 | `GUARD_TICKS` | `SET_GUARD_TICKS(N)` | 4~1023 | 동일 값 그대로 |
| 슬레이브 수 | — (각 `SLAVE_ADDR`로 결정) | `SET_NODE_CNT(N)` | 1~8 | **오프셋 다름** (아래 참조) |
| 결함 임계 | `FAULT_TH` | `SET_FAULT_TH(N)` | 1~245 | 의미가 다름 (아래 참조) |
| 선로 결함 임계 | `LINE_FAULT_TH` | — (Master에 없음) | 1~255 | Slave 전용 |
| Slient 임계 | — | `SET_SILENT_TH(N)` | 1~245 | Master 전용 |
| 슬레이브 주소 | `SLAVE_ADDR` | — | 0~7 | Slave 전용 |

---

## 2. DIV — 비트 주기 (핵심 주의 항목)

### 동작 원리
하나의 TDMA 비트를 전송하는 데 걸리는 클럭 수.  
**Master와 Slave가 같은 값을 사용해야 타이밍이 일치한다.**

### 왜 설정 방식이 다른가?
- **Slave**: Verilog `parameter`이므로 원하는 값을 그대로 쓴다.
- **Master**: PS(ARM)가 10비트 레지스터에 값을 저장한다.  
  `DIV=1024`를 저장하려면 10비트 최대값 `1023`을 사용해야 하므로  
  `SET_DIV(N)` 내부에서 **N-1을 레지스터에 씀**.  
  PL(RTL)은 읽은 값에 1을 더해 복원 → `DIV_p1 = DIV + 1`

### 설정 규칙

```
같은 비트 주기 T를 원할 때:
  Slave  parameter  : .DIV(T)
  Master main.c     : SET_DIV(T)   ← 내부에서 T-1 저장, RTL이 +1 복원
```

> **TB에서 직접 master_top 포트에 연결할 때**:  
> PS 역할을 TB가 대신하므로 `.DIV(T-1)` 로 입력해야 한다.  
> (master_top 내부에서 +1이 일어나기 때문)

### 예시 (T = 8클럭/비트, 100MHz → 80ns/비트)

```verilog
// Slave 인스턴스
tdma_slave_top #(.DIV(8), .GUARD_TICKS(200), .SLAVE_ADDR(0), ...) slave0 (...);

// TB에서 master_top에 직접 연결 (PS 대역)
localparam DIV_USER = 10'd8;
localparam DIV_M    = DIV_USER - 10'd1;  // = 7
master_top dut_m (.DIV(DIV_M), ...);     // 내부 DIV_p1 = 7+1 = 8 ✓
```

```c
// main.c (실보드)
SET_DIV(8);   // 내부: 8-1=7 레지스터에 저장, RTL DIV_p1=8 ✓
```

---

## 3. GUARD_TICKS — 슬롯 간 가드 구간

슬롯 마지막 비트 전송 후 다음 슬롯 시작 전까지 대기하는 클럭 수.  
**오프셋 없음 — 같은 값을 그대로 쓴다.**

```
슬롯 길이 [클럭] = 50 × DIV + GUARD_TICKS
TDMA 사이클 [클럭] = NODE_CNT × 슬롯 길이
```

```verilog
tdma_slave_top #(.GUARD_TICKS(200), ...) slave0 (...);
```

```c
SET_GUARD_TICKS(200);  // 레지스터에 200 그대로 저장
```

---

## 4. NODE_CNT — 슬레이브 수

Master가 몇 개의 슬롯을 순환할지 결정.  
**Slave에는 이 설정이 없다.** 각 슬레이브는 자신의 `SLAVE_ADDR` 슬롯에만 응답한다.

### 오프셋 규칙
`SET_NODE_CNT(N)` 내부에서 **N-1을 레지스터에 씀**.  
RTL은 `NODE_CNT` 값을 직접 사용해 슬롯 0..N-1 = N개를 순환.

```
슬레이브 3개(ADDR=0,1,2)를 사용할 때:
  SET_NODE_CNT(3)   → 레지스터에 2 저장 → RTL: 슬롯 0,1,2 순환 ✓
```

### SLAVE_ADDR와의 대응

```
  SET_NODE_CNT(N) → 슬롯 0 ~ N-1 활성
  슬레이브는 0 ~ N-1 사이의 주소를 가져야 한다.
  SLAVE_ADDR >= N 인 슬레이브는 자신의 슬롯이 오지 않아 아무것도 전송 못 함.
```

---

## 5. FAULT_TH / LINE_FAULT_TH / SILENT_TH

### FAULT_TH (공통, 의미가 다름)

| 모듈 | 파라미터 | 의미 |
|------|---------|------|
| Slave `tdma_slave_top` | `FAULT_TH` | **연속 무수신** 카운트 임계. 초과 시 FSM → DEAD |
| Master `master_top` | `SET_FAULT_TH(N)` | **오류 합계** (preamble_err + slot_timeout + hamming_err) 임계. 초과 시 해당 슬롯 halt_cmd 발생 |

두 값이 "같은 이름"이지만 판단 기준이 다르므로 독립적으로 설정한다.

### LINE_FAULT_TH (Slave 전용)
선로 비트 에러(preamble 불일치 등) 카운트 임계. Master에는 없음.

```verilog
tdma_slave_top #(.FAULT_TH(30), .LINE_FAULT_TH(30), ...) slave0 (...);
```

### SILENT_TH (Master 전용)
`err_cnt[7:0]`(silent_cnt) 초과 시 `Silent_node` 플래그 세팅 → 인터럽트 발생.

```c
SET_SILENT_TH(200);
```

---

## 6. 완전한 설정 예시 (슬레이브 3개, DIV=8, GT=200)

### Verilog TB (시뮬레이션)

```verilog
localparam [9:0] DIV_USER = 10'd8;          // 비트 주기
localparam [9:0] DIV_M    = DIV_USER - 10'd1; // master_top 포트용 (= 7)
localparam [9:0] GT       = 10'd200;         // GUARD_TICKS
localparam [2:0] NCNT     = 3'd2;            // NODE_CNT (3개 → 0,1,2)

master_top dut_m (
    .DIV        (DIV_M),    // 7 입력 → 내부 DIV_p1=8
    .GUARD_TICKS(GT),       // 200 그대로
    .NODE_CNT   (NCNT),     // 2 입력 → 슬롯 0,1,2 순환
    ...
);

tdma_slave_top #(.DIV(DIV_USER), .GUARD_TICKS(GT),
                 .SLAVE_ADDR(3'd0), .FAULT_TH(30), .LINE_FAULT_TH(30), ...)
  slave0 (...);
tdma_slave_top #(.DIV(DIV_USER), .GUARD_TICKS(GT),
                 .SLAVE_ADDR(3'd1), .FAULT_TH(30), .LINE_FAULT_TH(30), ...)
  slave1 (...);
tdma_slave_top #(.DIV(DIV_USER), .GUARD_TICKS(GT),
                 .SLAVE_ADDR(3'd2), .FAULT_TH(30), .LINE_FAULT_TH(30), ...)
  slave2 (...);
```

### main.c (실보드)

```c
// 위와 동일한 설정을 실보드에서 재현
Master_node_init(
    8,    // DIV        → 내부에서 7 저장, RTL DIV_p1=8
    200,  // GUARD_TICKS → 200 그대로
    3,    // NODE_CNT   → 내부에서 2 저장, RTL 슬롯 0,1,2
    200,  // FAULT_TH
    200,  // SILENT_TH
    1     // ENABLE
);
```

---

## 7. AXI 레지스터 맵 (Master_v1_0_S00_AXI.v)

| 바이트 오프셋 | 내용 | R/W |
|--------------|------|-----|
| `0x00` | `[9:0]` DIV(N-1) \| `[19:10]` GUARD_TICKS \| `[22:20]` NODE_CNT(N-1) \| `[23]` ENABLE | R/W |
| `0x04` | `[2:0]` slot \| `[18:3]` clk_cnt \| `[19]` GPIO_in | R (상태) |
| `0x08` | `[7:0]` FAULT_TH \| `[15:8]` SILENT_TH \| `[23:16]` silent_flags \| `[31:24]` halt_flags | R/W |
| `0x0C~0x28` | err_cnt0~7 (NODE별, 4바이트씩) | R |
| `0x2C~0x48` | slot_out0~7 (NODE별, 4바이트씩) | R |
| `0x4C` | cycle_cnt[31:0] | R |
| `0x50` | cycle_cnt[63:32] | R |

`err_cnt` 구조: `[7:0]` silent_cnt \| `[15:8]` hamming_err_cnt \| `[23:16]` slot_timeout_cnt \| `[31:24]` preamble_err_cnt

---

## 8. main.c 기존 버그 (미수정)

### 버그 1 — ServiceRoutine 잘못된 오프셋

```c
// 현재 (잘못됨): offset 4 = 상태 레지스터 (slot/clk_cnt/GPIO_in)
u32 temp = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 4);

// 올바름: offset 8 = halt_flags/silent_flags/임계값
u32 temp = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 8);
```

### 버그 2 — READ_CYCLE_CNT 잘못된 오프셋

```c
// 현재 (잘못됨): 0x2C/0x30 = slot_out0/1
u32 low  = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0x2C);
u32 high = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0x30);

// 올바름: 0x4C/0x50 = cycle_cnt
u32 low  = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0x4C);
u32 high = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0x50);
```
