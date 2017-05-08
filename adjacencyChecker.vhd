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
		master_board   : in GAME_BOARD;
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
		ST_CALCULATE,
		ST_JOIN,
		ST_DONE
	);
	
	signal rowMinusThree : std_logic_vector(2 downto 0);
	signal rowMinusTwo   : std_logic_vector(2 downto 0);
	signal rowMinusOne   : std_logic_vector(2 downto 0);
	
	signal rowPlusOne    : std_logic_vector(2 downto 0);
	signal rowPlusTwo    : std_logic_vector(2 downto 0);
	signal rowPlusThree  : std_logic_vector(2 downto 0);
	
	signal columnMinusThree : std_logic_vector(2 downto 0);
	signal columnMinusTwo   : std_logic_vector(2 downto 0);
	signal columnMinusOne   : std_logic_vector(2 downto 0);
	
	signal columnPlusOne    : std_logic_vector(2 downto 0);
	signal columnMinusTwo   : std_logic_vector(2 downto 0);
	signal columnMinusThree : std_logic_vector(2 downto 0);
	
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
	signal playerOneAdjsVec   : std_logic_vector(12 downto 0);
	
	component oneToThreeAdjCalc 
		port (
		input_vec : in std_logic_vector(2 downto 0);
		oneAdj    : out std_logic;
		twoAdjs   : out std_logic;
		threeAdjs : out std_logic
		);
	end component;

