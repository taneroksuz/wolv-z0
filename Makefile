default: none

export XVLOG ?= xvlog # execute "source settings64.sh" in Vivado installation folder
export XELAB ?= xelab
export XSIM ?= xsim
export RISCV ?= /opt/rv32imc/bin/riscv32-unknown-elf-
export OPTS ?= -O3 -fno-common -funroll-loops -finline-functions -falign-functions=16 -falign-jumps=4 -falign-loops=4 -finline-limit=1000
export MARCH ?= rv32imc_zicsr_zifencei
export MABI ?= ilp32
export ITER ?= 10
export CSMITH ?= /opt/csmith
export GCC ?= /usr/bin/gcc
export PYTHON ?= /usr/bin/python3
export SERIAL ?= /dev/ttyUSB0
export BASEDIR ?= $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
export PROGRAM ?= dhrystone# bootloader compliance coremark csmith dhrystone isa sram timer
export MAXTIME ?= 10000000
export OFFSET ?= 0x100000
export DUMP ?= off# "on" for saving dump file

generate:
	soft/compile.sh

simulate:
	sim/run.sh

send:
	serial/transfer.sh

all: generate simulate
