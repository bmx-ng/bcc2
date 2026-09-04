#!/usr/bin/env python3
"""Generate a deterministic pairwise corpus of valid and invalid generic programs."""

from __future__ import annotations

import argparse
import itertools
import random
from pathlib import Path


BASE_DIMENSIONS = {
    "payload": ("int", "string"),
    "owner": ("plain", "inherited", "interface"),
    "storage": ("field", "array", "closure"),
    "operation": ("roundtrip", "eachin", "nested"),
    "boundary": ("single", "imported"),
}

CORE_VALUE_DIMENSIONS = {
    "payload": (
        "int",
        "long",
        "double",
        "string",
        "typed-object",
        "object",
        "interface",
        "struct",
        "array",
        "nested-generic",
    ),
    "shape": ("box", "pair", "nested"),
    "flow": ("field", "routine", "array"),
}

DISPATCH_DIMENSIONS = {
    "payload": ("int", "string", "typed-object", "struct"),
    "receiver": ("derived", "base", "interface"),
    "flow": ("direct", "generic-routine", "generic-holder"),
}

CALLABLE_DIMENSIONS = {
    "payload": ("int", "string", "typed-object", "struct"),
    "capture": ("none", "local", "generic-argument", "nested"),
    "storage": ("local", "generic-field", "generic-array", "generic-routine"),
    "signature": ("value", "closure-result"),
}

BOUND_METHOD_DIMENSIONS = {
    "payload": (
        "int",
        "long",
        "double",
        "string",
        "typed-object",
        "object",
        "interface",
        "struct",
        "array",
        "nested-generic",
    ),
    "owner": ("ordinary", "generic", "generic-base"),
    "receiver": ("concrete", "interface", "factory", "implicit-self", "generic-routine"),
    "transport": ("local", "generic-field", "array", "argument", "returned", "nested"),
    "boundary": ("single", "imported"),
}

GENERIC_REFERENCE_DIMENSIONS = {
    "payload": (
        "int",
        "long",
        "double",
        "string",
        "typed-object",
        "object",
        "interface",
        "struct",
        "array",
        "nested-generic",
    ),
    "owner": ("free", "type-function", "generic-type-function"),
    "transport": ("direct", "local", "generic-field", "returned", "transitive"),
    "boundary": ("single", "imported"),
}

YIELD_DIMENSIONS = {
    "payload": (
        "int",
        "long",
        "double",
        "string",
        "typed-object",
        "object",
        "interface",
        "struct",
        "array",
        "nested-generic",
    ),
    "owner": ("free", "generic-type", "generic-base"),
    "flow": ("single", "loop", "branch-return", "nested-iterator", "using", "try-catch-finally", "capturing-closure", "yielding-closure", "static-array", "yield-from"),
    "consumption": ("exhaust", "early-close", "close-before-start"),
    "boundary": ("single", "imported"),
}

MODULE_BOUNDARY_DIMENSIONS = {
    "payload": ("int", "string", "typed-object", "struct", "closure"),
    "api": (
        "field",
        "routine",
        "routine-reference",
        "bound-method",
        "inheritance",
        "closure",
    ),
    "shape": ("direct", "nested", "pair"),
}

IMPORTED_CONSTRUCTOR_ARRAY_DIMENSIONS = {
    "payload": ("typed-object", "interface", "struct", "enum", "nested-generic"),
    "shape": ("vector", "jagged", "ranked"),
}

LIFECYCLE_DIMENSIONS = {
    "payload": ("string", "array", "typed-object", "struct", "closure"),
    "initialization": ("default", "explicit", "reassigned"),
    "storage": ("local", "generic-field", "global", "escaping-closure"),
    "control": ("straight", "branch", "exception"),
}

STRUCTURAL_PROTOCOL_DIMENSIONS = {
    "scale": ("small", "large"),
    "inheritance": ("direct", "derived", "deep"),
    "protocol": ("iterable", "iterator", "object-enumerator"),
    "interfaces": ("single", "multiple"),
    "boundary": ("single", "imported"),
}

CONTRACT_DIMENSIONS = {
    "payload": ("int", "string"),
    "constructor": (
        "base",
        "derived-default",
        "derived-overload",
        "inherited",
        "inherited-zero",
    ),
    "operator": ("index", "binary", "assignment"),
    "interfaces": ("single", "multiple"),
    "boundary": ("single", "imported"),
}

DEPENDENCY_DIMENSIONS = {
    "payload": ("string", "struct", "closure", "nested-generic"),
    "shape": ("fields", "routine", "inheritance"),
    "flow": ("direct", "array", "closure"),
    "import_order": ("left-first", "right-first"),
}

CLEANUP_DIMENSIONS = {
    "payload": ("int", "string"),
    "protocol": ("iterable", "iterator", "object-enumerator"),
    "transfer": ("normal", "return", "continue", "throw"),
    "nesting": ("single", "nested"),
}

MANAGED_CONVERSION_DIMENSIONS = {
    "payload": ("string", "typed-object", "interface", "array", "nested-generic"),
    "state": ("null", "valid", "incompatible"),
    "flow": ("direct", "routine", "generic-routine", "generic-field"),
    "consumer": ("truth", "length", "eachin"),
}


def pair_tokens(row: tuple[str, ...]) -> set[tuple[int, str, int, str]]:
    return {
        (left, row[left], right, row[right])
        for left in range(len(row))
        for right in range(left + 1, len(row))
    }


def select_pairwise(dimensions: dict[str, tuple[str, ...]], seed: int) -> list[tuple[str, ...]]:
    candidates = list(itertools.product(*dimensions.values()))
    uncovered = set().union(*(pair_tokens(row) for row in candidates))
    selected: list[tuple[str, ...]] = []
    randomizer = random.Random(seed)
    tie_break = {row: randomizer.random() for row in candidates}
    while uncovered:
        row = max(candidates, key=lambda item: (len(pair_tokens(item) & uncovered), tie_break[item]))
        covered = pair_tokens(row) & uncovered
        if not covered:
            raise RuntimeError("pairwise selection stopped before covering every feature pair")
        selected.append(row)
        uncovered -= covered
        candidates.remove(row)
    return selected


def payload_details(payload: str) -> tuple[str, str]:
    if payload == "int":
        return "Int", "41"
    return "String", '"pairwise"'


def storage_members(storage: str) -> str:
    if storage == "field":
        return """\tField item:T
\tMethod Store(value:T)
\t\titem = value
\tEnd Method
\tMethod Read:T()
\t\tReturn item
\tEnd Method"""
    if storage == "array":
        return """\tField items:T[]
\tMethod Store(value:T)
\t\titems = [value]
\tEnd Method
\tMethod Read:T()
\t\tReturn items[0]
\tEnd Method"""
    return """\tField callback:Closure<T()>
\tMethod Store(value:T)
\t\tLocal captured:T = value
\t\tcallback = Function()
\t\t\tReturn captured
\t\tEnd Function
\tEnd Method
\tMethod Read:T()
\t\tReturn callback()
\tEnd Method"""


def owner_declarations(owner: str, storage: str) -> str:
    members = storage_members(storage)
    if owner == "plain":
        return f"Type TCarrier<T>\n{members}\nEnd Type"
    if owner == "inherited":
        return f"Type TCarrierBase<T>\n{members}\nEnd Type\nType TCarrier<T> Extends TCarrierBase<T>\nEnd Type"
    return f"""Interface IReadable<T>
\tMethod Read:T()
End Interface
Type TCarrier<T> Implements IReadable<T>
{members}
End Type"""


COMMON_ITERATOR = """Type TGeneratedIterator<T> Implements IIterator<T>
\tField values:T[]
\tField index:Int = -1
\tMethod New(values:T[])
\t\tSelf.values = values
\tEnd Method
\tMethod MoveNext:Int()
\t\tindex :+ 1
\t\tReturn index < values.length
\tEnd Method
\tMethod Current:T()
\t\tReturn values[index]
\tEnd Method
End Type

Type TGeneratedValues<T>
\tField values:T[]
\tMethod New(value:T)
\t\tvalues = [value]
\tEnd Method
\tMethod ObjectEnumerator:TGeneratedIterator<T>()
\t\tReturn New TGeneratedIterator<T>(values)
\tEnd Method
End Type"""


def declarations_source(owner: str, storage: str) -> str:
    return f"""{owner_declarations(owner, storage)}

Type TBox<T>
\tField value:T
End Type

Function Wrap<T>:TBox<T>(value:T)
\tLocal box:TBox<T> = New TBox<T>
\tbox.value = value
\tReturn box
End Function

{COMMON_ITERATOR}
"""


def provider_source(owner: str, storage: str) -> str:
    return "SuperStrict\nImport BRL.Blitz\n\n" + declarations_source(owner, storage)


def operation_source(operation: str, type_name: str, value: str) -> str:
    setup = f"""Local carrier:TCarrier<{type_name}> = New TCarrier<{type_name}>
carrier.Store({value})
Local result:{type_name}"""
    if operation == "roundtrip":
        body = "result = carrier.Read()"
    elif operation == "eachin":
        body = f"""Local values:{type_name}[] = [carrier.Read()]
Local iterator:TGeneratedIterator<{type_name}> = New TGeneratedIterator<{type_name}>(values)
For Local item:{type_name} = EachIn iterator
\tresult = item
Next"""
    else:
        body = f"""Local box:TBox<TCarrier<{type_name}>> = Wrap<TCarrier<{type_name}>>(carrier)
result = box.value.Read()"""
    return setup + "\n" + body


def application_source(case_id: str, row: tuple[str, ...], imported: bool) -> str:
    payload, owner, storage, operation, _boundary = row
    type_name, value = payload_details(payload)
    imports = "Framework BRL.Blitz\nImport BRL.StandardIO"
    if imported:
        imports += f'\nImport "{case_id}_provider.bmx"'
        declarations = ""
    else:
        declarations = "\n\n" + declarations_source(owner, storage)
    operation_body = operation_source(operation, type_name, value)
    return f"""SuperStrict
{imports}{declarations}

{operation_body}
If result <> {value} Then Throw "{case_id}: unexpected result"
Print "generic-combination-ok:{case_id}"
"""


CORE_VALUE_DECLARATIONS = """Type TPayloadObject
\tField number:Int
End Type

Interface IPayload
\tMethod Read:Int()
End Interface

Type TPayloadInterface Implements IPayload
\tField number:Int
\tMethod Read:Int()
\t\tReturn number
\tEnd Method
End Type

Struct SPayload
\tField number:Int
End Struct

Type TValueBox<T>
\tField value:T
End Type

Type TValuePair<K, V>
\tField first:K
\tField second:V
End Type

Type TValueFlow<T>
\tField item:T
\tMethod Store(value:T)
\t\titem = value
\tEnd Method
\tMethod Read:T()
\t\tReturn item
\tEnd Method
End Type

Function MakeValueBox<T>:TValueBox<T>(value:T)
\tLocal box:TValueBox<T> = New TValueBox<T>
\tbox.value = value
\tReturn box
End Function

Function MakeValuePair<K, V>:TValuePair<K, V>(first:K, second:V)
\tLocal pair:TValuePair<K, V> = New TValuePair<K, V>
\tpair.first = first
\tpair.second = second
\tReturn pair
End Function

Function ValueIdentity<T>:T(value:T)
\tReturn value
End Function"""


def core_payload_source(payload: str, case_id: str) -> tuple[str, str, str]:
    if payload == "int":
        return "Int", "Local payload:Int = 41", f'If result <> 41 Then Throw "{case_id}: Int payload"'
    if payload == "long":
        return "Long", "Local payload:Long = 41:Long", f'If result <> 41:Long Then Throw "{case_id}: Long payload"'
    if payload == "double":
        return "Double", "Local payload:Double = 41.5", f'If result <> 41.5 Then Throw "{case_id}: Double payload"'
    if payload == "string":
        return "String", 'Local payload:String = "core-value"', f'If result <> "core-value" Then Throw "{case_id}: String payload"'
    if payload == "typed-object":
        return (
            "TPayloadObject",
            "Local payload:TPayloadObject = New TPayloadObject\npayload.number = 41",
            f'If result = Null Or result.number <> 41 Then Throw "{case_id}: typed Object payload"',
        )
    if payload == "object":
        return (
            "Object",
            "Local objectPayload:TPayloadObject = New TPayloadObject\nobjectPayload.number = 41\nLocal payload:Object = objectPayload",
            f'Local typedResult:TPayloadObject = TPayloadObject(result)\nIf typedResult = Null Or typedResult.number <> 41 Then Throw "{case_id}: Object payload"',
        )
    if payload == "interface":
        return (
            "IPayload",
            "Local interfacePayload:TPayloadInterface = New TPayloadInterface\ninterfacePayload.number = 41\nLocal payload:IPayload = interfacePayload",
            f'If result = Null Or result.Read() <> 41 Then Throw "{case_id}: Interface payload"',
        )
    if payload == "struct":
        return (
            "SPayload",
            "Local payload:SPayload\npayload.number = 41",
            f'If result.number <> 41 Then Throw "{case_id}: Struct payload"',
        )
    if payload == "array":
        return (
            "Int[]",
            "Local payload:Int[] = [20, 21]",
            f'If result = Null Or result.length <> 2 Or result[0] + result[1] <> 41 Then Throw "{case_id}: Array payload"',
        )
    return (
        "TValueBox<Int>",
        "Local payload:TValueBox<Int> = MakeValueBox<Int>(41)",
        f'If result = Null Or result.value <> 41 Then Throw "{case_id}: nested generic payload"',
    )


def core_shape_source(shape: str, payload_type: str) -> tuple[str, str, str, str]:
    if shape == "box":
        return (
            f"TValueBox<{payload_type}>",
            f"MakeValueBox<{payload_type}>(payload)",
            "resultCarrier.value",
            "",
        )
    if shape == "pair":
        return (
            f"TValuePair<String, {payload_type}>",
            f'MakeValuePair<String, {payload_type}>("key", payload)',
            "resultCarrier.second",
            'If resultCarrier.first <> "key" Then Throw "pair key was not retained"',
        )
    return (
        f"TValueBox<TValueBox<{payload_type}>>",
        f"MakeValueBox<TValueBox<{payload_type}>>(MakeValueBox<{payload_type}>(payload))",
        "resultCarrier.value.value",
        "",
    )


