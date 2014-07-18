--------------------------------------------------------------------------------
--
--	 FileName:		   i2c_master.vhd
--	 Dependencies:	   none
--	 Design Software:  Quartus II 32-bit Version 11.1 Build 173 SJ Full Version
--
--	 HDL CODE IS PROVIDED "AS IS."	DIGI-KEY EXPRESSLY DISCLAIMS ANY
--	 WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--	 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--	 PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--	 BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--	 DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--	 PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--	 BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--	 ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--	 Version History
--	 Version 1.0 11/1/2012 Scott Larson
--	   Initial Public Release
--	 Version 1.1 15/06/2014 Luca Longinotti
--	   Changed active-low reset_n to active-high reset for modern FPGAs.
--	   Changed clk'EVENT to rising/falling_edge() functions.
--	   Ran Emacs VHDL-mode beautifier over the whole code.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity i2c_master is
	generic(
		input_clk : integer := 50_000_000; --input clock speed from user logic in Hz
		bus_clk   : integer := 400_000); --speed the i2c bus (scl) will run at in Hz
	port(
		clk       : in    std_logic;    --system clock
		reset     : in    std_logic;    --active high reset
		ena       : in    std_logic;    --latch in command
		addr      : in    std_logic_vector(6 downto 0); --address of target slave
		rw        : in    std_logic;    --'0' is write, '1' is read
		data_wr   : in    std_logic_vector(7 downto 0); --data to write to slave
		busy      : out   std_logic;    --indicates transaction in progress
		data_rd   : out   std_logic_vector(7 downto 0); --data read from slave
		ack_error : buffer std_logic;   --flag if improper acknowledge from slave
		sda       : inout std_logic;    --serial data output of i2c bus
		scl       : inout std_logic);   --serial clock output of i2c bus
end i2c_master;

architecture logic of i2c_master is
	constant divider : integer := (input_clk / bus_clk) / 4; --number of clocks in 1/4 cycle of scl
	type machine is (ready, start, command, slv_ack1, wr, rd, slv_ack2, mstr_ack, stop); --needed states
	signal state     : machine;         --state machine
	signal data_clk  : std_logic;       --clock edges for sda
	signal scl_clk   : std_logic;       --constantly running internal scl
	signal scl_ena   : std_logic            := '0'; --enables internal scl to output
	signal sda_int   : std_logic            := '1'; --internal sda
	signal sda_ena_n : std_logic;       --enables internal sda to output
	signal addr_rw   : std_logic_vector(7 downto 0); --latched in address and read/write
	signal data_tx   : std_logic_vector(7 downto 0); --latched in data to write to slave
	signal data_rx   : std_logic_vector(7 downto 0); --data received from slave
	signal bit_cnt   : integer range 0 to 7 := 7; --tracks bit number in transaction
	signal stretch   : std_logic            := '0'; --identifies if slave is stretching scl
