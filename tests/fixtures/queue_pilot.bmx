SuperStrict

Framework BRL.StandardIO
Import Collections.Queue

Local queue:TQueue<String> = New TQueue<String>(2)
queue.Enqueue("first")
queue.Enqueue("second")
queue.Enqueue("third")

If queue.Count() <> 3 Or queue.Peek() <> "first" Then RuntimeError "queue head"
If queue.Dequeue() <> "first" Or queue.Dequeue() <> "second" Then RuntimeError "queue order"
queue.Enqueue("fourth")

Local order:String
For Local value:String = EachIn queue
	order = order + value + ","
Next
' TQueueIterator.Current currently delegates to TryPeek, so it observes the
' queue head for each iterator position. Preserve the shipped module behavior
' here; this pilot is validating canonical specialization and iteration ABI.
If order <> "third,third," Then RuntimeError "queue iteration"

Print "queue-ok"
