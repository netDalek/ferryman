.PHONY: all deps compile run test clean

REBAR=./rebar3

all: compile

deps:
	$(REBAR) install_deps

compile: deps
	$(REBAR) compile

console:
	erl -pa _build/default/lib/*/ebin

test:
	$(REBAR) eunit skip_deps=true verbose=3

clean:
	$(REBAR) clean
	rm -rf ./log
	rm -rf ./erl_crash.dump
