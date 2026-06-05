# 차기 Slave AXI IP 레지스터맵 확정안

이 문서는 `slave_regmap.md`와 같은 내용을 설계 문서 형식으로 풀어 쓴다. 구현 시 address, bit field, reset value는 이 문서와 `slave_regmap.md`를 동시에 기준으로 한다.

## 1. Register Summary

| Offset | Name | Access | Reset | 필수 여부 |
| ---: | --- | --- | ---: | --- |
| `0x00` | `CTRL` | RW | `0x0000_0000` | 필수 |
| `0x04` | `DIV` | RW | `0x0000_0000` | 필수 |
| `0x08` | `DATA_OUT0` | RW | `0x0000_0000` | 필수 |
| `0x0C` | `DATA_OUT1` | RW | `0x0000_0000` | 필수 |
| `0x10` | `DATA_OUT2` | RW | `0x0000_0000` | 필수 |
| `0x14` | `DATA_OUT3` | RW | `0x0000_0000` | 필수 |
| `0x18` | `DATA_OUT4` | RW | `0x0000_0000` | 필수 |
| `0x1C` | `DATA_OUT5` | RW | `0x0000_0000` | 필수 |
| `0x20` | `STATUS` | RO | `0x0000_0000` | 필수 |
| `0x24` | `EVENT` | W1C | `0x0000_0000` | 필수 |
| `0x28` | `FAULT` | W1C | `0x0000_0000` | 필수 |
| `0x2C` | `DBG_BIT_PERIOD_LO` | RO | `0x0000_0001` | 권장 |
| `0x30` | `DBG_FRAME_TICKS_LO` | RO | `0x0000_0032` | 권장 |
| `0x34` | `DBG_SLOT_TICKS_LO` | RO | `0x0000_0032` | 권장 |
| `0x38` | `DBG_GUARD_HALF_LO` | RO | `0x0000_0000` | 권장 |

## 2. Required Registers

### `0x00 CTRL`

| Bits | Field | Access | Reset | 설명 |
| ---: | --- | --- | ---: | --- |
| `0` | `ENABLE` | RW | `0` | core enable |
| `10:1` | `GUARD_TICKS` | RW | `0` | slot 내 총 guard tick. v1 scheduled TX는 4 이상 요구 |
| `18:11` | `ACTIVE_SLOT` | RW | `0` | 8개 가상 slot 송신 enable mask |
| `31:19` | `RESERVED` | RO | `0` | write ignored |

`ACTIVE_SLOT[n]=1`이면 slot `n`은 송신 후보가 된다. 실제 송신은 payload valid, halt mask, TX idle 조건을 함께 만족해야 한다.

### `0x04 DIV`

| Bits | Field | Access | Reset | 설명 |
| ---: | --- | --- | ---: | --- |
| `31:0` | `DIV_REG` | RW | `0` | bit period raw 값 |

```text
bit_period_ticks = DIV_REG + 1
```

이 정의 때문에 `DIV_REG=0`은 fault가 아니다.

### `0x08`~`0x1C DATA_OUT0`~`DATA_OUT5`

각 register는 대응하는 slot의 32-bit payload이다.

```text
slot 0 -> DATA_OUT0
slot 1 -> DATA_OUT1
slot 2 -> DATA_OUT2
slot 3 -> DATA_OUT3
slot 4 -> DATA_OUT4
slot 5 -> DATA_OUT5
slot 6 -> PL internal payload 6
slot 7 -> PL internal payload 7
```

## 3. Required Status/Event/Fault Registers

`STATUS`, `EVENT`, `FAULT`는 v1 구현 필수 관측 레지스터이다. full-case 테스트와 PS bring-up이 이 레지스터를 기준으로 동작한다.

### `0x20 STATUS`

| Bits | Field | 설명 |
| ---: | --- | --- |
| `0` | `STS_ENABLED` | shadow enable |
| `1` | `STS_SYNCED` | schedule active |
| `2` | `STS_RX_ACTIVE` | RX active |
| `3` | `STS_TX_ACTIVE` | TX active |
| `6:4` | `STS_CUR_SLOT` | current slot |
| `7` | `STS_SLOT_VALID` | current slot valid |
| `15:8` | `STS_HALT_MASK` | applied halt mask |
| `16` | `STS_CFG_PENDING` | config update pending |
| `17` | `STS_PL_PAYLOAD6_VALID` | PL payload 6 valid |
| `18` | `STS_PL_PAYLOAD7_VALID` | PL payload 7 valid |
| `31:19` | `RESERVED` | reserved |

