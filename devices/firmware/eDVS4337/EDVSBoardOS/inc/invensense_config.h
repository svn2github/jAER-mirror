/*
 * inv_config.h
 *
 *  Created on: 14/07/2014
 *      Author: ruka
 */

#ifndef INV_CONFIG_H_
#define INV_CONFIG_H_

#include "utils.h"
#include "xprintf.h"
#include <math.h>
#define delay_ms    timerDelayMs
#define get_ms      getTimerMs
#define log_i     xprintf
#define log_e     xprintf
extern int i2c_write(uint8_t slave_addr, uint8_t reg_addr, uint8_t length, uint8_t const *data);
extern int i2c_read(uint8_t slave_addr, uint8_t reg_addr, uint8_t length, uint8_t *data);
static inline int reg_int_cb(struct int_param_s *int_param) {
	return 0; //Not using interrupts
}

static inline void __no_operation() {
	__NOP();
}
/* labs is already defined by TI's toolchain. */
/* fabs is for doubles. fabsf is for floats. */
#define fabs        fabsf
#define min(a,b) 	((a<b)?a:b)

#endif /* INV_CONFIG_H_ */
