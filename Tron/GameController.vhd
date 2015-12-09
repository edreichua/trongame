----------------------------------------------------------------------------------
-- Company: 		 Engs 31 15X
-- Engineer: 		 Edrei Chua and Jonathan Huang
-- 
-- Create Date:    15:56:17 08/19/2015 
-- Design Name: 	 Tron
-- Module Name:    GameController - Behavioral 
-- Project Name: 	 Tron
-- Target Devices: Spartan 3E
-- Tool versions:  ISE 14.7
-- Description: 	 Game controller for the Tron game. It controls the logic of
--						 the game. 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- 	Revised: 8.20.15 (EC): changed timing of writing to slow down the game
--		Revised: 8.21.15 (JH): changed states of game controller to only control
--									  reading and writing (no counter control)
--		Revised: 8.22.15 (JH): added direction controllers to both players to 
--									  facilitate movement
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity GameController is
    Port ( clk : in  STD_LOGIC;
           left_one : in  STD_LOGIC;			-- debounced left signal for player 1
           right_one : in  STD_LOGIC;			-- debounced right signal for player 1
           up_one : in  STD_LOGIC;				-- debounced up signal for player 1
           down_one : in  STD_LOGIC;			-- debounced down signal for player 1
			  left_two : in  STD_LOGIC;			-- debounced left signal for player 2
           right_two : in  STD_LOGIC;			-- debounced right signal for player 2
           up_two : in  STD_LOGIC;				-- debounced up signal for player 2
           down_two : in  STD_LOGIC;			-- debounced down signal for player 2
           color_in : in  STD_LOGIC;			-- color input from MemoryRAM
           h_video_on : in  STD_LOGIC;			-- 1 during horizontal update, 0 during horizontal refreshes
           v_video_on : in  STD_LOGIC;			-- 1 during vertical update, 0 during vertical refreshes
			  reset : in STD_LOGIC;					-- debounced reset signal
           color_out : out  STD_LOGIC_VECTOR (1 downto 0);		-- the color to write to memory
           pixel_x_r : out  STD_LOGIC_VECTOR (9 downto 0);		-- the pixel x address to read from memory to detect collision
           pixel_y_r : out  STD_LOGIC_VECTOR (9 downto 0);		-- the pixel y address to read from memory to detect collision
           pixel_x_w : out  STD_LOGIC_VECTOR (9 downto 0);		-- the pixel x address to write to memory
           pixel_y_w : out  STD_LOGIC_VECTOR (9 downto 0);		-- the pixel y address to write to memory
           wr_en : out  STD_LOGIC);										-- write read enable for the memory. 1 to write and 0 to read
end GameController;

architecture Behavioral of GameController is
-- Constants
	constant PLAYER1_COLOR		: STD_LOGIC_VECTOR(1 downto 0) := "01";			-- Blue
	constant PLAYER2_COLOR		: STD_LOGIC_VECTOR(1 downto 0) := "10";			-- Green
	constant BACKGROUND			: STD_LOGIC_VECTOR(1 downto 0) := "00";			-- Black
	constant RED					: STD_LOGIC_VECTOR(1 downto 0) := "11";			-- Red
	
	constant START_POS_X1 		: UNSIGNED(9 downto 0) := "0010011111";			-- equals 159
	constant START_POS_Y1 		: UNSIGNED(9 downto 0) := "0011101111";			-- equals 239
	constant START_POS_X2 		: UNSIGNED(9 downto 0) := "0111011111";			-- equals 479
	constant START_POS_Y2 		: UNSIGNED(9 downto 0) := "0011101111";			-- equals 239
	
-- Direction signals
	signal start_game				: STD_LOGIC := '0';									
	
	-- Enables to update the position counter for player 1
	signal up_en_one 				: STD_LOGIC := '0';		
	signal right_en_one 			: STD_LOGIC := '0';
	signal down_en_one 			: STD_LOGIC := '0';
	signal left_en_one 			: STD_LOGIC := '0';
	
	-- Enables to update the position counter for player 2
	signal up_en_two 				: STD_LOGIC := '0';
	signal right_en_two 			: STD_LOGIC := '0';
	signal down_en_two			: STD_LOGIC := '0';
	signal left_en_two 			: STD_LOGIC := '0';
	
