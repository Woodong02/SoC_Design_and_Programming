# `slave_hamming_enc` 검증 노트

## 검증 대상

- DUT: `Slave_ip/v1_0/slave_hamming_enc.v`
- Testbench: `tb/tb_slave_hamming_enc.v`
- Master reference: `Master_ip/hamming_enc.v`
- Simulation script: `sim/slave_hamming_enc/run_xsim.tcl`

## 검증 목적

`slave_hamming_enc`가 Master `hamming_enc`와 동일한 SECDED parity tree 및 codeword layout을 생성하는지 확인한다.

검증 기준:

- `codeword[41:7] == data[34:0]`
- `codeword[6:1] == {p5,p4,p3,p2,p1,p0}`
- `codeword[0] == ^{data,p5,p4,p3,p2,p1,p0}`
- DUT output이 testbench 내부 reference parity 계산 결과와 일치
- DUT output이 Master `hamming_enc` output과 bit-for-bit 일치

## 실행 명령

Project root `C:\Users\sinsu\Desktop\myproject`에서 실행했다.

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim/slave_hamming_enc/run_xsim.tcl
```

## Test Coverage

| Phase | 내용 | 결과 |
| --- | --- | --- |
| all-zero | `35'd0` | PASS |
| all-one | `35'h7ffffffff` | PASS |
| walking-one | `data[0]`부터 `data[34]`까지 single-bit set 35개 | PASS |
| mixed pattern | `35'h00000aaaa`, `35'h155555555`, `35'h012345678`, `35'h6db6db6db` | PASS |

총 41개 self-checking vector를 실행했다.

## 결과 요약

Terminal output 핵심 결과:

```text
PASS: tb_slave_hamming_enc completed 41 self-checking vectors with 0 mismatches.
```

Vivado/xsim 결과:

- Compile: PASS
- Elaboration: PASS
- Simulation: PASS
- Mismatch count: 0

## 경고 및 판단

Vivado elaboration 중 다음 warning이 출력되었다.

```text
WARNING: [XSIM 43-4099] "Slave_ip/v1_0/slave_hamming_enc.v" Module slave_hamming_enc doesn't have a timescale but at least one module in design has a timescale.
WARNING: [XSIM 43-4099] "Master_ip/hamming_enc.v" Module hamming_enc doesn't have a timescale but at least one module in design has a timescale.
```

판단:

- `slave_hamming_enc`와 Master `hamming_enc`는 delay나 sequential timing이 없는 조합 모듈이다.
- Testbench에는 `` `timescale 1ns / 1ps``가 있고 `#1` settle delay만 사용한다.
- 기능 검증에는 영향이 없는 warning으로 판단한다.

## 결론

`slave_hamming_enc`는 Master `hamming_enc`와 동일한 codeword를 생성하는 것으로 확인되었다. Leaf module 검증 PASS 상태이므로 상위 `slave_tx`에서 child module로 사용할 수 있다.
