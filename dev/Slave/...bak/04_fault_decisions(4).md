# TDMA IP — 내고장성 설계 결정

> 버전: 0.4
> 작성일: 2026-05-21
> v0.4 변경: TX_TICK 제거에 따라 SYNC_FAULT, CLOCK_FAULT, PAUSE 상태 삭제.
>            마스터 FSM 7→5 상태, 슬레이브 FSM 6→5 상태로 단순화.
>            카운터 구조를 연속 기반에서 포인트 점수 기반(+10/−1, 포화)으로 전면 변경.
>            RECOVERY_TH 레지스터 삭제 (카운터 배율이 충분한 복구 히스테리시스 제공).

---

## 1. Fault 분류 체계

### 1.1 마스터 도메인 / 슬레이브 도메인 분리

마스터와 슬레이브는 감지 대상과 역할이 다르므로 fault 체계를 독립적으로 설계한다.

- **마스터**: 슬레이브 n별로 독립적인 fault 상태 머신을 운용한다 (최대 8개).
- **슬레이브**: 자기 자신에 대한 단일 fault 상태 머신을 운용한다.

### 1.2 Fault 이벤트 분류

**마스터 도메인** (슬레이브 n에 대해 마스터가 감지):

| 이벤트 | 감지 조건 | 집계 카운터 |
|--------|----------|------------|
| `SLOT_TIMEOUT` | 슬롯 RX 윈도우 내 유효한 Manchester 신호(액티브 에지) 없음 | `FAULT_CNT` |
| `FRAME_ERR` | 액티브 에지 감지 후 Manchester 인코딩 위반 검출 (mid-bit 전이 부재 또는 비트 수 불일치) | `FAULT_CNT` |
| `HAMMING_ERR` | Hamming 2비트 오류 (정정 불가, 프레임 폐기) | `FAULT_CNT` |
| `PREAMBLE_ERR` | 액티브 에지 감지 후 preamble(0x55) 패턴 불일치 | `LINE_CNT` |
| `ADDR_ERR` | addr 필드가 슬롯 번호와 불일치 (별도 즉각 처리 경로) | 해당 없음 |

`SLOT_TIMEOUT`은 물리 신호 자체가 없는 경우(슬레이브가 의도적으로 침묵하거나 전원 차단)이고, `PREAMBLE_ERR`은 신호는 있으나 내용이 올바르지 않은 경우(버스 잡음, 전기적 노이즈)다. 두 이벤트를 다른 카운터로 분리하여 장애 원인을 구분한다.

`ADDR_ERR` 발생 시나리오: 슬레이브 A가 슬롯 B를 침범 → 충돌로 HAMMING_ERR 발생 → FAULT_CNT[B] 누적 → HALT_CMD[B] 발행 → 슬레이브 B 침묵 → A 단독 전송 → addr 불일치 감지 → addr 필드에 표시된 슬레이브(A)에 즉시 HALT_CMD 세팅. FAULT_CNT 누적 없음.

**슬레이브 도메인** (슬레이브 자신이 감지):

| 이벤트 | 감지 조건 | 집계 카운터 |
|--------|----------|------------|
| `NO_BROADCAST` | CYCLE_TIMEOUT_TICKS 내 액티브 에지 미감지, 또는 preamble(0x55) 패턴 불일치 | `LINE_CNT` |
| `BROADCAST_HAMMING_ERR` | 마스터 브로드캐스트 Hamming 2비트 오류 (정정 불가) | `FAULT_CNT` |
| `HALT_CMD` | 브로드캐스트 HALT_CMD 필드에서 자신의 비트=1 | 즉각 FAULT 진입 (카운터 무관) |

슬레이브는 마스터 TX 케이블에서 신호가 없거나 preamble이 깨지면 물리 계층 이상으로 통합 판단하여 `LINE_CNT`에 집계한다. 마스터와 달리 SLOT_TIMEOUT을 별도 FAULT_CNT로 분리하지 않는다.

---

## 2. 카운터 동작 규칙

### 2.1 공통 포인트 점수 구조

