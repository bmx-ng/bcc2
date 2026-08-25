SuperStrict

Import acme.derived

Local value:TDerived = New TDerived(20, 22)
Local result:Int = value.Sum()
Local score:Int = value.Score(1)
Local doubled:Int = TDerived.Double(2)
Local ordering:Int = value.Compare(value)
Local hash:UInt = value.HashCode()
Local equal:Int = value.Equals(value)
value.ToString()
value.SendMessage(value, value)
value.BaseValue = result + score + doubled + ordering + Int(hash) + equal
