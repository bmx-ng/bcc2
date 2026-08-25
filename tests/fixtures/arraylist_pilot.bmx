SuperStrict

Framework BRL.StandardIO
Import Collections.ArrayList

Local values:TArrayList<String> = New TArrayList<String>(2)
values.Add("one")
values.Add("two")
values.Add("three")

If values.Count() <> 3 Then RuntimeError "ArrayList Count mismatch"
If values.Capacity() < 3 Then RuntimeError "ArrayList did not resize"
If values.Get(0) <> "one" Or values.Get(2) <> "three" Then RuntimeError "ArrayList indexed read mismatch"
If values.RemoveAt(1) <> "two" Then RuntimeError "ArrayList RemoveAt mismatch"
If values.Count() <> 2 Or values.Get(1) <> "three" Then RuntimeError "ArrayList compaction mismatch"
