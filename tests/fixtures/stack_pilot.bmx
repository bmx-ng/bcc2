SuperStrict

Framework BRL.StandardIO
Import Collections.Stack

Local stack:TStack<String> = New TStack<String>(2)
stack.Push("first")
stack.Push("second")
stack.Push("third")

If stack.Count() <> 3 Or stack.Peek() <> "third" Then RuntimeError "stack top"
If stack.Pop() <> "third" Then RuntimeError "stack order"

Local order:String
For Local value:String = EachIn stack
	order = order + value + ","
Next
If order <> "second,first," Then RuntimeError "stack iteration"

Print "stack-ok"
