#!/usr/local/bin/php -q
<?php
require_once("service-utils.inc");

$services = get_services();

foreach ($services as $service) {
    $name = $service['name'];
    $name_clean = str_replace(array(' ', ',', '='), array('\ ', '\,', '\='), $name);
    $pgid = trim(shell_exec("/bin/pgrep -ax " . escapeshellarg($name)));

    if (!empty($pgid)) {
        $status = 1;
    } else {
        // Fallback for services where the process name != service name
        $status = is_service_running($name) ? 1 : 0;
    }

    echo "pfsense_service,name={$name_clean} status={$status}i\n";
}
?>
