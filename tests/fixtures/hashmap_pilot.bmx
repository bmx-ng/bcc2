SuperStrict

Framework BRL.StandardIO
Import Collections.HashMap

Local values:THashMap<String, Int> = New THashMap<String, Int>
values.Add("one", 1)
values.Put("two", 2)
values["three"] = 3

If values.Count() <> 3 Then RuntimeError "HashMap Count mismatch"
If Not values.ContainsKey("two") Then RuntimeError "HashMap missing key"
If values["three"] <> 3 Then RuntimeError "HashMap indexed read mismatch"

Local found:Int
If Not values.TryGetValue("one", found) Or found <> 1 Then RuntimeError "HashMap TryGetValue mismatch"
If Not values.Remove("two") Or values.ContainsKey("two") Then RuntimeError "HashMap Remove mismatch"
If values.Count() <> 2 Then RuntimeError "HashMap final Count mismatch"
