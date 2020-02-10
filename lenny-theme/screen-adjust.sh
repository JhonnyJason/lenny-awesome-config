#!/usr/bin/env bash

xrandr --output DVI-0 --left-of HDMI-0 --auto;
xrandr --output DisplayPort-0 --right-of HDMI-0 --auto;

# function run {
#     if ! pgrep $1 ; then
#         $@&
#     fi
# }

# if xrandr | grep -q 'VGA-1 connected' ; then
#     xrandr --output VGA1 --right-of LVDS1 --auto;
# fi