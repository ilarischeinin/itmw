if {$argc == 2} then {
	encoding system [lindex $argv 0]
	puts [encoding convertto [lindex $argv 0] [lindex $argv 1]]
}
exit