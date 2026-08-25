SuperStrict

Framework BRL.StandardIO
Import Collections.BlockingQueue

Local queue:TBlockingQueue<String> = New TBlockingQueue<String>(4)
queue.Enqueue("first")
queue.Enqueue("second", 100)

Local peeked:String
If Not queue.TryPeek(peeked) Or peeked <> "first" Then
	RuntimeError "blocking queue peek"
End If

If queue.Dequeue() <> "first" Then
	RuntimeError "blocking queue dequeue"
End If

Local removed:String
If Not queue.TryDequeue(removed) Or removed <> "second" Then
	RuntimeError "blocking queue try-dequeue"
End If

Local tasks:TBlockingTaskQueue<Int> = New TBlockingTaskQueue<Int>()
tasks.Enqueue(17)
tasks.Enqueue(23, 100, ETimeUnit.Milliseconds)

If tasks.Dequeue(100) <> 17 Then
	RuntimeError "blocking task queue timed dequeue"
End If
tasks.TaskDone()

If tasks.Dequeue() <> 23 Then
	RuntimeError "blocking task queue dequeue"
End If
tasks.TaskDone()
tasks.Join()

Print "blockingqueue-ok"
