How to transfer a firmware upgrade (HEX file) to your eDVS:
J. Conradt. July 2011.

1)      Download and install NXP’s flashmagic tool: www.flashmagictool.com

2)      Powercycle eDVS (disconnect / reconnect USB cable). Wait for COM port to appear.

3)      Open terminal program (terminal.exe in the jAER/Utilities folder works on Windows 7), send “R<return>” (Reset) to eDVS. Wait briefly. Send “P<return>” to eDVS. Close COM port. Ensure you press no further keys after “P<return>”. eDVS will change into reprogramming mode.

4)      Start Flashmagic software.

5)      Step 1: Select Device “LPC2106”, COM port (to match your connection), BaudRate 19200, Interface “None (ISP)”, Oscillator (MHz) “16”.

6)      Step 2: tick the box “Erase all Flash+Code ...”

7)      Step 3: select the HEX file for the firmware upgrade.

8)      Step 4: tick the box “Verify after programming”. Do not tick “Fill unused Flash”.

9)      Step 5: press Start. Wait about 60 seconds. Flashmagic will reprogram and verify your eDVS.

10)   After reprogramming finished (see message at bottom of window) power-cycle eDVS (or alternatively use flashmagic menu “ISP” -> “Go ...” and start program at address 0 (default).

 

You have updated your system. Check the welcome message after reset/power on for the new revision.

 

If item (9) “Step 5” (Start) fails with the message “failed to autobaud”, please repeat procedure from (including) item (2), possibly reducing the baud rate selected in item (5) (“Step 1”).

Hint: You can select much higher baud rates as fractions of the crystal frequency (16MHz), e.g. 31250, 62500, 125000. The Flashmagic GUI does not provide these baud rates, but the command line interface “FM” does. Your choice.


--
Jörg Conradt
Prof. of Neuroscientific System Theory      www.nst.ei.tum.de
Cluster "Cognition for Technical Systems"   www.cotesys.org
Institute of Automatic Control Engineering  www.lsr.ei.tum.de
Technische Universität München, Karlstr. 45, 80333 Munich, Germany
Tel: +49 89 289-26925, Fax: +49 89 289-26913, E-mail: conradt@tum.de


Here some further info:

 

- the timer (Timer 1) is 32 bit (LPC2106 user manual, chapter 14, page 183).

 

- the timer is running at full speed, i.e. 64MHz. It’s exactly 64MHz:   16 MHz crystal * 4 (PLL)

 

- I use changes in the timer capture register to disambiguate successive events (from noise on the bus). Each “request” from DVS will capture a new timestamp (in hardware; no interrupt, no polling, etc.) into register T1_CR0. Therefore, the max total event rate is limited to 64M-events per second (which we will never reach anyways).

 

- in the mainloop (file mainloop.c) --- where all work happens after initialization --- lines 159ff capture new events:

  - line 159 fetches the last captured timestamp from the timer (32 bit, at full 64MHz time resolution)

  - line 174-177 shift the timestamp by 6 (so divide by 64), keep only the 16 LSB, and store the timestamp in the 16 LSB of newDVSEvent.

So taken all together we should get a timestamp from 0x0000 (0) to 0xFFFF (65535), with each step representing a microsecond (64 MHz / 64).

 

- you can check that the code until here works well when setting output mode “!E31” (human readable decimal with timestamps).

  The timestamps wrap around at 65535. Also, when I record about 2 seconds of real time data, I see 35 “wrap around” --- which corresponds to 35 * 65ms = 2,3 seconds. Seems all right to me.

 

 

- transmitting timestamps in the most compact data format “!e1” happens in lines 491ff (EDVS_DATA_FORMAT_BIN_TS). TXBuffer[3] is sent first, TXBuffer[0] is sent last. I am sending MSB first. Maybe the Java program is swapping those two bytes for the time stamp? That, however, would result in a timestamp overrun every 65ms / 256 = 0,25ms...

 

 

 
 
 
 
 