FAULT_CNT와 LINE_CNT 모두 동일한 포인트 점수 규칙을 따른다.

```
위반 이벤트 발생:  counter = min(counter + 10, THRESHOLD)  // 상한 포화
정상 수신:         counter = max(counter - 1,  0)           // 하한 포화

counter >= THRESHOLD → fault 상태 진입
counter == 0         → NORMAL 복귀
```

상한을 THRESHOLD로 포화하는 이유: 슬레이브가 fault 상태로 전송을 멈추는 동안 마스터의 카운터가 무한히 증가하면 복구 시간이 과도하게 길어진다. 포화로 인해 복구 시간은 항상 최대 THRESHOLD 사이클로 제한된다.

### 2.2 FAULT_CNT 규칙 (마스터·슬레이브 공통)

| 이벤트 | 마스터 FAULT_CNT[n] | 슬레이브 FAULT_CNT |
|--------|-------------------|------------------|
| SLOT_TIMEOUT | +10 (포화) | — |
| FRAME_ERR | +10 (포화) | — |
| HAMMING_ERR | +10 (포화) | — |
| BROADCAST_HAMMING_ERR | — | +10 (포화) |
| 정상 프레임 수신 | −1 (하한 0) | −1 (하한 0) |

Hamming 1비트 자동 정정은 정상 수신으로 간주하며 FAULT_CNT를 증가시키지 않는다.

### 2.3 LINE_CNT 규칙 (마스터·슬레이브 공통)

| 이벤트 | 마스터 LINE_CNT[n] | 슬레이브 LINE_CNT |
|--------|-------------------|-----------------|
| PREAMBLE_ERR | +10 (포화) | — |
| NO_BROADCAST | — | +10 (포화) |
| 유효 preamble 수신 | −1 (하한 0) | −1 (하한 0) |

LINE_CNT와 FAULT_CNT는 독립 카운터이며 서로 영향을 주지 않는다.

### 2.4 히스테리시스 수치 예

FAULT_TH = 30 기준:

```
진입: 오류 3회 → counter = 30 = FAULT_TH → fault 상태
복구: 정상 수신 30회 → counter = 0 → NORMAL

복구 중 추가 오류 1회: counter += 10 → 복구 10회 추가 지연
```

FAULT_TH 설정으로 허용 오류 횟수(TH/10)와 복구 소요 사이클(TH)을 동시에 제어한다. RECOVERY_TH 레지스터는 불필요하다.

---

## 3. Fault 우선순위

동시에 여러 fault 조건이 발생할 경우 아래 우선순위를 따른다.

```
LINE_FAULT > DATA_FAULT
```

- `LINE_FAULT`: 물리 계층 이상. 공유 버스 전체 또는 마스터 TX 라인이 영향받으므로 데이터 계층 fault보다 우선 처리. LINE_FAULT 상태에서는 데이터 수신 자체가 불가능하므로 FAULT_CNT 평가가 무의미하다.
- `DATA_FAULT`: 라인은 정상이나 데이터에 오류 누적. 라인 복구 후 평가.

`HALT_CMD`는 우선순위 체계 밖의 명시적 중단 명령으로, 어느 상태에서든 수신 즉시 FAULT 진입을 강제한다.

---

## 4. 마스터 도메인 상태 머신 (슬레이브 n별)

### 4.1 상태 목록

| 상태 | 인코딩 | 설명 |
|------|--------|------|
| `INACTIVE` | 000 | NODE_CNT 범위 밖. FAULT_CNT·LINE_CNT 집계 없음 |
| `NORMAL` | 001 | 정상 동작. FAULT_CNT < FAULT_TH (임계값 미만에서 오류 누적 허용) |
| `DATA_RECOVERY` | 010 | 0 < FAULT_CNT < FAULT_TH이며 DATA_FAULT에서 복구 중. 데이터 수신 재개 |
| `DATA_FAULT` | 011 | FAULT_CNT ≥ FAULT_TH. 데이터 수신 격리 |
| `LINE_FAULT` | 100 | LINE_CNT ≥ LINE_FAULT_TH. 공유 RX 버스 이상. 격리 |

