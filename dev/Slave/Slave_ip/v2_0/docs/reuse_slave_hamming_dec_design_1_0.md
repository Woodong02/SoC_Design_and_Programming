# `slave_hamming_dec` 설계 노트

## 목적

`slave_hamming_dec`는 Master broadcast 또는 향후 수신 frame의 42-bit SECDED codeword를 Master IP와 같은 방식으로 해독하는 leaf module이다. Slave RX 상위 모듈은 이 모듈에서 나온 `o_DATA`, `o_HAM_1BIT_ERR`, `o_HAM_2BIT_ERR`를 사용해 broadcast payload 반영 여부를 결정한다.

이 source는 Master `hamming_enc` / `hamming_dec`와 호환되는 systematic Hamming [42,35] SECDED layout을 Slave 전용 이름으로 제공하기 위해 작성한다.

## 기준 Source에서 확인한 동작

- Master encoder layout:

```text
codeword[41:0] = {data[34:0], p[5:0], p_overall}
codeword[41:7] = data[34:0]
codeword[6:1]  = {p[5], p[4], p[3], p[2], p[1], p[0]}
codeword[0]    = p_overall
```

- Master decoder는 수신 data field인 `codeword[41:7]`에서 parity를 재계산한다.
- `syndrome[k] = p_rx[k] ^ p_recomp[k]`이다.
- `all_xor = ^codeword[41:0]`이다.
- 판정은 실제 source 기준으로 다음과 같다.

```text
syndrome == 0, all_xor == 0 : no error
syndrome != 0, all_xor == 1 : 1-bit error 후보
syndrome != 0, all_xor == 0 : 2-bit error detect
syndrome == 0, all_xor == 1 : overall parity bit 단독 오류, data valid, error flag는 source 기준 0
```

Master `hamming_dec.v` 주석에는 overall parity bit 단독 오류를 1-bit로 카운트한다고 되어 있으나, 실제 assign 식은 `ham_1bit_err = (syndrome != 0) & all_xor`이므로 `syndrome == 0`인 경우 `ham_1bit_err`가 올라가지 않는다. Slave는 “Master source와 동일 동작” 요구사항에 따라 source 동작을 따른다.

## Interface

```verilog
module slave_hamming_dec (
    input  wire [41:0] i_CODEWORD,
    output wire [34:0] o_DATA,
    output wire        o_HAM_1BIT_ERR,
    output wire        o_HAM_2BIT_ERR
);
```

- `i_CODEWORD`: Master 호환 42-bit SECDED codeword.
- `o_DATA`: corrected data. Master decoder와 동일하게 correction 가능한 data 1-bit 오류만 보정한다.
- `o_HAM_1BIT_ERR`: Master source 기준 `syndrome != 0 && all_xor == 1`.
- `o_HAM_2BIT_ERR`: Master source 기준 `syndrome != 0 && all_xor == 0`.

## FSM 정의

이 모듈은 combinational leaf decoder이므로 FSM이 없다.

- Reachable state: 없음.
- State transition: 없음.
- Terminal/error state: 없음.
- Error status는 FSM state가 아니라 combinational syndrome/parity 판정 출력이다.

## Parity Tree

Master `hamming_enc.v`와 같은 data index coverage를 사용한다.

```text
p[0]: d[0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34]
p[1]: d[1,2,5,6,9,10,13,14,17,18,21,22,25,26,29,30,33,34]
p[2]: d[3,4,5,6,11,12,13,14,19,20,21,22,27,28,29,30]
p[3]: d[7,8,9,10,11,12,13,14,23,24,25,26,27,28,29,30]
p[4]: d[15..30]
p[5]: d[31,32,33,34]
```

## Correction 정책

Master decoder는 `ham_1bit_err`이고 `syndrome`이 `1..35` 범위일 때 data bit correction 후보로 판단한다. 단, `syndrome`이 `1, 2, 4, 8, 16, 32`이면 parity bit 오류로 취급해 data를 변경하지 않는다. Slave decoder도 이 동작을 그대로 따른다.

이 정책 때문에 data bit 중 `data[0]`, `data[1]`, `data[3]`, `data[7]`, `data[15]`, `data[31]` 단독 오류는 Master reference와 동일하게 data correction되지 않는다. 이는 일반적인 systematic Hamming correction 기대와 다를 수 있으므로 verification note에 reference behavior로 기록한다.

## Test Coverage

`tb/tb_slave_hamming_dec.v`는 self-checking 방식으로 다음을 검증한다.

- no-error codeword decode.
- correction 가능한 data 1-bit 오류 보정.
- parity bit 1-bit 오류에서 data 유지 및 1-bit flag 확인.
- overall parity bit 1-bit 오류에서 data 유지 및 Master source와 같은 flag 확인.
- 2-bit 오류 detection 및 data invalid 조건 확인.
- 여러 sample과 walking single-bit error에 대해 Master `hamming_dec` reference 출력과 slave 출력 비교.

## 확인/추론/미확정 사항

- 확인: layout, parity tree, syndrome 구성, `ham_1bit_err`, `ham_2bit_err` 판정식은 Master source에서 확인했다.
- 확인: correction skip syndrome 값 `1,2,4,8,16,32`은 Master `hamming_dec.v` source에서 확인했다.
- 추론: 상위 Slave RX/control은 `o_HAM_2BIT_ERR`가 1이면 broadcast data를 무시할 것이다. 이는 slave module structure 문서의 control 정책에 따른다.
- 미확정: Master decoder 주석과 source가 다른 overall parity 단독 오류 flag 의미는 source 동작을 우선 적용했으며, 상위 정책 변경 시 별도 협의가 필요하다.
