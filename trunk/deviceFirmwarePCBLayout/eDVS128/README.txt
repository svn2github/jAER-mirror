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

 