SuperStrict

Import acme.managedvalues

Type TManagedValueHolder
	Field value:SManagedValue
End Type

Global Direct:SManagedValue
Global Holder:TManagedValueHolder = New TManagedValueHolder
Global Values:SManagedValue[] = New SManagedValue[2]
Global StaticArray Fixed:SManagedValue[2]

Values[0] = Direct
Values[1] = Holder.value
Fixed[0] = Direct
Fixed[1] = Values[1]

Global First:SManagedValue = Values[0]
Global Literal:SManagedValue[] = [Values[0], Values[1]]
Global Joined:SManagedValue[] = Values + Literal

For Local item:SManagedValue = EachIn Fixed
	First = item
Next
