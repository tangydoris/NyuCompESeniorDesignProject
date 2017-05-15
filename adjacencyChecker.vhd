----------------------------------------------------------------------------------
-- Create Date:    	12:48:29 02/26/2017 
-- Design Name: 		Connect Four A.I. Module
-- Module Name:   	Artificial Intelligence Module - Behavioral 
-- Project Name: 		Connect Four
-- Target Devices:	Nexys 4 DDR
-- Description: 		Module for the Connect Four game that implements artificial intelligence for a machine player.
----------------------------------------------------------------------------------

--Given a matrix, calculates the largest line of pieces that exists.
--Outputs a true/false bit, as well as 
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use work.GamePackage.GAME_BOARD;

entity AdjacencyChecker is
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
end AdjacencyChecker;

architecture Behavioral of AdjacencyChecker is

	type AI_STATE is (
		ST_IDLE,
		ST_GATHER,
		ST_CALCULATE,
		ST_JOIN,
		ST_DONE
	);
	
	signal rowAsInt      : integer;
	signal columnAsInt   : integer;
	
	signal rowMinusThree : integer;
	signal rowMinusTwo   : integer;
	signal rowMinusOne   : integer;
	
	signal rowPlusOne    : integer;
	signal rowPlusTwo    : integer;
	signal rowPlusThree  : integer;
	
	signal columnMinusThree : integer;
	signal columnMinusTwo   : integer;
	signal columnMinusOne   : integer;
	
	signal columnPlusOne    : integer;
	signal columnPlusTwo    : integer;
	signal columnPlusThree  : integer;
	
	signal state: AI_STATE := ST_IDLE;
	
	signal oppThreeAdjsHoriz : std_logic_vector(3 downto 0);
	signal oppThreeAdjsVert  : std_logic;
	signal oppThreeAdjsTopRightDiag : std_logic_vector(3 downto 0);
	signal oppThreeAdjsTopLeftDiag  : std_logic_vector(3 downto 0);
	
	--13 possible combinations of 3
	type ADJ_BASKET is array(12 downto 0) of std_logic_vector(2 downto 0);
	
	signal playerAdjsArray : ADJ_BASKET;
	signal playerThreeAdjsVec : std_logic_vector(12 downto 0);
	signal playerTwoAdjsVec   : std_logic_vector(12 downto 0);
	signal playerOneAdjVec   : std_logic_vector(12 downto 0);

