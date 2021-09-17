entity test_polydiv is
end entity;

library ieee;
use ieee.std_logic_1164.all;
library std;
library local;
use local.testbench.all;

architecture behav of test_polydiv is

  -- Example from https://en.wikipedia.org/wiki/Cyclic_redundancy_check
  -- constant message    : std_ulogic_vector := "11010011101100" & "000"; -- message padded by 3 bits
  -- constant poly       : std_ulogic_vector := "1011";
  -- constant data_width : positive := 1;
  -- constant answer     : std_ulogic_vector := "100";
  -- http://www.ee.unb.ca/cgi-bin/tervo/calc.pl?num=11010011101100000&den=1011&f=d&e=1&p=1&m=1

  constant message    : std_ulogic_vector := "101001011010";
  constant poly       : std_ulogic_vector := "11010";
  constant data_width : positive := 3;
  constant answer     : std_ulogic_vector := "1000";

  -- Taken example from https://math.stackexchange.com/questions/682301/modulo-2-binary-division-xor-not-subtracting-method
  -- Which looks spookily like a copy & paste from http://www.ee.unb.ca/cgi-bin/tervo/calc.pl?num=111001010000&den=11011&f=d&e=1&p=1&m=1
  --
  --     10101100 quotient
  -- ------------
  -- 111001010000 dividend  x^11+x^10+x^9+x^6+x^4
  -- 11011        divisor   x^4+x^3+x+1
  -- -----
  --  01111
  --  00000  reg'high = 0
  --  -----
  --   11110
  --   11011  reg'high = 1
  --   -----
  --    01011
  --    00000  reg'high = 0
  --    -----
  --     10110
  --     11011  reg'high = 1
  --     -----
  --      11010
  --      11011  reg'high = 1
  --      -----
  --       00010
  --       00000  reg'high = 0
  --       -----
  --        00100
  --        00000  reg'high = 0
  --        -----
  --         0100 * remainder *

  signal reset         : std_ulogic;
  signal clk           : std_ulogic;
  signal data_in       : std_ulogic_vector(0 to 2);
  signal data_valid_in : std_ulogic;
  signal data_out      : std_ulogic_vector(poly'length-2 downto 0);
  
begin

  dut : entity work.polydiv
    generic map(
      poly => poly
    )
    port map(
      clk           => clk,
      reset         => reset,
      data_in       => data_in,
      data_valid_in => data_valid_in,
      data_out      => data_out
    );

  clock(clk, 5 ns, 5 ns);
  
  assert ((message'length / data_in'length) * data_in'length) = message'length
    report "The message length must be divisible by data_in's length."
    severity failure;
  
  process
  begin
    reset         <= '0';
    data_in       <= (others => '0');
    data_valid_in <= '0';
    wait_nr_ticks(clk, 1);
    toggle_r(reset, clk, 2);
    wait_nr_ticks(clk, 2);
    for i in 0 to (message'length/data_in'length)-1 loop
      data_in       <= message(i*data_in'length to i*data_in'length+data_in'length-1);
      data_valid_in <= '1';
      wait_nr_ticks(clk, 1);
    end loop;
    data_valid_in <= '0';
    wait_nr_ticks(clk, 1);
    if data_out = answer then
      report "SUCCESS - remainder supplied matches expected" severity note;
    else
      report "FAILED - remainder supplied does not match expected" severity warning;
    end if;
    wait_nr_ticks(clk, 4);
    stop_clocks;
    -- Prevent the process repeating after the simulation time has been manually extended.
    wait;
  end process;
  
end architecture;