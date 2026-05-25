# master_tx.v — 한글 주석 설명서

## 모듈 역할

마스터가 TX 케이블을 통해 전체 슬레이브에게 NRZ 브로드캐스트 프레임을 송신한다.
특히 HALT_CMD 비트맵을 포함한 제어 프레임을 전송한다.

- **비트 타이밍**: 비트 주기 = `2*(DIV+1)` 클럭 (slave_tx와 동일)
- **프레임 구조**: `[preamble 8b = 0xAA][halt_cmd 8b][reserved 27b][hamming 7b]` = 50비트
- **Hamming 생성**: `{halt_cmd, 27'b0}` 35비트에 대한 SEC-DED 인코딩
- **Tristate 출력**: `tx_enable=0`이면 `tx_line = High-Z`

---

## 포트

| 포트 | 방향 | 설명 |
|------|------|------|
| `clk` | 입력 | 시스템 클럭 |
| `rst_n` | 입력 | 비동기 액티브-로우 리셋 |
| `div[9:0]` | 입력 | LINK_CFG.DIV (비트 타이밍 계산용) |
| `tx_trigger` | 입력 | 1클럭 펄스 → 브로드캐스트 시작 |
| `tx_enable` | 입력 | 0이면 High-Z 유지 |
| `halt_cmd[7:0]` | 입력 | HALT_CMD 필드. bit n=1이면 슬레이브 n에 중단 명령 |
| `tx_line` | 출력 | 마스터 TX 케이블 (tristate) |
| `tx_active` | 출력 | TX 진행 중 플래그 |
| `data_sent` | 출력 | TX 완료 1클럭 펄스 |

---

## slave_tx와의 구조적 차이

| 항목 | slave_tx | master_tx |
|------|----------|-----------|
| 35비트 데이터 | `{slave_addr, tx_data}` | `{halt_cmd, 27'b0}` |
| 프레임 | `{0xAA, addr, payload, hamming}` | `{0xAA, halt_cmd, 27'b0, hamming}` |
| 출력 선 | `rx_line` (공유 RX 버스) | `tx_line` (마스터 TX 케이블) |

로직 구조(Hamming 생성, TX 카운터, tristate)는 slave_tx와 동일.

---

## Hamming 생성 — 35비트 데이터 매핑

`d[34:0] = {halt_cmd[7:0], 27'b0}`

```
d[34] = halt_cmd[7] → Hamming 위치 3
d[33] = halt_cmd[6] → 위치 5
...
d[27] = halt_cmd[0] → 위치 12
d[26..0] = 0        → 위치 13~41 (모두 0)
```

reserved 필드가 모두 0이므로 p8~p32에 해당하는 패리티 계산이 단순화됨.

---

## TX 카운터 동작 (slave_tx와 동일)

```verilog
wire [10:0] cnt_max = {div, 1'b1}; // 2*DIV+1
```

1. `tx_trigger && tx_enable` → 프레임 래치, `tx_active=1`, `tx_bit=1`(0xAA MSB)
2. `tx_cnt`가 `cnt_max`에 도달할 때마다 다음 비트 전환
3. 50번째 비트 완료 → `tx_active=0`, `data_sent=1`

---

## Tristate 출력

```verilog
assign tx_line = (tx_active && tx_enable) ? tx_bit : 1'bz;
```

마스터는 TX 케이블을 단독으로 구동하므로 충돌 위험 없음.
미사용 시 High-Z 유지로 슬레이브의 active_edge 오인식 방지.

---

## 검증 방법 (TB)

`tb_master_tx.v`에서 `master_rx`를 루프백 연결하여 검증:
```
tx_line ──(pull-down)──► tx_line_sync → master_rx
```
- `bc_valid=1`, `bc_halt_cmd == halt_cmd` 확인
- `data_sent` 펄스 확인
