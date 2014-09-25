VHDL code for:
Same as SBret10_2 but with experimental IMU and AER data integration into output FIFO.
Specs: 
	-IMU to CPLD, selected running by bit 0 of first IMU register
	-Rolling and Global shutter modes both integrated and selected by bit 1 of first 8 bit IMU register
	- black and white spots solved by constraint on ADC data line inputs to satisfy setup time specs of ADC
	- early packet timer changed to 1.5ms early packet timeout
	