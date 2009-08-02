if {$argc == 2} then {
	set encoding [lindex $argv 0]
	set string [string map {< _ > _ ? _ \" _ : _ | _ \\ _ / _ * _ ' _ ( _ ) _ \a _ \b _ \f _ \n _ \r _ \t _ \v _} [lindex $argv 1]]
	set string [encoding convertto $encoding $string ]
	puts [encoding convertfrom $encoding $string]
}
exit