-- Counter signals
	signal bkgd_x 					: unsigned(9 downto 0) := (others => '0');		-- pixel x count for background during reset
	signal bkgd_y 					: unsigned(9 downto 0) := (others => '0');		-- pixel y count for background during reset
	signal iQ1_x 					: unsigned(9 downto 0) := (others => '0');		-- pixel x count for player 1
	signal iQ1_y 					: unsigned(9 downto 0) := (others => '0');		-- pixel y count for player 1
	signal iQ2_x 					: unsigned(9 downto 0) := (others => '0');		-- pixel x count for player 2
	signal iQ2_y 					: unsigned(9 downto 0) := (others => '0');		-- pixel y count for player 2
	signal pos_ld		   		: STD_LOGIC := '0';										-- load initial positions of both players
	signal pos_en_one	   		: STD_LOGIC := '0';										-- enable the update of player 1's position counter
	signal pos_en_two	   		: STD_LOGIC := '0';										-- enable the update of player 2's position counter
	
-- Flags
	signal reset_game 			: STD_LOGIC := '0';										-- reset game signal
	signal player_select			: STD_LOGIC := '0';										-- select bit to choose which player position's to update; 0 for player 1 and 1 for player 2

	signal slow_count				: unsigned(1 downto 0) := "00";						-- count the number of screen refreshes
	signal slow_flag				: STD_LOGIC := '0';										-- indicate that the number of screen refreshes has reached the limit indicated
	signal slow_en					: STD_LOGIC := '0';										-- enable the slow down counter
	signal flag						: STD_LOGIC := '0';										-- indicates that all pixels have been updated to the background color during a reset

-- Collision signals
	signal collide_one			: STD_LOGIC := '0';										-- player 1 first collides with player 2
	signal collide_two			: STD_LOGIC := '0';										-- player 2 first collides with player 1
	signal border_collide_one	: STD_LOGIC := '0';										-- player 1 collides with the border
	signal border_collide_two 	: STD_LOGIC := '0';										-- player 2 collides with the border
	
-- Game states
	type game_states is (RESETSTATE, START, PLAYER_SEL_ONE, WAIT1, CHECK_ONE, WRITE_WAIT1, WRITE_WAIT2, PLAYER_SEL_TWO, WAIT2, CHECK_TWO, WRITE_WAIT3, WRITE_WAIT4, GAME_OVER);
	signal curr_game_state, next_game_state : game_states;
	
-- Player 1 Direction states
	type one_states is (START, RIGHT, LEFT, UP, DOWN);
	signal curr_one_state, next_one_state : one_states;
	
-- Player 2 Direction states
	type two_states is (START, RIGHT, LEFT, UP, DOWN);
	signal curr_two_state, next_two_state : two_states;

begin