def core_flow_source(flow: str, carrier_type: str) -> str:
    if flow == "field":
        return f"""Local flow:TValueFlow<{carrier_type}> = New TValueFlow<{carrier_type}>
flow.Store(carrier)
Local resultCarrier:{carrier_type} = flow.Read()"""
    if flow == "routine":
        return f"Local resultCarrier:{carrier_type} = ValueIdentity<{carrier_type}>(carrier)"
    return f"""Local carriers:{carrier_type}[] = [carrier]
Local resultCarrier:{carrier_type} = carriers[0]"""


def core_value_application_source(case_id: str, row: tuple[str, ...]) -> str:
    payload, shape, flow = row
    payload_type, payload_initialization, assertion = core_payload_source(payload, case_id)
    carrier_type, carrier_value, result_expression, shape_assertion = core_shape_source(shape, payload_type)
    flow_source = core_flow_source(flow, carrier_type)
    if shape_assertion:
        shape_assertion += "\n"
    return f"""SuperStrict
Framework BRL.Blitz
Import BRL.StandardIO

{CORE_VALUE_DECLARATIONS}

{payload_initialization}
Local carrier:{carrier_type} = {carrier_value}
{flow_source}
{shape_assertion}Local result:{payload_type} = {result_expression}
{assertion}
Print "generic-combination-ok:{case_id}"
"""


DISPATCH_DECLARATIONS = """Global dispatchCount:Int

Type TPayloadObject
\tField number:Int
End Type

Struct SPayload
\tField number:Int
End Struct

Interface IDispatch<T>
\tMethod Read:T()
End Interface

Type TDispatchBase<T>
\tField item:T
\tMethod Store(value:T)
\t\titem = value
\tEnd Method
\tMethod Read:T()
\t\tReturn item
\tEnd Method
End Type

Type TDispatchDerived<T> Extends TDispatchBase<T> Implements IDispatch<T>
\tMethod Read:T() Override
\t\tdispatchCount :+ 1
\t\tReturn Super.Read()
\tEnd Method
End Type

Type TDispatchHolder<T>
\tField item:T
End Type

Function ReadDerived<T>:T(receiver:TDispatchDerived<T>)
\tReturn receiver.Read()
End Function

Function ReadBase<T>:T(receiver:TDispatchBase<T>)
\tReturn receiver.Read()
End Function

Function ReadInterface<T>:T(receiver:IDispatch<T>)
\tReturn receiver.Read()
End Function"""


def dispatch_receiver_source(receiver: str, payload_type: str) -> tuple[str, str]:
    if receiver == "derived":
        return f"TDispatchDerived<{payload_type}>", "ReadDerived"
    if receiver == "base":
        return f"TDispatchBase<{payload_type}>", "ReadBase"
    return f"IDispatch<{payload_type}>", "ReadInterface"


def dispatch_flow_source(
    flow: str, receiver_type: str, routine_name: str, payload_type: str
) -> str:
    if flow == "direct":
        return f"Local result:{payload_type} = receiver.Read()"
    if flow == "generic-routine":
        return f"Local result:{payload_type} = {routine_name}<{payload_type}>(receiver)"
    return f"""Local holder:TDispatchHolder<{receiver_type}> = New TDispatchHolder<{receiver_type}>
holder.item = receiver
Local stored:{receiver_type} = holder.item
Local result:{payload_type} = stored.Read()"""


def dispatch_application_source(case_id: str, row: tuple[str, ...]) -> str:
    payload, receiver, flow = row
    payload_type, payload_initialization, assertion = core_payload_source(payload, case_id)
    receiver_type, routine_name = dispatch_receiver_source(receiver, payload_type)
    flow_source = dispatch_flow_source(flow, receiver_type, routine_name, payload_type)
    return f"""SuperStrict
Framework BRL.Blitz
Import BRL.StandardIO

{DISPATCH_DECLARATIONS}

{payload_initialization}
Local derived:TDispatchDerived<{payload_type}> = New TDispatchDerived<{payload_type}>
derived.Store(payload)
Local receiver:{receiver_type} = derived
dispatchCount = 0
{flow_source}
{assertion}
If dispatchCount <> 1 Then Throw "{case_id}: derived override was not dispatched"
Print "generic-combination-ok:{case_id}"
"""


CALLABLE_DECLARATIONS = """Type TPayloadObject
\tField number:Int
End Type

Struct SPayload
\tField number:Int
End Struct

Type TCallableHolder<T>
\tField item:T
End Type

Function CallableIdentity<T>:T(value:T)
\tReturn value
End Function

Function MakeArgumentClosure<T>:Closure<T()>(value:T)
\tLocal captured:T = value
\tReturn Function()
\t\tReturn captured
\tEnd Function
End Function

Function MakeArgumentFactory<T>:Closure<Closure<T()>()>(value:T)
\tLocal captured:T = value
\tReturn Function()
\t\tReturn Function()
\t\t\tReturn captured
\t\tEnd Function
\tEnd Function
End Function

Function CreateInt:Int()
\tReturn 41
End Function

Function CreateString:String()
\tReturn "core-value"
End Function

Function CreatePayloadObject:TPayloadObject()
\tLocal value:TPayloadObject = New TPayloadObject
\tvalue.number = 41
\tReturn value
End Function

Function CreateStruct:SPayload()
\tLocal value:SPayload
\tvalue.number = 41
\tReturn value
End Function"""


def callable_creator_name(payload: str) -> str:
    if payload == "int":
        return "CreateInt"
    if payload == "string":
        return "CreateString"
    if payload == "typed-object":
        return "CreatePayloadObject"
    return "CreateStruct"


def callable_creation_source(
    capture: str, signature: str, payload_type: str, creator_name: str
) -> tuple[str, str]:
    if signature == "value":
        callable_type = f"Closure<{payload_type}()>"
        if capture == "none":
            source = f"""Local callable:{callable_type} = Function()
\tReturn {creator_name}()
End Function"""
        elif capture == "local":
            source = f"""Local captured:{payload_type} = payload
Local callable:{callable_type} = Function()
\tReturn captured
End Function"""
        elif capture == "generic-argument":
            source = f"Local callable:{callable_type} = MakeArgumentClosure<{payload_type}>(payload)"
        else:
            source = f"""Local nestedCaptured:{payload_type} = payload
Local factory:Closure<Closure<{payload_type}()>()> = Function()
\tLocal innerCaptured:{payload_type} = nestedCaptured
\tReturn Function()
\t\tReturn innerCaptured
\tEnd Function
End Function
Local callable:{callable_type} = factory()"""
        return callable_type, source

    callable_type = f"Closure<Closure<{payload_type}()>()>"
    if capture == "none":
        source = f"""Local callable:{callable_type} = Function()
\tReturn Function()
\t\tReturn {creator_name}()
\tEnd Function
End Function"""
    elif capture == "local":
        source = f"""Local captured:{payload_type} = payload
Local callable:{callable_type} = Function()
\tReturn Function()
\t\tReturn captured
\tEnd Function
End Function"""
    elif capture == "generic-argument":
        source = f"Local callable:{callable_type} = MakeArgumentFactory<{payload_type}>(payload)"
    else:
        source = f"""Local outerCaptured:{payload_type} = payload
Local callable:{callable_type} = Function()
\tLocal innerCaptured:{payload_type} = outerCaptured
\tReturn Function()
\t\tReturn innerCaptured
\tEnd Function
End Function"""
    return callable_type, source


def callable_storage_source(storage: str, callable_type: str) -> str:
    if storage == "local":
        return f"Local storedCallable:{callable_type} = callable"
    if storage == "generic-field":
        return f"""Local holder:TCallableHolder<{callable_type}> = New TCallableHolder<{callable_type}>
holder.item = callable
Local storedCallable:{callable_type} = holder.item"""
    if storage == "generic-array":
        return f"""Local callables:{callable_type}[] = [callable]
Local storedCallable:{callable_type} = callables[0]"""
    return f"Local storedCallable:{callable_type} = CallableIdentity<{callable_type}>(callable)"


def callable_application_source(case_id: str, row: tuple[str, ...]) -> str:
    payload, capture, storage, signature = row
    payload_type, payload_initialization, assertion = core_payload_source(payload, case_id)
    callable_type, creation_source = callable_creation_source(
        capture, signature, payload_type, callable_creator_name(payload)
    )
    storage_source = callable_storage_source(storage, callable_type)
    if signature == "value":
        invocation = f"Local result:{payload_type} = storedCallable()"
    else:
        invocation = f"""Local inner:Closure<{payload_type}()> = storedCallable()
Local result:{payload_type} = inner()"""
    return f"""SuperStrict
Framework BRL.Blitz
Import BRL.StandardIO

{CALLABLE_DECLARATIONS}

{payload_initialization}
{creation_source}
{storage_source}
{invocation}
{assertion}
Print "generic-combination-ok:{case_id}"
"""


def bound_method_declarations(
    owner: str, receiver: str, payload_type: str, defer_generic_derived: bool = False
) -> str:
    common = CORE_VALUE_DECLARATIONS + f"""

Global boundImplementationCalls:Int
Global boundBaseCalls:Int
Global boundOverrideCalls:Int
Global boundFactoryCalls:Int

Interface IGeneratedBound<T>
\tMethod Transform:T(value:T)
End Interface

Type TGeneratedBoundHolder<T>
\tField callback:Closure<T(value:T)>
End Type

Function BindGenerated<T>:Closure<T(value:T)>(receiver:IGeneratedBound<T>)
\tReturn receiver.Transform
End Function

Function InvokeGenerated<T>:T(value:T, callback:Closure<T(value:T)>)
\tReturn callback(value)
End Function

Function ReturnGenerated<T>:Closure<T(value:T)>(callback:Closure<T(value:T)>)
\tReturn callback
End Function

Function WrapGenerated<T>:Closure<Closure<T(value:T)>()>(callback:Closure<T(value:T)>)
\tLocal captured:Closure<T(value:T)> = callback
\tReturn Function()
\t\tReturn captured
\tEnd Function
End Function
"""
    if owner == "ordinary":
        bind_self = ""
        if receiver == "implicit-self":
            bind_self = f"""
\tMethod BindSelf:Closure<{payload_type}(value:{payload_type})>()
\t\tReturn Transform
\tEnd Method"""
        declaration = f"""
Type TGeneratedBoundOwner Implements IGeneratedBound<{payload_type}>
\tField stored:{payload_type}
\tMethod Transform:{payload_type}(value:{payload_type})
\t\tboundImplementationCalls :+ 1
\t\tReturn stored
\tEnd Method{bind_self}
End Type
"""
        owner_type = "TGeneratedBoundOwner"
    elif owner == "generic":
        bind_self = ""
        if receiver == "implicit-self":
            bind_self = """
\tMethod BindSelf:Closure<T(value:T)>()
\t\tReturn Transform
\tEnd Method"""
        declaration = f"""
Type TGeneratedBoundOwner<T> Implements IGeneratedBound<T>
\tField stored:T
\tMethod Transform:T(value:T)
\t\tboundImplementationCalls :+ 1
\t\tReturn stored
\tEnd Method{bind_self}
End Type
"""
        owner_type = f"TGeneratedBoundOwner<{payload_type}>"
    else:
        bind_self = ""
        if receiver == "implicit-self":
            bind_self = """
\tMethod BindSelf:Closure<T(value:T)>()
\t\tReturn Transform
\tEnd Method"""
        declaration = f"""
Type TGeneratedBoundBase<T> Implements IGeneratedBound<T>
\tField stored:T
\tMethod Transform:T(value:T)
\t\tboundBaseCalls :+ 1
\t\tReturn stored
\tEnd Method{bind_self}
End Type
"""
        if not defer_generic_derived:
            declaration += f"""
Type TGeneratedBoundOwner Extends TGeneratedBoundBase<{payload_type}>
\tMethod Transform:{payload_type}(value:{payload_type}) Override
\t\tboundOverrideCalls :+ 1
\t\tReturn stored
\tEnd Method
End Type
"""
        owner_type = "TGeneratedBoundOwner"

    factory = ""
    if receiver == "factory" and not defer_generic_derived:
        factory = f"""
Function MakeGeneratedBoundOwner:{owner_type}(value:{payload_type})
\tboundFactoryCalls :+ 1
\tLocal owner:{owner_type} = New {owner_type}
\towner.stored = value
\tReturn owner
End Function
"""
    return common + declaration + factory


def bound_method_imported_consumer_declarations(
    owner: str, receiver: str, payload_type: str
) -> str:
    if owner != "generic-base":
        return ""
    result = f"""Type TGeneratedBoundOwner Extends TGeneratedBoundBase<{payload_type}>
\tMethod Transform:{payload_type}(value:{payload_type}) Override
\t\tboundOverrideCalls :+ 1
\t\tReturn stored
\tEnd Method
End Type
"""
    if receiver == "factory":
        result += f"""
Function MakeGeneratedBoundOwner:TGeneratedBoundOwner(value:{payload_type})
\tboundFactoryCalls :+ 1
\tLocal owner:TGeneratedBoundOwner = New TGeneratedBoundOwner
\towner.stored = value
\tReturn owner
End Function
"""
    return result


def bound_method_owner_type(owner: str, payload_type: str) -> str:
    if owner == "generic":
        return f"TGeneratedBoundOwner<{payload_type}>"
    return "TGeneratedBoundOwner"


def bound_method_binding_source(receiver: str, payload_type: str) -> str:
    callback_type = f"Closure<{payload_type}(value:{payload_type})>"
    if receiver == "concrete":
        return f"Local callback:{callback_type} = owner.Transform"
    if receiver == "interface":
        return f"""Local contract:IGeneratedBound<{payload_type}> = owner
Local callback:{callback_type} = contract.Transform"""
    if receiver == "factory":
        return f"Local callback:{callback_type} = MakeGeneratedBoundOwner(payload).Transform"
    if receiver == "implicit-self":
        return f"Local callback:{callback_type} = owner.BindSelf()"
    return f"Local callback:{callback_type} = BindGenerated<{payload_type}>(owner)"


