Struct SBoundaryPointerValue
	Field number:Int
End Struct

Enum EBoundaryPointerValue:Byte
	Ready = 7
	Done = 9
End Enum

Local StaticArray values:Int[2]
values[0] = 12
values[1] = 42
Local pointer:Int Ptr = Varptr values[0]
If BoundaryPointerRead<Int>(pointer, 1) <> 42 Then Throw "generic pointer import failed"
Local StaticArray records:SBoundaryPointerValue[2]
records[1].number = 37
Local recordPointer:SBoundaryPointerValue Ptr = Varptr records[0]
If BoundaryPointerRead<SBoundaryPointerValue>(recordPointer, 1).number <> 37 Then Throw "generic Struct pointer import failed"
Local StaticArray states:EBoundaryPointerValue[2]
states[1] = EBoundaryPointerValue.Done
Local statePointer:EBoundaryPointerValue Ptr = Varptr states[0]
If BoundaryPointerRead<EBoundaryPointerValue>(statePointer, 1) <> EBoundaryPointerValue.Done Then Throw "generic Enum pointer import failed"

Local owner:TBoundaryMethodOwner<Int> = New TBoundaryMethodOwner<Int>
Local callback:Closure<String(value:String)> = BoundaryBind<String>(owner)
If callback("generic") <> "generic" Then Throw "specialized Method reference import failed"

Local firstComputed:Closure<Int(value:Int)> = BoundaryBindComputed<Int>(0)
Local secondComputed:Closure<Int(value:Int)> = BoundaryBindComputed<Int>(0)
If boundaryReceiverFactoryCalls <> 2 Then Throw "computed Method receiver was evaluated more than once"
GCCollect()
If firstComputed(1) <> 11 Or secondComputed(1) <> 21 Then Throw "computed Method references did not retain separate receivers"
Local computedGeneric:Closure<String(value:String)> = BoundaryBindComputedGeneric<String>("unused")
If computedGeneric("generic") <> "generic" Then Throw "computed specialized generic Method reference failed"
Local memberComputed:Closure<Int(value:Int)> = BoundaryBindMember<Int>(0)
Local fieldComputed:Closure<Int(value:Int)> = BoundaryBindField<Int>(0)
Local indexedComputed:Closure<Int(value:Int)> = BoundaryBindIndexed<Int>(0)
If boundaryReceiverFactoryCalls <> 6 Then Throw "computed member/field/index receivers were evaluated more than once"
GCCollect()
If memberComputed(1) <> 41 Or fieldComputed(1) <> 51 Or indexedComputed(1) <> 61 Then Throw "computed member/field/index Method references lost their receivers"

Local interfaceBox:TBoundaryInterfaceBox<String> = New TBoundaryInterfaceBox<String>
Local advanced:IBoundaryAdvanced = interfaceBox
Local base:IBoundaryBase = interfaceBox
Local bumped:Int = 40
If advanced.Read() <> 42 Or advanced.Bump(bumped) <> 41 Or bumped <> 41 Then Throw "ordinary inherited Interface table lost its method layout"
If base.Bump(bumped) <> 42 Or bumped <> 42 Then Throw "ordinary parent Interface table was not emitted"

Print "generic-pointer-method-boundary-ok"
