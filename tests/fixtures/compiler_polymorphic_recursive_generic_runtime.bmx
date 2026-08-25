SuperStrict

Framework BRL.Blitz
Import Collections.LinkedList
Import BRL.StandardIO

Type TGList<T> Extends TLinkedList<T>
	Method ToBatches:TGList<TGList<T>>(batchSize:Int)
		Local out:TGList<TGList<T>> = New TGList<TGList<T>>()
		Local cur:TGList<T> = New TGList<T>()
		out.AddLast(cur)

		For Local value:T = EachIn Self
			If cur.Count() >= batchSize Then
				cur = New TGList<T>()
				out.AddLast(cur)
			End If
			cur.AddLast(value)
		Next

		Return out
	End Method

	Method Forward:TGList<TGList<T>>(batchSize:Int)
		Return ToBatches(batchSize)
	End Method

	Method GetNodesArray:TLinkedListNode<T>[]()
		Local nodes:TGList<TLinkedListNode<T>> = New TGList<TLinkedListNode<T>>()
		Return nodes.ToArray()
	End Method

	Method IterNodes:TGListNodeIterator<T>()
		Return New TGListNodeIterator<T>(Self)
	End Method
End Type

Type TGListNodeIterator<T> Implements IIterator<TLinkedListNode<T>>
	Field head:TLinkedListNode<T>
	Field current:TLinkedListNode<T>

	Method New(list:TGList<T>)
		head = list.First()
	End Method

	Method MoveNext:Int()
		If Not current Then
			current = head
		Else
			current = current.GetNext()
			If current = head Then Return False
		End If
		Return current <> Null
	End Method

	Method Current:TLinkedListNode<T>()
		Return current
	End Method
End Type

Local values:TGList<String> = New TGList<String>()
For Local index:Int = 0 Until 5
	values.AddLast(String(index))
Next

Local batches:TGList<TGList<String>> = values.ToBatches(2)
If batches.Count() <> 3 Then Throw "first demanded specialization depth failed"

Local forwarded:TGList<TGList<String>> = values.Forward(2)
If forwarded.Count() <> 3 Then Throw "transitive method-body demand failed"

Local nodes:TLinkedListNode<String>[] = values.GetNodesArray()
If nodes.length <> 0 Then Throw "transformed-argument polymorphic recursion failed"

Local visited:Int
For Local node:TLinkedListNode<String> = EachIn values.IterNodes()
	visited :+ 1
Next
If visited <> 5 Then Throw "cross-artifact generic iterator dependency failed"

Local nested:TGList<TGList<TGList<String>>> = batches.ToBatches(2)
If nested.Count() <> 2 Then Throw "second demanded specialization depth failed"

Print "polymorphic-recursive-generic-ok"
