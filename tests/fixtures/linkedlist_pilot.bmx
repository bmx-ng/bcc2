SuperStrict

Framework BRL.StandardIO
Import Collections.LinkedList

Type TFoo
	Field name:String

	Method New(name:String)
		Self.name = name
	End Method
End Type

Local values:TLinkedList<String> = New TLinkedList<String>
values.AddLast("two")
values.AddFirst("one")
values.AddLast("three")

If values.Count() <> 3 Then RuntimeError "LinkedList Count mismatch"
If values.FirstValue() <> "one" Then RuntimeError "LinkedList first value mismatch"
If values.LastValue() <> "three" Then RuntimeError "LinkedList last value mismatch"
If values.Shift() <> "one" Then RuntimeError "LinkedList Shift mismatch"
If values.Pop() <> "three" Then RuntimeError "LinkedList Pop mismatch"
If values.Count() <> 1 Or values.FirstValue() <> "two" Then RuntimeError "LinkedList removal mismatch"

Local objects:TLinkedList<TFoo> = New TLinkedList<TFoo>
objects.AddLast(New TFoo("first"))
objects.AddLast(New TFoo("second"))

Local joined:String
For Local value:TFoo = EachIn objects
	joined :+ value.name
Next
If joined <> "firstsecond" Then RuntimeError "LinkedList application-local Type mismatch"

Print "linkedlist-pilot-ok"
