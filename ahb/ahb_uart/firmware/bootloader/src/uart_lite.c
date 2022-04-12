/*-----------------------------------------------------------------------------
// File:    uart_lite.c
// Author:  shawn Liu
// E-mail:  shawn110285@gmail.com
-------------------------------------------------------------------------------

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------------------*/


#include "../include/uart_lite.h"

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
