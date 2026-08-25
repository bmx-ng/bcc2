SuperStrict

Framework BRL.StandardIO

?macosx86
Global MatrixTarget:Int = 101
?macosx64
Global MatrixTarget:Int = 102
?macosppc
Global MatrixTarget:Int = 103
?macosarm64
Global MatrixTarget:Int = 104
?win32x86
Global MatrixTarget:Int = 201
?win32x64
Global MatrixTarget:Int = 202
?win32armv7
Global MatrixTarget:Int = 203
?win32arm64
Global MatrixTarget:Int = 204
?linuxx86
Global MatrixTarget:Int = 301
?linuxx64
Global MatrixTarget:Int = 302
?linuxarm And Not linuxarm64
Global MatrixTarget:Int = 303
?linuxarm64
Global MatrixTarget:Int = 304
?linuxriscv32
Global MatrixTarget:Int = 305
?linuxriscv64
Global MatrixTarget:Int = 306
?

?debug
Global MatrixMode:Int = 1
?Not debug
Global MatrixMode:Int = 2
?

?threaded
Global MatrixThreaded:Int = 1
?Not threaded
Global MatrixThreaded:Int = 0
?

?console
Global MatrixApplication:Int = 1
?gui
Global MatrixApplication:Int = 2
?

?gdbdebug
Global MatrixGdb:Int = 1
?Not gdbdebug
Global MatrixGdb:Int = 0
?

?musl
Global MatrixMusl:Int = 1
?Not musl
Global MatrixMusl:Int = 0
?

If MatrixTarget = 0 Then Throw "desktop matrix target conditional was not selected"

Print MatrixTarget + ":" + MatrixMode + ":" + MatrixThreaded + ":" + MatrixApplication + ":" + MatrixGdb + ":" + MatrixMusl
