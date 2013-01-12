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
 
/*! \file command.c
 * this file contains the command table as well as all functions that
 * parse the command entry and perform actions according to commands
 * sent
 *
 * before sending a command, the computer asserts RTS  -- this interrupts normal 
 * program execution and _CNInterrupt() is called; the corresponding
 * function as specified in #cmd_table is then executed; an answer is
 * buffered in #answer_buf (see uart.c) and will be sent back before the
 * next command is executed or in the mainloop (see uart_send_answer() in uart.c)
 *
 *
 * receiving commands format : "cmd arg1 arg2 ... \n"
 *   - the whole command must be in #cmd_buf
 *   - tolerant to "\r\n" as well as "\n"
 *   - 'help' shows available commands and arguments
 * sending answer format : "[!]...\n"
 *   - leading exclamation mark indicates error
 */
 
#include <p33Fxxxx.h>

#include "config.h"
#include "port.h"
#include "command.h"
#include "uart.h"
#include "time.h"
#include "string.h"
#include "var.h"
#include "DAC.h"
#include "MDC2D.h"
#include "filter.h"

//! indicates what data should be streamed in main loop
int cmd_stream_data = CMD_STREAM_FRAMES | CMD_STREAM_SRINIVASAN;
//! indicates whether data should currently be streamed in main loop
cmd_state_type cmd_state = CMD_STATE_IDLE;
//! indictes what channel should be selected (also in main loop)
cmd_channel_type cmd_channel_select = CMD_CHANNEL_LMC1;
//! flag indicating whether to use the on-chip DAC
int cmd_use_onchip = 0;
//! every how manieth frame is to be sent to the computer (1= every frame)
int nth = 1;

/*! this buffer is filled with the incoming command by #_CNInterrupt
 *  and also serves as a buffer for parsed commands (by #cmd_parse) */
char cmd_buf[CMD_BUFLEN];


// declarations for table only
void cmd_help   (int argn, char *argc[]);
void cmd_version(int argn, char *argc[]);
void cmd_start  (int argn, char *argc[]);
void cmd_stop   (int argn, char *argc[]);
void cmd_stream (int argn, char *argc[]);
void cmd_nth    (int argn, char *argc[]);
void cmd_channel(int argn, char *argc[]);
void cmd_onchip (int argn, char *argc[]);
void cmd_DAC    (int argn, char *argc[]);
void cmd_FPN    (int argn, char *argc[]);
void cmd_set    (int argn, char *argc[]);
void cmd_get    (int argn, char *argc[]);
void cmd_echo   (int argn, char *argc[]);
void cmd_goto   (int argn, char *argc[]);
void cmd_next   (int argn, char *argc[]);
void cmd_sample (int argn, char *argc[]);
void cmd_status (int argn, char *argc[]);
void cmd_blink  (int argn, char *argc[]);
void cmd_biases (int argn, char *argc[]);
void cmd_pd     (int argn, char *argc[]);
void cmd_reset  (int argn, char *argc[]);


//---------------------------------------------------------- command table
/*! this table contains all valid commands and is used by 
 * #cmd_parse; must be \c NULL terminated
 */
cmd_table_entry cmd_table[]=
{
	// commands concerning streaming, pixel readout
	{"start",cmd_start,"starts streaming"},
	{"stop",cmd_stop,"stops streaming"},
	{"stream",cmd_stream,"what to stream : stream [fake] [frames] [srinivasan]"},
	{"nth",cmd_nth,"every how manieth frame to stream (1=every frame)"},

	// commands for setting parameters of MDC2D
	{"DAC",cmd_DAC,"sets a voltage , usage 'DAC [0-E] mv_hex'"},
	{"pd",cmd_pd,"set value of power-down pin, usage 'pd {0|1}'"},
	{"biases",cmd_biases,"sets on-chip biases, usage 'biases 012345..."},
	{"channel",cmd_channel,"chooses channel to stream {recep|lmc1|lmc2}"},

	// utility commands	
	{"reset",cmd_reset,"resets the device"},
	{"help",cmd_help,"displays this help"},
	{"status",cmd_status,"displays some status informations"},
	{"version",cmd_version,"displays some version informations"},

        // commands for processing pixel data
	{"FPN",cmd_FPN,"{set|zero} sets/unsets FPN reference"},

	// commands for tuning, debugging
	{"set",cmd_set,"sets (many) variables, usage 'set var1 val1 ...'"},
	{"get",cmd_get,"gets value of variable(s), usage 'get var1 ...'"},
	{"echo",cmd_echo,"simply echoes the provided argument(s)"},
	{"goto",cmd_goto,"jumps to pixel : goto x_hex y_hex"},
	{"next",cmd_next,"goto next pixel (optional argument indicates number)"},
	{"sample",cmd_sample,"samples analog input"},
	
	// old commands (to be deleted eventually)
	{"onchip",cmd_onchip,"whether to use onchip ADC : {0|1}"},
	{"blink",cmd_blink,"starts blinking and never returns"},
	{NULL,(cmd_func_type) 0,NULL}
};




