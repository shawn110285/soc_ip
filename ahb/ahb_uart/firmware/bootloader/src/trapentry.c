/*-----------------------------------------------------------------------------
// File:    trapentry.c
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

#include <stdint.h>
#include "../include/reg.h"
#include "../include/timer.h"
#include "../include/uart.h"
#include "../include/utils.h"


static uint32_t readmcause()
{
    unsigned long long  val;
    asm volatile("csrr %0, mcause" : "=r"(val));
    return val;
}


void general_exeception_handler()
{
    uart_send_string("exception handler!!! \r\n");
    uart_send_string("============ \r\n");
    uart_send_string("\r\nMTVEC:  0x");
    uart_send_hex(get_mtvec());
    uart_send_string("\r\nMEPC:   0x");
    uart_send_hex(get_mepc());
    uart_send_string("\r\nMCAUSE: 0x");
    uart_send_hex(get_mcause());
    uart_send_string("\r\nMTVAL:  0x");
    uart_send_hex(get_mtval());
    uart_send_string("\r\nhalt the processor\r\n");
    while(1);
}

void handle_trap(uintptr_t cause, uintptr_t  epc, uintptr_t regs[32])
{
    if(readmcause() == 0x80000007)  //timer interrupt
    {
        simple_timer_handler();
    }
    else
    {
        general_exeception_handler();
    }

    // save the redirect PC to a0, trap_entry in crt.s will reset the mepc with the a0
    // epc += 70;  // if require, you could update the mepc here
    asm ("mv a0, %0 \n" : :"r" (epc));
}
