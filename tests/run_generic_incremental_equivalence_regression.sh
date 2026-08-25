#!/bin/sh
set -eu

if test "$#" -ne 2
then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
incremental_root="$output_root/incremental"

test ! -e "$output_root"

run_application()
{
	application=$1
	executable=$application
	if test -f "$application.exe"
	then
		executable="$application.exe"
	fi
	"$executable" | tail -n 1 | tr -d '\r'
}

snapshot_reachable_bundles()
{
	root=$1
	result=$2
	find "$root/.bmx" -maxdepth 1 -type f \( \
		-name 'app.bmx.*.c' -o \
		-name 'app.bmx.*.bmxbuild' -o \
		-name 'pipeline.bmx.*.c' -o \
		-name 'pipeline.bmx.*.h' -o \
		-name 'pipeline.bmx.*.i' -o \
		-name 'pipeline.bmx.*.bmxbuild' -o \
		-name 'types.bmx.*.c' -o \
		-name 'types.bmx.*.h' -o \
		-name 'types.bmx.*.i' -o \
		-name 'types.bmx.*.bmxbuild' \
	\) -print | LC_ALL=C sort | while IFS= read -r artifact
	do
		set -- $(cksum "$artifact")
		printf '%s %s %s\n' "$(basename -- "$artifact")" "$1" "$2"
	done > "$result"
}

mkdir -p "$incremental_root"
cp "$fixture_dir/generic_incremental_provider_v1.bmx" "$incremental_root/provider.bmx"
cp "$fixture_dir/generic_incremental_app_v1.bmx" "$incremental_root/app.bmx"
incremental_application="$incremental_root/generic-incremental"
"$bmk" makeapp -a -bcc2 -single -r -o "$incremental_application" "$incremental_root/app.bmx"
test "$(run_application "$incremental_application")" = "seed!"

sleep 1
cp "$fixture_dir/generic_incremental_provider_v2.bmx" "$incremental_root/provider.bmx"
body_output=$("$bmk" makeapp -bcc2 -single -r -o "$incremental_application" "$incremental_root/app.bmx")
printf '%s\n' "$body_output"
printf '%s' "$body_output" | grep -q 'Compiling generic specializations'
test "$(run_application "$incremental_application")" = "seed!!"

sleep 1
cp "$fixture_dir/generic_incremental_provider_v3.bmx" "$incremental_root/provider.bmx"
cp "$fixture_dir/generic_incremental_app_v3.bmx" "$incremental_root/app.bmx"
shape_output=$("$bmk" makeapp -bcc2 -single -r -o "$incremental_application" "$incremental_root/app.bmx")
printf '%s\n' "$shape_output"
printf '%s' "$shape_output" | grep -q 'Compiling generic specializations'
incremental_result=$(run_application "$incremental_application")
test "$incremental_result" = "v3-ok"

sleep 1
rm -f "$incremental_root/provider.bmx"
cp "$fixture_dir/generic_incremental_types_v4.bmx" "$incremental_root/types.bmx"
cp "$fixture_dir/generic_incremental_pipeline_v4.bmx" "$incremental_root/pipeline.bmx"
cp "$fixture_dir/generic_incremental_app_v4.bmx" "$incremental_root/app.bmx"
topology_output=$("$bmk" makeapp -bcc2 -single -r -o "$incremental_application" "$incremental_root/app.bmx")
printf '%s\n' "$topology_output"
printf '%s' "$topology_output" | grep -q 'Compiling generic specializations'
test "$(run_application "$incremental_application")" = "topology-ok"

stale_provider_manifest=$(find "$incremental_root/.bmx" -maxdepth 1 -name 'provider.bmx.*.bmxbuild' -type f)
test -f "$stale_provider_manifest"
snapshot_reachable_bundles "$incremental_root" "$output_root/incremental-final.txt"

rm -rf "$incremental_root/.bmx"
rm -f "$incremental_application" "$incremental_application.exe"
"$bmk" makeapp -a -bcc2 -single -r -o "$incremental_application" "$incremental_root/app.bmx"
test "$(run_application "$incremental_application")" = "topology-ok"
snapshot_reachable_bundles "$incremental_root" "$output_root/clean-final.txt"
cmp "$output_root/incremental-final.txt" "$output_root/clean-final.txt"

quiet_output=$("$bmk" makeapp -bcc2 -single -r -o "$incremental_application" "$incremental_root/app.bmx")
if printf '%s' "$quiet_output" | grep -Eq 'Processing:|Compiling generic specialization|Compiling:|Linking:'
then
	printf '%s\n' "$quiet_output" >&2
	echo "unchanged clean-equivalent generic application was rebuilt" >&2
	exit 1
fi

echo "bcc2 generic clean/incremental equivalence regression passed"
