# Closure stress examples

These small programs deliberately combine features at boundaries that are more
likely to expose compiler, runtime ABI, environment-lifetime, or source-free
generic-specialization bugs. Each program is independent so that one compiler
failure does not hide the remaining cases.

- `recursive_closures.bmx` creates both a self-referential Closure and two
  mutually recursive Closures. Their shared environment contains managed cycles.
- `nested_generic_snapshots.bmx` returns a Closure which returns fresh child
  Closures. It specializes for both `String` and an application-local Type.
- `generic_bound_closure_array.bmx` creates a generic Array whose elements are
  escaping managed Closures, each retaining a different application-local value.
- `generic_ranked_array_capture.bmx` captures one ranked generic Array in reader
  and writer Closures and checks that mutations remain shared.
- `generic_struct_state.bmx` captures a generic Struct containing a managed
  Array, mutates a field with `:+`, and reads the resulting state after escape.

Every example throws on failure and prints an `-ok` line on success.
