' Copyright (c) 2026 Bruce A Henderson and contributors
' SPDX-License-Identifier: Zlib

SuperStrict

Framework BRL.StandardIO

Import BlitzMax.LSP
Import BlitzMax.Locale
Import Pub.StdC

TLocale.ConfigureToolchain(["language", "bls"])

If Not setbinarymode_(stdin_) Or Not setbinarymode_(stdout_) Then
	Throw TBlsMessages.StartupStandardIoConfigurationFailed().Render()
End If

Local io:TCStandardIO = New TCStandardIO
Local transport:TLspTransport = TLspTransport.Create(io, io)
Local server:TBlitzMaxLspServer = New TBlitzMaxLspServer
server.Run(transport)
