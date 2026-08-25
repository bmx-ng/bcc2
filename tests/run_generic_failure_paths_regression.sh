#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)

test ! -e "$output_root"
mkdir -p "$output_root/negative" "$output_root/repair"

expect_failure()
{
	case_name=$1
	expected_code=$2
	fixture=$3
	case_root="$output_root/negative/$case_name"
	mkdir -p "$case_root"
	source="$case_root/$case_name.bmx"
	application="$case_root/$case_name"
	output="$case_root/output.txt"
	cp "$fixture_dir/$fixture" "$source"
	if "$bmk" makeapp -bcc2 -single -r -o "$application" "$source" >"$output" 2>&1
	then
		echo "$case_name unexpectedly compiled" >&2
		exit 1
	fi
	grep -q "$expected_code" "$output"
	test ! -e "$application"
	test ! -e "$application.exe"
	if grep -Eqi 'segmentation fault|internal compiler error|assertion failed' "$output"
	then
		echo "$case_name failed through an internal compiler fault" >&2
		exit 1
	fi
}

expect_failure arity BMX3102 generic_negative_arity.bmx
expect_failure constraint BMX3209 generic_negative_constraint.bmx
expect_failure ambiguous BMX3303 generic_negative_ambiguous.bmx
expect_failure recursive-struct BMXC3008 generic_negative_recursive_struct.bmx
expect_failure runaway BMXC3090 generic_negative_runaway.bmx
expect_failure initialization-cycle BMXC3091 generic_negative_initialization_cycle.bmx
expect_failure scalar-throw BMXC3066 generic_negative_scalar_throw.bmx

repair_source="$output_root/repair/app.bmx"
repair_application="$output_root/repair/generic-failure-repair"
cp "$fixture_dir/generic_failure_repair_v1.bmx" "$repair_source"
"$bmk" makeapp -a -bcc2 -single -r -o "$repair_application" "$repair_source"
repair_executable=$repair_application
if test -f "$repair_application.exe"
then
	repair_executable="$repair_application.exe"
fi
test "$("$repair_executable" | tr -d '\r\n')" = "1"
executable_v1=$(cksum "$repair_executable")

sleep 1
cp "$fixture_dir/generic_failure_repair_invalid.bmx" "$repair_source"
repair_failure_output="$output_root/repair/failure.txt"
if "$bmk" makeapp -bcc2 -single -r -o "$repair_application" "$repair_source" >"$repair_failure_output" 2>&1
then
	echo "invalid replacement unexpectedly compiled" >&2
	exit 1
fi
grep -q 'BMXC3066' "$repair_failure_output"
test "$(cksum "$repair_executable")" = "$executable_v1"
test "$("$repair_executable" | tr -d '\r\n')" = "1"

sleep 1
cp "$fixture_dir/generic_failure_repair_v3.bmx" "$repair_source"
"$bmk" makeapp -bcc2 -single -r -o "$repair_application" "$repair_source"
test "$("$repair_executable" | tr -d '\r\n')" = "3"
test "$(cksum "$repair_executable")" != "$executable_v1"
test -z "$(find "$output_root/repair" -type f \( -name '*.bmk-tmp' -o -name '*.tmp' \) -print)"

echo "bcc2 generic failure-path regression passed"
