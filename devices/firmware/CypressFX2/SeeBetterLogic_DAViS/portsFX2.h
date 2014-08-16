/** register definitions for ports - note that not all are port addressable.
Depends on fx2regs.h
*/

#ifndef portsfx2_dot_h
#define portsfx2_dot_h

sbit PA0=IOA^0;
sbit PA1=IOA^1;
sbit PA2=IOA^2;
sbit PA3=IOA^3;
sbit PA4=IOA^4;
sbit PA5=IOA^5;
sbit PA6=IOA^6;
sbit PA7=IOA^7;

sbit PB0=IOB^0;
sbit PB1=IOB^1;
sbit PB2=IOB^2;
sbit PB3=IOB^3;
sbit PB4=IOB^4;
sbit PB5=IOB^5;
sbit PB6=IOB^6;
sbit PB7=IOB^7;

sbit PC0=IOC^0;
sbit PC1=IOC^1;
sbit PC2=IOC^2;
sbit PC3=IOC^3;
sbit PC4=IOC^4;
sbit PC5=IOC^5;
sbit PC6=IOC^6;
sbit PC7=IOC^7;

sbit PD0=IOD^0;
sbit PD1=IOD^1;
sbit PD2=IOD^2;
sbit PD3=IOD^3;
sbit PD4=IOD^4;
sbit PD5=IOD^5;
sbit PD6=IOD^6;
sbit PD7=IOD^7;

// Port E is not bit addressable, so we provide macros for it.
#define PE0 0x01
#define PE1 0x02
#define PE2 0x04
#define PE3 0x08
#define PE4 0x10
#define PE5 0x20
#define PE6 0x40
#define PE7 0x80

#define setPE(BIT_MASK, VALUE) (VALUE == 0) ? (IOE &= ~BIT_MASK) : (IOE |= BIT_MASK)

#define getPE(BIT_MASK) ((IOE & BIT_MASK) != 0)

#endif
