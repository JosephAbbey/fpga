-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Construct multiple FFTs of different sizes and radices and compare the outputs
-- with expected data generated by Octave and written to data structures in a package.
--
-- References:
--   1) Fast Fourier Transform (FFT),
--      https://www.cmlab.csie.ntu.edu.tw/cml/dsp/training/coding/transform/fft.html
--   2) Worked examples from:
--      a) https://www.youtube.com/watch?v=AF71Yqo7CoY
--      b) https://www.youtube.com/watch?v=xnVaHkRaJOw
--
-- P A Abbey, 1 Sep 2021
--
-------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.std_logic;
library ieee_proposed;
use ieee_proposed.fixed_pkg.all;
library local;
use local.testbench_pkg.all;
use work.test_fft_pkg.all;
use work.test_data_fft_pkg.all;

entity test_dft_multi_radix_sfixed is
end entity;


architecture test of test_dft_multi_radix_sfixed is

  -- Construct multiple FFTs of different sizes and radices
  constant tests_all_c : tests_sfixed_arr_t := (
    -- log_num_inputs, radix, input_high, input_low
    (         2,          2,       5,        -3  ), --  0    4 point, hierarchy depth 2
    (         2,          4,       5,        -3  ), --  1    4 point, hierarchy depth 1
    (         3,          2,       6,        -8  ), --  2    8 point, hierarchy depth 3
    (         3,          4,       6,        -8  ), --  3    8 point, hierarchy depth 2, mixed radix
    (         4,          2,       6,       -14  ), --  4   16 point, hierarchy depth 4
    (         4,          4,       6,       -14  ), --  5   16 point, hierarchy depth 2
    (         4,          8,       6,       -14  ), --  6   16 point, hierarchy depth 2, mixed radix
    (         5,          8,       6,       -14  ), --  7   32 point, hierarchy depth 2, mixed radix
    (         9,          2,       9,       -16  ), --  8  512 point, hierarchy depth 9
    (         9,          4,       9,       -16  ), --  9  512 point, hierarchy depth 5, mixed radix
    (         9,          8,       9,       -16  ), -- 10  512 point, hierarchy depth 3, mixed radix
    (         9,         32,      10,       -16  ), -- 11  512 point, hierarchy depth 2, mixed radix
    (         9,        512,       9,       -16  )  -- 12  512 point, hierarchy depth 1
  );
  -- Enable the testing of a subset, especially when using the free ModelSim with Quartus Prime Webpack
  constant tests_c     : tests_sfixed_arr_t(0 to 7) := tests_all_c(0 to 7);
  constant tolerance_c : real                       := 0.001; -- Permissive value

  type bool_arr_t is array(tests_c'range) of boolean;
  signal tests_passed   : bool_arr_t := (others => false);
  signal tests_finished : bool_arr_t := (others => false);

  signal clk   : std_logic;
  signal reset : std_logic;

begin

  clock(clk, 10 ns);

  process
  begin
    reset <= '1';
    wait_nr_ticks(clk, 2);
    reset <= '0';
    wait;
  end process;

  test_g: for t in tests_c'range generate

    constant num_inputs         : positive                                                  := 2**tests_c(t).log_num_inputs;
    constant template_c         : sfixed(tests_c(t).input_high downto tests_c(t).input_low) := to_sfixed(0.0, tests_c(t).input_high, tests_c(t).input_low);
    -- Additional delay for adder tree of depth log(tests_c(t).radix, 2)
    constant adder_tree_depth_c : natural                                                   := local.math_pkg.ceil_log(tests_c(t).radix);
    constant num_stages_c       : positive                                                  := local.math_pkg.ceil_log(num_inputs, tests_c(t).radix);
    -- This is sufficient but not exact. It is too large when later stages reduce the radix, but that is safe.
    constant fft_delay_c        : positive                                                  := (num_stages_c*(1+adder_tree_depth_c))+1;

    signal i, o : work.fft_sfixed_pkg.complex_arr_t(0 to (num_inputs)-1)(
      re(template_c'range),
      im(template_c'range)
    );

  begin

    process
      constant input_data_c  : complex_arr_arr_t    := to_complex_arr_arr_t(test_data_inputs(num_inputs), template_c);
      constant output_data_c : complex_vector_arr_t := test_data_outputs(num_inputs);
      variable passed        : boolean              := true;
    begin
      i <= (others => (re => (others => '0'), im => (others => '0')));
      wait_until(reset, '0');
      wait_nr_ticks(clk, 1);

      for k in input_data_c'range loop
        i <= input_data_c(k);
        wait_nf_ticks(clk, fft_delay_c);

        report "DUT" & integer'image(t) & ": " & integer'image(num_inputs) & "-point Radix-" & integer'image(tests_c(t).radix) & " FFT, checking data set " & integer'image(k);
        for j in output_data_c(k)'range loop
          if not compare_output(o(j), output_data_c(k)(j), tolerance_c) then
            passed := false;
            report "Index " & integer'image(j) & " values " & complex_str(o(j)) & " /= "
                 & complex_str(output_data_c(k)(j)) & " (test data)." severity warning;
          end if;
        end loop;
        wait_nr_ticks(clk, 1);
      end loop;

      if passed then
        report integer'image(num_inputs) & "-point FFT results: PASSED" severity note;
        tests_passed(t) <= true;
      else
        report integer'image(num_inputs) & "-point FFT results: FAILED" severity warning;
      end if;
      tests_finished(t) <= true;

      wait;
    end process;


    dut : entity work.dft_multi_radix_sfixed
      generic map (
        log_num_inputs_g => tests_c(t).log_num_inputs,
        template_g       => template_c,
        max_radix_g      => tests_c(t).radix
      )
      port map (
        clk   => clk,
        reset => reset,
        i     => i,
        o     => o
      );

  end generate;

  -- Accumulate results from each individual test and print a final pass or fail message.
  process(tests_finished)
    constant all_true : bool_arr_t := (others => true);
  begin
    if tests_finished = all_true then
      if tests_passed = all_true then
        report "All Tests PASSED" severity note;
      else
        report "Some Tests FAILED, check above." severity warning;
      end if;
      stop_clocks;
    end if;
  end process;

end architecture;


architecture instance of test_dft_multi_radix_sfixed is

  constant log_num_inputs_c : positive := 3;
  constant radix_c          : positive := 8;
  constant template_c       : sfixed(9 downto -16) := to_sfixed(0.0, 9, -16);

  signal clk   : std_logic;
  signal reset : std_logic;
  signal i, o  : work.fft_sfixed_pkg.complex_arr_t(0 to (2**log_num_inputs_c)-1)(
    re(template_c'range),
    im(template_c'range)
  );

begin

  assert false
    report "Radix-" & integer'image(radix_c) & " " & integer'image(2**log_num_inputs_c) & "-point FFT"
    severity note;

  dut : entity work.dft_multi_radix_sfixed
    generic map (
      log_num_inputs_g => log_num_inputs_c,
      template_g       => template_c,
      max_radix_g      => radix_c
    )
    port map (
      clk   => clk,
      reset => reset,
      i     => i,
      o     => o
    );

  clock(clk, 10 ns);

  process
  begin
    reset <= '1';
    i     <= (others => (re => (others => '0'), im => (others => '0')));
    wait_nr_ticks(clk, 2);
    reset <= '0';
    wait_nr_ticks(clk, 2);
    stop_clocks;

    wait;
  end process;

end architecture;