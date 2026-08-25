SuperStrict

Framework BRL.Blitz
Import BRL.StandardIO

Include "shared/owner.bmx"
Include "left/consumer.bmx"
Include "right/consumer.bmx"

If IncludedLeft.Read() <> "left-include" Then Throw "included String specialization ownership failed"
If IncludedRight.Read() <> 42 Then Throw "included Int specialization ownership failed"

Print "generic-include-identity-ok"
