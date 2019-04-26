# Use the offical Golang image to create a build artifact.
# This is based on Debian and sets the GOPATH to /go.
# https://hub.docker.com/_/golang
FROM golang as builder

# Copy local code to the container image.
WORKDIR /go/src/github.com/knative/docs/helloworld
COPY . .

# Build the command inside the container.
# (You may fetch or manage dependencies here,
# either manually or with a tool like "godep".)
RUN CGO_ENABLED=0 GOOS=linux go build -v -o server dmesg.go
RUN CGO_ENABLED=0 GOOS=linux go build -v -o tcp-rdtsc tcp-rdtsc.go
RUN CGO_ENABLED=0 GOOS=linux go build -v -o tcp-load tcp-load.go

# compilation requirement
RUN wget http://www.cs.virginia.edu/stream/FTP/Code/stream.c && \
	 gcc -O3 -fopenmp -DSTREAM_ARRAY_SIZE=64000000 -DNTIMES=10 stream.c -o stream

# Use a Docker multi-stage build to create a lean production image.
# https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds
FROM golang

#ADD apt.conf /etc/apt/apt.conf
# Install sysbench
#ADD iozone.test /mnt/mvm-test/iozone.test
RUN apt-get update
RUN apt install --yes sysbench fio iperf3 libnuma-dev
ADD iozone /usr/bin/iozone
ADD getpid /usr/bin/getpid

# Copy the binary to the production image from the builder stage.
COPY --from=builder /go/src/github.com/knative/docs/helloworld/server /server
COPY --from=builder /go/src/github.com/knative/docs/helloworld/tcp-rdtsc /usr/bin/tcp-rdtsc
COPY --from=builder /go/src/github.com/knative/docs/helloworld/tcp-load /usr/bin/tcp-load
COPY --from=builder /go/src/github.com/knative/docs/helloworld/stream /usr/bin/stream
COPY --from=builder /go/src/github.com/knative/docs/helloworld/mlc /usr/bin/mlc

ENV GIT_SSL_NO_VERIFY=true
RUN git clone https://github.com/kdlucas/byte-unixbench.git && \
	cd byte-unixbench/UnixBench && make
RUN git clone https://git.kernel.org/pub/scm/utils/rt-tests/rt-tests.git && \ 
	cd rt-tests && git checkout -b stable/v1.0 origin/stable/v1.0 && make && \
	cp cyclictest /usr/bin/cyclictest

EXPOSE 80

# Visit it via url: 
#	$ curl -X POST -d "ls /" http://localhost:8888
# Run the web service on container startup.
# 1. cpu perf: 						$ cd ./byte-unixbench/UnixBench && ./Run
# 2. cpu perf:						$ sysbench --test=cpu --cpu-max-prime=20000 run
# 3. cpu latency(small is better):	$ cyclictest -D 20s -q -p 99
# 4. memory bandwidth:	$ stream
# 5. memory bandwidth:	$ sysbench --test=memory --memory-block-size=8K --memory-total-size=10G run
# 6. memory bandwidth:	$ mlc --bandwidth_matrix -e
# 7. memory latency:	$ mlc --latency_matrix -r -e
# 8. network band:		$ netperf -H x.x.x.x -p xx -t TCP_STREAM -l 1200 -- -m 1440
# 9. network pps: 		$ netperf -H x.x.x.x -p xx -t UDP_STREAM -l 1200 - -m 64
# 10.network band:		$ iperf3 -c x.x.x.x -p xx -b 0 -t 1200
# 11.network pps: 		$ iperf3 -c x.x.x.x -p xx -b 0 -t 1200
# 	 network monitor:	$ sar -n DEV 1 60
# 12.IO test:			$ iozone -e -r 1M -s 6G -i 0 -I -w  -f /file -+n > /tmp/log && cat /tmp/log
CMD ["/server"]
