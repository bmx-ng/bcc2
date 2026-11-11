SuperStrict

Framework BRL.StandardIO

Function SortAndMeasure<T>:Int[](values:T[], ascending:Int = True)
	values.Sort(ascending)
	Return values.Dimensions()
End Function

Local words:String[] = ["charlie", "alpha", "bravo"]
Local wordDimensions:Int[] = SortAndMeasure<String>(words)
Local numbers:Int[] = [1, 3, 2]
Local numberDimensions:Int[] = SortAndMeasure<Int>(numbers, False)

Print words[0] + "|" + words[2] + "|" + wordDimensions.Length + "|" + wordDimensions[0] + "|" + numbers[0] + "|" + numbers[2] + "|" + numberDimensions[0]
