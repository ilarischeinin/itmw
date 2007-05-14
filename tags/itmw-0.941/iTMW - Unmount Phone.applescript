try
	set musicpath to do shell script "/usr/bin/defaults read com.itmw.itmw musicPath | /usr/bin/sed 's/\\\\\\\\/\\\\/'"
	set dir to do shell script "/bin/ls -d " & musicpath
on error
	beep
	return
end try
if dir contains return then
	beep
	return
end if
set macdir to POSIX file dir as string
tell application "Finder" to eject disk of folder macdir