# fault_fsm.v — 한글 주석 설명서

## 모듈 역할

TDMA 슬레이브의 고장(Fault) 상태 머신을 구현한다.
수신 이벤트를 분석하여 슬레이브의 동작 상태를 결정하고 TX 허가 신호를 생성한다.

**5개 상태**: IDLE(000) → NORMAL(001) ↔ DATA_RECOVERY(010) ↔ FAULT(011), DEAD(100)

---

## 포트

| 포트 | 방향 | 설명 |
|------|------|------|
| `clk` | 입력 | 시스템 클럭 |
| `rst_n` | 입력 | 비동기 액티브-로우 리셋 |
| `fault_th[7:0]` | 입력 | FAULT_CFG.FAULT_TH. FAULT_CNT 상한 임계값 (기본 30) |
| `line_fault_th[7:0]` | 입력 | FAULT_CFG.LINE_FAULT_TH. LINE_CNT 상한 임계값 (기본 30) |
| `active_edge` | 입력 | 마스터 브로드캐스트 첫 상승 에지. IDLE→NORMAL 전이 트리거 |
| `bc_valid` | 입력 | 유효 브로드캐스트 수신. FAULT_CNT -1 트리거 |
| `bc_preamble_ok` | 입력 | preamble 유효 수신. LINE_CNT -1 트리거 |
| `bc_hamming_err` | 입력 | Hamming 2비트 오류. FAULT_CNT +10 |
| `bc_preamble_err` | 입력 | preamble 불일치. LINE_CNT +10 |
| `no_broadcast` | 입력 | 브로드캐스트 타임아웃. LINE_CNT +10 |
| `halt_cmd` | 입력 | 자신의 HALT_CMD 비트=1. FAULT_CNT를 fault_th로 즉시 포화 |
| `tx_enable` | 출력 | 1 = TX 허가 (NORMAL/DATA_RECOVERY), 0 = High-Z 유지 |
| `state_change` | 출력 | 상태 전이 발생 시 1클럭 펄스 (IRQ 트리거용) |
| `fsm_state[2:0]` | 출력 | 현재 상태 → STATUS 레지스터 |
| `fault_cnt_out[7:0]` | 출력 | FAULT_CNT 현재값 → STATUS 레지스터 |
| `line_cnt_out[7:0]` | 출력 | LINE_CNT 현재값 → STATUS 레지스터 |

---

## 카운터 동작 규칙 (+10 / -1 포화 구조)

### FAULT_CNT

| 이벤트 | 동작 |
|--------|------|
| `halt_cmd = 1` | `fault_cnt = fault_th` (즉시 포화, 카운터 무관 FAULT 진입 강제) |
| `bc_hamming_err = 1` | `fault_cnt = min(fault_cnt + 10, fault_th)` |
| `bc_valid = 1` | `fault_cnt = max(fault_cnt - 1, 0)` |

`halt_cmd`가 최우선 — 올바른 브로드캐스트를 받아도 halt_cmd가 1이면 -1 적용 없음.

### LINE_CNT

| 이벤트 | 동작 |
|--------|------|
| `no_broadcast = 1` 또는 `bc_preamble_err = 1` | `line_cnt = min(line_cnt + 10, line_fault_th)` |
| `bc_preamble_ok = 1` | `line_cnt = max(line_cnt - 1, 0)` |

---

## 상태 전이 (우선순위: DEAD > FAULT > 나머지)

```
IDLE
  └─(active_edge)──────────────────────────────────▶ NORMAL

NORMAL
  ├─(line_cnt ≥ line_fault_th)───────────────────▶ DEAD
  ├─(halt_cmd OR fault_cnt ≥ fault_th)────────────▶ FAULT
  └─(fault_cnt > 0)────────────────────────────────▶ DATA_RECOVERY (*)

DATA_RECOVERY
  ├─(line_cnt ≥ line_fault_th)───────────────────▶ DEAD
  ├─(halt_cmd OR fault_cnt ≥ fault_th)────────────▶ FAULT
  └─(fault_cnt == 0)───────────────────────────────▶ NORMAL

FAULT
  ├─(line_cnt ≥ line_fault_th)───────────────────▶ DEAD
  └─(fault_cnt < fault_th)─────────────────────────▶ DATA_RECOVERY

DEAD
  └─(line_cnt == 0)────────────────────────────────▶ IDLE (**)
```

> (*) 스펙과 차이: 스펙은 NORMAL → DATA_RECOVERY 직접 전이 없음 (DATA_RECOVERY는 FAULT 이후에만 진입 가능). 구현에서는 fault_cnt > 0이면 NORMAL에서 바로 DATA_RECOVERY로 전이.
>
> (**) 스펙과 차이: 스펙은 DEAD → NORMAL 전이. 구현은 DEAD → IDLE 전이 후 다음 active_edge를 기다려야 NORMAL 진입.

---

## tx_enable 출력

```verilog
tx_enable <= (fsm_state == NORMAL || fsm_state == DATA_RECOVERY);
```

- `NORMAL`, `DATA_RECOVERY` 상태에서만 1 → slave_tx가 버스 구동
- `IDLE`, `FAULT`, `DEAD` 상태에서 0 → slave_tx High-Z 유지

> `tx_enable`은 `fsm_state`와 같은 클럭에 갱신되지만 조합 논리가 아닌 FF 출력.
> 실제 효과는 1클럭 후 (`fsm_state` 업데이트 다음 사이클부터 적용).

---

## state_change 출력

상태 전이가 발생한 클럭에 1을 출력, 다음 클럭에 자동으로 0.
`irq_ctrl`의 `state_change` 입력으로 연결되어 IRQ_STATUS[4]를 세팅.

---

## 카운터 포화 처리 (오버플로 방지)

```verilog
// 9비트 확장으로 오버플로 없이 비교
fault_cnt <= ({1'b0, fault_cnt} + 9'd10 >= {1'b0, fault_th})
             ? fault_th : fault_cnt + 8'd10;
```

8비트 + 8비트 덧셈 시 `fault_cnt = 250`인 경우 `+10`이 오버플로(260 > 255)가 되므로,
9비트로 확장하여 임계값과 비교 후 포화.
