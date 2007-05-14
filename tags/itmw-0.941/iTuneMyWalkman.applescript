-- iTuneMyWalkman.applescript
-- iTuneMyWalkman

(*
List of handlers in this script

-- EVENT HANDLERS
on launched
on should open untitled theObject
on should quit after last window closed theObject
on idle theObject
on clicked theObject
on choose menu item theObject
on change cell value theObject row theRow table column tableColumn value theValue
on selection changed theObject
-- OWN SUBROUTINES
on startsync()																			
on movepics(myprocess)
on getsongs()
on deleteolds()
on putsongs()
on copynext()
on cleanup()
-- HELPER FUNCTIONS
on getpath(path)
on strip(txt)
on shellcmd(cmd)
on whattodo(filetype, bitrate)
on updateballs()
on scriptsinstalled()
on fainstalled()
on showprefs()
on initprefs()
on checkforold()
*)

property stage : "init"
property itmwversion : "0.941"
property debugging : false

-- EVENT HANDLERS

-- This is called first every time the application starts.
on launched
	initprefs()
	set debugging to contents of default entry "debugging" of user defaults
	checkforold()
end launched

-- This handler checks whether iTuneMyWalkman is the frontmost application.
-- If yes, the main window is shown as the user probably opened the application directly.
-- If not, the call probably came from the iTunes script, so the main window should not be shown.
on should open untitled theObject
	if name of (info for (path to frontmost application)) = name of me & ".app" then
		considering numeric strings
			using terms from application "System Events"
				if system version of (system info) < "10.4" then
					display alert (localized string "Mac OS X 10.4") buttons {localized string "Quit"} default button 1
					quit
				end if
				tell application "Finder" to set hasitunes to exists application file id "com.apple.iTunes"
				if hasitunes then tell application "Finder" to set itunes to name of application file id "com.apple.iTunes"
				if not hasitunes or version of application itunes as text < "7" then
					display alert (localized string "iTunes 7") buttons {localized string "Quit"} default button 1
					quit
				end if
			end using terms from
		end considering
		updateballs()
		try
			tell application "Finder" to set itunesicon to POSIX path of ((application file id "com.apple.iTunes" as string) & ":Contents:Resources:iTunes.icns")
			tell application "Finder" to set fasicon to POSIX path of ((application file id "com.apple.FolderActionsSetup" as string) & ":Contents:Resources:Folder Actions Setup.icns")
			set image of image view "itunes" of window "main" to load image itunesicon
			set image of image view "fas" of window "main" to load image fasicon
		end try
		show window "main"
	end if
end should open untitled

-- Quits the application when the last window is closed
on should quit after last window closed theObject
	if stage = "init" or stage = "done" then return true
	return false
end should quit after last window closed

-- If the copying of files where done within a single method, the application would be unresponsive to user interaction during that time.
-- Instead, the stage property is set to copy, and files are copied individually from the idle handler.
on idle theObject
	if stage = "copy" then copynext()
	return 1
end idle

