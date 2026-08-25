SuperStrict

Framework BRL.StandardIO
Import Collections.LinkedHashMap

Local map:TLinkedHashMap<String, Int> = New TLinkedHashMap<String, Int>
map["first"] = 10
map["second"] = 20
map["third"] = 30

If map.Count() <> 3 Then RuntimeError "linked hash map count"
If map["second"] <> 20 Then RuntimeError "linked hash map lookup"
If Not map.Remove("first") Then RuntimeError "linked hash map removal"
If map.ContainsKey("first") Then RuntimeError "linked hash map removed key"

Local order:String
For Local key:String = EachIn map.Keys()
	order = order + key + ","
Next
If order <> "second,third," Then RuntimeError "linked hash map insertion order"

Print "linkedhashmap-ok"
