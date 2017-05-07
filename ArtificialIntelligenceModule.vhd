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
	signal move_calculated : std_logic := '0';
	type AI_STATE is (
		ST_IDLE,
		ST_PLAY,
		ST_CALCULATED
	);
	signal state : AI_STATE := ST_IDLE;
begin

	updatePlayedCol : process(clk, state, master_board)
	begin
		if (rising_edge(clk)) then
			if (state = ST_PLAY) then
				-- fill board from left to right
				if (master_board(5)(0) = '0') then
					play_col <= "000";
				elsif (master_board(5)(1) = '0') then
					play_col <= "001";
				elsif (master_board(5)(2) = '0') then
					play_col <= "010";
				elsif (master_board(5)(3) = '0') then
					play_col <= "011";
				elsif (master_board(5)(4) = '0') then
					play_col <= "100";
				elsif (master_board(5)(5) = '0') then
					play_col <= "101";
				elsif (master_board(5)(6) = '0') then
					play_col <= "110";
				else
					play_col <= "111";
				end if;
				-- update handshake
				move_calculated <= '1';
			else
				move_calculated <= '0';
			end if;
		end if;
	end process updatePlayedCol;
	
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
					state <= ST_IDLE;
			end case;
		end if;
	end process updateState;
end Behavioral;

