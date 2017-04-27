------------------------------------------------------------------------
-- mouse_displayer.vhd
------------------------------------------------------------------------
-- Author : Karl Gharbi
--          
------------------------------------------------------------------------
-- Software version : Xilinx ISE 7.1.04i
--                    WebPack
-- Device	        : 3s200ft256-4
------------------------------------------------------------------------
-- This file is a modification of the MouseDisplay sample code, designed by
-- Ulrich Zolt�n of Digilent. The goal is to have this file serve as a
-- generic flatbed to show game board graphics.
------------------------------------------------------------------------
--  Behavioral description
------------------------------------------------------------------------
-- Mouse position is received from the mouse_controller, horizontal and
-- vertical counters are received from vga_module and if the counters
-- are inside the mouse cursor bounds, then the mouse is sent to the
-- screen.
-- The mouse display module can be also used as an overlay of the VGA 
-- signal, also blanking the VGA screen, if the red_in, green_in, blue_in 
-- and the blank_in signals are used. 
-- In this application the signals mentioned and their corresponding code 
-- lines are commented, therefore the mouse display module only generates 
-- the RGB signals to display the cursor, and the VGA controller decides 
-- whether or not to display the cursor.
-- The mouse cursor is 16x16 pixels and uses 2 colors: white and black. 
-- For the color encoding 2 bits are used to be able to use transparency. 
-- The cursor is stored in a 256X2 bit distributed ram memory. If the current
-- pixel of the mouse is "00" then output color is black, if "01" then is
-- white and if "10" or "11" then the pixel is transparent and the input 
-- R, G and B signals are passed to the output. 
-- In this way, the mouse cursor will not be a 16x16 square, instead will 
-- have an arrow shape.
-- The memory address is composed from the difference of the vga counters
-- and mouse position: xdiff is the difference on 4 bits (because cursor
-- is 16 pixels width) between the horizontal vga counter and the xpos
-- of the mouse. ydiff is the difference on 4 bits (because cursor
-- has 16 pixels in height) between the vertical vga counter and the
-- ypos of the mouse. By concatenating ydiff and xidff (in this order)
-- the memory address of the current pixel is obtained.
-- A distributed memory implementation is forced by the attributes, to save 
-- BRAM resources.
-- If the blank input from the vga_module is active, this means that current
-- pixel is not inside visible screen and color outputs are set to black
------------------------------------------------------------------------
--  Port definitions
------------------------------------------------------------------------
-- pixel_clk      - input pin, representing the pixel clock, used
--                - by the vga_controller for the currently used
--                - resolution, generated by a dcm. 25MHz for 640x480,
--                - 40MHz for 800x600 and 108 MHz for 1280x1024. 
--                - This clock is used to read pixels from memory 
--                - and output data on color outputs.
-- hres           - input pin, 12 bits, from vga_module
--                - the horizontal resolution of the display to render to
--                - to be halved to center the board display.
-- vres           - input pin, 12 bits, from vga_module
--                - the vertical resolution of the display in question
--                - to be halved to center the board display.
-- hcount         - input pin, 12 bits, from vga_module
--                - the horizontal counter from the vga_controller
--                - tells the horizontal position of the current pixel
--                - on the screen from left to right.
-- vcount         - input pin, 12 bits, from vga_module
--                - the vertical counter from the vga_controller
--                - tells the vertical position of the currentl pixel
--                - on the screen from top to bottom.
-- red_out        - output pin, 4 bits, to vga hardware module.
--                - red output channel
-- green_out      - output pin, 4 bits, to vga hardware module.
--                - green output channel
-- blue_out       - output pin, 4 bits, to vga hardware module.
--                - blue output channel

------------------- Signals used when the mouse display is in overlay mode

-- blank          - input pin, from vga_module
--                - if active, current pixel is not in visible area,
--                - and color outputs should be set on 0.
-- red_in         - input pin, 4 bits, from effects_layer
--                - red channel input of the image to be displayed
-- green_in       - input pin, 4 bits, from effects_layer
--                - green channel input of the image to be displayed
-- blue_in        - input pin, 4 bits, from effects_layer
--                - blue channel input of the image to be displayed
------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.math_real.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.gamePackage.all;


-- simulation library
--library UNISIM;
--use UNISIM.VComponents.all;

-- the boardDisplay entity declaration
-- read above for behavioral description and port definitions.

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
constant displayHeight: integer := 456;
--constant displayWidth : integer := ((numColumns * slotSize) + ((numColumns+1) * borderSize));
--constant displayHeight : integer := (((numRows+1 * slotSize) + ((numRows+1) * borderSize) + borderSize));

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
			currRow <= (numRows - ((conv_integer(ydiff) / (slotSize + borderSize))));
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
	boardPixel: process(isTopPart, isBottomPart, isSlotPart, isBorderPart, topPartFill,
							bottomPartFill, slotPartFill, borderPartFill, fillCond, xdiff, ydiff)
	begin
				if(rising_edge(pixel_clk)) then
					isTopPart <= (ydiff < slotSize);
					isBottomPart <= (ydiff >= ((numRows+1) * (borderSize + slotSize)));
					isSlotPart <= (NOT (isTopPart OR isBottomPart OR isBorderPart));
					isBorderPart <= (NOT (isTopPart OR isBottomPart) AND ((conv_integer(ydiff) mod (slotSize + borderSize)) >= slotSize));
	 
	
					topPartFill <= (isTopPart AND ((xdiff < borderSize) or (xdiff > (X_OFFSET - 1 - borderSize))));
					bottomPartFill <= (isBottomPart AND ((xdiff < borderSize) or (xdiff > (X_OFFSET - 1 - borderSize))));
					slotPartFill <= (isSlotPart AND ((conv_integer(xdiff) mod (slotSize + borderSize)) < borderSize));
					borderPartFill <= isBorderPart;
					fillCond <= (topPartFill) OR (bottomPartFill) OR (slotPartFill) OR (borderPartFill);
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
