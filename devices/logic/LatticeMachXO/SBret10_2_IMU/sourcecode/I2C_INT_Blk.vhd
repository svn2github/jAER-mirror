------------------------------------------------------------------------------
-- 
--  Name:  I2C_INT_Blk.vhd
-- 
--  Description:  Initalize Interupt and ACK signals
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

entity Int_Ctrl_Block is
  port(MPU_CLK             : in std_logic;                        -- MPU clock
       RST_L               : in std_logic;                        -- Global reset
       abort               : in std_logic;                        -- abort 
       Trans_IE            : in std_logic;                        -- Transmit interrupt enable from MPU
       Recieve_IE          : in std_logic;                        -- Recieve interrupt enable from MPU
       I2C_RW              : in std_logic;                        -- I2C Read/Write register
       Trans_Buffer_Empty  : in std_logic;                        -- Interrupt enable from I2C SM
       Recieve_Buffer_Full : in std_logic;
       Iack                : in std_logic;
       Iack_Clear          : out std_logic;
       INTR_L              : out std_logic);                     -- Interrupt Request to MPU
end Int_Ctrl_Block;

architecture Int_Behave of Int_Ctrl_Block is
signal tbe_en : std_logic;
signal rbf_en : std_logic;
signal reset  : std_logic;
begin
  tbe_en <= Trans_IE  and Trans_Buffer_Empty  and not(I2C_RW);
  rbf_en <= Recieve_IE and Recieve_Buffer_Full and I2C_RW;
  reset <= '0' when RST_L = '0' or abort = '1' else '1';
  
  process(MPU_CLK,Reset,tbe_en,rbf_en,Iack)
  begin
    if(Reset = '0') then
      INTR_L     <= '1';
      Iack_Clear <= '0';  
    elsif(rising_edge(MPU_CLK)) then
      if(tbe_en = '1') then
        Iack_Clear <= '0';
        INTR_L <= '0';
      elsif(rbf_en = '1') then
        Iack_Clear <= '0';
        INTR_L <= '0';
      elsif(Iack = '1') then
        INTR_L <= '1';
        Iack_Clear <= '1';
      end if;  
    end if;  
  end process;     
end Int_Behave;

--------------------------------- E O F --------------------------------------