def bound_method_transport_source(transport: str, payload_type: str) -> str:
    callback_type = f"Closure<{payload_type}(value:{payload_type})>"
    if transport == "local":
        return f"Local result:{payload_type} = callback(payload)"
    if transport == "generic-field":
        return f"""Local holder:TGeneratedBoundHolder<{payload_type}> = New TGeneratedBoundHolder<{payload_type}>
holder.callback = callback
Local result:{payload_type} = holder.callback(payload)"""
    if transport == "array":
        return f"""Local callbacks:{callback_type}[] = [callback]
Local result:{payload_type} = callbacks[0](payload)"""
    if transport == "argument":
        return f"Local result:{payload_type} = InvokeGenerated<{payload_type}>(payload, callback)"
    if transport == "returned":
        return f"""Local returned:{callback_type} = ReturnGenerated<{payload_type}>(callback)
Local result:{payload_type} = returned(payload)"""
    return f"""Local wrapper:Closure<{callback_type}()> = WrapGenerated<{payload_type}>(callback)
Local nested:{callback_type} = wrapper()
Local result:{payload_type} = nested(payload)"""


def bound_method_application_source(
    case_id: str, row: tuple[str, ...], imported: bool
) -> str:
    payload, owner, receiver, transport, _ = row
    payload_type, payload_initialization, assertion = core_payload_source(payload, case_id)
    owner_type = bound_method_owner_type(owner, payload_type)
    if imported:
        declarations = bound_method_imported_consumer_declarations(
            owner, receiver, payload_type
        )
        if declarations:
            declarations = "\n\n" + declarations
    else:
        declarations = "\n\n" + bound_method_declarations(
            owner, receiver, payload_type
        )
    provider_import = f'\nImport "{case_id}_provider.bmx"' if imported else ""
    binding_source = bound_method_binding_source(receiver, payload_type)
    transport_source = bound_method_transport_source(transport, payload_type)
    expected_implementation = 0 if owner == "generic-base" else 1
    expected_override = 1 if owner == "generic-base" else 0
    expected_factory = 1 if receiver == "factory" else 0
    return f"""SuperStrict
Framework BRL.StandardIO{provider_import}{declarations}

{payload_initialization}
Local owner:{owner_type} = New {owner_type}
owner.stored = payload
boundImplementationCalls = 0
boundBaseCalls = 0
boundOverrideCalls = 0
boundFactoryCalls = 0
{binding_source}
{transport_source}
{assertion}
If boundImplementationCalls <> {expected_implementation} Then Throw "{case_id}: ordinary implementation count"
If boundBaseCalls <> 0 Then Throw "{case_id}: base implementation was called"
If boundOverrideCalls <> {expected_override} Then Throw "{case_id}: override invocation count"
If boundFactoryCalls <> {expected_factory} Then Throw "{case_id}: receiver evaluation count"
Print "generic-combination-ok:{case_id}"
"""


GENERIC_REFERENCE_DECLARATIONS = CORE_VALUE_DECLARATIONS + """

Type TReferenceFunctions
	Function Identity<T>:T(value:T)
		Return value
	End Function
End Type

Type TGenericReferenceFunctions<TOwner>
	Function Identity<T>:T(value:T)
		Return value
	End Function
End Type

Type TReferenceHolder<T>
	Field callback:T(value:T)
End Type

Function FreeReferenceIdentity<T>:T(value:T)
	Return value
End Function

Function InvokeReference<T>:T(value:T, callback:T(value:T))
	Return callback(value)
End Function

Function ReturnFreeReference<T>:T(value:T)()
	Return FreeReferenceIdentity<T>
End Function

Function ReturnTypeReference<T>:T(value:T)()
	Return TReferenceFunctions.Identity<T>
End Function

Function ReturnGenericTypeReference<T>:T(value:T)()
	Return TGenericReferenceFunctions<String>.Identity<T>
End Function

Function ApplyFreeReference<T>:T(value:T)
	Local callback:T(value:T) = FreeReferenceIdentity<T>
	Return callback(value)
End Function

Function ApplyTypeReference<T>:T(value:T)
	Local callback:T(value:T) = TReferenceFunctions.Identity<T>
	Return callback(value)
End Function

Function ApplyGenericTypeReference<T>:T(value:T)
	Local callback:T(value:T) = TGenericReferenceFunctions<String>.Identity<T>
	Return callback(value)
End Function
"""


def generic_reference_expression(owner: str, payload_type: str) -> str:
    if owner == "free":
        return f"FreeReferenceIdentity<{payload_type}>"
    if owner == "type-function":
        return f"TReferenceFunctions.Identity<{payload_type}>"
    return f"TGenericReferenceFunctions<String>.Identity<{payload_type}>"


def generic_reference_returner(owner: str) -> str:
    if owner == "free":
        return "ReturnFreeReference"
    if owner == "type-function":
        return "ReturnTypeReference"
    return "ReturnGenericTypeReference"


def generic_reference_application(owner: str) -> str:
    if owner == "free":
        return "ApplyFreeReference"
    if owner == "type-function":
        return "ApplyTypeReference"
    return "ApplyGenericTypeReference"


def generic_reference_transport_source(
    transport: str, owner: str, payload_type: str
) -> str:
    reference = generic_reference_expression(owner, payload_type)
    if transport == "direct":
        return f"Local result:{payload_type} = InvokeReference<{payload_type}>(payload, {reference})"
    if transport == "local":
        return f"""Local callback:{payload_type}(value:{payload_type}) = {reference}
Local result:{payload_type} = callback(payload)"""
    if transport == "generic-field":
        return f"""Local holder:TReferenceHolder<{payload_type}> = New TReferenceHolder<{payload_type}>
holder.callback = {reference}
Local result:{payload_type} = holder.callback(payload)"""
    if transport == "returned":
        return f"""Local callback:{payload_type}(value:{payload_type}) = {generic_reference_returner(owner)}<{payload_type}>()
Local result:{payload_type} = callback(payload)"""
    return f"Local result:{payload_type} = {generic_reference_application(owner)}<{payload_type}>(payload)"


def generic_reference_provider_source() -> str:
    return "SuperStrict\nImport BRL.Blitz\n\n" + GENERIC_REFERENCE_DECLARATIONS


def generic_reference_application_source(
    case_id: str, row: tuple[str, ...], imported: bool
) -> str:
    payload, owner, transport, _boundary = row
    payload_type, payload_initialization, assertion = core_payload_source(payload, case_id)
    declarations = "" if imported else "\n\n" + GENERIC_REFERENCE_DECLARATIONS
    provider_import = f'\nImport "{case_id}_provider.bmx"' if imported else ""
    transport_source = generic_reference_transport_source(transport, owner, payload_type)
    return f"""SuperStrict
Framework BRL.StandardIO{provider_import}{declarations}

{payload_initialization}
{transport_source}
{assertion}
Print "generic-combination-ok:{case_id}"
"""


YIELD_DECLARATIONS = """Function GeneratedYieldOnce<T>:ICloseableIterator<T>(value:T)
\tYield value
End Function

Function GeneratedYieldLoop<T>:ICloseableIterator<T>(value:T)
\tFor Local index:Int = 1 To 3
\t\tYield value
\tNext
End Function

Function GeneratedYieldBranch<T>:ICloseableIterator<T>(value:T)
\tIf True Then
\t\tYield value
\t\tReturn
\tEnd If
\tYield value
End Function

Function GeneratedYieldNested<T>:ICloseableIterator<T>(value:T)
\tFor Local item:T = EachIn GeneratedYieldOnce<T>(value)
\t\tYield item
\tNext
End Function

Function GeneratedYieldUsing<T>:ICloseableIterator<T>(value:T)
\tUsing
\t\tLocal owned:ICloseableIterator<T> = GeneratedYieldOnce<T>(value)
\tDo
\t\tYield value
\tEnd Using
End Function

Function GeneratedYieldTry<T>:ICloseableIterator<T>(value:T)
\tTry
\t\tYield value
\t\tThrow "generated"
\tCatch message:String
\t\tYield value
\tFinally
\t\tLocal completed:Int = 1
\tEnd Try
\tYield value
End Function

Function GeneratedYieldCaptured<T>:ICloseableIterator<T>(value:T)
\tLocal current:T = value
\tLocal read:Closure<T()> = Function()
\t\tReturn current
\tEnd Function
\tYield read()
End Function

Function GeneratedYieldFactory<T>:Closure<ICloseableIterator<T>()>(value:T)
\tReturn Function()
\t\tYield value
\tEnd Function
End Function

Function GeneratedYieldStaticArray<T>:ICloseableIterator<T>(value:T)
\tLocal StaticArray values:T[2]
\tvalues[0] = value
\tvalues[1] = value
\tYield values[0]
\tFor Local item:T = EachIn values
\t\tYield item
\tNext
End Function

Function GeneratedYieldFrom<T>:ICloseableIterator<T>(value:T)
\tLocal values:T[] = New T[1]
\tvalues[0] = value
\tYield From values
End Function

Type TGeneratedYielder<T>
\tField value:T

\tMethod Once:ICloseableIterator<T>()
\t\tYield value
\tEnd Method

\tMethod Loop:ICloseableIterator<T>()
\t\tFor Local index:Int = 1 To 3
\t\t\tYield value
\t\tNext
\tEnd Method

\tMethod Branch:ICloseableIterator<T>()
\t\tIf True Then
\t\t\tYield value
\t\t\tReturn
\t\tEnd If
\t\tYield value
\tEnd Method

\tMethod Nested:ICloseableIterator<T>()
\t\tFor Local item:T = EachIn GeneratedYieldOnce<T>(value)
\t\t\tYield item
\t\tNext
\tEnd Method

\tMethod Owned:ICloseableIterator<T>()
\t\tUsing
\t\t\tLocal inner:ICloseableIterator<T> = GeneratedYieldOnce<T>(value)
\t\tDo
\t\t\tYield value
\t\tEnd Using
\tEnd Method

\tMethod Protected:ICloseableIterator<T>()
\t\tTry
\t\t\tYield value
\t\t\tThrow "generated"
\t\tCatch message:String
\t\t\tYield value
\t\tFinally
\t\t\tLocal completed:Int = 1
\t\tEnd Try
\t\tYield value
\tEnd Method

\tMethod Captured:ICloseableIterator<T>()
\t\tLocal current:T = value
\t\tLocal read:Closure<T()> = Function()
\t\t\tReturn current
\t\tEnd Function
\t\tYield read()
\tEnd Method

\tMethod Factory:Closure<ICloseableIterator<T>()>()
\t\tReturn Function()
\t\t\tYield value
\t\tEnd Function
\tEnd Method

\tMethod StaticValues:ICloseableIterator<T>()
\t\tLocal StaticArray values:T[2]
\t\tvalues[0] = value
\t\tvalues[1] = value
\t\tYield values[0]
\t\tFor Local item:T = EachIn values
\t\t\tYield item
\t\tNext
\tEnd Method

\tMethod Delegated:ICloseableIterator<T>()
\t\tLocal values:T[] = New T[1]
\t\tvalues[0] = value
\t\tYield From values
\tEnd Method
End Type

Type TGeneratedYielderBase<T>
\tField value:T

\tMethod Once:ICloseableIterator<T>()
\t\tYield value
\tEnd Method

\tMethod Loop:ICloseableIterator<T>()
\t\tFor Local index:Int = 1 To 3
\t\t\tYield value
\t\tNext
\tEnd Method

\tMethod Branch:ICloseableIterator<T>()
\t\tIf True Then
\t\t\tYield value
\t\t\tReturn
\t\tEnd If
\t\tYield value
\tEnd Method
\tMethod Nested:ICloseableIterator<T>()
\t\tFor Local item:T = EachIn GeneratedYieldOnce<T>(value)
\t\t\tYield item
\t\tNext
\tEnd Method

\tMethod Owned:ICloseableIterator<T>()
\t\tUsing
\t\t\tLocal inner:ICloseableIterator<T> = GeneratedYieldOnce<T>(value)
\t\tDo
\t\t\tYield value
\t\tEnd Using
\tEnd Method

\tMethod Protected:ICloseableIterator<T>()
\t\tTry
\t\t\tYield value
\t\t\tThrow "generated"
\t\tCatch message:String
\t\t\tYield value
\t\tFinally
\t\t\tLocal completed:Int = 1
\t\tEnd Try
\t\tYield value
\tEnd Method

\tMethod Captured:ICloseableIterator<T>()
\t\tLocal current:T = value
\t\tLocal read:Closure<T()> = Function()
\t\t\tReturn current
\t\tEnd Function
\t\tYield read()
\tEnd Method

\tMethod Factory:Closure<ICloseableIterator<T>()>()
\t\tReturn Function()
\t\t\tYield value
\t\tEnd Function
\tEnd Method

\tMethod StaticValues:ICloseableIterator<T>()
\t\tLocal StaticArray values:T[2]
\t\tvalues[0] = value
\t\tvalues[1] = value
\t\tYield values[0]
\t\tFor Local item:T = EachIn values
\t\t\tYield item
\t\tNext
\tEnd Method

\tMethod Delegated:ICloseableIterator<T>()
\t\tLocal values:T[] = New T[1]
\t\tvalues[0] = value
\t\tYield From values
\tEnd Method
End Type

Type TGeneratedDerivedYielder<T> Extends TGeneratedYielderBase<T>
End Type"""


def yield_provider_source() -> str:
    return "SuperStrict\nImport BRL.Blitz\n\n" + YIELD_DECLARATIONS


