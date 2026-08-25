SuperStrict

Framework BRL.StandardIO

Import BRL.Sequence
Import "sequence_boundary_file_functions.bmx"

Local values:Int[] = [1, 2, 3, 4, 5, 6, 7, 8]

Local directFree:Long = Sequence<Int>.FromArray(values).Filter(FileSequenceEven).Map<Int>(FileSequenceTriple).Fold<Long>(Long(0), FileSequenceAdd)
If directFree <> 60 Then Throw "file-import free Function pipeline failed"

Local directType:Long = Sequence<Int>.FromArray(values).Filter(TFileSequenceFunctions.AboveTwo).Map<Int>(TFileSequenceFunctions.Double).Fold<Long>(Long(0), TFileSequenceFunctions.Add)
If directType <> 66 Then Throw "file-import Type Function pipeline failed"

Local directGenericType:Long = Sequence<Int>.FromArray(values).Map<Int>(TFileGenericSequenceFunctions<Int>.Identity).Fold<Long>(Long(0), FileSequenceAdd)
If directGenericType <> 36 Then Throw "file-import generic Type Function pipeline failed"

Local directGenericRoutine:Long = Sequence<Int>.FromArray(values).Map<Int>(FileGenericIdentity<Int>).Fold<Long>(Long(0), FileSequenceAdd)
If directGenericRoutine <> 36 Then Throw "file-import generic routine-reference pipeline failed"

Local first:Int = Sequence<Int>.FromArray(values).Filter(FileSequenceEven).Skip(1).FirstOrNone().Value()
If first <> 4 Then Throw "file-import FirstOrNone pipeline failed"

FileSequenceReset()
Sequence<Int>.FromArray(values).Filter(FileSequenceEven).Take(2).ForEach(FileSequenceVisit)
If FileSequenceVisited() <> 6 Then Throw "file-import ForEach pipeline failed"

Local materialized:Int[] = Sequence<Int>.FromArray(values).Filter(FileSequenceEven).Skip(1).Take(2).ToArray()
If materialized.length <> 2 Or materialized[0] <> 4 Or materialized[1] <> 6 Then Throw "file-import ToArray pipeline failed"

If Sequence<Int>.FromArray(values).Count(FileSequenceEven) <> 4 Then Throw "file-import predicate Count failed"
If Sequence<Int>.FromArray(values).FirstOrNone(FileSequenceEven).Value() <> 2 Then Throw "file-import predicate FirstOrNone failed"
If Sequence<Int>.FromArray(values).Map<Int>(FileSequenceTriple).LastOrNone().Value() <> 24 Then Throw "file-import LastOrNone failed"

Local selected:Int(value:Int) = FileSequenceEven
Local indirectVariable:Int = Sequence<Int>.FromArray(values).Filter(selected).Count()
If indirectVariable <> 4 Then Throw "file-import function-variable pipeline failed"

Local indirectGeneric:Long = Sequence<Int>.FromArray(values).Map<Int>(FileSequenceIdentity<Int>()).Fold<Long>(Long(0), FileSequenceAdd)
If indirectGeneric <> 36 Then Throw "file-import generic function-result pipeline failed"

Local returnedSequence:Int = FileEvenSequence(values).Count()
If returnedSequence <> 4 Then Throw "file-import returned Sequence fallback failed"

Local flattened:Int[] = Sequence<Int>.FromArray([1, 2]).FlatMap<Int>(FileExpandSequence).ToArray()
If flattened.length <> 4 Or flattened[0] <> 1 Or flattened[1] <> 10 Or flattened[2] <> 2 Or flattened[3] <> 20 Then Throw "file-import FlatMap failed"

Local prefix:Int[] = Sequence<Int>.FromArray([1, 3, 5, 2]).TakeWhile(FileSequenceBelowFive).Append(9).ToArray()
If prefix.length <> 3 Or prefix[0] <> 1 Or prefix[1] <> 3 Or prefix[2] <> 9 Then Throw "file-import TakeWhile/Append failed"

Local suffix:Int[] = Sequence<Int>.FromArray([1, 3, 5, 2]).SkipWhile(FileSequenceBelowFive).Prepend(0).ToArray()
If suffix.length <> 3 Or suffix[0] <> 0 Or suffix[1] <> 5 Or suffix[2] <> 2 Then Throw "file-import SkipWhile/Prepend failed"

If Sequence<Int>.FromArray([1, 3, 5, 2]).TakeWhile(FileSequenceBelowFive).Count() <> 2 Then Throw "file-import fused TakeWhile failed"
If Sequence<Int>.FromArray([1, 3, 5, 2]).SkipWhile(FileSequenceBelowFive).FirstOrNone().Value() <> 5 Then Throw "file-import fused SkipWhile failed"

Local joined:Sequence<Int> = Sequence<Int>.FromArray([1, 2]).Concat(Sequence<Int>.FromArray([3]))
If joined.ElementAtOrNone(2).Value() <> 3 Or joined.SingleOrNone().IsDefined() Then Throw "file-import Concat terminals failed"

Print "sequence-file-boundary-ok"
