tell application "iTuneMyWalkman"
	launch
	activate
	ignoring application responses
		tell button "sync" of window "main" to perform action
	end ignoring
end tell