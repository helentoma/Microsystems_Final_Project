library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- I just copied what I had for master and changed what needed to be changed
entity i2c_slave is port (clock		: IN STD_LOGIC;
			  inputData	: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			  outputData	: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			  sda		: INOUT STD_LOGIC;
			  scl		: IN STD_LOGIC;
			  wr		: OUT STD_LOGIC;
			  ack		: OUT STD_LOGIC;
			  writing	: OUT STD_LOGIC;
			  startProcess	: OUT STD_LOGIC;
			  endProcess	: OUT STD_LOGIC);
end i2c_slave;

-- Note: I am using rising_edge() instead of (clock'EVENT AND clock = '1') because
-- we are using 'H' and 'L' and not just 0 and 1. Accosrding to Slack Overflow,
-- rising_edge() detects those changes better.

architecture slave_func of i2c_slave is
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
			    state26, state27, state28, state29, state30, state31);

	-- variables with initial values:
	signal nxt			: state_type;
	signal curr			: state_type := state1;
	signal start			: STD_LOGIC := '0';
	signal finish			: STD_LOGIC := '1';
	signal shift_reg_clock		: STD_LOGIC := '0';
	signal shift_reg_q1		: STD_LOGIC := '0';
	signal shift_reg_q2		: STD_LOGIC := '0';
	signal shift_reg_output		: STD_LOGIC;
	signal shift_reg_outData	: STD_LOGIC_VECTOR (7 DOWNTO 0);	
	signal buffer_enable_sda	: STD_LOGIC := '0';
	signal buffer_enable_scl	: STD_LOGIC := '0';
	signal read_or_write		: STD_LOGIC;

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

-- initial values:
wr <= TO_X01(read_or_write);
outputData <= shift_reg_outData;
startProcess <= start;
endProcess <= finish;

shift_register : shiftRegisterTop port map (clock => shift_reg_clock,
					    serialIn => inputData,
					    serialOut => shift_reg_outData,
					    q1 => shift_reg_q1,
					    q2 => shift_reg_q2,
					    shiftingInput => sda,
					    shiftingOutput => shift_reg_output);

sda_activeLow_buff :  activeLow port map (enable => buffer_enable_sda,
					 bufferInput => '0',
					 bufferOutput => sda);

-- I guess we need a buffer for the shift register as well. This to run the output of the reg
shift_reg_buff : activeLow port map (enable => shift_reg_output,
				     bufferInput => '0',
				     bufferOutput => sda);



FINITE_STATE_MACHINE_SCL:
PROCESS (scl, finish)
BEGIN
	if(start = '1' AND finish = '1') then
		start <= '0';	-- do not start the signal
	elsif(start = '0' AND finish = '1') then
		if (falling_edge(scl) AND TO_X01(sda) = '0') then	-- rising_egde is a function provided by
							-- VHDL which looks when the value is 1
			start <= '1'; -- only start the signal at rising edges
		end if;
	end if;
END PROCESS; -- of FINITE_STATE_MACHINE

RST_FINITE_STATE_MACHINE_SCL:
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

UPDATING_CURRENT_STATE_SCL:
PROCESS(sda, scl)
BEGIN
	if (finish = '0' AND rising_edge(sda) AND TO_X01(scl) = '1') then
		if(NOT(falling_edge(scl))) then
			curr <= state1;
		end if;
	-- in the case of the other states and if the clock's falling edge is true, still update the current
	elsif(rising_edge(scl)) then
		if (curr = state1 OR curr = state2 OR curr = state3 OR curr = state4 OR
		    curr = state5 OR curr = state6 OR curr = state7 OR curr = state8 OR
		    curr = state11 OR curr = state12 OR curr = state13 OR
		    curr = state14 OR curr = state15 OR curr = state16 OR curr = state17 OR
		    curr = state27 OR curr = state28 OR curr = state30 OR curr = state31) then
			curr <= nxt;
		end if;
	elsif(falling_edge(scl)) then
		if(curr = state9 OR curr = state10 OR curr = state18 OR curr = state19 OR
		   curr = state20 OR curr = state21 OR curr = state22 OR curr = state23 OR
		   curr = state24 OR curr = state25 OR curr = state26 OR curr = state29) then
			curr <= nxt;
		end if;
	end if;
END PROCESS; -- of UPDATING_CURRENT_STATE

-- this is used to sign values to variables for each state. 
SIGNALS_STATE_MACHINE_SCL:
PROCESS (start, curr)
BEGIN
	-- initial values of these because they only change in couple of states
	ack <= '0';
	writing <= '0';

	case curr is
		-- Idle
		when state1 =>
			if (start = '0') then
				nxt <= state1;
			else
				nxt <= state30;
			end if;

			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '0';
		
		when state2 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state3;

		when state3 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state4;

		when state4 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state5;

		when state5 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state6;

		when state6 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state7;

		when state7 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state8;
	
		when state8 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state9;

		when state9 =>
			if (TO_X01(sda) = '0') then
				writing <= '0';
			else
				writing <= '1';
			end if;
			
			read_or_write <= sda;
			buffer_enable_sda <= '1';	
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '1';
			nxt <= state10;	

		when state10 =>
			if (read_or_write = '0') then
				buffer_enable_sda <= '0';
				nxt <= state31;
			else
				if(shift_reg_outData (7 DOWNTO 1) /= "000000H") then
					buffer_enable_sda <= '1';
					nxt <= state1;
				else
					buffer_enable_sda <= '0';
					nxt <= state20;
				end if;
			end if;

			shift_reg_q1 <= '1';
			shift_reg_q2 <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);
		
		when state11 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state12;

		when state12 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state13;

		when state13 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state14;

		when state14 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state15;

		when state15 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state16;

		when state16 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state17;

		when state17 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state18;

		when state18 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state19;

		when state19 =>
			buffer_enable_sda <= '0';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '0';
			ack <= '1';
			nxt <= state31;

		when state20 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '1';
			shift_reg_q2 <= '0';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state21;	

		when state30 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '0';
			nxt <= state2;

		when state31 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '0';
			nxt <= state11;

		when state21 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '1';
			shift_reg_q2 <= '0';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state22;

		when state22 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '1';
			shift_reg_q2 <= '0';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state23;

		when state23 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '1';
			shift_reg_q2 <= '0';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state24;

		when state24 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '1';
			shift_reg_q2 <= '0';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state25;

		when state25 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '1';
			shift_reg_q2 <= '0';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state26;

		when state26 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '1';
			shift_reg_q2 <= '0';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state27;
		
		when state27 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '1';
			shift_reg_q2 <= '0';
			shift_reg_clock <= NOT(shift_reg_clock);
			nxt <= state28;

		when state28 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '0';
			shift_reg_q2 <= '0';
			nxt <= state29;

		when state29 =>
			buffer_enable_sda <= '1';
			shift_reg_q1 <= '1';
			shift_reg_q2 <= '1';
			writing <= '1';
			shift_reg_clock <= NOT(shift_reg_clock);			

			if(TO_X01(sda) = '0') then
				nxt <= state20;
			else
				nxt <= state1;
			end if;
	end case;
END PROCESS; -- of SIGNALS_STATE_MACHINE

end slave_func;