begin
	--generate the timing for the bus clock (scl_clk) and the data clock (data_clk)
	process(clk, reset)
		variable count : integer range 0 to divider * 4; --timing for clock generation
	begin
		if (reset = '1') then           --reset asserted
			stretch <= '0';
			count   := 0;
		elsif (rising_edge(clk)) then
			if (count = divider * 4 - 1) then --end of timing cycle
				count := 0;             --reset timer
			elsif (stretch = '0') then  --clock stretching from slave not detected
				count := count + 1;     --continue clock generation timing
			end if;
			case count is
				when 0 to divider - 1 => --first 1/4 cycle of clocking
					scl_clk  <= '0';
					data_clk <= '0';
				when divider to divider * 2 - 1 => --second 1/4 cycle of clocking
					scl_clk  <= '0';
					data_clk <= '1';
				when divider * 2 to divider * 3 - 1 => --third 1/4 cycle of clocking
					scl_clk <= 'Z';     --release scl
					if (scl = '0') then --detect if slave is stretching clock
						stretch <= '1';
					else
						stretch <= '0';
					end if;
					data_clk <= '1';
				when others =>          --last 1/4 cycle of clocking
					scl_clk  <= 'Z';
					data_clk <= '0';
			end case;
		end if;
	end process;

	--state machine and writing to sda during scl low (data_clk rising edge)
	process(data_clk, reset)
	begin
		if (reset = '1') then           --reset asserted
			state   <= ready;           --return to initial state
			busy    <= '1';             --indicate not available
			scl_ena <= '0';             --sets scl high impedance
			sda_int <= '1';             --sets sda high impedance
			bit_cnt <= 7;               --restarts data bit counter
			data_rd <= "00000000";      --clear data read port
		elsif (rising_edge(data_clk)) then
			case state is
				when ready =>           --idle state
					if (ena = '1') then --transaction requested
						busy    <= '1'; --flag busy
						addr_rw <= addr & rw; --collect requested slave address and command
						data_tx <= data_wr; --collect requested data to write
						state   <= start; --go to start bit
					else                --remain idle
						busy  <= '0';   --unflag busy
						state <= ready; --remain idle
					end if;
				when start =>           --start bit of transaction
					busy    <= '1';     --resume busy if continuous mode
					scl_ena <= '1';     --enable scl output
					sda_int <= addr_rw(bit_cnt); --set first address bit to bus
					state   <= command; --go to command
				when command =>         --address and command byte of transaction
					if (bit_cnt = 0) then --command transmit finished
						sda_int <= '1'; --release sda for slave acknowledge
						bit_cnt <= 7;   --reset bit counter for "byte" states
						state   <= slv_ack1; --go to slave acknowledge (command)
					else                --next clock cycle of command state
						bit_cnt <= bit_cnt - 1; --keep track of transaction bits
						sda_int <= addr_rw(bit_cnt - 1); --write address/command bit to bus
						state   <= command; --continue with command
					end if;
				when slv_ack1 =>        --slave acknowledge bit (command)
					if (addr_rw(0) = '0') then --write command
						sda_int <= data_tx(bit_cnt); --write first bit of data
						state   <= wr;  --go to write byte
					else                --read command
						sda_int <= '1'; --release sda from incoming data
						state   <= rd;  --go to read byte
					end if;
				when wr =>              --write byte of transaction
					busy <= '1';        --resume busy if continuous mode
					if (bit_cnt = 0) then --write byte transmit finished
						sda_int <= '1'; --release sda for slave acknowledge
						bit_cnt <= 7;   --reset bit counter for "byte" states
						state   <= slv_ack2; --go to slave acknowledge (write)
					else                --next clock cycle of write state
						bit_cnt <= bit_cnt - 1; --keep track of transaction bits
						sda_int <= data_tx(bit_cnt - 1); --write next bit to bus
						state   <= wr;  --continue writing
					end if;
				when rd =>              --read byte of transaction
					busy <= '1';        --resume busy if continuous mode
					if (bit_cnt = 0) then --read byte receive finished
						if (ena = '1' and rw = '1') then --continuing with another read
							sda_int <= '0'; --acknowledge the byte has been received
						else            --stopping or continuing with a write
							sda_int <= '1'; --send a no-acknowledge (before stop or repeated start)
						end if;
						bit_cnt <= 7;   --reset bit counter for "byte" states
						data_rd <= data_rx; --output received data
						state   <= mstr_ack; --go to master acknowledge
					else                --next clock cycle of read state
						bit_cnt <= bit_cnt - 1; --keep track of transaction bits
						state   <= rd;  --continue reading
					end if;
				when slv_ack2 =>        --slave acknowledge bit (write)
					if (ena = '1') then --continue transaction
						busy    <= '0'; --continue is accepted
						addr_rw <= addr & rw; --collect requested slave address and command
						data_tx <= data_wr; --collect requested data to write
						if (rw = '1') then --continue transaction with a read
							state <= start; --go to repeated start
						else            --continue transaction with another write
							sda_int <= data_wr(bit_cnt); --write first bit of data
							state   <= wr; --go to write byte
						end if;
					else                --complete transaction
						scl_ena <= '0'; --disable scl
						state   <= stop; --go to stop bit
					end if;
				when mstr_ack =>        --master acknowledge bit after a read
					if (ena = '1') then --continue transaction
						busy    <= '0'; --continue is accepted and data received is available on bus
						addr_rw <= addr & rw; --collect requested slave address and command
						data_tx <= data_wr; --collect requested data to write
						if (rw = '0') then --continue transaction with a write
							state <= start; --repeated start
						else            --continue transaction with another read
							sda_int <= '1'; --release sda from incoming data
							state   <= rd; --go to read byte
						end if;
					else                --complete transaction
						scl_ena <= '0'; --disable scl
						state   <= stop; --go to stop bit
					end if;
				when stop =>            --stop bit of transaction
					busy  <= '0';       --unflag busy
					state <= ready;     --go to ready state
			end case;
		end if;

		--reading from sda during scl high (falling edge of data_clk)
		if (reset = '1') then           --reset asserted
			ack_error <= '0';
		elsif (falling_edge(data_clk)) then
			case state is
				when start =>           --starting new transaction
					ack_error <= '0';   --reset acknowledge error flag
				when slv_ack1 =>        --receiving slave acknowledge (command)
					ack_error <= sda or ack_error; --set error output if no-acknowledge
				when rd =>              --receiving slave data
					data_rx(bit_cnt) <= sda; --receive current slave data bit
				when slv_ack2 =>        --receiving slave acknowledge (write)
					ack_error <= sda or ack_error; --set error output if no-acknowledge
				when others =>
					null;
			end case;
		end if;

	end process;

	--set sda output
	with state select sda_ena_n <=
		data_clk when start,            --generate start condition
		not data_clk when stop,         --generate stop condition
		sda_int when others;            --set to internal sda signal

	--set scl and sda outputs
	scl <= scl_clk when scl_ena = '1' else 'Z';
	sda <= '0' when sda_ena_n = '0' else 'Z';
end logic;