-- Game Controller
GameControl: process(curr_game_state, collide_one, collide_two, v_video_on, flag, reset, slow_flag)
begin
-- defaults
	next_game_state <= curr_game_state;
	wr_en <= '0';
	reset_game <= '0';
	pos_ld <= '0';
	player_select <= '0';  
	start_game <= '0';
	pos_en_one <= '0';
	pos_en_two <= '0';
	slow_en <= '0';
	
	case curr_game_state is
		when RESETSTATE => 							-- Reset state
			pos_ld <= '1';								-- Load both start positions
			if flag = '1' then						-- Start game only once background is reset
				next_game_state <= START;
			elsif v_video_on = '0' then			-- Reset
				reset_game <= '1';
				wr_en <= '1';
			end if;
		when START => 									-- Start state
			if v_video_on = '0' then				
				start_game <= '1';					-- Makes both players go in their initial positions
				next_game_state <= PLAYER_SEL_ONE;
			end if;
		
		
		when PLAYER_SEL_ONE => 
			if v_video_on = '0' then
				player_select <= '0';				-- Select player 1
				pos_en_one <= '1';					-- Update position
				pos_en_two <= '1';
				next_game_state <= WAIT1;
			end if;
		when WAIT1 =>
			if v_video_on = '0' then
				next_game_state <= CHECK_ONE;		-- check if player 1 has collided
			end if;
		when CHECK_ONE => 
			if collide_one = '1' then				-- Collided so game over
				if v_video_on = '0' then
					wr_en <= '1';
					next_game_state <= GAME_OVER;
				end if;
			else											
				next_game_state <= WRITE_WAIT1;
			end if;
		when WRITE_WAIT1 => 							-- Slow down motorcycle 1
			if slow_flag = '1' then					-- Write once counter reaches terminal count
				wr_en <= '1';
				next_game_state <= PLAYER_SEL_TWO;	-- go to player 2
			elsif v_video_on = '1' then				-- toggle between WRITE_WAIT1 and WRITE_WAIT2
				next_game_state <= WRITE_WAIT2;
				slow_en <= '1';
			end if;
		when WRITE_WAIT2 => 							-- Slow down motorcycle 2
			if slow_flag = '1' then					-- Write once counter reaches terminal count
				wr_en <= '1';
				next_game_state <= PLAYER_SEL_TWO;	-- go to player 2
			elsif v_video_on = '0' then
				next_game_state <= WRITE_WAIT1;	-- toggle between WRITE_WAIT1 and WRITE_WAIT2
				slow_en <= '1';
			end if;
		
		
		when PLAYER_SEL_TWO =>
			if v_video_on = '0' then
				player_select <= '1';				-- Select player 2
				next_game_state <= WAIT2;
			end if;
		when WAIT2 => 
			if v_video_on = '0' then
				player_select <= '1';			
				next_game_state <= CHECK_TWO;		-- check if player 2 has collided
			end if;
		when CHECK_TWO => 
			if collide_two = '1' then				-- Collided so game over
				if v_video_on = '0' then
					player_select <= '1';
					wr_en <= '1';
					next_game_state <= GAME_OVER;
				end if;
			else											-- Go to write state
				next_game_state <= WRITE_WAIT3;
			end if;
		when WRITE_WAIT3 => 							-- Slow down motorcycle 3
			if slow_flag = '1' then					-- Write once counter reaches terminal count
				player_select <= '1';
				wr_en <= '1';
				next_game_state <= PLAYER_SEL_ONE;
			elsif v_video_on = '1' then			
				next_game_state <= WRITE_WAIT4;	-- toggle between WRITE_WAIT3 and WRITE_WAIT4
				slow_en <= '1';
			end if;
		when WRITE_WAIT4 => 							-- Slow down motorcycle 4	
			if slow_flag = '1' then					-- Write once counter reaches terminal count
				player_select <= '1';
				wr_en <= '1';
				next_game_state <= PLAYER_SEL_ONE;
			elsif v_video_on = '0' then
				next_game_state <= WRITE_WAIT3; -- toggle between WRITE_WAIT3 and WRITE_WAIT4
				slow_en <= '1';
			end if;
		when GAME_OVER =>	
			if reset = '1' then						-- wait for reset
				next_game_state <= RESETSTATE;
			end if;	
			
	end case;
end process GameControl;

-- Player One Direction Controller
DirectionController_One: process(curr_one_state, up_one, down_one, right_one, left_one, start_game, reset_game)
begin
-- defaults
	next_one_state <= curr_one_state; 
	up_en_one <= '0';
	right_en_one <= '0';
	down_en_one <= '0';
	left_en_one <= '0';
	
	case curr_one_state is
		when START => 								-- Player 1 initially goes right
			if start_game = '1' then
				next_one_state <= RIGHT;
			end if;
		when RIGHT => 								-- Right
			right_en_one <= '1';		
		
			if reset_game = '1' then
				next_one_state <= START;
			elsif up_one = '1' and left_one = '0' and right_one = '0' and down_one = '0' then			-- Go up
				next_one_state <= UP;
			elsif up_one = '0' and left_one = '0' and right_one = '0' and down_one = '1' then			-- Go down	
				next_one_state <= DOWN; 
			end if;
		when LEFT => 
			left_en_one <= '1';
		
			if reset_game = '1' then
				next_one_state <= START;
			elsif up_one = '1' and left_one = '0' and right_one = '0' and down_one = '0' then			-- Go up
				next_one_state <= UP;			
			elsif up_one = '0' and left_one = '0' and right_one = '0' and down_one = '1' then			-- Go down
				next_one_state <= DOWN; 
			end if;
		when UP =>
			up_en_one <= '1';
		
			if reset_game = '1' then
				next_one_state <= START;
			elsif up_one = '0' and left_one = '0' and right_one = '1' and down_one = '0' then 		-- Go right
				next_one_state <= RIGHT;
			elsif up_one = '0' and left_one = '1' and right_one = '0' and down_one = '0' then		-- Go left
				next_one_state <= LEFT;
			end if;
		when DOWN => 
			down_en_one <= '1';
		
			if reset_game = '1' then
				next_one_state <= START;
			elsif up_one = '0' and left_one = '0' and right_one = '1' and down_one = '0' then 		-- Go right
				next_one_state <= RIGHT;		
			elsif up_one = '0' and left_one = '1' and right_one = '0' and down_one = '0' then		-- Go left
				next_one_state <= LEFT;
			end if;	
	end case;
end process DirectionController_one;

