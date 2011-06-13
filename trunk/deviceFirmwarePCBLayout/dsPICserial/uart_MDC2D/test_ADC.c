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
 


// dsPIC33FJ128M804 can
//   - sample/convert continuously/manually : ASAM,SSRC
//   - use several S&H channels / scan with channel CH : CHPS,CSCNA
//     - when using several channels, DMA must be used (?)
//   - directly poll DONE / call ISR
//   - transfer 1 sample at a time via ADC1BUF0 / use DMA


// considerations for simplicity
//   - manually sample, manually convert

// considerations for speed
//   - drive sample&convert by clock
//   - emit sync signals by clock vs. upon conversion-completed
//   - use DMA
//   - fetch next frame while processing old frame

// considerations for compatability
//   - scan all three values sequentially


#include <p33Fxxxx.h>

#include "config.h"
#include "uart.h"
#include "time.h"
#include "port.h"
#include "ringbuffer.h"
#include "DAC.h"

void set_biases()
{
	int biases[15]={2800, 	//VregRefBiasAmp
					2800,	//VregRefBiasMain
					3000,	//Vprbias
					200,	//Vlmcfb
					3000,	//Vprbuff
					3000,	//Vprlmcbias
					3000,	//Vlmcbuff
					000,	//Screfpix
					1500,	//Follbias					
					3000,	//Vprscfbias
					3000,	//VADCbias
					500,	//Vrefminbias
					1500,	//Screfmin
					0000,	//VrefnegDAC
					4500	//VrefposDAC
					};
	int i;
	for(i=0; i<15; i++)
		set_bias(i,biases[i]);
}

// buffer vor values that can be used by DMA module
// CH3 puts dummy sample at fourth position
unsigned int values[4] __attribute__((space(dma)));


// some config common to all test_* functions
// does NOT enable ADC module
void init_ana_base()
{
	// AN0= scanvrecep
	// AN1= scanvlmc1
	// AN4= scanvlmc2
	
	AD1CON1bits.AD12B= 0;	// 10-bit, 4-channel mode
	AD1CON3bits.ADRC = 0;	// don't use RC as clock source (for sleep mode)
	AD1CON3bits.ADCS = 2;	// at 40 MIPS : 3x25 ns = 75 ns (=minimum)
	AD1CON1bits.SIMSAM = 1;	// sample simultanously (if CHPS!=0)
	AD1CON3bits.SAMC = 1;	// sample time, if auto : >=1 for simultanuous, 0 for sequential
	AD1CON2bits.VCFG = 0;	// reference : A_VDD, A_VSS
	AD1CON1bits.FORM = 0;	// unsigned integer format (0-1023)
	AD1CON2bits.SMPI = 0;	// ? increment rate for DMA addresses
	AD1CON1bits.ASAM = 0;	// manual sampling (by setting SAMP)
	AD1CON1bits.SSRC = 7;	// automatic conversion
	AD1CON2bits.BUFM = 1;	// use buffer alternatively between ISR calls
	AD1CON2bits.ALTS = 0;	// only use MUXA mode
	
	// basic single channel configuration
	AD1CON2bits.CHPS = 0;				// use CH0 only
	AD1CHS0bits.CH0NA = 0;				// CH0- = V_ref-
	AD1CHS0bits.CH0SA = 0;				// CH0+ = AN0
}

// get next value from ADC module
// expects manual sample / automatic converter mode
int poll_ana()
{
	AD1CON1bits.SAMP = 1;				// start sampling
//	sleep(1);							// fill internal 4.4pF sampling cap
	AD1CON1bits.SAMP = 0;				// start conversion
	while(!AD1CON1bits.DONE) Nop();		// wait for conversion to finish
	return ADC1BUF0;
}

void test_manual_scan()
{
	AD1CON2bits.CSCNA = 1;			// enable CH0 scanning
	AD1CON2bits.SMPI = 2;			// 3 conversions between interrupts
	AD1CSSLbits.CSS0 = 1;			// scan AN0
	AD1CSSLbits.CSS1 = 1;			// scan AN1
	AD1CSSLbits.CSS4 = 1;			// scan AN4
	
	AD1CON1bits.ADON = 1;				// enable ADC module -- after config
	
	uart_print("manual scan\n\r");

	while(1)
	{
		// manual/manual, scanning on CH0 : get values from CH0-CH2
		values[0] = poll_ana();
		values[1] = poll_ana();
		values[2] = poll_ana();
		
		// output values
		uart_print("values = ");
		int i;
		for(i=0; i<3; i++) {
			uart_print_i(values[i]);
			uart_print(" ");
		}
		uart_print("\n\r");
		sleep(1000);
		LED11_TOGGLE; //DBG
	}
}


