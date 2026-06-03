# TDMA Slave IP — 데이터시트

**버전**: 1.0  
**최종 수정**: 2026-06-01  
**검증 환경**: ModelSim Intel FPGA Edition 10.5b

---

## 1. 개요

`tdma_slave_top`은 TDMA(Time Division Multiple Access) 버스에 참여하는 슬레이브 노드 IP이다.  
두 개의 단방향 NRZ 버스를 통해 마스터와 통신하며, AXI-Lite 인터페이스로 프로세서(PS)에 제어/상태를 노출한다.

| 버스 | 방향 | 역할 |
|------|------|------|
| Bus A (`tx_line`) | Master → Slave | 마스터 브로드캐스트 수신 |
| Bus B (`rx_line`) | Slave → Master | 슬레이브 센서 데이터 송신 |

---

## 2. 시스템 구성

```
                      ┌─────────────────────────────────────────────┐
                      │              tdma_slave_top                  │
   AXI-Lite ──────────┤  regfile ◄────────────────────────────────  │
                      │     │                                        │
   tx_line ──[2-FF]──►│  master_rx ─► slot_timer ─► slave_tx ──────►│── rx_line
                      │     │              │                         │
                      │     └─► fault_fsm ─┘                        │
                      │              │                               │
                      │          irq_ctrl ──────────────────────────►│── irq
                      │                                              │
                      │  clk_div  (보조 클럭 틱)                     │
                      │  hamming_enc / hamming_dec  (조합회로)        │
                      └─────────────────────────────────────────────┘
```

---

## 3. 모듈 파라미터 및 포트

### 3.1 모듈 파라미터 (`tdma_slave_top`)

모든 정적 설정은 합성 시 파라미터로 고정한다. 인스턴스화 예:

```verilog
tdma_slave_top #(
    .DIV          (10'd8),   // 비트 주기: 8 클럭 = 12.5 Mbit/s @ 100 MHz
    .GUARD_TICKS  (10'd0),   // 슬롯 가드 타임
    .SLAVE_ADDR   (3'd2),    // 이 슬레이브의 TDMA 주소
    .FAULT_TH     (8'd30),
    .LINE_FAULT_TH(8'd30),
    .IRQ_MASK     (5'b00001) // data_sent IRQ 활성화
) u_slave (
    .clk(clk), .rst_n(rst_n),
    .enable(1'b1),
    .soft_rst(1'b0),
    .tx_data(sensor_data),
    .irq_clr(5'd0),
    .irq_status(irq_status),
    .fsm_state(fsm_state),
    .tx_line(bus_a_in),
    .rx_line(bus_b_out),
    .irq(irq_out)
);
```

| 파라미터 | 폭 | 기본값 | 설명 |
|---------|----|----|------|
| `DIV` | 10 | 8 | 비트 주기 = DIV 클럭 사이클 (마스터와 동일값 사용) |
| `GUARD_TICKS` | 10 | 0 | 슬롯 가드 타임 초기값; 브로드캐스트 수신 시 동적 갱신 |
| `SLAVE_ADDR` | 3 | 0 | TDMA 슬롯 주소 (0~7) |
| `FAULT_TH` | 8 | 30 | FAULT_CNT 임계값; 초과 시 DEAD 전이 |
| `LINE_FAULT_TH` | 8 | 30 | LINE_CNT 임계값; 초과 시 DEAD 전이 |
| `IRQ_MASK` | 5 | 5'b00001 | IRQ 마스크 (비트 정의는 §4.8 참조) |

### 3.2 포트 목록 (`tdma_slave_top`)

