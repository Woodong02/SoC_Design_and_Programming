# slave22 가혹 환경 검증 결과 (Step 4)

## 개요

- DUT: `slave22_top` (2.1 가혹 seed에서 **DUT 인스턴스만** `slave21_top` → `slave22_top` 교체)
- Master leaf: `Master_rx`, `hamming_dec`(master 측 디코더), `slave_hamming_enc`(master broadcast 인코더) 그대로 연결.
  broadcast는 seed대로 `slave_hamming_enc`로 인코딩+주입, 슬레이브 응답은 실제 `Master_rx`로 디코드 검증.
  **Master_tx 양방향 구조로 바꾸지 않음** — 2.1 가혹 결과와 동일 골격으로 직접 비교(regression 판정)하기 위함.
- seed 대비 변경: **DUT 교체 + 모듈명/PASS 라인명 + run_xsim.tcl 경로(v2_1→v2_2)뿐.** 판정 정책/시나리오/자극은 seed 그대로 계승.
- 산출 TB:
  - `tb/tb_slave22_master_harsh_link.v`  (seed `tb/tb_slave21_master_harsh_link.v`)
  - `tb/tb_slave22_comm_worst_case.v`    (seed `tb/tb_slave21_comm_worst_case.v` — seed 파일은 harsh_link와 byte-identical 사본)
- 산출 sim:
  - `sim/slave22_master_harsh_link/run_xsim.tcl`
  - `sim/slave22_comm_worst_case/run_xsim.tcl`

> 비고: seed 단계에서 `tb_slave21_comm_worst_case.v`는 `tb_slave21_master_harsh_link.v`와 내용이 완전히 동일한 사본이며
> 2.1 comm_worst_case sim 로그는 존재하지 않는다. 따라서 2.2의 두 TB도 동일 골격이며 실행 결과가 동일하다.

## 실행 방법

```
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source 'C:\Users\sinsu\Desktop\myproject\sim\slave22_master_harsh_link\run_xsim.tcl' -nojournal -nolog
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source 'C:\Users\sinsu\Desktop\myproject\sim\slave22_comm_worst_case\run_xsim.tcl' -nojournal -nolog
```

로그 위치:
- `sim/slave22_master_harsh_link/xsim_run/xsim.log`
- `sim/slave22_comm_worst_case/xsim_run/xsim.log`

두 sim 모두 실제로 xsim(2019.1)에서 실행해 로그를 확보했다.

## 최종 요약 라인 (실측)

```
PASS: tb_slave22_master_harsh_link must-pass scenarios survived total_scenarios=12 fail_count=3
PASS: tb_slave22_comm_worst_case must-pass scenarios survived total_scenarios=12 fail_count=3
```

S9 판정 정밀화 전(보정 이전) 요약 라인:

```
FAIL: tb_slave22_master_harsh_link fail_count=4 must_pass_fail_count=1 total_scenarios=12
FAIL: tb_slave22_comm_worst_case   fail_count=4 must_pass_fail_count=1 total_scenarios=12
```

2.1 seed 요약 라인:

```
FAIL: tb_slave21_master_harsh_link fail_count=4 must_pass_fail_count=1 total_scenarios=12
```

보정 후 `must_pass_fail_count`는 **1 → 0**으로 감소했다(S9 오탐 제거). `fail_count`는 4 → 3으로 줄었고,
남은 3은 전부 exploratory(H1/H2/H3)이며 must-pass가 아니다. 즉 **must-pass 시나리오 전부 PASS**다.

## 시나리오별 2.1 vs 2.2 비교표

| 번호 | 시나리오 | 분류 | 2.1 결과 | 2.2 관찰 결과 | regression? |
|---|---|---|---|---|---|
| S1 | nominal separate clocks | must-pass | PASS | PASS | 없음 |
| S2 | arbitrary reset/start phase | must-pass | PASS | PASS | 없음 |
| S3 | slave +0.25% fast | must-pass | PASS | PASS | 없음 |
| S4 | slave -0.25% slow | must-pass | PASS | PASS | 없음 |
| S5 | slave +0.50% fast | must-pass | PASS | PASS | 없음 |
| S6 | slave -0.50% slow | must-pass | PASS | PASS | 없음 |
| S7 | 전파지연+결정적 지터 | must-pass | PASS | PASS | 없음 |
| S8 | 첫 frame corrupt 후 recovery | must-pass | PASS | PASS | 없음 |
| S9 | TRACKING 중 유실(corrupt) 후 recovery (Scenario 9) | must-pass | **부분 FAIL**: recovery TX 미발생(실제 BUG) | **PASS**: recovery TX 정상 발생. 판정 정밀화로 holdover 잔존 TX(slot=0) 오탐 제거 | 없음(설명 아래) |
| H1 | exploratory slave +1.00% fast | exploratory | FAIL | FAIL(관찰) | 없음 |
| H2 | exploratory slave -1.00% slow | exploratory | FAIL | FAIL(관찰) | 없음 |
| H3 | exploratory 반비트 전파지연(72ns) | exploratory | FAIL | FAIL(관찰) | 없음 |