-- Player 2 Direction Controller
DirectionController_Two: process(curr_two_state, up_two, down_two, right_two, left_two, start_game, reset_game)
begin
-- defaults
	next_two_state <= curr_two_state; 
	up_en_two <= '0';
	right_en_two <= '0';
	down_en_two <= '0';
	left_en_two <= '0';
	
	case curr_two_state is
		when START => 									-- Player 2 initially goes left
			if start_game = '1' then
				next_two_state <= LEFT;
			end if;
		when RIGHT => 
			right_en_two <= '1';
		
			if reset_game = '1' then
				next_two_state <= START;
			elsif up_two = '1' and left_two = '0' and right_two = '0' and down_two = '0' then				-- go up
				next_two_state <= UP;				
			elsif up_two = '0' and left_two = '0' and right_two = '0' and down_two = '1' then				-- go down
				next_two_state <= DOWN; 
			end if;
		when LEFT => 
			left_en_two <= '1';
		
			if reset_game = '1' then
				next_two_state <= START;
			elsif up_two = '1' and left_two = '0' and right_two = '0' and down_two = '0'  then				-- go up
				next_two_state <= UP;
			elsif up_two = '0' and left_two = '0' and right_two = '0' and down_two = '1'  then				-- go down
				next_two_state <= DOWN; 
			end if;
		when UP =>
			up_en_two <= '1';
		
			if reset_game = '1' then
				next_two_state <= START;
			elsif up_two = '0' and left_two = '0' and right_two = '1' and down_two = '0'  then 			-- go right
				next_two_state <= RIGHT;
			elsif up_two = '0' and left_two = '1' and right_two = '0' and down_two = '0'  then			-- go left
				next_two_state <= LEFT;
			end if;
		when DOWN => 
			down_en_two <= '1';
		
			if reset_game = '1' then
				next_two_state <= START;
			elsif up_two = '0' and left_two = '0' and right_two = '1' and down_two = '0'  then 			-- go right
				next_two_state <= RIGHT;
			elsif up_two = '0' and left_two = '1' and right_two = '0' and down_two = '0'  then			-- go left
				next_two_state <= LEFT;
			end if;	
	end case;
end process DirectionController_Two;

-- COUNTERS

-- Background Counter
BackgroundCounter: process(clk, reset_game, flag)
begin
	if rising_edge(clk) then
		flag <= '0';
	
		if(reset_game= '1') then
		-- Horizontal Counter
		if bkgd_x < 639 then							-- increment
			bkgd_x <= bkgd_x + 1;
		else
			bkgd_x <= (others => '0');				-- reset
			-- Vertical Counter
			if bkgd_y < 479 then						-- increment
				bkgd_y <= bkgd_y + 1;
			else											-- reset
				bkgd_y <= (others => '0');
				flag <= '1';
			end if;
		end if;
		end if;
	end if;
end process BackgroundCounter;

-- Position Counter for player 1
Player_One_Counter: process(clk, up_en_one, down_en_one, right_en_one, left_en_one, pos_ld, pos_en_one, iQ1_x, iQ1_y)
begin
	if rising_edge(clk) then
		iQ1_x <= iQ1_x;
		iQ1_y <= iQ1_y;

		if pos_ld = '1' then						-- load position for player 1
			iQ1_x <= START_POS_X1;
			iQ1_y <= START_POS_Y1;
		elsif pos_en_one = '1' then
			if up_en_one = '1' then				-- up
				if iQ1_y < 4 then
					border_collide_one <= '1';
				else
					iQ1_y <= iQ1_y -2; 
					border_collide_one <= '0';
				end if;
			elsif down_en_one = '1' then 		-- down
				if iQ1_y > 477 then
					border_collide_one <= '1';
				else
					iQ1_y <= iQ1_y +2; 
					border_collide_one <= '0';
				end if;
			elsif left_en_one = '1' then		-- left
				if iQ1_x < 4 then
					border_collide_one <= '1';
				else
					iQ1_x <= iQ1_x -2; 
					border_collide_one <= '0';
				end if;
			elsif right_en_one = '1' then		-- right
				if iQ1_x > 637 then
					border_collide_one <= '1';
				else
					iQ1_x <= iQ1_x +2; 
					border_collide_one <= '0';
				end if;
			end if;
		end if;
	end if;
end process Player_One_Counter;

