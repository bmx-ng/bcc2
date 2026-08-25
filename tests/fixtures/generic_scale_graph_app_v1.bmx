SuperStrict

Framework BRL.StandardIO

Import Bcc2ScaleTest.Graph

Include "left.bmx"
Include "stable.bmx"

If ScaleStage0<String>("deep") <> "deep" Then Throw "String transitive graph failed"
Local callback:Closure<Int()> = Function()
	Return 42
End Function
If ScaleStage0<Closure<Int()>>(callback)() <> 42 Then Throw "Closure transitive graph failed"

Local integerBox:TScaleBox<Int> = New TScaleBox<Int>
integerBox.value = 7
Local nestedBox:TScaleBox<TScaleBox<Int>> = New TScaleBox<TScaleBox<Int>>
nestedBox.value = integerBox
If nestedBox.Read().Read() <> 7 Then Throw "nested generic argument failed"

Local arrayBox:TScaleBox<String[]> = New TScaleBox<String[]>
arrayBox.value = ["array"]
If arrayBox.Read()[0] <> "array" Then Throw "Array generic argument failed"

Local closureBox:TScaleBox<Closure<Int()>> = New TScaleBox<Closure<Int()>>
closureBox.value = callback
If closureBox.Read()() <> 42 Then Throw "Closure generic argument failed"

Print "generic-scale-graph-ok-" + (ScaleLeft() + ScaleMiddle() + ScaleRight() + ScaleDuplicate())
