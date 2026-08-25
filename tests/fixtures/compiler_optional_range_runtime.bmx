SuperStrict

Framework BRL.Blitz
Import BRL.Optional
Import BRL.Range
Import BRL.StandardIO

Global receiverEvaluations:Int
Global rangeEvaluations:Int

Type TMarker
End Type

Interface IMarker
End Interface

Type TInterfaceMarker Implements IMarker
End Type

Function CheckedText:String()
	receiverEvaluations :+ 1
	Return "abcdef"
End Function

Function CheckedRange:Range()
	rangeEvaluations :+ 1
	Return Range.FromUntil(1, 4)
End Function

Function Wrap<T>:Optional<T>(value:T)
	Return Optional<T>.FromValue(value)
End Function

Function SliceWithRange<T>:T[](values:T[], selected:Range)
	Return values[selected]
End Function

Function Fail(message:String)
	Throw "optional-range failure: " + message
End Function

Local absent:Optional<Int>
If Not absent.IsUndefined() Or absent.IsDefined() Or absent.HasValue() Then Fail("default state")

Local explicitNull:Optional<String> = Optional<String>.NullValue()
If Not explicitNull.IsNull() Or Not explicitNull.IsDefined() Or explicitNull.HasValue() Then Fail("null state")

Local answer:Optional<Int> = Wrap<Int>(42)
If Not answer.HasValue() Or answer.Value() <> 42 Or answer.ValueOr(7) <> 42 Then Fail("value state")

Local extracted:Int
If Not answer.TryGet(extracted) Or extracted <> 42 Then Fail("TryGet value")
extracted = 99
If absent.TryGet(extracted) Or extracted <> 0 Then Fail("TryGet undefined")

Local absentText:Optional<String>
Local extractedText:String = "stale"
If absentText.TryGet(extractedText) Or extractedText.Length <> 0 Then Fail("String sentinel")
Local absentArray:Optional<Int[]>
Local extractedArray:Int[] = [1]
If absentArray.TryGet(extractedArray) Or extractedArray.Length <> 0 Then Fail("Array sentinel")
Local absentObject:Optional<Object>
Local extractedObject:Object = New TMarker
If absentObject.TryGet(extractedObject) Or extractedObject Then Fail("Object sentinel")
Local absentInterface:Optional<IMarker>
Local extractedInterface:IMarker = New TInterfaceMarker
If absentInterface.TryGet(extractedInterface) Or extractedInterface Then Fail("Interface sentinel")
Local nested:Optional<Optional<Int>> = Optional<Optional<Int>>.FromValue(answer)
If Not nested.HasValue() Or nested.Value().Value() <> 42 Then Fail("nested Optional")

Local mapCalls:Int
Local mapOffset:Int = 8
Local render:Closure<String(value:Int)> = Function:String(value:Int)
	mapCalls :+ 1
	Return String(value + mapOffset)
End Function
If answer.Map<String>(render).Value() <> "50" Or mapCalls <> 1 Then Fail("Optional Map")
If Not absent.Map<String>(render).IsUndefined() Or Not Optional<Int>.NullValue().Map<String>(render).IsNull() Or mapCalls <> 1 Then Fail("Optional Map absence propagation")

Local recoverCalls:Int
Local recover:Closure<Optional<Int>()> = Function:Optional<Int>()
	recoverCalls :+ 1
	Return Optional<Int>.FromValue(9)
End Function
If absent.OrIfUndefined(recover).Value() <> 9 Or recoverCalls <> 1 Then Fail("Optional undefined recovery")
If answer.OrIfEmpty(recover).Value() <> 42 Or recoverCalls <> 1 Then Fail("Optional recovery laziness")

Local onValue:Closure<String(value:Int)> = Function:String(value:Int)
	Return "value" + value
End Function
Local onNull:Closure<String()> = Function:String()
	Return "null"
End Function
Local onUndefined:Closure<String()> = Function:String()
	Return "undefined"
End Function
Local onText:Closure<String(value:String)> = Function:String(value:String)
	Return value
End Function
If answer.Match<String>(onValue, onNull, onUndefined) <> "value42" Then Fail("Optional value Match")
If explicitNull.Match<String>(onText, onNull, onUndefined) <> "null" Then Fail("Optional null Match")
If absent.Match<String>(render, onNull, onUndefined) <> "undefined" Then Fail("Optional undefined Match")
Local visited:String
Local visitValue:Closure<(value:Int)> = Function(value:Int)
	visited = "value" + value
End Function
Local visitNull:Closure<()> = Function()
	visited = "null"
End Function
Local visitUndefined:Closure<()> = Function()
	visited = "undefined"
