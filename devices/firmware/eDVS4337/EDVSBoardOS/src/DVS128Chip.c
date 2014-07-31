#include "EDVS128_LPC43xx.h"
#include "chip.h"
#include "extra_pins.h"
#include "utils.h"
#include <cr_section_macros.h>
#include <string.h>

#define DEFAULT_BIAS_SET		BIAS_BRAGFOST_BALANCED

// *************************************** Pinout definitions
#define PORT_EVENT_Y				(7)
#define PIN_EVENT_Y0				(0)
#define PIN_EVENT_Y1				(1)
#define PIN_EVENT_Y2				(2)
#define PIN_EVENT_Y3				(3)
#define PIN_EVENT_Y4				(4)
#define PIN_EVENT_Y5				(5)
#define PIN_EVENT_Y6				(6)

#define PORT_EVENT_X				(6)
#define PIN_EVENT_X0				(1)
#define PIN_EVENT_X1				(2)
#define PIN_EVENT_X2				(3)
#define PIN_EVENT_X3				(4)
#define PIN_EVENT_X4				(5)
#define PIN_EVENT_X5				(9)
#define PIN_EVENT_X6				(10)
#define PIN_EVENT_P					(11)

// P3.5 signal to bias clock GPIO1[15]
#define PORT_BIAS_CLOCK				(3)
#define PIN_BIAS_CLOCK				(5)
#define GPIO_PORT_BIAS_CLOCK		(1)
#define GPIO_PIN_BIAS_CLOCK			(15)

// P3.7 signal to bias setup GPIO5[10]
#define PORT_BIAS_DATA				(3)
#define PIN_BIAS_DATA				(7)
#define GPIO_PORT_BIAS_DATA			(5)
#define GPIO_PIN_BIAS_DATA			(10)

// P2.12 signal to bias latch GPIO1[12]
#define PORT_BIAS_LATCH				(2)
#define PIN_BIAS_LATCH				(12)
#define GPIO_PORT_BIAS_LATCH		(1)
#define GPIO_PIN_BIAS_LATCH			(12)

// P2.11 reset DVS GPIO1[11]
#define PORT_RESET_DVS				(2)
#define PIN_RESET_DVS				(11)
#define GPIO_PORT_RESET_DVS			(1)
#define GPIO_PIN_RESET_DVS			(11)

// P1.6 DVS request (input to LPC) (Pin CAP)
#define PORT_DVS_REQUEST			(5)
#define PIN_DVS_REQUEST				(1)
#define GPIO_PORT_DVS_REQUEST		(2)
#define GPIO_PIN_DVS_REQUEST		(10)

// P1.8 DVS acknowledge (output to DVS) set as input
#define PORT_DVS_ACKN				(7)
#define PIN_DVS_ACKN				(7)
#define GPIO_PORT_DVS_ACKN			(3)
#define GPIO_PIN_DVS_ACKN			(15)

// P2.10 Output Enable ( Negative Logic) GPIO0[14]
#define PORT_DVS_OE					(2)
#define PIN_DVS_OE					(10)
#define GPIO_PORT_DVS_OE			(0)
#define GPIO_PIN_DVS_OE				(14)

// P4.0 Ground for Bias resistor
#define PORT_RX_DEFAULT_GND			(4)
#define PIN_RX_DEFAULT_GND			(0)
#define GPIO_PORT_RX_DEFAULT_GND	(2)
#define GPIO_PIN_RX_DEFAULT_GND		(0)

// *****************************************************************************
static uint32_t biasMatrix[12];
// *****************************************************************************
enum EDVS_MODE eDVSMode = EDVS_DATA_FORMAT_DEFAULT;
uint32_t eDVSDataFormat = EDVS_DATA_FORMAT_DEFAULT;
uint32_t eDVSProcessingMode;

//Using the NOINIT macros allows the flashed image size to be greatly reduced.
__NOINIT(RAM4) volatile struct eventRingBuffer events;

