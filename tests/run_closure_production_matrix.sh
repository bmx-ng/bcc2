#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_path=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)

mkdir -p "$output_root"

build_and_run()
{
	case_name=$1
	source_name=$2
	expected=$3
	shift 3
	application="$output_root/$case_name"
	"$bmk_path" makeapp -a -bcc2 -t console "$@" -o "$application" "$fixture_dir/$source_name"
	executable=$application
	if test -x "$application.exe"; then executable="$application.exe"; fi
	result=$("$executable" | tail -n 1 | tr -d '\r')
	if test "$result" != "$expected"; then
		echo "$case_name produced '$result', expected '$expected'" >&2
		exit 1
	fi
}

run_configuration()
{
	configuration=$1
	shift
	build_and_run "ordinary-$configuration" compiler_closure_capture_runtime.bmx closure-capture-ok "$@"
	build_and_run "generic-$configuration" compiler_generic_closure_runtime.bmx generic-closure-ok "$@"
	build_and_run "literal-$configuration" compiler_closure_literal_runtime.bmx closure-ok "$@"
}

# Modern NG bmk builds are threaded by default. `-single` selects a single
# application source root; it does not disable runtime threading. Keep default
# and explicit `-h` rows to verify their equivalence while Closure environments
# retain the same managed layout and exception behavior in debug and release.
run_configuration debug-default -single
run_configuration release-default -single -r
run_configuration debug-explicit-threaded -single -h
run_configuration release-explicit-threaded -single -h -r

echo "bcc2 Closure production matrix passed: $(uname -s) $(uname -m)"
