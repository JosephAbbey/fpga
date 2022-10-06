-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench to drive the time display.
--
-- P A Abbey, 18 September 2022
--
-------------------------------------------------------------------------------------

entity test_time_display is
end entity;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library local;

architecture rtl of test_time_display is

  signal disp        : work.sevseg_pkg.time_disp_t;
  signal digit       : work.sevseg_pkg.digits_t;
  signal am          : std_logic;
  signal pm          : std_logic;
  signal alarm       : std_logic;
  signal tfhr        : std_logic := '0';
  signal mode        : work.time_display_pkg.mode_t;
  signal silence     : std_logic := '0';
  signal up          : std_logic := '0';
  signal down        : std_logic := '0';
  signal ok          : std_logic := '0';

  signal Clk              : std_logic;
  constant ClkPeriod      : time                                    := 250 ms; -- 10 ns;
  constant ClkFrequencyHz : integer                                 := 1000 ms / ClkPeriod; -- 10 Hz
  signal   ticks          : integer range 0 to (ClkFrequencyHz - 1) := 0;

  function To_Std_Logic(L: boolean) return std_ulogic is
  begin
      if L then
          return('1');
      else
          return('0');
      end if;
  end function;

begin

  clkgen : local.testbench_pkg.clock(Clk, ClkPeriod);

  process(Clk) is
  begin
    if rising_edge(Clk) then
      ticks <= (ticks + 1) mod ClkFrequencyHz;
    end if;
  end process;

  comp_time_display : entity work.time_display
    port map (
      Clk     => Clk,
      PPS     => To_Std_Logic(ticks = 0),

      disp    => disp,
      digit   => digit,
      am      => am,
      pm      => pm,
      alarm   => alarm,
      tfhr    => tfhr,
      mode    => mode,
      silence => silence,
      up      => up,
      down    => down,
      ok      => ok
    );

end architecture;
