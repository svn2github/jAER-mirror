--------------------------------------------------------------------------------
-- Company: INI
-- Engineer: Diederik Paul Moeys
--
-- Create Date:    01.10.2014
-- Design Name:    
-- Module Name:    ObjectMotionCellConfigRecords
-- Project Name:   VISUALISE
-- Target Device:  Latticed LFE3-17EA-7ftn256i
-- Tool versions:  Diamond x64 3.0.0.97x
-- Description:	   Module to get SPI parameters of the Object Motion Cell RGC
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Libraries -------------------------------------------------------------------
-------------------------------------------------------------------------------- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ObjectMotionCellConfigRecords.all;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Entity Declaration ----------------------------------------------------------
--------------------------------------------------------------------------------
entity ObjectMotionCellSPIConfig is
	port (
		-- Clock and reset inputs
		Clock_CI	: in std_logic;
		Reset_RI	: in std_logic;
		
		-- Output containing parameters
		ObjectMotionCellConfig_DO            : out tObjectMotionCellConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI          : in  unsigned(6 downto 0);
		ConfigParamAddress_DI           : in  unsigned(7 downto 0);
		ConfigParamInput_DI             : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI             : in  std_logic;
		ObjectMotionCellConfigParamOutput_DO : out std_logic_vector(31 downto 0)); -- Check parameters
end ObjectMotionCellSPIConfig;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------  

--------------------------------------------------------------------------------
-- Architecture Declaration ----------------------------------------------------
--------------------------------------------------------------------------------
architecture Behavioural of ObjectMotionCellSPIConfig is
	signal LatchObjectMotionCellReg_S                            : std_logic;
	signal ObjectMotionCellInput_DP, ObjectMotionCellInput_DN         : std_logic_vector(31 downto 0);
	signal ObjectMotionCellOutput_DP, ObjectMotionCellOutput_DN       : std_logic_vector(31 downto 0);
	signal ObjectMotionCellConfigReg_DP, ObjectMotionCellConfigReg_DN : tObjectMotionCellConfig;
begin
	ObjectMotionCellConfig_DO            <= ObjectMotionCellConfigReg_DP;
	ObjectMotionCellConfigParamOutput_DO <= ObjectMotionCellOutput_DP;

	LatchObjectMotionCellReg_S <= '1' when ConfigModuleAddress_DI = ObjectMotionCellCONFIG_MODULE_ADDRESS else '0';
-------------------------------------------------------------------------------- 
	-- Combinational process
	ObjectMotionCellIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, ObjectMotionCellInput_DP, ObjectMotionCellConfigReg_DP)
	begin
		ObjectMotionCellConfigReg_DN <= ObjectMotionCellConfigReg_DP;
		ObjectMotionCellInput_DN     <= ConfigParamInput_DI;
		ObjectMotionCellOutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when ObjectMotionCellCONFIG_PARAM_ADDRESSES.Threshold_S =>
				ObjectMotionCellConfigReg_DN.Threshold_S <= ObjectMotionCellInput_DP(0);
				ObjectMotionCellOutput_DN(0)       <= ObjectMotionCellConfigReg_DP.Threshold_S;

			when ObjectMotionCellCONFIG_PARAM_ADDRESSES.DecayTime_S =>
				ObjectMotionCellConfigReg_DN.DecayTime_S <= ObjectMotionCellInput_DP(0);
				ObjectMotionCellOutput_DN(0)                <= ObjectMotionCellConfigReg_DP.DecayTime_S;

			when ObjectMotionCellCONFIG_PARAM_ADDRESSES.TimerLimit_S =>
				ObjectMotionCellConfigReg_DN.TimerLimit_S <= ObjectMotionCellInput_DP(0);
				ObjectMotionCellOutput_DN(0)                  <= ObjectMotionCellConfigReg_DP.TimerLimit_S;

			when others => null;
			
		end case;
	end process ObjectMotionCellIO;
--------------------------------------------------------------------------------
	-- Sequential process
	ObjectMotionCellUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			ObjectMotionCellInput_DP  <= (others => '0');
			ObjectMotionCellOutput_DP <= (others => '0');

			ObjectMotionCellConfigReg_DP <= tObjectMotionCellConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			ObjectMotionCellInput_DP  <= ObjectMotionCellInput_DN;
			ObjectMotionCellOutput_DP <= ObjectMotionCellOutput_DN;

			if LatchObjectMotionCellReg_S = '1' and ConfigLatchInput_SI = '1' then
				ObjectMotionCellConfigReg_DP <= ObjectMotionCellConfigReg_DN;
			end if;
		end if;
	end process ObjectMotionCellUpdate;
--------------------------------------------------------------------------------
end Behavioural;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------