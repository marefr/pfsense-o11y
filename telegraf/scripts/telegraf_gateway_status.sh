#!/bin/sh

# Loop through all active dpinger sockets
for sock in /var/run/dpinger_*.sock; do
    # Check if the socket actually exists
    [ -e "$sock" ] || continue

    # Read the data from the socket using netcat
    data=$(nc -U "$sock" 2>/dev/null)

    # Skip if no data was returned
    [ -z "$data" ] && continue

    # Pass the socket filename and the payload to awk
    echo "$data" | awk -v sockpath="$sock" '{
        # Parse the filename to get the Monitor IP
        n = split(sockpath, parts, "~");

        if (n >= 3) {
            monitor_ip = parts[n];
            sub("\\.sock$", "", monitor_ip); # Strip the .sock extension
        } else {
            monitor_ip = "unknown";
        }

        # The payload is: GatewayName RTT RTTsd Loss
        # Example: WAN 2668 6863 0
        # $1 = Gateway, $2 = RTT (us), $3 = RTTsd (us), $4 = Loss (%)

        printf "gateway,name=%s,monitor_ip=%s rtt_milliseconds=%.3f,rttsd_milliseconds=%.3f,loss_ratio=%d\n", $1, monitor_ip, $2/1000, $3/1000, $4
    }'
done