on clicked theObject
	global musicpath
	if name of window of theObject = "main" then
		if name of theObject = "paypal" then
			open location "https://www.paypal.com/cgi-bin/webscr?cmd=_xclick&business=ilari%2escheinin%40helsinki%2efi&item_name=iTuneMyWalkman&no_shipping=1&no_note=1&tax=0&currency_code=EUR&bn=PP%2dDonationsBF&charset=UTF%2d8"
		else if name of theObject = "sync" then
			startsync()
		else if name of theObject = "prefs" then
			showprefs()
		else if name of theObject = "installscripts" then
			set scriptdir to POSIX path of ((path to library folder from user domain as string) & "iTunes:Scripts:")
			shellcmd("/bin/mkdir -p " & quoted form of scriptdir)
			set mydir to (path to me) & "Contents:Resources:Scripts:" as string
			shellcmd("/bin/cp " & quoted form of POSIX path of mydir & "iTMW*.scpt" & " " & quoted form of scriptdir)
			shellcmd("/bin/rm -f " & quoted form of (scriptdir & "iTMW - Detect Phone.scpt"))
			updateballs()
		else if name of theObject = "removescripts" then
			set scriptdir to POSIX path of ((path to library folder from user domain as string) & "iTunes:Scripts:")
			shellcmd("/bin/rm -f " & (quoted form of scriptdir) & "iTMW*.scpt")
			updateballs()
		else if name of theObject = "installfa" then
			set fadir to path to Folder Action scripts from user domain as string with folder creation
			set mydir to (path to me) & "Contents:Resources:Scripts:" as string
			shellcmd("/bin/cp " & quoted form of POSIX path of (mydir & "iTMW - Detect Phone.scpt") & " " & quoted form of POSIX path of fadir)
			try
				tell application "System Events"
					set folder actions enabled to true
					attach action to folder "Volumes" of startup disk using (fadir & "iTMW - Detect Phone.scpt")
				end tell
			end try
			updateballs()
		else if name of theObject = "removefa" then
			try
				tell application "System Events" to remove action from folder "Volumes" of startup disk using action name "iTMW - Detect Phone.scpt"
			end try
			set fadir to path to Folder Action scripts from user domain as string with folder creation
			shellcmd("/bin/rm -f " & quoted form of POSIX path of (fadir & "iTMW - Detect Phone.scpt"))
			updateballs()
		end if
	else if name of window of theObject = "progress" then
		if name of theObject = "stop" then
			set stage to "stop"
			cleanup()
		end if
	else if name of window of theObject = "prefs" then
		if name of theObject = "changemusic" then
			set dir to quoted form of POSIX path of (choose folder "Choose the music folder of the phone:")
			set contents of text field "musicpath" of box "music" of tab view item "general" of tab view "prefs" of window "prefs" to dir
		else if name of theObject = "changemove" then
			set dir to quoted form of POSIX path of (choose folder "Choose the target folder for pictures and videos:")
			set contents of text field "movepath" of box "move" of tab view item "camera" of tab view "prefs" of window "prefs" to dir
		else if name of theObject = "changeimage" then
			set dir to quoted form of POSIX path of (choose folder "Choose the image folder of the phone:")
			set contents of text field "imagepath" of box "image" of tab view item "camera" of tab view "prefs" of window "prefs" to dir
		else if name of theObject = "changevideo" then
			set dir to quoted form of POSIX path of (choose folder "Choose the camera video folder of the phone:")
			set contents of text field "videopath" of box "video" of tab view item "camera" of tab view "prefs" of window "prefs" to dir
		else if name of theObject = "newitem" then
			set contentlist to {}
			set contentlist to contents of table view "filetypes" of scroll view "filetypes" of tab view item "encode" of tab view "prefs" of window "prefs"
			set contentlist to contentlist & {{".suffix", 0}}
			set contents of table view "filetypes" of scroll view "filetypes" of tab view item "encode" of tab view "prefs" of window "prefs" to contentlist
		else if name of theObject = "removeitem" then
			set contentlist to {}
			set theRow to selected row of table view "filetypes" of scroll view "filetypes" of tab view item "encode" of tab view "prefs" of window "prefs"
			if theRow > 0 then
				set contentlist to contents of table view "filetypes" of scroll view "filetypes" of tab view item "encode" of tab view "prefs" of window "prefs"
				set newcontentlist to {}
				repeat with i from 1 to count contentlist
					if i ­ theRow then set newcontentlist to newcontentlist & {item i of contentlist}
				end repeat
				set contents of table view "filetypes" of scroll view "filetypes" of tab view item "encode" of tab view "prefs" of window "prefs" to newcontentlist
			end if
			set enabled of button "removeitem" of tab view item "encode" of tab view "prefs" of window "prefs" to false
		else if name of theObject = "save" then
			tell tab view "prefs" of window "prefs"
				tell tab view item "general"
					set contents of default entry "musicPath" of user defaults of me to contents of text field "musicpath" of box "music"
					set contents of default entry "phoneDetected" of user defaults of me to tag of current menu item of popup button "phonedetected"
					set contents of default entry "askForConfirmation" of user defaults of me to content of button "confirmation"
					set contents of default entry "synchronizationComplete" of user defaults of me to tag of current menu item of popup button "endsync"
					set contents of default entry "sizeLimit" of user defaults of me to (contents of text field "sizelimit" as number) * 1024 * 1024
				end tell
				tell tab view item "playlists"
					set contents of default entry "syncMusic" of user defaults of me to content of button "syncmusic"
					set contents of default entry "syncPodcasts" of user defaults of me to content of button "syncpodcasts"
					set contents of default entry "whichPlaylists" of user defaults of me to current row of matrix "whichlists"
					set chosenlists to {}
					set checkedlist to contents of table view "playlists" of scroll view "playlists"
					repeat with x in checkedlist
						if ischecked of x then set chosenlists to chosenlists & {listname of x}
					end repeat
					set contents of default entry "chosenPlaylists" of user defaults of me to chosenlists
				end tell
				tell tab view item "folders"
					set contents of default entry "numberOfDirectoryLevels" of user defaults of me to tag of current menu item of popup button "dirlevel"
					set contents of default entry "directoryStructure" of user defaults of me to tag of current menu item of popup button "dirstructure"
					set od to text item delimiters of AppleScript
					set text item delimiters of AppleScript to {":"}
					set excludestring to contents of text field "excludelist"
					set contents of default entry "dontTouch" of user defaults of me to every text item of excludestring
					set text item delimiters of AppleScript to od
				end tell
				tell tab view item "playcount"
					set contents of default entry "incrementPlayCountOnSync" of user defaults of me to contents of text field "ionsync"
					set contents of default entry "incrementPlayCountOnCopy" of user defaults of me to contents of text field "ioncopy"
				end tell
				tell tab view item "encode"
					set contents of default entry "reencoder" of user defaults of me to tag of current menu item of popup button "encoder"
					set filetypelist to {}
					set bitratelist to {}
					set contentlist to {}
					set contentlist to contents of table view "filetypes" of scroll view "filetypes"
					repeat with x in contentlist
						set filetypelist to filetypelist & {filetype of x}
						set bitratelist to bitratelist & {bitrate of x}
					end repeat
					set contents of default entry "fileTypes" of user defaults of me to filetypelist
					set contents of default entry "fileBitRateLimits" of user defaults of me to bitratelist
				end tell
				tell tab view item "camera"
					set contents of default entry "processCameraImages" of user defaults of me to tag of current menu item of popup button "movepics"
					set contents of default entry "moveImagesTo" of user defaults of me to contents of text field "movepath" of box "move"
					set contents of default entry "cameraImagePath" of user defaults of me to contents of text field "imagepath" of box "image"
					set contents of default entry "cameraVideoPath" of user defaults of me to contents of text field "videopath" of box "video"
					set contents of default entry "handleS60Thumbnails" of user defaults of me to content of button "s60thumbs"
				end tell
			end tell
			hide window "prefs"
		else if name of theObject = "cancel" then
			hide window "prefs"
		end if
	end if
end clicked

on choose menu item theObject
	if name of theObject = "prefs" then tell button "prefs" of window "main" to perform action
end choose menu item

on change cell value theObject row theRow table column tableColumn value theValue
	if identifier of tableColumn = "filetype" then
		if character 1 of theValue = "." then
			return theValue
		else
			return "." & theValue
		end if
	else if identifier of tableColumn = "bitrate" then
		try
			set x to theValue as number
		on error
			return false
		end try
		return x
	end if
end change cell value

