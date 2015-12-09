----------------------------------------------------------------------------------
-- Company: 			ENGS 31 15X
-- Engineer: 			Edrei Chua and Jonathan HUang
-- 
-- Create Date:    	10:45:01 08/19/2015 
-- Design Name: 		Tron_top
-- Module Name:   	Tron_top - Behavioral 
-- Project Name: 		Tron
-- Target Devices: 	Spartan 3E
-- Tool versions: 	ISE 14.7
-- Description: 		Top level shell for Tron final project
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
--		Revised (EC) 8.26.15 to include debouncers for all the buttons
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity Tron_top is
    Port ( clk : in  STD_LOGIC;
	 		  left_one	: in	STD_LOGIC;			
			  right_one 	: in	STD_LOGIC;
			  up_one 		: in	STD_LOGIC;
			  down_one 	: in	STD_LOGIC;
			  left_two	: in	STD_LOGIC;
			  right_two 	: in	STD_LOGIC;
			  up_two 		: in	STD_LOGIC;
			  down_two 	: in	STD_LOGIC;
			  reset : in STD_LOGIC;
           hsync : out  STD_LOGIC;
           vsync : out  STD_LOGIC;
           color : out  STD_LOGIC_VECTOR (7 downto 0));
end Tron_top;

architecture Behavioral of Tron_top is

-- Component Declarations

-- VGA controller declaration
component VGAController is
    Port ( mclk : in  STD_LOGIC;
           pixel_x : out  STD_LOGIC_VECTOR (9 downto 0);
           pixel_y : out  STD_LOGIC_VECTOR (9 downto 0);			
           h_video_on : out  STD_LOGIC;
           v_video_on : out  STD_LOGIC;
           hsync : out  STD_LOGIC;
           vsync : out  STD_LOGIC);
end component;

-- MemoryRAM declaration
component MemoryRAM is
    Port ( clk : in STD_LOGIC;
		     pixel_x_r : in  STD_LOGIC_VECTOR (9 downto 0);
           pixel_y_r : in  STD_LOGIC_VECTOR (9 downto 0);
           pixel_x_w : in  STD_LOGIC_VECTOR (9 downto 0);
           pixel_y_w : in  STD_LOGIC_VECTOR (9 downto 0);
           wr_en : in  STD_LOGIC;
           d_in : in  STD_LOGIC_VECTOR (1 downto 0);
           color : out  STD_LOGIC_VECTOR (7 downto 0);
			  collide : out STD_LOGIC);
end component;

-- Game Controller declaration
component GameController is
    Port ( clk : in  STD_LOGIC;
           left_one : in  STD_LOGIC;
           right_one : in  STD_LOGIC;
           up_one : in  STD_LOGIC;
           down_one : in  STD_LOGIC;
			  left_two : in  STD_LOGIC;
           right_two : in  STD_LOGIC;
           up_two : in  STD_LOGIC;
           down_two : in  STD_LOGIC;
           color_in : in  STD_LOGIC;
           h_video_on : in  STD_LOGIC;
           v_video_on : in  STD_LOGIC;
			  reset : in STD_LOGIC;
           color_out : out  STD_LOGIC_VECTOR (1 downto 0);
           pixel_x_r : out  STD_LOGIC_VECTOR (9 downto 0);
           pixel_y_r : out  STD_LOGIC_VECTOR (9 downto 0);
           pixel_x_w : out  STD_LOGIC_VECTOR (9 downto 0);
           pixel_y_w : out  STD_LOGIC_VECTOR (9 downto 0);
           wr_en : out  STD_LOGIC);
end component;

-- Debouncer Monopulser declaration
component debouncer_monopulse is 
	port( 	clk					: in STD_LOGIC;
				switch				: in STD_LOGIC;
				dbpulseswitch		: out std_logic );
end component;

