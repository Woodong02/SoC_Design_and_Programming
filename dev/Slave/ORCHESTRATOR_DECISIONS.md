# Slave IP Orchestrator Decisions

## 목적

이 문서는 slave Verilog 구현 중 에이전트 또는 오케스트레이터가 판단한 사항을 루트 디렉토리에 기록하기 위한 문서이다. 판단은 기존 master source, slave 요구사항 문서, 시뮬레이션 가능성, 향후 확장성을 기준으로 한다.

## 2026-06-02 leaf 구현 시작 결정

### 병렬 담당 범위

- `slave_hamming_enc`: Master `hamming_enc`와 동일한 parity tree 및 codeword layout을 복제한다.
- `slave_hamming_dec`: Master `hamming_dec`와 동일한 SECDED 판정 정책을 복제한다.
- `slave_control`: decoded broadcast 정책만 담당하고 sync/timer 기능은 포함하지 않는다.

판단 이유:

- 세 모듈은 서로 인스턴스 의존성이 거의 없고 write scope가 분리되어 병렬 구현이 가능하다.
- `slave_tx`, `slave_rx`, `slave_slot_timer`, `slave_top`은 Hamming/control 결과와 timing 해석을 통합해야 하므로 오케스트레이터가 직접 기준을 잡은 뒤 순차적으로 쌓는다.

### `slave_control` payload 처리

`slave_control`은 `i_PAYLOAD_IN`을 그대로 `o_PAYLOAD`로 전달한다. `PAYLOAD_DEFAULT` parameter는 `slave_top`에서 입력 payload 선택 정책으로 처리한다.

판단 이유:

- control leaf의 primary function은 halt policy와 broadcast field latch이다.
- payload default 선택까지 control에 넣으면 policy FSM과 top parameter 연결 책임이 섞인다.

### RX sync commit 시점

`slave_rx`는 idle-low에서 첫 `1`을 발견해도 즉시 `o_SYNC_PULSE`를 내지 않는다. `8'hAA` preamble 검증 성공 시점에만 `o_SYNC_PULSE`를 1-cycle assert하고 `o_SYNC_CLK_CNT = 8 * i_BIT_DIV`를 함께 낸다.

판단 이유:

- 첫 `1`만으로 timer를 바꾸면 잘못된 preamble도 slot 기준을 흔들 수 있다.
- 요구사항 문서는 첫 bit를 sync candidate로만 잡고 preamble 성공 시 commit하도록 확정했다.

### Timer guard latch 사용

현재 `slave_slot_timer`는 `slave_control`이 latch한 broadcast `GUARD_TICKS`를 직접 사용하지 않고 top parameter/default timing을 사용한다.

판단 이유:

- 요구사항에서 수신 `GUARD_TICKS`는 관측 및 향후 확장용 latch로 확정했다.
- 동적 timing 변경을 넣으면 resync와 slot length 변경의 적용 시점이 추가 사양을 요구한다.

### Slot length 수식

현재 구현은 `slot_ticks = 50 * i_BIT_DIV + i_GUARD_TICKS`를 사용한다. source에는 향후 대안 `(50 + i_GUARD_TICKS) * i_BIT_DIV`를 주석으로 남긴다.

판단 이유:

- Master `Master_slot.v` 구현과 현재 slave 요구사항이 `50 * BIT_DIV + GUARD_TICKS`를 기준으로 한다.
- 다만 프로젝트 문서가 향후 guard에도 bit divider를 적용할 가능성을 명시하고 있어 확장 위치를 코드에 표시한다.

### Initial sync 직후 slot 0 trigger

`slave_rx`가 preamble 검증 성공 후 `i_SYNC_CLK_CNT = 8 * BIT_DIV`로 timer를 preload하면, 기본 `BIT_DIV=1024`, `GUARD_TICKS=256` 기준으로 slot 0의 `tx_start_tick = GUARD_TICKS >> 1` 지점은 이미 지나 있다. 따라서 `NODE_ID == 0` slave는 첫 sync commit 직후의 slot 0에서는 TX trigger를 내지 않고, 이후 cycle의 slot 0부터 정상 trigger를 낸다.