on selection changed theObject
	if name of theObject is "filetypes" then
		set theRow to selected row of theObject
		if theRow = 0 then
			set enabled of button "removeitem" of tab view item "encode" of tab view "prefs" of window "prefs" to false
		else
			set enabled of button "removeitem" of tab view item "encode" of tab view "prefs" of window "prefs" to true
		end if
	end if
end selection changed

-- OWN SUBROUTINES

on startsync()
	if debugging then log "startsync begins"
	global musicpath
	set stage to "initsync"
	set mymusicpath to contents of default entry "musicPath" of user defaults
	repeat
		set musicpath to getpath(mymusicpath)
		if musicpath = "notfound" then
			using terms from application "System Events"
				set relocate to display alert (localized string "phone not found") message mymusicpath buttons {localized string "Cancel", localized string "Locate..."} default button 2
				set stage to "done"
				return
			end using terms from
			if button returned of relocate = (localized string "Cancel") then return
			set mymusicpath to quoted form of POSIX path of (choose folder "Choose the music folder of the phone:")
			set contents of default entry "musicPath" of user defaults of me to mymusicpath
		else if musicpath = "ambiguous" then
			using terms from application "System Events"
				display alert (localized string "ambiguous path") message mymusicpath buttons {localized string "OK"} default button 1
			end using terms from
			return
		else
			exit repeat
		end if
	end repeat
	if (contents of default entry "askForConfirmation" of user defaults) then
		using terms from application "System Events"
			set confirmation to button returned of (display alert (localized string "confirmation") message musicpath & return & return & (localized string "confirmation2") buttons {localized string "Cancel", localized string "Continue"} default button 1)
		end using terms from
		if confirmation = (localized string "Cancel") then return
	end if
	global starttime, myencoder, oldenc, mybitrate, mysuffix, mydirlevel, mydirstruct, myincsync, myinccopy, myfiletypelimits, copied, copiedsize, notcopied, total
	set starttime to current date
	tell window "progress"
		set content of text field "status" to "Initializing"
		set content of text field "song" to ""
		start progress indicator "progressbar"
		update
		show
	end tell
	set myprocess to contents of default entry "processCameraImages" of user defaults
	if (myprocess) > 1 then movepics(myprocess)
	set myencoder to contents of default entry "reencoder" of user defaults
	set mydirlevel to contents of default entry "numberOfDirectoryLevels" of user defaults
	set mydirstruct to contents of default entry "directoryStructure" of user defaults
	set myincsync to contents of default entry "incrementPlayCountOnSync" of user defaults
	set myinccopy to contents of default entry "incrementPlayCountOnCopy" of user defaults
	set filetypelist to contents of default entry "fileTypes" of user defaults of me
	set bitratelist to contents of default entry "fileBitRateLimits" of user defaults of me
	set myfiletypelimits to {}
	repeat with i from 1 to count filetypelist
		set myfiletypelimits to myfiletypelimits & {{item i of filetypelist, item i of bitratelist}}
	end repeat
	if myencoder ­ 1 then
		set emptytrack to (path to me) & "Contents:Resources:empty.m4a" as string
		tell application "iTunes"
			set oldenc to current encoder
			try
				if myencoder = 3 then
					set current encoder to encoder "MP3 encoder"
					set mysuffix to ".mp3"
				else
					set current encoder to encoder "AAC encoder"
					set mysuffix to ".m4a"
				end if
				set convertedtrack to convert alias emptytrack
				set mybitrate to bit rate of item 1 of convertedtrack
				delete item 1 of convertedtrack
				my shellcmd("/bin/rm -f " & quoted form of POSIX path of (location of item 1 of convertedtrack))
			on error msg
				tell me to log msg
			end try
		end tell
	end if
	set total to 0
	set copied to 0
	set copiedsize to 0
	set notcopied to 0
	getsongs()
	deleteolds()
	putsongs()
	if debugging then log "startsync ends"
end startsync


