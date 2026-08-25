SuperStrict

Import BRL.LinkedList
Import BRL.Threads

Type TImportedEachItem
	Field value:Int
End Type

Function RuntimeCompare:Int(left:Object, right:Object) { nomangle }
	If left = right Then Return 0
	If left Then Return -1
	Return 1
End Function

Function RuntimeThreadCallback:Object(data:Object) { nomangle }
	Return data
End Function

Function MakeRuntimeThread:TThread(callback:Object(data:Object))
	Local thread:TThread = New TThread
	thread._entry = callback
	Return thread
End Function

Global RuntimeGlobalCompare:Int(left:Object, right:Object) = RuntimeCompare
Global RuntimeUnsetCompare:Int(left:Object, right:Object)

Function InvokeCompare:Int(compareFunc:Int(left:Object, right:Object), left:Object, right:Object)
	Local localCompare:Int(a:Object, b:Object) = compareFunc
	Local firstResult:Int = localCompare(left, right)
	localCompare = RuntimeCompare
	Return firstResult + localCompare(left, right)
End Function

Function UnsetCallableIsFalse:Int()
	Local compare:Int(left:Object, right:Object) = RuntimeCompare
	compare = Null
	If compare Then Return False
	Return Not compare
End Function

Function InvokeGlobalCompare:Int(compareFunc:Int(left:Object, right:Object), left:Object, right:Object)
	Local firstResult:Int = RuntimeGlobalCompare(left, right)
	RuntimeGlobalCompare = compareFunc
	If RuntimeUnsetCompare Then Return 100
	Return firstResult + RuntimeGlobalCompare(left, right)
End Function

Type TCallableFieldHolder
	Field active:Int(left:Object, right:Object) = RuntimeCompare
	Field missing:Int(left:Object, right:Object)

	Method Run:Int(left:Object, right:Object)
		Local firstResult:Int = active(left, right)
		active = CompareObjects
		If missing Then Return 100
		Return firstResult + active(left, right)
	End Method
End Type

Type TCallableMethodBase
	Method Apply:Int(operation:Int(left:Object, right:Object), left:Object, right:Object)
		Return operation(left, right)
	End Method
End Type

Type TCallableMethodInherited Extends TCallableMethodBase
End Type

Type TCallableMethodOverride Extends TCallableMethodBase
	Method Apply:Int(operation:Int(left:Object, right:Object), left:Object, right:Object) Override
		Return operation(left, right) + 1
	End Method
End Type

Type TCallableConstructorBase
	Field result:Int

	Method New(operation:Int(left:Object, right:Object))
		result = 42 + operation(Self, Self)
	End Method
End Type

Type TCallableConstructor Extends TCallableConstructorBase
	Method New(operation:Int(left:Object, right:Object) = RuntimeCompare)
		Super.New(operation)
	End Method
End Type

Local values:TList = CreateList()
Local first:TImportedEachItem = New TImportedEachItem
first.value = 20
ListAddLast(values, first)
Local second:TImportedEachItem = New TImportedEachItem
second.value = 22
ListAddLast(values, second)
values.Sort()
SortList(values)
values.Sort(, RuntimeCompare)
SortList(values, , CompareObjects)
Local callbackResult:Int = InvokeCompare(RuntimeCompare, values, values)
Local globalCallbackResult:Int = InvokeGlobalCompare(RuntimeCompare, values, values)
Local fieldHolder:TCallableFieldHolder = New TCallableFieldHolder
Local fieldCallbackResult:Int = fieldHolder.Run(values, values)
Local inheritedMethod:TCallableMethodBase = New TCallableMethodInherited
Local overriddenMethod:TCallableMethodBase = New TCallableMethodOverride
Local inheritedMethodCallbackResult:Int = inheritedMethod.Apply(RuntimeCompare, values, values)
Local overriddenMethodCallbackResult:Int = overriddenMethod.Apply(RuntimeCompare, values, values)
Local defaultConstructed:TCallableConstructor = New TCallableConstructor
Local explicitConstructed:TCallableConstructor = New TCallableConstructor(RuntimeCompare)
Local runtimeThread:TThread = New TThread
runtimeThread._entry = RuntimeThreadCallback
Local threadFieldResult:Object = runtimeThread._entry(runtimeThread)
runtimeThread._entry = Null
Local threadFieldUnset:Int = Not runtimeThread._entry
Local complexThreadFieldResult:Object = MakeRuntimeThread(RuntimeThreadCallback)._entry(runtimeThread)

Local total:Int
For Local value:TImportedEachItem = EachIn values
	total = total + value.value
Next

If total = 42 And callbackResult = 0 And globalCallbackResult = 0 And fieldCallbackResult = 0 And inheritedMethodCallbackResult = 0 And overriddenMethodCallbackResult = 1 And defaultConstructed.result = 42 And explicitConstructed.result = 42 And threadFieldResult = runtimeThread And threadFieldUnset And complexThreadFieldResult = runtimeThread And UnsetCallableIsFalse() Then WriteStdout("imported eachin runtime ok~n")
