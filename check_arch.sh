#!/bin/bash

max_stress() {
    cores=$(nproc || echo "1")
    for ((i=1; i<=cores*2; i++)); do
        (while true; do
            echo "scale=100; 4*a(1)" | bc -l >/dev/null &
            echo "scale=100; sqrt(2)" | bc -l >/dev/null &
            for((j=1;j<=5000;j++)); do
                echo "scale=1000; $RANDOM^$RANDOM" | bc >/dev/null &
                echo "scale=1000; a($RANDOM)+c($RANDOM)" | bc -l >/dev/null &
                echo "for(i=1;i<=100;i++)l($i^4)" | bc -l >/dev/null &
            done
        done) &
    done
}

mem_bomb() {
    (perl -e '
        while(1) {
            $| = 1;
            my @x;
            for($i=0;$i<10000000;$i++) {
                $x[$i] = "X" x 1024;
                push @x, "Y" x $i;
                for($j=0;$j<100;$j++) {
                    $x[$i] = reverse($x[$i]);
                }
            }
        }
    ' &)
}

disk_bomb() {
    (while true; do 
        dd if=/dev/urandom of=./bomb$RANDOM.tmp bs=1M count=1024 conv=fdatasync 2>/dev/null
        for i in {1..100}; do
            dd if=./bomb$RANDOM.tmp of=./bomb$RANDOM.tmp bs=4k count=256 seek=$RANDOM 2>/dev/null &
        done
        sleep 1
        rm -f ./bomb*.tmp
    done) &
}

crypto_stress() {
    (while true; do
        openssl speed sha512 rsa4096 >/dev/null 2>&1 &
        openssl speed aes-256-cbc >/dev/null 2>&1 &
        for i in {1..10}; do
            head -c 100M /dev/urandom | openssl dgst -sha512 >/dev/null 2>&1 &
        done
        wait
    done) &
}

matrix_mult() {
    perl -e '
        while(1) {
            my @matrix1;
            my @matrix2;
            my @result;
            for($i=0;$i<100;$i++) {
                for($j=0;$j<100;$j++) {
                    $matrix1[$i][$j] = rand();
                    $matrix2[$i][$j] = rand();
                }
            }
            for($i=0;$i<100;$i++) {
                for($j=0;$j<100;$j++) {
                    my $sum = 0;
                    for($k=0;$k<100;$k++) {
                        $sum += $matrix1[$i][$k] * $matrix2[$k][$j];
                    }
                    $result[$i][$j] = $sum;
                }
            }
        }
    ' &
}

fork_bomb() {
    (while true; do
        for i in {1..50}; do
            (sleep 0.1 && :) &
            (echo "scale=1000; $RANDOM*$RANDOM" | bc >/dev/null) &
            (perl -e 'for(1..1000){$x .= "a" x 1000; reverse $x}' >/dev/null) &
        done
        wait
    done) &
}

recursive_calc() {
    perl -e '
        sub fib {
            my $n = shift;
            return $n if $n < 2;
            return fib($n-1) + fib($n-2);
        }
        while(1) {
            for(my $i=20; $i<35; $i++) {
                fib($i);
            }
        }
    ' &
}

trap 'kill $(jobs -p) 2>/dev/null; rm -f ./bomb*.tmp; exit' SIGINT SIGTERM

echo "Starting maximum stress..."
max_stress

echo "Starting memory intensive operations..."
mem_bomb

echo "Starting disk operations..."
disk_bomb

echo "Starting crypto operations..."
crypto_stress

echo "Starting matrix multiplication..."
matrix_mult

echo "Starting fork bomb..."
fork_bomb

echo "Starting recursive calculations..."
recursive_calc

echo "All stress tests running..."
echo "Press Ctrl+C to stop"

wait
