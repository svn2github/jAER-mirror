/** register definitions for ports - note that not all are port addressable.
Depends on fx2regs.h
*/

#ifndef portsfx2_dot_h
#define portsfx2_dot_h

#define _IFREQ  30000            // IFCLK constant for Synchronization Delay
#define _CFREQ  48000            // CLKOUT constant for Synchronization Delay

// Defines all other ports.
#include <fx2.h>
#include <fx2regs.h>
#include <syncdly.h> // SYNCDELAY macro

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

// These are the definitions that map functionality to a port.
#define CPLD_TDI PC7
#define CPLD_TDO PC6
#define CPLD_TCK PC5
#define CPLD_TMS PC4

#define CPLD_SPI_SSN PC3 // is active-low
#define CPLD_SPI_CLOCK PC2
#define CPLD_SPI_MOSI PC1
#define CPLD_SPI_MISO PC0

#define CPLD_RESET PE7
#define FXLED PE6

#define BIAS_CLOCK PE5 // is active-low
#define BIAS_BIT PE4
// PE3 not used currently (CPLD internal)
#define BIAS_DIAG_SELECT PE2
#define BIAS_LATCH PE1 // is active-low
#define BIAS_ADDR_SELECT PE0 // is active-low

#endif
