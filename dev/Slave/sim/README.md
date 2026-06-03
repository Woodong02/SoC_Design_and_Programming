# Simulation Workspace

이 디렉토리는 Vivado/xsim 또는 ModelSim 실행 스크립트와 실행 산출물을 보관한다.

## 규칙

- 루트 디렉토리에 `.log`, `.jou`, `.backup.*`, `.Xil` 같은 tool artifact를 남기지 않는다.
- 실행 로그와 journal은 각 simulation 하위 디렉토리의 `logs` 폴더로 보낸다.
- Vivado batch 실행 시 `-log`와 `-journal`을 명시한다.
- Vivado 작업 디렉토리와 임시 `.Xil`은 각 simulation 하위 디렉토리의 `work` 폴더 안에 둔다.

## 현재 하위 디렉토리

| Path | Purpose |
|---|---|
| `master_smoke` | Master RTL read/elaboration smoke check |

