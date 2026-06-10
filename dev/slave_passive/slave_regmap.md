# Slave AXI IP Register Map

이 문서는 차기 slave IP에서 PS가 AXI-Lite로 접근하는 레지스터맵의 기준 문서이다.

## 기본 규칙

| 표기 | 의미 |
| --- | --- |
| RW | PS read/write 가능 |
| RO | PS read 전용, write 무시 |
| W1C | 1을 write한 bit만 clear |
| reserved | 0으로 읽히며 write는 무시 |

모든 레지스터는 32-bit word aligned address에 배치한다. AXI byte strobe는 지원하되, reserved bit는 byte strobe와 무관하게 write를 무시한다.

## 필수 레지스터

| Offset | Name | Access | Reset | 설명 |
| ---: | --- | --- | ---: | --- |
| `0x00` | `CTRL` | RW | `0x0000_0000` | enable, guard tick, active slot 제어 |
| `0x04` | `DIV` | RW | `0x0000_0000` | bit period raw 값. 실제 적용값은 `DIV_REG + 1` |
| `0x08` | `DATA_OUT0` | RW | `0x0000_0000` | slot 0 송신 payload |
| `0x0C` | `DATA_OUT1` | RW | `0x0000_0000` | slot 1 송신 payload |
| `0x10` | `DATA_OUT2` | RW | `0x0000_0000` | slot 2 송신 payload |
| `0x14` | `DATA_OUT3` | RW | `0x0000_0000` | slot 3 송신 payload |
| `0x18` | `DATA_OUT4` | RW | `0x0000_0000` | slot 4 송신 payload |
| `0x1C` | `DATA_OUT5` | RW | `0x0000_0000` | slot 5 송신 payload |

### `0x00 CTRL`

| Bits | Field | Access | Reset | 설명 |
| ---: | --- | --- | ---: | --- |
| `0` | `ENABLE` | RW | `0` | `1`: slave core 동작. `0`: sync 감지 및 신규 TX 요청 중지 |
| `10:1` | `GUARD_TICKS` | RW | `0` | 한 slot 안에서 송신하지 않는 전체 guard tick 수. v1 scheduled TX는 4 이상 요구 |
| `18:11` | `ACTIVE_SLOT` | RW | `0` | bit별 가상 slot 송신 enable. bit 0은 slot 0, bit 7은 slot 7 |
| `31:19` | `RESERVED` | RO | `0` | reserved |

`GUARD_TICKS`는 10-bit unsigned 값이다. 송신 시작 offset은 `GUARD_TICKS >> 1`로 계산하며, 홀수 값의 LSB는 앞쪽 guard 계산에서 버린다. v1 RTL은 `GUARD_TICKS < 4`이면 sync scheduling과 TX를 막고 `FAULT_SLOT_TIMING_INVALID`를 latch한다.

### `0x04 DIV`

| Bits | Field | Access | Reset | 설명 |
| ---: | --- | --- | ---: | --- |
| `31:0` | `DIV_REG` | RW | `0` | bit period raw 설정값 |

`DIV_REG`는 지수값이 아니다. 실제 송수신 bit period는 다음과 같이 계산한다.

```text
bit_period_ticks = DIV_REG + 1
```

따라서 `DIV_REG = 0`은 1 clock/bit로 동작한다.

### `0x08`~`0x1C DATA_OUT0`~`DATA_OUT5`

| Register | 대응 slot | Payload source |
| --- | ---: | --- |
| `DATA_OUT0` | 0 | PS register |
| `DATA_OUT1` | 1 | PS register |
| `DATA_OUT2` | 2 | PS register |
| `DATA_OUT3` | 3 | PS register |
| `DATA_OUT4` | 4 | PS register |
| `DATA_OUT5` | 5 | PS register |

slot 6과 slot 7 payload는 PS register가 아니라 PL 내부 payload 입력에서 온다. 단, 송신 여부는 `ACTIVE_SLOT[6]`, `ACTIVE_SLOT[7]`로 동일하게 제어한다.

## 상태, 이벤트, Fault, Debug 레지스터

`STATUS`, `EVENT`, `FAULT`는 v1 구현 필수 관측 레지스터이다. `DBG_*_LO` 레지스터는 bring-up을 위한 optional debug 레지스터이다.

| Offset | Name | Access | Reset | 설명 |
| ---: | --- | --- | ---: | --- |
| `0x20` | `STATUS` | RO | `0x0000_0000` | core 현재 상태. v1 필수 |
| `0x24` | `EVENT` | W1C | `0x0000_0000` | sticky event latch. v1 필수 |
| `0x28` | `FAULT` | W1C | `0x0000_0000` | sticky fault latch. v1 필수 |
| `0x2C` | `DBG_BIT_PERIOD_LO` | RO | `0x0000_0001` | optional debug: `DIV_REG + 1` low 32-bit |
| `0x30` | `DBG_FRAME_TICKS_LO` | RO | `0x0000_0032` | optional debug: `50 * bit_period_ticks` low 32-bit |
| `0x34` | `DBG_SLOT_TICKS_LO` | RO | `0x0000_0032` | optional debug: `frame_ticks + guard_ticks` low 32-bit |
| `0x38` | `DBG_GUARD_HALF_LO` | RO | `0x0000_0000` | optional debug: `guard_ticks >> 1` low 32-bit |

