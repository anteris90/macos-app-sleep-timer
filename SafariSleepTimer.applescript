property delayOptions : {"15 perc", "30 perc", "45 perc", "60 perc", "90 perc"}

on run
	repeat
		set timerChoice to my chooseDelay()
		if timerChoice is missing value then
			my resetProgress()
			return
		end if

		set selectedLabel to item 1 of timerChoice
		set delayTime to item 2 of timerChoice

		set timerAction to my runSleepTimer(selectedLabel, delayTime)

		if timerAction is "finished" then
			return
		else if timerAction is "cancelled" then
			set retryDialog to display dialog "Az időzítés leállítva." buttons {"Kilépés", "Új idő"} default button "Új idő"
			if button returned of retryDialog is "Kilépés" then return
		end if
	end repeat
end run

on chooseDelay()
	set choice to choose from list delayOptions ¬
		with prompt "Mikor zárjam be a Safarit?" ¬
		without empty selection allowed

	if choice is false then return missing value

	set selected to item 1 of choice
	return {selected, my secondsForSelection(selected)}
end chooseDelay

on secondsForSelection(selected)
	if selected is "15 perc" then
		return 900
	else if selected is "30 perc" then
		return 1800
	else if selected is "45 perc" then
		return 2700
	else if selected is "60 perc" then
		return 3600
	else if selected is "90 perc" then
		return 5400
	end if

	return 900
end secondsForSelection

on runSleepTimer(selectedLabel, totalSeconds)
	display notification "Safari bezárása időzítve: " & selectedLabel with title "Sleep Timer"

	set progress description to "Safari Sleep Timer"
	set progress total steps to totalSeconds
	set progress completed steps to 0

	try
		repeat with elapsedSeconds from 0 to (totalSeconds - 1)
			set remainingSeconds to totalSeconds - elapsedSeconds
			set progress completed steps to elapsedSeconds
			set progress additional description to "Hátralévő idő: " & my formatRemainingTime(remainingSeconds)
			delay 1
		end repeat
	on error number -128
		my resetProgress()
		return "cancelled"
	end try

	set progress completed steps to totalSeconds
	set progress additional description to "A visszaszámlálás lejárt."

	try
		set warningResponse to display dialog "Safari 10 másodperc múlva bezárul." ¬
			buttons {"Mégse", "Új idő", "Bezárás most"} ¬
			default button "Bezárás most" ¬
			cancel button "Mégse" ¬
			giving up after 10
	on error number -128
		my resetProgress()
		return "cancelled"
	end try

	my resetProgress()

	if gave up of warningResponse then
		my quitSafariIfRunning()
		return "finished"
	end if

	set selectedButton to button returned of warningResponse
	if selectedButton is "Bezárás most" then
		my quitSafariIfRunning()
		return "finished"
	else if selectedButton is "Új idő" then
		return "reschedule"
	end if

	return "cancelled"
end runSleepTimer

on formatRemainingTime(totalSeconds)
	set minutesRemaining to totalSeconds div 60
	set secondsRemaining to totalSeconds mod 60

	if secondsRemaining is less than 10 then
		set secondsText to "0" & secondsRemaining
	else
		set secondsText to secondsRemaining as text
	end if

	return minutesRemaining & ":" & secondsText
end formatRemainingTime

on quitSafariIfRunning()
	if application "Safari" is running then
		tell application "Safari" to quit
	end if
end quitSafariIfRunning

on resetProgress()
	set progress description to ""
	set progress additional description to ""
	set progress total steps to 0
	set progress completed steps to 0
end resetProgress