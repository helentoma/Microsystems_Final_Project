library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity top is
end entity;

architecture tb of top is
  constant matrixBFile: string := "./matrixb.dat";
  constant matrixBOffset: integer := 0;

  component cpu is
    port(	CLK:	 in std_logic;
          RST:	 in std_logic;
          WE:    out  std_logic;
          ADDR:  out  std_logic_vector(22 downto 0);
          D_IN:  in  std_logic_vector(7 downto 0);
          D_OUT: out std_logic_vector(7 downto 0);
          SDA:   inout std_logic;
          SCL:   out std_logic
    );
  end component;

  component coproc is
    port( CLK:   in std_logic;
          RST:   in std_logic;
          WE:    out  std_logic;
          ADDR:  out  std_logic_vector(22 downto 0);
          D_IN:  in  std_logic_vector(7 downto 0);
          D_OUT: out std_logic_vector(7 downto 0);
          SDA:   inout std_logic;
          SCL:   in std_logic
     );
  end component;

  component ram is
    port (
      CLK     : in  std_logic;
      RST     : in  std_logic;
      WE      : in  std_logic;
      ADDR    : in  std_logic_vector;
      D_IN    : in  std_logic_vector;
      D_OUT   : out std_logic_vector
    );
  end component;

  signal CLK_T, RST_T, SDA_T, SCL_T, WE_T: std_logic;
  signal ADDR_T: std_logic_vector(22 downto 0);
  signal D_IN_T, D_OUT_T: std_logic_vector(7 downto 0);
begin

  -- Hold these lines high at all times (THINK PULLUP RESISTOR HERE)
  PULLUP_SDA: SDA_T <= 'H';
  PULLUP_SCL: SCL_T <= 'H';
  PULLDOWN_WE: WE_T <= 'L';

  -- 1 GHz Clock to drive the CPU and Co-Proc.
  CLOCK: process begin
    CLK_T <= '0';
    wait for 0.5 ns;
    CLK_T <= '1';
    wait for 0.5 ns;
  end process;

  CPU0: cpu port map(CLK_T,RST_T,WE_T,ADDR_T,D_OUT_T,D_IN_T,SDA_T,SCL_T);
  CP0: coproc port map(CLK_T,RST_T,WE_T,ADDR_T,D_OUT_T,D_IN_T,SDA_T,SCL_T);
  RAM0: ram port map(CLK_T,RST_T,WE_T,ADDR_T,D_IN_T,D_OUT_T);

  INIT: process begin
    -- System starts off with a reset
    RST_T <= '1';
    wait for 100 ns;
    RST_T <= '0';
    -- Now the system runs forever... At this point the CPU would load some boot
    -- up code from ROM and then bootstrap the application (which could be an OS)

    wait;
  end process;

end tb;
