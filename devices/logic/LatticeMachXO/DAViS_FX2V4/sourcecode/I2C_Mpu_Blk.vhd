------------------------------------------------------------------------------
-- 
--  Name:  I2C_Mpu_Blk.vhd
-- 
--  Description:  Interface between the microprocessor and the I2C Master
--              Controller
-- 
--  $Revision: 1.0 $     
--  
--  Copyright 2004 Lattice Semiconductor Corporation.  All rights reserved.
--
------------------------------------------------------------------------------
-- Permission:
--
--   Lattice Semiconductor grants permission to use this code for use
--   in synthesis for any Lattice programmable logic product.  Other
--   use of this code, including the selling or duplication of any
--   portion is strictly prohibited.
--
-- Disclaimer:
--
--   This VHDL or Verilog source code is intended as a design reference
--   which illustrates how these types of functions can be implemented.
--   It is the user's responsibility to verify their design for
--   consistency and functionality through the use of formal
--   verification methods.  Lattice Semiconductor provides no warranty
--   regarding the use or functionality of this code.
------------------------------------------------------------------------------
--
--    Lattice Semiconductor Corporation
--    5555 NE Moore Court
--    Hillsboro, OR 97124
--    U.S.A
--
--    TEL: 1-800-Lattice (USA and Canada)
--    408-826-6000 (other locations)
--
--    web: http://www.latticesemi.com/
--    email: techsupport@latticesemi.com
-- 
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity MPU_to_I2C is
  port(MPU_CLK            : in std_logic;                       -- Main Clock
       Rst_L              : in std_logic;                       -- Main Reset, active low
       CS_L               : in std_logic;                       -- Chip select, active low
       Addr_Bits          : in std_logic_vector(2 downto 0);    -- Address bits A0, A1, A2. Used for register sel
       RW_L               : in std_logic;                       -- Read/Write, write active low
       Read_Buffer        : in std_logic_vector(7 downto 0);    -- I2C Data Read in
       Status_Reg         : in std_logic_vector(4 downto 0);    -- Status part of Command_Status Reg Contains:
                                                                -- I2C_Bus_Busy, Abort_Ack, Lost_Arb, Error,Done
                                                                -- Does not include: Trans_Buf_Empty,
                                                                -- and Recieve_Buf_Full
       TBE_Set            : in std_logic;                       -- TBE_Set flag, set Trans_Buf_Empty to empty                                                                   
       RBF_Set            : in std_logic;                       -- RBF_Set flag, set Read_Buff_Full  to full                                                                    
       Iack_Clear         : in std_logic;                       -- Clears the Iack
       Go_Clear           : in std_logic;                       -- Clears Go Bit
       Low_Address_Reg    : out std_logic_vector(7 downto 0);   -- Low order Address bits for I2C Slave
       Upper_Address_Reg  : out std_logic_vector(2 downto 0);   -- High order Address bits for I2C Slave
       Byte_Count_Reg     : out std_logic_vector(7 downto 0);   -- I2C Transaction Byte Count
       Command_Reg        : out std_logic_vector(7 downto 0);   -- CMD part of Command_Status Reg Contains:
                                                                -- Go, Abort,Iack, I2C_Mode,
                                                                -- I2C_address Size, Trans_IE and Recieve_IE. 
       Trans_Buffer       : out std_logic_vector(7 downto 0);    -- Holds Data for I2C Write transaction
       Trans_Buffer_Empty : out std_logic;                      -- 0 indicates that the trans buffer is empty
       Read_Buffer_Full   : out std_logic;                      -- 0 indicates that the read buffer is not full
       Iack               : out std_logic;                      -- interrupt acknowledge
       DATA               : inout std_logic_vector(7 downto 0)); -- Data bus to/from attached device(NOTE: Data(7) is MSB                         
end MPU_to_I2C;

architecture MPU_to_I2C_Behave of MPU_to_I2C is
signal tbe            : std_logic;
signal rbf            : std_logic;
signal mcr            : std_logic_vector(2 downto 0);
signal write_pulse    : std_logic;
signal ns             : std_logic_vector(1 downto 0);
--internal registers necessary for feedback
signal transb         : std_logic_vector(7 downto 0);
signal laddr          : std_logic_vector(7 downto 0);
signal upaddr         : std_logic_vector(2 downto 0);
signal bcnt           : std_logic_vector(7 downto 0);
signal cmd            : std_logic_vector(7 downto 0);

constant write        : std_logic_vector(2 downto 0) := "000";
constant low_addr     : std_logic_vector(2 downto 0) := "001";
constant up_addr      : std_logic_vector(2 downto 0) := "010";
constant command      : std_logic_vector(2 downto 0) := "100";
constant byte_cnt     : std_logic_vector(2 downto 0) := "101";
constant iack_st      : std_logic_vector(2 downto 0) := "110";
signal count1          : std_logic_vector(3 downto 0) := "0000";
signal count2         : std_logic_vector(3 downto 0) := "0000";
signal temp_data      : std_logic_vector(7 downto 0);

begin

Trans_Buffer_Empty <= tbe;
Read_Buffer_Full   <= rbf;
DATA <= temp_data when CS_L = '0' and RW_L = '1' else "ZZZZZZZZ";  
Trans_Buffer      <= transb;
Low_Address_Reg   <= laddr;
Upper_Address_Reg <= upaddr;
Command_Reg       <= cmd;
Byte_Count_Reg    <= bcnt;

 tdata :process(Addr_Bits(2),Status_Reg,Read_Buffer,tbe,rbf)
 begin
 if(Addr_Bits(2) = '1') then
  temp_data <= Status_Reg & "0" & tbe & rbf;
 elsif(Addr_Bits(2) = '0') then
  temp_data <= Read_Buffer;
 end if;
 end process;


 MPU :process(MPU_CLK, RST_L, Addr_Bits, DATA, write_pulse,go_clear)
 begin
   if(Rst_L= '0')then
       upaddr     <= "000";
       transb     <= "00000000";
       laddr      <= "00000000";
       cmd        <= "00000000";
       bcnt       <= "00000000";

   elsif(rising_edge(MPU_CLK)) then
     if(write_pulse = '1') then  
       case Addr_Bits is
         when write =>
           transb <= Data;  
         when low_addr =>
           laddr  <= Data;
         when up_addr =>
           upaddr <= Data(2 downto 0);
         when command =>
           cmd    <= Data;
         when byte_cnt =>
           bcnt   <= Data;
         when iack_st =>
           transb <= transb;
           laddr  <= laddr;
           upaddr <= upaddr;
           cmd    <= cmd;
           bcnt   <= bcnt; 
         when others =>
           transb <= transb;
           laddr  <= laddr;
           upaddr <= upaddr;
           cmd    <= cmd;
           bcnt   <= bcnt; 
       end case;  

     elsif(go_clear = '1') then
       cmd(7) <= '0';
     end if;
   end if;  
 end process;  
 
 pulse_write:process(MPU_CLK,RST_L, CS_L, RW_L)

 constant idle  : std_logic_vector(1 downto 0) := "00";
 constant one   : std_logic_vector(1 downto 0) := "01";
 constant two   : std_logic_vector(1 downto 0) := "10"; 
 begin
   if(RST_L = '0') then
     write_pulse <= '0';
     ns          <=  idle;
   elsif(rising_edge(MPU_CLK)) then
     case ns is
       when idle =>
         write_pulse <= '0';
         if(RW_L = '0' and CS_L = '0') then
           ns <= one;
         else
           ns <= idle;      
         end if;
       when one =>
         write_pulse <= '1';
         if(RW_L = '0' and CS_L = '0') then
           ns <= two;
         else
           ns <= idle;
         end if;
       when two =>
         write_pulse <= '0';
         if(CS_L = '1') then
           ns <= idle;
         else
           ns <= two;
         end if;
       when others =>
         write_pulse <= '0';
         ns <= idle;
     end case;
   end if; 
 end process;     

 iack_set: process(Rst_L, MPU_CLK, Iack_Clear)
 begin
  if(Rst_L= '0')then
     Iack    <= '0';
  elsif(rising_edge(MPU_CLK)) then
     if(CS_L = '0' and RW_L = '0' and Addr_Bits = "110") then
       Iack  <= '1';--Data(0);
     elsif(Iack_Clear = '1') then
       Iack  <= '0';
     end if;   
  end if;
 end process;    

 trans_buf_empty: process(MPU_CLK, Rst_L, TBE_Set)
 begin
  if(Rst_L= '0')then
    tbe <= '0';
  elsif(rising_edge(MPU_CLK)) then
    if(CS_L = '0' and RW_L = '0' and Addr_Bits = "000") then
      tbe <= '0'; -- trans buffer has been written to and is now full
    elsif(TBE_Set = '1') then
      tbe <= '1'; -- trans buffer is empty
    end if;
  end if;   
 end process;

 read_buf_full: process(MPU_CLK, Rst_L, RBF_Set)--, CS_L, RW_L, Addr_Bits,SCL_EN2,SCLH_EN2)
 begin
  if(Rst_L= '0')then
    rbf <= '0'; 
  elsif(rising_edge(MPU_CLK)) then
    if(CS_L = '0' and RW_L = '1' and Addr_Bits = "000") then
      rbf <= '0';  -- read buffer has been read and is now empty
    elsif(RBF_Set = '1') then
      rbf <= '1'; -- read buffer is full
    end if;
  end if;   
 end process;

end MPU_to_I2C_Behave;

--------------------------------- E O F --------------------------------------