def yield_application_source(
    case_id: str, row: tuple[str, ...], imported: bool
) -> str:
    payload, owner, flow, consumption, _boundary = row
    payload_type, payload_initialization, assertion = core_payload_source(payload, case_id)
    declarations = "" if imported else "\n\n" + YIELD_DECLARATIONS
    provider_import = f'\nImport "{case_id}_provider.bmx"' if imported else ""
    if flow == "single":
        free_name, method_name, expected_count = "GeneratedYieldOnce", "Once", 1
    elif flow == "loop":
        free_name, method_name, expected_count = "GeneratedYieldLoop", "Loop", 3
    elif flow == "branch-return":
        free_name, method_name, expected_count = "GeneratedYieldBranch", "Branch", 1
    elif flow == "nested-iterator":
        free_name, method_name, expected_count = "GeneratedYieldNested", "Nested", 1
    elif flow == "using":
        free_name, method_name, expected_count = "GeneratedYieldUsing", "Owned", 1
    elif flow == "try-catch-finally":
        free_name, method_name, expected_count = "GeneratedYieldTry", "Protected", 3
    elif flow == "capturing-closure":
        free_name, method_name, expected_count = "GeneratedYieldCaptured", "Captured", 1
    elif flow == "static-array":
        free_name, method_name, expected_count = "GeneratedYieldStaticArray", "StaticValues", 3
    elif flow == "yield-from":
        free_name, method_name, expected_count = "GeneratedYieldFrom", "Delegated", 1
    else:
        free_name, method_name, expected_count = "GeneratedYieldFactory", "Factory", 1
    if owner == "free":
        if flow == "yielding-closure":
            creation = f"""Local factory:Closure<ICloseableIterator<{payload_type}>()> = {free_name}<{payload_type}>(payload)
Local iterator:ICloseableIterator<{payload_type}> = factory()"""
        else:
            creation = f"Local iterator:ICloseableIterator<{payload_type}> = {free_name}<{payload_type}>(payload)"
    else:
        owner_type = "TGeneratedYielder" if owner == "generic-type" else "TGeneratedDerivedYielder"
        if flow == "yielding-closure":
            creation = f"""Local owner:{owner_type}<{payload_type}> = New {owner_type}<{payload_type}>
owner.value = payload
Local factory:Closure<ICloseableIterator<{payload_type}>()> = owner.{method_name}()
Local iterator:ICloseableIterator<{payload_type}> = factory()"""
        else:
            creation = f"""Local owner:{owner_type}<{payload_type}> = New {owner_type}<{payload_type}>
owner.value = payload
Local iterator:ICloseableIterator<{payload_type}> = owner.{method_name}()"""
    if consumption == "exhaust":
        consumption_source = f'''Local count:Int
While iterator.MoveNext()
\tLocal result:{payload_type} = iterator.Current()
\t{assertion}
\tcount :+ 1
Wend
If count <> {expected_count} Then Throw "{case_id}: yielded count"
If iterator.MoveNext() Then Throw "{case_id}: completed iterator resumed"'''
    elif consumption == "early-close":
        consumption_source = f'''If Not iterator.MoveNext() Then Throw "{case_id}: iterator ended before early Close"
Local result:{payload_type} = iterator.Current()
{assertion}
iterator.Close()
iterator.Close()
If iterator.MoveNext() Then Throw "{case_id}: closed iterator resumed"'''
    else:
        consumption_source = f'''iterator.Close()
iterator.Close()
If iterator.MoveNext() Then Throw "{case_id}: iterator closed before start resumed"'''
    return f"""SuperStrict
Framework BRL.StandardIO{provider_import}{declarations}

{CORE_VALUE_DECLARATIONS}

{payload_initialization}
{creation}
{consumption_source}
Print "generic-combination-ok:{case_id}"
"""


def module_boundary_provider_source(module_name: str) -> str:
    return f"""SuperStrict

Module {module_name}

Import BRL.Blitz

Type TBoundaryObject
\tField number:Int
End Type

Struct SBoundaryStruct
\tField number:Int
End Struct

Global boundaryBaseTransformCalls:Int
Global boundaryDerivedTransformCalls:Int

Type TBoundaryBox<T>
\tField value:T
End Type

Type TBoundaryPair<K, V>
\tField first:K
\tField second:V
End Type

Type TBoundaryArrayConstructor<T>
\tField values:T[]
\tMethod New(items:T[])
\t\tvalues = items
\tEnd Method
\tMethod First:T()
\t\tReturn values[0]
\tEnd Method
End Type

Type TBoundaryRankedArrayConstructor<T>
\tField values:T[,]
\tMethod New(items:T[,])
\t\tvalues = items
\tEnd Method
\tMethod Read:T(x:Int, y:Int)
\t\tReturn values[x, y]
\tEnd Method
End Type

Type TBoundaryBase<T>
\tField value:T
\tMethod New(item:T)
\t\tvalue = item
\tEnd Method
\tMethod Store(item:T)
\t\tvalue = item
\tEnd Method
\tMethod Read:T()
\t\tReturn value
\tEnd Method
\tMethod Transform:T(item:T)
\t\tboundaryBaseTransformCalls :+ 1
\t\tReturn item
\tEnd Method
\tMethod BindTransform:Closure<T(item:T)>()
\t\tReturn Transform
\tEnd Method
\tMethod RuntimeKind:String()
\t\tReturn "base"
\tEnd Method
End Type

Type TBoundaryDerived<T> Extends TBoundaryBase<T>
\tMethod Transform:T(item:T) Override
\t\tboundaryDerivedTransformCalls :+ 1
\t\tReturn item
\tEnd Method
\tMethod RuntimeKind:String()
\t\tReturn "derived"
\tEnd Method
End Type

Function MakeBoundaryBox<T>:TBoundaryBox<T>(value:T)
\tLocal box:TBoundaryBox<T> = New TBoundaryBox<T>
\tbox.value = value
\tReturn box
End Function

Function MakeBoundaryPair<K, V>:TBoundaryPair<K, V>(first:K, second:V)
\tLocal pair:TBoundaryPair<K, V> = New TBoundaryPair<K, V>
\tpair.first = first
\tpair.second = second
\tReturn pair
End Function

Function BoundaryIdentity<T>:T(value:T)
\tReturn value
End Function

Function BoundaryArray<T>:T[](value:Object)
\tReturn T[](value)
End Function

Function BoundaryDeferred<T>:Closure<T()>(value:T)
\tLocal captured:T = value
\tReturn Function()
\t\tReturn captured
\tEnd Function
End Function
"""


def module_boundary_payload_source(payload: str, case_id: str) -> tuple[str, str, str]:
    if payload == "int":
        return "Int", "Local payload:Int = 41", f'If result <> 41 Then Throw "{case_id}: Int payload"'
    if payload == "string":
        return "String", 'Local payload:String = "module-boundary"', f'If result <> "module-boundary" Then Throw "{case_id}: String payload"'
    if payload == "typed-object":
        return (
            "TBoundaryObject",
            "Local payload:TBoundaryObject = New TBoundaryObject\npayload.number = 41",
            f'If result = Null Or result.number <> 41 Then Throw "{case_id}: Object payload"',
        )
    if payload == "struct":
        return (
            "SBoundaryStruct",
            "Local payload:SBoundaryStruct\npayload.number = 41",
            f'If result.number <> 41 Then Throw "{case_id}: Struct payload"',
        )
    return (
        "Closure<Int()>",
        "Local payload:Closure<Int()> = Function()\n\tReturn 41\nEnd Function",
        f'If result = Null Or result() <> 41 Then Throw "{case_id}: Closure payload"',
    )


def module_boundary_shape_source(shape: str, payload_type: str) -> tuple[str, str, str, str]:
    if shape == "direct":
        return payload_type, "payload", "resultCarrier", ""
    if shape == "nested":
        return (
            f"TBoundaryBox<{payload_type}>",
            f"MakeBoundaryBox<{payload_type}>(payload)",
            "resultCarrier.value",
            "",
        )
    return (
        f"TBoundaryPair<String, {payload_type}>",
        f'MakeBoundaryPair<String, {payload_type}>("key", payload)',
        "resultCarrier.second",
        'If resultCarrier.first <> "key" Then Throw "module pair key was not retained"',
    )


def module_boundary_api_source(api: str, carrier_type: str) -> str:
    if api == "field":
        return f"""Local box:TBoundaryBox<{carrier_type}> = MakeBoundaryBox<{carrier_type}>(carrier)
Local resultCarrier:{carrier_type} = box.value"""
    if api == "routine":
        return f"Local resultCarrier:{carrier_type} = BoundaryIdentity<{carrier_type}>(carrier)"
    if api == "routine-reference":
        return f"""Local callback:{carrier_type}(value:{carrier_type}) = BoundaryIdentity<{carrier_type}>
Local resultCarrier:{carrier_type} = callback(carrier)"""
    if api == "bound-method":
        return f"""boundaryBaseTransformCalls = 0
boundaryDerivedTransformCalls = 0
Local derived:TBoundaryDerived<{carrier_type}> = New TBoundaryDerived<{carrier_type}>(carrier)
Local callback:Closure<{carrier_type}(item:{carrier_type})> = derived.BindTransform()
Local resultCarrier:{carrier_type} = callback(carrier)
If boundaryBaseTransformCalls <> 0 Then Throw "module bound Method called base implementation"
If boundaryDerivedTransformCalls <> 1 Then Throw "module bound Method lost virtual dispatch"
"""
    if api == "inheritance":
        return f"""Local derived:TBoundaryDerived<{carrier_type}> = New TBoundaryDerived<{carrier_type}>(carrier)
If derived.RuntimeKind() <> "derived" Then Throw "module inherited constructor lost derived runtime identity"
Local base:TBoundaryBase<{carrier_type}> = derived
Local resultCarrier:{carrier_type} = base.Read()"""
    return f"""Local deferred:Closure<{carrier_type}()> = BoundaryDeferred<{carrier_type}>(carrier)
Local resultCarrier:{carrier_type} = deferred()"""


def module_boundary_application_source(
    case_id: str, row: tuple[str, ...], module_name: str
) -> str:
    payload, api, shape = row
    payload_type, payload_initialization, assertion = module_boundary_payload_source(payload, case_id)
    carrier_type, carrier_value, result_expression, shape_assertion = module_boundary_shape_source(
        shape, payload_type
    )
    api_source = module_boundary_api_source(api, carrier_type)
    if shape_assertion:
        shape_assertion += "\n"
    return f"""SuperStrict

Framework BRL.StandardIO
Import {module_name}

{payload_initialization}
Local carrier:{carrier_type} = {carrier_value}
{api_source}
{shape_assertion}Local result:{payload_type} = {result_expression}
{assertion}
Print "generic-combination-ok:{case_id}"
"""


def imported_constructor_array_payload_source(payload: str) -> tuple[str, str, str]:
    if payload == "typed-object":
        return (
            """Type TLocalConstructorPayload
\tField value:Int
End Type""",
            "TLocalConstructorPayload",
            "Local payload:TLocalConstructorPayload = New TLocalConstructorPayload\npayload.value = 41",
        )
    if payload == "interface":
        return (
            """Interface ILocalConstructorPayload
\tMethod Value:Int()
End Interface

Type TLocalConstructorPayload Implements ILocalConstructorPayload
\tField value:Int
\tMethod Value:Int()
\t\tReturn value
\tEnd Method
End Type""",
            "ILocalConstructorPayload",
            "Local concrete:TLocalConstructorPayload = New TLocalConstructorPayload\n"
            "concrete.value = 41\n"
            "Local payload:ILocalConstructorPayload = concrete",
        )
    if payload == "struct":
        return (
            """Struct SLocalConstructorPayload
\tField value:Int
End Struct""",
            "SLocalConstructorPayload",
            "Local payload:SLocalConstructorPayload\npayload.value = 41",
        )
    if payload == "enum":
        return (
            """Enum ELocalConstructorPayload
\tZero
\tExpected = 41
End Enum""",
            "ELocalConstructorPayload",
            "Local payload:ELocalConstructorPayload = ELocalConstructorPayload.Expected",
        )
    return (
        """Type TLocalConstructorPayload<T>
\tField value:T
End Type""",
        "TLocalConstructorPayload<Int>",
        "Local payload:TLocalConstructorPayload<Int> = New TLocalConstructorPayload<Int>\n"
        "payload.value = 41",
    )


def imported_constructor_array_assertion(payload: str, expression: str, case_id: str) -> str:
    if payload == "interface":
        observed = f"{expression}.Value()"
    elif payload == "enum":
        observed = f"Int({expression})"
    else:
        observed = f"{expression}.value"
    return f'If {observed} <> 41 Then Throw "{case_id}: imported constructor array payload"'


def imported_constructor_array_application_source(
    case_id: str, row: tuple[str, ...], module_name: str
) -> str:
    payload, shape = row
    declarations, payload_type, initialization = imported_constructor_array_payload_source(payload)
    if shape == "vector":
        construction = (
            f"Local owner:TBoundaryArrayConstructor<{payload_type}> = "
            f"New TBoundaryArrayConstructor<{payload_type}>([payload])"
        )
        expression = "owner.First()"
    elif shape == "jagged":
        construction = (
            f"Local row:{payload_type}[] = [payload]\n"
            f"Local owner:TBoundaryArrayConstructor<{payload_type}[]> = "
            f"New TBoundaryArrayConstructor<{payload_type}[]>([row])"
        )
        expression = "owner.First()[0]"
    else:
        construction = (
            f"Local matrix:{payload_type}[,] = New {payload_type}[1, 1]\n"
            "matrix[0, 0] = payload\n"
            f"Local owner:TBoundaryRankedArrayConstructor<{payload_type}> = "
            f"New TBoundaryRankedArrayConstructor<{payload_type}>(matrix)"
        )
        expression = "owner.Read(0, 0)"
    assertion = imported_constructor_array_assertion(payload, expression, case_id)
    return f"""SuperStrict

Framework BRL.StandardIO
Import {module_name}

{declarations}

{initialization}
{construction}
{assertion}
Print "generic-combination-ok:{case_id}"
"""


LIFECYCLE_DECLARATIONS = """Type TLifecycleObject
\tField number:Int
End Type

Struct SLifecycleStruct
\tField number:Int
End Struct

Type TLifecycleSlot<T>
\tField value:T
End Type

Function BuildLifecycleReader<T>:Closure<T()>(value:T, mode:Int)
\tLocal slot:TLifecycleSlot<T> = New TLifecycleSlot<T>
\tIf mode = 1 Then
\t\tslot.value = value
\tElse If mode = 2 Then
\t\tLocal initial:T
\t\tslot.value = initial
\t\tslot.value = value
\tEnd If
\tReturn Function()
\t\tReturn slot.value
\tEnd Function
End Function"""


