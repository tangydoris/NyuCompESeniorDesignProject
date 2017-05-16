-- Create Date:    	12:48:29 02/26/2017 
-- Design Name: 		Connect Four Display Module
-- Module Name:   	DisplayModule - Behavioral 
-- Project Name: 		Connect Four
-- Target Devices:	Nexys 4 DDR
-- Description: 		Given a display resolution (hres, vres), the current row and column of the pixel position being considered (hcount, vcount), and the game boards for Player 1 and Player 2 (p1_board, p2_board), the Board Display renders a Connect 4 board at the center of the display, also showing the game pieces as they are updated in the input boards. This component uses parameters for the border and slot sizes to dynamically render the board; No bitmap is used. Based on a local offset relative to the top left corner of the board (xdiff, ydiff), it is determined what part of the board that pixel is in. Then, it is determined whether that pixel should be colored yellow by using an algorithm that considers where the borders should be. A similar system is also used to map game pieces. Three 8-bit outputs come out of the Board Display, corresponding to the red, green, and blue values for that pixel. This file is a modification of the MouseDisplay sample code that was part of the original system, designed by Ulrich Zoltán of Digilent.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.math_real.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.gamePackage.all;

entity BoardDisplay is
port (
   pixel_clk: in std_logic;

   hcount   : in std_logic_vector(11 downto 0);
   vcount   : in std_logic_vector(11 downto 0);
	
	hres     : in std_logic_vector(11 downto 0);
	vres     : in std_logic_vector(11 downto 0);
   --blank    : in std_logic; -- if VGA blank is used

   --red_in   : in std_logic_vector(3 downto 0); -- if VGA signal pass-through is used
   --green_in : in std_logic_vector(3 downto 0);
   --blue_in  : in std_logic_vector(3 downto 0);
   
   enable_display_out : out std_logic;

   red_out  : out std_logic_vector(3 downto 0);
   green_out: out std_logic_vector(3 downto 0);
   blue_out : out std_logic_vector(3 downto 0);
	
	p1_board : in GAME_BOARD;
	p2_board : in GAME_BOARD
);


-- force synthesizer to extract distributed ram for the
-- displayrom signal, and not a block ram, to save BRAM resources.
attribute rom_extract : string;
attribute rom_extract of BoardDisplay: entity is "yes";
attribute rom_style : string;
attribute rom_style of BoardDisplay: entity is "distributed";

end BoardDisplay;

architecture Behavioral of BoardDisplay is

------------------------------------------------------------------------
-- CONSTANTS
------------------------------------------------------------------------

constant numRows: integer := 6;
constant numColumns: integer := 7;
constant slotSize: integer := 50;
constant borderSize: integer := 7;

constant displayWidth: integer := 406;
constant displayHeight: integer := 412;
--constant displayWidth : integer := ((numColumns * slotSize) + ((numColumns+1) * borderSize));
--constant displayHeight : integer := (((numRows * slotSize) + ((numRows+1) * borderSize) + borderSize));

constant X_OFFSET: std_logic_vector(11 downto 0) := std_logic_vector(conv_unsigned(displayWidth, 12));
constant Y_OFFSET: std_logic_vector(11 downto 0) := std_logic_vector(conv_unsigned(displayHeight, 12));
						
constant X_OFFSET_HALF: std_logic_vector(11 downto 0) := '0' & X_OFFSET(11 downto 1);
constant Y_OFFSET_HALF: std_logic_vector(11 downto 0) := '0' & Y_OFFSET(11 downto 1);

------------------------------------------------------------------------
-- SIGNALS
------------------------------------------------------------------------
--new: provide information for where the top left corner of the board will be,
--as mouse input will not be used to figure that out.
--coded as signals, but in practice considered to be a constant.
signal hPoint : std_logic_vector(11 downto 0) := (('0' & hres(11 downto 1)) - X_OFFSET_HALF);
signal vPoint : std_logic_vector(11 downto 0) := (('0' & vres(11 downto 1)) - Y_OFFSET_HALF);

-- when high, enables displaying of the cursor, and reading the
-- cursor memory.
signal enable_display: std_logic := '0';

signal xdiff: std_logic_vector(11 downto 0) := (others => '0');
signal ydiff: std_logic_vector(11 downto 0) := (others => '0');

signal red_int  : std_logic_vector(3 downto 0);
signal green_int: std_logic_vector(3 downto 0);
signal blue_int : std_logic_vector(3 downto 0);

signal red_int1  : std_logic_vector(3 downto 0);
signal green_int1: std_logic_vector(3 downto 0);
signal blue_int1 : std_logic_vector(3 downto 0);

signal isTopPart: boolean;
signal isBottomPart: boolean;
signal isSlotPart: boolean;
signal isBorderPart: boolean;
	
signal topPartFill: boolean;
signal bottomPartFill: boolean;
signal slotPartFill: boolean;
signal borderPartFill: boolean;
signal fillCond: boolean;

signal redPieces:  GAME_BOARD;
signal bluePieces: GAME_BOARD;
signal currRow:    integer;
signal currColumn: integer;
signal inBoard:     boolean;

signal isRed:  boolean;
signal isBlue: boolean;

begin

	redPieces <= p2_board;
	bluePieces <= p1_board;

	hPoint <= (('0' & hres(11 downto 1)) - X_OFFSET_HALF);
	vPoint <= (('0' & vres(11 downto 1)) - Y_OFFSET_HALF);

