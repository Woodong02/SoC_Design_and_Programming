# TDMA IP — 내고장성 설계 결정

> 버전: 0.3
> 작성일: 2026-05-21

---

## 1. Fault 분류 체계

### 1.1 마스터 도메인 / 슬레이브 도메인 분리

마스터와 슬레이브는 감지 대상과 역할이 다르므로 fault 체계를 독립적으로 설계한다.

- **마스터**: 슬레이브 n별로 독립적인 fault 상태 머신을 운용한다 (최대 8개).
- **슬레이브**: 자기 자신에 대한 단일 fault 상태 머신을 운용한다.

### 1.2 Fault 종류

**마스터 도메인** (슬레이브 n에 대해 마스터가 감지):

| Fault          | 감지 조건                                                  | 분류                                        |
| -------------- | ------------------------------------------------------ | ----------------------------------------- |
| `LINE_FAULT`   | 공유 RX 버스에서 preamble(0x55) 미검출이 LINE_RECOVERY_TH회 연속 누적 | 카운터 도달 시 즉시 격리. PS 인터럽트 플래그 세팅            |
| `FRAME_ERR`    | 프레임 구조 오류                                              | FAULT_CNT 누적                              |
| `HAMMING_ERR`  | Hamming 2비트 오류 (정정 불가)                                 | FAULT_CNT 누적                              |
| `ADDR_ERR`     | addr 필드가 슬롯 번호와 불일치. 슬롯 점유자(B)가 침묵된 후 침범 슬레이브(A) 단독 전송 확인 | 즉시 격리. addr 필드에 식별된 슬레이브(A)에 HALT_CMD 자동 세팅. FAULT_CNT 누적 없음 |
| `SLOT_TIMEOUT` | RX 윈도우 내 아무것도 수신 안 됨                                   | FAULT_CNT 누적                              |
| `SYNC_FAULT`   | `\|offset[n][k]\| > GUARD_TICKS / 4`                   | SYNC_FAULT_CNT 누적                         |
| `CLOCK_FAULT`  | `\|offset[n][k]\| > GUARD_TICKS / 2`                   | SYNC_FAULT_CNT 누적 후 즉시 격리. HALT_CMD 자동 세팅 |

공유 RX 버스에서 LINE_FAULT는 버스 전체에 영향을 미친다. 버스 단절·단락 등 물리적 장애가 발생하면 모든 슬레이브 슬롯이 동시에 preamble 미검출로 나타나므로, 이 패턴으로 개별 슬레이브 장애와 버스 수준 장애를 구분할 수 있다. LINE_RECOVERY_TH회 연속 미검출 시 격리하며, 복구도 LINE_RECOVERY_TH 연속 유효 preamble 수신으로 동일하게 적용한다.

`FRAME_ERR`, `HAMMING_ERR`, `SLOT_TIMEOUT`은 성격이 동일하므로 **공통 FAULT_CNT**로 통합한다. 개별 오류 종류는 상태 레지스터에 별도 플래그로 기록한다.

`ADDR_ERR` 발생 시나리오: 슬레이브 A가 슬롯 B를 침범하면 두 슬레이브가 동시에 공유 버스를 구동하여 Hamming 오류가 발생한다. 마스터는 이를 슬롯 B의 FAULT_CNT로 누적하고, 임계치 도달 시 HALT_CMD[B]를 발행한다. 슬레이브 B가 침묵한 이후에야 슬롯 B에서 슬레이브 A 단독 전송이 이루어지며, 이때 addr 불일치가 명확하게 감지된다. ADDR_ERR 감지 시 FAULT_CNT 누적 없이 addr 필드에 표시된 슬레이브(A)에 즉시 HALT_CMD를 세팅한다. 침범이 확인된 상황이므로 카운터 누적 없이 즉각 격리한다.

`HAMMING_ERR`(Hamming 2비트 오류)은 데이터 손상임과 동시에 슬롯 타이밍 침범을 함의한다. 공유 버스에서 슬롯 침범이 발생하면 비트 경계가 어긋나 다중 비트 오류로 나타나기 때문이다.

