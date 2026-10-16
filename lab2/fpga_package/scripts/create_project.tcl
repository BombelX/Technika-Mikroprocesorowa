# Vivado 2024.1: GUI source, or -mode batch -source ... -tclargs base 0
set package_root [file normalize [file join [file dirname [info script]] ..]]
if {![info exists PROGRAM]} { set PROGRAM base }
if {![info exists ISA_LAB2]} { set ISA_LAB2 0 }
if {[info exists argc] && $argc > 0} { set PROGRAM [lindex $argv 0] }
if {[info exists argc] && $argc > 1} { set ISA_LAB2 [lindex $argv 1] }
if {$ISA_LAB2 ni {0 1}} { error "ISA_LAB2 must be 0 (Python) or 1 (lab2)" }
set allowed {base load_store undefined mul sub overflow sub_underflow lab2_add_r1 lab2_mul}
if {$PROGRAM ni $allowed} { error "Unknown PROGRAM: $PROGRAM; choose $allowed" }
if {[string match lab2_* $PROGRAM] && !$ISA_LAB2} { error "$PROGRAM requires ISA_LAB2=1" }
if {$PROGRAM eq "mul" && $ISA_LAB2} { error "mul uses Python opcode 30; choose lab2_mul for ISA_LAB2=1" }
if {$PROGRAM eq "undefined" && $ISA_LAB2} { error "undefined tests opcode 50, which is MUL in lab2; use ISA_LAB2=0" }
set profile [expr {$ISA_LAB2 ? "lab2" : "python"}]
set project_dir [file join $package_root build ${PROGRAM}_${profile}]
if {[file exists [file join $project_dir scs.xpr]]} {
    error "Project exists: $project_dir/scs.xpr. Open it, or use a fresh folder; no files were overwritten."
}
if {[current_project -quiet] ne ""} { close_project }
create_project scs $project_dir -part xc7z010clg400-1
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
add_files -norecurse [glob [file join $package_root rtl *.v]]
add_files -fileset constrs_1 -norecurse [file join $package_root constraints zybo.xdc]
set_property top toplevel [get_filesets sources_1]
set_property generic [list ISA_LAB2=$ISA_LAB2] [get_filesets sources_1]

# Same memory topology as lab2 pp.11-18; no board files or Zynq PS needed.
create_bd_design mem
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0
set coe [file normalize [file join $package_root programs ${PROGRAM}.coe]]
set_property -dict [list \
    CONFIG.use_bram_block {Stand_Alone} CONFIG.Interface_Type {Native} \
    CONFIG.Enable_32bit_Address {false} \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.Write_Width_A {8} CONFIG.Read_Width_A {8} CONFIG.Write_Depth_A {16} \
    CONFIG.Write_Width_B {8} CONFIG.Read_Width_B {8} \
    CONFIG.Operating_Mode_A {WRITE_FIRST} CONFIG.Operating_Mode_B {WRITE_FIRST} \
    CONFIG.Enable_A {Always_Enabled} CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.Register_PortB_Output_of_Memory_Core {false} \
    CONFIG.Use_Byte_Write_Enable {false} \
    CONFIG.Load_Init_File {true} CONFIG.Coe_File $coe \
] [get_bd_cells blk_mem_gen_0]
make_bd_intf_pins_external [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
make_bd_intf_pins_external [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB]
validate_bd_design
save_bd_design
set bd [get_files -quiet */mem.bd]
generate_target all $bd
set wrappers [make_wrapper -files $bd -top]
add_files -norecurse $wrappers
set_property top toplevel [get_filesets sources_1]
update_compile_order -fileset sources_1

# CPU unit test is independent of generated memory IP.
add_files -fileset sim_1 -norecurse [file join $package_root sim tb_cpu.v]
set_property file_type SystemVerilog [get_files */tb_cpu.v]
set_property top tb_cpu [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
update_compile_order -fileset sim_1
puts "READY: $project_dir/scs.xpr; PROGRAM=$PROGRAM; ISA_LAB2=$ISA_LAB2"
puts "Next: source {[file join $package_root scripts simulate.tcl]}"
puts "Then: source {[file join $package_root scripts build_bitstream.tcl]}"
