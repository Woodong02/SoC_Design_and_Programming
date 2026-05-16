#include "xil_types.h"
#include "xparameters.h"
#include "xiicps.h"
#include "seven_seg.h"
#include "textlcd.h"


#define	IIC_SLAVE_ADDR	0x51
#define	IIC_SCLK_RATE	100000


void	WriteTLCDReg(char *pRegVal, int val);
int		ReadRTC(XIicPs Iic, u8 *SendBuffer, u8 *RecvBuffer);


int main(void)
{
	XIicPs	Iic;			/**< Instance of the IIC Device */
	int 	IicStatus;
	u8		*SendBuffer;	/**< Buffer for Transmitting Data */
	u8		RecvBuffer[3];	/**< Buffer for Receiving Data */

	int		SegReg;
	char	TlcdReg_upline[16];
	char	TlcdReg_downline[16];

	int		i;
	int		wait;


	sprintf(TlcdReg_upline, "Digital Clock   ");

	while(TRUE)
	{
		IicStatus = ReadRTC(Iic, SendBuffer, RecvBuffer);

		if (IicStatus != XST_SUCCESS)
		{
			return XST_FAILURE;
		}

		// Coding here!
		//

		WriteTLCDReg(TlcdReg_downline, SegReg);
		for(i = 0; i < 4; i++)
		{
			// Coding here!
			//
		}

		for(wait = 0; wait < 1200; wait++);
	}
}

void WriteTLCDReg(char *pRegVal, int val)
{
	int		i = 0;
	char	temp;

	for(i = 0; i < 8; i++)
	{
		// Coding here!
		pRegVal[i] = temp;
		pRegVal[i+8] = 0x20;
	}
}

int ReadRTC(XIicPs Iic, u8 *SendBuffer, u8 *RecvBuffer)
{
	int				Status;
	XIicPs_Config	*Config;

	Config = XIicPs_LookupConfig(XPAR_XIICPS_0_DEVICE_ID);
	if (Config == NULL)
	{
		return XST_FAILURE;
	}

	Status = XIicPs_CfgInitialize(&Iic, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS)
	{
		return XST_FAILURE;
	}

	XIicPs_SetSClk(&Iic, IIC_SCLK_RATE);

	*SendBuffer		= 0x02;
	RecvBuffer[0]	= 0x00;
	RecvBuffer[1]	= 0x00;
	RecvBuffer[2]	= 0x00;

	Status = XIicPs_MasterSendPolled(&Iic, SendBuffer, 1, IIC_SLAVE_ADDR);
	if(Status != XST_SUCCESS)
	{
		return XST_FAILURE;
	}

	while(XIicPs_BusIsBusy(&Iic))
	{
		/* NOP */
	}

	Status = XIicPs_MasterRecvPolled(&Iic, RecvBuffer, 3, IIC_SLAVE_ADDR);
	if (Status != XST_SUCCESS)
	{
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}
