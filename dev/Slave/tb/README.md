# Testbench Directory

Slave module-level 및 integration testbench를 이 디렉토리에 작성한다.

## 규칙

- 각 module testbench는 해당 module design note와 source 작성 후에 만든다.
- Self-checking testbench여야 한다.
- Terminal output에 명확한 PASS/FAIL을 출력한다.
- Reset, valid input class, FSM transition, boundary/error case를 검증한다.
- Parent module testbench는 child module testbench PASS 후 작성한다.

## Naming

| Pattern | Purpose |
|---|---|
| `tb_slave_<module>.v` | Module-level testbench |
| `tb_slave_top.v` | Slave top integration testbench |
| `tb_master_slave_*.v` | Master/Slave communication integration testbench |

