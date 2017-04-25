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
		master_board : in GAME_BOARD;
		input_board : in GAME_BOARD;
		
		-- enable signal
		enable : in std_logic;
		
		-- output decision
		-- played column (0 through 7)
		play_col : out std_logic_vector(2 downto 0);
		-- validity signal
		valid : out std_logic
	);
end AdjacencyChecker;

architecture Behavioral of AdjacencyChecker is
	signal move_calculated : std_logic := '0';
	signal horizontalSelection : array(5 downto 0) of std_logic_vector(3 downto 0);
	signal verticalSelection : array (6 downto 0) of std_logic_vector(3 downto 0);
	
	--Composite valid bit vector
	signal doneValue : std_logic_vector(3 downto 0);
	
	signal verticalDone : std_logic := '0';
	signal horizontalDone : std_logic := '0';
	signal topRightDiagonalDone : std_logic := '1';
	signal topLeftDiagonalDone : std_logic := '1';
	
	signal horizontalColSel : std_logic_vector(2 downto 0);
	signal verticalColSel   : std_logic_vector(2 downto 0);
	signal trColSel         : std_logic_vector(2 downto 0);
	signal tlColSel         : std_logic_vector(2 downto 0);
	
	type STATE is (
		ST_IDLE,
		ST_WORKING,
		ST_DONE
	);
	signal state : STATE := ST_IDLE;
	
--Thinking takes ~4 clock cycles
--Want to choose a block of four slots. See if three are filled with one player's pieces.
--If so, see if the remaining piece is occupied, if not, select that as the play column.
begin
	doneValue <= (verticalDone + horizontalDone + topRightDiagonalDone + topLeftDiagonalDone);

	horizontalCheck : process(clk, state)
	signal leadingColumn: std_logic_vector (2 downto 0) := "011";
	begin
		if (rising_edge(clk)) then
			if (state = ST_WORKING) then
				for row in "000" to "101" loop
					if(leadingColumn = "111") then
						exit;
					end if;
					
					horizontalSelection(row) = input_board(row)(leadingColumn downto leadingColumn-3);
					--funky code that checks if three of the four bit selection are 1
					if((horizontalSelection(row)(0) xor horizontalSelection(row)(1)) xor (horizontalSelection(row)(2) xor horizontalSelection(row)(3))) then
						case horizontalSelection is
							when "1110" => horizontalColSel <= leadingColumn;
							when "1101" => horizontalColSel <= leadingColumn-"001";
							when "1011" => horizontalColSel <= leadingColumn-"010";
							when "0111" => horizontalColSel <= leadingColumn-"011";
							when others => horizontalColSel <= "111" --invalid value;
						end case;
						
						if(horizontalColSel != "111") then
							horizontalDone <= '1';
							exit; --leave inner loop
						end if;
					else
						leadingColumn <= leadingColumn + 1;
					end if;
				end loop;
			end if;		
		end if;	
	end process horizontalCheck;		
	
	updateState : process(clk, state, turn, move_calculated)
	begin
		if (rising_edge(clk)) then
			case state is
				when ST_WORKING =>
					if (enable = '1') then
						state <= ST_WORKING;
					end if;
				when ST_WORKING =>
					if (enable = '0') then
						state <= ST_IDLE;
					if (ready = "11") then
						state <= ST_DONE
				when ST_DONE =>
					state <= ST_IDLE;
			end case;
		end if;
	end process updateState;
	
	-- asynchronously update the played handshake signal
	with move_calculated select played <=
		'1' when '1',
		'0' when others;
end Behavioral;