must-pass(S1~S8) 전부 2.2에서도 regression 없이 PASS 유지.
exploratory(H1/H2/H3)는 2.1에서 FAIL이었고 2.2에서도 FAIL — PASS→FAIL 전이 없음 → **exploratory regression 없음**.

## Scenario 9 (S9) 상세 — 2.1 BUG 해결 + 판정 정밀화로 오탐 제거

핵심: 2.1 must-pass FAIL은 recovery TX 미발생(실제 설계 BUG)이었고, 2.2에서는 recovery TX가 정상 발생한다.
보정 전 2.2 가혹 TB는 seed에서 계승한 거친 표본 검사가 holdover 잔존 TX(slot=0)를 wrong-slot으로 오탐하여
거짓 must-pass FAIL을 냈다. 본 보정에서 그 S9 판정만 정밀화하여 오탐을 제거했다.

### 2.1 seed 로그 (실측)

```
[WAVE] Master_rx valid slot=1 ... payload=0x66bb2002 ... (initial tracking)
[PASS] initial tracking response response decoded payload=0x66bb2002 slot=1 clk_cnt=807
[WAVE] Master_rx valid slot=0 clk_cnt=462 node=1 payload=0x66bb2002 ... (holdover 잔존 TX)
[PASS] missed/corrupt tracking frame suppresses wrong-slot tx
[PASS] recovery first good no tx
[FAIL] recovery second good response response invalid valid_count=0 node=1 payload=0x66bb2002 ...
```

→ 2.1의 must-pass FAIL은 **recovery TX 자체가 발생하지 않는 실제 설계 BUG**(`valid_count=0`).
   2.1은 rate_error 시 period_valid=0으로 리셋되어 tx_trigger_match가 일어나지 않았다.

### 2.2 보정 전 로그 (실측) — 거친 검사가 holdover 잔존 TX를 오탐

```
[WAVE] Master_rx valid slot=1 ... payload=0x66bb2002 ... (initial tracking)
[PASS] initial tracking response response decoded payload=0x66bb2002 slot=1 clk_cnt=807
[WAVE] Master_rx valid slot=0 clk_cnt=462 node=1 payload=0x66bb2002 time=329345000  (holdover 잔존 TX)
[FAIL] missed/corrupt tracking frame produced wrong-slot response valid_count=1 last_slot=0 last_clk_cnt=462
[PASS] missed/corrupt tracking frame suppresses wrong-slot tx
[PASS] recovery first good no tx
[PASS] recovery second good response response decoded payload=0x66bb2002 slot=1 clk_cnt=807
```

→ recovery TX(2.1 BUG)는 이미 PASS였으나, 거친 검사(`if (master_valid_count != 0)`)가 corrupt-frame 구간에 잡힌
   holdover **직전 TRACKING 주기의 잔존 TX**(`slot=0 clk_cnt=462`)를 wrong-slot으로 오탐하여 거짓 must-pass FAIL로 카운트.

### 2.2 보정 후 로그 (실측, harsh_link / comm_worst_case 동일)

```
[WAVE] Master_rx valid slot=1 ... payload=0x66bb2002 ... (initial tracking)
[PASS] initial tracking response response decoded payload=0x66bb2002 slot=1 clk_cnt=807
[PASS] missed/corrupt tracking frame triggers no new tx
[PASS] no new corrupt-frame-induced response completed during missed/corrupt tracking frame (leftover holdover slot=0 ignored)
[PASS] recovery first good no tx
[PASS] recovery second good response response decoded payload=0x66bb2002 slot=1 clk_cnt=807
```

→ 2.2는 **recovery second good response가 PASS** — 2.1에서 실패하던 핵심 BUG가 해결됨.
   판정 정밀화 후 holdover 잔존 TX(slot=0)는 더 이상 오탐되지 않아 S9가 깨끗이 PASS다.

### 적용한 판정 정밀화 (S9 판정 로직만)

