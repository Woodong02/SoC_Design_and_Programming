`timescale 1ns / 1ps

module tb_FSM_data_rx_Master;

    //------------------------------------------------------------------
    // 1. 하드웨어 인터페이스 포트 선언
    //------------------------------------------------------------------
    reg clk;
    reg [9:0] DIV;
    reg GPIO_in;
    reg resetn;

    wire [41:0] data_out;
    wire out_sig;
    wire preamble_err;

    //------------------------------------------------------------------
    // 2. 검증 대상 장치(UUT) 인스턴스화
    //------------------------------------------------------------------
    FSM_data_rx_Master uut (
        .clk(clk),
        .DIV(DIV),
        .GPIO_in(GPIO_in),
        .resetn(resetn),
        .data_out(data_out),
        .out_sig(out_sig),
        .preamble_err(preamble_err)
    );

    // 100MHz 마스터 시스템 클록 생성 (주기: 10ns)
    always #5 clk = ~clk;

    reg [41:0] test_payload;
    integer i;

    //------------------------------------------------------------------
    // 3. 상승 에지(posedge) 기반 정밀 비트 송신 태스크
    //------------------------------------------------------------------
    task send_bit;
        input bit_to_send;
        begin
            // 수신단 레지스터의 비블로킹 갱신(NBA Region) 직후 타이밍에
            // 선로 전압을 스위칭하여 물리적 셋업/홀드 마진을 최대로 확보합니다.
            @(posedge clk);
            GPIO_in = bit_to_send;
            
            // 현재 타겟 분주비(DIV) 스펙에 맞추어 클록 주기를 정밀 소모합니다.
            repeat (DIV - 1) @(posedge clk);
        end
    endtask

    //------------------------------------------------------------------
    // 4. 단일 패킷 시퀀스 주입 및 자동 통계 로깅 태스크
    //------------------------------------------------------------------
    task send_full_packet;
        input [41:0] payload_data;
        begin
            $display("\n==================================================");
            $display("[TX_SIM] 패킷 드라이브 개시 -> 검증 분주비 DIV = %0d", DIV);
            $display("--------------------------------------------------");

            // [A] 프리앰블 8비트 주입 (8'hAA : 10101010)
            send_bit(1'b1); send_bit(1'b0);
            send_bit(1'b1); send_bit(1'b0);
            send_bit(1'b1); send_bit(1'b0);
            send_bit(1'b1); send_bit(1'b0);

            // [B] 페이로드 42비트 주입 (MSB First)
            for (i = 41; i >= 0; i = i - 1) begin
                send_bit(payload_data[i]);
            end

            // [C] 패킷 종료 후 유휴 상태(Idle) 복귀 및 가드 타임 마진 확보
            @(posedge clk);
            GPIO_in = 1'b0;
            repeat (DIV * 5) @(posedge clk);
            
            // [D] Tcl Console 검증 결과 출력
            $display("[RX_LOGS] 송신 데이터 원본 : 42'h%H", payload_data);
            $display("[RX_LOGS] 복원 수신 데이터 : 42'h%H", data_out);
            $display("[RX_LOGS] 프리앰블 에러 플래그 : %b (0:정상, 1:에러)", preamble_err);
            $display("[RX_LOGS] out_sig 스트로브     : %b", out_sig);
            
            if (data_out == payload_data && preamble_err == 1'b0)
                $display(" -> 검증 결과 : [PASS] DIV=%0d 도메인 무결성 검증 통과", DIV);
            else
                $display(" -> 검증 결과 : [FAIL] DIV=%0d 위상 탈조 및 데이터 오염 발생", DIV);
        end
    endtask

    //------------------------------------------------------------------
    // 5. 전 도메인(DIV = 1, 2, 3, 4, 6, 8) 순차 가변 시나리오 구동
    //------------------------------------------------------------------
    initial begin
        // 초기 전원 투입 상태 벡터 정의
        clk = 0;
        DIV = 10'd1; 
        GPIO_in = 1'b0;
        resetn = 1'b0;
        
        // 검증용 샘플 데이터 적재
        test_payload = 42'h2A_A5A5_5A5A; 

        // 비동기 액티브 로우 리셋 활성화 후 해제
        #50;
        @(posedge clk);
        resetn = 1'b1;
        repeat (5) @(posedge clk); // 시스템 전하 안정화 클록 마진

        // 요구사항: 지정된 모든 분주비 스캔 주입
        
        // 시나리오 1: DIV = 1 (최고속 도메인)
        DIV = 10'd1;
        send_full_packet(test_payload);

        // 시나리오 2: DIV = 2 (반 클럭 천이 도메인)
        DIV = 10'd2;
        send_full_packet(42'h7639a36722);

        // 시나리오 3: DIV = 3 (홀수 분주 정중앙 샘플링)
        DIV = 10'd3;
        send_full_packet(42'h7abbaEFFF11);

        // 시나리오 4: DIV = 4 (짝수 분주 도메인)
        DIV = 10'd4;
        send_full_packet(test_payload);

        // 시나리오 5: DIV = 6 (확장 분주 규격)
        DIV = 10'd6;
        send_full_packet(test_payload);

        // 시나리오 6: DIV = 8 (저속 고마진 도메인)
        DIV = 10'd8;
        send_full_packet(test_payload);

        $display("\n==================================================");
        $display("[SIM_END] 모든 분주비 규격(1, 2, 3, 4, 6, 8) 마스터 시나리오 검증 종료.");
        $finish;
    end

endmodule