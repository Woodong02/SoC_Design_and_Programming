# Slave Slot Timer 결정사항 Handoff

## 목적

이 문서는 이번 세션에서 확정한 `slave_slot_timer` 관련 정책을 다음 구현 세션에 넘기기 위한 작업 현황 기록이다. 다음 세션은 이 문서를 기준으로 module design note, Verilog source, testbench를 작성한다.

## 이번 세션에서 확정한 사항

### 필수 Parameter

Slave는 자기 노드 번호와 전체 slot 범위를 모두 알아야 한다.

```verilog
parameter [2:0] NODE_ID  = 3'd0;
parameter [2:0] NODE_CNT = 3'd4;
```

- `NODE_ID`는 slave response data `[34:32]`에 들어간다.
- `NODE_CNT`는 마지막 slot index이다.
- 허용 값은 3-bit 범위 `0..7`이다.
- 실제 slot 순환 범위는 `0..NODE_CNT`이다.
- `NODE_ID > NODE_CNT`이면 TX trigger를 만들지 않는다.

### Sync 정책

Initial sync는 Master broadcast preamble을 기준으로 한다.

확정 동작:

- `slave_rx`는 idle-low 상태에서 첫 `1`을 보면 RX 내부 sync candidate로만 기록한다.
- 아직 `slave_slot_timer`에는 sync를 보내지 않는다.
- Preamble `8'hAA` 검증 성공 시에만 sync를 commit한다.
- Sync commit 시 `slave_rx`는 `o_SYNC_PULSE`와 `o_SYNC_CLK_CNT`를 출력한다.
- `o_SYNC_CLK_CNT = 8 * BIT_DIV`를 기본 preload로 사용한다.
- `slave_slot_timer`는 sync commit을 받으면 `slot = 0`, `clk_cnt = i_SYNC_CLK_CNT`로 재시작한다.
- Preamble 검증 실패 시 sync하지 않고 RX만 idle로 복귀한다.
- Master message가 올 때마다 같은 방식으로 다시 sync한다.

이 정책은 "sync 기준은 첫 preamble bit"라는 통신 기준을 유지하면서, preamble 검증 전에는 timer 상태를 바꾸지 않기 위한 것이다.

### Sync fault/status 미사용

이번 slave 설계에는 sync drift fault를 소비할 별도 fault 처리 모듈이 없다.

따라서 구현하지 않는다:

- 예상 sync window 계산
- unexpected sync event 기록
- sync fault counter
- sync timing status output

Slave local timer 추정과 다른 시점에 Master preamble이 오더라도, `8'hAA` 검증이 성공하면 즉시 resync한다.

### Slot 길이

현재 Master 구현과 Slave 1차 설계는 다음 수식을 따른다.

```text
data_len_tick = 50 * BIT_DIV
slot_ticks    = data_len_tick + GUARD_TICKS
```

Master 구현자 협의 결과에 따라 향후 guard에도 bit divider를 적용하는 다음 수식으로 바뀔 수 있다.

```text
slot_ticks_alt = (50 + GUARD_TICKS) * BIT_DIV
```

다음 구현 세션에서 `slave_slot_timer.v`를 작성할 때, 실제 source의 slot length 수식 근처에 `slot_ticks_alt`를 주석으로 남긴다. 현재 동작 수식은 `50 * BIT_DIV + GUARD_TICKS`이다.

### TX 시작 시점

Slave response는 자기 slot에서 guard 절반이 지난 시점에 시작한다.

```text
tx_start_tick = GUARD_TICKS >> 1
```

이후 50-bit frame을 송신하면 response 완료 시점은 guard 중앙 근처가 된다. Master 정상 수신 window는 guard의 `1/4..3/4` 범위이므로 이 정책은 Master 의도와 맞는다.

별도 off-by-one 보정은 하지 않는다.

### Halt와 Timer 관계

Halt는 timer를 멈추지 않는다.

- `halt_cmd[NODE_ID] == 1`이면 `slave_control`이 TX enable만 막는다.
- `slave_slot_timer`는 halt 상태를 알 필요가 없다.
- Timer는 계속 sync와 slot counting을 유지한다.
- Recovery 기능은 이번 범위에서 구현하지 않지만, `slave_control` FSM에 확장 여지를 남긴다.

### GUARD_TICKS 수신값

Master broadcast에서 수신한 `GUARD_TICKS`는 별도 flip-flop에 저장만 한다.

- Latched `GUARD_TICKS`는 현재 timer에 연결하지 않는다.
- Timer는 parameter/default로 전달받은 `i_GUARD_TICKS`를 사용한다.
- 동적 timing 변경은 향후 확장 항목이다.

## 다음 세션 구현 전 할 일

1. `slave_rx` design note에 sync candidate/commit FSM 동작을 명시한다.
2. `slave_slot_timer` design note에 slot counter, sync preload, TX trigger 수식을 명시한다.
3. `slave_control` design note에서 sync를 다루지 않고 decoded broadcast 정책만 다룬다는 점을 명시한다.
4. 각 모듈 source 작성 전에 design note를 먼저 작성한다.
5. 각 모듈 testbench는 reset, FSM transition, boundary, error, PASS/FAIL 출력을 포함한다.

## 다음 세션에서 주의할 점

- `o_SYNC_PULSE`는 preamble 첫 `1`에서 바로 내지 않는다.
- `o_SYNC_PULSE`는 `8'hAA` 검증 성공 후에만 낸다.
- `o_SYNC_CLK_CNT` preload는 `8 * BIT_DIV`이다.
- `NODE_ID > NODE_CNT`일 때 TX trigger가 없어야 한다.
- `slave_slot_timer`에 sync fault 기록 기능을 추가하지 않는다.
- `slave_slot_timer`에 halt input을 넣지 않는다.
- 수신한 `GUARD_TICKS` latch 값을 timer에 동적으로 반영하지 않는다.

