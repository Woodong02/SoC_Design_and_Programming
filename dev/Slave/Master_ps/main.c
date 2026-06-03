#include <stdio.h>
#include <stdlib.h>
#include "xil_exception.h"
#include "xscugic.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xparameters.h"
#include "Master.h"
#include "tftlcd.h"
#include "ff.h"
#include "xil_types.h"
#include "xuartps_hw.h"


// interrupt
XScuGic InterruptController; 	     // Instance of the Interrupt Controller
static XScuGic_Config *GicConfig;    // The configuration parameters of the controller
#define INTC_DEVICE_ID		XPAR_SCUGIC_0_DEVICE_ID
#define INTC_DEVICE_INT_ID	31
int GicConfigure(u16 DeviceId);
void ServiceRoutine(void *CallbackRef); //
void intr_init();


/************ SD card parameters ************/
static FATFS fatfs;
static FIL fil;
TCHAR *Path = "0:/";
static char filename[32] = "first";
FRESULT Res;
char buffer[65280];
unsigned int NumBytesWrite = 0;
void file_init();



// Master Configurations
void Master_node_init(u16 DIV, u16 GUARD_TICKS, u16 NODE_CNT, u16 FAULT_TH, u16 SILENT_TH, u8 ENABLE);
void SET_DIV(u16 DIV);
void SET_GUARD_TICKS(u16 GUARD_TICKS);
void SET_NODE_CNT(u16 NODE_CNT);
void SET_ENABLE(u8 ENABLE);
void SET_FAULT_TH(u16 FAULT_TH);
void SET_SILENT_TH(u16 SILENT_TH);
void READ_ERR_CNT(u8 NODE);
void READ_ALL_ERR_CNT();
void READ_CYCLE_CNT();


// UART
#define		CR				0x0D						// carriage return
#define 	NUM_MAX			20							// number maximum
#define 	NAME_MAX		20							// name maximum
void	InitMsg(void);
void	PrintChar(u8 *str);
void	PrintMsg(u8 *str);
void	GetNumber(u8 *number);
void	GetName(u8 *name);
void	GetCmd(u8 *sel);
void	InitValue(u8 *number, u8 *name);


u16 DIV = 1024;
u16 GUARD_TICKS=256;
u16 NODE_CNT=5;
#define		FAULT_TH_INIT	200
#define		SILENT_TH_INIT	200
#define		ENABLE_INIT	1

const u16 NODE_COLORS[8] = {
    0xF800,  // Node 0: Red
    0x07E0,  // Node 1: Green
    0x001F,  // Node 2: Blue
    0xFFE0,  // Node 3: Yellow
    0xF81F,  // Node 4: Magenta
    0x07FF,  // Node 5: Cyan
    0xFBE0,  // Node 6: Orange
    0xFFFF   // Node 7: White
};


