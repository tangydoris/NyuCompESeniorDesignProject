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
use work.GamePackage.GAME_BOARD;

entity UserInputModule is
	port (
		-- system clock
		clk : in std_logic;
		-- switches for game board column selection
		sw : in std_logic_vector(6 downto 0);
		-- play column
		submit_play : in std_logic;
		-- input signals from master module
		turn : in  std_logic;
		-- master playing board to check for move validity
		master_board : in GAME_BOARD;
		
		-- output signals to master game module
		-- played column (0 through 7)
		play_col : out std_logic_vector(2 downto 0);
		-- play invalid
		move_invalid : out std_logic);
end UserInputModule;

architecture Behavioral of UserInputModule is
	signal play_valid : std_logic := '0';
	
	-- state machine
	type P1_STATE is (
		ST_IDLE,
		ST_PLAY);
	signal state : P1_STATE := ST_IDLE;
begin
	-- read user input if p1 is allowed to play (in the play state)
	updatePlayValid : process(clk, state, sw, master_board)
	begin
		if (rising_edge(clk)) then
			case sw(6 downto 0) is
				when "1000000" =>
					if (master_board(5)(0) = '0') then
						play_valid <= '1';
					else
						play_valid <= '0';
					end if;
				when "0100000" =>
					if (master_board(5)(1) = '0') then
						play_valid <= '1';
					else
						play_valid <= '0';
					end if;
				when "0010000" =>
					if (master_board(5)(2) = '0') then
						play_valid <= '1';
					else
						play_valid <= '0';
					end if;
				when "0001000" =>
					if (master_board(5)(3) = '0') then
						play_valid <= '1';
					else
						play_valid <= '0';
					end if;
				when "0000100" =>
					if (master_board(5)(4) = '0') then
						play_valid <= '1';
					else
						play_valid <= '0';
					end if;
				when "0000010" =>
					if (master_board(5)(5) = '0') then
						play_valid <= '1';
					else
						play_valid <= '0';
					end if;
				when "0000001" =>
					if (master_board(5)(6) = '0') then
						play_valid <= '1';
					else
						play_valid <= '0';
					end if;
				when others =>
					play_valid <= '0';
			end case;
		end if;
	end process updatePlayValid;
	
	updatePlayCol : process(clk, submit_play, play_valid)
	begin
		if (rising_edge(clk)) then
			if (submit_play = '1' and play_valid = '1') then
				case sw(6 downto 0) is
					when "0000001" =>
						-- col 7 (rightmost col)
						play_col <= "110";
					when "0000010" =>
						-- col 6
						play_col <= "101";
					when "0000100" =>
						-- col 5
						play_col <= "100";
					when "0001000" =>
						-- col 4
						play_col <= "011";
					when "0010000" =>
						-- col 3
						play_col <= "010";
					when "0100000" =>
						-- col 2
						play_col <= "001";
					when "1000000" =>
						-- col 1
						play_col <= "000";
					when others =>
						-- col 0 (leftmost col)
						play_col <= "000";
				end case;
			end if;
		end if;
	end process updatePlayCol;

	-- state machine
	updateState : process(clk, state, turn, play_valid)
	begin
		if (rising_edge(clk)) then
			case state is
				when ST_IDLE =>
					if (turn = '1') then
						state <= ST_PLAY;
					end if;
				when ST_PLAY =>
					if (submit_play = '1' and play_valid = '1') then
						state <= ST_IDLE;
					end if;
			end case;
		end if;
	end process updateState;

	-- asynchronously update invalid move signal
	with play_valid select move_invalid <=
		'0' when '1',
		'1' when others;
end Behavioral;