--what did I want to do
--Board size has been determined, based on predetermined # of lines & thickness
--For each row, have (x+1) divisions and x slots, where x is the number of slots
--Except for the first row, which will only have divisions at the ends.
--So, what shall the structure be?
--Initial loop: For (slot height), fill (borderSize) at beginning and end, rest is blank
--Main loop: For(slot height * rowCount), fill with (borderSize), then blank for slotSize, repeat 
--until (x+1) divisions done
--Final Loop: Generate legs
--	--generate/update new board

-- compute xdiff
	x_diff: process(hcount, hPoint)
   variable temp_diff: std_logic_vector(11 downto 0) := (others => '0');
   begin
			temp_diff := hcount - hPoint;
			if (temp_diff > X_OFFSET) then
				xdiff <= X_OFFSET;
			else
				xdiff <= temp_diff;
			end if;
   end process x_diff;
	
	   -- compute ydiff
   y_diff: process(vcount, vPoint)
   variable temp_diff: std_logic_vector(11 downto 0) := (others => '0');
   begin
         temp_diff := vcount - vPoint;
			if (temp_diff > Y_OFFSET) then --X"1C" = 28
				ydiff <= Y_OFFSET;
			else
				ydiff <= temp_diff;
			end if;
   end process y_diff;

   -- set enable_mouse_display high if vga counters inside cursor block
	--change: OFFSET replaced with X_OFFSET and Y_OFFSET for hcount and vcount
   enable_display_control: process(pixel_clk, hcount, vcount, hPoint, vPoint)
   begin
      if(rising_edge(pixel_clk)) then
         if(hcount >= hPoint + 1 and hcount <= (hPoint + X_OFFSET) and
            vcount >= vPoint + 1 and vcount <= (vPoint + Y_OFFSET))
         then
            enable_display <= '1';
         else
            enable_display <= '0';
         end if;
      end if;
   end process enable_display_control;
	
	rowColumn: process(xdiff, ydiff, currRow, currColumn, redPieces, bluePieces, isRed, isBlue, inBoard)
	begin
			currRow <= ((numRows-1) - ((conv_integer(ydiff) / (slotSize + borderSize))));
			currColumn <= (((conv_integer(xdiff) - borderSize)) / (slotSize + borderSize));
			
			inBoard <= ((currRow < 6) AND (currColumn < 7) AND (currRow >= 0) AND (currColumn >= 0));
			if( inBoard AND(redPieces(currRow)(currColumn) = '1') ) then
				isRed <= true;
			else
				isRed <= false;
			end if;
			if(inBoard AND (bluePieces(currRow)(currColumn) = '1')) then
				isBlue <= true;
			else
				isBlue <= false;
			end if;
	end process rowColumn;
	
	--Determine if the current pixel should be a filled board pixel
	--Also: Determine which slot the current pixel is in, if at all. Find out whether it's a red piece or a blue piece.
	boardPixel: process(pixel_clk, isTopPart, isBottomPart, isSlotPart, isBorderPart, topPartFill,
							bottomPartFill, slotPartFill, borderPartFill, fillCond, xdiff, ydiff)
	begin
				if(rising_edge(pixel_clk)) then
					isBottomPart <= (ydiff >= (((numRows) * (borderSize + slotSize)) + borderSize));
					isSlotPart <= (NOT (isBottomPart OR isBorderPart));
					isBorderPart <= (NOT (isBottomPart) AND (((conv_integer(ydiff) + slotSize) mod (slotSize + borderSize)) >= slotSize));
					
					bottomPartFill <= (isBottomPart AND ((xdiff < borderSize) or (xdiff > (X_OFFSET - 1 - borderSize))));
					slotPartFill <= (isSlotPart AND ((conv_integer(xdiff) mod (slotSize + borderSize)) < borderSize));
					borderPartFill <= isBorderPart;
					fillCond <= (bottomPartFill) OR (slotPartFill) OR (borderPartFill);
				end if;
					
					
					
	end process boardPixel;
	

   
enable_display_out <= enable_display;

   -- if cursor display is enabled, then, according to pixel
   -- value, set the output color channels.
 process(pixel_clk, fillCond, isRed, isBlue)
   begin
      if(rising_edge(pixel_clk)) then
         -- if in visible screen
--       if(blank = '0') then
            -- in display is enabled
            if(enable_display = '1') then
               -- yellow pixel of cursor
					--change: white -> yellow
               if(fillCond = true) then
                  red_out <= (others => '1');
                  green_out <= (others => '1');
                  blue_out <= (others => '0');
               -- black pixel of cursor
               else   --(fillCond = false)
					--WOOHOO NEW CODE HERE
						if(isRed = true) then
							red_out <= (others => '1');
							green_out <= (others => '0');
							blue_out <= (others => '0');
						elsif(isBlue = true) then
							red_out <= (others => '0');
							green_out <= (others => '0');
							blue_out <= (others => '1');
						else
							red_out <= (others => '0');
							green_out <= (others => '0');
							blue_out <= (others => '0');
						end if;
               -- transparent pixel of cursor
               -- let input pass to output
--               else
--                  red_out <= red_in;
--                  green_out <= green_in;
--                  blue_out <= blue_in;
               end if;
            -- cursor display is not enabled
            -- let input pass to output.
--          else
--               red_out <= red_in;
--               green_out <= green_in;
--               blue_out <= blue_in;
            end if;
         -- not in visible screen, black outputs.
--       else
--            red_out <= (others => '0');
--            green_out <= (others => '0');
--            blue_out <= (others => '0');
--      end if;
      end if;
   end process;
	
end Behavioral;