/*-----------------------------------------------------------------------------
// File:    flash.c
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

#include "../include/flash.h"


void flash_init(void)
{
    /*
    FCTL2 = FWKEY + FSSEL_2 + FN3;
    */
}

/* Segment size is 512B */
void flash_erase_segment(unsigned char * addr)
{
    /*
    unsigned char *ptr;

    ptr = addr;
    FCTL1 = FWKEY + ERASE;
    FCTL3 = FWKEY;

    *ptr = 0xFF;
    while (FCTL3 & BUSY);

    FCTL1 = FWKEY;
    FCTL3 = FWKEY + LOCK;
    */
}

void flash_write_byte(unsigned char * addr, unsigned char data)
{
    /*
    unsigned char *ptr;

    ptr = addr;
    FCTL1 = FWKEY + WRT;
    FCTL3 = FWKEY;

    *ptr = data;
    while (FCTL3 & BUSY);

    FCTL1 = FWKEY;
    FCTL3 = FWKEY + LOCK;
    */
}