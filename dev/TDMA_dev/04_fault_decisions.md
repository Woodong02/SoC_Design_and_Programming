# TDMA IP — 내고장성 설계 결정

> 버전: 0.1
> 작성일: 2026-05-18

---

## 1. Fault 분류 체계

### 1.1 마스터 도메인 / 슬레이브 도메인 분리

마스터와 슬레이브는 감지 대상과 역할이 다르므로 fault 체계를 독립적으로 설계한다.

- **마스터**: 슬레이브 n별로 독립적인 fault 상태 머신을 운용한다 (최대 8개).
- **슬레이브**: 자기 자신에 대한 단일 fault 상태 머신을 운용한다.

### 1.2 Fault 종류

**마스터 도메인** (슬레이브 n에 대해 마스터가 감지):

| Fault | 감지 조건 | 분류 |
|-------|----------|------|
| `PREAMBLE_ERR` | 슬롯 n에서 preamble 미감지 또는 오류 | 카운터 누적 |
| `FRAME_ERR` | 프레임 구조 오류 | 카운터 누적 |
| `CRC_ERR` | CRC-16 불일치 | 카운터 누적 |
| `ADDR_ERR` | addr 필드가 슬롯 번호와 불일치 | 카운터 누적 |
| `SLOT_TIMEOUT` | RX 윈도우 내 아무것도 수신 안 됨 | 카운터 누적 |
| `SYNC_FAULT` | `\|drift[n][k]\| > DRIFT_TH` | 별도 카운터 누적 |
| `CLOCK_FAULT` | `\|D[n][k]\| > OFFSET_TH` | 즉시 격리 |
| `LINE_FAULT` | RX 라인 stuck Low (1사이클 확인) | 즉시 격리 후 자동 복구 |

`PREAMBLE_ERR`, `FRAME_ERR`, `CRC_ERR`, `ADDR_ERR`, `SLOT_TIMEOUT`은 성격이 동일하므로 **공통 FAULT_CNT**로 통합한다. 개별 오류 종류는 상태 레지스터에 별도 플래그로 기록한다.

**슬레이브 도메인** (슬레이브 자신이 감지):

| Fault | 감지 조건 | 분류 |
|-------|----------|------|
| `SYNC_FAULT` | `\|drift[k]\| > DRIFT_TH` | 자율 처리 (PAUSE) |
| `SYNC_MISS` | 예상 사이클 내 마스터 브로드캐스트 미수신 | 카운터 누적 |
| `BROADCAST_CRC_ERR` | 마스터 브로드캐스트 CRC-16 불일치 | 카운터 누적 |
| `LINE_FAULT` | 마스터 TX 라인 stuck Low (1사이클 확인) | 즉시 격리 후 자동 복구 |

`SYNC_MISS`와 `BROADCAST_CRC_ERR`은 **공통 FAULT_CNT**로 통합한다.

---

## 2. Fault 우선순위

동시에 여러 fault가 발생할 경우 아래 우선순위를 따른다.

```
CLOCK_FAULT > LINE_FAULT > SYNC_FAULT > DATA_FAULT
```

근거:
- `CLOCK_FAULT`: 클럭 자체가 근본적으로 불일치. 라인이 복구되어도 클럭이 망가져 있으면 의미 없음.
- `LINE_FAULT`: 물리 계층 이상. 상위 계층 fault보다 우선.
- `SYNC_FAULT`: TDMA는 슬롯 타이밍 침범 방지가 최우선. 데이터 오류보다 우선.
- `DATA_FAULT`: 가장 낮은 우선순위.

---

## 3. FAULT_CNT 동작 규칙

- 오류 발생 시: `FAULT_CNT++`
- 성공 수신 시: 변화 없음 (감소하지 않음)
- NORMAL 복귀 시: `FAULT_CNT` 초기화

보수적 설계로 일시적 성공이 누적 오류를 희석시키지 않는다.

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
| `LINE_FAULT` | 물리 라인 이상, 즉시 격리 |
| `CLOCK_FAULT` | 클럭 근본 불일치, 영구 격리 |

### 상태 전이

