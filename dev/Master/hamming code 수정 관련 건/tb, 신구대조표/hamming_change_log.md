# error_with_hamming.v 해밍코드 변경 대조표

변경일: 2026-05-26  
변경 근거: Verilog/hamming_spec.md v2 — Systematic [42,35] + Overall Parity (SECDED) 적용

---

## 1. 해밍코드 방식 비교

| 항목 | 구버전 (변경 전) | 신버전 (변경 후) |
|------|----------------|-----------------|
| 코드 종류 | 비체계적 Hamming (Conventional) | Systematic [42,35] + p_overall |
| 코드워드 길이 | 42비트 (구조 불명확) | 42비트: `{d[34:0], p[5:0], p_overall}` |
| 에러 정정 능력 | SEC (1비트 정정) | SEC (1비트 정정) |
| 에러 검출 능력 | 2비트 검출 불안정 | SECDED (2비트 확실히 검출) |
| Syndrome 계산 위치 | `error_with_hamming.v` 내 inline | `hamming_dec` 서브모듈 위임 |

---

## 2. 코드워드 비트 레이아웃

### 구버전: 비체계적 배치 (변경 전)

```
비트 위치(41..0) 내에 패리티 비트가 2의 거듭제곱 위치에 분산 배치됨.
데이터와 패리티가 interleaved. 
```

### 신버전: 체계적 배치 (변경 후)

```
codeword[41:0] = { d[34:0], p[5:0], p_overall }
  [41:7]  = d[34:0]     — 데이터 35비트 (MSB 쪽)
  [6:1]   = p[5:0]      — 체계적 패리티 6비트
  [0]     = p_overall   — 전체 패리티 (SECDED용)
```

---

## 3. 변수 정의부 변경 (53~67줄)

### 구버전 코드

```verilog
wire [6:0]  syndrome;

reg out_sig;
assign syndrome[0] = ^(data_in & 42'h155_5555_5555); // P1
assign syndrome[1] = ^(data_in & 42'h266_6666_6666); // P2
assign syndrome[2] = ^(data_in & 42'h078_7878_7878); // P4
assign syndrome[3] = ^(data_in & 42'h380_7F80_7F80); // P8
assign syndrome[4] = ^(data_in & 42'h000_7FFF_8000); // P16
assign syndrome[5] = ^(data_in & 42'h3FF_8000_0000); // P32
assign syndrome[6] = ^(data_in);

wire [41:0] fixed_data = (syndrome[5:0] == 6'b0) ?
    data_in : (data_in ^ (42'b1 << (syndrome[5:0] - 6'b1)));

wire ham_1bit_err = (syndrome[5:0] != 6'b0) && (syndrome[6] == 1'b1);
wire ham_over_1bit_err = (syndrome[5:0] != 6'b0) && (syndrome[6] == 1'b0);
```

**문제점:**
- 비체계적 XOR 마스크 방식으로 systematic 인코딩과 호환되지 않음
- `fixed_data`가 42비트로 데이터/패리티 비트 혼재
- `ham_over_1bit_err` 명칭이 의미 불명확

### 신버전 코드

```verilog
reg out_sig;

wire [34:0] fixed_data;
wire        ham_1bit_err;
wire        ham_2bit_err;

hamming_dec u_hamming_dec (
    .codeword    (data_in),
    .data        (fixed_data),
    .ham_1bit_err(ham_1bit_err),
    .ham_2bit_err(ham_2bit_err)
);
```

**변경 근거:**
- `hamming_dec` 서브모듈이 [42,35] SECDED를 정확하게 구현
- `fixed_data`가 35비트 순수 데이터로 단순화
- `ham_2bit_err` 명칭이 SECDED 동작을 명확히 표현

---

## 4. 에러 플래그 의미 변경

| 플래그 | 구버전 | 신버전 |
|--------|--------|--------|
| `ham_1bit_err` | `syndrome[5:0] != 0 && overall_parity == 1` | `syndrome != 0 && all_xor == 1` (1비트 에러, 정정 완료) |
| `ham_over_1bit_err` | `syndrome[5:0] != 0 && overall_parity == 0` | — (삭제됨) |
| `ham_2bit_err` | — (없음) | `syndrome != 0 && all_xor == 0` (2비트 에러 검출, 데이터 무효) |

---

## 5. 데이터 추출 로직 변경 (341~373줄)

### 구버전: 비체계적 위치 발췌

```verilog
if (!ham_over_1bit_err) begin
    case(fixed_data[40:38])
        3'd0: begin
            slot_out0 <= {fixed_data[37:32], fixed_data[30:16],
                          fixed_data[14:8], fixed_data[6:4], fixed_data[2]};
```

**구조:** 비체계적 코드워드에서 패리티 위치(1,2,4,8,16,32)를 건너뛰며 데이터 발췌 → 6+15+7+3+1=32비트

### 신버전: 연속 32비트 직접 참조

```verilog
if (!ham_2bit_err) begin
    case(fixed_data[34:32])
        3'd0: begin
            slot_out0 <= fixed_data[31:0];
```

**구조:** `hamming_dec` 출력 `data[34:0]`에서 상위 3비트(슬롯 번호)를 제외한 하위 32비트를 직접 사용

---

## 6. 슬롯 라우팅 비트 변경

| 항목 | 구버전 | 신버전 |
|------|--------|--------|
| case 조건 | `fixed_data[40:38]` | `fixed_data[34:32]` |
| 슬롯 타임아웃 조건 | `fixed_data[40:38]` | `fixed_data[34:32]` |
| 이유 | 42비트 코드워드의 최상위 데이터 비트 | 35비트 데이터의 최상위 3비트 |

---

## 7. 에러 카운트 로직 변경 (378~403줄)

| 항목 | 구버전 | 신버전 |
|------|--------|--------|
| 2비트 에러 판정 | `ham_over_1bit_err` | `ham_2bit_err` |
| 에러 카운트 증가 | `hamming_err_cntN + (ham_over_1bit_err<<3)` | `hamming_err_cntN + (ham_2bit_err<<3)` |
| 에러 카운트 의미 | +8: "1비트 초과 에러" | +8: "SECDED 2비트 에러 검출" |

---

## 8. 기타 수정 (기존 버그 수정)

| 줄 | 구버전 | 신버전 | 비고 |
|----|--------|--------|------|
| `silent_cnt` 블록 | `8'b6` | `8'd6` | 이진수 표기에 십진 값 사용 오류 |
| `preamble_err_cnt` 블록 | `8'b6` | `8'd6` | 동일 |
| `slot_timeout_cnt` 블록 | `8'b255` | `8'd255` | 이진수 표기에 십진 값 사용 오류 |

---

## 9. 시뮬레이션 검증 결과

컴파일: `hamming_enc.v` → `hamming_dec.v` → `error_with_hamming.v` → `tb_error_and_hamming.v`

```
=== Case 1: Normal reception, all 8 slots ===
[PASS] slot0 ~ slot7 (8건): 정상 수신, 데이터 정확

=== Case 2: 1-bit error correction (slot 0) ===
[PASS] 1-bit err corrected: data=0xdeadbeef err_cnt=4

=== Case 3: 2-bit error - data must be discarded (slot 1) ===
[PASS] 2-bit err discarded: slot_out1 unchanged=0xcafebabe cnt=8

=== Case 4: Slot routing verification ===
[PASS] slot0 ~ slot7 (8건): 올바른 슬롯으로 라우팅

[DONE] error_and_hamming tb: 18 PASS, 0 FAIL
ALL PASS
```