on movepics(myprocess)
	if debugging then log "movepics begins"
	tell window "progress"
		set content of text field "status" to "Moving camera pictures and videos"
		update
	end tell
	set fils to {}
	set importlist to {}
	set myexclude to contents of default entry "dontTouch" of user defaults
	set s60thumbs to contents of default entry "handleS60Thumbnails" of user defaults
	set excludestring to ""
	repeat with x in myexclude
		if x as string ­ "" then set excludestring to excludestring & " -not -iname \"" & x & "\" -not -ipath \"*/" & x & "/*\""
	end repeat
	set myimagepath to getpath(contents of default entry "cameraImagePath" of user defaults)
	if myimagepath ­ "notfound" and myimagepath ­ "ambiguous" then
		if s60thumbs then
			set imgs to shellcmd("/usr/bin/find " & quoted form of myimagepath & " -type f -iname '*.jpg' -not -name '.*'" & excludestring)
		else
			set imgs to shellcmd("/usr/bin/find " & quoted form of myimagepath & " -type f -not -name '.*'" & excludestring)
		end if
		repeat with x in every paragraph of imgs
			if x as string = "" then exit repeat
			set fils to fils & {x as string}
			set importlist to importlist & {alias (POSIX file (x as string) as string)}
		end repeat
	end if
	set myvideopath to getpath(contents of default entry "cameraVideoPath" of user defaults)
	if myvideopath ­ "notfound" and myvideopath ­ "ambiguous" then
		set vids to shellcmd("/usr/bin/find " & quoted form of myvideopath & " -type f -not -name '.*'" & excludestring)
		repeat with x in every paragraph of vids
			if x as string = "" then exit repeat
			set fils to fils & {x as string}
			set importlist to importlist & {alias (POSIX file (x as string) as string)}
		end repeat
	end if
	if fils = {} then return
	if myprocess = 3 then -- iPhoto
		tell application "Finder" to set hasiphoto to exists application file id "com.apple.iPhoto"
		if hasiphoto then tell application "Finder" to set iphoto to name of application file id "com.apple.iPhoto"
		considering numeric strings
			if not hasiphoto or version of application iphoto < "6" then
				using terms from application "System Events"
					display alert (localized string "iPhoto 6") buttons {localized string "OK"} default button 1
				end using terms from
				return
			end if
		end considering
		using terms from application "iPhoto"
			tell application iphoto
				import from importlist
				repeat while importing
					my shellcmd("/bin/sleep 1")
				end repeat
				set imported to count photos of last rolls album
			end tell
		end using terms from
		set num to count importlist
		if imported ­ num then
			set sure to display dialog "iTuneMyWalkman tried to import " & num & " items to iPhoto, but your last rolls album contains " & imported & " pictures. Should iTuneMyWalkman delete the files from the memory stick or not?" buttons {localized string "Delete", localized string "Keep Files"}
			if button returned of sure = (localized string "Keep Files") then return
		end if
		repeat with x in fils
			if s60thumbs then
				shellcmd("/bin/rm -rf " & quoted form of x & "*")
			else
				shellcmd("/bin/rm -rf " & quoted form of x)
			end if
		end repeat
	else
		set mymovepath to contents of default entry "moveImagesTo" of user defaults
		if mymovepath ­ "notfound" and mymovepath ­ "ambiguous" then
			set newdir to shellcmd("/bin/date '+%y-%m-%d\\ %H.%M.%S'")
			shellcmd("/bin/mkdir -p " & mymovepath & newdir)
			repeat with x in fils
				if x as string = "" then exit repeat
				try
					shellcmd("/bin/cp " & quoted form of x & " " & mymovepath & newdir)
					if s60thumbs then
						shellcmd("/bin/rm " & quoted form of x & "*")
					else
						shellcmd("/bin/rm " & quoted form of x)
					end if
				on error msg
					using terms from application "System Events"
						display alert (localized string "picture error") message msg buttons {localized string "OK"} default button 1
					end using terms from
				end try
			end repeat
		end if
	end if
	if debugging then log "movepics ends"
end movepics

on getsongs()
	if debugging then log "getsongs begins"
	tell window "progress"
		set content of text field "status" to "Collecting data from iTunes"
		update
	end tell
	global musicpath, mydirlevel, mydirstruct, myincsync, myinccopy, myencoder, mybitrate, mysuffix
	global filelist, songlist, dirlist, targetlist, tracklist, encodelist, totalsize
	set filelist to {}
	set songlist to {}
	set dirlist to {musicpath}
	set targetlist to {}
	set tracklist to {}
	set encodelist to {}
	set totalsize to 0
	set mysizelimit to contents of default entry "sizeLimit" of user defaults
	if mysizelimit < 0 then
		tell application "Finder" to set mysizelimit to (free space of disk of folder (POSIX file musicpath as string)) + mysizelimit
	end if
	set syncmusic to contents of default entry "syncMusic" of user defaults
	set syncpodcasts to contents of default entry "syncPodcasts" of user defaults
	set whichlists to contents of default entry "whichPlaylists" of user defaults
	if syncpodcasts then
		tell application "iTunes"
			set plists to every playlist whose special kind = Podcasts
			repeat with plist in plists
				repeat with x in (every file track of plist whose enabled = true)
					set songfile to location of x
					if songfile ­ missing value and songfile is not in filelist then
						tell application "Finder"
							set songname to name of songfile as string
							set suffix to "." & name extension of songfile as string
						end tell
						set howto to my whattodo(suffix, bit rate of x)
						if howto > -1 then
							if howto = 1 then
								set filesize to (duration of x) * mybitrate * 125 -- 125 = 1000 / 8
								set songname to characters 1 thru (-1 - (count suffix)) of songname & mysuffix as string
								set encoded to true
							else
								set filesize to size of x
								set encoded to false
							end if
							if mysizelimit = 0 or (totalsize + filesize ² mysizelimit) then
								set filelist to filelist & {songfile}
								set tracklist to tracklist & {x}
								if myincsync > 0 then
									set played count of x to (played count of x) + myincsync
									set played date of x to current date
								end if
								set songlist to songlist & {songname}
								set totalsize to totalsize + filesize
								set encodelist to encodelist & {encoded}
								if mydirlevel = 2 then
									set targetlist to targetlist & {musicpath & "/Podcasts/Podcasts/" & songname}
									set tmp to musicpath & "/Podcasts/Podcasts"
									if tmp is not in dirlist then set dirlist to dirlist & {tmp}
									set tmp to musicpath & "/Podcasts"
									if tmp is not in dirlist then set dirlist to dirlist & {tmp}
								else if mydirlevel = 1 then
									set targetlist to targetlist & {musicpath & "/Podcasts/" & songname}
									set tmp to musicpath & "/Podcasts"
									if tmp is not in dirlist then set dirlist to dirlist & {tmp}
								else
									set targetlist to targetlist & {musicpath & "/" & songname}
								end if
							end if
						end if
					end if
				end repeat
			end repeat
		end tell
	end if
	if syncmusic then
		if whichlists = 1 then
			set plists to {}
			tell application "iTunes"
				repeat with x in every user playlist
					if (exists parent of x) and (name of parent of x begins with "iTuneMyWalkman" or name of parent of x begins with "iTMW") then
						set plists to plists & {name of x}
					end if
					if special kind of x ­ folder and (name of x begins with "iTuneMyWalkman" or name of x begins with "iTMW") then
						set plists to plists & {name of x}
					end if
				end repeat
			end tell
		else
			set plists to contents of default entry "chosenPlaylists" of user defaults
		end if
		if plists = {} then
			using terms from application "System Events"
				display alert (localized string "playlist error") message (localized string "create playlists") buttons {localized string "OK"} default button 1
			end using terms from
		end if
		repeat with i from 1 to count plists
			repeat with j from 2 to (count plists) - i + 1
				if item (j - 1) of plists > item j of plists then
					set tmp to item (j - 1) of plists
					set item (j - 1) of plists to item j of plists
					set item j of plists to tmp
				end if
			end repeat
		end repeat
		tell application "iTunes"
			repeat with plist in plists
				if exists user playlist plist then
					repeat with x in (every file track of user playlist plist whose enabled = true)
						set songfile to location of x
						if songfile ­ missing value and songfile is not in filelist then
							tell application "Finder"
								set songname to name of songfile as string
								set suffix to "." & name extension of songfile as string
							end tell
							set howto to my whattodo(suffix, bit rate of x)
							if howto > -1 then
								if howto = 1 then
									set filesize to (duration of x) * mybitrate * 125 -- 125 = 1000 / 8
									set songname to characters 1 thru (-1 - (count suffix)) of songname & mysuffix as string
									set encoded to true
								else
									set filesize to size of x
									set encoded to false
								end if
								if mysizelimit = 0 or (totalsize + filesize ² mysizelimit) then
									set filelist to filelist & {songfile}
									set tracklist to tracklist & {x}
									if myincsync > 0 then
										set played count of x to (played count of x) + myincsync
										set played date of x to current date
									end if
									set songlist to songlist & {songname}
									set totalsize to totalsize + filesize
									set encodelist to encodelist & {encoded}
									if mydirstruct = 1 then -- artist/album/
										set artistname to my strip(album artist of x as string)
										if artistname = "" then set artistname to my strip(artist of x as string)
										if artistname = "" then set artistname to localized string "Unknown Artist"
										set albumname to my strip(album of x as string)
										if albumname = "" then set albumname to localized string "Unknown Album"
										set discnum to disc number of x
										if discnum > 1 then set albumname to albumname & " " & discnum
									else if mydirstruct = 2 then -- Music/playlist/
										set artistname to "Music"
										set albumname to my strip(name of user playlist plist)
									else -- iTuneMyWalkman/genre/
										set artistname to "Music"
										set albumname to my strip(genre of x as string)
										if albumname = "" then set albumname to "Unknown Genre"
									end if
									if mydirlevel = 2 then -- two levels of folders
										set targetlist to targetlist & {musicpath & "/" & artistname & "/" & albumname & "/" & songname}
										set tmp to musicpath & "/" & artistname
										if tmp is not in dirlist then set dirlist to dirlist & {tmp}
										set tmp to musicpath & "/" & artistname & "/" & albumname
										if tmp is not in dirlist then set dirlist to dirlist & {tmp}
									else if mydirlevel = 1 then -- one folder level
										set targetlist to targetlist & {musicpath & "/" & albumname & "/" & songname}
										set tmp to musicpath & "/" & albumname
										if tmp is not in dirlist then set dirlist to dirlist & {tmp}
									else -- no folders
										set targetlist to targetlist & {musicpath & "/" & songname}
									end if
								end if
							end if
						end if
					end repeat
				end if
			end repeat
		end tell
	end if
	if debugging then log "getsongs ends"
