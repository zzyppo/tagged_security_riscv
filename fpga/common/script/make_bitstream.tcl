set origin_dir "."
set project_name [lindex $argv 0]
set orig_proj_dir [file normalize $origin_dir/$project_name]

# open project
open_project $orig_proj_dir/$project_name.xpr

# suppress some not very useful messages
# IP flow regeneration
set_msg_config -id "\[IP_Flow 19-3664\]" -suppress

#increase limit of variable size
set_param synth.elaboration.rodinMoreOptions "rt::set_parameter var_size_limit 4194304"

# reset runs
reset_run synth_1
reset_run impl_1

# run syntesis
launch_runs synth_1
wait_on_run synth_1

# run imp
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

