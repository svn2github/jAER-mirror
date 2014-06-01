#ifndef DVS_H_
#define DVS_H_

#include <stdint.h>
#include "config.h"

// ***************************************************************************** data formats
#define EDVS_DATA_FORMAT_DEFAULT			EDVS_DATA_FORMAT_BIN

#define EDVS_DATA_FORMAT_BIN				 0					//  2 Bytes/event#define EDVS_DATA_FORMAT_BIN_TS2B			 1					//  4 Bytes/event#define EDVS_DATA_FORMAT_BIN_TS3B			 2					//  5 Bytes/event#define EDVS_DATA_FORMAT_BIN_TS7B			 3					//  seven bit mode// *****************************************************************************#define DVS_EVENTBUFFER_SIZE_BITS		((uint32_t) 12)
#define DVS_EVENTBUFFER_SIZE		  	(((uint32_t) 1)<<DVS_EVENTBUFFER_SIZE_BITS)
#define DVS_EVENTBUFFER_MASK		  	(DVS_EVENTBUFFER_SIZE - 1)

struct eventRingBuffer {
	 uint32_t eventBufferWritePointer; /* the write pointer for the ring buffer */
	 uint32_t eventBufferReadPointer; /* the read pointer for the ring buffer */
	 uint32_t currentEventRate; /* the retina event rate per second */
	 uint32_t eventBufferTimeLow[DVS_EVENTBUFFER_SIZE]; /* 4 byte timestamp ring buffer*/
#if EXTENDED_TIMESTAMP
	 uint16_t eventBufferTimeHigh[DVS_EVENTBUFFER_SIZE]; /* 2 byte timestamp ring buffer*/
#endif
	 uint16_t eventBufferA[DVS_EVENTBUFFER_SIZE]; /* events address ring buffer*/
};

extern volatile struct eventRingBuffer events;


#define TIMER_CAPTURE_CHANNEL 		(1)
#define EVENT_PORT					(3)
#define PIN_ALL_ADDR            ((uint32_t) 0x00007FFF)// all 15 address bits from DVS#define PIN_ADDR_X              ((uint32_t) 0x0000007F)// address bits X#define PIN_ADDR_P              ((uint32_t) 0x00000080)// bit specifying polarity of event#define PIN_ADDR_Y              ((uint32_t) 0x00007F00)// address bits Y#define MEM_ADDR_X              ((uint32_t) 0x0000007F)// memory address bits X#define MEM_ADDR_P              ((uint32_t) 0x00000080)// memory bit specifying polarity of event#define MEM_ADDR_Y              ((uint32_t) 0x00007F00)// memory address bits Y#define OVERFLOW_BIT            ((uint32_t) 0x00008000)// this bit denotes overflow (in event memory, not on pin)// *************************************** bias definitions#define BIAS_cas			 0
#define BIAS_injGnd			 1
#define BIAS_reqPd			 2
#define BIAS_puX			 3
#define BIAS_diffOff		 4
#define BIAS_req			 5
#define BIAS_refr			 6
#define BIAS_puY			 7
#define BIAS_diffOn			 8
#define BIAS_diff			 9
#define BIAS_foll			10
#define BIAS_Pr				11

//BIAS seetings

#define BIAS_DEFAULT				0			// "BIAS_DEFAULT"#define BIAS_BRAGFOST				1			// "BIAS_BRAGFOST"#define BIAS_FAST					2			// "BIAS_FAST"#define BIAS_STEREO_PAIR			3			// "BIAS_STEREO_PAIR"#define BIAS_MINI_DVS				4			// "BIAS_MINI_DVS"#define BIAS_BRAGFOST_BALANCED		5			// "BIAS_BRAGFOST - ON/OFF Balanced"// *************************************** Function prototypes

extern uint32_t eDVSDataFormat; //current data format being used
extern uint32_t enableEventSending; //enabled event streaming

/**
 * It initializes the Retina chip, by pushing the default bias levels,
 * initializing the GPIO and the timer which is used to capture events.
 */
extern void DVS128ChipInit(void);
/**
 * Return a bias value
 * @param biasID Bias identifier, it should be between 0 and 12
 * @return the bias value or 0 if biasID is invalid
 */
extern uint32_t DVS128BiasGet(uint32_t biasID);

/**
 * It set a bias value
 * @param biasID Bias identifier, it should be between 0 and 12
 * @param biasValue the new bias values, should be smaller than 0xFFFFFF
 */
extern void DVS128BiasSet(uint32_t biasID, uint32_t biasValue);

/**
 * It loads the bias array with a default set of values.
 * There are currently 6 available.
 * @param biasSetID a value between 0 and 5
 */
extern void DVS128BiasLoadDefaultSet(uint32_t biasSetID);

/**
 * It flushs the bias value array to the Retina chip.
 * @param multiplier each bais value is mulplied by this value before being sent to the
 *        retina chip, it should usually be 1.
 */
extern void DVS128BiasFlush(uint32_t multiplier);

/**
 * It enables or disables the streaming of retina events through the UART.
 * @param flag ENABLE or DISABLE
 */
static inline void DVS128FetchEventsEnable(uint8_t flag) {
	enableEventSending = flag ? 1 : 0;
}

#endif
