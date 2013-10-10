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



/*! \file main.c
 * 
 * this file implements all the initialization and the main loop
 * for the firmware that can be used to stream image data from a
 * \c MDC2D chip via a \c FTDI \c FT232R (UART to USB interface)
 * to \c jAER
 *
 * see README.txt for more information
 */



#include <p33Fxxxx.h>

// 2s watchdog timer in case something goes wrong :
_FWDT( FWDTEN_ON | WDTPRE_PR32 | WDTPOST_PS2048 );
// disable watchdog for debugging :
//_FWDT( FWDTEN_OFF ); // disable WDT



#include "config.h"
#include "uart.h"
#include "time.h"
#include "port.h"
#include "command.h"
#include "DAC.h"
#include "MDC2D.h"
#include "srinivasan.h"
#include "message.h"
#include "var.h"
#include "filter.h"
#include <string.h>



/*! this buffer always points to the "current" buffer (being 
 * currently filled by ADC (either dma_buf1 or dma_buf2) */
unsigned char *buffer=dma_buf1;



/*! initializes the ADC module.
 *  we use the ADC mode "automatic sample & manual conversion"
 *  - the timer ISR is responsible for controlling the MDC2D scanner 
 *    and starting the conversion
 *  - the DMA ISR will automatically move every conversed value
 *    from ADC1BUF0 into the DMA allocated buffer
 *  - the conversion is done automatically and always takes 12*T_AD
 *    to finish the 10bit conversion
 *  - the speed of the whole scanning is set by the delay of the timer
 *    ISR -- the longer the delay the more time is granted to the
 *    scanner + the analog input to settle
 */
void ana_init()
{
	AD1CON1bits.AD12B= 0;	// 10-bit, 4-channel mode
	AD1CON3bits.ADRC = 0;	// don't use RC as clock source (for sleep mode)
	AD1CON3bits.ADCS = 2;	// at 40 MIPS : (2 +1)x25 ns = 75 ns (=minimum) => x9=900ns for 10bit
	AD1CON1bits.SIMSAM = 1;	// sample simultanously (if CHPS!=0)
	AD1CON3bits.SAMC = 1;	// sample time, if auto : >=1 for simultanuous, 0 for sequential
	AD1CON2bits.VCFG = 0;	// reference : A_VDD, A_VSS
	AD1CON1bits.FORM = 0;	// unsigned integer format (0-1023 for 10bit)
	AD1CON2bits.SMPI = 0;	// increment rate for DMA addresses -- we don't use peripheral mode
	AD1CON2bits.BUFM = 0;	// does not apply to device with DMA
	AD1CON2bits.ALTS = 0;	// only use MUXA mode
	
	AD1CON1bits.ASAM = 1;	// automatic sampling once conversion is finished
	AD1CON1bits.SSRC = 0;	// start of conversion == end of sampling : set manually
	
	AD1CON2bits.CHPS = 0;	// use CH0 only
	AD1CHS0bits.CH0SA = 1;	// CH0+ = AN1 (scnvlmc1)

	//TODO we pobably don't need these...	
	AD1CON2bits.SMPI = 0;
	AD1CON1bits.ADDMABM = 1;		// write in order of conversion
	AD1CON4bits.DMABL = 0;			// allocate 1 word for each ANx

	
	// DMA1 setup
	DMA1REQ = 0x0D;			// select ADC1 IRQ
	DMA1CONbits.AMODE = 0;	// register indirect mode with post-increment
	DMA1CONbits.MODE = 1;	// one-shot mode, ping-pong disabled
	DMA1PAD = (volatile unsigned int) &ADC1BUF0;
	// DMA1CNT and DMA1PAD will be set later
	IFS0bits.DMA1IF = 0;	// clear interrupt flag
	IEC0bits.DMA1IE = 1;	// enable interrupt (ISR will be called after every conversion)
	
	AD1CON1bits.ADON = 1;	// enable ADC module -- after config is done
	
	
	// timer init (uses timer2, a type B timer)
	T2CONbits.TON = 0;		// disable timer
	T2CONbits.T32 = 0;		// use standalone (as 16bit)
	T2CONbits.TCS = 0;		// FCY as clock source
	T2CONbits.TGATE = 0;	// disable gated timer
	
	T2CONbits.TCKPS = 0;	// 1:1 pre-scalar
							// cycle defined in start_conversion_frame()

	IPC1bits.T2IP = 1;		// low interrupt priority
	IFS0bits.T2IF = 0;		// clear interrupt flag
	IEC0bits.T2IE = 1;		// enable interrupt
	// timer will be enabled upon scanning
}

//! this counter will be increased by timer2 ISR
int timer2_counter;
//! is set when DMA transfer of the complete frame has finished
int frame_finished;