CLOCK_FAULT 조건(`|offset| > GUARD_TICKS/2`)은 반드시 SYNC_FAULT 조건도 만족한다. 이 경우 SYNC_FAULT_CNT를 먼저 증가시킨 후 CLOCK_FAULT로 즉시 전환한다. CLOCK_FAULT 복구(PS 리셋) 시 SYNC_FAULT_CNT도 함께 초기화한다.

**슬레이브 도메인** (슬레이브 자신이 감지):

| Fault | 감지 조건 | 분류 |
|-------|----------|------|
| `SYNC_FAULT` | `\|offset[k]\| > GUARD_TICKS / 4` | 자율 처리 (PAUSE 1사이클, 공유 버스 오염 방지) |
| `SYNC_MISS` | 예상 사이클 내 마스터 브로드캐스트 미수신 | FAULT_CNT 누적 |
| `BROADCAST_HAMMING_ERR` | 마스터 브로드캐스트 Hamming 2비트 오류 | FAULT_CNT 누적 |
| `LINE_FAULT` | 마스터 TX 라인 preamble(0x55) 미검출 LINE_RECOVERY_TH회 연속 | 카운터 도달 시 즉시 격리 |
| `HALT_CMD` | 마스터 브로드캐스트 HALT_CMD 필드에서 자신의 비트가 1 | 즉시 전송 중단 (공유 버스 해제) |

`SYNC_MISS`와 `BROADCAST_HAMMING_ERR`은 **공통 FAULT_CNT**로 통합한다.

`HALT_CMD`는 fault 카운터와 무관하게 마스터 HW의 명시적 중단 명령이다. 슬레이브는 해당 비트를 감지하면 즉시 전송을 중단하고 공유 RX 버스를 High-Z로 해제한 뒤 FAULT 상태로 진입한다. HALT_CMD 비트가 1인 브로드캐스트는 유효 브로드캐스트로 인정하지 않아 RECOVERY 진입 조건을 충족하지 못한다. HALT_CMD 반영은 마스터 레지스터 갱신 후 다음 브로드캐스트 사이클에 적용되며 최대 1사이클 지연이 발생한다(허용됨).

---

## 2. Fault 우선순위

동시에 여러 fault가 발생할 경우 아래 우선순위를 따른다.

```
CLOCK_FAULT > LINE_FAULT > SYNC_FAULT > DATA_FAULT
```

근거:
- `CLOCK_FAULT`: 클럭 자체가 근본적으로 불일치. 라인이 복구되어도 클럭이 망가져 있으면 의미 없음. 공유 버스 오염 즉각 차단 필요.
- `LINE_FAULT`: 물리 계층 이상. 공유 버스 전체가 영향받으므로 상위 계층 fault보다 우선.
- `SYNC_FAULT`: TDMA는 슬롯 타이밍 침범 방지가 최우선. 공유 버스에서 슬롯 침범은 다른 슬레이브 데이터를 손상시킴.
- `DATA_FAULT`: 가장 낮은 우선순위.

---

## 3. FAULT_CNT 동작 규칙

마스터와 슬레이브 모두 아래 규칙을 따른다.

| 이벤트 | FAULT_CNT | SYNC_FAULT_CNT |
|--------|-----------|----------------|
| 데이터 오류 발생 | `++` | 변화 없음 |
| 오프셋 경고 발생 | 변화 없음 | `++` |
| 정상 수신 | 변화 없음 | 변화 없음 |
| NORMAL 복귀 | 초기화 | 초기화 |
| CLOCK_FAULT PS 리셋 | 초기화 | 초기화 |

보수적 설계로 일시적 성공이 누적 오류를 희석시키지 않는다. Hamming 1비트 자동 정정은 정상 수신으로 간주하며 FAULT_CNT를 증가시키지 않는다.

---

## 4. 마스터 도메인 상태 머신 (슬레이브 n별)

### 상태 목록

