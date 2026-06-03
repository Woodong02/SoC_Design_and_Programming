# Slave 2.1 검증 계획

## 목적

Slave 2.1 검증은 frame-complete commit 구조가 Master 기대와 맞는지 확인한다. 정상 테스트는 실패 시 수정 대상이고, 가혹 테스트는 전체 실행 후 결과를 보고한다.

## 정상 Leaf 검증

### `slave21_rx`

필수 case:

- reset 후 idle
- idle-low 유지
- valid `8'hAA + codeword` 수신
- wrong preamble discard
- codeword valid pulse 1-cycle
- frame done pulse 1-cycle
- frame 중 `i_BIT_PERIOD` 변화 무시
- 작은 bit period boundary

### `slave21_tx`

필수 case:

- reset 후 idle
- disabled trigger ignore
- normal frame bit sequence
- 첫 bit full-width
- active 중 retrigger ignore
- frame 중 `i_BIT_PERIOD` 변화 무시
- done pulse 후 idle 0

### `slave21_fault_fsm`

필수 case:

- bad frame 반복 중 TX 금지
- first good 후 TX 금지
- second consecutive good 후 TX 허용
- halt_for_me 중 TX 금지
- tracking 중 bad frame -> recovery
- recovery good -> seen once
- recovery second good -> tracking

### `slave21_timebase`

필수 case:

- default period output
- first commit acquisition
- second commit tracking
- expected interval period 유지
- fast/slow interval correction
- TX allowed gating
- invalid node trigger block
- rate error case

## Top Full Serial 정상 검증

### Case 1: first good broadcast does not transmit

기대:

- guard/halt latch 가능
- fault state `SEEN_ONCE`
- TX 없음

### Case 2: second good broadcast enables tracking

기대:

- fault state `TRACKING`
- rate period valid
- 다음 자기 slot에서 response frame 송신
- response payload/node id 정상 decode

### Case 3: bad first frame recovery

절차:

1. corrupt preamble frame 송신
2. Slave TX 없음
3. good frame 송신
4. 아직 TX 없음 또는 `SEEN_ONCE`
5. second good frame 후 TX 허용

### Case 4: halt command

기대:

- TRACKING이어도 `halt_cmd[NODE_ID] == 1`이면 TX 없음
- halt clear 후 두 good policy를 만족하면 TX 복귀

## Master/Slave 정상 통합 검증

대상:

- Master source 직접 사용: `Master_tx`, `Master_rx`, `hamming_enc`, `hamming_dec`
- 필요 시 `Master_slot`을 TB monitor로 사용

필수 case:

- nominal same clock
- Master broadcast 2회 후 Slave response 정상
- response `fixed_data[34:32] == NODE_ID`
- response payload match
- Master normal guard window 안에서 frame 완료
- halt command silence
- bad broadcast 후 silence and recovery

정상 통합 테스트는 fail이면 오류이다. 원인을 RTL 또는 TB로 분류하고 수정해야 한다.

## 가혹 통신환경 테스트

가혹 테스트는 1.0의 다음 문서를 참조한다.

- `docs/slave_design/slave_master_harsh_link_verification.md`
- `docs/slave_design/slave_comm_worst_case_verification.md`

### Must-pass 권장 조건

- nominal separate clocks
- arbitrary reset/start phase
- `+0.25%`, `-0.25%` drift
- `+0.5%`, `-0.5%` drift
- propagation delay + deterministic jitter
- first frame corrupt, later recovery
- one missed broadcast in tracking, recovery without wrong-slot TX

### Exploratory 조건

- `+1%`, `-1%` drift
- `+2%`, `-2%` drift
- near half-bit propagation delay
- asymmetric bidirectional delay
- deterministic jitter sweep
- short glitch/noise pulse injection

가혹 테스트 정책:

- Must-pass 조건 실패는 수정 대상이다.
- Exploratory 조건은 전체 실행 후 결과를 보고한다.
- 결과 문서에는 “수렴 전 첫 frame”과 “수렴 후 tracking frame”을 반드시 분리해 기록한다.

## 결과 문서 형식

각 simulation directory에는 README와 실행 명령을 기록한다.

각 verification note에는 다음을 포함한다.

- 대상 source
- testbench
- 실행 명령
- PASS/FAIL summary
- 실패 시 원인 분류
- 가혹 테스트의 경우 scenario table

## 최종 인수 기준

2.1 1차 구현 완료 기준:

- 모든 leaf TB PASS
- top full serial 정상 TB PASS
- Master/Slave 정상 통합 TB PASS
- harsh/worst-case 전체 실행 결과 문서화
- Must-pass harsh 조건 PASS 또는 수정 완료
- Exploratory 조건은 pass/fail 그대로 기록

