SuperStrict

Framework BRL.StandardIO
Import Bcc2YieldBoundary.Values

Local words:ICloseableIterator<String> = Words("item-", 2)
If Not words.MoveNext() Or words.Current() <> "item-1" Then Throw "imported generator first value failed"
If Not words.MoveNext() Or words.Current() <> "item-2" Or words.MoveNext() Then Throw "imported generator completion failed"

Local once:ICloseableIterator<Int> = Once<Int>(19)
If Not once.MoveNext() Or once.Current() <> 19 Or once.MoveNext() Then Throw "imported generic generator failed"

Local nested:ICloseableIterator<String> = Nested<String>("nested")
If Not nested.MoveNext() Or nested.Current() <> "nested" Or nested.MoveNext() Then Throw "imported nested generic generator failed"

Local owned:ICloseableIterator<String> = Owned<String>("owned")
If Not owned.MoveNext() Or owned.Current() <> "owned" Or owned.MoveNext() Then Throw "imported generic Using generator failed"

Local protected:ICloseableIterator<String> = Protected<String>("protected")
For Local index:Int = 1 To 3
	If Not protected.MoveNext() Or protected.Current() <> "protected" Then Throw "imported protected generic generator failed"
Next
If protected.MoveNext() Then Throw "imported protected generic generator did not complete"

Local captured:ICloseableIterator<String> = Captured<String>("captured")
If Not captured.MoveNext() Or captured.Current() <> "captured" Or captured.MoveNext() Then Throw "imported capturing generic generator failed"

Local factory:Closure<ICloseableIterator<String>()> = Factory<String>("closure")
Local closureValues:ICloseableIterator<String> = factory()
If Not closureValues.MoveNext() Or closureValues.Current() <> "closure" Or closureValues.MoveNext() Then Throw "imported generic yielding Closure failed"

Local staticValues:ICloseableIterator<String> = StaticValues<String>("static-left", "static-right")
If Not staticValues.MoveNext() Or staticValues.Current() <> "static-left" Then Throw "imported generic StaticArray indexed Yield failed"
If Not staticValues.MoveNext() Or staticValues.Current() <> "static-left" Then Throw "imported generic StaticArray EachIn first value failed"
If Not staticValues.MoveNext() Or staticValues.Current() <> "static-right" Or staticValues.MoveNext() Then Throw "imported generic StaticArray EachIn resumption failed"

Local delegated:ICloseableIterator<String> = NestedDelegated<String>(["delegated-left", "delegated-right"])
If Not delegated.MoveNext() Or delegated.Current() <> "delegated-left" Then Throw "imported generic Yield From first value failed"
If Not delegated.MoveNext() Or delegated.Current() <> "delegated-right" Or delegated.MoveNext() Then Throw "imported generic Yield From completion failed"

Local box:TBox<String> = New TBox<String>
box.value = "box"
Local boxed:ICloseableIterator<String> = box.Values(2)
If Not boxed.MoveNext() Or boxed.Current() <> "box" Then Throw "imported generic generator Method failed"
If Not boxed.MoveNext() Or boxed.Current() <> "box" Or boxed.MoveNext() Then Throw "imported generic generator Method completion failed"

Print "yield-module-boundary-ok"
