UNAME := $(shell uname -r)
KERNEL26 := 2.6
KERNELVERSION := $(findstring $(KERNEL26),$(UNAME))

all:: retina_test

ifeq ($(KERNELVERSION),2.6)

obj-m	:= retina.o

KDIR	:= /lib/modules/$(shell uname -r)/build
PWD		:= $(shell pwd)

all::
	$(MAKE) -C $(KDIR) SUBDIRS=$(PWD) modules
	
else

TARGET	:= retina
CFLAGS	:= -O2 -Wall -DMODULE -D__KERNEL__ -DLINUX
CC	:= gcc

all:: ${TARGET}.o

${TARGET}.o: ${TARGET}.c
	$(CC) $(CFLAGS) ${INCLUDE} -c ${TARGET}.c
	
endif

retina_test: retina_test.c
	gcc -o $@ $<
