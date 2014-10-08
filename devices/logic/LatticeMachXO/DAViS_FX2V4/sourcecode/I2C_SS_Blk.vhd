------------------------------------------------------------------------------
-- 
--  Name:  I2C_SS_Blk.vhd  
-- 
--  Description: Start and Stop control block generates and detects the start
--              and stop events on the I2C bus
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

entity Start_Generator is
  port(MPU_CLK       : in std_logic;                    -- MPU Clock
       Rst_L         : in std_logic;                    -- Main Reset
       Start_Enable  : in std_logic;                    -- Start Enable, activates start gen process
       SCL           : in bit;                          -- I2C Clock for f/s mode 
       SDA           : in bit;                          -- I2C data bus for f/s mode        
       SDA_EN2       : out std_logic);                  -- sda enable

end Start_Generator;

architecture Start_Behave of Start_Generator is
-- State Signals for Start Generation State Machine
signal Current_Start_Gen_State    : std_logic_vector(1 downto 0);
signal Next_Start_Gen_State       : std_logic_vector(1 downto 0);
constant Idle_Start_Gen_State     : std_logic_vector(1 downto 0)  := "00";
constant Start_Gen_State_1        : std_logic_vector(1 downto 0)  := "01";
constant Start_Gen_State_2        : std_logic_vector(1 downto 0)  := "10";
constant Start_Gen_State_3        : std_logic_vector(1 downto 0)  := "11";

begin


 I2C_Start_Gen_States: process(MPU_CLK, Rst_L)
 begin
  if(Rst_L= '0')then
   Current_Start_Gen_State <= Idle_Start_Gen_State;
  elsif(rising_edge(MPU_CLK)) then
   Current_Start_Gen_State <= Next_Start_Gen_State;
  end if;
 end process;

 Start_Gen_State_Machine: process(Current_Start_Gen_State, Start_Enable,SDA,SCL)
 begin
  case Current_Start_Gen_State is
   when Idle_Start_Gen_State =>
     SDA_EN2  <= '0';
     if(Start_Enable = '1') then
       Next_Start_Gen_State <= Start_Gen_State_1;
     else
       Next_Start_Gen_State <= Idle_Start_Gen_State;        
     end if;
     
   when Start_Gen_State_1 =>
     SDA_EN2 <= '0';
     if(SDA = '1' and SCL = '1')then
       Next_Start_Gen_State <= Start_Gen_State_2;
     elsif(SDA = '1' and SCL = '0') then
       Next_Start_Gen_State <= Start_Gen_State_1;           -- waiting for the scl(h) clock to go high
     else
       Next_Start_Gen_State <= Idle_Start_Gen_State;
     end if;
      
   when Start_Gen_State_2 =>  
     SDA_EN2  <= '1';
     Next_Start_Gen_State <= Start_Gen_State_3;

   when Start_Gen_State_3 =>  
     if(SCL = '0' ) then
       SDA_EN2  <= '0';
       Next_Start_Gen_State <= Idle_Start_Gen_State;
     else
       SDA_EN2  <= '1';
       Next_Start_Gen_State <= Start_Gen_State_3;      
     end if;
    
   when others =>
       SDA_EN2  <= '0';
       Next_Start_Gen_State <= Idle_Start_Gen_State;
      
  end case;

 end process;      

end Start_Behave;

--==========================================================================
--I2C Start Detection Block
--==========================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;


entity Start_Detect is
  port(MPU_CLK       : in std_logic;                    -- MPU Clock
       Rst_L         : in std_logic;                    -- Main Reset
       SCL           : in bit;                          -- I2C Clock for f/s mode 
       SDA           : in bit;                          -- I2C data bus for f/s mode        
       Start_Det     : out std_logic);                  -- start detection bit

end Start_Detect;

