------------------------------------------------------------------------------
-- 
--  Name:  I2C_Arb_Blk.vhd  
-- 
--  Description: Perform arbitration for multiple masters on the I2C bus
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

entity Arbitrator is
  port(MPU_CLK       : in std_logic;                    -- MPU Clock
       Rst_L         : in std_logic;                    -- Main I2C Reset
       SCL           : in bit;                          -- I2C Clock for f/s mode 
       SDA           : in bit;                          -- I2C data bus for f/s mode
       SDA_EN1       : in std_logic;                    -- sda enable
       SDA_EN2       : in std_logic;                    -- sda enable
       SDA_EN3       : in std_logic;                    -- sda enable
       WCS_Ack       : in std_logic;                    -- Write State Ack Bit
       RCS_Ack       : in std_logic;                    -- Read State Ack Bit
       Lost_ARB      : out std_logic);                  -- Lost Arbitration bit
end Arbitrator;

architecture Arch_Behave of Arbitrator is
signal   Current_State : std_logic_vector(1 downto 0);
signal   Next_State    : std_logic_vector(1 downto 0);
constant Idle          : std_logic_vector(1 downto 0)  := "00";
constant State_1       : std_logic_vector(1 downto 0)  := "01";
constant State_2       : std_logic_vector(1 downto 0)  := "10";
constant State_3       : std_logic_vector(1 downto 0)  := "11";

begin

   
 I2C_Arb_States: process(MPU_CLK,Rst_L)
 begin
    if(Rst_L= '0')then
      Current_State <= Idle;
    elsif(MPU_CLK'event and MPU_CLK = '1') then
      Current_State <= Next_State;
    end if;
 end process;

 I2C_Arb_Register: process(MPU_CLK, Rst_L, Current_State, SDA, 
                           SDA_EN1, SDA_EN2, SDA_EN3,WCS_Ack)
 begin
   if(Rst_L= '0') then
     Lost_ARB <= '0';
   elsif(MPU_CLK'event and MPU_CLK = '1') then 
     if(Current_State = State_2) then
       if(((SDA_EN1 = '0') and (SDA_EN2 = '0') and (SDA_EN3 = '0')) and SDA = '0' 
         and (WCS_Ack = '1' or RCS_Ack = '1')) then
           Lost_ARB <= '1';
       elsif(((SDA_EN1 = '1') or (SDA_EN2 = '1') or (SDA_EN3 = '1')) and SDA = '1'
         and (WCS_Ack = '1' or RCS_Ack = '1')) then
           Lost_ARB <= '1';
       else
         Lost_ARB <= '0';
       end if;  
     end if;
   end if;
 end process;     

 I2C_Arb_Logic: process(Current_State,SCL)
 begin
   case Current_State is
    when Idle =>
      if(SCL = '1') then -- Check mode, and allow arb only during high clock
        Next_State <= State_1;
      else
        Next_State <= Idle;  
      end if;  
    when State_1 =>
      Next_State <= State_2;
    when State_2 =>  
      Next_State <= State_3;
    when State_3 =>
     if(SCL = '0') then 
        Next_State <= Idle;
      else
        Next_State <= State_3; -- Wait for the appropriate SCL clock to go low again. 
      end if;                  -- We only want to check arbitration once during the SCL clock high  
    when others =>
      Next_State <= Idle;      
   end case;
 end process;    

end Arch_Behave;

--------------------------------- E O F --------------------------------------
