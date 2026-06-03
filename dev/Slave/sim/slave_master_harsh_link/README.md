# slave_master_harsh_link simulation

## 목적

Master와 Slave가 같은 clock을 공유하지 않는 현실 조건을 모사한다.

- Master TX/RX: `master_clk`
- Slave top: `slave_clk`
- 양방향 serial line: transition별 propagation delay와 deterministic jitter 적용

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave_master_harsh_link\run_xsim.tcl
```

## 시나리오

- nominal separate clocks
- slave clock +0.25% fast
- slave clock -0.25% slow
- quarter-bit propagation delay with transition jitter
- combined mild drift and delayed noisy line
- exploratory extreme slave +2% fast

마지막 extreme case는 한계 관찰용이며, 실패해도 회귀 실패로 처리하지 않는다.

