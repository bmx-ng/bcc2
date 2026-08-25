SuperStrict

Framework BRL.Blitz
Import BRL.StandardIO

Local original:String = "test 000 test"
Local needle:String = "~0"
Local result:String = original.Replace(needle, "")

If needle.length <> 1 Or needle[0] <> 0 Then Throw "~0 did not decode to one NUL character"
If result <> original Then Throw "replacing a missing NUL changed the source String"

Local escaped:String = "~0~t~r~n~q~~~65~~$41~~%1000001~"
If escaped.length <> 9 Then Throw "documented escapes produced the wrong String length"
If escaped[0] <> 0 Or escaped[1] <> 9 Or escaped[2] <> 13 Or escaped[3] <> 10 Then Throw "control-character escapes failed"
If escaped[4] <> 34 Or escaped[5] <> 126 Then Throw "quote or tilde escape failed"
If escaped[6] <> 65 Or escaped[7] <> 65 Or escaped[8] <> 65 Then Throw "numeric escape failed"

Print "string-escape-ok"
