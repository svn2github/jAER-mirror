//*****************************************************************************
//
// cr_start_m0.h
//
// Provides function for CM4 'master' CPU in an NXP LPC43xx MCU to release
// CM0 'slave' CPUs from reset and begin executing.
//
// Version : 130731
//
//*****************************************************************************
//
// Copyright(C) NXP Semiconductors, 2013
// All rights reserved.
//
// Software that is described herein is for illustrative purposes only
// which provides customers with programming information regarding the
// LPC products.  This software is supplied "AS IS" without any warranties of
// any kind, and NXP Semiconductors and its licensor disclaim any and
// all warranties, express or implied, including all implied warranties of
// merchantability, fitness for a particular purpose and non-infringement of
// intellectual property rights.  NXP Semiconductors assumes no responsibility
// or liability for the use of the software, conveys no license or rights under any
// patent, copyright, mask work right, or any other intellectual property rights in
// or to any products. NXP Semiconductors reserves the right to make changes
// in the software without notification. NXP Semiconductors also makes no
// representation or warranty that such application will be suitable for the
// specified use without further testing or modification.
//
// Permission to use, copy, modify, and distribute this software and its
// documentation is hereby granted, under NXP Semiconductors' and its
// licensor's relevant copyrights in the software, without fee, provided that it
// is used in conjunction with NXP Semiconductors microcontrollers.  This
// copyright, permission, and disclaimer notice must appear in all copies of
// this code.
//*****************************************************************************

#ifndef CR_START_M0_H_
#define CR_START_M0_H_

#define SLAVE_M0APP 0
#define SLAVE_M0SUB 1

#include <stdint.h>

#ifdef __cplusplus
extern "C"
{
#endif

extern uint8_t __core_m0app_START__;

// This variable is used to make sure the M0 core is ready to continue
extern volatile uint32_t __core_m0_has_started__;

/**
 * It starts the M0. It sets up the M0 shadow pointer and it releases the M0
 * from reset.
 * @param CM0image_start the pointer for the M0 image
 */
extern void cr_start_m0(uint8_t *CM0image_start);

/**
 * It stops the M0 core by activatting its reset.
 */
extern void haltSlave(void);

#ifdef __cplusplus
}
#endif

#endif /* CR_START_M0_H_ */
