----------------------------------------------------------------------------------
-- Create Date:    	12:48:29 02/26/2017 
-- Design Name: 		Connect Four Adjacency Checker for the A.I. Module
-- Module Name:   	Adjacency Checker - Behavioral 
-- Project Name: 		Connect Four
-- Target Devices:	Nexys 4 DDR
-- Description: 		Helper module for the A.I. Module. Given a matrix, this sub-module calculates the largest line of pieces that exists.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use work.GamePackage.GAME_BOARD;

entity AdjacencyChecker is
	port (
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
	
	signal calcThreeAdjsVec : std_logic_vector(12 downto 0);
	signal calcTwoAdjsVec   : std_logic_vector(12 downto 0);
	signal calcOneAdjVec   : std_logic_vector(12 downto 0);
	
	component oneToThreeAdjCalc 
		port (
		input_vec : in std_logic_vector(2 downto 0);
		oneAdj    : out std_logic;
		twoAdjs   : out std_logic;
		threeAdjs : out std_logic
		);
	end component;

begin


	rowAsInt         <= conv_integer(row);
	columnAsInt      <= conv_integer(column);

	rowMinusThree    <= conv_integer(row - "11");
	rowMinusTwo      <= conv_integer(row - "10");
	rowMinusOne      <= conv_integer(row - "01");
	
	rowPlusOne       <= conv_integer(row + "01");
	rowPlusTwo       <= conv_integer(row + "10");
	rowPlusThree     <= conv_integer(row + "11");
	
	columnMinusThree <= conv_integer(column - "11");
	columnMinusTwo   <= conv_integer(column - "10");
	columnMinusOne   <= conv_integer(column - "01");
	
	columnPlusOne    <= conv_integer(column + "01");
	columnPlusTwo    <= conv_integer(column + "10");
	columnPlusThree  <= conv_integer(column + "11");

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
	
	--Breaking the three bit board selections into nice booleans for own adjacency calculation below
	Inst_OwnAdjEncoderCalc_0 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(0),
			oneAdj    => calcOneAdjVec(0),
			twoAdjs   => calcTwoAdjsVec(0),
			threeAdjs => calcThreeAdjsVec(0)
			);
			
	Inst_OwnAdjEncoderCalc_1 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(1),
			oneAdj    => calcOneAdjVec(1),
			twoAdjs   => calcTwoAdjsVec(1),
			threeAdjs => calcThreeAdjsVec(1)
			);
			
	Inst_OwnAdjEncoderCalc_2 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(2),
			oneAdj    => calcOneAdjVec(2),
			twoAdjs   => calcTwoAdjsVec(2),
			threeAdjs => calcThreeAdjsVec(2)
			);
	
	Inst_OwnAdjEncoderCalc_3 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(3),
			oneAdj    => calcOneAdjVec(3),
			twoAdjs   => calcTwoAdjsVec(3),
			threeAdjs => calcThreeAdjsVec(3)
			);
	
	Inst_OwnAdjEncoderCalc_4 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(4),
			oneAdj    => calcOneAdjVec(4),
			twoAdjs   => calcTwoAdjsVec(4),
			threeAdjs => calcThreeAdjsVec(4)
			);
			
	Inst_OwnAdjEncoderCalc_5 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(5),
			oneAdj    => calcOneAdjVec(5),
			twoAdjs   => calcTwoAdjsVec(5),
			threeAdjs => calcThreeAdjsVec(5)
			);
	
	Inst_OwnAdjEncoderCalc_6 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(6),
			oneAdj    => calcOneAdjVec(6),
			twoAdjs   => calcTwoAdjsVec(6),
			threeAdjs => calcThreeAdjsVec(6)
			);
	
	Inst_OwnAdjEncoderCalc_7 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(7),
			oneAdj    => calcOneAdjVec(7),
			twoAdjs   => calcTwoAdjsVec(7),
			threeAdjs => calcThreeAdjsVec(7)
			);
			
	Inst_OwnAdjEncoderCalc_8 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(8),
			oneAdj    => calcOneAdjVec(8),
			twoAdjs   => calcTwoAdjsVec(8),
			threeAdjs => calcThreeAdjsVec(8)
			);
			
	Inst_OwnAdjEncoderCalc_9 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(9),
			oneAdj    => calcOneAdjVec(9),
			twoAdjs   => calcTwoAdjsVec(9),
			threeAdjs => calcThreeAdjsVec(9)
			);
			
	Inst_OwnAdjEncoderCalc_10 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(10),
			oneAdj    => calcOneAdjVec(10),
			twoAdjs   => calcTwoAdjsVec(10),
			threeAdjs => calcThreeAdjsVec(10)
			);
			
	Inst_OwnAdjEncoderCalc_11 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(11),
			oneAdj    => calcOneAdjVec(11),
			twoAdjs   => calcTwoAdjsVec(11),
			threeAdjs => calcThreeAdjsVec(11)
			);
	
	Inst_OwnAdjEncoderCalc_12 : oneToThreeAdjCalc
	PORT MAP(
			input_vec => playerAdjsArray(12),
			oneAdj    => calcOneAdjVec(12),
			twoAdjs   => calcTwoAdjsVec(12),
			threeAdjs => calcThreeAdjsVec(12)
			);
			 
	--buffering Adjacency vector of std_logic bits (booleans) so systems won't be "unused"
	
	playerOneAdjVec <= calcOneAdjVec;
	playerTwoAdjsVec <= calcTwoAdjsVec;
	playerThreeAdjsVec <= calcThreeAdjsVec;

	--own adjacency calculation
	checkPlayer : process(clk, state, column, playerAdjsArray)
	begin
		if(rising_edge(clk)) then
			if(state = ST_CALCULATE) then
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
			
			elsif(state = ST_CALCULATE) then
				if(playerThreeAdjsVec = "0000000000000") then
					player_can_win <= '0';
				else
					player_can_win <= '1';
				end if;
				
				if(playerTwoAdjsVec = "0000000000000") then
					player_two_adjs <= '0';
				else
					player_two_adjs <= '1';
				end if;
				
				if(playerOneAdjVec = "0000000000000") then
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
	
	-- asynchronously update the played handshake signal
	with state select ready <=
		'1' when ST_DONE,
		'0' when others;
end Behavioral;