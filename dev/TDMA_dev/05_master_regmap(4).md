# TDMA Master IP — 레지스터 맵 사양

> 버전: 0.6
> 작성일: 2026-05-30
> v0.6 변경 : 마스터 레지스터 상당수 변경

---

## 표기 규칙

| 기호 | 의미 |
|------|------|
| RW | 읽기/쓰기 |
| RO | 읽기 전용 |
| W1C | 쓰기 1로 클리어 |
| RW† | PS 읽기/쓰기 + HW 자동 세팅 가능 |
| reserved | 0으로 읽힘, 쓰기 무시 |

---

## 1. 제어 레지스터

주소값은 신경쓰지 않겠습니다...

### 0x04 — LINK_CFG_CTRL

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 9:0 | DIV | RW | 0 | clk_tick 반주기 = clk / (DIV+1). Manchester 비트 주기 = 2×(DIV+1) clk 사이클 |
| 19:10 | GUARD_TICKS | RW | — | 슬롯 간 guard time (clk 사이클 단위). GUARD_MIN_RO 이상으로 설정 |
| 22:20 | NODE_CNT | RW | 0 | 값 N → 슬레이브 0~N 활성 (총 N+1개). 최대 7 (8개 슬레이브) |
| 23 | ENABLE | RW | 0 | 1: IP 동작 시작. 0: 정지 |



> 모든 슬레이브 노드는 마스터의 브로드캐스팅으로 GUARD_TICKS를 동기화한다.

---

### 0x08 — FAULT_CFG

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | FAULT_TH | RW | 30 | FAULT_CNT 포화 임계값. 허용 오류 횟수 ≈ FAULT_TH / 10. 복구 소요 사이클 ≈ FAULT_TH |
| 15:8 | LINE_FAULT_TH | RW | 30 | LINE_CNT 포화 임계값. 라인 이상 허용 횟수 ≈ LINE_FAULT_TH / 10 |
| 31:16 | reserved | — | 0 | — |

> 카운터 동작: 위반 이벤트 +4/+6/+8, 정상 수신 or 사이클 시작: −1 (하한 0). 임계값 도달 시 fault 진입. ~0 복귀 시 NORMAL 복귀~. 상세 규칙은 `04_fault_decisions(4).md` §2 참조.

---

### 0x0C — ERR_CNT0

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | err_cnt0[7:0] | RW | 0 | silent_cnt0
| 15:8 | err_cnt0[15:8] | RW | 0 |  hamming_err_cnt0
| 23:16 | err_cnt0[15:8] | RW | 0 |  slot_timeout_cnt0
| 31:24 | err_cnt0[15:8] | RW | 0 |  preamble_err_cnt0
---

### 0x10 — ERR_CNT1

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | err_cnt0[7:0] | RW | 0 | silent_cnt1
| 15:8 | err_cnt1[15:8] | RW | 0 |  hamming_err_cnt1
| 23:16 | err_cnt1[15:8] | RW | 0 |  slot_timeout_cnt1
| 31:24 | err_cnt1[15:8] | RW | 0 |  preamble_err_cnt1
---

### 0x14 — ERR_CNT2

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | err_cnt2[7:0] | RW | 0 | silent_cnt2
| 15:8 | err_cnt2[15:8] | RW | 0 |  hamming_err_cnt2
| 23:16 | err_cnt2[15:8] | RW | 0 |  slot_timeout_cnt2
| 31:24 | err_cnt2[15:8] | RW | 0 |  preamble_err_cnt2
---

### 0x18 — ERR_CNT3

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | err_cnt3[7:0] | RW | 0 | silent_cnt3
| 15:8 | err_cnt3[15:8] | RW | 0 |  hamming_err_cnt3
| 23:16 | err_cnt3[15:8] | RW | 0 |  slot_timeout_cnt3
| 31:24 | err_cnt3[15:8] | RW | 0 |  preamble_err_cnt3
---

### 0x1C — ERR_CNT4

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | err_cnt4[7:0] | RW | 0 | silent_cnt4
| 15:8 | err_cnt4[15:8] | RW | 0 |  hamming_err_cnt4
| 23:16 | err_cnt4[15:8] | RW | 0 |  slot_timeout_cnt4
| 31:24 | err_cnt4[15:8] | RW | 0 |  preamble_err_cnt4
---

### 0x20 — ERR_CNT5

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | err_cnt5[7:0] | RW | 0 | silent_cnt5
| 15:8 | err_cnt5[15:8] | RW | 0 |  hamming_err_cnt5
| 23:16 | err_cnt5[15:8] | RW | 0 |  slot_timeout_cnt5
| 31:24 | err_cnt5[15:8] | RW | 0 |  preamble_err_cnt5
---

### 0x24 — ERR_CNT6

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | err_cnt6[7:0] | RW | 0 | silent_cnt6
| 15:8 | err_cnt6[15:8] | RW | 0 |  hamming_err_cnt6
| 23:16 | err_cnt6[15:8] | RW | 0 |  slot_timeout_cnt6
| 31:24 | err_cnt6[15:8] | RW | 0 |  preamble_err_cnt6
---

### 0x28 — ERR_CNT7

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | err_cnt7[7:0] | RW | 0 | silent_cnt7
| 15:8 | err_cnt7[15:8] | RW | 0 |  hamming_err_cnt7
| 23:16 | err_cnt7[15:8] | RW | 0 |  slot_timeout_cnt7
| 31:24 | err_cnt7[15:8] | RW | 0 |  preamble_err_cnt7


---

## 3. 글로벌 상태

### 0x2C — CYCLE_CNT0

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 31:0 | CYCLE_CNT[31:0] | RW | 0 | 완료된 TDMA 사이클 수. 64비트 중 절반

### 0x30 — CYCLE_CNT1

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 31:0 | CYCLE_CN[63:32] | RW | 0 | 완료된 TDMA 사이클 수. 64비트 중 절반

---


## 4. 인터럽트

### 0x64 — IRQ_STATUS

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 0 | GPIO_in | W0C | 0 | GPIO_in, 데이터 수신시 tftlcd 화면 업데이트 |
| 1 | seg_err_out | W0C | 0 | 임의 노드가 DATA_FAULT 또는 LINE_FAULT 상태 진입 |


---

## 설정 초기화 순서

```
1. LINK_CFG 설정 (모든 노드 동일: DIV, GUARD_TICKS / 마스터 NODE_CNT 설정)
2. GUARD_MIN_RO 확인 → GUARD_TICKS ≥ GUARD_MIN_RO 검증
4. FAULT_CFG 설정 (FAULT_TH, LINE_FAULT_TH)
5. IRQ_MASK 설정 (필요한 인터럽트 활성화)
6. CTRL.ENABLE = 1
```
