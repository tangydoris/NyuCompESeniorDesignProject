----------------------------------------------------------------------------------
-- Create Date:    	12:48:29 02/26/2017 
-- Design Name: 		Connect Four Game Package
-- Module Name:   	GamePackage - Behavioral 
-- Project Name: 		Connect Four
-- Target Devices:	Nexys 4 DDR
-- Description: 		Package for Connect Four game - includes data structures and references to outer game modules.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package GamePackage is
	type GAME_BOARD is array(5 downto 0) of std_logic_vector(6 downto 0);
	
	component UserInputModule is
		port (
			clk_in : in std_logic;
			game_reset_in : in std_logic;
			sw_in : in std_logic_vector(6 downto 0);
			submit_play_in : in std_logic;
			p1_turn_in : in std_logic;
			master_board_in : in GAME_BOARD;
			p1_play_col_out : out std_logic_vector(2 downto 0);
			p1_played_out : out std_logic;
			p1_ends_game_out : out std_logic);
	end component;
end GamePackage;

package body GamePackage is
end GamePackage;

entity GamePackage is
	
end GamePackage;

