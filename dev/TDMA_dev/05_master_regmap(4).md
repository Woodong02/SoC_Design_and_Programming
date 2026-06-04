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

### 0x00 — LINK_CFG_AND_CTRL

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 9:0 | reserved
| 19:10 | GUARD_TICKS[9:0] | RW | — | 슬롯 간 guard time (clk 사이클 단위). GUARD_MIN_RO 이상으로 설정 |
| 22:20 | NODE_CNT[2:0] | RW  | 0 | 값 N → 슬레이브 0~N 활성 (총 N+1개). 최대 7 (8개 슬레이브) |
| 23 | ENABLE | RW | 0 | 1: IP 동작 시작. 0: 정지 |
| 31:24 | reserved | — | 0 | — |


## 0x04 - clk_DIV and DIV
| 15:0 | clk_DIV[15:0] | RW | 0 | original clk 분주기
| 31:16 | DIV[15:0] | RW | 0 | 분주된 clk 기준 송신 비트 폭



> 모든 슬레이브 노드는 마스터의 브로드캐스팅으로 GUARD_TICKS를 동기화한다.

---

### 0x08 — FAULT_CFG_intrclear

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | FAULT_TH[7:0] | RW | 30 | FAULT_CNT 포화 임계값. 허용 오류 횟수 ≈ FAULT_TH / 10. 복구 소요 사이클 ≈ FAULT_TH |
| 15:8 | SILENT_FAULT_TH[7:0] | RW | 30 | LINE_CNT 포화 임계값. 라인 이상 허용 횟수 ≈ LINE_FAULT_TH / 10 |
| 23:16 | new_Silent_node[7:0] | W0C | 0 | Silent_node 발생시 interrupt. Write 0 to clear |
| 31:24 | new_Halt_cmd[7:0] | W0C | 0 | Fault node 발생시 interrupt. Write 0 to clear |

> 카운터 동작: 위반 이벤트 +4/+6/+8, 정상 수신 or 사이클 시작: −1 (하한 0). 임계값 도달 시 fault 진입. ~0 복귀 시 NORMAL 복귀~. 상세 규칙은 `04_fault_decisions(4).md` §2 참조.

---

### 0x0C — ERR_CNT0

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | err_cnt0[7:0] | RO | 0 | silent_cnt0
| 15:8 | err_cnt0[15:8] | RO | 0 |  hamming_err_cnt0
| 23:16 | err_cnt0[15:8] | RO | 0 |  slot_timeout_cnt0
| 31:24 | err_cnt0[15:8] | RO | 0 |  preamble_err_cnt0
---

### 0x10 — ERR_CNT1

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | err_cnt0[7:0] | RO | 0 | silent_cnt1
| 15:8 | err_cnt1[15:8] | RO | 0 |  hamming_err_cnt1
| 23:16 | err_cnt1[15:8] | RO | 0 |  slot_timeout_cnt1
| 31:24 | err_cnt1[15:8] | RO | 0 |  preamble_err_cnt1
---

### 0x14 — ERR_CNT2

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | err_cnt2[7:0] | RO | 0 | silent_cnt2
| 15:8 | err_cnt2[15:8] | RO | 0 |  hamming_err_cnt2
| 23:16 | err_cnt2[15:8] | RO | 0 |  slot_timeout_cnt2
| 31:24 | err_cnt2[15:8] | RO | 0 |  preamble_err_cnt2
---

### 0x18 — ERR_CNT3

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | err_cnt3[7:0] | RO | 0 | silent_cnt3
| 15:8 | err_cnt3[15:8] | RO | 0 |  hamming_err_cnt3
| 23:16 | err_cnt3[15:8] | RO | 0 |  slot_timeout_cnt3
| 31:24 | err_cnt3[15:8] | RO | 0 |  preamble_err_cnt3
---

### 0x1C — ERR_CNT4

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | err_cnt4[7:0] | RO | 0 | silent_cnt4
| 15:8 | err_cnt4[15:8] | RO | 0 |  hamming_err_cnt4
| 23:16 | err_cnt4[15:8] | RO | 0 |  slot_timeout_cnt4
| 31:24 | err_cnt4[15:8] | RO | 0 |  preamble_err_cnt4
---

### 0x20 — ERR_CNT5

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | err_cnt5[7:0] | RO | 0 | silent_cnt5
| 15:8 | err_cnt5[15:8] | RO | 0 |  hamming_err_cnt5
| 23:16 | err_cnt5[15:8] | RO | 0 |  slot_timeout_cnt5
| 31:24 | err_cnt5[15:8] | RO | 0 |  preamble_err_cnt5
---

### 0x24 — ERR_CNT6

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | err_cnt6[7:0] | RO | 0 | silent_cnt6
| 15:8 | err_cnt6[15:8] | RO | 0 |  hamming_err_cnt6
| 23:16 | err_cnt6[15:8] | RO | 0 |  slot_timeout_cnt6
| 31:24 | err_cnt6[15:8] | RO | 0 |  preamble_err_cnt6
---

### 0x28 — ERR_CNT7

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 7:0 | err_cnt7[7:0] | RO | 0 | silent_cnt7
| 15:8 | err_cnt7[15:8] | RO | 0 |  hamming_err_cnt7
| 23:16 | err_cnt7[15:8] | RO | 0 |  slot_timeout_cnt7
| 31:24 | err_cnt7[15:8] | RO | 0 |  preamble_err_cnt7


---
### 0x2C, 30, 34, 38, 3C, 40, 44, 48
    slot_out x 8!!

## 3. 글로벌 상태

### 0x4C — CYCLE_CNT0

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 31:0 | CYCLE_CNT[31:0] | RO | 0 | 완료된 TDMA 사이클 수. 32비트까지만 연산

---

## 0x50 - buffer
| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 31:0 | buffer_out[31:0] | RO | 0 | 가장 최근 샘플링된 32비트 데이터.



## 4. 인터럽트

| 비트 | 이름 | 접근 | 초기값 | 설명 |
|------|------|------|--------|------|
| 0 | intr | - | 0 | Silent Node, Halt_cmd 인터럽트. 0x08 — FAULT_CFG_with_intr 31:16 bit clear를 통해 제어|


--
추천: 슬레이브도 PS에서 clk_div, div, guard_ticks, slv_node 설정할 수 있으면 디버깅 시간이 현저히 줄어들 것으로 예상
