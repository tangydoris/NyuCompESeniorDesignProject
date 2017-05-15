----------------------------------------------------------------------------------
-- Create Date:    	12:48:29 02/26/2017 
-- Design Name: 		Connect Four A.I. Module
-- Module Name:   	Artificial Intelligence Module - Behavioral 
-- Project Name: 		Connect Four
-- Target Devices:	Nexys 4 DDR
-- Description: 		Module for the Connect Four game that implements artificial intelligence for a machine player.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use work.GamePackage.GAME_BOARD;
use work.GamePackage.VALID_ROWS;

entity ArtificialIntelligenceModule is
	port (
		-- system clock
		clk : in std_logic;
		
		-- game boards
		master_board : in GAME_BOARD;
		p1_board : in GAME_BOARD;
		own_board : in GAME_BOARD;
		
		next_valid_rows : in VALID_ROWS;
		
		-- turn handshake
		turn : in std_logic;
		
		-- outputs to master game module
		-- played column (0 through 7)
		play_col : out std_logic_vector(2 downto 0);
		-- played handshake
		played : out std_logic
	);
end ArtificialIntelligenceModule;

architecture Behavioral of ArtificialIntelligenceModule is

	component AdjacencyChecker is
	port (
		-- system clock (?)
		clk : in std_logic;
		
		-- game boards
		opponent_board : in GAME_BOARD;
		own_board      : in GAME_BOARD;
		row            : in std_logic_vector(2 downto 0);
		column         : in std_logic_vector(2 downto 0);
		
		-- enable signal
		enable : in std_logic;
		
		player_can_win      : out std_logic;
		opp_can_win         : out std_logic;
		player_two_adjs     : out std_logic;
		player_one_adj      : out std_logic;
		-- validity signal
		ready : out std_logic
	);
	end component;
	
	signal move_calculated : std_logic := '0';
	type AI_STATE is (
		ST_IDLE,
		ST_PLAY,
		ST_CALCULATED
	);
	
	signal adjEnable : std_logic;
	
	signal state : AI_STATE := ST_IDLE;
	
	signal player_can_win_vec : std_logic_vector(6 downto 0);
	signal opp_can_win_vec    : std_logic_vector(6 downto 0);
	signal player_two_adjs_vec: std_logic_vector(6 downto 0);
	signal player_one_adj_vec : std_logic_vector(6 downto 0);
	signal adjCheck_ready_vec : std_logic_vector(6 downto 0);
	
	begin

	Inst_Column_0_AdjacencyChecker : AdjacencyChecker
	PORT MAP(
			clk            => clk,
			opponent_board => p1_board,
			own_board      => own_board,
			row            => next_valid_rows(0),
			column         => "000",
			enable         => AdjEnable,
			player_can_win => player_can_win_vec(0),
			opp_can_win    => opp_can_win_vec(0),
			player_two_adjs=> player_two_adjs_vec(0),
			player_one_adj => player_one_adj_vec(0),
			ready          => adjCheck_ready_vec(0)
			);
			
	Inst_Column_1_AdjacencyChecker : AdjacencyChecker
	PORT MAP(
	      clk            => clk,
			opponent_board => p1_board,
			own_board      => own_board,
			row            => next_valid_rows(1),
			column         => "001",
			enable         => AdjEnable,
			player_can_win => player_can_win_vec(1),
			opp_can_win    => opp_can_win_vec(1),
			player_two_adjs=> player_two_adjs_vec(1),
			player_one_adj => player_one_adj_vec(1),
			ready          => adjCheck_ready_vec(1)
			);
	
	Inst_Column_2_AdjacencyChecker : AdjacencyChecker
	PORT MAP(
			clk            => clk,
			opponent_board => p1_board,
			own_board      => own_board,
			row            => next_valid_rows(2),
			column         => "010",
			enable         => AdjEnable,
			player_can_win => player_can_win_vec(2),
			opp_can_win    => opp_can_win_vec(2),
			player_two_adjs=> player_two_adjs_vec(2),
			player_one_adj => player_one_adj_vec(2),
			ready          => adjCheck_ready_vec(2)
			);
	
	Inst_Column_3_AdjacencyChecker : AdjacencyChecker
	PORT MAP(
			clk            => clk,
			opponent_board => p1_board,
			own_board      => own_board,
			row            => next_valid_rows(3),
			column         => "011",
			enable         => AdjEnable,
			player_can_win => player_can_win_vec(3),
			opp_can_win    => opp_can_win_vec(3),
			player_two_adjs=> player_two_adjs_vec(3),
			player_one_adj => player_one_adj_vec(3),
			ready          => adjCheck_ready_vec(3)
			);
	
	Inst_Column_4_AdjacencyChecker : AdjacencyChecker
	PORT MAP(
			clk            => clk,
			opponent_board => p1_board,
			own_board      => own_board,
			row            => next_valid_rows(4),
			column         => "100",
			enable         => AdjEnable,
			player_can_win => player_can_win_vec(4),
			opp_can_win    => opp_can_win_vec(4),
			player_two_adjs=> player_two_adjs_vec(4),
			player_one_adj => player_one_adj_vec(4),
			ready          => adjCheck_ready_vec(4)
			);
	
	Inst_Column_5_AdjacencyChecker : AdjacencyChecker
	PORT MAP(
			clk            => clk,
			opponent_board => p1_board,
			own_board      => own_board,
			row            => next_valid_rows(5),
			column         => "101",
			enable         => AdjEnable,
			player_can_win => player_can_win_vec(5),
			opp_can_win    => opp_can_win_vec(5),
			player_two_adjs=> player_two_adjs_vec(5),
			player_one_adj => player_one_adj_vec(5),
			ready          => adjCheck_ready_vec(5)
			);
	
	Inst_Column_6_AdjacencyChecker : AdjacencyChecker
	PORT MAP(
			clk            => clk,
			opponent_board => p1_board,
			own_board      => own_board,
			row            => next_valid_rows(6),
			column         => "110",
			enable         => adjEnable,
			player_can_win => player_can_win_vec(6),
			opp_can_win    => opp_can_win_vec(6),
			player_two_adjs=> player_two_adjs_vec(6),
			player_one_adj => player_one_adj_vec(6),
			ready          => adjCheck_ready_vec(6)
			);
	
	
	
	updateEnable : process(state, adjEnable)
	begin
		if(state = ST_PLAY or state = ST_CALCULATED) then
			adjEnable <= '1';
		else
			adjEnable <= '0';
		end if;
	end process updateEnable;
	
	updatePlayPosition : process(clk, state, next_valid_rows, player_can_win_vec, opp_can_win_vec, player_two_adjs_vec, player_one_adj_vec)
	begin
		if(state = ST_CALCULATED) then
			if(not (player_can_win_vec = "0000000")) then
				--can win, play on that position before anything else
				if (player_can_win_vec(3) = '1' and next_valid_rows(3) < "110") then
					play_col <= "011";
				elsif(player_can_win_vec(4) = '1' and (next_valid_rows(4) < "110")) then
					play_col <= "100";
				elsif(player_can_win_vec(2) = '1' and (next_valid_rows(2) < "110")) then
					play_col <= "010";
				elsif(player_can_win_vec(5) = '1' and (next_valid_rows(5) < "110")) then
					play_col <= "101";
				elsif(player_can_win_vec(1) = '1' and (next_valid_rows(1) < "110")) then
					play_col <= "001";
				elsif(player_can_win_vec(6) = '1' and (next_valid_rows(6) < "110")) then
					play_col <= "110";
				elsif(player_can_win_vec(0) = '1' and (next_valid_rows(0) < "110")) then
					play_col <= "000";
				end if;
			elsif(not (opp_can_win_vec = "0000000")) then
				--opponent can win, must play at position to stop it
				--Note: next_valid_rows(n) = "110" denotes that row is full
				if (opp_can_win_vec(3) = '1' and next_valid_rows(3) < "110") then
					play_col <= "011";
				elsif(opp_can_win_vec(4) = '1' and (next_valid_rows(4) < "110")) then
					play_col <= "100";
				elsif(opp_can_win_vec(2) = '1' and (next_valid_rows(2) < "110")) then
					play_col <= "010";
				elsif(opp_can_win_vec(5) = '1' and (next_valid_rows(5) < "110")) then
					play_col <= "101";
				elsif(opp_can_win_vec(1) = '1' and (next_valid_rows(1) < "110")) then
					play_col <= "001";
				elsif(opp_can_win_vec(6) = '1' and (next_valid_rows(6) < "110")) then
					play_col <= "110";
				elsif(opp_can_win_vec(0) = '1' and (next_valid_rows(0) < "110")) then
					play_col <= "000";
				end if;
			elsif(not (player_two_adjs_vec = "0000000")) then
				--Play on position, netting three adjacencies
				if (player_two_adjs_vec(3) = '1' and next_valid_rows(3) < "110") then
					play_col <= "011";
				elsif(player_two_adjs_vec(4) = '1' and (next_valid_rows(4) < "110")) then
					play_col <= "100";
				elsif(player_two_adjs_vec(2) = '1' and (next_valid_rows(2) < "110")) then
					play_col <= "010";
				elsif(player_two_adjs_vec(5) = '1' and (next_valid_rows(5) < "110")) then
					play_col <= "101";
				elsif(player_two_adjs_vec(1) = '1' and (next_valid_rows(1) < "110")) then
					play_col <= "001";
				elsif(player_two_adjs_vec(6) = '1' and (next_valid_rows(6) < "110")) then
					play_col <= "110";
				elsif(player_two_adjs_vec(0) = '1' and (next_valid_rows(0) < "110")) then
					play_col <= "000";
				end if;
			elsif(not (player_one_adj_vec = "0000000")) then
				--Play on position, netting two adjacencies
				if (player_one_adj_vec(3) = '1' and next_valid_rows(3) < "110") then
					play_col <= "011";
				elsif(player_one_adj_vec(4) = '1' and (next_valid_rows(4) < "110")) then
					play_col <= "100";
				elsif(player_one_adj_vec(2) = '1' and (next_valid_rows(2) < "110")) then
					play_col <= "010";
				elsif(player_one_adj_vec(5) = '1' and (next_valid_rows(5) < "110")) then
					play_col <= "101";
				elsif(player_one_adj_vec(1) = '1' and (next_valid_rows(1) < "110")) then
					play_col <= "001";
				elsif(player_one_adj_vec(6) = '1' and (next_valid_rows(6) < "110")) then
					play_col <= "110";
				elsif(player_one_adj_vec(0) = '1' and (next_valid_rows(0) < "110")) then
					play_col <= "000";
				end if;
			else
				if (next_valid_rows(3) < "110") then
					play_col <= "011";
				elsif(next_valid_rows(4) < "110") then
					play_col <= "100";
				elsif(next_valid_rows(2) < "110") then
					play_col <= "010";
				elsif(next_valid_rows(5) < "110") then
					play_col <= "101";
				elsif(next_valid_rows(1) < "110") then
					play_col <= "001";
				elsif(next_valid_rows(6) < "110") then
					play_col <= "110";
				elsif(next_valid_rows(0) < "110") then
					play_col <= "000";
				end if;
			end if;
		else
			play_col <= "011";
		end if;
	end process updatePlayPosition;

	with adjCheck_ready_vec select
		move_calculated <=
		'1' when "1111111",
		'0' when others;
	
	updatePlayed : process(clk, state)
	begin
		if (rising_edge(clk)) then
			if (state = ST_CALCULATED) then
				played <= '1';
			else
				played <= '0';
			end if;
		end if;
	end process updatePlayed;	
	
	updateState : process(clk, state, turn, move_calculated)
	begin
		if (rising_edge(clk)) then
			case state is
				when ST_IDLE =>
					if (turn = '1') then
						state <= ST_PLAY;
					end if;
				when ST_PLAY =>
					if (move_calculated = '1') then
						state <= ST_CALCULATED;
					end if;
				when ST_CALCULATED =>
					if (turn = '0') then
						state <= ST_IDLE;
					end if;
			end case;
		end if;
	end process updateState;
end Behavioral;