begin


	rowAsInt         <= conv_integer(row);
	columnAsInt      <= conv_integer(column);

	rowMinusThree    <= conv_integer(row) - 3;
	rowMinusTwo      <= conv_integer(row) - 2;
	rowMinusOne      <= conv_integer(row) - 1;
	
	rowPlusOne       <= conv_integer(row) + 1;
	rowPlusTwo       <= conv_integer(row) + 2;
	rowPlusThree     <= conv_integer(row) + 3;
	
	columnMinusThree <= conv_integer(column) - 3;
	columnMinusTwo   <= conv_integer(column) - 2;
	columnMinusOne   <= conv_integer(column) - 1;
	
	columnPlusOne    <= conv_integer(column) + 1;
	columnPlusTwo    <= conv_integer(column) + 2;
	columnPlusThree  <= conv_integer(column) + 3;

	--opponent adjacency check
	checkOpponent : process(clk, state, column, oppThreeAdjsHoriz, oppThreeAdjsVert, oppThreeAdjsTopRightDiag, oppThreeAdjsTopLeftDiag)
	begin
		if (rising_edge(clk)) then
			if(state = ST_CALCULATE) then
				--horizontal checks
				if(column >= "011" and 
				(opponent_board(rowAsInt)(columnMinusThree) = '1') and (opponent_board(rowAsInt)(columnMinusTwo) = '1') and
				(opponent_board(rowAsInt)(columnMinusOne) = '1')) then
					oppThreeAdjsHoriz(0) <= '1';
				else
					oppThreeAdjsHoriz(0) <= '0';
				end if;
				
				if(column >= "010" and column <= "101" and 
				(opponent_board(rowAsInt)(columnMinusTwo) = '1') and (opponent_board(rowAsInt)(columnMinusOne) = '1') and 
				(opponent_board(rowAsInt)(columnPlusOne) = '1')) then
					oppThreeAdjsHoriz(1) <= '1';
				else
					oppThreeAdjsHoriz(1) <= '0';
				end if;
				
				if(column >=  "001" and column <= "100" and 
				(opponent_board(rowAsInt)(columnMinusOne) = '1') and (opponent_board(rowAsInt)(columnPlusOne) = '1') and 
				(opponent_board(rowAsInt)(columnPlusTwo) = '1')) then
					oppThreeAdjsHoriz(2) <= '1';
				else
					oppThreeAdjsHoriz(2) <= '0';
				end if;
				
				if(column <= "011" and
				(opponent_board(rowAsInt)(columnPlusOne) = '1') and (opponent_board(rowAsInt)(columnPlusTwo) = '1') and 
				(opponent_board(rowAsInt)(columnPlusThree) = '1')) then
					oppThreeAdjsHoriz(3) <= '1';
				else
					oppThreeAdjsHoriz(3) <= '0';
				end if;
				
				--vertical checks
				if(row >= "011" and
				(opponent_board(rowMinusOne)(columnAsInt) = '1') and (opponent_board(rowMinusTwo)(columnAsInt) = '1') and
				(opponent_board(rowMinusThree)(columnAsInt) = '1')) then
					oppThreeAdjsVert <= '1';
				else
					oppThreeAdjsVert <= '0';
				end if;
				
				--top-right diagonal checks
				if(row >= "011" and column >= "011" and
				(opponent_board(rowMinusThree)(columnMinusThree) = '1') and (opponent_board(rowMinusTwo)(columnMinusTwo) = '1') and
				(opponent_board(rowMinusOne)(columnMinusOne) = '1')) then
					oppThreeAdjsTopRightDiag(0) <= '1';
				else
					oppThreeAdjsTopRightDiag(0) <= '0';
				end if;
				
				if(row >= "010" and row <= "101" and column >= "010" and column <= "101" and
				(opponent_board(rowMinusTwo)(columnMinusTwo) = '1') and (opponent_board(rowMinusOne)(columnMinusOne) = '1') and
				(opponent_board(rowPlusOne)(columnPlusOne) = '1')) then
					oppThreeAdjsTopRightDiag(1) <= '1';
				else
					oppThreeAdjsTopRightDiag(1) <= '0';
				end if;
				
				if(row >= "001" and row <= "100" and column >=  "001" and column <= "100" and
				(opponent_board(rowMinusOne)(columnMinusOne) = '1') and (opponent_board(rowPlusOne)(columnPlusOne) = '1') and
				(opponent_board(rowPlusTwo)(columnPlusTwo) = '1')) then
					oppThreeAdjsTopRightDiag(2) <= '1';
				else
					oppThreeAdjsTopRightDiag(2) <= '0';
				end if;
				
				if(row <= "011" and column >= "011" and
				(opponent_board(rowPlusOne)(columnMinusOne) = '1') and (opponent_board(rowPlusTwo)(columnPlusTwo) = '1') and
				(opponent_board(rowPlusThree)(columnPlusThree) = '1')) then
					oppThreeAdjsTopRightDiag(3) <= '1';
				else
					oppThreeAdjsTopRightDiag(3) <= '0';
				end if;
				
				--top-left diagonal checks
				if(row <= "011" and column >= "011" and
				(opponent_board(rowMinusThree)(columnMinusThree) = '1') and (opponent_board(rowMinusTwo)(columnMinusTwo) = '1') and
				(opponent_board(rowMinusOne)(columnMinusOne) = '1')) then
					oppThreeAdjsTopLeftDiag(0) <= '1';
				else
					oppThreeAdjsTopLeftDiag(0) <= '0';
				end if;
				
				if(row >= "001" and row <= "100" and column >= "010" and column <= "101" and
				(opponent_board(rowMinusTwo)(columnMinusTwo) = '1') and (opponent_board(rowMinusOne)(columnMinusOne) = '1') and
				(opponent_board(rowPlusOne)(columnPlusOne) = '1')) then
					oppThreeAdjsTopLeftDiag(1) <= '1';
				else
					oppThreeAdjsTopLeftDiag(1) <= '0';
				end if;
				
				if(row >= "010" and row <= "101" and column >=  "001" and column <= "100" and
				(opponent_board(rowMinusOne)(columnMinusOne) = '1') and (opponent_board(rowPlusOne)(columnPlusOne) = '1') and
				(opponent_board(rowPlusTwo)(columnPlusTwo) = '1')) then
					oppThreeAdjsTopLeftDiag(2) <= '1';
				else
					oppThreeAdjsTopLeftDiag(2) <= '0';
				end if;
				
				if(row >= "011" and column <= "011" and
				(opponent_board(rowPlusOne)(columnPlusOne) = '1') and (opponent_board(rowPlusTwo)(columnPlusTwo) = '1') and
				(opponent_board(rowPlusThree)(columnPlusThree) = '1')) then
					oppThreeAdjsTopLeftDiag(3) <= '1';
				else
					oppThreeAdjsTopLeftDiag(3) <= '0';
				end if;
			
			elsif(state = ST_CALCULATE) then
				if (oppThreeAdjsHoriz = "0000" AND oppThreeAdjsVert = '0' AND oppThreeAdjsTopRightDiag = "0000" and oppThreeAdjsTopLeftDiag = "0000") then
					opp_can_win <= '0';
				else
					opp_can_win <= '1';
				end if;
			end if;
		end if;
	end process checkOpponent;
	
	calculateOwnAdjs : process(clk, state, playerAdjsArray)
	begin
		if(rising_edge(clk)) then
			if(state = ST_CALCULATE) then
				if(playerAdjsArray(0) = "111") then
					playerThreeAdjsVec(0) <= '1';
				else
					playerThreeAdjsVec(0) <= '0';
				end if;
		
				if ((playerAdjsArray(0) = "110") or (playerAdjsArray(0) = "101") or (playerAdjsArray(0) = "011")) then
					playerTwoAdjsVec(0) <= '1';
				else
					playerTwoAdjsVec(0) <= '0';
				end if;
		
				if ((playerAdjsArray(0) = "100") or (playerAdjsArray(0) = "010") or (playerAdjsArray(0) = "001")) then
					playerOneAdjVec(0) <= '1';
				else
					playerOneAdjVec(0) <= '0';
				end if;	
				
				if(playerAdjsArray(1) = "111") then
					playerThreeAdjsVec(1) <= '1';
				else
					playerThreeAdjsVec(1) <= '0';
				end if;
		
				if ((playerAdjsArray(1) = "110") or (playerAdjsArray(1) = "101") or (playerAdjsArray(1) = "011")) then
					playerTwoAdjsVec(1) <= '1';
				else
					playerTwoAdjsVec(1) <= '0';
				end if;
		
				if ((playerAdjsArray(1) = "100") or (playerAdjsArray(1) = "010") or (playerAdjsArray(1) = "001")) then
					playerOneAdjVec(1) <= '1';
				else
					playerOneAdjVec(1) <= '0';
				end if;
				
				if(playerAdjsArray(2) = "111") then
					playerThreeAdjsVec(2) <= '1';
				else
					playerThreeAdjsVec(2) <= '0';
				end if;
		
				if ((playerAdjsArray(2) = "110") or (playerAdjsArray(2) = "101") or (playerAdjsArray(2) = "011")) then
					playerTwoAdjsVec(2) <= '1';
				else
					playerTwoAdjsVec(2) <= '0';
				end if;
		
				if ((playerAdjsArray(2) = "100") or (playerAdjsArray(2) = "010") or (playerAdjsArray(2) = "001")) then
					playerOneAdjVec(2) <= '1';
				else
					playerOneAdjVec(2) <= '0';
				end if;
				
				-- (3)
				
				if(playerAdjsArray(3) = "111") then
					playerThreeAdjsVec(3) <= '1';
				else
					playerThreeAdjsVec(3) <= '0';
				end if;
		
				if ((playerAdjsArray(3) = "110") or (playerAdjsArray(3) = "101") or (playerAdjsArray(3) = "011")) then
					playerTwoAdjsVec(3) <= '1';
				else
					playerTwoAdjsVec(3) <= '0';
				end if;
		
				if ((playerAdjsArray(3) = "100") or (playerAdjsArray(3) = "010") or (playerAdjsArray(3) = "001")) then
					playerOneAdjVec(3) <= '1';
				else
					playerOneAdjVec(3) <= '0';
				end if;
				
				-- (4)
				
				if(playerAdjsArray(4) = "111") then
					playerThreeAdjsVec(4) <= '1';
				else
					playerThreeAdjsVec(4) <= '0';
				end if;
		
				if ((playerAdjsArray(4) = "110") or (playerAdjsArray(4) = "101") or (playerAdjsArray(4) = "011")) then
					playerTwoAdjsVec(4) <= '1';
				else
					playerTwoAdjsVec(4) <= '0';
				end if;
		
				if ((playerAdjsArray(4) = "100") or (playerAdjsArray(4) = "010") or (playerAdjsArray(4) = "001")) then
					playerOneAdjVec(4) <= '1';
				else
					playerOneAdjVec(4) <= '0';
				end if;
			end if;
		end if;
	end process;

	--own adjacency calculation
	checkPlayer : process(clk, state, column, playerAdjsArray)
	begin
		if(rising_edge(clk)) then
			if(state = ST_GATHER) then
				if(column >= "011") then
					playerAdjsArray(0) <= own_board(rowAsInt)(columnMinusThree) & own_board(rowAsInt)(columnMinusTwo) & 
					own_board(rowAsInt)(columnMinusOne);
				else
					playerAdjsArray(0) <= "000";
				end if;
				
				if(column >= "010" and column <= "101" ) then
					playerAdjsArray(1) <= own_board(rowAsInt)(columnMinusTwo) & own_board(rowAsInt)(columnMinusOne) & 
					own_board(rowAsInt)(columnPlusOne);
				else
					playerAdjsArray(1) <= "000";
				end if;
				
				if(column >=  "001" and column <= "100") then
					playerAdjsArray(2) <= own_board(rowAsInt)(columnMinusOne) & own_board(rowAsInt)(columnPlusOne) & 
					own_board(rowAsInt)(columnPlusTwo);
				else
					playerAdjsArray(2) <= "000";
				end if;
				
				if(column <= "011") then
					playerAdjsArray(3) <= own_board(rowAsInt)(columnPlusOne) & own_board(rowAsInt)(columnPlusTwo) & 
					own_board(rowAsInt)(columnPlusThree);
				else
					playerAdjsArray(3) <= "000";
				end if;
				
				--vertical checks
				if(row >= "011") then
					playerAdjsArray(4) <= own_board(rowMinusOne)(columnAsInt) & own_board(rowMinusTwo)(columnAsInt) & 
					own_board(rowMinusThree)(columnAsInt);
				else
					playerAdjsArray(4) <= "000";
				end if;
				
				--top-right diagonal checks
				if(row >= "011" and column >= "011") then
					playerAdjsArray(5) <= own_board(rowMinusThree)(columnMinusThree) & own_board(rowMinusTwo)(columnMinusTwo) & 
					own_board(rowMinusOne)(columnMinusOne);
				else
					playerAdjsArray(5) <= "000";
				end if;
				
				if(row >= "010" and row <= "101" and column >= "010" and column <= "101") then
					playerAdjsArray(6) <= own_board(rowMinusTwo)(columnMinusTwo) & own_board(rowMinusOne)(columnMinusOne) & 
					own_board(rowPlusOne)(columnPlusOne);
				else
					playerAdjsArray(6) <= "000";
				end if;
				
				if(row >= "001" and row <= "100" and column >=  "001" and column <= "100") then
					playerAdjsArray(7) <= own_board(rowMinusOne)(columnMinusOne) & own_board(rowPlusOne)(columnPlusOne) & 
					own_board(rowPlusTwo)(columnPlusTwo);
				else
					playerAdjsArray(7) <= "000";
				end if;
				
				if(row <= "011" and column >= "011") then
					playerAdjsArray(8) <= own_board(rowPlusOne)(columnMinusOne) & own_board(rowPlusTwo)(columnPlusTwo) & 
					own_board(rowPlusThree)(columnPlusThree);
				else
					playerAdjsArray(8) <= "000";
				end if;
				
				--top-left diagonal checks
				if(row <= "011" and column >= "011" ) then
					playerAdjsArray(9) <= own_board(rowMinusThree)(columnMinusThree) & own_board(rowMinusTwo)(columnMinusTwo) & 
					own_board(rowMinusOne)(columnMinusOne);
				else
					playerAdjsArray(9) <= "000";
				end if;
				
				if(row >= "001" and row <= "100" and column >= "010" and column <= "101" ) then
					playerAdjsArray(10) <= own_board(rowMinusTwo)(columnMinusTwo) & own_board(rowMinusOne)(columnMinusOne) & 
					own_board(rowPlusOne)(columnPlusOne);
				else
					playerAdjsArray(10) <= "000";
				end if;
				
				if(row >= "010" and row <= "101" and column >=  "001" and column <= "100" ) then
					playerAdjsArray(11) <= own_board(rowMinusOne)(columnMinusOne) & own_board(rowPlusOne)(columnPlusOne) & 
					own_board(rowPlusTwo)(columnPlusTwo);
				else
					playerAdjsArray(11) <= "000";
				end if;
				
				if(row >= "011" and column <= "011" ) then
					playerAdjsArray(12) <= own_board(rowPlusOne)(columnPlusOne) & own_board(rowPlusTwo)(columnPlusTwo) & 
					own_board(rowPlusThree)(columnPlusThree);
				else
					playerAdjsArray(12) <= "000";
				end if;
			
			elsif(state = ST_CALCULATE or state = ST_DONE) then
				if(playerThreeAdjsVec(0) = '0' and
					playerThreeAdjsVec(1) = '0' and
					playerThreeAdjsVec(2) = '0' and
					playerThreeAdjsVec(3) = '0' and
					playerThreeAdjsVec(4) = '0' and
					playerThreeAdjsVec(5) = '0' and
					playerThreeAdjsVec(6) = '0' and
					playerThreeAdjsVec(7) = '0' and
					playerThreeAdjsVec(8) = '0' and
					playerThreeAdjsVec(9) = '0' and
					playerThreeAdjsVec(10) = '0' and
					playerThreeAdjsVec(11) = '0' and
					playerThreeAdjsVec(12) = '0') then
					player_can_win <= '0';
				else
					player_can_win <= '1';
				end if;
				
				if(playerTwoAdjsVec(0) = '0' and
					playerTwoAdjsVec(1) = '0' and
					playerTwoAdjsVec(2) = '0' and
					playerTwoAdjsVec(3) = '0' and
					playerTwoAdjsVec(4) = '0' and
					playerTwoAdjsVec(5) = '0' and
					playerTwoAdjsVec(6) = '0' and
					playerTwoAdjsVec(7) = '0' and
					playerTwoAdjsVec(8) = '0' and
					playerTwoAdjsVec(9) = '0' and
					playerTwoAdjsVec(10) = '0' and
					playerTwoAdjsVec(11) = '0' and
					playerTwoAdjsVec(12) = '0') then
					player_two_adjs <= '0';
				else
					player_two_adjs <= '1';
				end if;
				
				if(playerOneAdjVec(0) = '0' and
					playerOneAdjVec(1) = '0' and
					playerOneAdjVec(2) = '0' and
					playerOneAdjVec(3) = '0' and
					playerOneAdjVec(4) = '0' and
					playerOneAdjVec(5) = '0' and
					playerOneAdjVec(6) = '0' and
					playerOneAdjVec(7) = '0' and
					playerOneAdjVec(8) = '0' and
					playerOneAdjVec(9) = '0' and
					playerOneAdjVec(10) = '0' and
					playerOneAdjVec(11) = '0' and
					playerOneAdjVec(12) = '0') then
					player_one_adj <= '0';
				else
					player_one_adj <= '1';
				end if;

			end if;
		end if;
	end process checkPlayer;
	
	
	updateState : process(clk, state)
	begin
		if (rising_edge(clk)) then
			case state is
				when ST_IDLE =>
					if (enable = '1') then
						state <= ST_GATHER;
					end if;
				when ST_GATHER =>
					if (enable = '0') then
						state <= ST_IDLE;
					else
						state <= ST_CALCULATE;
					end if;
				when ST_CALCULATE =>
					if (enable = '0') then
						state <= ST_IDLE;
					else
						state <= ST_JOIN;
					end if;
				when ST_JOIN =>
					if (enable = '0') then
						state <= ST_IDLE;
					else
						state <= ST_DONE;
					end if;
				when ST_DONE =>
					if (enable = '0') then
						state <= ST_IDLE;
					end if;
			end case;
		end if;
	end process updateState;
	
	
	readySignal : process(clk, state)
	begin
		if (rising_edge(clk)) then
			if(state = ST_DONE) then
				ready <= '1';
			else
				ready <= '0';
			end if;
		end if;
	end process;
		
end Behavioral;