void test_simult_ISR()
{
	// set up S&H channel configuration
	AD1CON2bits.CHPS = 2;			// use CH0,CH1 and CH2
	AD1CHS0bits.CH0SA = 4;			// CH0+ = AN4
	AD1CHS123bits.CH123NA = 0;		// CH1,2- = V_ref-
	AD1CHS123bits.CH123SA = 0;		// CH1+ = AN0 , CH2+ = AN1

	IFS0bits.AD1IF = 0;				// clear ADC1 interrupt flag
	IEC0bits.AD1IE = 1;				// enable ADC1 conversion complete ISR
	IPC3bits.AD1IP = 1;				// set priority level 1
	
	AD1CON1bits.ADON = 1;			// enable ADC module -- after config

	uart_print("simultanous ISR (AN4 AN0 AN1)\n\r");

	while(1)
	{
		// sample values
		AD1CON1bits.SAMP = 1;				// start sampling
		sleep(1);							// fill internal 4.4pF sampling cap
		AD1CON1bits.SAMP = 0;				// start conversion
		
		// will be converted during sleep in ISR
		sleep(1000);
		
		// output values
		uart_print("values = ");
		int i;
		for(i=0; i<3; i++) {
			uart_print_i(values[i]);
			uart_print(" ");
		}
		uart_print("\n\r");
		LED11_TOGGLE;
	}
}

//? why auto_psv
int bufi= 0;
void __attribute__((__interrupt__,auto_psv)) _ADC1Interrupt()
{
	IFS0bits.AD1IF = 0;				// reset interrupt flag
	values[bufi++]= ADC1BUF0;
	bufi&=0b11;
//	LED12_TOGGLE;//DBG
}

void test_DMA()
{
	// set up S&H channel configuration
	AD1CON2bits.CHPS = 2;			// use CH0,CH1 and CH2
	AD1CHS0bits.CH0SA = 4;			// CH0+ = AN4
	AD1CHS123bits.CH123NA = 0;		// CH1,2- = V_ref-
	AD1CHS123bits.CH123SA = 0;		// CH1+ = AN0 , CH2+ = AN1

	// "DMA address increments after every [1st] sample/conversion operation"
	AD1CON2bits.SMPI = 0;

	// DCA for DMA configuration -- IGNORED because we use DMAxCONbits.AMODE=0
	AD1CON1bits.ADDMABM = 1;		// write in order of conversion
	AD1CON4bits.DMABL = 0;			// allocate 1 word for each ANx
	
	// DMA proper configuration
	DMA0REQ = 0x0D;					// select ADC1 IRQ
	DMA0CONbits.AMODE = 0;			// register indirect mode with post-increment
	DMA0CONbits.MODE = 1;			// one-shot mode, ping-pong disabled
	DMA0CNT = 4;					// four conversions per interrupt
	DMA0PAD = (volatile unsigned int) &ADC1BUF0;
	DMA0STA = __builtin_dmaoffset(values);
	IFS0bits.DMA0IF = 0;
	IEC0bits.DMA0IE = 1;

	AD1CON1bits.ADON = 1;			// enable ADC module -- after config is done
	
	
	uart_print("simultanous DMA (AN4 AN0 AN1)\n\r");

	while(1)
	{
		// sample values
		AD1CON1bits.SAMP = 1;				// start sampling
		sleep(1);							// fill internal 4.4pF sampling cap
		AD1CON1bits.SAMP = 0;				// start conversion

		DMA0CONbits.CHEN = 1;				// have another shot
		
		// will be converted during sleep in ISR
		sleep(1000);
		
		// output values
		uart_print("values = ");
		int i;
		for(i=0; i<3; i++) {
			uart_print_i(values[i]);
			uart_print(" ");
		}
		uart_print("\n\r");
		LED11_TOGGLE;
	}
}

//? why auto_psv
void __attribute__((__interrupt__,auto_psv)) _DMA0Interrupt()
{
	IFS0bits.DMA0IF = 0;				// reset interrupt flag
}






int main()
{
	clock_init();
	port_init();
	time_init();
	ringbuffer_init();
	uart_init();
	DAC_init();

	set_biases();
	init_ana_base();

	values[0]= 0xFFFF;
	values[1]= 0xFFFF;
	values[2]= 0xFFFF;
		
	// choose one :
	//test_manual_scan();
	//test_simult_ISR();
	test_DMA();
	
	return 0;
}
