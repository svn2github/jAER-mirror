#include "sdcard.h"
#include "config.h"
#include "chip.h"
#include <string.h>
#include "utils.h"
#include "diskio.h"
#include "xprintf.h"
#include <cr_section_macros.h>

#if USE_SDCARD
#define SD_CMD_PORT				(1)
#define SD_CMD_PIN				(6)

#define SD_DAT0_PORT			(1)
#define SD_DAT0_PIN				(9)

#define SD_DAT1_PORT			(1)
#define SD_DAT1_PIN				(10)

#define SD_DAT2_PORT			(1)
#define SD_DAT2_PIN				(11)

#define SD_DAT3_PORT			(1)
#define SD_DAT3_PIN				(12)

#define SD_CS_PORT				(1)
#define SD_CS_PIN				(13)

#define SD_CLK					(0)

/* Disk Status */
static volatile DSTATUS Stat = STA_NOINIT;

__NOINIT(RAM) struct sdcard sdcard;
static mci_card_struct sdcardinfo;

void setSDCardRecord(uint32_t flag) {
	sdcard.shouldRecord = flag ? 1 : 0;
	if (sdcard.shouldRecord) {
		f_mount(&sdcard.fs, "", 0); //always ok, doesn't actually talks to card
		if (f_opendir(&sdcard.dir, "/") == FR_OK) {
			getFilename(sdcard.filename);
			if (f_open(&sdcard.outputFile, sdcard.filename, FA_WRITE | FA_CREATE_NEW | FA_OPEN_ALWAYS) == FR_OK) {
				xputs("-ER+\n");
				sdcard.isRecording = 1;
				sdcard.fileBufferIndex = 0;
			} else {
				xputs("-ER-\n");
				f_mount(NULL, "", 0); //unmounting the card
			}
		} else {
			xputs("-ER-\n");
			f_mount(NULL, "", 0); //unmounting the card
		}
	} else {
		if (sdcard.isRecording) {
			xputs("-ER-\n");
			sdcard.isRecording = 0;
			if (sdcard.fileBufferIndex != 0) {
				f_write(&sdcard.outputFile, sdcard.fileBuffer, sdcard.fileBufferIndex, &sdcard.bytesWritten); //write data
				sdcard.bytesWrittenPerSecond += sdcard.bytesWritten;
				sdcard.fileBufferIndex = 0;
			}
			f_close(&sdcard.outputFile);
		}
		f_mount(NULL, "", 0); //unmounting the card}
	}
}

/**
 * @brief	Sets up the SD event driven wakeup
 * @param	bits : Status bits to poll for command completion
 * @return	Nothing
 */

static volatile int32_t sdio_wait_exit = 0;
static void sdmmc_setup_wakeup(void *bits) {
	uint32_t bit_mask = *((uint32_t *) bits);
	/* Wait for IRQ - for an RTOS, you would pend on an event here with a IRQ based wakeup. */
	NVIC_ClearPendingIRQ(SDIO_IRQn);
	sdio_wait_exit = 0;
	Chip_SDIF_SetIntMask(LPC_SDMMC, bit_mask);
	NVIC_EnableIRQ(SDIO_IRQn);
}

/**
 * @brief	A better wait callback for SDMMC driven by the IRQ flag
 * @return	0 on success, or failure condition (-1)
 */
static uint32_t sdmmc_irq_driven_wait(void) {
	uint32_t status;

	/* Wait for event, would be nice to have a timeout, but keep it  simple */
	while (sdio_wait_exit == 0) {
		__WFE();
	}

	/* Get status and clear interrupts */
	status = Chip_SDIF_GetIntStatus(LPC_SDMMC);
	Chip_SDIF_ClrIntStatus(LPC_SDMMC, status);
	Chip_SDIF_SetIntMask(LPC_SDMMC, 0);

	return status;
}

/**
 * @brief	SDIO controller interrupt handler
 * @return	Nothing
 */
