/*
 * mutex.h
 *
 *  Created on: May 7, 2014
 *      Author: raraujo
 */

#ifndef MUTEX_H_
#define MUTEX_H_

#include <stdint.h>

typedef uint32_t mutex;

/**
 * Tries to lock the mutex.
 * If the mutex if locked it will busy wait, until it can capture it.
 * This routine should only be used by an ARM Cortex M3+
 * @param mutex pointer to the mutex
 */
extern void lock_mutex_M4(mutex * mutex);

/**
 * Unlocks the mutex.
 * This routine should only be used by an ARM Cortex M3+
 * @param mutex pointer to the mutex
 */
extern void unlock_mutex_M4(mutex * mutex);

#endif /* MUTEX_H_ */
