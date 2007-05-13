set iconfound to true
try
	tell application "Finder" to set itmwicon to (application file id "iTMW" as string) & ":Contents:Resources:iTuneMyWalkman.icns"
on error
	set iconfound to false
end try

tell application "iTunes"
	if selection = {} then
		if iconfound then
			display dialog "Please select one or more tracks first." buttons {"OK"} default button 1 with title "iTuneMyWalkman" with icon file itmwicon
		else
			display dialog "Please select one or more tracks first." buttons {"OK"} default button 1 with title "iTuneMyWalkman" with icon 1
		end if
		return
	end if
	if iconfound then
		set increment to display dialog "Increment the play counts of the selected tracks by:" default answer "" buttons {"Cancel", "OK"} default button 2 with title "iTuneMyWalkman" with icon file itmwicon
	else
		set increment to display dialog "Increment the play counts of the selected tracks by:" default answer "" buttons {"Cancel", "OK"} default button 2 with title "iTuneMyWalkman" with icon 1
	end if
	if button returned of increment = "Cancel" then return
	try
		set num to text returned of increment as number
	on error
		beep
		return
	end try
	repeat with thetrack in selection
		set played count of thetrack to (played count of thetrack) + num
		set played date of thetrack to current date
	end repeat
end tell