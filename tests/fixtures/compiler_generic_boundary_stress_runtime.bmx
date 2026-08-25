SuperStrict

Framework BRL.Blitz
Import BRL.StandardIO

Type TIndexBase<K, V>
	Field value:V

	Method Operator[]:V(key:K)
		Return value
	End Method

	Method Operator[]=(key:K, newValue:V)
		value = newValue
	End Method

	Method Choose:String(candidate:V)
		Return "value"
	End Method

	Method Choose:String(candidate:Object)
		Return "object"
	End Method
End Type

Type TIndexPlane<A, B, V> Extends TIndexBase<A, TIndexBase<B, V>>
	Method Operator[]=(first:A, second:B, newValue:V)
		Local row:TIndexBase<B, V> = Self[first]
		If Not row Then
			row = New TIndexBase<B, V>
			Self[first] = row
		End If
		row[second] = newValue
	End Method

	Method Operator[]:V(first:A, second:B)
		Local row:TIndexBase<B, V> = Self[first]
		If Not row Then Return Null
		Return row[second]
	End Method
End Type

Interface IReadable<T>
	Method Read:T()
End Interface

Interface ILayeredReadable<T> Extends IReadable<T>
End Interface

Type TValue<T> Implements ILayeredReadable<T>
	Field value:T

	Method Read:T()
		Return value
	End Method
End Type

Function ReadConstrained<T, V>:V(source:T) Where T Extends IReadable<V>
	Return source.Read()
End Function

Type TNode<T>
	Field value:T
	Field children:TNode<T>[]
	Field project:Closure<T(node:TNode<T>)>

	Method Evaluate:T()
		Return project(Self)
	End Method
End Type

Type TEdge<T>
	Field source:TNode<T>
	Field target:TNode<T>

	Method TargetValue:T()
		Return target.value
	End Method
End Type

Local plane:TIndexPlane<Int, Int, String> = New TIndexPlane<Int, Int, String>
plane[4, 7] = "operator-ok"
If plane[4, 7] <> "operator-ok" Then Throw "inherited generic Operator[] failed"
If plane.Choose(New TIndexBase<Int, String>) <> "value" Then Throw "specialized overload failed"

Local readable:TValue<String> = New TValue<String>
readable.value = "constraint-ok"
If ReadConstrained<TValue<String>, String>(readable) <> "constraint-ok" Then Throw "transitive constraint failed"

Local root:TNode<String> = New TNode<String>
Local child:TNode<String> = New TNode<String>
root.value = "root"
child.value = "recursive-ok"
root.children = [child]
root.project = Function:String(node:TNode<String>)
	Return node.children[0].value
End Function

Local edge:TEdge<String> = New TEdge<String>
edge.source = root
edge.target = child
If root.Evaluate() <> "recursive-ok" Or edge.TargetValue() <> "recursive-ok" Then Throw "recursive generic graph failed"

Print "generic-boundary-stress-ok"
