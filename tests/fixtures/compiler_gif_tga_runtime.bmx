SuperStrict

Framework BRL.StandardIO

Import Image.GIF
Import Image.TGA

Function WriteFixture(path:String, bytes:Byte[])
	Local stream:TStream = WriteStream(path)
	If Not stream Then Throw "fixture stream creation failed"
	If stream.WriteBytes(bytes, bytes.length) <> bytes.length Then Throw "fixture write failed"
	stream.Close()
End Function

Local gifPath:String = "/private/tmp/bcc2-image-runtime.gif"
Local gifBytes:Byte[] = [
	$47, $49, $46, $38, $39, $61,
	$01, $00, $01, $00, $80, $00, $00,
	$00, $00, $00, $ff, $ff, $ff,
	$21, $f9, $04, $01, $00, $00, $00, $00,
	$2c, $00, $00, $00, $00, $01, $00, $01, $00, $00,
	$02, $02, $44, $01, $00, $3b
]
WriteFixture(gifPath, gifBytes)

Local gif:TPixmap = TGifImage.LoadPixmap(gifPath)
If Not gif Then Throw "GIF load failed"
If gif.width <> 1 Or gif.height <> 1 Then Throw "GIF dimensions changed"

Local tgaPath:String = "/private/tmp/bcc2-image-runtime.tga"
Local tgaBytes:Byte[] = [
	$00, $00, $02, $00, $00, $00, $00, $00,
	$00, $00, $00, $00, $02, $00, $01, $00, $18, $00,
	$00, $00, $ff, $00, $ff, $00
]
WriteFixture(tgaPath, tgaBytes)

Local tga:TPixmap = LoadPixmap(tgaPath)
If Not tga Then Throw "TGA load failed"
If tga.width <> 2 Or tga.height <> 1 Then Throw "TGA dimensions changed"

Print "bcc2 GIF/TGA runtime regression passed"
