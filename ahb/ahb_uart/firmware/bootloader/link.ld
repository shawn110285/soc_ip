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
    } > ddr

    .text :
    {
        . = ALIGN(4);
        *(.text)
        *(.text.*)
    }  > ddr

    .rodata :
    {
        . = ALIGN(4);
        /* Small RO data before large RO data */
        *(.srodata)
        *(.srodata.*)
        *(.rodata);
        *(.rodata.*)
    } > ddr

    .data :
    {
        . = ALIGN(4);
        /* Small data before large data */
        *(.sdata)
        *(.sdata.*)
        *(.data);
        *(.data.*)
    } > ddr

    .sdata :
    {
        __global_pointer$ = . + 0x400;
        *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata*)
        *(.sdata .sdata.* .gnu.linkonce.s.*)
    } > ddr

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
    } > ddr


    /* ensure there is enough room for stack */
    .stack (NOLOAD):
    {
        . = ALIGN(4);
        . = . + _min_stack ;
        _stack_start = . ;
    } > ddr
}
