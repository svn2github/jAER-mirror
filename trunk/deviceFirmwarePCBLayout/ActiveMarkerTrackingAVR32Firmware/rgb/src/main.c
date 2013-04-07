//////////////////////////////////////////////////////////////////////////////
// RGG LED main.c
//////////////////////////////////////////////////////////////////////////////

#include "compiler.h"
#include "preprocessor.h"
#include "pm.h"
#include "gpio.h"
#include "pwm.h"

//////////////////////////////////////////////////////////////////////////////
// clock setup
//////////////////////////////////////////////////////////////////////////////

#define FOSC0           12000000                              //!< Osc0 frequency: Hz.
#define OSC0_STARTUP    AVR32_PM_OSCCTRL0_STARTUP_2048_RCOSC  //!< Osc0 startup time: RCOsc periods.
void init_clock() {
	// source: gpio_local_bus_example.c

	// Initialize domain clocks (CPU, HSB, PBA and PBB) to the max frequency available
	// without flash wait states.
	// Some of the registers in the GPIO module are mapped onto the CPU local bus.
	// To ensure maximum transfer speed and cycle determinism, any slaves being
	// addressed by the CPU on the local bus must be able to receive and transmit
	// data on the bus at CPU clock speeds. The consequences of this is that the
	// GPIO module has to run at the CPU clock frequency when local bus transfers
	// are being performed => we want fPBA = fCPU.

	// Switch the main clock source to Osc0.
	pm_switch_to_osc0(&AVR32_PM, FOSC0, OSC0_STARTUP);

	// Setup PLL0 on Osc0, mul=10 ,no divisor, lockcount=16: 12Mhzx11 = 132MHz output
	pm_pll_setup(&AVR32_PM, 0, // pll.
			10, // mul.
			1, // div.
			0, // osc.
			16); // lockcount.
	// PLL output VCO frequency is 132MHz.
	// We divide it by 2 with the pll_div2=1 to get a main clock at 66MHz.
	pm_pll_set_option(&AVR32_PM, 0, // pll.
			1, // pll_freq.
			1, // pll_div2.
			0); // pll_wbwdisable.
	// Enable the PLL.
	pm_pll_enable(&AVR32_PM, 0);
	// Wait until the PLL output is stable.
	pm_wait_for_pll0_locked(&AVR32_PM);
	// Configure each clock domain to use the main clock divided by 2
	// => fCPU = fPBA = fPBB = 33MHz.
	pm_cksel(&AVR32_PM, 1, // pbadiv.
			0, // pbasel.
			1, // pbbdiv.
			0, // pbbsel.
			1, // hsbdiv=cpudiv
			0); // hsbsel=cpusel
	// Switch the main clock source to PLL0.
	pm_switch_to_clock(&AVR32_PM, AVR32_PM_MCCTRL_MCSEL_PLL0);
}

//////////////////////////////////////////////////////////////////////////////
// PWM setup
//////////////////////////////////////////////////////////////////////////////

#define cR 					0
#define cG 					1
#define cB 					2

#define R_PWM_PIN			AVR32_PWM_1_0_PIN
#define R_PWM_FUNCTION		AVR32_PWM_1_0_FUNCTION
#define R_PWM_CHANNEL_ID	1

#define G_PWM_PIN			AVR32_PWM_3_0_PIN
#define G_PWM_FUNCTION		AVR32_PWM_3_0_FUNCTION
#define G_PWM_CHANNEL_ID	3

#define B_PWM_PIN			AVR32_PWM_4_0_PIN
#define B_PWM_FUNCTION		AVR32_PWM_4_0_FUNCTION
#define B_PWM_CHANNEL_ID	4

// storage:
static pwm_opt_t pwm_opt;
static avr32_pwm_channel_t pwm_channel[3];
static unsigned int channel_id[3];
// WARNING! the PWM example app does:
//avr32_pwm_channel_t pwm_channel = { .ccnt = 0 };  // One channel config.
// we don't, as pwm_channel_init() does not use the .ccnt field...!?!?

#define TTT 4

// current used pattern
static unsigned int counter = 1;

//static unsigned int scale = 500;
static unsigned int scale = 1;

// predefined temporal patterns
// [0] = number of states
// [i * 2 - 1] = duration, i>0
// [i * 2] = state
static unsigned int squared0[] = {
		2,
		10, 0,
		10, 1};

static unsigned int squared1[] = {
		2,
		5, 0,
		5, 1};

static unsigned int arbitrary0[] = {
		4,
		5, 0,
		5, 1,
		10, 0,
		5, 1};

static unsigned int arbitrary1[] = {
		4,
		5, 0,
		10, 1,
		5, 0,
		5, 1,
		10, 0,
		5, 1};

static unsigned int testing[] = {
		2,
		16000, 0,
		16000, 1};

