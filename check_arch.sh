#!/bin/bash

echo "Checking system architecture..."
echo "--------------------------------"
echo "OS Type: $(uname -s)"
echo "Kernel Version: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Processor: $(uname -p)"
echo "Hardware Platform: $(uname -i)"
echo "--------------------------------"

echo "Checking using 'arch' command..."
arch
echo "--------------------------------"

echo "Checking CPU info..."
lscpu | grep 'Architecture\|Model name\|CPU(s)'
