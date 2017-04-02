----------------------------------------------------------------------------------
-- Create Date:    	12:48:29 02/26/2017 
-- Design Name: 		Connect Four A.I. Module
-- Module Name:   	AiModule - Behavioral 
-- Project Name: 		Connect Four
-- Target Devices:	Nexys 4 DDR
-- Description: 		Module for the Connect Four game that implements artificial intelligence for a machine player.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use work.GamePackage.GAME_BOARD;

entity AiModule is
	port (
		-- system clock
		clk_in : in std_logic;
		-- 3 game boards that describe the current game conditions
		-- master playing board
		master_board_in : in GAME_BOARD;
		-- player 1 game board
		p1_board_in : in GAME_BOARD;
		-- player 2 (implemented by this module) game board
		own_board_in : in GAME_BOARD;
		-- player 2 turn
		turn_in : in std_logic;
		
		-- output signals to master module
		-- played column (o through 7)
		play_col_out : out std_logic_vector(2 downto 0);
		-- played handshake
		played_out : out std_logic);
end AiModule;

architecture Behavioral of AiModule is
begin

end Behavioral;

