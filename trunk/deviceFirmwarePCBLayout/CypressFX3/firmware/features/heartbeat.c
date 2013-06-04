#include "fx3.h"
#include "heartbeat.h"

// Array of pointers to HeartBeat functions (executed periodically).
// The Heartbeat system is intended for periodic execution, at relatively big time intervals (like multiples of 512ms),
// with no real guarantees about highly precise timing between calls.
typedef struct {
	void (*function)(uint32_t input);
	uint32_t input;
	uint16_t ticks_remaining;
	uint16_t ticks_total;
} HeartbeatFunction;

static HeartbeatFunction glHeartbeatFunctions[HEARTBEAT_NUMBER] = { { NULL, 0, 0, 0 } };
static uint16_t glHeartbeatTimerTicks = HEARTBEAT_TICKS_DEFAULT;
static CyU3PMutex glHeartbeatMutex;

static uint16_t CyFxHeartbeatGCD(uint16_t u, uint16_t v) {
	// GCD(0,v) == v; GCD(u,0) == u, GCD(0,0) == 0
	if (u == 0) {
		return (v);
	}

	if (v == 0) {
		return (u);
	}

	// GCD(1,v) == 1; GCD(u,1) == 1, GCD(1,1) == 1
	if (u == 1) {
		return (1);
	}

	if (v == 1) {
		return (1);
	}

	// Let shift := log K, where K is the greatest power of 2 dividing both u and v.
	size_t shift;

	for (shift = 0; ((u | v) & 1) == 0; shift++) {
		u >>= 1;
		v >>= 1;
	}

	while ((u & 1) == 0) {
		u >>= 1;
	}

	// From here on, u is always odd.
	do {
		// Remove all factors of 2 in v -- they are not common.
		// NOTE: v is not zero, so while will terminate.
		while ((v & 1) == 0) {
			v >>= 1;
		}

		// Now u and v are both odd. Swap if necessary so u <= v, then set v = v - u (which is even). For bignums, the
		// swapping is just pointer movement, and the subtraction can be done in-place.
		if (u > v) {
			uint16_t t = v;
			v = u;
			u = t;
		} // Swap u and v.

		v = (uint16_t) (v - u); // Here v >= u.
	}
	while (v != 0);

	// Restore common factors of 2.
	return ((uint16_t) (u << shift));
}

static uint16_t CyFxHeartbeatComputeGCDTicks(void) {
	uint16_t currentTicks = 0;

	for (size_t i = 0; i < HEARTBEAT_NUMBER; i++) {
		if (glHeartbeatFunctions[i].function != NULL) {
			currentTicks = CyFxHeartbeatGCD(currentTicks, glHeartbeatFunctions[i].ticks_total);
		}
	}

	// If no active functions exist anymore, reset to default of HEARTBEAT_TICKS_DEFAULT.
	if (currentTicks == 0) {
		currentTicks = HEARTBEAT_TICKS_DEFAULT;
	}

	return (currentTicks);
}

static uint16_t CyFxHeartbeatTimerToTicks(uint16_t timer) {
	// Never less than the minimum
	if (timer <= HEARTBEAT_TICKS_PRECISION) {
		return (1);
	}

	// Take care of the maximum
	if (timer >= (UINT16_MAX & ~(HEARTBEAT_TICKS_PRECISION - 1))) {
		return (UINT16_MAX / HEARTBEAT_TICKS_PRECISION);
	}

	// In between: round to nearest multiple of HEARTBEAT_PRECISION
	uint16_t timer_round_down = (uint16_t) (timer & ~(HEARTBEAT_TICKS_PRECISION - 1));
	uint16_t timer_round_up = (uint16_t) (timer_round_down + HEARTBEAT_TICKS_PRECISION);

	if ((timer - timer_round_down) <= (timer_round_up - timer)) {
		// round_down is closer than round_up or equally distant: round_down wins
		return (timer_round_down / HEARTBEAT_TICKS_PRECISION);
	}
	else {
		// round_up is closer than round_down: round_up wins
		return (timer_round_up / HEARTBEAT_TICKS_PRECISION);
	}
}

CyU3PReturnStatus_t CyFxHeartbeatInit(void) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	status = CyU3PMutexCreate(&glHeartbeatMutex, CYU3P_INHERIT);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

#if FX3_LOG_LEVEL == LOG_DEBUG
	// Enable SystemAliveMessage right away if the default log-level is appropriate
	status = CyFxHeartbeatFunctionAdd(&CyFxHeartbeatSystemAliveMessage, 0,
		HEARTBEAT_TICKS_DEFAULT * HEARTBEAT_TICKS_PRECISION);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}
#endif

	return (status);
}

