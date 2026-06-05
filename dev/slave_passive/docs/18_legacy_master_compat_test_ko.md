# 레거시 Master 호환성 및 최종 통신 검증 기준

## 1. 목적

이 문서는 `Master_source` 폴더의 레거시 master RTL과 차기 slave AXI IP의 호환 전제를 정리한다. 레거시 master는 최신 코드가 아닐 수 있고 내부 구현도 정리되어 있지 않으므로, slave IP는 master RTL의 세부 코드 스타일이 아니라 실제 통신 프로토콜과 운용 전제를 기준으로 맞춘다.

이 문서는 slave IP 구현 이후 수행할 최종 검증의 기준으로 사용한다.

## 2. 호환성 결론

아래 전제를 만족하면 차기 slave AXI IP는 레거시 master와 호환 가능하다.

```text
master cycle length = master NODE_CNT 설정이 결정
slave transmit slot = slave ACTIVE_SLOT 설정이 결정
DIV register value  = 실제 bit period tick 수 - 1
```

master는 `NODE_CNT`까지의 모든 slot을 순서대로 관측한다. slave는 master가 관측하는 slot 중 `ACTIVE_SLOT[n]=1`인 slot에서만 응답한다. `ACTIVE_SLOT[n]=0`인 slot은 slave가 의도적으로 송신하지 않으며, master에서는 silent fault로 누적될 수 있다.

이 동작은 호환성 문제로 보지 않는다. 레거시 master에는 expected slot mask가 없고, `NODE_CNT` 범위 안의 slot은 모두 응답을 기대하는 구조이기 때문이다.

## 3. 설정 일치 규칙

### 3.1 `NODE_CNT`

최종 통신 실험에서 master는 가능한 최대 slot 범위를 관측하도록 설정한다.

```text
NODE_CNT = 7
```

이 경우 master는 slot 0부터 slot 7까지 총 8개 slot을 한 cycle로 본다. 새 slave IP는 내부적으로 8개 virtual slot을 모두 시간상 추적하되, 실제 송신은 `ACTIVE_SLOT`에 의해 결정한다.

예:

```text
master NODE_CNT  = 7
slave ACTIVE_SLOT = 8'b0001_0000
```

위 설정에서 slave는 slot 4에서만 송신한다. slot 0, 1, 2, 3, 5, 6, 7은 송신하지 않는다. master가 해당 slot을 silent로 판단할 수 있으나, 이는 의도된 호환 동작이다.

### 3.2 `DIV`

운용 기준은 다음과 같다.

```text
actual_bit_period_ticks = DIV_REG + 1
```

PS는 master와 slave 양쪽에 실제 bit period보다 1 작은 값을 설정한다.

예:

| 실제 bit period | register에 쓰는 값 |
| ---: | ---: |
| 1 tick | `0` |
| 10 ticks | `9` |
| 100 ticks | `99` |

레거시 master 내부 코드에는 폭 선언 등 정리되지 않은 부분이 있을 수 있다. 그러나 slave IP 사양과 testbench 기준은 `DIV_REG + 1`을 source of truth로 둔다.

### 3.3 `GUARD_TICKS`

master와 slave는 같은 `GUARD_TICKS` 값을 사용한다.

slave TX 시작 시점은 다음 기준을 따른다.

```text
frame_ticks      = 50 * (DIV_REG + 1)
slot_ticks       = frame_ticks + GUARD_TICKS
guard_half_ticks = GUARD_TICKS >> 1
tx_start[n]      = frame_ticks + n * slot_ticks + guard_half_ticks
```

`GUARD_TICKS`가 홀수이면 앞쪽 guard는 LSB를 버린 `GUARD_TICKS >> 1`이고, 나머지 tick은 뒤쪽 guard에 포함한다.

## 4. 통신 프로토콜 호환 항목

| 항목 | 호환 기준 |
| --- | --- |
| frame length | 50 bit |
| preamble | `8'hAA` |
| Hamming codeword | systematic `[42,35]` SECDED |
| master broadcast data | `{halt_mask[7:0], guard_ticks[9:0], reserved[16:0]}` |
| slave response data | `{slot_id[2:0], payload[31:0]}` |
| bit order | MSB-first |
| idle serial level | `0` |

