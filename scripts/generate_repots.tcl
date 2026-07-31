# This tcl file generates reports on relevant data for RTL designs in Vivado

# Note that this file was used for Vivado 2023.2

puts "Generating Documentation Reports..."

set out_dir "./design_evidence"
file mkdir $out_dir

# 1. Utilization
report_utilization -file $out_dir/utilization.txt
report_utilization -hierarchical -file $out_dir/utilization_hier.txt

# 2. Timing
report_timing_summary -file $out_dir/timing_summary.txt
report_timing -max_paths 10 -file $out_dir/critical_paths.txt

# 3. Power (Often required alongside timing/utilization)
report_power -file $out_dir/power_summary.txt

puts "Done! Evidence saved to $out_dir"
