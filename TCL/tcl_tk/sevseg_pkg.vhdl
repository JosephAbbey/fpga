-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Types used to scale from a single digit to a time and hence multipel seven segment
-- displays.
--
-- P A Abbey, 18 September 2022
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package sevseg_pkg is

  subtype digit_t         is integer range 0 to 15;
  subtype one_time_disp_t is std_logic_vector(6 downto 0);
  type digits_t           is array (0 to 3) of digit_t;
  type time_disp_t        is array (0 to 3) of one_time_disp_t;

end package;