master broadcast frame 안의 `guard_ticks` field는 호환 확인 및 상태 관측 용도로만 사용한다. 차기 slave IP의 timing source는 PS가 설정한 `CTRL.GUARD_TICKS`이다.

## 5. 최종 검증 전략

slave IP 구현 후 최종 검증은 두 단계로 수행한다.

### 5.1 Full-case slave testbench

먼저 레거시 master와 직접 연결하기 전에, slave IP 단독 testbench에서 FSM full case를 검증한다.

필수 검증 항목:

| 범주 | 검증 내용 |
| --- | --- |
| `ACTIVE_SLOT` | 0~255 전체 mask 조합 |
| slot order | slot 0부터 7까지 시간 순서 유지 |
| inactive slot | 해당 slot에서 TX가 발생하지 않음 |
| active slot | 정확한 `tx_start[n]`에서 50-bit frame 송신 |
| payload source | slot 0~5는 PS register, slot 6~7은 PL payload |
| `DIV_REG` | `DIV_REG + 1` timing 적용 |
| `GUARD_TICKS` | `GUARD_TICKS >> 1` 뒤 TX 시작 |
| halt mask | 적용 정책에 따라 해당 slot TX 억제 |
| config snapshot | sync cycle 중 설정 변경이 현재 cycle을 흔들지 않음 |
| event/fault | skip, invalid payload, TX overlap 등 관측 가능 |

이 단계의 목적은 slave FSM과 scheduler가 모든 설정 조합에서 독립적으로 올바르게 동작하는지 확인하는 것이다.

### 5.2 Legacy master 통신 실험

단독 testbench가 통과한 뒤, `Master_source` 기반 레거시 master와 새 slave IP를 연결해 실제 통신 실험을 수행한다.

권장 절차:

1. master `NODE_CNT`를 `7`로 설정한다.
2. master와 slave의 `DIV` 값을 같은 raw 값으로 설정한다.
3. master와 slave의 `GUARD_TICKS` 값을 일치시킨다.
4. slave `ACTIVE_SLOT`을 테스트하려는 slot mask로 설정한다.
5. slot 0~5 payload register 또는 slot 6~7 PL payload를 설정한다.
6. master가 active slot의 payload를 정상 수신하는지 확인한다.
7. inactive slot은 slave가 송신하지 않고, master에서는 silent fault로 관측될 수 있음을 확인한다.

최종 통신 실험에서는 inactive slot의 silent fault 자체를 실패로 보지 않는다. 실패 조건은 active slot에서 payload가 수신되지 않거나, slot id/payload/Hamming/timing이 틀어지는 경우이다.

## 6. 판정 기준

최종 호환 판정은 다음 기준으로 한다.

```text
PASS:
  master NODE_CNT=7 조건에서
  slave ACTIVE_SLOT으로 켠 모든 slot의 payload가
  master의 대응 slot_out에 정상 반영된다.

ALLOW:
  slave ACTIVE_SLOT으로 끈 slot이
  master에서 silent fault로 누적된다.

FAIL:
  active slot payload 미수신
  active slot id 불일치
  payload bit mismatch
  Hamming 2-bit error 발생
  slot timing severe error 발생
  sync cycle 중 slave FSM이 다음 slot 또는 다음 sync를 놓침
```

## 7. 향후 개선 가능성

cycle 주기 자체를 줄이고 inactive slot의 silent fault를 없애려면 master 쪽에 expected slot mask 또는 active slot mask 개념이 추가되어야 한다. 현재 레거시 master 기준에서는 `NODE_CNT`가 cycle 길이와 수신 기대 범위를 동시에 결정하므로, slave 단독 설정만으로 cycle 주기를 줄이지 않는다.

따라서 v1 slave IP는 다음 정책을 유지한다.

```text
cycle length source = master NODE_CNT
slave TX eligibility = slave ACTIVE_SLOT
inactive slot behavior = no TX, master may count silent
```