end getsongs

on deleteolds()
	if debugging then log "deleteolds begins"
	tell window "progress"
		set content of text field "status" to "Cleaning up memory card"
		update
	end tell
	global musicpath, dirlist, targetlist
	set myexclude to contents of default entry "dontTouch" of user defaults
	set excludestring to ""
	repeat with x in myexclude
		if x as string ­ "" then set excludestring to excludestring & " -not -iname \"" & x & "\" -not -ipath \"*/" & x & "/*\""
	end repeat
	set dirs to shellcmd("/usr/bin/find " & quoted form of musicpath & " -type d" & excludestring)
	repeat with x in every paragraph of dirs
		if x as string = "" then exit repeat
		if x is not in dirlist then
			shellcmd("/bin/rm -rf " & quoted form of x)
			if debugging then log "deleting unneeded directory: " & x
		end if
	end repeat
	set fils to shellcmd("/usr/bin/find " & quoted form of musicpath & " -type f" & excludestring)
	repeat with x in every paragraph of fils
		if x as string = "" then exit repeat
		if x is not in targetlist then
			shellcmd("/bin/rm -f " & quoted form of x)
			if debugging then log "deleting unneeded file: " & x
		end if
	end repeat
	if debugging then log "deleteolds ends"
end deleteolds

on putsongs()
	if debugging then log "putsongs begins"
	global pos, musicpath, songlist, dirlist, total
	set total to count songlist
	tell window "progress"
		set content of text field "status" to "Transferring songs"
		set maximum value of progress indicator "progressbar" to total
		set indeterminate of progress indicator "progressbar" to false
		set content of progress indicator "progressbar" to 0
		update
	end tell
	repeat with x in dirlist
		shellcmd("/bin/mkdir -p " & quoted form of x)
	end repeat
	set stage to "copy"
	set pos to 1
	idle {}
	if debugging then log "putongs ends"
end putsongs

