# slave_top integration simulation

## 실행 명령

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source sim\slave_top\run_xsim.tcl
```

## 검증 범위

- valid master broadcast 수신
- sync/guard latch/control active
- slave response frame decode
- halt broadcast 이후 TX silence
- halt clear 이후 response 재개
- wrong preamble이 control latch를 변경하지 않음

