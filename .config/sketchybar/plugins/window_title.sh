#!/usr/bin/env sh

APP_NAME=$(yabai -m query --windows --window | jq '.app' | sed -E 's/^"(.*)"$/\1/')

if [ "$APP_NAME" = "" ]; then
  sketchybar --set $NAME label="Finder"
else 
  sketchybar --set $NAME label="$APP_NAME"
fi
