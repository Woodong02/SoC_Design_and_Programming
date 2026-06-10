# Slave AXI IP 문서 정합성 검토

## 1. 검토 기준

이번 설계 문서 세트는 아래 원칙을 source of truth로 공유한다.

```text
bit_period_ticks = DIV_REG + 1
frame_ticks      = 50 * bit_period_ticks
slot_ticks       = frame_ticks + GUARD_TICKS
tx_start[n]      = frame_ticks + n * slot_ticks + (GUARD_TICKS >> 1)
```

그리고 하나의 IP instance가 8개 가상 slot을 담당하며, `ACTIVE_SLOT[7:0]`로 송신할 slot을 선택한다.

## 2. 문서별 역할

| 문서 | 역할 |
| --- | --- |
| `docs/10_next_slave_ip_design_ko.md` | 차기 IP의 동작 방향과 설계 결정 |
| `docs/11_slave_ip_module_interfaces_ko.md` | 모듈 분리와 모듈 간 신호 |
| `docs/12_slave_ip_register_map_ko.md` | register map 설계 문서 |
| `docs/13_slave_ip_user_manual_ko.md` | PS 사용자 관점 운용 절차 |
| `docs/14_slave_ip_vv_test_plan_ko.md` | V&V 및 full-case 테스트 계획 |
| `docs/15_slave_ip_dependencies_ko.md` | 종속성, 리스크, 구현 전 확인 사항 |
| `docs/16_slave_ip_coding_comment_rules_ko.md` | 작명, 주석, 코드 구조 규칙 |
| `slave_regmap.md` | 구현자가 바로 보는 register map 기준 문서 |

## 3. 확인된 정합성

| 항목 | 결론 |
| --- | --- |
| `DIV` 의미 | 모든 차기 문서에서 `DIV_REG + 1`로 통일 |
| frame 길이 | 모든 차기 문서에서 50-bit 유지 |
| slot timing | `frame + n*slot + guard_half`로 통일 |
| guard 의미 | slot 내 총 무송신 시간으로 통일 |
| active slot | 8-bit mask로 통일 |
| payload source | slot 0~5 PS, slot 6~7 PL로 통일 |
| config update | sync boundary snapshot으로 통일 |
| 기존 RTL과 차기 설계 구분 | 현재 RTL 문서와 차기 설계 문서 번호 분리 |

## 3.1 검토 반영 결정

| 검토 이슈 | 반영 결정 |
| --- | --- |
| `STATUS/EVENT/FAULT` 권장/필수 혼재 | v1 필수 관측 레지스터로 승격. `DBG_*`도 현재 RTL에 구현됨 |
| `DIV_REG+1` overflow | `bit_period_ticks` 33-bit, timing/counter/table 64-bit 기준 |
| sync와 AXI write 동시성 | sync edge 이전 clock까지 commit된 shadow만 현재 cycle에 포함 |
| sync snapshot clock ordering | idle 상태에서 shadow commit, sync edge에서는 commit된 shadow freeze |
| TX handshake 부족 | sequencer/frame/serializer 사이 ready/valid 및 accept/skip 신호 사용 |
| coding standard 폭 충돌 | protocol/timing/frame 신호는 의미 폭 unsigned 사용을 명시 |
| TX payload 책임 혼재 | sequencer는 slot id만 발행하고 payload table이 payload/valid를 담당 |
| broadcast halt optional 여부 | v1에서 유지하며 다음 sync cycle부터 적용하는 것으로 확정 |
| `schedule_active` idle 복귀 | `slot_cycle_done`으로 scheduler를 clear하여 config commit idle 경계를 다시 연다 |

## 4. 의도적으로 남긴 선택지

아래 항목은 구현 전 최종 환경에 따라 달라질 수 있어 권장안으로 문서화했다.

| 항목 | 권장안 |
| --- | --- |
| `o_slave_oe` | 제공 권장. push-pull 연결이면 상위에서 무시 가능 |
| interrupt | `EVENT/FAULT` 기반 optional `o_irq` 권장 |
| broadcast halt 적용 | 다음 sync cycle부터 적용 |
| debug timing register | 현재 RTL에 구현됨. 최종 IP에서 축소하려면 register map과 TB를 함께 수정 |
| 기존 `slave21_tx/rx` | 기능 분리 관점에서 새 wrapper 또는 재작성 권장 |

## 5. 개발 중 주의할 충돌

### 5.1 현재 README와 차기 문서

README에는 현재 RTL 설명이 남아 있다. 구현이 차기 IP로 넘어가면 README의 timing 식도 새 식으로 교체해야 한다.

### 5.2 기존 `slave21_tx`와 새 모듈 분리

기존 TX는 frame build와 serializer가 결합되어 있다. 새 문서에서는 이 둘을 분리한다. 직접 재사용하려면 wrapper를 만들되, 최종 구조 문서에는 분리된 책임을 유지해야 한다.

### 5.3 `GUARD_TICKS` 최소값

의미상 timing 공식은 `GUARD_TICKS >> 1`을 사용하지만, v1 RTL은 pipeline 여유를 보장하기 위해 scheduled TX에서 `GUARD_TICKS >= 4`를 요구한다. 0~3은 `FAULT_SLOT_TIMING_INVALID`로 처리하고 TX를 시작하지 않는다. master decode latency와 halt 즉시 적용은 충돌할 수 있으므로 halt는 다음 sync 적용으로 정리했다.

### 5.4 `DIV_REG` 폭

register는 32-bit이고 내부 timing은 33/64-bit 기준으로 문서화했다. 구현 resource 제약으로 폭을 줄이면 `FAULT_SLOT_TIMING_INVALID`와 사용자 문서에 max 값을 추가해야 한다.

### 5.5 TX command handshake

slot sequencer는 slot id만 발행한다. payload table은 slot id에 따라 payload와 valid를 만들고, frame builder는 `tx_frame_ready`가 1일 때만 command를 수락한다. payload invalid, TX busy, frame builder busy는 silent drop이 아니라 skip/event/fault로 관측 가능해야 한다.

### 5.6 Scheduler idle clear

`schedule_active`는 sync 이후 slot scan 동안 high이며, `slot_cycle_done`이 들어오면 low로 돌아간다. 이 신호는 `core_idle`과 `STATUS.STS_SYNCED`에 연결되므로, cycle 완료 후 다음 pending config commit이 가능해야 한다.

## 6. 구현 시작 전 체크리스트

- `slave_regmap.md`와 `docs/12_slave_ip_register_map_ko.md`가 같은 offset/bit field를 유지하는지 확인.
- `docs/10`의 timing source와 scheduler RTL 공식이 일치하는지 확인.
- slot 6/7 PL payload port 이름과 valid 정책을 top-level에서 확정.
- Hamming encoder/decoder master vector를 확보.
- AXI byte strobe testbench를 준비.
- synthesis 후 timing path가 scheduler precompute stage에서 끊겼는지 확인.