### `0x24 EVENT`

| Bits | Field | 설명 |
| ---: | --- | --- |
| `0` | `EVT_SYNC_DETECTED` | sync edge detected |
| `1` | `EVT_RX_FRAME_DONE` | broadcast RX done |
| `2` | `EVT_TX_DONE` | one slot TX done |
| `3` | `EVT_SLOT_CYCLE_DONE` | slot scan done |
| `4` | `EVT_PREAMBLE_ERR` | preamble error |
| `5` | `EVT_HAM_1BIT_ERR` | hamming corrected error |
| `6` | `EVT_HAM_2BIT_ERR` | hamming uncorrectable error |
| `7` | `EVT_CFG_COMMIT` | shadow config committed |
| `31:8` | `RESERVED` | reserved |

### `0x28 FAULT`

| Bits | Field | 설명 |
| ---: | --- | --- |
| `0` | `FAULT_TX_OVERLAP` | TX busy 중 TX request |
| `1` | `FAULT_SLOT_TIMING_INVALID` | `GUARD_TICKS < 4` 등 scheduled TX timing 제약 위반 |
| `2` | `FAULT_PL_PAYLOAD6_INVALID` | slot 6 active인데 payload invalid |
| `3` | `FAULT_PL_PAYLOAD7_INVALID` | slot 7 active인데 payload invalid |
| `4` | `FAULT_RX_HAM_2BIT` | broadcast 2-bit error |
| `31:5` | `RESERVED` | reserved |

## 4. Debug Timing Registers

| Offset | Name | 계산식 |
| ---: | --- | --- |
| `0x2C` | `DBG_BIT_PERIOD_LO` | `DIV_REG + 1` low 32-bit |
| `0x30` | `DBG_FRAME_TICKS_LO` | `50 * DBG_BIT_PERIOD` low 32-bit |
| `0x34` | `DBG_SLOT_TICKS_LO` | `DBG_FRAME_TICKS + GUARD_TICKS` low 32-bit |
| `0x38` | `DBG_GUARD_HALF_LO` | `GUARD_TICKS >> 1` low 32-bit |

debug register는 현재 RTL에 구현되어 있다. 내부 timing은 64-bit 기준이므로, full-width debug가 필요하면 high-word register를 추가 배치해야 한다.

## 4.1 Numeric Width Policy

`DIV_REG` 32-bit 전체는 유효 입력이다. 내부 timing 계산은 overflow를 피하기 위해 다음 폭을 사용한다.

| 값 | 내부 폭 |
| --- | ---: |
| `bit_period_ticks` | 33 |
| `frame_ticks` | 64 |
| `slot_ticks` | 64 |
| `slot_target_tick[n]` | 64 |
| `sync_tick_counter` | 64 |

serializer/RX timer reload는 `DIV_REG` 자체를 사용한다. 이는 `bit_period_ticks - 1`과 같다.

## 5. Register Update Semantics

PS write는 raw register에는 즉시 반영된다. 그러나 core 동작에는 shadow commit 후 반영된다.

`GUARD_TICKS < 4`인 shadow 설정이 `ENABLE=1`로 반영되면 `FAULT_SLOT_TIMING_INVALID`가 latch되고, sync scheduling 및 TX는 차단된다.

| Register | Running 중 write | Core 반영 시점 |
| --- | --- | --- |
| `CTRL.ENABLE` | 허용 | enable down은 신규 동작 즉시 중지, enable up은 idle shadow commit 후 다음 sync부터 |
| `CTRL.GUARD_TICKS` | 허용 | idle shadow commit 후 다음 sync freeze |
| `CTRL.ACTIVE_SLOT` | 허용 | idle shadow commit 후 다음 sync freeze |
| `DIV` | 허용 | idle shadow commit 후 다음 sync freeze |
| `DATA_OUT0`~`DATA_OUT5` | 허용 | idle shadow commit 후 다음 sync freeze |
| `EVENT`, `FAULT` clear | 허용 | 즉시 clear |

한 sync cycle 안에서 사용하는 config는 고정이다.

AXI write handshake와 sync edge가 같은 clock에 겹치면 해당 write는 현재 sync cycle에 포함하지 않는다. PS가 `CTRL` field를 바꿀 때는 read-modify-write 또는 전체 `CTRL` word compose를 사용해야 한다.
