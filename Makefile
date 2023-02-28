default: none

export VERILATOR ?= /opt/verilator/bin/verilator
export SYSTEMC ?= /opt/systemc
export RISCVDV ?= /opt/riscv-dv
export RISCV ?= /opt/rv32imc/bin/riscv32-unknown-elf-
export MARCH ?= rv32imc
export MABI ?= ilp32
export ITER ?= 10
export CSMITH ?= /opt/csmith
export GCC ?= /usr/bin/gcc
export PYTHON ?= /usr/bin/python3
export BASEDIR ?= $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
export OFFSET ?= 0x100000# Number of dwords in blockram (address range is OFFSET * 8)
export PROGRAM ?= dhrystone# aapg bootloader compliance coremark csmith dhrystone isa riscv-dv sram timer
export AAPG ?= aapg
export CYCLES ?= 10000000000
export FPGA ?= quartus# tb vivado quartus
export WAVE ?= off# "on" for saving dump file

generate:
	soft/compile.sh

simulate:
	sim/run.sh

all: generate simulate