//---------------------------------------------------------- command handling

/*! the command parsing routine
 *  - in  : command string in #cmd_buf
 *  - out : directly calls appropriate function with parsed arguments
 */

void cmd_parse()
{
	char *argc[CMD_ARGN_MAX],*ptr;
	int cmdi,j,match,argn;

	// loop through command table
	for(cmdi=0; cmd_table[cmdi].cmd_string!=NULL; cmdi++)
	{

		// check every command for match
		for(j=0,ptr=cmd_buf,match=1; match; j++,ptr++)
		{
			// "windows compability" :-)
			if (*ptr == '\r')
				*ptr= '\n';
				
			// the command word may or may not be followed by args
			if (*ptr=='\n' || *ptr==' ' || *ptr=='\t')
				break;
			if (cmd_table[cmdi].cmd_string[j] != *ptr)
				match= 0;
		}
		
		// exit this loop only if command matches in length
		if (match && cmd_table[cmdi].cmd_string[j]==0)
			break;
	}
	
	// return if none matches
	if (!match)
	{
		uart_print_answer("!unknown command\n");
		return;
	}
	
	// parse args for command
	argn=0;
	// cmd line terminated by newline
	while(*ptr!='\n')
	{
		// mark end of previous argument
		*ptr=0;
		ptr++;
		
		// skip empty chars
		while(*ptr==' ' || *ptr=='\t')
			ptr++;
			
		// lazy syntax cheking
		if (*ptr=='\n')
			break;
			
		// save beginning of arg into array
		argc[argn++]= ptr;
		
		// arguments are separated by whitespaces
		while(*ptr!=' ' && *ptr!='\t' && *ptr!='\n' && *ptr!=0)
			ptr++;
	}
	// mark end of last argument
	*ptr=0;
	
	// execute command
	cmd_table[cmdi].cmd_func(argn,argc);
}



/*! ISR called when RTS is asserted by computer; reads incoming bytes
 *  into #cmd_buf and finally calls #cmd_parse */
void __attribute__((__interrupt__, no_auto_psv)) _CNInterrupt(void)
{
	char *ptr;
//	int ipl= SRbits.IPL;
//	SRbits.IPL= 7;			// disable user interrupts
	
	// asserted RTS == command mode
	while (USB_RTS_ == 0)
	{
//		IECbits.UTXIE = 0; 	// Disable UART Tx interrupt

		LED11_ON;			// indicate state to user
	
	
		// no need to care for buffers either, since the host will wait between
		// asserting RTS and sending a command for buffers to empty and DMA
		// UART transfer to finish
		ptr= cmd_buf;
		for(ptr= cmd_buf; ptr-cmd_buf<CMD_BUFLEN && USB_RTS_==0; ptr++)
		{
			// timeout is handled on host-side; we simply wait as long as RTS set...
			
			// blocking read as long as RTS is asserted
			while (USTAbits.URXDA==0 && USB_RTS_==0)
				Nop();
			*ptr = URXREG;
			if (*ptr == '\n')
				break;
		}
		
		/*
		//DBG
		uart_print_answer("got command; len=");
		uart_print_answer_i(ptr-cmd_buf);
		uart_print_answer("; 0ERR= ");
		uart_print_answer_i(USTAbits.OERR);
		uart_print_answer("; cmd_buf= ");
		*(ptr+1)=0;
		uart_print_answer(cmd_buf);
		uart_print_answer("; resting in peace\n");
		while(1) Nop();
		*/
	
		// every command must finish with a newline
		if (*ptr == '\n')
		{
			
			if (ptr-cmd_buf <2)
				;// friendly syntax parsing (several newlines cause no harm)
			else {
				// "windows compatibility"
				if (*(ptr-1)=='\r')
					*(ptr-1)= '\n';
				// send previous answer if not sent yet
				uart_send_answer();
				// parse + process command
				cmd_parse();
			}
			
		} 
		else 
		{
			// computer aborted command : no need to answer
			// just go back to streaming quickly to prevent loss of sync
		}
	}
	
	// empty Rx FIFO (in case there's a trailing '\r')
	while (USTAbits.URXDA)
		*ptr= URXREG;

	// clean-up
	LED11_OFF;			// indicate state to user
	IFS1bits.CNIF= 0;	// clear interrupt flag
//	SRbits.IPL= ipl;	// set old interrupt level (after clearing IFS...)
//	IECbits.UTXIE = 1; 	// Enable UART Tx interrupt
}

