SuperStrict

Framework BRL.Blitz
Import BRL.Glob

' The isolated SDK compiler is the deterministic file supplied by the test harness.
Local root:String = "/private/tmp/BlitzMax-bcc2-sdk-audit/bin"
Local expected:String = "bcc2"
Local probe:TList = New TList
probe.AddLast(expected)
If probe.Count() <> 1 Then Throw "list ABI failed"
If String(probe.Last()) <> expected Then Throw "list Last ABI failed"
Local grown:String[] = New String[0]
grown = grown[..grown.Length + 1]
If grown.Length <> 1 Then Throw "array growth failed"
If FileType(root + "/" + expected) <> FILETYPE_FILE Then Throw "fixture file missing"
If StripSlash(root) <> root Then Throw "StripSlash failed: " + StripSlash(root)
If Not MatchGlob("bcc?", expected) Then Throw "MatchGlob failed"
Local matches:String[] = Glob(expected, EGlobOptions.None, root)
If matches.length <> 1 Then Throw "Glob count failed: " + matches.length
If matches[0] <> expected Then Throw "Glob value failed: " + matches[0]

Local count:Int
Using
	Local iterator:TGlobIter = GlobIter(expected, EGlobOptions.None, root)
Do
	If iterator.pats.Length <> 1 Then Throw "pattern expansion failed"
	If iterator.pats[0] <> expected Then Throw "pattern value failed: " + iterator.pats[0]
	While iterator.MoveNext()
		count :+ 1
	Wend
End Using

If count <> 1 Then Throw "GlobIter failed"
