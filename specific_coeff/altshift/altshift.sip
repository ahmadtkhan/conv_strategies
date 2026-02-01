set_global_assignment -entity "altshift" -library "lib_altshift" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "altshift" -library "lib_altshift" -name IP_TOOL_VERSION "20.1"
set_global_assignment -entity "altshift" -library "lib_altshift" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_altshift" -name SPD_FILE [file join $::quartus(sip_path) "altshift.spd"]
set_global_assignment -library "lib_altshift" -name MISC_FILE [file join $::quartus(sip_path) "../altshift.qsys"]

set_global_assignment -library "lib_altshift" -name MISC_FILE [file join $::quartus(sip_path) "sim/altshift.v"]
set_global_assignment -library "lib_altshift" -name MISC_FILE [file join $::quartus(sip_path) "altshift_taps_201/sim/altshift_altshift_taps_201_as43lbi.v"]
