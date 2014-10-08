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



#include <p33Fxxxx.h>

#include "config.h"
#include "uart.h"
#include "time.h"
#include "port.h"
#include "ringbuffer.h"
#include "DAC.h"


// values from Reto Thuerer's  Short Project (ver 1.3.2011)
unsigned int default_biases[15]= {
	3040,		// VrefRegBiasAmp
	2600,		// VregRefBiasMain
	2710,		// Vprbias
	 550,		// Vlmcfb
	3070,		// Vprbuff
	3110,		// Vprlmcbias
	3300,		// Vlmcbuff
	 792,		// Srcrefpix
	 700,		// Follbias
	2870,		// Vpsrcbias
	2410,		// VADCbias
	 701,		// Vrefminbias
	1500,		// Srcrefmin
	   0,		// VrefnegDAC
	3300,		// VrefposDAC
	};

// contains 12 on-chip biases; 3 bytes/bias (big endian)
// 0xffffff means VDD/2 for nFET as well as for pFET
// 0x000000 means GND   for nFET and VDD    for pFET
unsigned int mdc_biases[36]= {
	0x00,0x00,0x39,				// VregRefBiasAmp
	0xFF,0xFF,0xFF,				// Vrefminbias (broke)
	0x01,0x0e,0x99,				// Vprbias
	0x04,0xb9,0x56,				// VregRefBiasMain
	0x01,0x65,0x0e,				// Vlmcfb
	0x00,0x2d,0xe3,				// Vlmcbuff
	0x13,0xf9,0x29,				// VADCbias
	0x1a,0x5a,0xdc,				// Follbias
	0x00,0x0f,0x23,				// Vpscfbias (probably miss-spelled : Vpsrcbias)
	0x00,0x00,0x00,				// Votabiasp (not used)
	0x00,0x00,0x0d,				// Vprlmcbias
	0x00,0x00,0x1d,				// Vprbuff
};


// indicates which channel is converted by on-chip ADC
// taking a bit LOW chooses it for conversion
// taking several bits LOW shorts these outputs together
// (not only internally but also on analog output pins !)
unsigned char mdc_channels;
#define MDC_CHANNELS_LMC2	0b1110
#define MDC_CHANNELS_LMC1	0b1101
#define MDC_CHANNELS_PHOTO	0b1011

unsigned char mdc_master_current = 0x22;	// stole value from old firmware


// bangs the LSB specified part, starting with its MSB
void mdc_bitbang(unsigned char x,int bits)
{
	int i;
	for(i=bits-1; i>=0; i--)
	{
		MDC_BIAS_BITIN = (x>>i)&0x1;
		MDC_BIAS_CLOCK = 1;
		Nop(); Nop(); Nop();
		MDC_BIAS_CLOCK = 0;
	}
}

// writes current values to shift register on MDC2D chip; that is
//   - all biases for on-chip bias generator
//   - selected channel for ADC conversion
//   - master bias current
void mdc_write_shiftreg()
{
	int i;
	for(i=0; i<36; i++)
		mdc_bitbang(mdc_biases[i],8);
	mdc_bitbang(mdc_channels,4);
	mdc_bitbang(mdc_master_current,8);
}



void mdc_init()
{
	MDC_BIAS_POWERDOWN_ = 1;				// power down on-chip bias generator
	MDC_BIAS_ENABLE = 1;					// enable on-chip srcbias generator
	mdc_channels= MDC_CHANNELS_LMC1;		// chose channel for on-chip ADC
	mdc_write_shiftreg();					// write all values
	
	int i;
	for(i=0; i<=15; i++)
		set_bias(i,default_biases[i]);
}



int main()
{
	clock_init();
	port_init();
	time_init();
	ringbuffer_init();
	uart_init();
	DAC_init();
	
	mdc_init();
	
	while(1);
	
	return 0;
}
