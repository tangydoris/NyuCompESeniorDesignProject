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

entity ArtificialIntelligenceModule is
	port (
		-- system clock
		clk : in std_logic;
		
		-- game boards
		master_board : in GAME_BOARD;
		p1_board : in GAME_BOARD;
		own_board : in GAME_BOARD;
		
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

signal calculateEnable;

COMPONENT adjacencyChecker
  PORT(
	-- system clock (?)
		clk : in std_logic;
		
		-- game boards
		master_board : in GAME_BOARD;
		input_board : in GAME_BOARD;
		
		-- enable signal
		enable : in std_logic;
		
		--column play suggestion
		play_col : out std_logic_vector(2 downto 0);
		-- validity signal
		valid : out std_logic
      );
end component;

	signal move_calculated : std_logic := '0';
	
	type AI_STATE is (
		ST_IDLE,
		ST_PLAY,
		ST_CALCULATED
	);
	signal state : AI_STATE := ST_IDLE;
begin

	opponentAdjacencyCheck : adjacencyChecker
	port map(
	clk => clk,
	master_board => master_board,
	input_board => p1_board,
	calculateEnable => turn
	);
	
	
	updatePlayedCol : process(clk, state)
	begin
		if (rising_edge(clk)) then
			if (state = ST_PLAY) then
				-- fill board from left to right
				if (master_board(5)(0) = '0') then
					play_col <= "000";
				else
					end if;
				end if;
				-- update handshake
				move_calculated <= '1';
			else
				move_calculated <= '0';
			end if;
		end if;
	end process updatePlayedCol;
	
	updateState : process(clk, state, turn, move_calculated)
	begin
		if (rising_edge(clk)) then
			case state is
				when ST_IDLE =>
					if (turn = '1') then
						state <= ST_PLAY;
					end if;
				when ST_PLAY =>
					state <= ST_CALCULATED;
				when ST_CALCULATED =>
					state <= ST_IDLE;
			end case;
		end if;
	end process updateState;
	
	enableSig : process(clk, turn)
	begin
		if 
	
	-- asynchronously update the played handshake signal
	with move_calculated select played <=
		'1' when '1',
		'0' when others;
end Behavioral;

