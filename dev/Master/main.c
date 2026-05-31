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
void Master_node_init(u16 DIV, u16 GUARD_TICKS, u16 NODE_CNT, u16 FAULT_TH, u16 SILENT_TH);
void SET_DIV(u16 DIV);
void SET_GUARD_TICKS(u16 GUARD_TICKS);
void SET_NODE_CNT(u16 NODE_CNT);
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


#define 	DIV_INIT	4
#define		GUARD_TICKS_INIT	8
#define		NODE_CNT_INIT	7
#define		FAULT_TH_INIT	200
#define		SILENT_TH_INIT	200

int main()
{

	intr_init();
	file_init(Path, filename);
	Master_node_init(DIV_INIT, GUARD_TICKS_INIT, NODE_CNT_INIT, FAULT_TH_INIT, SILENT_TH_INIT);


	while(1){

	}
    int Data;
    int R;
    int G;
    int B;
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

void Master_node_init(u16 DIV, u16 GUARD_TICKS, u16 NODE_CNT, u16 FAULT_TH, u16 SILENT_TH){
	SET_DIV(DIV);
	SET_GUARD_TICKS(GUARD_TICKS);
	SET_NODE_CNT(NODE_CNT);
	SET_FAULT_TH(FAULT_TH);
	SET_SILENT_TH(SILENT_TH);
}

void SET_DIV(u16 DIV){
	if(!DIV)
		xil_printf("DIV Cannot to be set zero.\n");
	else{
		DIV--;
		if(DIV > 1023)
			xil_printf("Please enter less than 1025.\n");
		else{
			MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0, DIV);
			xil_printf("Set DIV completed.\n");
		}
	}
}

void SET_GUARD_TICKS(u16 GUARD_TICKS){
	if(GUARD_TICKS > 1023)
		xil_printf("Please enter less than 1024\n");
	else{
		if(GUARD_TICKS < 4)
			xil_printf("Really? It's too small\n");
		/*else if(GUARD_TICKS % 4 != 0)
			xil_printf("I recommend you to set GUARD_TICKS multiple of 4\n");*/
		MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0, GUARD_TICKS<<10);
		xil_printf("Set GUARD_TICKS completed.\n");
	}
}

void SET_NODE_CNT(u16 NODE_CNT){
	if(!NODE_CNT)
			xil_printf("NODE_CNT Cannot to be set zero.\n");
		else{
			NODE_CNT--;
			if(NODE_CNT > 7)
				xil_printf("Please enter less than 9.\n");
			else{
				MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0, NODE_CNT<<20);
				xil_printf("Set NODE_CNT completed.\n");
			}
		}
}

void SET_FAULT_TH(u16 FAULT_TH){
	if(!FAULT_TH)
		xil_printf("FAULT_TH Cannot to be set zero.\n");
	else if(FAULT_TH > 245)
		xil_printf("Please enter less than 246.\n");
	else{
		MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 4, FAULT_TH);
		xil_printf("Set FAULT_TH completed.\n");
	}
}

void SET_SILENT_TH(u16 SILENT_TH){
	if(!SILENT_TH)
		xil_printf("SILENT_TH Cannot to be set zero.\n");
	else if(SILENT_TH > 245)
		xil_printf("Please enter less than 246.\n");
	else{
		MASTER_mWriteReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 4, SILENT_TH<<8);
		xil_printf("Set SILENT_TH completed.\n");
	}
}

void READ_ALL_ERR_CNT(){
	for(u8 i=0; i<8; i++){
		READ_ERR_CNT(i);
		xil_printf("\n");
	}
}

void READ_ERR_CNT(u8 NODE){
	int temp = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 4*(3+NODE));
	xil_printf("Node %d\nsilent_cnt = %d\nhamming_err_cnt = %d\nslot_timeout_cnt = %d\npreamble_err_cnt = %d\n", NODE, temp&0xFF, (temp>>8)&0xFF, (temp>>16)&0xFF, temp>>24);
}

void READ_CYCLE_CNT(){
	u64 temp = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 4*(3+NODE));
}

void ServiceRoutine(void *CallbackRef)
{
	Res = f_write(&fil, buffer, strlen(buffer), &NumBytesWrite);
	if(Res){
		xil_printf("data_read_fail\n");
		exit(-1);
	}

	int temp = MASTER_mReadReg(XPAR_MASTER_0_S00_AXI_BASEADDR, 0);

	if ((temp & 1) == 1){
		xil_printf("S1 Switch is pushed\r\n");
	}
	else if ((temp & 2) == 2){
		xil_printf("S2 Switch is pushed\r\n");
	}
	else if ((temp & 4) == 4){
		xil_printf("S3 Switch is pushed\r\n");
	}
	else if ((temp & 8) == 8){
		xil_printf("S4 Switch is pushed\r\n");
	}
}

void file_init(char* path, char* filename){
	Res = f_mount(&fatfs, Path, 0);
	if(Res != FR_OK){
		xil_printf("mount_fail\n");
		exit(-1);
	}

	Res = f_open(&fil, filename, FA_CREATE_ALWAYS | FA_WRITE);
	if(Res){
		xil_printf("file_open_fail\n");
		exit(-1);
	}

	Res = f_lseek(&fil, 0);
	if (Res) {
		xil_printf("fseek_fail\n");
		exit(-1);
	}

	xil_printf("file_create_success\n");
}


void intr_init(){
	int Status;

	xil_printf("Interrupt Test\r\n");

	/*
	 *  Run the Gic configure, specify the Device ID generated in xparameters.h
	 */
	Status = GicConfigure(INTC_DEVICE_ID);
	if (Status != XST_SUCCESS) {
		xil_printf("GIC Configure Failed\r\n");
		exit(XST_FAILURE);
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


