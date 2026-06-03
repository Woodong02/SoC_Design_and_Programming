# `slave2_top` 설계 노트

## 목적

`slave2_top`은 Slave 2.0의 integration module이다. 이 모듈은 외부 Master serial 입력, 2.0 timing/RX/TX leaf, 1.0 재사용 leaf인 `slave_hamming_dec`와 `slave_control`을 한 곳에서 배선한다.

이 source를 작성하는 이유는 Slave 2.0 하위 모듈들이 서로 다른 담당자에 의해 작성되는 동안, top-level interface와 신호 연결 정책을 먼저 고정하기 위함이다. `slave2_top`은 leaf module이 아니며, 자체 통신 알고리즘이나 상태 천이를 구현하지 않는다.

## 기준 자료

- `Slave_ip/v2_0/docs/00_slave2_robust_structure.md`
- `Slave_ip/v2_0/docs/01_reuse_and_modification_plan.md`
- `Slave_ip/v1_0/slave_top.v`
- `Slave_ip/v1_0/slave_hamming_dec.v`
- `Slave_ip/v1_0/slave_control.v`

## Module Interface

```verilog
module slave2_top (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire        i_MASTER_SERIAL,
    input  wire [31:0] i_PAYLOAD,
    output wire        o_SLAVE_SERIAL,
    output wire        o_SYNCED,
    output wire        o_HALTED,
    output wire        o_RATE_LOCKED,
    output wire        o_RATE_ERR,
    output wire [9:0]  o_LATCHED_GUARD_TICKS
);
```

### Parameter

| Parameter | 기본값 | 의미 |
|---|---:|---|
| `NODE_ID` | `3'd0` | 이 Slave의 응답 slot 번호 |
| `NODE_CNT` | `3'd4` | Master가 관리하는 마지막 node index |
| `BIT_DIV_DEFAULT` | `10'd1023` | lock 전 acquisition 및 초기 timing 기준 |
| `GUARD_TICKS_DEFAULT` | `10'd256` | 초기 `slave2_timebase` guard 입력 |

## 내부 연결 구조

```text
i_MASTER_SERIAL
  -> slave2_line_sync
  -> slave2_rx
      -> slave_hamming_dec
      -> slave_control
  -> slave2_timebase
  -> slave2_tx
  -> o_SLAVE_SERIAL
```

### 2.0 leaf interface 의존성

현재 top은 `slave2_line_sync`, `slave2_rx`, `slave2_timebase`, `slave2_tx`의 실제 source interface를 기준으로 작성되었다.

- `slave2_line_sync`: source 존재 및 단독 simulation PASS.
- `slave2_rx`: source 존재 및 단독 simulation PASS.
- `slave2_timebase`: source 존재 및 단독 simulation PASS.
- `slave2_tx`: source 존재 및 단독 simulation PASS.

향후 leaf 담당자가 port를 변경하면 `slave2_top.v`와 smoke test를 함께 조정해야 한다.

비고: 구조 문서 초안에는 `10'd1024`가 언급되어 있으나, 초안 `i_BIT_DIV_DEFAULT` port 폭은 `[9:0]`이므로 1024를 표현할 수 없다. `slave2_top`의 초기 기본값은 truncate로 0이 되는 것을 피하기 위해 `10'd1023`으로 둔다. Leaf interface가 `[15:0]` 등으로 확정되면 기본값을 다시 1024로 조정할 수 있다.

## 재사용 module 연결

### `slave_hamming_dec`

`slave2_rx`가 출력한 42-bit `o_CODEWORD`를 1.0 `slave_hamming_dec`에 직접 연결한다.

- `o_DATA[34:0]`: broadcast data로 `slave_control`에 전달
- `o_HAM_1BIT_ERR`: top debug/status에는 아직 노출하지 않음
- `o_HAM_2BIT_ERR`: `slave_control.i_BROADCAST_2BIT_ERR`에 전달

### `slave_control`

1.0 `slave_control`을 초기 2.0 control policy로 재사용한다.

