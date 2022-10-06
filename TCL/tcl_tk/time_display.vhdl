-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Aggregate four instantiations of a seven segment display decoder in order to
-- display the time.
--
-- P A Abbey, 18 September 2022
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

  use work.time_display_pkg.mode_t;
  use work.time_display_pkg.set_t;
  use work.sevseg_pkg.digits_t;
  use work.sevseg_pkg.time_disp_t;

entity time_display is
  port(
    Clk     : in  std_logic;
    PPS     : in  std_logic;
    disp    : out time_disp_t;
    digit   : out digits_t;
    am      : out std_logic := '1';
    pm      : out std_logic;
    alarm   : out std_logic;
    tfhr    : in  std_logic;
    mode    : in  mode_t;
    silence : in  std_logic;
    up      : in  std_logic;
    down    : in  std_logic;
    ok      : in  std_logic
  );
end entity;

architecture rtl of time_display is

  signal prev_mode         : mode_T := Clock;

  signal disp_i            : time_disp_t;

  constant flash_ticks     : integer                        := 10;
  signal   ticks           : integer range 0 to flash_ticks := 0;
  signal   flash           : std_logic                      := '0';

  signal digit_i           : digits_t;
  signal am_i              : std_logic;
  signal pm_i              : std_logic;
  signal idigit            : digits_t              := (0, 0, 0, 0);
  signal secs              : integer range 0 to 59 := 0;
  signal ispm              : std_logic             := '0';
  signal set               : set_t                 := D0;

  signal ialarm            : std_logic             := '0';
  signal alarm_am_i        : std_logic;
  signal alarm_pm_i        : std_logic;
  signal alarm_digit_i     : digits_t;
  signal alarm_idigit      : digits_t              := (0, 7, 0, 0);
  signal alarm_ispm        : std_logic             := '0';
  signal alarm_set         : set_t                 := D0;

  signal stopwatch_digit_i : digits_t;
  signal stopwatch_am_i    : std_logic;
  signal stopwatch_pm_i    : std_logic;
  signal stopwatch_idigit  : digits_t              := (0, 0, 0, 0);
  -- TODO: find a way to remove this and keep the procedure
  signal stopwatch_ispm    : std_logic             := '0'; -- never changes
  signal stopwatch_going   : std_logic             := '0';

  signal timer_ialarm      : std_logic             := '0';
  signal timer_digit_i     : digits_t;
  signal timer_am_i        : std_logic;
  signal timer_pm_i        : std_logic;
  signal timer_idigit      : digits_t              := (0, 0, 0, 0);
  -- TODO: find a way to remove this and keep the procedure
  signal timer_ispm        : std_logic             := '0'; -- never changes
  signal timer_set         : set_t                 := D0;


  procedure set_time(
    signal   set     : inout set_t;
    signal   idigit  : inout digits_t;
    signal   ispm    : inout std_logic;
    constant amPm    : in    boolean   := true;
    constant last    : in    set_t     := D0
  ) is 
  begin
    case set is
      when D0 =>
        if up then
          if idigit(0) = 1 then
            idigit(0) <= 0;
          else
            idigit(0) <= idigit(0)+1;
          end if;
        elsif down then
          if idigit(0) = 0 then
            idigit(0) <= 1;
          else
            idigit(0) <= idigit(0)-1;
          end if;
        elsif ok then
          set <= D1;
        end if;
      when D1 =>
        if up then
          if idigit(1) = 9 or (idigit(0) = 1 and idigit(1) = 2) then
            idigit(1) <= 0;
          else
            idigit(1) <= idigit(1)+1;
          end if;
        elsif down then
          if idigit(1) = 0 then
            if idigit(0) = 0 then
              idigit(1) <= 9;
            else
              idigit(1) <= 2;
            end if;
          else
            idigit(1) <= idigit(1)-1;
          end if;
        elsif ok then
          set <= D2;
        end if;
      when D2 =>
        if up then
          if idigit(2) = 5 then
            idigit(2) <= 0;
          else
            idigit(2) <= idigit(2)+1;
          end if;
        elsif down then
          if idigit(2) = 0 then
            idigit(2) <= 5;
          else
            idigit(2) <= idigit(2)-1;
          end if;
        elsif ok then
          set <= D3;
        end if;
      when D3 =>
        if up then
          if idigit(3) = 9 then
            idigit(3) <= 0;
          else
            idigit(3) <= idigit(3)+1;
          end if;
        elsif down then
          if idigit(3) = 0 then
            idigit(3) <= 9;
          else
            idigit(3) <= idigit(3)-1;
          end if;
        elsif ok then
          if amPm then
            set <= DP;
          else
            set <= last;
          end if;
        end if;
      when DP =>
        if up or down then
          ispm <= not ispm;
        elsif ok then
          set <= last;
        end if;
      when U =>
      when others =>
        set <= D0;
    end case;
  end procedure;

