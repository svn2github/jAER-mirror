library ieee;
use ieee.std_logic_1164.all;
use work.ShiftRegisterModes.all;

-- Generic shift register, able to shift from DataIn to DataOut{R,L} in both
-- directions, selected at run-time, with parallel load support, as well as
-- parallel output of all register states.
-- Parallel output is always enabled and reflects the currently stored bits.
-- Modes are:
-- 00 - do nothing
-- 01 - parallel load from ParallelWrite_DI (can be used as clear!)
-- 10 - shift right
-- 11 - shift left

entity ShiftRegister is
	generic (
		SIZE : integer := 8);
	port (
		Clock_CI : in std_logic;
		Reset_RI : in std_logic;

		Mode_SI : in std_logic_vector(SHIFTREGISTER_MODE_SIZE-1 downto 0);

		DataIn_DI		: in  std_logic;
		DataOutRight_DO : out std_logic;
		DataOutLeft_DO	: out std_logic;

		ParallelWrite_DI : in  std_logic_vector(SIZE-1 downto 0);
		ParallelRead_DO	 : out std_logic_vector(SIZE-1 downto 0));
end entity ShiftRegister;

architecture Behavioral of ShiftRegister is
	signal ShiftReg_DP, ShiftReg_DN : std_logic_vector(SIZE-1 downto 0);
begin
	shiftRegState : process (ShiftReg_DP, Mode_SI, DataIn_DI, ParallelWrite_DI)
	begin
		-- Don't change the shift register by default.
		ShiftReg_DN <= ShiftReg_DP;

		case Mode_SI is
			when SHIFTREGISTER_MODE_DO_NOTHING => null;

			when SHIFTREGISTER_MODE_PARALLEL_LOAD =>
				ShiftReg_DN <= ParallelWrite_DI;

			when SHIFTREGISTER_MODE_SHIFT_RIGHT =>
				ShiftReg_DN <= DataIn_DI & ShiftReg_DP(SIZE-1 downto 1);

			when SHIFTREGISTER_MODE_SHIFT_LEFT =>
				ShiftReg_DN <= ShiftReg_DP(SIZE-2 downto 0) & DataIn_DI;

			when others => null;
		end case;
	end process shiftRegState;

	shiftRegUpdate : process (Clock_CI, Reset_RI) is
	begin  -- process shiftRegUpdate
		if Reset_RI = '1' then			  -- asynchronous reset (active high)
			ShiftReg_DP <= (others => '0');
		elsif rising_edge(Clock_CI) then  -- rising clock edge
			ShiftReg_DP <= ShiftReg_DN;
		end if;
	end process shiftRegUpdate;

	-- Always output current state.
	ParallelRead_DO <= ShiftReg_DP;

	-- Output both the left and right-most bits, since, depending on the
	-- direction you're currently shifting, which one you want to monitor changes.
	DataOutRight_DO <= ShiftReg_DP(0);
	DataOutLeft_DO	<= ShiftReg_DP(SIZE-1);
end architecture Behavioral;