void DVS128InitTimer() {
	// *****************************************************************************
	// ** initialize Timer 1 (system main clock)
	// *****************************************************************************
	Chip_TIMER_Init(LPC_TIMER1);
	Chip_TIMER_PrescaleSet(LPC_TIMER1, 191);	// prescaler: run at 1Mhz!
	Chip_TIMER_MatchDisableInt(LPC_TIMER1, TIMER_CAPTURE_CHANNEL);
	Chip_TIMER_ResetOnMatchDisable(LPC_TIMER1, TIMER_CAPTURE_CHANNEL);
	Chip_TIMER_StopOnMatchDisable(LPC_TIMER1, TIMER_CAPTURE_CHANNEL);

	Chip_TIMER_CaptureRisingEdgeDisable(LPC_TIMER1, TIMER_CAPTURE_CHANNEL);
	Chip_TIMER_CaptureFallingEdgeEnable(LPC_TIMER1, TIMER_CAPTURE_CHANNEL);
	Chip_TIMER_CaptureDisableInt(LPC_TIMER1, TIMER_CAPTURE_CHANNEL);

	// set P5.1 to capture register CAP1_1
	Chip_SCU_PinMuxSet(PORT_DVS_REQUEST, PIN_DVS_REQUEST, MD_BUK | MD_EZI | FUNC5);

	//Select the capture input pin in the Global Input Multiplexer Array
	LPC_GIMA->CAP0_IN[1][1] = (uint32_t) (0x2 << 4);

	Chip_TIMER_Enable(LPC_TIMER1);  //Enable timer1
}

