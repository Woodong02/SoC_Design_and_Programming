# Master/Slave Harsh Link 검증 기록

## 목적

현실 장비에서는 Master와 Slave가 완전히 같은 clock을 공유하지 않고, board 간 line에도 전파 지연과 transition별 지터가 존재할 수 있다. 이 문서는 별도 clock domain과 지연 line model을 사용해 현재 slave 통신 구조의 여유를 확인한 기록이다.

## 대상

- Master source: `Master_ip/Master_tx.v`, `Master_ip/Master_rx.v`, `Master_ip/hamming_enc.v`, `Master_ip/hamming_dec.v`
- Slave source: `Slave_ip/v1_0/slave_top.v` 및 하위 slave modules
- Testbench: `tb/tb_slave_master_harsh_link.v`
- Script: `sim/slave_master_harsh_link/run_xsim.tcl`

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave_master_harsh_link\run_xsim.tcl
```

## Testbench 모델

```text
Master_tx / Master_rx: master_clk
slave_top:              slave_clk

Master_tx.GPIO_out -- delayed/jittered line --> slave_top.i_MASTER_SERIAL
slave_top.o_SLAVE_SERIAL -- delayed/jittered line --> Master_rx.GPIO_in
```

- Master와 Slave clock period를 scenario별로 다르게 설정한다.
- Line model은 transition마다 base propagation delay를 적용한다.
- 일부 transition에는 deterministic jitter를 더하거나 빼서 sampling margin을 흔든다.
- Analog rise/fall, metastability, random noise, drive contention은 아직 모델링하지 않았다.

## 시나리오 결과

| No. | Scenario | Must-pass | 결과 |
|---:|---|---:|---|
| 1 | nominal separate clocks, no delay | Yes | PASS |
| 2 | slave clock +0.25% fast | Yes | PASS |
| 3 | slave clock -0.25% slow | Yes | PASS |
| 4 | quarter-bit propagation delay with transition jitter | Yes | PASS |
| 5 | combined mild drift and delayed noisy line | Yes | PASS |
| 6 | exploratory extreme slave +2% fast | No | LIMIT EXPOSED |

주요 로그:

```text
[SCENARIO 2] slave clock +0.25 percent fast
[PASS] response decoded correctly under scenario

[SCENARIO 3] slave clock -0.25 percent slow
[PASS] response decoded correctly under scenario

[SCENARIO 4] quarter-bit propagation delay with transition jitter
[PASS] response decoded correctly under scenario

[SCENARIO 5] combined mild drift and delayed noisy line
[PASS] response decoded correctly under scenario

[SCENARIO 6] exploratory extreme slave +2 percent fast
[OBSERVE] slave did not latch broadcast guard within timeout
[INFO] exploratory harsh scenario exposed limit

PASS: tb_slave_master_harsh_link must-pass scenarios survived, total_scenarios=6
```

## 해석

- 현재 RX 구조는 preamble 첫 bit를 기준으로 frame 수신을 시작하고, 이후 local `BIT_DIV` 중앙 sample로 50-bit frame을 읽는다.
- 별도 clock 간 오차가 누적되므로, 큰 오차에서는 preamble 또는 codeword sample point가 bit center에서 벗어난다.
- `+2%` fast scenario는 50-bit continuous frame에서 누적 drift가 커져 broadcast latch 자체가 실패했다. 이는 현재 구조의 자연스러운 한계로 기록한다.
- `±0.25%`와 지연/jitter 조합은 현재 chosen `BIT_DIV=16` stress setup에서 정상 decode되었다.

## 잔여 시험 제안

- random jitter seed 기반 반복 시험
- asymmetric rise/fall delay
- short glitch/noise pulse injection
- `Master_slot.rx_stat`까지 포함한 timing fault score 검증
- 여러 `BIT_DIV` 값에서 drift 허용 범위 sweep

