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
		
		-- game state display via 7 segment display
		-- 7 cathodes (the individual segments)
		sseg_ca : out std_logic_vector(6 downto 0);
		-- 8 displays (each letter/number display)
		sseg_an : out std_logic_vector(7 downto 0)
		
		-- VGA display
--		vga_r : out std_logic_vector(3 downto 0);
--		vga_g : out std_logic_vector(3 downto 0);
--		vga_b : out std_logic_vector(3 downto 0);
--		vga_hs : out std_logic;
--		vga_vs : out std_logic
	);
end MainGame;

architecture Behavioral of MainGame is
	-- winning row
	constant WIN_R : std_logic_vector(3 downto 0) := "1111";
	
	-- player 1 signals
	signal p1_turn : std_logic := '0';
	signal p1_play_col : std_logic_vector(2 downto 0) := (others => '0');
	signal p1_move_invalid : std_logic := '0';
	signal p1_move_attempted : std_logic := '0';
	signal p1_played : std_logic := '0';
	signal p1_wins : std_logic := '0';
	
	-- player 2 signals
	signal p2_turn : std_logic := '0';
	signal p2_play_col : std_logic_vector(2 downto 0) := (others => '0');
	-- change this back to 0 for initialization
	signal p2_played : std_logic := '1';
	signal p2_wins : std_logic := '0';
	
	-- internal handshake signals
	signal initialization_complete : std_logic := '0';
	
	signal calculation_complete : std_logic := '0';
	
	-- state machine
	type GameState is (
		ST_IDLE,
		ST_INITIALIZATION,
		ST_P1_PLAY,
		ST_P1_MOVE_ATTEMPT,
		ST_P2_PLAY,
		ST_CALCULATION,
		ST_GAME_OVER);
		
	signal state : GameState := ST_IDLE;
	
	-- game boards: master, p1, p2
	signal master_board : GAME_BOARD := (others => (others => '0'));
	signal p1_board : GAME_BOARD := (others => (others => '0'));
	signal p2_board : GAME_BOARD := (others => (others => '0'));
	
	-- clock divider and annode number of 7-segment display
	signal clkDiv : std_logic_vector(31 downto 0) := (others => '0');
	constant digitPeriod : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(20000, 32));
	signal annodeNum : std_logic_vector(2 downto 0) := (others => '0');

begin
	-- map user input module component
	inputModule : UserInputModule port map(
		-- in
		clk_in => clk,
		sw_in => sw,
		submit_play_in => submit_play,
		turn_in => p1_turn,
		master_board_in => master_board,
		-- out
		play_col_out => p1_play_col,
		move_invalid_out => p1_move_invalid,
		move_attempted_out => p1_move_attempted,
		played_out => p1_played);
	
	-- map A.I. module component
