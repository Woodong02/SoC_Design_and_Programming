# `slave_slot_timer` 검증 기록

## 대상

- Source: `Slave_ip/v1_0/slave_slot_timer.v`
- Testbench: `tb/tb_slave_slot_timer.v`
- Script: `sim/slave_slot_timer/run_xsim.tcl`

## 실행 환경

- Tool: Vivado 2019.1 / xsim
- Command:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave_slot_timer\run_xsim.tcl
```

## 검증 항목

- reset 후 `o_SYNCED=0`, `o_SLOT=0`, `o_CLK_CNT=0`, `o_TX_TRIGGER=0`
- sync pulse 후 locked 진입, slot 0, preload count 반영
- sync pulse cycle에서 trigger 차단
- locked 상태 counter 증가
- `NODE_ID` slot에서 `GUARD_TICKS >> 1` 이후 registered trigger 발생
- `NODE_CNT` 마지막 slot 이후 slot 0 wrap
- repeated sync pulse가 즉시 slot 0/preload로 resync
- `NODE_ID > NODE_CNT`이면 trigger 미발생

## 결과

PASS.

주요 terminal 출력:

```text
[PASS] reset synced got=0
[PASS] sync enters locked got=1
[PASS] sync preload clk_cnt got=3
[WAVE] TX trigger observed slot=1 clk_cnt=5
[PASS] cycle wrap slot got=0
[PASS] invalid node trigger count got=0
PASS: tb_slave_slot_timer
```

## 주의 및 잔여 리스크

- Vivado가 `slave_slot_timer.v`에 `timescale`이 없다는 warning을 출력했다. DUT는 합성 대상 RTL이고 TB에만 `timescale`이 있어 기능 영향은 없다.
- `o_TX_TRIGGER`는 registered output이므로 testbench에서는 condition cycle 다음 관측 시점에서 확인한다.
- Initial sync 직후 `i_SYNC_CLK_CNT=8*BIT_DIV`가 `GUARD_TICKS>>1`보다 큰 경우 `NODE_ID==0`의 첫 cycle trigger는 생략된다. 이 정책은 `ORCHESTRATOR_DECISIONS.md`에 기록했다.

