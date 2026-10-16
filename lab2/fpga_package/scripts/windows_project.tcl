# Windows launcher: create missing project, otherwise open the existing .xpr.
# Used by START_WINDOWS.cmd with: -mode gui -source ... -tclargs PROGRAM ISA_LAB2
set package_root [file normalize [file join [file dirname [info script]] ..]]
if {![info exists argc] || $argc != 2} { error "Expected PROGRAM ISA_LAB2" }
set PROGRAM [lindex $argv 0]
set ISA_LAB2 [lindex $argv 1]
set supported {load_store:1 mul:0 sub:0 lab2_add_r1:1 lab2_mul:1 base:0}
if {"${PROGRAM}:${ISA_LAB2}" ni $supported} { error "Unsupported Windows launcher option" }
set profile [expr {$ISA_LAB2 ? "lab2" : "python"}]
set project_file [file join $package_root build ${PROGRAM}_${profile} scs.xpr]
if {[file exists $project_file]} {
    if {[current_project -quiet] ne ""} { close_project }
    open_project $project_file
} else {
    source [file join $package_root scripts create_project.tcl]
}
puts ""
puts "WINDOWS PROJECT READY: $project_file"
puts "PROGRAM=$PROGRAM / ISA_LAB2=$ISA_LAB2"
puts "Next: Generate Bitstream -> Open Hardware Manager -> Auto Connect -> Program Device."
puts "Review timing reports before programming."
puts "PuTTY: Pmod COM, 115200 8N1, Flow control None."
puts "ZYBO SW3..SW0=0100; press BTN0, then BTN2."
