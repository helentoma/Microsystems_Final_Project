library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.ram.all;

entity top is
end entity;

architecture tb of top is
  constant matrixBFile: string := "./matrixb.dat";
  constant matrixBOffset: integer := 0;

  component cpu is
    port(	CLK:	in std_logic;
          RST:	in std_logic;
          RAM:  inout ram_type;
          SDA:  inout std_logic;
          SCL:  out std_logic
    );
  end component;

  -- component coproc is
  --   port( CLK:  in std_logic;
  --         RST:  in std_logic;
  --         RAM:  inout ram_type;
  --         SDA:  inout std_logic;
  --         SCL:  in std_logic
  --   );
  -- end component;

  signal CLK_T, RST_T, SDA_T, SCL_T: std_logic;
  signal RAM_T: ram_type;
begin

  -- Hold these lines high at all times (THINK PULLUP RESISTOR HERE)
  PULLUP_SDA: SDA_T <= 'H';
  PULLUP_SCL: SCL_T <= 'H';

  -- 1 GHz Clock to drive the CPU and Co-Proc.
  CLOCK: process begin
    CLK_T <= '0';
    wait for 0.5 ns;
    CLK_T <= '1';
    wait for 0.5 ns;
  end process;

  CPU0: cpu port map(CLK_T,RST_T,RAM_T,SDA_T,SCL_T);
  --MMULTI: coproc port map(CLK_T,RST_T,RAM_T,SDA_T,SCL_T);

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
