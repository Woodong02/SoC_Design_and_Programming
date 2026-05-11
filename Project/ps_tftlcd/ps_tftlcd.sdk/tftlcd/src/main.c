#include <stdio.h>
#include "xil_printf.h"
#include "xil_io.h"
#include "xparameters.h"
#include "ff.h"


/************ SD card parameters ************/
static FATFS fatfs;
static FIL fil;
static char filename[32] = "lenna.bin";
FRESULT Res;
TCHAR *Path = "0:/";
u32 * buffer[65280];
u32 data_size = 4 * 65280; // 4byte * buffer_size
u32 NumBytesRead;

int main()
{
    NumBytesRead = 0;
/*********************SD card read*********************/
	Res = f_mount(&fatfs, Path, 0);
    if(Res != FR_OK){
    	xil_printf("mount_fail\n");
    	return 0;
    }

    Res = f_open(&fil, filename, FA_READ);
    if(Res){
        xil_printf("file_open_fail\n");
        return 0;
    }

    Res = f_lseek(&fil, 0);
    if (Res) {
    	xil_printf("fseek_fail\n");
    	return 0;
    }

    Res = f_read(&fil, buffer, data_size, &NumBytesRead);
    if(Res){
        xil_printf("data_read_fail\n");
        return 0;
    }

    Res = f_close(&fil);

	xil_printf("file_read_success\n");


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


    return 0;
}
