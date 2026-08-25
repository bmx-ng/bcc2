#!/bin/sh
set -eu

compiler_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
compiler="$compiler_dir/$(basename -- "$1")"
sdk_root=$(CDPATH= cd -- "$2" && pwd)
mkdir -p "$3"
output_root=$(CDPATH= cd -- "$3" && pwd)
target_platform=${4:-}
target_architecture=${5:-}
if [ -z "$target_platform" ]; then
	case $(uname -s) in
		Darwin) target_platform=macos ;;
		Linux) target_platform=linux ;;
		MINGW*|MSYS*|CYGWIN*) target_platform=win32 ;;
		*) echo "unable to infer compiler target platform" >&2; exit 1 ;;
	esac
fi
if [ -z "$target_architecture" ]; then
	case $(uname -m) in
		arm64|aarch64) target_architecture=arm64 ;;
		x86_64|amd64) target_architecture=x64 ;;
		i386|i686) target_architecture=x86 ;;
		*) echo "unable to infer compiler target architecture" >&2; exit 1 ;;
	esac
fi
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
source_path="$fixture_dir/compiler_generic_build.bmx"
one_shot_root="$output_root/one-shot"
engine_root="$output_root/engine"

mkdir -p "$one_shot_root" "$engine_root"

test "$("$compiler" | tr -d '\r')" = "bcc Release Version 1.00"
test "$("$compiler" --version | tr -d '\r')" = "bcc Release Version 1.00"

one_shot_output=$("$compiler" \
	--emit-build \
	--release \
	--platform "$target_platform" \
	--arch "$target_architecture" \
	--sdk "$sdk_root" \
	-o "$one_shot_root" \
	--build-c application.c \
	--build-manifest application.bmxbuild \
	"$source_path")
test -z "$one_shot_output"

encode()
{
	printf '%s' "$1" | base64 | tr -d '\r\n'
}

request="compile 1 15"
for argument in \
	--emit-build \
	--release \
	--platform "$target_platform" \
	--arch "$target_architecture" \
	--sdk "$sdk_root" \
	-o "$engine_root" \
	--build-c application.c \
	--build-manifest application.bmxbuild \
	"$source_path"
do
	request="$request $(encode "$argument")"
done

invalidate_request="invalidate 2 1 $(encode "$engine_root/application.i")"
printf '%s\n%s\n%s\nshutdown\n' "$request" "$invalidate_request" "$request" | "$compiler" --engine | tr -d '\r' > "$output_root/protocol.out"

test "$(grep -c '^bcc2-engine 2$' "$output_root/protocol.out" | tr -d ' ')" -eq 1
test "$(grep -c '^result 1 0 0$' "$output_root/protocol.out" | tr -d ' ')" -eq 2
test "$(grep -c '^end 1$' "$output_root/protocol.out" | tr -d ' ')" -eq 2
grep -q '^invalidated 2 1$' "$output_root/protocol.out"
grep -q '^shutdown$' "$output_root/protocol.out"

diff -ru --exclude='*.bmxbuild' "$one_shot_root" "$engine_root"
sed "s#$one_shot_root#ROOT#g" "$one_shot_root/application.bmxbuild" > "$output_root/one-shot.manifest"
sed "s#$engine_root#ROOT#g" "$engine_root/application.bmxbuild" > "$output_root/engine.manifest"
cmp "$output_root/one-shot.manifest" "$output_root/engine.manifest"

# Exercise bounded response framing with a diagnostic larger than the
# Pub.FreeProcess line buffer used by bmk.
long_argument="-$(printf '%05000d' 0)"
long_request="compile 2 2 $(encode --emit-build) $(encode "$long_argument")"
printf '%s\nshutdown\n' "$long_request" | "$compiler" --engine | tr -d '\r' > "$output_root/long-response.out"
grep -q '^result 2 2 ' "$output_root/long-response.out"
test "$(grep -c '^data 2 ' "$output_root/long-response.out" | tr -d ' ')" -gt 1
grep -q '^end 2$' "$output_root/long-response.out"

# Source diagnostics retain the same document-local line and column through
# both the one-shot and persistent-engine reporting paths.
invalid_source="$output_root/invalid-location.bmx"
printf 'SuperStrict\nLocal first:Int = 1 => 0\nLocal second:Int = 1 =< 0\n' > "$invalid_source"
invalid_one_shot="$output_root/invalid-one-shot.out"
if "$compiler" \
	--emit-build \
	--release \
	--platform "$target_platform" \
	--arch "$target_architecture" \
	--sdk "$sdk_root" \
	-o "$output_root/invalid-one-shot" \
	--build-c application.c \
	--build-manifest application.bmxbuild \
	"$invalid_source" > "$invalid_one_shot" 2>&1
then
	echo "invalid one-shot source unexpectedly compiled" >&2
	exit 1
fi
grep -Fq "$invalid_source:2:22: error BMX2101:" "$invalid_one_shot"
grep -Fq "$invalid_source:3:23: error BMX2101:" "$invalid_one_shot"

invalid_request="compile 3 15"
for argument in \
	--emit-build \
	--release \
	--platform "$target_platform" \
	--arch "$target_architecture" \
	--sdk "$sdk_root" \
	-o "$output_root/invalid-engine" \
	--build-c application.c \
	--build-manifest application.bmxbuild \
	"$invalid_source"
do
	invalid_request="$invalid_request $(encode "$argument")"
done
printf '%s\nshutdown\n' "$invalid_request" | "$compiler" --engine | tr -d '\r' > "$output_root/invalid-engine.out"
grep -q '^result 3 1 ' "$output_root/invalid-engine.out"
decoded_invalid_output="$output_root/invalid-engine-decoded.out"
awk '$1 == "data" && $2 == "3" { print $3 }' "$output_root/invalid-engine.out" | while IFS= read -r fragment
do
	printf '%s' "$fragment" | base64 --decode
done > "$decoded_invalid_output"
grep -Fq "$invalid_source:2:22: error BMX2101:" "$decoded_invalid_output"
grep -Fq "$invalid_source:3:23: error BMX2101:" "$decoded_invalid_output"

echo "bcc engine protocol regression passed"
