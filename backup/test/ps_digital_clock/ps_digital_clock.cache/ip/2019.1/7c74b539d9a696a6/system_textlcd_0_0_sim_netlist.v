// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Tue Apr 28 10:13:02 2026
// Host        : L7735 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ system_textlcd_0_0_sim_netlist.v
// Design      : system_textlcd_0_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7z020clg484-1
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "system_textlcd_0_0,textlcd_v1_0,{}" *) (* DowngradeIPIdentifiedWarnings = "yes" *) (* X_CORE_INFO = "textlcd_v1_0,Vivado 2019.1" *) 
(* NotValidForBitStream *)
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix
   (resetn,
    lcdclk,
    lcd_rs,
    lcd_rw,
    lcd_en,
    lcd_data,
    s00_axi_awaddr,
    s00_axi_awprot,
    s00_axi_awvalid,
    s00_axi_awready,
    s00_axi_wdata,
    s00_axi_wstrb,
    s00_axi_wvalid,
    s00_axi_wready,
    s00_axi_bresp,
    s00_axi_bvalid,
    s00_axi_bready,
    s00_axi_araddr,
    s00_axi_arprot,
    s00_axi_arvalid,
    s00_axi_arready,
    s00_axi_rdata,
    s00_axi_rresp,
    s00_axi_rvalid,
    s00_axi_rready,
    s00_axi_aclk,
    s00_axi_aresetn);
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 resetn RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME resetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *) input resetn;
  input lcdclk;
  output lcd_rs;
  output lcd_rw;
  output lcd_en;
  output [7:0]lcd_data;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI AWADDR" *) input [4:0]s00_axi_awaddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI AWPROT" *) input [2:0]s00_axi_awprot;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI AWVALID" *) input s00_axi_awvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI AWREADY" *) output s00_axi_awready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI WDATA" *) input [31:0]s00_axi_wdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI WSTRB" *) input [3:0]s00_axi_wstrb;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI WVALID" *) input s00_axi_wvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI WREADY" *) output s00_axi_wready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI BRESP" *) output [1:0]s00_axi_bresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI BVALID" *) output s00_axi_bvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI BREADY" *) input s00_axi_bready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI ARADDR" *) input [4:0]s00_axi_araddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI ARPROT" *) input [2:0]s00_axi_arprot;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI ARVALID" *) input s00_axi_arvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI ARREADY" *) output s00_axi_arready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI RDATA" *) output [31:0]s00_axi_rdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI RRESP" *) output [1:0]s00_axi_rresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI RVALID" *) output s00_axi_rvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI RREADY" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S00_AXI, WIZ_DATA_WIDTH 32, WIZ_NUM_REG 8, SUPPORTS_NARROW_BURST 0, DATA_WIDTH 32, PROTOCOL AXI4LITE, FREQ_HZ 50000000, ID_WIDTH 0, ADDR_WIDTH 5, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, NUM_READ_OUTSTANDING 2, NUM_WRITE_OUTSTANDING 2, MAX_BURST_LENGTH 1, PHASE 0.000, CLK_DOMAIN system_processing_system7_0_1_FCLK_CLK0, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *) input s00_axi_rready;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 S00_AXI_CLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S00_AXI_CLK, ASSOCIATED_BUSIF S00_AXI, ASSOCIATED_RESET s00_axi_aresetn:resetn, FREQ_HZ 50000000, PHASE 0.000, CLK_DOMAIN system_processing_system7_0_1_FCLK_CLK0, INSERT_VIP 0" *) input s00_axi_aclk;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 S00_AXI_RST RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S00_AXI_RST, POLARITY ACTIVE_LOW, INSERT_VIP 0" *) input s00_axi_aresetn;

  wire \<const0> ;
  wire [7:0]lcd_data;
  wire lcd_en;
  wire lcd_rs;
  wire lcdclk;
  wire resetn;
  wire s00_axi_aclk;
  wire [4:0]s00_axi_araddr;
  wire s00_axi_aresetn;
  wire s00_axi_arready;
  wire s00_axi_arvalid;
  wire [4:0]s00_axi_awaddr;
  wire s00_axi_awready;
  wire s00_axi_awvalid;
  wire s00_axi_bready;
  wire s00_axi_bvalid;
  wire [31:0]s00_axi_rdata;
  wire s00_axi_rready;
  wire s00_axi_rvalid;
  wire [31:0]s00_axi_wdata;
  wire s00_axi_wready;
  wire [3:0]s00_axi_wstrb;
  wire s00_axi_wvalid;

  assign lcd_rw = \<const0> ;
  assign s00_axi_bresp[1] = \<const0> ;
  assign s00_axi_bresp[0] = \<const0> ;
  assign s00_axi_rresp[1] = \<const0> ;
  assign s00_axi_rresp[0] = \<const0> ;
  GND GND
       (.G(\<const0> ));
  decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_textlcd_v1_0 inst
       (.S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WREADY(s00_axi_wready),
        .lcd_data(lcd_data),
        .lcd_en(lcd_en),
        .lcd_rs(lcd_rs),
        .lcdclk(lcdclk),
        .resetn(resetn),
        .s00_axi_aclk(s00_axi_aclk),
        .s00_axi_araddr(s00_axi_araddr[4:2]),
        .s00_axi_aresetn(s00_axi_aresetn),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_awaddr(s00_axi_awaddr[4:2]),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_bready(s00_axi_bready),
        .s00_axi_bvalid(s00_axi_bvalid),
        .s00_axi_rdata(s00_axi_rdata),
        .s00_axi_rready(s00_axi_rready),
        .s00_axi_rvalid(s00_axi_rvalid),
        .s00_axi_wdata(s00_axi_wdata),
        .s00_axi_wstrb(s00_axi_wstrb),
        .s00_axi_wvalid(s00_axi_wvalid));
endmodule

