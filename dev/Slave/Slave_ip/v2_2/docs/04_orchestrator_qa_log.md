# Slave 2.2 Orchestrator Q&A / 판단 기록

이 문서는 2.2 구현 중 오케스트레이터가 내린 판단과 에이전트 질의에 대한 답변, 그리고 그 근거를 기록한다. 루트의 `ORCHESTRATOR_DECISIONS.md`를 보완하며, 2.2 범위에 한정한다.

## D0. 병렬성 범위 판단 (오케스트레이터 사전 판단)

**판단:** 2.2는 leaf 병렬화 여지가 거의 없다. 단일 신규 leaf(`slave22_timebase`)만 존재하고, 나머지 leaf(`slave21_rx/tx/fault_fsm`, `slave_hamming_*`, `slave_control`, `slave2_line_sync`)는 변경 없이 `reuse/`에 이미 복사되어 단독 PASS 이력이 있다. `slave22_top` → `master_link` → `harsh`는 모두 직전 단계 산출물에 컴파일 의존한다.

**근거:**

- `docs/03_reuse_and_change_inventory.md`: 신규 작성 대상은 `slave22_timebase`, `slave22_top` 둘뿐.
- 따라서 dispatch는 의존성 체인(Step1→2→3→4)을 따라 순차 진행하되, 각 단계 내부의 (설계노트/RTL/TB/sim script) 산출은 한 에이전트가 묶어서 담당한다.
- 사용자 지시("가능한 모듈마다 에이전트")는 leaf 병렬을 강제하는 것이 아니라 모듈 단위 책임 분리를 의미하는 것으로 해석한다. 현재 구조상 leaf 병렬 대상이 1개이므로, 단계별 단일 에이전트가 곧 모듈별 에이전트다.

## D1. 재사용 leaf의 단독 재검증 생략 판단

**판단:** `reuse/` 하위 복사본은 2.2에서 단독 TB를 다시 돌리지 않는다. 통합(top/link) 단계에서 함께 컴파일·동작 검증된다.

**근거:**

- `03_reuse_and_change_inventory.md`가 각 파일의 v2.1 단독/compat PASS 근거를 명시.
- 파일 내용이 byte-identical인지는 오케스트레이터가 dispatch 전 확인한다(아래 검증).
- AGENTS.md "parent TB는 모든 child TB PASS 후" 규칙은 child가 이미 PASS 이력을 가진 재사용 모듈이면 충족된 것으로 본다.

## Q1. (Step 1 에이전트) WAIT_SECOND의 period_valid — 최초 획득 경로 vs holdover 경로

**에이전트 질의/판단:** `00_design_overview.md`의 정책표는 TB22_WAIT_SECOND에서 period_valid=1로 규정한다. 그러나 RESET→WAIT_FIRST→(첫 good)→WAIT_SECOND 의 *최초 획득* 경로에서는 아직 유효한 period 추정이 없다. 에이전트는 첫 good 시점에는 period_valid=0을 유지하고, 두 번째 good(TRACKING 진입)에서 1로 올린다고 구현(T2/T3로 검증). holdover 경로(TRACKING/HOLDOVER→WAIT_SECOND)에서는 valid=1이 그대로 유지된다.

**오케스트레이터 답변: 승인.** 정책표는 "holdover 이후에도 valid를 유지한다"는 의도를 표로 요약한 것이지, 콜드스타트에서 단 한 번의 broadcast만으로 송신 가능하게 하라는 의미가 아니다.

**근거:**
- 2.1 전환 결정(`ORCHESTRATOR_DECISIONS.md`)의 핵심 원칙: "첫 정상 broadcast만으로는 TX를 허용하지 않고, 두 번째 연속 정상 broadcast 이후부터 TX를 허용한다." 콜드스타트 첫 good에서 period_valid=1로 올리면 이 원칙과 충돌한다.
- 정책표의 목적은 Scenario 9(이미 TRACKING이던 노드가 rate_error를 만났을 때)에서 valid가 떨어지지 않게 하는 것. 최초 획득은 별개 경로이며 valid=0 유지가 안전하다.
- 실제 period_valid는 상태가 아니라 `good_interval_ok`(연속 good 2회로 측정된 유효 interval)에서만 set, RESET/miss_limit_exceeded에서만 clear되도록 구현됨 — 상태표와 모순 없이 두 경로를 모두 만족.

**결론:** 구현 그대로 채택. 정책표는 holdover 보존 의도로 읽고, 콜드스타트 첫 good에서 valid=0 유지가 정합적이다.

## D2. link TB의 master broadcast 생성 방식 (오케스트레이터 확인)

**상황:** `tb_slave22_master_link.v`는 슬레이브 응답 수신은 실제 `Master_rx`로 디코드 검증하지만, master→slave broadcast 방향은 `Master_tx` FSM을 인스턴스하지 않고 `slave_hamming_enc`로 codeword를 만들어 TB 드라이버가 직렬 주입한다.

