/*-----------------------------------------------------------------------------
// File:    reg.c
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

#include "../include/reg.h"

unsigned int get_mepc()
{
    uint32_t result;
    __asm__ volatile("csrr %0, mepc;" : "=r"(result));
    return result;
}

unsigned int get_mcause()
{
    uint32_t result;
    __asm__ volatile("csrr %0, mcause;" : "=r"(result));
    return result;
}

unsigned int get_mtval()
{
    uint32_t result;
    __asm__ volatile("csrr %0, mtval;" : "=r"(result));
    return result;
}


unsigned int get_mtvec()
{
    uint32_t result;
    __asm__ volatile("csrr %0, mtvec;" : "=r"(result));
    return result;
}
