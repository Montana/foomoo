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
    for ((i=1; i<=cores; i++)); do
        (
            for ((j=1; j<=duration; j++)); do
                echo "scale=50; for(i=1; i<=100; i+=1) s+=sqrt($j*$i+sqrt($j*$i)); s" | bc >/dev/null
                echo "scale=50; a=1; for(i=1; i<=50; i+=1) a=a*($i/$j)" | bc >/dev/null
                echo "for(i=2; i<=$j; i++) { p=1; for(k=2; k<i; k++) if (i%k==0) p=0; if (p==1) print i }" | bc >/dev/null
            done
        ) &
    done
    wait
}

memory_test() {
    duration=$1
    size_mb=$2
    perl -e "
        use strict;
        my @array;
        for (1..$size_mb) {
            push @array, 'X' x (1024 * 1024);
        }
        my \$end_time = time() + $duration;
        while (time() < \$end_time) {
            foreach my \$i (0..\$#array) {
                \$array[\$i] = reverse(\$array[\$i]) if \$i % 100 == 0;
            }
            sleep 1;
        }
    "
}

disk_test() {
    duration=$1
    size_gb=$2
    dd if=/dev/urandom of=./test_file bs=1M count=$((size_gb * 1024)) &>/dev/null
    end_time=$((SECONDS + duration))
    while [ $SECONDS -lt $end_time ]; do
        dd if=./test_file of=/dev/null bs=8k count=1000 skip=$((RANDOM % (size_gb * 131072))) &>/dev/null
        dd if=/dev/urandom of=./test_file bs=8k count=100 seek=$((RANDOM % (size_gb * 131072))) conv=notrunc &>/dev/null
    done
    rm -f ./test_file
}

network_test() {
    duration=$1
    end_time=$((SECONDS + duration))
    while [ $SECONDS -lt $end_time ]; do
        ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1 &
        ping -c 1 -W 1 1.1.1.1 >/dev/null 2>&1 &
        for domain in google.com amazon.com facebook.com twitter.com reddit.com; do
            dig +short $domain >/dev/null 2>&1 &
            curl -s -o /dev/null $domain &>/dev/null &
        done
        wait
        sleep 1
    done
}

monitor() {
    ps aux --sort=-%cpu | head -n 6
    ps aux --sort=-%mem | head -n 6
    uptime
    iostat 1 2 2>/dev/null
    sensors 2>/dev/null | grep "Core"
}

cpu_load_test 60
memory_test 30 1024
disk_test 30 2
network_test 30

(while true; do monitor; sleep 10; done) &
monitor_pid=$!
sleep 150
kill $monitor_pid 2>/dev/null

uptime
free -h
iostat -d 1 1 2>/dev/null
