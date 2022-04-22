/*-----------------------------------------------------------------------------
// File:    link.ld
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

OUTPUT_ARCH( "riscv" )
ENTRY(_start)

/*----------------------------------------------------------------------*/
/* Sections                                                             */
/*----------------------------------------------------------------------*/


MEMORY
{
    /* 992 kB should be enough for anybody... */
    tim0         : ORIGIN = 0x80000000, LENGTH = 64K
    tim1         : ORIGIN = 0x80010000, LENGTH = 64K
    ddr          : ORIGIN = 0x40000000, LENGTH = 64K
}

_min_stack = 4096;   /* 512 - minimum stack space to reserve */

SECTIONS
{
    .vectors :
    {
        . = ALIGN(4);
        _vectors_start = .;
        KEEP(*(.vectors))
        _vectors_end = .;
    } > tim0

    .text :
    {
        . = ALIGN(4);
        *(.text)
        *(.text.*)
    }  > tim0

    .rodata :
    {
        . = ALIGN(4);
        /* Small RO data before large RO data */
        *(.srodata)
        *(.srodata.*)
        *(.rodata);
        *(.rodata.*)
    } > tim0

    .data :
    {
        . = ALIGN(4);
        /* Small data before large data */
        *(.sdata)
        *(.sdata.*)
        *(.data);
        *(.data.*)
    } > tim0

    .sdata :
    {
        __global_pointer$ = . + 0x400;
        *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata*)
        *(.sdata .sdata.* .gnu.linkonce.s.*)
    } > tim0

    .bss :
    {
        . = ALIGN(4);
        _bss_start = .;
        /* Small BSS before large BSS */
        *(.sbss)
        *(.sbss.*)
        *(.bss)
        *(.bss.*)
        *(COMMON)
        _bss_end = .;
    } > tim0


    /* ensure there is enough room for stack */
    .stack (NOLOAD):
    {
        . = ALIGN(4);
        . = . + _min_stack ;
        _stack_start = . ;
    } > tim0
}
