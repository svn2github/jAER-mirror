/** register definitions for ports - note that not all are port addressable.
Depends on fx2regs.h
*/

#ifndef portsfx2_dot_h
#define portsfx2_dot_h 1

// Defines all other ports.
#include <fx2.h>
#include <fx2regs.h>

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
