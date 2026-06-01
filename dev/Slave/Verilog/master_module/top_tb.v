`timescale 1ns / 1ps

module tb_master_top_7seg();

    reg         clk;
    reg         resetn_bt;
    reg  [9:0]  DIV;
    reg  [9:0]  GUARD_TICKS;
    reg  [2:0]  NODE_CNT;
    reg         GPIO_in;
    reg  [3:0]  DIP_SW;
    reg         ENABLE;
    reg  [7:0]  FAULT_TH;
    reg  [7:0]  SILENT_TH;

    wire        GPIO_out;
    wire [7:0]  seg_en;
    wire [7:0]  seg_data;
    wire [15:0] clk_cnt;
    wire [2:0]  slot;
    
    wire [31:0] err_cnt0, err_cnt1, err_cnt2, err_cnt3;
    wire [31:0] slot_out0, slot_out1, slot_out2, slot_out3;

    // -----------------------------------------------------------------
    // 1. 개정된 DUT 최상위 모듈 결착 (Physical Wire Mapping)
    // -----------------------------------------------------------------
    master_top u_dut (
        .clk(clk), .resetn_bt(resetn_bt), .DIV(DIV), .GUARD_TICKS(GUARD_TICKS), .NODE_CNT(NODE_CNT), 
        .GPIO_in(GPIO_in), .DIP_SW(DIP_SW), .ENABLE(ENABLE), .FAULT_TH(FAULT_TH), .SILENT_TH(SILENT_TH),
        .seg_en(seg_en), .seg_data(seg_data), .GPIO_out(GPIO_out), .clk_cnt(clk_cnt), .slot(slot),
        .err_cnt0(err_cnt0), .err_cnt1(err_cnt1), .err_cnt2(err_cnt2), .err_cnt3(err_cnt3),
        .err_cnt4(), .err_cnt5(), .err_cnt6(), .err_cnt7(),
        .slot_out0(slot_out0), .slot_out1(slot_out1), .slot_out2(slot_out2), .slot_out3(slot_out3),
        .slot_out4(), .slot_out5(), .slot_out6(), .slot_out7()
    );

    // 50MHz 시스템 마스터 클럭 제너레이터 (주기 20ns 정각)
    always begin
        clk = 1'b0;
        forever #10 clk = ~clk; 
    end

    // -----------------------------------------------------------------
    // 2. [TB 전용] 패킷 인젝션용 동적 골든 해밍 인코더 함수
    // -----------------------------------------------------------------
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

    // 정밀 동기화 레이스 프리 해제 태스크
    task sync_to_slot(input [2:0] target_slot);
        begin
            while (slot === target_slot) @(posedge clk);
            while (slot !== target_slot) @(posedge clk);
            repeat (DIV * 2) @(posedge clk);
        end
    endtask

    // NRZ 패킷 직렬 사출 제어 엔진
    task inject_frame;
        input [2:0]  src_node;     
        input [31:0] payload;
        input [7:0]  preamble;     
        input [5:0]  err_bit_idx;  
        
        reg [41:0] cw;
        reg [49:0] full_frame;
        integer i;
        begin
            cw = ham_enc({src_node, payload});
            if (err_bit_idx < 42) cw[err_bit_idx] = ~cw[err_bit_idx];
            full_frame = {preamble, cw};
            
            // [버그 영구 픽스] 
            // 1. 송신 전 최초 하강 에지(negedge)에 동기화 안착
            @(negedge clk); 
            for (i = 49; i >= 0; i = i - 1) begin
                GPIO_in = full_frame[i];
                // 2. 정확히 DIV 횟수(예: 4)만큼 하강 에지를 통과.
                // 하강~하강은 정확히 1클럭(20ns)이므로, 오차 없이 80ns 폭 달성 완료
                repeat (DIV) @(negedge clk);
            end
            GPIO_in = 0;
        end
    endtask

    // -----------------------------------------------------------------
    // 3. 메인 하드웨어 무결성 시나리오 구동 레일
    // -----------------------------------------------------------------
    initial begin
        // 초기 제어 벡터 안착
        DIV         = 10'd4;
        GUARD_TICKS = 10'd12; // 4의 배수로 경계벽 오염 방어
        NODE_CNT    = 3'd2;   // Node 0, 1, 2 순환 구동
        GPIO_in     = 1'b0;
        DIP_SW      = 4'b000_1; // Node 0 데이터 표출 모드 시작
        ENABLE      = 1'b0;     // 하드웨어 인터록 록업
        resetn_bt   = 1'b0;
        FAULT_TH    = 8'd20;    // 에러 허용 한계선 배정
        SILENT_TH   = 8'd200;

        #100;
        resetn_bt = 1'b1;
        #20;
        ENABLE    = 1'b1; // 인터록 해제 부팅 완결

        // ---------------------------------------------------------
        // [시나리오 1] DIV=4 기준 다중 노드 정상 패킷 및 7-Seg 맵핑 스위칭
        // ---------------------------------------------------------
        sync_to_slot(3'd0);
        inject_frame(3'd0, 32'hAAAA_1111, 8'hAA, 63); // 무결성 통과
        
        sync_to_slot(3'd1);
        inject_frame(3'd1, 32'hBBBB_2222, 8'hAA, 63);

        #500;
        DIP_SW = 4'b001_1; // DIP_SW[3:1]=1, [0]=1 ➔ Node 1 데이터로 디스플레이 MUX 전환

        // ---------------------------------------------------------
        // [시나리오 2] 사용자 수정 해밍 가드벽 작동성 검증 (1-Bit 패리티 노이즈)
        // ---------------------------------------------------------
        sync_to_slot(3'd0);
        // p0 패리티 비트(코드워드 인덱스 1)를 강제로 뒤집어 인입
        inject_frame(3'd0, 32'h1234_5678, 8'hAA, 6'd1); 
        // 결과 확인: 해밍 카운터는 오르되, 데이터 변형 없이 '12345678'이 정상 출력되는지 사수

        // ---------------------------------------------------------
        // [시나리오 3] 극한 분주 경계면 동적 전이 ($DIV=1$ 런타임 클램프)
        // ---------------------------------------------------------
        wait (slot == 3'd0 && clk_cnt == 16'd0);
        @(negedge clk);
        DIV         = 10'd1;
        GUARD_TICKS = 10'd8; // 초고속 프로토콜 스케일로 대역폭 전이

        sync_to_slot(3'd0);
        inject_frame(3'd0, 32'hCAFE_BABE, 8'hAA, 63);

        // ---------------------------------------------------------
        // [시나리오 4] 고의적 위조 패킷을 통한 일격 차단(HALT) 기전 검증
        // ---------------------------------------------------------
        sync_to_slot(3'd1);
        // Node 1 슬롯 타이밍에 Node 2 헤더를 박아 강제 폭사 유도
        inject_frame(3'd2, 32'h9999_9999, 8'hAA, 63); 

        #500;
        DIP_SW = 4'b000_0; // DIP_SW[0]=0 ➔ 전체 노드 에러/진단 스태터스 모드로 디스플레이 강제 전환
        
        repeat(17000) @(posedge clk); // 세그먼트 MUX 스캔 타임 확보
        $finish;
    end

endmodule