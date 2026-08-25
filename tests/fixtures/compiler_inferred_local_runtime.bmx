SuperStrict

Framework BRL.StandardIO

Interface IInferredValue
	Method Read:Int()
End Interface

Type TInferredValue Implements IInferredValue
	Method Read:Int()
		Return 42
	End Method
End Type

Type TBox<T>
	Field value:T

	Method New(value:T)
		Self.value = value
	End Method
End Type

Struct SValue
	Field value:Int
End Struct

Function View:IInferredValue()
	Return New TInferredValue
End Function

Function Identity<T>:T(value:T)
	Return value
End Function

Function AddOne:Int(value:Int)
	Return value + 1
End Function

Function MakeAction:Closure<Int(value:Int)>()
	Return Function(value)
		Return value + 1
	End Function
End Function

Local number := 40
Local text := "hello"
Local values := [1, 2]
Local box := New TBox<String>(text)
Local record := New SValue
Local view := View()
Local callback := AddOne
Local action := MakeAction()
Local genericResult := Identity<Long>(number)
Local raw:Int = 42
Local pointer := Varptr raw

number = 41
record.value = values[0]
If number <> 41 Or box.value <> "hello" Then Throw "scalar, String, or constructed generic inference failed"
If record.value <> 1 Or view.Read() <> 42 Then Throw "Array, Struct, or Interface inference failed"
If callback(number) <> 42 Or action(number) <> 42 Then Throw "callable or Closure inference failed"
If genericResult <> 40 Or pointer[0] <> 42 Then Throw "generic routine result or pointer inference failed"

Print "inferred-local-runtime-ok"
