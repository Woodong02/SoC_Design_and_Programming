# `slave21_top` full serial simulation

## 대상

- Source: `Slave_ip/v2_1/slave21_top.v`
- Testbench: `tb/tb_slave21_top_full_serial.v`

## 실행

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave21_top_full_serial\run_xsim.tcl
```

## PASS 기준

```text
PASS: tb_slave21_top_full_serial
```

## 검증 범위

- 실제 serial Master broadcast frame 2회 주입
- first good broadcast 후 TX 없음
- second good broadcast 후 TRACKING
- Slave response preamble/node/payload/Hamming decode 확인

## 2026-06-03 실행 결과

```text
PASS: tb_slave21_top_full_serial
```

세부 marker:

```text
[PASS] first good no tracking
[PASS] first good guard latch
[PASS] first good no tx
[PASS] second good tracking
[PASS] second good not halted
[PASS] response preamble
[PASS] response node id
[PASS] response payload
[PASS] response no 2bit hamming
PASS: tb_slave21_top_full_serial
```

TB timing note:

- 두 Master broadcast의 frame-start interval을 `(NODE_CNT + 1) * (50 * BIT_PERIOD + GUARD_TICKS)`로 맞춘다.
- 두 번째 broadcast 뒤에는 고정 idle delay를 넣지 않는다. node slot TX가 commit 후 짧은 guard 뒤 시작되므로, capture는 second frame 직후 즉시 response edge를 기다린다.
- response monitor는 DUT의 현재 bit period를 기준으로 serial output을 sample한다. TX frame은 force하지 않는다.

`xvlog.log` / `xelab.log`: `ERROR`, `CRITICAL`, `WARNING` pattern 없음.