on copynext()
	global musicpath, pos, mydirlevel, mydirstruct, myincsync, myinccopy, filelist, songlist, targetlist, tracklist, encodelist, total, copied, copiedsize, notcopied
	if pos > total then
		set stage to "finishing"
		cleanup()
		return 1
	end if
	tell window "progress"
		set content of text field "song" to item pos of songlist
		update
	end tell
	set wasfound to true
	try
		shellcmd("/bin/test -f " & quoted form of (characters 1 thru -4 of (item pos of targetlist) as string) & "*")
	on error
		set wasfound to false
	end try
	with timeout of 3600 seconds
		if not wasfound then
			if not item pos of encodelist then -- just copy
				tell application "Finder" to set thesize to size of (item pos of filelist)
				try
					shellcmd("/bin/cp " & quoted form of POSIX path of (item pos of filelist) & " " & quoted form of item pos of targetlist)
					set copied to copied + 1
					if thesize ­ missing value then set copiedsize to copiedsize + thesize
					if myinccopy > 0 then
						tell application "iTunes"
							set played count of item pos of tracklist to (played count of item pos of tracklist) + myinccopy
							set played date of item pos of tracklist to current date
						end tell
					end if
				on error msg
					log msg
					set notcopied to notcopied + 1
					shellcmd("/bin/rm -f " & quoted form of item pos of targetlist)
				end try
			else -- reencode, then copy
				tell application "iTunes"
					set encodedtracks to convert item pos of tracklist
					set encodedfile to location of item 1 of encodedtracks
				end tell
				tell application "Finder" to set thesize to size of encodedfile
				try
					shellcmd("/bin/cp " & quoted form of POSIX path of encodedfile & " " & quoted form of item pos of targetlist)
					set copied to copied + 1
					if thesize ­ missing value then set copiedsize to copiedsize + thesize
					if myinccopy > 0 then
						tell application "iTunes"
							set played count of item pos of tracklist to (played count of item pos of tracklist) + myinccopy
							set played date of item pos of tracklist to current date
						end tell
					end if
				on error msg
					log msg
					set notcopied to notcopied + 1
					shellcmd("/bin/rm -f " & quoted form of item pos of targetlist)
				end try
				tell application "iTunes" to delete item 1 of encodedtracks
				shellcmd("/bin/rm -f " & quoted form of POSIX path of encodedfile)
			end if
		else
			if debugging then log "skipping " & item pos of songlist
		end if
	end timeout
	tell window "progress"
		set content of progress indicator "progressbar" to pos
		update
	end tell
	set pos to pos + 1
end copynext

on cleanup()
	global myencoder, musicpath, copied, total, copiedsize, totalsize, notcopied, oldenc, starttime
	tell window "progress"
		set content of text field "status" to "Cleaning up"
		set content of text field "song" to ""
		set indeterminate of progress indicator "progressbar" to true
		update
	end tell
	try
		shellcmd("/usr/bin/find " & quoted form of musicpath & " -name '.DS_Store' -exec rm {} \\;")
	end try
	try
		shellcmd("/usr/bin/find " & quoted form of musicpath & " -name '._*' -exec rm {} \\;")
	end try
	if myencoder ­ 1 then tell application "iTunes" to set current encoder to oldenc
	set duration to (current date) - starttime
	set mydone to contents of default entry "synchronizationComplete" of user defaults
	if mydone = 2 then -- Ask
		using terms from application "System Events"
			set themessage to localized string "Copied" & " " & copied & " / " & total & " " & (localized string "tracks" & " (" & (copiedsize * 10 / 1024 div 1024 / 10) & " " & (localized string "MB" & " / " & (totalsize * 10 / 1024 div 1024 / 10) & " " & (localized string "MB" & ")")))
			if notcopied ­ 0 then set themessage to themessage & return & (localized string "Warning" & ": " & notcopied & " " & (localized string "files could not be copied."))
			set unmount to button returned of (display alert (localized string "complete") message themessage buttons {localized string "Don't Unmount", localized string "Unmount"})
			if unmount = (localized string "Unmount") then
				tell application "Finder" to eject disk of folder (POSIX file musicpath as string)
			end if
		end using terms from
	end if
	if mydone = 3 then -- Beep
		beep
	else if mydone = 4 then -- Spean notification
		say "iTuneMyWalkman synchronization complete"
	else if mydone = 5 then -- Unmount phone
		tell application "Finder" to eject disk of folder (POSIX file musicpath as string)
	else if mydone = 6 then -- Unmount phone & beep
		tell application "Finder" to eject disk of folder (POSIX file musicpath as string)
		beep
	else if mydone = 7 then -- Unmount phone & speak notification
		tell application "Finder" to eject disk of folder (POSIX file musicpath as string)
		say "iTuneMyWalkman synchronization complete"
	end if
	set stage to "done"
	hide window "progress"
end cleanup

-- HELPER FUNCTIONS

on getpath(path)
	try
		-- set dir to shellcmd("/usr/bin/find /Volumes -ipath " & quoted form of path)
		set dir to shellcmd("/bin/ls -d " & path)
	on error
		return "notfound"
	end try
	if dir = "" then return "notfound"
	if dir contains return then return "ambiguous"
	return dir
end getpath

on strip(txt)
	try
		return shellcmd("/bin/echo " & quoted form of txt & " | /usr/bin/sed 's/[:\\?'\\''\\/]//g'")
	on error msg
		display dialog msg
	end try
end strip

on shellcmd(cmd)
	if debugging then log "Running shell command: " & cmd
	return do shell script cmd
end shellcmd

on whattodo(filetype, bitrate)
	global myencoder, myfiletypelimits
	repeat with x in myfiletypelimits
		if item 1 of x = filetype then
			if myencoder ­ 1 and bitrate > item 2 of x then
				return 1 -- re-encode
			else
				return 0 -- copy
			end if
		end if
	end repeat
	return -1 -- ignore file
end whattodo

on updateballs()
	set greenball to load image "green.gif"
	set redball to load image "red.gif"
	if scriptsinstalled() then
		set image of image view "scriptson" of window "main" to greenball
	else
		set image of image view "scriptson" of window "main" to redball
	end if
	tell application "System Events" to set ison to folder actions enabled
	if ison and fainstalled() then
		set image of image view "faon" of window "main" to greenball
	else
		set image of image view "faon" of window "main" to redball
	end if
end updateballs

