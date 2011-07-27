CC = iccarm
LIB = ilibarm-elf
CFLAGS =  -e -D__ICC_VERSION="7.09" -DLPC2106  -l -A -A -g 
ASFLAGS = $(CFLAGS) 
LFLAGS =  -g -ucrtlpc2k.o -fintelhex -cf:EDVS128_2106.cmd
FILES = EDVS128_2106.o MainLoop.o DVS128Chip.o UART.o PWM246.o EP_TrackHFL.o 

EDVS128_2106:	$(FILES)
	$(CC) -o EDVS128_2106 $(LFLAGS) @EDVS128_2106.lk   -llpARM -lcarm
EDVS128_2106.o: .\..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\EDVS128_2106.h .\..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\lpc210x_01.h C:\PROGRA~1\iccv7arm\include\stdio.h C:\PROGRA~1\iccv7arm\include\stdarg.h C:\PROGRA~1\iccv7arm\include\_const.h C:\PROGRA~1\iccv7arm\include\arm_macros.h
EDVS128_2106.o:	..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\EDVS128_2106.c
	$(CC) -c $(CFLAGS) ..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\EDVS128_2106.c
MainLoop.o: .\..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\EDVS128_2106.h .\..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\lpc210x_01.h C:\PROGRA~1\iccv7arm\include\stdio.h C:\PROGRA~1\iccv7arm\include\stdarg.h C:\PROGRA~1\iccv7arm\include\_const.h C:\PROGRA~1\iccv7arm\include\arm_macros.h
MainLoop.o:	..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\MainLoop.c
	$(CC) -c $(CFLAGS) ..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\MainLoop.c
DVS128Chip.o: .\..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\EDVS128_2106.h .\..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\lpc210x_01.h C:\PROGRA~1\iccv7arm\include\stdio.h C:\PROGRA~1\iccv7arm\include\stdarg.h C:\PROGRA~1\iccv7arm\include\_const.h C:\PROGRA~1\iccv7arm\include\arm_macros.h
DVS128Chip.o:	..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\DVS128Chip.c
	$(CC) -c $(CFLAGS) ..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\DVS128Chip.c
UART.o: .\..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\EDVS128_2106.h .\..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\lpc210x_01.h C:\PROGRA~1\iccv7arm\include\stdio.h C:\PROGRA~1\iccv7arm\include\stdarg.h C:\PROGRA~1\iccv7arm\include\_const.h C:\PROGRA~1\iccv7arm\include\arm_macros.h
UART.o:	..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\UART.c
	$(CC) -c $(CFLAGS) ..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\UART.c
PWM246.o: .\..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\EDVS128_2106.h .\..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\lpc210x_01.h C:\PROGRA~1\iccv7arm\include\stdio.h C:\PROGRA~1\iccv7arm\include\stdarg.h C:\PROGRA~1\iccv7arm\include\_const.h C:\PROGRA~1\iccv7arm\include\arm_macros.h
PWM246.o:	..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\PWM246.c
	$(CC) -c $(CFLAGS) ..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\PWM246.c
EP_TrackHFL.o: .\..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\EDVS128_2106.h .\..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\lpc210x_01.h C:\PROGRA~1\iccv7arm\include\stdio.h C:\PROGRA~1\iccv7arm\include\stdarg.h C:\PROGRA~1\iccv7arm\include\_const.h C:\PROGRA~1\iccv7arm\include\arm_macros.h
EP_TrackHFL.o:	..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\EP_TrackHFL.c
	$(CC) -c $(CFLAGS) ..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1\EP_TrackHFL.c