/*! sets up the timer ISR to convert a frame; once this method is called
 *  the main loop can perform other tasks while the complete frame is
 *  acquired via ISR/DMA; see #frame_finished
 */
void start_conversion_frame()
{
	DMA1CNT = MDC_WIDTH*MDC_HEIGHT -1;			// count before DMA interrupt is generated
	if (buffer == dma_buf1)						// set up DMA buffer
		DMA1STA = __builtin_dmaoffset(dma_buf1);
	else
		DMA1STA = __builtin_dmaoffset(dma_buf2);
	DMA1STA += sizeof(struct msg);				// don't overwrite the message header,length,type words

	PR2 = var_get("timer_cycles");
	
	frame_finished = 0;
	timer2_counter = 0;		// reset counters
	TMR2 = 0;
	T2CONbits.TON = 1;		// enable timer
	AD1CON1bits.SAMP = 1;	// start with first sampling (will be stopped in ISR)
}

/*! the timer ISR responsible for starting the ADC conversion and
 *  moving the scanner to the next pixel during frame acquisition.
 * 
 *  thiscode needs to be reasonable fast since it's called every 
 *  #TIMER_CYCLES cycles...
 */
void __attribute__((__interrupt__, no_auto_psv)) _T2Interrupt(void)
{
	if (++timer2_counter == MDC_WIDTH * MDC_HEIGHT)
		T2CONbits.TON = 0;	// disable timer upon sampling of last pixel

	AD1CON1bits.SAMP = 0;	// start conversion
	Nop(); Nop(); Nop();	//? time to settle
	mdc_next_pixel();		// go to next pixel during conversion

	IFS0bits.T2IF = 0; 		// clear timer2 interrupt flag
	
	//TODO DMA1 needs be "reset"
	DMA1CONbits.CHEN = 1;	// enable DMA channel 5
}

//! this ISR is only called once upon completion of the whole frame conversion
void __attribute__((__interrupt__, no_auto_psv)) _DMA1Interrupt()
{
	frame_finished = 1;
	IFS0bits.DMA1IF = 0;
}

//! switches buffers (see #buffer)
void switch_buffers()
{
	// we only have 2 buffers, so it's pretty straight-forward
	if (buffer == dma_buf1) buffer= dma_buf2;
	else buffer= dma_buf1;
}


/*! main loop of the program. does the following
 *   - reacts accordingly to flags set in command.c (e.g. chaning
 *     the channel for ADC) -- see #cmd_stream_data etc in command.c
 *   - acquires new frames from the \c MDC2D
 *   - calls #srinivasan2D_16bit
 *   - kick-starts the DMA transfer of frame-/motion-data over the
 *     UART interface
 */
