# Slave IP v2.3 Passive

최신 `master_top` 기능 검증을 위한 최소 기능 Slave IP이다.

## 현재 RTL 특징

아래 내용은 현재 저장소의 legacy/passive RTL 기준이다. 차기 AXI IP 설계 기준은 `slave_regmap.md`와 `docs/10_next_slave_ip_design_ko.md`를 따른다.

- master 입력선의 첫 `1`을 frame 시작으로 사용한다.
- `tx_start = 50*BIT_PERIOD + NODE_ID*(50*BIT_PERIOD + GUARD_TICKS)` 시점에 응답한다.
- 응답 frame은 `8'hAA + hamming_enc({NODE_ID, PAYLOAD})`이다.
- broadcast의 `halt_cmd[NODE_ID]`가 1이면 송신을 중단한다.
- recovery, holdover, rate correction, fault FSM은 포함하지 않는다.

## 차기 AXI IP 설계 기준

- PS가 AXI-Lite register로 `ENABLE`, `DIV`, `GUARD_TICKS`, `ACTIVE_SLOT`, `DATA_OUT0`~`DATA_OUT5`를 설정한다.
- `DIV`는 지수값이 아니며 실제 bit period는 `DIV_REG + 1`이다.
- 하나의 IP instance가 slot 0~7을 가상 slave로 담당한다.
- slot TX 시작 시점은 `frame_ticks + slot_id*slot_ticks + (GUARD_TICKS >> 1)`이다.
- v1 AXI IP 구현은 scheduled TX에서 `GUARD_TICKS >= 4`를 요구하며, 0~3은 timing fault로 처리한다.
- slot 0~5 payload는 PS register, slot 6~7 payload는 PL 내부 입력에서 온다.

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
| `slave_regmap.md` | 차기 AXI IP 레지스터맵 기준 문서 |
| `docs/10_next_slave_ip_design_ko.md` | 차기 AXI slave IP 설계 방향 |
| `docs/11_slave_ip_module_interfaces_ko.md` | 차기 IP 모듈 간 인터페이스 정의 |
| `docs/12_slave_ip_register_map_ko.md` | 차기 IP 레지스터맵 확정안 |
| `docs/13_slave_ip_user_manual_ko.md` | PS 사용자 매뉴얼 |
| `docs/14_slave_ip_vv_test_plan_ko.md` | V&V 및 테스트 계획 |
| `docs/15_slave_ip_dependencies_ko.md` | 종속성 및 리스크 문서 |
| `docs/16_slave_ip_coding_comment_rules_ko.md` | 작명 및 주석 규칙 |
| `docs/17_slave_ip_consistency_review_ko.md` | 문서 정합성 검토 |
