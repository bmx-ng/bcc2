# Generic template lowering coverage audit

This inventory compares the bound kinds in `language.mod/semantic_model.bmx`, the typed IR in `compiler.mod/ir_model.bmx`, and the builder, codec, specialization lowerer, and C emitter in `compiler.mod/generic_specialization.bmx` and `language.mod/generic_template_codec.bmx`. It describes format 35 and the accompanying compiler changes. Raw pointer indexing uses the existing element node, and an explicitly bound generic Method reference uses the existing call and closure records. Format 35 adds an initialized receiver capture for computed bound Method references and publishes ordinary Interface slot layouts with inherited descriptors; format 34 artifacts remain readable.

| Bound operation | Template representation | Current limit |
| --- | --- | --- |
| Literal, symbol, member, Self | Literal, name, member, Self | Closed types and stable published linkage are required across source boundaries. |
| Call and routine reference | Call or name; bound Method references become closure literals with one receiver capture | Explicit type arguments are retained. Computed receivers use a format-35 initialized capture and are evaluated once when the reference is formed. |
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

* Desktop generic Types emit ordinary Interface tables from published slot signatures, including inherited Interfaces and Var parameters. Embedded generic Type specialization still rejects ordinary imported Interfaces.
* Reading an ordinary Type field while forming a computed Method reference uses a stable getter emitted by the Type's owning source unit. This supports call chains, direct field reads and managed Array indexes across Include, quoted import and compiled-module boundaries. A field owned by an already imported ordinary Type has no published getter contract in its compact interface, so the builder diagnoses that case. Other generic field operations still need the Type's full layout or a dedicated accessor path.
* Range slicing calls the start and end bound resolvers with the same Range value. The builder requires stable expressions so neither the Range nor receiver gains extra side effects.
* Embedded specialization admits narrower value and operation sets, including no raw pointer ABI in the generic Type/routine baseline. Those guards remain separate from desktop support.
* Exploratory specializations using a source-defined Struct or Enum as a raw-pointer element still reach the ordinary C backend's `BMXC2020` scalar ABI diagnostic while it emits the surrounding generic signature. Scalar and nested-pointer elements pass the new runtime matrix; nominal pointer elements need separate signature-layout work.

Regression coverage is in the pointer indexing runtime and pointer/Method source-boundary scripts, the bound Method runtime script, and the generic production matrix. These exercise debug and release builds, Include, quoted source imports, compiled modules, scalar and nested pointers, computed receiver calls/chains/fields/indexes, and inherited ordinary Interface tables.
