#!/usr/bin/env sh

sketchybar --clone system.label label_template \
	--set system.label label=sys \
	position=left \
	drawing=on \
	script="$PLUGIN_DIR/window_title.sh" \
	--subscribe system.label front_app_switched \
	\
	--add alias "Control Center,Battery" left \
	--set "Control Center,Battery" update_freq=2 \
	drawing=$HAS_BATTERY \
	icon.padding_left=-5 \
	label.drawing=off \
	background.padding_left=0 \
	background.padding_right=0 \
	click_script="sketchybar -m --set \"\$NAME\" popup.drawing=toggle" \
	\
	--add item system.battery_details popup."Control Center,Battery" \
	--set system.battery_details icon=test \
	\
	--add alias "Control Center,WiFi" left \
	--set "Control Center,WiFi" update_freq=2 \
	icon.drawing=off \
	label.drawing=off \
	background.padding_left=0 \
	background.padding_right=0 \
	\
	--add alias "Control Center,Sound" left \
	--set "Control Center,Sound" update_freq=2 \
	icon.drawing=off \
	label.drawing=off \
	background.padding_left=-0 \
	background.padding_right=-0 \
	\
	--add item system.mic left \
	--set system.mic update_freq=100 \
	label.drawing=off \
	script="$PLUGIN_DIR/mic.sh" \
	click_script="$PLUGIN_DIR/mic_click.sh" \
	\
	--add item system.yabai_float left \
	--set system.yabai_float script="$PLUGIN_DIR/yabai_float.sh" \
	icon.font="VictorMono Nerd Font:Bold:15.0" \
	label.drawing=off \
	updates=on \
	--subscribe system.yabai_float front_app_switched window_focus mouse.clicked \
	\
	--add bracket system \
	system.label \
	"Control Center,Battery" \
	"Control Center,WiFi" \
	"Control Center,Sound" \
	system.mic \
	system.yabai_float \
	\
	--set system background.drawing=on
