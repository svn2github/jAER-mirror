#ifndef _INCLUDED_HEARTBEAT_H_
#define _INCLUDED_HEARTBEAT_H_ 1

// Heartbeat system configuration
#define HEARTBEAT_NUMBER          (8)
#define HEARTBEAT_TICKS_PRECISION (512) // must be multiple of two, in ms
#define HEARTBEAT_TICKS_DEFAULT   (10)

// Function declarations
CyU3PReturnStatus_t CyFxHeartbeatInit(void);
CyU3PReturnStatus_t CyFxHeartbeatFunctionAdd(void (*func)(uint32_t input), uint32_t input, uint16_t timer);
void CyFxHeartbeatFunctionRemove(void (*func)(uint32_t input), uint32_t input);
void CyFxHeartbeatFunctionsExecuteLoop(void);
void CyFxHeartbeatSystemAliveMessage(uint32_t input);

#endif /* _INCLUDED_HEARTBEAT_H_ */
