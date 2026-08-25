SuperStrict

Framework BRL.StandardIO
Import Collections.LinkedList

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
