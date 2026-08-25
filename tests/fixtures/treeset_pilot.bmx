SuperStrict

Framework BRL.StandardIO
Import Collections.TreeSet

Local set:TTreeSet<Int> = New TTreeSet<Int>
If Not set.Add(3) Or Not set.Add(1) Or Not set.Add(2) Then RuntimeError "tree set insertion"
If set.Add(2) Or set.Count() <> 3 Then RuntimeError "tree set duplicate"
If Not set.Contains(1) Or set.Contains(4) Then RuntimeError "tree set lookup"

Local order:String
For Local value:Int = EachIn set
	order = order + value + ","
Next
If order <> "1,2,3," Then RuntimeError "tree set ordering"

Local subset:TTreeSet<Int> = set.ViewBetween(1, 2)
If subset.Count() <> 2 Or Not subset.Contains(1) Or Not subset.Contains(2) Then RuntimeError "tree subset"
If Not set.Remove(2) Or set.Contains(2) Then RuntimeError "tree set removal"

Print "treeset-ok"