void SDIO_IRQHandler(void) {
	/* All SD based register handling is done in the callback
	 function. The SDIO interrupt is not enabled as part of this
	 driver and needs to be enabled/disabled in the callbacks or
	 application as needed. This is to allow flexibility with IRQ
	 handling for applications and RTOSes. */
	/* Set wait exit flag to tell wait function we are ready. In an RTOS,
	 this would trigger wakeup of a thread waiting for the IRQ. */
	NVIC_DisableIRQ(SDIO_IRQn);
	sdio_wait_exit = 1;
}

void SDCardInit(void) {

	Chip_SCU_PinMuxSet(SD_CMD_PORT, SD_CMD_PIN, MD_PLN_FAST | FUNC7);
	Chip_SCU_PinMuxSet(SD_DAT0_PORT, SD_DAT0_PIN, MD_PLN_FAST | FUNC7);
	Chip_SCU_PinMuxSet(SD_DAT1_PORT, SD_DAT1_PIN, MD_PLN_FAST | FUNC7);
	Chip_SCU_PinMuxSet(SD_DAT2_PORT, SD_DAT2_PIN, MD_PLN_FAST | FUNC7);
	Chip_SCU_PinMuxSet(SD_DAT3_PORT, SD_DAT3_PIN, MD_PLN_FAST | FUNC7);
	Chip_SCU_PinMuxSet(SD_CS_PORT, SD_CS_PIN, SCU_MODE_REPEATER | MD_EZI | MD_ZI | FUNC7);
	Chip_SCU_ClockPinMuxSet(SD_CLK, MD_PLN_FAST | FUNC4);
	memset(&sdcard, 0, sizeof(struct sdcard));
	memset(&sdcardinfo, 0, sizeof(sdcardinfo));
	sdcardinfo.card_info.msdelay_func = timerDelayMs;
	sdcardinfo.card_info.evsetup_cb = sdmmc_setup_wakeup;
	sdcardinfo.card_info.waitfunc_cb = sdmmc_irq_driven_wait;
}

/*
 * User provided RTC function for FatFs.
 *
 * This is a real time clock service to be called from FatFs.
 *
 * This function reads the RTC from the lpc43xx in order
 * to generate a valid time.
 */
DWORD get_fattime() {
	if (!Chip_RTC_Clock_Running()) {
		return ((DWORD) (2014 - 1980) << 25) /* Year = 2014 */
		| ((DWORD) 1 << 21) /* Month = 1 */
		| ((DWORD) 1 << 16) /* Day_m = 1*/
		| ((DWORD) 0 << 11) /* Hour = 0 */
		| ((DWORD) 0 << 5) /* Min = 0 */
		| ((DWORD) 0 >> 1); /* Sec = 0 */

	}
	/* Pack date and time into a DWORD variable */
	return ((DWORD) (Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_YEAR) - 1980) << 25)
			| ((DWORD) Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_MONTH) << 21)
			| ((DWORD) Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_DAYOFMONTH) << 16)
			| ((DWORD) Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_HOUR) << 11)
			| ((DWORD) Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_MINUTE) << 5)
			| ((DWORD) Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_SECOND) >> 1);

}

DSTATUS disk_initialize(BYTE drv) {
	if (drv)
		return STA_NOINIT;

	if (Stat != STA_NOINIT) {
		return Stat; /* card is already enumerated */
	}
	Chip_SDIF_Init(LPC_SDMMC);
	//if (Chip_SDIF_CardNDetect(LPC_SDMMC)) { TODO
	//return STA_NODISK;
	//}

	/* Reset */
	Stat = STA_NOINIT;
	Chip_SDIF_PowerOn(LPC_SDMMC);
	if (Chip_SDMMC_Acquire(LPC_SDMMC, &sdcardinfo)) {
		Stat &= ~STA_NOINIT;
	}
	return Stat;
}

DSTATUS disk_status(BYTE drv) {
	if (drv || (Stat & STA_NOINIT))
		return STA_NOINIT;

//	if (Chip_SDIF_CardNDetect(LPC_SDMMC)) {
//		return STA_NODISK;
//	}
	// Current hardware is meant for uSD which do not have a write protect pin.
#if 0
	if (Chip_SDIF_CardWpOn(LPC_SDMMC)) {
		return STA_PROTECT;
	}
#endif
	return STA_OK;
}

