set bd_name "v2release"

puts "Setting correct implementation settings"
set_property strategy Performance_ExtraTimingOpt [get_runs impl_1]

puts "Generating BD output products..."
generate_target all [get_files ${bd_name}.bd]

puts "Updating compile order..."
update_compile_order -fileset sources_1

puts "Launching synthesis..."
launch_runs synth_1
wait_on_run synth_1

puts "Launching implementation..."
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1


set bit_src "${project_dir}/${project_name}.runs/impl_1/${bd_name}_wrapper.bit"
set hwh_src "${project_dir}/${project_name}.gen/sources_1/bd/${bd_name}/hw_handoff/${bd_name}.bit"
set bit_dst "./bitstream_files/v2release.bit"
set hwh_dst "./bitstream_files/v2release.hwh"

file mkdir ./bitstream_files
file copy -force $bit_src $bit_dst
file copy -force $hwh_src $hwh_dst

puts "Bitstream generation complete."
