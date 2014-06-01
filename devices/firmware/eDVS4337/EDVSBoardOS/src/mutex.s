/*
 * mutex.s
 *
 *  Created on: May 7, 2014
 *      Author: raraujo
 */


.equ locked,1
.equ unlocked,0

@ lock_mutex
@ Declare for use from C as extern void lock_mutex(void * mutex);
    .global lock_mutex_M4
lock_mutex_M4:
testing:
	LDREX   r2, [r0]
    CMP     r2, #locked   @ Test if mutex is locked or unlocked
    BEQ     wait          @ If locked - wait for it to be released, from 2
    STREX   r2, r1, [r0]  @ Not locked, attempt to lock it
    CMP   	r2, #0        @ Check if Store-Exclusive failed
    BNE     testing       @ Failed - retry from 1
    # Lock acquired
    DMB                   @ Required before accessing protected resource
    BX      lr

wait:  @ Take appropriate action while waiting for mutex to become unlocked
    @ WAIT_FOR_UPDATE
    #WFE
    B       testing            @ Retry from 1


@ unlock_mutex
@ Declare for use from C as extern void unlock_mutex(void * mutex);
    .global unlock_mutex_M4
unlock_mutex_M4:
    LDR     r1, =unlocked
    DMB                   @ Required before releasing protected resource
    STR     r1, [r0]      @ Unlock mutex
    @ SIGNAL_UPDATE
    #SEV
    BX      lr