void init_pwm() {
	// set PWM GPIOs
	gpio_enable_module_pin(R_PWM_PIN, R_PWM_FUNCTION);
	gpio_enable_module_pin(G_PWM_PIN, G_PWM_FUNCTION);
	gpio_enable_module_pin(B_PWM_PIN, B_PWM_FUNCTION);

	// PWM controller configuration.
	pwm_opt.diva = AVR32_PWM_DIVA_CLK_OFF;
	pwm_opt.divb = AVR32_PWM_DIVB_CLK_OFF;
	pwm_opt.prea = AVR32_PWM_PREA_MCK;
	pwm_opt.preb = AVR32_PWM_PREB_MCK;
	// init pwm globals
	pwm_init(&pwm_opt);

	channel_id[cR] = R_PWM_CHANNEL_ID;
	channel_id[cG] = G_PWM_CHANNEL_ID;
	channel_id[cB] = B_PWM_CHANNEL_ID;

	unsigned int c;
	for (c = cR; c <= cB; c++) {

		/*
		 pwm_channel[c].CMR.calg = PWM_MODE_LEFT_ALIGNED; // Channel mode.
		 pwm_channel[c].CMR.cpol = PWM_POLARITY_LOW; // Channel polarity.
		 pwm_channel[c].CMR.cpd = PWM_UPDATE_DUTY; // Not used the first time.
		 pwm_channel[c].CMR.cpre = AVR32_PWM_CPRE_MCK_DIV_256; // Channel prescaler.
		 pwm_channel[c].cdty = 5; // Channel duty cycle, should be < CPRD.
		 pwm_channel[c].cprd = 20; // Channel period.
		 pwm_channel[c].cupd = 0; // Channel update is not used here.
		 // With these settings, the output waveform period will be :
		 // (115200/256)/20 == 22.5Hz == (MCK/prescaler)/period, with MCK == 115200Hz,
		 // prescaler == 256, period == 20.
		 */

		pwm_channel[c].CMR.calg = PWM_MODE_LEFT_ALIGNED; // Channel mode.
		pwm_channel[c].CMR.cpol = PWM_POLARITY_HIGH; // Channel polarity.
		pwm_channel[c].CMR.cpd = PWM_UPDATE_DUTY; // Not used the first time.
		pwm_channel[c].CMR.cpre = AVR32_PWM_CPRE_MCK_DIV_2; // Channel prescaler.
		//pwm_channel[c].cdty = 0; // Channel duty cycle, should be < CPRD.
		//pwm_channel[c].cprd = (256 << TTT); // Channel period.
		pwm_channel[c].cdty = 0; // Channel duty cycle, should be < CPRD.
		pwm_channel[c].cprd = 256 << TTT; // Channel period.
		pwm_channel[c].cupd = 0; // Channel update is not used here.

		pwm_channel_init(channel_id[c], &pwm_channel[c]);
	}

	pwm_start_channels((1 << channel_id[cR]) | (1 << channel_id[cG]) | (1
			<< channel_id[cB]));
}

//////////////////////////////////////////////////////////////////////////////
// main
//////////////////////////////////////////////////////////////////////////////

unsigned int xx() {
	unsigned int r = rand();
	r = r % 256;
	r = r*r / 256;
	r = r*r / 256;
	return r;
}

int main() {

	init_clock();

	init_pwm();

	// Enable the local bus interface for GPIO.
	gpio_local_init();

	// Enable the output driver of the example pin.
	// Note that the GPIO mode of pins is enabled by default after reset.
	gpio_local_enable_pin_output_driver(AVR32_PIN_PA10);
	gpio_local_enable_pin_output_driver(AVR32_PIN_PA11);
	gpio_local_enable_pin_output_driver(AVR32_PIN_PA12);

	// set some values..:
	gpio_clr_gpio_pin(AVR32_PIN_PA10);
	gpio_set_gpio_pin(AVR32_PIN_PA11);
	gpio_local_tgl_gpio_pin(AVR32_PIN_PA12);

	// advance pattern
	counter = 5;

	unsigned int pos = 0;
	unsigned int state = 0;
	unsigned int duration = 0;
	unsigned int cnt = 0;
	while (1) {
		asm volatile ("nop");

		if (cnt >= duration * scale) {
			cnt = 0;

			pos++;
			switch(counter) {
			case 1:
				if (pos > squared0[0]) pos = 1;
				state = squared0[2 * pos];
				duration = squared0[2 * pos - 1];
				break;
			case 2:
				if (pos > squared1[0]) pos = 1;
				state = squared1[2 * pos];
				duration = squared1[2 * pos - 1];
				break;
			case 3:
				if (pos > arbitrary0[0]) pos = 1;
				state = arbitrary0[2 * pos];
				duration = arbitrary0[2 * pos - 1];
				break;
			case 4:
				if (pos > arbitrary1[0]) pos = 1;
				state = arbitrary1[2 * pos];
				duration = arbitrary1[2 * pos - 1];
				break;
			case 5:
				if (pos > testing[0]) pos = 1;
				state = testing[2 * pos];
				duration = testing[2 * pos - 1];
				break;
			}

			//pwm_channel[cR].cdty = (pwm_channel[cR].cprd - 1) * state;
			//pwm_channel_init(channel_id[cR], &pwm_channel[cR]);

			unsigned int c;
			for (c = cR; c <= cB; c++) {
				//pwm_channel[c].cdty = 0;
				pwm_channel[c].cdty = (pwm_channel[c].cprd - 1) * state;
				pwm_channel_init(channel_id[c], &pwm_channel[c]);
			}

			//c = cR; //rand() % 3 + cR;
			//pwm_channel[c].cdty = (pwm_channel[c].cprd - 1) * state;
			//pwm_channel_init(channel_id[c], &pwm_channel[c]);

		} else {
			cnt++;
		}
	}

	return 0;
}

//////////////////////////////////////////////////////////////////////////////
// EOF
//////////////////////////////////////////////////////////////////////////////
