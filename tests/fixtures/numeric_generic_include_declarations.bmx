Function IncludedClamp<T>:T(value:T, low:T, high:T) Where T Is Numeric
	If value < low Then Return low
	If value > high Then Return high
	Return value
End Function
