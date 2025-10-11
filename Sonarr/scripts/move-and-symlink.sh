#!/bin/sh

exec >> "/servarr/output-`hostname`.log" 2>&1

echo "Moving \"$1\" to \"$2\""
mv "$1" "$2"
echo "Linking new file to original file"
ln -s "$2" "$1"
echo "Verifying symlink..."
ls -lsa "$1"

exit 0