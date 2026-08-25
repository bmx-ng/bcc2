SuperStrict

Framework BRL.StandardIO

Private

Function HiddenOffset:Int(value:Int)
	Return value + 1
End Function

Type TOrdinaryHelpers
	Function Offset:Int(value:Int)
		Return value + 1
	End Function
End Type

Type TOptionalPlain
	Field value:String

	Method New(input:String = "default")
		value = input
	End Method
End Type

Type TVarPlain
	Field value:Int

	Method New(input:Int Var)
		input :+ 1
		value = input
	End Method
End Type

Struct SOrdinaryAmount
	Field value:Int

	Method Operator +:SOrdinaryAmount(delta:Int)
		Self.value :+ delta
		Return Self
	End Method
End Struct

Public

Type TOrdinaryBoundary<T>
	Method Hidden:Int(value:Int)
		Return HiddenOffset(value)
	End Method

	Method Containing:Int(value:Int)
		Return TOrdinaryHelpers.Offset(value)
	End Method

	Method Optional:TOptionalPlain()
		Return New TOptionalPlain()
	End Method

	Method VarConstruct:TVarPlain(value:Int Var)
		Return New TVarPlain(value)
	End Method

	Method Add:SOrdinaryAmount(value:SOrdinaryAmount)
		Return value + 1
	End Method
End Type

Local boundary:TOrdinaryBoundary<String> = New TOrdinaryBoundary<String>
If boundary.Hidden(41) <> 42 Then RuntimeError "private helper dependency failed"
If boundary.Containing(41) <> 42 Then RuntimeError "containing-Type helper dependency failed"
If boundary.Optional().value <> "default" Then RuntimeError "optional ordinary constructor default failed"
Local seed:Int = 41
Local constructed:TVarPlain = boundary.VarConstruct(seed)
If seed <> 42 Or constructed.value <> 42 Then RuntimeError "Var ordinary constructor ABI failed"
Local amount:SOrdinaryAmount
amount.value = 41
If boundary.Add(amount).value <> 42 Then RuntimeError "ordinary Struct operator dependency failed"

Print "generic ordinary-call boundary runtime passed"
