SuperStrict

Framework BRL.Blitz
Import BRL.Stream

Local stream:TStream = New TStream
Local closeable:ICloseable = stream
closeable.Close()

If stream.Pos() <> -1 Then RuntimeError "unexpected default stream position"
If stream.Size() <> 0 Then RuntimeError "unexpected default stream size"
WriteStdout("stream runtime ok~n")
