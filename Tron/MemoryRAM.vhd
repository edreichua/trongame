----------------------------------------------------------------------------------
-- Company: 		 Engs 31 15X
-- Engineer: 		 Edrei Chua and Jonathan Huang
-- 
-- Create Date:    20:03:20 08/13/2015 
-- Design Name: 	 Tron
-- Module Name:    MemoryRAM - Behavioral 
-- Project Name:   Tron
-- Target Devices: Spartan 3E
-- Tool versions:  ISE 14.7
-- Description: 	 Pixel generation circuit to store the memory (color) at each
--						 pixel. Downsized to 320x240 to adjust for memory restrictions
--					    on FPGA.
--
-- Dependencies: 
--
-- Revision 1.00 - 08/15/2015: Added process to convert output (2-bit) of  
--									  	  memory into actual color.
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity MemoryRAM is
    Port ( clk : in STD_LOGIC;
		     pixel_x_r : in  STD_LOGIC_VECTOR (9 downto 0);				-- pixel x address to read from memory
           pixel_y_r : in  STD_LOGIC_VECTOR (9 downto 0);				-- pixel y address to read from memory
           pixel_x_w : in  STD_LOGIC_VECTOR (9 downto 0);				-- pixel x address to write to memory
           pixel_y_w : in  STD_LOGIC_VECTOR (9 downto 0);				-- pixel y address to write to memory
           wr_en : in  STD_LOGIC;												-- 1 to write to memory and 0 to read from memory
           d_in : in  STD_LOGIC_VECTOR (1 downto 0);						-- color to write to memory
           color : out  STD_LOGIC_VECTOR (7 downto 0);					-- color read from memory
			  collide: out STD_LOGIC);												-- collision detection
end MemoryRAM;

architecture Behavioral of MemoryRAM is
-- BRAM signals
	signal rd_addr, wr_addr : std_logic_vector (16 downto 0) := (others => '0');								-- read/write address
	signal d_out : std_logic_vector (1 downto 0) := "00";																-- output of memory
	constant RAM_ADDR_BITS : integer := 17;
	constant RAM_WIDTH : integer := 2;
	type ram_type is array(2**RAM_ADDR_BITS-1 downto 0) of std_logic_vector (RAM_WIDTH-1 downto 0);
	signal myRAM : ram_type;
	
-- Predefined 8-bit colors
	constant RED		: std_logic_vector(7 downto 0) := "11100000";
	constant GREEN		: std_logic_vector(7 downto 0) := "00011100";
	constant BLUE		: std_logic_vector(7 downto 0) := "00011011";
	constant YELLOW	: std_logic_vector(7 downto 0) := "11111100";
	constant BLACK		: std_logic_vector(7 downto 0) := "00000000";
	constant GRAY0		: std_logic_vector(7 downto 0) := "01001001";
	constant GRAY1		: std_logic_vector(7 downto 0) := "10010010";
begin

-- BRAM memory
wr_addr <= pixel_y_w(8 downto 1) & pixel_x_w(9 downto 1);			-- concaternating the write address and group 4 pixels to one
rd_addr <= pixel_y_r(8 downto 1) & pixel_x_r(9 downto 1);			-- concaternating the read address and group 4 pixels to one

BRAM: process(clk)
begin
	if rising_edge(clk) then
		if wr_en = '1' then																-- Write
			myRAM(to_integer(unsigned(wr_addr))) <= d_in;
		else																					-- Read
			d_out <= myRAM(to_integer(unsigned(rd_addr)));
		end if;
	end if;
end process BRAM;

-- Convert d_out of memory to actual color
ColorMap: process(d_out)
begin

	if d_out = "00" then
		color <= BLACK;
		collide <= '0';
	elsif d_out = "01" then
		color <= BLUE; 
		collide <= '1';
	elsif d_out = "10" then
		color <= GREEN;
		collide <= '1';
	else
		color <= RED;
		collide <= '1';
	end if;
end process ColorMap;


end Behavioral;

