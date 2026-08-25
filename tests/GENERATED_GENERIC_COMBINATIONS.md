# Generated generic combinations

`run_generated_generic_combinations.sh` creates and validates deterministic,
focused pairwise families of generic BlitzMax programs. It complements the
handwritten regression fixtures without combining every language feature into
one difficult-to-diagnose random program.

The baseline family combines these dimensions:

- `Int` and `String` payloads;
- plain, inherited, and Interface-backed generic owners;
- field, Array, and captured `Closure` storage;
- direct calls, typed `EachIn`, and nested generic routine results;
- single-file and relative-import application boundaries.

The core-values family combines:

- `Int`, `Long`, `Double`, `String`, typed Object, erased `Object`, Interface,
  Struct, Array, and nested-generic payloads;
- single-parameter boxes, two-parameter pairs, and nested boxes;
- transport through a generic field, generic identity routine, or Array.

The dispatch family combines:

- `Int`, `String`, typed Object, and Struct payloads;
- derived, generic-base, and generic-Interface receiver views;
- direct invocation, a generic routine, and a generic holder.

Every dispatch case verifies that the derived override actually ran, rather
than accepting a plausible value returned through the wrong static path.

The callable family combines:

- `Int`, `String`, typed Object, and Struct return values;
- non-capturing, local, generic-argument, and nested captures;
- local, generic-field, generic-Array, and generic-routine transport;
- value-returning and Closure-returning Closure signatures.

The module-boundary family builds one temporary producer module, verifies its
compact interface and source-free generic templates, and then combines:

- `Int`, `String`, typed Object, Struct, and Closure payloads;
- generic fields, routines, inheritance, and captured Closure APIs;
- direct, nested-box, and two-parameter pair shapes.

The temporary module is removed from the SDK on success or failure. A failing
consumer's generated source and build log remain in the requested output tree.

The lifecycle family combines:

- String, Array, typed Object, Struct, and Closure values;
- default, explicit, and reassigned initialization;
- locals, generic fields, globals, and generic Closures escaping their creator;
- straight-line, branch, and exception control flow.

Default managed values are checked through their normal runtime invariants:
empty Strings and Arrays, Null object and Closure values, and zeroed Structs.

The structural-protocol family combines:

- small and deliberately wide generic Types;
- direct, derived, and deep inheritance;
- `IIterable<T>`, direct `IIterator<T>`, and legacy object-enumerator shapes;
- one or multiple generic Interfaces;
- single-file and relative-import boundaries.

The contract family combines `Int` and `String` payloads with base, explicit
derived, overloaded derived, and inherited-only constructors;
index/binary/assignment operators; one or multiple generic Interfaces; and
single-file or relative-import consumption. Inherited-only cases also dispatch
a derived override after construction so the test verifies the allocated
object retained its derived runtime class identity.

The dependency family builds two ordered imported source units and combines
String, Struct, Closure, and nested-generic payloads with generic fields,
routines, inheritance, Arrays, and captured Closures. Both explicit import
orders are exercised, including a generic declared in one source unit whose
ordinary Struct argument is owned by another source unit.

The cleanup family drives generic `EachIn` through normal completion, `Return`,
labelled `Continue`, and caught exceptions. It combines iterable and iterator
protocols with single and nested `Try`/`Finally` regions and verifies the exact
cleanup count at runtime.

After the generated programs, a deterministic incremental scenario builds a
generic Type containing a captured Closure, changes only its provider body,
and rebuilds without `-a`. It verifies the new result, removes one cached
specialization object, and confirms that a normal retry recreates it and still
runs correctly.

`run_generic_inherited_constructor_regression.sh` supplements the pairwise
cases with deep inheritance, optional arguments, implicit zero-argument
construction, overload shadowing, `Var` forwarding, and derived dispatch:

```sh
tests/run_generic_inherited_constructor_regression.sh ../BlitzMax-bcc2/bin/bmk /tmp/bcc2-inherited-constructors
```

Each family performs its own pairwise selection. A seed changes assignments
within every family, but features from unrelated families are not randomized
together.

Every pair of dimension values occurs in at least one positive program. Fixed
positive regressions retain useful failures found by earlier generated runs;
these currently cover inherited generic Closure storage combined with a nested
generic result, default Closure initialization, and a wide deeply inherited
generic iterable with multiple Interfaces. The corpus also contains curated
negative cases for arity, recursive Struct layout, and non-convergent
transformed recursion.

Run it with a self-built toolchain and an unused output directory:

```sh
tests/run_generated_generic_combinations.sh ../BlitzMax-bcc2/bin/bmk /tmp/bcc2-generated-generics
```

An optional third argument changes the deterministic selection seed. The seed,
manifest, generated sources, build logs, and executables remain in the output
directory. A failed case can therefore be rebuilt directly without regenerating
the corpus.

To exercise an inclusive range of seeds, deleting each successful corpus while
retaining the first failure, use:

```sh
tests/run_generated_generic_seed_range.sh ../BlitzMax-bcc2/bin/bmk /tmp/bcc2-generated-range 1 10
```

The range runner stops immediately when a seed fails and reports the retained
seed directory. Existing seed directories are never overwritten.
