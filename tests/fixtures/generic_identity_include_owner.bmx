Type TIdentityCell<T>
	Field value:T
End Type

Type TIdentityEnvelope<T>
	Field cell:TIdentityCell<T>
	Field transform:Closure<T(value:T)>

	Method Read:T()
		Return transform(cell.value)
	End Method
End Type
