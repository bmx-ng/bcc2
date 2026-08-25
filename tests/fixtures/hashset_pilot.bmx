SuperStrict

Framework BRL.StandardIO
Import Collections.HashSet

Local set:THashSet<String> = New THashSet<String>
If Not set.Add("alpha") Or Not set.Add("beta") Then RuntimeError "hash set insertion"
If set.Add("alpha") Or set.Count() <> 2 Then RuntimeError "hash set duplicate"
If Not set.Contains("beta") Then RuntimeError "hash set lookup"

Local other:THashSet<String> = New THashSet<String>
other.Add("beta")
other.Add("gamma")
set.UnionOf(other)
If set.Count() <> 3 Or Not set.Contains("gamma") Then RuntimeError "hash set union"
If Not set.Remove("alpha") Or set.Contains("alpha") Then RuntimeError "hash set removal"

Local seen:Int
For Local value:String = EachIn set
	If value = "beta" Or value = "gamma" Then seen = seen + 1
Next
If seen <> 2 Then RuntimeError "hash set iteration"

Print "hashset-ok"
