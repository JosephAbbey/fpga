package time_display_pkg is

  --                            (Count down)
  type mode_t is (Clock, SetClock, StopWatch, Timer, SetAlarm);

  --                             (am/pm) (no set)
  type   set_t is (D0, D1, D2, D3, DP,      U);

end package ;