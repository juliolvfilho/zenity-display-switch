#!/bin/bash

MONITORS=($(xrandr | grep " connected" | awk '{print $1}'))
PRIMARY="${MONITORS[0]}"
SECONDARY="${MONITORS[1]}"

if [ -z "$PRIMARY" ]; then
  zenity --error --title="Display Switch" --text="No connected monitors were detected by xrandr."
  exit 1
fi

if [ -z "$SECONDARY" ]; then
  zenity --warning \
    --title="Display Switch" \
    --text="No secondary monitor detected. Keeping only $PRIMARY enabled."
  xrandr --output "$PRIMARY" --auto
  exit 0
fi

CHOICE=$(zenity --list \
  --title="Display Switch" \
  --text="Choose how to use the monitors:" \
  --column="Mode" \
  --column="Description" \
  "primary"  "PC screen only ($PRIMARY)" \
  "duplicate"  "Duplicate screen" \
  "extend"  "Extend screen" \
  "secondary"   "Secondary screen only ($SECONDARY)" \
  --width=380 --height=280)

case "$CHOICE" in
  primary)
    xrandr --output "$PRIMARY" --auto --output "$SECONDARY" --off
    ;;
  duplicate)
    xrandr --output "$PRIMARY" --auto --output "$SECONDARY" --auto --same-as "$PRIMARY"
    ;;
  extend)
    xrandr --output "$PRIMARY" --auto --output "$SECONDARY" --auto --right-of "$PRIMARY"
    ;;
  secondary)
    xrandr --output "$SECONDARY" --auto --output "$PRIMARY" --off
    ;;
esac
