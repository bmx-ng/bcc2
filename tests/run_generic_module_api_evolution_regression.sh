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
module_root="$sdk_root/mod/bcc2apievolutiontest.mod"
module_dir="$module_root/owner.mod"
application="$output_root/generic-api-evolution"

test ! -e "$output_root"
if test -e "$module_root"
then
	echo "temporary generic API-evolution module already exists: $module_root" >&2
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

checksum_file()
{
	set -- $(cksum "$1")
	printf '%s %s\n' "$1" "$2"
}

snapshot_templates()
{
	result=$1
	find "$module_dir/.generics/templates" -name '*.bmxgt' -type f -print | LC_ALL=C sort | while IFS= read -r artifact
	do
		set -- $(cksum "$artifact")
		printf '%s %s %s\n' "$(basename -- "$artifact")" "$1" "$2"
	done > "$result"
}

snapshot_consumer_manifest()
{
	result=$1
	manifest=$(find "$output_root/.bmx" -maxdepth 1 -name 'app.bmx.console.release.*.bmxbuild' -type f)
	test -f "$manifest"
	grep -E '^(file generic-specialization-c|link) ' "$manifest" > "$result"
}

mkdir -p "$module_dir" "$output_root"
cp "$fixture_dir/module_generic_api_evolution_v1.bmx" "$module_dir/owner.bmx"
cp "$fixture_dir/generic_api_evolution_app.bmx" "$output_root/app.bmx"

"$bmk" makemods -a -bcc2 -r Bcc2ApiEvolutionTest.Owner
"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$output_root/app.bmx"
test "$(run_application)" = "1:10"

interface=$(find "$module_dir" -maxdepth 1 -name 'owner.release.*.i' -type f)
consumer_c=$(find "$output_root/.bmx" -maxdepth 1 -name 'app.bmx.console.release.*.c' -type f)
consumer_o=$(find "$output_root/.bmx" -maxdepth 1 -name 'app.bmx.console.release.*.o' -type f)
test -f "$interface"
test -f "$consumer_c"
test -f "$consumer_o"
checksum_file "$interface" > "$output_root/v1-interface.txt"
checksum_file "$consumer_c" > "$output_root/v1-consumer-c.txt"
checksum_file "$consumer_o" > "$output_root/v1-consumer-o.txt"
snapshot_templates "$output_root/v1-templates.txt"
snapshot_consumer_manifest "$output_root/v1-consumer-manifest.txt"

sleep 1
cp "$fixture_dir/module_generic_api_evolution_v2.bmx" "$module_dir/owner.bmx"
"$bmk" makemods -bcc2 -r Bcc2ApiEvolutionTest.Owner
checksum_file "$interface" > "$output_root/v2-interface.txt"
snapshot_templates "$output_root/v2-templates.txt"
cmp "$output_root/v1-interface.txt" "$output_root/v2-interface.txt"
cmp "$output_root/v1-templates.txt" "$output_root/v2-templates.txt"

private_output=$("$bmk" makeapp -bcc2 -single -r -o "$application" "$output_root/app.bmx")
if printf '%s' "$private_output" | grep -Eq 'Processing:app|Compiling generic specialization|Compiling:app'
then
	echo "private provider change recompiled the consumer" >&2
	exit 1
fi
printf '%s' "$private_output" | grep -q 'Linking:generic-api-evolution'
test "$(run_application)" = "1:20"
checksum_file "$consumer_c" > "$output_root/v2-consumer-c.txt"
checksum_file "$consumer_o" > "$output_root/v2-consumer-o.txt"
cmp "$output_root/v1-consumer-c.txt" "$output_root/v2-consumer-c.txt"
cmp "$output_root/v1-consumer-o.txt" "$output_root/v2-consumer-o.txt"

sleep 1
cp "$fixture_dir/module_generic_api_evolution_v3.bmx" "$module_dir/owner.bmx"
"$bmk" makemods -bcc2 -r Bcc2ApiEvolutionTest.Owner
checksum_file "$interface" > "$output_root/v3-interface.txt"
if cmp -s "$output_root/v2-interface.txt" "$output_root/v3-interface.txt"
then
	echo "generic body change did not revise the compact interface" >&2
	exit 1
fi
body_output=$("$bmk" makeapp -bcc2 -single -r -o "$application" "$output_root/app.bmx")
printf '%s' "$body_output" | grep -q 'Compiling generic specializations'
test "$(run_application)" = "2:20"
snapshot_consumer_manifest "$output_root/v3-consumer-manifest.txt"
if cmp -s "$output_root/v1-consumer-manifest.txt" "$output_root/v3-consumer-manifest.txt"
then
	echo "generic body change retained the previous consumer specialization manifest" >&2
	exit 1
fi

sleep 1
cp "$fixture_dir/module_generic_api_evolution_v4.bmx" "$module_dir/owner.bmx"
"$bmk" makemods -bcc2 -r Bcc2ApiEvolutionTest.Owner
constraint_output=$("$bmk" makeapp -bcc2 -single -r -o "$application" "$output_root/app.bmx")
printf '%s' "$constraint_output" | grep -q 'Compiling generic specializations'
test "$(run_application)" = "2:20"
snapshot_consumer_manifest "$output_root/v4-consumer-manifest.txt"
if cmp -s "$output_root/v3-consumer-manifest.txt" "$output_root/v4-consumer-manifest.txt"
then
	echo "generic constraint change retained the previous specialization manifest" >&2
	exit 1
fi

sleep 1
cp "$fixture_dir/module_generic_api_evolution_v5.bmx" "$module_dir/owner.bmx"
"$bmk" makemods -bcc2 -r Bcc2ApiEvolutionTest.Owner
signature_output=$("$bmk" makeapp -bcc2 -single -r -o "$application" "$output_root/app.bmx")
printf '%s' "$signature_output" | grep -q 'Compiling generic specializations'
test "$(run_application)" = "3:20"

quiet_output=$("$bmk" makeapp -bcc2 -single -r -o "$application" "$output_root/app.bmx")
if printf '%s' "$quiet_output" | grep -Eq 'Processing:app|Compiling generic specialization|Compiling:app|Linking:generic-api-evolution'
then
	printf '%s\n' "$quiet_output" >&2
	echo "unchanged final generic API was rebuilt" >&2
	exit 1
fi

cleanup_module
trap - 0 HUP INT TERM

echo "bcc2 generic module API-evolution regression passed"
