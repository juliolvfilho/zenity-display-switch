#!/bin/bash

MONITORS=($(xrandr | grep " connected" | awk '{print $1}'))
PRIMARY="${MONITORS[0]}"
SECONDARY="${MONITORS[1]}"

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