-- Signal declarations
signal pixel_x_r, pixel_y_r : std_logic_vector(9 downto 0);								-- connection from game controller to memory
signal pixel_x_r_VGA, pixel_y_r_VGA : std_logic_vector(9 downto 0);					-- VGA controller to read from memory
signal pixel_x_r_game, pixel_y_r_game : std_logic_vector(9 downto 0);				-- Game controller to read from memory
signal pixel_x_w, pixel_y_w : std_logic_vector(9 downto 0);								-- connection from game controller to memory
signal h_video_on, v_video_on : std_logic;													-- connection from VGA controller to game controller
signal wr_en : std_logic;																			-- connection from game controller to memoryRAM to choose to read or write to memory
signal color_in_ram : std_logic_vector(1 downto 0);										-- color to be written to memory			
signal reset_sig : std_logic;																		-- connection from debouncer output to game controller
signal collide_sig : std_logic;																	-- indicating collision
signal up_one_sig, down_one_sig, left_one_sig, right_one_sig	: 	STD_LOGIC;		-- connection from debouncer output to game controller
signal up_two_sig, down_two_sig, left_two_sig, right_two_sig	: 	STD_LOGIC;		-- connection from debouncer output to game controller

begin

-- VGA controller port map
VGAControl: VGAController PORT MAP(
	mclk => clk,
	pixel_x => pixel_x_r_VGA,
	pixel_y => pixel_y_r_VGA,
	h_video_on => h_video_on,
	v_video_on => v_video_on,
	hsync => hsync,
	vsync => vsync);
	
-- MemoryRAM port map
Memory: MemoryRAM PORT MAP(
	clk => clk,
	pixel_x_r => pixel_x_r,
	pixel_y_r => pixel_y_r,	  
	pixel_x_w => pixel_x_w,
	pixel_y_w => pixel_y_w,
	wr_en => wr_en,
	d_in => color_in_ram,	
	color => color,
	collide => collide_sig);

-- Game Controller port map
Game: GameController PORT MAP(
	clk => clk,
	left_one => left_one_sig, 
	right_one => right_one_sig, 
	up_one => up_one_sig, 
	down_one => down_one_sig,
	left_two => left_two_sig,
   right_two => right_two_sig,
   up_two => up_two_sig,
   down_two => down_two_sig,
	color_in => collide_sig,
	h_video_on => h_video_on,
	v_video_on => v_video_on,
	reset => reset_sig, 
	color_out => color_in_ram,
	pixel_x_r => pixel_x_r_game,
	pixel_y_r => pixel_y_r_game,
	pixel_x_w => pixel_x_w,
	pixel_y_w => pixel_y_w,
	wr_en => wr_en);
	
-- Debouncer port map
Debounce_reset: debouncer_monopulse PORT MAP( 	
	clk => clk,
	switch => reset,
	dbpulseswitch => reset_sig);
	
Debounce_up_one: debouncer_monopulse PORT MAP( 	
	clk => clk,
	switch => up_one,
	dbpulseswitch => up_one_sig);

Debounce_down_one: debouncer_monopulse PORT MAP( 	
	clk => clk,
	switch => down_one,
	dbpulseswitch => down_one_sig);
	
Debounce_left_one: debouncer_monopulse PORT MAP( 	
	clk => clk,
	switch => left_one,
	dbpulseswitch => left_one_sig);
Debounce_right_one: debouncer_monopulse PORT MAP( 	
	clk => clk,
	switch => right_one,
	dbpulseswitch => right_one_sig);
Debounce_up_two: debouncer_monopulse PORT MAP( 	
	clk => clk,
	switch => up_two,
	dbpulseswitch => up_two_sig);
Debounce_down_two: debouncer_monopulse PORT MAP( 	
	clk => clk,
	switch => down_two,
	dbpulseswitch => down_two_sig);
Debounce_left_two: debouncer_monopulse PORT MAP( 	
	clk => clk,
	switch => left_two,
	dbpulseswitch => left_two_sig);
Debounce_right_two: debouncer_monopulse PORT MAP( 	
	clk => clk,
	switch => right_two,
	dbpulseswitch => right_two_sig);
	
-- Multiplexer to select pixel_reads
Mux: process(pixel_x_r_game, pixel_y_r_game, pixel_x_r_VGA, pixel_y_r_VGA, v_video_on)
begin
	if v_video_on = '0' then				-- game controller to read from memory when video is off
		pixel_x_r <= pixel_x_r_game;
		pixel_y_r <= pixel_y_r_game;
	else											-- VGA controller to read from memory when video is on
		pixel_x_r <= pixel_x_r_VGA;
		pixel_y_r <= pixel_y_r_VGA;
	end if;
end process Mux;

end Behavioral;

