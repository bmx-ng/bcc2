SuperStrict

Framework BRL.StandardIO

Import Bcc2ApiEvolutionTest.Owner

Type TApiEvolutionConsumerValue Implements IApiEvolutionValue
	Field amount:Int

	Method EvolutionTag:Int()
		Return amount
	End Method
End Type

Local value:TApiEvolutionConsumerValue = New TApiEvolutionConsumerValue
Local box:TApiEvolutionBox<TApiEvolutionConsumerValue> = New TApiEvolutionBox<TApiEvolutionConsumerValue>
box.value = value
Local advance:Closure<TApiEvolutionConsumerValue(value:TApiEvolutionConsumerValue)> = Function:TApiEvolutionConsumerValue(value:TApiEvolutionConsumerValue)
	value.amount :+ 1
	Return value
End Function

Local result:TApiEvolutionConsumerValue = box.Apply(advance)
Print result.amount + ":" + ProviderMarker()
