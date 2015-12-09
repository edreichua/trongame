----------------------------------------------------------------------------------
-- Company: 		 Engs 31 15X
-- Engineer: 		 Edrei Chua and Jonathan Huang
-- 
-- Create Date:    23:54:10 08/11/2015 
-- Design Name: 	 Tron
-- Module Name:    VGAtest_top - Behavioral 
-- Project Name: 	 Tron
-- Target Devices: Spartan 3E
-- Tool versions:  ISE 14.7
-- Description: 	 Top level file to test the VGAController
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
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity VGAtest_top is
    Port ( clk : in  STD_LOGIC;
			  hsync : out STD_LOGIC;
			  vsync : out STD_LOGIC;
           color : out  STD_LOGIC_VECTOR (7 downto 0));
end VGAtest_top;

architecture Behavioral of VGAtest_top is

-- Component Declarations
component VGAController is
    Port ( mclk : in  STD_LOGIC;
           pixel_x : out  STD_LOGIC_VECTOR (9 downto 0);
           pixel_y : out  STD_LOGIC_VECTOR (9 downto 0);			
           h_video_on : out  STD_LOGIC;
           v_video_on : out  STD_LOGIC;
           hsync : out  STD_LOGIC;
           vsync : out  STD_LOGIC);
end component;

component vga_test_pattern is
	port(row,column			: in std_logic_vector(9 downto 0);
		  color					: out std_logic_vector(7 downto 0));
end component;

-- internal signal
signal row, column : std_logic_vector(9 downto 0);

begin
VGAControl: VGAController PORT MAP(
	mclk => clk,
	pixel_x => column,
	pixel_y => row,
	h_video_on => open,
	v_video_on => open,
	hsync => hsync,
	vsync => vsync);

Test: vga_test_pattern PORT MAP(
	row => row,
	column => column,
	color => color);


end Behavioral;

