
# ARCH = rv32im # to disable compressed instructions
ARCH ?= rv32imc
CC = riscv32-unknown-elf-gcc   # riscv64-unknown-elf-gcc

OBJCOPY ?= $(subst gcc,objcopy,$(wordlist 1,1,$(CC)))
OBJDUMP ?= $(subst gcc,objdump,$(wordlist 1,1,$(CC)))


COMMON_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

SRCS = $(wildcard $(COMMON_DIR)/src/*.c)
INCS := -I$(COMMON_DIR)/inc

C_SRCS = $(filter %.c, $(SRCS))
ASM_SRCS = $(filter %.S, $(SRCS))


CRT ?= $(COMMON_DIR)/src/crt0.S
OBJS := ${C_SRCS:.c=.o} ${ASM_SRCS:.S=.o} ${CRT:.S=.o}
DEPS = $(OBJS:%.o=%.d)

LINKER_SCRIPT ?= $(COMMON_DIR)/link.ld
CFLAGS ?= -march=$(ARCH) -mabi=ilp32 -static -mcmodel=medany -Wall -g -O0 \
	-fvisibility=hidden -nostdlib -nostartfiles -ffreestanding

HEXFLAGS = -O srec

PROGRAM = bootrom

INST_HEX = ${PROGRAM}_inst.hex
DATA_HEX = ${PROGRAM}_data.hex

OUTFILES := $(PROGRAM).dis $(PROGRAM).elf $(PROGRAM).bin $(PROGRAM).dump $(PROGRAM).vmem $(PROGRAM).hex

all: $(OUTFILES)

$(PROGRAM).elf: $(OBJS) $(LINKER_SCRIPT)
	$(CC) $(CFLAGS) -T $(LINKER_SCRIPT) $(OBJS) -o $@ $(LIBS)

%.dis: %.elf
	$(OBJDUMP) -fhSD $^ > $@

%.hex: %.elf
	${OBJCOPY} ${HEXFLAGS} $< ${INST_HEX} -j .text*  -j .rodata* -j .eh_frame*
	${OBJCOPY} ${HEXFLAGS} $< ${DATA_HEX} -j .data*  -j .bss -j .COMMON
	${OBJCOPY} ${HEXFLAGS} $< $@

%.dump: %.elf
	$(OBJDUMP) --disassemble-all $< > $@

%.bin: %.elf
	$(OBJCOPY) -O binary $^ $@

%.vmem: %.bin
	srec_cat $^ -binary -offset 0x0000 -o $@ -vmem

#	srec_cat $^ -binary -offset 0x0000 -byte-swap 4 -o $@ -vmem   # -byte-swap depends on your requirement

%.o: %.c
	$(CC) $(CFLAGS) -MMD -c $(INCS) -o $@ $<

%.o: %.S
	$(CC) $(CFLAGS) -MMD -c $(INCS) -o $@ $<

clean:
	$(RM) -f $(OBJS) $(DEPS) $(OUTFILES) $(INST_HEX) $(DATA_HEX)

distclean: clean
	$(RM) -f $(OUTFILES)