// *****************************************************************************
void DVS128ChipInit(void) {
	memset((void*) &events, 0, sizeof(struct eventRingBuffer));
	DVS128InitTimer();
	// *****************************************************************************
	eDVSProcessingMode = 0;
	eDVSDataFormat = EDVS_DATA_FORMAT_DEFAULT;

	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, GPIO_PORT_RX_DEFAULT_GND, GPIO_PIN_RX_DEFAULT_GND);	// set to ground
	Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, GPIO_PORT_RX_DEFAULT_GND, GPIO_PIN_RX_DEFAULT_GND); /* set P4.0 as output */
	Chip_SCU_PinMuxSet(PORT_RX_DEFAULT_GND, PIN_RX_DEFAULT_GND, MD_PLN_FAST | FUNC0);

	Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, GPIO_PORT_RESET_DVS, GPIO_PIN_RESET_DVS); /* set P2.11 as output */
	Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, GPIO_PORT_RESET_DVS, GPIO_PIN_RESET_DVS); // DVS array reset to high
	Chip_SCU_PinMuxSet(PORT_RESET_DVS, PIN_RESET_DVS, MD_PLN_FAST | FUNC0);

	Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, GPIO_PORT_DVS_OE, GPIO_PIN_DVS_OE); /* set P2.9 as output */
	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, GPIO_PORT_DVS_OE, GPIO_PIN_DVS_OE); // Enable DVS outputs
	Chip_SCU_PinMuxSet(PORT_DVS_OE, PIN_DVS_OE, MD_PLN_FAST | FUNC0);

	// let DVS handshake itself (REQ -> ACK)
	// set ACK as input
	Chip_SCU_PinMuxSet(PORT_DVS_ACKN, PIN_DVS_ACKN, MD_BUK | MD_EZI | FUNC0);

	Chip_SCU_PinMuxSet(PORT_BIAS_LATCH, PIN_BIAS_LATCH, MD_PLN_FAST | FUNC0);
	Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, GPIO_PORT_BIAS_LATCH, GPIO_PIN_BIAS_LATCH);// set pins to bias setup as outputs
	Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, GPIO_PORT_BIAS_LATCH, GPIO_PIN_BIAS_LATCH); /* set P2.12 as output */

	Chip_SCU_PinMuxSet(PORT_BIAS_DATA, PIN_BIAS_DATA, MD_PLN_FAST | FUNC4);
	Chip_SCU_PinMuxSet(PORT_BIAS_CLOCK, PIN_BIAS_CLOCK, MD_PLN_FAST | FUNC0);
	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, GPIO_PORT_BIAS_DATA, GPIO_PIN_BIAS_DATA);
	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, GPIO_PORT_BIAS_CLOCK, GPIO_PIN_BIAS_CLOCK);
	/* set P3.4 and P3.7 as output */
	Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, GPIO_PORT_BIAS_DATA, GPIO_PIN_BIAS_DATA);
	Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, GPIO_PORT_BIAS_CLOCK, GPIO_PIN_BIAS_CLOCK);

	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, GPIO_PORT_RESET_DVS, GPIO_PIN_RESET_DVS); // DVS array reset to low
	timerDelayMs(10); 	 								// 10ms delay
	Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, GPIO_PORT_RESET_DVS, GPIO_PIN_RESET_DVS); // DVS array reset to high
	timerDelayMs(1); 	 								// 1ms delay

	Chip_SCU_PinMuxSet(PORT_EVENT_X, PIN_EVENT_X0, MD_BUK | MD_EZI | FUNC0);
	Chip_SCU_PinMuxSet(PORT_EVENT_X, PIN_EVENT_X1, MD_BUK | MD_EZI | FUNC0);
	Chip_SCU_PinMuxSet(PORT_EVENT_X, PIN_EVENT_X2, MD_BUK | MD_EZI | FUNC0);
	Chip_SCU_PinMuxSet(PORT_EVENT_X, PIN_EVENT_X3, MD_BUK | MD_EZI | FUNC0);
	Chip_SCU_PinMuxSet(PORT_EVENT_X, PIN_EVENT_X4, MD_BUK | MD_EZI | FUNC0);
	Chip_SCU_PinMuxSet(PORT_EVENT_X, PIN_EVENT_X5, MD_BUK | MD_EZI | FUNC0);
	Chip_SCU_PinMuxSet(PORT_EVENT_X, PIN_EVENT_X6, MD_BUK | MD_EZI | FUNC0);
	Chip_SCU_PinMuxSet(PORT_EVENT_X, PIN_EVENT_P, MD_BUK | MD_EZI | FUNC0);

	Chip_SCU_PinMuxSet(PORT_EVENT_Y, PIN_EVENT_Y0, MD_BUK | MD_EZI | FUNC0);
	Chip_SCU_PinMuxSet(PORT_EVENT_Y, PIN_EVENT_Y1, MD_BUK | MD_EZI | FUNC0);
	Chip_SCU_PinMuxSet(PORT_EVENT_Y, PIN_EVENT_Y2, MD_BUK | MD_EZI | FUNC0);
	Chip_SCU_PinMuxSet(PORT_EVENT_Y, PIN_EVENT_Y3, MD_BUK | MD_EZI | FUNC0);
	Chip_SCU_PinMuxSet(PORT_EVENT_Y, PIN_EVENT_Y4, MD_BUK | MD_EZI | FUNC0);
	Chip_SCU_PinMuxSet(PORT_EVENT_Y, PIN_EVENT_Y5, MD_BUK | MD_EZI | FUNC0);
	Chip_SCU_PinMuxSet(PORT_EVENT_Y, PIN_EVENT_Y6, MD_BUK | MD_EZI | FUNC0);

	DVS128BiasLoadDefaultSet(DEFAULT_BIAS_SET);	// load default bias settings
	DVS128BiasFlush(1);					// transfer bias settings to chip

}

// *****************************************************************************

// *****************************************************************************
void DVS128BiasSet(uint32_t biasID, uint32_t biasValue) {
	if (biasID < 12) {
		biasMatrix[biasID] = biasValue;
	}
}
// *****************************************************************************
uint32_t DVS128BiasGet(uint32_t biasID) {
	if (biasID < 12) {
		return (biasMatrix[biasID]);
	}
	return (0);
}