| 상태 | 설명 |
|------|------|
| `NORMAL` | 정상 동작 |
| `DATA_FAULT` | FAULT_CNT >= FAULT_TH, 데이터 수신 격리 |
| `DATA_RECOVERY` | 데이터 복구 확인 중 |
| `SYNC_FAULT` | SYNC_FAULT_CNT >= SYNC_FAULT_TH, 동기 격리 |
| `SYNC_RECOVERY` | 동기 복구 확인 중 |
| `LINE_FAULT` | 공유 RX 버스 이상, 격리 |
| `CLOCK_FAULT` | 클럭 근본 불일치, 영구 격리, HALT_CMD 자동 세팅 |

### 상태 전이

```
┌──────────────────────────────────────────────────────────────────┐
│  어느 상태에서든 |offset|>GUARD_TICKS/2 → SYNC_FAULT_CNT++ 후   │
│  CLOCK_FAULT 즉시 진입. HALT_CMD 비트 자동 세팅.                 │
│  (공유 버스에서 슬레이브 즉각 격리 및 버스 해제)                  │
│  PS 명시적 클리어만 복구 가능. 복구 시 SYNC_FAULT_CNT 초기화.   │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  CLOCK_FAULT 제외, 어느 상태에서든 LINE_FAULT 감지               │
│  (공유 RX 버스 preamble 미검출 LINE_RECOVERY_TH회 연속)          │
│  → LINE_FAULT 진입. PS 인터럽트 플래그 세팅.                     │
│  LINE_RECOVERY_TH 연속 유효 preamble → NORMAL (카운터 초기화)   │
└──────────────────────────────────────────────────────────────────┘

NORMAL
  ├─(FAULT_CNT >= FAULT_TH)──────────────▶ DATA_FAULT
  └─(SYNC_FAULT_CNT >= SYNC_FAULT_TH)───▶ SYNC_FAULT

DATA_FAULT
  ├─(SYNC_FAULT_CNT >= SYNC_FAULT_TH)───▶ SYNC_FAULT  ← 격상
  └─(슬레이브 재개 감지)─────────────────▶ DATA_RECOVERY
        DATA_RECOVERY
          ├─(RECOVERY_TH 연속 정상 수신)──▶ NORMAL
          └─(오류 재발생)─────────────────▶ DATA_FAULT

SYNC_FAULT
  └─(|offset| 정상 복귀)──────────────────▶ SYNC_RECOVERY
        SYNC_RECOVERY
          ├─(SYNC_RECOVERY_TH 연속        ▶ NORMAL (CNT 초기화)
             |offset|<=GUARD_TICKS/4)
          └─(|offset| 재초과)──────────────▶ SYNC_FAULT
```

DATA_RECOVERY에서 "정상 수신"이란 FRAME_ERR, HAMMING_ERR, SLOT_TIMEOUT 없이 프레임을 수신한 경우를 말한다. Hamming 1비트 자동 정정은 정상 수신으로 간주한다. ADDR_ERR는 별도 즉각 격리 경로를 따르므로 DATA_RECOVERY 판정에 포함하지 않는다.

### 격리 상태에서 마스터 동작

| 상태 | 슬롯 유지 | 데이터 수락 | 오프셋 계산 | HALT_CMD |
|------|----------|------------|------------|---------|
| DATA_FAULT | ✓ | ✗ | ✓ (복구 감시) | PS 제어 |
| DATA_RECOVERY | ✓ | 조건부 | ✓ | ✗ |
| SYNC_FAULT | ✓ | ✗ | ✓ (복구 감시) | PS 제어 |
| SYNC_RECOVERY | ✓ | 조건부 | ✓ | ✗ |
| LINE_FAULT | ✓ | ✗ | ✗ | ✗ |
| CLOCK_FAULT | ✓ | ✗ | ✗ | HW 자동 세팅 |

슬롯은 어느 fault 상태에서도 사이클에서 제거하지 않는다. 공유 버스에서 슬롯 구조를 변경하면 전 슬레이브의 타이밍이 흔들리기 때문이다.

