## Slave IP v2.2 board constraints
## Board : Huins RPS-Z020-TK / Xilinx Zynq-7000 xc7z020clg484-1
## Top   : slave22_fpga_top (Slave_ip/v2_2/slave22_fpga_top.v)
##
## 마스터 top.xdc(Master_ps/top.xdc)와 물리 핀을 공통으로 맞춘다. 같은 보드.
## 케이블 = 점대점 / 단방향 / crossover:
##   Master GPIO_out(E16) ──> Slave i_MASTER_SERIAL(F16)
##   Slave  o_SLAVE_SERIAL(E16) ──> Master GPIO_in(F16)
##   + 공통 GND 최소 1선 (가능하면 신호별 리턴 GND)
## 즉 두 보드 모두 "E16=송신, F16=수신" 역할로 동일하게 두고, 케이블이 E16<->F16을 교차한다.

## ---------------------------------------------------------------------------
## 25 MHz 시스템 클럭  (마스터 clk_0 와 동일 핀 M19, period 40ns)
## ---------------------------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports i_CLK]
set_property PACKAGE_PIN M19     [get_ports i_CLK]
create_clock -period 40.000 -name sys_clk -waveform {0.000 20.000} [get_ports i_CLK]

## ---------------------------------------------------------------------------
## 리셋  (active-low, 마스터 resetn_bt_0 와 동일 핀 Y18)
## 주의: 보드 버튼의 물리 극성이 active-high면 wrapper 또는 BD에서 반전 필요.
##       마스터가 resetn_bt_0를 어떻게 받는지와 동일하게 맞출 것.
## ---------------------------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports i_RESETN]
set_property PACKAGE_PIN Y18     [get_ports i_RESETN]

## ---------------------------------------------------------------------------
## 통신 라인
## ---------------------------------------------------------------------------
## 슬레이브 수신 (마스터 GPIO_out 에서 옴).  마스터 GPIO_in 과 동일 핀 F16.
## PULLDOWN: 마스터가 라인을 구동하기 전(미구성 구간)에 입력이 떠서
##           가짜 상승에지=가짜 preamble 로 읽히는 것을 방지. idle=0 고정.
set_property IOSTANDARD LVCMOS33 [get_ports i_MASTER_SERIAL]
set_property PACKAGE_PIN F16     [get_ports i_MASTER_SERIAL]
set_property PULLDOWN   true      [get_ports i_MASTER_SERIAL]

## 슬레이브 송신 (마스터 GPIO_in 으로 감).  마스터 GPIO_out 과 동일 핀 E16.
## idle 에 능동 0 구동(push-pull). 점대점 단방향이라 충돌 없음.
set_property IOSTANDARD LVCMOS33 [get_ports o_SLAVE_SERIAL]
set_property PACKAGE_PIN E16     [get_ports o_SLAVE_SERIAL]

## 비동기 입력(2-FF synchronizer 통과)이므로 입력 경로는 false path 처리.
set_false_path -from [get_ports i_MASTER_SERIAL]

## ---------------------------------------------------------------------------
## 상태 LED (선택, bring-up 디버그용)  — 마스터 LED 핀과 동일 위치
##   o_LED_TRACKING : link tracking (정상 통신 중)        = 마스터 LED_out_0 (T17)
##   o_LED_FAULT    : halted | rate_err (정지/속도오류)   = 마스터 LED_in_0  (T16)
## ---------------------------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports o_LED_TRACKING]
set_property PACKAGE_PIN T17     [get_ports o_LED_TRACKING]

set_property IOSTANDARD LVCMOS33 [get_ports o_LED_FAULT]
set_property PACKAGE_PIN T16     [get_ports o_LED_FAULT]
