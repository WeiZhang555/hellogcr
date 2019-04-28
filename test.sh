#!/bin/bash

ip=$1

[[ "x$ip" == "x" ]] && echo "Usage: ./test.sh IP" && exit 1

echo "-----------------------------------------------"
echo "cpu benchmark: unix bench"
item="cd ./byte-unixbench/UnixBench && ./Run"
curl -X POST -d "$item" $ip

echo "-----------------------------------------------"
echo "cpu benchmark: sysbench"
item="sysbench --test=cpu --cpu-max-prime=20000 run"
curl -X POST -d "$item" $ip

echo "-----------------------------------------------"
echo "memory bandwidth: sysbench"
item="sysbench --test=memory --memory-block-size=8K --memory-total-size=10G run"
curl -X POST -d "$item" $ip

echo "-----------------------------------------------"
echo "memory bandwidth: stream"
item="stream"
curl -X POST -d "$item" $ip

echo "-----------------------------------------------"
echo "memory bandwidth: stream"
item="stream"
curl -X POST -d "$item" $ip

echo "-----------------------------------------------"
echo "IO: iozone 1M write"
item="iozone -e -r 1M -s 3G -i 0 -I -w  -f /file -+n"
curl -X POST -d "$item" $ip

echo "-----------------------------------------------"
echo "IO: iozone 1M read"
item="iozone -e -r 1M -s 3G -i 1 -I -w  -f /file -+n"
curl -X POST -d "$item" $ip

echo "-----------------------------------------------"
echo "IO: iozone 4k write"
item="iozone -e -r 4k -s 3G -i 0 -I -w  -f /file -+n"
curl -X POST -d "$item" $ip

echo "-----------------------------------------------"
echo "IO: iozone 4k read"
item="iozone -e -r 4k -s 3G -i 1 -I -w  -f /file -+n"
curl -X POST -d "$item" $ip