begin

  gd : for i in digit'range generate
    sevseg_display_i : entity work.sevseg_display
      port map (
        Clk   => Clk,
        digit => digit(i),
        disp  => disp_i(i)
      );
  end generate;

  process (Clk)
  begin
    if rising_edge(Clk) then
      if ticks = flash_ticks then
        ticks <= 0;
        case mode is
          when SetClock | SetAlarm | Timer =>
            case set is
              when D0 =>
                disp(3) <= disp_i(3);
                disp(2) <= disp_i(2);
                disp(1) <= disp_i(1);
                disp(0) <= disp_i(0) when flash else "0000000";
              when D1 =>
                disp(3) <= disp_i(3);
                disp(2) <= disp_i(2);
                disp(1) <= disp_i(1) when flash else "0000000";
                disp(0) <= disp_i(0);
              when D2 =>
                disp(3) <= disp_i(3);
                disp(2) <= disp_i(2) when flash else "0000000";
                disp(1) <= disp_i(1);
                disp(0) <= disp_i(0);
              when D3 =>
                disp(3) <= disp_i(3) when flash else "0000000";
                disp(2) <= disp_i(2);
                disp(1) <= disp_i(1);
                disp(0) <= disp_i(0);
              when others =>
                disp(3) <= disp_i(3);
                disp(2) <= disp_i(2);
                disp(1) <= disp_i(1);
                disp(0) <= disp_i(0);
            end case;
          when others =>
            disp(3) <= disp_i(3);
            disp(2) <= disp_i(2);
            disp(1) <= disp_i(1);
            disp(0) <= disp_i(0);
        end case;
        flash <= not flash;
      else
        ticks <= ticks+1;
      end if;
    end if;
  end process;

  nice_time_i : entity work.nice_time
    port map (
      idigit => idigit,
      ispm   => ispm,
      tfhr   => tfhr,
      digit  => digit_i,
      am     => am_i,
      pm     => pm_i
    );

  alarm_nice_time_i : entity work.nice_time
    port map (
      idigit => alarm_idigit,
      ispm   => alarm_ispm,
      tfhr   => tfhr,
      digit  => alarm_digit_i,
      am     => alarm_am_i,
      pm     => alarm_pm_i
    );

  stopwatch_nice_time_i : entity work.nice_time
    port map (
      idigit => stopwatch_idigit,
      ispm   => '0',
      tfhr   => tfhr,
      digit  => stopwatch_digit_i,
      am     => stopwatch_am_i,
      pm     => stopwatch_pm_i
    );

  timer_nice_time_i : entity work.nice_time
    port map (
      idigit => timer_idigit,
      ispm   => '0',
      tfhr   => tfhr,
      digit  => timer_digit_i,
      am     => timer_am_i,
      pm     => timer_pm_i
    );

  process(Clk)
  begin
    if rising_edge(Clk) then
      if silence then
        ialarm <= '0';
      else
        if  secs = 0 and
            idigit(0) = alarm_idigit(0) and
            idigit(1) = alarm_idigit(1) and
            idigit(2) = alarm_idigit(2) and
            idigit(3) = alarm_idigit(3) and
            ispm = alarm_ispm then
              ialarm <= '1';
        end if;
      end if;
      alarm <= (timer_ialarm or ialarm) and not alarm;
    end if;
  end process;

  process(Clk)
  begin
    if rising_edge(Clk) then
      if (mode = SetClock) then
        set_time(
          set,
          idigit,
          ispm
        );
      elsif PPS then
        if secs = 59 then
          secs <= 0;
          if idigit(3) = 9 then
              idigit(3) <= 0;
            if idigit(2) = 5 then
              idigit(2) <= 0;
              if idigit(1) = 9 or (idigit(0) = 1 and idigit(1) = 1) then
                idigit(1) <= 0;
                if idigit(0) = 1 then
                  idigit(0) <= 0;
                  ispm <= not ispm;
                else
                  idigit(0) <= idigit(0)+1;
                end if;
              else
                idigit(1) <= idigit(1)+1;
              end if;
            else
              idigit(2) <= idigit(2)+1;
            end if;
          else
            idigit(3) <= idigit(3)+1;
          end if;
        else
          secs <= secs+1;
        end if;
      end if;
    end if;
  end process;

  process(Clk)
  begin
    if rising_edge(Clk) then

      if not (mode = prev_mode) then

        prev_mode <= mode;

        -- default
        alarm_set        <= D0;
        timer_set        <= D0;
        timer_ialarm     <= '0';
        stopwatch_going  <= '0';
        stopwatch_idigit <= (0, 0, 0, 0);

      else

        case mode is
          when Clock =>
            digit <= digit_i;
            am    <= am_i;
            pm    <= pm_i;
          when SetClock =>
            digit <= digit_i;
            am    <= am_i;
            pm    <= pm_i;
          when StopWatch =>
            digit <= stopwatch_digit_i;
            am    <= '0';
            pm    <= '0';
            if ok then
              stopwatch_going <= not stopwatch_going;
            elsif stopwatch_going then
              if PPS then
                if stopwatch_idigit(3) = 9 then
                    stopwatch_idigit(3) <= 0;
                  if stopwatch_idigit(2) = 5 then
                    stopwatch_idigit(2) <= 0;
                    if stopwatch_idigit(1) = 9 then
                      stopwatch_idigit(1) <= 0;
                      if stopwatch_idigit(0) = 5 then
                        stopwatch_going <= '0';
                      else
                        stopwatch_idigit(0) <= stopwatch_idigit(0)+1;
                      end if;
                    else
                      stopwatch_idigit(1) <= stopwatch_idigit(1)+1;
                    end if;
                  else
                    stopwatch_idigit(2) <= stopwatch_idigit(2)+1;
                  end if;
                else
                  stopwatch_idigit(3) <= stopwatch_idigit(3)+1;
                end if;
              end if;
            end if;
          when Timer =>
            digit <= timer_digit_i;
            am    <= '0';
            pm    <= '0';
            if timer_set = U then
              if PPS then
                if  timer_idigit(3) = 0 and
                    timer_idigit(2) = 0 and
                    timer_idigit(1) = 0 and
                    timer_idigit(0) = 0 then
                      timer_ialarm <= '1';
                else
                      if timer_idigit(3) = 0 then
                        timer_idigit(3) <= 9;
                        if timer_idigit(2) = 0 then
                          timer_idigit(2) <= 5;
                          if timer_idigit(1) = 0 then
                            timer_idigit(1) <= 9;
                            timer_idigit(0) <= timer_idigit(0)-1;
                          else
                            timer_idigit(1) <= timer_idigit(1)-1;
                          end if;
                        else
                          timer_idigit(2) <= timer_idigit(2)-1;
                        end if;
                      else
                        timer_idigit(3) <= timer_idigit(3)-1;
                      end if;
                    end if;
              end if;
            else
              set_time(
                timer_set,
                timer_idigit,
                timer_ispm,
                false,
                U
              );
            end if;
          when SetAlarm =>
            digit <= alarm_digit_i;
            am    <= alarm_am_i;
            pm    <= alarm_pm_i;
            set_time(
              alarm_set,
              alarm_idigit,
              alarm_ispm
            );
          when others =>
            am       <= '0';
            pm       <= '0';
            digit(0) <= 11;
            digit(1) <= 10;
            digit(2) <= 13;
            digit(3) <= 0;
        end case;

      end if;

    end if;
  end process;

end architecture;
