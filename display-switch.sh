#!/bin/bash

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/display-switch"
CONFIG_FILE="$CONFIG_DIR/config"
EXTEND_DIRECTION="right"
CINNAMON_WALLPAPER_ASPECT_PRIMARY=""
CINNAMON_WALLPAPER_ASPECT_DUPLICATE=""
CINNAMON_WALLPAPER_ASPECT_EXTEND=""
CINNAMON_WALLPAPER_ASPECT_SECONDARY=""

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

normalize_cinnamon_wallpaper_aspect() {
  case "$1" in
    none|wallpaper|centered|scaled|stretched|zoom|spanned) echo "$1" ;;
    *) return 1 ;;
  esac
}

normalize_mode_name() {
  case "$1" in
    primary|duplicate|extend|secondary) echo "$1" ;;
    *) return 1 ;;
  esac
}

save_config() {
  {
    echo "EXTEND_DIRECTION=$EXTEND_DIRECTION"
    [ -n "$CINNAMON_WALLPAPER_ASPECT_PRIMARY" ] && echo "CINNAMON_WALLPAPER_ASPECT_PRIMARY=$CINNAMON_WALLPAPER_ASPECT_PRIMARY"
    [ -n "$CINNAMON_WALLPAPER_ASPECT_DUPLICATE" ] && echo "CINNAMON_WALLPAPER_ASPECT_DUPLICATE=$CINNAMON_WALLPAPER_ASPECT_DUPLICATE"
    [ -n "$CINNAMON_WALLPAPER_ASPECT_EXTEND" ] && echo "CINNAMON_WALLPAPER_ASPECT_EXTEND=$CINNAMON_WALLPAPER_ASPECT_EXTEND"
    [ -n "$CINNAMON_WALLPAPER_ASPECT_SECONDARY" ] && echo "CINNAMON_WALLPAPER_ASPECT_SECONDARY=$CINNAMON_WALLPAPER_ASPECT_SECONDARY"
  } > "$CONFIG_FILE"
}

set_cinnamon_wallpaper_aspect_for_mode() {
  MODE_NAME="$1"
  WALLPAPER_ASPECT="$2"

  case "$MODE_NAME" in
    primary) CINNAMON_WALLPAPER_ASPECT_PRIMARY="$WALLPAPER_ASPECT" ;;
    duplicate) CINNAMON_WALLPAPER_ASPECT_DUPLICATE="$WALLPAPER_ASPECT" ;;
    extend) CINNAMON_WALLPAPER_ASPECT_EXTEND="$WALLPAPER_ASPECT" ;;
    secondary) CINNAMON_WALLPAPER_ASPECT_SECONDARY="$WALLPAPER_ASPECT" ;;
  esac
}

get_cinnamon_wallpaper_aspect_for_mode() {
  case "$1" in
    primary) echo "$CINNAMON_WALLPAPER_ASPECT_PRIMARY" ;;
    duplicate) echo "$CINNAMON_WALLPAPER_ASPECT_DUPLICATE" ;;
    extend) echo "$CINNAMON_WALLPAPER_ASPECT_EXTEND" ;;
    secondary) echo "$CINNAMON_WALLPAPER_ASPECT_SECONDARY" ;;
  esac
}

apply_cinnamon_wallpaper_aspect_for_mode() {
  MODE_NAME="$1"
  WALLPAPER_ASPECT="$(get_cinnamon_wallpaper_aspect_for_mode "$MODE_NAME")"

  if [ -z "$WALLPAPER_ASPECT" ]; then
    return 0
  fi

  if ! command -v gsettings >/dev/null 2>&1; then
    return 0
  fi

  if ! gsettings writable org.cinnamon.desktop.background picture-options >/dev/null 2>&1; then
    return 0
  fi

  gsettings set org.cinnamon.desktop.background picture-options "$WALLPAPER_ASPECT"
}

if [ "$1" = "--config" ]; then
  if [ -z "$2" ]; then
    echo "Missing configuration value."
    echo "Use: --config extend-direction=left|right"
    echo "Or:  --config cinnamon-wallpaper-aspect-primary|duplicate|extend|secondary=<value>"
    exit 1
  fi

  case "$2" in
    extend-direction=*)
      RAW_VALUE="${2#extend-direction=}"
      if ! EXTEND_DIRECTION="$(normalize_extend_direction "$RAW_VALUE")"; then
        echo "Invalid value for extend-direction: $RAW_VALUE (use left or right)"
        exit 1
      fi

      save_config

      echo "Configuration saved: extend-direction=$EXTEND_DIRECTION"
      exit 0
      ;;
    cinnamon-wallpaper-aspect-*=*)
      RAW_KEY="${2%%=*}"
      RAW_MODE="${RAW_KEY#cinnamon-wallpaper-aspect-}"
      RAW_VALUE="${2#*=}"

      if ! MODE_NAME="$(normalize_mode_name "$RAW_MODE")"; then
        echo "Invalid mode for wallpaper config: $RAW_MODE (use primary, duplicate, extend or secondary)"
        exit 1
      fi

      if ! WALLPAPER_ASPECT="$(normalize_cinnamon_wallpaper_aspect "$RAW_VALUE")"; then
        echo "Invalid value for cinnamon wallpaper aspect: $RAW_VALUE"
        echo "Supported values: none, wallpaper, centered, scaled, stretched, zoom, spanned"
        exit 1
      fi

      set_cinnamon_wallpaper_aspect_for_mode "$MODE_NAME" "$WALLPAPER_ASPECT"
      save_config

      echo "Configuration saved: cinnamon-wallpaper-aspect-$MODE_NAME=$WALLPAPER_ASPECT"
      exit 0
      ;;
    *)
      echo "Invalid configuration key."
      echo "Supported keys:"
      echo "  - extend-direction=left|right"
      echo "  - cinnamon-wallpaper-aspect-primary|duplicate|extend|secondary=<value>"
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
  apply_cinnamon_wallpaper_aspect_for_mode "primary"
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
    apply_cinnamon_wallpaper_aspect_for_mode "primary"
    ;;
  duplicate)
    xrandr --output "$PRIMARY" --auto --output "$SECONDARY" --auto --same-as "$PRIMARY"
    apply_cinnamon_wallpaper_aspect_for_mode "duplicate"
    ;;
  extend)
    xrandr --output "$PRIMARY" --auto --output "$SECONDARY" --auto "$XRANDR_POSITION_FLAG" "$PRIMARY"
    apply_cinnamon_wallpaper_aspect_for_mode "extend"
    ;;
  secondary)
    xrandr --output "$SECONDARY" --auto --output "$PRIMARY" --off
    apply_cinnamon_wallpaper_aspect_for_mode "secondary"
    ;;
esac
