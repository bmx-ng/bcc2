#!/bin/sh
set -eu

if test "$#" -ne 2
then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
bmk="$bmk_dir/$(basename -- "$1")"
sdk_root=$(CDPATH= cd -- "$bmk_dir/.." && pwd)
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
module_root="$sdk_root/mod/bcc2scaletest.mod"
module_dir="$module_root/graph.mod"
application="$output_root/generic-scale-graph"

test ! -e "$output_root"
if test -e "$module_root"
then
	echo "temporary generic scale-test module already exists: $module_root" >&2
	exit 1
fi

cleanup_module()
{
	rm -rf "$module_root"
}
trap cleanup_module 0 HUP INT TERM

run_application()
{
	executable=$application
	if test -f "$application.exe"
	then
		executable="$application.exe"
	fi
	"$executable" | tail -n 1 | tr -d '\r'
}

snapshot_generic_artifacts()
{
	root=$1
	result=$2
	find "$root/.bmx/.generics" -type f \( -name '*.c' -o -name '*.o' -o -name '*.bcc2key' \) -print | LC_ALL=C sort | while IFS= read -r artifact
	do
		relative=${artifact#"$root"/}
		set -- $(cksum "$artifact")
		printf '%s %s %s\n' "$relative" "$1" "$2"
	done > "$result"
}

mkdir -p "$module_dir" "$output_root"
cp "$fixture_dir/module_generic_scale_graph_owner.bmx" "$module_dir/graph.bmx"
"$bmk" makemods -a -bcc2 -r Bcc2ScaleTest.Graph
test "$(find "$module_dir/.generics/templates" -name '*.bmxgt' -type f | wc -l | tr -d ' ')" -ge 11

cp "$fixture_dir/generic_scale_graph_left_v1.bmx" "$output_root/left.bmx"
cp "$fixture_dir/generic_scale_graph_stable.bmx" "$output_root/stable.bmx"
cp "$fixture_dir/generic_scale_graph_app_v1.bmx" "$output_root/app.bmx"
"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$output_root/app.bmx"
test "$(run_application)" = "generic-scale-graph-ok-40"

initial_count=$(find "$output_root/.bmx/.generics" -name '*.c' -type f | wc -l | tr -d ' ')
test "$initial_count" -ge 34
snapshot_generic_artifacts "$output_root" "$output_root/initial-artifacts.txt"

sleep 1
cp "$fixture_dir/generic_scale_graph_left_v2.bmx" "$output_root/left.bmx"
body_output=$("$bmk" makeapp -bcc2 -single -r -o "$application" "$output_root/app.bmx")
if printf '%s' "$body_output" | grep -q 'Compiling generic specialization'
then
	echo "body-only included-source edit recompiled an unchanged generic graph" >&2
	exit 1
fi
test "$(run_application)" = "generic-scale-graph-ok-41"
snapshot_generic_artifacts "$output_root" "$output_root/body-artifacts.txt"
cmp "$output_root/initial-artifacts.txt" "$output_root/body-artifacts.txt"

sleep 1
cp "$fixture_dir/generic_scale_graph_left_v3.bmx" "$output_root/left.bmx"
cp "$fixture_dir/generic_scale_graph_app_v3.bmx" "$output_root/app.bmx"
expansion_output=$("$bmk" makeapp -bcc2 -single -r -o "$application" "$output_root/app.bmx")
printf '%s' "$expansion_output" | grep -q 'Compiling generic specializations'
test "$(run_application)" = "generic-scale-graph-ok-41"

expanded_count=$(find "$output_root/.bmx/.generics" -name '*.c' -type f | wc -l | tr -d ' ')
test "$expanded_count" -eq $((initial_count + 10))
while IFS=' ' read -r relative checksum size
do
	set -- $(cksum "$output_root/$relative")
	test "$1" = "$checksum"
	test "$2" = "$size"
done < "$output_root/initial-artifacts.txt"

unchanged_output=$("$bmk" makeapp -bcc2 -single -r -o "$application" "$output_root/app.bmx")
if printf '%s' "$unchanged_output" | grep -Eq 'Processing:app|Compiling generic specialization|Compiling:app|Linking:generic-scale-graph'
then
	echo "unchanged expanded generic graph was rebuilt" >&2
	exit 1
fi

cleanup_module
trap - 0 HUP INT TERM

echo "bcc2 generic scale/request-graph regression passed: $initial_count initial units, $expanded_count after localized growth"
