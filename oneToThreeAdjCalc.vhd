----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:03:35 05/08/2017 
-- Design Name: 
-- Module Name:    oneToThreeAdjCalc - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

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

	threeAdjs <= (input_vec = "111");
	twoAdjs   <= (input_vec = "110") or (input_vec = "101") or (input_vec = "011");
	oneAdj    <= (input_vec = "100") or (input_vec = "010") or (input_vec = "001");

end Behavioral;

