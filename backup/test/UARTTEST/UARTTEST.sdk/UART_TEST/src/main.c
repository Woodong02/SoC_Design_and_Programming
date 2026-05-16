#include "xil_types.h"
#include "xuartps_hw.h"


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


int main(void)
{
	u32	CntrlRegister;
	u8	number[NUM_MAX]	=	{0, };
	u8	name[NAME_MAX]	=	{0, };
	u8	sel				=	0;

	// Read status register
	CntrlRegister = XUartPs_ReadReg(XPAR_PS7_UART_1_BASEADDR, XUARTPS_CR_OFFSET);
	
	// Enable TX and RX for the device
	XUartPs_WriteReg( XPAR_PS7_UART_1_BASEADDR, XUARTPS_CR_OFFSET,
					  ((CntrlRegister & ~XUARTPS_CR_EN_DIS_MASK) | XUARTPS_CR_TX_EN | XUARTPS_CR_RX_EN) );
	
	InitMsg();

	while(1)
	{
		PrintChar("What is your student ID number? ");
		GetNumber(number);

		PrintChar("What is your name? ");
		GetName(name);

		PrintChar("1. Student ID number");
		PrintChar("2. Name");
		PrintChar("What do you want to print? ");

		GetCmd(&sel);

		switch(sel)
		{
			case ('1') :
			{
				PrintChar("Your student ID number is ");
				PrintMsg(number);
				break;
			}
			case ('2')	:
			{
				PrintChar("Your name is ");
				PrintMsg(name);
				break;
			}
			default :
			{
				PrintChar("Select only 1 or 2, please!");
				break;
			}
		}

		InitValue(number, name);
	}

	return 0;
}


void InitMsg(void)
{
	PrintChar("===== Welcome to the ARM Programming World !!! =====");
}


void PrintChar(u8 *str)
{
	XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, CR);

	while(*str != 0)
	{
		XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, *str++);
	}
}


void PrintMsg(u8 *str)
{
	while(*str != 0)
	{
		XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, *str++);
	}
}


void GetNumber(u8 *number)
{
	int i = 0;
	char tmp;

	do
	{
		tmp = XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);

		if( (tmp >= '0') && (tmp <= '9') )
		{
			XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, tmp);
			number[i] = tmp;
			i++;

		}
	}
	while( !((tmp == CR) || (i >= NUM_MAX-1)) );
	while(tmp != CR)
		tmp = XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);
}


void GetName(u8 *name)
{
	int i = 0;
    char tmp;

	//***************************************************
	//
	//Coding here !
	//
	//***************************************************

	while(tmp != CR)
		tmp = XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);
}


void GetCmd(u8 *sel)
{
	char tmp;

	//***************************************************
	//
	//Coding here !
	//
	//***************************************************
	
	while(tmp != CR)
		tmp = XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);
}


void InitValue(u8 *number, u8 *name)
{
	int i = 0;

	//***************************************************
	//
	//Coding here !
	//
	//***************************************************

}