begin

	rowMinusThree <= row - "11";
	rowMinusTwo   <= row - "10";
	rowMinusOne   <= row - "01";
	
	rowPlusOne    <= row + "01";
	rowPlusTwo    <= row + "10";
	rowPlusThree  <= row + "11";
	
	columnMinusThree <= column - "11";
	columnMinusTwo   <= column - "10";
	columnMinusOne   <= column - "01";
	
	columnPlusOne    <= column + "01";
	columnPlusTwo    <= column + "10";
	columnPlusThree  <= column + "11";

	--opponent adjacency check
	checkOpponent : process(clk, state, column, oppThreeAdjsHoriz, oppThreeAdjsVert, oppThreeAdjsTopRightDiag, oppThreeAdjsTopLeftDiag)
	begin
		if (rising_edge(clk)) then
			if(state = ST_WORKING) then
				--horizontal checks
				if(column >= "011") then
					oppThreeAdjsHoriz(0) <= opponent_board(row)(columnMinusThree) and opponent_board(row)(columnMinusTwo) and opponent_board(row)(columnMinusOne);
				else
					oppThreeAdjsHoriz(0) <= '0';
				end if;
				
				if(column >= "010" and column <= "101" ) then
					oppThreeAdjsHoriz(1) <= opponent_board(row)(columnMinusTwo) and opponent_board(row)(columnMinusOne) and opponent_board(row)(columnPlusOne);
				else
					oppThreeAdjsHoriz(1) <= '0';
				end if;
				
				if(column >=  "001" and column <= "100") then
					oppThreeAdjsHoriz(2) <= opponent_board(row)(columnMinusOne) and opponent_board(row)(columnPlusOne) and opponent_board(row)(columnPlusTwo);
				else
					oppThreeAdjsHoriz(2) <= '0';
				end if;
				
				if(column <= "011") then
					oppThreeAdjsHoriz(3) <= opponent_board(row)(columnPlusOne) and opponent_board(row)(columnPlusTwo) and opponent_board(row)(columnPlusThree);
				else
					oppThreeAdjsHoriz(3) <= '0';
				end if;
				
				--vertical checks
				if(row >= "011") then
					oppThreeAdjsVert <= opponent_board(rowMinusOne)(column) and opponent_board(rowMinusTwo)(column) and opponent_board(rowMinusThree)(column);
				else
					oppThreeAdjsVert <= '0';
				end if;
				
				--top-right diagonal checks
				if(row >= "011" and column >= "011") then
					oppThreeAdjsTopRightDiag(0) <= opponent_board(rowMinusThree)(columnMinusThree) and opponent_board(rowMinusTwo)(columnMinusTwo) and opponent_board(rowMinusOne)(columnMinusOne);
				else
					oppThreeAdjsTopRightDiag(0) <= '0';
				end if;
				
				if(row >= "010" and row <= "101" and column >= "010" and column <= "101") then
					oppThreeAdjsTopRightDiag(1) <= opponent_board(rowMinusTwo)(columnMinusTwo) and opponent_board(rowMinusOne)(columnMinusOne) and opponent_board(rowPlusOne)(columnPlusOne);
				else
					oppThreeAdjsTopRightDiag(1) <= '0';
				end if;
				
				if(row >= "001" and row <= "100" and column >=  "001" and column <= "100") then
					oppThreeAdjsTopRightDiag(2) <= opponent_board(rowMinusOne)(columnMinusOne) and opponent_board(rowPlusOne)(columnPlusOne) and opponent_board(rowPlusTwo)(columnPlusTwo);
				else
					oppThreeAdjsTopRightDiag(2) <= '0';
				end if;
				
				if(row <= "011" and column >= "011") then
					oppThreeAdjsTopRightDiag(3) <= opponent_board(rowPlusOne)(columnMinusOne) and opponent_board(rowPlusTwo)(columnPlusTwo) and opponent_board(rowPlusThree)(columnPlusThree);
				else
					oppThreeAdjsTopRightDiag(3) <= '0';
				end if;
				
				--top-left diagonal checks
				if(row <= "011" and column >= "011" ) then
					oppThreeAdjsTopLeftDiag(0) <= opponent_board(rowMinusThree)(columnMinusThree) and opponent_board(rowMinusTwo)(columnMinusTwo) and opponent_board(rowMinusOne)(columnMinusOne);
				else
					oppThreeAdjsTopLeftDiag(0) <= '0';
				end if;
				
				if(row >= "001" and row <= "100" and column >= "010" and column <= "101" ) then
					oppThreeAdjsTopLeftDiag(1) <= opponent_board(rowMinusTwo)(columnMinusTwo) and opponent_board(rowMinusOne)(columnMinusOne) and opponent_board(rowPlusOne)(columnPlusOne);
				else
					oppThreeAdjsTopLeftDiag(1) <= '0';
				end if;
				
				if(row >= "010" and row <= "101" and column >=  "001" and column <= "100" ) then
					oppThreeAdjsTopLeftDiag(2) <= opponent_board(rowMinusOne)(columnMinusOne) and opponent_board(rowPlusOne)(columnPlusOne) and opponent_board(rowPlusTwo)(columnPlusTwo);
				else
					oppThreeAdjsTopLeftDiag(2) <= '0';
				end if;
				
				if(row >= "011" and column <= "011" ) then
					oppThreeAdjsTopLeftDiag(3) <= opponent_board(rowPlusOne)(columnPlusOne) and opponent_board(rowPlusTwo)(columnPlusTwo) and opponent_board(rowPlusThree)(columnPlusThree);
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
	
	--Breaking the three bit board selections into nice booleans for own adjacency calculation below
	Inst_OwnAdjEncoderCalc_0 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(0),
			oneAdj    => playerOneAdjsVec(0),
			twoAdjs   => playerTwoAdjsVec(0),
			threeAdjs => playerThreeAdjsVec(0)
			);
			
	Inst_OwnAdjEncoderCalc_1 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(1),
			oneAdj    => playerOneAdjsVec(1),
			twoAdjs   => playerTwoAdjsVec(1),
			threeAdjs => playerThreeAdjsVec(1)
			);
			
	Inst_OwnAdjEncoderCalc_2 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(2),
			oneAdj    => playerOneAdjsVec(2),
			twoAdjs   => playerTwoAdjsVec(2),
			threeAdjs => playerThreeAdjsVec(2)
			);
	
	Inst_OwnAdjEncoderCalc_3 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(3),
			oneAdj    => playerOneAdjsVec(3),
			twoAdjs   => playerTwoAdjsVec(3),
			threeAdjs => playerThreeAdjsVec(3)
			);
	
	Inst_OwnAdjEncoderCalc_4 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(4),
			oneAdj    => playerOneAdjsVec(4),
			twoAdjs   => playerTwoAdjsVec(4),
			threeAdjs => playerThreeAdjsVec(4)
			);
			
	Inst_OwnAdjEncoderCalc_5 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(5),
			oneAdj    => playerOneAdjsVec(5),
			twoAdjs   => playerTwoAdjsVec(5),
			threeAdjs => playerThreeAdjsVec(5)
			);
	
	Inst_OwnAdjEncoderCalc_6 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(6),
			oneAdj    => playerOneAdjsVec(6),
			twoAdjs   => playerTwoAdjsVec(6),
			threeAdjs => playerThreeAdjsVec(6)
			);
	
	Inst_OwnAdjEncoderCalc_7 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(7),
			oneAdj    => playerOneAdjsVec(7),
			twoAdjs   => playerTwoAdjsVec(7),
			threeAdjs => playerThreeAdjsVec(7)
			);
			
	Inst_OwnAdjEncoderCalc_8 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(8),
			oneAdj    => playerOneAdjsVec(8),
			twoAdjs   => playerTwoAdjsVec(8),
			threeAdjs => playerThreeAdjsVec(8)
			);
			
	Inst_OwnAdjEncoderCalc_9 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(9),
			oneAdj    => playerOneAdjsVec(9),
			twoAdjs   => playerTwoAdjsVec(9),
			threeAdjs => playerThreeAdjsVec(9)
			);
			
	Inst_OwnAdjEncoderCalc_10 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(10),
			oneAdj    => playerOneAdjsVec(10),
			twoAdjs   => playerTwoAdjsVec(10),
			threeAdjs => playerThreeAdjsVec(10)
			);
			
	Inst_OwnAdjEncoderCalc_11 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(11),
			oneAdj    => playerOneAdjsVec(11),
			twoAdjs   => playerTwoAdjsVec(11),
			threeAdjs => playerThreeAdjsVec(11)
			);
	
	Inst_OwnAdjEncoderCalc_12 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(12),
			oneAdj    => playerOneAdjsVec(12),
			twoAdjs   => playerTwoAdjsVec(12),
			threeAdjs => playerThreeAdjsVec(12)
			);
			 
			

	--own adjacency calculation
	checkPlayer : process(clk, state, column, playerAdjsArray)
	begin
		if(rising_edge(clk)) then
			if(state = ST_CALCULATE) then
				if(column >= "011") then
					playerAdjsArray(0) <= own_board(row)(columnMinusThree) and own_board(row)(columnMinusTwo) and own_board(row)(columnMinusOne);
				else
					playerAdjsArray(0) <= '0';
				end if;
				
				if(column >= "010" and column <= "101" ) then
					playerAdjsArray(1) <= own_board(row)(columnMinusTwo) and own_board(row)(columnMinusOne) and own_board(row)(columnPlusOne);
				else
					playerAdjsArray(1) <= '0';
				end if;
				
				if(column >=  "001" and column <= "100") then
					playerAdjsArray(2) <= own_board(row)(columnMinusOne) and own_board(row)(columnPlusOne) and own_board(row)(columnPlusTwo);
				else
					playerAdjsArray(2) <= '0';
				end if;
				
				if(column <= "011") then
					playerAdjsArray(3) <= own_board(row)(columnPlusOne) and own_board(row)(columnPlusTwo) and own_board(row)(columnPlusThree);
				else
					playerAdjsArray(3) <= '0';
				end if;
				
				--vertical checks
				if(row >= "011") then
					playerAdjsArray(4) <= own_board(rowMinusOne)(column) and own_board(rowMinusTwo)(column) and own_board(rowMinusThree)(column);
				else
					playerAdjsArray(4) <= '0';
				end if;
				
				--top-right diagonal checks
				if(row >= "011" and column >= "011") then
					playerAdjsArray(5) <= own_board(rowMinusThree)(columnMinusThree) and own_board(rowMinusTwo)(columnMinusTwo) and own_board(rowMinusOne)(columnMinusOne);
				else
					playerAdjsArray(5) <= '0';
				end if;
				
				if(row >= "010" and row <= "101" and column >= "010" and column <= "101") then
					playerAdjsArray(6) <= own_board(rowMinusTwo)(columnMinusTwo) and own_board(rowMinusOne)(columnMinusOne) and own_board(rowPlusOne)(columnPlusOne);
				else
					playerAdjsArray(6) <= '0';
				end if;
				
				if(row >= "001" and row <= "100" and column >=  "001" and column <= "100") then
					playerAdjsArray(7) <= own_board(rowMinusOne)(columnMinusOne) and own_board(rowPlusOne)(columnPlusOne) and own_board(rowPlusTwo)(columnPlusTwo);
				else
					playerAdjsArray(7) <= '0';
				end if;
				
				if(row <= "011" and column >= "011") then
					playerAdjsArray(8) <= own_board(rowPlusOne)(columnMinusOne) and own_board(rowPlusTwo)(columnPlusTwo) and own_board(rowPlusThree)(columnPlusThree);
				else
					playerAdjsArray(8) <= '0';
				end if;
				
				--top-left diagonal checks
				if(row <= "011" and column >= "011" ) then
					playerAdjsArray(9) <= own_board(rowMinusThree)(columnMinusThree) and own_board(rowMinusTwo)(columnMinusTwo) and own_board(rowMinusOne)(columnMinusOne);
				else
					playerAdjsArray(9) <= '0';
				end if;
				
				if(row >= "001" and row <= "100" and column >= "010" and column <= "101" ) then
					playerAdjsArray(10) <= own_board(rowMinusTwo)(columnMinusTwo) and own_board(rowMinusOne)(columnMinusOne) and own_board(rowPlusOne)(columnPlusOne);
				else
					playerAdjsArray(10) <= '0';
				end if;
				
				if(row >= "010" and row <= "101" and column >=  "001" and column <= "100" ) then
					playerAdjsArray(11) <= own_board(rowMinusOne)(columnMinusOne) and own_board(rowPlusOne)(columnPlusOne) and own_board(rowPlusTwo)(columnPlusTwo);
				else
					playerAdjsArray(11) <= '0';
				end if;
				
				if(row >= "011" and column <= "011" ) then
					playerAdjsArray(12) <= own_board(rowPlusOne)(columnPlusOne) and own_board(rowPlusTwo)(columnPlusTwo) and own_board(rowPlusThree)(columnPlusThree);
				else
					playerAdjsArray(12) <= '0';
				end if;
			
			elsif(state = ST_CALCULATE) then
				player_can_win  <= (not (playerThreeAdjsVec = "00000000000000000"));
				player_two_adjs <= (not (playerTwoAdjsVec   = "00000000000000000"));
				player_one_adjs <= (not (playerOneAdjsVec   = "00000000000000000"));
			end if;
		end if;
	end process checkPlayer;
	
	
	updateState : process(clk, state)
	begin
		if (rising_edge(clk)) then
			case state is
				when ST_IDLE =>
					if (enable = '1') then
						state <= ST_WORKING;
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
	
	-- asynchronously update the played handshake signal
	with state select ready <=
		'1' when ST_DONE,
		'0' when others;
end Behavioral;

