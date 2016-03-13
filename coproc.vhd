
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use std.env.all;

entity coproc is
  port(	CLK:	in std_logic;
        RST:  in std_logic;
        WE:    out  std_logic;
        ADDR:  out  std_logic_vector(22 downto 0);
        D_IN:  in  std_logic_vector(7 downto 0);
        D_OUT: out std_logic_vector(7 downto 0);
        SDA:  inout std_logic;
        SCL:  in std_logic
  );
end entity;

architecture behv of coproc is
  constant matrixBOffset: natural := 0;
  constant newImgOffset: natural := 1920*270;
  constant MY_ADDR: std_logic_vector(7 downto 0) := "00000010";

  type i2c_state_t is (IDLE,ADDR_RD,ADDR_RD_ACK,DATA_RD,DATA_RD_ACK);
  type regfile is array (0 to 15) of std_logic_vector(7 downto 0);
  signal I2C_START, I2C_STOP, I2C_RDY: std_logic;
  signal I2C_ADDR: std_logic_vector(7 downto 0);
  signal I2C_REG: regfile;
  signal I2C_ST, I2C_N_ST: i2c_state_t;

  signal c: natural range 0 to 7;
  signal c_match: natural range 0 to 7;
  signal r: natural range 0 to 15;
begin
  I2C_START_DETECTOR: process (SDA, I2C_ST) is
  begin
    if SDA'event and SDA='0' and (SCL='1' or SCL='H') and (I2C_ST = IDLE) then
      I2C_START <= '1';
    else
      I2C_START <= '0';
    end if;
  end process;

  I2C_STOP_DETECTOR: process (SDA, I2C_ST) is
  begin
    if SDA'event and (SDA='1' or SDA='H') and (SCL='1' or SCL='H') and (I2C_ST = DATA_RD) then
      I2C_STOP <= '1';
    else
      I2C_STOP <= '0';
    end if;
  end process;

  I2C_FSM_SEQ: process (SCL,RST,I2C_STOP) is
  begin
    if RST'event and RST='1' then
      I2C_ST <= IDLE;
      c <= 0;
      r <= 0;
    elsif I2C_STOP'event and I2C_STOP ='1' then
      I2C_ST <= IDLE;
      c <= 0;
      r <= 0;
    elsif SCL'event and SCL='0' then
      if I2C_ST = ADDR_RD then
        if SDA = '1' or SDA = 'H' then
          I2C_ADDR(7-c) <= '1';
        else
          I2C_ADDR(7-c) <= '0';
        end if;
      elsif I2C_ST = DATA_RD then
        if SDA = '1' or SDA = 'H' then
          I2C_REG(r)(7-c) <= '1';
        else
          I2C_REG(r)(7-c) <= '0';
        end if;
      end if;

      if c = c_match then
        if I2C_ST = DATA_RD_ACK then
          r <= r + 1;
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

  I2C_FSM_COMB: process (I2C_ST,I2C_ADDR,I2C_START) is
  begin
      case I2C_ST is
        when IDLE =>
          I2C_RDY <= '1';
          SDA <= 'Z';
          c_match <= 0;
          if I2C_START = '1' then
            I2C_N_ST <= ADDR_RD;
          else
            I2C_N_ST <= IDLE;
          end if;
        when ADDR_RD =>
          I2C_RDY <= '0';
          SDA <= 'Z';
          c_match <= 7;
          I2C_N_ST <= ADDR_RD_ACK;
        when ADDR_RD_ACK =>
          I2C_RDY <= '0';
          if MY_ADDR = I2C_ADDR then
            SDA <= '0';
            I2C_N_ST <= DATA_RD;
          else
            SDA <= 'Z';
            I2C_N_ST <= IDLE;
          end if;
          c_match <= 0;
        when DATA_RD =>
          I2C_RDY <= '0';
          SDA <= 'Z';
          I2C_N_ST <= DATA_RD_ACK;
          c_match <= 7;
        when DATA_RD_ACK =>
          I2C_RDY <= '0';
          SDA <= '0';
          I2C_N_ST <= DATA_RD;
          c_match <= 0;
      end case;
  end process;

  CO_PROC_CNTRL: process(CLK, RST) is
  begin
    if RST'event and RST='1' then
      ADDR <= "ZZZZZZZZZZZZZZZZZZZZZZZ";
      D_OUT <= "ZZZZZZZZ";
      WE <= 'Z';
    end if;
  end process;

  TESTING_PROC: process is
  begin
    wait until RST='1';
    wait until RST='0';
    wait until I2C_RDY='0';
    wait until I2C_RDY='1';

    wait;
  end process;
end behv;
