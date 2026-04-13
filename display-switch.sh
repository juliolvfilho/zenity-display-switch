#!/bin/bash

# Detecta os nomes dos monitores conectados
MONITORS=($(xrandr | grep " connected" | awk '{print $1}'))
INTERNO="${MONITORS[0]}"
EXTERNO="${MONITORS[1]}"

ESCOLHA=$(zenity --list \
  --title="Modo de exibição" \
  --text="Escolha como usar os monitores:" \
  --column="Modo" \
  --column="Descrição" \
  "notebook"  "Somente o notebook ($INTERNO)" \
  "externo"   "Somente o monitor externo ($EXTERNO)" \
  "duplicar"  "Duplicar telas" \
  "extender"  "Estender telas" \
  --width=380 --height=280)

case "$ESCOLHA" in
  notebook)
    xrandr --output "$INTERNO" --auto --output "$EXTERNO" --off
    ;;
  externo)
    xrandr --output "$EXTERNO" --auto --output "$INTERNO" --off
    ;;
  duplicar)
    xrandr --output "$INTERNO" --auto --output "$EXTERNO" --same-as "$INTERNO"
    ;;
  extender)
    xrandr --output "$INTERNO" --auto --output "$EXTERNO" --right-of "$INTERNO"
    ;;
esac
