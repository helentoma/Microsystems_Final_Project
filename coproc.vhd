
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity coproc is
  port(	CLK:	in std_logic;
        RST:  in std_logic;
        WE:    out  std_logic;
        ADDR:  out  std_logic_vector(22 downto 0);
        D_IN:  in  std_logic_vector(7 downto 0);
        D_OUT: out std_logic_vector(7 downto 0);
        SDA:  inout std_logic;
        SCL:  in std_logic;
        INT:  out std_logic
  );
end entity;

architecture behv of coproc is
  constant matrixBOffset: natural := 0;
  constant newImgOffset: natural := 1920*270;

  type i2c_state_t is (IDLE,ADDR_RD,ADDR_RD_ACK,DATA_RD,DATA_RD_ACK);
  type regfile is array (0 to 15) of std_logic_vector(7 downto 0);
  constant MY_ADDR: std_logic_vector(7 downto 0) := "00000010";
  signal I2C_START, I2C_STOP, I2C_RDY: std_logic;
  signal I2C_ADDR: std_logic_vector(7 downto 0);
  signal I2C_REG: regfile;
  signal I2C_ST, I2C_N_ST: i2c_state_t;
  signal c: natural range 0 to 7;
  signal c_match: natural range 0 to 7;
  signal r: natural range 0 to 15;

  type cp_state_t is (CP_IDLE,CP_READ_MEM,CP_VERIFY,CP_DONE);
  signal CP_STATE: cp_state_t;
  signal TMP0, TMP1, TMP2, TMP3: std_logic_vector(7 downto 0);

  signal slave_data_in	: STD_LOGIC_VECTOR (7 DOWNTO 0) := "00000000";
  signal slave_data_out	: STD_LOGIC_VECTOR (7 DOWNTO 0) := "00000000";
  signal slave_wr	: STD_LOGIC := '0';
  signal slave_ack	: STD_LOGIC := '0';
  signal slave_writing	: STD_LOGIC := '0';
  signal slave_start	: STD_LOGIC := '0';
  signal slave_finish	: STD_LOGIC := '0';

  type matrixMult is array (0 to 2**21) of STD_LOGIC_VECTOR (7 DOWNTO 0);

  component i2c_slave is port  (clock		: IN STD_LOGIC;
			        inputData	: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			  	outputData	: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			  	sda		: INOUT STD_LOGIC;
			  	scl		: IN STD_LOGIC;
			  	wr		: OUT STD_LOGIC;
			  	ack		: OUT STD_LOGIC;
			  	writing		: OUT STD_LOGIC;
			  	startProcess	: OUT STD_LOGIC;
			  	endProcess	: OUT STD_LOGIC);
  end component i2c_slave;

  signal A_matrix	: matrixMult;
  signal B_matrix	: matrixMult;
  signal result_matrix	: matrixMult;
  
begin


  slave: i2c_slave port map (clk => CLK,
  			     inputData => slave_data_in,
			     outputData => slave_data_out,
			     sda => SDA,
			     scl => SCL,
			     wr => slave_wr,
			     ack => slave_ack,
			     writing => slave_writing,
			     startProcess => slave_start,
			     endProcess => slave_finish);

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
      I2C_ADDR <= "00000000";
      for i in I2C_REG'range loop
        I2C_REG(i) <= "00000000";
      end loop;
    elsif I2C_STOP'event and I2C_STOP ='1' and RST='0' then
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
    variable c: natural;
  begin
    if RST'event and RST='1' then
      ADDR <= "ZZZZZZZZZZZZZZZZZZZZZZZ";
      D_OUT <= "ZZZZZZZZ";
      WE <= 'Z';
      CP_STATE <= CP_IDLE;
      c := 0;
      INT <= '0';
    elsif CLK'event and CLK='1' and RST='0' then
      case CP_STATE is
        when CP_IDLE =>
          INT <= '0';
          if I2C_ADDR=MY_ADDR and I2C_RDY='1' then
            CP_STATE <= CP_READ_MEM;
          else
            CP_STATE <= CP_IDLE;
          end if;
        when CP_READ_MEM =>
          if c=0 then
            ADDR <= "00000000000000000000000";
          elsif c=1 then
            TMP0 <= D_IN;
          elsif c=2 then
            ADDR <= "00000000000000000000001";
          elsif c=3 then
            TMP1 <= D_IN;
          elsif c=4 then
            ADDR <= "00000000000000000000010";
          elsif c=5 then
            TMP2 <= D_IN;
          elsif c=6 then
            ADDR <= "00000000000000000000011";
          elsif c=7 then
            TMP1 <= D_IN;
          end if;
          c := c+1;
          if c=8 then
            CP_STATE <= CP_VERIFY;
          else
            CP_STATE <= CP_READ_MEM;
          end if;
        when CP_VERIFY =>
          if TMP0 = I2C_REG(0) and TMP0 = I2C_REG(0) and TMP0 = I2C_REG(0) and TMP0 = I2C_REG(0) then
            report "TEST PASSED!!!";
          else
            report "TEST FAILED";
          end if;
          CP_STATE <= CP_DONE;
        when CP_DONE =>
          CP_STATE <= CP_DONE;
          INT <= '1';
      end case;
    end if;
  end process;
end behv;
