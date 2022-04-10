#include "../include/bootloader.h"
#include "../include/reg.h"
#include "../include/timer.h"
#include "../include/uart.h"
#include "../include/flash.h"
#include "../include/utils.h"


char * menuStr = "------------Cookabarra Boot Menu------------\r\n"
        " (D):DDR TEST\r\n"
        " (S):SRAM TEST\r\n"
        " (A):Start App\r\n";

char * commandStr = "command:";
char * commandErrorStr = "command error!\r\n";
char * strPompt = "Press Any Key to Interrupt Boot!\r\n";

unsigned char currentState;
unsigned int  timer_count = 0;


static void timerCallback(void);
static char checkApplication(void);
static void call_application();
static void SRAM_test(void);
static void ddr_test(void);


void uart_init()
{
    XUartLite_DisableIntr();
}

void uart_send_char(uint8_t data)
{
    XUartLite_SendByte(data);
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

void uart_send_string(char *str)
{
    while (*str != '\0')
    {
        uart_send_char(*str);
        str++;
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


void main()
{
    char command[5] = { 0 };

    uart_init();
    uart_send_string(strPompt);
    flash_init();
    // timer_enable(50000000, timerCallback);

    currentState = START_STATE;
    timer_count = 0;

    while (1)
    {
        switch (currentState)
        {
            case START_STATE:
            {
                if ( timer_count < 6 )
                {
                    xprintf("wait for more %d Seconds! \r", 6 - timer_count);
                    if( uart_check_rx_buf())
                    {
                        uart_read_char();    //block here
                        currentState = MENU_STATE;
                        uart_send_string(menuStr);
                        uart_send_string(commandStr);
                        //timer_disable();
                    }
                }
                else
                {
                    currentState = START_APPLICATION_STATE;
                    //timer_disable();
                }
            }
            break;

            case MENU_STATE:
            {
                uart_read_string(command, 5);
                switch (command[0])
                {
                    case 'D':
                    case 'd':
                        ddr_test();
                        uart_send_string(commandStr);
                        break;

                    case 'S':
                    case 's':
                        SRAM_test();
                        uart_send_string(commandStr);
                        break;

                    case 'A':
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

static char checkApplication(void)
{
    return 1;
}


static void call_application()
{
    /* asm ("lui   x1, 0x10000 \n"
         "addi  x1, x1, 0x080 \n"
         "jalr  x0, 0(x1) \n" ); */

    while(1);
}

static void timerCallback(void)
{
    timer_count ++;
}


#define SRAM_BASE     TIM0_BASE
#define SRAM_OFFSET   (64*1024)    //64k
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



#define DDR_SIZE  64*1024   //512M 512*1024
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

