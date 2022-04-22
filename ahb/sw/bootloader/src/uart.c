/*-----------------------------------------------------------------------------
// File:    uart.c
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

void uart_init()
{
    XUartLite_DisableIntr();
}

void uart_send_char(uint8_t data)
{
    XUartLite_SendByte(data);
}


void uart_send_string(char *str)
{
    while (*str != '\0')
    {
        uart_send_char(*str);
        str++;
    }
}


void uart_send_hex(unsigned int  h)
{
    int cur_digit;
    // Iterate through h taking top 4 bits each time and outputting ASCII of hex
    // digit for those 4 bits
    for (int i = 0; i < 8; i++)
    {
        cur_digit = h >> 28;

        if (cur_digit < 10)
            uart_send_char('0' + cur_digit);
        else
            uart_send_char('A' - 10 + cur_digit);

        h <<= 4;
    }
}


char uart_check_rx_buf()
{
    return (! XUartLite_IsReceiveEmpty());
}


// Block, get one char from uart.
unsigned char uart_read_char()
{
    uint8_t input_char;
    input_char = XUartLite_RecvByte();
    return input_char;
}


void uart_read_string(char * str, unsigned int length)
{
    unsigned int index;
    unsigned char temp;

    index = 0;
    temp = 0;

    while (index < length)
    {
        temp = uart_read_char();
        // echo
        uart_send_char(temp);

        *(str+index) = temp;
        index += 1;
        if (temp == '\r' || temp == '\n')
        {
            break;
        }
    }

    *(str+index) = '\0';
}