on scriptsinstalled()
	set scriptdir to POSIX path of ((path to library folder from user domain as string) & "iTunes:Scripts:")
	try
		shellcmd("/bin/test -f " & quoted form of (scriptdir & "iTMW - Check for New Version.scpt"))
		shellcmd("/bin/test -f " & quoted form of (scriptdir & "iTMW - Increment Play Count.scpt"))
		shellcmd("/bin/test -f " & quoted form of (scriptdir & "iTMW - Preferences.scpt"))
		shellcmd("/bin/test -f " & quoted form of (scriptdir & "iTMW - Synchronize.scpt"))
		shellcmd("/bin/test -f " & quoted form of (scriptdir & "iTMW - Unmount Phone.scpt"))
	on error
		return false
	end try
	return true
end scriptsinstalled

on fainstalled()
	tell application "System Events" to set actionlist to attached scripts folder "Volumes" of startup disk
	tell application "Finder"
		repeat with x in actionlist
			if name of x = "iTMW - Detect Phone.scpt" then return true
		end repeat
	end tell
	return false
end fainstalled

on showprefs()
	tell tab view "prefs" of window "prefs"
		tell tab view item "general" of tab view "prefs" of window "prefs"
			set contents of text field "musicpath" of box "music" to (contents of default entry "musicPath" of user defaults of me)
			set current menu item of popup button "phonedetected" to menu item (contents of default entry "phoneDetected" of user defaults of me) of popup button "phonedetected"
			set content of button "confirmation" to contents of default entry "askForConfirmation" of user defaults of me
			set current menu item of popup button "endsync" to menu item (contents of default entry "synchronizationComplete" of user defaults of me) of popup button "endsync"
			set contents of text field "sizelimit" to (contents of default entry "sizeLimit" of user defaults of me) / 1024 div 1024
		end tell
		tell tab view item "playlists"
			set content of button "syncmusic" to contents of default entry "syncMusic" of user defaults of me
			set content of button "syncpodcasts" to contents of default entry "syncPodcasts" of user defaults of me
			set current row of matrix "whichlists" to contents of default entry "whichPlaylists" of user defaults of me
			set chosenlists to contents of default entry "chosenPlaylists" of user defaults of me
			set checkedlist to {}
			tell application "iTunes" to set alllists to name of every user playlist
			repeat with x in alllists
				if x is in chosenlists then
					set checkedlist to checkedlist & {{true, x}}
				else
					set checkedlist to checkedlist & {{false, x}}
				end if
			end repeat
			set contents of table view "playlists" of scroll view "playlists" to checkedlist
		end tell
		tell tab view item "folders"
			set current menu item of popup button "dirlevel" to menu item ((contents of default entry "numberOfDirectoryLevels" of user defaults of me) + 1) of popup button "dirlevel"
			set current menu item of popup button "dirstructure" to menu item (contents of default entry "directoryStructure" of user defaults of me) of popup button "dirstructure"
			set od to text item delimiters of AppleScript
			set text item delimiters of AppleScript to {":"}
			set contents of text field "excludelist" to (contents of default entry "dontTouch" of user defaults of me) as string
			set text item delimiters of AppleScript to od
		end tell
		tell tab view item "playcount"
			set contents of text field "ionsync" to (contents of default entry "incrementPlayCountOnSync" of user defaults of me)
			set contents of text field "ioncopy" to (contents of default entry "incrementPlayCountOnCopy" of user defaults of me)
		end tell
		tell tab view item "encode"
			set current menu item of popup button "encoder" to menu item (contents of default entry "reencoder" of user defaults of me) of popup button "encoder"
			set filetypelist to contents of default entry "fileTypes" of user defaults of me
			set bitratelist to contents of default entry "fileBitRateLimits" of user defaults of me
			set contentlist to {}
			repeat with i from 1 to count filetypelist
				set contentlist to contentlist & {{item i of filetypelist, item i of bitratelist}}
			end repeat
			set contents of table view "filetypes" of scroll view "filetypes" to contentlist
		end tell
		tell tab view item "camera"
			set current menu item of popup button "movepics" to menu item (contents of default entry "processCameraImages" of user defaults of me) of popup button "movepics"
			set contents of text field "movepath" of box "move" to (contents of default entry "moveImagesTo" of user defaults of me)
			set contents of text field "imagepath" of box "image" to (contents of default entry "cameraImagePath" of user defaults of me)
			set contents of text field "videopath" of box "video" to (contents of default entry "cameraVideoPath" of user defaults of me)
			set content of button "s60thumbs" to contents of default entry "handleS60Thumbnails" of user defaults of me
		end tell
	end tell
	show window "prefs"
end showprefs

