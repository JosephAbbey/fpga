
library ieee;
  use ieee.std_logic_1164.all;

  use work.time_display_pkg.mode_t;

entity nice_time is
  port(
    idigit  : in  work.sevseg_pkg.digits_t;
    ispm    : in  std_logic;
    tfhr    : in  std_logic;
    digit   : out work.sevseg_pkg.digits_t;
    am      : out std_logic;
    pm      : out std_logic
  );
end entity;

architecture rtl of nice_time is

begin

  process(all)
  begin
    digit(3) <= idigit(3);
    digit(2) <= idigit(2);
    if tfhr = '1' then
      am <= '0';
      pm <= '0';
      if ispm = '1' then
        if idigit(1) = 8 or idigit(1) = 9 then -- prevents the rarely seen case of 1b o'clock
          digit(1) <= idigit(1) - 8;
          digit(0) <= idigit(0) + 2;
        else
          if idigit(0) = 1 and idigit(1) = 2 then
            digit(1) <= 0;
            digit(0) <= 0;
          else
            digit(1) <= idigit(1) + 2;
            digit(0) <= idigit(0) + 1;
          end if;
        end if;
      else
        digit(1) <= idigit(1);
        digit(0) <= idigit(0);
      end if;
    else
      am <= not ispm;
      pm <= ispm;
      if ispm = '1' and idigit(1) = 0 and idigit(0) = 0  then
        digit(1) <= 2;
        digit(0) <= 1;
      else
        digit(1) <= idigit(1);
        digit(0) <= idigit(0);
      end if;
    end if;
  end process;

end architecture;