CLOCK_FAULT 상태에서는 HW가 해당 슬레이브의 HALT_CMD 비트를 자동으로 1로 세팅하여 브로드캐스트에 실어 보낸다. 슬레이브는 HALT_CMD를 수신하는 즉시 공유 버스 구동을 중단(High-Z 전환)한다. 그 외 fault 상태에서는 PS가 HALT_CMD 레지스터를 직접 제어한다.

---

## 5. 슬레이브 도메인 상태 머신

### 상태 목록

| 상태 | 설명 |
|------|------|
| `NORMAL` | 정상 동작, 매 슬롯 전송, 오프셋 보정 |
| `PAUSE` | SYNC_FAULT 자율 감지, 1사이클 전송 중단 후 자동 복귀 (공유 버스 오염 방지) |
| `FAULT` | FAULT_CNT >= FAULT_TH 또는 HALT_CMD 수신, 전송 중단 및 버스 High-Z 유지 |
| `RECOVERY` | 복구 확인 중 |
| `DEAD` | LINE_FAULT, 마스터 TX 라인 이상 |

### 상태 전이

```
┌──────────────────────────────────────────────────────────────────┐
│  어느 상태에서든 LINE_FAULT 감지                                  │
│  (마스터 TX 라인 preamble 미검출 LINE_RECOVERY_TH회 연속)         │
│  → DEAD 진입                                                     │
│  LINE_RECOVERY_TH 연속 유효 브로드캐스트 → NORMAL                │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  어느 상태에서든 HALT_CMD 수신(자신의 비트=1)                     │
│  → FAULT 즉시 진입. 공유 RX 버스 High-Z 즉각 전환.              │
└──────────────────────────────────────────────────────────────────┘

NORMAL
  ├─(|offset[k]|>GUARD_TICKS/4)──────▶ PAUSE (1사이클, 전송 중단)
  │       1사이클 경과 후 자동 복귀 ───▶ NORMAL
  └─(FAULT_CNT >= FAULT_TH)──────────▶ FAULT

FAULT
  └─(유효 브로드캐스트 연속 수신,      ▶ RECOVERY
     HALT_CMD 비트=0 포함 조건)
        RECOVERY
          ├─(RECOVERY_TH 연속 정상 수신)▶ NORMAL (FAULT_CNT 초기화)
          └─(오류 재발생)──────────────▶ FAULT
```

HALT_CMD로 진입한 FAULT와 FAULT_CNT로 진입한 FAULT는 동일 상태이며 복구 경로도 동일하다. HALT_CMD 비트가 1인 브로드캐스트는 유효 브로드캐스트로 인정하지 않는다.

### FAULT 상태에서 슬레이브 동작

전송을 중단하고 공유 RX 버스를 High-Z로 유지한다. RX 라인(마스터 TX 케이블)만 모니터링한다. 유효한 브로드캐스트(HALT_CMD 비트=0, Hamming 정상)가 연속 수신되면 RECOVERY로 진입한다. TICK_OFFSET 보정은 유효한 브로드캐스트가 수신될 때마다 계속 수행한다.

---

## 6. 설정 가능한 임계값 레지스터

모두 RW 레지스터로 구성한다.

| 레지스터 | 적용 대상 | 설명 |
|---------|----------|------|
| `FAULT_TH` | 마스터, 슬레이브 | 데이터 fault FAULT_CNT 임계값 |
| `RECOVERY_TH` | 마스터, 슬레이브 | 데이터 fault 복구 연속 정상 수신 횟수 |
| `SYNC_FAULT_TH` | 마스터 | SYNC_FAULT_CNT 임계값 |
| `SYNC_RECOVERY_TH` | 마스터 | sync fault 복구 연속 정상 횟수 |
| `LINE_RECOVERY_TH` | 마스터, 슬레이브 | 라인 fault 진입 및 복구 연속 횟수 |
| `GUARD_TICKS` | 마스터, 슬레이브 | guard time 길이. SYNC_FAULT(÷4)·CLOCK_FAULT(÷2) 임계값의 기준 |

`DRIFT_TH`와 `OFFSET_TH`는 제거한다. 오프셋 임계값은 `GUARD_TICKS`로부터 하드와이어드로 계산되므로 별도 레지스터가 불필요하다.
