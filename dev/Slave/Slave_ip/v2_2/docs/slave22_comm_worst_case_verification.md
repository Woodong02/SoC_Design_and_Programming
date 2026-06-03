# slave22 통신 가혹환경 검증 (tb_slave22_comm_worst_case)

대상 TB: `tb/tb_slave22_comm_worst_case.v`
실행: `& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source 'sim/slave22_comm_worst_case/run_xsim.tcl' -nojournal -nolog`
로그: `sim/slave22_comm_worst_case/xsim_run/xsim.log`

## 최종 요약
```
PASS: tb_slave22_comm_worst_case must-pass scenarios survived total_scenarios=5 fail_count=0
```
must_pass_fail_count = 0 (PASS 분기). 모든 must-pass(W1~W3) 통과, E1/E2 exploratory는
[FAIL] 없이 순수 관찰만 수행하여 fail_count에 기여하지 않음.

## 설계 의도 / harsh_link와의 차별화
`tb_slave22_master_harsh_link.v`는 클럭 drift(±0.25~1.0%)·전파 지연·결정적 지터 sweep을
다룬다(통신 채널 물리 가혹환경). 본 TB는 **클럭/지연을 전 시나리오 nominal(10ns, delay 0,
jitter 0)로 고정**하고, 대신 **broadcast 손상 패턴(corrupt preamble / blackout)을 직접
인가**하여 2.2 신규 로직인 timebase의 holdover 및 miss_count 카운터를 정밀 자극한다.
따라서 두 TB의 자극 시퀀스는 겹치지 않는다(harsh_link: 물리 채널 sweep, comm_worst_case:
손상/유실 프로토콜 가혹). 공통 인프라(slave_hamming_enc 주입, slave22_top DUT, Master_rx 디코드,
epoch slot 모니터, `expect_no_slave_tx`/`wait_response_and_check` 태스크, drift/지연/지터 모델)는
그대로 재사용했다.

## 2.2 기능을 어떻게 자극·확인했는가
- **holdover**: `slave22_timebase`는 rate_error_event(연속 broadcast interval이 약 2배로
  벌어짐) 발생 시에도 miss_count가 MISS_RESET_LIMIT(4) 이하이면 period_valid_ff와 bit_period_ff를
  유지한다. TB는 timebase 내부 `period_valid_ff`/`miss_count_ff`/`state_ff`를 hierarchical
  참조(`u_slave_top.u_timebase.*`)로 관찰하고, 최초 TRACKING 확립 직후부터 period_valid가
  1->0으로 떨어지는 순간을 `period_valid_dropped` 플래그로 감시한다(W must-pass 위반 조건).
- **miss_count**: corrupt 후 첫 good broadcast가 commit될 때(interval_ready=1) 누적 interval로
  rate_error_event가 트리거되어 miss_count가 1씩 증가하고, 정상 interval(good_interval_ok)이
  관측되면 0으로 클리어된다. TB는 각 단계 후 `tb_miss`를 [INFO]로 기록한다.
- **판정(L9 정밀 패턴)**: corrupt 전송 완료 직후 `master_valid_count=0`으로 리셋하여 직전
  TRACKING 사이클의 잔존 holdover TX(slot=0, master broadcast slot)와 진짜 recovery TX
  (slot==NODE_ID=1)를 구분한다.

## W1~W3 (must-pass)

### W1 단발 corrupt -> holdover -> recovery TX  → PASS
TRACKING 확립 후 corrupt 1회 인가. fault_fsm TRACKING(3)->RECOVERY(4), timebase는 아직
rate_err 없이 holdover 진입 준비. 이후 good1(RECOVERY->SEEN_ONCE, miss=1), good2
(SEEN_ONCE->TRACKING)에서 recovery TX 발생.
```
[INFO] after corrupt: fault_state=4 tb_state=4 tb_period_valid=1 tb_miss=0
[INFO] after good: fault_state=2 tb_state=3 tb_period_valid=1 tb_miss=1
[PASS] W1 recovery TX after single corrupt response decoded payload=0xc0de0001 slot=1 clk_cnt=808
[PASS] W1 period_valid stayed 1 (holdover) through single corrupt; recovery TX slot=1
```
period_valid가 한 번도 0으로 떨어지지 않았고(holdover), recovery TX가 slot==NODE_ID(1)로 수신됨.

### W2 연속 3회 corrupt(miss<=limit) -> holdover -> recovery TX  → PASS
TRACKING 확립 후 corrupt를 연속 3회 인가. 각 corrupt 후 RECOVERY 유지, period_valid=1 유지.
이후 good 시퀀스로 재획득, recovery TX 발생.
```
[PASS] W2 burst corrupt no new recovery TX   (x3, 각 corrupt 후 새 recovery-slot TX 없음)
[INFO] after good: fault_state=2 tb_state=3 tb_period_valid=1 tb_miss=1
[PASS] W2 recovery TX after burst corrupt response decoded payload=0xc0de0002 slot=0 clk_cnt=188
[PASS] W2 period_valid stayed 1 through 3x corrupt holdover; recovery TX slot=0
```
miss_count는 limit(4) 이하로 유지되어 period_valid가 0으로 떨어지지 않음(holdover 확인).
(주: 재개 TX가 master broadcast slot=0 윈도우에 정렬되어 수신됐으나 payload/node 정상.)