int main()
{
	intr_init();
	//file_init(Path, filename);
	Master_node_init(DIV, GUARD_TICKS, NODE_CNT, FAULT_TH_INIT, SILENT_TH_INIT, ENABLE_INIT);

    int Data;
	char msg[1024];
	int ptr=0;
	int timer=0;
	while(1){
		if(XUartPs_IsReceiveData(XPAR_PS7_UART_1_BASEADDR)){
			msg[ptr++] = XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);
			xil_printf("a");
		}/*
		if(msg[ptr-1] == CR){
			msg[ptr-1] = 0;
			xil_printf("Received: %s\r\n", msg);
			ptr=0;
			if (strcmp(msg, "READ_ALL_ERR_CNT") == 0)
				READ_ALL_ERR_CNT();
			else if (strncmp(msg, "READ_ERR_CNT ", 12) == 0)
				READ_ERR_CNT(atoi(msg+12));
			else if (strcmp(msg, "READ_CYCLE_CNT") == 0)
				READ_CYCLE_CNT();
			else if (strcmp(msg, "SET_ENABLE 1") == 0)
				SET_ENABLE(1);
			else if (strcmp(msg, "SET_ENABLE 0") == 0)
				SET_ENABLE(0);
			else if (strncmp(msg, "SET_DIV ", 8) == 0)
				SET_DIV(atoi(msg+8));
			else if (strncmp(msg, "SET_GUARD_TICKS ", 16) == 0)
				SET_GUARD_TICKS(atoi(msg+16));
			else if (strncmp(msg, "SET_NODE_CNT ", 13) == 0)
				SET_NODE_CNT(atoi(msg+13));
			else if (strncmp(msg, "SET_FAULT_TH ", 13) == 0)
				SET_FAULT_TH(atoi(msg+13));
			else if (strncmp(msg, "SET_SILENT_TH ", 15) == 0)
				SET_SILENT_TH(atoi(msg+15));
			else
				xil_printf("Err command.\r\n");
		}*/
		//Data = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 4);
		//슬롯 = (data&0x7), clk_cnt = data(>>3)&0xFFFF
		//0~479 가로, 0~271 세로 = 480*272 = 130560 pixels. 가로를 3칸으로 나누기
		//(data&0x7)/3*160 + (data&0x7)%3*160 = x좌표, (data>>3)&0xFFFF/160 = y좌표
		//if(((Data>>19)&0x1) ==1){
			//int node = Data&0x7;
			//x = (node%3)*160 + rand()%160;
			//y = (node/3)*480*90 + (rand()%90)*480;
			//Xil_Out32(XPAR_TFTLCD_0_S00_AXI_BASEADDR + ((node%3)*160 + rand()%160 + (node/3)*480*90 + (rand()%90)*480)*2, NODE_COLORS[node]);
		//}
		// 1. 5'h01 레지스터 주소번지로부터 원자적 버스 읽기 집행 [cite: 154]
		Data = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 4);
		//xil_printf("%u",(Data>>19&0x1));
		// 2. 비교 연산자 우선순위 괄호 체결 및 GPIO_in 플래그 검사
		if ((Data >> 19) & 0x1) {
		    int node = Data & 0x7;

		    // [A] X축 물리 좌표 정산 (가로폭 480을 3칸으로 분할: 0~159 마진)
		    u32 final_x = ((node % 3) * 160) + (rand() % 160);

		    // [B] Y축 물리 좌표 정산 (세로폭 272 내부 안착용 가물막이 수립)
		    // node=0,1,2 (0층=0라인) / node=3,4,5 (1층=90라인) / node=6,7 (2층=180라인) 기점 수립
		    u32 node_y_floor = (node / 3) * 90;
		    u32 final_y = node_y_floor + (rand() % 90); // 180 + 89 = 269라인이므로 272 상한선 내부 안전 안착

		    // [C] 2차원 평면 좌표 -> 1차원 물리 바이트 주소 최종 선형화
		    // 명전한 대원칙 공식 적용: ((Y * 가로폭) + X)
		    // 좌표 결착이 완전히 끝난 유효 덩어리에, RGB565 규격인 2바이트(*2) 배율을 최종 마디에 단 한 번만 곱합니다.
		    u32 pixel_byte_offset = ((final_y * 480) + final_x) * 2;

		    // [D] 하드웨어 프레임 버퍼 RAM 경계선 보호 가드벽 실행 (메모리 크래시 원천 봉쇄)
		    if (pixel_byte_offset < (480 * 272 * 2)) {
		        // 16비트 버스 전용 함수인 Xil_Out16으로 저격 사출하여 인접 픽셀 데이터 오염 차단
		        Xil_Out16(XPAR_TFTLCD_0_S00_AXI_BASEADDR + pixel_byte_offset, NODE_COLORS[node]);
		    }
		}
	}
	Res = f_close(&fil);

    return XST_SUCCESS;
}

