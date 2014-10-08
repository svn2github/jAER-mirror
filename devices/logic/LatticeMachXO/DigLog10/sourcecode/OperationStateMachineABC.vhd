--------------------------------------------------------------------------------
-- Company: 
-- Engineer: Chenghan Li
--
-- Create Date:    12/18/2012
-- Design Name:    
-- Module Name:    OperationStatemachine - Behavioral
-- Project Name:   DigLog10PCB
-- Target Device:  
-- Tool versions:  
-- Description: controls the general operation of the chip
--
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity OperationStateMachineABC is

  port (
    ClockxCI              : in    std_logic; --90MHz?
	CheckxDI			  : in    std_logic;
	S0xDI				  : in    std_logic;
	S1xDI				  : in    std_logic;
	ResetxDO			  : out   std_logic;
	PreChargexDO		  : out   std_logic;
	ReadoutxDO			  : out   std_logic;
	RowScanInitxDO		  : out   std_logic;
	ColScanInitxDO		  : out   std_logic;
	ClockRowScanxCO		  : out   std_logic;
	ClockColScanxCO		  : out   std_logic;
	--fifo interface, adapting from monitorStateMachine
	-- fifo flags
    FifoFullxSI           : in  std_logic;
    -- fifo control lines
    FifoWritexEO          : out std_logic;
	
	-- log counter interface
	CounterResetxRBO		: out	std_logic;
	CounterIncrementxSO		: out	std_logic;
	-- FX2 interface to produce VREF
	VrefStatusxDO       : out    std_logic_vector(1 downto 0)
    
    );
end OperationStateMachineABC;

architecture Behavioral of OperationStateMachineABC is
  
  signal ClockxC                  				: std_logic; --???
  
  signal RowCount             	  				: std_logic_vector(4 downto 0);
  signal ColCount             	  				: std_logic_vector(5 downto 0);
  signal ResetEnd, ExposureEnd, TerminationEnd 	: std_logic;
  signal ResetCount 			  				: std_logic_vector(18 downto 0); --90000, 1ms
  signal ExposureCount	                		: std_logic_vector(21 downto 0); --1800000, 20ms
  signal TerminationCount						: std_logic_vector(21 downto 0); --900000, 10ms

 
begin
  
  --StateClockxC <= ClockxC;
     
