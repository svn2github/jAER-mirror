//*****************************************************************************
//   +--+
//   | ++----+
//   +-++    |
//     |     |
//   +-+--+  |
//   | +--+--+
//   +----+    Copyright (c) 2013 Code Red Technologies Ltd.
//
// cr_start_m0.c
//
// Provides function for CM4 'master' CPU in an NXP LPC43xx MCU to release
// CM0 'slave' CPUs from reset and begin executing.
//
// Version : 130410
//
// Software License Agreement
//
// The software is owned by Code Red Technologies and/or its suppliers, and is
// protected under applicable copyright laws.  All rights are reserved.  Any
// use in violation of the foregoing restrictions may subject the user to criminal
// sanctions under applicable laws, as well as to civil liability for the breach
// of the terms and conditions of this license.
//
// THIS SOFTWARE IS PROVIDED "AS IS".  NO WARRANTIES, WHETHER EXPRESS, IMPLIED
// OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE.
// USE OF THIS SOFTWARE FOR COMMERCIAL DEVELOPMENT AND/OR EDUCATION IS SUBJECT
// TO A CURRENT END USER LICENSE AGREEMENT (COMMERCIAL OR EDUCATIONAL) WITH
// CODE RED TECHNOLOGIES LTD.
//
//*****************************************************************************

#include <cr_section_macros.h>
#include "chip.h"
#include "cr_start_m0.h"
#include "config.h"

// Provide defines for accessing peripheral registers necessary to release
// CM0 slave processors from reset. Note that this code does not use the
// CMSIS register access mechanism, as there is no guarantee that the
// project has been configured to use CMSIS.
#define RGU_RESET_CTRL1	          (*((volatile uint32_t *) 0x40053104))
#define RGU_RESET_ACTIVE_STATUS1  (*((volatile uint32_t *) 0x40053154))
#define RGU_RESET_CTRL0	          (*((volatile uint32_t *) 0x40053100))
#define RGU_RESET_ACTIVE_STATUS0  (*((volatile uint32_t *) 0x40053150))
#define CREG_M0APPMEMMAP	        (*((volatile uint32_t *) 0x40043404))
__DATA(RAM6) volatile uint32_t __core_m0_has_started__ = 0;

#if LOW_POWER_MODE
void M0APP_IRQHandler(void){
	Chip_CREG_ClearM0AppEvent();
}
#endif

/*******************************************************************
 * Static function to Release SLAVE processor from reset
 *******************************************************************/
static void startSlave(void) {

	volatile uint32_t u32REG, u32Val;

	/* Release Slave from reset, first read status */
	/* Notice, this is a read only register !!! */
	u32REG = RGU_RESET_ACTIVE_STATUS1;

	/* If the M0 is being held in reset, release it */
	/* 1 = no reset, 0 = reset */
	while (!(u32REG & (1u << 24))) {
		u32Val = (~(u32REG) & (~(1 << 24)));
		RGU_RESET_CTRL1 = u32Val;
		u32REG = RGU_RESET_ACTIVE_STATUS1;
	};

}

/*******************************************************************
 * Static function to put the SLAVE processor back in reset
 *******************************************************************/
void haltSlave(void) {

	volatile uint32_t u32REG, u32Val;
	/* Check if M0 is reset by reading status */
	u32REG = RGU_RESET_ACTIVE_STATUS1;

	/* If the M0 has reset not asserted, halt it... */
	/* in u32REG, status register, 1 = no reset */
	while ((u32REG & (1u << 24))) {
		u32Val = ((~u32REG) | (1 << 24));
		RGU_RESET_CTRL1 = u32Val;
		u32REG = RGU_RESET_ACTIVE_STATUS1;
	}
}

/*******************************************************************
 * Function to start required CM0 slave cpu executing
 *******************************************************************/
void cr_start_m0(uint8_t *CM0image_start) {

	// Make sure M0 is not running
	haltSlave();

	// Set M0's vector table to point to start of M0 image
	CREG_M0APPMEMMAP = (uint32_t) CM0image_start;
	__core_m0_has_started__ = 0; //the M0 will set this variable to 1
#if LOW_POWER_MODE
	NVIC_EnableIRQ(M0APP_IRQn);
#endif
	// Release M0 from reset
	startSlave();
	while (!__core_m0_has_started__) {
		;//Wait for the M0 to be ready
	}
}
