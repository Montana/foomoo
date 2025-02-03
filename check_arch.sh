#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' 

print_header() {
    local title="$1"
    echo -e "${BLUE}=== $title ===${NC}\n"
}

print_section() {
    local title="$1"
    echo -e "${GREEN}$title${NC}"
    echo -e "${GREEN}${title//?/-}${NC}"
}

print_header "TRAVIS CI SYSTEM ANALYSIS"

ARCH=$(uname -m)
OS=$(uname -s)
KERNEL=$(uname -r)

echo -e "Architecture: ${RED}$ARCH${NC}"
echo -e "OS: ${RED}$OS${NC}"
echo -e "Kernel: ${RED}$KERNEL${NC}\n"

print_section "System Details"
if [ -f /etc/os-release ]; then
    source /etc/os-release
    echo -e "Distribution: ${RED}$NAME${NC}"
    echo -e "Version: ${RED}$VERSION${NC}"
fi

print_section "CPU Configuration"
if command -v lscpu >/dev/null 2>&1; then
    lscpu | grep -E "Architecture|CPU op-mode|Thread|Core|Socket|Model name|CPU MHz"
else
    echo "CPU info not available (lscpu not found)"
fi

print_section "Memory Status"
if command -v free >/dev/null 2>&1; then
    free -h
else
    echo "Memory info not available (free command not found)"
fi

print_section "Storage Status"
if command -v df >/dev/null 2>&1; then
    df -h /
else
    echo "Storage info not available (df command not found)"
fi

print_section "Performance Tests"

echo "1. CPU Test - Prime Numbers"
SECONDS=0
count=0
for ((i=2; i<=1000; i++)); do
    is_prime=1
    for ((j=2; j<=i/2; j++)); do
        if [ $((i%j)) -eq 0 ]; then
            is_prime=0
            break
        fi
    done
    if [ $is_prime -eq 1 ]; then
        ((count++))
    fi
done
echo -e "Found $count prime numbers in ${RED}$SECONDS${NC} seconds\n"

echo "2. I/O Performance Test"
echo "Writing 100MB..."
dd if=/dev/urandom of=test_file bs=1M count=100 2>&1 | grep -E "bytes|copied"
echo "Reading 100MB..."
dd if=test_file of=/dev/null bs=1M count=100 2>&1 | grep -E "bytes|copied"
rm -f test_file

print_section "Environment Variables"
echo "CI: $CI"
echo "TRAVIS: $TRAVIS"
echo "BUILD_DIR: $TRAVIS_BUILD_DIR"
echo "BUILD_ID: $TRAVIS_BUILD_ID"
echo "BUILD_NUMBER: $TRAVIS_BUILD_NUMBER"

print_header "END OF ANALYSIS"
