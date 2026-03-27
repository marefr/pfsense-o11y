#!/bin/sh

# Get temperature for each core
# dev.cpu.X.temperature outputs "XX.XC"
sysctl -a | grep "dev.cpu.*.temperature" | while read -r line; do
    # Extract core number (e.g., 0 from dev.cpu.0.temperature)
    CORE=$(echo "$line" | cut -d. -f3)
    # Extract temperature and remove the 'C' suffix
    TEMP=$(echo "$line" | awk '{print $2}' | sed 's/C//')

    # Output in Influx format
    printf "node_temp,core=%s celsius=%s\n" "$CORE" "$TEMP"
done
