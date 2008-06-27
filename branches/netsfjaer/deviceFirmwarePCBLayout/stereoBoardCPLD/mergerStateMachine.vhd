----------------------------------------------------------------------------------
-- Company:        Institute of Neuroinformatics Uni/ETHZ
-- Engineer:       Rico Möckel
-- 
-- Create Date:    11:44:49 06/07/2006 
-- Design Name: 
-- Module Name:    mergerStateMachine - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: State machine that controls communication between FIFO SM and two
--              Monitor SM. Merges event streams of two chips.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mergerStateMachine is
    port ( 
	   Clk                  : in   std_logic;                    --Clock
		Rst                  : in   std_logic;                    --Reset
	   SetMonitorEventReady : in   std_logic_vector(1 downto 0); --inputs from monitor SM indicating that there is a new valid event
      ClearEventReady      : in   std_logic;                    --input from FIFO SM indicating the event has been copied to FIFO
	   MonitorEventReady    : out  std_logic_vector(1 downto 0); --output to monitor SM indicating that there is a new valid event
      EventReady           : out  std_logic;                    --output to FIFO SM indicating there is a new valid event
      Sel                  : out  std_logic);                   --output for selecting channel             
end mergerStateMachine;

architecture Behavioral of mergerStateMachine is

  -- uart states
  type state_type is (waitForEvent, setEventReady, waitForClearEvent);

  -- all registers
  type reg_type is
    record
      -- current uart state
      State      : state_type;
      -- data register
		MonitorEventReady : std_logic_vector(1 downto 0); --Register storing if there is a new event from the monitor SM
 		-- Select
		Sel        : std_logic;
		-- event ready
		EventReady : std_logic;
    end record;

  -- reset value
  constant R_RST : reg_type := (
    State             => waitForEvent,
    MonitorEventReady => (others => '0'),
    Sel               => '0',
    EventReady        => '0'
	 );

  -- current and next register value
  signal r, rin : reg_type;

begin  -- Behavioral

	-- all registers
	regs : process( Clk, Rst )
	begin	-- process reg
      if rising_edge(Clk) then
			r <= rin;
      end if;
      if rst = '0' then		-- asynchronous reset
         r <= R_RST;
      end if;
	end process regs;


  -- combinatoral logic
  comb : process (r, SetMonitorEventReady, ClearEventReady)
    variable v : reg_type;
  begin  -- process comb

    -- keep old by default
    v := r;

    --store if a monitor registers an event
    if SetMonitorEventReady(0) = '1' then
       v.MonitorEventReady(0) := '1';
    end if;
    if SetMonitorEventReady(1) = '1' then
       v.MonitorEventReady(1) := '1';
    end if;
 	 
    case r.State is
        
	   when waitForEvent =>  --wait for event if last event came from
		                      --monitor 0 check monitor 1 first and vice versa
									 --set select accordingly
		  if r.Sel = '0' then
		    if r.MonitorEventReady(1) = '1' then
			   v.Sel := '1';
			   v.State := setEventReady;
		  v.EventReady := '1';
		  v.State := waitForClearEvent;
			 elsif r.MonitorEventReady(0) = '1' then
			   v.Sel := '0';
			   v.State := setEventReady;
			 end if;
		  else
			 if r.MonitorEventReady(0) = '1' then
			   v.Sel := '0';
			   v.State := setEventReady;
		    elsif r.MonitorEventReady(1) = '1' then
			   v.Sel := '1';
			   v.State := setEventReady;
			 end if;
		  end if;


	   when setEventReady =>  --tell FIFO SM that new event is registered
		  v.EventReady := '1';
		  v.State := waitForClearEvent;


	   when waitForClearEvent =>  --wait for signal from FIFO SM that event is processed
		  if ClearEventReady = '1' then
		    if r.Sel = '0' then			   
			   v.MonitorEventReady(0) := '0';
			 else
			   v.MonitorEventReady(1) := '0';
			 end if;
			 v.EventReady := '0';
		    v.State := waitForEvent;
		  end if;

    end case;
	 

    -- drive register
    rin <= v;
    -- drive outputs (registered)
    Sel               <= r.Sel;
	 EventReady        <= r.EventReady;
	 MonitorEventReady <= r.MonitorEventReady;
    
  end process comb;

end Behavioral;

