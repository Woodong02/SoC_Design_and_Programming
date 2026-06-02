# ─── tdma_slave_sys.xdc ───────────────────────────────────────────────────────

# ── Clock (M19) ───────────────────────────────────────────────────────────────
set_property PACKAGE_PIN  M19      [get_ports "clk"]
set_property IOSTANDARD   LVCMOS33 [get_ports "clk"]
create_clock -name clk -period 40.000 [get_ports "clk"]
# period 40.000 = 25 MHz (마스터 측 클럭과 동일)

# ── Reset (Y18 / PUSH_G0) ─────────────────────────────────────────────────────
# 버튼을 누르면 Low → rst_n = 0 → 리셋 동작
set_property PACKAGE_PIN  Y18      [get_ports "rst_n"]
set_property IOSTANDARD   LVCMOS33 [get_ports "rst_n"]

# ── Bus A: 마스터 브로드캐스트 수신 (E16, 입력) ──────────────────────────────
set_property PACKAGE_PIN  E16      [get_ports "tx_line"]
set_property IOSTANDARD   LVCMOS33 [get_ports "tx_line"]

# ── Bus B: 슬레이브 송신 (F16, tristate inout) ────────────────────────────────
# 1'bz 전파 → Vivado가 OBUFT 자동 추론
set_property PACKAGE_PIN  F16      [get_ports "rx_line"]
set_property IOSTANDARD   LVCMOS33 [get_ports "rx_line"]
