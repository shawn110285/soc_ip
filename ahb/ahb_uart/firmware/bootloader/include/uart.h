
/*-----------------------------------------------------------------------------
// File:    uart.h
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

#ifndef _UART_H_
#define _UART_H_

#include <stdint.h>

extern  void uart_init();
extern  void uart_send_char(uint8_t data);
extern  void uart_send_string(char *str);
extern  void uart_send_hex(unsigned int h);

extern  char uart_check_rx_buf();
extern  unsigned char uart_read_char();
extern  void uart_read_string(char *str, unsigned int length);

#endif /* _UART_H_ */