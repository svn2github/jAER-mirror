------------------------------------------------------------------------------
-- 
--  Name: I2C_Cnt_Blk.vhd  
-- 
--  Description: Bit and Byte counters to keep track of the transactions on 
--              the I2C bus
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
use ieee.std_logic_unsigned."-";
use ieee.std_logic_unsigned."+";

entity Counter_Block is
  port(MPU_CLK        : in std_logic;                     -- MP Clock 
       Rst_L          : in std_logic;                     -- Main Reset, active low
       SCL            : in bit;                           -- SCL
       Abort          : in std_logic;                     -- Abort
       Byte_Cnt_EN    : in std_logic;                     -- Byte Count Enable
       Bit_Cnt_EN     : in std_logic;                     -- Bit Count Enable
       go             : in std_logic;                     -- go bit for restarts
       Byte_Count_Reg : in std_logic_vector(7 downto 0);  -- Byte Count Register setup from MPU
       Bit_Count      : out std_logic_vector(2 downto 0);  -- Bit Count 
       Bit_Cnt_Flag   : out std_logic;                     -- Bit Count overflow flag
       Byte_Cnt_Flag  : out std_logic);                    -- Byte Count overflow flag
end Counter_Block;

architecture Count_Behave of Counter_Block is
signal Bit_Counter  : std_logic_vector(2 downto 0);
signal Byte_Counter : std_logic_vector(7 downto 0);
signal Current_Bit_State             : std_logic;--_vector(1 downto 0);
signal Next_Bit_State                : std_logic;--_vector(1 downto 0);
constant Idle_Bit_State              : std_logic := '0';
constant Count_Bit_State             : std_logic := '1';
signal Current_Byte_State            : std_logic;
signal Next_Byte_State               : std_logic;
constant Idle_Byte_State             : std_logic := '0';
constant Count_Byte_State            : std_logic := '1';
signal reset                         : std_logic;

signal Byte_Cmpr                     : std_logic;

begin
Bit_Count  <= Bit_Counter;

reset <= '0' when RST_L ='0' or Abort = '1' or go = '1' else '1';

 Bit_Count_States: process(MPU_CLK,reset)
  begin
   if(reset= '0')then
     Current_Bit_State <= Idle_Bit_State;
   elsif(MPU_CLK'event and MPU_CLK = '1') then
     Current_Bit_State <= Next_Bit_State;
   end if;
  end process;

 Bit_Countp: process(MPU_CLK,reset,Current_Bit_State,SCL,Bit_Cnt_EN)
  begin
   if(reset= '0')then
     Bit_Counter               <= "000";
     Bit_Cnt_Flag              <= '0';
   elsif(rising_edge(MPU_CLK)) then
     if(Current_Bit_State = Idle_Bit_State) then
       if(SCL = '1') then
         if(Bit_Cnt_EN = '1') then
           Bit_Counter <= Bit_Counter + '1';
         end if;
       end if;
     end if;   
     if(Bit_Counter = "111") then
       Bit_Cnt_Flag <= '1';
     else
       Bit_Cnt_Flag <= '0';
     end if;
   end if;
  end process;   
      
 Bit_Count_State_Machine: process(Current_Bit_State, SCL, Bit_Cnt_EN)
  begin
   case Current_Bit_State is
     when Idle_Bit_State =>
       if(SCL = '1' ) then
         if(Bit_Cnt_EN = '1') then
           Next_Bit_State <= Count_Bit_State;
         else
           Next_Bit_State <= Idle_Bit_State; 
         end if;
       else
         Next_Bit_State <= Idle_Bit_State; 
       end if;
 
     when Count_Bit_State =>
       if(SCL = '0') then
         Next_Bit_State <= Idle_Bit_State;            
       else
         Next_Bit_State <= Count_Bit_State;   
       end if;
 
     when others =>
       Next_Bit_State <= Idle_Bit_State;
     end case;
 end process;
 
--Byte Counter stuff         
 Byte_Count_States: process(MPU_CLK,reset)
  begin
   if(reset= '0')then
     Current_Byte_State <= Idle_Byte_State;
   elsif(rising_edge(MPU_CLK)) then
     Current_Byte_State <= Next_Byte_State;
   end if;
  end process;

 Byte_Countp: process(MPU_CLK,reset,Current_Byte_State,SCL,Byte_Cnt_EN, Byte_Cmpr)
  begin
   if(reset= '0')then
     Byte_Counter               <= "00000000";
     Byte_Cnt_Flag              <= '0';
   elsif(rising_edge(MPU_CLK)) then
     if(Current_Byte_State = Idle_Byte_State) then
       if(SCL = '1') then
         if(Byte_Cnt_EN = '1') then
           if(Byte_Cmpr = '0') then
             Byte_Counter <= Byte_Counter + '1'; 
           else
             Byte_Counter <= "00000000";  
           end if; 
         end if;
       end if;
       if(Byte_Cmpr = '1') then
          Byte_Cnt_Flag <= '1';
       else
          Byte_Cnt_Flag <= '0';
       end if; 
     end if;
   end if;
  end process;   
 
 Byte_Comparitor:process(MPU_CLK,reset,Byte_Counter,Byte_Count_Reg)
 begin
   if(reset = '0') then
    Byte_Cmpr <= '0';
   elsif(rising_edge(MPU_CLK)) then
     if(Byte_Counter = Byte_Count_Reg) then
       Byte_Cmpr <= '1';
     else
       Byte_Cmpr <= '0';
     end if;
   end if;  
 end process;      

 Byte_Count_State_Machine: process(Current_Byte_State, SCL, Byte_Cnt_EN)
  begin
   case Current_Byte_State is
     when Idle_Byte_State =>
       if(SCL = '1') then
         if(Byte_Cnt_EN = '1') then
           Next_Byte_State <= Count_Byte_State;
         else
           Next_Byte_State <= Idle_Byte_State; 
         end if;
       else
         Next_Byte_State <= Idle_Byte_State; 
       end if;
       
     when Count_Byte_State =>
       if(SCL = '0') then
         Next_Byte_State <= Idle_Byte_State;            
       else
         Next_Byte_State <= Count_Byte_State;   
       end if;
       
     when others =>
       Next_Byte_State <= Idle_Byte_State;
     end case;
 end process;
     
end Count_Behave;

--------------------------------- E O F --------------------------------------
