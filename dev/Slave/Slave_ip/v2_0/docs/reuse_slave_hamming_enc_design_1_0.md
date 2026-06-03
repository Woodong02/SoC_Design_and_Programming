# `slave_hamming_enc` 설계 노트

## 목적

`slave_hamming_enc`는 Slave가 Master로 response frame을 보낼 때 사용할 35-bit data를 Master 호환 42-bit SECDED codeword로 변환하는 leaf 조합 모듈이다.

이 source를 작성하는 이유는 Slave TX가 `{8'hAA, codeword[41:0]}` 형태의 50-bit frame을 만들 때 Master `hamming_dec`가 기대하는 parity tree와 codeword layout을 정확히 만족해야 하기 때문이다. 기준 구현은 `Master_ip/hamming_enc.v`이며, 이 설계는 해당 parity coverage를 그대로 복제하되 Slave 전용 모듈명과 project coding standard port naming을 사용한다.

## 기준 및 확인된 동작

### Source에서 확인된 동작

- Master encoder module: `hamming_enc`
- Master codeword layout:

```text
codeword[41:0] = {data[34:0], p[5:0], p_overall}
codeword[41:7] = data[34:0]
codeword[6:1]  = {p[5], p[4], p[3], p[2], p[1], p[0]}
codeword[0]    = p_overall
```

- `p_overall`은 `{data, p5, p4, p3, p2, p1, p0}` 전체 XOR이다.
- parity coverage는 data bit 위치를 `position = data index + 1`로 본 systematic Hamming parity tree이다.

### 추론한 동작

- Slave response data는 상위 설계 문서 기준으로 `{NODE_ID[2:0], payload[31:0]}`가 `i_DATA[34:0]`에 들어올 예정이다.
- 이 leaf module은 data 의미를 해석하지 않고 SECDED encoding만 수행한다.

### Unknown / 추가 확인 필요 없음

- 이 모듈 자체에는 timing, reset, handshake, frame serialization이 없다.
- 상위 `slave_tx`에서 preamble 결합과 MSB-first serialization을 담당한다.

## Module Interface

```verilog
module slave_hamming_enc (
    input  wire [34:0] i_DATA,
    output wire [41:0] o_CODEWORD
);
```

| Port | Direction | Width | 설명 |
| --- | --- | --- | --- |
| `i_DATA` | input | 35 | SECDED encoding 대상 data. 상위 응답에서는 `{NODE_ID, payload}` |
| `o_CODEWORD` | output | 42 | Master layout과 동일한 `{data, p[5:0], p_overall}` |

Protocol bit field이므로 `signed [31:0]` 표준 예외로 unsigned vector width를 사용한다.

## Parity Tree

Master `hamming_enc.v`와 동일하게 다음 parity bit을 계산한다.

```text
p[0]: d[0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34]
p[1]: d[1,2,5,6,9,10,13,14,17,18,21,22,25,26,29,30,33,34]
p[2]: d[3,4,5,6,11,12,13,14,19,20,21,22,27,28,29,30]
p[3]: d[7,8,9,10,11,12,13,14,23,24,25,26,27,28,29,30]
p[4]: d[15..30]
p[5]: d[31,32,33,34]
```

`p_overall = ^{data, p5, p4, p3, p2, p1, p0}`이다.

## FSM 정의

FSM 없음.

이 모듈은 clock과 reset이 없는 순수 combinational encoder이다. 모든 입력 조합에 대해 같은 cycle에 deterministic output을 만든다.

## Expected Behavior

- `i_DATA`가 변경되면 `o_CODEWORD`가 조합 경로로 갱신된다.
- `o_CODEWORD[41:7]`은 `i_DATA[34:0]`와 항상 동일하다.
- `o_CODEWORD[6:1]`은 Master parity tree의 `{p5,p4,p3,p2,p1,p0}`와 동일하다.
- `o_CODEWORD[0]`은 전체 41-bit `{data,p}`의 XOR이다.
- Master `hamming_enc` 출력과 bit-for-bit 동일해야 한다.

## Test Coverage

Self-checking testbench `tb/tb_slave_hamming_enc.v`에서 다음 입력군을 검증한다.

- all-zero data
- all-one data
- walking-one data: 35개 bit 전체
- reference parity 계산 함수와 비교
- Master `hamming_enc` instance와 output 비교
- 추가 pattern 몇 개를 phase별 `$display`와 함께 비교

PASS 조건:

- 모든 test vector에서 `slave_hamming_enc.o_CODEWORD == reference_codeword`
- 모든 test vector에서 `slave_hamming_enc.o_CODEWORD == hamming_enc.codeword`
- mismatch가 없으면 terminal에 명확히 `PASS` 출력

FAIL 조건:

- 하나라도 mismatch가 있으면 mismatch data, expected, actual, master output을 출력하고 `FAIL` 출력 후 simulation 종료
