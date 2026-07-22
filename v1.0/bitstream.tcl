set bd_name "v1release"

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
set bit_dst "./bitstream/v1release.bit"

file mkdir ./bitstream
file copy -force $bit_src $bit_dst

puts "Bitstream generation complete."
