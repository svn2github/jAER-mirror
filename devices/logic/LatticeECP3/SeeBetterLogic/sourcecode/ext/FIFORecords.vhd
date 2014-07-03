library ieee;
use ieee.std_logic_1164.all;

package FIFORecords is
	-- Inputs to the FIFO.
	type tToFifoReadSide is record
		Read_S : std_logic;
	end record tToFifoReadSide;

	type tToFifoWriteSide is record
		Data_D	: std_logic_vector;
		Write_S : std_logic;
	end record tToFifoWriteSide;

	type tToFifo is record
		ReadSide  : tToFifoReadSide;
		WriteSide : tToFifoWriteSide;
	end record tToFifo;

	-- Outputs from the FIFO.
	type tFromFifoReadSide is record
		Data_D		  : std_logic_vector;
		Empty_S		  : std_logic;
		AlmostEmpty_S : std_logic;
	end record tFromFifoReadSide;

	type tFromFifoWriteSide is record
		Full_S		 : std_logic;
		AlmostFull_S : std_logic;
	end record tFromFifoWriteSide;

	type tFromFifo is record
		ReadSide  : tFromFifoReadSide;
		WriteSide : tFromFifoWriteSide;
	end record tFromFifo;
end package FIFORecords;
