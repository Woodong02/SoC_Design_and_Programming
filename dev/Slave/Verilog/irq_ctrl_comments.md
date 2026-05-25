# irq_ctrl.v — 한글 주석 설명서

## 모듈 역할

이벤트 펄스를 IRQ_STATUS 레지스터에 래치하고, IRQ_MASK와 AND하여 `irq` 핀을 구동한다.

- **5개 이벤트**: data_sent, no_broadcast, bc_hamming_err, halt_cmd, state_change
- **W1C(Write-1-to-Clear)**: `irq_clr` 신호로 각 비트를 개별 클리어
- **Level IRQ**: `irq = |(irq_status & irq_mask)` — 레벨 방식, 상위에서 관리

---

## 포트

| 포트 | 방향 | 설명 |
|------|------|------|
| `clk` | 입력 | 시스템 클럭 |
| `rst_n` | 입력 | 비동기 액티브-로우 리셋 |
| `data_sent` | 입력 | slave_tx TX 완료 펄스 |
| `no_broadcast` | 입력 | slot_timer 브로드캐스트 타임아웃 펄스 |
| `bc_hamming_err` | 입력 | master_rx Hamming 2비트 오류 펄스 |
| `halt_cmd` | 입력 | 자신의 HALT_CMD 비트 (bc_halt_cmd[slave_addr]) |
| `state_change` | 입력 | fault_fsm 상태 전이 펄스 |
| `irq_clr[4:0]` | 입력 | regfile에서 W1C 펄스. 1이면 해당 비트 클리어 |
| `irq_mask[4:0]` | 입력 | IRQ_MASK 레지스터 (1이면 해당 이벤트 IRQ 활성화) |
| `irq_status[4:0]` | 출력 | IRQ_STATUS 레지스터 (regfile readback용) |
| `irq` | 출력 | 인터럽트 핀 (레벨, 액티브-하이) |

---

## IRQ_STATUS 비트 매핑

| 비트 | 이벤트 | 설명 |
|------|--------|------|
| [0] | `data_sent` | 슬레이브 TX 1프레임 완료 |
| [1] | `no_broadcast` | 마스터 브로드캐스트 타임아웃 |
| [2] | `bc_hamming_err` | 수신 Hamming 2비트 오류 |
| [3] | `halt_cmd` | 마스터로부터 중단 명령 수신 |
| [4] | `state_change` | fault_fsm 상태 전이 발생 |

---

## 핵심 로직 — 셋/클리어 우선순위

```verilog
irq_status[0] <= (irq_status[0] | data_sent) & ~irq_clr[0];
```

| 상황 | 결과 |
|------|------|
| `data_sent=1, irq_clr[0]=0` | 비트 세팅 (1) |
| `data_sent=0, irq_clr[0]=1` | 비트 클리어 (0) |
| `data_sent=1, irq_clr[0]=1` | **클리어 우선** — 새 이벤트 발생과 동시에 클리어 시 0 유지 |
| `data_sent=0, irq_clr[0]=0` | 이전 상태 유지 |

**동작 설명**: `(old | event) & ~clr`
- 이벤트 펄스가 들어오면 기존 값과 OR → 비트 세팅
- irq_clr 비트가 1이면 AND NOT → 비트 클리어
- 두 조건이 동시 발생 시 클리어가 우선

---

## irq 출력 (조합 논리)

```verilog
assign irq = |(irq_status & irq_mask);
```

- `irq_status`와 `irq_mask`의 AND를 OR 감소 → 레벨 IRQ
- 마스크된 이벤트 중 하나라도 세팅되어 있으면 `irq=1`
- PS(ARM 프로세서)가 IRQ_STATUS를 W1C 클리어해야 irq가 해제됨

---

## irq_clr 동작 (regfile과의 연계)

```
PS가 IRQ_STATUS(0x18)에 W1C 쓰기
  → regfile이 1클럭 동안 irq_clr[i]=1 출력
  → irq_ctrl이 해당 비트 클리어
  → 다음 클럭에 irq_clr는 자동으로 0으로 돌아감 (regfile에서 처리)
```
