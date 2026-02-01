set_global_assignment -entity "dsp" -library "lib_dsp" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "dsp" -library "lib_dsp" -name IP_TOOL_VERSION "20.1"
set_global_assignment -entity "dsp" -library "lib_dsp" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_dsp" -name SPD_FILE [file join $::quartus(sip_path) "dsp.spd"]
set_global_assignment -library "lib_dsp" -name MISC_FILE [file join $::quartus(sip_path) "../dsp.qsys"]

set_global_assignment -library "lib_dsp" -name MISC_FILE [file join $::quartus(sip_path) "sim/dsp.v"]
set_global_assignment -library "lib_dsp" -name MISC_FILE [file join $::quartus(sip_path) "altera_a10_native_fixed_point_dsp_201/sim/dsp_altera_a10_native_fixed_point_dsp_201_ffpppjq.v"]
