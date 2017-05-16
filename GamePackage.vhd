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
	type VALID_ROWS is array(6 downto 0) of std_logic_vector(2 downto 0);
	
	component AdjacencyChecker is
	port (
		-- system clock
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
	end component;
	
	component UserInputModule is
		port (
			clk : in std_logic;
			sw : in std_logic_vector(6 downto 0);
			submit_play : in std_logic;
			turn : in std_logic;
			master_board : in GAME_BOARD;
			play_col : out std_logic_vector(2 downto 0);
			move_invalid : out std_logic
		);
	end component;
	
	component ArtificialIntelligenceModule is
		port (
			clk : in std_logic;
			master_board : in GAME_BOARD;
			p1_board : in GAME_BOARD;
			own_board : in GAME_BOARD;
			next_valid_rows : in VALID_ROWS;
			turn : in std_logic;
			play_col : out std_logic_vector(2 downto 0);
			played : out std_logic
		);
	end component;
	
	component DisplayModule is
		port (
			CLK_I : in STD_LOGIC;
			VGA_HS_O : out STD_LOGIC;
			VGA_VS_O : out STD_LOGIC;
			VGA_RED_O : out STD_LOGIC_VECTOR (3 downto 0);
			VGA_BLUE_O : out STD_LOGIC_VECTOR (3 downto 0);
			VGA_GREEN_O : out STD_LOGIC_VECTOR (3 downto 0);
			PS2_CLK : inout STD_LOGIC;
			PS2_DATA : inout STD_LOGIC;
			p1_board : in GAME_BOARD;
			p2_board : in GAME_BOARD
		);
	end component;
	
end GamePackage;

package body GamePackage is
end GamePackage;

entity GamePackage is
	
end GamePackage;