def lifecycle_payload_source(
    payload: str, initialization: str, case_id: str
) -> tuple[str, str, str]:
    is_default = initialization == "default"
    if payload == "string":
        assertion = (
            f'If observed <> "" Then Throw "{case_id}: default String was not empty"'
            if is_default
            else f'If observed <> "lifecycle" Then Throw "{case_id}: String value was not retained"'
        )
        return "String", 'Local payload:String = "lifecycle"', assertion
    if payload == "array":
        assertion = (
            f'If observed.length <> 0 Then Throw "{case_id}: default Array was not empty"'
            if is_default
            else f'If observed.length <> 1 Or observed[0] <> 41 Then Throw "{case_id}: Array value was not retained"'
        )
        return "Int[]", "Local payload:Int[] = [41]", assertion
    if payload == "typed-object":
        assertion = (
            f'If observed <> Null Then Throw "{case_id}: default Object was not Null"'
            if is_default
            else f'If observed = Null Or observed.number <> 41 Then Throw "{case_id}: Object value was not retained"'
        )
        return (
            "TLifecycleObject",
            "Local payload:TLifecycleObject = New TLifecycleObject\npayload.number = 41",
            assertion,
        )
    if payload == "struct":
        assertion = (
            f'If observed.number <> 0 Then Throw "{case_id}: default Struct was not zeroed"'
            if is_default
            else f'If observed.number <> 41 Then Throw "{case_id}: Struct value was not retained"'
        )
        return (
            "SLifecycleStruct",
            "Local payload:SLifecycleStruct\npayload.number = 41",
            assertion,
        )
    assertion = (
        f'If observed <> Null Then Throw "{case_id}: default Closure was not Null"'
        if is_default
        else f'If observed = Null Or observed() <> 41 Then Throw "{case_id}: Closure value was not retained"'
    )
    return (
        "Closure<Int()>",
        "Local payload:Closure<Int()> = Function()\n\tReturn 41\nEnd Function",
        assertion,
    )


def lifecycle_storage_source(
    storage: str, initialization: str, payload_type: str
) -> tuple[str, str]:
    mode = {"default": 0, "explicit": 1, "reassigned": 2}[initialization]
    if storage == "local":
        if mode == 0:
            return "Local result:" + payload_type, ""
        if mode == 1:
            return f"Local result:{payload_type} = payload", ""
        return f"""Local result:{payload_type}
Local initial:{payload_type}
result = initial
result = payload""", ""
    if storage == "generic-field":
        assignments = ""
        if mode == 1:
            assignments = "slot.value = payload\n"
        elif mode == 2:
            assignments = f"Local initial:{payload_type}\nslot.value = initial\nslot.value = payload\n"
        return (
            f"""Local slot:TLifecycleSlot<{payload_type}> = New TLifecycleSlot<{payload_type}>
{assignments}Local result:{payload_type} = slot.value""",
            "",
        )
    if storage == "global":
        assignments = ""
        if mode == 1:
            assignments = "lifecycleGlobal.value = payload\n"
        elif mode == 2:
            assignments = f"Local initial:{payload_type}\nlifecycleGlobal.value = initial\nlifecycleGlobal.value = payload\n"
        declaration = f"Global lifecycleGlobal:TLifecycleSlot<{payload_type}> = New TLifecycleSlot<{payload_type}>"
        return assignments + f"Local result:{payload_type} = lifecycleGlobal.value", declaration
    return (
        f"""Local reader:Closure<{payload_type}()> = BuildLifecycleReader<{payload_type}>(payload, {mode})
Local result:{payload_type} = reader()""",
        "",
    )


def lifecycle_control_source(control: str, payload_type: str) -> str:
    if control == "straight":
        return f"Local observed:{payload_type} = result"
    if control == "branch":
        return f"""Local observed:{payload_type}
If True Then
\tobserved = result
Else
\tobserved = result
End If"""
    return f"""Local observed:{payload_type}
Try
\tThrow "lifecycle-control"
Catch exception:Object
\tobserved = result
End Try"""


def lifecycle_application_source(case_id: str, row: tuple[str, ...]) -> str:
    payload, initialization, storage, control = row
    payload_type, payload_initialization, assertion = lifecycle_payload_source(
        payload, initialization, case_id
    )
    storage_source, global_declaration = lifecycle_storage_source(
        storage, initialization, payload_type
    )
    control_source = lifecycle_control_source(control, payload_type)
    if global_declaration:
        global_declaration += "\n\n"
    return f"""SuperStrict

Framework BRL.Blitz
Import BRL.StandardIO

{LIFECYCLE_DECLARATIONS}

{global_declaration}{payload_initialization}
{storage_source}
{control_source}
{assertion}
Print "generic-combination-ok:{case_id}"
"""


def structural_padding(scale: str) -> str:
    count = 4 if scale == "small" else 48
    return "\n".join(
        f"\tMethod Padding{index}:Int()\n\t\tReturn {index}\n\tEnd Method"
        for index in range(count)
    )


def structural_protocol_members(protocol: str) -> tuple[str, str]:
    if protocol == "iterable":
        return (
            " Implements IIterable<T>",
            "\tMethod GetIterator:IIterator<T>()\n"
            "\t\tReturn New TScaleIterator<T>(values)\n"
            "\tEnd Method",
        )
    if protocol == "iterator":
        return (
            " Implements IIterator<T>",
            "\tMethod Current:T()\n\t\tReturn values[index]\n\tEnd Method\n"
            "\tMethod MoveNext:Int()\n\t\tindex :+ 1\n\t\tReturn index < values.length\n\tEnd Method",
        )
    return (
        "",
        "\tMethod ObjectEnumerator:TScaleLegacyIterator()\n"
        "\t\tReturn New TScaleLegacyIterator(41)\n"
        "\tEnd Method",
    )


def structural_provider_source(row: tuple[str, ...]) -> str:
    scale, inheritance, protocol, interfaces, _boundary = row
    protocol_clause, protocol_members = structural_protocol_members(protocol)
    extra_interface = ""
    extra_clause = ""
    extra_member = ""
    if interfaces == "multiple":
        extra_interface = "Interface IScaleReadable<T>\n\tMethod ReadScale:T()\nEnd Interface\n\n"
        extra_clause = ", IScaleReadable<T>" if protocol_clause else " Implements IScaleReadable<T>"
        extra_member = "\n\tMethod ReadScale:T()\n\t\tReturn values[0]\n\tEnd Method"
    base_header = "Type TScaleValues<T>" if inheritance == "direct" else "Type TScaleBase<T>"
    base_interfaces = protocol_clause + extra_clause if inheritance == "direct" else ""
    base = f"""{base_header}{base_interfaces}
\tField values:T[]
\tField index:Int = -1
\tMethod New(value:T)
\t\tvalues = [value]
\tEnd Method
{structural_padding(scale)}
{protocol_members if inheritance == 'direct' else ''}{extra_member if inheritance == 'direct' else ''}
End Type"""
    if inheritance == "direct":
        hierarchy = base
    else:
        leaf_clause = protocol_clause + extra_clause
        middle = ""
        parent = "TScaleBase<T>"
        if inheritance == "deep":
            middle = "\n\nType TScaleMiddle<T> Extends TScaleBase<T>\n\tMethod Middle:Int()\n\t\tReturn 1\n\tEnd Method\nEnd Type"
            parent = "TScaleMiddle<T>"
        hierarchy = (
            base
            + middle
            + f"\n\nType TScaleValues<T> Extends {parent}{leaf_clause}\n"
            + "\tMethod SetValue(value:T)\n\t\tvalues = [value]\n\tEnd Method\n"
            + protocol_members
            + extra_member
            + "\nEnd Type"
        )
    return f"""SuperStrict
Import BRL.Blitz

{extra_interface}Type TScaleIterator<T> Implements IIterator<T>
\tField values:T[]
\tField index:Int = -1
\tMethod New(values:T[])
\t\tSelf.values = values
\tEnd Method
\tMethod Current:T()
\t\tReturn values[index]
\tEnd Method
\tMethod MoveNext:Int()
\t\tindex :+ 1
\t\tReturn index < values.length
\tEnd Method
End Type

Type TScaleLegacyValue
\tField value:Int
End Type

Type TScaleLegacyIterator
\tField value:TScaleLegacyValue
\tField available:Int = True
\tMethod New(value:Int)
\t\tSelf.value = New TScaleLegacyValue
\t\tSelf.value.value = value
\tEnd Method
\tMethod HasNext:Int()
\t\tLocal result:Int = available
\t\tavailable = False
\t\tReturn result
\tEnd Method
\tMethod NextObject:Object()
\t\tReturn value
\tEnd Method
End Type

{hierarchy}
"""


def structural_application_source(
    case_id: str, row: tuple[str, ...], imported: bool
) -> str:
    _scale, inheritance, protocol, interfaces, _boundary = row
    declarations = "" if imported else "\n" + structural_provider_source(row).replace(
        "SuperStrict\nImport BRL.Blitz\n", ""
    )
    imports = "Framework BRL.Blitz\nImport BRL.StandardIO"
    if imported:
        imports += f'\nImport "{case_id}_provider.bmx"'
    if inheritance == "direct":
        receiver = "Local receiver:TScaleValues<Int> = New TScaleValues<Int>(41)"
    else:
        receiver = "Local receiver:TScaleValues<Int> = New TScaleValues<Int>()\nreceiver.SetValue(41)"
    if protocol == "object-enumerator":
        loop = "For Local value:TScaleLegacyValue = EachIn receiver\n\tresult = value.value\nNext"
    else:
        loop = "For Local value:Int = EachIn receiver\n\tresult = value\nNext"
    extra_assertion = ""
    if interfaces == "multiple":
        extra_assertion = f'If receiver.ReadScale() <> 41 Then Throw "{case_id}: secondary Interface"\n'
    return f"""SuperStrict
{imports}{declarations}

{receiver}
Local result:Int
{loop}
{extra_assertion}If result <> 41 Then Throw "{case_id}: protocol result"
Print "generic-combination-ok:{case_id}"
"""


def contract_provider_source(row: tuple[str, ...]) -> str:
    _payload, constructor, operator, interfaces, _boundary = row
    extra_interface = ""
    implements = " Implements IContractValue<T>"
    extra_method = ""
    if interfaces == "multiple":
        extra_interface = "Interface IContractStamp<T>\n\tMethod Stamp:Int()\nEnd Interface\n\n"
        implements += ", IContractStamp<T>"
        extra_method = "\n\tMethod Stamp:Int()\n\t\tReturn marker\n\tEnd Method"
    operator_methods = {
        "index": "\tMethod Operator[]:T(index:Int)\n\t\tReturn value\n\tEnd Method\n\tMethod Operator[]=(index:Int, nextValue:T)\n\t\tvalue = nextValue\n\tEnd Method",
        "binary": "\tMethod Operator +:TContractBase<T>(delta:Int)\n\t\tmarker :+ delta\n\t\tReturn Self\n\tEnd Method",
        "assignment": "\tMethod Operator :=:TContractBase<T>(nextValue:T)\n\t\tvalue = nextValue\n\t\tReturn Self\n\tEnd Method",
    }[operator]
    derived = ""
    if constructor == "derived-default":
        derived = f"""

Type TContract<T> Extends TContractBase<T>{implements}
\tMethod New()
\t\tNew(40)
\t\tmarker :+ 1
\tEnd Method
\tMethod Read:T()
\t\tReturn value
\tEnd Method{extra_method}
End Type"""
    elif constructor == "derived-overload":
        derived = f"""

Type TContract<T> Extends TContractBase<T>{implements}
\tMethod New(seed:Int, delta:Int)
\t\tNew(seed)
\t\tmarker :+ delta
\tEnd Method
\tMethod Read:T()
\t\tReturn value
\tEnd Method{extra_method}
End Type"""
    elif constructor in ("inherited", "inherited-zero"):
        derived = f"""

Type TContract<T> Extends TContractBase<T>
\tMethod RuntimeKind:String()
\t\tReturn "derived"
\tEnd Method
End Type"""
    if constructor == "inherited-zero":
        constructor_method = "\tMethod New()\n\t\tmarker = 41\n\tEnd Method"
    else:
        constructor_method = "\tMethod New(seed:Int)\n\t\tmarker = seed\n\tEnd Method"
    return f"""SuperStrict
Import BRL.Blitz

Interface IContractValue<T>
\tMethod Read:T()
End Interface

{extra_interface}Type TContractBase<T>{implements if constructor in ('base', 'inherited', 'inherited-zero') else ''}
\tField value:T
\tField marker:Int
{constructor_method}
\tMethod Read:T()
\t\tReturn value
\tEnd Method
\tMethod RuntimeKind:String()
\t\tReturn "base"
\tEnd Method
{operator_methods}{extra_method if constructor in ('base', 'inherited', 'inherited-zero') else ''}
End Type{derived}
"""


def contract_application_source(
    case_id: str, row: tuple[str, ...], imported: bool
) -> str:
    payload, constructor, operator, interfaces, _boundary = row
    payload_type, value = payload_details(payload)
    declarations = "" if imported else "\n" + contract_provider_source(row).replace(
        "SuperStrict\nImport BRL.Blitz\n", ""
    )
    imports = "Framework BRL.Blitz\nImport BRL.StandardIO"
    if imported:
        imports += f'\nImport "{case_id}_provider.bmx"'
    if constructor == "base":
        contract_type = f"TContractBase<{payload_type}>"
        creation = f"New TContractBase<{payload_type}>(41)"
    elif constructor == "derived-default":
        contract_type = f"TContract<{payload_type}>"
        creation = f"New TContract<{payload_type}>()"
    elif constructor == "inherited":
        contract_type = f"TContract<{payload_type}>"
        creation = f"New TContract<{payload_type}>(41)"
    elif constructor == "inherited-zero":
        contract_type = f"TContract<{payload_type}>"
        creation = f"New TContract<{payload_type}>()"
    else:
        contract_type = f"TContract<{payload_type}>"
        creation = f"New TContract<{payload_type}>(40, 1)"
    if operator == "index":
        operation = f"contract[0] = payload\nLocal result:{payload_type} = contract[0]"
        expected_marker = 41
    elif operator == "binary":
        operation = f"contract.value = payload\nLocal operated:TContractBase<{payload_type}> = contract + 1\nLocal result:{payload_type} = operated.Read()"
        expected_marker = 42
    else:
        operation = f"contract = payload\nLocal result:{payload_type} = contract.Read()"
        expected_marker = 41
    interface_assertion = ""
    if interfaces == "multiple":
        interface_assertion = f'If contract.Stamp() <> {expected_marker} Then Throw "{case_id}: secondary Interface"\n'
    runtime_assertion = ""
    if constructor in ("inherited", "inherited-zero"):
        runtime_assertion = f'If contract.RuntimeKind() <> "derived" Then Throw "{case_id}: derived runtime identity"\n'
    return f"""SuperStrict
{imports}{declarations}

Local payload:{payload_type} = {value}
Local contract:{contract_type} = {creation}
{operation}
{interface_assertion}{runtime_assertion}If contract.marker <> {expected_marker} Or result <> payload Then Throw "{case_id}: contract result"
Print "generic-combination-ok:{case_id}"
"""


