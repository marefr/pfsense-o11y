#!/bin/sh

# Get system values
NODENAME=$(uname -n)
SYSNAME=$(uname -s)
RELEASE=$(uname -r)
VERSION=$(uname -v)
MACHINE=$(uname -m)

# InfluxDB Line Protocol requires commas, spaces, and equals signs in tags to be escaped
escape_tag() {
  echo "$1" | sed -e 's/,/\\,/g' -e 's/ /\\ /g' -e 's/=/\\=/g'
}

NODENAME_ESC=$(escape_tag "$NODENAME")
SYSNAME_ESC=$(escape_tag "$SYSNAME")
RELEASE_ESC=$(escape_tag "$RELEASE")
VERSION_ESC=$(escape_tag "$VERSION")
MACHINE_ESC=$(escape_tag "$MACHINE")

# Output format: node_uname,<tags> info=1
printf "node_uname,nodename=%s,sysname=%s,release=%s,version=%s,machine=%s info=1\n" \
  "$NODENAME_ESC" "$SYSNAME_ESC" "$RELEASE_ESC" "$VERSION_ESC" "$MACHINE_ESC"
