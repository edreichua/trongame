----------------------------------------------------------------------------------
-- Company: 		 Engs 31 15X
-- Engineer: 		 Edrei Chua and Jonathan Huang
-- 
-- Create Date:    10:32:22 08/14/2015 
-- Design Name: 	 Tron
-- Module Name:    memory_test_pattern - Behavioral 
-- Project Name:   Tron
-- Target Devices: Spartan 3E
-- Tool versions:  ISE 14.7
-- Description:  	 Test pattern to test the MemoryRAM and VGAController
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity memory_test_pattern is
    Port ( clk : in STD_LOGIC;
			  h_video_on : in STD_LOGIC;
			  v_video_on : in STD_LOGIC;
			  pixel_x_w : out  STD_LOGIC_VECTOR (9 downto 0);
           pixel_y_w : out  STD_LOGIC_VECTOR (9 downto 0);
			  wr_en : out STD_LOGIC;
           color : out  STD_LOGIC_VECTOR (1 downto 0));
end memory_test_pattern;

architecture Behavioral of memory_test_pattern is
-- internal signals
	signal iQ_x : unsigned(9 downto 0) := (others => '0');
	signal iQ_y : unsigned(9 downto 0) := (others => '0');

begin
-- Test Pattern
Pattern: process(iQ_x, iQ_y)
begin
	if (iQ_x >= 0) and (iQ_x < 320) and (iQ_y >= 0) and (iQ_y < 240) then			-- top left is black
		color <= "00";
	elsif (iQ_x >= 320) and (iQ_x < 640) and (iQ_y >= 0) and (iQ_y < 240) then		-- top right is blue
		color <= "01";
	elsif (iQ_x >= 320) and (iQ_x < 640) and (iQ_y >= 240) and (iQ_y < 480) then	-- bottom right is green
		color <= "10";
	elsif (iQ_x >= 0) and (iQ_x <320) and (iQ_y >= 240) and (iQ_y < 480) then		-- bottom left is red
		color <= "11";
	else
		color <= "00";
	end if;

end process Pattern;

-- Counter
Counter: process(clk)
begin
	if rising_edge(clk) then
		-- only write when video is not on
		if h_video_on = '0' or v_video_on = '0' then
		
			-- Horizontal Counter
			if iQ_x < 639 then							-- increment
				iQ_x <= iQ_x + 1;
			else
				iQ_x <= (others => '0');				-- reset
				-- Vertical Counter
				if iQ_y < 479 then						-- increment
					iQ_y <= iQ_y + 1;
				else											-- reset
					iQ_y <= (others => '0');
				end if;
			end if;
		end if;
	end if;
end process Counter;

-- convert back to std_logic_vector
pixel_x_w <= std_logic_vector(iQ_x);	
pixel_y_w <= std_logic_vector(iQ_y);	
wr_en <= NOT(v_video_on);

end Behavioral;

