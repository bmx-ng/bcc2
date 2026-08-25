SuperStrict

Framework BRL.StandardIO

Type TDifferentialItem
	Field value:Int
End Type

Local missing:Object
Local emptyStrings:String[] = String[](missing)
Local boxedStrings:Object = ["left", "right"]
Local validStrings:String[] = String[](boxedStrings)
Local boxedNumbers:Object = [1, 2]
Local incompatibleStrings:String[] = String[](boxedNumbers)

Local first:TDifferentialItem = New TDifferentialItem
first.value = 20
Local second:TDifferentialItem = New TDifferentialItem
second.value = 22
Local boxedItems:Object = [first, second]
Local validItems:TDifferentialItem[] = TDifferentialItem[](boxedItems)

Local visits:Int
For Local value:String = EachIn emptyStrings
	visits :+ 1
Next

Print emptyStrings.length + ":" + validStrings.length + ":" + incompatibleStrings.length + ":" + validItems.length + ":" + (validItems[0].value + validItems[1].value) + ":" + visits