// *****************************************************************************
void DVS128BiasLoadDefaultSet(uint32_t biasSetID) {

	switch (biasSetID) {

	case 0: // 12 bias values of 24 bits each 								BIAS_DEFAULT
		biasMatrix[0] = 1067; // 0x00042B,	  		// Tmpdiff128.IPot.cas
		biasMatrix[1] = 12316; // 0x00301C,			// Tmpdiff128.IPot.injGnd
		biasMatrix[2] = 16777215; // 0xFFFFFF,			// Tmpdiff128.IPot.reqPd
		biasMatrix[3] = 5579732; // 0x5523D4,			// Tmpdiff128.IPot.puX
		biasMatrix[4] = 151; // 0x000097,			// Tmpdiff128.IPot.diffOff
		biasMatrix[5] = 427594; // 0x06864A,			// Tmpdiff128.IPot.req
		biasMatrix[6] = 0; // 0x000000,			// Tmpdiff128.IPot.refr
		biasMatrix[7] = 16777215; // 0xFFFFFF,			// Tmpdiff128.IPot.puY
		biasMatrix[8] = 296253; // 0x04853D,			// Tmpdiff128.IPot.diffOn
		biasMatrix[9] = 3624; // 0x000E28,			// Tmpdiff128.IPot.diff
		biasMatrix[10] = 39; // 0x000027,			// Tmpdiff128.IPot.foll
		biasMatrix[11] = 4; // 0x000004			// Tmpdiff128.IPot.Pr
		break;

	case 1: // 12 bias values of 24 bits each 								BIAS_BRAGFOST
		biasMatrix[0] = 1067;	  		// Tmpdiff128.IPot.cas
		biasMatrix[1] = 12316;			// Tmpdiff128.IPot.injGnd
		biasMatrix[2] = 16777215;			// Tmpdiff128.IPot.reqPd
		biasMatrix[3] = 5579731;			// Tmpdiff128.IPot.puX
		biasMatrix[4] = 60;			// Tmpdiff128.IPot.diffOff
		biasMatrix[5] = 427594;			// Tmpdiff128.IPot.req
		biasMatrix[6] = 0;			// Tmpdiff128.IPot.refr
		biasMatrix[7] = 16777215;			// Tmpdiff128.IPot.puY
		biasMatrix[8] = 567391;			// Tmpdiff128.IPot.diffOn
		biasMatrix[9] = 6831;			// Tmpdiff128.IPot.diff
		biasMatrix[10] = 39;			// Tmpdiff128.IPot.foll
		biasMatrix[11] = 4;			// Tmpdiff128.IPot.Pr
		break;

	case 2: // 12 bias values of 24 bits each 								BIAS_FAST
		biasMatrix[0] = 1966;	  		// Tmpdiff128.IPot.cas
		biasMatrix[1] = 1137667;			// Tmpdiff128.IPot.injGnd
		biasMatrix[2] = 16777215;			// Tmpdiff128.IPot.reqPd
		biasMatrix[3] = 8053457;			// Tmpdiff128.IPot.puX
		biasMatrix[4] = 133;			// Tmpdiff128.IPot.diffOff
		biasMatrix[5] = 160712;			// Tmpdiff128.IPot.req
		biasMatrix[6] = 944;			// Tmpdiff128.IPot.refr
		biasMatrix[7] = 16777215;			// Tmpdiff128.IPot.puY
		biasMatrix[8] = 205255;			// Tmpdiff128.IPot.diffOn
		biasMatrix[9] = 3207;			// Tmpdiff128.IPot.diff
		biasMatrix[10] = 278;			// Tmpdiff128.IPot.foll
		biasMatrix[11] = 217;			// Tmpdiff128.IPot.Pr
		break;

	case 3: // 12 bias values of 24 bits each 								BIAS_STEREO_PAIR
		biasMatrix[0] = 1966;
		biasMatrix[1] = 1135792;
		biasMatrix[2] = 16769632;
		biasMatrix[3] = 8061894;
		biasMatrix[4] = 133;
		biasMatrix[5] = 160703;
		biasMatrix[6] = 935;
		biasMatrix[7] = 16769632;
		biasMatrix[8] = 205244;
		biasMatrix[9] = 3207;
		biasMatrix[10] = 267;
		biasMatrix[11] = 217;
		break;

	case 4: // 12 bias values of 24 bits each 								BIAS_MINI_DVS
		biasMatrix[0] = 1966;
		biasMatrix[1] = 1137667;
		biasMatrix[2] = 16777215;
		biasMatrix[3] = 8053458;
		biasMatrix[4] = 62;
		biasMatrix[5] = 160712;
		biasMatrix[6] = 944;
		biasMatrix[7] = 16777215;
		biasMatrix[8] = 480988;
		biasMatrix[9] = 3207;
		biasMatrix[10] = 278;
		biasMatrix[11] = 217;
		break;

	case 5: // 12 bias values of 24 bits each 								BIAS_BRAGFOST - on/off balanced
		biasMatrix[0] = 1067;	  		// Tmpdiff128.IPot.cas
		biasMatrix[1] = 12316;			// Tmpdiff128.IPot.injGnd
		biasMatrix[2] = 16777215;			// Tmpdiff128.IPot.reqPd
		biasMatrix[3] = 5579731;			// Tmpdiff128.IPot.puX
		biasMatrix[4] = 60;			// Tmpdiff128.IPot.diffOff
		biasMatrix[5] = 427594;			// Tmpdiff128.IPot.req
		biasMatrix[6] = 0;			// Tmpdiff128.IPot.refr
		biasMatrix[7] = 16777215;			// Tmpdiff128.IPot.puY
		biasMatrix[8] = 567391;			// Tmpdiff128.IPot.diffOn
		biasMatrix[9] = 19187;			// Tmpdiff128.IPot.diff
		biasMatrix[10] = 39;			// Tmpdiff128.IPot.foll
		biasMatrix[11] = 4;			// Tmpdiff128.IPot.Pr
		break;

	}
}