architecture Start_Det_Behave of Start_Detect is
-- State Signals for Start Detection State Machine
signal Current_Start_Det_State    : std_logic_vector(1 downto 0);
signal Next_Start_Det_State       : std_logic_vector(1 downto 0);
constant Idle_Start_Det_State     : std_logic_vector(1 downto 0)  := "00";
constant Start_Det_State_1        : std_logic_vector(1 downto 0)  := "01";

begin

 I2C_Start_Det_States: process(MPU_CLK,Rst_L)
 begin
   if(Rst_L= '0')then
     Current_Start_Det_State <= Idle_Start_Det_State;
   elsif(rising_edge(MPU_CLK)) then
     Current_Start_Det_State <= Next_Start_Det_State;
   end if;
 end process;

 Start_Det_Reg : process(MPU_Clk, Rst_L, Current_Start_Det_State, SCL, SDA)
 begin
   if(Rst_L= '0')then
     Start_Det <= '0';
   elsif(rising_edge(MPU_CLK)) then
     if(Current_Start_Det_State = Idle_Start_Det_State) then
       Start_Det <= '0';
     elsif(Current_Start_Det_State = Start_Det_State_1) then
       if(SDA = '0' and SCL = '1') then
         Start_Det <= '1';
       else
         Start_Det <= '0';
       end if;   
     end if;  
   end if; 
 end process;
 
 Start_Det_State_Machine: process(Current_Start_Det_State, SCL, SDA)
 begin
   case Current_Start_Det_State is
     when Idle_Start_Det_State =>
       if(SCL = '1' and SDA = '1') then
         Next_Start_Det_State <= Start_Det_State_1;        
       else
         Next_Start_Det_State <= Idle_Start_Det_State;       
       end if;    
     when Start_Det_State_1 =>
       if(SDA = '0' and SCL = '1') then
         Next_Start_Det_State <= Idle_Start_Det_State;       
       elsif(SDA = '1' and SCL = '1') then
         Next_Start_Det_State <= Start_Det_State_1;        
       else
         Next_Start_Det_State <= Idle_Start_Det_State;       
       end if;
     when others =>
       Next_Start_Det_State <= Idle_Start_Det_State;         
   end case;
 end process;

end Start_Det_Behave;

--==========================================================================
--I2C Stop Signal Generation Block
--==========================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity Stop_Generator is
  port(MPU_CLK       : in std_logic;                    -- MPU Clock
       Rst_L         : in std_logic;                    -- Main Reset
       Stop_Enable   : in std_logic;                    -- Stop Enable, activates stop gen process
       SCL           : in bit;                          -- I2C Clock for f/s mode 
       SDA           : in bit;                          -- I2C data bus for f/s mode        
       SDA_EN3       : out std_logic);                  -- sda enable

end Stop_Generator;

architecture Stop_Behave of Stop_Generator is
-- State Signals for Stop Generation State Machine
signal Current_Stop_Gen_State    : std_logic_vector(1 downto 0);
signal Next_Stop_Gen_State       : std_logic_vector(1 downto 0);
constant Idle_Stop_Gen_State     : std_logic_vector(1 downto 0)  := "00";
constant Stop_Gen_State_1        : std_logic_vector(1 downto 0)  := "01";
constant Stop_Gen_State_2        : std_logic_vector(1 downto 0)  := "10";
constant Stop_Gen_State_3        : std_logic_vector(1 downto 0)  := "11";

