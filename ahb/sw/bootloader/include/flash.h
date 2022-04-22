/*-----------------------------------------------------------------------------
// File:    flash.h
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



#ifndef _FLASH_H_
#define _FLASH_H_

void flash_init(void);
void flash_erase_segment(unsigned char * addr);
void flash_write_byte(unsigned char * addr, unsigned char data);

#endif /* _FLASH_H_ */