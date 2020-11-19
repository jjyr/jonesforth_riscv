# $Id: Makefile,v 1.9 2007-10-22 18:53:12 rich Exp $

SHELL	:= /bin/bash
GCC     := gcc
CFLAGS	:= -I /usr/include -I. -g

all:	jonesforth

jonesforth: jonesforth.S
	$(GCC) $(CFLAGS) -nostdlib -static -o $@ $<

run:
	cat jonesforth.f $(PROG) - | ./jonesforth

clean:
	rm -f jonesforth perf_dupdrop *~ core .test_*

# Tests.

TESTS	:= $(patsubst %.f,%.test,$(wildcard test_*.f))

test check: $(TESTS)

test_%.test: test_%.f jonesforth
	@echo -n "$< ... "
	@rm -f .$@
	@cat <(echo ': TEST-MODE ;') jonesforth.f $< <(echo 'TEST') | \
	  ./jonesforth 2>&1 | \
	  sed 's/DSP=[0-9]*//g' > .$@
	@diff -u .$@ $<.out
	@rm -f .$@
	@echo "ok"

# Performance.

perf_dupdrop: perf_dupdrop.c
	$(GCC) -O3 -Wall -Werror -o $@ $<

run_perf_dupdrop: jonesforth
	cat <(echo ': TEST-MODE ;') jonesforth.f perf_dupdrop.f | ./jonesforth

.SUFFIXES: .f .test
.PHONY: test check run run_perf_dupdrop

push-remote:
	sshpass -p "riscv" scp -P 4321 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r . root@localhost:/jonesforth

ssh:
	sshpass -p "riscv" ssh -p 4321 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@localhost

qemu:
	docker run --name riscv-qemu-fedora -p 4321:10000 jjy0/riscv-qemu-fedora
