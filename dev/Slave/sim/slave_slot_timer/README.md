# slave_slot_timer simulation

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave_slot_timer\run_xsim.tcl
```

## 검증 범위

- reset/unsynced
- sync preload
- counter increment
- slot increment/wrap
- repeated sync resync
- node slot TX trigger
- invalid node trigger block