begin

 I2C_Stop_Gen_States: process(MPU_CLK,Rst_L)
 begin
  if(Rst_L= '0')then
   Current_Stop_Gen_State <= Idle_Stop_Gen_State;
  elsif(rising_edge(MPU_CLK)) then
   Current_Stop_Gen_State <= Next_Stop_Gen_State;
  end if;
 end process;

 Stop_Gen_State_Machine: process(Current_Stop_Gen_State, Stop_Enable, SCL, SDA)
 begin
 
  case Current_Stop_Gen_State is
   when Idle_Stop_Gen_State =>
     if(Stop_Enable = '1') then
       SDA_EN3  <= '1';
       Next_Stop_Gen_State <= Stop_Gen_State_1;
     else
       SDA_EN3  <= '0';
       Next_Stop_Gen_State <= Idle_Stop_Gen_State;        
     end if;
    
   when Stop_Gen_State_1 =>
     SDA_EN3 <= '1';                               
     if(SCL = '1') then                
       Next_Stop_Gen_State <= Stop_Gen_State_2;      
     else            
       Next_Stop_Gen_State <= Stop_Gen_State_1;      
     end if;                                         
      
   when Stop_Gen_State_2 =>  
     SDA_EN3  <= '0';
     Next_Stop_Gen_State <= Stop_Gen_State_3; 

  when Stop_Gen_State_3 =>
     if(SCL = '0') then
      SDA_EN3  <= '0';
      Next_Stop_Gen_State <= Idle_Stop_Gen_State;
     else
      SDA_EN3  <= '0';
      Next_Stop_Gen_State <= Stop_Gen_State_3;     
     end if;  
 
   when others =>
       SDA_EN3  <= '0';
       Next_Stop_Gen_State <= Idle_Stop_Gen_State;
      
  end case;

 end process;      

end Stop_Behave;

--===========================================================================
--I2C Stop Detection Block
--===========================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;


entity Stop_Detect is
  port(MPU_CLK       : in std_logic;                    -- MPU Clock
       Rst_L         : in std_logic;                    -- Main Reset
       SCL           : in bit;                          -- I2C Clock for f/s mode 
       SDA           : in bit;                          -- I2C data bus for f/s mode        
       Stop_Det      : out std_logic);                  -- stop detection bit

end Stop_Detect;

architecture Stop_Det_Behave of Stop_Detect is
-- State Signals for Start Detection State Machine
signal Current_Stop_Det_State    : std_logic_vector(1 downto 0);
signal Next_Stop_Det_State       : std_logic_vector(1 downto 0);
constant Idle_Stop_Det_State     : std_logic_vector(1 downto 0)  := "00";
constant Stop_Det_State_1        : std_logic_vector(1 downto 0)  := "01";

begin

 I2C_Stop_Det_States: process(MPU_CLK,Rst_L)
 begin
   if(Rst_L= '0')then
     Current_Stop_Det_State <= Idle_Stop_Det_State;
   elsif(rising_edge(MPU_CLK)) then
     Current_Stop_Det_State <= Next_Stop_Det_State;
   end if;
 end process;

 Stop_Det_Reg : process(MPU_Clk, Rst_L, Current_Stop_Det_State,SCL, SDA)
 begin
   if(Rst_L= '0')then
     Stop_Det <= '0';
   elsif(rising_edge(MPU_CLK)) then
     if(Current_Stop_Det_State = Idle_Stop_Det_State) then
       Stop_Det <= '0';
     elsif(Current_Stop_Det_State = Stop_Det_State_1) then
       if(SDA = '1' and SCL = '1') then
         Stop_Det <= '1';
       else
         Stop_Det <= '0';
       end if;   
     end if;  
   end if; 
 end process;
 
 Stop_Det_State_Machine: process(Current_Stop_Det_State, SCL, SDA)
 begin
   case Current_Stop_Det_State is
     when Idle_Stop_Det_State =>
       if(SCL = '1' and SDA = '0')then
         Next_Stop_Det_State <= Stop_Det_State_1;        
       else
         Next_Stop_Det_State <= Idle_Stop_Det_State;       
       end if;    
     when Stop_Det_State_1 =>
       if(SDA = '1' and SCL = '1') then
         Next_Stop_Det_State <= Idle_Stop_Det_State;       
       elsif(SDA = '0' and SCL = '1') then
         Next_Stop_Det_State <= Stop_Det_State_1;        
       else
         Next_Stop_Det_State <= Idle_Stop_Det_State;       
       end if;
     when others =>
       Next_Stop_Det_State <= Idle_Stop_Det_State;         
   end case;
 end process;

end Stop_Det_Behave;

--------------------------------- E O F --------------------------------------