//! inits command-module (setting up ISR #_CNInterrupt)
void cmd_init()
{
	// generate CN interrupt for RTS
	ENABLE_CN_RTS;
	IEC1bits.CNIE= 1;
	
	// initialize command state
	_CNInterrupt();
}




//---------------------------------------------------------- command functions

void cmd_help(int argn, char *argc[])
{
	int i;
	for(i=0; cmd_table[i].cmd_string!=NULL; i++)
	{
		uart_print_answer(cmd_table[i].cmd_string);
		uart_print_answer(": ");
		uart_print_answer(cmd_table[i].cmd_descr);
		uart_print_answer("; ");
	}
	uart_print_answer("\n");
}


void cmd_stream (int argn, char *argc[])
{
	cmd_stream_data = 0;
	
	int i;
	for(i=0; i<argn; i++)
	{
		if (strcmpi(argc[i],"fake") == 0) {
			uart_print_answer(argc[i]);
			cmd_stream_data |= CMD_STREAM_FAKE;
			
		} else if (strcmpi(argc[i],"frames") == 0) {
			uart_print_answer(argc[i]);
			cmd_stream_data |= CMD_STREAM_FRAMES;
			
		} else if (strcmpi(argc[i],"srinivasan") == 0) {
			uart_print_answer(argc[i]);
			cmd_stream_data |= CMD_STREAM_SRINIVASAN;
			
		} else
			uart_print_answer("???");
		uart_print_answer(" ");
	}
	uart_print_answer("\n");
}


void cmd_nth    (int argn, char *argc[])
{
	int i;
	if (argn > 1)
	{
		uart_print_answer("!invalid number of arguments\n");
		return;
	}
	uart_print_answer("nth ");
	if (argn == 1)
		nth = htoi(argc[0]);
	uart_print_answer_i(nth);
	uart_print_answer("\n");
}


void cmd_channel(int argn, char *argc[])
{
	if (argn != 1)
	{
		uart_print_answer("! must specify one channel\n");
		return;
	}
	
	if (strcmpi(*argc,"recep") == 0)
		cmd_channel_select = CMD_CHANNEL_RECEP;
		
	else if (strcmpi(*argc,"lmc1") == 0)
		cmd_channel_select = CMD_CHANNEL_LMC1;
		
	else if (strcmpi(*argc,"lmc2") == 0)
		cmd_channel_select = CMD_CHANNEL_LMC2;
		
	else {
		uart_print_answer("! unknown channel\n");
		return;
	}

	uart_print_answer(*argc);	
	uart_print_answer("\n");
}


void cmd_start(int argn, char *argc[])
{
	cmd_state= CMD_STATE_RUNNING;
	uart_print_answer("started\n");
}


void cmd_stop(int argn, char *argc[])
{
	cmd_state= CMD_STATE_IDLE;
	uart_print_answer("stopped\n");
}



void cmd_onchip (int argn, char *argc[])
{
	if (argn != 1)
	{
		uart_print_answer("!wrong number of arguments\n");
		return;
	}
	cmd_use_onchip = (argc[0][0] == '1');
	uart_print_answer("\n");
}


void cmd_biases(int argn, char *argc[])
{
	int j;
	unsigned char biases[36],t;
	char *str;
	
	if (argn != 1 || strlen(argc[0]) != 72)
	{
		uart_print_answer("! argument must be 72 digits long\n");
		return;
	}
	
	for(j=0,str=argc[0]; str[j]; j++)
	{
		if (j%2) t<<=4;
		else t=0;
		if (str[j]>='0' && str[j]<='9')
			t|= str[j]-'0';
		if (str[j]>='a' && str[j]<='f')
			t|= str[j]-'a' + 0x0a;
		if (str[j]>='A' && str[j]<='F')
			t|= str[j]-'A' + 0x0a;
		if (j%2) biases[j/2]= t;
	}
	
	mdc_set_biases(biases);
	mdc_write_shiftreg();
	uart_print_answer("\n");
}


void cmd_pd    (int argn, char *argc[])
{
	MDC_BIAS_POWERDOWN_ = **argc!='0';
	uart_print_answer("\n");
}


