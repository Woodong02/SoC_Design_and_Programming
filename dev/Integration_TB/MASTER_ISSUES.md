# Master Module Issue Log

---

## 수정 완료 (사본에 적용됨)

### [Master_top] syntax error — Silent_node 미완성 (긴급)
- 위치: `Master_top.v` line 107–108
- 현상: `wire[7:0] Silent_node;` 선언 후 `Silent_node[0] =` 로 끝남 → 컴파일 불가
- 수정: 두 줄 삭제 (Silent_node 미사용)
- 상태: **사본에 수정 완료**
- 피드백: push가 늦어서 죄송합니다. Silent_node는 PS 인터럽트용으로 사용 예정

### [Master_top] DIV 약속 불일치 — DIV_p1 오프셋
- 위치: `Master_top.v` line 45: `wire [9:0] DIV_p1 = DIV + 10'd1;`
- 현상: 외부에서 DIV=8을 넣으면 내부 모듈들이 DIV=9로 동작 → slave DIV=8과 불일치
- 수정: `DIV_p1` 제거, 모든 서브모듈에 `DIV` 직접 전달
- 상태: **사본에 수정 완료**
- 피드백: DIV=0일 경우 해결 불가능, top 모듈에서 DIV+1을 해줌으로써 ps에서 DIV=0을 기입했을 때 DIV=1로 통제 가능하므로 필요한 기능. 수정 x
---

## 미수정 (원본 보존, 향후 확인 필요)

### [Master_rx] comment typo
- 위치: `Master_rx.v` line 200
- 현상: 주석에 `0x55` → 실제 프리앰블은 `0xAA`
- 심각도: 무시 가능 (기능 영향 없음)
- 피드백: 확인 완료, 감사합니다

### [Master_dec_ham] 슬롯 비교 타입
- 위치: `Master_dec_ham.v` line 328: `slot==2'd0`
- 현상: slot은 [2:0]인데 2비트 리터럴 비교 → Verilog에서 암묵적 확장되어 기능상 무해
- 심각도: 무시 가능
- 피드백: 반영 완료, 감사합니다
---

## 구조적 버그 (사본 수정 완료)

### [Master_slot / Master_top] NODE_CNT=7 시 3비트 오버플로우
- 발생: Stage 3 tb_sys_integration 분석
- 현상:
  - `master_top`: `wire [2:0] NODE_CNT_p1 = NODE_CNT + 3'd1;`
    NODE_CNT=7 → 7+1=8=3'b000 → NODE_CNT_p1=0 (오버플로우)
  - `Master_slot`: `output reg [2:0] slot` — 3비트 slot이 8번 슬롯에 도달 불가
  - 결과: slot이 0에서만 순환, tx_trigger가 매 slot마다 발사 → 7슬레이브 운영 불가
- 영향 범위: NODE_CNT=6까지는 정상 동작 (NODE_CNT_p1=7, 3비트 이내)
- 원인: 3비트 NODE_CNT(0~7)에 +1한 결과를 3비트 wire에 저장
- 피드백: 반영 완료, 감사합니다.

- **제안 수정 (사본 적용 완료)**:
  1. `Master_slot.v`: `NODE_CNT` 포트 및 `slot` 레지스터를 4비트로 확장
  2. `Master_top.v`: 내부 `NODE_CNT_p1`, `slot` wire를 4비트로 확장
     (외부 포트 `NODE_CNT [2:0]`는 변경 없음 — {1'b0, NODE_CNT}로 확장)
  3. Master_dec_ham, 기존 TB: slot [2:0] 입력은 트런케이션 발생 가능하나
     slot=8은 마스터 브로드캐스트 슬롯이므로 Bus B 수신 없음 → 안전
- 상태: **사본에 수정 완료 (tbfix_n7.v로 검증)**
- 피드백: 실제 NODE_CNT는 0이어도 사실상 1개 노드로 동작하기때문에 NODE_CNT+1은 잘못된 선택, 수정 완료. 3비트면 0~7이 1~8의 노드 범위로 동작하므로 비트 확장 불필요

---

## 미수정 (원본 보존, 향후 확인 필요)

### [Master_tx] 비트 주기 주석 오류 (Stage 3 시스템 통합 중 발견)
- 발생: `Master_tx.v` 파일 헤더 주석
- 현상: `// Bit period = 2*(div+1) clk cycles` 라고 기재되어 있으나,
  실제 코드는 `if (tx_cnt == DIV-1)` → 비트 주기 = DIV 클럭 (slave_tx와 동일)
- 원인: 구버전 타이밍 공식이 주석에 남아 있음. 기능 동작에는 영향 없음.
- 제안: 주석을 `// Bit period = DIV clk cycles (same as slave_tx)` 로 수정
- 심각도: 낮음 (기능 정상, 주석만 오류)
- 피드백: 감사합니다.