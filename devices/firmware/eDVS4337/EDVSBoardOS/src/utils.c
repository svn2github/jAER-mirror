/*
 * utils.c
 *
 *  Created on: Apr 24, 2014
 *      Author: raraujo
 */

#include "chip.h"
#include "utils.h"
#include "uart.h"
#include "cr_start_m0.h"
#include "build_defs.h"

void timerDelayUs(uint32_t timeUs) {
	/* In an RTOS, the thread would sleep allowing other threads to run.
	 For standalone operation, we just spin on RI timer */
	int32_t curr = (int32_t) Chip_RIT_GetCounter(LPC_RITIMER);
	int32_t final = curr + ((SystemCoreClock / 1000000) * timeUs);

	if (final == curr)
		return;

	if ((final < 0) && (curr > 0)) {
		while (Chip_RIT_GetCounter(LPC_RITIMER) < (uint32_t) final) {
		}
	} else {
		while ((int32_t) Chip_RIT_GetCounter(LPC_RITIMER) < final) {
		}
	}
}
void timerDelayMs(uint32_t timems) {
	/* In an RTOS, the thread would sleep allowing other threads to run.
	 For standalone operation, we just spin on RI timer */
	int32_t curr = (int32_t) Chip_RIT_GetCounter(LPC_RITIMER);
	int32_t final = curr + ((SystemCoreClock / 1000) * timems);

	if (final == curr)
		return;

	if ((final < 0) && (curr > 0)) {
		while (Chip_RIT_GetCounter(LPC_RITIMER) < (uint32_t) final) {
		}
	} else {
		while ((int32_t) Chip_RIT_GetCounter(LPC_RITIMER) < final) {
		}
	}

	return;
}

void getTimerMs(uint32_t * ms) {
	*ms = LPC_TIMER1->TC / 1000; //1Mhz /1000 =  1 ms
}

void resetDevice() {
	/**
	 * Using the Reset generation unit, activate the signal that the reset button does
	 * which means the consequences of physical and software reset should be the same.
	 */
	Chip_RGU_TriggerReset(RGU_CORE_RST);
	Chip_RGU_ClearReset(RGU_CORE_RST);
}

#define REPROGRAMMING_UART_BAUD		115200
/* Internal oscillator frequency */
#define CGU_IRC_FREQ 				(12000000)
#define ISP_CLOCK_FREQ 				(96000000)

void enterReprogrammingMode() {
	//Disable interrupts
	__disable_irq();
	//Stop the M0 core
	haltSlave();

	LPC_RGU->RESET_CTRL0 = 0x10DF1200;
	// GPIO_RST|AES_RST|ETHERNET_RST|SDIO_RST|DMA_RST|
	// USB1_RST|USB0_RST|LCD_RST|M0_SUB_RST|SCU_RST

	LPC_RGU->RESET_CTRL1 = 0x01DFF7FF;
	// M0APP_RST|CAN0_RST|CAN1_RST|I2S_RST|SSP1_RST|SSP0_RST|
	// I2C1_RST|I2C0_RST|UART3_RST|UART1_RST|UART1_RST|UART0_RST|
	// DAC_RST|ADC1_RST|ADC0_RST|QEI_RST|MOTOCONPWM_RST|SCT_RST|
	// RITIMER_RST|TIMER3_RST|TIMER2_RST|TIMER1_RST|TIMER0_RST

	/* Switch UART clock to IRC */
	Chip_Clock_SetBaseClock(CLK_BASE_UART0, CLKIN_IRC, true, false);
	/* Setup PLL for ISP clock */
	Chip_Clock_SetupMainPLLHz(CLKIN_IRC, CGU_IRC_FREQ, ISP_CLOCK_FREQ, ISP_CLOCK_FREQ);
	Chip_UART_DeInit(LPC_USART0);
	//Make sure UART0 is configured correctly
	UARTInit(LPC_USART0, REPROGRAMMING_UART_BAUD);
	Chip_IAP_ReinvokeISP();
}

void disablePeripherals() {
	/**
	 * The order is relevant.
	 * The peripherals' clocks is disabled first, then the base clocks and
	 * finally the PLLs.
	 * Inversion of this order may lead to lockup.
	 */
	Chip_Clock_Disable(CLK_APB3_CAN0);
	Chip_Clock_Disable(CLK_APB1_I2S);
	Chip_Clock_Disable(CLK_APB1_CAN1);
	Chip_Clock_Disable(CLK_MX_SPIFI);
	Chip_Clock_Disable(CLK_MX_LCD);
	Chip_Clock_Disable(CLK_MX_ETHERNET);
	Chip_Clock_Disable(CLK_MX_USB0);
	Chip_Clock_Disable(CLK_MX_EMC);
#if !USE_SDCARD
	Chip_Clock_Disable(CLK_MX_SDIO);
#endif
	Chip_Clock_Disable(CLK_MX_DMA);
	Chip_Clock_Disable(CLK_MX_SCT);
	Chip_Clock_Disable(CLK_MX_USB1);
	Chip_Clock_Disable(CLK_MX_EMC_DIV);
	Chip_Clock_Disable(CLK_MX_FLASHB);
	Chip_Clock_Disable(CLK_MX_ADCHS);
	Chip_Clock_Disable(CLK_MX_EEPROM);
	Chip_Clock_Disable(CLK_MX_WWDT);
	Chip_Clock_Disable(CLK_MX_SSP0);
	Chip_Clock_Disable(CLK_MX_TIMER0);
	Chip_Clock_Disable(CLK_MX_UART2);
	Chip_Clock_Disable(CLK_MX_UART3);
	Chip_Clock_Disable(CLK_MX_TIMER2);
	Chip_Clock_Disable(CLK_MX_TIMER3);
	Chip_Clock_Disable(CLK_MX_SSP1);
	Chip_Clock_Disable(CLK_MX_QEI);
	Chip_Clock_Disable(CLK_PERIPH_SGPIO);
	Chip_Clock_DisableBaseClock(CLK_BASE_USB0);
	Chip_Clock_DisableBaseClock(CLK_BASE_USB1);
	Chip_Clock_DisableBaseClock(CLK_BASE_SPIFI);
	Chip_Clock_DisableBaseClock(CLK_BASE_PHY_RX);
	Chip_Clock_DisableBaseClock(CLK_BASE_LCD);
	Chip_Clock_DisableBaseClock(CLK_BASE_ADCHS);
#if !USE_SDCARD
	Chip_Clock_DisableBaseClock(CLK_BASE_SDIO);
#endif
	Chip_Clock_DisableBaseClock(CLK_BASE_UART2);
	Chip_Clock_DisableBaseClock(CLK_BASE_UART3);
	Chip_Clock_DisableBaseClock(CLK_BASE_OUT);
	Chip_Clock_DisableBaseClock(CLK_BASE_APLL);
	Chip_Clock_DisableBaseClock(CLK_BASE_CGU_OUT0);
	Chip_Clock_DisableBaseClock(CLK_BASE_CGU_OUT1);
	Chip_Clock_DisablePLL(CGU_USB_PLL);
	Chip_Clock_DisablePLL(CGU_AUDIO_PLL);
}
