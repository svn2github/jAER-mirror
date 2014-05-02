------------------------------------------------------------------------------
-- 
--  Name:  I2C_Main_Blk.vhd
-- 
--  Description:  Main state machine block controls the transaction on the 
--              I2C bus. It acts as an interface between the I2C controller 
--              and the I2C bus. 
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

entity I2C_Main is
  port(MPU_CLK           : in std_logic;                        -- MP Clock 
       Rst_L             : in std_logic;                        -- Main Reset, active low
       SCL               : in bit;--7/14std_logic;                      -- I2C F/S mode Clock
       SDA               : in bit;--7/14std_logic;                      -- SDA
       Bit_Count         : in std_logic_vector(2 downto 0);     -- Bit count for I2C packets
       Bit_Cnt_Flag      : in std_logic;                        -- Bit Count overflow flag
       Byte_Cnt_Flag     : in std_logic;                        -- Byte Count overflow flag
       Trans_Buffer      : in std_logic_vector(7 downto 0);     -- Data from MPU for I2C Write
       Low_Address_Reg   : in std_logic_vector(7 downto 0);     -- Low order Address bits for I2C Slave
       Lost_Arb          : in std_logic;                        -- Lost Arbitration Bit
       Start_Det         : in std_logic;                        -- I2C Start Detect
       Stop_Det          : in std_logic;                        -- I2C Stop Detect       
       Command_Reg       : in std_logic_vector(1 downto 0);     -- CMD part of Command_Status Reg Contains:
                                                                -- Go, Abort. Does not include: I2C_Mode, 
                                                                -- I2C_address Size,Iack,Trans_IE and Recieve_IE.      
       Status_Reg        : out std_logic_vector(3 downto 0);    -- Status part of Command_Status Reg Contains:
                                                                -- I2C_Bus_Busy, Abort_Ack, Error,Done
                                                                -- Does not include:Trans_Buf_Empty, Recieve_Buf_Full,
                                                                -- Lost_Arb. Lost Arb comes from arbiter
       Read_Buffer       : out std_logic_vector(7 downto 0);    -- I2C read data byte                                                                   
       Bit_Cnt_EN        : out std_logic;                       -- Bit count enable
       Byte_Cnt_EN       : out std_logic;                       -- Byte count enable
       Start_EN          : out std_logic;                       -- Start enable
       Stop_EN           : out std_logic;                       -- Stop enable
       SDA_EN1           : out std_logic;                       -- SDA enable
       TBE_Set           : out std_logic;                       -- set Transmit_Buffer_Empty flag for MPU block
       RBF_Set           : out std_logic;                       -- set Recieve_Buffer_Full flag for MPU block
       Go_Clear          : out std_logic;                      -- Request to clear go bit
       WCS_Ack           : out std_logic;
       RCS_Ack           : out std_logic);

end I2C_Main;

architecture I2C_Main_Behave of I2C_Main is
 signal go           : std_logic;
 signal abort        : std_logic;
 signal I2C_Bus_Busy         : std_logic;
 signal Error                : std_logic;
 signal Abort_Ack            : std_logic;
 signal Done                 : std_logic;
 signal Reset                : std_logic;
  
 signal I2C_RW_Bit           : std_logic;
 signal Read_SR              : std_logic_vector(7 downto 0);
 signal Trans_Buffer_SR      : std_logic_vector(7 downto 0);

 signal Value                : std_logic;
 
 signal det_low              : std_logic;
 signal det_high             : std_logic;
 signal MCS_Write_Flag       : std_logic; 
 signal MCS_Read_Flag        : std_logic; 
 signal load                 : std_logic_vector(1 downto 0);
 signal shift                : std_logic;
 signal bit_cnt2             : std_logic; 


signal b0                    :std_logic;
signal b1                    :std_logic;
signal s                     :std_logic;

-- State Bits for the Main State Machine
-- ONLY 3 state bits
signal   MCS                     : std_logic_vector(4 downto 0);
constant Idle_State              : std_logic_vector(4 downto 0)  := "00001";
constant Delay_Start_EN_State    : std_logic_vector(4 downto 0)  := "00010";
constant Write_Slv_Addr_State    : std_logic_vector(4 downto 0)  := "00100";
constant Main_Write_State        : std_logic_vector(4 downto 0)  := "01000";
constant Main_Read_State         : std_logic_vector(4 downto 0)  := "10000";

