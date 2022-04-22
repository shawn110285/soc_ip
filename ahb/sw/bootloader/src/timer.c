
/*-----------------------------------------------------------------------------
// File:    timer.c
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


uint64_t get_cycle_value()
{
    uint64_t cycle;

    cycle = read_csr(cycle);
    cycle += (uint64_t)(read_csr(cycleh)) << 32;

    return cycle;
}


uint64_t timer_read(void)
{
    uint32_t current_timeh;
    uint32_t current_time;
    // check if time overflowed while reading and try again
    do
    {
        current_timeh = DEV_READ(TIMER_BASE + TIMER_MTIMEH);
        current_time = DEV_READ(TIMER_BASE + TIMER_MTIME);
    } while (current_timeh != DEV_READ(TIMER_BASE + TIMER_MTIMEH));

    uint64_t final_time = ((uint64_t)current_timeh << 32) | current_time;
    return final_time;
}


void timecmp_update(uint64_t new_time)
{
    DEV_WRITE(TIMER_BASE + TIMER_MTIMECMP, -1);
    DEV_WRITE(TIMER_BASE + TIMER_MTIMECMPH, new_time >> 32);
    DEV_WRITE(TIMER_BASE + TIMER_MTIMECMP, new_time);
}

inline static void increment_timecmp(uint64_t time_base)
{
    uint64_t current_time = timer_read();
    current_time += time_base;
    timecmp_update(current_time);
}



uint64_t time_increment;
callback sgfTimerCallback = 0;

void timer_enable(uint64_t time_base, callback timer_cb)
{
    time_increment = time_base;
    sgfTimerCallback = timer_cb;
    // Set timer values
    increment_timecmp(time_base);
    // enable timer interrupt
    asm volatile("csrs  mie, %0\n" : : "r"(0x80));
    // enable global interrupt
    asm volatile("csrs  mstatus, %0\n" : : "r"(0x8));
}


void simple_timer_handler(void)
{
    increment_timecmp(time_increment);
    if(0 != sgfTimerCallback)
        sgfTimerCallback();
}

void timer_disable(void)
{
    asm volatile("csrc  mie, %0\n" : : "r"(0x80));
}