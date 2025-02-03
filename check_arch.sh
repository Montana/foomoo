#!/bin/bash

print_header() {
    echo
    echo "--------------------------------"
    echo "$1"
    echo "--------------------------------"
}

cpu_load_test() {
    duration=$1
    cores=$(nproc)
    print_header "Running CPU Load Test"
    echo "Duration: $duration seconds"
    echo "Number of cores: $cores"
    echo "Starting test..."
    
    for ((i=1; i<=cores; i++)); do
        (
            for ((j=1; j<=duration; j++)); do
                echo "scale=10; sqrt($j*$j*$j*$j)" | bc >/dev/null
            done
        ) &
    done
    
    wait
    echo "CPU load test completed"
}

check_service_status() {
    local service=$1
    if systemctl is-active --quiet $service; then
        echo "$service: Active"
    else
        echo "$service: Inactive"
    fi
}

network_test() {
    print_header "Network Information"
    echo "IP Configuration:"
    ip addr show 2>/dev/null || ifconfig 2>/dev/null || echo "No IP tools found"
    
    echo -e "\nNetwork Connectivity Test:"
    ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo "Internet: Connected" || echo "Internet: Disconnected"
    
    echo -e "\nOpen Ports:"
    netstat -tuln 2>/dev/null || ss -tuln 2>/dev/null || echo "No port tools found"
}

check_security() {
    print_header "Security Check"
    echo "Firewall Status:"
    if command -v ufw >/dev/null; then
        ufw status
    elif command -v firewall-cmd >/dev/null; then
        firewall-cmd --state
    else
        echo "No firewall detected"
    fi
    
    echo -e "\nSELinux Status:"
    getenforce 2>/dev/null || echo "SELinux not detected"
    
    echo -e "\nLast 5 Failed Login Attempts:"
    lastb | head -n 5 2>/dev/null || echo "No login history available"
}

monitor_system() {
    print_header "Live System Monitor (10 seconds)"
    echo "Top CPU Processes:"
    ps aux --sort=-%cpu | head -n 6
    
    echo -e "\nTop Memory Processes:"
    ps aux --sort=-%mem | head -n 6
    
    echo -e "\nCurrent Load Average:"
    uptime
    
    echo -e "\nIOwait Status:"
    iostat 1 2 2>/dev/null || echo "iostat not available"
}

print_header "System Architecture Information"
echo "OS Type           : $(uname -s)"
echo "Kernel Version    : $(uname -r)"
echo "Architecture      : $(uname -m)"
echo "Processor         : $(uname -p 2>/dev/null || echo 'N/A')"
echo "Hardware Platform : $(uname -i 2>/dev/null || echo 'N/A')"
echo "OS Distribution   : $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)"
echo "System Uptime     : $(uptime -p 2>/dev/null || echo 'N/A')"

print_header "Detailed Architecture Information"
dpkg --print-architecture 2>/dev/null || echo "Primary architecture not found"
dpkg --print-foreign-architectures 2>/dev/null || echo "Foreign architectures not found"
file /bin/bash | awk -F',' '{print $2}' 2>/dev/null || echo "Binary architecture not found"
getconf LONG_BIT 2>/dev/null || echo "Bit width not found"

print_header "Using 'arch' Command"
arch

print_header "CPU Information"
lscpu | grep -E 'Architecture|Model name|CPU\(s\):|Byte Order|CPU op-mode|Cache|Thread|Core|Socket|NUMA|Virtualization'

print_header "Memory Information"
free -h
echo -e "\nSwap Usage:"
swapon --show 2>/dev/null || echo "No swap information available"
echo -e "\nMemory Limits:"
ulimit -a 2>/dev/null || echo "No ulimit information available"

print_header "Disk Usage Information"
df -h --total | grep -E 'Filesystem|total'
echo -e "\nDisk I/O Statistics:"
iostat -d 2>/dev/null || echo "iostat not available"
echo -e "\nFile System Type:"
mount | grep -E "^/dev"

print_header "Critical Services Status"
for service in sshd nginx apache2 docker mysqld postgresql; do
    check_service_status $service
done

network_test

check_security

monitor_system

print_header "Available Updates (Linux-based Systems)"
if command -v apt &> /dev/null; then
    apt list --upgradable 2>/dev/null | tail -n +2
elif command -v yum &> /dev/null; then
    yum check-update
elif command -v dnf &> /dev/null; then
    dnf check-update
else
    echo "Package manager not detected or unsupported."
fi

print_header "GPU Information"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi
elif command -v lshw &> /dev/null; then
    lshw -C display
else
    echo "No GPU information available"
fi

cpu_load_test 30

print_header "System Health Check"
echo "Temperature Info (if available):"
sensors 2>/dev/null || echo "No temperature sensors found"

echo -e "\nRAID Status (if available):"
cat /proc/mdstat 2>/dev/null || echo "No RAID information available"

echo -e "\nSystem Errors:"
dmesg | grep -i error | tail -n 5 || echo "No error logs found"

print_header "Completed System Check"
