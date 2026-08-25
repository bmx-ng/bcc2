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
module_root="$sdk_root/mod/bcc2reproducibilitytest.mod"
module_dir="$module_root/owner.mod"

test ! -e "$output_root"
if test -e "$module_root"
then
	echo "temporary reproducibility-test module already exists: $module_root" >&2
	exit 1
fi

cleanup_module()
{
	rm -rf "$module_root"
}
trap cleanup_module 0 HUP INT TERM

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

snapshot_artifacts()
{
	root=$1
	result=$2
	find "$root" -type f \( \
		-name '*.i' -o \
		-name '*.bmxgt' -o \
		-name '*.c' -path '*/.generics/*' -o \
		-name '*.bmxbuild' \
	\) -print | LC_ALL=C sort | while IFS= read -r artifact
	do
		relative=${artifact#"$root"/}
		set -- $(cksum "$artifact")
		printf '%s %s %s\n' "$relative" "$1" "$2"
	done > "$result"
}

mkdir -p "$output_root/snapshots" "$module_dir"
cp "$fixture_dir/module_generic_reproducibility_owner.bmx" "$module_dir/owner.bmx"

"$bmk" makemods -a -bcc2 -r Bcc2ReproducibilityTest.Owner
module_interface=$(find "$module_dir" -maxdepth 1 -name 'owner.release.*.i' -type f)
test -f "$module_interface"
test "$(find "$module_dir/.generics/templates" -name '*.bmxgt' -type f | wc -l | tr -d ' ')" -ge 2
test "$(find "$module_dir/.generics" -name '*.c' -type f | wc -l | tr -d ' ')" -ge 1
test -z "$(find "$module_dir/.generics" -name '*.c' -type f ! -path '*/.generics/units/*' -print)"
snapshot_artifacts "$module_dir" "$output_root/snapshots/module-first.txt"

"$bmk" cleanmods Bcc2ReproducibilityTest.Owner
"$bmk" makemods -a -bcc2 -r Bcc2ReproducibilityTest.Owner
snapshot_artifacts "$module_dir" "$output_root/snapshots/module-second.txt"
cmp "$output_root/snapshots/module-first.txt" "$output_root/snapshots/module-second.txt"

build_application()
{
	root=$1
	mkdir -p "$root"
	cp "$fixture_dir/module_generic_reproducibility_app.bmx" "$root/app.bmx"
	"$bmk" makeapp -a -bcc2 -single -r -o "$root/generic-reproducibility" "$root/app.bmx"
	test "$(run_application "$root/generic-reproducibility")" = "generic-reproducibility-ok"
}

application_root="$output_root/application"
build_application "$application_root"
test "$(find "$application_root/.bmx/.generics" -name '*.c' -type f | wc -l | tr -d ' ')" -ge 2
test -z "$(find "$application_root/.bmx/.generics" -name '*.c' -type f ! -path '*/.generics/units/*' -print)"
snapshot_artifacts "$application_root" "$output_root/snapshots/application-first.txt"

rm -rf "$application_root/.bmx"
rm -f "$application_root/generic-reproducibility" "$application_root/generic-reproducibility.exe"
"$bmk" makeapp -a -bcc2 -single -r -o "$application_root/generic-reproducibility" "$application_root/app.bmx"
test "$(run_application "$application_root/generic-reproducibility")" = "generic-reproducibility-ok"
snapshot_artifacts "$application_root" "$output_root/snapshots/application-second.txt"
cmp "$output_root/snapshots/application-first.txt" "$output_root/snapshots/application-second.txt"

relocated_root="$output_root/relocated"
build_application "$relocated_root"
find "$application_root/.bmx/.generics" -name '*.c' -type f -exec basename {} \; | LC_ALL=C sort > "$output_root/snapshots/application-names.txt"
find "$relocated_root/.bmx/.generics" -name '*.c' -type f -exec basename {} \; | LC_ALL=C sort > "$output_root/snapshots/relocated-names.txt"
comm -12 "$output_root/snapshots/application-names.txt" "$output_root/snapshots/relocated-names.txt" > "$output_root/snapshots/shared-names.txt"
test "$(wc -l < "$output_root/snapshots/shared-names.txt" | tr -d ' ')" -ge 2
while IFS= read -r shared_name
do
	application_artifact=$(find "$application_root/.bmx/.generics" -name "$shared_name" -type f)
	relocated_artifact=$(find "$relocated_root/.bmx/.generics" -name "$shared_name" -type f)
	cmp "$application_artifact" "$relocated_artifact"
done < "$output_root/snapshots/shared-names.txt"
if cmp -s "$output_root/snapshots/application-names.txt" "$output_root/snapshots/relocated-names.txt"
then
	echo "relocated application did not distinguish source-owned generic identities" >&2
	exit 1
fi
if grep -R -F "$application_root" "$relocated_root/.bmx/.generics" >/dev/null
then
	echo "relocated generic artifacts retained the original application root" >&2
	exit 1
fi

cleanup_module
trap - 0 HUP INT TERM

echo "bcc2 generic reproducibility regression passed"
