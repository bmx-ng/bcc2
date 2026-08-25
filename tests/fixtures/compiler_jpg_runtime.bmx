SuperStrict

Framework BRL.StandardIO

Import Image.JPG

Local path:String = "/private/tmp/bcc2-jpg-runtime.jpg"
Local source:TPixmap = CreatePixmap(4, 4, PF_RGB888)
For Local y:Int = 0 Until source.height
	For Local x:Int = 0 Until source.width
		source.WritePixel(x, y, $ff000000 | (x * 60 Shl 16) | (y * 60 Shl 8) | 32)
	Next
Next

If Not SavePixmapJPeg(source, path, 90) Then Throw "JPEG save failed"
Local loaded:TPixmap = LoadPixmapJPeg(path)
If Not loaded Then Throw "JPEG load failed"
If loaded.width <> source.width Or loaded.height <> source.height Then Throw "JPEG dimensions changed"

Print "bcc2 JPEG runtime regression passed"
