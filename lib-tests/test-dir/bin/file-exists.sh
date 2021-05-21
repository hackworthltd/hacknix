#!/bin/sh
if find "$1" -name "$2" -type f -exec false {} +
then
    echo "no"
    exit 1
else
    echo "yes"
    exit 0
fi
