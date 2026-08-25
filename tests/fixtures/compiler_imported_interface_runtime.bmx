SuperStrict

Type TCloseable Implements ICloseable
	Field closed:Int

	Method Close()
		closed = 1
	End Method
End Type

Local item:TCloseable = New TCloseable
Local closeable:ICloseable = item
closeable.Close()

If item.closed = 1
	WriteStdout("bcc2 imported interface runtime ok~n")
End If