void stream_loop()
{
	unsigned int i,j;
	int x,y,dx,dy;
	unsigned srinivasan_us,capture_us;
	struct msg *m,msgbuf;
	struct msg_frame_bytes *frame_bytes;
	struct msg_frame_words *frame_words;
	struct msg_frame_words_dxdy *frame_words_dxdy;
	struct msg_dxdy dxdybuf;
	cmd_channel_type current_channel= -1;			// make sure it's set in the first run
	
	// input is handled by command-ISR
	// during command parsing/execution, normal program flow is interrupted
	cmd_init();
	
	// flush buffers
	msg_create_empty(buffer,MSG_MAX_LENGTH - sizeof(struct msg));
	uart_dma_send_msg(buffer);
	switch_buffers();
	
	// indicate startup with reset message
	msg_create_reset(buffer);
	uart_dma_send_msg(buffer);
	switch_buffers();

	i=0;
	while(1)
	{
		// clear watchdog timer
		__asm__("CLRWDT");
		
		// evtl. wait between frames
		// odd  sequence number == us1
		// even sequence number == us2
		if (i%2)
			sleep_us(var_get("main_us1"));
		else
			sleep_us(var_get("main_us2"));
		
		// send answers even if we're not streaming
		uart_send_answer();

		if (cmd_state == CMD_STATE_RUNNING)
		{

			// check whether channel change occured
			if (current_channel != cmd_channel_select)
			{
				if (cmd_channel_select == CMD_CHANNEL_RECEP) {
					AD1CHS0bits.CH0SA = 0;				// CH0+ = AN0 (recep);
					mdc_channels = MDC_CHANNELS_RECEP;
				} else if (cmd_channel_select == CMD_CHANNEL_LMC1) {
					AD1CHS0bits.CH0SA = 1;				// CH0+ = AN1 (lmc1);
					mdc_channels = MDC_CHANNELS_LMC1;
				} else if (cmd_channel_select == CMD_CHANNEL_LMC2) {
					AD1CHS0bits.CH0SA = 4;				// CH0+ = AN4 (lmc2);
					mdc_channels = MDC_CHANNELS_LMC2;
				}
				
				mdc_write_shiftreg();
				current_channel = cmd_channel_select;
			}

			// stream test image ?
			if (cmd_stream_data & CMD_STREAM_FAKE)
			{
				// stream bytes
				m= (struct msg *) buffer;
				m->marker= MSG_MARKER;
				m->payload_length= sizeof(struct msg_frame_bytes);
				m->type = MSG_FRAME_BYTES;
				
				frame_bytes = (struct msg_frame_bytes *) (buffer + sizeof(struct msg));

				for(y=0; y<MDC_HEIGHT; y++)
					for(x=0; x<MDC_WIDTH; x++)
					{
						if ((x&1) ^ (y&1))
							frame_bytes->buf[y*20+x]=  i&0xff;
						else
							frame_bytes->buf[y*20+x]= (i&0xff)^0xff;
					}
					
				if (i%nth == 0)
					uart_dma_send_msg(buffer);
				switch_buffers();
			}
			

			// for streaming frames/motion we have to acquire pixels & calculate
			// (see further down for what is acutally sent)
			if (cmd_stream_data & (CMD_STREAM_FRAMES|CMD_STREAM_SRINIVASAN) )
			{

				m= (struct msg *) buffer;
				m->marker= MSG_MARKER;
				m->payload_length= sizeof(struct msg_frame_words_dxdy);
				m->type = MSG_FRAME_WORDS_DXDY;
				
				frame_words_dxdy = (struct msg_frame_words_dxdy *) MSG_PAYLOAD(buffer);
				
				// init scanner, ADC
				if (cmd_use_onchip)
					mdc_adc_init();
				// don't move the scanner here because the analog values need some
				// time to settle after mdc_goto_xy(0,0) -- that's why it's done
				// just _after_ the frame is acquired

				
				tictoc_us=0;
				TIC;
				if (cmd_use_onchip)
				{
					// convert pixel by pixel if on-chip AD is used
					for(j=0; j<MDC_WIDTH*MDC_HEIGHT; j++)
					{
						frame_words->buf[j] = mdc_adc_get();
	
						// advance one pixel	
						mdc_next_pixel();
					}
				}
				else
				{
					// initialize the ISRs
					start_conversion_frame();
					// the whole sampling&conversion is done in iSR
					while(!frame_finished)
						Nop();	// we could actually do something useful here...
				}
				// position to first pixel for next acquisition already
				mdc_goto_xy(0,0);
				TOC;
				capture_us= tictoc_us;

				// remove fixed pattern noise
				FPN_remove( frame_words_dxdy->buf );

				// only calculate motion data if we have to stream it
				// calculate dx,dy between this and the last frame
				tictoc_us=0;
				TIC;
				if (cmd_stream_data & CMD_STREAM_SRINIVASAN)
				{
					if (lastframe != (int *) 0) {
						dx=0x1234; dy=0x5678;
						srinivasan2D_16bit(lastframe,(int *)MSG_PAYLOAD(buffer),&dx,&dy,var_get("shiftacc"));
					} else {
						dx=0; dy=0;
					}
				} else {
					dx= 0;
					dy= 0;
				}
				TOC;
				srinivasan_us= tictoc_us;
				
				frame_words_dxdy->dx  = dx;
				frame_words_dxdy->dy  = dy;
				frame_words_dxdy->seq = i;

				// make this frame next last frame
				lastframe= (int *) MSG_PAYLOAD(buffer);
				
				
				if (i%nth == 0)
				{
					// either stream the frame (+/- motion data) via DMA...
					if (cmd_stream_data & CMD_STREAM_FRAMES)
						uart_dma_send_msg(buffer);
					else
					// or simply send the motion data via blocking i/o
					{
						msgbuf.type= MSG_DXDY;
						msgbuf.marker= MSG_MARKER;
						msgbuf.payload_length= sizeof(struct msg_dxdy);
						dxdybuf.dx= dx;
						dxdybuf.dy= dy;
						uart_write((char *) &msgbuf,sizeof(struct msg));
						uart_write((char *) &dxdybuf,sizeof(struct msg_dxdy));
					}
				}

				
				// in any case, switch the buffers for motion calculation...
				switch_buffers();
				
				//LED12_TOGGLE;
				
				// update stats
				var_set("stats_frames_total",var_get("stats_frames_total") +1);
				var_set("stats_capture_us",capture_us);
				var_set("stats_srinivasan_us",srinivasan_us);
			}
			
			// increase sequence number
			i++;		
					

		}

		//DBG
		//sleep(1000);
	}
}

//! main entry point : initializes modules & then calls #stream_loop
int main()
{

	clock_init();
	tictoc_init();
	port_init();
	uart_init();
	DAC_init(); // call before mdc_init()
	mdc_init();
	ana_init();
	FPN_reset();
	
	stream_loop();
	
	return 0;
}
