/*
 * log.h
 *
 *  Created on: May 25, 2015
 *      Author: llongi
 */

#ifndef LIBCAER_LOG_H_
#define LIBCAER_LOG_H_

// Debug severity levels
#define LOG_EMERGENCY (0)
#define LOG_ALERT     (1)
#define LOG_CRITICAL  (2)
#define LOG_ERROR     (3)
#define LOG_WARNING   (4)
#define LOG_NOTICE    (5)
#define LOG_INFO      (6)
#define LOG_DEBUG     (7)

void caerLogLevelSet(uint8_t logLevel);
uint8_t caerLogLevelGet(void);
void caerLog(uint8_t logLevel, const char *subSystem, const char *format, ...) __attribute__ ((format (printf, 3, 4)));

#endif /* LIBCAER_LOG_H_ */