-- Position Counter for player 2
Player_Two_Counter: process(clk, up_en_two, down_en_two, right_en_two, left_en_two, pos_ld, pos_en_two, iQ2_x, iQ2_y)
begin
	if rising_edge(clk) then
		iQ2_x <= iQ2_x;
		iQ2_y <= iQ2_y;

		if pos_ld = '1' then						-- load position for player 2
			iQ2_x <= START_POS_X2;
			iQ2_y <= START_POS_Y2;
		elsif pos_en_two = '1' then
			if up_en_two = '1' then				-- up
				if iQ2_y < 4 then
					border_collide_two <= '1';
				else
					iQ2_y <= iQ2_y -2; 
					border_collide_two <= '0';
				end if;
			elsif down_en_two = '1' then 		-- down
				if iQ2_y > 477 then
					border_collide_two <= '1';
				else
					iQ2_y <= iQ2_y +2; 
					border_collide_two <= '0';
				end if;
			elsif left_en_two = '1' then		-- left
				if iQ2_x < 4 then
					border_collide_two <= '1';
				else
					iQ2_x <= iQ2_x -2; 
					border_collide_two <= '0';
				end if;
			elsif right_en_two = '1' then		-- right
				if iQ2_x > 637 then
					border_collide_two <= '1';
				else
					iQ2_x <= iQ2_x +2; 
					border_collide_two <= '0';
				end if;
			end if;
		end if;
	end if;
end process Player_Two_Counter;

--Slow Down counter
SlowDown: process(clk, slow_en)
begin
	if rising_edge(clk) then
		slow_count <= slow_count;
		slow_flag <= '0';
		if slow_en = '1' then								-- Only count if enabled
			if slow_count = "10" then				
				slow_count <= "00";
				slow_flag <= '1';
			else
				slow_count <= slow_count + 1;
			end if;
		end if;
	
	end if;
end process SlowDown;




-- MULTIPLEXERS AND CHECKS

-- Collision Check
CheckCollision: process(iQ1_x, iQ1_y, iQ2_x, iQ2_y, player_select, border_collide_one, border_collide_two, color_in, v_video_on)
begin
	collide_one <= '0';
	collide_two <= '0';
	
	if player_select = '0' then													-- Get player 1's address for reading
		pixel_x_r <= std_logic_vector(iQ1_x);	
		pixel_y_r <= std_logic_vector(iQ1_y);
	else																					-- Get player 2's address for reading
		pixel_x_r <= std_logic_vector(iQ2_x);	
		pixel_y_r <= std_logic_vector(iQ2_y);
	end if;
	
	if v_video_on = '0' then
		if color_in = '1' or border_collide_one = '1' then					-- Check collision for player 1
			collide_one <= '1';
		else
			collide_one <= '0';
		end if;
		
		if color_in = '1' or border_collide_two = '1' then					-- Check collision for player 2
			collide_two <= '1';
		else
			collide_two <= '0';
		end if;
	end if;

end process CheckCollision;

-- Color Multiplexer
ColorMux: process(reset_game, player_select, collide_one, collide_two)
begin
	if reset_game = '1' then														-- BLACK when reset
		color_out <= BACKGROUND;
	elsif collide_one = '1' or collide_two = '1' then						-- RED when collided
		color_out <= RED;
	elsif player_select = '0' then												-- BLUE for player 1
		color_out <= PLAYER1_COLOR;
	elsif player_select = '1' then												-- GREEN for player 2
		color_out <= PLAYER2_COLOR;
	else
		color_out <= BACKGROUND;
	end if;
end process ColorMux;

-- Player Multiplexer
PlayerMux: process(reset_game, player_select, bkgd_x, bkgd_y, iQ1_x, iQ1_y, iQ2_x, iQ2_y)
begin
	if reset_game = '1' then														-- Write using background address
		pixel_x_w <= std_logic_vector(bkgd_x);	
		pixel_y_w <= std_logic_vector(bkgd_y);
	elsif player_select = '0' then												-- Write player 1's address
		pixel_x_w <= std_logic_vector(iQ1_x);	
		pixel_y_w <= std_logic_vector(iQ1_y);
	elsif player_select = '1' then 												-- Write player 2's address
		pixel_x_w <= std_logic_vector(iQ2_x);	
		pixel_y_w <= std_logic_vector(iQ2_y);
	else
		pixel_x_w <= std_logic_vector(iQ1_x);	
		pixel_y_w <= std_logic_vector(iQ1_y);
	end if;
end process PlayerMux;

-- State Update
StateUpdate: process(clk)
begin
	if rising_edge(clk) then
		curr_game_state <= next_game_state;
		curr_one_state <= next_one_state;
		curr_two_state <= next_two_state;
	end if;
end process StateUpdate;

end Behavioral;

