library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.Numeric_Std.all;

entity ram is
  port (
    CLK     : in  std_logic;
    RST     : in  std_logic;
    WE      : in  std_logic;
    ADDR    : in  std_logic_vector(22 downto 0);
    D_IN    : in  std_logic_vector(7 downto 0);
    D_OUT   : out std_logic_vector(7 downto 0)
  );
end entity ram;

architecture RTL of ram is
   type ram_type is array (0 to (2**ADDR'length)-1) of std_logic_vector(D_IN'range);
   signal ram : ram_type;
   signal read_address : std_logic_vector(ADDR'range);
begin
  RamProc: process(CLK,RST) is
  begin
    if RST'event and RST='1' then
      for i in ram'range loop
        ram(i) <= "00000000";
      end loop;
    elsif CLK'event and CLK='1' and RST='0' then
        if WE = '1' then
          ram(to_integer(unsigned(ADDR))) <= D_IN;
        end if;
        read_address <= ADDR;
      else

    end if;
  end process RamProc;

  D_OUT <= ram(to_integer(unsigned(read_address)));

end architecture RTL;
