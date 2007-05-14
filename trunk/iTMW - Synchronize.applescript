-- This method is used to hide the tell block from Xcode during compile time.
-- Otherwise the compiling would fail, if the application is not found.

do shell script "/usr/bin/osascript -e \\
	'tell application \"iTuneMyWalkman\"
		launch
		activate
		ignoring application responses
			tell button \"sync\" of window \"main\" to perform action
		end ignoring
	end tell'"