----------------------------------------------------------------------------------
-- Create Date:    	12:48:29 02/26/2017 
-- Design Name: 		Connect Four User Input Mapping Module
-- Module Name:   	UserInputModule - Behavioral 
-- Project Name: 		Connect Four
-- Target Devices:	Nexys 4 DDR
-- Description: 		User input mapping module for Connect Four game - maps user input on switches and buttons to actions in the game.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use workspace.GamePackage.GAME_BOARD;

entity UserInputModule is
	port (
		-- system clock
		clk_in : in std_logic;
		-- game over/reset
		game_reset_in : in std_logic;
		-- switches for game board column selection
		sw_in : in std_logic_vector(6 downto 0);
		-- play column
		submit_play_in : in std_logic;
		-- input signals from master module
		p1_turn_in : in  std_logic;
		-- master playing board to check for move validity
		master_board_in : in GAME_BOARD;
		
		-- output signals to master module
		-- played column (o through 7)
		p1_play_col_out : out std_logic_vector(2 downto 0);
		-- played handshake
		p1_played_out : out std_logic;
		-- ended game
		p1_ends_game_out : out std_logic);
end UserInputModule;

architecture Behavioral of UserInputModule is
	signal play_valid : std_logic := '0';
	
	-- state machine
	type P1_STATE is (
		ST_IDLE,
		ST_END_GAME,
		ST_PLAY);
	signal state : P1_STATE := ST_IDLE;
begin
	-- read user input if p1 is allowed to play (in the play state)
	updatePlayValid : process(clk_in, state, submit_play_in, sw_in, master_board_in)
	begin
		if (rising_edge(clk_in)) then
			if (state = ST_PLAY and submit_play_in = '1') then
				case sw_in(6 downto 0) is
					when "1000000" =>
						if (master_board_in(5)(0) = '0') then
							play_valid <= '1';
						end if;
					when "0100000" =>
						if (master_board_in(5)(1) = '0') then
							play_valid <= '1';
						end if;
					when "0010000" =>
						if (master_board_in(5)(2) = '0') then
							play_valid <= '1';
						end if;
					when "0001000" =>
						if (master_board_in(5)(3) = '0') then
							play_valid <= '1';
						end if;
					when "0000100" =>
						if (master_board_in(5)(4) = '0') then
							play_valid <= '1';
						end if;
					when "0000010" =>
						if (master_board_in(5)(5) = '0') then
							play_valid <= '1';
						end if;
					when "0000001" =>
						if (master_board_in(5)(6) = '0') then
							play_valid <= '1';
						end if;
					when others =>
						play_valid <= '0';
				end case;
			else
				play_valid <= '0';
			end if;
		end if;
	end process updatePlayValid;
	
	updatePlayCol : process(clk_in, state, play_valid)
	begin
		if (rising_edge(clk_in)) then
			if (state = ST_PLAY and play_valid = '1') then
				case sw_in(6 downto 0) is
					when "1000000" =>
						p1_play_col_out <= "000";
					when "0100000" =>
						p1_play_col_out <= "001";
					when "0010000" =>
						p1_play_col_out <= "010";
					when "0001000" =>
						p1_play_col_out <= "011";
					when "0000100" =>
						p1_play_col_out <= "100";
					when "0000010" =>
						p1_play_col_out <= "101";
					when "0000001" =>
						p1_play_col_out <= "110";
					when others =>
						p1_play_col_out <= "000";
				end case;
			else
				p1_play_col_out <= "000";
			end if;
		end if;
	end process updatePlayCol;
	
	updateP1Played : process(clk_in, state, play_valid)
	begin
		if (rising_edge(clk_in)) then
			if (state = ST_IDLE and play_valid = '1') then
				p1_played_out <= '1';
			else
				p1_played_out <= '0';
			end if;
		end if;
	end process updateP1Played;
	
	updateP1EndsGame : process(clk_in, game_reset_in)
	begin
		if (rising_edge(clk_in)) then
			if (game_reset_in = '1') then
				p1_ends_game_out <= '1';
			else
				p1_ends_game_out <= '0';
			end if;
		end if;
	end process updateP1EndsGame;

	-- state machine
	updateState : process(clk_in, state, p1_turn_in, game_reset_in, play_valid)
	begin
		if (rising_edge(clk_in)) then
			if (game_reset_in = '1') then
				state <= ST_END_GAME;
			else
				case state is
					when ST_IDLE =>
						if (p1_turn_in = '1') then
							state <= ST_PLAY;
						end if;
					when ST_PLAY =>
						if (play_valid = '1') then
							state <= ST_IDLE;
						end if;
					when ST_END_GAME =>
						state <= ST_IDLE;
				end case;
			end if;
		end if;
	end process updateState;
	
end Behavioral;

