#!/bin/sh

# Extract the exact mbuf clusters line (e.g., 12862/5980/18842/1000000)
MBUF_DATA=$(netstat -m | awk '/mbuf clusters/ {print $1}')

CURRENT=$(echo "$MBUF_DATA" | cut -d'/' -f1)
FREE=$(echo "$MBUF_DATA" | cut -d'/' -f2)
TOTAL=$(echo "$MBUF_DATA" | cut -d'/' -f3)
LIMIT=$(echo "$MBUF_DATA" | cut -d'/' -f4)

# Output in Influx format. The Prometheus exporter will split these into:
# node_netstat_mbuf_current, node_netstat_mbuf_free, etc.
printf "node_netstat_mbuf current=%di,free=%di,total=%di,limit=%di\n" \
  "$CURRENT" "$FREE" "$TOTAL" "$LIMIT"
