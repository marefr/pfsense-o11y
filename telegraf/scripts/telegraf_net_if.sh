#!/bin/sh

# Run ifconfig and pipe it into awk for parsing
ifconfig | awk '
# Match lines starting with an interface name
/^[a-zA-Z0-9_.-]+:/ {
    if (iface != "") {
        # Sanitize description (no spaces or commas for Influx format)
        gsub(/[ ,=]/, "_", desc)

        # 1. Metadata Info Metric (becomes net_if_info in Prometheus)
        printf "net_if,interface=%s,mac=%s,ip=%s,vlan=%s,description=%s info=1\n", iface, mac, ip, vlan, desc

        # 2. Administrative State (becomes net_if_admin_state)
        printf "net_if_admin,interface=%s state=%d\n", iface, admin

        # 3. Physical Link State (becomes net_if_link_state)
        printf "net_if_link,interface=%s state=%d\n", iface, link
    }

    # Reset for new interface
    iface = $1
    sub(":$", "", iface)
    admin = match($2, "UP") ? 1 : 0

    # Defaults
    mac = "none"; ip = "none"; vlan = "none"; desc = "none"
    link = admin
}

$1 == "ether" || $1 == "lladdr" { mac = $2 }
$1 == "status:" { link = ($2 == "active") ? 1 : 0 }
$1 == "inet" { ip = $2 }
$1 == "vlan:" { vlan = $2 }
$1 == "description:" { desc = substr($0, index($0, $2)) }

# Print the last interface
END {
    if (iface != "") {
        gsub(/[ ,=]/, "_", desc)
        printf "net_if,interface=%s,mac=%s,ip=%s,vlan=%s,description=%s info=1\n", iface, mac, ip, vlan, desc
        printf "net_if_admin,interface=%s state=%d\n", iface, admin
        printf "net_if_link,interface=%s state=%d\n", iface, link
    }
}'
