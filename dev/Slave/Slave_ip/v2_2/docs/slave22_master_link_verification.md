# slave22_master_link 통합 검증 결과

## 개요

- DUT: `slave22_top` (slave21_master link/harsh-link seed에서 DUT만 교체)
- Master leaf: `Master_rx`, `hamming_dec`(master 측 디코더), `slave_hamming_enc`(master broadcast 인코더) 그대로 연결
- TB: `tb/tb_slave22_master_link.v`
- 실행: `sim/slave22_master_link/run_xsim.tcl` (Vivado xsim 2019.1)
- 환경: 분리된 master/slave 클럭, 파라미터화된 클럭 skew / start phase / 전파지연 / 결정적 지터

## 실행 방법

```
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch \
  -source 'C:\Users\sinsu\Desktop\myproject\sim\slave22_master_link\run_xsim.tcl' -nojournal -nolog
```

xsim.log 위치: `sim/slave22_master_link/xsim_run/xsim.log`

## must-pass 시나리오 결과 (L1~L9)

| 번호 | 시나리오 | 조건 | 결과 |
|---|---|---|---|
| L1 | nominal 클럭, 지연 없음 | slave=10.0000ns, delay/jitter=0 | PASS |
| L2 | 임의 start phase | start_phase=3.750ns | PASS |
| L3 | 슬레이브 클럭 +0.25% | slave=9.9750ns | PASS |
| L4 | 슬레이브 클럭 -0.25% | slave=10.0250ns | PASS |
| L5 | 슬레이브 클럭 +0.50% | slave=9.9500ns | PASS |
| L6 | 슬레이브 클럭 -0.50% | slave=10.0500ns | PASS |
| L7 | 전파지연 + 결정적 지터 | m2s=28ns±5, s2m=36ns±7 | PASS |
| L8 | 첫 frame corrupt 후 recovery | bad preamble 후 2 good | PASS |
| **L9** | **TRACKING 중 유실(corrupt) 후 recovery TX (Scenario 9)** | corrupt 후 holdover→2 good→TX | **PASS** |

전체 요약 라인:

```
PASS: tb_slave22_master_link must-pass scenarios L1-L9 survived total_scenarios=9 fail_count=0
```

## L9 (Scenario 9) 상세

이것이 2.1에서 must-pass FAIL이던 핵심 항목이며, 2.2 holdover 설계로 PASS를 달성했다.

### 자극 시퀀스 (design_overview Scenario 9 재현 순서)

1. **단계 ①** 정상 broadcast 2회 → TRACKING 진입, 초기 TX 정상 수신
2. **단계 ②** corrupt broadcast(잘못된 preamble) 1회 → fault_fsm TRACKING→RECOVERY,
   good_broadcast_commit 없음, timebase interval_count 계속 증가
3. **단계 ③** 첫 recovery good → fault_fsm RECOVERY→SEEN_ONCE, good_broadcast_commit 발생,
   interval이 expected의 약 2배 → rate_error_event 발생.
   **2.2 holdover**: period_valid=1 유지, bit_period 유지. tx_allowed 아직 아님 → TX 없음
4. **단계 ④** 두 번째 recovery good → fault_fsm SEEN_ONCE→TRACKING, tx_allowed=1.
   period_valid가 holdover로 1 유지 → tx_trigger_match 발생 → **슬레이브 TX가 Master_rx에 정상 수신**

### 로그 핵심 라인

```
[SCENARIO 9] L9 Scenario 9: tracking loss (corrupt) then recovery TX
[PASS] L9 step1 tracking TX before loss response decoded payload=0x99cc3003 slot=1 clk_cnt=807
[PASS] L9 step1 link TRACKING established fault_state=3
[INFO] L9 step2 corrupt broadcast delivered, fault_state=4 (expect demote from TRACKING)
[PASS] L9 step2 corrupt broadcast triggers no new tx
[PASS] L9 step2 corrupt broadcast triggered no new response
[PASS] L9 step3 first recovery good no tx (rate_err holdover)
[PASS] L9 step4 recovery TX after tracking loss response decoded payload=0x99cc3003 slot=1 clk_cnt=807
```

- `fault_state=3`(TRACKING) → corrupt 후 `fault_state=4`(RECOVERY) 데모트 확인.
- 단계 ④에서 payload `0x99cc3003`이 slot=1, node=1로 Master_rx에 정상 디코드됨
  (`[WAVE] ... payload=0x99cc3003 ... time=370445000`).
- 2.1에서는 이 지점에서 period_valid가 0으로 리셋되어 tx_trigger_match가 발생하지 않아
  TX 없음(BUG)이었다. 2.2 holdover로 PASS.

### L9가 Scenario 9를 정확히 모사함을 보장한 방법

- 단계 ②에서 단순 zero/halt frame이 아닌 **실제 corrupt frame(bad preamble 0xAB)** 을 주입하여
  good_broadcast_commit이 발생하지 않고 fault_fsm이 TRACKING에서 demote되도록 강제했다
  (`fault_state=4`로 확인).
- corrupt frame으로 한 interval을 통째로 건너뛰어, 다음 good에서 측정되는 interval이
  expected의 약 2배가 되어 rate_error_event가 확정적으로 발생하도록 했다.
- 단계 ③/④에서 연속 2회 good broadcast를 주입하여 fault_fsm의 재획득(2회)과
  timebase의 holdover 정책이 어긋나지 않음을 확인했다.
- 단계 ④의 두 번째 good 직후 슬레이브 TX가 Master_rx에 디코드되는지를 self-check로 검증했다.

### step2 검사 정밀화 (TB 주석)

단계 ②에서 직전 TRACKING 사이클의 **주기적 TX가 잔존**하여 corrupt frame interval에 Master_rx로
수신될 수 있다(슬레이브 정상 동작, 첫 시도에서 `slot=0` 잔존 TX 관측됨). 이는 RTL 버그가 아니라
TB의 표본 시점 문제이므로, "corrupt frame 수신 완료 이후 **새 TX가 발생하지 않음**"을 검사하도록
정밀화했다. 잔존 TX와 신규 TX를 구분하여 Scenario 9 의도를 정확히 검증한다.

## 작성/산출 파일

- `tb/tb_slave22_master_link.v`
- `sim/slave22_master_link/run_xsim.tcl`
- `Slave_ip/v2_2/docs/slave22_master_link_verification.md` (본 문서)

## 질의 / 미해결

없음. slave22_timebase / slave22_top 수정 없이 L1~L9 전부 PASS.
RTL 변경 없음.
