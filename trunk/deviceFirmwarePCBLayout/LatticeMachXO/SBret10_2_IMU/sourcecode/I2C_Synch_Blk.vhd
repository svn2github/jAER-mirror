------------------------------------------------------------------------------
-- 
--  Name:  I2C_Synch_Blk.vhd 
-- 
--  Description: Synchronization block synchronizes the SDA and the SDL signals
--              with the system clock and protects against metastability
-- 
--  $Revision: 1.0 $          
--  
--  Copyright 2002 Lattice Semiconductor Corporation.  All rights reserved.
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
-----------------------------------------------------------------------
-- Revision History :
-----------------------------------------------------------------------
-- Ver  | Author    | Mod. Date | Changes Made:
-----------------------------------------------------------------------
-- 0.1  | tmk       | 04/21/99  | birth
-----------------------------------------------------------------------
-- 0.2  | tmk       | 07/27/99  | removed high speed stuff
--                                added sda synch                                   
----------------------------------------------------------------------- 
-- 0.3  | tmk       | 08/6/99   | added extra registers to guard
--                                against metastability
----------------------------------------------------------------------- 


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity Synch_Block is
  port(MPU_CLK     : in std_logic;
       Rst_L       : in std_logic;                       
       SCL         : in bit;
       SDA         : in bit;
       SCL_synch   : out bit;
       SDA_synch   : out bit);
end Synch_Block;

architecture Synch_Behave of Synch_Block is
signal t1 :bit;
signal t2 :bit;

begin
 

 -- Synchronize scl and sda
 Sync: process(MPU_CLK, Rst_L, SCL, SDA) 
 begin                      
   if(Rst_L= '0') then
     t1 <= '0';
     t2 <= '0';
     SCL_synch  <= '0';
     SDA_synch <= '0';   
   elsif(rising_edge(MPU_CLK)) then 
     t1 <= SCL;
     t2 <= SDA;
     SCL_synch  <= t1;
     SDA_synch  <= t2;
   end if;
 end process;

end Synch_Behave;

--------------------------------- E O F --------------------------------------
