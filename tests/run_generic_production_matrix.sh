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
	if test -f "$application.exe"
	then
		executable="$application.exe"
	fi
	result=$("$executable" | tail -n 1 | tr -d '\r')
	if test "$result" != "$expected"
	then
		echo "$case_name produced '$result', expected '$expected'" >&2
		exit 1
	fi
}

run_configuration()
{
	configuration=$1
	shift
	build_and_run "composition-$configuration" compiler_generic_composition_matrix_runtime.bmx generic-composition-matrix-runtime-ok "$@"
	build_and_run "boundary-$configuration" compiler_generic_boundary_stress_runtime.bmx generic-boundary-stress-ok "$@"
	build_and_run "statements-$configuration" generic_statement_boundaries.bmx "bcc2 generic statement boundaries ok" "$@"
	build_and_run "lifecycle-$configuration" generic_lifecycle_boundaries.bmx "bcc2 generic lifecycle boundaries ok" "$@"
	build_and_run "initialization-$configuration" generic_initialization_ordering.bmx "bcc2 generic initialization ordering ok" "$@"
	build_and_run "threaded-global-$configuration" generic_threaded_global_runtime.bmx "bcc2 generic ThreadedGlobal runtime ok" "$@"
}

# Modern NG bmk builds are threaded by default. `-single` selects a single
# application source root; it does not disable runtime threading. Keep default
# and explicit `-h` rows to verify their equivalence while debug/release retain
# distinct canonical configurations.
run_configuration debug-default -single
run_configuration release-default -single -r
run_configuration debug-explicit-threaded -single -h
run_configuration release-explicit-threaded -single -h -r

echo "bcc2 generic production matrix passed: $(uname -s) $(uname -m)"
