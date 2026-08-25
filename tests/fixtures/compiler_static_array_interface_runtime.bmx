SuperStrict

Interface IFixedReader
	Method Read:Int(StaticArray values:Int[4])
End Interface

Type TFixedReader Implements IFixedReader
	Field seed:Int

	Method New(StaticArray values:Int[4])
		seed = values[0]
	End Method

	Method Read:Int(StaticArray values:Int[4])
		Return seed + values.length
	End Method
End Type

Struct SFixedSummary
	Field total:Int

	Method New(StaticArray values:Int[4])
		total = values[0] + values.length
	End Method
End Struct

Local StaticArray values:Int[4]
values[0] = 38
Local concrete:TFixedReader = New TFixedReader(values)
Local reader:IFixedReader = concrete
Local summary:SFixedSummary = New SFixedSummary(values)
Local result:Int = reader.Read(values) + summary.total

If result = 84
	WriteStdout("bcc2 StaticArray Interface runtime ok~n")
End If