def dependency_payload_source(payload: str, case_id: str) -> tuple[str, str, str]:
    if payload == "string":
        return "String", 'Local payload:String = "dependency"', f'If result <> "dependency" Then Throw "{case_id}: String"'
    if payload == "struct":
        return "SDependencyPayload", "Local payload:SDependencyPayload\npayload.number = 41", f'If result.number <> 41 Then Throw "{case_id}: Struct"'
    if payload == "closure":
        return "Closure<Int()>", "Local payload:Closure<Int()> = Function()\n\tReturn 41\nEnd Function", f'If result = Null Or result() <> 41 Then Throw "{case_id}: Closure"'
    return "TDependencyBox<Int>", "Local payload:TDependencyBox<Int> = New TDependencyBox<Int>\npayload.value = 41", f'If result = Null Or result.value <> 41 Then Throw "{case_id}: nested generic"'


def dependency_sources(_case_id: str, row: tuple[str, ...]) -> tuple[str, str]:
    _payload, shape, _flow, _order = row
    inheritance = " Extends TRightBase<T>" if shape == "inheritance" else ""
    left = f"""SuperStrict
Import "right.bmx"

Struct SDependencyPayload
\tField number:Int
End Struct

Type TDependencyBox<T>
\tField value:T
End Type

Type TLeft<T>{inheritance}
\tField value:T
\tField right:TRight<T>
\tMethod Read:T()
\t\tReturn value
\tEnd Method
End Type
"""
    routine = ""
    if shape == "routine":
        routine = "\nFunction DependencyIdentity<T>:T(value:T)\n\tReturn value\nEnd Function\n"
    right = f"""SuperStrict

Type TRightBase<T>
\tField inheritedValue:T
End Type

Type TRight<T>
\tField value:T
End Type
{routine}"""
    return left, right


def dependency_application_source(case_id: str, row: tuple[str, ...]) -> str:
    payload, shape, flow, import_order = row
    payload_type, initialization, assertion = dependency_payload_source(payload, case_id)
    imports = ['Import "left.bmx"', 'Import "right.bmx"']
    if import_order == "right-first":
        imports.reverse()
    value_source = "left.value = payload\nLocal carried:" + payload_type + " = left.Read()"
    if shape == "routine":
        value_source = f"Local carried:{payload_type} = DependencyIdentity<{payload_type}>(payload)\nleft.value = carried"
    elif shape == "inheritance":
        value_source = f"left.inheritedValue = payload\nLocal carried:{payload_type} = left.inheritedValue\nleft.value = carried"
    if flow == "direct":
        result_source = f"Local result:{payload_type} = carried"
    elif flow == "array":
        result_source = f"Local values:{payload_type}[] = [carried]\nLocal result:{payload_type} = values[0]"
    else:
        result_source = f"Local reader:Closure<{payload_type}()> = Function()\n\tReturn carried\nEnd Function\nLocal result:{payload_type} = reader()"
    return f"""SuperStrict
Framework BRL.Blitz
Import BRL.StandardIO
{chr(10).join(imports)}

{initialization}
Local left:TLeft<{payload_type}> = New TLeft<{payload_type}>
Local right:TRight<{payload_type}> = New TRight<{payload_type}>
left.right = right
{value_source}
{result_source}
{assertion}
Print "generic-combination-ok:{case_id}"
"""


CLEANUP_DECLARATIONS = """Type TCleanupIterator<T> Implements ICloseableIterator<T>
\tField value:T
\tField available:Int = True
\tField tracker:Int[]
\tField closed:Int
\tMethod New(value:T, tracker:Int[])
\t\tSelf.value = value
\t\tSelf.tracker = tracker
\tEnd Method
\tMethod Current:T()
\t\tReturn value
\tEnd Method
\tMethod MoveNext:Int()
\t\tLocal result:Int = available
\t\tavailable = False
\t\tReturn result
\tEnd Method
\tMethod Close()
\t\tIf closed Then Return
\t\tclosed = True
\t\ttracker[0] :+ 100
\tEnd Method
End Type

Type TCleanupIterable<T> Implements IIterable<T>
\tField value:T
\tField tracker:Int[]
\tMethod New(value:T, tracker:Int[])
\t\tSelf.value = value
\t\tSelf.tracker = tracker
\tEnd Method
\tMethod GetIterator:IIterator<T>()
\t\tReturn New TCleanupIterator<T>(value, tracker)
\tEnd Method
End Type

Type TCleanupLegacyIntValue
\tField value:Int
\tMethod New(value:Int)
\t\tSelf.value = value
\tEnd Method
End Type

Type TCleanupLegacyIntIterator Implements ICloseable
\tField value:TCleanupLegacyIntValue
\tField available:Int = True
\tField tracker:Int[]
\tField closed:Int
\tMethod New(value:Int, tracker:Int[])
\t\tSelf.value = New TCleanupLegacyIntValue(value)
\t\tSelf.tracker = tracker
\tEnd Method
\tMethod HasNext:Int()
\t\tLocal result:Int = available
\t\tavailable = False
\t\tReturn result
\tEnd Method
\tMethod NextObject:Object()
\t\tReturn value
\tEnd Method
\tMethod Close()
\t\tIf closed Then Return
\t\tclosed = True
\t\ttracker[0] :+ 100
\tEnd Method
End Type

Type TCleanupLegacyIntIterable
\tField value:Int
\tField tracker:Int[]
\tMethod New(value:Int, tracker:Int[])
\t\tSelf.value = value
\t\tSelf.tracker = tracker
\tEnd Method
\tMethod ObjectEnumerator:TCleanupLegacyIntIterator()
\t\tReturn New TCleanupLegacyIntIterator(value, tracker)
\tEnd Method
End Type

Type TCleanupLegacyStringIterator Implements ICloseable
\tField value:String
\tField available:Int = True
\tField tracker:Int[]
\tField closed:Int
\tMethod New(value:String, tracker:Int[])
\t\tSelf.value = value
\t\tSelf.tracker = tracker
\tEnd Method
\tMethod HasNext:Int()
\t\tLocal result:Int = available
\t\tavailable = False
\t\tReturn result
\tEnd Method
\tMethod NextObject:Object()
\t\tReturn value
\tEnd Method
\tMethod Close()
\t\tIf closed Then Return
\t\tclosed = True
\t\ttracker[0] :+ 100
\tEnd Method
End Type

Type TCleanupLegacyStringIterable
\tField value:String
\tField tracker:Int[]
\tMethod New(value:String, tracker:Int[])
\t\tSelf.value = value
\t\tSelf.tracker = tracker
\tEnd Method
\tMethod ObjectEnumerator:TCleanupLegacyStringIterator()
\t\tReturn New TCleanupLegacyStringIterator(value, tracker)
\tEnd Method
End Type"""


def cleanup_try_source(action: str, nesting: str, catches: bool) -> str:
    if nesting == "single":
        catch = "\n\t\tCatch message:String\n\t\t\tresult = value" if catches else ""
        return f"Try\n\t\t\t{action}{catch}\n\t\tFinally\n\t\t\ttracker[0] :+ 1\n\t\tEnd Try"
    if catches:
        return f"""Try
\t\t\tTry
\t\t\t\t{action}
\t\t\tFinally
\t\t\t\ttracker[0] :+ 1
\t\t\tEnd Try
\t\tCatch message:String
\t\t\tresult = value
\t\tFinally
\t\t\ttracker[0] :+ 1
\t\tEnd Try"""
    return f"""Try
\t\t\tTry
\t\t\t\t{action}
\t\t\tFinally
\t\t\t\ttracker[0] :+ 1
\t\t\tEnd Try
\t\tFinally
\t\t\ttracker[0] :+ 1
\t\tEnd Try"""


def cleanup_application_source(case_id: str, row: tuple[str, ...]) -> str:
    payload, protocol, transfer, nesting = row
    payload_type, value = payload_details(payload)
    if protocol == "iterable":
        collection = f"New TCleanupIterable<T>(value, tracker)"
    elif protocol == "iterator":
        collection = f"New TCleanupIterator<T>(value, tracker)"
    elif payload == "int":
        collection = "source"
    else:
        collection = "source"
    loop_type = payload_type if protocol == "object-enumerator" else "T"
    action = "result = item"
    catches = False
    if transfer == "return":
        action = "Return item"
    elif transfer == "continue":
        action = "If pass = 0 Then Continue Outer\n\t\t\tresult = item"
    elif transfer == "throw":
        action = 'Throw "cleanup"'
        catches = True
    protected = cleanup_try_source(action, nesting, catches)
    if transfer == "continue":
        loop = f"""#Outer
\tFor Local pass:Int = 0 Until 2
\t\tFor Local item:{loop_type} = EachIn {collection}
\t\t\t{protected}
\t\tNext
\tNext"""
        cleanup_count = 200 + 2 * (2 if nesting == "nested" else 1)
    else:
        loop = f"""For Local item:{loop_type} = EachIn {collection}
\t\t{protected}
\tNext"""
        cleanup_count = 100 + (2 if nesting == "nested" else 1)
    value_type = payload_type if protocol == "object-enumerator" else "T"
    source_type = "TCleanupLegacyIntIterable" if payload == "int" else "TCleanupLegacyStringIterable"
    extra_parameter = f", source:{source_type}" if protocol == "object-enumerator" else ""
    extra_argument = f", New {source_type}({value}, tracker)" if protocol == "object-enumerator" else ""
    function = f"""Function ExerciseCleanup<T>:{value_type}(value:{value_type}, tracker:Int[]{extra_parameter})
\tLocal result:{value_type}
\t{loop}
\tReturn result
End Function"""
    return f"""SuperStrict
Framework BRL.Blitz
Import BRL.StandardIO

{CLEANUP_DECLARATIONS}

{function}

Local tracker:Int[] = [0]
Local result:{payload_type} = ExerciseCleanup<{payload_type}>({value}, tracker{extra_argument})
If result <> {value} Or tracker[0] <> {cleanup_count} Then Throw "{case_id}: cleanup result"
Print "generic-combination-ok:{case_id}"
"""


def managed_conversion_application_source(
    case_id: str, row: tuple[str, ...]
) -> str:
    payload, state, flow, consumer = row
    payload_types = {
        "string": "String",
        "typed-object": "TManagedItem",
        "interface": "IManagedItem",
        "array": "Int[]",
        "nested-generic": "TManagedStringBox",
    }
    element_type = payload_types[payload]
    valid_values = {
        "string": '["left", "right"]',
        "typed-object": "[New TManagedItem, New TManagedItem]",
        "interface": "preparedInterfaces",
        "array": "[[1], [2, 3]]",
        "nested-generic": "[New TManagedStringBox, New TManagedStringBox]",
    }
    setup = "Local boxed:Object"
    if state == "valid":
        if payload == "interface":
            setup = """Local preparedInterfaces:IManagedItem[] = New IManagedItem[2]
preparedInterfaces[0] = New TManagedItem
preparedInterfaces[1] = New TManagedItem
Local boxed:Object = preparedInterfaces"""
        else:
            setup = f"Local boxed:Object = {valid_values[payload]}"
    elif state == "incompatible":
        setup = "Local boxed:Object = [1, 2]"

    helpers = ""
    if flow == "direct":
        conversion = f"Local values:{element_type}[] = {element_type}[](boxed)"
    elif flow == "routine":
        helpers = f"""Function ReadManaged:{element_type}[](value:Object)
	Return {element_type}[](value)
End Function
"""
        conversion = f"Local values:{element_type}[] = ReadManaged(boxed)"
    elif flow == "generic-routine":
        helpers = """Function ReadManagedGeneric<T>:T[](value:Object)
	Return T[](value)
End Function
"""
        conversion = f"Local values:{element_type}[] = ReadManagedGeneric<{element_type}>(boxed)"
    else:
        helpers = """Type TManagedHolder<T>
	Field value:Object
	Method Read:T[]()
		Return T[](value)
	End Method
End Type
"""
        conversion = f"""Local holder:TManagedHolder<{element_type}> = New TManagedHolder<{element_type}>
holder.value = boxed
Local values:{element_type}[] = holder.Read()"""

    expected = 2 if state == "valid" else 0
    if consumer == "truth":
        assertion = f'''Local truth:Int
If values Then truth = 1
If truth <> {1 if expected else 0} Then Throw "{case_id}: truth"'''
    elif consumer == "length":
        assertion = f'If values.length <> {expected} Then Throw "{case_id}: length"'
    else:
        assertion = f'''Local visits:Int
For Local item:{element_type} = EachIn values
	visits :+ 1
Next
If visits <> {expected} Then Throw "{case_id}: EachIn"'''

    return f"""SuperStrict
Framework BRL.StandardIO

Interface IManagedItem
End Interface

Type TManagedItem Implements IManagedItem
End Type

Type TManagedBox<T>
	Field value:T
End Type

Type TManagedStringBox Extends TManagedBox<String>
End Type

{helpers}{setup}
{conversion}
{assertion}
Print "generic-combination-ok:{case_id}"
"""


