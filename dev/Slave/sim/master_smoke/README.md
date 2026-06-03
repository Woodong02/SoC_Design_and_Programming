# Master Smoke Check

Master RTL의 Vivado 2019.1 read/elaboration smoke check 위치이다.

## Scripts

| Script | Purpose |
|---|---|
| `scripts/smoke_master_ip.tcl` | 일반 Vivado RTL smoke check |
| `scripts/smoke_master_ip_strict_nettype.tcl` | `default_nettype none` guard를 둔 strict smoke check |

## Run Commands

프로젝트 루트에서 실행한다.

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch `
  -source sim\master_smoke\scripts\smoke_master_ip.tcl `
  -log sim\master_smoke\logs\smoke_master_ip.log `
  -journal sim\master_smoke\logs\smoke_master_ip.jou

& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch `
  -source sim\master_smoke\scripts\smoke_master_ip_strict_nettype.tcl `
  -log sim\master_smoke\logs\smoke_master_ip_strict_nettype.log `
  -journal sim\master_smoke\logs\smoke_master_ip_strict_nettype.jou
```

## Artifact Policy

- `logs`에는 `.log`와 `.jou`를 둔다.
- `work`에는 Vivado working files와 임시 `.Xil`이 생길 수 있다.
- 루트 디렉토리에 새 Vivado 로그가 생기면 정리 대상으로 본다.

