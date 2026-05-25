# slave_tx.v — 한글 주석 설명서

## 모듈 역할

TDMA 슬레이브가 공유 RX 버스에 NRZ 프레임을 송신한다.

- **비트 타이밍**: 비트 주기 = `2*(DIV+1)` 클럭
- **프레임 구조**: `[preamble 8b = 0xAA][addr 3b][payload 32b][hamming 7b]` = 50비트
- **Hamming 생성**: `{slave_addr, tx_data}` 35비트에 대한 SEC-DED 인코딩
- **Tristate 출력**: `tx_enable=0` (FAULT/DEAD 상태)이면 `rx_line = High-Z`

---

## 포트

| 포트 | 방향 | 설명 |
|------|------|------|
| `clk` | 입력 | 시스템 클럭 |
| `rst_n` | 입력 | 비동기 액티브-로우 리셋 |
| `div[9:0]` | 입력 | LINK_CFG.DIV (비트 타이밍 계산용) |
| `tx_trigger` | 입력 | slot_timer 출력. 1클럭 펄스 → TX 시작 |
| `tx_enable` | 입력 | fault_fsm 출력. 0이면 High-Z 유지 (FAULT/DEAD) |
| `slave_addr[2:0]` | 입력 | 슬레이브 주소 (프레임 addr 필드에 삽입) |
| `tx_data[31:0]` | 입력 | 송신 페이로드 (tx_trigger 시점에 래치) |
| `rx_line` | 출력 | 공유 RX 버스 (tristate). 송신 중에만 구동 |
| `tx_active` | 출력 | TX 진행 중 플래그 |
| `data_sent` | 출력 | TX 완료 1클럭 펄스 |

---

## Hamming SEC-DED 생성 (조합 논리)

35비트 입력: `d[34:0] = {slave_addr[2:0], tx_data[31:0]}`

Hamming 위치 매핑 (1~41):
- 패리티 위치: 1, 2, 4, 8, 16, 32
- 데이터 위치: 3, 5-7, 9-15, 17-31, 33-41 (총 35개)

```
d[34] = addr[2]  → 위치 3
d[33] = addr[1]  → 위치 5
d[32] = addr[0]  → 위치 6
d[31] = pay[31]  → 위치 7
...
d[0]  = pay[0]   → 위치 41
```

각 패리티 비트 계산 (`XOR 트리`):
```
p1  = XOR(d[34], d[33], d[31], d[30], ..., d[0])  // 홀수 위치 비트
p2  = XOR(d[34], d[32], d[31], d[29], ..., d[2])  // 2의 배수 위치 비트
...
p32 = XOR(d[8], d[7], ..., d[0])                  // 위치 33~41 비트
```

41비트 코드워드 구성 후 전체 XOR:
```
p_overall = ^codeword41  // 전체 패리티
hamming[6:0] = {p1, p2, p4, p8, p16, p32, p_overall}  // p1 먼저 송신
```

---

## TX 타이밍 카운터

```verilog
wire [10:0] cnt_max = {div, 1'b1}; // 2*DIV+1 (주기 = 2*(DIV+1))
```

**TX 시작** (`tx_trigger && tx_enable`):
- 프레임 래치: `{8'hAA, slave_addr, tx_data, hamming}`
- `tx_active = 1`, `tx_bit = frame[49]` (preamble MSB = 1), `tx_cnt = 0`, `bit_cnt = 0`

**TX 진행 중**:
- `tx_cnt`: 매 클럭 +1, `cnt_max`에 도달하면 0 리셋 → 비트 주기 `2*(DIV+1)`
- `tx_cnt == cnt_max`가 되면 다음 비트로 이동: `bit_cnt++`, `tx_bit = frame[49 - bit_cnt]`

**TX 완료** (`bit_cnt == 49`이면서 `tx_cnt == cnt_max`):
- `tx_active = 0`, `data_sent = 1` (1클럭 펄스), `tx_bit = 0`

---

## Tristate 출력

```verilog
assign rx_line = (tx_active && tx_enable) ? tx_bit : 1'bz;
```

- 송신 중(`tx_active=1`)이고 허용 상태(`tx_enable=1`)일 때만 버스 구동
- 그 외(아이들, FAULT 상태)는 High-Z → 다른 슬레이브가 버스 사용 가능

---

## 프레임 비트 순서 (MSB first)

```
frame[49] = preamble[7] = 1  ← 첫 번째 송신
frame[48] = preamble[6] = 0
...
frame[42] = preamble[0] = 0
frame[41] = addr[2]
...
frame[39] = addr[0]
frame[38] = tx_data[31]
...
frame[7]  = tx_data[0]
frame[6]  = p1          ← Hamming 시작
...
frame[0]  = p_overall   ← 마지막 송신
```
