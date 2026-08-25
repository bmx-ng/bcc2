SuperStrict

Import acme.types

Local value:TPublished = New TPublished(40)
value.Value = value.Value + 1

Local second:TSecond = New TSecond(2)
value.Peer = second

Local items:Int[] = New Int[1]
items[0] = 3
value.Items = items

Local readResult:Int = value.Read(1)
Local identityResult:Int = TPublished.Identity(42)
Local peerResult:TSecond = value.EchoPeer(second)
Local arrayResult:Int[] = value.EchoItems(items)
value.Value = readResult + identityResult + peerResult.Value + arrayResult[0]
