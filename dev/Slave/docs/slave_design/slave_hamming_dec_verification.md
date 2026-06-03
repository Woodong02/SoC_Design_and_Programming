# `slave_hamming_dec` 검증 노트

## 검증 대상

- Source: `Slave_ip/v1_0/slave_hamming_dec.v`
- Testbench: `tb/tb_slave_hamming_dec.v`
- Reference source:
  - `Master_ip/hamming_enc.v`
  - `Master_ip/hamming_dec.v`
- Simulation script: `sim/slave_hamming_dec/run_xsim.tcl`

## 실행 명령

Project root `C:\Users\sinsu\Desktop\myproject`에서 다음 명령을 실행했다.

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim/slave_hamming_dec/run_xsim.tcl
```

## Simulation 환경

- Tool: Vivado/xsim 2019.1
- Flow:
  1. `xvlog.bat`로 Master reference encoder/decoder, Slave decoder, testbench compile.
  2. `xelab.bat -debug typical tb_slave_hamming_dec -s tb_slave_hamming_dec_sim`.
  3. `xsim.bat tb_slave_hamming_dec_sim -runall`.

## Testbench 구조

`tb_slave_hamming_dec`는 Master `hamming_enc`로 정상 codeword를 생성하고, 같은 corrupted codeword를 Master `hamming_dec`와 `slave_hamming_dec`에 동시에 입력한다.

Self-check 항목은 두 계층으로 구성했다.

- 명시 기대값 비교: no-error, correction 가능한 data 1-bit, parity bit 1-bit, overall parity 1-bit, 2-bit detection.
- Reference 비교: 모든 주요 phase와 walking single-bit error에서 Master decoder 출력과 Slave decoder 출력을 비교.

## Coverage 결과

검증된 항목:

- no-error decode: PASS
- data 1-bit correction: PASS
- parity bit 1-bit 오류: PASS
- overall parity bit 1-bit 오류: PASS
- 2-bit 오류 detection: PASS
- Master reference behavior 비교: PASS
- walking single-bit error reference 비교: PASS

최종 xsim 출력:

```text
PASS: tb_slave_hamming_dec completed 99 checks with no errors
```

## Reference Behavior 확인 사항

Master source와 동일하게 구현한 특수 동작:

- `ham_1bit_err = (syndrome != 0) & all_xor`
- `ham_2bit_err = (syndrome != 0) & ~all_xor`
- `syndrome`이 `1, 2, 4, 8, 16, 32`이면 `ham_1bit_err` 조건에서도 data를 수정하지 않음.
- overall parity bit 단독 오류는 `syndrome == 0`, `all_xor == 1`이므로 data는 valid이고 source 기준 error flag는 둘 다 `0`.

Master file 주석은 overall parity bit 단독 오류를 1-bit로 카운트한다고 설명하지만, 실제 source 출력식은 flag를 올리지 않는다. Slave는 요구사항에 따라 실제 Master source behavior를 reference로 삼았다.

## 실행 중 발생한 이슈와 처리

1차 실행 실패:

```text
couldn't execute "C:\Xilinx\Vivado\2019.1\bin\unwrapped\win64.o\xvlog.bat": no such file or directory
```

원인: Vivado batch Tcl에서 `[info nameofexecutable]`가 `bin\unwrapped\win64.o` 아래 executable을 가리켜 `xvlog.bat` 위치를 잘못 계산했다.

처리: `run_xsim.tcl`에서 해당 위치에 `xvlog.bat`가 없으면 `../..`로 올라가 `C:\Xilinx\Vivado\2019.1\bin`을 사용하도록 수정했다.

2차 실행 실패:

```text
ERROR: [XSIM 43-4099] "C:/Users/sinsu/Desktop/myproject/Master_ip/hamming_enc.v" Line 14.
Module hamming_enc doesn't have a timescale but at least one module in design has a timescale.
```

원인: Master source에는 timescale directive가 없고 testbench에만 timescale directive가 있어 xelab이 중단했다.

처리: Master source는 소유 범위 밖이므로 수정하지 않았다. Testbench의 timescale directive를 제거해 모든 module을 동일 조건으로 맞춘 뒤 재실행했다.

최종 실행 결과: PASS.
