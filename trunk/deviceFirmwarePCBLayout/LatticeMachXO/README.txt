These designs use a Lattice CPLD. To build these designs, install the Lattice Diamond tools from
	http://www.latticesemi.com/ 
(signup needed to download).

After signup (confirming email, sometimes email takes up to 2 hours to come because of institutional spam blockers), download Lattice Diamond either 32 or 64 bit depending on your windows version.

Programming the Lattice parts requires a Lattice programmer for Cypress FX firmware that does not yet support USB upgrade of CPLD.
The USB programmer costs about $170 on USA web site.

You do not need to install the FPGA tools.
You can choose Node locked license.

You need to request a free license http://www.latticesemi.com/licensing/flexlmlicense.cfm?p=diamond .  To request license ou need the MAC ID "Host NIC". You can get this with "ipconfig/all" from a cmd window and look for the active ethernet adaptor.
After license request the email comes in about 30 minutes.
If you are already using Xilinx tools you may already have set LM_LICENSE_SERVER to a network server. In this case, use a license string like this: 
	2100@license.ini.uzh.ch;C:\lscc\diamond\2.1_x64\license\license.dat
Note the semicolon separates the two places licenses are looked for.














