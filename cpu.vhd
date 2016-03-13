
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use std.env.all;

entity cpu is
  port(	CLK:	in std_logic;
        RST:  in std_logic;
        WE:    out  std_logic;
        ADDR:  out  std_logic_vector(22 downto 0);
        D_IN:  in  std_logic_vector(7 downto 0);
        D_OUT: out std_logic_vector(7 downto 0);
        SDA:  inout std_logic;
        SCL:  out std_logic
  );
end entity;

architecture tb of cpu is
  constant matrixBOffset: natural := 0;
  constant newImageFile: string := "./image.dat";
  constant newImgOffset: natural := 1920*270;
  constant i2cCmdOffset: natural := 1080*1920 + 1920*270;

  type i2c_state_t is (IDLE,START,DATA_WR,DATA_WR_ACK,STOP);
  type regfile is array (0 to 15) of std_logic_vector(7 downto 0);
  signal I2C_ACLK, I2C_DCLK, I2C_BCLK: std_logic;
  signal I2C_GO, I2C_R_OR_W, I2C_RDY, I2C_FAIL, I2C_RST: std_logic;
  signal I2C_DATA_LEN: natural range 0 to 15;
  signal I2C_REG: regfile;
  signal I2C_ST, I2C_N_ST: i2c_state_t;

  signal c: natural range 0 to 7;
  signal c_match: natural range 0 to 7;
  signal r: natural range 0 to 15;
begin
  -- This is the emulator for the CPU in this architecture. You can think of
  -- this as running a program that is tracking an object from an HD video
  -- camera feed using the KLT algorithm. The only part that you will show
  -- is where the program offloads a matrix multiplication to the co-processor
  ACLK: process (CLK,RST) is
    variable count: natural range 0 to 31;
  begin
    if RST'event and RST='1' then
      I2C_ACLK <= '0';
      count := 0;
    elsif CLK'event and CLK='1' then
      count := count + 1;
      if count = 31 then
        I2C_ACLK <= not I2C_ACLK;
        count := 0;
      end if;
    end if;
  end process;

  D_B_CLKS: process (I2C_ACLK,RST) is
    variable count: natural range 0 to 4;
  begin
    if RST'event and RST='1' then
      count := 0;
      I2C_BCLK <= '0';
      I2C_DCLK <= '0';
    elsif I2C_ACLK'event and I2C_ACLK='1' then
      count := count + 1;
      if count = 1 then
        I2C_BCLK <= '0';
      elsif count = 2 then
        I2C_DCLK <= '1';
      elsif count = 3 then
        I2C_BCLK <= 'Z';
      else
        I2C_DCLK <= '0';
        count := 0;
      end if;
    end if;
  end process;

  I2C_FSM_SEQ: process (I2C_DCLK,RST) is
  begin
    if RST'event and RST='1' then
      I2C_ST <= IDLE;
      I2C_FAIL <= '0';
      c <= 0;
      r <= 0;
    elsif I2C_DCLK'event and I2C_DCLK='1' then
      if c = c_match then
        if I2C_ST = DATA_WR_ACK then
          r <= r + 1;
          if SDA ?= '1' then
            I2C_FAIL <= '1';
          else
            I2C_FAIL <= '0';
          end if;
        elsif I2C_ST = IDLE then
          r <= 0;
        end if;
        c <= 0;
        I2C_ST <= I2C_N_ST;
      else
        c <= c + 1;
      end if;
    end if;
  end process;

  I2C_FSM_COMB: process (I2C_ST, I2C_BCLK, I2C_REG, I2C_GO, I2C_R_OR_W,r,c) is
  begin
      case I2C_ST is
        when IDLE =>
          I2C_RDY <= '1';
          SCL <= 'Z';
          SDA <= 'Z';
          c_match <= 0;
          if I2C_GO = '1' then
            I2C_N_ST <= START;
          end if;
        when START =>
          I2C_RDY <= '0';
          SCL <= 'Z';
          SDA <= '0';
          c_match <= 0;
          if I2C_R_OR_W='1' then
            I2C_N_ST <= IDLE; -- THIS SHOULD BE DATA_RD
          else
            I2C_N_ST <= DATA_WR;
          end if;
        when DATA_WR =>
          I2C_RDY <= '0';
          SCL <= I2C_BCLK;
          if I2C_REG(r)(7-c) = '1' then
            SDA <= 'Z';
          else
            SDA <= '0';
          end if;
          c_match <= 7;
          I2C_N_ST <= DATA_WR_ACK;
        when DATA_WR_ACK =>
          I2C_RDY <= '0';
          SCL <= I2C_BCLK;
          SDA <= 'Z';
          c_match <= 0;
          if r=I2C_DATA_LEN-1 then
            I2C_N_ST <= STOP;
          else
            I2C_N_ST <= DATA_WR;
          end if;
        when STOP =>
          I2C_RDY <= '0';
          SCL <= 'Z';
          SDA <= '0';
          c_match <= 0;
          I2C_N_ST <= IDLE;
      end case;
  end process;


  assert I2C_FAIL='0'
    report "ACK NOT RECV, RESETTING I2C"
    severity warning;
  PROGRAM_EXE: process is
  begin
    wait until RST='1';
    I2C_R_OR_W <= '0';
    I2C_GO <= '0';
    I2C_DATA_LEN <= 0;
    for idx in I2C_REG'range loop
      I2C_REG(idx) <= "00000000";
    end loop;
    ADDR <= "ZZZZZZZZZZZZZZZZZZZZZZZ";
    D_OUT <= "ZZZZZZZZ";
    WE <= 'Z';
    wait until RST='0';


    -- The matrix which we will multiply by was in the programs data section
    -- which would have been loading into memory when the process was first
    -- loaded and executed. To simulate this, we will read in the matrix from
    -- a file here after the reset. (Just the matrix, not an actual program)

    -- This file read is simulating a new image being recieved from the camera

    -- At this point in the program a new image has just been recieved and a
    -- matrix multiplication is now required in the algorithm
    wait until CLK='1';
    I2C_R_OR_W <= '0';
    wait until CLK='1';
    I2C_DATA_LEN <= 5;
    wait until CLK='1';
    I2C_REG(0) <= "00000010";
    wait until CLK='1';
    I2C_REG(1) <= "01010101";
    wait until CLK='1';
    I2C_REG(2) <= "10100101";
    wait until CLK='1';
    I2C_REG(3) <= "00110011";
    wait until CLK='1';
    I2C_REG(4) <= "00101010";
    wait until CLK='1';
    I2C_GO <= '1';
    wait until I2C_RDY='0';
    I2C_GO <= '0';
    wait until I2C_RDY='1';

    wait for 1 us;
    stop(1);
  end process;

end tb;
