# martin ebner, igi, tu graz, austria
# this script builds and reloads the linux aer driver
# this script must run once for each new kernel

UNAME := $(shell uname -r)
KERNEL26 := 2.6
KERNELVERSION := $(findstring $(KERNEL26),$(UNAME))

all:: retina_test

ifeq ($(KERNELVERSION),2.6)

obj-m	:= retina.o

KDIR	:= /lib/modules/$(shell uname -r)/build
PWD		:= $(shell pwd)

all::
	rm -f *.ko *.o 
	$(MAKE) -C $(KDIR) SUBDIRS=$(PWD) modules
	rm -f *~ *.symvers *.o *.mod.c
	
else

TARGET	:= retina
CFLAGS	:= -O2 -Wall -DMODULE -D__KERNEL__ -DLINUX
CC	:= gcc

#builds retina driver for linux
all:: ${TARGET}.o

${TARGET}.o: ${TARGET}.c
	$(CC) $(CFLAGS) ${INCLUDE} -c ${TARGET}.c
	
endif

retina_test: retina_test.c
	gcc -o $@ $<

install: 
#ubuntu:        add line "retina" to /etc/modules [finished]
#other distros: load module at boot time (modprobe retina)
#               i.e. /etc/rc.3/S10retina.sh
#               linking to /etc/init.d/retina
	@modprobe -r retina
	@install -v -c -m 644 retina.ko /lib/modules/`uname -r`/kernel/drivers/video
	@depmod -a
	@install -v -c -m 644 10-retina.rules /etc/udev/rules.d
	@modprobe retina
	@/etc/init.d/udev restart
	@sleep 1
	@ls -l /dev/retina?
	@if [ -r /etc/modules ] ; then \
		if ! less /etc/modules | grep retina ; then \
			echo retina >> /etc/modules; \
		fi; \
		echo "autoload at system boot [ubuntu/debian]"; \
	fi;
	@echo "retina driver module built for kernel `uname -r` and module installed.";
	