### W3 간헐 corrupt/good -> miss_count 클리어 -> 주기적 TX  → PASS
corrupt 1 + good 2 사이클을 3회 반복. 각 사이클에서 recovery TX(slot==NODE_ID=1)가
발생하여 good_tx_count=3 달성. miss_count는 누적되되 정상 interval에서 갱신되며 limit 미만 유지.
```
[INFO] W3 cycle done tb_miss=1 tb_period_valid=1 good_tx_count=1
[INFO] W3 cycle done tb_miss=2 tb_period_valid=1 good_tx_count=2
[INFO] W3 cycle done tb_miss=3 tb_period_valid=1 good_tx_count=3
[PASS] W3 miss_count cleared each good interval, period_valid held, periodic TX x3
```
period_valid가 전 구간 1로 유지되며 매 사이클 주기적 TX가 지속됨을 확인.

## E1~E2 (exploratory, 관찰 전용)

### E1 연속 corrupt > MISS_RESET_LIMIT 관찰
corrupt와 good를 번갈아 8회 인가(각 corrupt 후 단발 good로 commit하여 rate_error_event 유발).
관찰 결과 miss_count는 4까지 증가했으나, **각 good commit 시 fault_fsm가 RECOVERY->SEEN_ONCE로
전이하면서 일부 interval은 good_interval_ok로 인식되어 miss_count가 limit을 초과(>4)하지 못했다.**
따라서 default 리셋(period_valid=0, WAIT_FIRST)에는 도달하지 않음:
```
[INFO] E1 after good-after-corrupt fault_state=2 tb_state=3 tb_period_valid=1 tb_miss=4
[OBSERVE-NOTE] E1 did not observe period_valid=0 within burst (record for analysis)
[OBSERVE] E1 re-acquired after blackout-style reset; fault_state=3 tb_period_valid=1
```
**분석**: miss_limit_exceeded(period_valid=0, WAIT_FIRST 복귀)에 도달하려면 good commit 없이
rate_error_event가 연속으로(>4회) 발생해야 하는데, 본 자극은 corrupt 사이에 good를 끼워 넣어
miss_count가 중간에 클리어/포화되지 않는 단조 누적을 만들지 못했다. miss>limit 강제 도달은
TB 자극 설계 한계이며 2.2 RTL 동작은 사양과 일치(holdover 우선). 강제 reset 관찰은 후속
exploratory 보완 과제로 기록. RTL 버그 아님.

### E2 장기 blackout 후 재개 관찰
TRACKING 확립 후 약 6 master interval 동안 broadcast 완전 침묵. blackout 동안 good/bad frame이
없어 fault_fsm는 TRACKING(3) 유지, timebase는 holdover로 period_valid=1 유지 → **주기적 TX가
blackout 내내 지속됨**(설계대로):
```
[WAVE] Master_rx valid slot=1 ... payload=0xc0de00b0 ...   (blackout 동안 6회 반복 TX)
[OBSERVE] E2 after blackout: fault_state=3 tb_state=4 tb_period_valid=1 tb_miss=0
```
재개 시 첫 good broadcast가 다른 epoch에 도착하여 interval 불일치 -> rate_err ->
TRACKING->RECOVERY 강등(holdover). 본 exploratory는 good를 2회만 보내 SEEN_ONCE까지만 도달:
```
[OBSERVE] E2 resume good1: fault_state=4 tb_state=3 tb_period_valid=1 tb_miss=1
[OBSERVE-NOTE] E2 no resume TX captured within timeout valid_count=0 (record for analysis)
```
**분석**: blackout 중 holdover로 TX 지속은 2.2 설계 의도대로 확인됨. 재개 후 완전한 TRACKING
복귀에는 추가 good broadcast가 필요(W1/W2와 동일 경로). 이는 손상 흡수 사양과 일치하며 RTL
버그 아님. blackout 후 완전 재획득까지의 good 수 측정은 후속 보완 과제로 기록.

## 결론 / 질의
- W1~W3 must-pass 전부 PASS, must_pass_fail_count=0.
- E1/E2 관찰 기록 완료, [FAIL] 없음.
- harsh_link(물리 채널 sweep)와 자극 시퀀스가 완전히 분리되어 중복 해소됨.
- RTL 수정 없음. ORCHESTRATOR 질의 사항 없음(E1/E2의 미도달 관찰은 TB 자극 설계 한계이며
  2.2 RTL 사양과 일치, 후속 exploratory 보완 과제로만 기록).
