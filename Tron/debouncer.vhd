----------------------------------------------------------------------------------
-- Company: 			Engs 31 15X
-- Engineer: 			Edrei Chua and Jonathan Huang
-- 
-- Create Date:    	08/06/2015
-- Design Name: 
-- Module Name:    	debouncer_monopulser - Behavioral 
-- Project Name: 		
-- Target Devices: 	Spartan 3E
-- Tool versions: 	ISE 14.7
-- Description: 		Debouncer code provided by Prof Hansen, integrated with a monopulser
--
-- Dependencies: 
--
--
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity debouncer_monopulse is 
	port( 	clk, switch			: in STD_LOGIC;
				dbpulseswitch		: out std_logic );
end debouncer_monopulse;

architecture behavioral of debouncer_monopulse is 
constant REG_LEN : integer := 10;				-- typ 10ms, lengthen for more delay
signal dbreg	:	std_logic_vector(REG_LEN-1 downto 0) := (others => '0'); 
signal dbswitch : std_logic := '0';

-- signal for monopulser
type state_monopulser is (WAIT1, PULSE, WAIT2);
signal curr_monopulser, next_monopulser: state_monopulser;	-- state for monopulser

begin	  

debounce: 
process(clk, dbreg)
begin
	if rising_edge(clk) then
		if switch /= dbreg(0) then
			dbreg <= switch & dbreg(REG_LEN-1 downto 1);
		else
			dbreg <= (others => switch);
		end if;
	end if;
	
	dbswitch <= dbreg(0);
end process;

-- Combinational logic for monopulser
CombLogicMonopulser: process(curr_monopulser, dbswitch)
begin
-- default
dbpulseswitch <= '0';
next_monopulser <= curr_monopulser;

case curr_monopulser is
	when WAIT1 =>									-- next state is pulse if button is pressed
		if dbswitch ='1' then
			next_monopulser <= PULSE;
		end if;
	when PULSE => dbpulseswitch <= '1';		-- next state is WAIT2
		next_monopulser <= WAIT2;
	when WAIT2 =>									-- next state is WAIT1 after button is released
		if dbswitch='0' then
			next_monopulser <= WAIT1;
		end if;
end case;
end process CombLogicMonopulser;

-- State update for monopulser
StateUpdate: process(clk)
begin
if rising_edge(clk) then
	curr_monopulser <= next_monopulser;
end if;
end process StateUpdate;

end behavioral;

