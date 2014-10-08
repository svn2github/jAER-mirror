------------------------------------------------------------------------------
-- 
--  Name:  I2C_delay.vhd
-- 
--  Description: Generate a 4-clock-cycle delay for the SDA enable signal
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

entity Delay_SDA is
  port(MPU_CLK     : in std_logic;
       Rst_L       : in std_logic;                       
       SDA_EN      : in std_logic;
       SDA_EN_Out  : out std_logic);
end Delay_SDA;

architecture Delay_Behave of Delay_SDA is
signal t1 : std_logic;
signal t2 : std_logic;
signal t3 : std_logic;
begin
 
 delay: process(MPU_CLK, Rst_L, SDA_EN) 
 begin                      
   if(Rst_L= '0') then
       SDA_EN_out  <= '0';
   elsif(rising_edge(MPU_CLK)) then 
     t1 <= SDA_EN;
     t2 <= t1;
     t3 <= t2;
     SDA_EN_Out <= t3;
   end if;
 end process;

end Delay_Behave;

--------------------------------- E O F --------------------------------------
