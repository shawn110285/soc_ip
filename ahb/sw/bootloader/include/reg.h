/*-----------------------------------------------------------------------------
// File:    reg.h
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


#ifndef __SOC_REGS_H__
#define __SOC_REGS_H__

#include <stdint.h>

#define DEV_WRITE(addr, val) (*((volatile uint32_t *)(addr)) = val)
#define DEV_READ(addr) (*((volatile uint32_t *)(addr)))

#define read_csr(reg) ({ unsigned long __tmp; \
  asm volatile ("csrr %0, " #reg : "=r"(__tmp)); \
  __tmp; })

#define write_csr(reg, val) ({ \
    asm volatile ("csrw " #reg ", %0" :: "r"(val)); })


#define SYSTEM_CLK_FREQ   (50*1000000)    /*50 MHZ*/


/*========================= timer related reg =======================*/
#define DEBUG_ROM_BASE          0x00000000
#define DEBUG_ROM_TOP           0x00001000

#define CLIC_BASE               0x02000000    //timer
#define CLIC_TOP                0x03000000

#define PERIPH_PORT_BASE        0x20000000    //UART
#define PERIPH_PORT_TOP         0x30000000

#define SYSTEM_PORT_BASE        0x40000000    //SDRAM
#define SYSTEM_PORT_TOP         0x80000000

#define TIM0_BASE               0x80000000    //SRAM, 64k
#define TIM0_TOP                0x80010000

#define TIM1_BASE               0x80010000    //SRAM, 64k
#define TIM1_TOP                0x80008000


extern unsigned int get_mepc();
extern unsigned int get_mcause();
extern unsigned int get_mtval();
extern unsigned int get_mtvec();

#endif  // __SOC_REGS_H__
