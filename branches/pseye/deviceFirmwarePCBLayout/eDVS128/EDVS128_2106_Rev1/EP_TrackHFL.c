#include "EDVS128_2106.h"

#ifdef INCLUDE_TRACK_HF_LED

unsigned short tsMemory[128][128];
unsigned long trackingHFLCenterX[4], trackingHFLCenterY[4], trackingHFLCenterC[4];
unsigned long trackingHFLDesiredTimeDiff[4];
unsigned long transmitTrackHFLED;
unsigned long EP_TrackHFP_ServoEnabled;

#ifdef INCLUDE_TRACK_HF_LED_SERVO_OUT
  unsigned long TrackHFL_PWM0, TrackHFL_PWM1;
#endif


void EP_TrackHFLInit(void) {
  unsigned long a, b, n;
  for (a=0; a<128; a++) {
    for (b=0; b<128; b++) {
	  tsMemory[a][b] = ((unsigned short) 0);
	}
  }

  for (n=0; n<4; n++) {
	trackingHFLCenterX[n]=64<<8;
	trackingHFLCenterY[n]=64<<8;
	trackingHFLCenterC[n]=0;
  }
  trackingHFLDesiredTimeDiff[0] = 1000000 /  600;	  // track  600Hz -> 1666us time-diff
  trackingHFLDesiredTimeDiff[1] = 1000000 /  900;	  // track  900Hz -> 1111us time-diff
  trackingHFLDesiredTimeDiff[2] = 1000000 / 1200;	  // track 1200Hz ->  833us time-diff
  trackingHFLDesiredTimeDiff[3] = 1000000 / 1500;	  // track 1500Hz ->  666us time-diff
  EP_TrackHFLSetOutputEnabled(FALSE);

#ifdef INCLUDE_TRACK_HF_LED_SERVO_OUT
  TrackHFL_PWM0 = 6000;
  TrackHFL_PWM1 = 5200;
  PWM246SetCycle(10000);
  PWM246SetSignal(1, TrackHFL_PWM0);
  PWM246SetSignal(2, TrackHFL_PWM1);
  EP_TrackHFLServoSetEnabled(TRUE);

  #ifdef INCLUDE_TRACK_HF_LED_LASERPOINTER
    FGPIO_IODIR  |= PIN_TRACK_HFL_LASER;	  	// (P0.2) pin to output
    FGPIO_IOSET   = PIN_TRACK_HFL_LASER;		// high -> laser off
  #endif

#endif
}

void EP_TrackHFLSetOutputEnabled(unsigned long flag) {
  transmitTrackHFLED = flag;
}
long EP_TrackHFLGetOutputEnabled(void) {
  return(transmitTrackHFLED);
}


#ifdef INCLUDE_TRACK_HF_LED_SERVO_OUT
void EP_TrackHFLServoResetPosition(void) {
  TrackHFL_PWM0 = 6000;
  TrackHFL_PWM1 = 6000;
  PWM246SetCycle(10000);
  PWM246SetSignal(1, TrackHFL_PWM0);
  PWM246SetSignal(2, TrackHFL_PWM1);
}
void EP_TrackHFLServoSetEnabled(unsigned long flag) {
  EP_TrackHFP_ServoEnabled = flag;
#ifdef INCLUDE_TRACK_HF_LED_LASERPOINTER
  FGPIO_IOSET  = PIN_TRACK_HFL_LASER;		// high -> laser off  on changes
#endif
}
long EP_TrackHFLServoGetEnabled(void) {
  return(EP_TrackHFP_ServoEnabled);
}
#endif

#endif
  