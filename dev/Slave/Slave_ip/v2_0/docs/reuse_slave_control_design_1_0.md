# slave_control 설계 노트

## 목적

`slave_control`은 Master broadcast decode 결과를 받아 Slave의 정책 상태를 결정하는 leaf module이다. 이 module은 Hamming decode, serial RX/TX, slot timing을 직접 수행하지 않고, 유효한 broadcast의 `halt_cmd`와 `GUARD_TICKS`만 정책에 반영한다.

이번 source를 작성하는 이유는 Master가 broadcast하는 node별 halt 명령을 Slave TX enable 정책으로 변환하고, broadcast의 `data[26:17]` `GUARD_TICKS` 값을 관측/확장용 register에 저장하기 위해서이다.

## Interface

```verilog
module slave_control (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [2:0]  i_NODE_ID,
    input  wire [34:0] i_BROADCAST_DATA,
    input  wire        i_BROADCAST_VALID,
    input  wire        i_BROADCAST_2BIT_ERR,
    input  wire [31:0] i_PAYLOAD_IN,
    output wire        o_TX_ENABLE,
    output wire [9:0]  o_LATCHED_GUARD_TICKS,
    output wire [31:0] o_PAYLOAD,
    output wire        o_HALTED
);
```

Port 의미:

- `i_CLK`: 동기 clock.
- `i_RESETN`: active-low synchronous reset.
- `i_NODE_ID`: 이 Slave node의 3-bit ID. `halt_cmd[NODE_ID]` indexing에 사용한다.
- `i_BROADCAST_DATA`: Master broadcast Hamming decode 후의 35-bit data.
- `i_BROADCAST_VALID`: broadcast data가 1-cycle 동안 유효함을 나타낸다.
- `i_BROADCAST_2BIT_ERR`: Hamming SECDED 2-bit error indication. 이 값이 `1`이면 broadcast는 정책에 반영하지 않는다.
- `i_PAYLOAD_IN`: 상위 module이 제공하는 32-bit response payload.
- `o_TX_ENABLE`: `slave_tx` trigger 허용 신호. halt 상태에서는 `0`이다.
- `o_LATCHED_GUARD_TICKS`: 마지막으로 정상 반영된 broadcast의 `data[26:17]`.
- `o_PAYLOAD`: `i_PAYLOAD_IN` pass-through.
- `o_HALTED`: 현재 정책 FSM이 halt 상태임을 나타낸다.

## Broadcast Field

Master broadcast data layout은 다음과 같다.

```text
data[34:27] = halt_cmd[7:0]
data[26:17] = GUARD_TICKS[9:0]
data[16:0]  = 17'b0
```

`slave_control`은 `i_BROADCAST_VALID == 1`이고 `i_BROADCAST_2BIT_ERR == 0`인 cycle에만 다음을 수행한다.

- `i_BROADCAST_DATA[26:17]`을 `o_LATCHED_GUARD_TICKS` register에 저장한다.
- `i_BROADCAST_DATA[34:27]`에서 `halt_cmd`를 추출하고 `halt_cmd[i_NODE_ID]`를 FSM 전이에 반영한다.

2-bit error broadcast는 상태와 latched guard 값을 모두 유지한다.

## Payload 정책

이 leaf module은 payload 값을 해석하거나 default로 치환하지 않는다. `o_PAYLOAD`는 항상 `i_PAYLOAD_IN`을 그대로 전달한다. 필요한 경우 `PAYLOAD_DEFAULT` parameter 선택은 `slave_top` 같은 상위 module에서 처리할 수 있으며, `slave_control`은 input pass-through leaf로 유지한다.

## FSM

Reachable state는 전체 3개이다.

```text
CTRL_WAIT_SYNC
CTRL_ACTIVE
CTRL_HALT
```

State 의미:

- `CTRL_WAIT_SYNC`: reset 후 또는 아직 정상 broadcast가 반영되지 않은 상태. TX는 disabled.
- `CTRL_ACTIVE`: valid broadcast에서 `halt_cmd[NODE_ID] == 0`이 확인된 상태. TX enabled.
- `CTRL_HALT`: valid broadcast에서 `halt_cmd[NODE_ID] == 1`이 확인된 상태. TX disabled.

Transition:

| Current state | 조건 | Next state | 설명 |
|---|---|---|---|
| `CTRL_WAIT_SYNC` | valid clean broadcast and halt bit clear | `CTRL_ACTIVE` | 첫 정상 broadcast에서 active 진입 |
| `CTRL_WAIT_SYNC` | valid clean broadcast and halt bit set | `CTRL_HALT` | 첫 정상 broadcast가 halt 명령 |
| `CTRL_WAIT_SYNC` | no valid clean broadcast | `CTRL_WAIT_SYNC` | 대기 유지 |
| `CTRL_ACTIVE` | valid clean broadcast and halt bit set | `CTRL_HALT` | halt 명령 반영 |
| `CTRL_ACTIVE` | valid clean broadcast and halt bit clear | `CTRL_ACTIVE` | active 유지 및 guard 갱신 |
| `CTRL_ACTIVE` | 2-bit error broadcast or invalid | `CTRL_ACTIVE` | 상태/latch 유지 |
| `CTRL_HALT` | valid clean broadcast and halt bit clear | `CTRL_ACTIVE` | halt clear에 따른 재활성화 |
| `CTRL_HALT` | valid clean broadcast and halt bit set | `CTRL_HALT` | halt 유지 및 guard 갱신 |
| `CTRL_HALT` | 2-bit error broadcast or invalid | `CTRL_HALT` | 상태/latch 유지 |

Terminal/error case:

- 별도 terminal state는 없다.
- 2-bit Hamming error는 broadcast ignore 조건으로 처리한다.
- Recovery 기능은 이번 범위에서 구현하지 않는다. 향후 recovery 조건이 확정되면 `CTRL_HALT`에서 `CTRL_WAIT_SYNC` 또는 `CTRL_ACTIVE`로 전이되는 조건을 추가할 수 있다.

## 출력 동작

- `o_TX_ENABLE = 1` only when state is `CTRL_ACTIVE`.
- `o_HALTED = 1` only when state is `CTRL_HALT`.
- `o_LATCHED_GUARD_TICKS`는 reset에서 `0`으로 초기화되고, valid clean broadcast에서만 갱신된다.
- `o_PAYLOAD`는 조합 pass-through이다.

## Test Coverage

`tb_slave_control.v`는 self-checking 방식으로 다음을 검증한다.

- reset 후 `CTRL_WAIT_SYNC` 동작: TX disabled, halted clear, guard reset.
- valid clean broadcast와 halt clear로 active 진입.
- `data[26:17]` guard latch.
- valid clean broadcast와 halt set으로 halt 진입.
- halt clear broadcast에 의한 재활성화.
- 2-bit error broadcast ignore: 상태와 guard latch 유지.
- 서로 다른 `NODE_ID` instance에서 `halt_cmd[NODE_ID]` indexing이 올바른지 확인.
- payload pass-through.

## 확인/추정 구분

확인된 사항:

- Broadcast layout, halt 정책, 2-bit error ignore 정책은 slave requirement/spec 문서에서 확인되었다.
- `slave_control` 포트 초안과 FSM 후보는 `00_slave_spec_and_module_structure.md`에서 확인되었다.

추정 또는 상위 module 책임:

- `PAYLOAD_DEFAULT` 선택은 이 leaf가 아니라 상위 `slave_top`에서 처리될 수 있다.
- Latched `GUARD_TICKS`를 timer에 동적으로 연결할지는 향후 통합 단계에서 결정한다.