| 포트 | 방향 | 폭 | 설명 |
|------|------|----|------|
| `clk` | in | 1 | 시스템 클럭 |
| `rst_n` | in | 1 | 비동기 액티브-로우 리셋 |
| `enable` | in | 1 | 1: 정상 동작, 0: master_rx IDLE 유지 |
| `soft_rst` | in | 1 | 1-클럭 펄스: FSM/타이머 소프트 리셋 |
| `tx_data` | in | 32 | Bus B 송신 페이로드 (tx_trigger 시점에 래치) |
| `irq_clr` | in | 5 | W1C IRQ 클리어 (1클럭 펄스, 비트 정의는 irq_status와 동일) |
| `irq_status` | out | 5 | IRQ 상태 비트 (스티키, W1C) |
| `fsm_state` | out | 3 | 0=IDLE, 1=NORMAL, 2=DEAD |
| `tx_line` | in | 1 | Bus A 입력 (마스터→슬레이브 브로드캐스트) |
| `rx_line` | out | 1 | Bus B 출력 (슬레이브→마스터), 비전송 시 High-Z |
| `irq` | out | 1 | 인터럽트 출력 (액티브-하이, IRQ_MASK 적용 후) |

---

## 4. 런타임 제어 인터페이스

정적 설정(DIV, 주소, 임계값, IRQ 마스크)은 파라미터로 고정되며, 아래 포트를 통해 런타임 제어가 이루어진다.

### 4.1 enable

| 값 | 동작 |
|----|------|
| 1 | 정상 동작. master_rx가 Bus A를 수신하고 slot_timer가 tx_trigger를 생성 |
| 0 | master_rx를 IDLE에 고정. 브로드캐스트 수신 및 slave_tx 송신 중단 |

일반적으로 `1'b1`로 고정 연결한다.

### 4.2 soft_rst

1-클럭 폭의 펄스를 인가하면 내부 조합 리셋(`rst_int_n = rst_n & ~soft_rst`)이 발생한다.  
FSM, slot_timer, 카운터가 초기화된다. **regfile은 영향 없음** — `tx_data`와 파라미터 값은 유지된다.

```verilog
// 사용 예 (PL FSM에서)
@(posedge clk); soft_rst = 1;
@(posedge clk); soft_rst = 0;
```

### 4.3 tx_data

`tx_trigger` 시점에 `slave_tx` 내부에 래치된다. 마스터로 전송할 최신 센서 값을 유지하면 된다.

### 4.4 irq_status / irq_clr

`irq_status`는 스티키 비트로, 이벤트 발생 시 세트되고 `irq_clr`의 대응 비트를 1로 인가(1클럭 펄스)하면 클리어된다.

| 비트 | 이벤트 소스 |
|------|------------|
| [0] | `data_sent` — slave_tx 프레임 송신 완료 |
| [1] | `no_broadcast` — 워치독 타임아웃 (9 슬롯 주기 동안 브로드캐스트 없음) |
| [2] | `bc_hamming_err` — master_rx 2비트 해밍 오류 |
| [3] | `halt_cmd` — 브로드캐스트 HALT_CMD 수신 |
| [4] | `state_change` — fault_fsm 상태 전이 |

`irq = |(irq_status & IRQ_MASK_파라미터)`

```verilog
// IRQ 처리 예 (PL 로직)
if (irq) begin
    // irq_status 확인 후 처리
    irq_clr <= 5'h1F;  // 1클럭 후 자동으로 0으로 복귀 필요
end
```

### 4.5 fsm_state

| 값 | 상태 | 설명 |
|----|------|------|
| 3'd0 | IDLE | 브로드캐스트 미수신. tx 불가 |
| 3'd1 | NORMAL | 정상 동작. tx 허용 |
| 3'd2 | DEAD | 장애 감지. tx 불가. 하드웨어 리셋 필요 |

---

## 5. 통신 프로토콜

### 5.1 NRZ 인코딩

- 비트 주기: `DIV` 클럭 사이클
- 샘플 포인트: `DIV / 2` (중간점, 정수 나눗셈)
- 유휴 상태: 0 (Low)
- 프레임 시작: 첫 번째 비트가 1이므로 Rising edge로 감지

### 5.2 프레임 구조

Bus A와 Bus B 공통:

```
 ┌─────────────┬───────────────────────────────────┐
 │ Preamble    │       Hamming Codeword            │
 │  8 bits     │           42 bits                 │
 │  0xAA       │  {data[34:0], p[5:0], p_overall}  │
 └─────────────┴───────────────────────────────────┘
  MSB first                                 = 50 bits total
```

- **Bus A 데이터 필드** (35비트): `{halt_cmd[7:0], guard_ticks[9:0], 17'b0}`
- **Bus B 데이터 필드** (35비트): `{slave_addr[2:0], tx_data[31:0]}`

### 5.3 프레임 타이밍

| 파라미터 | 값 |
|---------|-----|
| 비트 주기 | `DIV` 클럭 |
| 프레임 기간 | `50 × DIV` 클럭 |
| 슬롯 주기 (`slot_ticks`) | `50 × DIV + guard_ticks` 클럭 |
| 슬레이브 N의 TX 오프셋 | `N × slot_ticks + guard_ticks / 2` 클럭 |
| 워치독 타임아웃 | `9 × slot_ticks` 클럭 |

> **설정 예시**: `DIV=8`, `guard_ticks=0`, `slave_addr=2`  
> → `slot_ticks=400`, TX 트리거: active_edge 기준 800 클럭 후

---

## 6. 해밍 코드 사양

**형식**: Systematic SEC-DED Hamming [42, 35]

| 항목 | 값 |
|------|-----|
| 데이터 비트 | 35비트 (`d[34:0]`) |
| 패리티 비트 | 6비트 (`p[5:0]`) |
| 전체 패리티 | 1비트 (`p_overall`) |
| 코드워드 | 42비트 (`codeword[41:0]`) |
| 오류 정정 | 1비트 단일 오류 정정 (SEC) |
| 오류 검출 | 2비트 이중 오류 검출 (DED) |

**코드워드 배치**:
```
codeword[41:7]  = data[34:0]   (데이터, MSB 먼저)
codeword[6:1]   = p[5:0]       (패리티)
codeword[0]     = p_overall    (전체 패리티)
```

**패리티 커버리지** (d 인덱스):

| 패리티 | 커버 범위 |
|--------|----------|
| p[0] | d[0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34] |
| p[1] | d[1,2,5,6,9,10,13,14,17,18,21,22,25,26,29,30,33,34] |
| p[2] | d[3,4,5,6,11,12,13,14,19,20,21,22,27,28,29,30] |
| p[3] | d[7,8,9,10,11,12,13,14,23,24,25,26,27,28,29,30] |
| p[4] | d[15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30] |
| p[5] | d[31,32,33,34] |

**복호 판정 로직**:

| syndrome | all_xor | 결과 |
|----------|---------|------|
| 0 | 0 | 오류 없음 |
| ≠0 | 1 | 1비트 오류 → 자동 정정 |
| ≠0 | 0 | 2비트 오류 → `ham_2bit_err=1` (데이터 무효) |
| 0 | 1 | p_overall 자체 오류 → 데이터 유효 (1비트 처리) |

---

## 7. 서브모듈 설명

### 7.1 master_rx

Bus A 수신기. NRZ 스트림에서 50비트 프레임을 복조·복호한다.

**동작 순서**:
1. IDLE: `tx_line_sync`의 Rising edge 감지 → `active_edge` 1클럭 펄스 발생, PREAMBLE 상태 이동
2. PREAMBLE: 8비트 샘플링. 8번째 샘플 시점에 `buffer[7:0]`이 `0xAA`이면 `bc_preamble_ok=1`, 아니면 `bc_preamble_err=1`
3. DATA: 42비트 코드워드 수신 → `hamming_dec`로 복호
4. 복호 완료:
   - 2비트 오류: `bc_hamming_err=1`
   - 정상/1비트 오류 수정: `bc_valid=1`, `bc_halt_cmd`, `bc_guard_ticks` 출력

> 모든 출력 신호는 **1클럭 펄스**. 래치는 상위 모듈에서 수행.

