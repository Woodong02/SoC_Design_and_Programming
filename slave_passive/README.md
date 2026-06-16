# Slave IP v2.3 Passive

최신 `master_top` 기능 검증을 위한 최소 기능 Slave IP이다.

## 현재 RTL 특징

- master 입력선의 첫 `1`을 frame 시작으로 사용한다.
- `tx_start = 50*BIT_PERIOD + NODE_ID*(50*BIT_PERIOD + GUARD_TICKS)` 시점에 응답한다.
- 응답 frame은 `8'hAA + hamming_enc({NODE_ID, PAYLOAD})`이다.
- broadcast의 `halt_cmd[NODE_ID]`가 1이면 송신을 중단한다.
- recovery, holdover, rate correction, fault FSM은 포함하지 않는다.

## Source

| File | 설명 |
|---|---|
| `slave23_passive_top.v` | passive slave top FSM |
| `reuse/` | 기존 검증 모듈 재사용 |

## Documents

| File | 설명 |
|---|---|
| `docs/03_current_slave23_passive_spec.md` | 현재 RTL 기준 상세 사양 |
| `docs/03_current_slave23_passive_spec_ko.md` | 현재 RTL 기준 상세 사양 한국어본 |
