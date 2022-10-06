# Clock uncertainty (from a timing report), looks to be device independent
set tcu 0.035

# Part: xazu2eg-sbva484-1-i
# FDRE Setup Time (Setup_FDRE_C_D) in ns (Fast Process, max delay for Setup times)
#set tsuf 0.023
# FDRE Setup Time (Setup_FDRE_C_D) in ns (Slow Process, max delay for Setup times)
set tsus 0.027
# FDRE Hold Time (Hold_FDRE_C_D) in ns (Fast Process, min delay for Hold times)
#set thf 0.046
# FDRE Hold Time (Hold_FDRE_C_D) in ns (Slow Process, min delay for Hold times)
set ths 0.053

# Choose these:
#
# Extra slack (on hold time), designer's choice
set txs 0.008
# Additional clock uncertainty desired for over constraining the design, set by designer choice
set tcu_add 0.000
#
create_clock -period 10.0 -name clk [get_ports Clk]
#create_clock -period 0.740 -name clk [get_ports Clk]
#create_clock -period 0.650 -name clk [get_ports Clk]
set input_ports  {mode silence tfhr up down ok}
set output_ports {disp[*] digit[*] alarm am pm}
#
# Standard timing setup, allocate the device delays into the meaningful variables
#
# https://www.xilinx.com/publications/prod_mktg/club_vivado/presentation-2015/paris/Xilinx-TimingClosure.pdf
# Recommended technique for over-constraining a design:
set_clock_uncertainty -setup $tcu_add [get_clocks]
# Input Hold = Input Setup (slow corner)
set input_delay [expr $ths + $tcu + $txs]
# Output Hold = Output Setup (slow corner)
set output_delay $tsus

set_input_delay  -clock [get_clocks clk] $input_delay  $input_ports
set_output_delay -clock [get_clocks clk] $output_delay $output_ports
