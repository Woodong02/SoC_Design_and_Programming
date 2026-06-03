# `slave2_line_sync` 설계 노트

## 목적

`slave2_line_sync`는 외부 board에서 들어오는 asynchronous serial line을 Slave 2.0의 `i_CLK` domain으로 동기화하는 leaf module이다.

Master와 Slave는 서로 다른 clock domain에서 동작할 수 있으므로, serial 입력은 Slave 내부 RX logic에 직접 연결하지 않는다. 이 module은 metastability 전파 위험을 줄이기 위해 2-stage synchronizer만 제공한다.

## 기준 및 범위

- 대상 source: `Slave_ip/v2_0/slave2_line_sync.v`
- 대상 testbench: `tb/tb_slave2_line_sync.v`
- HDL: pure Verilog, Vivado 2019.1 xsim compatible
- Coding standard: `CODING_STANDARDS.md`

이 module은 glitch filter, edge detector, preamble detector 기능을 포함하지 않는다. 짧은 glitch 제거가 필요하면 별도 `slave2_line_filter` 같은 leaf module로 분리해야 한다.

## Module Interface

```verilog
module slave2_line_sync (
    input  wire i_CLK,
    input  wire i_RESETN,
    input  wire i_SERIAL_ASYNC,
    output wire o_SERIAL_SYNC
);
```

### 입력

- `i_CLK`: Slave 2.0 내부 기준 clock.
- `i_RESETN`: active-low reset. reset 동안 synchronizer stage는 모두 `0`으로 초기화된다.
- `i_SERIAL_ASYNC`: 외부 asynchronous serial 입력.

### 출력

- `o_SERIAL_SYNC`: `i_CLK` domain으로 2-stage 동기화된 serial signal.

## 내부 구조

입력 포트는 coding standard에 따라 내부 wire로 먼저 복사한다.

```text
i_SERIAL_ASYNC -> serial_async -> ff_sync_stage1 -> ff_sync_stage2 -> serial_sync -> o_SERIAL_SYNC
```

`ff_sync_stage1`은 asynchronous 입력을 첫 번째 clock edge에서 capture한다. `ff_sync_stage2`는 그 다음 clock edge에서 첫 번째 stage 값을 capture한다. 따라서 안정적으로 유지된 입력 변화는 `o_SERIAL_SYNC`에 2개 rising edge 후 반영된다.

## FSM 정의

FSM 없음.

이 module은 state machine이 아니라 2개의 flip-flop stage로 구성된 synchronizer이다. reachable internal stage 조합은 입력 변화 순서에 따라 다음 네 가지가 모두 가능하다.

- `ff_sync_stage1=0`, `ff_sync_stage2=0`
- `ff_sync_stage1=1`, `ff_sync_stage2=0`
- `ff_sync_stage1=1`, `ff_sync_stage2=1`
- `ff_sync_stage1=0`, `ff_sync_stage2=1`

상태 전이는 별도 FSM case로 관리하지 않고, 매 clock edge마다 stage pipeline 동작으로 결정된다.

## Reset 동작

`i_RESETN=0`이면 두 stage가 모두 `0`이 된다. reset 해제 후 `i_SERIAL_ASYNC`가 `1`로 유지되면:

```text
release reset
1st posedge: ff_sync_stage1=1, ff_sync_stage2=0, o_SERIAL_SYNC=0
2nd posedge: ff_sync_stage1=1, ff_sync_stage2=1, o_SERIAL_SYNC=1
```

reset 중 입력이 `1`이어도 출력은 `0`이어야 한다.

## 기대 동작

- 안정적인 `0 -> 1` 입력 변화는 2개 clock edge 뒤 출력 `1`로 반영된다.
- 안정적인 `1 -> 0` 입력 변화는 2개 clock edge 뒤 출력 `0`으로 반영된다.
- 1-clock 폭 입력 pulse도 pipeline latency에 따라 출력에서 1-clock pulse로 관측된다.
- 이 module은 asynchronous 입력의 실제 metastability를 simulation에서 재현하지 않는다. 검증은 deterministic pipeline latency와 reset 동작 확인에 집중한다.

## Test Coverage

`tb_slave2_line_sync`는 self-checking 방식으로 다음을 검증한다.

- reset 동안 `o_SERIAL_SYNC=0`
- reset 중 `i_SERIAL_ASYNC=1`이어도 stage와 출력이 `0`
- reset 해제 후 stable high 입력의 2-stage latency
- stable low 입력의 2-stage latency
- 1-clock pulse가 2-clock latency 후 1-clock 출력 pulse로 전달
- 내부 synchronizer stage의 reachable 조합 `00`, `10`, `11`, `01`

## 검증 결과

초기 작성 시점의 xsim 실행 결과는 `sim/slave2_line_sync/README.md`에 기록한다.