### `0x20 STATUS`

| Bits | Field | 설명 |
| ---: | --- | --- |
| `0` | `STS_ENABLED` | shadow register에 반영된 enable 상태 |
| `1` | `STS_SYNCED` | sync 감지 후 slot schedule 진행 중 |
| `2` | `STS_RX_ACTIVE` | broadcast RX 동작 중 |
| `3` | `STS_TX_ACTIVE` | TX serializer 동작 중 |
| `6:4` | `STS_CUR_SLOT` | 현재 처리 중인 slot index |
| `7` | `STS_SLOT_VALID` | `STS_CUR_SLOT` 유효 |
| `15:8` | `STS_HALT_MASK` | 마지막으로 적용된 slot별 halt mask |
| `16` | `STS_CFG_PENDING` | AXI register write가 safe idle shadow commit 대기 중 |
| `17` | `STS_PL_PAYLOAD6_VALID` | PL slot 6 payload 유효 |
| `18` | `STS_PL_PAYLOAD7_VALID` | PL slot 7 payload 유효 |
| `31:19` | `RESERVED` | reserved |

### `0x24 EVENT`

| Bits | Field | 설명 |
| ---: | --- | --- |
| `0` | `EVT_SYNC_DETECTED` | master sync edge 감지 |
| `1` | `EVT_RX_FRAME_DONE` | master broadcast frame 수신 완료 |
| `2` | `EVT_TX_DONE` | 한 slot 송신 완료 |
| `3` | `EVT_SLOT_CYCLE_DONE` | 현재 sync cycle의 slot scan 완료 |
| `4` | `EVT_PREAMBLE_ERR` | preamble mismatch |
| `5` | `EVT_HAM_1BIT_ERR` | SECDED 1-bit error correction 발생 |
| `6` | `EVT_HAM_2BIT_ERR` | SECDED 2-bit error 감지 |
| `7` | `EVT_CFG_COMMIT` | pending config가 shadow에 반영됨 |
| `31:8` | `RESERVED` | reserved |

### `0x28 FAULT`

| Bits | Field | 설명 |
| ---: | --- | --- |
| `0` | `FAULT_TX_OVERLAP` | TX active 중 신규 TX 요청이 발생함 |
| `1` | `FAULT_SLOT_TIMING_INVALID` | `GUARD_TICKS < 4` 등 scheduled TX timing 제약 위반 |
| `2` | `FAULT_PL_PAYLOAD6_INVALID` | slot 6 active 시 payload valid가 0 |
| `3` | `FAULT_PL_PAYLOAD7_INVALID` | slot 7 active 시 payload valid가 0 |
| `4` | `FAULT_RX_HAM_2BIT` | 복구 불가 broadcast decode error |
| `31:5` | `RESERVED` | reserved |

`DIV_REG = 0`은 정상 입력이다. `DIV_REG + 1` 보정으로 1 tick/bit가 되므로 fault로 취급하지 않는다.

## Numeric Width Policy

`DIV_REG`는 32-bit raw register 전체를 유효 입력으로 허용한다. overflow를 피하기 위해 내부 timing 계산은 다음 폭을 기준으로 한다.

| 값 | 내부 폭 | 설명 |
| --- | ---: | --- |
| `bit_period_ticks` | 33 | `{1'b0, DIV_REG} + 33'd1` |
| `bit_period_reload` | 32 | serializer/RX timer reload 값. `bit_period_ticks - 1 == DIV_REG` |
| `frame_ticks` | 64 | `50 * bit_period_ticks` |
| `slot_ticks` | 64 | `frame_ticks + GUARD_TICKS` |
| `slot_target_tick[n]` | 64 | slot별 TX start tick |
| `sync_tick_counter` | 64 | sync 이후 schedule counter |

v1 RTL은 위 폭을 사용하여 모든 32-bit `DIV_REG`와 10-bit `GUARD_TICKS` 조합을 overflow 없이 표현하는 것을 목표로 한다. 구현 resource 제약으로 내부 폭을 줄이는 경우, 축소된 최대값을 문서화하고 범위 초과 config는 shadow에 commit하지 않으며 `FAULT_SLOT_TIMING_INVALID`를 latch해야 한다.

## Timing Source of Truth

```text
bit_period_ticks = DIV_REG + 1
frame_ticks      = 50 * bit_period_ticks
slot_ticks       = frame_ticks + GUARD_TICKS
guard_half_ticks = GUARD_TICKS >> 1

slot_base[n]     = frame_ticks + n * slot_ticks
tx_start[n]      = slot_base[n] + guard_half_ticks
tx_end[n]        = tx_start[n] + frame_ticks
```

PS-visible register 값은 core idle 상태에서 shadow register로 commit되고, master sync edge에서는 이미 commit된 shadow 값을 freeze한다. sync edge와 같은 clock에 완료된 AXI write는 현재 sync cycle에 포함하지 않고 다음 cycle 후보가 된다. 한 master sync cycle 동안 `DIV`, `GUARD_TICKS`, `ACTIVE_SLOT`, `DATA_OUT0`~`DATA_OUT5`는 고정된 값으로 동작한다.
