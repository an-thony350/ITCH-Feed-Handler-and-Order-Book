# Build script for the Nasdaq-ITCH feed handler & Order Book release v4.0

set project_name "Feed_Handler_v4.0"
set project_dir  "./Feed_Handler_v4.0"
set board        "xczu7ev-ffvc1156-2-e"  ;

puts "Creating $project_name :"
create_project $project_name $project_dir -part $board -force

puts "Loading Custom IPs..."
set_property ip_repo_paths {./ip_repo} [current_project]
update_ip_catalog

puts "Adding taxi library sources..."
add_files -norecurse [glob -nocomplain ./lib/taxi/src/eth/rtl/*.sv]
add_files -norecurse [glob -nocomplain ./lib/taxi/src/axis/rtl/*.sv]
add_files -norecurse [glob -nocomplain ./lib/taxi/src/sync/rtl/*.sv]
update_compile_order -fileset sources_1

puts "Adding constraints..."
add_files -fileset constrs_1 -norecurse ./constraints/zcu106_taxi_10gbe.xdc

add_files -fileset constrs_1 -norecurse ./constraints/taxi/taxi_sync_reset.tcl
add_files -fileset constrs_1 -norecurse ./constraints/taxi/taxi_sync_signal.tcl
add_files -fileset constrs_1 -norecurse ./constraints/taxi/taxi_axis_async_fifo.tcl
add_files -fileset constrs_1 -norecurse ./constraints/taxi/taxi_eth_mac_fifo.tcl

set_property PROCESSING_ORDER LATE [get_files taxi_sync_reset.tcl]
set_property PROCESSING_ORDER LATE [get_files taxi_sync_signal.tcl]
set_property PROCESSING_ORDER LATE [get_files taxi_axis_async_fifo.tcl]
set_property PROCESSING_ORDER LATE [get_files taxi_eth_mac_fifo.tcl]

puts "Building Block Design..."
source ./bd.tcl

puts "Generating HDL Wrapper..."
set bd_name "v4_release"
make_wrapper -files [get_files ${bd_name}.bd] -top
add_files -norecurse ${project_dir}/${project_name}.gen/sources_1/bd/${bd_name}/hdl/${bd_name}_wrapper.v

set_property top ${bd_name}_wrapper [current_fileset]
update_compile_order -fileset sources_1

puts "Project generation complete"
