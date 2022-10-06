@echo off

D:
cd Users\Joseph\ModelSim\projects\tcltk
start vsim work.test_time_display -do "source {F:\fpga\TCL\tcl_tk\setup.tcl}"
