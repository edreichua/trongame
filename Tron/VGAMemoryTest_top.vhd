----------------------------------------------------------------------------------
-- Company: 		 Engs 31 15X
-- Engineer: 		 Edrei Chua and Jonathan Huang
-- 
-- Create Date:    10:23:53 08/14/2015 
-- Design Name: 	 Tron
-- Module Name:    VGAMemoryTest_top - Behavioral 
-- Project Name:   Tron
-- Target Devices: Spartan 3E
-- Tool versions:  ISE 14.7
-- Description:    Top level file to test MemoryRAM with VGAController
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

entity VGAMemoryTest_top is
    Port ( clk : in  STD_LOGIC;
			  hsync : out STD_LOGIC;
			  vsync : out STD_LOGIC;
           color : out  STD_LOGIC_VECTOR (7 downto 0));
end VGAMemoryTest_top;

architecture Behavioral of VGAMemoryTest_top is

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

component MemoryRAM is
    Port ( clk : in STD_LOGIC;
		     pixel_x_r : in  STD_LOGIC_VECTOR (9 downto 0);
           pixel_y_r : in  STD_LOGIC_VECTOR (9 downto 0);
           pixel_x_w : in  STD_LOGIC_VECTOR (9 downto 0);
           pixel_y_w : in  STD_LOGIC_VECTOR (9 downto 0);
           wr_en : in  STD_LOGIC;
           d_in : in  STD_LOGIC_VECTOR (1 downto 0);
           color : out  STD_LOGIC_VECTOR (7 downto 0);
			  collide: out STD_LOGIC);
end component;

component memory_test_pattern is
    Port ( clk : in STD_LOGIC;
		     h_video_on : in STD_LOGIC;
			  v_video_on : in STD_LOGIC;
			  pixel_x_w : out  STD_LOGIC_VECTOR (9 downto 0);
           pixel_y_w : out  STD_LOGIC_VECTOR (9 downto 0);
			  wr_en : out STD_LOGIC;
           color : out  STD_LOGIC_VECTOR (1 downto 0));
end component;

-- Signal declarations
signal pixel_x_r, pixel_y_r : std_logic_vector(9 downto 0);
signal pixel_x_w, pixel_y_w : std_logic_vector(9 downto 0);
signal h_video_on, v_video_on : std_logic;
signal wr_en : std_logic;
signal color_2 : std_logic_vector(1 downto 0);

begin
VGAControl: VGAController PORT MAP(
	mclk => clk,
	pixel_x => pixel_x_r,
	pixel_y => pixel_y_r,
	h_video_on => h_video_on,
	v_video_on => v_video_on,
	hsync => hsync,
	vsync => vsync);
	
Test: memory_test_pattern PORT MAP(
	clk => clk,
	h_video_on => h_video_on,
	v_video_on => v_video_on,
	pixel_x_w => pixel_x_w,
   pixel_y_w => pixel_y_w,
	wr_en => wr_en,
   color => color_2);
	
Memory: MemoryRAM PORT MAP(
	clk => clk,
	pixel_x_r => pixel_x_r,
	pixel_y_r => pixel_y_r,	  
	pixel_x_w => pixel_x_w,
	pixel_y_w => pixel_y_w,
	wr_en => wr_en,
	d_in => color_2,	
	color => color,
	collide => open);



end Behavioral;