-- State Bits for the Write State Machine
-- ONLY 2 state bits
signal   WCS                     : std_logic_vector(4 downto 0);
signal   Next_WCS                : std_logic_vector(4 downto 0);
constant Write_State             : std_logic_vector(4 downto 0)  := "00001";
constant Delay_Write_State       : std_logic_vector(4 downto 0)  := "00010";
constant Delay_Ack_Write_State   : std_logic_vector(4 downto 0)  := "00100";
constant Ack_Write_State         : std_logic_vector(4 downto 0)  := "01000";
constant Error_Write_State       : std_logic_vector(4 downto 0)  := "10000";

-- State Bits for the Read State Machine
-- ONLY 2 state bits
signal   RCS                     : std_logic_vector(5 downto 0);
signal   Next_RCS                : std_logic_vector(5 downto 0);
constant Read_State              : std_logic_vector(5 downto 0)  := "000001";
constant Delay_Read_State        : std_logic_vector(5 downto 0)  := "000010";
constant Delay_Ack_Read_State    : std_logic_vector(5 downto 0)  := "000100";
constant Delay_Ack_Read_State2   : std_logic_vector(5 downto 0)  := "001000";
constant Ack_Read_State          : std_logic_vector(5 downto 0)  := "010000";
constant Error_Read_State        : std_logic_vector(5 downto 0)  := "100000";

