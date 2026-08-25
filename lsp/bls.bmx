' Copyright (c) 2026 Bruce A Henderson and contributors
' SPDX-License-Identifier: Zlib

SuperStrict

Framework BRL.StandardIO

Import BlitzMax.LSP
Import Pub.StdC

If Not setbinarymode_(stdin_) Or Not setbinarymode_(stdout_) Then
	Throw "Unable to configure byte-exact LSP standard I/O"
End If

Local io:TCStandardIO = New TCStandardIO
Local transport:TLspTransport = TLspTransport.Create(io, io)
Local server:TBlitzMaxLspServer = New TBlitzMaxLspServer
server.Run(transport)
