#!/bin/bash

print_header() {
    echo
    echo "--------------------------------"
    echo "$1"
    echo "--------------------------------"
}

print_header "System Architecture Information"
echo "OS Type           : $(uname -s)"
echo "Kernel Version    : $(uname -r)"
echo "Architecture      : $(uname -m)"
echo "Processor         : $(uname -p 2>/dev/null || echo 'N/A')"
echo "Hardware Platform : $(uname -i 2>/dev/null || echo 'N/A')"

print_header "Using 'arch' Command"
arch

print_header "CPU Information"
lscpu | grep -E 'Architecture|Model name|CPU\(s\):'

print_header "Memory Information"
free -h

print_header "Disk Usage Information"
df -h --total | grep -E 'Filesystem|total'

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

print_header "Completed System Check"
