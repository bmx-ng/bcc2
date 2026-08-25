SuperStrict

Framework BRL.StandardIO
Import Collections.PtrMap

Local map:TPtrMap = New TPtrMap

map.Insert(Byte Ptr(12345), "one")
map.Insert(Byte Ptr(2222), "two")
map.Insert(Byte Ptr(100), "three")

If map.ValueForKey(Byte Ptr(12345)) <> "one" Then Throw "pointer-key lookup failed"
If map.ValueForKey(Byte Ptr(42)) Then Throw "missing pointer key unexpectedly resolved"

Local count:Int
For Local key:TPtrKey = EachIn map.Keys()
	If Not key Then Throw "pointer-key enumerator returned Null"
	count :+ 1
Next
If count <> 3 Then Throw "pointer-key enumeration count failed"

If Not map.Remove(Byte Ptr(2222)) Then Throw "pointer-key removal failed"
If map.Remove(Byte Ptr(2222)) Then Throw "duplicate pointer-key removal succeeded"

map.Clear()
count = 0
For Local key:TPtrKey = EachIn map.Keys()
	count :+ 1
Next
If count Then Throw "cleared pointer map still enumerates values"

Print "ptrmap runtime ok"