def incremental_provider_source(revision: int) -> str:
    return f"""SuperStrict

Type TIncrementalValue<T>
\tField value:T
\tMethod New(value:T)
\t\tSelf.value = value
\tEnd Method
\tMethod Revision:Int()
\t\tReturn {revision}
\tEnd Method
\tMethod Reader:Closure<T()>()
\t\tLocal captured:T = value
\t\tReturn Function()
\t\t\tReturn captured
\t\tEnd Function
\tEnd Method
End Type
"""


def incremental_application_source(seed: int) -> str:
    return f"""SuperStrict
Framework BRL.Blitz
Import BRL.StandardIO
Import "provider.bmx"

Local value:TIncrementalValue<String> = New TIncrementalValue<String>("seed-{seed}")
Local reader:Closure<String()> = value.Reader()
If reader = Null Or reader() <> "seed-{seed}" Then Throw "incremental Closure transport"
Print "generic-incremental-v" + value.Revision()
"""


NEGATIVE_CASES = {
	"negative-untyped-generic-callable-parameter": (
		"BMX3103",
		"SuperStrict\nFunction Apply<T>:T(value:T, fn:T(T))\nReturn fn(value)\nEnd Function",
	),
	"negative-implicit-string-numeric-constructor": (
		"BMX3302",
		'SuperStrict\nType TBox<T>\nField value:T\nMethod New(value:T)\nSelf.value=value\nEnd Method\nEnd Type\nLocal value:TBox<Int>=New TBox<Int>("hello")',
	),
	"negative-implicit-string-numeric-member": (
		"BMX3310",
		'SuperStrict\nType TBox<T>\nField value:T\nEnd Type\nType TPair<A,B>\nField first:A\nField second:B\nEnd Type\nLocal pair:TPair<String,TBox<Int>>\npair.second.value="hello"',
	),
	"negative-postfix-generic-type": (
		"BMX2105",
		"SuperStrict\nFunction Convert<A, B>:B(value:A)\nReturn value:B\nEnd Function\nLocal converted:Int = Convert<String, Int>(~q1~q)",
	),
	"negative-postfix-for-type": (
		"BMX2105",
		"SuperStrict\nLocal existing:Int\nFor existing:Int = 0 Until 2\nNext",
	),
	"negative-yield-contract": (
		"BMX3332",
		"SuperStrict\nFunction Value:Int()\nYield 1\nEnd Function",
	),
	"negative-yield-return-value": (
		"BMX3334",
		"SuperStrict\nFramework BRL.Blitz\nFunction Values:ICloseableIterator<Int>()\nYield 1\nReturn 2\nEnd Function",
	),
	"negative-yield-from-missing": (
		"BMX2328",
		"SuperStrict\nFramework BRL.Blitz\nFunction Values:ICloseableIterator<Int>()\nYield From\nEnd Function",
	),
	"negative-yield-from-source": (
		"BMX3330",
		"SuperStrict\nFramework BRL.Blitz\nFunction Values:ICloseableIterator<Int>()\nYield From 1\nEnd Function",
	),
	"negative-yield-finally": (
		"BMXC1252",
		"SuperStrict\nFramework BRL.Blitz\nFunction Values:ICloseableIterator<Int>()\nTry\nYield 1\nFinally\nYield 2\nEnd Try\nEnd Function",
	),
    "negative-arity": (
        "BMX3102",
        "SuperStrict\nType TBox<T>\nEnd Type\nGlobal value:TBox<Int,String>",
    ),
    "negative-growing-cycle": (
        "BMXC3090",
        "SuperStrict\nType TNode<T>\nEnd Type\nType TLeft<T>\nField right:TRight<TNode<T>>\nEnd Type\nType TRight<T>\nField left:TLeft<TNode<T>>\nEnd Type\nGlobal root:TLeft<Int> = New TLeft<Int>",
    ),
    "negative-recursive-struct": (
        "BMXC3008",
        "SuperStrict\nStruct SRecursive<T>\nField child:SRecursive<T>\nEnd Struct\nGlobal value:SRecursive<Int>",
    ),
    "negative-generic-reference-arity": (
        "BMX3341",
        "SuperStrict\nFunction Identity<T>:T(value:T)\nReturn value\nEnd Function\nLocal callback:Int(value:Int)=Identity<Int,String>",
    ),
    "negative-generic-reference-constraint": (
        "BMX3341",
        "SuperStrict\nInterface IMarker\nEnd Interface\nFunction Identity<T>:T(value:T) Where T Extends IMarker\nReturn value\nEnd Function\nLocal callback:Int(value:Int)=Identity<Int>",
    ),
    "negative-generic-reference-overload": (
        "BMX3342",
        "SuperStrict\nFunction Choose<T>:T(value:T)\nReturn value\nEnd Function\nFunction Choose<T>:T(value:T, fallback:T)\nReturn value\nEnd Function\nLocal callback:Int(value:Int)=Choose<Int>",
    ),
    "negative-struct-bound-method-reference": (
        "BMX3348",
        "SuperStrict\nStruct SValue\nMethod Read:Int(value:Int)\nReturn value\nEnd Method\nEnd Struct\nLocal value:SValue\nLocal callback:Closure<Int(value:Int)> = value.Read",
    ),
}


CURATED_POSITIVE_CASES = {
    "regression-inherited-generic-interface-implementation": """SuperStrict
Framework BRL.StandardIO

Interface IMatrixIterator<T>
End Interface

Interface IMatrixIterable<T>
    Method GetIterator:IMatrixIterator<T>()
End Interface

Interface IMatrixCollection<T> Extends IMatrixIterable<T>
    Method CopyTo(array:T[], index:Int = 0)
End Interface

Type TMatrixCollection<T> Implements IMatrixCollection<T>
    Method GetIterator:IMatrixIterator<T>()
        Return Null
    End Method
    Method CopyTo(array:T[], index:Int = 0)
        array[index] = array[index]
    End Method
End Type

Type TMatrixList<T> Extends TMatrixCollection<T>
End Type

Local list:TMatrixList<String> = New TMatrixList<String>()
Local values:String[] = ["inherited"]
list.CopyTo(values)
Print "generic-combination-ok:regression-inherited-generic-interface-implementation"
""",
    "regression-inherited-closure-nested": application_source(
        "regression-inherited-closure-nested",
        ("int", "inherited", "closure", "nested", "single"),
        False,
    ),
    "regression-default-closure-local": lifecycle_application_source(
        "regression-default-closure-local",
        ("closure", "default", "local", "exception"),
    ),
    "regression-large-deep-generic-eachin": structural_application_source(
        "regression-large-deep-generic-eachin",
        ("large", "deep", "iterable", "multiple", "single"),
        False,
    ),
    "regression-bound-method-reference": """SuperStrict
Framework BRL.StandardIO

Interface IBoundTransformer<T>
    Method Transform:T(value:T)
End Interface

Struct SBoundPayload
    Field number:Int
End Struct

Type TBoundNested<T>
    Field value:T
End Type

Type TBoundTransformer<T> Implements IBoundTransformer<T>
    Field stored:T
    Method Transform:T(value:T)
        Return stored
    End Method
    Method BindSelf:Closure<T(value:T)>()
        Return Transform
    End Method
End Type

Type TBoundIntDerived Extends TBoundTransformer<Int>
    Method Transform:Int(value:Int) Override
        Return value + 1
    End Method
End Type

Type TBoundHolder<T>
    Field callback:Closure<T(value:T)>
End Type

Function BindBoundInterface<T>:Closure<T(value:T)>(receiver:IBoundTransformer<T>)
    Return receiver.Transform
End Function

Local derived:TBoundIntDerived = New TBoundIntDerived
Local throughInterface:IBoundTransformer<Int> = derived
Local integerCall:Closure<Int(value:Int)> = BindBoundInterface<Int>(throughInterface)
If integerCall(41) <> 42 Then Throw "regression-bound-method-reference: Interface virtual dispatch"

Local strings:TBoundTransformer<String> = New TBoundTransformer<String>
strings.stored = "bound"
Local holder:TBoundHolder<String> = New TBoundHolder<String>
holder.callback = strings.BindSelf()
If holder.callback("ignored") <> "bound" Then Throw "regression-bound-method-reference: generic Self capture"

Local arrays:TBoundTransformer<Int[]> = New TBoundTransformer<Int[]>
arrays.stored = [20, 22]
Local arraysInterface:IBoundTransformer<Int[]> = arrays
Local arrayCall:Closure<Int[](value:Int[])> = BindBoundInterface<Int[]>(arraysInterface)
Local arrayResult:Int[] = arrayCall(Null)
If arrayResult.length <> 2 Or arrayResult[0] + arrayResult[1] <> 42 Then Throw "regression-bound-method-reference: Array signature"

Local structs:TBoundTransformer<SBoundPayload> = New TBoundTransformer<SBoundPayload>
structs.stored.number = 42
Local structCall:Closure<SBoundPayload(value:SBoundPayload)> = structs.Transform
Local emptyStruct:SBoundPayload
If structCall(emptyStruct).number <> 42 Then Throw "regression-bound-method-reference: Struct signature"

Local nested:TBoundTransformer<TBoundNested<String>> = New TBoundTransformer<TBoundNested<String>>
nested.stored = New TBoundNested<String>
nested.stored.value = "nested"
Local nestedCall:Closure<TBoundNested<String>(value:TBoundNested<String>)> = nested.BindSelf()
If nestedCall(Null).value <> "nested" Then Throw "regression-bound-method-reference: nested generic signature"

Print "generic-combination-ok:regression-bound-method-reference"
""",
}

CURATED_MODULE_POSITIVE_CASES = {
    "regression-module-inherited-struct-constructor": (
        "struct",
        "inheritance",
        "direct",
    ),
    "regression-module-inherited-object-constructor": (
        "typed-object",
        "inheritance",
        "direct",
    ),
}


