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
		sw_led : out std_logic_vector(6 downto 0);
		-- play column
		submit_play : in std_logic;
		
		p1_turn_led : out std_logic;
		p2_turn_led : out std_logic;
		
		-- game state display via 7 segment display
		-- 7 cathodes (the individual segments)
		sseg_ca : out std_logic_vector(6 downto 0);
		-- 8 displays (each letter/number display)
		sseg_an : out std_logic_vector(7 downto 0);
		
		-- VGA display
		vga_red_o : out std_logic_vector(3 downto 0);
		vga_green_o : out std_logic_vector(3 downto 0);
		vga_blue_o : out std_logic_vector(3 downto 0);
		vga_hs_o : out std_logic;
		vga_vs_o : out std_logic;
		ps2_clk : inout std_logic;
		ps2_data : inout std_logic
	);
end MainGame;

architecture Behavioral of MainGame is
	-- winning row
	constant WIN_R : std_logic_vector(3 downto 0) := "1111";
	
	-- player 1 signals
	signal p1_turn : std_logic := '0';
	signal p1_play_col : std_logic_vector(2 downto 0) := (others => '0');
	signal p1_move_invalid : std_logic := '0';
	signal p1_wins : std_logic := '0';
	
	-- player 2 signals
	signal p2_turn : std_logic := '0';
	signal p2_play_col : std_logic_vector(2 downto 0) := (others => '0');
	signal p2_played : std_logic := '0';
	signal p2_wins : std_logic := '0';
	
	signal turns_played : std_logic_vector(7 downto 0) := (others => '0');
	
	-- state machine
	type GameState is (
		ST_IDLE,
		ST_INITIALIZATION,
		ST_P1_PLAY,
		ST_P1_MOVE_INVALID,
		ST_P1_MOVE_VALID,
		ST_UPDATE_P1_BOARD,
		ST_P2_PLAY,
		ST_UPDATE_P2_BOARD,
		ST_UPDATE_MASTER_BOARD,
		ST_UPDATE_NEXT_VALID_ROWS_P1,
		ST_UPDATE_NEXT_VALID_ROWS_P2,
		ST_CALCULATION,
		ST_CHECK_FOR_WINNER,
		ST_CHECK_FOR_TIE,
		ST_GAME_RESET,
		ST_GAME_TIE,
		ST_P1_WINS,
		ST_P2_WINS);
		
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
	-- map User Input Module component
	uiModule : UserInputModule port map(
		-- in
		clk => clk,
		sw => sw,
		submit_play => submit_play,
		turn => p1_turn,
		master_board => master_board,
		-- out
		play_col => p1_play_col,
		move_invalid => p1_move_invalid
	);
	
	-- map A.I. Module component
	aiModule : ArtificialIntelligenceModule port map(
		clk => clk,
		master_board => master_board,
		p1_board => p1_board,
		own_board => p2_board,
		next_valid_rows => next_valid_rows,
		turn => p2_turn,
		play_col => p2_play_col,
		played => p2_played
	);
	
	-- map Display Module component
	vgaModule : DisplayModule port map(
		CLK_I => clk,
		VGA_HS_O => vga_hs_o,
		VGA_VS_O => vga_vs_o,
		VGA_RED_O => vga_red_o,
		VGA_BLUE_O => vga_blue_o,
		VGA_GREEN_O => vga_green_o,
		PS2_CLK => ps2_clk,
		PS2_DATA => ps2_data,
		p1_board => p1_board,
		p2_board => p2_board
	);
	
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
			elsif (state = ST_GAME_TIE) then
				case annodeNum(2 downto 0) is
					when "111" => sseg_ca <= "1001111"; -- I
					when "110" => sseg_ca <= "0000111"; -- t
					when "101" => sseg_ca <= "0010010"; -- S
					when "100" => sseg_ca <= "0001000"; -- A
					when "011" => sseg_ca <= "1111111"; -- 
					when "010" => sseg_ca <= "0000111"; -- t
					when "001" => sseg_ca <= "1001111"; -- I
					when others => sseg_ca <= "0000110"; -- E
				end case;
			elsif (state = ST_P1_WINS) then
				case annodeNum(2 downto 0) is
					when "111" => sseg_ca <= "0001100"; -- P
					when "110" => sseg_ca <= "0100100"; -- 2
					when "101" => sseg_ca <= "1111111"; --
					when "100" => sseg_ca <= "1000111"; -- L
					when "011" => sseg_ca <= "1000000"; -- 0
					when "010" => sseg_ca <= "0010010"; -- S
					when "001" => sseg_ca <= "0000111"; -- t
					when others => sseg_ca <= "1111111"; --
				end case;
			elsif (state = ST_P2_WINS) then
				case annodeNum(2 downto 0) is
					when "111" => sseg_ca <= "0001100"; -- P
					when "110" => sseg_ca <= "1001111"; -- 1
					when "101" => sseg_ca <= "1111111"; --
					when "100" => sseg_ca <= "1000111"; -- L
					when "011" => sseg_ca <= "1000000"; -- 0
					when "010" => sseg_ca <= "0010010"; -- S
					when "001" => sseg_ca <= "0000111"; -- t
					when others => sseg_ca <= "1111111"; --
				end case;
			elsif (state = ST_GAME_RESET) then
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
			elsif (state = ST_CALCULATION) then
				case annodeNum(2 downto 0) is
					when "111" => sseg_ca <= "1000110"; -- C
					when "110" => sseg_ca <= "0001000"; -- A
					when "101" => sseg_ca <= "1000111"; -- L
					when "100" => sseg_ca <= "1000110"; -- C
					when "011" => sseg_ca <= "1000001"; -- U
					when "010" => sseg_ca <= "1000111"; -- L
					when "001" => sseg_ca <= "0001000"; -- A
					when others => sseg_ca <= "0000111"; -- t
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
	
	updateSwLeds : process(clk, state, sw)
	begin
		if (rising_edge(clk)) then
			if (state = ST_P1_PLAY or state = ST_P1_MOVE_INVALID or state = ST_P1_MOVE_VALID) then
				sw_led(6 downto 0) <= sw(6 downto 0);
			else
				sw_led(6 downto 0) <= (others => '0');
			end if;
		end if;
	end process updateSwLeds;
	
	-- update max-row vector
	updateNextValidRows : process(clk, state, p2_play_col, p1_play_col)
	begin
		if (rising_edge(clk)) then
			if (state = ST_INITIALIZATION) then
				next_valid_rows(6 downto 0) <= (others => (others => '0'));
			elsif (state = ST_UPDATE_NEXT_VALID_ROWS_P1) then
				case p1_play_col(2 downto 0) is
					when "110" => -- col 6
						if (next_valid_rows(6) < 6) then
							next_valid_rows(6) <= next_valid_rows(6) + 1;
						end if;
					when "101" => -- col 5
						if (next_valid_rows(5) < 6) then
							next_valid_rows(5) <= next_valid_rows(5) + 1;
						end if;
					when "100" => -- col 4
						if (next_valid_rows(4) < 6) then
							next_valid_rows(4) <= next_valid_rows(4) + 1;
						end if;
					when "011" => -- col 3
						if (next_valid_rows(3) < 6) then
							next_valid_rows(3) <= next_valid_rows(3) + 1;
						end if;
					when "010" => -- col 2
						if (next_valid_rows(2) < 6) then
							next_valid_rows(2) <= next_valid_rows(2) + 1;
						end if;
					when "001" => -- col 1
						if (next_valid_rows(1) < 6) then
							next_valid_rows(1) <= next_valid_rows(1) + 1;
						end if;
					when "000" => -- col 0
						if (next_valid_rows(0) < 6) then
							next_valid_rows(0) <= next_valid_rows(0) + 1;
						end if;
					when others => -- do nothing
				end case;
			elsif (state = ST_UPDATE_NEXT_VALID_ROWS_P2) then
				-- player 2 just went, record player 2 col played
				case p2_play_col(2 downto 0) is
					when "110" => -- col 6
						if (next_valid_rows(6) < 6) then
							next_valid_rows(6) <= next_valid_rows(6) + 1;
						end if;
					when "101" => -- col 5
						if (next_valid_rows(5) < 6) then
							next_valid_rows(5) <= next_valid_rows(5) + 1;
						end if;
					when "100" => -- col 4
						if (next_valid_rows(4) < 6) then
							next_valid_rows(4) <= next_valid_rows(4) + 1;
						end if;
					when "011" => -- col 3
						if (next_valid_rows(3) < 6) then
							next_valid_rows(3) <= next_valid_rows(3) + 1;
						end if;
					when "010" => -- col 2
						if (next_valid_rows(2) < 6) then
							next_valid_rows(2) <= next_valid_rows(2) + 1;
						end if;
					when "001" => -- col 1
						if (next_valid_rows(1) < 6) then
							next_valid_rows(1) <= next_valid_rows(1) + 1;
						end if;
					when "000" => -- col 0
						if (next_valid_rows(0) < 6) then
							next_valid_rows(0) <= next_valid_rows(0) + 1;
						end if;
					when others => -- do nothing
				end case;
			end if;
		end if;
	end process updateNextValidRows;
	
	updateP2TurnLed : process(clk, state)
	begin
		if (rising_edge(clk)) then
			if (state = ST_P2_PLAY) then
				p2_turn_led <= '1';
			else
				p2_turn_led <= '0';
			end if;
		end if;
	end process updateP2TurnLed;
	
	updateP1TurnLed : process(clk, state)
	begin
		if (rising_edge(clk)) then
			if (state = ST_P1_PLAY or state = ST_P1_MOVE_VALID or state = ST_P1_MOVE_INVALID) then
				p1_turn_led <= '1';
			else
				p1_turn_led <= '0';
			end if;
		end if;
	end process updateP1TurnLed;
	
	updateP1Board : process(clk, state, next_valid_rows, p1_play_col)
	begin
		if (rising_edge(clk)) then
			if (state = ST_INITIALIZATION) then
				p1_board <= (others => (others => '0'));
			elsif (state = ST_UPDATE_P1_BOARD) then
				case p1_play_col(2 downto 0) is
					when "110" => -- col 6
						case next_valid_rows(6)(2 downto 0) is
							when "101" => -- row 5
								p1_board(5)(6) <= '1';
							when "100" => -- row 4
								p1_board(4)(6) <= '1';
							when "011" => -- row 3
								p1_board(3)(6) <= '1';
							when "010" => -- row 2
								p1_board(2)(6) <= '1';
							when "001" => -- row 1
								p1_board(1)(6) <= '1';
							when "000" => -- row 0
								p1_board(0)(6) <= '1';
							when others => -- do nothing
						end case;
					when "101" => -- col 5
						case next_valid_rows(5)(2 downto 0) is
							when "101" => -- row 5
								p1_board(5)(5) <= '1';
							when "100" => -- row 4
								p1_board(4)(5) <= '1';
							when "011" => -- row 3
								p1_board(3)(5) <= '1';
							when "010" => -- row 2
								p1_board(2)(5) <= '1';
							when "001" => -- row 1
								p1_board(1)(5) <= '1';
							when "000" => -- row 0
								p1_board(0)(5) <= '1';
							when others => -- do nothing
						end case;
					when "100" => -- col 4
						case next_valid_rows(4)(2 downto 0) is
							when "101" => -- row 5
								p1_board(5)(4) <= '1';
							when "100" => -- row 4
								p1_board(4)(4) <= '1';
							when "011" => -- row 3
								p1_board(3)(4) <= '1';
							when "010" => -- row 2
								p1_board(2)(4) <= '1';
							when "001" => -- row 1
								p1_board(1)(4) <= '1';
							when "000" => -- row 0
								p1_board(0)(4) <= '1';
							when others => -- do nothing
						end case;
					when "011" => -- col 3
						case next_valid_rows(3)(2 downto 0) is
							when "101" => -- row 5
								p1_board(5)(3) <= '1';
							when "100" => -- row 4
								p1_board(4)(3) <= '1';
							when "011" => -- row 3
								p1_board(3)(3) <= '1';
							when "010" => -- row 2
								p1_board(2)(3) <= '1';
							when "001" => -- row 1
								p1_board(1)(3) <= '1';
							when "000" => -- row 0
								p1_board(0)(3) <= '1';
							when others => -- do nothing
						end case;
					when "010" => -- col 2
						case next_valid_rows(2)(2 downto 0) is
							when "101" => -- row 5
								p1_board(5)(2) <= '1';
							when "100" => -- row 4
								p1_board(4)(2) <= '1';
							when "011" => -- row 3
								p1_board(3)(2) <= '1';
							when "010" => -- row 2
								p1_board(2)(2) <= '1';
							when "001" => -- row 1
								p1_board(1)(2) <= '1';
							when "000" => -- row 0
								p1_board(0)(2) <= '1';
							when others => -- do nothing
						end case;
					when "001" => -- col 1
						case next_valid_rows(1)(2 downto 0) is
							when "101" => -- row 5
								p1_board(5)(1) <= '1';
							when "100" => -- row 4
								p1_board(4)(1) <= '1';
							when "011" => -- row 3
								p1_board(3)(1) <= '1';
							when "010" => -- row 2
								p1_board(2)(1) <= '1';
							when "001" => -- row 1
								p1_board(1)(1) <= '1';
							when "000" => -- row 0
								p1_board(0)(1) <= '1';
							when others => -- do nothing
						end case;
					when "000" => -- col 0
						case next_valid_rows(0)(2 downto 0) is
							when "101" => -- row 5
								p1_board(5)(0) <= '1';
							when "100" => -- row 4
								p1_board(4)(0) <= '1';
							when "011" => -- row 3
								p1_board(3)(0) <= '1';
							when "010" => -- row 2
								p1_board(2)(0) <= '1';
							when "001" => -- row 1
								p1_board(1)(0) <= '1';
							when "000" => -- row 0
								p1_board(0)(0) <= '1';
							when others => -- do nothing
						end case;
					when others => -- do nothing
				end case;
			end if;
		end if;
	end process updateP1Board;
	
	updateP2Board : process(clk, state, p2_play_col)
	begin
		if (rising_edge(clk)) then
			if (state = ST_INITIALIZATION) then
				p2_board <= (others => (others => '0'));
			elsif (state = ST_UPDATE_P2_BOARD) then
				case p2_play_col(2 downto 0) is
					when "110" => -- col 6
						case next_valid_rows(6)(2 downto 0) is
							when "101" => -- row 5
								p2_board(5)(6) <= '1';
							when "100" => -- row 4
								p2_board(4)(6) <= '1';
							when "011" => -- row 3
								p2_board(3)(6) <= '1';
							when "010" => -- row 2
								p2_board(2)(6) <= '1';
							when "001" => -- row 1
								p2_board(1)(6) <= '1';
							when "000" => -- row 0
								p2_board(0)(6) <= '1';
							when others => -- do nothing
						end case;
					when "101" => -- col 5
						case next_valid_rows(5)(2 downto 0) is
							when "101" => -- row 5
								p2_board(5)(5) <= '1';
							when "100" => -- row 4
								p2_board(4)(5) <= '1';
							when "011" => -- row 3
								p2_board(3)(5) <= '1';
							when "010" => -- row 2
								p2_board(2)(5) <= '1';
							when "001" => -- row 1
								p2_board(1)(5) <= '1';
							when "000" => -- row 0
								p2_board(0)(5) <= '1';
							when others => -- do nothing
						end case;
					when "100" => -- col 4
						case next_valid_rows(4)(2 downto 0) is
							when "101" => -- row 5
								p2_board(5)(4) <= '1';
							when "100" => -- row 4
								p2_board(4)(4) <= '1';
							when "011" => -- row 3
								p2_board(3)(4) <= '1';
							when "010" => -- row 2
								p2_board(2)(4) <= '1';
							when "001" => -- row 1
								p2_board(1)(4) <= '1';
							when "000" => -- row 0
								p2_board(0)(4) <= '1';
							when others => -- do nothing
						end case;
					when "011" => -- col 3
						case next_valid_rows(3)(2 downto 0) is
							when "101" => -- row 5
								p2_board(5)(3) <= '1';
							when "100" => -- row 4
								p2_board(4)(3) <= '1';
							when "011" => -- row 3
								p2_board(3)(3) <= '1';
							when "010" => -- row 2
								p2_board(2)(3) <= '1';
							when "001" => -- row 1
								p2_board(1)(3) <= '1';
							when "000" => -- row 0
								p2_board(0)(3) <= '1';
							when others => -- do nothing
						end case;
					when "010" => -- col 2
						case next_valid_rows(2)(2 downto 0) is
							when "101" => -- row 5
								p2_board(5)(2) <= '1';
							when "100" => -- row 4
								p2_board(4)(2) <= '1';
							when "011" => -- row 3
								p2_board(3)(2) <= '1';
							when "010" => -- row 2
								p2_board(2)(2) <= '1';
							when "001" => -- row 1
								p2_board(1)(2) <= '1';
							when "000" => -- row 0
								p2_board(0)(2) <= '1';
							when others => -- do nothing
						end case;
					when "001" => -- col 1
						case next_valid_rows(1)(2 downto 0) is
							when "101" => -- row 5
								p2_board(5)(1) <= '1';
							when "100" => -- row 4
								p2_board(4)(1) <= '1';
							when "011" => -- row 3
								p2_board(3)(1) <= '1';
							when "010" => -- row 2
								p2_board(2)(1) <= '1';
							when "001" => -- row 1
								p2_board(1)(1) <= '1';
							when "000" => -- row 0
								p2_board(0)(1) <= '1';
							when others => -- do nothing
						end case;
					when "000" => -- col 0
						case next_valid_rows(0)(2 downto 0) is
							when "101" => -- row 5
								p2_board(5)(0) <= '1';
							when "100" => -- row 4
								p2_board(4)(0) <= '1';
							when "011" => -- row 3
								p2_board(3)(0) <= '1';
							when "010" => -- row 2
								p2_board(2)(0) <= '1';
							when "001" => -- row 1
								p2_board(1)(0) <= '1';
							when "000" => -- row 0
								p2_board(0)(0) <= '1';
							when others => -- do nothing
						end case;
					when others => -- do nothing
				end case;
			end if;
		end if;
	end process updateP2Board;
	
	updateMasterBoard : process(clk, state, p1_turn, p2_turn)
	begin
		if (rising_edge(clk)) then
			if (state = ST_INITIALIZATION) then
				master_board <= (others => (others => '0'));
			elsif (state = ST_UPDATE_MASTER_BOARD) then
				-- update all game boards with token just played
				-- if player 1 just played - update with blue token
				if (p1_turn = '0') then
					case p1_play_col(2 downto 0) is
						when "110" => -- col 6
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
						when "101" => -- col 5
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
						when "100" => -- col 4
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
						when "011" => -- col 3
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
						when "010" => -- col 2
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
						when "001" => -- col 1
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
						when others => -- col 0
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
						when "110" => -- col 6
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
						when "101" => -- col 5
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
						when "100" => -- col 4
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
						when "011" => -- col 3
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
						when "010" => -- col 2
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
						when "001" => -- col 1
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
						when others => -- col 0
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
			end if;
		end if;
	end process updateMasterBoard;
	
	updateP1Wins : process(clk, state, master_board, p1_board)
	begin
		if (rising_edge(clk)) then
			if (state = ST_INITIALIZATION) then
				p1_wins <= '0';
			elsif (state = ST_CALCULATION) then
				-- check for all rows
				-- row 0
				if (p1_board(0)(3 downto 0) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(0)(4 downto 1) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(0)(5 downto 2) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(0)(6 downto 3) = WIN_R) then
					p1_wins <= '1';
				-- row 1
				elsif (p1_board(1)(3 downto 0) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(1)(4 downto 1) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(1)(5 downto 2) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(1)(6 downto 3) = WIN_R) then
					p1_wins <= '1';
				-- row 2
				elsif (p1_board(2)(3 downto 0) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(2)(4 downto 1) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(2)(5 downto 2) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(2)(6 downto 3) = WIN_R) then
					p1_wins <= '1';
				-- row 3
				elsif (p1_board(3)(3 downto 0) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(3)(4 downto 1) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(3)(5 downto 2) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(3)(6 downto 3) = WIN_R) then
					p1_wins <= '1';
				-- row 4
				elsif (p1_board(4)(3 downto 0) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(4)(4 downto 1) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(4)(5 downto 2) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(4)(6 downto 3) = WIN_R) then
					p1_wins <= '1';
				-- row 5
				elsif (p1_board(5)(3 downto 0) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(5)(4 downto 1) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(5)(5 downto 2) = WIN_R) then
					p1_wins <= '1';
				elsif (p1_board(5)(6 downto 3) = WIN_R) then
					p1_wins <= '1';
				-- check for all columns
				-- col 0
				elsif (p1_board(0)(0) = '1' and p1_board(1)(0) = '1' and p1_board(2)(0) = '1' and p1_board(3)(0) = '1') then
					p1_wins <= '1';
				elsif (p1_board(1)(0) = '1' and p1_board(2)(0) = '1' and p1_board(3)(0) = '1' and p1_board(4)(0) = '1') then
					p1_wins <= '1';
				elsif (p1_board(2)(0) = '1' and p1_board(3)(0) = '1' and p1_board(4)(0) = '1' and p1_board(5)(0) = '1') then
					p1_wins <= '1';
				-- col 1
				elsif (p1_board(0)(1) = '1' and p1_board(1)(1) = '1' and p1_board(2)(1) = '1' and p1_board(3)(1) = '1') then
					p1_wins <= '1';
				elsif (p1_board(1)(1) = '1' and p1_board(2)(1) = '1' and p1_board(3)(1) = '1' and p1_board(4)(1) = '1') then
					p1_wins <= '1';
				elsif (p1_board(2)(1) = '1' and p1_board(3)(1) = '1' and p1_board(4)(1) = '1' and p1_board(5)(1) = '1') then
					p1_wins <= '1';
				-- col 2
				elsif (p1_board(0)(2) = '1' and p1_board(1)(2) = '1' and p1_board(2)(2) = '1' and p1_board(3)(2) = '1') then
					p1_wins <= '1';
				elsif (p1_board(1)(2) = '1' and p1_board(2)(2) = '1' and p1_board(3)(2) = '1' and p1_board(4)(2) = '1') then
					p1_wins <= '1';
				elsif (p1_board(2)(2) = '1' and p1_board(3)(2) = '1' and p1_board(4)(2) = '1' and p1_board(5)(2) = '1') then
					p1_wins <= '1';
				-- col 3
				elsif (p1_board(0)(3) = '1' and p1_board(1)(3) = '1' and p1_board(2)(3) = '1' and p1_board(3)(3) = '1') then
					p1_wins <= '1';
				elsif (p1_board(1)(3) = '1' and p1_board(2)(3) = '1' and p1_board(3)(3) = '1' and p1_board(4)(3) = '1') then
					p1_wins <= '1';
				elsif (p1_board(2)(3) = '1' and p1_board(3)(3) = '1' and p1_board(4)(3) = '1' and p1_board(5)(3) = '1') then
					p1_wins <= '1';
				-- col 4
				elsif (p1_board(0)(4) = '1' and p1_board(1)(4) = '1' and p1_board(2)(4) = '1' and p1_board(3)(4) = '1') then
					p1_wins <= '1';
				elsif (p1_board(1)(4) = '1' and p1_board(2)(4) = '1' and p1_board(3)(4) = '1' and p1_board(4)(4) = '1') then
					p1_wins <= '1';
				elsif (p1_board(2)(4) = '1' and p1_board(3)(4) = '1' and p1_board(4)(4) = '1' and p1_board(5)(4) = '1') then
					p1_wins <= '1';
				-- col 5
				elsif (p1_board(0)(5) = '1' and p1_board(1)(5) = '1' and p1_board(2)(5) = '1' and p1_board(3)(5) = '1') then
					p1_wins <= '1';
				elsif (p1_board(1)(5) = '1' and p1_board(2)(5) = '1' and p1_board(3)(5) = '1' and p1_board(4)(5) = '1') then
					p1_wins <= '1';
				elsif (p1_board(2)(5) = '1' and p1_board(3)(5) = '1' and p1_board(4)(5) = '1' and p1_board(5)(5) = '1') then
					p1_wins <= '1';
				-- col 6
				elsif (p1_board(0)(6) = '1' and p1_board(1)(6) = '1' and p1_board(2)(6) = '1' and p1_board(3)(6) = '1') then
					p1_wins <= '1';
				elsif (p1_board(1)(6) = '1' and p1_board(2)(6) = '1' and p1_board(3)(6) = '1' and p1_board(4)(6) = '1') then
					p1_wins <= '1';
				elsif (p1_board(2)(6) = '1' and p1_board(3)(6) = '1' and p1_board(4)(6) = '1' and p1_board(5)(6) = '1') then
					p1_wins <= '1';
				end if;
			end if;
		end if;
	end process updateP1Wins;
	
	updateP2Wins : process(clk, state, master_board, p2_board)
	begin
		if (rising_edge(clk)) then
			if (state = ST_INITIALIZATION) then
				p2_wins <= '0';
			elsif (state = ST_CALCULATION) then
				-- check for all rows
				-- row 0
				if (p2_board(0)(3 downto 0) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(0)(4 downto 1) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(0)(5 downto 2) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(0)(6 downto 3) = WIN_R) then
					p2_wins <= '1';
				-- row 1
				elsif (p2_board(1)(3 downto 0) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(1)(4 downto 1) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(1)(5 downto 2) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(1)(6 downto 3) = WIN_R) then
					p2_wins <= '1';
				-- row 2
				elsif (p2_board(2)(3 downto 0) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(2)(4 downto 1) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(2)(5 downto 2) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(2)(6 downto 3) = WIN_R) then
					p2_wins <= '1';
				-- row 3
				elsif (p2_board(3)(3 downto 0) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(3)(4 downto 1) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(3)(5 downto 2) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(3)(6 downto 3) = WIN_R) then
					p2_wins <= '1';
				-- row 4
				elsif (p2_board(4)(3 downto 0) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(4)(4 downto 1) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(4)(5 downto 2) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(4)(6 downto 3) = WIN_R) then
					p2_wins <= '1';
				-- row 5
				elsif (p2_board(5)(3 downto 0) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(5)(4 downto 1) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(5)(5 downto 2) = WIN_R) then
					p2_wins <= '1';
				elsif (p2_board(5)(6 downto 3) = WIN_R) then
					p2_wins <= '1';
				-- check for all columns
				-- col 0
				elsif (p2_board(0)(0) = '1' and p2_board(1)(0) = '1' and p2_board(2)(0) = '1' and p2_board(3)(0) = '1') then
					p2_wins <= '1';
				elsif (p2_board(1)(0) = '1' and p2_board(2)(0) = '1' and p2_board(3)(0) = '1' and p2_board(4)(0) = '1') then
					p2_wins <= '1';
				elsif (p2_board(2)(0) = '1' and p2_board(3)(0) = '1' and p2_board(4)(0) = '1' and p2_board(5)(0) = '1') then
					p2_wins <= '1';
				-- col 1
				elsif (p2_board(0)(1) = '1' and p2_board(1)(1) = '1' and p2_board(2)(1) = '1' and p2_board(3)(1) = '1') then
					p2_wins <= '1';
				elsif (p2_board(1)(1) = '1' and p2_board(2)(1) = '1' and p2_board(3)(1) = '1' and p2_board(4)(1) = '1') then
					p2_wins <= '1';
				elsif (p2_board(2)(1) = '1' and p2_board(3)(1) = '1' and p2_board(4)(1) = '1' and p2_board(5)(1) = '1') then
					p2_wins <= '1';
				-- col 2
				elsif (p2_board(0)(2) = '1' and p2_board(1)(2) = '1' and p2_board(2)(2) = '1' and p2_board(3)(2) = '1') then
					p2_wins <= '1';
				elsif (p2_board(1)(2) = '1' and p2_board(2)(2) = '1' and p2_board(3)(2) = '1' and p2_board(4)(2) = '1') then
					p2_wins <= '1';
				elsif (p2_board(2)(2) = '1' and p2_board(3)(2) = '1' and p2_board(4)(2) = '1' and p2_board(5)(2) = '1') then
					p2_wins <= '1';
				-- col 3
				elsif (p2_board(0)(3) = '1' and p2_board(1)(3) = '1' and p2_board(2)(3) = '1' and p2_board(3)(3) = '1') then
					p2_wins <= '1';
				elsif (p2_board(1)(3) = '1' and p2_board(2)(3) = '1' and p2_board(3)(3) = '1' and p2_board(4)(3) = '1') then
					p2_wins <= '1';
				elsif (p2_board(2)(3) = '1' and p2_board(3)(3) = '1' and p2_board(4)(3) = '1' and p2_board(5)(3) = '1') then
					p2_wins <= '1';
				-- col 4
				elsif (p2_board(0)(4) = '1' and p2_board(1)(4) = '1' and p2_board(2)(4) = '1' and p2_board(3)(4) = '1') then
					p2_wins <= '1';
				elsif (p2_board(1)(4) = '1' and p2_board(2)(4) = '1' and p2_board(3)(4) = '1' and p2_board(4)(4) = '1') then
					p2_wins <= '1';
				elsif (p2_board(2)(4) = '1' and p2_board(3)(4) = '1' and p2_board(4)(4) = '1' and p2_board(5)(4) = '1') then
					p2_wins <= '1';
				-- col 5
				elsif (p2_board(0)(5) = '1' and p2_board(1)(5) = '1' and p2_board(2)(5) = '1' and p2_board(3)(5) = '1') then
					p2_wins <= '1';
				elsif (p2_board(1)(5) = '1' and p2_board(2)(5) = '1' and p2_board(3)(5) = '1' and p2_board(4)(5) = '1') then
					p2_wins <= '1';
				elsif (p2_board(2)(5) = '1' and p2_board(3)(5) = '1' and p2_board(4)(5) = '1' and p2_board(5)(5) = '1') then
					p2_wins <= '1';
				-- col 6
				elsif (p2_board(0)(6) = '1' and p2_board(1)(6) = '1' and p2_board(2)(6) = '1' and p2_board(3)(6) = '1') then
					p2_wins <= '1';
				elsif (p2_board(1)(6) = '1' and p2_board(2)(6) = '1' and p2_board(3)(6) = '1' and p2_board(4)(6) = '1') then
					p2_wins <= '1';
				elsif (p2_board(2)(6) = '1' and p2_board(3)(6) = '1' and p2_board(4)(6) = '1' and p2_board(5)(6) = '1') then
					p2_wins <= '1';
				end if;
			end if;
		end if;
	end process updateP2Wins;
	
	updateTurnsPlayed : process(clk, state)
	begin
		if (rising_edge(clk)) then
			if (state = ST_INITIALIZATION) then
				turns_played <= (others => '0');
			elsif (state = ST_UPDATE_P1_BOARD) then
				turns_played <= turns_played + 1;
			elsif (state = ST_UPDATE_P2_BOARD) then
				turns_played <= turns_played + 1;
			end if;
		end if;
	end process updateTurnsPlayed;
	
	updateP1Turn : process(clk, state)
	begin
		if (rising_edge(clk)) then
			if (state = ST_P1_MOVE_VALID) then
				p1_turn <= '0';
			elsif (state = ST_P2_PLAY) then
				if (p2_played = '1') then
					p1_turn <= '1';
				end if;
			elsif (state = ST_INITIALIZATION) then
				p1_turn <= '1';
			end if;
		end if;
	end process updateP1Turn;
	
	updateP2Turn : process(clk, state)
	begin
		if (rising_edge(clk)) then
			if (state = ST_P2_PLAY) then
				p2_turn <= '1';
			else
				p2_turn <= '0';
			end if;
		end if;
	end process updateP2Turn;
	
	updateState : process(clk, state, game_start, submit_play, p1_turn, p1_wins, game_reset, p2_played, p2_wins, turns_played)
	begin
		if (rising_edge(clk)) then
			if (game_reset = '1') then
				state <= ST_GAME_RESET;
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
							state <= ST_UPDATE_P1_BOARD;
						end if;
					when ST_UPDATE_P1_BOARD =>
						state <= ST_UPDATE_NEXT_VALID_ROWS_P1;
					when ST_UPDATE_NEXT_VALID_ROWS_P1 =>
						state <= ST_UPDATE_MASTER_BOARD;
					when ST_P2_PLAY =>
						if (p2_played = '1') then
							state <= ST_UPDATE_P2_BOARD;
						end if;
					when ST_UPDATE_P2_BOARD =>
						state <= ST_UPDATE_NEXT_VALID_ROWS_P2;
					when ST_UPDATE_NEXT_VALID_ROWS_P2 =>
						state <= ST_UPDATE_MASTER_BOARD;
					when ST_UPDATE_MASTER_BOARD =>
						state <= ST_CALCULATION;
					when ST_CALCULATION =>
						state <= ST_CHECK_FOR_WINNER;
					when ST_CHECK_FOR_WINNER =>
						if (p1_wins = '1') then
							state <= ST_P1_WINS;
						elsif (p2_wins = '1') then
							state <= ST_P2_WINS;
						elsif (turns_played = 42) then
							-- if the maximum number of turns is achieved without a winner,
							-- then the game ends in a tie
							state <= ST_GAME_TIE;
						else
							if (p1_turn = '1') then
								state <= ST_P1_PLAY;
							else
								state <= ST_P2_PLAY;
							end if;
						end if;
					when ST_GAME_RESET =>
						state <= ST_INITIALIZATION;
					when ST_GAME_TIE =>
						if (game_start = '1') then
							state <= ST_INITIALIZATION;
						end if;
					when ST_P1_WINS =>
						if (game_start = '1') then
							state <= ST_INITIALIZATION;
						end if;
					when ST_P2_WINS =>
						if (game_start = '1') then
							state <= ST_INITIALIZATION;
						end if;
					when others =>
						state <= ST_IDLE;
				end case;
			end if;
		end if;
	end process updateState;
	
end Behavioral;
