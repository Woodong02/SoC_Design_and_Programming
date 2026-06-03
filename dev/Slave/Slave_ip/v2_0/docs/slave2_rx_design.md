# `slave2_rx` 설계 노트

## 목적

`slave2_rx`는 Slave 2.0의 synchronized Master serial line에서 broadcast frame을 수신하는 leaf module이다. 이 module은 자체 `BIT_DIV` counter를 만들지 않고 `slave2_timebase`가 제공하는 sample tick을 clock enable처럼 사용해 preamble과 codeword bit를 shift한다.

수신 frame은 기존 Master/Slave 1.0과 같은 `8'hAA + 42-bit codeword`이다. `8'hAA` preamble이 완전히 검증된 경우에만 `o_SYNC_PULSE`를 1 cycle assert하고, 이후 42-bit codeword 수신이 끝나면 `o_CODEWORD_VALID`를 1 cycle assert한다.

## 기준 및 범위

- 대상 source: `Slave_ip/v2_0/slave2_rx.v`
- 대상 testbench: `tb/tb_slave2_rx.v`
- HDL: pure Verilog, Vivado 2019.1 xsim compatible
- Coding standard: `CODING_STANDARDS.md`
- 기존 참고 구현: `Slave_ip/v1_0/slave_rx.v`

이 module은 serial input synchronizer, Hamming decode, timebase/rate correction을 포함하지 않는다. 입력 `i_SERIAL_IN`은 이미 `i_CLK` domain으로 동기화되어 있다고 가정한다.

## Module Interface

```verilog
module slave2_rx (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire        i_SERIAL_IN,
    input  wire        i_SAMPLE_TICK,
    input  wire        i_SAMPLE_EARLY_TICK,
    input  wire        i_SAMPLE_LATE_TICK,
    output wire [41:0] o_CODEWORD,
    output wire        o_CODEWORD_VALID,
    output wire        o_SYNC_PULSE,
    output wire        o_RX_ACTIVE,
    output wire        o_PREAMBLE_ERR
);
```

### 입력

- `i_CLK`: RX FSM clock.
- `i_RESETN`: active-low reset.
- `i_SERIAL_IN`: 동기화된 NRZ serial input. idle 값은 `0`이다.
- `i_SAMPLE_TICK`: center sample tick. `USE_MAJORITY=0`일 때 이 tick에서 bit를 commit한다.
- `i_SAMPLE_EARLY_TICK`: early sample tick. `USE_MAJORITY=1`일 때 majority vote의 첫 sample을 capture한다.
- `i_SAMPLE_LATE_TICK`: late sample tick. `USE_MAJORITY=1`일 때 majority vote를 계산하고 bit를 commit한다.

### 출력

- `o_CODEWORD`: 마지막으로 정상 수신 완료된 42-bit codeword.
- `o_CODEWORD_VALID`: codeword 수신 완료 1-cycle pulse.
- `o_SYNC_PULSE`: preamble `8'hAA` 성공 시점의 1-cycle pulse.
- `o_RX_ACTIVE`: FSM이 `RX2_PREAMBLE` 또는 `RX2_CODEWORD`일 때 high.
- `o_PREAMBLE_ERR`: preamble mismatch 1-cycle pulse.

## Sampling 정책

초기 구현은 parameter `USE_MAJORITY`를 제공한다.

```verilog
parameter USE_MAJORITY = 1;
```

- `USE_MAJORITY=1`: `early -> center -> late` 순서의 tick을 한 bit sample window로 사용한다. early/center sample은 register에 저장하고 late tick에서 `early`, `center`, `late` 3-sample majority를 계산해 bit를 commit한다.
- `USE_MAJORITY=0`: `i_SAMPLE_TICK`만 사용해 center sample을 즉시 commit한다. early/late tick은 무시된다.

`slave2_rx`는 자체 bit counter를 갖지 않으므로, tick 간격과 bit-center alignment는 `slave2_timebase` 책임이다. majority mode에서는 한 bit 안에서 tick이 `early`, `center`, `late` 순서로 한 번씩 발생한다고 가정한다. 이 순서가 깨지면 해당 bit sample은 정의된 통신 조건이 아니다.

## FSM 정의

### `RX2_IDLE`

- Reset 후 기본 상태이다.
- committed sample bit가 `0`이면 계속 idle이다.
- committed sample bit가 `1`이면 preamble candidate의 첫 bit로 shift하고 `RX2_PREAMBLE`로 이동한다.
- tick이 없으면 serial input noise가 있어도 상태와 출력은 변하지 않는다.

### `RX2_PREAMBLE`

