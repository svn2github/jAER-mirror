SBret logic versions


DAVIS_V4_SBRet20: This logic is for small production run of 30x boards with IMU-I2C-CPLD integration. Derved from SBRet10_2_IMU which actually is global shutter logic for SBRet20 chip, which supports this function.

SBret10: this logic belongs to the SBret10 test and small boards (rolling shutter)

SBret10_2: this experimental logic belongs to SBret10_2 small boards with two synchronization jacks

SBret10s: this patch logic is only used by one small camera with a problem in nAck and reset signals (it's wired), so in the firmware that signals are interchanged

SBRet20: this is the global shutter logic for SBret20 chips for the test and small boards

SBRet10_2_IMU: Same as SBret10_2 but with experimental IMU and AER data integration into output FIFO.