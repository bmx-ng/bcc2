SuperStrict

Framework BRL.StandardIO

Local topLevelCaptured:String = "module"
Local topLevelReader:Closure<String()> = Function()
	Return topLevelCaptured
End Function
topLevelCaptured :+ "-environment"

Struct SCapturedShape
	Field number:Int
	Field text:String
End Struct

Function MakeStructReader:Closure<String()>()
	Local shape:SCapturedShape
	shape.number = 42
	shape.text = "struct"
	Return Function()
		Return shape.text + "-" + shape.number
	End Function
End Function

Function MakeCatchReader:Closure<String()>(prefix:String)
	Try
		Throw "caught"
	Catch problem:String
		problem :+ "-mutated"
		Return Function()
			Return prefix + "-" + problem
		End Function
	End Try
End Function

Function MakeNestedCatchReader:Closure<String()>()
	Try
		Throw "outer"
	Catch outerProblem:String
		Try
			Throw "inner"
		Catch innerProblem:String
			Return Function()
				Return outerProblem + "-" + innerProblem
			End Function
		End Try
	End Try
End Function

Function MakeCounter:Closure<Int()>(initial:Int)
	Local count:Int = initial
	Local result:Closure<Int()> = Function()
		count :+ 1
		Return count
	End Function
	count :+ 10
	Return result
End Function

Function MakeSnapshotReader:Closure<Int()>()
	Local changing:Int = 10
	Local snapshot:Int = changing
	Local result:Closure<Int()> = Function()
		Return snapshot
	End Function
	changing = 20
	Return result
End Function

Function MakeAdder:Closure<Int(value:Int)>(amount:Int)
	Return Function(value:Int)
		Return value + amount
	End Function
End Function

Function MakeText:Closure<String()>(prefix:String)
	Local suffix:String = "-retained"
	Return Function()
		Return prefix + suffix
	End Function
End Function

Global producedNestedSelf:Closure<Int()>

Function MakeNestedFactory:Closure<Closure<Int()>()>(initial:Int)
	Local parentValue:Int = initial
	Return Function()
		Local childValue:Int = 10
		Return Function()
			parentValue :+ 1
			childValue :+ 2
			Return parentValue + childValue
		End Function
	End Function
End Function

Function InvokeNestedFactory:Int(factory:Closure<Closure<Int()>()>)
	Local callback:Closure<Int()> = factory()
	Return callback()
End Function

Global increment:Closure<Int()>
Global current:Closure<Int()>

Function MakePair()
	Local count:Int = 20
	increment = Function()
		count :+ 1
		Return count
	End Function
	current = Function()
		Return count
	End Function
End Function

Type TClosureCaptureOwner
	Field offset:Int

	Method New(offset:Int)
		Self.offset = offset
	End Method

	Method Adjust:Int(value:Int)
		Return value + offset
	End Method

	Method Make:Closure<Int(value:Int)>()
		Return Function(value:Int)
			Return Self.Adjust(value) + offset - Self.offset
		End Function
	End Method
End Type

Type TReadOnlyClosureOwner
	Field ReadOnly label:String

	Method New(label:String)
		Self.label = label
	End Method

	Method Reader:Closure<String()>()
		Return Function()
			Return label
		End Function
	End Method
End Type

Type TDerivedClosureCaptureOwner Extends TClosureCaptureOwner
	Method Adjust:Int(value:Int)
		Return value + offset + 1
	End Method

	Method MakeBase:Closure<Int(value:Int)>()
		Return Function(value:Int)
			Return Super.Adjust(value)
		End Function
	End Method

	Method MakeNestedSelf:Closure<()>()
		Return Function()
			Local childValue:Int = 1
			producedNestedSelf = Function()
				Return Self.Adjust(34) + childValue
			End Function
		End Function
	End Method
End Type

Local first:Closure<Int()> = MakeCounter(1)
Local second:Closure<Int()> = MakeCounter(100)
If first() <> 12 Or first() <> 13 Then Throw "escaping Local capture mutation failed"
If second() <> 111 Then Throw "Closure environments were shared between parent invocations"

Local snapshotReader:Closure<Int()> = MakeSnapshotReader()
If snapshotReader() <> 10 Then Throw "dedicated Local snapshot capture followed later source mutation"

Local addSeven:Closure<Int(value:Int)> = MakeAdder(7)
If addSeven(35) <> 42 Then Throw "captured value parameter failed"

MakePair()
If current() <> 20 Or increment() <> 21 Or current() <> 21 Then Throw "sibling Closures did not share one lexical cell"

Local text:Closure<String()> = MakeText("capture")
Local caught:Closure<String()> = MakeCatchReader("prefix")
Local nestedCaught:Closure<String()> = MakeNestedCatchReader()
Local structReader:Closure<String()> = MakeStructReader()
For Local index:Int = 0 Until 1000
	Local pressure:String = "allocation-" + index
Next
GCCollect()
If text() <> "capture-retained" Then Throw "managed captured values were not retained"
If caught() <> "prefix-caught-mutated" Then Throw "Catch capture did not retain its fresh mutable cell"
If nestedCaught() <> "outer-inner" Then Throw "nested Catch capture did not retain its activation chain"
If structReader() <> "struct-42" Then Throw "Struct capture did not retain its managed fields"
If topLevelReader() <> "module-environment" Then Throw "top-level Local capture did not share its module environment"

Local nestedFactory:Closure<Closure<Int()>()> = MakeNestedFactory(10)
Local nestedFirst:Closure<Int()> = nestedFactory()
Local nestedSecond:Closure<Int()> = nestedFactory()
nestedFactory = Null
GCCollect()
If nestedFirst() <> 23 Then Throw "nested Closure did not retain its parent and owned lexical cells"
If nestedSecond() <> 24 Then Throw "nested Closure did not share its inherited parent cell"
If nestedFirst() <> 27 Then Throw "nested Closure child cells were copied or shared incorrectly"
If InvokeNestedFactory(MakeNestedFactory(20)) <> 33 Then Throw "Closure-valued Closure parameters did not preserve their recursive signature"

Local owner:TClosureCaptureOwner = New TDerivedClosureCaptureOwner(6)
Local capturedSelf:Closure<Int(value:Int)> = owner.Make()
owner = Null
GCCollect()
If capturedSelf(35) <> 42 Then Throw "captured Self was not retained or virtual dispatch was lost"

Local readOnlyOwner:TReadOnlyClosureOwner = New TReadOnlyClosureOwner("read-only")
Local readOnlyReader:Closure<String()> = readOnlyOwner.Reader()
readOnlyOwner = Null
GCCollect()
If readOnlyReader() <> "read-only" Then Throw "captured ReadOnly field was not retained through Self"

Local nestedSelfOwner:TDerivedClosureCaptureOwner = New TDerivedClosureCaptureOwner(6)
Local nestedSelfFactory:Closure<()> = nestedSelfOwner.MakeNestedSelf()
nestedSelfFactory()
Local nestedSelf:Closure<Int()> = producedNestedSelf
nestedSelfOwner = Null
nestedSelfFactory = Null
GCCollect()
If nestedSelf() <> 42 Then Throw "nested Closure did not retain inherited Self through its parent chain"

Local superOwner:TDerivedClosureCaptureOwner = New TDerivedClosureCaptureOwner(7)
Local capturedSuper:Closure<Int(value:Int)> = superOwner.MakeBase()
superOwner = Null
GCCollect()
If capturedSuper(35) <> 42 Then Throw "captured Super did not retain Self or lost static base dispatch"

Print "closure-capture-ok"
