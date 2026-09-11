# Build script for the Nasdaq-ITCH feed handler & Order Book release v1.0

set project_name "Feed_Handler_v1.0"
set project_dir  "./Feed_Handler_v1.0"
set board        "xc7z020clg400-1"  ;

puts "Creating $project_name :"
create_project $project_name $project_dir -part $board -force

puts "Loading Custom IPs..."
set_property ip_repo_paths {./ip_repo} [current_project]
update_ip_catalog

puts "Building Block Design..."
source ./bd.tcl

puts "Generating HDL Wrapper..."
set bd_name "v1release"
make_wrapper -files [get_files ${bd_name}.bd] -top
add_files -norecurse ${project_dir}/${project_name}.gen/sources_1/bd/${bd_name}/hdl/${bd_name}_wrapper.v

set_property top ${bd_name}_wrapper [current_fileset]
update_compile_order -fileset sources_1

puts "Project generation complete"