판단 이유:

- 잘못된 preamble로 timer를 흔들지 않기 위해 preamble 검증 후 sync commit 정책을 유지한다.
- 첫 cycle의 slot 0 보정을 위해 별도 late-trigger를 만들면 Master broadcast 수신 직후 timing 보정 규칙이 새로 필요해지고, 기존 확정 문서의 "별도 off-by-one 보정 없음" 원칙과 충돌한다.

### `slave_top` payload default 처리

`slave_top`은 외부 `i_PAYLOAD`를 실제 response payload로 사용한다. `PAYLOAD_DEFAULT` parameter는 이번 top source에 넣지 않는다.

판단 이유:

- 현재 top interface에는 `i_PAYLOAD`가 항상 존재하므로 "입력이 없으면 default"라는 하드웨어 조건을 표현할 수 없다.
- `i_PAYLOAD == 32'd0`일 때 default를 대신 쓰면 payload 값 0을 정상 송신할 수 없게 된다.
- default payload가 필요한 경우에는 별도 wrapper나 상위 모듈에서 `i_PAYLOAD`에 parameter constant를 연결하는 방식이 더 명확하다.

### 통합 시뮬레이션 `timescale`

Slave RTL 전체와 Master link testbench에서 사용하는 Master leaf 파일에 `` `timescale 1ns / 1ps``를 추가했다.

판단 이유:

- Vivado/xsim 2019.1은 한 design 안에 timescale이 있는 Verilog module과 없는 module이 섞이면 elaboration에서 `XSIM 43-4099` 오류를 낸다.
- `xvlog` 2019.1에는 전체 기본 timescale을 주는 옵션이 없어 source-level directive가 가장 단순하다.
- `timescale` directive는 delay 해석용 metadata이며 합성 가능한 RTL의 논리 기능을 변경하지 않는다.

## 2026-06-03 Slave 2.0 leaf 병렬 구현 결정

### 병렬 담당 범위

사용자 지시에 따라 대기 중인 leaf가 없도록 다음 범위를 병렬 에이전트와 오케스트레이터가 나누어 진행했다.

- `slave2_line_sync`: 2-stage synchronizer leaf. 단독 xsim PASS.
- `slave2_tx`: 1.0 frame/Hamming layout을 유지하되 `i_TX_BIT_TICK` 기반으로 재설계. 단독 xsim PASS.
- `slave2_rx`: `i_SAMPLE_*_TICK` 기반 RX FSM과 optional 3-sample majority sampling 구현. 단독 xsim PASS.
- `slave2_timebase`: 오케스트레이터 직접 구현. sync-to-sync interval 기반 rate correction, pending correction, slot/trigger/tick 생성. 단독 xsim PASS.
- `slave_hamming_enc`, `slave_hamming_dec`, `slave_control`: 1.0 source를 수정 없이 재사용하고 compatibility TB로 xsim PASS.
- `slave2_top`: 실제 leaf source 기반 smoke simulation PASS.

### `slave2_timebase` sync preload 정책

`slave2_rx.o_SYNC_PULSE`는 `8'hAA` preamble 검증 후 발생한다. 따라서 `slave2_timebase`는 sync event에서 slot counter를 `8 * bit_period_est`로 preload한다.

판단 이유:

- Slave 1.0의 `o_SYNC_CLK_CNT = 8 * BIT_DIV` 의미를 유지한다.
- 잘못된 preamble 후보로 slot phase를 흔들지 않고, 검증된 preamble boundary에서만 phase를 commit한다.

### `slave2_timebase` correction 보류 정책

`i_RX_ACTIVE` 또는 `i_TX_ACTIVE` 중 들어온 valid sync interval의 rate correction은 pending으로 저장하고, RX/TX가 모두 inactive인 boundary에서 적용한다. Sync event 자체의 phase reset은 preamble boundary로 보고 즉시 적용한다.

