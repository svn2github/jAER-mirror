library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.APPROACHSENSITIVITYConfigRecords.all;

entity ApproachCellStateMachine is
	generic(
		SubunitXAddr, SubunitYAddr: std_logic_vector(AERAddressBits- SubsamplingBits downto 0);

	port(
		Clock_CI                 : in  std_logic;
		Reset_RI                 : in  std_logic;

		 --output to DVSAER including 	ApproachCell Membrane Potential encoded in data_encode
		OutFifoControl_SI        : in  tFromFifoWriteSide;
		OutFifoControl_SO        : out tToFifoWriteSide;
		OutFifoData_DO           : out std_logic_vector(EVENT_WIDTH - 1 downto 0);
		
			-- Fifo input (from DVSAER)
		DVSAERFifoControl_SI     : in  tFromFifoReadSide;
		DVSAERFifoControl_SO     : out tToFifoReadSide;
		DVSAERFifoData_DI        : in  std_logic_vector(EVENT_WIDTH - 1 downto 0);

		
		--VmemOn, VmemOff		 : out real in the range of -2^(m-1) to 2^(m-1)-2(-f);  Instantiate SubunitStatemachine inside AC stateMachine
		
		-- Configuration input
		APPROACHSENSITIVITYConfig_DI     : in  tAPPROACHSENSITIVITYConfig);
		
end entity ApproachCellStateMachine;

architecture Behavioral of ApproachCellStateMachine is
	attribute syn_enum_encoding : string

	type state is (stIdle, stResetCounter, stCheckCounter, stDecayALL, stUpdateACVmem, stComparetoRN, stComparetoIFThreshold, Fire);
	
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;
	
	-- Register outputs to FIFO.
	signal OutFifoWriteReg_S      : std_logic;
	signal OutFifoDataRegEnable_S : std_logic;
	signal OutFifoDataReg_D       : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	
	signal sum 					 : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal result				 : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal OnInhibition, OffExcitation :std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal ACVmem				 : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal CounterValue		     : std_logic_vector(Counter_WIDTH - 1 downto 0);
	
	
	-- Register outputs to APPROACHSENSITIVITY.
	APPROACHSENSITIVITYConfig_DI     : in  tAPPROACHSENSITIVITYConfig;
	
	
