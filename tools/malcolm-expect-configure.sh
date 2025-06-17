#!/usr/bin/expect -f
# auto-configure.exp
# This script automatically feeds predefined answers into the Malcolm configure script.
#
# Usage: auto-configure.exp /full/path/to/configure

# Check for a command-line argument
if { $argc < 1 } {
    puts "Usage: $argv0 /path/to/configure_script"
    exit 1
}

# Get the path to the configure script from the first argument
set configure_script [lindex $argv 0]

# Disable timeout (wait indefinitely for prompts)
set timeout -1

# Spawn the configure script using the provided path
spawn $configure_script

# 1: docker vs podman prompt
expect {
    -re {Select container runtime engine \(docker\):} { send "1\r" }
}

# Malcolm processes will run as UID/GID prompt
expect {
    -re {Is this OK\? \(Y / n\):} { send "y\r" }
}

# Node name prompt – press Enter to use default
expect {
    -re {Enter the node name to associate with network traffic metadata.*:} { send "\r" }
}

# Profile prompt: Malcolm (all containers) vs Hedgehog (capture only)
expect {
    -re {Run with Malcolm.*profile\? \(Y \(Malcolm\) / n \(Hedgehog\)\):} { send "y\r" }
}

# OpenSearch instance prompt
expect {
    -re {Should Malcolm use and maintain its own OpenSearch instance\? \(Y / n\):} { send "y\r" }
}

# OpenSearch snapshot compression prompt
expect {
    -re {Compress local OpenSearch index snapshots\? \(y / N\):} { send "n\r" }
}

# Forward Logstash logs prompt
expect {
    -re {Forward Logstash logs to a secondary remote document store\? \(y / N\):} { send "n\r" }
}

# OpenSearch/Logstash resource settings confirmation
expect {
    -re {Setting 24g for OpenSearch and 3g for Logstash. Is this OK\? \(Y / n\):} { send "y\r" }
}

# Logstash workers confirmation
expect {
    -re {Setting 6 workers for Logstash pipelines. Is this OK\? \(Y / n\):} { send "y\r" }
}

# Restart on system/container daemon restart prompt
expect {
    -re {Restart Malcolm upon system or container daemon restart\? \(y / N\):} { send "n\r" }
}

# Require encrypted HTTPS connections
expect {
    -re {Require encrypted HTTPS connections\? \(Y / n\):} { send "y\r" }
}

# Reverse proxy prompt
expect {
    -re {Will Malcolm be running behind another reverse proxy.*\(y / N\):} { send "n\r" }
}

# External container network name prompt – press Enter for default
expect {
    -re {Specify external container network name.*\(\):} { send "\r" }
}

# Authentication method prompt
expect {
    -re {Select authentication method \(Basic\):} { send "1\r" }
}

# Storage location prompt for PCAP, log, and index files
expect {
    -re {Store PCAP, log and index files in .* \(Y / n\):} { send "y\r" }
}

# Index management policies prompt in Arkime
expect {
    -re {Enable index management policies .* in Arkime\? \(y / N\):} { send "n\r" }
}

# Delete oldest indices/artifacts prompt
expect {
    -re {Should Malcolm delete the oldest database indices and capture artifacts based on available storage\? \(y / N\):} { send "n\r" }
}

# Automatically analyze PCAP files with Arkime
expect {
    -re {Automatically analyze all PCAP files with Arkime\? \(Y / n\):} { send "y\r" }
}

# Automatically analyze PCAP files with Suricata
expect {
    -re {Automatically analyze all PCAP files with Suricata\? \(Y / n\):} { send "y\r" }
}

# Download updated Suricata signatures
expect {
    -re {Download updated Suricata signatures periodically\? \(y / N\):} { send "n\r" }
}

# Automatically analyze PCAP files with Zeek
expect {
    -re {Automatically analyze all PCAP files with Zeek\? \(Y / n\):} { send "y\r" }
}

# OT/ICS monitoring prompt
expect {
    -re {Is Malcolm being used to monitor an Operational Technology/Industrial Control Systems.*\(y / N\):} { send "n\r" }
}

# Reverse DNS lookup prompt
expect {
    -re {Perform reverse DNS lookup locally for source and destination IP addresses in logs\? \(y / N\):} { send "n\r" }
}

# OUI lookup prompt for MAC addresses
expect {
    -re {Perform hardware vendor OUI lookups for MAC addresses\? \(Y / n\):} { send "y\r" }
}

# String randomness scoring prompt
expect {
    -re {Perform string randomness scoring on some fields\? \(Y / n\):} { send "y\r" }
}

# Logs/metrics from Hedgehog sensor prompt – send empty (default "no")
expect {
    -re {Should Malcolm accept logs and metrics from a Hedgehog Linux sensor or other forwarder\?} { send "\r" }
}

# Enable file extraction with Zeek
expect {
    -re {Enable file extraction with Zeek\? \(Y / n\):} { send "y\r" }
}

# File extraction behavior selection
expect {
    -re {Select file extraction behavior.*} { send "2\r" }
}

# File preservation behavior selection
expect {
    -re {Select file preservation behavior.*} { send "1\r" }
}

# Expose web interface for downloading preserved files
expect {
    -re {Expose web interface for downloading preserved files\? \(y / N\):} { send "n\r" }
}

# Scan extracted files with ClamAV
expect {
    -re {Scan extracted files with ClamAV\? \(Y / n\):} { send "y\r" }
}

# Scan extracted files with Yara
expect {
    -re {Scan extracted files with Yara\? \(Y / n\):} { send "y\r" }
}

# Scan extracted PE files with Capa
expect {
    -re {Scan extracted PE files with Capa\? \(Y / n\):} { send "y\r" }
}

# Lookup file hashes with VirusTotal
expect {
    -re {Lookup extracted file hashes with VirusTotal\? \(y / N\):} { send "n\r" }
}

# Download file scanner signature updates
expect {
    -re {Download updated file scanner signatures periodically\? \(y / N\):} { send "n\r" }
}

# Threat intelligence feeds for Zeek intelligence framework
expect {
    -re {Configure pulling from threat intelligence feeds for Zeek intelligence framework\? \(y / N\):} { send "n\r" }
}

# Run and maintain NetBox instance prompt
expect {
    -re {Should Malcolm run and maintain an instance of NetBox,.*\(y / N\):} { send "y\r" }
}

# Enrich network traffic using NetBox prompt
expect {
    -re {Should Malcolm enrich network traffic using NetBox\? \(Y / n\):} { send "y\r" }
}

# Automatically populate NetBox inventory prompt
expect {
    -re {Should Malcolm automatically populate NetBox inventory based on observed network traffic\? \(y / N\):} { send "y\r" }
}

# Automatically create missing NetBox subnet prefixes prompt
expect {
    -re {Should Malcolm automatically create missing NetBox subnet prefixes based on observed network traffic\? \(y / N\):} { send "y\r" }
}

# Default NetBox site name prompt
expect {
    -re {Specify default NetBox site name.*\(\):} { send "test\r" }
}

# Capture live network traffic prompt – default "no"
expect {
    -re {Should Malcolm capture live network traffic\? \(no\):} { send "\r" }
}

# Enable dark mode for OpenSearch Dashboards prompt
expect {
    -re {Enable dark mode for OpenSearch Dashboards\? \(Y / n\):} { send "y\r" }
}

# Wait for end-of-file indicating configuration is complete
expect eof
