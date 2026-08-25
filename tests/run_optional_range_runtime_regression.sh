#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/optional-range-runtime"

mkdir -p "$output_root"
"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$fixture_dir/compiler_optional_range_runtime.bmx"

executable=$application
if test -f "$application.exe"
then
	executable="$application.exe"
fi

result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "optional-range-ok"

expect_failure() {
	source_name=$1
	expected=$2
	log="$output_root/$source_name.log"
	if "$bmk" makeapp -a -bcc2 -single -r -o "$output_root/$source_name" "$fixture_dir/$source_name.bmx" >"$log" 2>&1
	then
		echo "$source_name unexpectedly compiled" >&2
		exit 1
	fi
	grep -F "$expected" "$log" >/dev/null
}

expect_failure compiler_range_ranked_negative "BMX3310: Range slicing requires a one-dimensional heap Array."
expect_failure compiler_range_lookalike_negative "conversion to UInt is required"
expect_failure compiler_range_static_array_negative "BMX3310: Range slicing requires a one-dimensional heap Array; StaticArray values are not supported."

echo "bcc2 Optional and Range runtime regression passed"