--	machineModule : AiModule port map(
--		clk_in => clk,
--		master_board_in => master_board,
--		p1_board_in => p1_board,
--		own_board_in => p2_board,
--		turn_in => p2_turn,
--		play_col_out => p2_play_col,
--		played_out => p2_played);

	-- processes
	-- update clock divider
	updateClockDivider : process(clk) 
	begin
		if(rising_edge(clk)) then
			if(clkDiv = digitPeriod) then
				clkDiv <= (others => '0');
			else
				clkDiv <= clkDiv + 1;
			end if;
		end if;
	end process updateClockDivider;
	
	-- update annode number (0 to 7)
	updateAnnodeNumber : process(clk, clkDiv, annodeNum)
	begin
		if (rising_edge(clk)) then
			-- annode number only changes on every digit period
			if(clkDiv = digitPeriod) then
				if(annodeNum = "111") then
					annodeNum <= (others => '0');
				else
					annodeNum <= annodeNum + 1;
				end if;
			end if;
		end if;
	end process updateAnnodeNumber;
	
	-- update annode selector
	updateAnnodeSelector : process(clk, annodeNum)
	begin
		if (rising_edge(clk)) then
			case annodeNum(2 downto 0) is
				when "111" => sseg_an <= "01111111";
				when "110" => sseg_an <= "10111111";
				when "101" => sseg_an <= "11011111";
				when "100" => sseg_an <= "11101111";
				when "011" => sseg_an <= "11110111";
				when "010" => sseg_an <= "11111011";
				when "001" => sseg_an <= "11111101";
				when others => sseg_an <= "11111110";
			end case;
		end if;
	end process updateAnnodeSelector;
	
	-- update the 4 bits that show up on one of the 7 segment displays
	updateCathodes : process(clk, state, annodeNum, p1_move_invalid)
	begin
		if (rising_edge(clk)) then
			if (state = ST_IDLE or state = ST_INITIALIZATION) then
				case annodeNum(2 downto 0) is
					when "111" => sseg_ca <= "1000110"; -- C
					when "110" => sseg_ca <= "1000000"; -- 0
					when "101" => sseg_ca <= "1001000"; -- n
					when "100" => sseg_ca <= "1001000"; -- n
					when "011" => sseg_ca <= "0000110"; -- E
					when "010" => sseg_ca <= "1000110"; -- C
					when "001" => sseg_ca <= "0000111"; -- t
					when others => sseg_ca <= "0011001"; -- 4
				end case;
			elsif (state = ST_GAME_OVER) then
				case annodeNum(2 downto 0) is
					when "111" => sseg_ca <= "0111111"; -- -
					when "110" => sseg_ca <= "1001110"; -- r
					when "101" => sseg_ca <= "0000110"; -- E
					when "100" => sseg_ca <= "0010010"; -- S
					when "011" => sseg_ca <= "0000110"; -- E
					when "010" => sseg_ca <= "0000111"; -- t
					when "001" => sseg_ca <= "0111111"; -- -
					when others => sseg_ca <= "0111111"; -- -
				end case;
			elsif (state = ST_P1_PLAY) then
				if (p1_move_attempted = '1') then
					-- display move validity
					if (p1_move_invalid = '1') then
						case annodeNum(2 downto 0) is
							when "111" => sseg_ca <= "1001000"; -- n
							when "110" => sseg_ca <= "1000000"; -- 0
							when "101" => sseg_ca <= "0000111"; -- t
							when "100" => sseg_ca <= "1111111"; --
							when "011" => sseg_ca <= "1000001"; -- V
							when "010" => sseg_ca <= "0001000"; -- A
							when "001" => sseg_ca <= "1000111"; -- L
							when others => sseg_ca <= "1001111"; -- I
						end case;
					end if;
				else
					case annodeNum(2 downto 0) is
						when "111" => sseg_ca <= "0001100"; -- P
						when "110" => sseg_ca <= "1001111"; -- 1
						when "101" => sseg_ca <= "1111111"; -- 
						when "100" => sseg_ca <= "1111111"; -- 
						when "011" => sseg_ca <= "0001100"; -- P
						when "010" => sseg_ca <= "1000111"; -- L
						when "001" => sseg_ca <= "0001000"; -- A
						when others => sseg_ca <= "0011001"; -- Y
					end case;
				end if;
			elsif (state = ST_P2_play) then
				case annodeNum(2 downto 0) is
					when "111" => sseg_ca <= "0001100"; -- P
					when "110" => sseg_ca <= "0100100"; -- 2
					when "101" => sseg_ca <= "1111111"; -- 
					when "100" => sseg_ca <= "1111111"; -- 
					when "011" => sseg_ca <= "0001100"; -- P
					when "010" => sseg_ca <= "1000111"; -- L
					when "001" => sseg_ca <= "0001000"; -- A
					when others => sseg_ca <= "0011001"; -- Y
				end case;
			elsif (state = ST_CALCULATION) then
				case annodeNum(2 downto 0) is
					when "111" => sseg_ca <= "1000110"; -- C
					when "110" => sseg_ca <= "1000000"; -- 0
					when "101" => sseg_ca <= "1000111"; -- L
					when "100" => sseg_ca <= "1111111"; --
					when "011" => 
						case sw(6 downto 0) is
							when "1000000" => sseg_ca <= "1000000"; -- 0
							when "0100000" => sseg_ca <= "1001111"; -- 1
							when "0010000" => sseg_ca <= "0100100"; -- 2
							when "0001000" => sseg_ca <= "0110000"; -- 3
							when "0000100" => sseg_ca <= "0011001"; -- 4
							when "0000010" => sseg_ca <= "0010010"; -- 5
							when others => sseg_ca <= "0000010"; -- 6
						end case;
					when "010" => sseg_ca <= "1111111"; --
					when "001" => sseg_ca <= "1111111"; --
					when others => sseg_ca <= "1111111"; --
				end case;
			else
				-- placeholder
				case annodeNum(2 downto 0) is
					when "111" => sseg_ca <= "1000000"; -- 0
					when "110" => sseg_ca <= "1000000"; -- 0
					when "101" => sseg_ca <= "1000000"; -- 0
					when "100" => sseg_ca <= "1000000"; -- 0
					when "011" => sseg_ca <= "1000000"; -- 0
					when "010" => sseg_ca <= "1000000"; -- 0
					when "001" => sseg_ca <= "1000000"; -- 0
					when others => sseg_ca <= "1000000"; -- 0
				end case;
			end if;
		end if;
	end process updateCathodes;
	
	updateP1TurnLed : process(clk, p1_turn)
	begin
		if (rising_edge(clk)) then
			if (p1_turn = '1') then
				if (state = ST_P1_PLAY) then
					p1_turn_led <= '1';
				else
					p1_turn_led <= '0';
				end if;
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
--				if (p1_board(0)(3 downto 0) = WIN_R) then
--					p1_wins <= '1';
--				elsif (p2_board(0)(3 downto 0) = WIN_R) then
--					p2_wins <= '1';
--				end if;
				calculation_complete <= '1';
			else
				calculation_complete <= '0';
			end if;
		end if;
	end process calculateWinner;
	
	updateTurn : process(clk, p1_played, p2_played)
	begin
		if (rising_edge(clk)) then
			case state is
				when ST_P1_PLAY =>
					if (p1_played = '1') then
						p1_turn <= '0';
					end if;
				when ST_P2_PLAY =>
					if (p2_played = '1') then
						p1_turn <= '1';
					end if;
				when ST_INITIALIZATION =>
					if (initialization_complete = '1') then
						p1_turn <= '1';
					end if;
				when others =>
					-- must insert default case, just default to true for player 1's turn
					p1_turn <= '1';
			end case;
		end if;
	end process updateTurn;
	
	updateState : process(clk, state, game_start, initialization_complete, calculation_complete, p1_turn, p1_played, p1_wins, game_reset, p2_turn, p2_played, p2_wins)
	begin
		if (rising_edge(clk)) then
			if (game_reset = '1' or p1_wins = '1' or p2_wins = '1') then
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
						-- incorporate move validity display
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

