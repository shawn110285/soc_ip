
/*-----------------------------------------------------------------------------
// File:    utils.h
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


#ifndef _UTILS_H_
#define _UTILS_H_

#include <stdarg.h>

extern int put_char(char c);
extern int put_str(const char *str);
extern void put_hex(unsigned int  h);
extern void xvprintf(const char* fmt, va_list arp );
extern void xprintf (const char* fmt,  ... );

#endif /* _UTILS_H_ */
