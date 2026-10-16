# Source with a project already open. Or vivado -mode batch -source this.tcl -tclargs path/to/scs.xpr
if {[current_project -quiet] eq ""} {
    if {![info exists argc] || $argc != 1} { error "Open scs.xpr first, or pass its path as the only argument" }
    open_project [lindex $argv 0]
}
# Explicit reset ensures edited RTL / COE gets rebuilt, even when a previous run exists.
set memory_bd [get_files -quiet */mem.bd]
if {[llength $memory_bd]} {
    reset_target all $memory_bd
    generate_target all $memory_bd
}
# Regenerated COE products must also invalidate any previous out-of-context IP netlist.
foreach ip_run [get_runs -quiet *_synth_1] { reset_run $ip_run }
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
    error "Synthesis failed: [get_property STATUS [get_runs synth_1]]"
}
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {![string match *write_bitstream*Complete* [get_property STATUS [get_runs impl_1]]]} {
    error "Bitstream generation failed: [get_property STATUS [get_runs impl_1]]"
}
open_run impl_1
set reports [file join [get_property DIRECTORY [current_project]] reports]
file mkdir $reports
report_timing_summary -report_unconstrained -file [file join $reports timing_summary.rpt]
report_utilization -file [file join $reports utilization.rpt]
report_drc -file [file join $reports drc.rpt]
report_clocks -file [file join $reports clocks.rpt]
set failing [get_timing_paths -quiet -max_paths 1 -slack_lesser_than 0]
if {[llength $failing]} { error "Negative timing slack. Inspect $reports/timing_summary.rpt before programming." }
set hold_failing [get_timing_paths -quiet -delay_type min -max_paths 1 -slack_lesser_than 0]
if {[llength $hold_failing]} { error "Hold timing failure. Inspect timing report before programming." }
puts "BITSTREAM: [get_property DIRECTORY [get_runs impl_1]]/toplevel.bit"
puts "Review reports in $reports, especially half-period CPU/BRAM timing and unconstrained paths."