void cmd_FPN    (int argn, char *argc[])
{
	if (argn==1 && strcmpi("set",argc[0])==0) {
		if (lastframe == 0)
			uart_print_answer("!no last frame");
		else
			FPN_set(lastframe);
	} else if (argn==1 && strcmpi("zero",argc[0])==0) 
		FPN_reset();
	else
		uart_print_answer("!invalid arguments");
	uart_print_answer("\n");
}

void cmd_set    (int argn, char *argc[])
{
	int i;
	if (argn %2)
	{
		uart_print_answer("!invalid number of arguments\n");
		return;
	}
	uart_print_answer("set");
	for(i=0; i*2<argn; i++)
	{
		if (var_set(argc[i*2],htoi(argc[i*2+1])) == 1)
		{
			// success
			uart_print_answer(" ");
			uart_print_answer(argc[i*2]);
		}
	}
	uart_print_answer("\n");
}


void cmd_DAC    (int argn, char *argc[])
{
	if (argn != 2)
	{
		uart_print_answer("!invalid number of arguments\n");
		return;
	}
	int n= htoi(argc[0]);				// which bias to set
	int mv=htoi(argc[1]);				// value in mV
	DAC_set_bias(n,mv);
	uart_print_answer("DAC ");
	uart_print_answer_i(n);
	uart_print_answer(" ");
	uart_print_answer_i(mv);
	uart_print_answer("\n");
}


void cmd_goto   (int argn, char *argc[])
{
	if (argn != 2)
	{
		uart_print_answer("! you must specify x,y\n");
		return;
	}
	mdc_goto_xy(htoi(argc[0]), htoi(argc[1]));
	uart_print_answer("\n");
}


void cmd_next   (int argn, char *argc[])
{
	int i,n=1;
	if (argn==1) n=htoi(argc[0]);
	
	for(i=0; i<n; i++)
		mdc_next_pixel();
	uart_print_answer("\n");
}


void cmd_sample (int argn, char *argc[])
{
	AD1CON1bits.SAMP = 1;				// start sampling
//	sleep(1);							// fill internal 4.4pF sampling cap
	AD1CON1bits.SAMP = 0;				// start conversion
	while(!AD1CON1bits.DONE) Nop();		// wait for conversion to finish
	uart_print_answer_i(ADC1BUF0);
	uart_print_answer("\n");
}


void cmd_get    (int argn, char *argc[])
{
	int i;
	
	if (argn == 0)
	{
		// print all vars & values without args
		for(i=0; var_table[i].var_name!=NULL; i++)
		{
			uart_print_answer(var_table[i].var_name);
			uart_print_answer("=");
			uart_print_answer_i(var_table[i].var_value);
			uart_print_answer(" ");
		}
	
	} 
	else for(i=0; i<argn; i++)
	{
		// only print values for vars specified
		if (i>0)
			uart_print_answer(" ");
		// prints "-1" (in hex) if var not found...
		uart_print_answer( itoh(var_get(argc[i])) );
	}
	uart_print_answer("\n");
}

void cmd_echo(int argn, char *argc[])
{
    int i;
    for(i=0; i<argn; i++) {
        uart_print_answer("#");
        uart_print_answer_i(i);
        uart_print_answer(" : ");
        uart_print_answer(argc[i]);
        uart_print_answer("\n");
    }
}

void cmd_blink(int argn, char *argc[])
{
	// this effectifely kills the application...
	while(1)
	{
		LED12_TOGGLE;
		sleep(100);
	}
}


void cmd_version(int argn, char *argc[])
{
	uart_print_answer("uart_MDC2D version " PROTOCOL_STRING "\n");
}


void cmd_status(int argn, char *argc[])
{
	uart_print_answer("state=");
	if (cmd_state==CMD_STATE_IDLE) uart_print_answer("idle");
	if (cmd_state==CMD_STATE_RUNNING) uart_print_answer("running");
	uart_print_answer(";channel=");
	if (cmd_channel_select==CMD_CHANNEL_RECEP) uart_print_answer("recep");
	if (cmd_channel_select==CMD_CHANNEL_LMC1) uart_print_answer("lmc1");
	if (cmd_channel_select==CMD_CHANNEL_LMC2) uart_print_answer("lmc2");
	uart_print_answer(";onchip=");
	uart_print_answer_i(cmd_use_onchip);
	uart_print_answer(";stream_flag=");
	uart_print_answer_i(cmd_stream_data);
	uart_print_answer("\n");
}

void cmd_reset  (int argn, char *argc[])
{
	void (*reset)(void);
	reset= (void *) 0;
	reset();
}




