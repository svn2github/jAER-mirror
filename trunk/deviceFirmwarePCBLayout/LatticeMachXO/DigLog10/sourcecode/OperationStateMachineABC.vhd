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
	RreadoutxDO			  : out   std_logic;
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
	
	-- FX2 interface
	FX2FifoInFullxSBI       : in    std_logic;
    FX2FifoWritexEBO        : out   std_logic;
    FX2FifoReadxEBO         : out   std_logic;
  
    FX2FifoPktEndxSBO       : out   std_logic; --???
    FX2FifoAddressxDO       : out   std_logic_vector(1 downto 0); --???
    
end OperationStateMachineABC;

architecture Behavioral of OperationStateMachineABC is
  
  signal ClockxC                  				: std_logic; --???
  
  signal RowCount             	  				: std_logic_vector(4 downto 0);
  signal ColCount             	  				: std_logic_vector(5 downto 0);
  signal ResetEnd, ExposureEnd, TerminationEnd 	: std_logic;
  signal ResetCount 			  				: std_logic_vector(18 downto 0); --90000, 1ms
  signal ExposureCount	                		: std_logic_vector(21 downto 0); --1800000, 20ms
  signal TerminationCount						: std_logic_vector(21 downt0 0); --900000, 10ms

 
begin
  
  StateClockxC <= ClockxC;
  
   
-- determine the operation cycle
  op_cycle : process (CheckxDI, S1xDI, S0xDI, ResetEnd, ExposureEnd, TerminationEnd, ClockxC)
  begin  
  
    if CheckxDI = '1' then
		--readout phase
		--reset log counter...
		
		ReadoutxDO <= '1';
		if RowCount = 30 then
			--CheckxDI <= '0'; --legal???
			RowCount <= '0';
		else
			if RowCount = '0' then
				RowScanInitxDO <= '1';
			else
				RowScanInitxDO <= '0';
			end if;
			if ColCount = '0' then
				PreChargexDO <= '1';
				ColCount = '1';
			elseif ColCount = '1' then
				ColScanInitxDO <= '1';
				ColCount <= ColCount + 1;
				ClockRowScanxCO <= '1';
				ClockColScanxCO <= ClockxC;
				-- write to fifo
				
			elseif ColCount > '1' and ColCount < 60 then --"111100"?
				ColCount <= ColCount + 1;
				ColScanInitxDO <= '0';
				ClockColScanxCO <= ClockxC;
				ClockRowScanxCO <= '0';
				-- write to fifo
				
			else -- ColCount reaches 60
				ColCount <= '0';
				RowCount <= RowCount + 1;
				-- write to fifo and fifo to FX2
				
			end if;
		end if;
		
	else
		if S0 = '0' and S1 = '0' then
			-- stay in idle state
			ResetxDO    <= '0';
			VREFstatus	<= VREFisLow;
			ReadoutxDO <= '0';
			RowCount := '0';
			ColCount := '0';
			RowScanInitxDO <= '0';
			ColScanInitxDO <= '0';	
			ClockColScanxCO <= '0';
			ClockRowScanxCO <= '0';
			ResetCount <= '0';
			ResetEnd <= '0';
			ExposureCount <= '0';
			ExposureEnd <= '0';
			TerminationCount <= '0';
			TerminationEnd <= '0';
			
		elseif S0 = '1' or S1 = '1' then
			--reset pixel
			ResetxDO    <= '1';
			VREFstatus	<= VREFisLow;
			--...
			
			if ResetCount < 90000 then -- 1ms reset time
				ResetCount <= ResetCount + 1;
			else
				ResetEnd <= '1';
			end if;
			if ResetEnd = '1' then
				if S1 = '0' then
					--readout phase
					--reset log counter...
					
					ReadoutxDO <= '1';
					if RowCount = 30 then
						--CheckxDI <= '0';
						RowCount <= '0';
					else
						if RowCount = '0' then
							RowScanInitxDO <= '1';
						else
							RowScanInitxDO <= '0';
						end if;
						if ColCount = '0' then
							PreChargexDO <= '1';
							ColCount = '1';
						elseif ColCount = '1' then
							ColScanInitxDO <= '1';
							ColCount <= ColCount + 1;
							ClockRowScanxCO <= '1';
							ClockColScanxCO <= ClockxC;
							-- write to fifo
				
						elseif ColCount > '1' and ColCount < 60 then --"111100"?
							ColCount <= ColCount + 1;
							ColScanInitxDO <= '0';
							ClockColScanxCO <= ClockxC;
							ClockRowScanxCO <= '0';
							-- write to fifo
				
						else -- ColCount reaches 60
							ColCount <= '0';
							RowCount <= RowCount + 1;
							-- write to fifo
							
						end if;
					end if;
				else
					--esposure phase
					ResetxDO    <= '0';
					VREFstatus	<= VREFisHi;
					--...
					
					--start log counter...
					
					if EposureCount < 1800000 then -- 20ms exposure time
						ExposureCount <= ExposureCount + 1;
					else
						EsposureEnd <= '1';
					end if;
					if EposureEnd = '1' then
						if S0 = '0' then
							--readout phase
							--reset log counter...
							
							ReadoutxDO <= '1';
							if RowCount = 30 then
								--Check <= '0';
								RowCount <= '0';
							else
								if RowCount = '0' then
									RowScanInitxDO <= '1';
								else
									RowScanInitxDO <= '0';
								end if;
								if ColCount = '0' then
									PreChargexDO <= '1';
									ColCount = '1';
								elseif ColCount = '1' then
									ColScanInitxDO <= '1';
									ColCount <= ColCount + 1;
									ClockRowScanxCO <= '1';
									ClockColScanxCO <= ClockxC;
									-- write to fifo
				
								elseif ColCount > '1' and ColCount < 60 then --"111100"?
									ColCount <= ColCount + 1;
									ColScanInitxDO <= '0';
									ClockColScanxCO <= ClockxC;
									ClockRowScanxCO <= '0';
									-- write to fifo
				
								else -- ColCount reaches 60
									ColCount <= '0';
									RowCount <= RowCount + 1;
									-- write to fifo
								
								end if;
							end if;
						else
							--termination phase
							VREFstatus	<= VREFisDecay;
							--...
							
							if TerminationCount < 900000 then -- 10ms termination time
								TerminationCount <= TerminationCount + 1;
							else
								TerminationEnd <= '1';
							end if;
							if TerminationEnd = '1' then
								--readout phase
								--reset log counter...
								
								ReadoutxDO <= '1';
								if RowCount = 30 then
									--Check <= '0';
									RowCount <= '0';
								else
									if RowCount = '0' then
										RowScanInitxDO <= '1';
									else
										RowScanInitxDO <= '0';
									end if;
									if ColCount = '0' then
										PreChargexDO <= '1';
										ColCount = '1';
									elseif ColCount = '1' then
										ColScanInitxDO <= '1';
										ColCount <= ColCount + 1;
										ClockRowScanxCO <= '1';
										ClockColScanxCO <= ClockxC;
										-- write to fifo
				
									elseif ColCount > '1' and ColCount < 60 then --"111100"?
										ColCount <= ColCount + 1;
										ColScanInitxDO <= '0';
										ClockColScanxCO <= ClockxC;
										ClockRowScanxCO <= '0';
										-- write to fifo
				
									else -- ColCount reaches 60
										ColCount <= '0';
										RowCount <= RowCount + 1;
										-- write to fifo
								
									end if;
								end if;
							end if;
						end if;
					end if;
				end if;
			end if;
		end if;
	end if;
	
    

  end process p_col;

end Behavioral;