on initprefs()
	tell user defaults
		make new default entry at end of default entries with properties {name:"musicPath", contents:"/Volumes/*/MSSEMC/Media\\ files/audio/"}
		make new default entry at end of default entries with properties {name:"videoPath", contents:"/Volumes/*/MSSEMC/Media\\ files/video/"}
		make new default entry at end of default entries with properties {name:"phoneDetected", contents:2}
		make new default entry at end of default entries with properties {name:"askForConfirmation", contents:true}
		make new default entry at end of default entries with properties {name:"syncMusic", contents:true}
		make new default entry at end of default entries with properties {name:"syncPodcasts", contents:true}
		make new default entry at end of default entries with properties {name:"synchronizationComplete", contents:2}
		make new default entry at end of default entries with properties {name:"sizeLimit", contents:0}
		make new default entry at end of default entries with properties {name:"directoryStructure", contents:1}
		make new default entry at end of default entries with properties {name:"numberOfDirectoryLevels", contents:2}
		make new default entry at end of default entries with properties {name:"dontTouch", contents:{"ringtones", "videodj"}}
		make new default entry at end of default entries with properties {name:"incrementPlayCountOnSync", contents:0}
		make new default entry at end of default entries with properties {name:"incrementPlayCountOnCopy", contents:0}
		make new default entry at end of default entries with properties {name:"reencoder", contents:1}
		make new default entry at end of default entries with properties {name:"processCameraImages", contents:1}
		make new default entry at end of default entries with properties {name:"moveImagesTo", contents:"~/Desktop/Pictures\\ from\\ Phone/"}
		make new default entry at end of default entries with properties {name:"cameraImagePath", contents:"/Volumes/*/DCIM"}
		make new default entry at end of default entries with properties {name:"cameraVideoPath", contents:"/Volumes/*/MSSEMC/Media\\ files/video/camera/"}
		make new default entry at end of default entries with properties {name:"fileTypes", contents:{".m4a", ".mp3"}}
		make new default entry at end of default entries with properties {name:"fileBitRateLimits", contents:{128, 128}}
		make new default entry at end of default entries with properties {name:"itmwVersion", contents:itmwversion}
		make new default entry at end of default entries with properties {name:"chosenPlaylists", contents:{}}
		make new default entry at end of default entries with properties {name:"whichPlaylists", contents:1}
		make new default entry at end of default entries with properties {name:"handleS60Thumbnails", contents:false}
		make new default entry at end of default entries with properties {name:"debugging", contents:false}
	end tell
end initprefs

on checkforold()
	set lastversion to contents of default entry "itmwVersion" of user defaults
	considering numeric strings
		if lastversion as text < itmwversion then
			if scriptsinstalled() then tell button "installscripts" of window "main" to perform action
			if fainstalled() then tell button "installfa" of window "main" to perform action
			set contents of default entry "itmwVersion" of user defaults to itmwversion
		end if
	end considering
	set oldprefs to (path to preferences folder from user domain as string) & "iTuneMyWalkman.scpt"
	set wasfound to true
	try
		shellcmd("/bin/test -f " & quoted form of POSIX path of oldprefs)
	on error
		set wasfound to false
	end try
	if not wasfound then return
	set sure to display dialog (localized string "old version") buttons {localized string "Quit", localized string "Continue"} default button 2 with icon 2
	if button returned of sure = (localized string "Quit") then
		tell me to close window "main"
		return
	end if
	set cmdlist to {}
	set cmdlist to cmdlist & {"rm -rf " & quoted form of POSIX path of ((path to library folder from local domain as string) & "iTunes:Scripts:iTMW - Synchronize.scpt")}
	set cmdlist to cmdlist & {"rm -rf " & quoted form of POSIX path of ((path to library folder from local domain as string) & "iTunes:Scripts:iTMW - Set Size Limit.scpt")}
	set cmdlist to cmdlist & {"rm -rf " & quoted form of POSIX path of ((path to library folder from local domain as string) & "iTunes:Scripts:iTMW - Preferences.scpt")}
	set cmdlist to cmdlist & {"rm -rf " & quoted form of POSIX path of ((path to library folder from local domain as string) & "iTunes:Scripts:iTMW - Increment Play Count.scpt")}
	set cmdlist to cmdlist & {"rm -rf " & quoted form of POSIX path of ((path to library folder from local domain as string) & "iTunes:Scripts:iTMW - Check for New Version.scpt")}
	set cmdlist to cmdlist & {"rm -rf " & quoted form of POSIX path of ((path to library folder from local domain as string) & "iTunes:Scripts:iTMW - Unmount Phone.scpt")}
	set cmdlist to cmdlist & {"rm -rf " & quoted form of POSIX path of ((path to application support from local domain as string) & "iTuneMyWalkman:")}
	set cmdlist to cmdlist & {"rm -rf " & quoted form of POSIX path of ((path to Folder Action scripts from local domain as string) & "iTMW - Detect Phone.scpt")}
	set cmdlist to cmdlist & {"rm -rf " & quoted form of POSIX path of ((path to library folder from local domain as string) & "Receipts:iTuneMyWalkman.pkg")}
	set thecmd to ""
	repeat with cmd in cmdlist
		set thecmd to thecmd & cmd & " ; "
	end repeat
	do shell script "/bin/sh -c " & quoted form of thecmd with administrator privileges
	try
		tell application "System Events" to remove action from folder "Volumes" of startup disk using action name "iTMW - Detect Phone.scpt"
	end try
	try
		set prefs to load script file oldprefs
		set contents of default entry "musicPath" of user defaults to musicpath of prefs
		set contents of default entry "phoneDetected" of user defaults to phonedetected of prefs
		if startsync of prefs = 2 then set contents of default entry "askForConfirmation" to false
		set contents of default entry "synchronizationComplete" of user defaults to endsync of prefs
		set contents of default entry "sizeLimit" of user defaults to sizelimit of prefs
		set contents of default entry "directoryStructure" of user defaults to directorystructure of prefs
		set contents of default entry "numberOfDirectoryLevels" of user defaults to directorylevel of prefs
		set contents of default entry "dontTouch" of user defaults to excludelist of prefs
		set contents of default entry "incrementPlayCountOnCopy" of user defaults to incrementoncopy of prefs
		set contents of default entry "incrementPlayCountOnSync" of user defaults to incrementonsync of prefs
		set contents of default entry "reencoder" of user defaults to encodewith of prefs
		set contents of default entry "processCameraImages" of user defaults to movepics of prefs
		set contents of default entry "moveImagesTo" of user defaults to movepath of prefs
		set contents of default entry "cameraImagePath" of user defaults to imagepath of prefs
		set contents of default entry "cameraVideoPath" of user defaults to videopath of prefs
	end try
	shellcmd("rm -rf " & quoted form of POSIX path of (oldprefs))
	tell button "installscripts" of window "main" to perform action
	tell button "installfa" of window "main" to perform action
	tell button "prefs" of window "main" to perform action
end checkforold