void ServiceRoutine(void *CallbackRef)
{
	u32 temp = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 8);
	MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 8, temp&0x0000FFFF);
	u32 cycles_low = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0x4C);
	u32 cycles_high = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0x50);
	xil_printf("Interrupted\r\n");
	for(int i=0; i<8; i++){
		if(temp & (1<<(i+24))){
			xil_printf("Node %u is Halted.\r\n", i);
			//Res = f_write(&fil, buffer, strlen(buffer), NULL);
			//if(Res)
				//xil_printf("data_write_fail\r\n");
		}
		if(temp & (1<<(i+16))){
			//sprintf(buffer, "Node %u is Silent.\n", i);
			xil_printf("Node %u is Silent.\r\n", i);
			//Res = f_write(&fil, buffer, strlen(buffer), NULL);
			//if(Res)
				//xil_printf("data_write_fail\r\n");
		}
	}
	//sprintf(buffer, "After %u%09u cycles,\n\n", cycles_high,cycles_low);
	//Res = f_write(&fil, buffer, strlen(buffer), NULL);
	//if(Res)
		//xil_printf("data_write_fail\r\n");
	xil_printf("After %u%09u cycles,\r\n\r\n", cycles_high, cycles_low);
}

void Master_node_init(u16 DIVi, u16 GUARD_TICKSi, u16 NODE_CNTi, u16 FAULT_TH, u16 SILENT_TH, u8 ENABLE){
	DIV=DIVi;
	GUARD_TICKS=GUARD_TICKSi;
	NODE_CNT=NODE_CNTi;
	SET_DIV(DIV);
	SET_GUARD_TICKS(GUARD_TICKS);
	SET_NODE_CNT(NODE_CNT);
	SET_FAULT_TH(FAULT_TH);
	SET_SILENT_TH(SILENT_TH);
	SET_ENABLE(ENABLE);
}

void SET_ENABLE(u8 ENABLE){
	u32 temp = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0);
	temp&=~(0x1<<23);
	if(ENABLE)
		xil_printf("Master Enabled.\r\n");
	else
		xil_printf("Master Disabled.\r\n");
	MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0, temp | (ENABLE&0x1)<<23);
}

void SET_DIV(u16 DIVi){
	u32 temp = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0);
	temp&=~0x3FF;
	DIV=DIVi;
	if(!DIV)
		xil_printf("DIV Cannot to be set zero.\r\n");
	else{
		DIVi--;
		if(DIVi > 1023)
			xil_printf("Please enter less than 1025.\r\n");
		else{
			MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0,temp | (DIVi&0x3FF));
			xil_printf("Set DIV %u completed.\r\n", DIV);
		}
	}
}

void SET_GUARD_TICKS(u16 GUARD_TICKSi){
	u32 temp = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0);
	temp&= ~(0x3FF << 10);
	GUARD_TICKS = GUARD_TICKSi;
	if(GUARD_TICKS > 1023)
		xil_printf("Please enter less than 1024\r\n");
	else{
		if(GUARD_TICKS < 4)
			xil_printf("Really? It's too small\r\n");
		/*else if(GUARD_TICKS % 4 != 0)
			xil_printf("I recommend you to set GUARD_TICKS multiple of 4\r\n");*/
		MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0, temp | (GUARD_TICKS&0x3FF)<<10);
		xil_printf("Set GUARD_TICKS %u completed.\r\n", GUARD_TICKS);
	}
}

void SET_NODE_CNT(u16 NODE_CNTi){
	NODE_CNT = NODE_CNTi;
	u32 temp = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0);
	temp&= ~(0x7<<20);
	if(!NODE_CNT)
			xil_printf("NODE_CNT Cannot to be set zero.\r\n");
		else{
			NODE_CNTi--;
			if(NODE_CNT > 7)
				xil_printf("Please enter less than 9.\r\n");
			else{
				temp&=~(0x7)<<20;
				MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0, ((NODE_CNTi&0x7)<<20)|temp);
				xil_printf("Set NODE_CNT %u completed.\r\n", NODE_CNT);
			}
		}
}

void SET_FAULT_TH(u16 FAULT_TH){
	u32 temp = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 8);
	temp&=~0xFF;
	if(!FAULT_TH)
		xil_printf("FAULT_TH Cannot to be set zero.\r\n");
	else if(FAULT_TH > 245)
		xil_printf("Please enter less than 246.\r\n");
	else{
		MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 8, temp | (FAULT_TH&0xFF));
		xil_printf("Set FAULT_TH %u completed.\r\n", FAULT_TH);
	}
}

