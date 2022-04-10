/* ns16550.c - NS16550D serial driver */

#include <stdint.h>
#include "../include/reg.h"
#include "../include/uart.h"

/****************************************************************************
* This functions sends a single byte using the UART. It is blocking in that it
* waits for the transmitter to become non-full before it writes the byte to
* the transmit register.
******************************************************************************/
void XUartLite_SendByte(uint8_t Data)
{
	while (XUartLite_IsTransmitFull());
	XUartLite_WriteReg(XUL_TX_FIFO_OFFSET, Data);
}


/****************************************************************************
* This functions receives a single byte using the UART. It is blocking in that
* it waits for the receiver to become non-empty before it reads from the
* receive register.
******************************************************************************/
uint8_t XUartLite_RecvByte()
{
	while (XUartLite_IsReceiveEmpty());

	return (uint8_t) XUartLite_ReadReg(XUL_RX_FIFO_OFFSET);
}

