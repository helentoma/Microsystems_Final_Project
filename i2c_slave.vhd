library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity i2c_slave is port (clock		: IN STD_LOGIC;
			  reset		: IN STD_LOGIC;
			  data		: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			  sda		: INOUT STD_LOGIC;
			  scl		: IN STD_LOGIC;
			  rd		: IN STD_LOGIC);
end i2c_slave;

architecture func of i2c_slave is
begin
end func;