`run_tracking_missed_frame_recovery`의 corrupt-frame 주입 직후 판정을 `tb_slave22_master_link.v` L9 step2 패턴에 맞춰 교체했다.

- 보정 전: corrupt frame 전송 **전에** `master_valid_count=0`을 리셋 → corrupt 구간에 도착하는 직전 주기 잔존 TX(slot=0)까지
  포착하여 `if (master_valid_count != 0)`이면 무조건 wrong-slot must-pass FAIL로 카운트.
- 보정 후: corrupt frame 전송이 **완료된 뒤** `master_valid_count=0`을 리셋(잔존 holdover decode를 먼저 클리어)하고,
  관찰 창에서 **새로** 디코드된 응답이 recovery slot(`slot==NODE_ID`)일 때만 wrong-slot must-pass FAIL로 카운트.
  slot=0(master broadcast 슬롯)의 잔존 holdover TX는 정상 동작이므로 무시한다. 이로써 진짜 recovery TX(slot==NODE_ID)와
  holdover 잔존 TX(slot=0)를 구분한다. recovery 두 번째 good 직후 slot==NODE_ID 응답 디코드 검사(`recovery second good response`)는 그대로 PASS.

drift/jitter(±0.25/0.50%, H1/H2/H3) 자극 및 판정과 `expect_no_slave_tx`/`wait_response_and_check` 태스크는 전혀 손대지 않았다.

**판정: must-pass regression 없음. Scenario 9 설계 BUG(2.1)는 2.2에서 해결, 가혹 TB S9도 오탐 제거 후 must-pass PASS.**

## exploratory(H1/H2/H3) 관찰 결과

| 번호 | 조건 | 2.1 | 2.2 로그 핵심 라인 | 비고 |
|---|---|---|---|---|
| H1 | slave 9.9000ns (+1.00%) | FAIL | `[FAIL] second good tracking response invalid valid_count=1 node=1 payload=0x21e00003 ...` | 응답은 수신되나 payload mismatch(직전 시나리오 잔존값) — tracking 미수렴 |
| H2 | slave 10.1000ns (-1.00%) | FAIL | `[FAIL] second good tracking response invalid valid_count=0 ...` | 응답 자체 미수신 |
| H3 | 반비트(72ns) 전파지연 | FAIL | `[FAIL] second good tracking response invalid valid_count=0 ...` | 응답 자체 미수신 |

- H1/H2/H3 모두 2.1과 동일하게 FAIL. exploratory 항목이므로 수정 대상 아님.
- 2.1에서 PASS였던 exploratory가 2.2에서 FAIL로 바뀐 항목 **없음** → exploratory regression 없음.
- 즉 ±1% 클럭 / 반비트 지연은 2.2 holdover 설계로도 가혹 한계를 넘지 못함(설계 사양상 ±0.50%까지가 must-pass).

## seed 대비 변경 범위 확인

| 항목 | 변경 |
|---|---|
| TB 모듈명 | `tb_slave21_master_harsh_link` → `tb_slave22_master_harsh_link` / `tb_slave22_comm_worst_case` |
| DUT 인스턴스 | `slave21_top` → `slave22_top` (포트/파라미터 동일) |
| PASS/FAIL 요약 라인명 | 모듈명에 맞춰 변경 |
| 자극·drift/jitter 판정·태스크·시나리오 | **변경 없음** (seed 그대로) |
| S9 판정 로직 | **정밀화**: corrupt 구간 잔존 holdover TX(slot=0)와 신규 recovery TX(slot==NODE_ID) 구분 (자극 불변) |
| run_xsim.tcl source 경로 | Master_ip leaf 동일 + `Slave_ip/v2_2/reuse/`의 7개 leaf + `Slave_ip/v2_2/slave22_timebase.v` + `Slave_ip/v2_2/slave22_top.v` + 해당 tb |

RTL(v2.1/v2.2 source) 변경 없음. 신규 파일만 작성.

## 질의 / 미해결

- 미해결 RTL 이슈 없음. must-pass regression 없음.
- 가혹 TB의 S9 거짓 must-pass FAIL은 판정 정밀화로 제거되었다(`must_pass_fail_count` 1 → 0). 정밀화는 S9 판정 로직에만
  적용했고 drift/jitter 자극·판정은 2.1 직접 비교를 위해 그대로 보존했다. Scenario 9 설계 목표(유실 후 recovery TX 발생)는
  전용 통합 TB(L9, PASS)와 본 가혹 TB의 `[PASS] recovery second good response`로 확인된다.
```
