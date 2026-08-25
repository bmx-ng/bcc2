SuperStrict

Framework BRL.StandardIO

Struct SCompositionCell<T>
	Field value:T
	Field history:T[]
	Field transform:Closure<T(value:T)>
End Struct

Function BuildCompositionCells<T>:SCompositionCell<T>[](first:T, second:T, transform:Closure<T(value:T)>)
	Local cell:SCompositionCell<T>
	cell.value = first
	cell.history = [first]
	cell.history :+ [second]
	cell.transform = transform
	Local result:SCompositionCell<T>[] = [cell]
	Return result + [cell]
End Function

Function CompositionDefault<T>:T(value:T = Null)
	Return value
End Function

Type TCompositionBase<A, B>
	Field first:A
	Field second:B

	Method Describe:String()
		Return "base"
	End Method
End Type

Type TCompositionMiddle<X> Extends TCompositionBase<String, X[]>
	Method Last:X()
		Return second[second.length - 1]
	End Method

	Method Describe:String() Override
		Return "middle:" + first
	End Method
End Type

Type TCompositionLeaf<Y> Extends TCompositionMiddle<Y>
	Method Describe:String() Override
		Return "leaf:" + Super.Describe()
	End Method
End Type

Type TCompositionGrid<T>
	Field values:T[,]

	Method New(width:Int, height:Int)
		values = New T[width, height]
	End Method

	Method Operator []:T(x:Int, y:Int)
		Return values[x, y]
	End Method

	Method Operator []=(x:Int, y:Int, value:T)
		values[x, y] = value
	End Method
End Type

Struct SCompositionPair<T>
	Field left:T
	Field right:T
End Struct

Type TCompositionFactory
	Method Pair<T>:SCompositionPair<T>(left:T, right:T)
		Local result:SCompositionPair<T>
		result.left = left
		result.right = right
		Return result
	End Method
End Type

Type TCompositionPayload
	Field text:String

	Method New(text:String)
		Self.text = text
	End Method
End Type

Local decorate:Closure<TCompositionPayload(value:TCompositionPayload)> = Function(value:TCompositionPayload)
	Return New TCompositionPayload("[" + value.text + "]")
End Function
Local cells:SCompositionCell<TCompositionPayload>[] = BuildCompositionCells<TCompositionPayload>(New TCompositionPayload("first"), New TCompositionPayload("second"), decorate)
GCCollect()
If cells.length <> 2 Or cells[0].history[1].text <> "second" Or cells[1].transform(cells[1].value).text <> "[first]" Then RuntimeError "generic Struct, Array, and Closure composition failed"

Local defaultText:String = CompositionDefault<String>()
Local defaultValues:Int[] = CompositionDefault<Int[]>()
Local defaultObject:Object = CompositionDefault<Object>()
Local defaultClosure:Closure<Int()> = CompositionDefault<Closure<Int()>>()
If defaultText <> "" Or defaultValues.length <> 0 Or defaultObject Or defaultClosure Then RuntimeError "closed generic managed defaults violated runtime sentinels"

Local leaf:TCompositionLeaf<TCompositionPayload> = New TCompositionLeaf<TCompositionPayload>
leaf.first = "name"
leaf.second = [New TCompositionPayload("one"), New TCompositionPayload("two")]
Local base:TCompositionBase<String, TCompositionPayload[]> = leaf
If base.Describe() <> "leaf:middle:name" Or leaf.Last().text <> "two" Then RuntimeError "multi-level substituted inheritance failed"

Local grid:TCompositionGrid<String> = New TCompositionGrid<String>(2, 3)
grid[1, 2] = "ranked"
If grid[1, 2] <> "ranked" Then RuntimeError "generic ranked indexing operator failed"

Local pair:SCompositionPair<String> = New TCompositionFactory.Pair<String>("left", "right")
If pair.left <> "left" Or pair.right <> "right" Then RuntimeError "ordinary-owner generic method failed"

Print "generic-composition-ok"