- committed sample bit마다 `{previous[6:0], sampled_bit}` 방향으로 preamble shift register를 갱신한다.
- 8번째 preamble bit까지 shift한 값이 `8'hAA`이면 `RX2_CODEWORD`로 이동하고 같은 clock edge 이후 `o_SYNC_PULSE`를 1 cycle assert한다.
- 8번째 preamble bit까지 shift한 값이 `8'hAA`가 아니면 `RX2_ERROR`로 이동하고 같은 clock edge 이후 `o_PREAMBLE_ERR`를 1 cycle assert한다.

### `RX2_CODEWORD`

- committed sample bit마다 42-bit codeword shift register를 갱신한다.
- 42번째 codeword bit 수신 시 `o_CODEWORD`에 complete codeword를 latch하고 `RX2_DONE`으로 이동한다.
- 같은 clock edge 이후 `o_CODEWORD_VALID`를 1 cycle assert한다.

### `RX2_DONE`

- 정상 frame terminal state이다.
- 출력 pulse는 이전 clock edge에서 이미 생성되며, 이 상태는 1 cycle 후 `RX2_IDLE`로 복귀한다.
- 다음 frame은 `RX2_IDLE` 복귀 후 새 committed sample bit에서 시작할 수 있다.

### `RX2_ERROR`

- preamble error terminal state이다.
- error pulse는 이전 clock edge에서 이미 생성되며, 이 상태는 1 cycle 후 `RX2_IDLE`로 복귀한다.
- `o_SYNC_PULSE`와 `o_CODEWORD_VALID`는 preamble mismatch에서 생성되지 않는다.

## 상태 전이 요약

| 현재 상태 | 조건 | 다음 상태 | 출력/동작 |
|---|---|---|---|
| `RX2_IDLE` | no committed bit 또는 bit `0` | `RX2_IDLE` | idle 유지 |
| `RX2_IDLE` | committed bit `1` | `RX2_PREAMBLE` | 첫 preamble bit shift |
| `RX2_PREAMBLE` | 1~7번째 committed bit | `RX2_PREAMBLE` | preamble shift |
| `RX2_PREAMBLE` | 8번째 committed bit, shift 결과 `8'hAA` | `RX2_CODEWORD` | `o_SYNC_PULSE` |
| `RX2_PREAMBLE` | 8번째 committed bit, shift 결과 != `8'hAA` | `RX2_ERROR` | `o_PREAMBLE_ERR` |
| `RX2_CODEWORD` | 1~41번째 committed bit | `RX2_CODEWORD` | codeword shift |
| `RX2_CODEWORD` | 42번째 committed bit | `RX2_DONE` | codeword latch, `o_CODEWORD_VALID` |
| `RX2_DONE` | always | `RX2_IDLE` | terminal 복귀 |
| `RX2_ERROR` | always | `RX2_IDLE` | terminal 복귀 |

## 기대 동작

- Preamble 성공 전에는 `o_SYNC_PULSE`가 발생하지 않는다.
- `o_SYNC_PULSE`는 preamble `8'hAA` 성공 시에만 1 cycle assert된다.
- Preamble mismatch에서는 `o_PREAMBLE_ERR`만 1 cycle assert되고 codeword 수신은 진행하지 않는다.
- Idle 상태에서 serial line noise가 있어도 committed sample bit가 없으면 수신을 시작하지 않는다.
- 정상 frame 완료 후 reset 없이 다음 frame을 받을 수 있다.

## Test Coverage

`tb_slave2_rx`는 self-checking 방식으로 다음을 검증한다.

- reset 중 출력 clear와 reset 해제 후 idle 상태
- 정상 frame에서 preamble 성공 `o_SYNC_PULSE` 1-cycle pulse
- 정상 frame에서 `o_CODEWORD` 값과 `o_CODEWORD_VALID` 1-cycle pulse
- wrong preamble에서 `o_PREAMBLE_ERR` 발생, sync/codeword valid 차단
- tick 없는 idle noise에서 출력 pulse 미발생
- reset 없이 두 frame을 연속 수신하는 back-to-back behavior
- majority mode에서 early/center/late 중 하나가 반전되어도 2-of-3 vote로 정상 수신

## 확인된 사항과 가정

- 확인됨: 기존 `slave_rx`는 `8'hAA` preamble과 42-bit codeword를 MSB-first로 shift한다.
- 확인됨: Slave 2.0 구조 문서는 RX가 자체 `BIT_DIV` counter 대신 timebase sample tick을 사용해야 한다고 정의한다.
- 확인됨: `o_SYNC_PULSE`는 preamble 성공 시에만 생성되어야 한다.
- 가정: `i_SERIAL_IN`은 `slave2_line_sync` 같은 별도 module을 거쳐 `i_CLK` domain에 들어온다.
- 가정: `slave2_timebase`는 RX가 bit를 commit할 수 있는 tick 위치를 제공한다. majority mode에서는 early/center/late tick 순서가 유지된다.

## 검증 결과

초기 작성 시점의 xsim 실행 결과는 `sim/slave2_rx/README.md`에 기록한다.
