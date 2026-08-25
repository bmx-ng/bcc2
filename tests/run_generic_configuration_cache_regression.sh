#!/bin/sh
set -eu

if test "$#" -ne 2
then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
bmk="$bmk_dir/$(basename -- "$1")"
compiler="$bmk_dir/bcc"
if test -f "$bmk_dir/bcc.exe"
then
	compiler="$bmk_dir/bcc.exe"
fi
sdk_root=$(CDPATH= cd -- "$bmk_dir/.." && pwd)
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
source_file="$output_root/app.bmx"

test ! -e "$output_root"
mkdir -p "$output_root"
cp "$fixture_dir/generic_configuration_cache_app.bmx" "$source_file"

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

snapshot_manifest()
{
	label=$1
	mode=debug
	case "$label" in
		release-*) mode=release ;;
	esac
	manifest=$(find "$output_root/.bmx" -maxdepth 1 -name "app.bmx.console.$mode.*.bmxbuild" -type f)
	test -f "$manifest"
	grep -E '^(file generic-specialization-c|link) ' "$manifest" > "$output_root/$label-manifest.txt"
}

build_configuration()
{
	label=$1
	shift
	application="$output_root/app-$label"
	"$bmk" makeapp -a -bcc2 -t console "$@" -o "$application" "$source_file"
	test "$(run_application "$application")" = "generic-configuration-cache-ok"
	snapshot_manifest "$label"
}

build_configuration debug-default -single
build_configuration release-default -single -r
build_configuration debug-explicit-threaded -single -h
build_configuration release-explicit-threaded -single -h -r

# NG bmk builds are threaded by default. -h is therefore an explicit spelling
# of the existing mode and must not fork canonical identities.
cmp "$output_root/debug-default-manifest.txt" "$output_root/debug-explicit-threaded-manifest.txt"
cmp "$output_root/release-default-manifest.txt" "$output_root/release-explicit-threaded-manifest.txt"

awk '$1 == "link" { print $2 }' "$output_root/debug-default-manifest.txt" | LC_ALL=C sort > "$output_root/debug-ids.txt"
awk '$1 == "link" { print $2 }' "$output_root/release-default-manifest.txt" | LC_ALL=C sort > "$output_root/release-ids.txt"
test -z "$(comm -12 "$output_root/debug-ids.txt" "$output_root/release-ids.txt")"

# A timestamp-only revisit republishes no changed generic unit and recompiles
# no specialization object; the retained debug configuration is reused.
touch "$source_file"
return_output=$("$bmk" makeapp -bcc2 -t console -single -o "$output_root/app-debug-default" "$source_file")
if printf '%s' "$return_output" | grep -q 'Compiling generic specialization'
then
	echo "returning to a cached configuration recompiled generic specializations" >&2
	exit 1
fi
test "$(run_application "$output_root/app-debug-default")" = "generic-configuration-cache-ok"

quiet_output=$("$bmk" makeapp -bcc2 -t console -single -o "$output_root/app-debug-default" "$source_file")
if printf '%s' "$quiet_output" | grep -Eq 'Processing:app|Compiling generic specialization|Compiling:app|Linking:app-debug-default'
then
	echo "unchanged cached configuration was rebuilt" >&2
	exit 1
fi

# bmk's NG policy is always threaded, but the compiler option remains a real
# configuration boundary for direct/packaging consumers.
for threading in single threaded
do
	direct_root="$output_root/direct-$threading"
	threading_option=--single-threaded
	if test "$threading" = threaded
	then
		threading_option=--threaded
	fi
	"$compiler" --emit-build --debug "$threading_option" --app-type console \
		--framework brl.standardio --sdk "$sdk_root" -o "$direct_root" \
		--build-c application.c --build-manifest application.bmxbuild "$source_file"
	awk '$1 == "link" { print $2 }' "$direct_root/application.bmxbuild" | LC_ALL=C sort > "$output_root/direct-$threading-ids.txt"
done
test -z "$(comm -12 "$output_root/direct-single-ids.txt" "$output_root/direct-threaded-ids.txt")"

echo "bcc2 generic configuration-cache regression passed"