```
┌─────────────────────────────────────────────────────────────┐
│        어느 상태에서든 CLOCK_FAULT 감지 → CLOCK_FAULT 진입   │
│              (PS 명시적 클리어만 복구 가능)                   │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│   CLOCK_FAULT 제외, 어느 상태에서든 LINE_FAULT 감지           │
│   → LINE_FAULT 진입                                          │
│   LINE_RECOVERY_TH 연속 라인 정상 → NORMAL (카운터 초기화)   │
└──────────────────────────────────────────────────────────────┘

NORMAL
  ├─(FAULT_CNT >= FAULT_TH)──────────────▶ DATA_FAULT
  └─(SYNC_FAULT_CNT >= SYNC_FAULT_TH)───▶ SYNC_FAULT

DATA_FAULT
  ├─(SYNC_FAULT_CNT >= SYNC_FAULT_TH)───▶ SYNC_FAULT  ← 격상
  └─(슬레이브 재개 감지)─────────────────▶ DATA_RECOVERY
        DATA_RECOVERY
          ├─(RECOVERY_TH 연속 성공)───────▶ NORMAL
          └─(오류 재발생)─────────────────▶ DATA_FAULT

SYNC_FAULT
  └─(드리프트 정상 복귀)─────────────────▶ SYNC_RECOVERY
        SYNC_RECOVERY
          ├─(SYNC_RECOVERY_TH 연속 정상)──▶ NORMAL
          └─(드리프트 재초과)─────────────▶ SYNC_FAULT
```

### 격리 상태에서 마스터 동작

| 상태 | 슬롯 유지 | 데이터 수락 | 틱 비교 |
|------|----------|------------|--------|
| DATA_FAULT | ✓ | ✗ | ✓ (복구 감시) |
| DATA_RECOVERY | ✓ | 조건부 | ✓ |
| SYNC_FAULT | ✓ | ✗ | ✓ (복구 감시) |
| SYNC_RECOVERY | ✓ | 조건부 | ✓ |
| LINE_FAULT | ✓ | ✗ | ✗ |
| CLOCK_FAULT | ✓ | ✗ | ✗ |

슬롯은 어느 fault 상태에서도 사이클에서 제거하지 않는다. 타이밍 구조를 고정하기 위함이다.

---

## 5. 슬레이브 도메인 상태 머신

### 상태 목록

| 상태 | 설명 |
|------|------|
| `NORMAL` | 정상 동작, 매 슬롯 전송, 드리프트 보정 |
| `PAUSE` | SYNC_FAULT 자율 감지, 1사이클 전송 중단 |
| `FAULT` | FAULT_CNT >= FAULT_TH, 전송 중단 |
| `RECOVERY` | 복구 확인 중 |
| `DEAD` | LINE_FAULT, 마스터 TX 라인 이상 |

### 상태 전이

```
┌──────────────────────────────────────────────────────────────┐
│  어느 상태에서든 LINE_FAULT 감지 → DEAD 진입                 │
│  LINE_RECOVERY_TH 연속 유효 브로드캐스트 → NORMAL            │
└──────────────────────────────────────────────────────────────┘

NORMAL
  ├─(|drift|>DRIFT_TH)──────────────▶ PAUSE
  │       1사이클 경과 후 자동 복귀 ──▶ NORMAL
  └─(FAULT_CNT >= FAULT_TH)─────────▶ FAULT

FAULT
  └─(유효 브로드캐스트 연속 수신 시작)▶ RECOVERY
        RECOVERY
          ├─(RECOVERY_TH 연속 성공)───▶ NORMAL
          └─(오류 재발생)─────────────▶ FAULT
```

### FAULT 상태에서 슬레이브 동작

마스터 브로드캐스트 수신이 불안정하므로 전송을 중단하고 RX 라인만 모니터링한다. 유효한 브로드캐스트가 연속 수신되면 RECOVERY로 진입한다. TICK_OFFSET 보정은 유효한 브로드캐스트가 수신될 때마다 계속 수행한다.

---

## 6. 설정 가능한 임계값 레지스터

모두 RW 레지스터로 구성한다.

| 레지스터 | 적용 대상 | 설명 |
|---------|----------|------|
| `FAULT_TH` | 마스터, 슬레이브 | 데이터 fault FAULT_CNT 임계값 |
| `RECOVERY_TH` | 마스터, 슬레이브 | 데이터 fault 복구 연속 성공 횟수 |
| `SYNC_FAULT_TH` | 마스터 | SYNC_FAULT_CNT 임계값 |
| `SYNC_RECOVERY_TH` | 마스터 | sync fault 복구 연속 성공 횟수 |
| `LINE_RECOVERY_TH` | 마스터, 슬레이브 | 라인 복구 연속 정상 횟수 |
| `DRIFT_TH` | 마스터, 슬레이브 | 사이클 간 드리프트 허용 임계값 |
| `OFFSET_TH` | 마스터 | CLOCK_FAULT 선언 누적 오프셋 한계 |
