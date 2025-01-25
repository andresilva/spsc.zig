OPT ?= Debug

build:
	zig build-exe -O $(OPT) benchmark.zig

run: build
	./benchmark

benchmark: OPT = ReleaseFast
benchmark: run

test:
	zig test benchmark.zig

clean:
	rm -rf benchmark benchmark.o

all: build test