module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_textlcd
   (lcd_en,
    lcd_data,
    lcd_rs,
    lcdclk,
    Q,
    \lcd_data[7]_INST_0_i_5_0 ,
    \lcd_data[7]_INST_0_i_6_0 ,
    \lcd_data[7]_INST_0_i_6_1 ,
    \lcd_data[7]_INST_0_i_3_0 ,
    \lcd_data[7]_INST_0_i_4_0 ,
    \lcd_data[7]_INST_0_i_4_1 ,
    \lcd_data[7]_INST_0_i_4_2 ,
    resetn);
  output lcd_en;
  output [7:0]lcd_data;
  output lcd_rs;
  input lcdclk;
  input [31:0]Q;
  input [31:0]\lcd_data[7]_INST_0_i_5_0 ;
  input [31:0]\lcd_data[7]_INST_0_i_6_0 ;
  input [31:0]\lcd_data[7]_INST_0_i_6_1 ;
  input [31:0]\lcd_data[7]_INST_0_i_3_0 ;
  input [31:0]\lcd_data[7]_INST_0_i_4_0 ;
  input [31:0]\lcd_data[7]_INST_0_i_4_1 ;
  input [31:0]\lcd_data[7]_INST_0_i_4_2 ;
  input resetn;

  wire [31:0]Q;
  wire \count_lcdclk[0]_i_2_n_0 ;
  wire \count_lcdclk[10]_i_2_n_0 ;
  wire \count_lcdclk[10]_i_3_n_0 ;
  wire \count_lcdclk[10]_i_4_n_0 ;
  wire \count_lcdclk[10]_i_5_n_0 ;
  wire \count_lcdclk[1]_i_2_n_0 ;
  wire \count_lcdclk[2]_i_2_n_0 ;
  wire \count_lcdclk[2]_i_3_n_0 ;
  wire \count_lcdclk[3]_i_2_n_0 ;
  wire \count_lcdclk[3]_i_3_n_0 ;
  wire \count_lcdclk[4]_i_2_n_0 ;
  wire \count_lcdclk[5]_i_2_n_0 ;
  wire \count_lcdclk[6]_i_2_n_0 ;
  wire \count_lcdclk[6]_i_3_n_0 ;
  wire \count_lcdclk[6]_i_4_n_0 ;
  wire \count_lcdclk[7]_i_2_n_0 ;
  wire \count_lcdclk[7]_i_3_n_0 ;
  wire \count_lcdclk[8]_i_2_n_0 ;
  wire \count_lcdclk[8]_i_3_n_0 ;
  wire \count_lcdclk[9]_i_2_n_0 ;
  wire [10:0]count_lcdclk_reg;
  wire count_mode;
  wire \count_mode[5]_i_3_n_0 ;
  wire [5:0]count_mode_reg;
  wire [7:0]lcd_data;
  wire \lcd_data[0]_INST_0_i_10_n_0 ;
  wire \lcd_data[0]_INST_0_i_11_n_0 ;
  wire \lcd_data[0]_INST_0_i_12_n_0 ;
  wire \lcd_data[0]_INST_0_i_13_n_0 ;
  wire \lcd_data[0]_INST_0_i_14_n_0 ;
  wire \lcd_data[0]_INST_0_i_15_n_0 ;
  wire \lcd_data[0]_INST_0_i_1_n_0 ;
  wire \lcd_data[0]_INST_0_i_2_n_0 ;
  wire \lcd_data[0]_INST_0_i_3_n_0 ;
  wire \lcd_data[0]_INST_0_i_4_n_0 ;
  wire \lcd_data[0]_INST_0_i_5_n_0 ;
  wire \lcd_data[0]_INST_0_i_6_n_0 ;
  wire \lcd_data[0]_INST_0_i_7_n_0 ;
  wire \lcd_data[0]_INST_0_i_8_n_0 ;
  wire \lcd_data[0]_INST_0_i_9_n_0 ;
  wire \lcd_data[1]_INST_0_i_10_n_0 ;
  wire \lcd_data[1]_INST_0_i_11_n_0 ;
  wire \lcd_data[1]_INST_0_i_12_n_0 ;
  wire \lcd_data[1]_INST_0_i_13_n_0 ;
  wire \lcd_data[1]_INST_0_i_14_n_0 ;
  wire \lcd_data[1]_INST_0_i_15_n_0 ;
  wire \lcd_data[1]_INST_0_i_1_n_0 ;
  wire \lcd_data[1]_INST_0_i_2_n_0 ;
  wire \lcd_data[1]_INST_0_i_3_n_0 ;
  wire \lcd_data[1]_INST_0_i_4_n_0 ;
  wire \lcd_data[1]_INST_0_i_5_n_0 ;
  wire \lcd_data[1]_INST_0_i_6_n_0 ;
  wire \lcd_data[1]_INST_0_i_7_n_0 ;
  wire \lcd_data[1]_INST_0_i_8_n_0 ;
  wire \lcd_data[1]_INST_0_i_9_n_0 ;
  wire \lcd_data[2]_INST_0_i_10_n_0 ;
  wire \lcd_data[2]_INST_0_i_11_n_0 ;
  wire \lcd_data[2]_INST_0_i_12_n_0 ;
  wire \lcd_data[2]_INST_0_i_13_n_0 ;
  wire \lcd_data[2]_INST_0_i_14_n_0 ;
  wire \lcd_data[2]_INST_0_i_15_n_0 ;
  wire \lcd_data[2]_INST_0_i_1_n_0 ;
  wire \lcd_data[2]_INST_0_i_2_n_0 ;
  wire \lcd_data[2]_INST_0_i_3_n_0 ;
  wire \lcd_data[2]_INST_0_i_4_n_0 ;
  wire \lcd_data[2]_INST_0_i_5_n_0 ;
  wire \lcd_data[2]_INST_0_i_6_n_0 ;
  wire \lcd_data[2]_INST_0_i_7_n_0 ;
  wire \lcd_data[2]_INST_0_i_8_n_0 ;
  wire \lcd_data[2]_INST_0_i_9_n_0 ;
  wire \lcd_data[3]_INST_0_i_10_n_0 ;
  wire \lcd_data[3]_INST_0_i_11_n_0 ;
  wire \lcd_data[3]_INST_0_i_12_n_0 ;
  wire \lcd_data[3]_INST_0_i_13_n_0 ;
  wire \lcd_data[3]_INST_0_i_14_n_0 ;
  wire \lcd_data[3]_INST_0_i_15_n_0 ;
  wire \lcd_data[3]_INST_0_i_1_n_0 ;
  wire \lcd_data[3]_INST_0_i_2_n_0 ;
  wire \lcd_data[3]_INST_0_i_3_n_0 ;
  wire \lcd_data[3]_INST_0_i_4_n_0 ;
  wire \lcd_data[3]_INST_0_i_5_n_0 ;
  wire \lcd_data[3]_INST_0_i_6_n_0 ;
  wire \lcd_data[3]_INST_0_i_7_n_0 ;
  wire \lcd_data[3]_INST_0_i_8_n_0 ;
  wire \lcd_data[3]_INST_0_i_9_n_0 ;
  wire \lcd_data[4]_INST_0_i_10_n_0 ;
  wire \lcd_data[4]_INST_0_i_11_n_0 ;
  wire \lcd_data[4]_INST_0_i_12_n_0 ;
  wire \lcd_data[4]_INST_0_i_13_n_0 ;
  wire \lcd_data[4]_INST_0_i_14_n_0 ;
  wire \lcd_data[4]_INST_0_i_15_n_0 ;
  wire \lcd_data[4]_INST_0_i_1_n_0 ;
  wire \lcd_data[4]_INST_0_i_2_n_0 ;
  wire \lcd_data[4]_INST_0_i_3_n_0 ;
  wire \lcd_data[4]_INST_0_i_4_n_0 ;
  wire \lcd_data[4]_INST_0_i_5_n_0 ;
  wire \lcd_data[4]_INST_0_i_6_n_0 ;
  wire \lcd_data[4]_INST_0_i_7_n_0 ;
  wire \lcd_data[4]_INST_0_i_8_n_0 ;
  wire \lcd_data[4]_INST_0_i_9_n_0 ;
  wire \lcd_data[5]_INST_0_i_10_n_0 ;
  wire \lcd_data[5]_INST_0_i_11_n_0 ;
  wire \lcd_data[5]_INST_0_i_12_n_0 ;
  wire \lcd_data[5]_INST_0_i_13_n_0 ;
  wire \lcd_data[5]_INST_0_i_14_n_0 ;
  wire \lcd_data[5]_INST_0_i_15_n_0 ;
  wire \lcd_data[5]_INST_0_i_1_n_0 ;
  wire \lcd_data[5]_INST_0_i_2_n_0 ;
  wire \lcd_data[5]_INST_0_i_3_n_0 ;
  wire \lcd_data[5]_INST_0_i_4_n_0 ;
  wire \lcd_data[5]_INST_0_i_5_n_0 ;
  wire \lcd_data[5]_INST_0_i_6_n_0 ;
  wire \lcd_data[5]_INST_0_i_7_n_0 ;
  wire \lcd_data[5]_INST_0_i_8_n_0 ;
  wire \lcd_data[5]_INST_0_i_9_n_0 ;
  wire \lcd_data[6]_INST_0_i_10_n_0 ;
  wire \lcd_data[6]_INST_0_i_11_n_0 ;
  wire \lcd_data[6]_INST_0_i_12_n_0 ;
  wire \lcd_data[6]_INST_0_i_13_n_0 ;
  wire \lcd_data[6]_INST_0_i_14_n_0 ;
  wire \lcd_data[6]_INST_0_i_15_n_0 ;
  wire \lcd_data[6]_INST_0_i_1_n_0 ;
  wire \lcd_data[6]_INST_0_i_2_n_0 ;
  wire \lcd_data[6]_INST_0_i_3_n_0 ;
  wire \lcd_data[6]_INST_0_i_4_n_0 ;
  wire \lcd_data[6]_INST_0_i_5_n_0 ;
  wire \lcd_data[6]_INST_0_i_6_n_0 ;
  wire \lcd_data[6]_INST_0_i_7_n_0 ;
  wire \lcd_data[6]_INST_0_i_8_n_0 ;
  wire \lcd_data[6]_INST_0_i_9_n_0 ;
  wire \lcd_data[7]_INST_0_i_10_n_0 ;
  wire \lcd_data[7]_INST_0_i_11_n_0 ;
  wire \lcd_data[7]_INST_0_i_12_n_0 ;
  wire \lcd_data[7]_INST_0_i_13_n_0 ;
  wire \lcd_data[7]_INST_0_i_14_n_0 ;
  wire \lcd_data[7]_INST_0_i_15_n_0 ;
  wire \lcd_data[7]_INST_0_i_1_n_0 ;
  wire \lcd_data[7]_INST_0_i_2_n_0 ;
  wire [31:0]\lcd_data[7]_INST_0_i_3_0 ;
  wire \lcd_data[7]_INST_0_i_3_n_0 ;
  wire [31:0]\lcd_data[7]_INST_0_i_4_0 ;
  wire [31:0]\lcd_data[7]_INST_0_i_4_1 ;
  wire [31:0]\lcd_data[7]_INST_0_i_4_2 ;
  wire \lcd_data[7]_INST_0_i_4_n_0 ;
  wire [31:0]\lcd_data[7]_INST_0_i_5_0 ;
  wire \lcd_data[7]_INST_0_i_5_n_0 ;
  wire [31:0]\lcd_data[7]_INST_0_i_6_0 ;
  wire [31:0]\lcd_data[7]_INST_0_i_6_1 ;
  wire \lcd_data[7]_INST_0_i_6_n_0 ;
  wire \lcd_data[7]_INST_0_i_7_n_0 ;
  wire \lcd_data[7]_INST_0_i_8_n_0 ;
  wire \lcd_data[7]_INST_0_i_9_n_0 ;
  wire lcd_en;
  wire lcd_en0;
  wire lcd_en_i_1_n_0;
  wire lcd_en_i_2_n_0;
  wire lcd_en_i_3_n_0;
  wire lcd_en_i_5_n_0;
  wire [3:0]lcd_mode;
  wire \lcd_mode[3]_i_1_n_0 ;
  wire [3:0]lcd_mode_0;
  wire lcd_rs;
  wire lcdclk;
  wire [10:0]p_0_in__0;
  wire [5:0]p_0_in__1;
  wire resetn;

  (* SOFT_HLUTNM = "soft_lutpair7" *) 
  LUT4 #(
    .INIT(16'h80BF)) 
    \count_lcdclk[0]_i_1 
       (.I0(\count_lcdclk[0]_i_2_n_0 ),
        .I1(count_lcdclk_reg[9]),
        .I2(count_lcdclk_reg[10]),
        .I3(count_lcdclk_reg[0]),
        .O(p_0_in__0[0]));
  LUT6 #(
    .INIT(64'h000000001FFFFFFF)) 
    \count_lcdclk[0]_i_2 
       (.I0(count_lcdclk_reg[4]),
        .I1(count_lcdclk_reg[5]),
        .I2(count_lcdclk_reg[6]),
        .I3(count_lcdclk_reg[7]),
        .I4(count_lcdclk_reg[8]),
        .I5(count_lcdclk_reg[0]),
        .O(\count_lcdclk[0]_i_2_n_0 ));
  LUT4 #(
    .INIT(16'hB8CC)) 
    \count_lcdclk[10]_i_1 
       (.I0(\count_lcdclk[10]_i_2_n_0 ),
        .I1(count_lcdclk_reg[10]),
        .I2(\count_lcdclk[10]_i_3_n_0 ),
        .I3(count_lcdclk_reg[9]),
        .O(p_0_in__0[10]));
  LUT6 #(
    .INIT(64'h5575FFFFFFFFFFFF)) 
    \count_lcdclk[10]_i_2 
       (.I0(count_lcdclk_reg[7]),
        .I1(count_lcdclk_reg[5]),
        .I2(\count_lcdclk[10]_i_4_n_0 ),
        .I3(count_lcdclk_reg[4]),
        .I4(count_lcdclk_reg[6]),
        .I5(count_lcdclk_reg[8]),
        .O(\count_lcdclk[10]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair5" *) 
  LUT4 #(
    .INIT(16'h8000)) 
    \count_lcdclk[10]_i_3 
       (.I0(count_lcdclk_reg[7]),
        .I1(\count_lcdclk[10]_i_5_n_0 ),
        .I2(count_lcdclk_reg[6]),
        .I3(count_lcdclk_reg[8]),
        .O(\count_lcdclk[10]_i_3_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair6" *) 
  LUT4 #(
    .INIT(16'h7FFF)) 
    \count_lcdclk[10]_i_4 
       (.I0(count_lcdclk_reg[2]),
        .I1(count_lcdclk_reg[1]),
        .I2(count_lcdclk_reg[0]),
        .I3(count_lcdclk_reg[3]),
        .O(\count_lcdclk[10]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'h8000000000000000)) 
    \count_lcdclk[10]_i_5 
       (.I0(count_lcdclk_reg[4]),
        .I1(count_lcdclk_reg[2]),
        .I2(count_lcdclk_reg[0]),
        .I3(count_lcdclk_reg[1]),
        .I4(count_lcdclk_reg[3]),
        .I5(count_lcdclk_reg[5]),
        .O(\count_lcdclk[10]_i_5_n_0 ));
  LUT6 #(
    .INIT(64'h8000BFFFBFFF8000)) 
    \count_lcdclk[1]_i_1 
       (.I0(\count_lcdclk[1]_i_2_n_0 ),
        .I1(count_lcdclk_reg[8]),
        .I2(count_lcdclk_reg[9]),
        .I3(count_lcdclk_reg[10]),
        .I4(count_lcdclk_reg[1]),
        .I5(count_lcdclk_reg[0]),
        .O(p_0_in__0[1]));
  LUT6 #(
    .INIT(64'h00001FFF1FFF0000)) 
    \count_lcdclk[1]_i_2 
       (.I0(count_lcdclk_reg[4]),
        .I1(count_lcdclk_reg[5]),
        .I2(count_lcdclk_reg[6]),
        .I3(count_lcdclk_reg[7]),
        .I4(count_lcdclk_reg[1]),
        .I5(count_lcdclk_reg[0]),
        .O(\count_lcdclk[1]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hBFFFFFFF80000000)) 
    \count_lcdclk[2]_i_1 
       (.I0(\count_lcdclk[2]_i_2_n_0 ),
        .I1(count_lcdclk_reg[7]),
        .I2(count_lcdclk_reg[8]),
        .I3(count_lcdclk_reg[9]),
        .I4(count_lcdclk_reg[10]),
        .I5(\count_lcdclk[2]_i_3_n_0 ),
        .O(p_0_in__0[2]));
  LUT6 #(
    .INIT(64'h001F1F001F001F00)) 
    \count_lcdclk[2]_i_2 
       (.I0(count_lcdclk_reg[4]),
        .I1(count_lcdclk_reg[5]),
        .I2(count_lcdclk_reg[6]),
        .I3(count_lcdclk_reg[2]),
        .I4(count_lcdclk_reg[1]),
        .I5(count_lcdclk_reg[0]),
        .O(\count_lcdclk[2]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair6" *) 
  LUT3 #(
    .INIT(8'h6A)) 
    \count_lcdclk[2]_i_3 
       (.I0(count_lcdclk_reg[2]),
        .I1(count_lcdclk_reg[1]),
        .I2(count_lcdclk_reg[0]),
        .O(\count_lcdclk[2]_i_3_n_0 ));
  LUT4 #(
    .INIT(16'hBF80)) 
    \count_lcdclk[3]_i_1 
       (.I0(\count_lcdclk[3]_i_2_n_0 ),
        .I1(count_lcdclk_reg[9]),
        .I2(count_lcdclk_reg[10]),
        .I3(\count_lcdclk[3]_i_3_n_0 ),
        .O(p_0_in__0[3]));
  LUT6 #(
    .INIT(64'h1FFFFFFF00000000)) 
    \count_lcdclk[3]_i_2 
       (.I0(count_lcdclk_reg[4]),
        .I1(count_lcdclk_reg[5]),
        .I2(count_lcdclk_reg[6]),
        .I3(count_lcdclk_reg[7]),
        .I4(count_lcdclk_reg[8]),
        .I5(\count_lcdclk[3]_i_3_n_0 ),
        .O(\count_lcdclk[3]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair3" *) 
  LUT4 #(
    .INIT(16'h6AAA)) 
    \count_lcdclk[3]_i_3 
       (.I0(count_lcdclk_reg[3]),
        .I1(count_lcdclk_reg[1]),
        .I2(count_lcdclk_reg[0]),
        .I3(count_lcdclk_reg[2]),
        .O(\count_lcdclk[3]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFF00000000)) 
    \count_lcdclk[4]_i_1 
       (.I0(count_lcdclk_reg[6]),
        .I1(count_lcdclk_reg[7]),
        .I2(count_lcdclk_reg[8]),
        .I3(count_lcdclk_reg[9]),
        .I4(count_lcdclk_reg[10]),
        .I5(\count_lcdclk[4]_i_2_n_0 ),
        .O(p_0_in__0[4]));
  (* SOFT_HLUTNM = "soft_lutpair3" *) 
  LUT5 #(
    .INIT(32'h6AAAAAAA)) 
    \count_lcdclk[4]_i_2 
       (.I0(count_lcdclk_reg[4]),
        .I1(count_lcdclk_reg[2]),
        .I2(count_lcdclk_reg[0]),
        .I3(count_lcdclk_reg[1]),
        .I4(count_lcdclk_reg[3]),
        .O(\count_lcdclk[4]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFF00000000)) 
    \count_lcdclk[5]_i_1 
       (.I0(count_lcdclk_reg[6]),
        .I1(count_lcdclk_reg[7]),
        .I2(count_lcdclk_reg[8]),
        .I3(count_lcdclk_reg[9]),
        .I4(count_lcdclk_reg[10]),
        .I5(\count_lcdclk[5]_i_2_n_0 ),
        .O(p_0_in__0[5]));
  LUT6 #(
    .INIT(64'h6AAAAAAAAAAAAAAA)) 
    \count_lcdclk[5]_i_2 
       (.I0(count_lcdclk_reg[5]),
        .I1(count_lcdclk_reg[3]),
        .I2(count_lcdclk_reg[1]),
        .I3(count_lcdclk_reg[0]),
        .I4(count_lcdclk_reg[2]),
        .I5(count_lcdclk_reg[4]),
        .O(\count_lcdclk[5]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hBFFFFFFF80000000)) 
    \count_lcdclk[6]_i_1 
       (.I0(\count_lcdclk[6]_i_2_n_0 ),
        .I1(count_lcdclk_reg[7]),
        .I2(count_lcdclk_reg[8]),
        .I3(count_lcdclk_reg[9]),
        .I4(count_lcdclk_reg[10]),
        .I5(\count_lcdclk[6]_i_3_n_0 ),
        .O(p_0_in__0[6]));
  LUT6 #(
    .INIT(64'h4000000002222222)) 
    \count_lcdclk[6]_i_2 
       (.I0(count_lcdclk_reg[6]),
        .I1(count_lcdclk_reg[4]),
        .I2(count_lcdclk_reg[2]),
        .I3(\count_lcdclk[6]_i_4_n_0 ),
        .I4(count_lcdclk_reg[3]),
        .I5(count_lcdclk_reg[5]),
        .O(\count_lcdclk[6]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'h6AAAAAAAAAAAAAAA)) 
    \count_lcdclk[6]_i_3 
       (.I0(count_lcdclk_reg[6]),
        .I1(count_lcdclk_reg[4]),
        .I2(count_lcdclk_reg[2]),
        .I3(\count_lcdclk[6]_i_4_n_0 ),
        .I4(count_lcdclk_reg[3]),
        .I5(count_lcdclk_reg[5]),
        .O(\count_lcdclk[6]_i_3_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair7" *) 
  LUT2 #(
    .INIT(4'h8)) 
    \count_lcdclk[6]_i_4 
       (.I0(count_lcdclk_reg[0]),
        .I1(count_lcdclk_reg[1]),
        .O(\count_lcdclk[6]_i_4_n_0 ));
  LUT5 #(
    .INIT(32'hBFFF8000)) 
    \count_lcdclk[7]_i_1 
       (.I0(\count_lcdclk[7]_i_2_n_0 ),
        .I1(count_lcdclk_reg[8]),
        .I2(count_lcdclk_reg[9]),
        .I3(count_lcdclk_reg[10]),
        .I4(\count_lcdclk[7]_i_3_n_0 ),
        .O(p_0_in__0[7]));
  LUT6 #(
    .INIT(64'h04FF0400FF00FF00)) 
    \count_lcdclk[7]_i_2 
       (.I0(count_lcdclk_reg[5]),
        .I1(\count_lcdclk[10]_i_4_n_0 ),
        .I2(count_lcdclk_reg[4]),
        .I3(count_lcdclk_reg[7]),
        .I4(\count_lcdclk[10]_i_5_n_0 ),
        .I5(count_lcdclk_reg[6]),
        .O(\count_lcdclk[7]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hDFFFDF00FF00FF00)) 
    \count_lcdclk[7]_i_3 
       (.I0(count_lcdclk_reg[5]),
        .I1(\count_lcdclk[10]_i_4_n_0 ),
        .I2(count_lcdclk_reg[4]),
        .I3(count_lcdclk_reg[7]),
        .I4(\count_lcdclk[10]_i_5_n_0 ),
        .I5(count_lcdclk_reg[6]),
        .O(\count_lcdclk[7]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hBF80FFFFBF800000)) 
    \count_lcdclk[8]_i_1 
       (.I0(\count_lcdclk[8]_i_2_n_0 ),
        .I1(count_lcdclk_reg[9]),
        .I2(count_lcdclk_reg[10]),
        .I3(\count_lcdclk[9]_i_2_n_0 ),
        .I4(count_lcdclk_reg[8]),
        .I5(\count_lcdclk[8]_i_3_n_0 ),
        .O(p_0_in__0[8]));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT5 #(
    .INIT(32'h5575FFFF)) 
    \count_lcdclk[8]_i_2 
       (.I0(count_lcdclk_reg[6]),
        .I1(count_lcdclk_reg[4]),
        .I2(\count_lcdclk[10]_i_4_n_0 ),
        .I3(count_lcdclk_reg[5]),
        .I4(count_lcdclk_reg[7]),
        .O(\count_lcdclk[8]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair5" *) 
  LUT3 #(
    .INIT(8'h80)) 
    \count_lcdclk[8]_i_3 
       (.I0(count_lcdclk_reg[6]),
        .I1(\count_lcdclk[10]_i_5_n_0 ),
        .I2(count_lcdclk_reg[7]),
        .O(\count_lcdclk[8]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hB8BBFFFFB8BB0000)) 
    \count_lcdclk[9]_i_1 
       (.I0(\count_lcdclk[10]_i_2_n_0 ),
        .I1(count_lcdclk_reg[10]),
        .I2(\count_lcdclk[9]_i_2_n_0 ),
        .I3(count_lcdclk_reg[8]),
        .I4(count_lcdclk_reg[9]),
        .I5(\count_lcdclk[10]_i_3_n_0 ),
        .O(p_0_in__0[9]));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT5 #(
    .INIT(32'hF7FFFFFF)) 
    \count_lcdclk[9]_i_2 
       (.I0(count_lcdclk_reg[6]),
        .I1(count_lcdclk_reg[4]),
        .I2(\count_lcdclk[10]_i_4_n_0 ),
        .I3(count_lcdclk_reg[5]),
        .I4(count_lcdclk_reg[7]),
        .O(\count_lcdclk[9]_i_2_n_0 ));
  FDCE \count_lcdclk_reg[0] 
       (.C(lcdclk),
        .CE(1'b1),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__0[0]),
        .Q(count_lcdclk_reg[0]));
  FDCE \count_lcdclk_reg[10] 
       (.C(lcdclk),
        .CE(1'b1),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__0[10]),
        .Q(count_lcdclk_reg[10]));
  FDCE \count_lcdclk_reg[1] 
       (.C(lcdclk),
        .CE(1'b1),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__0[1]),
        .Q(count_lcdclk_reg[1]));
  FDCE \count_lcdclk_reg[2] 
       (.C(lcdclk),
        .CE(1'b1),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__0[2]),
        .Q(count_lcdclk_reg[2]));
  FDCE \count_lcdclk_reg[3] 
       (.C(lcdclk),
        .CE(1'b1),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__0[3]),
        .Q(count_lcdclk_reg[3]));
  FDCE \count_lcdclk_reg[4] 
       (.C(lcdclk),
        .CE(1'b1),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__0[4]),
        .Q(count_lcdclk_reg[4]));
  FDCE \count_lcdclk_reg[5] 
       (.C(lcdclk),
        .CE(1'b1),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__0[5]),
        .Q(count_lcdclk_reg[5]));
  FDCE \count_lcdclk_reg[6] 
       (.C(lcdclk),
        .CE(1'b1),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__0[6]),
        .Q(count_lcdclk_reg[6]));
  FDCE \count_lcdclk_reg[7] 
       (.C(lcdclk),
        .CE(1'b1),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__0[7]),
        .Q(count_lcdclk_reg[7]));
  FDCE \count_lcdclk_reg[8] 
       (.C(lcdclk),
        .CE(1'b1),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__0[8]),
        .Q(count_lcdclk_reg[8]));
  FDCE \count_lcdclk_reg[9] 
       (.C(lcdclk),
        .CE(1'b1),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__0[9]),
        .Q(count_lcdclk_reg[9]));
  (* SOFT_HLUTNM = "soft_lutpair4" *) 
  LUT4 #(
    .INIT(16'hE0FF)) 
    \count_mode[0]_i_1 
       (.I0(count_mode_reg[3]),
        .I1(count_mode_reg[4]),
        .I2(count_mode_reg[5]),
        .I3(count_mode_reg[0]),
        .O(p_0_in__1[0]));
  (* SOFT_HLUTNM = "soft_lutpair4" *) 
  LUT5 #(
    .INIT(32'hE0FFFFE0)) 
    \count_mode[1]_i_1 
       (.I0(count_mode_reg[3]),
        .I1(count_mode_reg[4]),
        .I2(count_mode_reg[5]),
        .I3(count_mode_reg[1]),
        .I4(count_mode_reg[0]),
        .O(p_0_in__1[1]));
  LUT6 #(
    .INIT(64'hE0FFFFE0FFE0FFE0)) 
    \count_mode[2]_i_1 
       (.I0(count_mode_reg[3]),
        .I1(count_mode_reg[4]),
        .I2(count_mode_reg[5]),
        .I3(count_mode_reg[2]),
        .I4(count_mode_reg[1]),
        .I5(count_mode_reg[0]),
        .O(p_0_in__1[2]));
  LUT6 #(
    .INIT(64'h0730303030303030)) 
    \count_mode[3]_i_1 
       (.I0(count_mode_reg[4]),
        .I1(count_mode_reg[5]),
        .I2(count_mode_reg[3]),
        .I3(count_mode_reg[1]),
        .I4(count_mode_reg[0]),
        .I5(count_mode_reg[2]),
        .O(p_0_in__1[3]));
  LUT6 #(
    .INIT(64'h000000007FFF8000)) 
    \count_mode[4]_i_1 
       (.I0(count_mode_reg[3]),
        .I1(count_mode_reg[1]),
        .I2(count_mode_reg[0]),
        .I3(count_mode_reg[2]),
        .I4(count_mode_reg[4]),
        .I5(count_mode_reg[5]),
        .O(p_0_in__1[4]));
  LUT6 #(
    .INIT(64'h8000000000000000)) 
    \count_mode[5]_i_1 
       (.I0(count_lcdclk_reg[9]),
        .I1(count_lcdclk_reg[7]),
        .I2(\count_mode[5]_i_3_n_0 ),
        .I3(count_lcdclk_reg[6]),
        .I4(count_lcdclk_reg[8]),
        .I5(count_lcdclk_reg[10]),
        .O(count_mode));
  LUT6 #(
    .INIT(64'h4000000022222222)) 
    \count_mode[5]_i_2 
       (.I0(count_mode_reg[5]),
        .I1(count_mode_reg[3]),
        .I2(count_mode_reg[1]),
        .I3(count_mode_reg[0]),
        .I4(count_mode_reg[2]),
        .I5(count_mode_reg[4]),
        .O(p_0_in__1[5]));
  LUT6 #(
    .INIT(64'h0000000040000000)) 
    \count_mode[5]_i_3 
       (.I0(count_lcdclk_reg[4]),
        .I1(count_lcdclk_reg[2]),
        .I2(count_lcdclk_reg[0]),
        .I3(count_lcdclk_reg[1]),
        .I4(count_lcdclk_reg[3]),
        .I5(count_lcdclk_reg[5]),
        .O(\count_mode[5]_i_3_n_0 ));
  FDCE \count_mode_reg[0] 
       (.C(lcdclk),
        .CE(count_mode),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__1[0]),
        .Q(count_mode_reg[0]));
  FDCE \count_mode_reg[1] 
       (.C(lcdclk),
        .CE(count_mode),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__1[1]),
        .Q(count_mode_reg[1]));
  FDCE \count_mode_reg[2] 
       (.C(lcdclk),
        .CE(count_mode),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__1[2]),
        .Q(count_mode_reg[2]));
  FDCE \count_mode_reg[3] 
       (.C(lcdclk),
        .CE(count_mode),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__1[3]),
        .Q(count_mode_reg[3]));
  FDCE \count_mode_reg[4] 
       (.C(lcdclk),
        .CE(count_mode),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__1[4]),
        .Q(count_mode_reg[4]));
  FDCE \count_mode_reg[5] 
       (.C(lcdclk),
        .CE(count_mode),
        .CLR(lcd_en_i_2_n_0),
        .D(p_0_in__1[5]),
        .Q(count_mode_reg[5]));
  LUT6 #(
    .INIT(64'h000F000000C000A0)) 
    \lcd_data[0]_INST_0 
       (.I0(\lcd_data[0]_INST_0_i_1_n_0 ),
        .I1(\lcd_data[0]_INST_0_i_2_n_0 ),
        .I2(lcd_mode[3]),
        .I3(lcd_mode[0]),
        .I4(lcd_mode[1]),
        .I5(lcd_mode[2]),
        .O(lcd_data[0]));
  LUT6 #(
    .INIT(64'hCDC8DDDDCDC88888)) 
    \lcd_data[0]_INST_0_i_1 
       (.I0(count_mode_reg[5]),
        .I1(\lcd_data[7]_INST_0_i_3_0 [0]),
        .I2(count_mode_reg[3]),
        .I3(\lcd_data[0]_INST_0_i_3_n_0 ),
        .I4(count_mode_reg[4]),
        .I5(\lcd_data[0]_INST_0_i_4_n_0 ),
        .O(\lcd_data[0]_INST_0_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[0]_INST_0_i_10 
       (.I0(\lcd_data[7]_INST_0_i_4_1 [24]),
        .I1(\lcd_data[7]_INST_0_i_4_2 [0]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_2 [8]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_2 [16]),
        .O(\lcd_data[0]_INST_0_i_10_n_0 ));
  LUT5 #(
    .INIT(32'hBFFF8000)) 
    \lcd_data[0]_INST_0_i_11 
       (.I0(\lcd_data[7]_INST_0_i_4_2 [24]),
        .I1(count_mode_reg[0]),
        .I2(count_mode_reg[1]),
        .I3(count_mode_reg[2]),
        .I4(\lcd_data[7]_INST_0_i_3_0 [0]),
        .O(\lcd_data[0]_INST_0_i_11_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[0]_INST_0_i_12 
       (.I0(\lcd_data[7]_INST_0_i_5_0 [0]),
        .I1(\lcd_data[7]_INST_0_i_5_0 [8]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_5_0 [16]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_5_0 [24]),
        .O(\lcd_data[0]_INST_0_i_12_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[0]_INST_0_i_13 
       (.I0(Q[0]),
        .I1(Q[8]),
        .I2(count_mode_reg[1]),
        .I3(Q[16]),
        .I4(count_mode_reg[0]),
        .I5(Q[24]),
        .O(\lcd_data[0]_INST_0_i_13_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[0]_INST_0_i_14 
       (.I0(\lcd_data[7]_INST_0_i_6_1 [0]),
        .I1(\lcd_data[7]_INST_0_i_6_1 [8]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_6_1 [16]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_6_1 [24]),
        .O(\lcd_data[0]_INST_0_i_14_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[0]_INST_0_i_15 
       (.I0(\lcd_data[7]_INST_0_i_6_0 [0]),
        .I1(\lcd_data[7]_INST_0_i_6_0 [8]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_6_0 [16]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_6_0 [24]),
        .O(\lcd_data[0]_INST_0_i_15_n_0 ));
  LUT6 #(
    .INIT(64'hFCFFFFBB30000088)) 
    \lcd_data[0]_INST_0_i_2 
       (.I0(\lcd_data[0]_INST_0_i_5_n_0 ),
        .I1(count_mode_reg[5]),
        .I2(\lcd_data[0]_INST_0_i_6_n_0 ),
        .I3(count_mode_reg[3]),
        .I4(count_mode_reg[4]),
        .I5(Q[0]),
        .O(\lcd_data[0]_INST_0_i_2_n_0 ));
  MUXF7 \lcd_data[0]_INST_0_i_3 
       (.I0(\lcd_data[0]_INST_0_i_7_n_0 ),
        .I1(\lcd_data[0]_INST_0_i_8_n_0 ),
        .O(\lcd_data[0]_INST_0_i_3_n_0 ),
        .S(count_mode_reg[2]));
  LUT5 #(
    .INIT(32'hB8FFB800)) 
    \lcd_data[0]_INST_0_i_4 
       (.I0(\lcd_data[0]_INST_0_i_9_n_0 ),
        .I1(count_mode_reg[2]),
        .I2(\lcd_data[0]_INST_0_i_10_n_0 ),
        .I3(count_mode_reg[3]),
        .I4(\lcd_data[0]_INST_0_i_11_n_0 ),
        .O(\lcd_data[0]_INST_0_i_4_n_0 ));
  MUXF7 \lcd_data[0]_INST_0_i_5 
       (.I0(\lcd_data[0]_INST_0_i_12_n_0 ),
        .I1(\lcd_data[0]_INST_0_i_13_n_0 ),
        .O(\lcd_data[0]_INST_0_i_5_n_0 ),
        .S(count_mode_reg[2]));
  MUXF7 \lcd_data[0]_INST_0_i_6 
       (.I0(\lcd_data[0]_INST_0_i_14_n_0 ),
        .I1(\lcd_data[0]_INST_0_i_15_n_0 ),
        .O(\lcd_data[0]_INST_0_i_6_n_0 ),
        .S(count_mode_reg[2]));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[0]_INST_0_i_7 
       (.I0(\lcd_data[7]_INST_0_i_3_0 [24]),
        .I1(\lcd_data[7]_INST_0_i_4_0 [0]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_0 [8]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_0 [16]),
        .O(\lcd_data[0]_INST_0_i_7_n_0 ));
  LUT5 #(
    .INIT(32'hB8BBB888)) 
    \lcd_data[0]_INST_0_i_8 
       (.I0(\lcd_data[7]_INST_0_i_3_0 [0]),
        .I1(count_mode_reg[1]),
        .I2(\lcd_data[7]_INST_0_i_3_0 [8]),
        .I3(count_mode_reg[0]),
        .I4(\lcd_data[7]_INST_0_i_3_0 [16]),
        .O(\lcd_data[0]_INST_0_i_8_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[0]_INST_0_i_9 
       (.I0(\lcd_data[7]_INST_0_i_4_0 [24]),
        .I1(\lcd_data[7]_INST_0_i_4_1 [0]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_1 [8]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_1 [16]),
        .O(\lcd_data[0]_INST_0_i_9_n_0 ));
  LUT6 #(
    .INIT(64'hF0FFFF00F0C0FFAF)) 
    \lcd_data[1]_INST_0 
       (.I0(\lcd_data[1]_INST_0_i_1_n_0 ),
        .I1(\lcd_data[1]_INST_0_i_2_n_0 ),
        .I2(lcd_mode[3]),
        .I3(lcd_mode[2]),
        .I4(lcd_mode[1]),
        .I5(lcd_mode[0]),
        .O(lcd_data[1]));
  LUT6 #(
    .INIT(64'hCDC8DDDDCDC88888)) 
    \lcd_data[1]_INST_0_i_1 
       (.I0(count_mode_reg[5]),
        .I1(\lcd_data[7]_INST_0_i_3_0 [1]),
        .I2(count_mode_reg[3]),
        .I3(\lcd_data[1]_INST_0_i_3_n_0 ),
        .I4(count_mode_reg[4]),
        .I5(\lcd_data[1]_INST_0_i_4_n_0 ),
        .O(\lcd_data[1]_INST_0_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[1]_INST_0_i_10 
       (.I0(\lcd_data[7]_INST_0_i_4_1 [25]),
        .I1(\lcd_data[7]_INST_0_i_4_2 [1]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_2 [9]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_2 [17]),
        .O(\lcd_data[1]_INST_0_i_10_n_0 ));
  LUT5 #(
    .INIT(32'hBFFF8000)) 
    \lcd_data[1]_INST_0_i_11 
       (.I0(\lcd_data[7]_INST_0_i_4_2 [25]),
        .I1(count_mode_reg[0]),
        .I2(count_mode_reg[1]),
        .I3(count_mode_reg[2]),
        .I4(\lcd_data[7]_INST_0_i_3_0 [1]),
        .O(\lcd_data[1]_INST_0_i_11_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[1]_INST_0_i_12 
       (.I0(\lcd_data[7]_INST_0_i_5_0 [1]),
        .I1(\lcd_data[7]_INST_0_i_5_0 [9]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_5_0 [17]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_5_0 [25]),
        .O(\lcd_data[1]_INST_0_i_12_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[1]_INST_0_i_13 
       (.I0(Q[1]),
        .I1(Q[9]),
        .I2(count_mode_reg[1]),
        .I3(Q[17]),
        .I4(count_mode_reg[0]),
        .I5(Q[25]),
        .O(\lcd_data[1]_INST_0_i_13_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[1]_INST_0_i_14 
       (.I0(\lcd_data[7]_INST_0_i_6_1 [1]),
        .I1(\lcd_data[7]_INST_0_i_6_1 [9]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_6_1 [17]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_6_1 [25]),
        .O(\lcd_data[1]_INST_0_i_14_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[1]_INST_0_i_15 
       (.I0(\lcd_data[7]_INST_0_i_6_0 [1]),
        .I1(\lcd_data[7]_INST_0_i_6_0 [9]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_6_0 [17]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_6_0 [25]),
        .O(\lcd_data[1]_INST_0_i_15_n_0 ));
  LUT6 #(
    .INIT(64'hFCFFFFBB30000088)) 
    \lcd_data[1]_INST_0_i_2 
       (.I0(\lcd_data[1]_INST_0_i_5_n_0 ),
        .I1(count_mode_reg[5]),
        .I2(\lcd_data[1]_INST_0_i_6_n_0 ),
        .I3(count_mode_reg[3]),
        .I4(count_mode_reg[4]),
        .I5(Q[1]),
        .O(\lcd_data[1]_INST_0_i_2_n_0 ));
  MUXF7 \lcd_data[1]_INST_0_i_3 
       (.I0(\lcd_data[1]_INST_0_i_7_n_0 ),
        .I1(\lcd_data[1]_INST_0_i_8_n_0 ),
        .O(\lcd_data[1]_INST_0_i_3_n_0 ),
        .S(count_mode_reg[2]));
  LUT5 #(
    .INIT(32'hB8FFB800)) 
    \lcd_data[1]_INST_0_i_4 
       (.I0(\lcd_data[1]_INST_0_i_9_n_0 ),
        .I1(count_mode_reg[2]),
        .I2(\lcd_data[1]_INST_0_i_10_n_0 ),
        .I3(count_mode_reg[3]),
        .I4(\lcd_data[1]_INST_0_i_11_n_0 ),
        .O(\lcd_data[1]_INST_0_i_4_n_0 ));
  MUXF7 \lcd_data[1]_INST_0_i_5 
       (.I0(\lcd_data[1]_INST_0_i_12_n_0 ),
        .I1(\lcd_data[1]_INST_0_i_13_n_0 ),
        .O(\lcd_data[1]_INST_0_i_5_n_0 ),
        .S(count_mode_reg[2]));
  MUXF7 \lcd_data[1]_INST_0_i_6 
       (.I0(\lcd_data[1]_INST_0_i_14_n_0 ),
        .I1(\lcd_data[1]_INST_0_i_15_n_0 ),
        .O(\lcd_data[1]_INST_0_i_6_n_0 ),
        .S(count_mode_reg[2]));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[1]_INST_0_i_7 
       (.I0(\lcd_data[7]_INST_0_i_3_0 [25]),
        .I1(\lcd_data[7]_INST_0_i_4_0 [1]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_0 [9]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_0 [17]),
        .O(\lcd_data[1]_INST_0_i_7_n_0 ));
  LUT5 #(
    .INIT(32'hB8BBB888)) 
    \lcd_data[1]_INST_0_i_8 
       (.I0(\lcd_data[7]_INST_0_i_3_0 [1]),
        .I1(count_mode_reg[1]),
        .I2(\lcd_data[7]_INST_0_i_3_0 [9]),
        .I3(count_mode_reg[0]),
        .I4(\lcd_data[7]_INST_0_i_3_0 [17]),
        .O(\lcd_data[1]_INST_0_i_8_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[1]_INST_0_i_9 
       (.I0(\lcd_data[7]_INST_0_i_4_0 [25]),
        .I1(\lcd_data[7]_INST_0_i_4_1 [1]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_1 [9]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_1 [17]),
        .O(\lcd_data[1]_INST_0_i_9_n_0 ));
  LUT6 #(
    .INIT(64'h000F00C000000FA0)) 
    \lcd_data[2]_INST_0 
       (.I0(\lcd_data[2]_INST_0_i_1_n_0 ),
        .I1(\lcd_data[2]_INST_0_i_2_n_0 ),
        .I2(lcd_mode[3]),
        .I3(lcd_mode[2]),
        .I4(lcd_mode[0]),
        .I5(lcd_mode[1]),
        .O(lcd_data[2]));
  LUT6 #(
    .INIT(64'hCDC8DDDDCDC88888)) 
    \lcd_data[2]_INST_0_i_1 
       (.I0(count_mode_reg[5]),
        .I1(\lcd_data[7]_INST_0_i_3_0 [2]),
        .I2(count_mode_reg[3]),
        .I3(\lcd_data[2]_INST_0_i_3_n_0 ),
        .I4(count_mode_reg[4]),
        .I5(\lcd_data[2]_INST_0_i_4_n_0 ),
        .O(\lcd_data[2]_INST_0_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[2]_INST_0_i_10 
       (.I0(\lcd_data[7]_INST_0_i_4_1 [26]),
        .I1(\lcd_data[7]_INST_0_i_4_2 [2]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_2 [10]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_2 [18]),
        .O(\lcd_data[2]_INST_0_i_10_n_0 ));
  LUT5 #(
    .INIT(32'hBFFF8000)) 
    \lcd_data[2]_INST_0_i_11 
       (.I0(\lcd_data[7]_INST_0_i_4_2 [26]),
        .I1(count_mode_reg[0]),
        .I2(count_mode_reg[1]),
        .I3(count_mode_reg[2]),
        .I4(\lcd_data[7]_INST_0_i_3_0 [2]),
        .O(\lcd_data[2]_INST_0_i_11_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[2]_INST_0_i_12 
       (.I0(\lcd_data[7]_INST_0_i_5_0 [2]),
        .I1(\lcd_data[7]_INST_0_i_5_0 [10]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_5_0 [18]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_5_0 [26]),
        .O(\lcd_data[2]_INST_0_i_12_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[2]_INST_0_i_13 
       (.I0(Q[2]),
        .I1(Q[10]),
        .I2(count_mode_reg[1]),
        .I3(Q[18]),
        .I4(count_mode_reg[0]),
        .I5(Q[26]),
        .O(\lcd_data[2]_INST_0_i_13_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[2]_INST_0_i_14 
       (.I0(\lcd_data[7]_INST_0_i_6_1 [2]),
        .I1(\lcd_data[7]_INST_0_i_6_1 [10]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_6_1 [18]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_6_1 [26]),
        .O(\lcd_data[2]_INST_0_i_14_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[2]_INST_0_i_15 
       (.I0(\lcd_data[7]_INST_0_i_6_0 [2]),
        .I1(\lcd_data[7]_INST_0_i_6_0 [10]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_6_0 [18]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_6_0 [26]),
        .O(\lcd_data[2]_INST_0_i_15_n_0 ));
  LUT6 #(
    .INIT(64'hFCFFFFBB30000088)) 
    \lcd_data[2]_INST_0_i_2 
       (.I0(\lcd_data[2]_INST_0_i_5_n_0 ),
        .I1(count_mode_reg[5]),
        .I2(\lcd_data[2]_INST_0_i_6_n_0 ),
        .I3(count_mode_reg[3]),
        .I4(count_mode_reg[4]),
        .I5(Q[2]),
        .O(\lcd_data[2]_INST_0_i_2_n_0 ));
  MUXF7 \lcd_data[2]_INST_0_i_3 
       (.I0(\lcd_data[2]_INST_0_i_7_n_0 ),
        .I1(\lcd_data[2]_INST_0_i_8_n_0 ),
        .O(\lcd_data[2]_INST_0_i_3_n_0 ),
        .S(count_mode_reg[2]));
  LUT5 #(
    .INIT(32'hB8FFB800)) 
    \lcd_data[2]_INST_0_i_4 
       (.I0(\lcd_data[2]_INST_0_i_9_n_0 ),
        .I1(count_mode_reg[2]),
        .I2(\lcd_data[2]_INST_0_i_10_n_0 ),
        .I3(count_mode_reg[3]),
        .I4(\lcd_data[2]_INST_0_i_11_n_0 ),
        .O(\lcd_data[2]_INST_0_i_4_n_0 ));
  MUXF7 \lcd_data[2]_INST_0_i_5 
       (.I0(\lcd_data[2]_INST_0_i_12_n_0 ),
        .I1(\lcd_data[2]_INST_0_i_13_n_0 ),
        .O(\lcd_data[2]_INST_0_i_5_n_0 ),
        .S(count_mode_reg[2]));
  MUXF7 \lcd_data[2]_INST_0_i_6 
       (.I0(\lcd_data[2]_INST_0_i_14_n_0 ),
        .I1(\lcd_data[2]_INST_0_i_15_n_0 ),
        .O(\lcd_data[2]_INST_0_i_6_n_0 ),
        .S(count_mode_reg[2]));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[2]_INST_0_i_7 
       (.I0(\lcd_data[7]_INST_0_i_3_0 [26]),
        .I1(\lcd_data[7]_INST_0_i_4_0 [2]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_0 [10]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_0 [18]),
        .O(\lcd_data[2]_INST_0_i_7_n_0 ));
  LUT5 #(
    .INIT(32'hB8BBB888)) 
    \lcd_data[2]_INST_0_i_8 
       (.I0(\lcd_data[7]_INST_0_i_3_0 [2]),
        .I1(count_mode_reg[1]),
        .I2(\lcd_data[7]_INST_0_i_3_0 [10]),
        .I3(count_mode_reg[0]),
        .I4(\lcd_data[7]_INST_0_i_3_0 [18]),
        .O(\lcd_data[2]_INST_0_i_8_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[2]_INST_0_i_9 
       (.I0(\lcd_data[7]_INST_0_i_4_0 [26]),
        .I1(\lcd_data[7]_INST_0_i_4_1 [2]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_1 [10]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_1 [18]),
        .O(\lcd_data[2]_INST_0_i_9_n_0 ));
  LUT6 #(
    .INIT(64'h000000000FFFCFA0)) 
    \lcd_data[3]_INST_0 
       (.I0(\lcd_data[3]_INST_0_i_1_n_0 ),
        .I1(\lcd_data[3]_INST_0_i_2_n_0 ),
        .I2(lcd_mode[3]),
        .I3(lcd_mode[1]),
        .I4(lcd_mode[0]),
        .I5(lcd_mode[2]),
        .O(lcd_data[3]));
  LUT6 #(
    .INIT(64'hCDC8DDDDCDC88888)) 
    \lcd_data[3]_INST_0_i_1 
       (.I0(count_mode_reg[5]),
        .I1(\lcd_data[7]_INST_0_i_3_0 [3]),
        .I2(count_mode_reg[3]),
        .I3(\lcd_data[3]_INST_0_i_3_n_0 ),
        .I4(count_mode_reg[4]),
        .I5(\lcd_data[3]_INST_0_i_4_n_0 ),
        .O(\lcd_data[3]_INST_0_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[3]_INST_0_i_10 
       (.I0(\lcd_data[7]_INST_0_i_4_1 [27]),
        .I1(\lcd_data[7]_INST_0_i_4_2 [3]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_2 [11]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_2 [19]),
        .O(\lcd_data[3]_INST_0_i_10_n_0 ));
  LUT5 #(
    .INIT(32'hBFFF8000)) 
    \lcd_data[3]_INST_0_i_11 
       (.I0(\lcd_data[7]_INST_0_i_4_2 [27]),
        .I1(count_mode_reg[0]),
        .I2(count_mode_reg[1]),
        .I3(count_mode_reg[2]),
        .I4(\lcd_data[7]_INST_0_i_3_0 [3]),
        .O(\lcd_data[3]_INST_0_i_11_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[3]_INST_0_i_12 
       (.I0(\lcd_data[7]_INST_0_i_5_0 [3]),
        .I1(\lcd_data[7]_INST_0_i_5_0 [11]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_5_0 [19]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_5_0 [27]),
        .O(\lcd_data[3]_INST_0_i_12_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[3]_INST_0_i_13 
       (.I0(Q[3]),
        .I1(Q[11]),
        .I2(count_mode_reg[1]),
        .I3(Q[19]),
        .I4(count_mode_reg[0]),
        .I5(Q[27]),
        .O(\lcd_data[3]_INST_0_i_13_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[3]_INST_0_i_14 
       (.I0(\lcd_data[7]_INST_0_i_6_1 [3]),
        .I1(\lcd_data[7]_INST_0_i_6_1 [11]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_6_1 [19]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_6_1 [27]),
        .O(\lcd_data[3]_INST_0_i_14_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[3]_INST_0_i_15 
       (.I0(\lcd_data[7]_INST_0_i_6_0 [3]),
        .I1(\lcd_data[7]_INST_0_i_6_0 [11]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_6_0 [19]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_6_0 [27]),
        .O(\lcd_data[3]_INST_0_i_15_n_0 ));
  LUT6 #(
    .INIT(64'hFCFFFFBB30000088)) 
    \lcd_data[3]_INST_0_i_2 
       (.I0(\lcd_data[3]_INST_0_i_5_n_0 ),
        .I1(count_mode_reg[5]),
        .I2(\lcd_data[3]_INST_0_i_6_n_0 ),
        .I3(count_mode_reg[3]),
        .I4(count_mode_reg[4]),
        .I5(Q[3]),
        .O(\lcd_data[3]_INST_0_i_2_n_0 ));
  MUXF7 \lcd_data[3]_INST_0_i_3 
       (.I0(\lcd_data[3]_INST_0_i_7_n_0 ),
        .I1(\lcd_data[3]_INST_0_i_8_n_0 ),
        .O(\lcd_data[3]_INST_0_i_3_n_0 ),
        .S(count_mode_reg[2]));
  LUT5 #(
    .INIT(32'hB8FFB800)) 
    \lcd_data[3]_INST_0_i_4 
       (.I0(\lcd_data[3]_INST_0_i_9_n_0 ),
        .I1(count_mode_reg[2]),
        .I2(\lcd_data[3]_INST_0_i_10_n_0 ),
        .I3(count_mode_reg[3]),
        .I4(\lcd_data[3]_INST_0_i_11_n_0 ),
        .O(\lcd_data[3]_INST_0_i_4_n_0 ));
  MUXF7 \lcd_data[3]_INST_0_i_5 
       (.I0(\lcd_data[3]_INST_0_i_12_n_0 ),
        .I1(\lcd_data[3]_INST_0_i_13_n_0 ),
        .O(\lcd_data[3]_INST_0_i_5_n_0 ),
        .S(count_mode_reg[2]));
  MUXF7 \lcd_data[3]_INST_0_i_6 
       (.I0(\lcd_data[3]_INST_0_i_14_n_0 ),
        .I1(\lcd_data[3]_INST_0_i_15_n_0 ),
        .O(\lcd_data[3]_INST_0_i_6_n_0 ),
        .S(count_mode_reg[2]));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[3]_INST_0_i_7 
       (.I0(\lcd_data[7]_INST_0_i_3_0 [27]),
        .I1(\lcd_data[7]_INST_0_i_4_0 [3]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_0 [11]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_0 [19]),
        .O(\lcd_data[3]_INST_0_i_7_n_0 ));
  LUT5 #(
    .INIT(32'hB8BBB888)) 
    \lcd_data[3]_INST_0_i_8 
       (.I0(\lcd_data[7]_INST_0_i_3_0 [3]),
        .I1(count_mode_reg[1]),
        .I2(\lcd_data[7]_INST_0_i_3_0 [11]),
        .I3(count_mode_reg[0]),
        .I4(\lcd_data[7]_INST_0_i_3_0 [19]),
        .O(\lcd_data[3]_INST_0_i_8_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[3]_INST_0_i_9 
       (.I0(\lcd_data[7]_INST_0_i_4_0 [27]),
        .I1(\lcd_data[7]_INST_0_i_4_1 [3]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_1 [11]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_1 [19]),
        .O(\lcd_data[3]_INST_0_i_9_n_0 ));
  LUT6 #(
    .INIT(64'h0000000000CF0FA0)) 
    \lcd_data[4]_INST_0 
       (.I0(\lcd_data[4]_INST_0_i_1_n_0 ),
        .I1(\lcd_data[4]_INST_0_i_2_n_0 ),
        .I2(lcd_mode[3]),
        .I3(lcd_mode[0]),
        .I4(lcd_mode[1]),
        .I5(lcd_mode[2]),
        .O(lcd_data[4]));
  LUT6 #(
    .INIT(64'hCDC8DDDDCDC88888)) 
    \lcd_data[4]_INST_0_i_1 
       (.I0(count_mode_reg[5]),
        .I1(\lcd_data[7]_INST_0_i_3_0 [4]),
        .I2(count_mode_reg[3]),
        .I3(\lcd_data[4]_INST_0_i_3_n_0 ),
        .I4(count_mode_reg[4]),
        .I5(\lcd_data[4]_INST_0_i_4_n_0 ),
        .O(\lcd_data[4]_INST_0_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[4]_INST_0_i_10 
       (.I0(\lcd_data[7]_INST_0_i_4_1 [28]),
        .I1(\lcd_data[7]_INST_0_i_4_2 [4]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_2 [12]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_2 [20]),
        .O(\lcd_data[4]_INST_0_i_10_n_0 ));
  LUT5 #(
    .INIT(32'hBFFF8000)) 
    \lcd_data[4]_INST_0_i_11 
       (.I0(\lcd_data[7]_INST_0_i_4_2 [28]),
        .I1(count_mode_reg[0]),
        .I2(count_mode_reg[1]),
        .I3(count_mode_reg[2]),
        .I4(\lcd_data[7]_INST_0_i_3_0 [4]),
        .O(\lcd_data[4]_INST_0_i_11_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[4]_INST_0_i_12 
       (.I0(\lcd_data[7]_INST_0_i_5_0 [4]),
        .I1(\lcd_data[7]_INST_0_i_5_0 [12]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_5_0 [20]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_5_0 [28]),
        .O(\lcd_data[4]_INST_0_i_12_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[4]_INST_0_i_13 
       (.I0(Q[4]),
        .I1(Q[12]),
        .I2(count_mode_reg[1]),
        .I3(Q[20]),
        .I4(count_mode_reg[0]),
        .I5(Q[28]),
        .O(\lcd_data[4]_INST_0_i_13_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[4]_INST_0_i_14 
       (.I0(\lcd_data[7]_INST_0_i_6_1 [4]),
        .I1(\lcd_data[7]_INST_0_i_6_1 [12]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_6_1 [20]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_6_1 [28]),
        .O(\lcd_data[4]_INST_0_i_14_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[4]_INST_0_i_15 
       (.I0(\lcd_data[7]_INST_0_i_6_0 [4]),
        .I1(\lcd_data[7]_INST_0_i_6_0 [12]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_6_0 [20]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_6_0 [28]),
        .O(\lcd_data[4]_INST_0_i_15_n_0 ));
  LUT6 #(
    .INIT(64'hFCFFFFBB30000088)) 
    \lcd_data[4]_INST_0_i_2 
       (.I0(\lcd_data[4]_INST_0_i_5_n_0 ),
        .I1(count_mode_reg[5]),
        .I2(\lcd_data[4]_INST_0_i_6_n_0 ),
        .I3(count_mode_reg[3]),
        .I4(count_mode_reg[4]),
        .I5(Q[4]),
        .O(\lcd_data[4]_INST_0_i_2_n_0 ));
  MUXF7 \lcd_data[4]_INST_0_i_3 
       (.I0(\lcd_data[4]_INST_0_i_7_n_0 ),
        .I1(\lcd_data[4]_INST_0_i_8_n_0 ),
        .O(\lcd_data[4]_INST_0_i_3_n_0 ),
        .S(count_mode_reg[2]));
  LUT5 #(
    .INIT(32'hB8FFB800)) 
    \lcd_data[4]_INST_0_i_4 
       (.I0(\lcd_data[4]_INST_0_i_9_n_0 ),
        .I1(count_mode_reg[2]),
        .I2(\lcd_data[4]_INST_0_i_10_n_0 ),
        .I3(count_mode_reg[3]),
        .I4(\lcd_data[4]_INST_0_i_11_n_0 ),
        .O(\lcd_data[4]_INST_0_i_4_n_0 ));
  MUXF7 \lcd_data[4]_INST_0_i_5 
       (.I0(\lcd_data[4]_INST_0_i_12_n_0 ),
        .I1(\lcd_data[4]_INST_0_i_13_n_0 ),
        .O(\lcd_data[4]_INST_0_i_5_n_0 ),
        .S(count_mode_reg[2]));
  MUXF7 \lcd_data[4]_INST_0_i_6 
       (.I0(\lcd_data[4]_INST_0_i_14_n_0 ),
        .I1(\lcd_data[4]_INST_0_i_15_n_0 ),
        .O(\lcd_data[4]_INST_0_i_6_n_0 ),
        .S(count_mode_reg[2]));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[4]_INST_0_i_7 
       (.I0(\lcd_data[7]_INST_0_i_3_0 [28]),
        .I1(\lcd_data[7]_INST_0_i_4_0 [4]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_0 [12]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_0 [20]),
        .O(\lcd_data[4]_INST_0_i_7_n_0 ));
  LUT5 #(
    .INIT(32'hB8BBB888)) 
    \lcd_data[4]_INST_0_i_8 
       (.I0(\lcd_data[7]_INST_0_i_3_0 [4]),
        .I1(count_mode_reg[1]),
        .I2(\lcd_data[7]_INST_0_i_3_0 [12]),
        .I3(count_mode_reg[0]),
        .I4(\lcd_data[7]_INST_0_i_3_0 [20]),
        .O(\lcd_data[4]_INST_0_i_8_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[4]_INST_0_i_9 
       (.I0(\lcd_data[7]_INST_0_i_4_0 [28]),
        .I1(\lcd_data[7]_INST_0_i_4_1 [4]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_1 [12]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_1 [20]),
        .O(\lcd_data[4]_INST_0_i_9_n_0 ));
  LUT6 #(
    .INIT(64'h0000000000CFFFA0)) 
    \lcd_data[5]_INST_0 
       (.I0(\lcd_data[5]_INST_0_i_1_n_0 ),
        .I1(\lcd_data[5]_INST_0_i_2_n_0 ),
        .I2(lcd_mode[3]),
        .I3(lcd_mode[0]),
        .I4(lcd_mode[1]),
        .I5(lcd_mode[2]),
        .O(lcd_data[5]));
  LUT6 #(
    .INIT(64'hCDC8DDDDCDC88888)) 
    \lcd_data[5]_INST_0_i_1 
       (.I0(count_mode_reg[5]),
        .I1(\lcd_data[7]_INST_0_i_3_0 [5]),
        .I2(count_mode_reg[3]),
        .I3(\lcd_data[5]_INST_0_i_3_n_0 ),
        .I4(count_mode_reg[4]),
        .I5(\lcd_data[5]_INST_0_i_4_n_0 ),
        .O(\lcd_data[5]_INST_0_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[5]_INST_0_i_10 
       (.I0(\lcd_data[7]_INST_0_i_4_1 [29]),
        .I1(\lcd_data[7]_INST_0_i_4_2 [5]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_2 [13]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_2 [21]),
        .O(\lcd_data[5]_INST_0_i_10_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair1" *) 
  LUT5 #(
    .INIT(32'hBFFF8000)) 
    \lcd_data[5]_INST_0_i_11 
       (.I0(\lcd_data[7]_INST_0_i_4_2 [29]),
        .I1(count_mode_reg[0]),
        .I2(count_mode_reg[1]),
        .I3(count_mode_reg[2]),
        .I4(\lcd_data[7]_INST_0_i_3_0 [5]),
        .O(\lcd_data[5]_INST_0_i_11_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[5]_INST_0_i_12 
       (.I0(\lcd_data[7]_INST_0_i_5_0 [5]),
        .I1(\lcd_data[7]_INST_0_i_5_0 [13]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_5_0 [21]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_5_0 [29]),
        .O(\lcd_data[5]_INST_0_i_12_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[5]_INST_0_i_13 
       (.I0(Q[5]),
        .I1(Q[13]),
        .I2(count_mode_reg[1]),
        .I3(Q[21]),
        .I4(count_mode_reg[0]),
        .I5(Q[29]),
        .O(\lcd_data[5]_INST_0_i_13_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[5]_INST_0_i_14 
       (.I0(\lcd_data[7]_INST_0_i_6_1 [5]),
        .I1(\lcd_data[7]_INST_0_i_6_1 [13]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_6_1 [21]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_6_1 [29]),
        .O(\lcd_data[5]_INST_0_i_14_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[5]_INST_0_i_15 
       (.I0(\lcd_data[7]_INST_0_i_6_0 [5]),
        .I1(\lcd_data[7]_INST_0_i_6_0 [13]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_6_0 [21]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_6_0 [29]),
        .O(\lcd_data[5]_INST_0_i_15_n_0 ));
  LUT6 #(
    .INIT(64'hFCFFFFBB30000088)) 
    \lcd_data[5]_INST_0_i_2 
       (.I0(\lcd_data[5]_INST_0_i_5_n_0 ),
        .I1(count_mode_reg[5]),
        .I2(\lcd_data[5]_INST_0_i_6_n_0 ),
        .I3(count_mode_reg[3]),
        .I4(count_mode_reg[4]),
        .I5(Q[5]),
        .O(\lcd_data[5]_INST_0_i_2_n_0 ));
  MUXF7 \lcd_data[5]_INST_0_i_3 
       (.I0(\lcd_data[5]_INST_0_i_7_n_0 ),
        .I1(\lcd_data[5]_INST_0_i_8_n_0 ),
        .O(\lcd_data[5]_INST_0_i_3_n_0 ),
        .S(count_mode_reg[2]));
  LUT5 #(
    .INIT(32'hB8FFB800)) 
    \lcd_data[5]_INST_0_i_4 
       (.I0(\lcd_data[5]_INST_0_i_9_n_0 ),
        .I1(count_mode_reg[2]),
        .I2(\lcd_data[5]_INST_0_i_10_n_0 ),
        .I3(count_mode_reg[3]),
        .I4(\lcd_data[5]_INST_0_i_11_n_0 ),
        .O(\lcd_data[5]_INST_0_i_4_n_0 ));
  MUXF7 \lcd_data[5]_INST_0_i_5 
       (.I0(\lcd_data[5]_INST_0_i_12_n_0 ),
        .I1(\lcd_data[5]_INST_0_i_13_n_0 ),
        .O(\lcd_data[5]_INST_0_i_5_n_0 ),
        .S(count_mode_reg[2]));
  MUXF7 \lcd_data[5]_INST_0_i_6 
       (.I0(\lcd_data[5]_INST_0_i_14_n_0 ),
        .I1(\lcd_data[5]_INST_0_i_15_n_0 ),
        .O(\lcd_data[5]_INST_0_i_6_n_0 ),
        .S(count_mode_reg[2]));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[5]_INST_0_i_7 
       (.I0(\lcd_data[7]_INST_0_i_3_0 [29]),
        .I1(\lcd_data[7]_INST_0_i_4_0 [5]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_0 [13]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_0 [21]),
        .O(\lcd_data[5]_INST_0_i_7_n_0 ));
  LUT5 #(
    .INIT(32'hB8BBB888)) 
    \lcd_data[5]_INST_0_i_8 
       (.I0(\lcd_data[7]_INST_0_i_3_0 [5]),
        .I1(count_mode_reg[1]),
        .I2(\lcd_data[7]_INST_0_i_3_0 [13]),
        .I3(count_mode_reg[0]),
        .I4(\lcd_data[7]_INST_0_i_3_0 [21]),
        .O(\lcd_data[5]_INST_0_i_8_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[5]_INST_0_i_9 
       (.I0(\lcd_data[7]_INST_0_i_4_0 [29]),
        .I1(\lcd_data[7]_INST_0_i_4_1 [5]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_1 [13]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_1 [21]),
        .O(\lcd_data[5]_INST_0_i_9_n_0 ));
  LUT6 #(
    .INIT(64'h0000454000000000)) 
    \lcd_data[6]_INST_0 
       (.I0(lcd_mode[2]),
        .I1(\lcd_data[6]_INST_0_i_1_n_0 ),
        .I2(lcd_mode[1]),
        .I3(\lcd_data[6]_INST_0_i_2_n_0 ),
        .I4(lcd_mode[0]),
        .I5(lcd_mode[3]),
        .O(lcd_data[6]));
  LUT6 #(
    .INIT(64'hFCFFFFBB30000088)) 
    \lcd_data[6]_INST_0_i_1 
       (.I0(\lcd_data[6]_INST_0_i_3_n_0 ),
        .I1(count_mode_reg[5]),
        .I2(\lcd_data[6]_INST_0_i_4_n_0 ),
        .I3(count_mode_reg[3]),
        .I4(count_mode_reg[4]),
        .I5(Q[6]),
        .O(\lcd_data[6]_INST_0_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[6]_INST_0_i_10 
       (.I0(\lcd_data[7]_INST_0_i_6_0 [6]),
        .I1(\lcd_data[7]_INST_0_i_6_0 [14]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_6_0 [22]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_6_0 [30]),
        .O(\lcd_data[6]_INST_0_i_10_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[6]_INST_0_i_11 
       (.I0(\lcd_data[7]_INST_0_i_3_0 [30]),
        .I1(\lcd_data[7]_INST_0_i_4_0 [6]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_0 [14]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_0 [22]),
        .O(\lcd_data[6]_INST_0_i_11_n_0 ));
  LUT5 #(
    .INIT(32'hB8BBB888)) 
    \lcd_data[6]_INST_0_i_12 
       (.I0(\lcd_data[7]_INST_0_i_3_0 [6]),
        .I1(count_mode_reg[1]),
        .I2(\lcd_data[7]_INST_0_i_3_0 [14]),
        .I3(count_mode_reg[0]),
        .I4(\lcd_data[7]_INST_0_i_3_0 [22]),
        .O(\lcd_data[6]_INST_0_i_12_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[6]_INST_0_i_13 
       (.I0(\lcd_data[7]_INST_0_i_4_0 [30]),
        .I1(\lcd_data[7]_INST_0_i_4_1 [6]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_1 [14]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_1 [22]),
        .O(\lcd_data[6]_INST_0_i_13_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[6]_INST_0_i_14 
       (.I0(\lcd_data[7]_INST_0_i_4_1 [30]),
        .I1(\lcd_data[7]_INST_0_i_4_2 [6]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_2 [14]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_2 [22]),
        .O(\lcd_data[6]_INST_0_i_14_n_0 ));
  LUT5 #(
    .INIT(32'hBFFF8000)) 
    \lcd_data[6]_INST_0_i_15 
       (.I0(\lcd_data[7]_INST_0_i_4_2 [30]),
        .I1(count_mode_reg[0]),
        .I2(count_mode_reg[1]),
        .I3(count_mode_reg[2]),
        .I4(\lcd_data[7]_INST_0_i_3_0 [6]),
        .O(\lcd_data[6]_INST_0_i_15_n_0 ));
  LUT6 #(
    .INIT(64'hCDC8DDDDCDC88888)) 
    \lcd_data[6]_INST_0_i_2 
       (.I0(count_mode_reg[5]),
        .I1(\lcd_data[7]_INST_0_i_3_0 [6]),
        .I2(count_mode_reg[3]),
        .I3(\lcd_data[6]_INST_0_i_5_n_0 ),
        .I4(count_mode_reg[4]),
        .I5(\lcd_data[6]_INST_0_i_6_n_0 ),
        .O(\lcd_data[6]_INST_0_i_2_n_0 ));
  MUXF7 \lcd_data[6]_INST_0_i_3 
       (.I0(\lcd_data[6]_INST_0_i_7_n_0 ),
        .I1(\lcd_data[6]_INST_0_i_8_n_0 ),
        .O(\lcd_data[6]_INST_0_i_3_n_0 ),
        .S(count_mode_reg[2]));
  MUXF7 \lcd_data[6]_INST_0_i_4 
       (.I0(\lcd_data[6]_INST_0_i_9_n_0 ),
        .I1(\lcd_data[6]_INST_0_i_10_n_0 ),
        .O(\lcd_data[6]_INST_0_i_4_n_0 ),
        .S(count_mode_reg[2]));
  MUXF7 \lcd_data[6]_INST_0_i_5 
       (.I0(\lcd_data[6]_INST_0_i_11_n_0 ),
        .I1(\lcd_data[6]_INST_0_i_12_n_0 ),
        .O(\lcd_data[6]_INST_0_i_5_n_0 ),
        .S(count_mode_reg[2]));
  LUT5 #(
    .INIT(32'hB8FFB800)) 
    \lcd_data[6]_INST_0_i_6 
       (.I0(\lcd_data[6]_INST_0_i_13_n_0 ),
        .I1(count_mode_reg[2]),
        .I2(\lcd_data[6]_INST_0_i_14_n_0 ),
        .I3(count_mode_reg[3]),
        .I4(\lcd_data[6]_INST_0_i_15_n_0 ),
        .O(\lcd_data[6]_INST_0_i_6_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[6]_INST_0_i_7 
       (.I0(\lcd_data[7]_INST_0_i_5_0 [6]),
        .I1(\lcd_data[7]_INST_0_i_5_0 [14]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_5_0 [22]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_5_0 [30]),
        .O(\lcd_data[6]_INST_0_i_7_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[6]_INST_0_i_8 
       (.I0(Q[6]),
        .I1(Q[14]),
        .I2(count_mode_reg[1]),
        .I3(Q[22]),
        .I4(count_mode_reg[0]),
        .I5(Q[30]),
        .O(\lcd_data[6]_INST_0_i_8_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[6]_INST_0_i_9 
       (.I0(\lcd_data[7]_INST_0_i_6_1 [6]),
        .I1(\lcd_data[7]_INST_0_i_6_1 [14]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_6_1 [22]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_6_1 [30]),
        .O(\lcd_data[6]_INST_0_i_9_n_0 ));
  LUT6 #(
    .INIT(64'h0F00000000F0C0A0)) 
    \lcd_data[7]_INST_0 
       (.I0(\lcd_data[7]_INST_0_i_1_n_0 ),
        .I1(\lcd_data[7]_INST_0_i_2_n_0 ),
        .I2(lcd_mode[3]),
        .I3(lcd_mode[1]),
        .I4(lcd_mode[0]),
        .I5(lcd_mode[2]),
        .O(lcd_data[7]));
  LUT6 #(
    .INIT(64'hCDC8DDDDCDC88888)) 
    \lcd_data[7]_INST_0_i_1 
       (.I0(count_mode_reg[5]),
        .I1(\lcd_data[7]_INST_0_i_3_0 [7]),
        .I2(count_mode_reg[3]),
        .I3(\lcd_data[7]_INST_0_i_3_n_0 ),
        .I4(count_mode_reg[4]),
        .I5(\lcd_data[7]_INST_0_i_4_n_0 ),
        .O(\lcd_data[7]_INST_0_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[7]_INST_0_i_10 
       (.I0(\lcd_data[7]_INST_0_i_4_1 [31]),
        .I1(\lcd_data[7]_INST_0_i_4_2 [7]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_2 [15]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_2 [23]),
        .O(\lcd_data[7]_INST_0_i_10_n_0 ));
  LUT5 #(
    .INIT(32'hBFFF8000)) 
    \lcd_data[7]_INST_0_i_11 
       (.I0(\lcd_data[7]_INST_0_i_4_2 [31]),
        .I1(count_mode_reg[0]),
        .I2(count_mode_reg[1]),
        .I3(count_mode_reg[2]),
        .I4(\lcd_data[7]_INST_0_i_3_0 [7]),
        .O(\lcd_data[7]_INST_0_i_11_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[7]_INST_0_i_12 
       (.I0(\lcd_data[7]_INST_0_i_5_0 [7]),
        .I1(\lcd_data[7]_INST_0_i_5_0 [15]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_5_0 [23]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_5_0 [31]),
        .O(\lcd_data[7]_INST_0_i_12_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[7]_INST_0_i_13 
       (.I0(Q[7]),
        .I1(Q[15]),
        .I2(count_mode_reg[1]),
        .I3(Q[23]),
        .I4(count_mode_reg[0]),
        .I5(Q[31]),
        .O(\lcd_data[7]_INST_0_i_13_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[7]_INST_0_i_14 
       (.I0(\lcd_data[7]_INST_0_i_6_1 [7]),
        .I1(\lcd_data[7]_INST_0_i_6_1 [15]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_6_1 [23]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_6_1 [31]),
        .O(\lcd_data[7]_INST_0_i_14_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[7]_INST_0_i_15 
       (.I0(\lcd_data[7]_INST_0_i_6_0 [7]),
        .I1(\lcd_data[7]_INST_0_i_6_0 [15]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_6_0 [23]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_6_0 [31]),
        .O(\lcd_data[7]_INST_0_i_15_n_0 ));
  LUT6 #(
    .INIT(64'hFCFFFFBB30000088)) 
    \lcd_data[7]_INST_0_i_2 
       (.I0(\lcd_data[7]_INST_0_i_5_n_0 ),
        .I1(count_mode_reg[5]),
        .I2(\lcd_data[7]_INST_0_i_6_n_0 ),
        .I3(count_mode_reg[3]),
        .I4(count_mode_reg[4]),
        .I5(Q[7]),
        .O(\lcd_data[7]_INST_0_i_2_n_0 ));
  MUXF7 \lcd_data[7]_INST_0_i_3 
       (.I0(\lcd_data[7]_INST_0_i_7_n_0 ),
        .I1(\lcd_data[7]_INST_0_i_8_n_0 ),
        .O(\lcd_data[7]_INST_0_i_3_n_0 ),
        .S(count_mode_reg[2]));
  LUT5 #(
    .INIT(32'hB8FFB800)) 
    \lcd_data[7]_INST_0_i_4 
       (.I0(\lcd_data[7]_INST_0_i_9_n_0 ),
        .I1(count_mode_reg[2]),
        .I2(\lcd_data[7]_INST_0_i_10_n_0 ),
        .I3(count_mode_reg[3]),
        .I4(\lcd_data[7]_INST_0_i_11_n_0 ),
        .O(\lcd_data[7]_INST_0_i_4_n_0 ));
  MUXF7 \lcd_data[7]_INST_0_i_5 
       (.I0(\lcd_data[7]_INST_0_i_12_n_0 ),
        .I1(\lcd_data[7]_INST_0_i_13_n_0 ),
        .O(\lcd_data[7]_INST_0_i_5_n_0 ),
        .S(count_mode_reg[2]));
  MUXF7 \lcd_data[7]_INST_0_i_6 
       (.I0(\lcd_data[7]_INST_0_i_14_n_0 ),
        .I1(\lcd_data[7]_INST_0_i_15_n_0 ),
        .O(\lcd_data[7]_INST_0_i_6_n_0 ),
        .S(count_mode_reg[2]));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[7]_INST_0_i_7 
       (.I0(\lcd_data[7]_INST_0_i_3_0 [31]),
        .I1(\lcd_data[7]_INST_0_i_4_0 [7]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_0 [15]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_0 [23]),
        .O(\lcd_data[7]_INST_0_i_7_n_0 ));
  LUT5 #(
    .INIT(32'hB8BBB888)) 
    \lcd_data[7]_INST_0_i_8 
       (.I0(\lcd_data[7]_INST_0_i_3_0 [7]),
        .I1(count_mode_reg[1]),
        .I2(\lcd_data[7]_INST_0_i_3_0 [15]),
        .I3(count_mode_reg[0]),
        .I4(\lcd_data[7]_INST_0_i_3_0 [23]),
        .O(\lcd_data[7]_INST_0_i_8_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \lcd_data[7]_INST_0_i_9 
       (.I0(\lcd_data[7]_INST_0_i_4_0 [31]),
        .I1(\lcd_data[7]_INST_0_i_4_1 [7]),
        .I2(count_mode_reg[1]),
        .I3(\lcd_data[7]_INST_0_i_4_1 [15]),
        .I4(count_mode_reg[0]),
        .I5(\lcd_data[7]_INST_0_i_4_1 [23]),
        .O(\lcd_data[7]_INST_0_i_9_n_0 ));
  LUT4 #(
    .INIT(16'h2F20)) 
    lcd_en_i_1
       (.I0(lcd_en_i_3_n_0),
        .I1(count_lcdclk_reg[10]),
        .I2(lcd_en0),
        .I3(lcd_en),
        .O(lcd_en_i_1_n_0));
  LUT1 #(
    .INIT(2'h1)) 
    lcd_en_i_2
       (.I0(resetn),
        .O(lcd_en_i_2_n_0));
  LUT5 #(
    .INIT(32'h00004000)) 
    lcd_en_i_3
       (.I0(count_lcdclk_reg[8]),
        .I1(count_lcdclk_reg[6]),
        .I2(lcd_en_i_5_n_0),
        .I3(count_lcdclk_reg[7]),
        .I4(count_lcdclk_reg[9]),
        .O(lcd_en_i_3_n_0));
  LUT6 #(
    .INIT(64'h0000080010000000)) 
    lcd_en_i_4
       (.I0(count_lcdclk_reg[10]),
        .I1(count_lcdclk_reg[8]),
        .I2(count_lcdclk_reg[6]),
        .I3(lcd_en_i_5_n_0),
        .I4(count_lcdclk_reg[7]),
        .I5(count_lcdclk_reg[9]),
        .O(lcd_en0));
  LUT6 #(
    .INIT(64'h0000000000010000)) 
    lcd_en_i_5
       (.I0(count_lcdclk_reg[4]),
        .I1(count_lcdclk_reg[2]),
        .I2(count_lcdclk_reg[0]),
        .I3(count_lcdclk_reg[1]),
        .I4(count_lcdclk_reg[3]),
        .I5(count_lcdclk_reg[5]),
        .O(lcd_en_i_5_n_0));
  FDCE lcd_en_reg
       (.C(lcdclk),
        .CE(1'b1),
        .CLR(lcd_en_i_2_n_0),
        .D(lcd_en_i_1_n_0),
        .Q(lcd_en));
  LUT4 #(
    .INIT(16'hAACF)) 
    \lcd_mode[0]_i_1 
       (.I0(count_mode_reg[5]),
        .I1(count_mode_reg[4]),
        .I2(count_mode_reg[0]),
        .I3(count_mode_reg[3]),
        .O(lcd_mode_0[0]));
  (* SOFT_HLUTNM = "soft_lutpair2" *) 
  LUT4 #(
    .INIT(16'h01FE)) 
    \lcd_mode[1]_i_1 
       (.I0(count_mode_reg[5]),
        .I1(count_mode_reg[4]),
        .I2(count_mode_reg[1]),
        .I3(count_mode_reg[0]),
        .O(lcd_mode_0[1]));
  (* SOFT_HLUTNM = "soft_lutpair1" *) 
  LUT3 #(
    .INIT(8'h6A)) 
    \lcd_mode[2]_i_1 
       (.I0(count_mode_reg[2]),
        .I1(count_mode_reg[1]),
        .I2(count_mode_reg[0]),
        .O(lcd_mode_0[2]));
  LUT6 #(
    .INIT(64'h0001000240005555)) 
    \lcd_mode[3]_i_1 
       (.I0(count_mode_reg[5]),
        .I1(count_mode_reg[1]),
        .I2(count_mode_reg[0]),
        .I3(count_mode_reg[2]),
        .I4(count_mode_reg[4]),
        .I5(count_mode_reg[3]),
        .O(\lcd_mode[3]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair2" *) 
  LUT5 #(
    .INIT(32'hF0EE00EE)) 
    \lcd_mode[3]_i_2 
       (.I0(count_mode_reg[5]),
        .I1(count_mode_reg[4]),
        .I2(count_mode_reg[1]),
        .I3(count_mode_reg[0]),
        .I4(count_mode_reg[2]),
        .O(lcd_mode_0[3]));
  FDPE \lcd_mode_reg[0] 
       (.C(lcdclk),
        .CE(\lcd_mode[3]_i_1_n_0 ),
        .D(lcd_mode_0[0]),
        .PRE(lcd_en_i_2_n_0),
        .Q(lcd_mode[0]));
  FDCE \lcd_mode_reg[1] 
       (.C(lcdclk),
        .CE(\lcd_mode[3]_i_1_n_0 ),
        .CLR(lcd_en_i_2_n_0),
        .D(lcd_mode_0[1]),
        .Q(lcd_mode[1]));
  FDCE \lcd_mode_reg[2] 
       (.C(lcdclk),
        .CE(\lcd_mode[3]_i_1_n_0 ),
        .CLR(lcd_en_i_2_n_0),
        .D(lcd_mode_0[2]),
        .Q(lcd_mode[2]));
  FDCE \lcd_mode_reg[3] 
       (.C(lcdclk),
        .CE(\lcd_mode[3]_i_1_n_0 ),
        .CLR(lcd_en_i_2_n_0),
        .D(lcd_mode_0[3]),
        .Q(lcd_mode[3]));
  LUT3 #(
    .INIT(8'h10)) 
    lcd_rs_INST_0
       (.I0(lcd_mode[2]),
        .I1(lcd_mode[0]),
        .I2(lcd_mode[3]),
        .O(lcd_rs));
endmodule

module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_textlcd_v1_0
   (S_AXI_AWREADY,
    S_AXI_WREADY,
    S_AXI_ARREADY,
    s00_axi_rdata,
    lcd_data,
    lcd_rs,
    s00_axi_rvalid,
    lcd_en,
    s00_axi_bvalid,
    s00_axi_awaddr,
    s00_axi_wvalid,
    s00_axi_awvalid,
    s00_axi_aclk,
    s00_axi_wdata,
    lcdclk,
    s00_axi_araddr,
    s00_axi_arvalid,
    s00_axi_wstrb,
    s00_axi_aresetn,
    resetn,
    s00_axi_bready,
    s00_axi_rready);
  output S_AXI_AWREADY;
  output S_AXI_WREADY;
  output S_AXI_ARREADY;
  output [31:0]s00_axi_rdata;
  output [7:0]lcd_data;
  output lcd_rs;
  output s00_axi_rvalid;
  output lcd_en;
  output s00_axi_bvalid;
  input [2:0]s00_axi_awaddr;
  input s00_axi_wvalid;
  input s00_axi_awvalid;
  input s00_axi_aclk;
  input [31:0]s00_axi_wdata;
  input lcdclk;
  input [2:0]s00_axi_araddr;
  input s00_axi_arvalid;
  input [3:0]s00_axi_wstrb;
  input s00_axi_aresetn;
  input resetn;
  input s00_axi_bready;
  input s00_axi_rready;

  wire S_AXI_ARREADY;
  wire S_AXI_AWREADY;
  wire S_AXI_WREADY;
  wire [7:0]lcd_data;
  wire lcd_en;
  wire lcd_rs;
  wire lcdclk;
  wire resetn;
  wire s00_axi_aclk;
  wire [2:0]s00_axi_araddr;
  wire s00_axi_aresetn;
  wire s00_axi_arvalid;
  wire [2:0]s00_axi_awaddr;
  wire s00_axi_awvalid;
  wire s00_axi_bready;
  wire s00_axi_bvalid;
  wire [31:0]s00_axi_rdata;
  wire s00_axi_rready;
  wire s00_axi_rvalid;
  wire [31:0]s00_axi_wdata;
  wire [3:0]s00_axi_wstrb;
  wire s00_axi_wvalid;

  decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_textlcd_v1_0_S00_AXI textlcd_v1_0_S00_AXI_inst
       (.S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_WREADY(S_AXI_WREADY),
        .lcd_data(lcd_data),
        .lcd_en(lcd_en),
        .lcd_rs(lcd_rs),
        .lcdclk(lcdclk),
        .resetn(resetn),
        .s00_axi_aclk(s00_axi_aclk),
        .s00_axi_araddr(s00_axi_araddr),
        .s00_axi_aresetn(s00_axi_aresetn),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_awaddr(s00_axi_awaddr),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_bready(s00_axi_bready),
        .s00_axi_bvalid(s00_axi_bvalid),
        .s00_axi_rdata(s00_axi_rdata),
        .s00_axi_rready(s00_axi_rready),
        .s00_axi_rvalid(s00_axi_rvalid),
        .s00_axi_wdata(s00_axi_wdata),
        .s00_axi_wstrb(s00_axi_wstrb),
        .s00_axi_wvalid(s00_axi_wvalid));
endmodule

module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_textlcd_v1_0_S00_AXI
   (S_AXI_AWREADY,
    S_AXI_WREADY,
    S_AXI_ARREADY,
    s00_axi_rdata,
    lcd_data,
    lcd_rs,
    s00_axi_rvalid,
    lcd_en,
    s00_axi_bvalid,
    s00_axi_awaddr,
    s00_axi_wvalid,
    s00_axi_awvalid,
    s00_axi_aclk,
    s00_axi_wdata,
    lcdclk,
    s00_axi_araddr,
    s00_axi_arvalid,
    s00_axi_wstrb,
    s00_axi_aresetn,
    resetn,
    s00_axi_bready,
    s00_axi_rready);
  output S_AXI_AWREADY;
  output S_AXI_WREADY;
  output S_AXI_ARREADY;
  output [31:0]s00_axi_rdata;
  output [7:0]lcd_data;
  output lcd_rs;
  output s00_axi_rvalid;
  output lcd_en;
  output s00_axi_bvalid;
  input [2:0]s00_axi_awaddr;
  input s00_axi_wvalid;
  input s00_axi_awvalid;
  input s00_axi_aclk;
  input [31:0]s00_axi_wdata;
  input lcdclk;
  input [2:0]s00_axi_araddr;
  input s00_axi_arvalid;
  input [3:0]s00_axi_wstrb;
  input s00_axi_aresetn;
  input resetn;
  input s00_axi_bready;
  input s00_axi_rready;

  wire S_AXI_ARREADY;
  wire S_AXI_AWREADY;
  wire S_AXI_WREADY;
  wire aw_en_i_1_n_0;
  wire aw_en_reg_n_0;
  wire \axi_araddr[2]_i_1_n_0 ;
  wire \axi_araddr[3]_i_1_n_0 ;
  wire \axi_araddr[4]_i_1_n_0 ;
  wire axi_arready0;
  wire \axi_awaddr[2]_i_1_n_0 ;
  wire \axi_awaddr[3]_i_1_n_0 ;
  wire \axi_awaddr[4]_i_1_n_0 ;
  wire axi_awready0;
  wire axi_awready_i_1_n_0;
  wire axi_bvalid_i_1_n_0;
  wire \axi_rdata[0]_i_2_n_0 ;
  wire \axi_rdata[0]_i_3_n_0 ;
  wire \axi_rdata[10]_i_2_n_0 ;
  wire \axi_rdata[10]_i_3_n_0 ;
  wire \axi_rdata[11]_i_2_n_0 ;
  wire \axi_rdata[11]_i_3_n_0 ;
  wire \axi_rdata[12]_i_2_n_0 ;
  wire \axi_rdata[12]_i_3_n_0 ;
  wire \axi_rdata[13]_i_2_n_0 ;
  wire \axi_rdata[13]_i_3_n_0 ;
  wire \axi_rdata[14]_i_2_n_0 ;
  wire \axi_rdata[14]_i_3_n_0 ;
  wire \axi_rdata[15]_i_2_n_0 ;
  wire \axi_rdata[15]_i_3_n_0 ;
  wire \axi_rdata[16]_i_2_n_0 ;
  wire \axi_rdata[16]_i_3_n_0 ;
  wire \axi_rdata[17]_i_2_n_0 ;
  wire \axi_rdata[17]_i_3_n_0 ;
  wire \axi_rdata[18]_i_2_n_0 ;
  wire \axi_rdata[18]_i_3_n_0 ;
  wire \axi_rdata[19]_i_2_n_0 ;
  wire \axi_rdata[19]_i_3_n_0 ;
  wire \axi_rdata[1]_i_2_n_0 ;
  wire \axi_rdata[1]_i_3_n_0 ;
  wire \axi_rdata[20]_i_2_n_0 ;
  wire \axi_rdata[20]_i_3_n_0 ;
  wire \axi_rdata[21]_i_2_n_0 ;
  wire \axi_rdata[21]_i_3_n_0 ;
  wire \axi_rdata[22]_i_2_n_0 ;
  wire \axi_rdata[22]_i_3_n_0 ;
  wire \axi_rdata[23]_i_2_n_0 ;
  wire \axi_rdata[23]_i_3_n_0 ;
  wire \axi_rdata[24]_i_2_n_0 ;
  wire \axi_rdata[24]_i_3_n_0 ;
  wire \axi_rdata[25]_i_2_n_0 ;
  wire \axi_rdata[25]_i_3_n_0 ;
  wire \axi_rdata[26]_i_2_n_0 ;
  wire \axi_rdata[26]_i_3_n_0 ;
  wire \axi_rdata[27]_i_2_n_0 ;
  wire \axi_rdata[27]_i_3_n_0 ;
  wire \axi_rdata[28]_i_2_n_0 ;
  wire \axi_rdata[28]_i_3_n_0 ;
  wire \axi_rdata[29]_i_2_n_0 ;
  wire \axi_rdata[29]_i_3_n_0 ;
  wire \axi_rdata[2]_i_2_n_0 ;
  wire \axi_rdata[2]_i_3_n_0 ;
  wire \axi_rdata[30]_i_2_n_0 ;
  wire \axi_rdata[30]_i_3_n_0 ;
  wire \axi_rdata[31]_i_2_n_0 ;
  wire \axi_rdata[31]_i_3_n_0 ;
  wire \axi_rdata[3]_i_2_n_0 ;
  wire \axi_rdata[3]_i_3_n_0 ;
  wire \axi_rdata[4]_i_2_n_0 ;
  wire \axi_rdata[4]_i_3_n_0 ;
  wire \axi_rdata[5]_i_2_n_0 ;
  wire \axi_rdata[5]_i_3_n_0 ;
  wire \axi_rdata[6]_i_2_n_0 ;
  wire \axi_rdata[6]_i_3_n_0 ;
  wire \axi_rdata[7]_i_2_n_0 ;
  wire \axi_rdata[7]_i_3_n_0 ;
  wire \axi_rdata[8]_i_2_n_0 ;
  wire \axi_rdata[8]_i_3_n_0 ;
  wire \axi_rdata[9]_i_2_n_0 ;
  wire \axi_rdata[9]_i_3_n_0 ;
  wire axi_rvalid_i_1_n_0;
  wire axi_wready0;
  wire [7:0]data1;
  wire [7:0]data10;
  wire [7:0]data11;
  wire [7:0]data12;
  wire [7:0]data13;
  wire [7:0]data14;
  wire [7:0]data15;
  wire [7:0]data2;
  wire [7:0]data3;
  wire [7:0]data4;
  wire [7:0]data5;
  wire [7:0]data6;
  wire [7:0]data7;
  wire [7:0]data8;
  wire [7:0]data9;
  wire [7:0]lcd_data;
  wire lcd_en;
  wire lcd_rs;
  wire lcdclk;
  wire [2:0]p_0_in;
  wire [7:0]p_12_in;
  wire [31:7]p_1_in;
  wire [31:0]reg_data_out;
  wire resetn;
  wire s00_axi_aclk;
  wire [2:0]s00_axi_araddr;
  wire s00_axi_aresetn;
  wire s00_axi_arvalid;
  wire [2:0]s00_axi_awaddr;
  wire s00_axi_awvalid;
  wire s00_axi_bready;
  wire s00_axi_bvalid;
  wire [31:0]s00_axi_rdata;
  wire s00_axi_rready;
  wire s00_axi_rvalid;
  wire [31:0]s00_axi_wdata;
  wire [3:0]s00_axi_wstrb;
  wire s00_axi_wvalid;
  wire [2:0]sel0;
  wire \slv_reg0_reg_n_0_[24] ;
  wire \slv_reg0_reg_n_0_[25] ;
  wire \slv_reg0_reg_n_0_[26] ;
  wire \slv_reg0_reg_n_0_[27] ;
  wire \slv_reg0_reg_n_0_[28] ;
  wire \slv_reg0_reg_n_0_[29] ;
  wire \slv_reg0_reg_n_0_[30] ;
  wire \slv_reg0_reg_n_0_[31] ;
  wire \slv_reg1[15]_i_1_n_0 ;
  wire \slv_reg1[23]_i_1_n_0 ;
  wire \slv_reg1[31]_i_1_n_0 ;
  wire \slv_reg1[7]_i_1_n_0 ;
  wire \slv_reg2[15]_i_1_n_0 ;
  wire \slv_reg2[23]_i_1_n_0 ;
  wire \slv_reg2[31]_i_1_n_0 ;
  wire \slv_reg2[7]_i_1_n_0 ;
  wire \slv_reg3[15]_i_1_n_0 ;
  wire \slv_reg3[23]_i_1_n_0 ;
  wire \slv_reg3[31]_i_1_n_0 ;
  wire \slv_reg3[7]_i_1_n_0 ;
  wire [31:0]slv_reg4;
  wire \slv_reg4[15]_i_1_n_0 ;
  wire \slv_reg4[23]_i_1_n_0 ;
  wire \slv_reg4[31]_i_1_n_0 ;
  wire \slv_reg4[7]_i_1_n_0 ;
  wire [31:0]slv_reg5;
  wire \slv_reg5[15]_i_1_n_0 ;
  wire \slv_reg5[23]_i_1_n_0 ;
  wire \slv_reg5[31]_i_1_n_0 ;
  wire \slv_reg5[7]_i_1_n_0 ;
  wire [31:0]slv_reg6;
  wire \slv_reg6[15]_i_1_n_0 ;
  wire \slv_reg6[23]_i_1_n_0 ;
  wire \slv_reg6[31]_i_1_n_0 ;
  wire \slv_reg6[7]_i_1_n_0 ;
  wire \slv_reg7[15]_i_1_n_0 ;
  wire \slv_reg7[23]_i_1_n_0 ;
  wire \slv_reg7[31]_i_1_n_0 ;
  wire \slv_reg7[7]_i_1_n_0 ;
  wire \slv_reg7_reg_n_0_[10] ;
  wire \slv_reg7_reg_n_0_[11] ;
  wire \slv_reg7_reg_n_0_[12] ;
  wire \slv_reg7_reg_n_0_[13] ;
  wire \slv_reg7_reg_n_0_[14] ;
  wire \slv_reg7_reg_n_0_[15] ;
  wire \slv_reg7_reg_n_0_[16] ;
  wire \slv_reg7_reg_n_0_[17] ;
  wire \slv_reg7_reg_n_0_[18] ;
  wire \slv_reg7_reg_n_0_[19] ;
  wire \slv_reg7_reg_n_0_[20] ;
  wire \slv_reg7_reg_n_0_[21] ;
  wire \slv_reg7_reg_n_0_[22] ;
  wire \slv_reg7_reg_n_0_[23] ;
  wire \slv_reg7_reg_n_0_[24] ;
  wire \slv_reg7_reg_n_0_[25] ;
  wire \slv_reg7_reg_n_0_[26] ;
  wire \slv_reg7_reg_n_0_[27] ;
  wire \slv_reg7_reg_n_0_[28] ;
  wire \slv_reg7_reg_n_0_[29] ;
  wire \slv_reg7_reg_n_0_[30] ;
  wire \slv_reg7_reg_n_0_[31] ;
  wire \slv_reg7_reg_n_0_[8] ;
  wire \slv_reg7_reg_n_0_[9] ;
  wire slv_reg_rden__0;
  wire slv_reg_wren__0;

  LUT6 #(
    .INIT(64'hF7FFC4CCC4CCC4CC)) 
    aw_en_i_1
       (.I0(s00_axi_awvalid),
        .I1(aw_en_reg_n_0),
        .I2(S_AXI_AWREADY),
        .I3(s00_axi_wvalid),
        .I4(s00_axi_bready),
        .I5(s00_axi_bvalid),
        .O(aw_en_i_1_n_0));
  FDSE aw_en_reg
       (.C(s00_axi_aclk),
        .CE(1'b1),
        .D(aw_en_i_1_n_0),
        .Q(aw_en_reg_n_0),
        .S(axi_awready_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair8" *) 
  LUT4 #(
    .INIT(16'hFB08)) 
    \axi_araddr[2]_i_1 
       (.I0(s00_axi_araddr[0]),
        .I1(s00_axi_arvalid),
        .I2(S_AXI_ARREADY),
        .I3(sel0[0]),
        .O(\axi_araddr[2]_i_1_n_0 ));
  LUT4 #(
    .INIT(16'hFB08)) 
    \axi_araddr[3]_i_1 
       (.I0(s00_axi_araddr[1]),
        .I1(s00_axi_arvalid),
        .I2(S_AXI_ARREADY),
        .I3(sel0[1]),
        .O(\axi_araddr[3]_i_1_n_0 ));
  LUT4 #(
    .INIT(16'hFB08)) 
    \axi_araddr[4]_i_1 
       (.I0(s00_axi_araddr[2]),
        .I1(s00_axi_arvalid),
        .I2(S_AXI_ARREADY),
        .I3(sel0[2]),
        .O(\axi_araddr[4]_i_1_n_0 ));
  FDRE \axi_araddr_reg[2] 
       (.C(s00_axi_aclk),
        .CE(1'b1),
        .D(\axi_araddr[2]_i_1_n_0 ),
        .Q(sel0[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \axi_araddr_reg[3] 
       (.C(s00_axi_aclk),
        .CE(1'b1),
        .D(\axi_araddr[3]_i_1_n_0 ),
        .Q(sel0[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \axi_araddr_reg[4] 
       (.C(s00_axi_aclk),
        .CE(1'b1),
        .D(\axi_araddr[4]_i_1_n_0 ),
        .Q(sel0[2]),
        .R(axi_awready_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair8" *) 
  LUT2 #(
    .INIT(4'h2)) 
    axi_arready_i_1
       (.I0(s00_axi_arvalid),
        .I1(S_AXI_ARREADY),
        .O(axi_arready0));
  FDRE axi_arready_reg
       (.C(s00_axi_aclk),
        .CE(1'b1),
        .D(axi_arready0),
        .Q(S_AXI_ARREADY),
        .R(axi_awready_i_1_n_0));
  LUT6 #(
    .INIT(64'hFBFFFFFF08000000)) 
    \axi_awaddr[2]_i_1 
       (.I0(s00_axi_awaddr[0]),
        .I1(s00_axi_wvalid),
        .I2(S_AXI_AWREADY),
        .I3(aw_en_reg_n_0),
        .I4(s00_axi_awvalid),
        .I5(p_0_in[0]),
        .O(\axi_awaddr[2]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hFBFFFFFF08000000)) 
    \axi_awaddr[3]_i_1 
       (.I0(s00_axi_awaddr[1]),
        .I1(s00_axi_wvalid),
        .I2(S_AXI_AWREADY),
        .I3(aw_en_reg_n_0),
        .I4(s00_axi_awvalid),
        .I5(p_0_in[1]),
        .O(\axi_awaddr[3]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hFBFFFFFF08000000)) 
    \axi_awaddr[4]_i_1 
       (.I0(s00_axi_awaddr[2]),
        .I1(s00_axi_wvalid),
        .I2(S_AXI_AWREADY),
        .I3(aw_en_reg_n_0),
        .I4(s00_axi_awvalid),
        .I5(p_0_in[2]),
        .O(\axi_awaddr[4]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[2] 
       (.C(s00_axi_aclk),
        .CE(1'b1),
        .D(\axi_awaddr[2]_i_1_n_0 ),
        .Q(p_0_in[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \axi_awaddr_reg[3] 
       (.C(s00_axi_aclk),
        .CE(1'b1),
        .D(\axi_awaddr[3]_i_1_n_0 ),
        .Q(p_0_in[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \axi_awaddr_reg[4] 
       (.C(s00_axi_aclk),
        .CE(1'b1),
        .D(\axi_awaddr[4]_i_1_n_0 ),
        .Q(p_0_in[2]),
        .R(axi_awready_i_1_n_0));
  LUT1 #(
    .INIT(2'h1)) 
    axi_awready_i_1
       (.I0(s00_axi_aresetn),
        .O(axi_awready_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair9" *) 
  LUT4 #(
    .INIT(16'h2000)) 
    axi_awready_i_2
       (.I0(s00_axi_wvalid),
        .I1(S_AXI_AWREADY),
        .I2(aw_en_reg_n_0),
        .I3(s00_axi_awvalid),
        .O(axi_awready0));
  FDRE axi_awready_reg
       (.C(s00_axi_aclk),
        .CE(1'b1),
        .D(axi_awready0),
        .Q(S_AXI_AWREADY),
        .R(axi_awready_i_1_n_0));
  LUT6 #(
    .INIT(64'h0000FFFF80008000)) 
    axi_bvalid_i_1
       (.I0(s00_axi_awvalid),
        .I1(s00_axi_wvalid),
        .I2(S_AXI_AWREADY),
        .I3(S_AXI_WREADY),
        .I4(s00_axi_bready),
        .I5(s00_axi_bvalid),
        .O(axi_bvalid_i_1_n_0));
  FDRE axi_bvalid_reg
       (.C(s00_axi_aclk),
        .CE(1'b1),
        .D(axi_bvalid_i_1_n_0),
        .Q(s00_axi_bvalid),
        .R(axi_awready_i_1_n_0));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[0]_i_2 
       (.I0(p_12_in[0]),
        .I1(data11[0]),
        .I2(sel0[1]),
        .I3(data7[0]),
        .I4(sel0[0]),
        .I5(data3[0]),
        .O(\axi_rdata[0]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[0]_i_3 
       (.I0(data15[0]),
        .I1(slv_reg6[0]),
        .I2(sel0[1]),
        .I3(slv_reg5[0]),
        .I4(sel0[0]),
        .I5(slv_reg4[0]),
        .O(\axi_rdata[0]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[10]_i_2 
       (.I0(data14[2]),
        .I1(data10[2]),
        .I2(sel0[1]),
        .I3(data6[2]),
        .I4(sel0[0]),
        .I5(data2[2]),
        .O(\axi_rdata[10]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[10]_i_3 
       (.I0(\slv_reg7_reg_n_0_[10] ),
        .I1(slv_reg6[10]),
        .I2(sel0[1]),
        .I3(slv_reg5[10]),
        .I4(sel0[0]),
        .I5(slv_reg4[10]),
        .O(\axi_rdata[10]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[11]_i_2 
       (.I0(data14[3]),
        .I1(data10[3]),
        .I2(sel0[1]),
        .I3(data6[3]),
        .I4(sel0[0]),
        .I5(data2[3]),
        .O(\axi_rdata[11]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[11]_i_3 
       (.I0(\slv_reg7_reg_n_0_[11] ),
        .I1(slv_reg6[11]),
        .I2(sel0[1]),
        .I3(slv_reg5[11]),
        .I4(sel0[0]),
        .I5(slv_reg4[11]),
        .O(\axi_rdata[11]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[12]_i_2 
       (.I0(data14[4]),
        .I1(data10[4]),
        .I2(sel0[1]),
        .I3(data6[4]),
        .I4(sel0[0]),
        .I5(data2[4]),
        .O(\axi_rdata[12]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[12]_i_3 
       (.I0(\slv_reg7_reg_n_0_[12] ),
        .I1(slv_reg6[12]),
        .I2(sel0[1]),
        .I3(slv_reg5[12]),
        .I4(sel0[0]),
        .I5(slv_reg4[12]),
        .O(\axi_rdata[12]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[13]_i_2 
       (.I0(data14[5]),
        .I1(data10[5]),
        .I2(sel0[1]),
        .I3(data6[5]),
        .I4(sel0[0]),
        .I5(data2[5]),
        .O(\axi_rdata[13]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[13]_i_3 
       (.I0(\slv_reg7_reg_n_0_[13] ),
        .I1(slv_reg6[13]),
        .I2(sel0[1]),
        .I3(slv_reg5[13]),
        .I4(sel0[0]),
        .I5(slv_reg4[13]),
        .O(\axi_rdata[13]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[14]_i_2 
       (.I0(data14[6]),
        .I1(data10[6]),
        .I2(sel0[1]),
        .I3(data6[6]),
        .I4(sel0[0]),
        .I5(data2[6]),
        .O(\axi_rdata[14]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[14]_i_3 
       (.I0(\slv_reg7_reg_n_0_[14] ),
        .I1(slv_reg6[14]),
        .I2(sel0[1]),
        .I3(slv_reg5[14]),
        .I4(sel0[0]),
        .I5(slv_reg4[14]),
        .O(\axi_rdata[14]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[15]_i_2 
       (.I0(data14[7]),
        .I1(data10[7]),
        .I2(sel0[1]),
        .I3(data6[7]),
        .I4(sel0[0]),
        .I5(data2[7]),
        .O(\axi_rdata[15]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[15]_i_3 
       (.I0(\slv_reg7_reg_n_0_[15] ),
        .I1(slv_reg6[15]),
        .I2(sel0[1]),
        .I3(slv_reg5[15]),
        .I4(sel0[0]),
        .I5(slv_reg4[15]),
        .O(\axi_rdata[15]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[16]_i_2 
       (.I0(data13[0]),
        .I1(data9[0]),
        .I2(sel0[1]),
        .I3(data5[0]),
        .I4(sel0[0]),
        .I5(data1[0]),
        .O(\axi_rdata[16]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[16]_i_3 
       (.I0(\slv_reg7_reg_n_0_[16] ),
        .I1(slv_reg6[16]),
        .I2(sel0[1]),
        .I3(slv_reg5[16]),
        .I4(sel0[0]),
        .I5(slv_reg4[16]),
        .O(\axi_rdata[16]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[17]_i_2 
       (.I0(data13[1]),
        .I1(data9[1]),
        .I2(sel0[1]),
        .I3(data5[1]),
        .I4(sel0[0]),
        .I5(data1[1]),
        .O(\axi_rdata[17]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[17]_i_3 
       (.I0(\slv_reg7_reg_n_0_[17] ),
        .I1(slv_reg6[17]),
        .I2(sel0[1]),
        .I3(slv_reg5[17]),
        .I4(sel0[0]),
        .I5(slv_reg4[17]),
        .O(\axi_rdata[17]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[18]_i_2 
       (.I0(data13[2]),
        .I1(data9[2]),
        .I2(sel0[1]),
        .I3(data5[2]),
        .I4(sel0[0]),
        .I5(data1[2]),
        .O(\axi_rdata[18]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[18]_i_3 
       (.I0(\slv_reg7_reg_n_0_[18] ),
        .I1(slv_reg6[18]),
        .I2(sel0[1]),
        .I3(slv_reg5[18]),
        .I4(sel0[0]),
        .I5(slv_reg4[18]),
        .O(\axi_rdata[18]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[19]_i_2 
       (.I0(data13[3]),
        .I1(data9[3]),
        .I2(sel0[1]),
        .I3(data5[3]),
        .I4(sel0[0]),
        .I5(data1[3]),
        .O(\axi_rdata[19]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[19]_i_3 
       (.I0(\slv_reg7_reg_n_0_[19] ),
        .I1(slv_reg6[19]),
        .I2(sel0[1]),
        .I3(slv_reg5[19]),
        .I4(sel0[0]),
        .I5(slv_reg4[19]),
        .O(\axi_rdata[19]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[1]_i_2 
       (.I0(p_12_in[1]),
        .I1(data11[1]),
        .I2(sel0[1]),
        .I3(data7[1]),
        .I4(sel0[0]),
        .I5(data3[1]),
        .O(\axi_rdata[1]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[1]_i_3 
       (.I0(data15[1]),
        .I1(slv_reg6[1]),
        .I2(sel0[1]),
        .I3(slv_reg5[1]),
        .I4(sel0[0]),
        .I5(slv_reg4[1]),
        .O(\axi_rdata[1]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[20]_i_2 
       (.I0(data13[4]),
        .I1(data9[4]),
        .I2(sel0[1]),
        .I3(data5[4]),
        .I4(sel0[0]),
        .I5(data1[4]),
        .O(\axi_rdata[20]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[20]_i_3 
       (.I0(\slv_reg7_reg_n_0_[20] ),
        .I1(slv_reg6[20]),
        .I2(sel0[1]),
        .I3(slv_reg5[20]),
        .I4(sel0[0]),
        .I5(slv_reg4[20]),
        .O(\axi_rdata[20]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[21]_i_2 
       (.I0(data13[5]),
        .I1(data9[5]),
        .I2(sel0[1]),
        .I3(data5[5]),
        .I4(sel0[0]),
        .I5(data1[5]),
        .O(\axi_rdata[21]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[21]_i_3 
       (.I0(\slv_reg7_reg_n_0_[21] ),
        .I1(slv_reg6[21]),
        .I2(sel0[1]),
        .I3(slv_reg5[21]),
        .I4(sel0[0]),
        .I5(slv_reg4[21]),
        .O(\axi_rdata[21]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[22]_i_2 
       (.I0(data13[6]),
        .I1(data9[6]),
        .I2(sel0[1]),
        .I3(data5[6]),
        .I4(sel0[0]),
        .I5(data1[6]),
        .O(\axi_rdata[22]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[22]_i_3 
       (.I0(\slv_reg7_reg_n_0_[22] ),
        .I1(slv_reg6[22]),
        .I2(sel0[1]),
        .I3(slv_reg5[22]),
        .I4(sel0[0]),
        .I5(slv_reg4[22]),
        .O(\axi_rdata[22]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[23]_i_2 
       (.I0(data13[7]),
        .I1(data9[7]),
        .I2(sel0[1]),
        .I3(data5[7]),
        .I4(sel0[0]),
        .I5(data1[7]),
        .O(\axi_rdata[23]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[23]_i_3 
       (.I0(\slv_reg7_reg_n_0_[23] ),
        .I1(slv_reg6[23]),
        .I2(sel0[1]),
        .I3(slv_reg5[23]),
        .I4(sel0[0]),
        .I5(slv_reg4[23]),
        .O(\axi_rdata[23]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[24]_i_2 
       (.I0(data12[0]),
        .I1(data8[0]),
        .I2(sel0[1]),
        .I3(data4[0]),
        .I4(sel0[0]),
        .I5(\slv_reg0_reg_n_0_[24] ),
        .O(\axi_rdata[24]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[24]_i_3 
       (.I0(\slv_reg7_reg_n_0_[24] ),
        .I1(slv_reg6[24]),
        .I2(sel0[1]),
        .I3(slv_reg5[24]),
        .I4(sel0[0]),
        .I5(slv_reg4[24]),
        .O(\axi_rdata[24]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[25]_i_2 
       (.I0(data12[1]),
        .I1(data8[1]),
        .I2(sel0[1]),
        .I3(data4[1]),
        .I4(sel0[0]),
        .I5(\slv_reg0_reg_n_0_[25] ),
        .O(\axi_rdata[25]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[25]_i_3 
       (.I0(\slv_reg7_reg_n_0_[25] ),
        .I1(slv_reg6[25]),
        .I2(sel0[1]),
        .I3(slv_reg5[25]),
        .I4(sel0[0]),
        .I5(slv_reg4[25]),
        .O(\axi_rdata[25]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[26]_i_2 
       (.I0(data12[2]),
        .I1(data8[2]),
        .I2(sel0[1]),
        .I3(data4[2]),
        .I4(sel0[0]),
        .I5(\slv_reg0_reg_n_0_[26] ),
        .O(\axi_rdata[26]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[26]_i_3 
       (.I0(\slv_reg7_reg_n_0_[26] ),
        .I1(slv_reg6[26]),
        .I2(sel0[1]),
        .I3(slv_reg5[26]),
        .I4(sel0[0]),
        .I5(slv_reg4[26]),
        .O(\axi_rdata[26]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[27]_i_2 
       (.I0(data12[3]),
        .I1(data8[3]),
        .I2(sel0[1]),
        .I3(data4[3]),
        .I4(sel0[0]),
        .I5(\slv_reg0_reg_n_0_[27] ),
        .O(\axi_rdata[27]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[27]_i_3 
       (.I0(\slv_reg7_reg_n_0_[27] ),
        .I1(slv_reg6[27]),
        .I2(sel0[1]),
        .I3(slv_reg5[27]),
        .I4(sel0[0]),
        .I5(slv_reg4[27]),
        .O(\axi_rdata[27]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[28]_i_2 
       (.I0(data12[4]),
        .I1(data8[4]),
        .I2(sel0[1]),
        .I3(data4[4]),
        .I4(sel0[0]),
        .I5(\slv_reg0_reg_n_0_[28] ),
        .O(\axi_rdata[28]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[28]_i_3 
       (.I0(\slv_reg7_reg_n_0_[28] ),
        .I1(slv_reg6[28]),
        .I2(sel0[1]),
        .I3(slv_reg5[28]),
        .I4(sel0[0]),
        .I5(slv_reg4[28]),
        .O(\axi_rdata[28]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[29]_i_2 
       (.I0(data12[5]),
        .I1(data8[5]),
        .I2(sel0[1]),
        .I3(data4[5]),
        .I4(sel0[0]),
        .I5(\slv_reg0_reg_n_0_[29] ),
        .O(\axi_rdata[29]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[29]_i_3 
       (.I0(\slv_reg7_reg_n_0_[29] ),
        .I1(slv_reg6[29]),
        .I2(sel0[1]),
        .I3(slv_reg5[29]),
        .I4(sel0[0]),
        .I5(slv_reg4[29]),
        .O(\axi_rdata[29]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[2]_i_2 
       (.I0(p_12_in[2]),
        .I1(data11[2]),
        .I2(sel0[1]),
        .I3(data7[2]),
        .I4(sel0[0]),
        .I5(data3[2]),
        .O(\axi_rdata[2]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[2]_i_3 
       (.I0(data15[2]),
        .I1(slv_reg6[2]),
        .I2(sel0[1]),
        .I3(slv_reg5[2]),
        .I4(sel0[0]),
        .I5(slv_reg4[2]),
        .O(\axi_rdata[2]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[30]_i_2 
       (.I0(data12[6]),
        .I1(data8[6]),
        .I2(sel0[1]),
        .I3(data4[6]),
        .I4(sel0[0]),
        .I5(\slv_reg0_reg_n_0_[30] ),
        .O(\axi_rdata[30]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[30]_i_3 
       (.I0(\slv_reg7_reg_n_0_[30] ),
        .I1(slv_reg6[30]),
        .I2(sel0[1]),
        .I3(slv_reg5[30]),
        .I4(sel0[0]),
        .I5(slv_reg4[30]),
        .O(\axi_rdata[30]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[31]_i_2 
       (.I0(data12[7]),
        .I1(data8[7]),
        .I2(sel0[1]),
        .I3(data4[7]),
        .I4(sel0[0]),
        .I5(\slv_reg0_reg_n_0_[31] ),
        .O(\axi_rdata[31]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[31]_i_3 
       (.I0(\slv_reg7_reg_n_0_[31] ),
        .I1(slv_reg6[31]),
        .I2(sel0[1]),
        .I3(slv_reg5[31]),
        .I4(sel0[0]),
        .I5(slv_reg4[31]),
        .O(\axi_rdata[31]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[3]_i_2 
       (.I0(p_12_in[3]),
        .I1(data11[3]),
        .I2(sel0[1]),
        .I3(data7[3]),
        .I4(sel0[0]),
        .I5(data3[3]),
        .O(\axi_rdata[3]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[3]_i_3 
       (.I0(data15[3]),
        .I1(slv_reg6[3]),
        .I2(sel0[1]),
        .I3(slv_reg5[3]),
        .I4(sel0[0]),
        .I5(slv_reg4[3]),
        .O(\axi_rdata[3]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[4]_i_2 
       (.I0(p_12_in[4]),
        .I1(data11[4]),
        .I2(sel0[1]),
        .I3(data7[4]),
        .I4(sel0[0]),
        .I5(data3[4]),
        .O(\axi_rdata[4]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[4]_i_3 
       (.I0(data15[4]),
        .I1(slv_reg6[4]),
        .I2(sel0[1]),
        .I3(slv_reg5[4]),
        .I4(sel0[0]),
        .I5(slv_reg4[4]),
        .O(\axi_rdata[4]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[5]_i_2 
       (.I0(p_12_in[5]),
        .I1(data11[5]),
        .I2(sel0[1]),
        .I3(data7[5]),
        .I4(sel0[0]),
        .I5(data3[5]),
        .O(\axi_rdata[5]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[5]_i_3 
       (.I0(data15[5]),
        .I1(slv_reg6[5]),
        .I2(sel0[1]),
        .I3(slv_reg5[5]),
        .I4(sel0[0]),
        .I5(slv_reg4[5]),
        .O(\axi_rdata[5]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[6]_i_2 
       (.I0(p_12_in[6]),
        .I1(data11[6]),
        .I2(sel0[1]),
        .I3(data7[6]),
        .I4(sel0[0]),
        .I5(data3[6]),
        .O(\axi_rdata[6]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[6]_i_3 
       (.I0(data15[6]),
        .I1(slv_reg6[6]),
        .I2(sel0[1]),
        .I3(slv_reg5[6]),
        .I4(sel0[0]),
        .I5(slv_reg4[6]),
        .O(\axi_rdata[6]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[7]_i_2 
       (.I0(p_12_in[7]),
        .I1(data11[7]),
        .I2(sel0[1]),
        .I3(data7[7]),
        .I4(sel0[0]),
        .I5(data3[7]),
        .O(\axi_rdata[7]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[7]_i_3 
       (.I0(data15[7]),
        .I1(slv_reg6[7]),
        .I2(sel0[1]),
        .I3(slv_reg5[7]),
        .I4(sel0[0]),
        .I5(slv_reg4[7]),
        .O(\axi_rdata[7]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[8]_i_2 
       (.I0(data14[0]),
        .I1(data10[0]),
        .I2(sel0[1]),
        .I3(data6[0]),
        .I4(sel0[0]),
        .I5(data2[0]),
        .O(\axi_rdata[8]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[8]_i_3 
       (.I0(\slv_reg7_reg_n_0_[8] ),
        .I1(slv_reg6[8]),
        .I2(sel0[1]),
        .I3(slv_reg5[8]),
        .I4(sel0[0]),
        .I5(slv_reg4[8]),
        .O(\axi_rdata[8]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[9]_i_2 
       (.I0(data14[1]),
        .I1(data10[1]),
        .I2(sel0[1]),
        .I3(data6[1]),
        .I4(sel0[0]),
        .I5(data2[1]),
        .O(\axi_rdata[9]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hAFA0CFCFAFA0C0C0)) 
    \axi_rdata[9]_i_3 
       (.I0(\slv_reg7_reg_n_0_[9] ),
        .I1(slv_reg6[9]),
        .I2(sel0[1]),
        .I3(slv_reg5[9]),
        .I4(sel0[0]),
        .I5(slv_reg4[9]),
        .O(\axi_rdata[9]_i_3_n_0 ));
  FDRE \axi_rdata_reg[0] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[0]),
        .Q(s00_axi_rdata[0]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[0]_i_1 
       (.I0(\axi_rdata[0]_i_2_n_0 ),
        .I1(\axi_rdata[0]_i_3_n_0 ),
        .O(reg_data_out[0]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[10] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[10]),
        .Q(s00_axi_rdata[10]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[10]_i_1 
       (.I0(\axi_rdata[10]_i_2_n_0 ),
        .I1(\axi_rdata[10]_i_3_n_0 ),
        .O(reg_data_out[10]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[11] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[11]),
        .Q(s00_axi_rdata[11]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[11]_i_1 
       (.I0(\axi_rdata[11]_i_2_n_0 ),
        .I1(\axi_rdata[11]_i_3_n_0 ),
        .O(reg_data_out[11]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[12] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[12]),
        .Q(s00_axi_rdata[12]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[12]_i_1 
       (.I0(\axi_rdata[12]_i_2_n_0 ),
        .I1(\axi_rdata[12]_i_3_n_0 ),
        .O(reg_data_out[12]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[13] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[13]),
        .Q(s00_axi_rdata[13]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[13]_i_1 
       (.I0(\axi_rdata[13]_i_2_n_0 ),
        .I1(\axi_rdata[13]_i_3_n_0 ),
        .O(reg_data_out[13]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[14] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[14]),
        .Q(s00_axi_rdata[14]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[14]_i_1 
       (.I0(\axi_rdata[14]_i_2_n_0 ),
        .I1(\axi_rdata[14]_i_3_n_0 ),
        .O(reg_data_out[14]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[15] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[15]),
        .Q(s00_axi_rdata[15]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[15]_i_1 
       (.I0(\axi_rdata[15]_i_2_n_0 ),
        .I1(\axi_rdata[15]_i_3_n_0 ),
        .O(reg_data_out[15]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[16] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[16]),
        .Q(s00_axi_rdata[16]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[16]_i_1 
       (.I0(\axi_rdata[16]_i_2_n_0 ),
        .I1(\axi_rdata[16]_i_3_n_0 ),
        .O(reg_data_out[16]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[17] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[17]),
        .Q(s00_axi_rdata[17]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[17]_i_1 
       (.I0(\axi_rdata[17]_i_2_n_0 ),
        .I1(\axi_rdata[17]_i_3_n_0 ),
        .O(reg_data_out[17]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[18] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[18]),
        .Q(s00_axi_rdata[18]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[18]_i_1 
       (.I0(\axi_rdata[18]_i_2_n_0 ),
        .I1(\axi_rdata[18]_i_3_n_0 ),
        .O(reg_data_out[18]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[19] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[19]),
        .Q(s00_axi_rdata[19]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[19]_i_1 
       (.I0(\axi_rdata[19]_i_2_n_0 ),
        .I1(\axi_rdata[19]_i_3_n_0 ),
        .O(reg_data_out[19]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[1] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[1]),
        .Q(s00_axi_rdata[1]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[1]_i_1 
       (.I0(\axi_rdata[1]_i_2_n_0 ),
        .I1(\axi_rdata[1]_i_3_n_0 ),
        .O(reg_data_out[1]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[20] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[20]),
        .Q(s00_axi_rdata[20]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[20]_i_1 
       (.I0(\axi_rdata[20]_i_2_n_0 ),
        .I1(\axi_rdata[20]_i_3_n_0 ),
        .O(reg_data_out[20]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[21] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[21]),
        .Q(s00_axi_rdata[21]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[21]_i_1 
       (.I0(\axi_rdata[21]_i_2_n_0 ),
        .I1(\axi_rdata[21]_i_3_n_0 ),
        .O(reg_data_out[21]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[22] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[22]),
        .Q(s00_axi_rdata[22]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[22]_i_1 
       (.I0(\axi_rdata[22]_i_2_n_0 ),
        .I1(\axi_rdata[22]_i_3_n_0 ),
        .O(reg_data_out[22]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[23] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[23]),
        .Q(s00_axi_rdata[23]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[23]_i_1 
       (.I0(\axi_rdata[23]_i_2_n_0 ),
        .I1(\axi_rdata[23]_i_3_n_0 ),
        .O(reg_data_out[23]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[24] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[24]),
        .Q(s00_axi_rdata[24]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[24]_i_1 
       (.I0(\axi_rdata[24]_i_2_n_0 ),
        .I1(\axi_rdata[24]_i_3_n_0 ),
        .O(reg_data_out[24]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[25] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[25]),
        .Q(s00_axi_rdata[25]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[25]_i_1 
       (.I0(\axi_rdata[25]_i_2_n_0 ),
        .I1(\axi_rdata[25]_i_3_n_0 ),
        .O(reg_data_out[25]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[26] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[26]),
        .Q(s00_axi_rdata[26]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[26]_i_1 
       (.I0(\axi_rdata[26]_i_2_n_0 ),
        .I1(\axi_rdata[26]_i_3_n_0 ),
        .O(reg_data_out[26]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[27] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[27]),
        .Q(s00_axi_rdata[27]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[27]_i_1 
       (.I0(\axi_rdata[27]_i_2_n_0 ),
        .I1(\axi_rdata[27]_i_3_n_0 ),
        .O(reg_data_out[27]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[28] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[28]),
        .Q(s00_axi_rdata[28]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[28]_i_1 
       (.I0(\axi_rdata[28]_i_2_n_0 ),
        .I1(\axi_rdata[28]_i_3_n_0 ),
        .O(reg_data_out[28]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[29] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[29]),
        .Q(s00_axi_rdata[29]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[29]_i_1 
       (.I0(\axi_rdata[29]_i_2_n_0 ),
        .I1(\axi_rdata[29]_i_3_n_0 ),
        .O(reg_data_out[29]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[2] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[2]),
        .Q(s00_axi_rdata[2]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[2]_i_1 
       (.I0(\axi_rdata[2]_i_2_n_0 ),
        .I1(\axi_rdata[2]_i_3_n_0 ),
        .O(reg_data_out[2]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[30] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[30]),
        .Q(s00_axi_rdata[30]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[30]_i_1 
       (.I0(\axi_rdata[30]_i_2_n_0 ),
        .I1(\axi_rdata[30]_i_3_n_0 ),
        .O(reg_data_out[30]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[31] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[31]),
        .Q(s00_axi_rdata[31]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[31]_i_1 
       (.I0(\axi_rdata[31]_i_2_n_0 ),
        .I1(\axi_rdata[31]_i_3_n_0 ),
        .O(reg_data_out[31]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[3] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[3]),
        .Q(s00_axi_rdata[3]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[3]_i_1 
       (.I0(\axi_rdata[3]_i_2_n_0 ),
        .I1(\axi_rdata[3]_i_3_n_0 ),
        .O(reg_data_out[3]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[4] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[4]),
        .Q(s00_axi_rdata[4]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[4]_i_1 
       (.I0(\axi_rdata[4]_i_2_n_0 ),
        .I1(\axi_rdata[4]_i_3_n_0 ),
        .O(reg_data_out[4]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[5] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[5]),
        .Q(s00_axi_rdata[5]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[5]_i_1 
       (.I0(\axi_rdata[5]_i_2_n_0 ),
        .I1(\axi_rdata[5]_i_3_n_0 ),
        .O(reg_data_out[5]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[6] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[6]),
        .Q(s00_axi_rdata[6]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[6]_i_1 
       (.I0(\axi_rdata[6]_i_2_n_0 ),
        .I1(\axi_rdata[6]_i_3_n_0 ),
        .O(reg_data_out[6]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[7] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[7]),
        .Q(s00_axi_rdata[7]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[7]_i_1 
       (.I0(\axi_rdata[7]_i_2_n_0 ),
        .I1(\axi_rdata[7]_i_3_n_0 ),
        .O(reg_data_out[7]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[8] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[8]),
        .Q(s00_axi_rdata[8]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[8]_i_1 
       (.I0(\axi_rdata[8]_i_2_n_0 ),
        .I1(\axi_rdata[8]_i_3_n_0 ),
        .O(reg_data_out[8]),
        .S(sel0[2]));
  FDRE \axi_rdata_reg[9] 
       (.C(s00_axi_aclk),
        .CE(slv_reg_rden__0),
        .D(reg_data_out[9]),
        .Q(s00_axi_rdata[9]),
        .R(axi_awready_i_1_n_0));
  MUXF7 \axi_rdata_reg[9]_i_1 
       (.I0(\axi_rdata[9]_i_2_n_0 ),
        .I1(\axi_rdata[9]_i_3_n_0 ),
        .O(reg_data_out[9]),
        .S(sel0[2]));
  LUT4 #(
    .INIT(16'h08F8)) 
    axi_rvalid_i_1
       (.I0(S_AXI_ARREADY),
        .I1(s00_axi_arvalid),
        .I2(s00_axi_rvalid),
        .I3(s00_axi_rready),
        .O(axi_rvalid_i_1_n_0));
  FDRE axi_rvalid_reg
       (.C(s00_axi_aclk),
        .CE(1'b1),
        .D(axi_rvalid_i_1_n_0),
        .Q(s00_axi_rvalid),
        .R(axi_awready_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair9" *) 
  LUT4 #(
    .INIT(16'h0800)) 
    axi_wready_i_1
       (.I0(s00_axi_awvalid),
        .I1(s00_axi_wvalid),
        .I2(S_AXI_WREADY),
        .I3(aw_en_reg_n_0),
        .O(axi_wready0));
  FDRE axi_wready_reg
       (.C(s00_axi_aclk),
        .CE(1'b1),
        .D(axi_wready0),
        .Q(S_AXI_WREADY),
        .R(axi_awready_i_1_n_0));
  LUT5 #(
    .INIT(32'h00020000)) 
    \slv_reg0[15]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[1]),
        .I2(p_0_in[0]),
        .I3(p_0_in[2]),
        .I4(s00_axi_wstrb[1]),
        .O(p_1_in[15]));
  LUT5 #(
    .INIT(32'h00020000)) 
    \slv_reg0[23]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[1]),
        .I2(p_0_in[0]),
        .I3(p_0_in[2]),
        .I4(s00_axi_wstrb[2]),
        .O(p_1_in[23]));
  LUT5 #(
    .INIT(32'h00020000)) 
    \slv_reg0[31]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[1]),
        .I2(p_0_in[0]),
        .I3(p_0_in[2]),
        .I4(s00_axi_wstrb[3]),
        .O(p_1_in[31]));
  LUT5 #(
    .INIT(32'h00020000)) 
    \slv_reg0[7]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[1]),
        .I2(p_0_in[0]),
        .I3(p_0_in[2]),
        .I4(s00_axi_wstrb[0]),
        .O(p_1_in[7]));
  FDRE \slv_reg0_reg[0] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[7]),
        .D(s00_axi_wdata[0]),
        .Q(data3[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[10] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[15]),
        .D(s00_axi_wdata[10]),
        .Q(data2[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[11] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[15]),
        .D(s00_axi_wdata[11]),
        .Q(data2[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[12] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[15]),
        .D(s00_axi_wdata[12]),
        .Q(data2[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[13] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[15]),
        .D(s00_axi_wdata[13]),
        .Q(data2[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[14] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[15]),
        .D(s00_axi_wdata[14]),
        .Q(data2[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[15] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[15]),
        .D(s00_axi_wdata[15]),
        .Q(data2[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[16] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[23]),
        .D(s00_axi_wdata[16]),
        .Q(data1[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[17] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[23]),
        .D(s00_axi_wdata[17]),
        .Q(data1[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[18] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[23]),
        .D(s00_axi_wdata[18]),
        .Q(data1[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[19] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[23]),
        .D(s00_axi_wdata[19]),
        .Q(data1[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[1] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[7]),
        .D(s00_axi_wdata[1]),
        .Q(data3[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[20] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[23]),
        .D(s00_axi_wdata[20]),
        .Q(data1[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[21] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[23]),
        .D(s00_axi_wdata[21]),
        .Q(data1[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[22] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[23]),
        .D(s00_axi_wdata[22]),
        .Q(data1[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[23] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[23]),
        .D(s00_axi_wdata[23]),
        .Q(data1[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[24] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[31]),
        .D(s00_axi_wdata[24]),
        .Q(\slv_reg0_reg_n_0_[24] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[25] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[31]),
        .D(s00_axi_wdata[25]),
        .Q(\slv_reg0_reg_n_0_[25] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[26] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[31]),
        .D(s00_axi_wdata[26]),
        .Q(\slv_reg0_reg_n_0_[26] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[27] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[31]),
        .D(s00_axi_wdata[27]),
        .Q(\slv_reg0_reg_n_0_[27] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[28] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[31]),
        .D(s00_axi_wdata[28]),
        .Q(\slv_reg0_reg_n_0_[28] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[29] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[31]),
        .D(s00_axi_wdata[29]),
        .Q(\slv_reg0_reg_n_0_[29] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[2] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[7]),
        .D(s00_axi_wdata[2]),
        .Q(data3[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[30] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[31]),
        .D(s00_axi_wdata[30]),
        .Q(\slv_reg0_reg_n_0_[30] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[31] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[31]),
        .D(s00_axi_wdata[31]),
        .Q(\slv_reg0_reg_n_0_[31] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[3] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[7]),
        .D(s00_axi_wdata[3]),
        .Q(data3[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[4] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[7]),
        .D(s00_axi_wdata[4]),
        .Q(data3[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[5] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[7]),
        .D(s00_axi_wdata[5]),
        .Q(data3[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[6] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[7]),
        .D(s00_axi_wdata[6]),
        .Q(data3[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[7] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[7]),
        .D(s00_axi_wdata[7]),
        .Q(data3[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[8] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[15]),
        .D(s00_axi_wdata[8]),
        .Q(data2[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg0_reg[9] 
       (.C(s00_axi_aclk),
        .CE(p_1_in[15]),
        .D(s00_axi_wdata[9]),
        .Q(data2[1]),
        .R(axi_awready_i_1_n_0));
  LUT5 #(
    .INIT(32'h02000000)) 
    \slv_reg1[15]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[2]),
        .I2(p_0_in[1]),
        .I3(s00_axi_wstrb[1]),
        .I4(p_0_in[0]),
        .O(\slv_reg1[15]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h02000000)) 
    \slv_reg1[23]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[2]),
        .I2(p_0_in[1]),
        .I3(s00_axi_wstrb[2]),
        .I4(p_0_in[0]),
        .O(\slv_reg1[23]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h02000000)) 
    \slv_reg1[31]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[2]),
        .I2(p_0_in[1]),
        .I3(s00_axi_wstrb[3]),
        .I4(p_0_in[0]),
        .O(\slv_reg1[31]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h02000000)) 
    \slv_reg1[7]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[2]),
        .I2(p_0_in[1]),
        .I3(s00_axi_wstrb[0]),
        .I4(p_0_in[0]),
        .O(\slv_reg1[7]_i_1_n_0 ));
  FDRE \slv_reg1_reg[0] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[7]_i_1_n_0 ),
        .D(s00_axi_wdata[0]),
        .Q(data7[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[10] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[15]_i_1_n_0 ),
        .D(s00_axi_wdata[10]),
        .Q(data6[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[11] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[15]_i_1_n_0 ),
        .D(s00_axi_wdata[11]),
        .Q(data6[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[12] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[15]_i_1_n_0 ),
        .D(s00_axi_wdata[12]),
        .Q(data6[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[13] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[15]_i_1_n_0 ),
        .D(s00_axi_wdata[13]),
        .Q(data6[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[14] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[15]_i_1_n_0 ),
        .D(s00_axi_wdata[14]),
        .Q(data6[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[15] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[15]_i_1_n_0 ),
        .D(s00_axi_wdata[15]),
        .Q(data6[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[16] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[23]_i_1_n_0 ),
        .D(s00_axi_wdata[16]),
        .Q(data5[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[17] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[23]_i_1_n_0 ),
        .D(s00_axi_wdata[17]),
        .Q(data5[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[18] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[23]_i_1_n_0 ),
        .D(s00_axi_wdata[18]),
        .Q(data5[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[19] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[23]_i_1_n_0 ),
        .D(s00_axi_wdata[19]),
        .Q(data5[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[1] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[7]_i_1_n_0 ),
        .D(s00_axi_wdata[1]),
        .Q(data7[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[20] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[23]_i_1_n_0 ),
        .D(s00_axi_wdata[20]),
        .Q(data5[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[21] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[23]_i_1_n_0 ),
        .D(s00_axi_wdata[21]),
        .Q(data5[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[22] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[23]_i_1_n_0 ),
        .D(s00_axi_wdata[22]),
        .Q(data5[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[23] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[23]_i_1_n_0 ),
        .D(s00_axi_wdata[23]),
        .Q(data5[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[24] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[31]_i_1_n_0 ),
        .D(s00_axi_wdata[24]),
        .Q(data4[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[25] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[31]_i_1_n_0 ),
        .D(s00_axi_wdata[25]),
        .Q(data4[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[26] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[31]_i_1_n_0 ),
        .D(s00_axi_wdata[26]),
        .Q(data4[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[27] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[31]_i_1_n_0 ),
        .D(s00_axi_wdata[27]),
        .Q(data4[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[28] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[31]_i_1_n_0 ),
        .D(s00_axi_wdata[28]),
        .Q(data4[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[29] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[31]_i_1_n_0 ),
        .D(s00_axi_wdata[29]),
        .Q(data4[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[2] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[7]_i_1_n_0 ),
        .D(s00_axi_wdata[2]),
        .Q(data7[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[30] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[31]_i_1_n_0 ),
        .D(s00_axi_wdata[30]),
        .Q(data4[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[31] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[31]_i_1_n_0 ),
        .D(s00_axi_wdata[31]),
        .Q(data4[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[3] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[7]_i_1_n_0 ),
        .D(s00_axi_wdata[3]),
        .Q(data7[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[4] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[7]_i_1_n_0 ),
        .D(s00_axi_wdata[4]),
        .Q(data7[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[5] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[7]_i_1_n_0 ),
        .D(s00_axi_wdata[5]),
        .Q(data7[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[6] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[7]_i_1_n_0 ),
        .D(s00_axi_wdata[6]),
        .Q(data7[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[7] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[7]_i_1_n_0 ),
        .D(s00_axi_wdata[7]),
        .Q(data7[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[8] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[15]_i_1_n_0 ),
        .D(s00_axi_wdata[8]),
        .Q(data6[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg1_reg[9] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg1[15]_i_1_n_0 ),
        .D(s00_axi_wdata[9]),
        .Q(data6[1]),
        .R(axi_awready_i_1_n_0));
  LUT5 #(
    .INIT(32'h02000000)) 
    \slv_reg2[15]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[2]),
        .I2(p_0_in[0]),
        .I3(s00_axi_wstrb[1]),
        .I4(p_0_in[1]),
        .O(\slv_reg2[15]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h02000000)) 
    \slv_reg2[23]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[2]),
        .I2(p_0_in[0]),
        .I3(s00_axi_wstrb[2]),
        .I4(p_0_in[1]),
        .O(\slv_reg2[23]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h02000000)) 
    \slv_reg2[31]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[2]),
        .I2(p_0_in[0]),
        .I3(s00_axi_wstrb[3]),
        .I4(p_0_in[1]),
        .O(\slv_reg2[31]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h02000000)) 
    \slv_reg2[7]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[2]),
        .I2(p_0_in[0]),
        .I3(s00_axi_wstrb[0]),
        .I4(p_0_in[1]),
        .O(\slv_reg2[7]_i_1_n_0 ));
  FDRE \slv_reg2_reg[0] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[7]_i_1_n_0 ),
        .D(s00_axi_wdata[0]),
        .Q(data11[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[10] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[15]_i_1_n_0 ),
        .D(s00_axi_wdata[10]),
        .Q(data10[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[11] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[15]_i_1_n_0 ),
        .D(s00_axi_wdata[11]),
        .Q(data10[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[12] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[15]_i_1_n_0 ),
        .D(s00_axi_wdata[12]),
        .Q(data10[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[13] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[15]_i_1_n_0 ),
        .D(s00_axi_wdata[13]),
        .Q(data10[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[14] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[15]_i_1_n_0 ),
        .D(s00_axi_wdata[14]),
        .Q(data10[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[15] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[15]_i_1_n_0 ),
        .D(s00_axi_wdata[15]),
        .Q(data10[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[16] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[23]_i_1_n_0 ),
        .D(s00_axi_wdata[16]),
        .Q(data9[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[17] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[23]_i_1_n_0 ),
        .D(s00_axi_wdata[17]),
        .Q(data9[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[18] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[23]_i_1_n_0 ),
        .D(s00_axi_wdata[18]),
        .Q(data9[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[19] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[23]_i_1_n_0 ),
        .D(s00_axi_wdata[19]),
        .Q(data9[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[1] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[7]_i_1_n_0 ),
        .D(s00_axi_wdata[1]),
        .Q(data11[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[20] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[23]_i_1_n_0 ),
        .D(s00_axi_wdata[20]),
        .Q(data9[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[21] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[23]_i_1_n_0 ),
        .D(s00_axi_wdata[21]),
        .Q(data9[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[22] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[23]_i_1_n_0 ),
        .D(s00_axi_wdata[22]),
        .Q(data9[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[23] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[23]_i_1_n_0 ),
        .D(s00_axi_wdata[23]),
        .Q(data9[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[24] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[31]_i_1_n_0 ),
        .D(s00_axi_wdata[24]),
        .Q(data8[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[25] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[31]_i_1_n_0 ),
        .D(s00_axi_wdata[25]),
        .Q(data8[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[26] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[31]_i_1_n_0 ),
        .D(s00_axi_wdata[26]),
        .Q(data8[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[27] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[31]_i_1_n_0 ),
        .D(s00_axi_wdata[27]),
        .Q(data8[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[28] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[31]_i_1_n_0 ),
        .D(s00_axi_wdata[28]),
        .Q(data8[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[29] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[31]_i_1_n_0 ),
        .D(s00_axi_wdata[29]),
        .Q(data8[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[2] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[7]_i_1_n_0 ),
        .D(s00_axi_wdata[2]),
        .Q(data11[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[30] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[31]_i_1_n_0 ),
        .D(s00_axi_wdata[30]),
        .Q(data8[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[31] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[31]_i_1_n_0 ),
        .D(s00_axi_wdata[31]),
        .Q(data8[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[3] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[7]_i_1_n_0 ),
        .D(s00_axi_wdata[3]),
        .Q(data11[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[4] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[7]_i_1_n_0 ),
        .D(s00_axi_wdata[4]),
        .Q(data11[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[5] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[7]_i_1_n_0 ),
        .D(s00_axi_wdata[5]),
        .Q(data11[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[6] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[7]_i_1_n_0 ),
        .D(s00_axi_wdata[6]),
        .Q(data11[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[7] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[7]_i_1_n_0 ),
        .D(s00_axi_wdata[7]),
        .Q(data11[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[8] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[15]_i_1_n_0 ),
        .D(s00_axi_wdata[8]),
        .Q(data10[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg2_reg[9] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg2[15]_i_1_n_0 ),
        .D(s00_axi_wdata[9]),
        .Q(data10[1]),
        .R(axi_awready_i_1_n_0));
  LUT5 #(
    .INIT(32'h20000000)) 
    \slv_reg3[15]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[2]),
        .I2(p_0_in[1]),
        .I3(p_0_in[0]),
        .I4(s00_axi_wstrb[1]),
        .O(\slv_reg3[15]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h20000000)) 
    \slv_reg3[23]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[2]),
        .I2(p_0_in[1]),
        .I3(p_0_in[0]),
        .I4(s00_axi_wstrb[2]),
        .O(\slv_reg3[23]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h20000000)) 
    \slv_reg3[31]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[2]),
        .I2(p_0_in[1]),
        .I3(p_0_in[0]),
        .I4(s00_axi_wstrb[3]),
        .O(\slv_reg3[31]_i_1_n_0 ));
  LUT4 #(
    .INIT(16'h8000)) 
    \slv_reg3[31]_i_2 
       (.I0(S_AXI_WREADY),
        .I1(S_AXI_AWREADY),
        .I2(s00_axi_awvalid),
        .I3(s00_axi_wvalid),
        .O(slv_reg_wren__0));
  LUT5 #(
    .INIT(32'h20000000)) 
    \slv_reg3[7]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[2]),
        .I2(p_0_in[1]),
        .I3(p_0_in[0]),
        .I4(s00_axi_wstrb[0]),
        .O(\slv_reg3[7]_i_1_n_0 ));
  FDRE \slv_reg3_reg[0] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[7]_i_1_n_0 ),
        .D(s00_axi_wdata[0]),
        .Q(p_12_in[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[10] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[15]_i_1_n_0 ),
        .D(s00_axi_wdata[10]),
        .Q(data14[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[11] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[15]_i_1_n_0 ),
        .D(s00_axi_wdata[11]),
        .Q(data14[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[12] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[15]_i_1_n_0 ),
        .D(s00_axi_wdata[12]),
        .Q(data14[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[13] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[15]_i_1_n_0 ),
        .D(s00_axi_wdata[13]),
        .Q(data14[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[14] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[15]_i_1_n_0 ),
        .D(s00_axi_wdata[14]),
        .Q(data14[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[15] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[15]_i_1_n_0 ),
        .D(s00_axi_wdata[15]),
        .Q(data14[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[16] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[23]_i_1_n_0 ),
        .D(s00_axi_wdata[16]),
        .Q(data13[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[17] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[23]_i_1_n_0 ),
        .D(s00_axi_wdata[17]),
        .Q(data13[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[18] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[23]_i_1_n_0 ),
        .D(s00_axi_wdata[18]),
        .Q(data13[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[19] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[23]_i_1_n_0 ),
        .D(s00_axi_wdata[19]),
        .Q(data13[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[1] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[7]_i_1_n_0 ),
        .D(s00_axi_wdata[1]),
        .Q(p_12_in[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[20] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[23]_i_1_n_0 ),
        .D(s00_axi_wdata[20]),
        .Q(data13[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[21] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[23]_i_1_n_0 ),
        .D(s00_axi_wdata[21]),
        .Q(data13[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[22] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[23]_i_1_n_0 ),
        .D(s00_axi_wdata[22]),
        .Q(data13[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[23] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[23]_i_1_n_0 ),
        .D(s00_axi_wdata[23]),
        .Q(data13[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[24] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[31]_i_1_n_0 ),
        .D(s00_axi_wdata[24]),
        .Q(data12[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[25] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[31]_i_1_n_0 ),
        .D(s00_axi_wdata[25]),
        .Q(data12[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[26] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[31]_i_1_n_0 ),
        .D(s00_axi_wdata[26]),
        .Q(data12[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[27] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[31]_i_1_n_0 ),
        .D(s00_axi_wdata[27]),
        .Q(data12[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[28] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[31]_i_1_n_0 ),
        .D(s00_axi_wdata[28]),
        .Q(data12[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[29] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[31]_i_1_n_0 ),
        .D(s00_axi_wdata[29]),
        .Q(data12[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[2] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[7]_i_1_n_0 ),
        .D(s00_axi_wdata[2]),
        .Q(p_12_in[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[30] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[31]_i_1_n_0 ),
        .D(s00_axi_wdata[30]),
        .Q(data12[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[31] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[31]_i_1_n_0 ),
        .D(s00_axi_wdata[31]),
        .Q(data12[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[3] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[7]_i_1_n_0 ),
        .D(s00_axi_wdata[3]),
        .Q(p_12_in[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[4] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[7]_i_1_n_0 ),
        .D(s00_axi_wdata[4]),
        .Q(p_12_in[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[5] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[7]_i_1_n_0 ),
        .D(s00_axi_wdata[5]),
        .Q(p_12_in[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[6] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[7]_i_1_n_0 ),
        .D(s00_axi_wdata[6]),
        .Q(p_12_in[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[7] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[7]_i_1_n_0 ),
        .D(s00_axi_wdata[7]),
        .Q(p_12_in[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[8] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[15]_i_1_n_0 ),
        .D(s00_axi_wdata[8]),
        .Q(data14[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg3_reg[9] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg3[15]_i_1_n_0 ),
        .D(s00_axi_wdata[9]),
        .Q(data14[1]),
        .R(axi_awready_i_1_n_0));
  LUT5 #(
    .INIT(32'h02000000)) 
    \slv_reg4[15]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[1]),
        .I2(p_0_in[0]),
        .I3(p_0_in[2]),
        .I4(s00_axi_wstrb[1]),
        .O(\slv_reg4[15]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h02000000)) 
    \slv_reg4[23]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[1]),
        .I2(p_0_in[0]),
        .I3(p_0_in[2]),
        .I4(s00_axi_wstrb[2]),
        .O(\slv_reg4[23]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h02000000)) 
    \slv_reg4[31]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[1]),
        .I2(p_0_in[0]),
        .I3(p_0_in[2]),
        .I4(s00_axi_wstrb[3]),
        .O(\slv_reg4[31]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h02000000)) 
    \slv_reg4[7]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[1]),
        .I2(p_0_in[0]),
        .I3(p_0_in[2]),
        .I4(s00_axi_wstrb[0]),
        .O(\slv_reg4[7]_i_1_n_0 ));
  FDRE \slv_reg4_reg[0] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[7]_i_1_n_0 ),
        .D(s00_axi_wdata[0]),
        .Q(slv_reg4[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[10] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[15]_i_1_n_0 ),
        .D(s00_axi_wdata[10]),
        .Q(slv_reg4[10]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[11] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[15]_i_1_n_0 ),
        .D(s00_axi_wdata[11]),
        .Q(slv_reg4[11]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[12] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[15]_i_1_n_0 ),
        .D(s00_axi_wdata[12]),
        .Q(slv_reg4[12]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[13] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[15]_i_1_n_0 ),
        .D(s00_axi_wdata[13]),
        .Q(slv_reg4[13]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[14] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[15]_i_1_n_0 ),
        .D(s00_axi_wdata[14]),
        .Q(slv_reg4[14]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[15] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[15]_i_1_n_0 ),
        .D(s00_axi_wdata[15]),
        .Q(slv_reg4[15]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[16] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[23]_i_1_n_0 ),
        .D(s00_axi_wdata[16]),
        .Q(slv_reg4[16]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[17] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[23]_i_1_n_0 ),
        .D(s00_axi_wdata[17]),
        .Q(slv_reg4[17]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[18] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[23]_i_1_n_0 ),
        .D(s00_axi_wdata[18]),
        .Q(slv_reg4[18]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[19] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[23]_i_1_n_0 ),
        .D(s00_axi_wdata[19]),
        .Q(slv_reg4[19]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[1] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[7]_i_1_n_0 ),
        .D(s00_axi_wdata[1]),
        .Q(slv_reg4[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[20] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[23]_i_1_n_0 ),
        .D(s00_axi_wdata[20]),
        .Q(slv_reg4[20]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[21] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[23]_i_1_n_0 ),
        .D(s00_axi_wdata[21]),
        .Q(slv_reg4[21]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[22] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[23]_i_1_n_0 ),
        .D(s00_axi_wdata[22]),
        .Q(slv_reg4[22]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[23] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[23]_i_1_n_0 ),
        .D(s00_axi_wdata[23]),
        .Q(slv_reg4[23]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[24] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[31]_i_1_n_0 ),
        .D(s00_axi_wdata[24]),
        .Q(slv_reg4[24]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[25] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[31]_i_1_n_0 ),
        .D(s00_axi_wdata[25]),
        .Q(slv_reg4[25]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[26] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[31]_i_1_n_0 ),
        .D(s00_axi_wdata[26]),
        .Q(slv_reg4[26]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[27] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[31]_i_1_n_0 ),
        .D(s00_axi_wdata[27]),
        .Q(slv_reg4[27]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[28] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[31]_i_1_n_0 ),
        .D(s00_axi_wdata[28]),
        .Q(slv_reg4[28]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[29] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[31]_i_1_n_0 ),
        .D(s00_axi_wdata[29]),
        .Q(slv_reg4[29]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[2] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[7]_i_1_n_0 ),
        .D(s00_axi_wdata[2]),
        .Q(slv_reg4[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[30] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[31]_i_1_n_0 ),
        .D(s00_axi_wdata[30]),
        .Q(slv_reg4[30]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[31] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[31]_i_1_n_0 ),
        .D(s00_axi_wdata[31]),
        .Q(slv_reg4[31]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[3] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[7]_i_1_n_0 ),
        .D(s00_axi_wdata[3]),
        .Q(slv_reg4[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[4] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[7]_i_1_n_0 ),
        .D(s00_axi_wdata[4]),
        .Q(slv_reg4[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[5] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[7]_i_1_n_0 ),
        .D(s00_axi_wdata[5]),
        .Q(slv_reg4[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[6] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[7]_i_1_n_0 ),
        .D(s00_axi_wdata[6]),
        .Q(slv_reg4[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[7] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[7]_i_1_n_0 ),
        .D(s00_axi_wdata[7]),
        .Q(slv_reg4[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[8] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[15]_i_1_n_0 ),
        .D(s00_axi_wdata[8]),
        .Q(slv_reg4[8]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg4_reg[9] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg4[15]_i_1_n_0 ),
        .D(s00_axi_wdata[9]),
        .Q(slv_reg4[9]),
        .R(axi_awready_i_1_n_0));
  LUT5 #(
    .INIT(32'h20000000)) 
    \slv_reg5[15]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[1]),
        .I2(s00_axi_wstrb[1]),
        .I3(p_0_in[0]),
        .I4(p_0_in[2]),
        .O(\slv_reg5[15]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h20000000)) 
    \slv_reg5[23]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[1]),
        .I2(s00_axi_wstrb[2]),
        .I3(p_0_in[0]),
        .I4(p_0_in[2]),
        .O(\slv_reg5[23]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h20000000)) 
    \slv_reg5[31]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[1]),
        .I2(s00_axi_wstrb[3]),
        .I3(p_0_in[0]),
        .I4(p_0_in[2]),
        .O(\slv_reg5[31]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h20000000)) 
    \slv_reg5[7]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[1]),
        .I2(s00_axi_wstrb[0]),
        .I3(p_0_in[0]),
        .I4(p_0_in[2]),
        .O(\slv_reg5[7]_i_1_n_0 ));
  FDRE \slv_reg5_reg[0] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[7]_i_1_n_0 ),
        .D(s00_axi_wdata[0]),
        .Q(slv_reg5[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[10] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[15]_i_1_n_0 ),
        .D(s00_axi_wdata[10]),
        .Q(slv_reg5[10]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[11] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[15]_i_1_n_0 ),
        .D(s00_axi_wdata[11]),
        .Q(slv_reg5[11]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[12] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[15]_i_1_n_0 ),
        .D(s00_axi_wdata[12]),
        .Q(slv_reg5[12]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[13] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[15]_i_1_n_0 ),
        .D(s00_axi_wdata[13]),
        .Q(slv_reg5[13]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[14] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[15]_i_1_n_0 ),
        .D(s00_axi_wdata[14]),
        .Q(slv_reg5[14]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[15] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[15]_i_1_n_0 ),
        .D(s00_axi_wdata[15]),
        .Q(slv_reg5[15]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[16] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[23]_i_1_n_0 ),
        .D(s00_axi_wdata[16]),
        .Q(slv_reg5[16]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[17] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[23]_i_1_n_0 ),
        .D(s00_axi_wdata[17]),
        .Q(slv_reg5[17]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[18] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[23]_i_1_n_0 ),
        .D(s00_axi_wdata[18]),
        .Q(slv_reg5[18]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[19] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[23]_i_1_n_0 ),
        .D(s00_axi_wdata[19]),
        .Q(slv_reg5[19]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[1] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[7]_i_1_n_0 ),
        .D(s00_axi_wdata[1]),
        .Q(slv_reg5[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[20] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[23]_i_1_n_0 ),
        .D(s00_axi_wdata[20]),
        .Q(slv_reg5[20]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[21] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[23]_i_1_n_0 ),
        .D(s00_axi_wdata[21]),
        .Q(slv_reg5[21]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[22] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[23]_i_1_n_0 ),
        .D(s00_axi_wdata[22]),
        .Q(slv_reg5[22]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[23] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[23]_i_1_n_0 ),
        .D(s00_axi_wdata[23]),
        .Q(slv_reg5[23]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[24] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[31]_i_1_n_0 ),
        .D(s00_axi_wdata[24]),
        .Q(slv_reg5[24]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[25] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[31]_i_1_n_0 ),
        .D(s00_axi_wdata[25]),
        .Q(slv_reg5[25]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[26] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[31]_i_1_n_0 ),
        .D(s00_axi_wdata[26]),
        .Q(slv_reg5[26]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[27] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[31]_i_1_n_0 ),
        .D(s00_axi_wdata[27]),
        .Q(slv_reg5[27]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[28] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[31]_i_1_n_0 ),
        .D(s00_axi_wdata[28]),
        .Q(slv_reg5[28]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[29] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[31]_i_1_n_0 ),
        .D(s00_axi_wdata[29]),
        .Q(slv_reg5[29]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[2] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[7]_i_1_n_0 ),
        .D(s00_axi_wdata[2]),
        .Q(slv_reg5[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[30] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[31]_i_1_n_0 ),
        .D(s00_axi_wdata[30]),
        .Q(slv_reg5[30]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[31] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[31]_i_1_n_0 ),
        .D(s00_axi_wdata[31]),
        .Q(slv_reg5[31]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[3] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[7]_i_1_n_0 ),
        .D(s00_axi_wdata[3]),
        .Q(slv_reg5[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[4] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[7]_i_1_n_0 ),
        .D(s00_axi_wdata[4]),
        .Q(slv_reg5[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[5] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[7]_i_1_n_0 ),
        .D(s00_axi_wdata[5]),
        .Q(slv_reg5[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[6] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[7]_i_1_n_0 ),
        .D(s00_axi_wdata[6]),
        .Q(slv_reg5[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[7] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[7]_i_1_n_0 ),
        .D(s00_axi_wdata[7]),
        .Q(slv_reg5[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[8] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[15]_i_1_n_0 ),
        .D(s00_axi_wdata[8]),
        .Q(slv_reg5[8]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg5_reg[9] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg5[15]_i_1_n_0 ),
        .D(s00_axi_wdata[9]),
        .Q(slv_reg5[9]),
        .R(axi_awready_i_1_n_0));
  LUT5 #(
    .INIT(32'h20000000)) 
    \slv_reg6[15]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[0]),
        .I2(p_0_in[1]),
        .I3(s00_axi_wstrb[1]),
        .I4(p_0_in[2]),
        .O(\slv_reg6[15]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h20000000)) 
    \slv_reg6[23]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[0]),
        .I2(p_0_in[1]),
        .I3(s00_axi_wstrb[2]),
        .I4(p_0_in[2]),
        .O(\slv_reg6[23]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h20000000)) 
    \slv_reg6[31]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[0]),
        .I2(p_0_in[1]),
        .I3(s00_axi_wstrb[3]),
        .I4(p_0_in[2]),
        .O(\slv_reg6[31]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h20000000)) 
    \slv_reg6[7]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[0]),
        .I2(p_0_in[1]),
        .I3(s00_axi_wstrb[0]),
        .I4(p_0_in[2]),
        .O(\slv_reg6[7]_i_1_n_0 ));
  FDRE \slv_reg6_reg[0] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[7]_i_1_n_0 ),
        .D(s00_axi_wdata[0]),
        .Q(slv_reg6[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[10] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[15]_i_1_n_0 ),
        .D(s00_axi_wdata[10]),
        .Q(slv_reg6[10]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[11] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[15]_i_1_n_0 ),
        .D(s00_axi_wdata[11]),
        .Q(slv_reg6[11]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[12] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[15]_i_1_n_0 ),
        .D(s00_axi_wdata[12]),
        .Q(slv_reg6[12]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[13] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[15]_i_1_n_0 ),
        .D(s00_axi_wdata[13]),
        .Q(slv_reg6[13]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[14] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[15]_i_1_n_0 ),
        .D(s00_axi_wdata[14]),
        .Q(slv_reg6[14]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[15] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[15]_i_1_n_0 ),
        .D(s00_axi_wdata[15]),
        .Q(slv_reg6[15]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[16] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[23]_i_1_n_0 ),
        .D(s00_axi_wdata[16]),
        .Q(slv_reg6[16]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[17] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[23]_i_1_n_0 ),
        .D(s00_axi_wdata[17]),
        .Q(slv_reg6[17]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[18] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[23]_i_1_n_0 ),
        .D(s00_axi_wdata[18]),
        .Q(slv_reg6[18]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[19] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[23]_i_1_n_0 ),
        .D(s00_axi_wdata[19]),
        .Q(slv_reg6[19]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[1] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[7]_i_1_n_0 ),
        .D(s00_axi_wdata[1]),
        .Q(slv_reg6[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[20] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[23]_i_1_n_0 ),
        .D(s00_axi_wdata[20]),
        .Q(slv_reg6[20]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[21] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[23]_i_1_n_0 ),
        .D(s00_axi_wdata[21]),
        .Q(slv_reg6[21]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[22] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[23]_i_1_n_0 ),
        .D(s00_axi_wdata[22]),
        .Q(slv_reg6[22]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[23] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[23]_i_1_n_0 ),
        .D(s00_axi_wdata[23]),
        .Q(slv_reg6[23]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[24] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[31]_i_1_n_0 ),
        .D(s00_axi_wdata[24]),
        .Q(slv_reg6[24]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[25] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[31]_i_1_n_0 ),
        .D(s00_axi_wdata[25]),
        .Q(slv_reg6[25]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[26] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[31]_i_1_n_0 ),
        .D(s00_axi_wdata[26]),
        .Q(slv_reg6[26]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[27] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[31]_i_1_n_0 ),
        .D(s00_axi_wdata[27]),
        .Q(slv_reg6[27]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[28] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[31]_i_1_n_0 ),
        .D(s00_axi_wdata[28]),
        .Q(slv_reg6[28]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[29] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[31]_i_1_n_0 ),
        .D(s00_axi_wdata[29]),
        .Q(slv_reg6[29]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[2] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[7]_i_1_n_0 ),
        .D(s00_axi_wdata[2]),
        .Q(slv_reg6[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[30] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[31]_i_1_n_0 ),
        .D(s00_axi_wdata[30]),
        .Q(slv_reg6[30]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[31] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[31]_i_1_n_0 ),
        .D(s00_axi_wdata[31]),
        .Q(slv_reg6[31]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[3] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[7]_i_1_n_0 ),
        .D(s00_axi_wdata[3]),
        .Q(slv_reg6[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[4] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[7]_i_1_n_0 ),
        .D(s00_axi_wdata[4]),
        .Q(slv_reg6[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[5] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[7]_i_1_n_0 ),
        .D(s00_axi_wdata[5]),
        .Q(slv_reg6[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[6] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[7]_i_1_n_0 ),
        .D(s00_axi_wdata[6]),
        .Q(slv_reg6[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[7] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[7]_i_1_n_0 ),
        .D(s00_axi_wdata[7]),
        .Q(slv_reg6[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[8] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[15]_i_1_n_0 ),
        .D(s00_axi_wdata[8]),
        .Q(slv_reg6[8]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg6_reg[9] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg6[15]_i_1_n_0 ),
        .D(s00_axi_wdata[9]),
        .Q(slv_reg6[9]),
        .R(axi_awready_i_1_n_0));
  LUT5 #(
    .INIT(32'h80000000)) 
    \slv_reg7[15]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[1]),
        .I2(p_0_in[0]),
        .I3(p_0_in[2]),
        .I4(s00_axi_wstrb[1]),
        .O(\slv_reg7[15]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h80000000)) 
    \slv_reg7[23]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[1]),
        .I2(p_0_in[0]),
        .I3(p_0_in[2]),
        .I4(s00_axi_wstrb[2]),
        .O(\slv_reg7[23]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h80000000)) 
    \slv_reg7[31]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[1]),
        .I2(p_0_in[0]),
        .I3(p_0_in[2]),
        .I4(s00_axi_wstrb[3]),
        .O(\slv_reg7[31]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h80000000)) 
    \slv_reg7[7]_i_1 
       (.I0(slv_reg_wren__0),
        .I1(p_0_in[1]),
        .I2(p_0_in[0]),
        .I3(p_0_in[2]),
        .I4(s00_axi_wstrb[0]),
        .O(\slv_reg7[7]_i_1_n_0 ));
  FDRE \slv_reg7_reg[0] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[7]_i_1_n_0 ),
        .D(s00_axi_wdata[0]),
        .Q(data15[0]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[10] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[15]_i_1_n_0 ),
        .D(s00_axi_wdata[10]),
        .Q(\slv_reg7_reg_n_0_[10] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[11] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[15]_i_1_n_0 ),
        .D(s00_axi_wdata[11]),
        .Q(\slv_reg7_reg_n_0_[11] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[12] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[15]_i_1_n_0 ),
        .D(s00_axi_wdata[12]),
        .Q(\slv_reg7_reg_n_0_[12] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[13] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[15]_i_1_n_0 ),
        .D(s00_axi_wdata[13]),
        .Q(\slv_reg7_reg_n_0_[13] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[14] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[15]_i_1_n_0 ),
        .D(s00_axi_wdata[14]),
        .Q(\slv_reg7_reg_n_0_[14] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[15] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[15]_i_1_n_0 ),
        .D(s00_axi_wdata[15]),
        .Q(\slv_reg7_reg_n_0_[15] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[16] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[23]_i_1_n_0 ),
        .D(s00_axi_wdata[16]),
        .Q(\slv_reg7_reg_n_0_[16] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[17] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[23]_i_1_n_0 ),
        .D(s00_axi_wdata[17]),
        .Q(\slv_reg7_reg_n_0_[17] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[18] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[23]_i_1_n_0 ),
        .D(s00_axi_wdata[18]),
        .Q(\slv_reg7_reg_n_0_[18] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[19] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[23]_i_1_n_0 ),
        .D(s00_axi_wdata[19]),
        .Q(\slv_reg7_reg_n_0_[19] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[1] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[7]_i_1_n_0 ),
        .D(s00_axi_wdata[1]),
        .Q(data15[1]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[20] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[23]_i_1_n_0 ),
        .D(s00_axi_wdata[20]),
        .Q(\slv_reg7_reg_n_0_[20] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[21] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[23]_i_1_n_0 ),
        .D(s00_axi_wdata[21]),
        .Q(\slv_reg7_reg_n_0_[21] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[22] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[23]_i_1_n_0 ),
        .D(s00_axi_wdata[22]),
        .Q(\slv_reg7_reg_n_0_[22] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[23] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[23]_i_1_n_0 ),
        .D(s00_axi_wdata[23]),
        .Q(\slv_reg7_reg_n_0_[23] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[24] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[31]_i_1_n_0 ),
        .D(s00_axi_wdata[24]),
        .Q(\slv_reg7_reg_n_0_[24] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[25] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[31]_i_1_n_0 ),
        .D(s00_axi_wdata[25]),
        .Q(\slv_reg7_reg_n_0_[25] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[26] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[31]_i_1_n_0 ),
        .D(s00_axi_wdata[26]),
        .Q(\slv_reg7_reg_n_0_[26] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[27] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[31]_i_1_n_0 ),
        .D(s00_axi_wdata[27]),
        .Q(\slv_reg7_reg_n_0_[27] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[28] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[31]_i_1_n_0 ),
        .D(s00_axi_wdata[28]),
        .Q(\slv_reg7_reg_n_0_[28] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[29] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[31]_i_1_n_0 ),
        .D(s00_axi_wdata[29]),
        .Q(\slv_reg7_reg_n_0_[29] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[2] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[7]_i_1_n_0 ),
        .D(s00_axi_wdata[2]),
        .Q(data15[2]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[30] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[31]_i_1_n_0 ),
        .D(s00_axi_wdata[30]),
        .Q(\slv_reg7_reg_n_0_[30] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[31] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[31]_i_1_n_0 ),
        .D(s00_axi_wdata[31]),
        .Q(\slv_reg7_reg_n_0_[31] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[3] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[7]_i_1_n_0 ),
        .D(s00_axi_wdata[3]),
        .Q(data15[3]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[4] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[7]_i_1_n_0 ),
        .D(s00_axi_wdata[4]),
        .Q(data15[4]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[5] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[7]_i_1_n_0 ),
        .D(s00_axi_wdata[5]),
        .Q(data15[5]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[6] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[7]_i_1_n_0 ),
        .D(s00_axi_wdata[6]),
        .Q(data15[6]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[7] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[7]_i_1_n_0 ),
        .D(s00_axi_wdata[7]),
        .Q(data15[7]),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[8] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[15]_i_1_n_0 ),
        .D(s00_axi_wdata[8]),
        .Q(\slv_reg7_reg_n_0_[8] ),
        .R(axi_awready_i_1_n_0));
  FDRE \slv_reg7_reg[9] 
       (.C(s00_axi_aclk),
        .CE(\slv_reg7[15]_i_1_n_0 ),
        .D(s00_axi_wdata[9]),
        .Q(\slv_reg7_reg_n_0_[9] ),
        .R(axi_awready_i_1_n_0));
  LUT3 #(
    .INIT(8'h20)) 
    slv_reg_rden
       (.I0(s00_axi_arvalid),
        .I1(s00_axi_rvalid),
        .I2(S_AXI_ARREADY),
        .O(slv_reg_rden__0));
  decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_textlcd textlcd_1
       (.Q({\slv_reg7_reg_n_0_[31] ,\slv_reg7_reg_n_0_[30] ,\slv_reg7_reg_n_0_[29] ,\slv_reg7_reg_n_0_[28] ,\slv_reg7_reg_n_0_[27] ,\slv_reg7_reg_n_0_[26] ,\slv_reg7_reg_n_0_[25] ,\slv_reg7_reg_n_0_[24] ,\slv_reg7_reg_n_0_[23] ,\slv_reg7_reg_n_0_[22] ,\slv_reg7_reg_n_0_[21] ,\slv_reg7_reg_n_0_[20] ,\slv_reg7_reg_n_0_[19] ,\slv_reg7_reg_n_0_[18] ,\slv_reg7_reg_n_0_[17] ,\slv_reg7_reg_n_0_[16] ,\slv_reg7_reg_n_0_[15] ,\slv_reg7_reg_n_0_[14] ,\slv_reg7_reg_n_0_[13] ,\slv_reg7_reg_n_0_[12] ,\slv_reg7_reg_n_0_[11] ,\slv_reg7_reg_n_0_[10] ,\slv_reg7_reg_n_0_[9] ,\slv_reg7_reg_n_0_[8] ,data15}),
        .lcd_data(lcd_data),
        .\lcd_data[7]_INST_0_i_3_0 ({data12,data13,data14,p_12_in}),
        .\lcd_data[7]_INST_0_i_4_0 ({data8,data9,data10,data11}),
        .\lcd_data[7]_INST_0_i_4_1 ({data4,data5,data6,data7}),
        .\lcd_data[7]_INST_0_i_4_2 ({\slv_reg0_reg_n_0_[31] ,\slv_reg0_reg_n_0_[30] ,\slv_reg0_reg_n_0_[29] ,\slv_reg0_reg_n_0_[28] ,\slv_reg0_reg_n_0_[27] ,\slv_reg0_reg_n_0_[26] ,\slv_reg0_reg_n_0_[25] ,\slv_reg0_reg_n_0_[24] ,data1,data2,data3}),
        .\lcd_data[7]_INST_0_i_5_0 (slv_reg6),
        .\lcd_data[7]_INST_0_i_6_0 (slv_reg5),
        .\lcd_data[7]_INST_0_i_6_1 (slv_reg4),
        .lcd_en(lcd_en),
        .lcd_rs(lcd_rs),
        .lcdclk(lcdclk),
        .resetn(resetn));
endmodule
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

endmodule
`endif
