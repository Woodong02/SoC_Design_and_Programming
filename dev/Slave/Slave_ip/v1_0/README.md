# Slave IP v1.0 Source Directory

이 디렉토리는 기존 Slave 1.0 Verilog source를 보존한다.

2.0 통신 강인성 개선 작업은 `../v2_0`에서 진행한다.

## 규칙

- Pure Verilog만 사용한다.
- 각 module source 작성 전 `docs/slave_design`에 Korean-centered design note를 먼저 작성한다.
- Module naming은 `slave_*` 형식을 따른다.
- Leaf module부터 작성하고 검증한다.
- 현재 확정된 module structure는 `docs/slave_design/00_slave_spec_and_module_structure.md`를 따른다.

## Planned Modules

| Module | Purpose |
|---|---|
| `slave_hamming_enc.v` | Master 호환 SECDED encoding |
| `slave_hamming_dec.v` | Master broadcast SECDED decoding |
| `slave_rx.v` | Master broadcast serial RX |
| `slave_tx.v` | Slave response serial TX |
| `slave_slot_timer.v` | Sync/slot timing/TX trigger |
| `slave_control.v` | Halt, guard latch, payload policy |
| `slave_top.v` | Top integration |
