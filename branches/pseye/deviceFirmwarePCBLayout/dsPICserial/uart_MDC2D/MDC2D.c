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
 
/*! \file MDC2D.c
 * functions handling the \c MDC2D motion detection chip
 * please see the MDC2D_dsPIC.xml file in the bais-directory on jAER... 
 * (see README.txt for where to download jAER)
 */


#include <p33Fxxxx.h>

#include "MDC2D.h"
#include "config.h"
#include "port.h"
#include "DAC.h"


//! pointer to the last frame data; initially set to zero; see main.c
int *lastframe= (int *) 0;


#define VDD3280		// adjust biases for the TPS79328

#ifdef VDD3280
// if VDD is set to 3.28 V
unsigned int default_biases[15]= {
	3040-50,		// VrefRegBiasAmp
	2600-50,		// VregRefBiasMain
	2710-50,		// Vprbias
	 550,			// Vlmcfb
	3070-50,		// Vprbuff
	3110-50,		// Vprlmcbias
	3300-50,		// Vlmcbuff
	 792,			// Srcrefpix
	 700,			// Follbias
	2870-50,		// Vpsrcbias
	2410-50,		// VADCbias
	 701,			// Vrefminbias
	1500,			// Srcrefmin
	   0,			// VrefnegDAC
	3300			// VrefposDAC
	};
#else
// if VDD is set to 3.33 V
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
	3300		// VrefposDAC
	};
#endif


/*!default biases (used unless set via "biases" command; see
 * command.c #cmd_biases)
 *
 * contains 12 on-chip biases :
 *  - 3 bytes/bias (big endian)
 *  - \c 0xffffff means VDD/2 for nFET as well as for pFET
 *  - \c 0x000000 means GND   for nFET and VDD    for pFET
 */
unsigned char mdc_biases[36]= {
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
	0x00,0x00,0x0e,				// Vprlmcbias
	0x00,0x00,0x1d				// Vprbuff
};


/*! indicates which channel is converted by on-chip ADC
 *  taking a bit LOW chooses it for conversion
 *  taking several bits LOW shorts these outputs together
 *  (not only internally but also on analog output pins !)
 */
unsigned char mdc_channels;

//! stole this value from old firmware...
unsigned char mdc_master_current = 0x22;


/*! bit-bangs value to \c MDC2D bias generator
 *  starting with the MSB
 * \param x value, only the \a bits LSB are used
 * \param bits how many bits to transmit (starting with LSB)
 */
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

/*! writes current values to shift register on MDC2D chip; that is
 *   - all biases for on-chip bias generator
 *   - selected channel for ADC conversion
 *   - master bias current
 */
void mdc_write_shiftreg()
{
	int i;
	for(i=0; i<36; i++)
		mdc_bitbang(mdc_biases[i],8);
	mdc_bitbang(mdc_channels,4);
	mdc_bitbang(mdc_master_current,8);
	//?BIAS_LATCH
}

/*!sets all biases
 * \param array of biases; see #mdc_biases
 */
void mdc_set_biases(unsigned char biases[])
{
	int i;
	for(i=0; i<sizeof(mdc_biases); i++)
		mdc_biases[i]= biases[i];
}

//!inits the \c MDC2D module
void mdc_init()
{
	MDC_BIAS_POWERDOWN_ = 0;				// power up on-chip bias generator
	MDC_BIAS_ENABLE = 1;					// enable on-chip srcbias generator
	mdc_channels= MDC_CHANNELS_LMC1;		// chose channel for on-chip ADC
	mdc_write_shiftreg();					// write all values
	
	int i;
	for(i=0; i<=15; i++)
		DAC_set_bias(i,default_biases[i]);
		
	MDC_VCLOCK_ = 1;						// clocks on negative edge
	MDC_HCLOCK_ = 1;
}




//! \c MDC2D's scanner's current x position (0-19)
int mdc_x=0;
//! \c MDC2D's scanner's current y position (0-19)
int mdc_y=0;

//! arbitrary delay between scanner bits
#define MDC_CLOCK_DELAY Nop();Nop();Nop();

//! sends one (negative) horizontal clock pulse
void clock_x()
{
	MDC_HCLOCK_=0;
	MDC_CLOCK_DELAY;
	MDC_HCLOCK_=1;
}

//! moves the scanner's horizontal position to the specified value
// \param x where #mdc_x should be moved to
void mdc_goto_x(int x)
{
	while (MDC_HSYNC_)
		clock_x();

	// get past sync
	while (!MDC_HSYNC_)
		clock_x();
	clock_x();	// discard first bogus value
	
	mdc_x = 0;
	
	while(x) {
		clock_x();
		x--;
	}
}

//! sends one (negative) vertical clock pulse
void clock_y()
{
	MDC_VCLOCK_=0;
	MDC_CLOCK_DELAY;
	MDC_VCLOCK_=1;
}

//! moves the scanner's vertical position to the specified value
// \param y where #mdc_y should be moved to
void mdc_goto_y(int y)
{
	while (MDC_VSYNC_)
		clock_y();

	// get past sync		
	while (!MDC_VSYNC_)
		clock_y();
	clock_y();	// discard first bogus value
	
	mdc_y = 0;
	
	while(y) {
		clock_y();
		y--;
	}
}

//! see #mdc_goto_x and #mdc_goto_y
void mdc_goto_xy(int x,int y)
{
	mdc_goto_y(y);
	mdc_goto_x(x);
}

//! moves the scanner to the next pixel (row-wise)
void mdc_next_pixel()
{
	clock_x();
	
	// row ended ?
	if (++mdc_x == 20)
	{
		clock_x(); // jump over sync
		mdc_x=0;
		clock_y(); // applications responsability not to clock too far
	}
}

//! generates clock impulse for on-chip ADC
void adc_clock()
{
	MDC_ADC_CLOCK_HACK=0;
	MDC_CLOCK_DELAY;
	MDC_ADC_CLOCK_HACK=1;
}

//! initializes on-chip ADC
void mdc_adc_init()
{
	MDC_ADC_RESET = 1;
	MDC_CLOCK_DELAY;
	MDC_ADC_RESET = 0;
	
	while( !MDC_ADC_READY )
		adc_clock();
}

//! read the value fromt he on-chip ADC
//  \return an unsigned 8bit value
int mdc_adc_get()
{
	int i,ret;
	
	// synchronize (shouldn't be necessary)
	while( !MDC_ADC_READY )
		adc_clock();
	
	adc_clock();				// discard "9th bit"
	//TODO? use SPI interface
	for(i=0,ret=0; i<8; i++)
	{
		ret |= MDC_ADC_SERIALOUT;
		adc_clock();
		ret <<= 1;
	}
	
	return ret;
}
