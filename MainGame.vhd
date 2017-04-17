----------------------------------------------------------------------------------
-- Create Date:    	12:48:29 02/26/2017 
-- Design Name: 		Connect Four Master Game Module
-- Module Name:   	MainGame - Behavioral 
-- Project Name: 		Connect Four
-- Target Devices:	Nexys 4 DDR
-- Description: 		Master module for Connect Four game - connects all outer modules for the game.
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
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
	signal p1_played : std_logic := '0';
	signal p1_wins : std_logic := '0';
	
	-- player 2 signals
	signal p2_turn : std_logic := '0';
	signal p2_play_col : std_logic_vector(2 downto 0) := (others => '0');
	-- change this back to 0 for initialization
	signal p2_played : std_logic := '0';
	signal p2_wins : std_logic := '0';
	
	signal calculation_complete : std_logic := '0';
	
	-- state machine
	type GameState is (
		ST_IDLE,
		ST_INITIALIZATION,
		ST_P1_PLAY,
		ST_P1_MOVE_INVALID,
		ST_P1_MOVE_VALID,
		ST_P2_PLAY,
		ST_CALCULATION,
		ST_GAME_OVER);
		
	signal state : GameState := ST_IDLE;
	
	-- game boards: master, p1, p2
	signal master_board : GAME_BOARD := (others => (others => '0'));
	signal p1_board : GAME_BOARD := (others => (others => '0'));
	signal p2_board : GAME_BOARD := (others => (others => '0'));
	
	-- size-7 vector that indicates the highest row that can be filled in each column (rows 0 - 5)
	signal next_valid_rows : VALID_ROWS := (others => (others => '0'));
	
	-- clock divider and annode number of 7-segment display
	signal clkDiv : std_logic_vector(31 downto 0) := (others => '0');
	constant digitPeriod : std_logic_vector(16 downto 0) := std_logic_vector(to_unsigned(20000, 17));
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
	
	-- update active-lo annode selector
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
	
	-- update active-lo cathodes
	updateCathodes : process(clk, state, annodeNum, p1_move_invalid, submit_play, sw)
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
			elsif (state = ST_P1_MOVE_VALID) then
				-- display VALID move made
				case annodeNum(2 downto 0) is
					when "111" => sseg_ca <= "1000110"; -- C
					when "110" => sseg_ca <= "1000000"; -- 0
					when "101" => sseg_ca <= "1000111"; -- L
					when "100" => sseg_ca <= "1111111"; --
					when "011" => 
						case p1_play_col(2 downto 0) is
							when "111" => sseg_ca <= "1111000"; -- 7
							when "110" => sseg_ca <= "0000010"; -- 6
							when "101" => sseg_ca <= "0010010"; -- 5
							when "100" => sseg_ca <= "0011001"; -- 4
							when "011" => sseg_ca <= "0110000"; -- 3
							when "010" => sseg_ca <= "0100100"; -- 2
							when "001" => sseg_ca <= "1001111"; -- 1
							when others => sseg_ca <= "1000000"; -- 0
						end case;
					when "010" => sseg_ca <= "1111111"; --
					when "001" => sseg_ca <= "1111111"; --
					when others => sseg_ca <= "1111111"; --
				end case;
			elsif (state = ST_P1_MOVE_INVALID) then
				-- display that move is INVALID
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
	
	-- update max-row vector
	updateValidRows : process(clk, p1_played, p2_played)
	begin
		if (rising_edge(clk)) then
			if (p1_played = '1') then
				case p1_play_col(2 downto 0) is
					when "110" =>
						if (next_valid_rows(6) < 6) then
							next_valid_rows(6) <= next_valid_rows(6) + 1;
						end if;
					when "101" =>
						if (next_valid_rows(5) < 6) then
							next_valid_rows(5) <= next_valid_rows(5) + 1;
						end if;
					when "100" =>
						if (next_valid_rows(4) < 6) then
							next_valid_rows(4) <= next_valid_rows(4) + 1;
						end if;
					when "011" =>
						if (next_valid_rows(3) < 6) then
							next_valid_rows(3) <= next_valid_rows(3) + 1;
						end if;
					when "010" =>
						if (next_valid_rows(2) < 6) then
							next_valid_rows(2) <= next_valid_rows(2) + 1;
						end if;
					when "001" =>
						if (next_valid_rows(1) < 6) then
							next_valid_rows(1) <= next_valid_rows(1) + 1;
						end if;
					when others =>
						if (next_valid_rows(0) < 6) then
							next_valid_rows(0) <= next_valid_rows(0) + 1;
						end if;
				end case;
			elsif (p2_played = '1') then
				case p2_play_col(2 downto 0) is
					when "110" =>
						if (next_valid_rows(6) < 6) then
							next_valid_rows(6) <= next_valid_rows(6) + 1;
						end if;
					when "101" =>
						if (next_valid_rows(5) < 6) then
							next_valid_rows(5) <= next_valid_rows(5) + 1;
						end if;
					when "100" =>
						if (next_valid_rows(4) < 6) then
							next_valid_rows(4) <= next_valid_rows(4) + 1;
						end if;
					when "011" =>
						if (next_valid_rows(3) < 6) then
							next_valid_rows(3) <= next_valid_rows(3) + 1;
						end if;
					when "010" =>
						if (next_valid_rows(2) < 6) then
							next_valid_rows(2) <= next_valid_rows(2) + 1;
						end if;
					when "001" =>
						if (next_valid_rows(1) < 6) then
							next_valid_rows(1) <= next_valid_rows(1) + 1;
						end if;
					when others =>
						if (next_valid_rows(0) < 6) then
							next_valid_rows(0) <= next_valid_rows(0) + 1;
						end if;
				end case;
			end if;
		end if;
	end process updateValidRows;
	
	-- used for testing ONLY - must remove
	updateP2Turn : process(clk, p2_turn)
	begin
		if (rising_edge(clk)) then
			if (p2_turn = '1') then
				p2_turn <= '0';
			end if;
		end if;
	end process updateP2Turn;
	-- used for testing ONLY - must remove
	updateP2Played : process(clk, p2_turn)
	begin
		if (rising_edge(clk)) then
			if (p2_turn = '1') then
				p2_played <= '1';
			else
				p2_played <= '0';
			end if;
		end if;
	end process updateP2Played;
	
	updateP1TurnLed : process(clk, p1_turn)
	begin
		if (rising_edge(clk)) then
			if (p1_turn = '1') then
				if (state = ST_P1_PLAY or state = ST_P1_MOVE_VALID or state = ST_P1_MOVE_INVALID) then
					p1_turn_led <= '1';
				else
					p1_turn_led <= '0';
				end if;
			else
				p1_turn_led <= '0';
			end if;
		end if;
	end process updateP1TurnLed;
	
	updateP1Board : process(clk, state, master_board)
	begin
		if (rising_edge(clk)) then
			if (state = ST_INITIALIZATION) then
				p1_board <= (others => (others => '0'));
			end if;
		end if;
	end process updateP1Board;
	
	updateP2Board : process(clk, state, master_board)
	begin
		if (rising_edge(clk)) then
			if (state = ST_INITIALIZATION) then
				p2_board <= (others => (others => '0'));
			end if;
		end if;
	end process updateP2Board;
	
	updateMasterBoard : process(clk, state, master_board)
	begin
		if (rising_edge(clk)) then
			if (state = ST_INITIALIZATION) then
				master_board <= (others => (others => '0'));
			elsif (state = ST_CALCULATION) then
				-- update all game boards with token just played
				-- if player 1 just played - update with blue token
				if (p1_turn = '0') then
					case p1_play_col(2 downto 0) is
						-- col 6
						when "110" =>
							if (master_board(0)(6) = '0') then
								master_board(0)(6) <= '1';
							elsif (master_board(1)(6) = '0') then
								master_board(1)(6) <= '1';
							elsif (master_board(2)(6) = '0') then
								master_board(2)(6) <= '1';
							elsif (master_board(3)(6) = '0') then
								master_board(3)(6) <= '1';
							elsif (master_board(4)(6) = '0') then
								master_board(4)(6) <= '1';
							elsif (master_board(5)(6) = '0') then
								master_board(5)(6) <= '1';
							end if;
						-- col 5
						when "101" =>
							if (master_board(0)(5) = '0') then
								master_board(0)(5) <= '1';
							elsif (master_board(1)(5) = '0') then
								master_board(1)(5) <= '1';
							elsif (master_board(2)(5) = '0') then
								master_board(2)(5) <= '1';
							elsif (master_board(3)(5) = '0') then
								master_board(3)(5) <= '1';
							elsif (master_board(4)(5) = '0') then
								master_board(4)(5) <= '1';
							elsif (master_board(5)(5) = '0') then
								master_board(5)(5) <= '1';
							end if;
						-- col 4
						when "100" =>
							if (master_board(0)(4) = '0') then
								master_board(0)(4) <= '1';
							elsif (master_board(1)(4) = '0') then
								master_board(1)(4) <= '1';
							elsif (master_board(2)(4) = '0') then
								master_board(2)(4) <= '1';
							elsif (master_board(3)(4) = '0') then
								master_board(3)(4) <= '1';
							elsif (master_board(4)(4) = '0') then
								master_board(4)(4) <= '1';
							elsif (master_board(5)(4) = '0') then
								master_board(5)(4) <= '1';
							end if;
						-- col 3
						when "011" =>
							if (master_board(0)(3) = '0') then
								master_board(0)(3) <= '1';
							elsif (master_board(1)(3) = '0') then
								master_board(1)(3) <= '1';
							elsif (master_board(2)(3) = '0') then
								master_board(2)(3) <= '1';
							elsif (master_board(3)(3) = '0') then
								master_board(3)(3) <= '1';
							elsif (master_board(4)(3) = '0') then
								master_board(4)(3) <= '1';
							elsif (master_board(5)(3) = '0') then
								master_board(5)(3) <= '1';
							end if;
						-- col 2
						when "010" =>
							if (master_board(0)(2) = '0') then
								master_board(0)(2) <= '1';
							elsif (master_board(1)(2) = '0') then
								master_board(1)(2) <= '1';
							elsif (master_board(2)(2) = '0') then
								master_board(2)(2) <= '1';
							elsif (master_board(3)(2) = '0') then
								master_board(3)(2) <= '1';
							elsif (master_board(4)(2) = '0') then
								master_board(4)(2) <= '1';
							elsif (master_board(5)(2) = '0') then
								master_board(5)(2) <= '1';
							end if;
						-- col 1
						when "001" =>
							if (master_board(0)(1) = '0') then
								master_board(0)(1) <= '1';
							elsif (master_board(1)(1) = '0') then
								master_board(1)(1) <= '1';
							elsif (master_board(2)(1) = '0') then
								master_board(2)(1) <= '1';
							elsif (master_board(3)(1) = '0') then
								master_board(3)(1) <= '1';
							elsif (master_board(4)(1) = '0') then
								master_board(4)(1) <= '1';
							elsif (master_board(5)(1) = '0') then
								master_board(5)(1) <= '1';
							end if;
						-- col 0
						when others =>
							if (master_board(0)(0) = '0') then
								master_board(0)(0) <= '1';
							elsif (master_board(1)(0) = '0') then
								master_board(1)(0) <= '1';
							elsif (master_board(2)(0) = '0') then
								master_board(2)(0) <= '1';
							elsif (master_board(3)(0) = '0') then
								master_board(3)(0) <= '1';
							elsif (master_board(4)(0) = '0') then
								master_board(4)(0) <= '1';
							elsif (master_board(5)(0) = '0') then
								master_board(5)(0) <= '1';
							end if;
					end case;
				-- otherwise player 2 just played - update with red token
				else
					case p2_play_col(2 downto 0) is
						-- col 6
						when "110" =>
							if (master_board(0)(6) = '0') then
								master_board(0)(6) <= '1';
							elsif (master_board(1)(6) = '0') then
								master_board(1)(6) <= '1';
							elsif (master_board(2)(6) = '0') then
								master_board(2)(6) <= '1';
							elsif (master_board(3)(6) = '0') then
								master_board(3)(6) <= '1';
							elsif (master_board(4)(6) = '0') then
								master_board(4)(6) <= '1';
							elsif (master_board(5)(6) = '0') then
								master_board(5)(6) <= '1';
							end if;
						-- col 5
						when "101" =>
							if (master_board(0)(5) = '0') then
								master_board(0)(5) <= '1';
							elsif (master_board(1)(5) = '0') then
								master_board(1)(5) <= '1';
							elsif (master_board(2)(5) = '0') then
								master_board(2)(5) <= '1';
							elsif (master_board(3)(5) = '0') then
								master_board(3)(5) <= '1';
							elsif (master_board(4)(5) = '0') then
								master_board(4)(5) <= '1';
							elsif (master_board(5)(5) = '0') then
								master_board(5)(5) <= '1';
							end if;
						-- col 4
						when "100" =>
							if (master_board(0)(4) = '0') then
								master_board(0)(4) <= '1';
							elsif (master_board(1)(4) = '0') then
								master_board(1)(4) <= '1';
							elsif (master_board(2)(4) = '0') then
								master_board(2)(4) <= '1';
							elsif (master_board(3)(4) = '0') then
								master_board(3)(4) <= '1';
							elsif (master_board(4)(4) = '0') then
								master_board(4)(4) <= '1';
							elsif (master_board(5)(4) = '0') then
								master_board(5)(4) <= '1';
							end if;
						-- col 3
						when "011" =>
							if (master_board(0)(3) = '0') then
								master_board(0)(3) <= '1';
							elsif (master_board(1)(3) = '0') then
								master_board(1)(3) <= '1';
							elsif (master_board(2)(3) = '0') then
								master_board(2)(3) <= '1';
							elsif (master_board(3)(3) = '0') then
								master_board(3)(3) <= '1';
							elsif (master_board(4)(3) = '0') then
								master_board(4)(3) <= '1';
							elsif (master_board(5)(3) = '0') then
								master_board(5)(3) <= '1';
							end if;
						-- col 2
						when "010" =>
							if (master_board(0)(2) = '0') then
								master_board(0)(2) <= '1';
							elsif (master_board(1)(2) = '0') then
								master_board(1)(2) <= '1';
							elsif (master_board(2)(2) = '0') then
								master_board(2)(2) <= '1';
							elsif (master_board(3)(2) = '0') then
								master_board(3)(2) <= '1';
							elsif (master_board(4)(2) = '0') then
								master_board(4)(2) <= '1';
							elsif (master_board(5)(2) = '0') then
								master_board(5)(2) <= '1';
							end if;
						-- col 1
						when "001" =>
							if (master_board(0)(1) = '0') then
								master_board(0)(1) <= '1';
							elsif (master_board(1)(1) = '0') then
								master_board(1)(1) <= '1';
							elsif (master_board(2)(1) = '0') then
								master_board(2)(1) <= '1';
							elsif (master_board(3)(1) = '0') then
								master_board(3)(1) <= '1';
							elsif (master_board(4)(1) = '0') then
								master_board(4)(1) <= '1';
							elsif (master_board(5)(1) = '0') then
								master_board(5)(1) <= '1';
							end if;
						-- col 0
						when others =>
							if (master_board(0)(0) = '0') then
								master_board(0)(0) <= '1';
							elsif (master_board(1)(0) = '0') then
								master_board(1)(0) <= '1';
							elsif (master_board(2)(0) = '0') then
								master_board(2)(0) <= '1';
							elsif (master_board(3)(0) = '0') then
								master_board(3)(0) <= '1';
							elsif (master_board(4)(0) = '0') then
								master_board(4)(0) <= '1';
							elsif (master_board(5)(0) = '0') then
								master_board(5)(0) <= '1';
							end if;
					end case;
				end if;
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
	end process updateMasterBoard;
	
	calculateWinner : process(clk, state, master_board)
	begin
		if (rising_edge(clk)) then
			
		end if;
	end process calculateWinner;
	
	updateTurn : process(clk, p1_played, p2_played)
	begin
		if (rising_edge(clk)) then
			if (state = ST_P1_PLAY) then
				if (p1_played = '1') then
						p1_turn <= '0';
					end if;
			elsif (state = ST_P2_PLAY) then
				if (p2_played = '1') then
						p1_turn <= '1';
					end if;
			elsif (state = ST_INITIALIZATION) then
				p1_turn <= '1';
			end if;
		end if;
	end process updateTurn;
	
	updateState : process(clk, state, game_start, calculation_complete, submit_play, p1_turn, p1_played, p1_wins, game_reset, p2_played, p2_wins)
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
						state <= ST_P1_PLAY;
					when ST_P1_PLAY =>
						if (submit_play = '1') then
							if (p1_move_invalid = '1') then
								state <= ST_P1_MOVE_INVALID;
							else
								state <= ST_P1_MOVE_VALID;
							end if;
						end if;
					when ST_P1_MOVE_INVALID =>
						if (submit_play = '0') then
								state <= ST_P1_PLAY;
						end if;
					when ST_P1_MOVE_VALID =>
						if (submit_play = '0') then
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