### 4.2 상태 전이

```
┌──────────────────────────────────────────────────────────────────┐
│  어느 상태에서든 LINE_CNT ≥ LINE_FAULT_TH → LINE_FAULT 진입      │
│  LINE_CNT가 0에 도달 → NORMAL 복귀 (FAULT_CNT도 함께 초기화)    │
└──────────────────────────────────────────────────────────────────┘

INACTIVE
  └─(NODE_CNT 범위 내 변경)──────────────────▶ NORMAL

NORMAL  [FAULT_CNT < FAULT_TH]
  └─(FAULT_CNT ≥ FAULT_TH)──────────────────▶ DATA_FAULT

DATA_FAULT  [FAULT_CNT ≥ FAULT_TH]
  └─(정상 프레임 수신 → FAULT_CNT--)
      FAULT_CNT < FAULT_TH 되는 순간 ────────▶ DATA_RECOVERY

DATA_RECOVERY  [0 < FAULT_CNT < FAULT_TH]
  ├─(FAULT_CNT ≥ FAULT_TH 재도달)──────────▶ DATA_FAULT
  └─(FAULT_CNT == 0)────────────────────────▶ NORMAL

LINE_FAULT  [LINE_CNT ≥ LINE_FAULT_TH]
  └─(LINE_CNT == 0)─────────────────────────▶ NORMAL
      (FAULT_CNT도 0으로 초기화)
```

ADDR_ERR 감지 시 상태 전이 없이 해당 슬레이브(addr 필드 값)에 즉시 HALT_CMD를 세팅한다. 침범 슬레이브가 HALT_CMD 수신 후 침묵하면 마스터는 SLOT_TIMEOUT을 수신하고 침범 슬레이브의 슬롯에서 FAULT_CNT가 누적된다.

### 4.3 격리 상태에서 마스터 동작

| 상태 | 슬롯 유지 | 데이터 수락 | HALT_CMD |
|------|----------|------------|---------|
| DATA_FAULT | ✓ | ✗ (FAULT_CNT 집계만) | PS 제어 |
| DATA_RECOVERY | ✓ | ✓ (DATA_VALID 플래그 세팅) | ✗ |
| LINE_FAULT | ✓ | ✗ | ✗ |

슬롯은 어느 fault 상태에서도 사이클에서 제거하지 않는다. 공유 버스에서 슬롯 구조를 변경하면 전 슬레이브의 타이밍이 흔들리기 때문이다.

---

## 5. 슬레이브 도메인 상태 머신

### 5.1 상태 목록

| 상태 | 인코딩 | 설명 |
|------|--------|------|
| `IDLE` | 000 | ENABLE=0. TX 라인 모니터링 없음 |
| `NORMAL` | 001 | 정상 동작. 매 슬롯 전송. FAULT_CNT < FAULT_TH (임계값 미만에서 오류 누적 허용) |
| `DATA_RECOVERY` | 010 | 0 < FAULT_CNT < FAULT_TH이며 FAULT에서 복구 중. 전송 재개 |
| `FAULT` | 011 | FAULT_CNT ≥ FAULT_TH 또는 HALT_CMD 수신. 전송 중단, 버스 High-Z |
| `DEAD` | 100 | LINE_CNT ≥ LINE_FAULT_TH. 마스터 TX 라인 이상. 전송 중단 |

### 5.2 상태 전이

