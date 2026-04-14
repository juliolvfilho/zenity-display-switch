#!/bin/bash

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/display-switch"
CONFIG_FILE="$CONFIG_DIR/config"
EXTEND_DIRECTION="right"

mkdir -p "$CONFIG_DIR"

if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
fi

normalize_extend_direction() {
  case "$1" in
    right|right-of) echo "right" ;;
    left|left-of) echo "left" ;;
    *) return 1 ;;
  esac
}

if [ "$1" = "--config" ]; then
  if [ -z "$2" ]; then
    echo "Missing configuration value. Use: --config extend-direction=left|right"
    exit 1
  fi

  case "$2" in
    extend-direction=*)
      RAW_VALUE="${2#extend-direction=}"
      if ! EXTEND_DIRECTION="$(normalize_extend_direction "$RAW_VALUE")"; then
        echo "Invalid value for extend-direction: $RAW_VALUE (use left or right)"
        exit 1
      fi

      {
        echo "EXTEND_DIRECTION=$EXTEND_DIRECTION"
      } > "$CONFIG_FILE"

      echo "Configuration saved: extend-direction=$EXTEND_DIRECTION"
      exit 0
      ;;
    *)
      echo "Invalid configuration key. Supported: extend-direction=left|right"
      exit 1
      ;;
  esac
fi

if ! EXTEND_DIRECTION="$(normalize_extend_direction "$EXTEND_DIRECTION")"; then
  EXTEND_DIRECTION="right"
fi

if [ "$EXTEND_DIRECTION" = "left" ]; then
  XRANDR_POSITION_FLAG="--left-of"
else
  XRANDR_POSITION_FLAG="--right-of"
fi

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
    xrandr --output "$PRIMARY" --auto --output "$SECONDARY" --auto "$XRANDR_POSITION_FLAG" "$PRIMARY"
    ;;
  secondary)
    xrandr --output "$SECONDARY" --auto --output "$PRIMARY" --off
    ;;
esac
