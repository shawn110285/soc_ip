/*-----------------------------------------------------------------------------
// File:    bootloader.s
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

#include "../include/bootloader.h"
#include "../include/reg.h"
#include "../include/timer.h"
#include "../include/uart.h"
#include "../include/flash.h"
#include "../include/utils.h"

#define  DOWN_LOAD_BASE_ADDR   (0x40000000)
#define  MHZ_PER_SECOND        (10*5*1000*1000)

char * menuStr = "------------Cookabarra Boot Menu(TIM0)------------\r\n"
        " (D):DDR TEST\r\n"
        " (S):SRAM TEST\r\n"
        " (U):Update firmware\r\n"
        " (A):Start App\r\n";

char * commandStr = "command:";
char * commandErrorStr = "command error!\r\n";
char * strPompt = "Press Any Key to Interrupt Boot (TIM0)!\r\n";

unsigned char currentState;
unsigned int  timer_count = 0;


static void timerCallback(void);

static void SRAM_test(void);
static void ddr_test(void);

static void downloadProgram();
static char checkApplication(void);
static void call_application();

void main()
{
    char command[5] = { 0 };

    uart_init();
    uart_send_string(strPompt);
    flash_init();

   // timer_enable(MHZ_PER_SECOND, timerCallback);

    currentState = START_STATE;
    timer_count = 0;

    while (1)
    {
        switch (currentState)
        {
            case START_STATE:
            {
                if ( timer_count < 60 )
                {
                    if( uart_check_rx_buf())
                    {
                        uart_read_char();
                        currentState = MENU_STATE;
                        uart_send_string(menuStr);
                        uart_send_string(commandStr);
                        timer_disable();
                    }
                }
                else
                {
                    currentState = START_APPLICATION_STATE;
                    timer_disable();
                }
            }
            break;

            case MENU_STATE:
            {
                uart_read_string(command, 5);
                switch (command[0])
                {
                    case 'D':           //ddr test
                    case 'd':
                        ddr_test();
                        uart_send_string(commandStr);
                        break;

                    case 'S':           // sram test
                    case 's':
                        SRAM_test();
                        uart_send_string(commandStr);
                        break;

                    case 'U':           //update
                    case 'u':
                        downloadProgram();
                        uart_send_string(commandStr);
                        break;

                    case 'A':          //jump to application
                    case 'a':
                        currentState = START_APPLICATION_STATE;
                        break;

                    default:
                        uart_send_string(commandErrorStr);
                        uart_send_string(commandStr);
                        break;
                }
            }
            break;

            case START_APPLICATION_STATE:
            {
                uart_send_string("\r\n=======================================\r\n");
                uart_send_string("start the application!\r\n");
                currentState = END_STATE;
                call_application();
            }
            break;
        }
    }
}



#define SRAM_BASE     TIM0_BASE
#define SRAM_OFFSET   (64*1024)    //64k, skip the 64k occupied by the bootloader itself
#define SRAM_SIZE     (128*1024)

static void SRAM_test(void)
{
    int32_t addr;
    int32_t value;

    uart_send_string("Start to  test the sram \r\n");

    uart_send_string("write word to the sram:");
    for (addr = SRAM_OFFSET; addr < SRAM_SIZE; addr += 4)
    {
        *(int32_t *)(SRAM_BASE + addr) = 0x5a5a5a5a;
        if( addr%1024 == 0)
        {
            uart_send_char('.');
        }
    }

    uart_send_string("\r\n");
    uart_send_string("read word from the sram:");
    for (addr = SRAM_OFFSET; addr < SRAM_SIZE; addr += 4)
    {
        value = *(int32_t *)(SRAM_BASE + addr);
        if(addr%1024 == 0)
        {
            uart_send_char('.');
        }

        if(value != 0x5a5a5a5a)
        {
            xprintf("test failed, addr =0x%x  \r", (SRAM_BASE + addr));
            break;
        }
    }

    uart_send_string("\r\n");
    uart_send_string("write byte to the sram:");
    for (addr = SRAM_OFFSET; addr < SRAM_SIZE; addr += 4)
    {
        *(int8_t *)(SRAM_BASE + addr) = 0xA5;
        if( addr%1024 == 0)
        {
            uart_send_char('.');
        }
    }

    uart_send_string("\r\n");
    uart_send_string("read byte from the sram:");
    for (addr = SRAM_OFFSET; addr < SRAM_SIZE; addr += 4)
    {
        value = *(int32_t *)(SRAM_BASE + addr);
        if(addr%1024 == 0)
        {
            uart_send_char('.');
        }

        if(value != 0x5a5a5aA5)
        {
            xprintf("test failed, addr =0x%x  \r", (SRAM_BASE + addr));
            break;
        }
    }

    uart_send_string("\r\n");
    uart_send_string("write index into the sram:");
    for (addr = SRAM_OFFSET; addr < SRAM_SIZE; addr += 4)
    {
        *(int32_t *)(SRAM_BASE + addr) = (SRAM_BASE + addr);
        if( addr%1024 == 0)
        {
            uart_send_char('.');
        }
    }

    uart_send_string("\r\n");
    uart_send_string("read index from the sram:");
    for (addr = SRAM_OFFSET; addr < SRAM_SIZE; addr += 4)
    {
        value = *(int32_t *)(SRAM_BASE + addr);
        if(addr%1024 == 0)
        {
            uart_send_char('.');
        }

        if(value != (SRAM_BASE + addr))
        {
            xprintf("test failed, addr =0x, index =%x  \r", (SRAM_BASE + addr), value);
            break;
        }
    }

    uart_send_string("\r\n");
    if(addr >= SRAM_SIZE)
        uart_send_string("SRAM tested Complete!\r\n");
    else
        uart_send_string("SRAM tested failed!\r\n");
}



#define DDR_SIZE  512*1024*1024   //512M 512*1024
#define DDR_BASE  0x40000000

static void ddr_test(void)
{
    uint32_t addr;
    uint32_t value;

    uart_send_string("Start to  test the ddr \r\n");

    uart_send_string("\r\n");
    uart_send_string("write index into the ddr:");
    for (addr = 0; addr < DDR_SIZE; addr += 4)
    {
        *(uint32_t *)(DDR_BASE + addr) = (uint32_t)(DDR_BASE + addr);

        if( addr%(1024*1024) == 0)
        {
            uart_send_char('.');
        }
        // xprintf("write, addr =0x%x, value =0x%x \r\n", (DDR_BASE + addr), (uint32_t)(DDR_BASE + addr));
    }

    uart_send_string("\r\n");
    uart_send_string("read index from the ddr:");
    for (addr = 0; addr < DDR_SIZE; addr += 4)
    {
        value = *(uint32_t *)(DDR_BASE + addr);
        if(addr%(1024*1024) == 0)
        {
            uart_send_char('.');
        }

        if(value != (DDR_BASE + addr))
        {
            xprintf("test failed, addr =0x%x, index =0x%x  \r", (DDR_BASE + addr), value);
            break;
        }
    }

    uart_send_string("\r\n");
    uart_send_string("write word to the ddr:");
    for (addr = 0; addr < DDR_SIZE; addr += 4)
    {
        *(int32_t *)(DDR_BASE + addr) = 0x5a5a5a5a;
        if( addr%(1024*1024) == 0)
        {
            uart_send_char('.');
        }
    }

    uart_send_string("\r\n");
    uart_send_string("write byte to the ddr:");
    for (addr = 0; addr < DDR_SIZE; addr += 4)
    {
        *(int8_t *)(DDR_BASE + addr) = 0xA5;
        if( addr%(1024*1024) == 0)
        {
            uart_send_char('.');
        }
    }

    uart_send_string("\r\n");
    uart_send_string("read from the ddr:");
    for (addr = 0; addr < DDR_SIZE; addr += 4)
    {
        value = *(int32_t *)(DDR_BASE + addr);
        if(addr%(1024*1024) == 0)
        {
            uart_send_char('.');
        }
        if(value != 0x5a5a5aA5)
        {
            xprintf("test failed, addr =0x%x  \r", (DDR_BASE + addr));
            break;
        }
    }

    uart_send_string("\r\n");
    if(addr >= DDR_SIZE)
        uart_send_string("DDR tested Complete!\r\n");
    else
        uart_send_string("DDR tested failed!\r\n");
}


/* download binary file to DOWN_LOAD_BASE_ADDR*/
void downloadProgram(void)
{
	unsigned char *ptr = (char *)DOWN_LOAD_BASE_ADDR;
	char command = 0;
	unsigned char length;
	unsigned char index;

	uart_send_string("start to send the bin file in the desktop !\r\n");

	while (1)
    {
		command = uart_read_char();	  /* wait backend */
		switch (command)
        {
			/* start to receive a segment */
			case 's':
            {
				length = uart_read_char();
				for (index = 0; index < length; index++)
                {
					*ptr++ =(unsigned char) uart_read_char();
				}
				uart_send_char('n');   // give a feedback to the desktop program
            }
            break;

			/* finish */
			case 'f':
            {
				uart_send_char('n');
				return;
            }
            break;

			default:
            {
				uart_send_string("\r\n unknown command! \r\n");
            }
            break;
		}
	}
}

static char checkApplication(void)
{
    // todo: crc checking after download
    return 1;
}


static void call_application()
{
    // asm ("j 0x40000000");

    // the offset is the entry address
    asm ("lui   x1, 0x40001 \n"
         "addi  x1, x1, 0x26e \n"
         "jalr  x0, 0(x1) \n" );
}

static void timerCallback(void)
{
    timer_count ++;
    xprintf("wait for more %d Seconds (TIM0)! \r\n", (60 - timer_count));
}