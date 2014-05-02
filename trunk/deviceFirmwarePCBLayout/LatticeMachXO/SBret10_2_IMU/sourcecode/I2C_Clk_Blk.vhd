------------------------------------------------------------------------------
-- 
--  Name:   I2C_Clk_Blk.vhd
-- 
--  Description: Generate SCL clock line for the I2C bus
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
-------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity I2C_Clock_Generator is
  generic (cnt_f_hi: integer := 105;  -- = clk80_f_hi;     fast   count hi time
           cnt_s_hi: integer := 417;  -- = clk80_s_hi;     std.   count hi time
           cnt_f_lo: integer := 209;  -- = clk80_f_lo;     fast   count lo time
           cnt_s_lo: integer := 834); -- = clk80_s_lo;     std.   count lo time
  port(MPU_CLK    : in std_logic;                       -- MP Clock 
       Rst_L      : in std_logic;                       -- Main Reset, active low
       Mode       : in std_logic;                       -- I2C mode from command register
       Abort      : in std_logic;                       -- abort from command register
       SCL_CK     : out std_logic);                     -- Serial Clock Line of the I2C bus

end I2C_Clock_Generator;

architecture Clk_Gen_Behave of I2C_Clock_Generator is
signal count : integer range 0 to 834;
signal reset : std_logic;
begin

 reset <= '0' when RST_L = '0' or Abort = '1' else '1';
 
 counter:process(MPU_CLK,Reset,Mode)
 begin
  if(Reset = '0') then
   count <= 0;
  elsif (rising_edge(MPU_CLK)) then    
    if ((Mode = '0') and (count = cnt_s_lo)) then     --     std roll over
        count <= 0;
    elsif ((Mode = '1') and (count = cnt_f_lo)) then  --     fast roll over
        count <= 0;
    else                                              --     count
        count <= count + 1;
    end if;
  end if;
 end process;
     
 std_fast:process(MPU_CLK,Reset,count,Mode)
 begin
  if(Reset = '0') then
   SCL_CK  <= '0';
  elsif (rising_edge(MPU_CLK)) then    
    if((Mode = '1') and (count = cnt_f_lo)) then
        SCL_CK <= '1';
    elsif((Mode = '0') and (count = cnt_s_lo)) then
        SCL_CK <= '1';
    elsif((Mode = '1') and (count = cnt_f_hi)) then
        SCL_CK <= '0';
    elsif((Mode = '0') and (count = cnt_s_hi)) then
        SCL_CK <= '0';    
    end if;
  end if;  
 end process;
end Clk_Gen_Behave;
       
--------------------------------- E O F --------------------------------------
