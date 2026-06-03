# Slave 2.0 재사용 leaf 호환 검증 노트

## 목적

이 문서는 Slave 2.0에서 수정 없이 그대로 재사용하기로 한 Slave 1.0 leaf module의 호환성을 검증한 결과를 기록한다.

검증 대상 source는 다음 3개이며, 본 작업에서는 source를 수정하지 않는다.

- `Slave_ip/v1_0/slave_hamming_enc.v`
- `Slave_ip/v1_0/slave_hamming_dec.v`
- `Slave_ip/v1_0/slave_control.v`

## 검증 대상과 판단 기준

### `slave_hamming_enc`

확인된 역할:

- 35-bit data를 Master 호환 42-bit SECDED codeword로 조합 encoding한다.
- Layout은 `{data[34:0], p[5:0], p_overall}`이다.
- FSM, reset, handshake가 없으므로 Slave 2.0 timing 구조와 직접 충돌하지 않는다.

호환 PASS 기준:

- 다양한 data vector에서 encode 후 decoder roundtrip 결과가 원본 data와 같아야 한다.
- 출력 codeword의 data field `codeword[41:7]`이 입력 data와 같아야 한다.
- no-error decode에서 1-bit/2-bit error flag가 모두 0이어야 한다.

### `slave_hamming_dec`

확인된 역할:

- 42-bit SECDED codeword에서 35-bit data를 복원한다.
- `o_HAM_1BIT_ERR`와 `o_HAM_2BIT_ERR`를 조합 출력한다.
- 1-bit data error 중 syndrome이 `1,2,4,8,16,32`인 경우는 기존 Master 호환 정책에 따라 data correction을 수행하지 않는다.

호환 PASS 기준:

- encoder/decoder roundtrip이 통과해야 한다.
- correction 가능한 single-bit data error는 `o_HAM_1BIT_ERR=1`, `o_HAM_2BIT_ERR=0`이고 data가 원본으로 복원되어야 한다.
- parity bit single-bit error는 data를 유지하고 1-bit error flag를 세워야 한다.
- overall parity bit 단독 error는 기존 source 정책대로 data를 유지하고 1-bit/2-bit flag가 모두 0이어야 한다.
- double-bit error는 `o_HAM_2BIT_ERR=1`로 검출되어야 한다.

### `slave_control`

확인된 역할:

- reset 후 `WAIT_SYNC`에서 TX disabled 상태로 시작한다.
- clean broadcast만 FSM과 guard latch에 반영한다.
- `halt_cmd[i_NODE_ID] == 0`이면 active, `1`이면 halt 상태가 된다.
- `i_BROADCAST_2BIT_ERR == 1`인 broadcast는 상태와 guard latch를 유지한다.
- `o_PAYLOAD`는 `i_PAYLOAD_IN` pass-through이다.

호환 PASS 기준:

- reset 후 TX disabled, not halted, guard latch 0이어야 한다.
- halt clear clean broadcast 후 active 상태로 진입해야 한다.
- halt set clean broadcast 후 halted 상태로 진입해야 한다.
- halt clear clean broadcast 후 active 상태로 복귀해야 한다.
- 2-bit error broadcast는 active/halt 상태와 guard latch를 변경하지 않아야 한다.
- `i_NODE_ID` 변경 시 `halt_cmd` bit indexing이 맞아야 한다.
- payload는 상태와 무관하게 pass-through되어야 한다.

## Testbench

통합 호환 testbench:

- `tb/tb_slave2_reuse_compat.v`

검증 항목:

- encoder/decoder roundtrip
- correction 가능한 data single-bit error 전수 검사
- parity bit single-bit error 검사
- overall parity bit 단독 error 정책 확인
- double-bit error flag 검사
- `slave_control` reset, active, halt, guard latch, 2-bit error ignore, payload pass-through 검사

## Simulation

실행 Tcl:

- `sim/slave2_reuse_compat/run_xsim.tcl`

실행 명령:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave2_reuse_compat\run_xsim.tcl
```

## Verification Result

2026-06-03 현재 결과:

- `tb_slave2_reuse_compat`: PASS
- Vivado/xsim compile, elaboration, simulation: PASS

실행 로그 기준:

```text
PASS: tb_slave2_reuse_compat completed checks with no failures
```

## 수정 필요성 판단

검증 범위 내에서는 Slave 2.0 direct reuse를 막는 수정 필요 사항이 발견되지 않았다.

단, `slave_hamming_dec`의 single-bit correction 정책은 일반적인 systematic Hamming 기대와 다를 수 있다. syndrome이 `1,2,4,8,16,32`인 data bit 오류는 기존 source 정책상 correction되지 않으므로, Slave 2.0 상위 설계는 이 leaf를 "Master source 호환 decoder"로 취급해야 한다. 이 정책 변경이 필요하면 1.0 source를 수정하지 말고 별도 2.0 decoder wrapper 또는 신규 decoder TB를 작성해 검증해야 한다.

