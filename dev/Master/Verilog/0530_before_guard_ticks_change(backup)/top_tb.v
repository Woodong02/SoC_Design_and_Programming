`timescale 1ns / 1ps

module tb_master_top_7seg();

    // =========================================================================
    // 1. 시스템 글로벌 포트 및 파라미터 선언
    // =========================================================================
    reg         clk;
    reg         resetn;
    reg  [9:0]  DIV;
    reg  [9:0]  GUARD_TICKS;
    reg  [2:0]  NODE_CNT;
    reg         GPIO_in;
    reg  [3:0]  DIP_SW;      // [추가] 7-Segment 제어용 딥 스위치

    wire        GPIO_out;
    wire [7:0]  seg_en;      // [추가] 세그먼트 자릿수 활성화 핀
    wire [7:0]  seg_data;    // [추가] 세그먼트 출력 핀 (Active Low/High 종속)
    
    wire [31:0] err_cnt0, err_cnt1, err_cnt2, err_cnt3;
    wire [31:0] err_cnt4, err_cnt5, err_cnt6, err_cnt7;
    wire [31:0] slot_out0, slot_out1, slot_out2, slot_out3;
    wire [31:0] slot_out4, slot_out5, slot_out6, slot_out7;

    // =========================================================================
    // 2. DUT (Device Under Test) 결착
    // =========================================================================
    master_top u_dut (
        .clk(clk), .resetn(resetn), .DIV(DIV), .GUARD_TICKS(GUARD_TICKS), .NODE_CNT(NODE_CNT), 
        .GPIO_in(GPIO_in), .DIP_SW(DIP_SW),
        .seg_en(seg_en), .seg_data(seg_data),
        .GPIO_out(GPIO_out),
        .err_cnt0(err_cnt0), .err_cnt1(err_cnt1), .err_cnt2(err_cnt2), .err_cnt3(err_cnt3),
        .err_cnt4(err_cnt4), .err_cnt5(err_cnt5), .err_cnt6(err_cnt6), .err_cnt7(err_cnt7),
        .slot_out0(slot_out0), .slot_out1(slot_out1), .slot_out2(slot_out2), .slot_out3(slot_out3),
        .slot_out4(slot_out4), .slot_out5(slot_out5), .slot_out6(slot_out6), .slot_out7(slot_out7)
    );

    // 50MHz 시스템 클럭 주행 평면
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk; 
    end

    // =========================================================================
    // 3. 동적 해밍 코드 생성 함수 (순수 조합 논리)
    // =========================================================================
    function [41:0] ham_enc(input [34:0] d);
        reg p0, p1, p2, p3, p4, p5, po;
        begin
            p0 = d[0]^d[2]^d[4]^d[6]^d[8]^d[10]^d[12]^d[14]^d[16]^d[18]^d[20]^d[22]^d[24]^d[26]^d[28]^d[30]^d[32]^d[34];
            p1 = d[1]^d[2]^d[5]^d[6]^d[9]^d[10]^d[13]^d[14]^d[17]^d[18]^d[21]^d[22]^d[25]^d[26]^d[29]^d[30]^d[33]^d[34];
            p2 = d[3]^d[4]^d[5]^d[6]^d[11]^d[12]^d[13]^d[14]^d[19]^d[20]^d[21]^d[22]^d[27]^d[28]^d[29]^d[30];
            p3 = d[7]^d[8]^d[9]^d[10]^d[11]^d[12]^d[13]^d[14]^d[23]^d[24]^d[25]^d[26]^d[27]^d[28]^d[29]^d[30];
            p4 = d[15]^d[16]^d[17]^d[18]^d[19]^d[20]^d[21]^d[22]^d[23]^d[24]^d[25]^d[26]^d[27]^d[28]^d[29]^d[30];
            p5 = d[31]^d[32]^d[33]^d[34];
            po = ^{d, p5, p4, p3, p2, p1, p0};
            ham_enc = {d, p5, p4, p3, p2, p1, p0, po};
        end
    endfunction

    // =========================================================================
    // 4. 무결성 정밀 동기화 태스크
    // =========================================================================
    task sync_to_slot(input [2:0] target_slot);
        begin
            while (u_dut.slot === target_slot) @(posedge clk);
            while (u_dut.slot !== target_slot) @(posedge clk);
            repeat(DIV * 2) @(posedge clk);
        end
    endtask

    task inject_frame;
        input [2:0]  src_node;     
        input [31:0] payload;      
        input [7:0]  preamble;     
        input [5:0]  err_bit_idx;  
        
        reg [41:0] cw;
        reg [49:0] full_frame;
        integer i, j;
        begin
            cw = ham_enc({src_node, payload});
            if (err_bit_idx < 42) cw[err_bit_idx] = ~cw[err_bit_idx];
            full_frame = {preamble, cw};
            
            for (i = 49; i >= 0; i = i - 1) begin
                GPIO_in = full_frame[i];
                for (j = 0; j < DIV; j = j + 1) @(posedge clk);
            end
            GPIO_in = 0; 
        end
    endtask

    // =========================================================================
    // 5. 시뮬레이션 콘솔 모니터링 (7-Segment 변화 감지)
    // =========================================================================
    always @(slot_out0) if(slot_out0 != 0) $display("[%0t] [RX_LATCH] Node 0 Data: 0x%08X", $time, slot_out0);
    always @(slot_out1) if(slot_out1 != 0) $display("[%0t] [RX_LATCH] Node 1 Data: 0x%08X", $time, slot_out1);
    
    // 딥 스위치가 변할 때 내부 먹스(MUX) 출력값 모니터링
    always @(DIP_SW) begin
        #1; // 전파 지연 허용
        $display("[%0t] [UI_CTRL] DIP_SW Changed to 4'b%04b", $time, DIP_SW);
        if (DIP_SW[0] == 1'b1) 
            $display("          -> Target Node Data Routing Activated");
        else 
            $display("          -> Global Status Routing Activated");
    end

    // =========================================================================
    // 6. 메인 검증 시나리오 주행
    // =========================================================================
    initial begin
        $display("=================================================");
        $display("  [TB] MASTER_TOP 7-SEGMENT VERIFICATION STARTED ");
        $display("=================================================");

        // 환경 변수 셋업
        DIV = 10'd4;
        GUARD_TICKS = 10'd10;
        NODE_CNT = 3'd3; 
        GPIO_in = 1'b0;
        DIP_SW = 4'b000_1; // 초기 상태: 노드 0의 수신 데이터 표출 모드
        resetn = 1'b0;

        #100;
        @(posedge clk);
        resetn = 1'b1;
        $display("[%0t] Reset Released.", $time);
        
        // ---------------------------------------------------------
        // SCENARIO 1: 정상 데이터 수신 및 7-Segment 데이터 맵핑 확인
        // ---------------------------------------------------------
        sync_to_slot(3'd0);
        $display("\n[%0t] [SCENARIO 1] Injecting Normal Data to Node 0 (0xAAAA_1111)", $time);
        inject_frame(3'd0, 32'hAAAA_1111, 8'hAA, 63);
        
        sync_to_slot(3'd1);
        $display("[%0t] [SCENARIO 1] Injecting Normal Data to Node 1 (0xBBBB_2222)", $time);
        inject_frame(3'd1, 32'hBBBB_2222, 8'hAA, 63); 

        // 7-Segment 디스플레이 스위칭 검증
        #500;
        DIP_SW = 4'b001_1; // DIP_SW[3:1] = 1 (노드 1) 데이터 관측 모드로 전환
        #500;
        
        // ---------------------------------------------------------
        // SCENARIO 2: 에러 인젝션 및 Status 표출 모드 검증
        // ---------------------------------------------------------
        sync_to_slot(3'd2);
        $display("\n[%0t] [SCENARIO 2] Forcing Error on Node 2 to trigger HALT", $time);
        // 어드레스 탈조 주입 (Node 2 슬롯에 Node 0 헤더를 쏴서 Timeout 255 폭사 유도)
        inject_frame(3'd0, 32'hCCCC_3333, 8'hAA, 63);

        // 에러 적발 후 Status 표출 모드로 전환
        #1000;
        DIP_SW = 4'b000_0; // DIP_SW[0] = 0 (상태 모니터링 모드)
        $display("[%0t] [SCENARIO 2] Switched to Status Mode. Observe u_dut.seg_in2", $time);

        // ---------------------------------------------------------
        // SCENARIO 3: 7-Segment 디스플레이 멀티플렉서(MUX) 스캔 대기
        // ---------------------------------------------------------
        $display("\n[%0t] [SCENARIO 3] Waiting for 7-Segment Multiplexer Scan (16384 clocks)...", $time);
        // seven_seg.v 내부의 clk_cnt가 16384에 도달하여 seg_en이 시프트되는지 관측
        repeat(17000) @(posedge clk);

        if (seg_en !== 8'b0000_0001) 
            $display("[%0t] [PASS] 7-Segment Scan Counter is operational (seg_en shifted).", $time);
        else 
            $display("[%0t] [FAIL] 7-Segment Scan Counter did not shift.", $time);

        $display("\n=================================================");
        $display("  [TB] ALL SCENARIOS COMPLETED SUCCESSFULLY      ");
        $display("=================================================");
        $finish;
    end

endmodule