# Generic template lowering coverage audit

This inventory compares the bound kinds in `language.mod/semantic_model.bmx`, the typed IR in `compiler.mod/ir_model.bmx`, and the builder, codec, specialization lowerer, and C emitter in `compiler.mod/generic_specialization.bmx` and `language.mod/generic_template_codec.bmx`. It describes format 34 and the accompanying compiler changes. The generic artifact format is unchanged: raw pointer indexing uses the existing element node, and an explicitly bound generic Method reference uses the existing call and closure records.

| Bound operation | Template representation | Current limit |
| --- | --- | --- |
| Literal, symbol, member, Self | Literal, name, member, Self | Closed types and stable published linkage are required across source boundaries. |
| Call and routine reference | Call or name; bound Method references become closure literals with one receiver capture | Explicit type arguments on bound generic Method references are retained. A bound receiver expression must currently be Self, a parameter, or a Local. |
| Index | Element, slice, length, or operator call | String, managed Array, StaticArray, and supported raw pointer elements are covered. Range indexing becomes a slice only for a stable receiver and stable Range value. |
| Unary, binary, conversion | Operator, conversion, or resolved call | Numeric capabilities and pointer/managed conversion rules are checked after specialization. The typed IR's String concat, compare, truth, identity, pointer arithmetic, and enum operations are canonicalized here. |
| New, Array literal, Function literal | New, Array literal, Function literal | Closed ABI and allocation support vary by desktop and embedded target. |
| Passthrough | Child expression | Parentheses do not require a serialized node. |
| Omitted argument | Resolved default value | An unresolved omitted argument is diagnosed before publication. |
| Error expression | None | Publication is rejected. |

| Bound statement | Template representation | Current limit |
| --- | --- | --- |
| Block, declaration, assignment, expression, return | Shared block/declaration/assignment/expression/return nodes | Scalar compound assignment needs supported numeric operands. Managed Array concatenation assignment currently requires a stable Local or field target. |
| Throw, Assert, Release, Yield | Dedicated nodes | Runtime and target capability checks remain in the lowerer. |
| If, While, Repeat, For, Select | Branch, loop, select, and loop-control nodes | EachIn protocol and iterator forms have target-specific guards. |
| Try, Using | Dedicated nodes with cleanup edges | Iterator retention and cleanup routing are checked separately for desktop and embedded. |
| Data, ReadData, RestoreData | Data node with operation identity | Target conversion and addressability checks remain in the emitter. |
| Conditional directive | None | Configuration must be applied before template publication. |
| Error statement | None | Publication is rejected. |

The typed IR has more operation kinds than the 30 template node kinds because templates preserve semantic operations before specializing types. For example, the typed IR's separate pointer, String, StaticArray, and managed Array element expressions share `TEMPLATE_NODE_ARRAY_ELEMENT`; the emitter chooses the closed operation from the receiver type. `IR_EXPRESSION_MATERIALIZE` is an evaluation-order implementation detail, not a source operation or serialized template kind. The codec checks node arity and version gates; it does not itself decide whether a closed ABI is supported.

Remaining deliberate limits and gaps:

* A bound Method receiver produced by a call, member chain, or index needs a per-reference evaluated capture. The current closure environment captures lexical cells, so treating such a receiver as a normal capture would change evaluation and lifetime behavior. The builder diagnoses it.
* Generic Type implementation of ordinary imported Interfaces has only a hard-coded `ICloseable` runtime table. General tables require method-layout and slot ABI metadata for each imported Interface, including inherited slots; the current type reference records only the runtime ABI identity. The emitter diagnoses other cases instead of guessing an ABI. Embedded generic Type specialization rejects ordinary imported Interfaces entirely.
* Range slicing calls the start and end bound resolvers with the same Range value. The builder requires stable expressions so neither the Range nor receiver gains extra side effects.
* Embedded specialization admits narrower value and operation sets, including no raw pointer ABI in the generic Type/routine baseline. Those guards remain separate from desktop support.

Regression coverage is in the pointer indexing runtime and pointer/Method source-boundary scripts, the bound Method runtime script, and the generic production matrix. These exercise debug and release builds, Include, quoted source imports, compiled modules, scalar and nested pointers, and single evaluation of pointer/index expressions.