-- determine the operation cycle
  op_cycle : process (CheckxDI, S1xDI, S0xDI, ResetEnd, ExposureEnd, TerminationEnd, ClockxC)
  begin  
	FifoWritexEO <= '0';

    if CheckxDI = '1' then
		--readout phase
		--reset log counter...
		CounterResetxRBO <= '0';
		CounterIncrementxSO <= '0';
		
		ReadoutxDO <= '1';
		if RowCount = 30 then
			--CheckxDI <= '0'; --legal???
			RowCount <= "00000";
		else
			if RowCount = 0 then
				RowScanInitxDO <= '1';
			else
				RowScanInitxDO <= '0';
			end if;
			if ColCount = 0 then
				PreChargexDO <= '1';
				ColCount <= "000001";
			elsif ColCount = 1 then
				ColScanInitxDO <= '1';
				ColCount <= ColCount + 1;
				ClockRowScanxCO <= '1';
				ClockColScanxCO <= ClockxC;
				-- write to fifo
				FifoWritexEO <= '1';
			elsif ColCount > 1 and ColCount < 60 then --"111100"?
				ColCount <= ColCount + 1;
				ColScanInitxDO <= '0';
				ClockColScanxCO <= ClockxC;
				ClockRowScanxCO <= '0';
				-- write to fifo
				FifoWritexEO <= '1';
			else -- ColCount reaches 60
				ColCount <= "000000";
				RowCount <= RowCount + 1;
				-- write to fifo and fifo to FX2
				FifoWritexEO <= '1';
			end if;
		end if;
		
	else
		if S0xDI = '0' and S1xDI = '0' then
			-- initialize
			ResetxDO    <= '0';
			VrefStatusxDO	<= "00"; --vref is low
			ReadoutxDO <= '0';
			RowCount <= "00000";
			ColCount <= "000000";
			RowScanInitxDO <= '0';
			ColScanInitxDO <= '0';	
			ClockColScanxCO <= '0';
			ClockRowScanxCO <= '0';
			ResetCount <= "0000000000000000000";
			ResetEnd <= '0';
			ExposureCount <= "0000000000000000000000";
			ExposureEnd <= '0';
			TerminationCount <= "0000000000000000000000";
			TerminationEnd <= '0';
			CounterResetxRBO <= '0';
			CounterIncrementxSO <= '0';
			FifoWritexEO <= '0';
			
		elsif S0xDI = '1' or S1xDI = '1' then
			--reset pixel
			ResetxDO    <= '1';
			VrefStatusxDO	<= "00"; --vref is low
			
			if ResetCount < 90000 then -- 1ms reset time
				ResetCount <= ResetCount + 1;
			else
				ResetEnd <= '1';
			end if;
			if ResetEnd = '1' then
				if S1xDI = '0' then
					--readout phase
					--reset log counter...
					CounterResetxRBO <= '0';
					CounterIncrementxSO <= '0';
					ReadoutxDO <= '1';
					if RowCount = 30 then
						--CheckxDI <= '0';
						RowCount <= "00000";
					else
						if RowCount = 0 then
							RowScanInitxDO <= '1';
						else
							RowScanInitxDO <= '0';
						end if;
						if ColCount = 0 then
							PreChargexDO <= '1';
							ColCount <= "000001";
						elsif ColCount = 1 then
							ColScanInitxDO <= '1';
							ColCount <= ColCount + 1;
							ClockRowScanxCO <= '1';
							ClockColScanxCO <= ClockxC;
							-- write to fifo
							FifoWritexEO <= '1';
						elsif ColCount > 1 and ColCount < 60 then --"111100"?
							ColCount <= ColCount + 1;
							ColScanInitxDO <= '0';
							ClockColScanxCO <= ClockxC;
							ClockRowScanxCO <= '0';
							-- write to fifo
							FifoWritexEO <= '1';
						else -- ColCount reaches 60
							ColCount <= "000000";
							RowCount <= RowCount + 1;
							-- write to fifo
							FifoWritexEO <= '1';
						end if;
					end if;
				else
					--esposure phase
					ResetxDO    <= '0';
					VrefStatusxDO	<= "01"; --vref is hi
					
					--start log counter...
					CounterResetxRBO <= '1';
					CounterIncrementxSO <= '1';
					if ExposureCount < 1800000 then -- 20ms exposure time
						ExposureCount <= ExposureCount + 1;
					else
						ExposureEnd <= '1';
					end if;
					if ExposureEnd = '1' then
						if S0xDI = '0' then
							--readout phase
							--reset log counter...
							CounterResetxRBO <= '0';
							CounterIncrementxSO <= '0';
							ReadoutxDO <= '1';
							if RowCount = 30 then
								--Check <= '0';
								RowCount <= "00000";
							else
								if RowCount = 0 then
									RowScanInitxDO <= '1';
								else
									RowScanInitxDO <= '0';
								end if;
								if ColCount = 0 then
									PreChargexDO <= '1';
									ColCount <= "000001";
								elsif ColCount = 1 then
									ColScanInitxDO <= '1';
									ColCount <= ColCount + 1;
									ClockRowScanxCO <= '1';
									ClockColScanxCO <= ClockxC;
									-- write to fifo
									FifoWritexEO <= '1';
								elsif ColCount > 1 and ColCount < 60 then --"111100"?
									ColCount <= ColCount + 1;
									ColScanInitxDO <= '0';
									ClockColScanxCO <= ClockxC;
									ClockRowScanxCO <= '0';
									-- write to fifo
									FifoWritexEO <= '1';
								else -- ColCount reaches 60
									ColCount <= "000000";
									RowCount <= RowCount + 1;
									-- write to fifo
									FifoWritexEO <= '1';
								end if;
							end if;
						else
							--termination phase
							VrefStatusxDO	<= "10"; --vref is decay
							--counter to linear mode
							--...
							
							if TerminationCount < 900000 then -- 10ms termination time
								TerminationCount <= TerminationCount + 1;
							else
								TerminationEnd <= '1';
							end if;
							if TerminationEnd = '1' then
								--readout phase
								--reset log counter...
								CounterResetxRBO <= '0';
								CounterIncrementxSO <= '0';
								ReadoutxDO <= '1';
								if RowCount = 30 then
									--Check <= '0';
									RowCount <= "00000";
								else
									if RowCount = 0 then
										RowScanInitxDO <= '1';
									else
										RowScanInitxDO <= '0';
									end if;
									if ColCount = 0 then
										PreChargexDO <= '1';
										ColCount <= "000001";
									elsif ColCount = 1 then
										ColScanInitxDO <= '1';
										ColCount <= ColCount + 1;
										ClockRowScanxCO <= '1';
										ClockColScanxCO <= ClockxC;
										-- write to fifo
										FifoWritexEO <= '1';
									elsif ColCount > 1 and ColCount < 60 then --"111100"?
										ColCount <= ColCount + 1;
										ColScanInitxDO <= '0';
										ClockColScanxCO <= ClockxC;
										ClockRowScanxCO <= '0';
										-- write to fifo
										FifoWritexEO <= '1';
									else -- ColCount reaches 60
										ColCount <= "000000";
										RowCount <= RowCount + 1;
										-- write to fifo
										FifoWritexEO <= '1';
									end if;
								end if;
							end if;
						end if;
					end if;
				end if;
			end if;
		end if;
	end if;
	
    

  end process op_cycle;

end Behavioral;
