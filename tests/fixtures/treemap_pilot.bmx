SuperStrict

Framework BRL.StandardIO
Import Collections.TreeMap

Local map:TTreeMap<String, Int> = New TTreeMap<String, Int>
map["charlie"] = 30
map["alpha"] = 10
map["bravo"] = 20

If map.Count() <> 3 Then RuntimeError "tree map count"
If map["bravo"] <> 20 Then RuntimeError "tree map lookup"
If Not map.Remove("charlie") Then RuntimeError "tree map removal"
If map.ContainsKey("charlie") Then RuntimeError "tree map removed key"

Local order:String
For Local key:String = EachIn map.Keys()
	order = order + key + ","
Next
If order <> "alpha,bravo," Then RuntimeError "tree map key order"

Print "treemap-ok"
