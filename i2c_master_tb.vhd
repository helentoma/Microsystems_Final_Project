library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity i2c_master_tb is
end i2c_master_tb;

architecture master_tb_func of i2c_master_tb is

component i2c_master port (clock	: IN STD_LOGIC;
			   inputData	: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			   outputData	: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			   sda		: INOUT STD_LOGIC;
			   scl		: OUT STD_LOGIC;
			   wr		: IN STD_LOGIC;
			   ack		: OUT STD_LOGIC;
			   writing	: OUT STD_LOGIC;
			   startProcess	: IN STD_LOGIC;
			   endProcess	: IN STD_LOGIC);
end component i2c_master;

signal clk 	: STD_LOGIC := '1';
signal in_data  : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal out_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal this_sda : STD_LOGIC;
signal this_scl : STD_LOGIC;
signal this_wr  : STD_LOGIC;
signal this_ack : STD_LOGIC;
signal this_write : STD_LOGIC;
signal starting : STD_LOGIC;
signal ending : STD_LOGIC;

begin

	master_test: i2c_master port map (clock => clk,
					  inputData => in_data,
					  outputData => out_data,
					  sda => this_sda,
					  scl => this_scl,
					  wr => this_wr,
					  ack => this_ack,
					  writing => this_write,
					  startProcess => starting,
					  endProcess => ending);

-- simple test. Can we invert the master signal?
TEST_CLK:
process
begin
	wait for 20 us;
	clk <= NOT clk;
end process;

MORE_TEST:
process
begin
	this_wr <= '0';
	starting <= '0';
	ending <= '0';

	wait for 50 us;
	starting <= '1';

	wait for 100 us;
	in_data <= "10001100";

	wait for 150 us;
	ending <= '1';

	wait for 200 us;
	this_wr <= '1';

	wait for 250 us;
	in_data <= "11111111";

	assert (this_ack = '1' OR this_ack = '0');
	assert (TO_X01(this_scl) = '1' OR this_scl = '0');
	assert (TO_X01(this_sda) = '1' OR this_sda = '0');
	assert (this_wr = '1' OR this_wr = '0');

	wait;

end process;
end master_tb_func;



