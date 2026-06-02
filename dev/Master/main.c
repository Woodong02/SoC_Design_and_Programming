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


u16 DIV = 4;
u16 GUARD_TICKS=8;
u16 NODE_CNT=7;
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
	Master_node_init(DIV, GUARD_TICKS, NODE_CNT, FAULT_TH_INIT, SILENT_TH_INIT, ENABLE_INIT);
	file_init(Path, filename);
	
    int Data;
    int R;
    int G;
    int B;
	char msg[128];
	int ptr=0;
	while(1){
		if(XUartPs_IsReceiveData)
			msg[ptr++] = XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);
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
		}
		Data = mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 4);
		if((data>>19) & 0x1 ==1){
			(data&0x7)
			Xil_Out32(XPAR_TFTLCD_0_S00_AXI_BASEADDR + (2*j + 480*i)*4, NODE_COLORS[Data&0x7]);
		}
	}

	print
    /****************************TFT-LCD write(RGB565)****************************/
    for (int i = 0; i < 272; i++){
    	for (int j = 0; j < 240; j++){
    		// 1
			Data = (int)buffer[j + 240*i] & 0x0000ffff;
			//xil_printf("1. Data:%08x\n", Data);
			R = (Data >> 11) & 0x0000001f;
			G = Data & 0x000007E0;
			B = Data & 0x0000001f;
			Data = (B<<11)| G | R;
			//xil_printf("2. R:%08x, G:%08x, B:%08x, Data:%08x\n", R, G, B, Data);
			Xil_Out32(XPAR_TFTLCD_0_S00_AXI_BASEADDR + (2*j + 480*i)*4, Data);

			// 2
			Data = (int)buffer[j + 240*i] >> 16;
			//xil_printf("3. Data:%08x\n", Data);
			R = (Data >> 11) & 0x0000001f;
			G = Data & 0x000007E0;
			B = Data & 0x0000001f;
			Data = (B<<11)| G | R;
			//xil_printf("4. R:%08x, G:%08x, B:%08x, Data:%08x\n", R, G, B, Data);
			Xil_Out32(XPAR_TFTLCD_0_S00_AXI_BASEADDR + (1 + 2*j + 480*i)*4, Data);
    	}
    }

	Res = f_close(&fil);

    return XST_SUCCESS;
}

void ServiceRoutine(void *CallbackRef)
{
	u32 temp = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 4);
	MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 4, temp&0x0000FFFF);

	u32 cycles_low = Master_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0x2C);
	u32 cycles_high = Master_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0x30);
	u64 cycles = ((u64)cycles_high << 32) | cycles_low;

	for(int i=0; i<8; i++){
		if(temp & (1<<(i+24))){
			sprintf(buffer, "Node %u is Halted.\n", i);
			xil_printf("Node %u is Halted.\r\n", i);
			Res = f_write(&fil, buffer, strlen(buffer), NULL);
			if(Res)
				xil_printf("data_write_fail\r\n");
		}
		if(temp & (1<<(i+16))){
			sprintf(buffer, "Node %u is Silent.\n", i);
			xil_printf("Node %u is Silent.\r\n", i);
			Res = f_write(&fil, buffer, strlen(buffer), NULL);
			if(Res)
				xil_printf("data_write_fail\r\n");
		}
	}
	sprintf(buffer, "After %llu cycles,\n\n", cycles);
	Res = f_write(&fil, buffer, strlen(buffer), NULL);
	if(Res)
		xil_printf("data_write_fail\r\n");
	xil_printf("After %llu cycles,\r\n\r\n", cycles);
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
	if(ENABLE)
		xil_printf("Master Enabled.\r\n");
	else
		xil_printf("Master Disabled.\r\n");
	MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0, (ENABLE&0x1)<<23);
}

void SET_DIV(u16 DIVi){
	DIV=DIVi;
	if(!DIV)
		xil_printf("DIV Cannot to be set zero.\r\n");
	else{
		DIV--;
		if(DIV > 1023)
			xil_printf("Please enter less than 1025.\r\n");
		else{
			MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0, DIV&0x3FF);
			xil_printf("Set DIV completed.\r\n");
		}
	}
}

void SET_GUARD_TICKS(u16 GUARD_TICKSi){
	GUARD_TICKS = GUARD_TICKSi;
	if(GUARD_TICKS > 1023)
		xil_printf("Please enter less than 1024\r\n");
	else{
		if(GUARD_TICKS < 4)
			xil_printf("Really? It's too small\r\n");
		/*else if(GUARD_TICKS % 4 != 0)
			xil_printf("I recommend you to set GUARD_TICKS multiple of 4\r\n");*/
		MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0, (GUARD_TICKS&0x3FF)<<10);
		xil_printf("Set GUARD_TICKS completed.\r\n");
	}
}

void SET_NODE_CNT(u16 NODE_CNTi){
	NODE_CNT = NODE_CNTi;
	if(!NODE_CNT)
			xil_printf("NODE_CNT Cannot to be set zero.\r\n");
		else{
			NODE_CNT--;
			if(NODE_CNT > 7)
				xil_printf("Please enter less than 9.\r\n");
			else{
				MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0, (NODE_CNT&0x7)<<20);
				xil_printf("Set NODE_CNT completed.\r\n");
			}
		}
}

void SET_FAULT_TH(u16 FAULT_TH){
	if(!FAULT_TH)
		xil_printf("FAULT_TH Cannot to be set zero.\r\n");
	else if(FAULT_TH > 245)
		xil_printf("Please enter less than 246.\r\n");
	else{
		MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 8, FAULT_TH&0xFF);
		xil_printf("Set FAULT_TH completed.\r\n");
	}
}

void SET_SILENT_TH(u16 SILENT_TH){
	if(!SILENT_TH)
		xil_printf("SILENT_TH Cannot to be set zero.\r\n");
	else if(SILENT_TH > 245)
		xil_printf("Please enter less than 246.\r\n");
	else{
		MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 8, (SILENT_TH&0xFF)<<8);
		xil_printf("Set SILENT_TH completed.\r\n");
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
	u32 low = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0x2C);
	u32 high = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0x30);
	if(high==0)
		xil_printf("Cycle done: %u\r\n", low);
	else
		xil_printf("Cycle done: %u%09u\r\n", high, low);
	low = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 8);
	xil_printf("FAULT_TH: %u\r\n", low&0xFF);
	xil_printf("SILENT_TH: %u\r\n", (high>>8)&0xFF);
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