**2-FF 동기화**: `tx_line_sync`는 `tdma_slave_top`의 2-FF 동기화 체인 출력을 입력받음.

### 7.2 slave_tx

Bus B 송신기. 프레임 구성 후 NRZ 직렬 출력한다.

**동작 순서**:
1. `tx_trigger`와 `tx_enable`이 동시에 1일 때 프레임 래치 및 송신 시작
2. `{8'hAA, hamming_enc({slave_addr, tx_data})}` = 50비트 프레임을 MSB 먼저 출력
3. 마지막 비트 전송 후 `data_sent` 1클럭 펄스, `rx_line = 1'bz`로 복귀
4. `tx_enable=0`이면 `tx_trigger`가 와도 무시

**트라이스테이트 출력**: `rx_line`은 비전송 시 `1'bz`. 버스에 여러 슬레이브가 있을 경우 와이어드-OR 구성 가능.

### 7.3 slot_timer

active_edge 기준으로 각 슬레이브의 송신 타이밍을 결정한다.

```
slot_ticks = 50 × div + guard_ticks
trig_cnt   = slave_addr × slot_ticks + (guard_ticks >> 1)
wdog_cnt   = 9 × slot_ticks
```

- `tx_trigger`: `slot_cnt == trig_cnt` 시점에 1클럭 펄스
- `no_broadcast`: `slot_cnt == wdog_cnt` 도달 시 1클럭 펄스 (active_edge 없이 9 슬롯 경과)

### 7.4 fault_fsm

**상태 전이**:

```
      active_edge
IDLE ──────────────► NORMAL ──────────────► DEAD
                      tx_enable=1           tx_enable=0
                                            (복구 불가, HW 리셋 필요)
```

**NORMAL → DEAD 조건** (하나라도 충족 시):
- `halt_cmd = 1` (이 슬레이브 대상 정지 명령)
- `fault_cnt >= fault_th` (해밍 오류 누적)
- `line_cnt >= line_fault_th` (라인 오류 누적)

**카운터 동작**:

| 카운터 | 증가 조건 | 감소 조건 | 포화값 |
|--------|----------|----------|--------|
| FAULT_CNT | `bc_hamming_err`: +10, `halt_cmd`: 즉시 포화 | `bc_valid`: -1 | `fault_th` |
| LINE_CNT | `no_broadcast` or `bc_preamble_err`: +10 | `bc_preamble_ok`: -1 | `line_fault_th` |

### 7.5 irq_ctrl

5개 이벤트 소스를 스티키 비트로 래치하여 마스크된 `irq` 신호를 생성한다.

```
irq_status[n] = (irq_status[n] | event[n]) & ~irq_clr[n]
irq           = |(irq_status & irq_mask)
```

IRQ_STATUS(0x18)에 해당 비트를 1로 쓰면 클리어(W1C).

### 7.6 regfile

AXI-Lite 레지스터 파일. `awready=wready=arready=1` 상시 유지(단순화 구현).  
쓰기: `awvalid & wvalid` 동시 인가 시 처리.  
`soft_rst`는 1클럭 후 자동 클리어. `irq_clr`도 1클럭 펄스 후 자동 0.  
**regfile은 `rst_n`에 직접 연결** (soft_rst 미적용 — 레지스터 값 보존).

### 7.7 clk_div

보조 클럭 분주기. `clk_tick`은 `cnt == div`일 때 1클럭 펄스.  
현재 버전에서 `clk_tick`은 내부 배선은 되어 있으나 서브모듈에 직접 사용되지 않음.

### 7.8 hamming_enc / hamming_dec

순수 조합회로. 레지스터 없음.

- `hamming_enc`: `data[34:0]` → `codeword[41:0]`
- `hamming_dec`: `codeword[41:0]` → `data[34:0]`, `ham_1bit_err`, `ham_2bit_err`

---

## 8. 구동 절차

### 8.1 초기화 순서

