#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_path=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/closure-debugger-interactive"

mkdir -p "$output_root"
"$bmk_path" makeapp -a -d -h -t console -o "$application" "$fixture_dir/compiler_closure_debugger_runtime.bmx"

# Each Closure stops immediately before throwing. Printing its stack verifies
# source-facing frame names and live captures; resume then verifies that the
# ordinary exception path unwinds the synthetic invoke frame into Catch.
output=$(printf 't\nr\nt\nr\nt\nr\n' | "$application" 2>&1 | tr -d '\r')

test "$(printf '%s\n' "$output" | grep -c '^~>DebugStop:$')" -eq 3
test "$(printf '%s\n' "$output" | grep -c '^~>StackTrace{$')" -eq 3
printf '%s\n' "$output" | grep -q '^~>Function Closure in MakeOrdinary at line 8$'
printf '%s\n' "$output" | grep -q '^~>Local count:Int=41$'
printf '%s\n' "$output" | grep -q '^~>Function Closure in MakeNested at line 19$'
printf '%s\n' "$output" | grep -q '^~>Local parentValue:Int=11$'
printf '%s\n' "$output" | grep -q '^~>Local childValue:Int=4$'
printf '%s\n' "$output" | grep -q '^~>Function Closure in MakeGeneric at line 31$'
printf '%s\n' "$output" | grep -q '^~>Local genericValue:Int=91$'
test "$(printf '%s\n' "$output" | grep -c '^~>Local environment:Object=')" -eq 0
printf '%s\n' "$output" | grep -q '^ordinary-caught=1$'
printf '%s\n' "$output" | grep -q '^nested-caught=1$'
printf '%s\n' "$output" | grep -q '^generic-caught=1$'

echo "bcc2 Closure interactive debugger regression passed"
