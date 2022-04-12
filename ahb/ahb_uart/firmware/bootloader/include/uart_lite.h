
/*-----------------------------------------------------------------------------
// File:    uart_lite.h
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

#ifndef _UART_LITE_H_
#define _UART_LITE_H_

#include <stdint.h>
#include "reg.h"

#define  BaseAddress   PERIPH_PORT_BASE

/************************** Constant Definitions ****************************/

/* UART Lite register offsets */
#define XUL_RX_FIFO_OFFSET		    0	/* receive FIFO, read only */
#define XUL_TX_FIFO_OFFSET	   	    4	/* transmit FIFO, write only */
#define XUL_STATUS_REG_OFFSET		8	/* status register, read only */
#define XUL_CONTROL_REG_OFFSET		12	/* control reg, write only */

/* Control Register bit positions */
#define XUL_CR_ENABLE_INTR		    0x10	/* enable interrupt */
#define XUL_CR_FIFO_RX_RESET		0x02	/* reset receive FIFO */
#define XUL_CR_FIFO_TX_RESET		0x01	/* reset transmit FIFO */

/* Status Register bit positions */
#define XUL_SR_PARITY_ERROR		    0x80
#define XUL_SR_FRAMING_ERROR		0x40
#define XUL_SR_OVERRUN_ERROR		0x20
#define XUL_SR_INTR_ENABLED		    0x10	/* interrupt enabled */
#define XUL_SR_TX_FIFO_FULL		    0x08	/* transmit FIFO full */
#define XUL_SR_TX_FIFO_EMPTY		0x04	/* transmit FIFO empty */
#define XUL_SR_RX_FIFO_FULL		    0x02	/* receive FIFO full */
#define XUL_SR_RX_FIFO_VALID_DATA	0x01	/* data in receive FIFO */



/****************************************************************************
* Write a value to a UartLite register. A 32 bit write is performed.
****************************************************************************/
#define XUartLite_WriteReg(RegOffset, Data)  DEV_WRITE((BaseAddress) + (RegOffset), (uint32_t)(Data))


/****************************************************************************
* Read a value from a UartLite register. A 32 bit read is performed.
****************************************************************************/
#define XUartLite_ReadReg(RegOffset)  DEV_READ((BaseAddress) + (RegOffset))


/****************************************************************************
* Set the contents of the control register. Use the XUL_CR_* constants defined
* above to create the bit-mask to be written to the register.
*****************************************************************************/
#define XUartLite_SetControlReg(Mask) XUartLite_WriteReg(XUL_CONTROL_REG_OFFSET, (Mask))


/****************************************************************************
* Get the contents of the status register. Use the XUL_SR_* constants defined
* above to interpret the bit-mask returned.
*****************************************************************************/
#define XUartLite_GetStatusReg()  XUartLite_ReadReg(XUL_STATUS_REG_OFFSET)


/****************************************************************************
* Check to see if the receiver has data.
*****************************************************************************/
#define XUartLite_IsReceiveEmpty() \
  ((XUartLite_GetStatusReg() & XUL_SR_RX_FIFO_VALID_DATA) != XUL_SR_RX_FIFO_VALID_DATA)


/****************************************************************************
* Check to see if the transmitter is full.
*****************************************************************************/
#define XUartLite_IsTransmitFull() \
	(( XUartLite_GetStatusReg() & XUL_SR_TX_FIFO_FULL) == XUL_SR_TX_FIFO_FULL)


/****************************************************************************
*
* Check to see if the interrupt is enabled.
*
*****************************************************************************/
#define XUartLite_IsIntrEnabled() \
	((XUartLite_GetStatusReg() & XUL_SR_INTR_ENABLED) == XUL_SR_INTR_ENABLED)


/****************************************************************************
* Enable the device interrupt. We cannot read the control register, so we
* just write the enable interrupt bit and clear all others. Since the only
* other ones are the FIFO reset bits, this works without side effects.
*****************************************************************************/
#define XUartLite_EnableIntr() \
		XUartLite_SetControlReg(XUL_CR_ENABLE_INTR)


/****************************************************************************
*
* Disable the device interrupt. We cannot read the control register, so we
* just clear all bits. Since the only other ones are the FIFO reset bits,
* this works without side effects.
*****************************************************************************/
#define XUartLite_DisableIntr()  XUartLite_SetControlReg(0)

/************************** Function Prototypes *****************************/

void    XUartLite_SendByte(uint8_t Data);
uint8_t XUartLite_RecvByte();



#endif /* _UART_LITE_H_ */