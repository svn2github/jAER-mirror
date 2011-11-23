MEMORY
{
	STARTUP(RO):	o = 00000000 l = 0x000100
	ROM(RO):		o = 0x000100 l = 0x01ff00
	RAM(RW):		o = 0x40000000 l = 0x010000
}

SECTIONS
{
	C$$init	> STARTUP
	C$$code	> ROM
	C$Thumb	> ROM
	Cidata	> RAM
	CTidata	> RAM
	Cudata	> RAM
}
$icc$SP_VALUE = 0x4000fffc;
$icc$IRQ_VALUE = 0x000028;
$icc$FIQ_VALUE = 0x000028;
$icc$REMAP = 0;
