#!/bin/sh
printf "$2\r" | hydroxide auth "$1" | awk '{ print $4 }'
