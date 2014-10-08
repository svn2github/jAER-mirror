// header for USB_Main.c and Config.c
// uncomment one of the following

#define DVS128_PAER
//#define TMPDIFF128_CAVIAR


#ifdef TMPDIFF128_CAVIAR
#define HANDSHAKE_ENABLED // enables handshaking with NOTACK for Tmpdiff128 CAVIAR board.  Comment for PAER board
#endif