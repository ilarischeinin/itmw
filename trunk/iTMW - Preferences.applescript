tell application "iTuneMyWalkman"
	launch
	activate
	ignoring application responses
		tell button "prefs" of window "main" to perform action
	end ignoring
end tell