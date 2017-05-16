----------------------------------------------------------------------------------
-- Create Date:    	12:48:29 02/26/2017 
-- Design Name: 		Connect Four Adjacency Checker for the A.I. Module
-- Module Name:   	Adjacency Checker - Behavioral 
-- Project Name: 		Connect Four
-- Target Devices:	Nexys 4 DDR
-- Description: 		Given a 3-slot selection from the game board, oneToThreeAdjCalc determines how many pieces a player has in this selection. The possible values that a player would be interested in range from one to three, hence the name of the module. Three 1-bit std_logic signals are used as output, with each one corresponding to how many pieces a player has in this adjacency selection. That is to say, there is an output signal for the player having three pieces, one for having two pieces, and one for one piece.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.all;

entity oneToThreeAdjCalc is
port (
	input_vec : in std_logic_vector(2 downto 0);
	oneAdj    : out std_logic;
	twoAdjs   : out std_logic;
	threeAdjs : out std_logic
	);
end oneToThreeAdjCalc;

architecture Behavioral of oneToThreeAdjCalc is

begin

	process(input_vec)
	begin
		if(input_vec = "111") then
			threeAdjs <= '1';
		else
			threeAdjs <= '0';
		end if;
		
		if ((input_vec = "110") or (input_vec = "101") or (input_vec = "011")) then
			twoAdjs <= '1';
		else
			twoAdjs <= '0';
		end if;
		
		if ((input_vec = "100") or (input_vec = "010") or (input_vec = "001")) then
			oneAdj <= '1';
		else
			oneAdj <= '0';
		end if;
	end process;

end Behavioral;