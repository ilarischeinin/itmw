on adding folder items to this_folder after receiving added_items
	try
		set pref to do shell script "/usr/bin/defaults read com.itmw.itmw phoneDetected"
		set phonedetected to pref as number
	on error
		return
	end try
	if phonedetected = 1 then return
	try
		set musicpath to do shell script "/usr/bin/defaults read com.itmw.itmw musicPath | /usr/bin/sed 's/\\\\\\\\/\\\\/'"
		set dir to do shell script "/bin/ls -d " & musicpath
	on error
		return
	end try
	if dir = "" then return
	if dir contains return then return
	set phonepath to POSIX file dir as string
	tell application "Finder"
		repeat with x in added_items
			if disk of folder phonepath = disk of x then
				if phonedetected = 2 then
					tell me to set sync to choose from list {"Unmount", "Open Image Capture", "Open iPhoto", "Synchronize"} with title "iTuneMyWalkman" with prompt "iTuneMyWalkman has detected the phone. What do you want to do?" with multiple selections allowed
					if sync = false then return
					if sync contains "Unmount" then
						eject disk of x
						return
					end if
					if sync contains "Synchronize" then
						my openapp()
					end if
					if sync contains "Open Image Capture" then open application file id "icac"
					if sync contains "Open iPhoto" then open application file id "iPho"
				else if phonedetected = 3 then
					my openapp()
				end if
			end if
		end repeat
	end tell
end adding folder items to

on openapp()
	tell application "iTuneMyWalkman"
		launch
		activate
		ignoring application responses
			tell button "sync" of window "main" to perform action
		end ignoring
	end tell
end openapp