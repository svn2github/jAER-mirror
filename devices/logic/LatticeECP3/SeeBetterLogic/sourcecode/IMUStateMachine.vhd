library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.all;

entity IMUStateMachine is
	port (
		Clock_CI  : in std_logic;
		Reset_RI  : in std_logic;
		IMURun_SI : in std_logic;

		-- Fifo output (to Multiplexer)
		OutFifoFull_SI		 : in  std_logic;
		OutFifoAlmostFull_SI : in  std_logic;
		OutFifoWrite_SO		 : out std_logic;
		OutFifoData_DO		 : out std_logic_vector(EVENT_WIDTH-1 downto 0);

		IMUClock_ZO		: inout std_logic;	-- this is inout because it must be tristateable
		IMUData_ZIO		: inout std_logic;
		IMUInterrupt_SI : in	std_logic);
end entity IMUStateMachine;

architecture Behavioral of IMUStateMachine is
	-- I2C Master module from eewiki.
	component i2c_master is
		generic (
			input_clk : integer := 50_000_000;
			bus_clk	  : integer := 400_000);
		port (
			clk		  : in	   std_logic;
			reset	  : in	   std_logic;
			ena		  : in	   std_logic;
			addr	  : in	   std_logic_vector(6 downto 0);
			rw		  : in	   std_logic;
			data_wr	  : in	   std_logic_vector(7 downto 0);
			busy	  : out	   std_logic;
			data_rd	  : out	   std_logic_vector(7 downto 0);
			ack_error : buffer std_logic;
			sda		  : inout  std_logic;
			scl		  : inout  std_logic);
	end component i2c_master;

	type state is (stIdle, stWriteEvent);

	attribute syn_enum_encoding			 : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;
begin
	i2cMasterForIMU : i2c_master
		generic map (
			input_clk => LOGIC_CLOCK_FREQ * 1_000_000,
			bus_clk	  => 400_000)
		port map (
			clk		  => Clock_CI,
			reset	  => Reset_RI,
			ena		  => '0',
			addr	  => "0000000",
			rw		  => '0',
			data_wr	  => "00000000",
			busy	  => open,
			data_rd	  => open,
			ack_error => open,
			sda		  => IMUData_ZIO,
			scl		  => IMUClock_ZO);


	p_memoryless : process (State_DP, IMURun_SI, OutFifoFull_SI)
	begin
		State_DN <= State_DP;			-- Keep current state by default.

		OutFifoWrite_SO <= '0';
		OutFifoData_DO	<= (others => '0');

		case State_DP is
			when stIdle =>
				-- Only exit idle state if IMU data producer is active.
				if IMURun_SI = '1' then
					if OutFifoFull_SI = '0' then
						-- If output fifo full, just wait for it to be empty.
						State_DN <= stWriteEvent;
					end if;
				end if;

			when stWriteEvent =>
				OutFifoData_DO	<= (others => '0');
				OutFifoWrite_SO <= '1';
				State_DN		<= stIdle;

			when others => null;
		end case;
	end process p_memoryless;

	-- Change state on clock edge (synchronous).
	p_memoryzing : process (Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then	-- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;
		end if;
	end process p_memoryzing;
end architecture Behavioral;
