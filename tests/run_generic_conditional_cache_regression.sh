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
cp "$fixture_dir/generic_conditional_cache_app.bmx" "$source_file"

case "$(uname -s)" in
	Darwin) target_value=1000 ;;
	Linux) target_value=2000 ;;
	MINGW*|MSYS*|CYGWIN*) target_value=3000 ;;
	*) echo "unsupported native conditional-test host: $(uname -s)" >&2; exit 1 ;;
esac

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
	mode=$2
	manifest=$(find "$output_root/.bmx" -maxdepth 1 -name "app.bmx.console.$mode.*.bmxbuild" -type f)
	test -f "$manifest"
	grep -E '^(file generic-specialization-c|link) ' "$manifest" > "$output_root/$label-manifest.txt"
	awk '$1 == "link" { print $2 }' "$manifest" | LC_ALL=C sort > "$output_root/$label-ids.txt"
}

build_native()
{
	label=$1
	mode=$2
	expected=$3
	shift 3
	application="$output_root/app-$label"
	"$bmk" makeapp -bcc2 -single -t console "$@" -o "$application" "$source_file"
	test "$(run_application "$application")" = "$expected"
	snapshot_manifest "$label" "$mode"
}

build_native debug-default debug $((target_value + 121))
build_native release-default release $((target_value + 221)) -r
test -z "$(comm -12 "$output_root/debug-default-ids.txt" "$output_root/release-default-ids.txt")"

# Returning to the first conditional environment after a timestamp-only touch
# must reuse its retained specialization C and objects. The next identical
# build must then be quiet.
touch "$source_file"
return_output=$("$bmk" makeapp -bcc2 -single -t console -o "$output_root/app-debug-default" "$source_file")
if printf '%s' "$return_output" | grep -q 'Compiling generic specialization'
then
	echo "returning to a cached conditional environment recompiled specializations" >&2
	exit 1
fi
test "$(run_application "$output_root/app-debug-default")" = "$((target_value + 121))"
quiet_output=$("$bmk" makeapp -bcc2 -single -t console -o "$output_root/app-debug-default" "$source_file")
if printf '%s' "$quiet_output" | grep -Eq 'Processing:app|Compiling generic specialization|Compiling:app|Linking:app-debug-default'
then
	echo "unchanged conditional environment was rebuilt" >&2
	exit 1
fi

compile_direct()
{
	label=$1
	platform=$2
	architecture=$3
	mode=$4
	threading=$5
	definitions=$6
	direct_root="$output_root/direct-$label"
	set -- "$compiler" --emit-build "--$mode" "--$threading" \
		--platform "$platform" --arch "$architecture" --app-type console \
		--framework brl.standardio --sdk "$sdk_root" -o "$direct_root" \
		--build-c application.c --build-manifest application.bmxbuild
	if test -n "$definitions"
	then
		set -- "$@" --user-defs "$definitions"
	fi
	"$@" "$source_file"
	awk '$1 == "link" { print $2 }' "$direct_root/application.bmxbuild" | LC_ALL=C sort > "$output_root/direct-$label-ids.txt"
}

compile_direct macos-feature macos arm64 debug threaded feature=1
grep -R -Eq '= 100;' "$output_root/direct-macos-feature/.generics"
grep -R -Eq '= 1;' "$output_root/direct-macos-feature/.generics"
grep -R -Eq '= 10;' "$output_root/direct-macos-feature/.generics"
grep -R -Eq '= 1000;' "$output_root/direct-macos-feature/.generics"

compile_direct macos-default macos arm64 debug threaded ''
grep -R -Eq '= 20;' "$output_root/direct-macos-default/.generics"

compile_direct macos-single macos arm64 debug single-threaded feature=1
grep -R -Eq '= 2;' "$output_root/direct-macos-single/.generics"

compile_direct win32-default win32 x64 release single-threaded ''
grep -R -Eq 'return 200;' "$output_root/direct-win32-default/.generics"
grep -R -Eq 'return 2;' "$output_root/direct-win32-default/.generics"
grep -R -Eq 'return 20;' "$output_root/direct-win32-default/.generics"
grep -R -Eq 'return 3000;' "$output_root/direct-win32-default/.generics"

for left in macos-feature macos-default macos-single win32-default
do
	for right in macos-feature macos-default macos-single win32-default
	do
		if test "$left" = "$right"
		then
			continue
		fi
		test -z "$(comm -12 "$output_root/direct-$left-ids.txt" "$output_root/direct-$right-ids.txt")"
	done
done

echo "bcc2 generic conditional-cache regression passed"
