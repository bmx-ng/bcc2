SuperStrict

Framework BRL.Blitz
Import BRL.StandardIO
Import Bcc2IdentityTest.Left
Import Bcc2IdentityTest.Right

If LeftIdentity() <> "left-module" Then Throw "left private generic identity failed"
If RightIdentity() <> "right-module" Then Throw "right private generic identity failed"

Print "generic-module-identity-ok"