```
┌──────────────────────────────────────────────────────────────────┐
│  어느 상태에서든 LINE_CNT ≥ LINE_FAULT_TH → DEAD 진입           │
│  LINE_CNT가 0에 도달 → NORMAL 복귀 (FAULT_CNT도 초기화)         │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  어느 상태에서든 HALT_CMD 수신 (자신의 비트=1)                    │
│  → FAULT 즉시 진입. 공유 RX 버스 High-Z 즉각 전환.              │
└──────────────────────────────────────────────────────────────────┘

IDLE
  └─(ENABLE=1, 첫 액티브 에지 감지)────────────▶ NORMAL

NORMAL  [FAULT_CNT < FAULT_TH]
  └─(FAULT_CNT ≥ FAULT_TH)──────────────────────▶ FAULT

FAULT  [FAULT_CNT ≥ FAULT_TH, 전송 중단]
  └─(유효 브로드캐스트 수신 → FAULT_CNT--)
      FAULT_CNT < FAULT_TH 되는 순간 ────────────▶ DATA_RECOVERY

DATA_RECOVERY  [0 < FAULT_CNT < FAULT_TH, 전송 재개]
  ├─(FAULT_CNT ≥ FAULT_TH 재도달)──────────────▶ FAULT
  └─(FAULT_CNT == 0)──────────────────────────────▶ NORMAL

DEAD  [LINE_CNT ≥ LINE_FAULT_TH, 전송 중단]
  └─(LINE_CNT == 0)─────────────────────────────▶ NORMAL
      (FAULT_CNT도 0으로 초기화)
```

HALT_CMD로 진입한 FAULT와 FAULT_CNT로 진입한 FAULT는 동일 상태이며 복구 경로도 동일하다. HALT_CMD 비트가 1인 브로드캐스트는 유효 브로드캐스트로 인정하지 않아 FAULT_CNT에 −1 적용 없음.

### 5.3 FAULT 상태에서 슬레이브 동작

전송을 중단하고 공유 RX 버스를 High-Z로 유지한다. 마스터 TX 케이블(RX 수신 경로)만 모니터링한다. 유효 브로드캐스트(HALT_CMD 비트=0, Hamming 정상) 수신 시 FAULT_CNT에 −1 적용 → FAULT_CNT < FAULT_TH에 도달하는 순간 DATA_RECOVERY로 전이, 전송 재개.

### 5.4 DEAD 상태에서 슬레이브 동작

전송을 중단하고 버스를 High-Z로 유지한다. 액티브 에지 감지를 계속 시도한다. 유효 preamble 수신 시 LINE_CNT에 −1 적용 → LINE_CNT == 0에 도달 시 NORMAL로 자동 복구.

---

## 6. HALT_CMD

마스터 브로드캐스트 프레임의 HALT_CMD 필드(8비트 비트맵). 슬레이브는 자신의 비트(SLAVE_ADDR번째 비트)가 1인 브로드캐스트 수신 시 즉시 FAULT 진입 및 버스 High-Z 전환. FAULT_CNT 값과 무관하게 강제 적용된다.

| HW 자동 세팅 조건 | 대상 비트 |
|-----------------|---------|
| ADDR_ERR 감지 | addr 필드에 표시된 침범 슬레이브(rx_addr) |

PS는 언제든 HALT_CMD 레지스터를 읽기/쓰기 가능. SOFT_RST 시 전체 클리어. 브로드캐스트 반영은 다음 사이클부터 (최대 1사이클 지연, 허용됨).

---

## 7. 설정 가능한 임계값 레지스터

| 레지스터 | 적용 대상 | 설명 |
|---------|----------|------|
| `FAULT_TH` | 마스터, 슬레이브 | FAULT_CNT 상한 임계값. 오류 허용 횟수 ≈ FAULT_TH / 10. 복구 소요 사이클 ≈ FAULT_TH |
| `LINE_FAULT_TH` | 마스터, 슬레이브 | LINE_CNT 상한 임계값. 라인 이상 허용 횟수 ≈ LINE_FAULT_TH / 10 |

v0.3 대비 삭제된 레지스터:
- `RECOVERY_TH`: +10/−1 배율이 충분한 히스테리시스를 제공하므로 별도 임계값 불필요
- `SYNC_FAULT_TH`: SYNC_FAULT 상태 삭제로 불필요
- `SYNC_RECOVERY_TH`: SYNC_RECOVERY 상태 삭제로 불필요
- `LINE_RECOVERY_TH`: `LINE_FAULT_TH`로 통합 및 명칭 변경 (카운터 의미가 바뀌었으므로)
