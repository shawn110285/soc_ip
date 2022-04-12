
/*-----------------------------------------------------------------------------
// File:    timer.h
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


#ifndef __TIMER_H__
#define __TIMER_H__

#include <stdint.h>

#define TIMER_BASE           CLIC_BASE

#define TIMER_MTIMECMP       0x4000
#define TIMER_MTIMECMPH      0x4004

#define TIMER_MTIME          0xBFF8
#define TIMER_MTIMEH         0xBFFC

typedef void (*callback)(void);

uint64_t get_cycle_value();
uint64_t timer_read(void);
void timecmp_update(uint64_t new_time);
void timer_enable(uint64_t time_base, callback timer_cb);
void timer_disable(void);
void simple_timer_handler(void);
#endif  // __TIMER_H__
