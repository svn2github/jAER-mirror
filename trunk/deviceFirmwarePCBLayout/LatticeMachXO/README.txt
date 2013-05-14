These designs use a Lattice CPLD. To build these designs, install the Lattice Diamond tools from
http://www.latticesemi.com/ (signup needed).

After signup (confirming email, sometimes email takes up to 2 hours to come because of institutional spam blockers), download Lattice Diamond either 32 or 64 bit depending on your windows version.

Programming the Lattice parts requires a Lattice programmer for Cypress FX firmware that does not yet support USB upgrade of CPLD.
The USB programmer costs about $170 on USA web site.

You DO need to install the FPGA tools to get the stuff for MachXO.
You can choose Node locked license.

You need to request a free license http://www.latticesemi.com/licensing/flexlmlicense.cfm?p=diamond .  To request license ou need the MAC ID "Host NIC". You can get this with "ipconfig/all" from a cmd window and look for the active ethernet adaptor.
After license request the email should come in a little while.
If you are already using Xilinx tools you may already have set LM_LICENSE_SERVER to a network server. In this case, set your LM_LICENSE_FILE as in the example below, uing the Xilinx Manage Licenses tool or an environment variable editor:
	LM_LICENSE_FILE=2100@license.ini.uzh.ch;C:\lscc\license\license.dat
replacing these paths with your license server details (the first one is for our Xilinx network license and the second one points to the Lattice node-locked license).