- `i_BROADCAST_VALID`: `slave2_rx.o_CODEWORD_VALID`
- `i_BROADCAST_2BIT_ERR`: Hamming decoder 2-bit error
- `o_TX_ENABLE`: `slave2_tx.i_TX_ENABLE`
- `o_PAYLOAD`: `slave2_tx.i_PAYLOAD`
- `o_HALTED`: top `o_HALTED`
- `o_LATCHED_GUARD_TICKS`: top `o_LATCHED_GUARD_TICKS`

## Guard 입력 정책

초기 구현에서 `slave2_timebase.i_GUARD_TICKS`는 parameter `GUARD_TICKS_DEFAULT`에 연결한다.

`slave_control.o_LATCHED_GUARD_TICKS`는 외부 status로는 노출하지만, timebase timing에는 아직 반영하지 않는다. Broadcast로 latch된 guard를 동적으로 반영하려면 다음 정책을 별도 설계해야 한다.

- frame/TX active 중 변경 보류 여부
- lock 상태에서 guard 변경이 slot phase에 주는 영향
- 잘못된 broadcast 이후 guard 유지 정책

## Status 출력 정의

### `o_SYNCED`

초기 top에서 `o_SYNCED`는 RX sync acquisition event 의미로 정의한다.

- 연결: `slave2_rx.o_SYNC_PULSE`
- 의미: RX가 Master broadcast preamble을 검증해 sync event를 생성한 cycle의 pulse
- 주의: timebase lock status가 아니다. 지속 status가 필요한 경우 `o_RATE_LOCKED`를 사용한다.

### `o_RATE_LOCKED`

`o_RATE_LOCKED`는 `slave2_timebase.o_LOCKED`에 연결한다.

- 의미: timebase가 Master cycle timing을 추적 중이라고 판단한 상태
- RX preamble 검증 pulse와 구분된다.

### `o_RATE_ERR`

`o_RATE_ERR`는 `slave2_timebase.o_RATE_ERR`에 연결한다. pulse인지 sticky status인지는 `slave2_timebase` 최종 설계에 따른다.

## FSM 정의

`slave2_top` 자체에는 FSM이 없다.

이 모듈은 다음 하위 FSM/status를 배선만 한다.

- RX FSM: `slave2_rx` 내부
- Timebase FSM: `slave2_timebase` 내부
- Control FSM: 재사용 `slave_control` 내부
- TX FSM: `slave2_tx` 내부

Top에서 새 state register를 추가하지 않으므로 top-level state transition, terminal state, error state는 없다.

## 기대 동작

1. Reset 중에는 leaf module reset 결과가 top 출력으로 전달된다.
2. Master serial 입력은 `slave2_line_sync`를 거쳐 RX로 들어간다.
3. RX가 codeword를 valid로 만들면 Hamming decoder와 `slave_control`이 broadcast를 처리한다.
4. `slave_control`이 halt 상태가 아니면 `slave2_tx`가 timebase trigger와 bit tick을 사용해 응답한다.
5. Timebase는 RX sync pulse, RX active, TX active를 관찰해 lock/status/tick/trigger를 만든다.

## Test Coverage

`tb_slave2_top_smoke.v`는 leaf 기능 검증용 full integration test가 아니다. 실제 leaf source를 컴파일하되, RX 내부 wire를 force하여 top 배선과 control/status 경로만 확인한다. Smoke 목적은 다음으로 제한한다.

- top module port와 parameter override 확인
- 1.0 `slave_hamming_dec`, `slave_control` direct reuse 배선 확인
- `o_SYNCED = rx_sync_pulse`, `o_RATE_LOCKED = timebase_locked` 분리 확인
- `i_GUARD_TICKS`가 `GUARD_TICKS_DEFAULT`로 들어가는지 확인
- halt 상태가 TX enable에 반영되는지 확인

Smoke testbench는 local stub을 사용하지 않는다. 실제 serial frame 수신, timebase lock convergence, TX response decode까지 포함하는 full integration simulation은 별도로 수행해야 한다.

## Verification Result

작성 시점 기준:

- `slave2_line_sync.v`, `slave2_rx.v`, `slave2_timebase.v`, `slave2_tx.v` 실제 source 기반 smoke simulation PASS.
- 실행 명령:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave2_top_smoke\run_xsim.tcl
```

- 결과 marker:

```text
PASS: tb_slave2_top_smoke
```
