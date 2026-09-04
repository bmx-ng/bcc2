SuperStrict

Framework BRL.StandardIO

Import BRL.Sequence
Import Bcc2SequenceBoundaryTest.Functions

Type TSequenceBoundaryMarker
	Field value:Int
End Type

Interface ISequenceBoundaryMarker
	Method Value:Int()
End Interface

Type TSequenceBoundaryInterfaceMarker Implements ISequenceBoundaryMarker
	Field value:Int

	Method Value:Int()
		Return value
	End Method
End Type

Struct SSequenceBoundaryPoint
	Field x:Int
End Struct

Enum ESequenceBoundaryValue
	First
	Second
End Enum

Local values:Int[] = [1, 2, 3, 4, 5, 6, 7, 8]

' Imported generic constructors must match arrays whose element identity is
' owned by the consuming application rather than the defining module.
Local marker:TSequenceBoundaryMarker = New TSequenceBoundaryMarker
marker.value = 11
If New Sequence<TSequenceBoundaryMarker>([marker]).FirstOrNone().Value() <> marker Then Throw "local Type array constructor failed"

Local interfaceMarker:TSequenceBoundaryInterfaceMarker = New TSequenceBoundaryInterfaceMarker
interfaceMarker.value = 13
Local interfaceValue:ISequenceBoundaryMarker = interfaceMarker
If New Sequence<ISequenceBoundaryMarker>([interfaceValue]).FirstOrNone().Value().Value() <> 13 Then Throw "local Interface array constructor failed"

Local point:SSequenceBoundaryPoint
point.x = 17
If New Sequence<SSequenceBoundaryPoint>([point]).FirstOrNone().Value().x <> 17 Then Throw "local Struct array constructor failed"

If New Sequence<ESequenceBoundaryValue>([ESequenceBoundaryValue.Second]).FirstOrNone().Value() <> ESequenceBoundaryValue.Second Then Throw "local Enum array constructor failed"

Local directFree:Long = Sequence<Int>.FromArray(values).Filter(ModuleSequenceEven).Map<Int>(ModuleSequenceTriple).Fold<Long>(Long(0), ModuleSequenceAdd)
If directFree <> 60 Then Throw "module-import free Function pipeline failed"

Local directType:Long = Sequence<Int>.FromArray(values).Filter(TModuleSequenceFunctions.AboveTwo).Map<Int>(TModuleSequenceFunctions.Double).Fold<Long>(Long(0), TModuleSequenceFunctions.Add)
If directType <> 66 Then Throw "module-import Type Function pipeline failed"

Local directGenericType:Long = Sequence<Int>.FromArray(values).Map<Int>(TModuleGenericSequenceFunctions<Int>.Identity).Fold<Long>(Long(0), ModuleSequenceAdd)
If directGenericType <> 36 Then Throw "module-import generic Type Function pipeline failed"

Local directGenericRoutine:Long = Sequence<Int>.FromArray(values).Map<Int>(ModuleGenericIdentity<Int>).Fold<Long>(Long(0), ModuleSequenceAdd)
If directGenericRoutine <> 36 Then Throw "module-import generic routine-reference pipeline failed"

Local first:Int = Sequence<Int>.FromArray(values).Filter(ModuleSequenceEven).Skip(1).FirstOrNone().Value()
If first <> 4 Then Throw "module-import FirstOrNone pipeline failed"

ModuleSequenceReset()
Sequence<Int>.FromArray(values).Filter(ModuleSequenceEven).Take(2).ForEach(ModuleSequenceVisit)
If ModuleSequenceVisited() <> 6 Then Throw "module-import ForEach pipeline failed"

Local materialized:Int[] = Sequence<Int>.FromArray(values).Filter(ModuleSequenceEven).Skip(1).Take(2).ToArray()
If materialized.length <> 2 Or materialized[0] <> 4 Or materialized[1] <> 6 Then Throw "module-import ToArray pipeline failed"

If Sequence<Int>.FromArray(values).Count(ModuleSequenceEven) <> 4 Then Throw "module-import predicate Count failed"
If Sequence<Int>.FromArray(values).FirstOrNone(ModuleSequenceEven).Value() <> 2 Then Throw "module-import predicate FirstOrNone failed"
If Sequence<Int>.FromArray(values).Map<Int>(ModuleSequenceTriple).LastOrNone().Value() <> 24 Then Throw "module-import LastOrNone failed"

Local selected:Int(value:Int) = ModuleSequenceEven
Local indirectVariable:Int = Sequence<Int>.FromArray(values).Filter(selected).Count()
If indirectVariable <> 4 Then Throw "module-import function-variable pipeline failed"

Local indirectGeneric:Long = Sequence<Int>.FromArray(values).Map<Int>(ModuleSequenceIdentity<Int>()).Fold<Long>(Long(0), ModuleSequenceAdd)
If indirectGeneric <> 36 Then Throw "module-import generic function-result pipeline failed"

Local returnedSequence:Int = ModuleEvenSequence(values).Count()
If returnedSequence <> 4 Then Throw "module-import returned Sequence fallback failed"

Local flattened:Int[] = Sequence<Int>.FromArray([1, 2]).FlatMap<Int>(ModuleExpandSequence).ToArray()
If flattened.length <> 4 Or flattened[0] <> 1 Or flattened[1] <> 10 Or flattened[2] <> 2 Or flattened[3] <> 20 Then Throw "module-import FlatMap failed"

Local prefix:Int[] = Sequence<Int>.FromArray([1, 3, 5, 2]).TakeWhile(ModuleSequenceBelowFive).Append(9).ToArray()
If prefix.length <> 3 Or prefix[0] <> 1 Or prefix[1] <> 3 Or prefix[2] <> 9 Then Throw "module-import TakeWhile/Append failed"

Local suffix:Int[] = Sequence<Int>.FromArray([1, 3, 5, 2]).SkipWhile(ModuleSequenceBelowFive).Prepend(0).ToArray()
If suffix.length <> 3 Or suffix[0] <> 0 Or suffix[1] <> 5 Or suffix[2] <> 2 Then Throw "module-import SkipWhile/Prepend failed"

If Sequence<Int>.FromArray([1, 3, 5, 2]).TakeWhile(ModuleSequenceBelowFive).Count() <> 2 Then Throw "module-import fused TakeWhile failed"
If Sequence<Int>.FromArray([1, 3, 5, 2]).SkipWhile(ModuleSequenceBelowFive).FirstOrNone().Value() <> 5 Then Throw "module-import fused SkipWhile failed"

Local joined:Sequence<Int> = Sequence<Int>.FromArray([1, 2]).Concat(Sequence<Int>.FromArray([3]))
If joined.ElementAtOrNone(2).Value() <> 3 Or joined.SingleOrNone().IsDefined() Then Throw "module-import Concat terminals failed"

Print "sequence-module-boundary-ok"
