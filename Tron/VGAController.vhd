----------------------------------------------------------------------------------
-- Company: 		 Engs 31 15X
-- Engineer: 		 Edrei Chua and Jonathan Huang
-- 
-- Create Date:    22:07:26 08/11/2015 
-- Design Name: 	 Tron
-- Module Name:    VGAController - Behavioral 
-- Project Name: 	 Tron
-- Target Devices: Spartan 3E
-- Tool versions:  ISE 14.7
-- Description: 	 Controller that controls the display of the VGA display
--
-- Dependencies: 
--
-- Revision: 1.01 - 08/19/2015: Edited to change when v_video_on turns off
-- Revision: 1.00 - 08/13/2015: Put counters into separate clocked process. 
--									  Made vertical/horizontal logic asynchronous 
--									  Adjusted clock to make it 25 MHz
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity VGAController is
    Port ( mclk : in  STD_LOGIC;
           pixel_x : out  STD_LOGIC_VECTOR (9 downto 0);			
           pixel_y : out  STD_LOGIC_VECTOR (9 downto 0);			
           h_video_on : out  STD_LOGIC;
           v_video_on : out  STD_LOGIC;
           hsync : out  STD_LOGIC;
           vsync : out  STD_LOGIC);
end VGAController;

architecture Behavioral of VGAController is
-- internal signals
	signal iQ_x :	unsigned(9 downto 0) := (others => '0'); 
	signal iQ_y : 	unsigned(9 downto 0) := (others => '0');
	signal v_en : std_logic := '0';
	
	
-- Signals for the clock divider, which divides the matser clock down to 25 MHz 
-- Master clock frequency / CLOCK_DIVIDER_VALUE = 25 MHz
constant CDV2: integer := 50E6/50E6; 						-- Nexys2 board has 50 MHz
constant CLOCK_DIVIDER_VALUE: integer := CDV2;		-- 10 for simulation, CDV2 for implementation
signal clkdiv : integer := 0;								-- the clock divider count
signal clkdiv_tog: std_logic := '0';					-- terminal count
signal clk25 : std_logic := '0';							-- 25 MHz clock

begin
-- Clock buffer for 25 MHz clock
-- The BUFG component puts the slower clock onto the FPGA clocking network
Slow_clock_buffer: BUFG
	port map (I => clkdiv_tog,
				 O => clk25); 

-- Divide the master clock down to 50 MHz, then toggling the clkdiv_tog at 50 MHz
-- gives a 25 MHz clock with 50% duty cycle.
Clock_divider: process(mclk)
begin
	if rising_edge(mclk) then
		if clkdiv = CLOCK_DIVIDER_VALUE-1 then 
			clkdiv_tog <= NOT(clkdiv_tog);
			clkdiv <= 0;
		else
			clkdiv <= clkdiv + 1;
		end if;
	end if;
end process Clock_divider;

-- Horizontal Logic
Horizontal: process(iQ_x)
begin
	hsync <= '1';
	h_video_on <= '0';
	v_en <= '0';								-- default v_en
	
	if iQ_x < 640 then						-- display
		hsync <= '1';
	elsif iQ_x < 656 then					-- right border
		h_video_on <= '0';
		hsync <= '1';
	elsif iQ_x < 752 then					-- retrace
		h_video_on <= '0';
		hsync <= '0';
	elsif iQ_x < 800 then					-- left border
		h_video_on <= '0';
		hsync <= '1';
			
		if iQ_x = 799 then
			v_en <= '1';
		end if;
	end if;
		
end process Horizontal;

-- Vertical Logic
Vertical: process(iQ_y)
begin
	vsync <= '1';
	v_video_on <= '0';

	if iQ_y < 480 then						-- display
		v_video_on <= '1';
		vsync <= '1';
	elsif iQ_y < 490 then					-- bottom border
		v_video_on <= '1';
		vsync <= '1';
	elsif iQ_y < 492 then					-- retrace
		v_video_on <= '0';
		vsync <= '0';
	elsif iQ_y < 521 then					-- top border
		v_video_on <= '0';
		vsync <= '1';
	end if;

end process Vertical;

-- Counter
Counter: process(clk25)
begin
	if rising_edge(clk25) then
		-- Horizontal Counter
		if iQ_x < 799 then						-- increment
			iQ_x <= iQ_x + 1;
		else
			iQ_x <= (others => '0');				-- reset
		end if;
		
		-- Vertical Counter
		if v_en = '1' then
			if iQ_y < 520 then						-- increment
				iQ_y <= iQ_y + 1;
			else											-- reset
				iQ_y <= (others => '0');
			end if;
		end if;
	end if;

end process Counter;

-- convert back to std_logic_vector

pixel_x <= std_logic_vector(iQ_x);	
pixel_y <= std_logic_vector(iQ_y);	

end Behavioral;

