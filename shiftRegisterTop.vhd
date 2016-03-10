library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- This is an 8 bit shift register which helps with the clock.
-- Please go through this to understand it and keep in mind that this code shifts input and output:
-- https://startingelectronics.org/software/VHDL-CPLD-course/tut11-shift-register/

entity shiftRegisterTop is port (clock		: IN STD_LOGIC;
				 serialIn	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				 serialOut	: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
				 q1		: IN STD_LOGIC;
				 q2		: IN STD_LOGIC;
				 shiftingInput	: IN STD_LOGIC;
				 shiftingOutput	: OUT STD_LOGIC);
end shiftRegisterTop;

architecture shiftRegisterTop_func of shiftRegisterTop is

signal shift_reg 	: STD_LOGIC_VECTOR(7 downto 0) := X"00";

begin
	-- assign our output sirial to the shift register values
	serialOut <= shift_reg;

	process (clock) begin

		if (q1 = '0' AND q2 = '0') then
			shiftingOutput <= 'Z';	-- don't care (see truth table)
		elsif (q1 = '0' AND q2 = '1') then 
			-- need to shift our input
			shift_reg(0) <= shiftingInput;
			shift_reg(1) <= shift_reg(0);
			shift_reg(2) <= shift_reg(1);
			shift_reg(3) <= shift_reg(2);
			shift_reg(4) <= shift_reg(3);
			shift_reg(5) <= shift_reg(4);
			shift_reg(6) <= shift_reg(5);
			shift_reg(7) <= shift_reg(6);
			shiftingOutput <= 'Z';
		elsif (q1 = '1' AND q2 = '0') then
			-- need to shift our output
			shiftingOutput <= shift_reg(7);
			shift_reg(7) <= shift_reg(6);
			shift_reg(6) <= shift_reg(5);
			shift_reg(5) <= shift_reg(4);
			shift_reg(4) <= shift_reg(3);
			shift_reg(3) <= shift_reg(2);
			shift_reg(2) <= shift_reg(1);
			shift_reg(1) <= shift_reg(0);
			shift_reg(0) <= '0';
		elsif (q1 = '1' AND q2 = '1') then
			shift_reg <= serialIn;	-- no need to shift
			shiftingOutput <= 'Z';
		else -- in the case of other input
			shiftingOutput <= 'Z';
		end if;
	end process;
end shiftRegisterTop_func;
