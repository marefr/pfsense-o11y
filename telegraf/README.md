# Telegraf

See [config_example.toml](./config/config_example.toml) for an example of a full configuration.

- [Custom Input Plugins](#custom-input-plugins)
- [Other Input Plugin Configurations](#other-input-plugin-configurations)

## Custom Input Plugins

- [Gateway Status](#gateway-status)
- [Network Interface Details & Status](#network-interface-details--status)
- [System Info & Metadata](#system-info--metadata)
- [CPU Temperature](#cpu-temperature)
- [Service Status](#service-status)
- [MBUF Usage](#mbuf-usage)
- [Wireguard Peer Latest Handshake](#wireguard-peer-latest-handshake)
- [Tailscale Backend State](#tailscale-backend-state)

### Gateway status

This plugin reads the pfSense Gateway Status and output metrics in Influx format. It works by looping through all active dpinger sockets, read the data from the socket using netcat, and output formatted result.

Example output:
```shell
> /usr/local/bin/telegraf_gateway_status.sh
gateway,name=<name>,monitor_ip=<ip> rtt_milliseconds=3.975,rttsd_milliseconds=9.297,loss_ratio=0
gateway,name=<name>,monitor_ip=<ip> rtt_milliseconds=0.042,rttsd_milliseconds=0.025,loss_ratio=0
```

#### Installation & Setup

1. Put `scripts/telegraf_gateway_status.sh` in /usr/local/bin/
2. Make it executable
```shell
chmod 755 /usr/local/bin/telegraf_gateway_status.sh
```
3. Configure telegraf config and add
```toml
[[inputs.exec]]
  commands = [
    "/usr/local/bin/telegraf_gateway_status.sh"
  ]
  timeout = "5s"
  data_format = "influx"
```

#### Prometheus metrics output example
See [example_output](./../example_output/gateway_status.txt).

### Network Interface Details & Status

This plugin extracts physical and logical interface metadata and operational states using the ifconfig command. It parses the raw output to separate static inventory data (IP, MAC, VLAN) from dynamic operational states (Admin/Link status).

Example output:
```shell
> /usr/local/bin/telegraf_net_if.sh
net_if,interface=igc0,mac=<mac>,ip=<ip>,vlan=<vlan nr or none>,description=<desc> info=1
net_if_admin,interface=igc0 state=1
net_if_link,interface=igc0 state=1
...
```

### Installation & Setup

1. Put `scripts/telegraf_net_if.sh` in /usr/local/bin/
2. Make it executable
```shell
chmod 755 /usr/local/bin/telegraf_net_if.sh
```
3. Configure telegraf config and add
```toml
[[inputs.exec]]
  commands = [
    "/usr/local/bin/telegraf_net_if.sh"
  ]
  timeout = "5s"
  data_format = "influx"

  ## If the "interface" tag matches any of these strings, optionally drop the metric entirely.
  [inputs.exec.tagdrop]
    interface = [ "<interface name>" ]
```

#### Prometheus metrics output example
See [example_output](./../example_output/net_if.txt).

### System Info & Metadata

This plugin extracts additional system infomration and metadata, trying to mimic the Prometheus Node Exporter metric `node_uname_info`.

Example output:
```shell
> /usr/local/bin/telegraf_node_uname.sh
node_uname,nodename=<nodename>,sysname=FreeBSD,release=15.0-CURRENT,version=FreeBSD\ 15.0-CURRENT\ #21\ RELENG_2_8_1-n256095-47c932dcc0e9:\ Thu\ Aug\ 28\ 16:27:48\ UTC\ 2025\ \ \ \ \ root@pfsense-build-release-amd64-1.eng.atx.netgate.com:/var/jenkins/workspace/pfSense-CE-snapshots-2_8_1-main/obj/amd64/AupY3aTL/var/jenkins/workspace/pfSense-CE-snapshots-2_8_1-main/sources/FreeBSD-src-RELENG_2_8_1/amd64.amd64/sys/pfSense,machine=amd64 info=1
```

### Installation & Setup

1. Put `scripts/telegraf_node_uname.sh` in /usr/local/bin/
2. Make it executable
```shell
chmod 755 /usr/local/bin/telegraf_node_uname.sh
```
3. Configure telegraf config and add
```toml
[[inputs.exec]]
  commands = [
    "/usr/local/bin/telegraf_node_uname.sh"
  ]
  timeout = "5s"
  data_format = "influx"
```

#### Prometheus metrics output example
See [example_output](./../example_output/node_uname.txt).

### CPU Temperature

This plugin extracts CPU temperature per core.

Example output:
```shell
> /usr/local/bin/telegraf_node_temp.sh
node_temp,core=3 celsius=70.0
node_temp,core=2 celsius=70.0
node_temp,core=1 celsius=69.0
node_temp,core=0 celsius=68.0
```

### Installation & Setup

1. Put `scripts/telegraf_node_temp.sh` in /usr/local/bin/
2. Make it executable
```shell
chmod 755 /usr/local/bin/telegraf_node_temp.sh
```
3. Configure telegraf config and add
```toml
[[inputs.exec]]
  commands = [
    "/usr/local/bin/telegraf_node_temp.sh"
  ]
  timeout = "5s"
  data_format = "influx"
```

#### Prometheus metrics output example
See [example_output](./../example_output/node_temp.txt).

### Service Status

This plugin extracts status of pfSense services.

Example output:
```shell
> /usr/local/bin/telegraf_pfsense_services.sh
pfsense_service,name=wireguard status=1i
pfsense_service,name=avahi status=1i
pfsense_service,name=haproxy status=1i
pfsense_service,name=tailscale status=1i
pfsense_service,name=telegraf status=1i
pfsense_service,name=unbound status=1i
pfsense_service,name=ntpd status=1i
pfsense_service,name=syslogd status=1i
pfsense_service,name=dhcpd status=1i
pfsense_service,name=dpinger status=1i
pfsense_service,name=bsnmpd status=1i
pfsense_service,name=miniupnpd status=1i
pfsense_service,name=sshd status=1i
```

### Installation & Setup

1. Put `scripts/telegraf_pfsense_services.sh` in /usr/local/bin/
2. Make it executable
```shell
chmod 755 /usr/local/bin/telegraf_pfsense_services.sh
```
3. Configure telegraf config and add
```toml
[[inputs.exec]]
  commands = [
    "/usr/local/bin/telegraf_pfsense_services.sh"
  ]
  timeout = "5s"
  data_format = "influx"
```

#### Prometheus metrics output example
See [example_output](./../example_output/pfsense_services.txt).

### MBUF Usage

This plugin extracts `MBUF Usage` as can be seen on the system information widget in the pfSense dashboard.

Example output:
```shell
> /usr/local/bin/telegraf_node_netstat_mbuf.sh
node_netstat_mbuf current=12860i,free=5910i,total=18770i,limit=1000000i
```

### Installation & Setup

1. Put `scripts/telegraf_node_netstat_mbuf.sh` in /usr/local/bin/
2. Make it executable
```shell
chmod 755 /usr/local/bin/telegraf_node_netstat_mbuf.sh
```
3. Configure telegraf config and add
```toml
[[inputs.exec]]
  commands = [
    "/usr/local/bin/telegraf_node_netstat_mbuf.sh"
  ]
  timeout = "5s"
  data_format = "influx"
```

#### Prometheus metrics output example
See [example_output](./../example_output/node_netstat_mbuf.txt).

### Wireguard Peer Latest Handshake

This plugin extracts latest handshake (timestamp in seconds) of Wireguard peers.

Example output:
```shell
> /usr/local/bin/telegraf_wireguard.sh
wireguard_peer,interface=<interface>,peer=<public key>,endpoint=<ip;port> latest_handshake_seconds=1774600244i
```

### Installation & Setup

1. Put `scripts/telegraf_wireguard.sh` in /usr/local/bin/
2. Make it executable
```shell
chmod 755 /usr/local/bin/telegraf_wireguard.sh
```
3. Configure telegraf config and add
```toml
[[inputs.exec]]
  commands = [
    "/usr/local/bin/telegraf_wireguard.sh"
  ]
  timeout = "5s"
  data_format = "influx"
```

#### Prometheus metrics output example
See [example_output](./../example_output/wireguard.txt).

### Tailscale Backend State

This plugin extracts backend state of Tailscale.

Example output:
```shell
>  /usr/local/bin/telegraf_tailscale.sh
tailscale_backend,state_desc=Running state=1i
tailscale_backend,state_desc=NeedsLogin state=0i
tailscale_backend,state_desc=Stopped state=0i
tailscale_backend,state_desc=NoState state=0i
tailscale_backend,state_desc=LoadingConfig state=0i
tailscale_backend,state_desc=Unknown state=0i
```

### Installation & Setup

1. Put `scripts/telegraf_tailscale.sh` in /usr/local/bin/
2. Make it executable
```shell
chmod 755 /usr/local/bin/telegraf_tailscale.sh
```
3. Configure telegraf config and add
```toml
[[inputs.exec]]
  commands = [
    "/usr/local/bin/telegraf_tailscale.sh"
  ]
  timeout = "5s"
  data_format = "influx"
```

#### Prometheus metrics output example
See [example_output](./../example_output/tailscale.txt).

## Other Input Plugin Configurations

Rather than using the builtin configurations of pfSense Telegraf package, we use custom ones that allows greater flexibility, together with some additional ones not provided out of the box by the pfSense Telegraf package.

- [Ping Configuration](#ping-configuration)
- [S.M.A.R.T. Hard Disk Status Configuration](#smart-hard-disk-status-configuration)
- [HAProxy Configuration](#haproxy-configuration)
- [Network Time Protocol Query Configuration](#network-time-protocol-query-configuration)
- [x509 Certificate Configuration](#x509-certificate-configuration)

### Ping Configuration

To allow for additional configuration options you can use a the [Ping Input Plugin](https://docs.influxdata.com/telegraf/v1/input-plugins/ping/) with a custom configuration. When using below configuration, make sure to not check `Enable Ping Monitor` when configuring Telegraf in the GUI.

```toml
[[inputs.ping]]
  urls = ["46.227.67.134", "192.165.9.158"]
  count = 5            # Send 5 pings per interval
  ping_interval = 0.2  # Wait 200ms between those 5 pings
  timeout = 1.0        # How long to wait for each individual response
  method = "native"

# Add alias tag for each configured ping URL
[[processors.enum]]
  namepass = ["ping"]
  [[processors.enum.mapping]]
    tag = "url"
    dest = "alias"
    [processors.enum.mapping.value_mappings]
      "46.227.67.134" = "OVPN DNS 1"
      "192.165.9.158" = "OVPN DNS 2"
```

### S.M.A.R.T. Hard Disk Status Configuration

The [smartctl JSON Input Plugin](https://docs.influxdata.com/telegraf/v1/input-plugins/smartctl/) collects S.M.A.R.T. information of storage devices using the `smartmontools` package / `smartctl` tool, which should be installed by default. See [pfSense S.M.A.R.T. Hard Disk Status](https://docs.netgate.com/pfsense/en/latest/monitoring/status/smart.html) for more information.

```toml
[[inputs.smartctl]]
  path = "/usr/local/sbin/smartctl"
  devices_include = [ "<storage device, e.g. /dev/nvme0>" ]
```

### HAProxy Configuration

If you have the HAProxy package/service installed on your pfSense this [HAProxy Input Plugin](https://docs.influxdata.com/telegraf/v1/input-plugins/haproxy/) collects the metrics that matters the most. When using below configuration, make sure to not check `Enable HAProxy Status Reporting` when configuring Telegraf in the GUI.

```toml
[[inputs.haproxy]]
  servers = ["http://127.0.0.1:2200/haproxy/haproxy_stats.php?haproxystats=1"]

  ## The fieldpass array tells Telegraf to drop ALL HAProxy metrics
  ## EXCEPT for the exact ones listed here.
  fieldpass = [
    "bin",
    "bout",
    "scur",
    "ereq",
    "eresp",
    "http_response.2xx",
    "http_response.4xx",
    "http_response.5xx",
    "check_duration"
  ]
```

### Network Time Protocol Query Configuration

The [Network Time Protocol Query Input Plugin](https://docs.influxdata.com/telegraf/v1/input-plugins/ntpq/) collects metrics about Network Time Protocol queries.

```toml
[[inputs.ntpq]]
  ## Use -p to list peers and -n to keep it numeric (no DNS)
  options = "-p -n"
```

### x509 Certificate Configuration

The [x509 Certificate Input Plugin](https://docs.influxdata.com/telegraf/v1/input-plugins/x509_cert/) collects information about X.509 certificates, e.g. certificates generated by the [ACME package](https://docs.netgate.com/pfsense/en/latest/packages/acme/index.html).

```toml
[[inputs.x509_cert]]
  sources = ["/conf/acme/<cert>.crt"]
  tls_ca = "/conf/acme/<ca>.ca"
```