DRESULT disk_read(BYTE drv, /* Physical drive nmuber (0) */
BYTE *buf, /* Pointer to the data buffer to store read data */
DWORD sector, /* Start sector number (LBA) */
UINT count) /* Sector count (1..128) */
{
	static int bytes_transferred = 0;
	int stat = disk_status(drv);

	bytes_transferred = 0;
	if (stat != STA_OK && stat != STA_PROTECT)
		return RES_ERROR;
	if (count == 0)
		return RES_PARERR;
	bytes_transferred = Chip_SDMMC_ReadBlocks(LPC_SDMMC, buf, sector, count);
	if (bytes_transferred != count * MMC_SECTOR_SIZE)
		return RES_ERROR;
	return RES_OK;
}

DRESULT disk_write(BYTE drv, /* Physical drive nmuber (0) */
const BYTE *buf, /* Pointer to the data to be written */
DWORD sector, /* Start sector number (LBA) */
UINT count) /* Sector count (1..128) */
{
	static int bytes_transferred = 0;
	int stat = disk_status(drv);

	bytes_transferred = 0;
	if (stat != STA_OK)
		return RES_ERROR;

	if (count == 0)
		return RES_PARERR;
	bytes_transferred = Chip_SDMMC_WriteBlocks(LPC_SDMMC, (BYTE *) buf, sector, count);
	if (bytes_transferred != count * MMC_SECTOR_SIZE)
		return RES_ERROR;
	return RES_OK;
}

DRESULT disk_ioctl(BYTE drv, /* Physical drive nmuber (0) */
BYTE ctrl, /* Control code */
void *buf) /* Buffer to send/receive control data */
{
	int stat = disk_status(drv);
	int size;

	if (stat != STA_OK && stat != STA_PROTECT)
		return RES_ERROR;

	switch (ctrl) {
	case CTRL_SYNC:
		return RES_OK;

	case GET_SECTOR_COUNT:
		size = Chip_SDMMC_GetDeviceSize(LPC_SDMMC);
		*(DWORD *) buf = size / MMC_SECTOR_SIZE;
		return RES_OK;

	case GET_SECTOR_SIZE:
		*(DWORD *) buf = MMC_SECTOR_SIZE;
		return RES_OK;

	case GET_BLOCK_SIZE:
		*(DWORD *) buf = 1;
		return RES_OK;

	default:
		return RES_PARERR;
	}
}

void getFilename(char filename[19]) {
	uint32_t random = Chip_RIT_GetCounter(LPC_RITIMER);
	uint16_t tmp;
	filename[0] = '/';
	tmp = Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_YEAR) & RTC_YEAR_MASK;
	filename[1] = '0' + tmp / 1000;
	tmp %= 1000;
	filename[2] = '0' + tmp / 100;
	tmp %= 100;
	filename[3] = '0' + tmp / 10;
	tmp %= 10;
	filename[4] = '0' + tmp;
	tmp = Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_MONTH) & RTC_MONTH_MASK;
	filename[5] = '0' + tmp / 10;
	tmp %= 10;
	filename[6] = '0' + tmp;
	tmp = Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_DAYOFMONTH) & RTC_DOM_MASK;
	filename[7] = '0' + tmp / 10;
	tmp %= 10;
	filename[8] = '0' + tmp;
	tmp = Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_HOUR) & RTC_HOUR_MASK;
	filename[9] = '0' + tmp / 10;
	tmp %= 10;
	filename[10] = '0' + tmp;
	tmp = Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_MINUTE) & RTC_MIN_MASK;
	filename[11] = '0' + tmp / 10;
	tmp %= 10;
	filename[12] = '0' + tmp;
	tmp = Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_SECOND) & RTC_SEC_MASK;
	filename[13] = '0' + tmp / 10;
	tmp %= 10;
	filename[14] = '0' + tmp;
	tmp = random % 1000;
	filename[15] = '0' + tmp / 100;
	tmp = random % 100;
	filename[16] = '0' + tmp / 10;
	tmp = random % 10;
	filename[17] = '0' + tmp;
	filename[18] = '\0';
}

#endif