// *****************************************************************************
#define BOUT(x)  { if (x) \
						Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT,GPIO_PORT_BIAS_DATA, GPIO_PIN_BIAS_DATA);\
					else \
						Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT,GPIO_PORT_BIAS_DATA, GPIO_PIN_BIAS_DATA); \
						Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT,GPIO_PORT_BIAS_CLOCK, GPIO_PIN_BIAS_CLOCK);\
						timerDelayUs(1);\
						Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT,GPIO_PORT_BIAS_CLOCK, GPIO_PIN_BIAS_CLOCK);\
						timerDelayUs(1); }

void DVS128BiasFlush(uint32_t multiplier) {
	uint32_t biasIndex, currentBias;

	for (biasIndex = 0; biasIndex < 12; biasIndex++) {
		currentBias = biasMatrix[biasIndex];

		currentBias *= multiplier;
		if (currentBias > 0xFFFFFF)
			currentBias = 0xFFFFFF;

		BOUT(currentBias & 0x800000);
		BOUT(currentBias & 0x400000);
		BOUT(currentBias & 0x200000);
		BOUT(currentBias & 0x100000);

		BOUT(currentBias & 0x80000);
		BOUT(currentBias & 0x40000);
		BOUT(currentBias & 0x20000);
		BOUT(currentBias & 0x10000);

		BOUT(currentBias & 0x8000);
		BOUT(currentBias & 0x4000);
		BOUT(currentBias & 0x2000);
		BOUT(currentBias & 0x1000);

		BOUT(currentBias & 0x800);
		BOUT(currentBias & 0x400);
		BOUT(currentBias & 0x200);
		BOUT(currentBias & 0x100);

		BOUT(currentBias & 0x80);
		BOUT(currentBias & 0x40);
		BOUT(currentBias & 0x20);
		BOUT(currentBias & 0x10);

		BOUT(currentBias & 0x8);
		BOUT(currentBias & 0x4);
		BOUT(currentBias & 0x2);
		BOUT(currentBias & 0x1);

	}  // end of biasIndexclocking

	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, GPIO_PORT_BIAS_DATA, GPIO_PIN_BIAS_DATA); // set data pin to low just to have the same output all the time

// trigger latch to push bias data to bias generators
	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, GPIO_PORT_BIAS_LATCH, GPIO_PIN_BIAS_LATCH);
	Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, GPIO_PORT_BIAS_LATCH, GPIO_PIN_BIAS_LATCH);

}