begin
   go           <= Command_Reg(1);
   abort        <= Command_Reg(0);
   I2C_RW_Bit   <= Low_Address_Reg(0);

   WCS_Ack      <= WCS(3);
   RCS_Ack      <= RCS(4);

   Status_Reg   <= I2C_Bus_Busy & Error & Abort_Ack & Done;

   Reset        <= '0' when RST_L = '0' or abort = '1' else '1';
   
   MCS_Read_Flag   <= '1' when MCS(4) = '1' and I2C_RW_Bit = '1' else '0';

   MCS_Write_Flag   <= '1' when MCS(2) = '1' or ((MCS(3) = '1') and I2C_RW_Bit = '0') else '0';

 output_proc: process(MPU_CLK,Reset,WCS,MCS,Start_Det,Stop_Det,I2C_RW_Bit,det_low,bit_cnt2)
 begin
   if(Reset = '0') then
     Abort_Ack    <= '0';
     Error        <= '0';
     I2C_Bus_Busy <= '0';
     Done         <= '0';
     TBE_Set      <= '0';
     RBF_Set      <= '0';
     Bit_Cnt_En   <= '0';
     bit_cnt2     <= '0';
     Byte_Cnt_En  <= '0';
     Start_En     <= '0';
     Stop_En      <= '0';
     Go_Clear     <= '0';
     Read_Buffer  <= "00000000";
     b0 <= '0';
     b1 <= '0';
     s  <= '0';


   elsif(rising_edge(MPU_CLK)) then
     if(abort = '1') then
       Abort_Ack <= '1';
     else  
       Abort_Ack <= '0';
     end if;  
     
     if((WCS(4) = '1')or(RCS(5) = '1')) then      
       Error <= '1';
     else
       Error <= '0';
     end if;

     if(start_det = '1') then
       I2C_Bus_Busy <= '1';
     end if;
     if(stop_det = '1' and I2C_Bus_Busy = '1') then
       I2C_Bus_Busy <= '0';
     end if;

     if((s = '0' and b0 = '0' and b1 = '1') or ( s = '1' and ( b0 = '1' or b1 = '1'))) then
       b0 <= '1';
     else
       b0 <= '0';
     end if;

     if( s = '1' and b0 = '0' and b1 = '0') then
       b1 <= '1';
     else
       b1 <= '0';
     end if;

     if(WCS(1) = '1' and I2C_RW_Bit = '0' and Bit_Count = "001" and Byte_Cnt_Flag = '0' and MCS(3) = '1') then
       s <= '1';
     else
       s <= '0';
     end if;

     if(b0 = '0' and b1 = '1') then
       TBE_Set <= '1';
     else
       TBE_Set <= '0';
     end if;
       
     if(RCS(4) = '1' and I2C_RW_Bit = '1' and MCS(4) = '1') then
       RBF_Set <= '1';
     else
       RBF_Set <= '0';
     end if;
       
     if(((WCS(0) = '1' and MCS_Write_Flag = '1') or (RCS(0) = '1' and MCS_Read_Flag = '1' )) and bit_cnt2 = '1') then
       Bit_Cnt_En <= '1';
     else
       Bit_Cnt_En <= '0';
     end if;

     if((MCS(2) = '1' or MCS(3) = '1' ) and det_low = '1')  then
       bit_cnt2 <= '1';
     elsif(MCS(0) = '1') then
       bit_cnt2 <= '0';
     end if;
       
     if((WCS(3) = '1' and MCS_Write_Flag = '1') or (RCS(2) = '1' and MCS_Read_Flag = '1')) then
       Byte_Cnt_En <= '1';
     else
       Byte_Cnt_En <= '0';
     end if;

     if(MCS(1) = '1'  and det_low = '1' and I2C_Bus_Busy = '0') then
       Start_En <= '1';
     else
       Start_En <= '0';
     end if;

     if(MCS(1) = '1') then
       Go_Clear <= '1';
       Done     <= '0';
       Stop_En  <= '0';
     elsif((MCS(0) = '1' and (WCS(0) = '1' or RCS(2) = '1'))and 
           Bit_Cnt_Flag = '1' and Byte_Cnt_Flag = '1' and det_low = '1' and I2C_Bus_Busy = '1') then
       Done     <= '1';
       Go_Clear <= '0';
       Stop_En  <= '1';
     else
       Go_Clear <= '0';
       Stop_En  <= '0';
     end if;
    
     if(RCS(4) = '1') then
       Read_Buffer  <= Read_SR;
     end if;
 
   end if;
 end process;          
     
                             
 I2C_Det : process(MPU_CLK, Reset, SCL)
 begin
   if(Reset = '0') then
     det_low  <= '0';
     det_high <= '0';
     
   elsif(rising_edge(MPU_CLK)) then 
     if(SCL = '0') then --  data can only change during scl low    
       det_low <= '1';
     else
       det_low <= '0';
     end if;

     if(SCL = '1') then --  data can only change during scl low    
       det_high <= '1';
     else
       det_high <= '0';
     end if;
     
   end if;
 end process;        
 
 I2C_Load_SR_Process:process(MPU_CLK, Reset, load,shift)
 begin
   if(Reset = '0') then
     Trans_Buffer_SR     <= "00000000";        
     Value               <= '0';     
          
   elsif(rising_edge(MPU_CLK)) then 
     case load is
       when "01" =>
         Trans_Buffer_SR(7 downto 0) <= Low_Address_Reg(6 downto 0) & Low_Address_Reg(7);
         Value                       <= Low_Address_Reg(7); --write out msb to lsb
       when "10" =>
         Trans_Buffer_SR(7 downto 0) <= Trans_Buffer(6 downto 0) & Trans_Buffer(7);
         Value <= Trans_Buffer(7);
       when "11" =>
         if(shift = '0') then
           Trans_Buffer_SR(7 downto 0) <= Trans_Buffer_SR(7 downto 0);
           Value <= Value;
         else
           Trans_Buffer_SR(7 downto 0) <= Trans_Buffer_SR(6 downto 0) & Trans_Buffer_SR(7);         
           Value                       <= Trans_Buffer_SR(7); --write out msb to lsb           
         end if;   
       when others =>
         Trans_Buffer_SR(7 downto 0) <= Trans_Buffer_SR(7 downto 0);
         Value <= Value;
      end case;
   end if;
 end process;
     


 I2C_drive_sda_Process:process(MPU_CLK, MCS(0),MCS(1),WCS(2),WCS(3),WCS(4),Bit_Cnt_Flag,Reset, value)
 begin
   if(Reset = '0') then
     SDA_EN1 <= '0';
         
   elsif(rising_edge(MPU_CLK)) then    
     if(RCS(4) = '1') then
       SDA_EN1 <= '1';
     elsif(det_low = '1') then   
       if(MCS(0) = '1' or MCS(1) = '1'  or 
         ((WCS(2) = '1' or WCS(3) = '1' or WCS(4) = '1') and Bit_Cnt_Flag = '1')) then
         SDA_EN1 <= '0';
       else 
         if(Value = '1') then  -- Write out MSB to LSB and address first       
           SDA_EN1   <= '0'; -- write out high
         else
             SDA_EN1   <= '1'; -- write out low
         end if;
       end if;
     end if;  --want the data to stay the same until next low scl or sclh
   end if;
 end process;

 I2C_Write_Process:process(MPU_CLK, Reset,MCS(2),MCS(3),WCS(0), Bit_Count, det_low)
 begin
   if(Reset = '0') then
     load  <= "11";
     shift <= '0';     
    
   elsif(rising_edge(MPU_CLK)) then 
     if((MCS(2) = '1') and (WCS(0) = '1') and (Bit_Count = "000") and (det_low = '1')) then
       load <= "01";
       shift <= '0';
     elsif((MCS(3) = '1') and (WCS(0) = '1') and (Bit_Count = "000") and (det_low = '1')) then
       load <= "10";
       shift <= '0';
     elsif((MCS(2) = '1' or MCS(3) = '1') and (Bit_Count = "000") and (det_low = '1') ) then
       load <= load;
       shift <= '0';
     elsif((MCS(2) = '1' or MCS(3) = '1') and (WCS(0) = '1') and (det_low = '1') ) then
       load <= "11";
       shift <= '1';
     else --do nothing
       load <= load;
       shift <= '0';
     end if;
   end if;  
 end process; 
  

 I2C_Read_Process:process(MPU_CLK, Reset, Bit_Count, det_high, RCS, SDA)

 begin
   if(Reset = '0') then
     Read_SR     <= "00000000";        
 
   elsif(rising_edge(MPU_CLK)) then 
     if(MCS(4) = '1' and RCS(0) = '1' and Bit_Count = "001" and det_high = '1') then  
       if(SDA = '1') then
          Read_SR <= "0000000" & '1';
       else
          Read_SR <= "00000000";
       end if;      

     elsif(MCS(4) = '1' and (RCS(0) = '1' or RCS(2) = '1') and det_high = '1') then 
       if(SDA = '1') then
         Read_SR <= Read_SR(6 downto 0) & '1';
       else
         Read_SR <= Read_SR(6 downto 0) & '0';
       end if;      
     else
       Read_SR <= Read_SR;
     end if;
   end if;  
 end process;

 I2C_WSM: process(MPU_CLK, Reset,Next_WCS)
 begin
   if(Reset = '0') then
     WCS       <= Write_State;     
   elsif(rising_edge(MPU_CLK)) then 
     WCS       <= Next_WCS;        
   end if;
 end process;
     
 I2C_WSM_Process: process(WCS, det_low, det_high, Lost_Arb, Bit_Cnt_Flag, MCS_Write_Flag, SDA)
 begin
   case WCS is
     when Write_State =>
       if(Lost_Arb = '0') then
         if(det_low = '1' and MCS_Write_Flag = '1') then
             Next_WCS <= Delay_Write_State;  -- wait for the SCLH clock to transition one cycle    
                                                       -- and write out next bit 
         else
           Next_WCS <= Write_State;
         end if;
       else
         Next_WCS <= Error_Write_State;         
       end if;  

     when Delay_Write_State =>
          if(det_high = '1' and Bit_Cnt_Flag = '1') then -- wait for the clock to go high again
            Next_WCS <= Delay_Ack_Write_State;                 -- if bit_count is up goto ack state
          elsif(det_high = '1' and Bit_Cnt_Flag = '0') then
            Next_WCS <= Write_State;
          else
            Next_WCS <= Delay_Write_State;      
          end if;        

     when Delay_Ack_Write_State =>
          if(det_low = '1') then
            Next_WCS <= Ack_Write_State;
          else
            Next_WCS <= Delay_Ack_Write_State;      
          end if;        

     when Ack_Write_State =>
       if(det_high = '1') then
         if(SDA = '0') then  -- acknowlege recieved /A
           Next_WCS <= Write_State;        
         else --failed ack
           Next_WCS <= Error_Write_State;                   
         end if;  
       else
         Next_WCS <= Ack_Write_State; -- wait for the SCL or SCLH clock to go high, thus data is stable
       end if;

     when Error_Write_State =>       
       Next_WCS <= Error_Write_State;                   
              
     when others =>
       Next_WCS <= Write_State;        
   end case;
 end process;

 I2C_RSM: process(MPU_CLK, Reset,Next_RCS)
 begin
   if(Reset = '0') then
     RCS       <= Read_State;     
   elsif(rising_edge(MPU_CLK)) then 
     RCS       <= Next_RCS;        
   end if;
 end process;

 I2C_RSM_Process: process(RCS, Lost_Arb, Bit_Cnt_Flag,
                           det_low, SDA, det_high, MCS_Read_Flag)
 begin
   case RCS is
     when Read_State =>
       if(Lost_Arb = '0') then
         if(det_high = '1' and MCS_Read_Flag = '1') then
              Next_RCS <= Delay_Read_State;  -- wait for the SCLH clock to transition one cycle    
                                                       -- and read in next bit 
          else
            Next_RCS <= Read_State;  
          end if;  
        else -- lost arb
          Next_RCS <= Error_Read_State;      
        end if;

     when Delay_Read_State =>
       if(det_low = '1') then -- wait for the clock to go high again
         if(Bit_Cnt_Flag = '1') then 
           Next_RCS <= Delay_Ack_Read_State; -- done reading byte
         else
           Next_RCS <= Read_State;  -- wait for the SCLH clock to transition one cycle    
                                                      -- and read in next bit 
         end if;
       else
         Next_RCS <= Delay_Read_State;      
       end if;        

     when Delay_Ack_Read_State =>
          if(det_high = '1') then
            Next_RCS <= Delay_Ack_Read_State2;
          else
            Next_RCS <= Delay_Ack_Read_State;      
          end if;        

     when Delay_Ack_Read_State2 =>
          if(det_low = '1') then
            Next_RCS <= Ack_Read_State;
          else
            Next_RCS <= Delay_Ack_Read_State2;      
          end if;        

     when Ack_Read_State =>
       if(det_high = '1') then 
         if(SDA = '0') then  -- acknowlege recieved /A
           Next_RCS <= Read_State;        
         else --failed ack
           Next_RCS <= Error_Read_State;                   
         end if;  
       else
         Next_RCS <= Ack_Read_State; -- wait for the SCL or SCLH clock to go high, thus data is stable
       end if;

     when Error_Read_State =>       
       Next_RCS <= Error_Read_State;                   
              
     when others =>
       Next_RCS <= Read_State;        
   end case;
 end process;
   
 I2C_MSM_Process: process(MPU_CLK, Reset, MCS,Byte_Cnt_Flag, I2C_RW_Bit,
                           SCL, Start_Det, go)
 begin
   if(Reset = '0') then
     MCS       <= Idle_State;     
     
   elsif(rising_edge(MPU_CLK)) then 
     case MCS is
       when Idle_State =>
         if(I2C_Bus_Busy = '0' and go = '1') then
          if(SCL = '1') then
             MCS <= Delay_Start_EN_State;                  
           else
             MCS <= Idle_State;
           end if;
         else
           MCS <= Idle_State;
         end if;
      
       when Delay_Start_EN_State =>
         if(Start_Det = '1')  then 
           MCS <= Write_Slv_Addr_State;
         else
           MCS <= Delay_Start_EN_State;            
         end if;

       when Write_Slv_Addr_State =>
         if(WCS(3) = '1' ) then   -- ack state in write sm
           if(I2C_RW_Bit = '0') then
             MCS <= Main_Write_State;
           else
             MCS <= Main_Read_State;
           end if;
         else
           MCS <= Write_Slv_Addr_State; -- wait for write sm to finish
         end if;

       when Main_Write_State =>
         if(Byte_Cnt_Flag = '1' and WCS(3) = '1') then -- continue writing until transaction complete
           MCS <= Idle_State;
         else          
           MCS <= Main_Write_State;        
         end if;                
             
       when Main_Read_State =>
         if(Byte_Cnt_Flag = '1') then -- continue reading until transaction complete
           MCS <= Idle_State;
         else          
           MCS <= Main_Read_State;        
         end if;                

       when others =>
         MCS <= Idle_State;
     end case;
   end if;
 end process;

end I2C_Main_Behave;

--------------------------------- E O F --------------------------------------
