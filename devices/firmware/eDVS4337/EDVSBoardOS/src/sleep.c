/*
 * sleep.c
 *
 *  Created on: Mar 9, 2013
 *      Author: raraujo
 */

#include "chip.h"
#include "cr_start_m0.h"
#include "config.h"
#include "sleep.h"
#include "mpu9105.h"

/* Structure for initial base clock states */
struct CLK_BASE_STATES {
	CHIP_CGU_BASE_CLK_T clk; /* Base clock */
	CHIP_CGU_CLKIN_T clkin; /* Base clock source, see UM for allowable sources per base clock */
	bool autoblock_enab;/* Set to true to enable autoblocking on frequency change */
	bool powerdn; /* Set to true if the base clock is initially powered down */
};

/* Initial base clock states are mostly on */
static struct CLK_BASE_STATES InitClkStates[] = {
		{ CLK_BASE_SAFE, CLKIN_IRC, true, false },
		{ CLK_BASE_APB1, CLKIN_MAINPLL, true, false },
		{ CLK_BASE_APB3, CLKIN_MAINPLL, true, false }, {
		CLK_BASE_USB0, CLKIN_USBPLL, true, true },
#if defined(CHIP_LPC43XX)
		{ CLK_BASE_PERIPH, CLKIN_MAINPLL, true, false },
		{ CLK_BASE_SPI, CLKIN_MAINPLL, true, false },
		{ CLK_MX_ADCHS, CLKIN_MAINPLL, true, true },
#endif
		{ CLK_BASE_PHY_TX, CLKIN_ENET_TX, true, false },
#if defined(USE_RMII)
		{	CLK_BASE_PHY_RX, CLKIN_ENET_TX, true, false},
#else
		{ CLK_BASE_PHY_RX, CLKIN_ENET_RX, true, false },
#endif
		{ CLK_BASE_SDIO, CLKIN_MAINPLL, true, false },
		{ CLK_BASE_SSP0, CLKIN_MAINPLL, true, false },
		{ CLK_BASE_SSP1, CLKIN_MAINPLL, true, false },
		{ CLK_BASE_UART0, CLKIN_MAINPLL, true, false },
		{ CLK_BASE_UART1, CLKIN_MAINPLL, true, false },
		{ CLK_BASE_UART2, CLKIN_MAINPLL, true, false },
		{ CLK_BASE_UART3, CLKIN_MAINPLL, true, false },
		// {CLK_BASE_OUT, CLKINPUT_PD, true, false},
		// {CLK_BASE_APLL, CLKINPUT_PD, true, false},
		// {CLK_BASE_CGU_OUT0, CLKINPUT_PD, true, false},
		// {CLK_BASE_CGU_OUT1, CLKINPUT_PD, true, false},
		{ CLK_BASE_LCD, CLKIN_IDIVC, true, false },
		{ CLK_BASE_USB1, CLKIN_IDIVD, true, true }, };

void enterSleepMode() {
#if USE_IMU_DATA
	disableIMU();
#endif

	/* Configure Interrupt signal from Evrt_Src pin to EVRT */
	Chip_EVRT_ConfigIntSrcActiveType(EVRT_SRC_WAKEUP0, EVRT_SRC_ACTIVE_FALLING_EDGE);

	/* Enable interrupt signal from Evrt_Src pin to EVRT */
	Chip_EVRT_SetUpIntSrc(EVRT_SRC_WAKEUP0, ENABLE);

	/* Clear any pending interrupt */
	Chip_EVRT_ClrPendIntSrc(EVRT_SRC_WAKEUP0);

	/* Disable EVRT interrupt in NVIC */
	NVIC_DisableIRQ(EVENTROUTER_IRQn);

	/* preemption = 1, sub-priority = 1 */
	NVIC_SetPriority(EVENTROUTER_IRQn, ((0x01 << 3) | 0x01));

	/* Enable Event Router interrupt in NVIC */
	NVIC_EnableIRQ(EVENTROUTER_IRQn);

	//DVS128BiasFlush(40);// transfer bias settings to chip
	haltSlave();
	/* Shutdown peripheral clocks with wake up enabled */
	Chip_Clock_StartPowerDown();

	/* Get state of individual base clocks & store them for restoring.
	 * Sets up the IRC as base clock source
	 */
	for (int i = 0; i < (sizeof(InitClkStates) / sizeof(InitClkStates[0])); i++) {
		/* Get the Base clock settings */
		Chip_Clock_GetBaseClockOpts(InitClkStates[i].clk, &InitClkStates[i].clkin, &InitClkStates[i].autoblock_enab, &InitClkStates[i].powerdn);

		/* Set IRC as clock input for all the base clocks */
		Chip_Clock_SetBaseClock(InitClkStates[i].clk, CLKIN_IRC, InitClkStates[i].autoblock_enab, InitClkStates[i].powerdn);
	}

	/* Set IRC as clock source for SPIFI */
	Chip_Clock_SetBaseClock(CLK_BASE_SPIFI, CLKIN_IRC, true, false);

	/* Set IRC as source clock for Core */
	Chip_Clock_SetBaseClock(CLK_BASE_MX, CLKIN_IRC, true, false);
	/* Disable EVRT interrupt in NVIC */

	/* Power down the main PLL */
	Chip_Clock_DisableMainPLL();

	Chip_PMC_Set_PwrState(PMC_DeepPowerDown);

	/* Wake up from Deep power down state is as good as RESET */
	while (1) {
	}
}

/**
 * Input for the wakeup comparator
 * The DAC uses a 10 bit value and the V_DAC is 2.8V
 * 366 * 2.8 / 1024 ~= 1 V
 */
#define COMPARATOR_OUTPUT_VALUE  	(366)
void DacInit() {
	Chip_DAC_Init(LPC_DAC);
	Chip_DAC_SetBias(LPC_DAC, DAC_MAX_UPDATE_RATE_400kHz);
	Chip_DAC_ConfigDAConverterControl(LPC_DAC, DAC_DMA_ENA); //Needed for the DAC to work
	Chip_DAC_UpdateValue(LPC_DAC, COMPARATOR_OUTPUT_VALUE);
}

