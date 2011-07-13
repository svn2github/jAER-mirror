
obj-m	:= retina.o

# if we want warnings to be fatal:
EXTRA_CFLAGS += -Werror

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

install: all
	mkdir -p /lib/modules/$(shell uname -r)/extra/
	cp retina.ko /lib/modules/$(shell uname -r)/extra/
	depmod -a
	cp 88-retina.rules /etc/udev/rules.d/

uninstall:
	rmmod -s retina || true
	rm /lib/modules/*/kernel/drivers/video/retina.ko || true
	rm /lib/modules/*/extra/retina.ko || true
	rm /etc/udev/rules.d/88-retina.rules || true

load:
	sync
	modprobe retina

unload:
	modprobe -r retina

reload: unload load

usbtestkill:
	rmmod -s usbtest || true
	echo "blacklist usbtest" >/etc/modprobe.d/blacklist-usbtest.conf
	find /lib/modules/ -name aerfx2.ko -exec rm '{}' ';' || true
	depmod -a
