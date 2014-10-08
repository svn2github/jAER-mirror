#ifndef __PORT_H__
#define __PORT_H__

/*
 * Copyright June 13, 2011 Andreas Steiner, Inst. of Neuroinformatics, UNI-ETH Zurich
 * This file is part of uart_MDC2D.

 * uart_MDC2D is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * uart_MDC2D is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with uart_MDC2D.  If not, see <http://www.gnu.org/licenses/>.
 */
 
/*! \file port.h
 * contains preprocessor definitions for accessing the microcontroller's pins
 */

#include "config.h"

void port_init();



// platform is defined in config.h
#ifdef PLATFROM_DSDEVEL

#define PORT_SW1 (!_RA4)
#define PORT_SW2 (!_RA3)

#define PORT_LED _LATA4
#define PORT_LED_TOGGLE (PORT_LED ^= 1)
#define PORT_LED_READ _RA4

#define PORT_PIN27 _LATA0
#define PORT_PIN28 _LATA1
#define PORT_PIN7 _LATA3
#define PORT_PIN9 _LATA4

#define PORT_PIN3 _LATB2
#define PORT_PIN4 _LATB3
#define PORT_PIN8 _LATB4

#define PORT_PIN19 _LATB11
#define PORT_PIN20 _LATB12
#define PORT_PIN21 _LATB13
#define PORT_PIN22 _LATB14
#define PORT_PIN23 _LATB15

// RTS(computer) -> CTS(dsPIC)
#define USB_CTS_ _RB5
#define ENABLE_CN_CTS CNEN2bits.CN27IE= 1
// CTS(computer) <- RTS(dsPIC)
#define USB_RTS_ _LATB10

// LEDs
#define PORT_LED11 		PORT_PIN7
#define LED11_ON 		PORT_LED11=1
#define LED11_OFF 		PORT_LED11=0
#define LED11_TOGGLE 	PORT_LED11^=1
#define PORT_LED12 		PORT_PIN9
#define LED12_ON 		PORT_LED12=1
#define LED12_OFF 		PORT_LED12=0
#define LED12_TOGGLE 	PORT_LED12^=1

// end copyright


#elif defined PLATFROM_MDC2D

// the following ports are used
//   - MDC_* : for communication with the MDC2D
//   - USB_* : for communication with the FT232R
//   - DAC_* : for communication with the AD5391
//   - a trailing underscore indicates active LOW

// PORT A
#define USB_RI_ _LATA2
#define USB_PWREN_ _LATA3
#define LED11_ _LATA7
#define LED12_ _LATA10
// PORT B
#define USB_CTS_ _LATB3					// CTS : dsPIC->FT232RL->computer : not used
#define MDC_BIAS_BITOUT _RB4
#define MDC_BIAS_ENABLE _LATB5
#define MDC_ADC_SERIALOUT _RB7
#define MDC_ADC_RESET _LATB8
#define DAC_MOSI _LATB9
#define MDC_VSYNC_ _RB10
#define MDC_HSYNC_ _RB11
#define MDC_VCLOCK_ _LATB12
#define MDC_HCLOCK_ _LATB13
#define MDC_ADC_CLOCK _LATB14
#define MDC_ADC_CLOCK_HACK _LATB15
// PORT C
#define USB_RTS_ _RC1					// RTS : computer->FT232RL->dsPIC : for sending cmd
#define DAC_NSS  _LATC3
#define DAC_SCK  _LATC4
#define MDC_BIAS_POWERDOWN_ _LATC5
#define MDC_BIAS_BITIN _LATC6
#define MDC_BIAS_BITLATCH _LATC7
#define MDC_BIAS_CLOCK _LATC8
#define MDC_ADC_READY _RC9
// ISR definitions
#define  ENABLE_CN_RTS CNEN1bits.CN9IE=1
#define DISABLE_CN_RTS CNEN1bits.CN9IE=0
// commands for setting the value of the two LEDs
#define LED11_ON 		LED11_=0
#define LED11_OFF 		LED11_=1
#define LED11_TOGGLE 	LED11_^=1
#define LED12_ON 		LED12_=0
#define LED12_OFF 		LED12_=1
#define LED12_TOGGLE 	LED12_^=1


#else
#error "you must define a valid PLATFORM_*"
#endif

#endif /* __PORT_H__*/