End Function
answer.Visit(visitValue, visitNull, visitUndefined)
If visited <> "value42" Then Fail("Optional Visit")

Local missingMapper:Closure<String(value:Int)>
Local nullClosureThrew:Int
Try
	answer.Map<String>(missingMapper)
Catch exception:TNullFunctionException
	nullClosureThrew = True
End Try
If Not nullClosureThrew Then Fail("selected null Optional Closure")

Local threw:Int
Try
	absent.Value()
Catch exception:TOptionalValueException
	threw = True
End Try
If Not threw Then Fail("Value exception")

If CheckedText()[CheckedRange()] <> "bcd" Then Fail("String Range slice")
If receiverEvaluations <> 1 Or rangeEvaluations <> 1 Then Fail("single evaluation")
If "abcdef"[Range.Until(2)] <> "ab" Then Fail("open start")
If "abcdef"[Range.From(4)] <> "ef" Then Fail("open end")
Local all:Range
If "abcdef"[all] <> "abcdef" Then Fail("default Range")
If Not all.IsAll() Or all.IsBounded() Then Fail("Range bound queries")
If "abcdef"[Range.Single(2)] <> "c" Or "abcdef"[Range.FromLength(2, 2)] <> "cd" Then Fail("Range constructors")
If Not Range.FromLength(3, -1).Resolve(6).IsEmpty() Then Fail("negative Range length")
Local resolved:ResolvedRange = Range.FromUntil(-2, 8).Resolve(6)
If resolved.Start() <> -2 Or resolved.EndExclusive() <> 8 Or resolved.Length() <> 10 Then Fail("Range Resolve")
Local clamped:ResolvedRange = Range.FromUntil(-2, 8).Clamp(6)
If clamped.Start() <> 0 Or clamped.EndExclusive() <> 6 Or clamped.Length() <> 6 Then Fail("Range Clamp")
Local reversed:ResolvedRange = Range.FromUntil(5, 2).Resolve(6)
If reversed.Start() <> 5 Or reversed.EndExclusive() <> 2 Or Not reversed.IsEmpty() Then Fail("reversed resolved Range")
If "abcdef"[Range.UntilFromEnd(2)] <> "abcd" Then Fail("Range end-relative prefix")
If "abcdef"[Range.FromEnd(2)] <> "ef" Then Fail("Range end-relative suffix")
Local relativeMiddle:Range = Range.FromEndpoints(RangeEndpoint.FromEnd(5), RangeEndpoint.FromEnd(2))
If "abcdef"[relativeMiddle] <> "bcd" Then Fail("Range relative endpoints")
If Not relativeMiddle.Resolve(6).Contains(2) Or relativeMiddle.Resolve(6).Contains(4) Then Fail("ResolvedRange Contains")
Local literalMiddle:Range = 1..^2
Local literalSuffix:Range = (^2..)
If "abcdef"[literalMiddle] <> "bcd" Or "abcdef"[literalSuffix] <> "ef" Then Fail("Range expression syntax")
If "abcdef"[2..^1] <> "cde" Or "abcdef"[^5..^2] <> "bcd" Then Fail("direct from-end String slice")
Local coordinateOverflow:Int
Try
	Range.Single(2147483647)
Catch exception:TRangeCoordinateException
	coordinateOverflow = True
End Try
If Not coordinateOverflow Then Fail("Range coordinate overflow")

Local values:Int[] = [10, 20, 30, 40]
Local middle:Int[] = values[Range.FromUntil(1, 3)]
If middle.Length <> 2 Or middle[0] <> 20 Or middle[1] <> 30 Then Fail("Array Range slice")
Local genericIntegers:Int[] = SliceWithRange<Int>(values, Range.FromUntil(1, 3))
If genericIntegers.Length <> 2 Or genericIntegers[0] <> 20 Or genericIntegers[1] <> 30 Then Fail("generic Int Array Range slice")
Local genericStrings:String[] = SliceWithRange<String>(["a", "b", "c"], Range.From(1))
If genericStrings.Length <> 2 Or genericStrings[0] <> "b" Or genericStrings[1] <> "c" Then Fail("generic String Array Range slice")
Local genericRelative:Int[] = SliceWithRange<Int>(values, Range.FromEnd(2))
If genericRelative.Length <> 2 Or genericRelative[0] <> 30 Or genericRelative[1] <> 40 Then Fail("generic end-relative Array Range slice")
Local directRelative:Int[] = values[1..^1]
If directRelative.Length <> 2 Or directRelative[0] <> 20 Or directRelative[1] <> 30 Then Fail("direct from-end Array slice")

Print "optional-range-ok"