```
1. 파라미터 결정 (합성 전):
   - DIV = 마스터 DIV와 동일하게 설정
   - SLAVE_ADDR = 이 노드의 TDMA 슬롯 번호
   - IRQ_MASK = 처리할 이벤트 비트 마스크

2. rst_n 해제 (최소 5 클럭 유지)

3. 포트 초기값 연결:
   - enable = 1'b1
   - soft_rst = 1'b0
   - tx_data = 최초 전송 데이터
   - irq_clr = 5'd0
```

### 8.2 정상 동작 흐름

```
① 마스터가 Bus A로 브로드캐스트 송신
② master_rx: active_edge 펄스 → fault_fsm NORMAL 전이 → slot_timer 카운트 시작
③ master_rx: bc_valid → guard_ticks_sync 업데이트 (GUARD_TICKS 파라미터 이후)
④ slot_timer: slot_cnt == trig_cnt 도달 → tx_trigger 펄스
⑤ slave_tx: tx_trigger & tx_enable → tx_data 래치 후 프레임 송신 시작
⑥ slave_tx: 50비트 전송 후 data_sent 펄스 → irq_ctrl → IRQ
⑦ PL 로직: IRQ 처리
    - irq_status 읽기 → 원인 확인
    - tx_data 업데이트 (다음 프레임 데이터)
    - irq_clr = 5'h1F (1클럭 펄스)
```

### 8.3 소프트 리셋

```
soft_rst = 1 (1클럭 펄스)
→ rst_int_n = 0 → FSM/카운터/슬롯타이머 초기화
→ 다음 클럭에 soft_rst = 0으로 복귀
※ tx_data, 파라미터 값은 영향 없음
```

### 8.4 HALT 및 DEAD 상태 복구

DEAD 상태는 자동 복구되지 않는다. 복구 방법:
- 하드웨어 리셋: `rst_n` Low 인가 (5 클럭 이상)
- 소프트 리셋: `soft_rst = 1` (1클럭 펄스)

---

## 9. 전기적 특성 / 타이밍 제약

| 파라미터 | 값 | 비고 |
|---------|-----|------|
| `tx_line` 메타스테빌리티 해소 | 2-FF 동기화 체인 | 2 클럭 지연 발생 |
| `rx_line` 출력 | 트라이스테이트 | 비전송 시 1'bz |
| 최소 DIV | 4 이상 권장 | 샘플 포인트 = DIV/2; DIV=2이면 여유 없음 |
| guard_ticks 최대 | 10비트 = 1023 클럭 | |
| slave_addr 범위 | 0 ~ 7 | 3비트 |

---

## 10. 소스 파일 목록

| 파일 | 역할 |
|------|------|
| `tdma_slave_top.v` | 최상위 래퍼 (파라미터 기반, AXI-Lite 없음) |
| `master_rx.v` | Bus A 수신기 |
| `slave_tx.v` | Bus B 송신기 |
| `slot_timer.v` | TDMA 슬롯 타이밍 생성기 |
| `fault_fsm.v` | 장애 상태 머신 |
| `irq_ctrl.v` | 인터럽트 컨트롤러 |
| `clk_div.v` | 클럭 분주기 |
| `hamming_enc.v` | Hamming [42,35] 인코더 |
| `hamming_dec.v` | Hamming [42,35] SEC-DED 복호기 |
| `sim_Master_tx.v` | 시뮬레이션용 마스터 송신기 (복사본) |
| `sim_Master_rx.v` | 시뮬레이션용 마스터 수신기 (복사본) |
| `sim_Master_dec_ham.v` | 시뮬레이션용 마스터 해밍 복호기 (복사본) |
| `tb_master_rx.v` | master_rx 단위 테스트 |
| `tb_slave_tx.v` | slave_tx 단위 테스트 |
| `tb_slot_timer.v` | slot_timer 단위 테스트 |
| `tb_tdma_slave_top.v` | tdma_slave_top 통합 테스트 |
| `tb_integration.v` | Master↔Slave 전체 통합 테스트 |
