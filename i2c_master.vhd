library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity i2c_master is port (clock	: IN STD_LOGIC;
			   reset	: IN STD_LOGIC;
			   data		: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			   sda		: INOUT STD_LOGIC;
			   scl		: OUT STD_LOGIC;
			   wr		: IN STD_LOGIC);
end i2c_master;

architecture master_func of i2c_master is
begin
end master_func;
