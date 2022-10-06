#####################################################################################
#
#  Distributed under MIT Licence
#    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
#####################################################################################
#
# TCL script to display a the time in a quadruple seven segment display created out
# of TCL/TK graphics linked to a trigger set by ModelSim VHDL simulator.
#
# To run this code, keep your synthesised design open in Vivado and run:
#
#   source {path\to\sevseg_display.tcl}
#
# Reference:
#   https://blog.abbey1.org.uk/index.php/technology/tcl-tk-graphical-display-driven-by-a-vhdl
#
# P A Abbey, 18 September 2022
#
#####################################################################################

variable thisscript [file normalize [info script]]

proc hseg {can w h {col #f00} {ox 0} {oy 0}} {
  $can create polygon \
    [expr      $h/2 + $ox]                   $oy  \
    [expr $w - $h/2 + $ox]                   $oy  \
    [expr $w        + $ox] [expr      $h/2 + $oy] \
    [expr $w - $h/2 + $ox] [expr $h        + $oy] \
    [expr      $h/2 + $ox] [expr $h        + $oy] \
                      $ox  [expr      $h/2 + $oy] \
    -outline $col -fill $col
}

proc vseg {can w h {col #f00} {ox 0} {oy 0}} {
  $can create polygon \
                      $ox  [expr      $w/2 + $oy] \
                      $ox  [expr $h - $w/2 + $oy] \
    [expr      $w/2 + $ox] [expr $h        + $oy] \
    [expr $w        + $ox] [expr $h - $w/2 + $oy] \
    [expr $w        + $ox] [expr      $w/2 + $oy] \
    [expr      $w/2 + $ox]                   $oy  \
    -outline $col -fill $col
}

#
#      a
#    #####
#   #     #
# f #     # b
#   #  g  #
#    #####
#   #     #
# e #     # c
#   #  d  #
#    #####
#
#                    0123456
#                    abcdefg
proc sevseg {can {b "0000000"} {w 20} {h 60} {g 2} {ox 0} {oy 0}} {
  global on off
  if {[string length $b] != 7} {
    error "Seven segment displays need precisely 7 bits."
  }
  # a
  if {[expr [string index $b 0] == "1"]} {
    hseg $can $h $w $on  [expr $w/2 + $g   + $ox]                          $oy
  } else {
    hseg $can $h $w $off [expr $w/2 + $g   + $ox]                          $oy
  }
  # g
  if {[expr [string index $b 6] == "1"]} {
    hseg $can $h $w $on  [expr $w/2 + $g   + $ox] [expr $h        + $g*2 + $oy]
  } else {
    hseg $can $h $w $off [expr $w/2 + $g   + $ox] [expr $h        + $g*2 + $oy]
  }
  # d
  if {[expr [string index $b 3] == "1"]} {
    hseg $can $h $w $on  [expr $w/2 + $g   + $ox] [expr $h*2      + $g*4 + $oy]
  } else {
    hseg $can $h $w $off [expr $w/2 + $g   + $ox] [expr $h*2      + $g*4 + $oy]
  }
  # f
  if {[expr [string index $b 5] == "1"]} {
    vseg $can $w $h $on                      $ox  [expr      $w/2 + $g   + $oy]
  } else {
    vseg $can $w $h $off                     $ox  [expr      $w/2 + $g   + $oy]
  }
  # b
  if {[expr [string index $b 1] == "1"]} {
    vseg $can $w $h $on  [expr $h   + $g*2 + $ox] [expr      $w/2 + $g   + $oy]
  } else {
    vseg $can $w $h $off [expr $h   + $g*2 + $ox] [expr      $w/2 + $g   + $oy]
  }
  # e
  if {[expr [string index $b 4] == "1"]} {
    vseg $can $w $h $on                      $ox  [expr $h + $w/2 + $g*3 + $oy]
  } else {
    vseg $can $w $h $off                     $ox  [expr $h + $w/2 + $g*3 + $oy]
  }
  # c
  if {[expr [string index $b 2] == "1"]} {
    vseg $can $w $h $on  [expr $h   + $g*2 + $ox] [expr $h + $w/2 + $g*3 + $oy]
  } else {
    vseg $can $w $h $off [expr $h   + $g*2 + $ox] [expr $h + $w/2 + $g*3 + $oy]
  }
}

proc display {can {s0 "0000000"} {s1 "0000000"} {s2 "0000000"} {s3 "0000000"} {alarm 0} {am 0} {pm 0}} {
  global width height gap space fontsize on off canheight canwidth
  set dw [expr $height + $width + $gap*2]
  destroy $can
  canvas $can -width $canwidth -height $canheight -background #000
  sevseg $can $s0 $width $height $gap 0
  sevseg $can $s1 $width $height $gap [expr $dw + $space]
  # Central pair of dots, ':'
  $can create oval \
    [expr $dw*2 + $space*2         ] [expr $height  /2 +          $gap*2] \
    [expr $dw*2 + $space*2 + $width] [expr $height  /2 + $width + $gap*2] \
    -outline $on -fill $on
  $can create oval \
    [expr $dw*2 + $space*2         ] [expr $height*3/2 +          $gap*2] \
    [expr $dw*2 + $space*2 + $width] [expr $height*3/2 + $width + $gap*2] \
    -outline $on -fill $on
  sevseg $can $s2 $width $height $gap [expr $dw*2 + $space*3 + $width]
  sevseg $can $s3 $width $height $gap [expr $dw*3 + $space*4 + $width]

  if {$am == 1} {
    $can create text \
      [expr $dw*4 + $space*5 + $width] [expr $height  /2 + $gap*2 + $fontsize/2] \
      -fill $on -text "AM" \
      -anchor w -font "Helvetica $fontsize bold"
  } else {
    $can create text \
      [expr $dw*4 + $space*5 + $width] [expr $height  /2 + $gap*2 + $fontsize/2] \
      -fill $off -text "AM" \
      -anchor w -font "Helvetica $fontsize bold"
  }

  if {$pm == 1} {
    $can create text \
      [expr $dw*4 + $space*5 + $width] [expr $height*3/2 + $gap*2 + $fontsize/2] \
      -fill $on -text "PM" \
      -anchor w -font "Helvetica $fontsize bold"
  } else {
    $can create text \
      [expr $dw*4 + $space*5 + $width] [expr $height*3/2 + $gap*2 + $fontsize/2] \
      -fill $off -text "PM" \
      -anchor w -font "Helvetica $fontsize bold"
  }

  if {$alarm == 1} {
    $can create oval \
      [expr $dw*4 + $space*5 + $width  ] [expr $height +            $gap*2] \
      [expr $dw*4 + $space*5 + $width*2] [expr $height + $width   + $gap*2] \
      -outline $on -fill $on
    bell
  } else {
    $can create oval \
      [expr $dw*4 + $space*5 + $width  ] [expr $height +            $gap*2] \
      [expr $dw*4 + $space*5 + $width*2] [expr $height + $width   + $gap*2] \
      -outline $off -fill $off
  }
  $can create text \
    [expr $dw*4 + $space*5 + $width*3/2] [expr $height + $width/2 + $gap*2] \
    -fill #000 -text "A" \
    -anchor c -font "Helvetica [expr $width*8/10] bold"

  pack $can
}

proc setup_monitor {} {
  global clock alarm am pm cwait
  when -label updateTime "${clock}='1'" {
    set disp_v [lindex [examine -radix bin $disp] 0]
    display .sevseg.time \
      [lindex $disp_v 0] \
      [lindex $disp_v 1] \
      [lindex $disp_v 2] \
      [lindex $disp_v 3] \
      [examine $alarm]   \
      [examine $am]      \
      [examine $pm]
    # Don't let the sim run away, we won't see the display update
    stop
  }
}

proc display_cursor {} {
  global disp alarm am pm
  set disp_v [lindex [examine -time [wave cursor time] -radix bin $disp] 0]
  display .sevseg.time \
    [lindex $disp_v 0] \
    [lindex $disp_v 1] \
    [lindex $disp_v 2] \
    [lindex $disp_v 3] \
    [examine -time [wave cursor time] $alarm] \
    [examine -time [wave cursor time] $am   ] \
    [examine -time [wave cursor time] $pm   ]
}

# Global variables
set on       #f00
set off      #333
set width      16
set height     60
set gap         2
set space      12
set fontsize   16
# Don't amend these
set canwidth    [expr ($height   + $width + $gap*2 + $space)*4 + $width + $space + $fontsize*2 + 1]
set canheight   [expr  $height*2 + $width + $gap*4 + 1]
set winwidth    [expr  $canwidth + $fontsize*22]
set winheight   [expr  $canheight + $fontsize*3]
set btnfontsize [expr $fontsize/2]
set itoggletime [string trim [examine /test_time_display/ClkPeriod] " ps{}"]
set toggletime  "[expr $itoggletime*2] ps"
# set toggletime [examine /test_time_display/ClkPeriod]
# Signals
set clock   {/test_time_display/Clk}
set disp    {/test_time_display/disp}
set alarm   {/test_time_display/alarm}
set am      {/test_time_display/am}
set pm      {/test_time_display/pm}
set tfhr    {/test_time_display/tfhr}
set mode    {/test_time_display/mode}
set silence {/test_time_display/silence}
set up      {/test_time_display/up}
set ok      {/test_time_display/ok}
set down    {/test_time_display/down}

# Clean up from last time
destroy .sevseg

toplevel .sevseg

frame .sevseg.controls
pack .sevseg.controls

# sim controls
frame .sevseg.controls.sim       -border 2 -relief groove
pack  .sevseg.controls.sim       -side left
label .sevseg.controls.sim.label -text "Sim Controls"
pack  .sevseg.controls.sim.label -side top

button .sevseg.controls.sim.reload \
  -text "reload" \
  -font "Helvetica $btnfontsize bold" \
  -command {source $thisscript}
pack .sevseg.controls.sim.reload -side left

button .sevseg.controls.sim.step \
  -text "step" \
  -font "Helvetica $btnfontsize bold" \
  -command {run -all}
pack .sevseg.controls.sim.step -side left

set autostep 0
checkbutton .sevseg.controls.sim.autostep \
  -text "autostep" \
  -font "Helvetica $btnfontsize bold" \
  -command {
    global autostep
    while {$autostep} {
      run -all
    }
  } \
  -variable autostep \
  -onvalue  1 \
  -offvalue 0
pack .sevseg.controls.sim.autostep -side left

button .sevseg.controls.sim.gotocursor \
  -text "goto cursor" \
  -font "Helvetica $btnfontsize bold" \
  -command {display_cursor}
pack .sevseg.controls.sim.gotocursor -side left

# app controls
frame .sevseg.controls.app       -border 2 -relief groove
pack  .sevseg.controls.app       -side left
label .sevseg.controls.app.label -text "App Controls"
pack  .sevseg.controls.app.label -side top

set tfhrs 0
checkbutton .sevseg.controls.app.tfhr \
  -text "24 hours" \
  -font "Helvetica $btnfontsize bold" \
  -command {
    global tfhrs tfhr
    force -deposit $tfhr $tfhrs
  } \
  -variable tfhrs \
  -onvalue  1 \
  -offvalue 0
pack .sevseg.controls.app.tfhr -side left

frame .sevseg.controls.app.mode -border 2 -relief groove
pack  .sevseg.controls.app.mode -side left
set modes "Clock"
radiobutton .sevseg.controls.app.mode.clock \
  -text "Clock" \
  -variable modes \
  -value "Clock" \
  -command {force -deposit $mode Clock}
pack .sevseg.controls.app.mode.clock -side left
radiobutton .sevseg.controls.app.mode.setClock \
  -text "SetClock" \
  -variable modes \
  -value "SetClock" \
  -command {force -deposit $mode SetClock}
pack .sevseg.controls.app.mode.setClock -side left
radiobutton .sevseg.controls.app.mode.stopWatch \
  -text "StopWatch" \
  -variable modes \
  -value "StopWatch" \
  -command {force -deposit $mode StopWatch}
pack .sevseg.controls.app.mode.stopWatch -side left
radiobutton .sevseg.controls.app.mode.timer \
  -text "Timer" \
  -variable modes \
  -value "Timer" \
  -command {force -deposit $mode Timer}
pack .sevseg.controls.app.mode.timer -side left
radiobutton .sevseg.controls.app.mode.setAlarm \
  -text "SetAlarm" \
  -variable modes \
  -value "SetAlarm" \
  -command {force -deposit $mode SetAlarm}
pack .sevseg.controls.app.mode.setAlarm -side left

button .sevseg.controls.app.silence \
  -text "silence" \
  -font "Helvetica $btnfontsize bold" \
  -command {force -deposit $silence 1 0, 0 $toggletime}
pack .sevseg.controls.app.silence -side left

button .sevseg.controls.app.up \
  -text "^" \
  -font "Helvetica $btnfontsize bold" \
  -command {force -deposit $up 1 0, 0 $toggletime}
pack .sevseg.controls.app.up -side left

button .sevseg.controls.app.ok \
  -text "ok" \
  -font "Helvetica $btnfontsize bold" \
  -command {force -deposit $ok 1 0, 0 $toggletime}
pack .sevseg.controls.app.ok -side left

button .sevseg.controls.app.down \
  -text "v" \
  -font "Helvetica $btnfontsize bold" \
  -command {force -deposit $down 1 0, 0 $toggletime}
pack .sevseg.controls.app.down -side left

# Four seven segment displays for the time
display .sevseg.time

wm title .sevseg "Time Display"
wm geometry .sevseg ${winwidth}x${winheight}+100+100
wm attributes .sevseg -topmost 1

if {[runStatus] == "ready"} {
  # Setup the trigger to update the display
  setup_monitor
  puts "NOTE - Trigger setup."
} {
  puts "WARNING - Load the design then call TCL 'setup_monitor'."
}
puts "NOTE - Use 'display_cursor' to update the display to the values shown under the cursor."

# setup sim
restart -f
run -all
view wave
