# Slave AXI IP V&V 및 테스트 계획

## 1. 검증 목표

검증 목표는 RTL이 아래 기준을 만족함을 증명하는 것이다.

- AXI register map이 reset, RW/RO/W1C, reserved bit 정책을 지킨다.
- `DIV_REG + 1`이 모든 RX/TX/timing block에 일관 적용된다.
- `GUARD_TICKS >> 1` 이후 slot 중앙에서 TX가 시작된다.
- `ACTIVE_SLOT[7:0]` 256개 조합에서 기대 slot만 송신한다.
- slot 0~5는 PS payload, slot 6~7은 PL payload를 사용한다.
- frame format은 `8'hAA + 42-bit Hamming SECDED codeword`로 master 호환성을 유지한다.
- config snapshot 정책 때문에 frame 중 register write가 현재 cycle을 흔들지 않는다.

## 2. 단위 테스트 계획

| 대상 | 주요 테스트 |
| --- | --- |
| `slave_axi_lite_regs` | reset value, write/readback, byte strobe, reserved write ignore, W1C clear |
| `slave_cfg_shadow` | `DIV_REG+1`, pending/commit, sync boundary snapshot |
| `slave_sync_detector` | disabled ignore, idle edge detect, TX/RX active 중 ignore, double edge 방지 |
| `slave_broadcast_rx` | preamble pass/fail, codeword capture, bit period sampling |
| `slave_broadcast_decoder` | no error, 1-bit correction, 2-bit detect, halt mask extraction |
| `slave_timing_scheduler` | 33/64-bit frame/slot/guard_half 계산, target tick table, `cycle_done` schedule clear |
| `slave_slot_sequencer` | 256 active mask, ascending slot order, inactive skip, halt mask 적용 |
| `slave_payload_table` | slot별 payload source, PL valid fault |
| `slave_frame_builder` | `{slot_id, payload}` encoding, preamble prepend |
| `slave_tx_serializer` | MSB-first, 50-bit length, exact bit hold, done pulse |
| `slave_status_event` | sticky event, W1C clear, status level 반영 |

## 3. 통합 테스트 계획

### 3.1 기본 bring-up

1. reset 후 모든 register reset value 확인.
2. `ENABLE=0` 상태에서 master frame 입력, TX 없음 확인.
3. register 설정 후 `ENABLE=1`.
4. master sync 입력.
5. expected tick에서 active slot TX 확인.

### 3.2 Timing directed cases

| Case | 기대 결과 |
| --- | --- |
| `DIV_REG=0` | `bit_period_ticks=1` |
| `DIV_REG=1` | `bit_period_ticks=2` |
| `GUARD_TICKS=0` | `FAULT_SLOT_TIMING_INVALID`, scheduled TX 없음 |
| `GUARD_TICKS=1` | `FAULT_SLOT_TIMING_INVALID`, scheduled TX 없음 |
| `GUARD_TICKS=2` | `FAULT_SLOT_TIMING_INVALID`, scheduled TX 없음 |
| `GUARD_TICKS=3` | `FAULT_SLOT_TIMING_INVALID`, scheduled TX 없음 |
| `GUARD_TICKS=4` | 앞 guard 2, 뒤 guard 2 |
| slot 0 only | `frame_ticks + guard_half` |
| slot 7 only | `frame_ticks + 7*slot_ticks + guard_half` |
| all slots | 8개 frame이 slot index 순서대로 송신 |

### 3.3 Active slot full case

`ACTIVE_SLOT` 0부터 255까지 전수 테스트한다.

Reference model:

```text
for slot in 0..7:
    if active_slot[slot] == 1 and halt_mask[slot] == 0:
        expect_tx(slot, frame_ticks + slot * slot_ticks + guard_half_ticks)
    else:
        expect_no_tx(slot)
```

TB reference model은 RTL 내부 table 구현을 복사하지 않고 독립 계산식으로 작성한다.

### 3.4 Payload tests

- slot 0~5: 각 `DATA_OUTn` 값이 frame data `{slot_id, payload}`로 encode되는지 확인한다.
- slot 6~7: PL payload valid=1이면 PL payload가 송신되는지 확인한다.
- slot 6~7: PL payload valid=0이고 active이면 TX skip 및 fault latch를 확인한다.

### 3.5 Config update tests

- schedule 진행 중 `DIV` write 후 현재 cycle timing이 변하지 않는지 확인한다.
- schedule 진행 중 `ACTIVE_SLOT` write 후 현재 cycle slot list가 변하지 않는지 확인한다.
- 다음 sync에서 새 config가 반영되는지 확인한다.
- `EVENT.EVT_CFG_COMMIT`과 `STATUS.STS_CFG_PENDING` 동작을 확인한다.

### 3.6 Hamming/frame compatibility

- encoder output layout 검증.
- slave response frame `8'hAA + hamming_enc({slot_id, payload})` 검증.
- 1-bit data error correction directed test.
- parity bit error directed test.
- 2-bit error detect directed 또는 constrained random.
- preamble mismatch 시 codeword valid가 나오지 않는지 확인.

### 3.7 Policy directed tests

- broadcast frame 내부 `guard_ticks` field를 바꿔도 PS `CTRL.GUARD_TICKS` 기준 timing이 유지되는지 확인한다.
- broadcast halt mask가 현재 sync cycle을 즉시 흔들지 않고 다음 sync cycle부터 적용되는지 확인한다.
- TX active 중 `CTRL.ENABLE=0`이 write되면 현재 frame 완료 후 idle로 복귀하고 신규 TX request가 생기지 않는지 확인한다.
- AXI write handshake와 sync edge가 같은 clock에 발생하면 해당 write가 현재 sync cycle에 포함되지 않는지 확인한다.
- `DIV_REG=32'hFFFF_FFFF`에서 내부 `bit_period_ticks`가 33-bit `2^32`로 표현되고 wrap되지 않는지, simulation 시간 제약상 full serial 송신이 어려우면 precompute/debug 경로로 확인한다.

## 4. Coverage 목표

| Coverage | 목표 |
| --- | --- |
| `ACTIVE_SLOT` | 256개 전수 |
| slot id | 0~7 모두 TX |
| `DIV_REG` | 0, 1, representative normal, max-near values |
| `GUARD_TICKS` | invalid 0~3, minimum valid 4, even, odd, max |
| payload source | PS 0~5, PL 6~7 |
| AXI access | full word, byte strobe, reserved write |
| errors | preamble, ham 1-bit, ham 2-bit, TX overlap, PL payload invalid |
| config update | idle, sync wait, RX active, TX active |

## 5. 개발 게이트

RTL 구현은 다음 gate를 통과해야 다음 단계로 간다.

1. register block 단위 테스트 통과.
2. timing scheduler directed test 통과.
3. TX serializer standalone test 통과.
4. frame builder와 Hamming vector test 통과.
5. slot sequencer 256 active mask test 통과.
6. AXI + core 통합 simulation 통과.
7. Vivado synthesis에서 setup timing 위반 없음.
8. IP packaging address map과 `slave_regmap.md` 일치 확인.
