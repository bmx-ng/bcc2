SuperStrict

Framework BRL.StandardIO

' These reusable operations know nothing about the values flowing through them.
' Their generic types and Closure signatures preserve that information for us.
Function Where<T>:T[](values:T[], predicate:Closure<Int(value:T)>)
	Local result:T[] = New T[0]
	For Local value:T = EachIn values
		If predicate(value) Then result :+ [value]
	Next
	Return result
End Function

Function Select<T, R>:R[](values:T[], transform:Closure<R(value:T)>)
	Local result:R[] = New R[values.length]
	For Local index:Int = 0 Until values.length
		result[index] = transform(values[index])
	Next
	Return result
End Function

Function Fold<T, R>:R(values:T[], seed:R, combine:Closure<R(total:R, value:T)>)
	Local result:R = seed
	For Local value:T = EachIn values
		result = combine(result, value)
	Next
	Return result
End Function

' This generic function returns a new Closure which captures two other Closures.
Function Compose<A, B, C>:Closure<C(value:A)>(first:Closure<B(value:A)>, second:Closure<C(value:B)>)
	Return Function(value:A)
		Return second(first(value))
	End Function
End Function

' Every Closure returned here owns an independent, mutable counter cell.
Function Numbered<T>:Closure<String(value:T)>(render:Closure<String(value:T)>)
	Local number:Int
	Return Function(value:T)
		number :+ 1
		Return number + ". " + render(value)
	End Function
End Function

Type TPilot
	Field name:String
	Field score:Int

	Method New(name:String, score:Int)
		Self.name = name
		Self.score = score
	End Method
End Type

Local pilots:TPilot[] = [..
	New TPilot("Ava", 91), ..
	New TPilot("Ben", 67), ..
	New TPilot("Cleo", 84), ..
	New TPilot("Dax", 73)]

' Changing this one captured value changes the filtering policy without changing
' Where itself or introducing a one-use named Type.
Local qualifyingScore:Int = 70
Local qualifies:Closure<Int(value:TPilot)> = Function(value:TPilot)
	Return value.score >= qualifyingScore
End Function

' The multiplier and label are also lexical captures.
Local multiplier:Int = 10
Local pilotStanding:Closure<String(value:TPilot)> = Function(value:TPilot)
	Return value.name + " | " + (value.score * multiplier)
End Function

Local pointsLabel:String = " championship points"
Local formatStanding:Closure<String(value:String)> = Function(value:String)
	Return value + pointsLabel
End Function

' Compose builds one managed callable containing the complete operation. The
' explicit arguments make every stage of the generic pipeline visible here.
Local describeScore:Closure<String(value:TPilot)> = Compose<TPilot, String, String>(pilotStanding, formatStanding)

Local finalists:TPilot[] = Where<TPilot>(pilots, qualifies)
Local descriptions:String[] = Select<TPilot, String>(finalists, describeScore)

Local renderLine:Closure<String(value:String)> = Function(value:String)
	Return value
End Function
Local nextLine:Closure<String(value:String)> = Numbered<String>(renderLine)

Print "Finalists (minimum score " + qualifyingScore + "):"
For Local description:String = EachIn descriptions
	Print nextLine(description)
Next

Local addScore:Closure<Int(total:Int, value:TPilot)> = Function(total:Int, value:TPilot)
	Return total + value.score
End Function
Local combinedScore:Int = Fold<TPilot, Int>(finalists, 0, addScore)
Print "Combined raw score: " + combinedScore
