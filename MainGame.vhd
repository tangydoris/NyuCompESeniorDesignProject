----------------------------------------------------------------------------------
-- Create Date:    	12:48:29 02/26/2017 
-- Design Name: 		Connect Four Master Game Module
-- Module Name:   	MainGame - Behavioral 
-- Project Name: 		Connect Four
-- Target Devices:	Nexys 4 DDR
-- Description: 		Master module for Connect Four game - connects all outer modules for the game.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use work.GamePackage.all;

entity MainGame is
	port (
		-- system clock
		clk : in std_logic;
		-- game over/reset
		game_reset : in std_logic;
		-- start game
		game_start : in std_logic;
		
		-- user input mapping signals
		-- switches for game board column selection
		sw : in std_logic_vector(6 downto 0);
		-- play column
		submit_play : in std_logic;
		p1_turn_led : out std_logic;
		
		-- VGA display
		vga_r : out std_logic_vector(3 downto 0);
		vga_g : out std_logic_vector(3 downto 0);
		vga_b : out std_logic_vector(3 downto 0);
		vga_hs : out std_logic;
		vga_vs : out std_logic);
end MainGame;

architecture Behavioral of MainGame is
	-- winning row
	constant WIN_R : std_logic_vector(3 downto 0) := "1111";
	
	-- player 1 signals
	signal p1_turn : std_logic := '0';
	signal p1_play_col : std_logic_vector(2 downto 0) := (others => '0');
	signal p1_played : std_logic := '0';
	signal p1_ends_game : std_logic := '0';
	signal p1_wins : std_logic := '0';
	
	-- player 2 signals
	signal p2_turn : std_logic := '0';
	signal p2_play_col : std_logic_vector(2 downto 0) := (others => '0');
	signal p2_played : std_logic := '0';
	signal p2_wins : std_logic := '0';
	
	-- internal handshake signals
	signal initialization_complete : std_logic := '0';
	
	signal calculation_complete : std_logic := '0';
	
	-- state machine
	type GameState is (
		ST_IDLE,
		ST_INITIALIZATION,
		ST_P1_PLAY,
		ST_P2_PLAY,
		ST_CALCULATION,
		ST_GAME_OVER);
		
	signal state : GameState := ST_IDLE;
	
	-- game boards: master, p1, p2
	signal master_board : GAME_BOARD := (others => (others => '0'));
	signal p1_board : GAME_BOARD := (others => (others => '0'));
	signal p2_board : GAME_BOARD := (others => (others => '0'));
begin
	inputModule : UserInputModule port map(
		clk_in => clk,
		game_reset_in => game_reset,
		sw_in => sw,
		submit_play_in => submit_play,
		p1_turn_in => p1_turn,
		master_board_in => master_board,
		p1_play_col_out => p1_play_col,
		p1_played_out => p1_played,
		p1_ends_game_out => p1_ends_game);

	updateP1TurnLed : process(clk, p1_turn)
	begin
		if (rising_edge(clk)) then
			if (p1_turn = '1') then
				p1_turn_led <= '1';
			else
				p1_turn_led <= '0';
			end if;
		end if;
	end process updateP1TurnLed;
	
	initializeBoards : process(clk, state)
	begin
		if (rising_edge(clk)) then
			if (state = ST_INITIALIZATION) then
				master_board <= (others => (others => '0'));
				p1_board <= (others => (others => '0'));
				p2_board <= (others => (others => '0'));
				initialization_complete <= '1';
			else
				initialization_complete <= '0';
			end if;
		end if;
	end process initializeBoards;
	
	calculateWinner : process(clk, state, master_board)
	begin
		if (rising_edge(clk)) then
			if (state = ST_CALCULATION) then
				-- ** INSERT BOARD CALCULATIONS HERE **
				-- ** currently, player with 4 tokens in positions A0-D0 wins **
				if (p1_board(0)(3 downto 0) = WIN_R) then
					p1_wins <= '1';
				elsif (p2_board(0)(3 downto 0) = WIN_R) then
					p2_wins <= '1';
				end if;
				calculation_complete <= '1';
			else
				calculation_complete <= '0';
			end if;
		end if;
	end process calculateWinner;
	
	updateTurn : process(clk, p1_played, p2_played)
	begin
		if (rising_edge(clk)) then
			if (p1_played = '1') then
				p1_turn <= '0';
			elsif (p2_played = '1') then
				p1_turn <= '1';
			end if;
		end if;
	end process updateTurn;
	
	updateState : process(clk, state, game_start, initialization_complete, calculation_complete, p1_turn, p1_played, p1_wins, p1_ends_game, p2_turn, p2_played, p2_wins)
	begin
		if (rising_edge(clk)) then
			if (p1_ends_game = '1' or p1_wins = '1' or p2_wins = '1') then
				state <= ST_GAME_OVER;
			else
				case state is
					when ST_IDLE =>
						if (game_start = '1') then
							state <= ST_INITIALIZATION;
						end if;
					when ST_INITIALIZATION =>
						if (initialization_complete = '1') then
							state <= ST_P1_play;
						end if;
					when ST_P1_PLAY =>
						if (p1_played = '1') then
							state <= ST_CALCULATION;
						end if;
					when ST_P2_PLAY =>
						if (p2_played = '1') then
							state <= ST_CALCULATION;
						end if;
					when ST_CALCULATION =>
						if (calculation_complete = '1') then
							if (p1_turn = '1') then
								state <= ST_P1_PLAY;
							else
								state <= ST_P2_play;
							end if;
						end if;
					when ST_GAME_OVER =>
						state <= ST_IDLE;
					when others =>
						state <= ST_IDLE;
				end case;
			end if;
		end if;
	end process updateState;

end Behavioral;

