# master_rx.v — 한글 주석 설명서

## 모듈 역할

마스터가 TX 케이블로 브로드캐스트하는 NRZ 프레임을 수신하고 파싱한다.

- **비트 타이밍**: 비트 주기 = `2*(DIV+1)` 클럭, 샘플 포인트 = `DIV+1` 클럭 (중간점)
- **프레임 구조**: `[preamble 8b = 0xAA][halt_cmd 8b][reserved 27b][hamming 7b]` = 50비트
- **Hamming**: 35비트 데이터(halt_cmd + reserved)에 대한 SEC-DED 검증
- **출력**: `active_edge`(슬롯 타이머 기준), `bc_valid`(유효 수신), `bc_halt_cmd`, 오류 플래그

---

## 포트

| 포트 | 방향 | 설명 |
|------|------|------|
| `clk` | 입력 | 시스템 클럭 |
| `rst_n` | 입력 | 비동기 액티브-로우 리셋 |
| `enable` | 입력 | CTRL.ENABLE. 0이면 IDLE 강제 유지 |
| `div[9:0]` | 입력 | LINK_CFG.DIV (비트 타이밍 계산용) |
| `tx_line_sync` | 입력 | 마스터 TX 라인 (2-FF 동기화 후 입력) |
| `active_edge` | 출력 | 아이들(0) → HIGH 상승 에지 감지 시 1클럭 펄스 |
| `bc_valid` | 출력 | 유효 브로드캐스트 수신 펄스 (preamble OK + Hamming 오류 없음/1비트 정정) |
| `bc_preamble_ok` | 출력 | preamble 0xAA 수신 성공 펄스 |
| `bc_halt_cmd[7:0]` | 출력 | 수신된 HALT_CMD 필드 |
| `bc_hamming_err` | 출력 | Hamming 2비트 오류 감지 펄스 |
| `bc_preamble_err` | 출력 | preamble 불일치 펄스 |

---

## 상태 머신 (3상태)

```
IDLE  ──(active_edge)──▶  PREAMBLE  ──(8 samples)──▶  DATA  ──(42 samples)──▶  IDLE
```

| 상태 | 동작 |
|------|------|
| `IDLE` | tx_line_sync 0→1 상승 에지 대기. 감지 시 active_edge 출력 + PREAMBLE 전이 |
| `PREAMBLE` | 8비트 수집 (매 샘플 포인트마다). 완료 시 buffer[7:0]으로 0xAA 검증 |
| `DATA` | 42비트 수집 (매 샘플 포인트마다). 완료 시 Hamming 검증 후 출력 |

---

## 비트 타이밍 카운터 (clk_cnt)

```verilog
wire [10:0] cnt_max    = {div, 1'b1};          // 2*DIV+1 (주기 = 2*(DIV+1))
wire [10:0] samp_point = {1'b0, div} + 11'd1; // DIV+1 (비트 중간점 샘플)
wire        at_sample  = (clk_cnt == samp_point);
```

- IDLE에서 상승 에지 감지 시 `clk_cnt = 1`로 시작
- PREAMBLE/DATA에서 `cnt_max`에 도달하면 0으로 리셋 → 주기 유지
- `at_sample`이 HIGH인 클럭에서 `tx_line_sync` 샘플링

---

## 버퍼 동작 (42비트 좌시프트)

```verilog
buffer <= {buffer[40:0], tx_line_sync}; // 매 at_sample마다 MSB first로 수신
```

- PREAMBLE에서 8번 시프트: `buffer[7:0]` = 수신 preamble
- DATA에서 42번 시프트: `buffer[41:7]` = 35비트 데이터, `buffer[6:0]` = 7비트 Hamming

---

## preamble 검증 (PREAMBLE 상태, bit_cnt==8)

```verilog
if (buffer[7:0] == 8'hAA) begin
    bc_preamble_ok    <= 1'b1;  // LINE_CNT 감소 트리거
    preamble_ok_latch <= 1'b1;
end else begin
    bc_preamble_err   <= 1'b1;  // LINE_CNT 증가 트리거
end
```

---

## Hamming SEC-DED 검증 (DATA 상태, bit_cnt==41)

```
buffer[41:7]  = rx_data[34:0] = {halt_cmd[7:0], 27'b0}
buffer[6:0]   = rx_hamming[6:0]
  [6]=p1, [5]=p2, [4]=p4, [3]=p8, [2]=p16, [1]=p32, [0]=p_overall
```

Hamming 위치(1~41)에 대한 syndrome 계산:
- `s1~s32`: 각 패리티 비트와 해당 위치의 데이터 XOR
- `syndrome = {s32, s16, s8, s4, s2, s1}`
- `all_xor = ^buffer` (42비트 전체 XOR)

| syndrome | all_xor | 판정 |
|----------|---------|------|
| 0 | 0 | 오류 없음 → bc_valid=1 |
| ≠0 | ≠0 | 1비트 오류 → 자동 정정, bc_valid=1 |
| ≠0 | 0 | **2비트 오류** → bc_hamming_err=1 |
| 0 | ≠0 | (전체 패리티 비트 1비트 오류) → bc_valid=1 |

> 2비트 오류 조건: `h_2bit_err = (syndrome != 0) && (all_xor == 0)`

---

## 출력 레지스터 (1클럭 펄스)

- 모든 출력(`active_edge`, `bc_valid`, `bc_preamble_ok`, `bc_hamming_err`, `bc_preamble_err`)은 매 클럭 0으로 초기화 후 해당 조건에서 1클럭만 HIGH
- `bc_halt_cmd[7:0]`: DATA 완료 시점에 래치 (`buffer[41:34]`)
