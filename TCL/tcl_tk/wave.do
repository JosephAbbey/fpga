onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /test_time_display/Clk
add wave -noupdate -expand /test_time_display/disp
add wave -noupdate -radix hexadecimal -expand /test_time_display/digit
add wave -noupdate /test_time_display/am
add wave -noupdate /test_time_display/pm
add wave -noupdate /test_time_display/alarm
add wave -noupdate /test_time_display/tfhr
add wave -noupdate /test_time_display/mode
add wave -noupdate /test_time_display/silence
add wave -noupdate /test_time_display/up
add wave -noupdate /test_time_display/down
add wave -noupdate /test_time_display/ok
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1669619 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits sec
update
WaveRestoreZoom {2023 ns} {3283 ns}
