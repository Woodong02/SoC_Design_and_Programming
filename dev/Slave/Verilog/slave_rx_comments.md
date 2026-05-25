# slave_rx.v — 한글 주석 설명서

## 모듈 역할

마스터 측에서 공유 RX 버스로 수신된 슬레이브 데이터 프레임을 파싱한다.
`master_rx`의 대칭 모듈로, 프레임 포맷만 슬레이브 프레임 기준으로 다르다.

- **비트 타이밍**: 비트 주기 = `2*(DIV+1)` 클럭, 샘플 포인트 = `DIV+1` (master_rx와 동일)
- **프레임 구조**: `[preamble 8b = 0xAA][addr 3b][payload 32b][hamming 7b]` = 50비트
- **Hamming**: `{addr, payload}` 35비트에 대한 SEC-DED 검증

---

## 포트

| 포트 | 방향 | 설명 |
|------|------|------|
| `clk` | 입력 | 시스템 클럭 |
| `rst_n` | 입력 | 비동기 액티브-로우 리셋 |
| `enable` | 입력 | 0이면 IDLE 강제 유지 |
| `div[9:0]` | 입력 | LINK_CFG.DIV |
| `rx_line_sync` | 입력 | 공유 RX 버스 (2-FF 동기화 후 입력) |
| `active_edge` | 출력 | 슬레이브 프레임 시작 감지 펄스 |
| `frame_valid` | 출력 | 유효 슬레이브 프레임 수신 펄스 |
| `frame_addr[2:0]` | 출력 | 수신된 슬레이브 주소 |
| `frame_data[31:0]` | 출력 | 수신된 페이로드 데이터 |
| `hamming_err` | 출력 | Hamming 2비트 오류 감지 펄스 |
| `preamble_err` | 출력 | preamble 불일치 펄스 |
| `preamble_ok` | 출력 | preamble 0xAA 수신 성공 펄스 |

---

## master_rx와의 구조적 차이

| 항목 | master_rx (브로드캐스트 수신) | slave_rx (슬레이브 데이터 수신) |
|------|------------------------------|--------------------------------|
| 입력 선 | `tx_line_sync` | `rx_line_sync` |
| 35비트 데이터 | `{halt_cmd, 27'b0}` | `{addr[2:0], payload[31:0]}` |
| 출력 | `bc_halt_cmd[7:0]` | `frame_addr[2:0]`, `frame_data[31:0]` |

Hamming syndrome 계산 공식은 완전히 동일 (35비트 → 41비트 코드워드 동일 구조).

---

## 버퍼 필드 매핑 (42번 시프트 후)

```
buffer[41:0]  (42비트, MSB first)
  ├─ buffer[41:39] = frame_addr[2:0]   ← 슬레이브 주소
  ├─ buffer[38:7]  = frame_data[31:0]  ← 페이로드 데이터
  └─ buffer[6:0]   = rx_hamming[6:0]   ← 7비트 Hamming
       [6]=p1, [5]=p2, [4]=p4, [3]=p8, [2]=p16, [1]=p32, [0]=p_overall
```

---

## 출력 래치 (DATA 상태 완료 시)

```verilog
if (state == DATA && at_sample && bit_cnt == 6'd41) begin
    if (h_2bit_err) begin
        hamming_err <= 1'b1;
    end else if (preamble_ok_latch) begin
        frame_valid <= 1'b1;
        frame_addr  <= buffer[41:39];   // 슬레이브 주소 추출
        frame_data  <= buffer[38:7];    // 페이로드 추출
    end
end
```

---

## Hamming syndrome 계산 (master_rx와 동일)

`rx_data[34:0] = buffer[41:7] = {addr[2:0], payload[31:0]}`

- `syndrome = {s32, s16, s8, s4, s2, s1}`
- `all_xor = ^buffer` (42비트 전체 XOR)
- `h_2bit_err = (syndrome != 0) && (all_xor == 0)` → 2비트 오류

---

## 상태 머신 (master_rx와 동일 구조)

```
IDLE ──(rx_line 0→1)──▶ PREAMBLE ──(8 samples)──▶ DATA ──(42 samples)──▶ IDLE
```

- `active_edge`: IDLE에서 `!rx_prev && rx_line_sync` 감지 시 1클럭 펄스
- PREAMBLE: 8비트 수집 후 `buffer[7:0] == 8'hAA` 검증
- DATA: 42비트 수집 후 Hamming 검증 및 필드 추출
