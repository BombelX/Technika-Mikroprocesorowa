# Source after create_project.tcl / opening scs.xpr. This tests both ISA profiles.
if {[current_project -quiet] eq ""} { error "Open the generated project first" }
set_property top tb_cpu [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
launch_simulation -simset sim_1 -mode behavioral
# launch_simulation runs the configured 'all' duration. Inspect PASS in console.
