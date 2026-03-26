# pfSense Observability (o11y) Setup

[![pfSense](https://img.shields.io/badge/pfSense-2.8.1-white?logo=pfsense)](https://www.pfsense.org/)
[![Telegraf](https://img.shields.io/badge/Telegraf-1.33-blue?logo=influxdb)](https://www.influxdata.com/time-series-platform/telegraf/)
[![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-red?logo=prometheus)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-Dashboards-F46800?logo=grafana)](https://grafana.com)

Observability setup for [pfSense](https://www.pfsense.org/), using [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/), [Prometheus](https://prometheus.io/) and [Grafana](https://grafana.com).

> [!WARNING]
> This has been tested and verified by the author on **pfSense Community Edition 2.8.1-RELEASE (amd64)** with **Telegraf package v0.9_8**. No guarantees this will work on your hardware/setup.

See [Telegraf](./telegraf/README.md) for details about custom input plugins and configurations used in this setup. See [config_example.toml](./telegraf/config/config_example.toml), for an example of a full configuration.

**Table of contents:**
- [Key Observability Metrics](#key-observability-metrics)
- [Collected Metrics](#collected-metrics)
- Grafana Dashboards TBD
- [Prometheus metrics output examples](#prometheus-metrics-output-examples)
- [Use of AI](#use-of-ai)

## Key Observability Metrics

The following metrics are the primary indicators for monitoring pfSense health and performance.

### System Telemetry (Hardware & OS)
* **`cpu_usage_idle`**: Primary indicator of processing headroom. Values consistently below 20% suggest the CPU is bottlenecked.
* **`mem_used_percent`**: Vital for preventing stability issues. High usage often precedes system hangs or OOM events.
* **`system_load1`**: Reflects the OS task queue. A load significantly higher than your CPU core count indicates congestion.
* **`disk_used_percent`**: Critical to monitor on `/` and `/var`. If storage hits 100%, pfSense may fail to log or boot.

### Network Connectivity
* **`gateway_loss_ratio`**: **The single most important metric.** Even 1-2% packet loss significantly degrades real-time services like VoIP and gaming.
* **`gateway_rtt_milliseconds`**: Tracks path latency to your ISP. Helps distinguish between local network issues and ISP-side slowness.
* **`net_if_link_state`**: Hardware-level monitoring. Returns `0` if a cable is unplugged or a physical port fails.
* **`ping_result_code`**: Confirms reachability of external dependencies (e.g., DNS). `0` is success; any other value indicates a service outage.

### Connection & State Tracking
* **`netstat_tcp_established`**: Monitors the volume of active sessions. Sudden spikes can indicate a misbehaving device or a security event.
* **`pf_states`**: Tracks the firewall state table. If this hits your configured `state_limit`, new connections will be dropped.

### Application Delivery (HAProxy)
* **`haproxy_status`**: Real-time status of backend services (Home Assistant, etc.).
* **`haproxy_http_response_5xx`**: Directly tracks server-side errors. A spike here means your users are seeing error pages.
* **`haproxy_scur`**: Tracks current active users/connections per hosted service.

## Collected Metrics

A breakdown of the collected metrics and what specific ones are important to monitor.

- [System Metrics](#system-metrics)
- [Gateway Status Metrics](#gateway-status-metrics)
- [Packet Filter Metrics](#packet-filter-metrics-pf_)
- [Network Interface Details & Status Metrics](#network-interface-details--status-metrics)
- [Ping Metrics](#ping-metrics)
- [Netstat Metrics](#netstat-metrics)
- [HAProxy Metrics](#haproxy-metrics)

### System Metrics

- [CPU Metrics](#cpu-metrics)
- [Memory & Swap Metrics](#memory--swap-metrics)
- [Disk & I/O Metrics](#disk--io-metrics)
- [Processes & System Metrics](#processes--system-metrics)
- [Uptime Metrics](#uptime-metric)

#### CPU Metrics
These metrics indicate how much processing power is being consumed and by what.
- `cpu_usage_idle`: The percentage of time the CPU is not doing any work.
- `cpu_usage_system`: Time spent by the CPU on kernel-level tasks (e.g., handling firewall rules or network traffic).
- `cpu_usage_user`: Time spent on user-level applications (e.g., HAProxy or the WebGUI).
- `cpu_usage_iowait`: Time the CPU spends waiting for disk I/O. If this is high, your disk may be a bottleneck.

⭐ Critical for Monitoring: `cpu_usage_idle` (to see overall headroom) and `cpu_usage_system` (to identify if heavy networking/firewalling is taxing the system).

#### Memory & Swap Metrics
These metrics track how your router's RAM is being utilized.
- `mem_used_percent`: The overall percentage of RAM in use.
- `mem_available`: The amount of RAM immediately available for new processes.
- `swap_used_percent`: The percentage of swap space (on-disk "emergency" memory) currently in use.

⭐ Critical for Monitoring: `mem_used_percent`. If this stays consistently high, you risk the system becoming unstable. Monitoring `swap_used_percent` is also vital; if swap is being used heavily, it often indicates you have run out of physical RAM.

#### Disk & I/O Metrics
These track storage space and the speed of reading/writing to your disk.
- `disk_used_percent`: Percentage of disk space consumed on your partitions (e.g., / or /var).
- `diskio_io_time`: The total time spent on I/O operations for a specific disk.
- `diskio_read_bytes` / `diskio_write_bytes`: The actual throughput of data being moved to/from storage.

⭐ Critical for Monitoring: `disk_used_percent` on the root (/) partition. If this hits 100%, pfSense can fail to boot or log data, leading to a crash.

#### Processes & System Metrics
These provide a high-level overview of system activity and resource queuing.
- `system_load1` / `load5` / `load15`: The system load average over 1, 5, and 15 minutes.
- `processes_running`: The number of processes currently active.
- `processes_total`: The total number of processes in the system.

⭐ Critical for Monitoring: `system_load1`. A load average significantly higher than your CPU core count (e.g., >4 on a 4-core system) suggests a backlog of work that can lead to network latency.

#### Uptime Metric

`system_uptime`: The total time in seconds the system has been running since the last reboot.

⭐ Critical for Monitoring: `system_uptime`. Sudden drops in uptime indicate an unexpected reboot or crash, which is a key trigger for troubleshooting.

### Gateway Status Metrics
> [!NOTE]
> To use/configure, see [Telegraf](./telegraf/README.md).

These metrics monitor the health of your WAN link and additional uplinks by measuring communication with a target monitor IP.
- `gateway_rtt_milliseconds`: The average Round Trip Time (RTT) to the monitor IP. High RTT indicates latency on the link.
- `gateway_loss_ratio`: The percentage of packet loss detected on the gateway. Any value above 0 is a sign of connection instability.
- `gateway_rttsd_milliseconds`: The standard deviation of the RTT, often used to measure "jitter". High jitter can degrade real-time services like VoIP or gaming.

⭐ Critical for Monitoring: `gateway_loss_ratio` and `gateway_rtt_milliseconds`. These are the most direct indicators of whether your internet connection is stable or struggling.

#### How does pfSense derive the gateway status?

In pfSense, a gateway isn't just a simple "on/off" switch. Because networks fluctuate, dpinger uses thresholds to determine the state of the connection.

It evaluates the **Packet Loss** and **Latency (RTT)** and assigns a status based on how high those numbers get.

Unless you manually changed them in the pfSense GUI (under System > Routing > Gateways > Edit (Advanced)), pfSense uses these default thresholds to determine the gateway's state:
- **Online (Green):** Everything is operating normally.
- **Warning (Yellow):** Latency exceeds **250ms** OR Packet Loss exceeds **10%**.
- **Offline / Down (Red):** Latency exceeds **500ms** OR Packet Loss exceeds **20%** (or hits 100% for a completely dead link).

### Packet Filter Metrics (`pf_`)
These metrics are the absolute holy grail of pfSense monitoring. These `pf_` metrics tell you exactly what the core firewall engine itself is doing.

The `pf` stands for Packet Filter, which is the kernel-level firewall engine built into FreeBSD that powers pfSense. When you look at these metrics, you are looking directly at the brain of your firewall.

- [Current State Metrics](#current-state-metrics)
- [Lifetime Traffic Metrics](#lifetime-traffic-metrics)
- [Validation & Errors Metrics](#lifetime-traffic-metrics)
- [Resource Exhaustion Metrics](#resource-exhaustion-metrics)

#### Current State Metrics

 - `pf_entries`: This is the current number of active connections (states) your firewall is tracking right now. Every time a device opens a website or starts a download, a "state" is created. If this number hits your firewall's maximum state limit, pfSense will completely stop routing new traffic.

⭐ Critical for Monitoring: `pf_entries` is the single most important metric to monitor.

#### Lifetime Traffic Metrics

- `pf_searches`: The number of times the firewall had to search the state table to see if an incoming packet belonged to an existing connection.
- `pf_inserts` / `pf_removals`: The total lifetime number of connections that have been created (inserted) and closed (removed) since the firewall last rebooted.
- `pf_match`: The total number of packets that successfully matched a firewall rule or an existing state.

#### Validation & Errors Metrics

- `pf_state_mismatch`: This happens when a packet arrives claiming to be part of an active connection, but its sequence numbers or TCP flags are completely wrong. A steadily climbing number here is normal (it's often just sloppy internet noise or out-of-order packets), but massive spikes can indicate asymmetric routing issues or someone trying to spoof connections.
- `pf_fragment`: Number of fragmented packets the firewall had to drop or reassemble.
- `pf_normalize`: pfSense automatically "scrubs" incoming traffic to fix basic IP formatting errors before it hits your network. This counts how many packets it had to clean up.
- `pf_bad_offset`, `pf_bad_timestamp`, `pf_short`, `pf_proto_cksum`, `pf_ip_option`: These are pure error drops. The firewall received a packet that was too short, had a corrupted checksum, or contained illegal TCP options, so it was instantly dropped.

#### Resource Exhaustion Metrics

- `pf_memory`: Packets dropped because the firewall literally ran out of RAM to allocate to the state table.
- `pf_state_limit`: Packets dropped because your pf_entries hit the maximum configured limit in pfSense (usually a few hundred thousand, depending on your RAM).
- `pf_src_limit`: Packets dropped because a single internal IP triggered a "Maximum connections per host" rule you set up.
- `pf_congestion`: Drops due to severe kernel queuing congestion.

### Network Interface Details & Status Metrics
> [!NOTE]
> To use/configure, see [Telegraf](./telegraf/README.md).

While the default net plugin provides traffic volume, these specific metrics track the physical and logical state of your interfaces.
- `net_if_link_state`: Indicates if a physical connection is detected (1 for active, 0 for no carrier).
- `net_if_admin_state`: Shows if the interface is logically enabled in the pfSense configuration (1 for up, 0 for down).
- `net_if_info`: A metadata metric that carries important tags like ip, mac, vlan, and the pfSense description.

⭐ Critical for Monitoring: `net_if_link_state`. Monitoring this allows you to immediately detect if a cable has been unplugged or a physical port has failed.

### Ping Metrics
These metrics allow to monitor specific external targets (like your DNS servers) independently of the gateway monitor.
- `ping_average_response_ms`: The average response time for your targeted pings.
- `ping_percent_packet_loss`: The percentage of pings that failed to return a response.
- `ping_result_code`: A binary indicator where 0 means success and any other number indicates a failure to reach the target.

⭐ Critical for Monitoring: `ping_result_code`. It is the simplest way to alert on the total unavailability of a critical external dependency like a DNS server.

To use/configure custom Ping metrics, see [Telegraf](./telegraf/README.md).

### Netstat Metrics
> [!NOTE]
> To use/configure, check the `Enable Netstat Monitor` in the Telegraf GUI settings.

These metrics provide visibility into the network stack's current workload and state.
- `netstat_tcp_established`: The number of currently active, established TCP connections.
- `netstat_tcp_listen`: The number of ports currently listening for incoming connections.
- `netstat_udp_socket`: The total count of active UDP sockets.

⭐ Critical for Monitoring: `netstat_tcp_established`. A sudden spike in established connections can indicate a surge in legitimate traffic, a misbehaving application, or a potential security event like a DDoS attack.

### HAProxy Metrics
> [!NOTE]
> To use/configure custom HAProxy metrics, see [Telegraf](./telegraf/README.md).

#### Traffic & Throughput Metrics
These metrics track the volume of data flowing through your frontends and backends.
- `haproxy_bin` / `haproxy_bout`: The total bytes received (bin) and sent (bout). This is essential for understanding your bandwidth consumption per proxy.
`haproxy_scur`: The number of current active sessions. This tells you how many users or devices are connected to a specific service at any given moment.

⭐ Critical for Monitoring: `haproxy_scur`. Monitoring active sessions helps you identify traffic spikes and ensure your services aren't hitting connection limits.

#### Health & Availability Metrics
These metrics tell you if HAProxy can actually talk to your backend servers.
- `haproxy_status`: This is a label-based indicator (e.g., UP, DOWN, OPEN, no check). It is the most direct way to see if a backend server is healthy or failing health checks.
- `haproxy_check_duration`: The time (in milliseconds) it took to perform the last health check. A sudden increase can indicate that a backend server is becoming slow or unresponsive.

⭐ Critical for Monitoring: `haproxy_status`. You should alert immediately if any production backend status moves to DOWN.

#### Error Tracking Metrics
These metrics identify failures in the communication between clients and your servers.
- `haproxy_ereq`: Total number of request errors from clients. High numbers often indicate bad client behavior or misconfigured frontends.
- `haproxy_eresp`: Total number of response errors from backend servers. This is a clear indicator of server-side instability.
- `haproxy_http_response_*`: Counts of specific HTTP status codes (2xx, 4xx, 5xx).

⭐ Critical for Monitoring: `haproxy_http_response_5xx`. A spike in 5xx errors means your users are seeing "Server Error" pages, indicating a critical failure in your backend services.

## Prometheus metrics output examples
See [example_output](./example_output/).

## Use of AI

The author uses AI for this project, but as the maintainer, he owns the outcome and consequences. However, the author can't guarantee this will work on other hardware/setup than his own.