def write_corpus(output: Path, seed: int) -> None:
    output.mkdir(parents=True, exist_ok=True)
    manifest: list[str] = ["kind\tid\texpected\tsource\tfeatures"]
    dimension_names = tuple(BASE_DIMENSIONS)
    for index, row in enumerate(select_pairwise(BASE_DIMENSIONS, seed), 1):
        case_id = f"pairwise-{index:03d}"
        case_dir = output / case_id
        case_dir.mkdir()
        imported = row[-1] == "imported"
        if imported:
            (case_dir / f"{case_id}_provider.bmx").write_text(
                provider_source(row[1], row[2]), encoding="utf-8"
            )
        source = case_dir / f"{case_id}.bmx"
        source.write_text(application_source(case_id, row, imported), encoding="utf-8")
        features = ",".join(f"{name}={value}" for name, value in zip(dimension_names, row))
        manifest.append(f"positive\t{case_id}\tgeneric-combination-ok:{case_id}\t{source.as_posix()}\t{features}")

    core_dimension_names = tuple(CORE_VALUE_DIMENSIONS)
    for index, row in enumerate(select_pairwise(CORE_VALUE_DIMENSIONS, seed + 1000003), 1):
        case_id = f"core-values-{index:03d}"
        case_dir = output / case_id
        case_dir.mkdir()
        source = case_dir / f"{case_id}.bmx"
        source.write_text(core_value_application_source(case_id, row), encoding="utf-8")
        features = ",".join(
            f"{name}={value}" for name, value in zip(core_dimension_names, row)
        )
        manifest.append(
            f"positive\t{case_id}\tgeneric-combination-ok:{case_id}\t"
            f"{source.as_posix()}\tfamily=core-values,{features}"
        )

    dispatch_dimension_names = tuple(DISPATCH_DIMENSIONS)
    for index, row in enumerate(select_pairwise(DISPATCH_DIMENSIONS, seed + 2000003), 1):
        case_id = f"dispatch-{index:03d}"
        case_dir = output / case_id
        case_dir.mkdir()
        source = case_dir / f"{case_id}.bmx"
        source.write_text(dispatch_application_source(case_id, row), encoding="utf-8")
        features = ",".join(
            f"{name}={value}" for name, value in zip(dispatch_dimension_names, row)
        )
        manifest.append(
            f"positive\t{case_id}\tgeneric-combination-ok:{case_id}\t"
            f"{source.as_posix()}\tfamily=dispatch,{features}"
        )

    callable_dimension_names = tuple(CALLABLE_DIMENSIONS)
    for index, row in enumerate(select_pairwise(CALLABLE_DIMENSIONS, seed + 3000003), 1):
        case_id = f"callable-{index:03d}"
        case_dir = output / case_id
        case_dir.mkdir()
        source = case_dir / f"{case_id}.bmx"
        source.write_text(callable_application_source(case_id, row), encoding="utf-8")
        features = ",".join(
            f"{name}={value}" for name, value in zip(callable_dimension_names, row)
        )
        manifest.append(
            f"positive\t{case_id}\tgeneric-combination-ok:{case_id}\t"
            f"{source.as_posix()}\tfamily=callable,{features}"
        )

    bound_method_dimension_names = tuple(BOUND_METHOD_DIMENSIONS)
    bound_method_rows: list[tuple[str, ...]] = []
    for selected_row in select_pairwise(BOUND_METHOD_DIMENSIONS, seed + 3250003):
        row = selected_row
        # A quoted companion source is compiled before its application consumer,
        # so an ordinary derived Type cannot close that source's generic base
        # over an application-owned value layout. Cross-module generic-base
        # publication is covered by the module-boundary family below; keep this
        # file-boundary family focused on owners wholly declared by one source.
        if row[1] == "generic-base" and row[-1] == "imported":
            row = row[:-1] + ("single",)
        # Likewise, a provider-local ordinary owner implementing an Interface
        # already closed over its own Struct layout requests specialization
        # before the consumer header exists. Generic owners defer that closure
        # naturally and retain the intended imported Struct coverage.
        if row[0] == "struct" and row[1] == "ordinary" and row[-1] == "imported":
            row = row[:-1] + ("single",)
        # A provider-local non-generic owner can otherwise register its closed
        # Interface using the synthetic application identity while the consumer
        # asks for the same source-declared payload through quoted-source
        # identity. Generic owners close on the consumer side and cover the
        # cross-boundary form without creating two runtime Interface IDs.
        if (
            row[0] in ("typed-object", "interface", "struct", "nested-generic")
            and row[1] == "ordinary"
            and row[2] in ("interface", "generic-routine")
            and row[-1] == "imported"
        ):
            row = row[:-1] + ("single",)
        if row not in bound_method_rows:
            bound_method_rows.append(row)
    for index, row in enumerate(bound_method_rows, 1):
        case_id = f"bound-method-{index:03d}"
        case_dir = output / case_id
        case_dir.mkdir()
        imported = row[-1] == "imported"
        if imported:
            (case_dir / f"{case_id}_provider.bmx").write_text(
                "SuperStrict\n\n"
                + bound_method_declarations(
                    row[1],
                    row[2],
                    core_payload_source(row[0], case_id)[0],
                    row[1] == "generic-base",
                ),
                encoding="utf-8",
            )
        source = case_dir / f"{case_id}.bmx"
        source.write_text(
            bound_method_application_source(case_id, row, imported), encoding="utf-8"
        )
        features = ",".join(
            f"{name}={value}" for name, value in zip(bound_method_dimension_names, row)
        )
        manifest.append(
            f"positive\t{case_id}\tgeneric-combination-ok:{case_id}\t"
            f"{source.as_posix()}\tfamily=bound-method,{features}"
        )

    generic_reference_dimension_names = tuple(GENERIC_REFERENCE_DIMENSIONS)
    for index, row in enumerate(
        select_pairwise(GENERIC_REFERENCE_DIMENSIONS, seed + 3500003), 1
    ):
        case_id = f"generic-reference-{index:03d}"
        case_dir = output / case_id
        case_dir.mkdir()
        imported = row[-1] == "imported"
        if imported:
            (case_dir / f"{case_id}_provider.bmx").write_text(
                generic_reference_provider_source(), encoding="utf-8"
            )
        source = case_dir / f"{case_id}.bmx"
        source.write_text(
            generic_reference_application_source(case_id, row, imported),
            encoding="utf-8",
        )
        features = ",".join(
            f"{name}={value}"
            for name, value in zip(generic_reference_dimension_names, row)
        )
        manifest.append(
            f"positive\t{case_id}\tgeneric-combination-ok:{case_id}\t"
            f"{source.as_posix()}\tfamily=generic-reference,{features}"
        )

    yield_dimension_names = tuple(YIELD_DIMENSIONS)
    for index, row in enumerate(select_pairwise(YIELD_DIMENSIONS, seed + 3750003), 1):
        case_id = f"yield-{index:03d}"
        case_dir = output / case_id
        case_dir.mkdir()
        imported = row[-1] == "imported"
        if imported:
            (case_dir / f"{case_id}_provider.bmx").write_text(
                yield_provider_source(), encoding="utf-8"
            )
        source = case_dir / f"{case_id}.bmx"
        source.write_text(
            yield_application_source(case_id, row, imported), encoding="utf-8"
        )
        features = ",".join(
            f"{name}={value}" for name, value in zip(yield_dimension_names, row)
        )
        manifest.append(
            f"positive\t{case_id}\tgeneric-combination-ok:{case_id}\t"
            f"{source.as_posix()}\tfamily=yield,{features}"
        )

    lifecycle_dimension_names = tuple(LIFECYCLE_DIMENSIONS)
    for index, row in enumerate(select_pairwise(LIFECYCLE_DIMENSIONS, seed + 5000003), 1):
        case_id = f"lifecycle-{index:03d}"
        case_dir = output / case_id
        case_dir.mkdir()
        source = case_dir / f"{case_id}.bmx"
        source.write_text(lifecycle_application_source(case_id, row), encoding="utf-8")
        features = ",".join(
            f"{name}={value}" for name, value in zip(lifecycle_dimension_names, row)
        )
        manifest.append(
            f"positive\t{case_id}\tgeneric-combination-ok:{case_id}\t"
            f"{source.as_posix()}\tfamily=lifecycle,{features}"
        )

    structural_dimension_names = tuple(STRUCTURAL_PROTOCOL_DIMENSIONS)
    for index, row in enumerate(
        select_pairwise(STRUCTURAL_PROTOCOL_DIMENSIONS, seed + 6000003), 1
    ):
        case_id = f"structural-protocol-{index:03d}"
        case_dir = output / case_id
        case_dir.mkdir()
        imported = row[-1] == "imported"
        if imported:
            (case_dir / f"{case_id}_provider.bmx").write_text(
                structural_provider_source(row), encoding="utf-8"
            )
        source = case_dir / f"{case_id}.bmx"
        source.write_text(
            structural_application_source(case_id, row, imported), encoding="utf-8"
        )
        features = ",".join(
            f"{name}={value}" for name, value in zip(structural_dimension_names, row)
        )
        manifest.append(
            f"positive\t{case_id}\tgeneric-combination-ok:{case_id}\t"
            f"{source.as_posix()}\tfamily=structural-protocol,{features}"
        )

    contract_dimension_names = tuple(CONTRACT_DIMENSIONS)
    for index, row in enumerate(
        select_pairwise(CONTRACT_DIMENSIONS, seed + 7000003), 1
    ):
        case_id = f"contract-{index:03d}"
        case_dir = output / case_id
        case_dir.mkdir()
        imported = row[-1] == "imported"
        if imported:
            (case_dir / f"{case_id}_provider.bmx").write_text(
                contract_provider_source(row), encoding="utf-8"
            )
        source = case_dir / f"{case_id}.bmx"
        source.write_text(
            contract_application_source(case_id, row, imported), encoding="utf-8"
        )
        features = ",".join(
            f"{name}={value}" for name, value in zip(contract_dimension_names, row)
        )
        manifest.append(
            f"positive\t{case_id}\tgeneric-combination-ok:{case_id}\t"
            f"{source.as_posix()}\tfamily=contract,{features}"
        )

    dependency_dimension_names = tuple(DEPENDENCY_DIMENSIONS)
    for index, row in enumerate(
        select_pairwise(DEPENDENCY_DIMENSIONS, seed + 8000003), 1
    ):
        case_id = f"dependency-{index:03d}"
        case_dir = output / case_id
        case_dir.mkdir()
        left, right = dependency_sources(case_id, row)
        (case_dir / "left.bmx").write_text(left, encoding="utf-8")
        (case_dir / "right.bmx").write_text(right, encoding="utf-8")
        source = case_dir / f"{case_id}.bmx"
        source.write_text(dependency_application_source(case_id, row), encoding="utf-8")
        features = ",".join(
            f"{name}={value}" for name, value in zip(dependency_dimension_names, row)
        )
        manifest.append(
            f"positive\t{case_id}\tgeneric-combination-ok:{case_id}\t"
            f"{source.as_posix()}\tfamily=dependency,{features}"
        )

    cleanup_dimension_names = tuple(CLEANUP_DIMENSIONS)
    for index, row in enumerate(
        select_pairwise(CLEANUP_DIMENSIONS, seed + 9000003), 1
    ):
        case_id = f"cleanup-{index:03d}"
        case_dir = output / case_id
        case_dir.mkdir()
        source = case_dir / f"{case_id}.bmx"
        source.write_text(cleanup_application_source(case_id, row), encoding="utf-8")
        features = ",".join(
            f"{name}={value}" for name, value in zip(cleanup_dimension_names, row)
        )
        manifest.append(
            f"positive\t{case_id}\tgeneric-combination-ok:{case_id}\t"
            f"{source.as_posix()}\tfamily=cleanup,{features}"
        )

    managed_conversion_dimension_names = tuple(MANAGED_CONVERSION_DIMENSIONS)
    for index, row in enumerate(
        select_pairwise(MANAGED_CONVERSION_DIMENSIONS, seed + 10000019), 1
    ):
        case_id = f"managed-conversion-{index:03d}"
        case_dir = output / case_id
        case_dir.mkdir()
        source = case_dir / f"{case_id}.bmx"
        source.write_text(
            managed_conversion_application_source(case_id, row), encoding="utf-8"
        )
        features = ",".join(
            f"{name}={value}"
            for name, value in zip(managed_conversion_dimension_names, row)
        )
        manifest.append(
            f"positive\t{case_id}\tgeneric-combination-ok:{case_id}\t"
            f"{source.as_posix()}\tfamily=managed-conversion,{features}"
        )

    module_suffix = f"P{seed}" if seed >= 0 else f"N{abs(seed)}"
    module_group = f"Bcc2GeneratedBoundary{module_suffix}"
    module_name = f"{module_group}.Owner"
    module_relative = f"mod/{module_group.lower()}.mod/owner.mod/owner.bmx"
    provider_dir = output / "module-boundary-provider"
    provider_dir.mkdir()
    provider = provider_dir / "owner.bmx"
    provider.write_text(module_boundary_provider_source(module_name), encoding="utf-8")
    (output / "module-setup.tsv").write_text(
        f"{module_name}\t{module_relative}\t{provider.as_posix()}\n", encoding="utf-8"
    )

    module_dimension_names = tuple(MODULE_BOUNDARY_DIMENSIONS)
    for index, row in enumerate(
        select_pairwise(MODULE_BOUNDARY_DIMENSIONS, seed + 4000003), 1
    ):
        case_id = f"module-boundary-{index:03d}"
        case_dir = output / case_id
        case_dir.mkdir()
        source = case_dir / f"{case_id}.bmx"
        source.write_text(
            module_boundary_application_source(case_id, row, module_name), encoding="utf-8"
        )
        features = ",".join(
            f"{name}={value}" for name, value in zip(module_dimension_names, row)
        )
        manifest.append(
            f"module-positive\t{case_id}\tgeneric-combination-ok:{case_id}\t"
            f"{source.as_posix()}\tfamily=module-boundary,{features}"
        )

    for case_id, row in CURATED_MODULE_POSITIVE_CASES.items():
        case_dir = output / case_id
        case_dir.mkdir()
        source = case_dir / f"{case_id}.bmx"
        source.write_text(
            module_boundary_application_source(case_id, row, module_name), encoding="utf-8"
        )
        features = ",".join(
            f"{name}={value}" for name, value in zip(module_dimension_names, row)
        )
        manifest.append(
            f"module-positive\t{case_id}\tgeneric-combination-ok:{case_id}\t"
            f"{source.as_posix()}\tfamily=module-boundary,curated-regression,{features}"
        )

    constructor_array_dimension_names = tuple(IMPORTED_CONSTRUCTOR_ARRAY_DIMENSIONS)
    for index, row in enumerate(
        select_pairwise(IMPORTED_CONSTRUCTOR_ARRAY_DIMENSIONS, seed + 4500007), 1
    ):
        case_id = f"imported-constructor-array-{index:03d}"
        case_dir = output / case_id
        case_dir.mkdir()
        source = case_dir / f"{case_id}.bmx"
        source.write_text(
            imported_constructor_array_application_source(case_id, row, module_name),
            encoding="utf-8",
        )
        features = ",".join(
            f"{name}={value}"
            for name, value in zip(constructor_array_dimension_names, row)
        )
        manifest.append(
            f"module-positive\t{case_id}\tgeneric-combination-ok:{case_id}\t"
            f"{source.as_posix()}\tfamily=imported-constructor-array,{features}"
        )

    managed_boundary_id = "regression-module-managed-conversion"
    managed_boundary_dir = output / managed_boundary_id
    managed_boundary_dir.mkdir()
    managed_boundary_source = managed_boundary_dir / f"{managed_boundary_id}.bmx"
    managed_boundary_source.write_text(
        f'''SuperStrict
Framework BRL.StandardIO
Import {module_name}

Local missing:Object
Local empty:String[] = BoundaryArray<String>(missing)
Local validObject:Object = ["left", "right"]
Local valid:String[] = BoundaryArray<String>(validObject)
Local wrongObject:Object = [1, 2]
Local wrong:String[] = BoundaryArray<String>(wrongObject)
Local visits:Int
For Local value:String = EachIn empty
    visits :+ 1
Next
If empty.length <> 0 Or valid.length <> 2 Or wrong.length <> 0 Or visits <> 0 Then Throw "{managed_boundary_id}: managed conversion"
Print "generic-combination-ok:{managed_boundary_id}"
''',
        encoding="utf-8",
    )
    manifest.append(
        f"module-positive\t{managed_boundary_id}\tgeneric-combination-ok:{managed_boundary_id}\t"
        f"{managed_boundary_source.as_posix()}\tfamily=module-boundary,managed-conversion,curated-regression"
    )

    for case_id, text in CURATED_POSITIVE_CASES.items():
        case_dir = output / case_id
        case_dir.mkdir()
        source = case_dir / f"{case_id}.bmx"
        source.write_text(text, encoding="utf-8")
        manifest.append(
            f"positive\t{case_id}\tgeneric-combination-ok:{case_id}\t"
            f"{source.as_posix()}\tcurated-regression"
        )

    for case_id, (diagnostic, text) in NEGATIVE_CASES.items():
        case_dir = output / case_id
        case_dir.mkdir()
        source = case_dir / f"{case_id}.bmx"
        source.write_text(text + "\n", encoding="utf-8")
        manifest.append(f"negative\t{case_id}\t{diagnostic}\t{source.as_posix()}\tcurated-negative")

    incremental_dir = output / "incremental"
    incremental_dir.mkdir()
    incremental_v1 = incremental_dir / "provider-v1.bmx"
    incremental_v2 = incremental_dir / "provider-v2.bmx"
    incremental_live = incremental_dir / "provider.bmx"
    incremental_app = incremental_dir / "incremental-app.bmx"
    incremental_v1.write_text(incremental_provider_source(1), encoding="utf-8")
    incremental_v2.write_text(incremental_provider_source(2), encoding="utf-8")
    incremental_app.write_text(incremental_application_source(seed), encoding="utf-8")
    (output / "incremental-setup.tsv").write_text(
        f"{incremental_v1.as_posix()}\t{incremental_v2.as_posix()}\t"
        f"{incremental_live.as_posix()}\t{incremental_app.as_posix()}\t"
        "generic-incremental-v1\tgeneric-incremental-v2\n",
        encoding="utf-8",
    )

    (output / "manifest.tsv").write_text("\n".join(manifest) + "\n", encoding="utf-8")
    (output / "seed.txt").write_text(str(seed) + "\n", encoding="ascii")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--seed", type=int, default=1337)
    args = parser.parse_args()
    write_corpus(args.output.resolve(), args.seed)


if __name__ == "__main__":
    main()
