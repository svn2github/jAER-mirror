#include "EDVS128_2106.h"
		 							// this is typically used for servos
#ifdef INCLUDE_PWM246
// *****************************************************************************
//#define PWM_PCLK_DIVIDE				(64)	//   1us ticks
#define PWM_PCLK_DIVIDE					(16)	//   250ns ticks
												//  --> 6000 == 1.5ms (neutral servo)

// *****************************************************************************
unsigned long PWMCycle, PWMSignal[3];

// *****************************************************************************
void PWM246SetSignal(unsigned long id, unsigned long newSignal) {
  if (newSignal > PWMCycle)	newSignal = PWMCycle;
  if (id > 2) id=0;

  PWMSignal[id] = newSignal;

  if (id==0) {
   PWM_MR2 = PWMSignal[0];		// update PWM2
   PWM_LER |= BIT(2);			// allow changes of MR2 on next counter reset
  }
  if (id==1) {
   PWM_MR4 = PWMSignal[1];		// update PWM4
   PWM_LER |= BIT(4);			// allow changes of MR4 on next counter reset
  }
  if (id==2) {
   PWM_MR6 = PWMSignal[2];		// update PWM6
   PWM_LER |= BIT(6);			// allow changes of MR6 on next counter reset
  }
}

// *****************************************************************************
unsigned long PWM246GetSignal(unsigned long id) {
  return(PWMSignal[id]);
}

// *****************************************************************************
void PWM246SetCycle(unsigned long newCycle) {
  PWMCycle = newCycle;

  if (PWMSignal[0] > PWMCycle)	PWM246SetSignal(0, PWMCycle);
  if (PWMSignal[1] > PWMCycle)	PWM246SetSignal(1, PWMCycle);
  if (PWMSignal[2] > PWMCycle)	PWM246SetSignal(2, PWMCycle);

  PWM_MR0 = PWMCycle;			// reset counter after this many ticks
  PWM_LER |= BIT(0);			// allow change of MR0 on next counter reset
}

// *****************************************************************************
unsigned long PWM246GetCycle(void) {
  return(PWMCycle);
}


// *****************************************************************************
void PWM246Init(void) {
// *****************************************************************************
	// initialize variables
// *****************************************************************************
  PWM246SetCycle(10000);				// 2.5ms total cycle -> 400Hz
  PWM246SetSignal(0, 6000);				// 1.5ms duty cycle (neutral)
  PWM246SetSignal(1, 5200);				// 1.5ms duty cycle (neutral)
  PWM246SetSignal(2, 6000);				// 1.5ms duty cycle (neutral)

// *****************************************************************************
	// initialize PWM block (PWM2, PWM4, and PWM6)
// *****************************************************************************
  PWM_PR = ((PWM_PCLK_DIVIDE)-1);		// prescale system clock

  PWM_MCR = BIT(1);						// reset counter on match of MR0
  		  								// MR0 is loaded with PWM2SetCycle

  PWM_PCR = BIT(10) | BIT(12) | BIT(14); // enable PWM2, PWM4, PWM6

// ********************************** assign GPIO ports to special functionality
  #ifdef INCLUDE_PWM246_ENABLE_PWM2_OUT
    PCB_PINSEL0 |= BIT(15);				// enable PWM2 on P0.7
  #endif
  #ifdef INCLUDE_PWM246_ENABLE_PWM4_OUT
    PCB_PINSEL0 |= BIT(17);				// enable PWM4 on P0.8
  #endif
  #ifdef INCLUDE_PWM246_ENABLE_PWM6_OUT
    PCB_PINSEL0 |= BIT(19);				// enable PWM2 on P0.9
  #endif

// *****************************************************************************
  	// start PWM and counter0
// *****************************************************************************
  PWM_TCR = BIT(3) | BIT(0);			// enable PWM mode, enable counter
}

// *****************************************************************************
//void PWM246Iterate(void) {
//}

void PWM246StopPWM(void) {
  PWM246SetSignal(0, 0);				// gracefully stop PWM (not in the middle of signal
  PWM246SetSignal(1, 0);
  PWM246SetSignal(2, 0);

  // set "stop PWM counter on MR0 match", then wait while "PWM running flag" is set.
  // wait for PWM Counter Value to be "less" than before

  delayMS(20);		 					// make sure to wait for PWM to finish.
  										   // rethink to determine wait time in a more elegant way
}

#endif
