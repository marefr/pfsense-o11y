#!/bin/sh

/usr/bin/wg show all dump | /usr/bin/awk '
{
    # Peer lines have 8 or 9 columns
    if (NF >= 8) {
        interface = $1;
        public_key = $2;
        endpoint = $4;
        handshake = $6;  # Handshake is the 6th column in pfSense wg dump

        # Escape equal signs for Telegraf/Influx format
        gsub(/=/, "\\=", public_key);

        # Ensure handshake is treated as an integer (i suffix)
        printf "wireguard_peer,interface=%s,peer=%s,endpoint=%s latest_handshake_seconds=%si\n", interface, public_key, endpoint, handshake
    }
}'