CyU3PReturnStatus_t CyFxHeartbeatFunctionAdd(void (*func)(uint32_t input), uint32_t input, uint16_t timer) {
	// Do the given parameters make sense?
	if (func == NULL || timer == 0) {
		return (CY_U3P_ERROR_BAD_ARGUMENT);
	}

	// Transform the timer into Heartbeat ticks (multipliers of HEARTBEAT_PRECISION, never 0)
	uint16_t ticks = CyFxHeartbeatTimerToTicks(timer);

	// Thread-safety via Mutex
	CyU3PMutexGet(&glHeartbeatMutex, CYU3P_WAIT_FOREVER);

	// Adding the same function with the same input again just updates the ticks_total and resets ticks_remaining.
	for (size_t i = 0; i < HEARTBEAT_NUMBER; i++) {
		if (glHeartbeatFunctions[i].function == func && glHeartbeatFunctions[i].input == input) {
			glHeartbeatFunctions[i].ticks_remaining = 0; // Execute on next cycle.
			glHeartbeatFunctions[i].ticks_total = ticks;

			// Reset global timer to biggest possible value to maximize sleep
			glHeartbeatTimerTicks = CyFxHeartbeatComputeGCDTicks();

			// Thread-safety via Mutex
			CyU3PMutexPut(&glHeartbeatMutex);

			return (CY_U3P_SUCCESS);
		}
	}

	for (size_t i = 0; i < HEARTBEAT_NUMBER; i++) {
		if (glHeartbeatFunctions[i].function == NULL) {
			glHeartbeatFunctions[i].function = func;
			glHeartbeatFunctions[i].input = input;
			glHeartbeatFunctions[i].ticks_remaining = 0; // Execute on next cycle.
			glHeartbeatFunctions[i].ticks_total = ticks;

			// Reset global timer to biggest possible value to maximize sleep
			glHeartbeatTimerTicks = CyFxHeartbeatComputeGCDTicks();

			// Thread-safety via Mutex
			CyU3PMutexPut(&glHeartbeatMutex);

			return (CY_U3P_SUCCESS);
		}
	}

	// Thread-safety via Mutex
	CyU3PMutexPut(&glHeartbeatMutex);

	return (CY_U3P_ERROR_BAD_THRESHOLD);
}

void CyFxHeartbeatFunctionRemove(void (*func)(uint32_t input), uint32_t input) {
	// Do the given parameters make sense?
	if (func == NULL) {
		return;
	}

	// Thread-safety via Mutex
	CyU3PMutexGet(&glHeartbeatMutex, CYU3P_WAIT_FOREVER);

	for (size_t i = 0; i < HEARTBEAT_NUMBER; i++) {
		if (glHeartbeatFunctions[i].function == func && glHeartbeatFunctions[i].input == input) {
			glHeartbeatFunctions[i].function = NULL;
			glHeartbeatFunctions[i].input = 0;
			glHeartbeatFunctions[i].ticks_remaining = 0;
			glHeartbeatFunctions[i].ticks_total = 0;

			// Reset global timer to biggest possible value to maximize sleep
			glHeartbeatTimerTicks = CyFxHeartbeatComputeGCDTicks();

			// Thread-safety via Mutex
			CyU3PMutexPut(&glHeartbeatMutex);

			return;
		}
	}

	// Thread-safety via Mutex
	CyU3PMutexPut(&glHeartbeatMutex);
}

void CyFxHeartbeatFunctionsExecuteLoop(void) {
	size_t i;
	uint32_t nextSleepTime = (HEARTBEAT_TICKS_DEFAULT * HEARTBEAT_TICKS_PRECISION);

	for (;;) {
		CyU3PThreadSleep(nextSleepTime);

		if (glAppRunning) {
			// Thread-safety via Mutex
			CyU3PMutexGet(&glHeartbeatMutex, CYU3P_WAIT_FOREVER);

			// Execute all defined heart-beat functions, if it's their turn
			for (i = 0; i < HEARTBEAT_NUMBER; i++) {
				if (glHeartbeatFunctions[i].function != NULL) {
					if (glHeartbeatFunctions[i].ticks_remaining == 0) {
						glHeartbeatFunctions[i].function(glHeartbeatFunctions[i].input);

						// Reset function timer.
						glHeartbeatFunctions[i].ticks_remaining = glHeartbeatFunctions[i].ticks_total;
					}

					// Subtract the time spent in the next sleep (careful about underflow!)
					if (glHeartbeatFunctions[i].ticks_remaining <= glHeartbeatTimerTicks) {
						glHeartbeatFunctions[i].ticks_remaining = 0;
					}
					else {
						glHeartbeatFunctions[i].ticks_remaining = (uint16_t) (glHeartbeatFunctions[i].ticks_remaining
							- glHeartbeatTimerTicks);
					}
				}
			}

			nextSleepTime = (uint32_t) (glHeartbeatTimerTicks * HEARTBEAT_TICKS_PRECISION);

			// Thread-safety via Mutex
			CyU3PMutexPut(&glHeartbeatMutex);
		}
	}
}

void CyFxHeartbeatSystemAliveMessage(uint32_t input) {
	(void) input; // UNUSED

	CyFxErrorHandler(LOG_DEBUG, "System still alive.", CY_U3P_SUCCESS);
}