판단 이유:

- active frame 중 bit period estimate 변경으로 인한 bit skip/repeat를 막는다.
- RX가 preamble 검증 cycle에 active를 유지하는 구현과 호환된다.

### `slave2_top` smoke 검증 범위

`tb_slave2_top_smoke`는 실제 `slave2_*` leaf를 컴파일하지만, RX 내부 wire를 force하여 control/status wiring만 확인한다. 이 테스트는 full serial integration이 아니다.

남은 다음 단계:

- Master-compatible serial broadcast를 실제 `i_MASTER_SERIAL`로 주입하는 `slave2_top` 통합 TB 작성.
- Master RX/TX leaf와 연결한 robust link TB 작성.
- 기존 1.0 한계였던 drift/jitter/line-delay scenario를 2.0 기준으로 재검증.

## 2026-06-03 Slave 2.1 전환 결정

Slave 2.0 개발은 중단하고 산출물은 비교/분석용으로 보존한다. 2.1은 2.0과 같은 강인성 목표를 유지하되, `slave2_timebase`가 RX/TX bit tick까지 직접 공급하는 구조를 버리고 frame-complete commit 구조로 전환한다.

전환 의도:

- Master broadcast를 끝까지 수신하고 preamble/Hamming이 정상인 경우에만 상태를 commit한다.
- 첫 정상 broadcast만으로는 TX를 허용하지 않고, 두 번째 연속 정상 broadcast 이후부터 TX를 허용한다.
- Slave fault FSM은 영구 정지가 아니라 TX 금지와 다음 broadcast 재획득을 관리하는 recovery 상태기로 정의한다.
- RX/TX는 frame 시작 시 bit period를 snapshot하고 자체 frame-local timer로 동작한다.
- Slave가 확신 없는 상태에서 송신해 Master severe slot timeout을 유발하는 것을 방지한다.

작성 문서:

- `Slave_ip/v2_1/README.md`
- `Slave_ip/v2_1/docs/00_slave2_1_frame_commit_structure.md`
- `Slave_ip/v2_1/docs/01_slave2_1_agent_work_plan.md`
- `Slave_ip/v2_1/docs/02_slave2_1_verification_plan.md`

## 2026-06-03 Slave 2.2 구현 완료

2.1의 Scenario 9 must-pass 실패(TRACKING 중 broadcast 유실 후 recovery 경로에서 TX 미발생)를 해결했다. 근본 원인은 `slave21_timebase`가 `rate_error_event`에서 `period_valid`를 0으로 리셋하여 fault_fsm(2회 재획득)과 timebase(추가 측정 필요) 간 재획득 횟수가 어긋난 것이었다.

해결: `slave22_timebase`에 holdover 도입 — rate_error 시 마지막 good bit_period와 period_valid를 유지하고, 연속 miss를 `miss_count`로 추적해 `MISS_RESET_LIMIT(기본 4)` 초과 시에만 default 리셋한다. fault_fsm·rx·tx·hamming·control·line_sync는 변경 없이 재사용.

신규 RTL: `slave22_timebase.v`, `slave22_top.v`(timebase 인스턴스만 교체). v2.1/Master_ip 무수정.

검증(xsim 2019.1, 전부 PASS):
- 단위: `tb_slave22_timebase`(T1~T13, holdover/miss_count/Scenario 9 포함)
- 통합: `tb_slave22_top_smoke`, `tb_slave22_top_full_serial`
- 통신: `tb_slave22_master_link`(L1~L9, **L9=Scenario 9 PASS**)
- 가혹: `tb_slave22_master_harsh_link`(must-pass PASS, ±1%/반비트는 exploratory 관찰 — 2.1과 동일), `tb_slave22_comm_worst_case`(broadcast 손상/blackout 패턴으로 차별화, W1~W3 PASS)

세부 판단·에이전트 질의응답은 `Slave_ip/v2_2/docs/04_orchestrator_qa_log.md`에 기록.
