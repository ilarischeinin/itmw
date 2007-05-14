set myversion to do shell script "defaults read com.itmw.itmw itmwVersion"

set iconfound to true
try
	tell application "Finder" to set itmwicon to (application file id "com.itmw.itmw" as string) & ":Contents:Resources:iTuneMyWalkman.icns"
on error
	set iconfound to false
end try

set err to false
try
	set answer to do shell script "/usr/bin/curl http://ilari.scheinin.fidisk.fi/itunemywalkman/version.php?checker=" & myversion
	set currentversion to last word of answer
on error
	set err to true
end try

using terms from application "System Events"
	if err or answer does not start with "iTuneMyWalkman" then
		display alert "Error checking for new version." message "Connection failed." buttons {"OK"} default button 1
	else if myversion = currentversion then
		if iconfound then
			display dialog "You have the most recent version (" & myversion & ")." buttons {"OK"} default button 1 with title "iTuneMyWalkman" with icon file itmwicon
		else
			display dialog "You have the most recent version (" & myversion & ")." buttons {"OK"} default button 1 with title "iTuneMyWalkman" with icon 1
		end if
	else
		if iconfound then
			set download to display dialog "An upgrade (" & currentversion & ") is available." buttons {"Later", "Download"} default button 2 with title "iTuneMyWalkman" with icon file itmwicon
		else
			set download to display dialog "An upgrade (" & currentversion & ") is available." buttons {"Later", "Download"} default button 2 with title "iTuneMyWalkman" with icon 1
		end if
		if button returned of download = "Download" then
			tell application "Finder" to open location "http://ilari.scheinin.fidisk.fi/itunemywalkman/download.php"
		end if
	end if
end using terms from