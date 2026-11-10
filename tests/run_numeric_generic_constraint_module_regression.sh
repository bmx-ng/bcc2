#!/bin/sh
set -eu

bmk=$1
output_root=$2
bmk_dir=$(CDPATH= cd -- "$(dirname -- "$bmk")" && pwd)
sdk_root=$(CDPATH= cd -- "$bmk_dir/.." && pwd)
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
module_root="$sdk_root/mod/bcc2numericconstrainttest.mod"
module_dir="$module_root/owner.mod"
application="$output_root/numeric-generic-module"

if test -e "$module_root"; then
	echo "temporary numeric constraint module already exists: $module_root" >&2
	exit 1
fi
cleanup_module() { rm -rf "$module_root"; }
trap cleanup_module 0 HUP INT TERM
mkdir -p "$module_dir" "$output_root"
cp "$fixture_dir/module_numeric_constraint_owner.bmx" "$module_dir/owner.bmx"
"$bmk" makemods -a -r Bcc2NumericConstraintTest.Owner
"$bmk" makeapp -a -r -o "$application" "$fixture_dir/numeric_generic_module_app.bmx"
result=$("$application" | tail -n 1 | tr -d '\r')
test "$result" = "numeric-generic-module-ok"
interface=$(find "$module_dir" -maxdepth 1 -name 'owner.release.*.i' -type f)
test -f "$interface"
grep -q 'Where T Is Numeric' "$interface"
grep -q 'Where T Is Integral' "$interface"
cat > "$output_root/rejected-type.bmx" <<'SOURCE'
SuperStrict
Import Bcc2NumericConstraintTest.Owner
Local bad:SIntegralBox<Float>
SOURCE
if "$bmk" makeapp -a -r -o "$output_root/rejected-type" "$output_root/rejected-type.bmx" > "$output_root/rejected-type.log" 2>&1; then
	echo "imported Integral type accepted Float" >&2
	exit 1
fi
grep -q 'BMX3209' "$output_root/rejected-type.log"
cat > "$output_root/rejected-routine.bmx" <<'SOURCE'
SuperStrict
Import Bcc2NumericConstraintTest.Owner
Local bad:String = ModuleClamp<String>("a", "a", "z")
SOURCE
if "$bmk" makeapp -a -r -o "$output_root/rejected-routine" "$output_root/rejected-routine.bmx" > "$output_root/rejected-routine.log" 2>&1; then
	echo "imported Numeric routine accepted String" >&2
	exit 1
fi
grep -q 'BMX3302' "$output_root/rejected-routine.log"
echo "numeric generic constraint module regression passed"
