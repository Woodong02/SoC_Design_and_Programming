# Slave AXI IP 사용자 매뉴얼

## 1. IP 개요

이 IP는 PL에 위치하며 PS가 AXI-Lite register로 설정한다. master serial input에서 sync/broadcast frame 시작을 감지하면, 설정된 slot schedule에 따라 slave response frame을 송신한다.

하나의 IP instance는 slot 0~7까지 8개의 가상 slave를 담당할 수 있다.

## 2. 기본 설정 순서

PS 초기화 절차:

1. `CTRL.ENABLE=0`을 write하여 core를 정지한다.
2. `EVENT`, `FAULT`를 W1C로 clear한다.
3. `DIV`에 bit period raw 값을 write한다.
4. `CTRL.GUARD_TICKS`에 guard 값을 write한다.
5. `DATA_OUT0`~`DATA_OUT5`에 slot 0~5 payload를 write한다.
6. slot 6~7을 사용할 경우 PL payload valid가 1인지 확인한다.
7. `CTRL.ACTIVE_SLOT`에 송신할 slot mask를 write한다.
8. `CTRL.ENABLE=1`을 write한다.
9. master sync/broadcast frame을 기다린다.

`CTRL`은 `ENABLE`, `GUARD_TICKS`, `ACTIVE_SLOT`이 같은 32-bit word에 들어있다. field 하나만 바꿀 때는 PS 코드에서 read-modify-write를 하거나, 최종 `CTRL` 전체 word를 다시 compose해서 write해야 한다. 단순히 `CTRL=1`을 write하면 이전 guard와 active slot 값이 지워질 수 있다.

## 3. `DIV` 사용법

`DIV`는 clock divider exponent가 아니다. 실제 bit period는 다음과 같다.

```text
bit_period_ticks = DIV_REG + 1
```

| `DIV_REG` | 실제 bit period |
| ---: | ---: |
| `0` | 1 clock |
| `1` | 2 clocks |
| `9` | 10 clocks |
| `99` | 100 clocks |

## 4. `GUARD_TICKS` 사용법

`GUARD_TICKS`는 한 slot 안에서 송신하지 않는 전체 tick 수이다. 송신은 slot 시작 후 `GUARD_TICKS >> 1` tick이 지난 뒤 시작한다.

```text
slot_ticks  = frame_ticks + GUARD_TICKS
tx_start[n] = frame_ticks + n * slot_ticks + (GUARD_TICKS >> 1)
```

예:

| `GUARD_TICKS` | 앞 guard | 뒤 guard |
| ---: | ---: | ---: |
| `4` | 2 | 2 |
| `5` | 2 | 3 |
| `10` | 5 | 5 |
| `11` | 5 | 6 |

v1 RTL은 `GUARD_TICKS >= 4`를 요구한다. 0~3으로 enable된 상태에서 sync가 들어오면 scheduled TX를 수행하지 않고 `FAULT_SLOT_TIMING_INVALID`를 latch한다.

## 5. `ACTIVE_SLOT` 사용법

`ACTIVE_SLOT`은 8-bit mask이다.

```text
ACTIVE_SLOT[0] -> slot 0 송신 enable
ACTIVE_SLOT[1] -> slot 1 송신 enable
...
ACTIVE_SLOT[7] -> slot 7 송신 enable
```

slot 0~5는 `DATA_OUT0`~`DATA_OUT5` payload를 송신한다. slot 6~7은 PL 내부 payload를 송신한다.

예: slot 0, 2, 6 활성화

```text
ACTIVE_SLOT = 8'b0100_0101
```

## 6. 동작 예시

설정:

```text
DIV_REG       = 9
GUARD_TICKS   = 256
ACTIVE_SLOT   = 8'b0100_0101
DATA_OUT0     = 32'h1111_0000
DATA_OUT2     = 32'h2222_0000
PL_PAYLOAD6   = 32'h6666_0000
```

계산:

```text
bit_period_ticks = 10
frame_ticks      = 500
slot_ticks       = 756
guard_half_ticks = 128

slot 0 tx_start  = 500 + 0*756 + 128 = 628
slot 2 tx_start  = 500 + 2*756 + 128 = 2140
slot 6 tx_start  = 500 + 6*756 + 128 = 5164
```

모든 tick은 master sync edge 기준이다.

## 7. 동작 중 설정 변경

PS write는 register readback에는 즉시 보이지만, core 동작에는 다음 sync boundary에서 반영된다.

권장 운용:

1. 긴급하지 않으면 `ENABLE=0`으로 정지한다.
2. `DIV`, `GUARD_TICKS`, `ACTIVE_SLOT`, `DATA_OUTn`을 갱신한다.
3. `ENABLE=1`로 재시작한다.

동작 중 write가 필요하면 `STATUS.STS_CFG_PENDING`과 `EVENT.EVT_CFG_COMMIT`으로 반영 시점을 확인한다.

sync edge와 AXI write가 같은 clock에 겹치면 해당 write는 현재 sync cycle에 반영되지 않는다. 현재 cycle은 sync 이전 clock까지 shadow에 commit된 설정만 사용한다.

## 8. Slot 6/7 사용

slot 6과 7은 PS payload register가 없다. PL 내부 logic이 payload와 valid를 제공한다.

PS가 `ACTIVE_SLOT[6]` 또는 `ACTIVE_SLOT[7]`을 1로 만들기 전, `STATUS.STS_PL_PAYLOAD6_VALID` 또는 `STATUS.STS_PL_PAYLOAD7_VALID`를 확인하는 것을 권장한다.

payload invalid 상태에서 slot이 active이면 현재 RTL은 해당 slot을 송신하지 않고 `FAULT_PL_PAYLOAD6_INVALID` 또는 `FAULT_PL_PAYLOAD7_INVALID`를 latch한다.

## 9. 상태 및 오류 확인

기본 확인 순서:

1. `STATUS.STS_ENABLED`로 enable이 shadow에 반영됐는지 확인한다.
2. `EVENT.EVT_SYNC_DETECTED`로 master sync가 감지됐는지 확인한다.
3. `STATUS.STS_TX_ACTIVE` 또는 `EVENT.EVT_TX_DONE`으로 송신 상태를 확인한다.
4. `EVENT.EVT_SLOT_CYCLE_DONE`으로 현재 sync cycle 처리가 끝났는지 확인한다.
5. `EVENT.EVT_PREAMBLE_ERR`, `EVENT.EVT_HAM_2BIT_ERR`, `FAULT`를 확인한다.
6. 처리한 event/fault는 해당 bit에 1을 write하여 clear한다.

## 10. 주의 사항

- `DIV_REG=0`은 오류가 아니다.
- `GUARD_TICKS`는 v1에서 4 이상으로 설정한다. shadow 설정이 `ENABLE=1`인 상태에서 0~3이면 invalid timing fault가 latch되고 scheduling/TX가 차단된다.
- `ACTIVE_SLOT=0`이면 sync를 감지해도 송신하지 않는다.
- broadcast frame 내부의 guard field는 timing source가 아니다.
- 현재 cycle의 동작은 sync boundary에서 snapshot한 설정을 따른다.
