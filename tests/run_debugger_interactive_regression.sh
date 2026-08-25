#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_path=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/debugger-interactive"

mkdir -p "$output_root"
"$bmk_path" makeapp -a -d -h -t console -o "$application" "$fixture_dir/compiler_debugger_interactive_runtime.bmx"

# The first prompt exercises help and a nested main-thread stack. Step-over is
# then retained across a Throw that crosses RaiseFailure, so the catch body must
# produce the third Debug prompt. A second sequence crosses both an inner
# rethrow checkpoint and its outer catch. The worker subsequently exercises an
# independent thread-local debugger stack and command loop.
output=$(printf 'h\nt\ns\ns\ns\nr\ns\ns\ns\nr\nh\nt\nr\n' | "$application" 2>&1 | tr -d '\r')

test "$(printf '%s\n' "$output" | grep -c '^~>DebugStop:$')" -eq 3
test "$(printf '%s\n' "$output" | grep -c '^~>Debug:$')" -eq 6
test "$(printf '%s\n' "$output" | grep -c '^~>StackTrace{$')" -eq 2
printf '%s\n' "$output" | grep -q '^~>T - Stack trace$'
printf '%s\n' "$output" | grep -q '^~>Function Outer$'
printf '%s\n' "$output" | grep -q '^~>Function CatchFailure$'
printf '%s\n' "$output" | grep -q '^~>Local outerMarker:Int=11$'
printf '%s\n' "$output" | grep -q '^~>Function Worker$'
printf '%s\n' "$output" | grep -q '^~>Local workerValue:Int=99$'
printf '%s\n' "$output" | grep -q '^caught=1$'
printf '%s\n' "$output" | grep -q '^rethrown=1$'
printf '%s\n' "$output" | grep -q '^worker=99$'

echo "bcc2 interactive debugger regression passed"