void SET_SILENT_TH(u16 SILENT_TH){
	u32 temp = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 8);
	temp&=~(0xFF<<8);
	if(!SILENT_TH)
		xil_printf("SILENT_TH Cannot to be set zero.\r\n");
	else if(SILENT_TH > 245)
		xil_printf("Please enter less than 246.\r\n");
	else{
		MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 8, temp | (SILENT_TH&0xFF)<<8);
		xil_printf("Set SILENT_TH %u completed.\r\n", SILENT_TH);
	}
}

void READ_ALL_ERR_CNT(){
	for(u8 i=0; i<NODE_CNT; i++){
		READ_ERR_CNT(i);
		xil_printf("\r\n");
	}
}

void READ_ERR_CNT(u8 NODE){
	int temp = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 4*(3+NODE));
	xil_printf("Node %u\r\nsilent_cnt = %u\r\nhamming_err_cnt = %u\r\nslot_timeout_cnt = %u\r\npreamble_err_cnt = %u\r\n", NODE, temp&0xFF, (temp>>8)&0xFF, (temp>>16)&0xFF, temp>>24);
}

void READ_CYCLE_CNT(){
	u32 low = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0x4C);
	u32 high = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0x50);
	if(high==0)
		xil_printf("Cycle done: %u\r\n", low);
	else
		xil_printf("Cycle done: %u%09u\r\n", high, low);
	low = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 8);
	xil_printf("FAULT_TH: %u\r\n", low&0xFF);
	xil_printf("SILENT_TH: %u\r\n", (low>>8)&0xFF);
}



void file_init(char* path, char* filename){
	Res = f_mount(&fatfs, Path, 0);
	if(Res != FR_OK){
		xil_printf("mount_fail\r\n");
	}

	Res = f_open(&fil, filename, FA_CREATE_ALWAYS | FA_WRITE);
	if(Res){
		xil_printf("file_open_fail\r\n");
	}

	Res = f_lseek(&fil, 0);
	if (Res) {
		xil_printf("fseek_fail\r\n");
	}

	xil_printf("file_create_success\r\n");
}


void intr_init(){
	int Status;
	/*
	 *  Run the Gic configure, specify the Device ID generated in xparameters.h
	 */
	Status = GicConfigure(INTC_DEVICE_ID);
	if (Status != XST_SUCCESS) {
		xil_printf("GIC Configure Failed\r\n");
	}
	xil_printf("Intr_init Finished\r\n");
}

int GicConfigure(u16 DeviceId)
{
	int Status;

	/*
	 * Initialize the interrupt controller driver so that it is ready to
	 * use.
	 */
	GicConfig = XScuGic_LookupConfig(DeviceId);
	if (NULL == GicConfig) {
		return XST_FAILURE;
	}

	Status = XScuGic_CfgInitialize(&InterruptController, GicConfig,
					GicConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Connect the interrupt controller interrupt handler to the hardware
	 * interrupt handling logic in the ARM processor.
	 */
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
			(Xil_ExceptionHandler) XScuGic_InterruptHandler,
			&InterruptController);

	/*
	 * Enable interrupts in the ARM
	 */
	Xil_ExceptionEnable();

	/*
	 * Connect a device driver handler that will be called when an
	 * interrupt for the device occurs, the device driver handler performs
	 * the specific interrupt processing for the device
	 */
	Status = XScuGic_Connect(&InterruptController, INTC_DEVICE_INT_ID,
			   (Xil_ExceptionHandler)ServiceRoutine,
			   (void *)&InterruptController);

	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Enable the interrupt for the device and then cause (simulate) an
	 * interrupt so the handlers will be called
	 */
	XScuGic_Enable(&InterruptController, INTC_DEVICE_INT_ID);

	return XST_SUCCESS;
}