**판단: 허용.** 이는 v2.1 harsh-link seed의 확립된 관례이며, master broadcast의 Hamming 인코딩은 `slave_hamming_enc`와 동일 codeword layout이다(AGENTS.md/이전 분석에서 확정). 핵심 검증 대상인 "슬레이브가 올바른 timing에 응답하고 그 응답이 master 수신기에 디코드되는가"는 실제 `Master_rx`로 확인된다. run_xsim.tcl은 `Master_tx`도 컴파일 목록에 포함해 컴파일 정합성을 유지한다.

**근거:** 결정적 corrupt/유실 시퀀스(Scenario 9)를 정밀 주입하려면 TB가 broadcast 직렬 스트림을 직접 제어하는 편이 Master_tx FSM을 우회 제어하는 것보다 모사가 정확하다.

**정정(D2-a):** Step 4 가혹 TB에서 "양방향 Master_tx 링크로 바꾸라"는 초기 구상은 철회한다. v2.1 harsh-link / comm_worst_case seed 자체가 `slave_hamming_enc` broadcast + 실제 `Master_rx` 구조이며, **2.1 가혹 결과와 직접 비교(regression 판정)** 하려면 동일 TB 골격을 유지해야 한다. 따라서 Step 4도 seed 골격을 그대로 계승하고 DUT만 `slave22_top`으로 교체한다.

## D3. 가혹 TB의 S9 판정 정밀화 (Step 4 후속)

**상황:** Step 4 가혹 TB 2종이 seed의 거친 S9 판정 때문에 holdover 잔존 TX(slot=0, 정상 동작)를 wrong-slot으로 오탐해 `must_pass_fail_count=1` 거짓 FAIL을 냈다.

**판단:** drift/jitter sweep(±0.25/0.50%, H1/H2/H3) 자극·판정은 2.1 비교용으로 **그대로 보존**하고, **S9 판정만** Step 3 link TB(L9)의 정밀 패턴으로 보정했다. corrupt 전송 완료 후 valid_count 리셋 → 잔존 holdover TX와 진짜 recovery TX(slot==NODE_ID)를 구분.

**결과:** 두 가혹 TB 모두 `must_pass_fail_count` 1→0, 요약 라인 FAIL→PASS. 남은 fail 3건은 전부 exploratory(H1/H2/H3, must_pass=0)로 must-pass에 미포함.

**근거:** S9는 Step 3 전용 link TB에서 이미 authoritative하게 PASS 검증된 항목이라, 가혹 TB의 거짓 FAIL은 판정 artifact였다. RTL은 무수정. drift 시나리오 보존으로 2.1 regression 비교 가능성 유지.

## D4. comm_worst_case TB 차별화 (사용자 위임 결정)

**상황:** v2.1 seed의 `tb_slave21_comm_worst_case.v`가 `tb_slave21_master_harsh_link.v`와 byte-identical 사본이었고, 그대로 계승하면 2.2의 두 가혹 TB도 이름만 다른 중복이 된다. 사용자에게 차별화 여부를 질의하려 했으나 응답 불가 상황으로 **오케스트레이터 위임 결정**으로 진행.

**판단: 차별화한다.** 사용자가 요청한 "slave와 master의 가혹한 환경을 모사한 통신 TB"가 의미를 가지려면 단순 중복이 아니라 별도 통신 가혹 조건을 모사해야 한다. harsh_link는 물리 채널(클럭 drift/지터/지연) sweep을 담당하고, comm_worst_case는 클럭/지연을 nominal 고정한 채 **broadcast 손상·blackout 패턴**으로 2.2 신규 로직(holdover, miss_count)을 직접 자극하도록 재설계했다.

**구성:**
- must-pass W1(단발 corrupt→holdover→recovery TX), W2(연속 corrupt miss≤limit→holdover 유지→recovery), W3(간헐 손상→miss_count 클리어→주기 TX 지속) — 전부 PASS(must_pass_fail_count=0).
- exploratory E1(연속 corrupt MISS_RESET_LIMIT 초과 관찰), E2(blackout 후 재획득 관찰) — 관찰 기록.

**잔여 메모:** E1은 TB 자극에서 good commit이 끼어들어 miss>limit default-reset 경로 완전 도달에 실패(관찰만). 단, 이 경로는 단위 TB `tb_slave22_timebase` **T8(miss exceeded resets period)에서 PASS로 이미 검증**되어 커버리지 공백은 없다. comm 레벨에서의 강제 도달은 후속 exploratory 보완 과제로 남긴다.

## 최종 상태 (2026-06-03)

전 단계 xsim PASS. RTL 변경: 신규 `slave22_timebase.v`, `slave22_top.v`뿐. v2.1/Master_ip 무수정.

| sim | 결과 |
|---|---|
| slave22_timebase (단위, T1~T13) | PASS |
| slave22_top_smoke | PASS |
| slave22_top_full_serial | PASS |
| slave22_master_link (L1~L9, **L9=Scenario 9**) | PASS |
| slave22_master_harsh_link (must-pass) | PASS (exploratory H1/H2/H3 FAIL = 관찰, 2.1과 동일, regression 없음) |
| slave22_comm_worst_case (W1~W3) | PASS |
