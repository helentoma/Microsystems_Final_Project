library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity i2c_master is port (clock	: IN STD_LOGIC;
			   reset	: IN STD_LOGIC;
			   inputData	: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			   outputData	: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			   sda		: INOUT STD_LOGIC;
			   scl		: OUT STD_LOGIC;
			   wr		: IN STD_LOGIC;
			   ack		: OUT STD_LOGIC;
			   startProcess	: IN STD_LOGIC;
			   endProcess	: IN STD_LOGIC);
end i2c_master;

architecture master_func of i2c_master is
-- This is not going to be pretty, but it is the only way I could process this
-- project. I am working on 32 states. Each state is being assigned values. This
-- is similar to what we did in lab 2 but a bit more tricky.

-- shifting register
	component shiftRegisterTop is port (clock		: IN STD_LOGIC;
				 	    serialIn		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				 	    serialOut		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
				 	    q1			: IN STD_LOGIC;
				 	    q2			: IN STD_LOGIC;
				 	    shiftingInput	: IN STD_LOGIC;
				 	    shiftingOutput	: OUT STD_LOGIC);
	end component shiftRegisterTop;

-- using an active low buffer (needed for the states)
	component activeLow is port (enable		: IN STD_LOGIC;
			  	     bufferInput	: IN STD_LOGIC;
			  	     bufferOutput	: OUT STD_LOGIC);
	end component activeLow;
	
	type state_type is (state1, state2, state3, state4, state5, state6, state7,
			    state8, state9, state10, state11, state12, state13, 
			    state14, state15, state16, state17, state18, state19,
			    state20, state21, state22, state23, state24, state25,
			    state26, state27, state28, state29, state30, state31,
			    state32);

	-- variables with initial values:
	signal nxt			: state_type;
	signal curr			: state_type := state1;
	signal start			: STD_LOGIC := '0';
	signal finish			: STD_LOGIC := '1';
	signal shift_reg_clock		: STD_LOGIC := '0';
	signal shift_reg_q1		: STD_LOGIC := '0';
	signal shift_reg_q2		: STD_LOGIC;
	signal shift_reg_output		: STD_LOGIC;
	signal buffer_enable_sda	: STD_LOGIC := '0';
	signal buffer_enable_scl	: STD_LOGIC := '0';
	signal start_clock		: STD_LOGIC := '0';
	signal temp_clock		: STD_LOGIC := '1';

--curr := state1;
--start := '0';
--finish := '1';
--shift_reg_clock := '0';
--shift_reg_q1 := '0';
--shift_reg_q2 := '0';
--buffer_enable_sda := '0';
--buffer_enable_scl := '0';
--start_clock := '0';
--temp_clock := '1';

begin

shift_register : shiftRegisterTop port map (clock => shift_reg_clock,
					    serialIn => inputData,
					    serialOut => outputData,
					    q1 => shift_reg_q1,
					    q2 => shift_reg_q2,
					    shiftingInput => sda,
					    shiftingOutput => shift_reg_output);

scl_activeLow_buff : activeLow port map (enable => buffer_enable_scl,
					 bufferInput => '0',
					 bufferOutput => scl);

sda_activeLow_buff :  activeLow port map (enable => buffer_enable_sda,
					 bufferInput => '0',
					 bufferOutput => sda);

-- I guess we need a buffer for the shift register as well. This to run the output of the reg
shift_reg_buff : activeLow port map (enable => shift_reg_output,
				     bufferInput => '0',
				     bufferOutput => sda);

sda <= 'H';
scl <= 'H';

SCL_SWITCH:
PROCESS (clock)
BEGIN
	if (start_clock = '1') then
		if(temp_clock = '0') then
			buffer_enable_scl <= '0';
		else
			buffer_enable_scl <= '1';
		end if;
		-- invert the clock
		temp_clock <= not(temp_clock);
	end if;
END PROCESS;	-- of SCL_SWITCH

FINITE_STATE_MACHINE:
PROCESS (startProcess, finish)
BEGIN
	if(start = '1' AND finish = '1') then
		start <= '0';	-- do not start the signal
	else
		if (rising_edge(startProcess)) then	-- rising_egde is a function provided by
							-- VHDL which looks when the value is 1
			start <= '1'; -- only start the signal at rising edges
		end if;
	end if;
END PROCESS; -- of FINITE_STATE_MACHINE

RST_FINITE_STATE_MACHINE:
PROCESS (curr)	-- resting by munapulating the finish time
BEGIN
	-- if the current state is the first state then the progarm is reseted
	-- otherwise, we send a signal not finished so we can reset the FSM
	if(curr = state1) then
		finish <= '1';
	else
		finish <= '0';
	end if;
END PROCESS;	-- of RST_FINITE_STATE_MACHINE

end master_func;
