library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- This is a valve (Tri-state buffer). It is an active low buffer (control has a bubble). 
-- it is useful because we have 32 states to control. Read this article to understand it:
-- https://startingelectronics.org/software/VHDL-CPLD-course/tut16-tri-state-buffer/
entity activeLow is port (enable	: IN STD_LOGIC;
			  bufferInput	: IN STD_LOGIC;
			  bufferOutput	: OUT STD_LOGIC);
end activeLow;

architecture activeLowBuffer_func of activeLow is
begin

	bufferOutput <= bufferInput when (enable = '0') else 'Z';

end activeLowBuffer_func;
