#!/usr/bin/env bash

RUNNING=$(osascript -e 'if application "Spotify" is running then return 0')
if [ "$RUNNING" == "" ]; then
	RUNNING=1
fi
PLAYING=1
TRACK=""
ALBUM=""
ARTIST=""
SHUFFLE=""
REPEAT=""

next() {
	if [ $RUNNING -eq 0 ]; then
		osascript -e 'tell application "Spotify" to play next track'
	fi
}

back() {
	if [ $RUNNING -eq 0 ]; then
		osascript -e 'tell application "Spotify" to play previous track'
	fi
}

play_pause() {
	if [ $RUNNING -eq 0 ]; then
		osascript -e 'tell application "Spotify" to playpause'
	fi
}

repeat() {
	REPEAT=$(osascript -e 'tell application "Spotify" to get repeating')
	if [ "$REPEAT" = "false" ]; then
		sketchybar -m --set spotify.repeat icon.highlight=on
		osascript -e 'tell application "Spotify" to set repeating to true'
	else
		sketchybar -m --set spotify.repeat icon.highlight=off
		osascript -e 'tell application "Spotify" to set repeating to false'
	fi
}

shuffle() {
	SHUFFLE=$(osascript -e 'tell application "Spotify" to get shuffling')
	if [ "$SHUFFLE" = "false" ]; then
		sketchybar -m --set spotify.shuffle icon.highlight=on
		osascript -e 'tell application "Spotify" to set shuffling to true'
	else
		sketchybar -m --set spotify.shuffle icon.highlight=off
		osascript -e 'tell application "Spotify" to set shuffling to false'
	fi
}

update() {
	if [ "$(osascript -e 'if application "Spotify" is running then tell application "Spotify" to get player state')" == "playing" ]; then
		PLAYING=0
		TRACK=$(osascript -e 'tell application "Spotify" to get name of current track' | cut -c1-20)
		ARTIST=$(osascript -e 'tell application "Spotify" to get artist of current track' | cut -c1-20)
		ALBUM=$(osascript -e 'tell application "Spotify" to get album of current track' | cut -c1-20)
		SHUFFLE=$(osascript -e 'tell application "Spotify" to get shuffling')
		REPEAT=$(osascript -e 'tell application "Spotify" to get repeating')
	fi

	args=()
	if [ $RUNNING -eq 0 ] && [ $PLAYING -eq 0 ]; then
		if [ "$ARTIST" == "" ]; then
			args+=(--set spotify.name label="$TRACK  􀉮  $ALBUM" drawing=on)
		else
			args+=(--set spotify.name label="$TRACK  􀉮  $ARTIST" drawing=on)
		fi
		args+=(--set spotify.play_pause icon=契
			--set spotify.shuffle icon.highlight=$SHUFFLE
			--set spotify.repeat icon.highlight=$REPEAT)
	else
		args+=(--set spotify.name drawing=off
			--set spotify.name popup.drawing=off
			--set spotify.play_pause icon=􀊄)
	fi
	sketchybar -m "${args[@]}"
}

mouse_clicked() {
	case "$NAME" in
	"spotify.next")
		next
		;;
	"spotify.back")
		back
		;;
	"spotify.play_pause")
		play_pause
		;;
	"spotify.shuffle")
		shuffle
		;;
	"spotify.repeat")
		repeat
		;;
	*) ;;

	esac
}

case "$SENDER" in
"mouse.clicked")
	mouse_clicked
	;;
*)
	update
	;;
esac
