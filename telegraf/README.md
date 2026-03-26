# Telegraf

See [config_example.toml](./config/config_example.toml) for an example of a full configuration.

## Custom Input Plugins

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
chmod +x /usr/local/bin/telegraf_gateway_status.sh
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
> /usr/local/bin/telegraf_ifconfig.sh
net_if,interface=igc0,mac=<mac>,ip=<ip>,vlan=<vlan nr or none>,description=<desc> info=1
net_if_admin,interface=igc0 state=1
net_if_link,interface=igc0 state=1
...
```

### Installation & Setup

1. Put `scripts/telegraf_ifconfig.sh` in /usr/local/bin/
2. Make it executable
```shell
chmod +x /usr/local/bin/telegraf_ifconfig.sh
```
3. Configure telegraf config and add
```toml
[[inputs.exec]]
  commands = [
    "/usr/local/bin/telegraf_ifconfig.sh"
  ]
  timeout = "5s"
  data_format = "influx"

  ## If the "interface" tag matches any of these strings, optionally drop the metric entirely.
  [inputs.exec.tagdrop]
    interface = [ "<interface name>" ]
```

#### Prometheus metrics output example
See [example_output](./../example_output/net_if.txt).

## Custom Input Configurations

Rather than using the builtin configurations of pfSense Telegraf package, we use custom ones that allows greater flexibility.

### Custom Ping Configuration

To allow for additional configuration options you can use a custom ping configuration. When using below configuration, make sure to not check `Enable Ping Monitor` when configuring Telegraf in the GUI.

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

### Custom HAProxy Configuration

If you have the HAProxy package/service installed on your pfSense this custom configuration collects the metrics that matters the most. When using below configuration, make sure to not check `Enable HAProxy Status Reporting` when configuring Telegraf in the GUI.

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
