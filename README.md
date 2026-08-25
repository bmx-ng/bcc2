# bcc2

`bcc2` is the next-generation BlitzMax NG compiler. The repository also
contains `bls`, the BlitzMax language server used by editor integrations.

The installed compiler executable remains named `bcc` so that it works with
`bmk2` and the established BlitzMax SDK layout.

## Repository layout

```text
compiler/  Compiler command-line application and persistent build engine
lsp/       Language-server command-line application
tests/     Compiler, language-model, LSP, and runtime regression tests
examples/  Small programs demonstrating bcc2 language features
```

The compiler and language server use the `BlitzMax.Compiler`,
`BlitzMax.Language`, and `BlitzMax.LSP` modules from the matching
`blitzmax.mod` source tree.

## Building

A matching bmk2 and BlitzMax NG SDK are required. From this repository, build
the release executables with:

```sh
/path/to/bmk makeapp -a -r -h -o /path/to/sdk/bin/bcc compiler/bcc.bmx
/path/to/bmk makeapp -a -r -h -o /path/to/sdk/bin/bls lsp/bls.bmx
```

Verify the compiler installation with:

```sh
/path/to/sdk/bin/bcc --version
```

The compiler reports release version `1.00`. Build-manager compatibility is
defined by the matched bmk2/compiler protocol and generated-artifact formats,
so bcc2 and bmk2 should be installed and updated together.

## Language support

bcc2 preserves ordinary BlitzMax NG source compatibility while adding the new
compiler architecture and language work developed for this toolchain,
including generic Types and routines, Closures, resumable `Yield` generators,
sequence optimisations, EachIn deconstruction, and arbitrary-depth module
namespaces.

The compiler pipeline keeps semantic analysis, typed intermediate
representation, and native code generation as separate stages. The language
server shares the parser and semantic model with the compiler rather than
maintaining an independent interpretation of the language.

## Tests

Focused tests are ordinary BlitzMax applications. For example:

```sh
/path/to/bmk makeapp -a -r -h -o /tmp/test_compiler_ir tests/test_compiler_ir.bmx
/tmp/test_compiler_ir
```

The `tests/run_*.sh` scripts provide runtime, module-boundary, incremental-build,
debugger, and generated-matrix coverage. They accept explicit SDK, compiler,
build-manager, and output paths according to the needs of each test so that
validation can run without modifying a production SDK.
