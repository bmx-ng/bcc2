SuperStrict

Framework BRL.StandardIO

Import Image.PNG

Local path:String = "/private/tmp/bcc2-png-runtime.png"
Local source:TPixmap = CreatePixmap(2, 2, PF_RGBA8888)
source.WritePixel(0, 0, $ffff0000)
source.WritePixel(1, 0, $ff00ff00)
source.WritePixel(0, 1, $ff0000ff)
source.WritePixel(1, 1, $ffffffff)

If Not SavePixmapPNG(source, path, 1) Then Throw "PNG save failed"
Local loaded:TPixmap = LoadPixmapPNG(path)
If Not loaded Then Throw "PNG load failed"
If loaded.width <> 2 Or loaded.height <> 2 Then Throw "PNG dimensions changed"
If loaded.ReadPixel(0, 0) <> source.ReadPixel(0, 0) Then Throw "PNG pixel data changed"

Print "bcc2 PNG runtime regression passed"
