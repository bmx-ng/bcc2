SuperStrict

Struct SRange
	Field first:Int = 2
	Field last:Int = first + 3

	Method Add(delta:Int)
		first = first + delta
		last = last + delta
	End Method

	Method Span:Int()
		Return last - first
	End Method

	Method New(seed:Int)
		Add(seed)
	End Method
End Struct

Local range:SRange = New SRange(10)
Local span:Int = range.Span()
Local temporarySpan:Int = New SRange(20).Span()
Local result:Int = span + temporarySpan
If result <> 6 Then result = 0
