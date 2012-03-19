/* AER defines and macros */

#define XMASK 0xf7
#define XSHIFT 1
#define YMASK 0x7f
#define YSHIFT 8
#define POLMASK 1
#define getX(a) ((a&XMASK)>>>XSHIFT)
