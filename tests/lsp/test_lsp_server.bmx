SuperStrict

Framework BRL.StandardIO

Import BlitzMax.LSP
Import BRL.Bank
Import BRL.BankStream
Import BRL.FileSystem
Import BRL.TextStream

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Function TestSdkPath:String()
	Local referenceSdk:String = RealPath(AppDir + "/../../../BlitzMax")
	If TestSdkComplete(referenceSdk) Then Return referenceSdk
	Try
		Local installed:String = BlitzMaxPath()
		If TestSdkComplete(installed) Then Return installed
	Catch exception:Object
	End Try
	Local workspaceSdk:String = RealPath(AppDir + "/../../../BlitzMax-bcc2")
	If TestSdkComplete(workspaceSdk) Then Return workspaceSdk
	Throw "LSP tests could not locate a complete BlitzMax SDK containing the core and module-source fixtures"
End Function

Function TestSdkComplete:Int(path:String)
	Return FileType(path + "/mod/brl.mod/blitz.mod/blitz_classes.i") = FILETYPE_FILE And ..
		FileType(path + "/mod/ecs.mod/flecs.mod/flecs.bmx") = FILETYPE_FILE
End Function

Function SnapshotDiagnosticSummary:String(snapshot:TCompilationSnapshot)
	If Not snapshot Or Not snapshot.diagnostics.length Then Return "no snapshot diagnostics"
	Local result:String
	For Local diagnostic:TSnapshotDiagnostic = EachIn snapshot.diagnostics
		If result.length Then result :+ "; "
		result :+ diagnostic.code + " " + diagnostic.message
	Next
	Return result
End Function

Function NewTestServer:TBlitzMaxLspServer()
	Local server:TBlitzMaxLspServer = New TBlitzMaxLspServer
	Local sdkPath:String = TestSdkPath()
	server.workspaces.defaultConfiguration.sdkPath = sdkPath
	server.workspaces.adHoc.configuration.sdkPath = sdkPath
	Return server
End Function

Function HasDiagnostic:Int(diagnostics:TDiagnostic[], code:String)
	For Local diagnostic:TDiagnostic = EachIn diagnostics
		If diagnostic.code = code Then Return True
	Next
	Return False
End Function

Function FindCall:TCallExpressionSyntax(analysis:TLanguageAnalysis, text:String, needle:String)
	Local offset:Int = text.Find(needle)
	If offset < 0 Then Return Null
	Local location:TSyntaxLocation = TSyntaxLocation.Locate(TSyntaxNavigator.Create(analysis.syntaxTree), offset)
	For Local candidate:TSyntaxNode = EachIn location.parents
		Local call:TCallExpressionSyntax = TCallExpressionSyntax(candidate)
		If call Then Return call
	Next
	Return Null
End Function

Function ObjectFrom:TJSONObject(text:String)
	Local error:TJSONError
	Return TJSONObject(TJSON.Load(text, 0, error))
End Function

Function HasPublishedUri:Int(responses:String[], uri:String)
	For Local responseText:String = EachIn responses
		Local response:TJSONObject = ObjectFrom(responseText)
		Local params:TJSONObject = TJSONObject(response.Get("params"))
		If params And params.GetString("uri") = uri Then Return True
	Next
	Return False
End Function

Function DidOpenPayload:String(uri:String, text:String, version:Int = 1)
	Local textDocument:TJSONObject = JsonObject()
	textDocument.Set("uri", New TJSONString.Create(uri))
	textDocument.Set("languageId", New TJSONString.Create("blitzmax"))
	textDocument.Set("version", New TJSONInteger.Create(version))
	textDocument.Set("text", New TJSONString.Create(text))
	Local params:TJSONObject = JsonObject()
	params.Set("textDocument", textDocument)
	Local request:TJSONObject = JsonObject()
	request.Set("jsonrpc", New TJSONString.Create("2.0"))
	request.Set("method", New TJSONString.Create("textDocument/didOpen"))
	request.Set("params", params)
	Return request.SaveString(JSON_COMPACT)
End Function

Function DidChangePayload:String(uri:String, text:String, version:Int)
	Local textDocument:TJSONObject = JsonObject()
	textDocument.Set("uri", New TJSONString.Create(uri))
	textDocument.Set("version", New TJSONInteger.Create(version))
	Local change:TJSONObject = JsonObject()
	change.Set("text", New TJSONString.Create(text))
	Local changes:TJSONArray = JsonArray()
	changes.Append(change)
	Local params:TJSONObject = JsonObject()
	params.Set("textDocument", textDocument)
	params.Set("contentChanges", changes)
	Local request:TJSONObject = JsonObject()
	request.Set("jsonrpc", New TJSONString.Create("2.0"))
	request.Set("method", New TJSONString.Create("textDocument/didChange"))
	request.Set("params", params)
	Return request.SaveString(JSON_COMPACT)
End Function

Function FindCompletionItem:TJSONObject(items:TJSONArray, label:String)
	If Not items Then Return Null
	For Local index:Int = 0 Until items.Size()
		Local item:TJSONObject = TJSONObject(items.Get(index))
		If item And item.GetString("label").ToLower() = label.ToLower() Then Return item
	Next
	Return Null
End Function

Function CompletionItemCount:Int(items:TJSONArray, label:String)
	Local count:Int
	If Not items Then Return count
	For Local index:Int = 0 Until items.Size()
		Local item:TJSONObject = TJSONObject(items.Get(index))
		If item And item.GetString("label").ToLower() = label.ToLower() Then count :+ 1
	Next
	Return count
End Function

Function FindCompletionItemWithLabelDetail:TJSONObject(items:TJSONArray, label:String, detail:String)
	If Not items Then Return Null
	For Local index:Int = 0 Until items.Size()
		Local item:TJSONObject = TJSONObject(items.Get(index))
		If Not item Or item.GetString("label").ToLower() <> label.ToLower() Then Continue
		Local labelDetails:TJSONObject = TJSONObject(item.Get("labelDetails"))
		If labelDetails And labelDetails.GetString("detail") = detail Then Return item
	Next
	Return Null
End Function

Function HasSemanticToken:Int(data:TJSONArray, targetLine:Int, targetCharacter:Int, targetLength:Int, targetType:Int, requiredModifiers:Int = 0)
	If Not data Or data.Size() Mod 5 <> 0 Then Return False
	Local line:Int
	Local character:Int
	For Local index:Int = 0 Until data.Size() Step 5
		Local deltaLine:Int = Int(TJSONInteger(data.Get(index)).Value())
		Local deltaCharacter:Int = Int(TJSONInteger(data.Get(index + 1)).Value())
		line :+ deltaLine
		If deltaLine Then character = deltaCharacter Else character :+ deltaCharacter
		Local length:Int = Int(TJSONInteger(data.Get(index + 2)).Value())
		Local tokenType:Int = Int(TJSONInteger(data.Get(index + 3)).Value())
		Local modifiers:Int = Int(TJSONInteger(data.Get(index + 4)).Value())
		If line = targetLine And character = targetCharacter And length = targetLength And tokenType = targetType And (modifiers & requiredModifiers) = requiredModifiers Then Return True
	Next
	Return False
End Function

Function FindInlayHint:TJSONObject(hints:TJSONArray, line:Int, character:Int, label:String, kind:Int)
	If Not hints Then Return Null
	For Local index:Int = 0 Until hints.Size()
		Local hint:TJSONObject = TJSONObject(hints.Get(index))
		If Not hint Or hint.GetString("label") <> label Or hint.GetInteger("kind") <> kind Then Continue
		Local position:TJSONObject = TJSONObject(hint.Get("position"))
		If position And position.GetInteger("line") = line And position.GetInteger("character") = character Then Return hint
	Next
	Return Null
End Function

Function InlayTooltip:String(hint:TJSONObject)
	If Not hint Then Return ""
	Local tooltip:TJSONObject = TJSONObject(hint.Get("tooltip"))
	If tooltip Then Return tooltip.GetString("value")
	Return ""
End Function

Function HasSignatureLabel:Int(result:TJSONObject, fragment:String)
	If Not result Then Return False
	Local signatures:TJSONArray = TJSONArray(result.Get("signatures"))
	If Not signatures Then Return False
	For Local index:Int = 0 Until signatures.Size()
		Local signature:TJSONObject = TJSONObject(signatures.Get(index))
		If signature And signature.GetString("label").Contains(fragment) Then Return True
	Next
	Return False
End Function

Function FindHierarchyItem:TJSONObject(items:TJSONArray, name:String)
	If Not items Then Return Null
	For Local index:Int = 0 Until items.Size()
		Local item:TJSONObject = TJSONObject(items.Get(index))
		If item And item.GetString("name").ToLower() = name.ToLower() Then Return item
	Next
	Return Null
End Function

Function HasLocation:Int(items:TJSONArray, uri:String, line:Int, character:Int = -1)
	If Not items Then Return False
	For Local index:Int = 0 Until items.Size()
		Local item:TJSONObject = TJSONObject(items.Get(index))
		If Not item Or item.GetString("uri") <> uri Then Continue
		Local range:TJSONObject = TJSONObject(item.Get("range"))
		Local start:TJSONObject
		If range Then start = TJSONObject(range.Get("start"))
		If start And start.GetInteger("line") = line And (character < 0 Or start.GetInteger("character") = character) Then Return True
	Next
	Return False
End Function

Function FindDocumentLink:TJSONObject(items:TJSONArray, targetEnding:String)
	If Not items Then Return Null
	For Local index:Int = 0 Until items.Size()
		Local item:TJSONObject = TJSONObject(items.Get(index))
		If item And item.GetString("target").EndsWith(targetEnding) Then Return item
	Next
	Return Null
End Function

Function HasFoldingRange:Int(items:TJSONArray, startLine:Int, endLine:Int, kind:String = "")
	If Not items Then Return False
	For Local index:Int = 0 Until items.Size()
		Local item:TJSONObject = TJSONObject(items.Get(index))
		If Not item Then Continue
		If item.GetInteger("startLine") <> startLine Or item.GetInteger("endLine") <> endLine Then Continue
		If kind.length And item.GetString("kind") <> kind Then Continue
		Return True
	Next
	Return False
End Function

Function SelectionChainContains:Int(item:TJSONObject, startLine:Int, startCharacter:Int, endLine:Int, endCharacter:Int)
	Local current:TJSONObject = item
	While current
		Local range:TJSONObject = TJSONObject(current.Get("range"))
		Local startPosition:TJSONObject
		Local endPosition:TJSONObject
		If range Then
			startPosition = TJSONObject(range.Get("start"))
			endPosition = TJSONObject(range.Get("end"))
		End If
		If startPosition And endPosition And startPosition.GetInteger("line") = startLine And startPosition.GetInteger("character") = startCharacter And endPosition.GetInteger("line") = endLine And endPosition.GetInteger("character") = endCharacter Then Return True
		current = TJSONObject(current.Get("parent"))
	Wend
	Return False
End Function

Function FindWorkspaceSymbol:TJSONObject(items:TJSONArray, name:String, uriContains:String = "")
	If Not items Then Return Null
	For Local index:Int = 0 Until items.Size()
		Local item:TJSONObject = TJSONObject(items.Get(index))
		If Not item Or item.GetString("name").ToLower() <> name.ToLower() Then Continue
		Local location:TJSONObject = TJSONObject(item.Get("location"))
		If uriContains.length And (Not location Or Not location.GetString("uri").Contains(uriContains)) Then Continue
		Return item
	Next
	Return Null
End Function

Function WorkspaceEditEdits:TJSONArray(edit:TJSONObject, uri:String)
	If Not edit Then Return Null
	Local changes:TJSONObject = TJSONObject(edit.Get("changes"))
	If Not changes Then Return Null
	Return TJSONArray(changes.Get(uri))
End Function

Function VersionedWorkspaceEdit:TJSONObject(edit:TJSONObject)
	If Not edit Then Return Null
	Local changes:TJSONArray = TJSONArray(edit.Get("documentChanges"))
	If Not changes Or changes.Size() <> 1 Then Return Null
	Return TJSONObject(changes.Get(0))
End Function

Function PointRange:TJSONObject(line:Int, character:Int)
	Local position:TJSONObject = JsonObject()
	position.Set("line", line)
	position.Set("character", character)
	Local range:TJSONObject = JsonObject()
	range.Set("start", position)
	Local finish:TJSONObject = JsonObject()
	finish.Set("line", line)
	finish.Set("character", character)
	range.Set("end", finish)
	Return range
End Function

Function PositionAtOrBefore:Int(left:TJSONObject, right:TJSONObject)
	If Not left Or Not right Then Return False
	Local leftLine:Int = Int(left.GetInteger("line"))
	Local rightLine:Int = Int(right.GetInteger("line"))
	If leftLine <> rightLine Then Return leftLine < rightLine
	Return left.GetInteger("character") <= right.GetInteger("character")
End Function

Function DocumentSymbolRangesValid:Int(items:TJSONArray)
	If Not items Then Return True
	For Local index:Int = 0 Until items.Size()
		Local item:TJSONObject = TJSONObject(items.Get(index))
		If Not item Then Return False
		Local fullRange:TJSONObject = TJSONObject(item.Get("range"))
		Local selectionRange:TJSONObject = TJSONObject(item.Get("selectionRange"))
		If Not fullRange Or Not selectionRange Then Return False
		If Not PositionAtOrBefore(TJSONObject(fullRange.Get("start")), TJSONObject(selectionRange.Get("start"))) Then Return False
		If Not PositionAtOrBefore(TJSONObject(selectionRange.Get("end")), TJSONObject(fullRange.Get("end"))) Then Return False
		If Not DocumentSymbolRangesValid(TJSONArray(item.Get("children"))) Then Return False
	Next
	Return True
End Function

Function FindProtocolDiagnostic:TJSONObject(items:TJSONArray, code:String)
	If Not items Then Return Null
	For Local index:Int = 0 Until items.Size()
		Local diagnostic:TJSONObject = TJSONObject(items.Get(index))
		If diagnostic And diagnostic.GetString("code") = code Then Return diagnostic
	Next
	Return Null
End Function

Function CodeActionPayload:String(id:Int, uri:String, range:TJSONObject, diagnostics:TJSONArray, onlyKind:String = "")
	Local textDocument:TJSONObject = JsonObject()
	textDocument.Set("uri", uri)
	Local context:TJSONObject = JsonObject()
	context.Set("diagnostics", diagnostics)
	If onlyKind.length Then
		Local only:TJSONArray = JsonArray()
		only.Append(New TJSONString.Create(onlyKind))
		context.Set("only", only)
	End If
	Local params:TJSONObject = JsonObject()
	params.Set("textDocument", textDocument)
	params.Set("range", range)
	params.Set("context", context)
	Local request:TJSONObject = JsonObject()
	request.Set("jsonrpc", "2.0")
	request.Set("id", id)
	request.Set("method", "textDocument/codeAction")
	request.Set("params", params)
	Return request.SaveString(JSON_COMPACT)
End Function

Function CodeActionsAt:TJSONArray(server:TBlitzMaxLspServer, id:Int, uri:String, line:Int, character:Int = 0, onlyKind:String = "refactor.rewrite")
	Local responses:String[] = server.HandlePayload(CodeActionPayload(id, uri, PointRange(line, character), JsonArray(), onlyKind))
	If Not responses.length Then Return Null
	Return TJSONArray(ObjectFrom(responses[0]).Get("result"))
End Function

Function AllEditsUseName:Int(edits:TJSONArray, name:String)
	If Not edits Or edits.Size() = 0 Then Return False
	For Local index:Int = 0 Until edits.Size()
		Local edit:TJSONObject = TJSONObject(edits.Get(index))
		If Not edit Or edit.GetString("newText") <> name Then Return False
	Next
	Return True
End Function

Local reservedVariableAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nLocal step:Int~nstep :+ 1", "reserved-variable.bmx")
Check(HasDiagnostic(reservedVariableAnalysis.syntaxTree.diagnostics, "BMX2004"), "LSP analysis reports a reserved keyword at its variable declaration")

Local conditionalElseTerminatorLspSource:String = "SuperStrict~nFunction MultiSys:Int(outer:Int)~nIf outer~nLocal threaded:Int~n?bmxng~nthreaded = True~nIf threaded Then~nReturn 1~nElse~n?~nReturn 2~n?bmxng~nEnd If~n?~nEnd If~nReturn 0~nEnd Function"
Local conditionalElseTerminatorAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(conditionalElseTerminatorLspSource, "conditional-else-terminator-lsp.bmx")
Check(Not HasDiagnostic(conditionalElseTerminatorAnalysis.syntaxTree.diagnostics, "BMX2300"), "LSP parser assigns a conditional End If inside Else to the inner statement")
Check(Not HasDiagnostic(conditionalElseTerminatorAnalysis.model.diagnostics, "BMX3401"), "conditional End If regions do not make the surrounding runtime If unreachable")

Local framingBank:TBank = TBank.Create(0)
Local framingStream:TBankStream = CreateBankStream(framingBank)
Local framingTransport:TLspTransport = TLspTransport.Create(framingStream, framingStream)
Local unicodePayload:String = "{~qtext~q:~qcafé~q}"
framingTransport.WriteMessage(unicodePayload)
Local unicodeBytes:Byte Ptr = unicodePayload.ToUTF8String()
Local framingHeaderEnd:Int = Int(framingStream.Pos()) - Int(strlen_(unicodeBytes))
MemFree(unicodeBytes)
Check(framingHeaderEnd >= 4 And PeekByte(framingBank, framingHeaderEnd - 4) = 13 And PeekByte(framingBank, framingHeaderEnd - 3) = 10 And PeekByte(framingBank, framingHeaderEnd - 2) = 13 And PeekByte(framingBank, framingHeaderEnd - 1) = 10, "transport emits the exact CRLF CRLF header terminator")
framingStream.Seek(0)
Check(framingTransport.ReadMessage() = unicodePayload, "transport uses UTF-8 byte content length")

Local messageQueue:TLspMessageQueue = New TLspMessageQueue(0)
messageQueue.Enqueue("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didChange~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/queued.bmx~q,~qversion~q:2},~qcontentChanges~q:[{~qtext~q:~qversion two~q}]}}")
messageQueue.Enqueue("{~qjsonrpc~q:~q2.0~q,~qid~q:901,~qmethod~q:~qtextDocument/hover~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/queued.bmx~q},~qposition~q:{~qline~q:0,~qcharacter~q:0}}}")
messageQueue.Enqueue("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didChange~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/queued.bmx~q,~qversion~q:5},~qcontentChanges~q:[{~qtext~q:~qversion five~q}]}}")
Check(messageQueue.PendingCount() = 2 And messageQueue.HasNewerDocumentVersion("file:///tmp/queued.bmx", 2), "queued document changes collapse to the newest version across obsolete feature requests")
Local queuedChange:TLspQueuedMessage = messageQueue.Dequeue()
Check(queuedChange.documentVersion = 5 And queuedChange.payload.Contains("version five"), "the coalesced queue delivers only the newest full document text")
Local queuedHover:TLspQueuedMessage = messageQueue.Dequeue()
Check(queuedHover.requestKey = "n:901", "non-change requests retain their queue position")

Local priorityQueue:TLspMessageQueue = New TLspMessageQueue(0)
priorityQueue.Enqueue("{~qjsonrpc~q:~q2.0~q,~qid~q:909,~qmethod~q:~qtextDocument/semanticTokens/full~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/background.bmx~q}}}")
priorityQueue.Enqueue("{~qjsonrpc~q:~q2.0~q,~qid~q:910,~qmethod~q:~qtextDocument/hover~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/foreground.bmx~q},~qposition~q:{~qline~q:0,~qcharacter~q:0}}}")
Check(priorityQueue.Dequeue().requestKey = "n:910", "foreground requests overtake automatic background feature requests")
Check(priorityQueue.Dequeue().requestKey = "n:909", "overtaken background feature work remains queued")
priorityQueue.Enqueue("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/ordered.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict~q}}}")
priorityQueue.Enqueue("{~qjsonrpc~q:~q2.0~q,~qid~q:911,~qmethod~q:~qtextDocument/hover~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/foreground.bmx~q},~qposition~q:{~qline~q:0,~qcharacter~q:0}}}")
Check(priorityQueue.Dequeue().methodName = "textDocument/didOpen", "foreground requests never cross pending document lifecycle updates")
Check(priorityQueue.Dequeue().requestKey = "n:911", "foreground request follows the stable document generation")
priorityQueue.Enqueue("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qworkspace/didChangeConfiguration~q,~qparams~q:{~qsettings~q:{}}}")
priorityQueue.Enqueue("{~qjsonrpc~q:~q2.0~q,~qid~q:912,~qmethod~q:~qtextDocument/definition~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/foreground.bmx~q},~qposition~q:{~qline~q:0,~qcharacter~q:0}}}")
Check(priorityQueue.Dequeue().methodName = "workspace/didChangeConfiguration", "foreground requests do not cross global configuration barriers")
Check(priorityQueue.Dequeue().requestKey = "n:912", "foreground request resumes after the global barrier")
priorityQueue.Close()
messageQueue.Enqueue("{~qjsonrpc~q:~q2.0~q,~qid~q:902,~qmethod~q:~qtextDocument/hover~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/queued.bmx~q},~qposition~q:{~qline~q:0,~qcharacter~q:0}}}")
messageQueue.Enqueue("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~q$/cancelRequest~q,~qparams~q:{~qid~q:902}}")
Local canceledHover:TLspQueuedMessage = messageQueue.Dequeue()
Check(messageQueue.IsCanceled(canceledHover.requestKey), "cancellation is recorded while its request is still pending")
messageQueue.CompleteRequest(canceledHover.requestKey)
Check(Not messageQueue.IsCanceled(canceledHover.requestKey), "completed request cancellation state is released")
messageQueue.Close()

Local runInput:TBankStream = CreateBankStream(TBank.Create(0))
Local runOutput:TBankStream = CreateBankStream(TBank.Create(0))
Local runWriter:TLspTransport = TLspTransport.Create(runInput, runInput)
runWriter.WriteMessage("{~qjsonrpc~q:~q2.0~q,~qid~q:1,~qmethod~q:~qinitialize~q,~qparams~q:{~qinitializationOptions~q:{~quseDependencySnapshots~q:false}}}")
runWriter.WriteMessage("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/queued-run.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict~q}}}")
For Local version:Int = 2 To 5
	runWriter.WriteMessage("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didChange~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/queued-run.bmx~q,~qversion~q:" + version + "},~qcontentChanges~q:[{~qtext~q:~qSuperStrict\nLocal value:Int = " + version + "~q}]}}")
Next
runWriter.WriteMessage("{~qjsonrpc~q:~q2.0~q,~qid~q:903,~qmethod~q:~qtextDocument/hover~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/queued-run.bmx~q},~qposition~q:{~qline~q:1,~qcharacter~q:6}}}")
runWriter.WriteMessage("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~q$/cancelRequest~q,~qparams~q:{~qid~q:903}}")
runWriter.WriteMessage("{~qjsonrpc~q:~q2.0~q,~qid~q:2,~qmethod~q:~qshutdown~q}")
runWriter.WriteMessage("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qexit~q}")
runInput.Seek(0)
Local queuedServer:TBlitzMaxLspServer = NewTestServer()
queuedServer.Run(TLspTransport.Create(runInput, runOutput))
Check(queuedServer.cleanExit And queuedServer.documents.Get("file:///tmp/queued-run.bmx").version = 5, "threaded server run applies only the newest queued document version and exits cleanly")
runOutput.Seek(0)
Local runReader:TLspTransport = TLspTransport.Create(runOutput, runOutput)
Local queuedPublications:Int
Local latestPublishedVersion:Int
Local cancellationResponse:Int
While True
	Local runPayload:String = runReader.ReadMessage()
	If runPayload = Null Then Exit
	Local runMessage:TJSONObject = ObjectFrom(runPayload)
	If runMessage.GetString("method") = "textDocument/publishDiagnostics" Then
		queuedPublications :+ 1
		latestPublishedVersion = Int(TJSONObject(runMessage.Get("params")).GetInteger("version"))
	End If
	Local runError:TJSONObject = TJSONObject(runMessage.Get("error"))
	If runError And runError.GetInteger("code") = LSP_REQUEST_CANCELLED Then cancellationResponse = True
Wend
Check(queuedPublications = 1 And latestPublishedVersion = 5, "stale diagnostic results are suppressed when a newer queued version exists")
Check(cancellationResponse, "threaded dispatch returns the standard cancellation error for an obsolete request")

Local store:TLspDocumentStore = New TLspDocumentStore
Local document:TLspDocument = store.Open("file:///tmp/hello%20caf%C3%A9.bmx", "blitzmax", 1, "SuperStrict")
Check(document.path = "/tmp/hello café.bmx", "UTF-8 file URI is decoded")
Check(FileUriForPath("/tmp/hello café #1.bmx") = "file:///tmp/hello%20caf%C3%A9%20%231.bmx", "source-link file URIs encode UTF-8 and reserved path characters")
Check(store.Count() = 1, "document opens")
store.Change(document.uri, 2, "SuperStrict~nLocal value:Int")
Check(store.Get(document.uri).version = 2, "document version changes")
Check(store.Close(document.uri) = document And store.Count() = 0, "document closes")
Local passivePath:String = "/tmp/blitzmax-lsp-passive-navigation.bmx"
SaveText("SuperStrict~nType TPassive~nEnd Type", passivePath)
Local passiveDocument:TLspDocument = store.Open("file:///tmp/blitzmax-lsp-passive-navigation.bmx", "blitzmax", 1, LoadText(passivePath))
Check(Not passiveDocument.liveOverlay, "an unchanged navigation tab does not become a live dependency overlay")
store.Change(passiveDocument.uri, 2, passiveDocument.text + "~n' edited")
Check(passiveDocument.liveOverlay, "an edited document becomes a live dependency overlay")
store.Close(passiveDocument.uri)
DeleteFile(passivePath)

Local foreignDiagnostic:TDiagnostic = TDiagnostic.Create("BMX9998", "dependency failure", DIAGNOSTIC_ERROR, TSourceSpan.Create(0, 1), "/sdk/dependency.i")
Check(Not TBlitzMaxLspDiagnostics.DiagnosticBelongsToDocument(foreignDiagnostic, "/workspace/main.bmx"), "dependency diagnostic is not published on the open document")
Local localDiagnostic:TDiagnostic = TDiagnostic.Create("BMX9999", "local failure", DIAGNOSTIC_ERROR, TSourceSpan.Create(0, 1), "/workspace/main.bmx")
Check(TBlitzMaxLspDiagnostics.DiagnosticBelongsToDocument(localDiagnostic, "/workspace/main.bmx"), "local diagnostic remains publishable")

Local workspaceStore:TLspWorkspaceStore = New TLspWorkspaceStore
workspaceStore.Add("file:///workspace", "outer")
workspaceStore.Add("file:///workspace/nested", "nested")
Check(workspaceStore.ContextForPath("/workspace/nested/source.bmx").name = "nested", "most specific workspace wins")
Check(workspaceStore.ContextForPath("/workspace/other.bmx").name = "outer", "outer workspace handles its document")
Check(workspaceStore.ContextForPath("/workspace-other/file.bmx") = workspaceStore.adHoc, "path prefix is not mistaken for a workspace")

Local configuration:TLspWorkspaceConfiguration = TLspWorkspaceConfiguration.CreateDefault()
Check(Not configuration.SnapshotOptions().parseConfiguredConditionals, "LSP snapshots retain every conditional source branch")
configuration.sdkPath = TestSdkPath()
configuration.ApplyJson(ObjectFrom("{~qbuildMode~q:~qdebug~q,~quseDependencySnapshots~q:false,~qwarnImplicitDefaultReturns~q:true,~qconditionalSymbols~q:[~qcustom~q]}"))
Check(configuration.buildMode = "debug" And Not configuration.useDependencySnapshots, "workspace configuration is applied")
Check(configuration.conditionalSymbols.length = 1 And configuration.conditionalSymbols[0] = "custom", "configured conditional symbols replace defaults")
Check(configuration.SnapshotOptions().conditionalSymbols.length = 3 And configuration.SnapshotOptions().conditionalSymbols[1] = "bmxng" And configuration.SnapshotOptions().conditionalSymbols[2] = "bmxng2", "intrinsic compiler symbols survive configured target-symbol replacement")
Check(configuration.warnImplicitDefaultReturns And configuration.AnalysisOptions().controlFlow.reportImplicitDefaultReturns, "implicit default return warning is configurable")
Check(configuration.AnalysisOptions().typeResolution.reportUnresolvedTypes, "LSP analyses report unresolved types")

Local catalogueSdk:String = "/tmp/blitzmax-lsp-installed-catalogue-sdk"
Local catalogueConfiguration:TLspWorkspaceConfiguration = configuration.Copy()
catalogueConfiguration.sdkPath = catalogueSdk
catalogueConfiguration.buildMode = "release"
catalogueConfiguration.targetPlatform = HostTargetPlatform()
catalogueConfiguration.targetArchitecture = HostTargetArchitecture()
Local catalogueMung:String = catalogueConfiguration.InterfaceMung()
Local catalogueCoreDirectory:String = catalogueSdk + "/mod/brl.mod/blitz.mod"
Local catalogueAlphaDirectory:String = catalogueSdk + "/mod/alpha.mod/first.mod"
Local catalogueAlphaThirdDirectory:String = catalogueSdk + "/mod/alpha.mod/third.mod"
Local catalogueAlphaNestedDirectory:String = catalogueSdk + "/mod/alpha.mod/first.mod/deep.mod"
Local catalogueNamespaceOnlyDirectory:String = catalogueSdk + "/mod/alpha.mod/namespace.mod/only.mod"
Local catalogueBetaDirectory:String = catalogueSdk + "/mod/beta.mod/second.mod"
CreateDir(catalogueCoreDirectory, True)
CreateDir(catalogueAlphaDirectory, True)
CreateDir(catalogueAlphaThirdDirectory, True)
CreateDir(catalogueAlphaNestedDirectory, True)
CreateDir(catalogueNamespaceOnlyDirectory, True)
CreateDir(catalogueBetaDirectory, True)
SaveText("Object^Null{~n}=~qbbObjectClass~q", catalogueCoreDirectory + "/blitz_classes.i")
SaveText("SuperStrict~nInterface IFirst~nMethod Run:Int(value:Int)~nEnd Interface", catalogueAlphaDirectory + "/first.bmx")
SaveText("SuperStrict~nType TThird~nEnd Type", catalogueAlphaThirdDirectory + "/third.bmx")
SaveText("SuperStrict~nType TDeep~nEnd Type", catalogueAlphaNestedDirectory + "/deep.bmx")
SaveText("SuperStrict~nImport alpha.first~nType TSecond Implements IFirst~nMethod Run:Int(amount:Int)~nReturn amount~nEnd Method~nEnd Type~nRem~nbbdoc: Returns the kind of a file.~nEnd Rem~nFunction FileType:Int(path:String)~nReturn 1~nEnd Function~nFunction FileType:Int(path:String, followLinks:Int)~nReturn 1~nEnd Function", catalogueBetaDirectory + "/second.bmx")
SaveText("IFirst^Null{ '@source ~qfirst.bmx~q,2,0~n-Run:Int(value:Int) '@source ~qfirst.bmx~q,3,0~n}AI=~qalpha_first_IFirst~q", catalogueAlphaDirectory + "/first." + catalogueMung + ".i")
SaveText("TThird^Object{ '@source ~qthird.bmx~q,2,0~n}F=~qalpha_third_TThird~q~nSharedProbe:Int()=~qalpha_third_SharedProbe~q", catalogueAlphaThirdDirectory + "/third." + catalogueMung + ".i")
SaveText("TDeep^Object{ '@source ~qdeep.bmx~q,2,0~n}F=~qalpha_first_deep_TDeep~q", catalogueAlphaNestedDirectory + "/deep." + catalogueMung + ".i")
SaveText("superstrict~nimport alpha.first~nTSecond^Object@IFirst{ '@source ~qsecond.bmx~q,3,0~n-Run:Int(amount:Int) '@source ~qsecond.bmx~q,4,0~n}F=~qbeta_second_TSecond~q~nTNoSource^Object@IFirst{~n-Run:Int(amount:Int)~n}F=~qbeta_second_TNoSource~q~nFileType:Int(path:String)=~qbeta_second_FileType~q '@source ~qsecond.bmx~q,11,0~nFileType:Int(path:String,followLinks:Int)=~qbeta_second_FileType2~q '@source ~qsecond.bmx~q,14,0~nSharedProbe:Int()=~qbeta_second_SharedProbe~q", catalogueBetaDirectory + "/second." + catalogueMung + ".i")
Local catalogueDependencies:TLspDependencyCache = New TLspDependencyCache
Local installedCatalogue:TLspInstalledModuleCatalogue = New TLspInstalledModuleCatalogue
Check(installedCatalogue.Refresh(catalogueConfiguration, catalogueDependencies), "installed catalogue performs its initial discovery")
Check(installedCatalogue.ModuleCount() = 5 And installedCatalogue.catalogue.FindModule("alpha.first") <> Null And installedCatalogue.catalogue.FindModule("alpha.first.deep") <> Null And installedCatalogue.catalogue.FindModule("alpha.third") <> Null And installedCatalogue.catalogue.FindModule("beta.second") <> Null And installedCatalogue.catalogue.FindModule("alpha.namespace.only") = Null, "installed catalogue recursively discovers concrete modules but excludes namespace-only containers")
Check(installedCatalogue.catalogue.SymbolsQualified("alpha.first.IFirst.Run").length = 1, "installed catalogue indexes module members")
Check(installedCatalogue.catalogue.SymbolsQualified("beta.second.TSecond")[0].originPath = catalogueBetaDirectory + "/second.bmx", "installed catalogue retains source provenance")
Check(installedCatalogue.catalogue.SymbolsQualified("alpha.first.deep.TDeep")[0].originPath = catalogueAlphaNestedDirectory + "/deep.bmx", "nested installed modules retain original source provenance")
Check(installedCatalogue.catalogue.ExportedTopLevelSymbolsWithPrefix("FileT").length = 2 And installedCatalogue.catalogue.ExportedTopLevelSymbolsWithPrefix("Run").length = 0, "installed completion index returns public top-level prefix matches without type members")
Local importNameCatalogueStore:TLspInstalledModuleCatalogueStore = New TLspInstalledModuleCatalogueStore
Local importNameContext:TLspWorkspaceContext = TLspWorkspaceContext.Create("file:///catalogue-import", "catalogue import", catalogueConfiguration.Copy(), catalogueDependencies, Null, importNameCatalogueStore)
Local importNameDocument:TLspDocument = New TLspDocument
importNameDocument.uri = "file:///catalogue-import/main.bmx"
importNameDocument.path = "/catalogue-import/main.bmx"
importNameDocument.text = "SuperStrict~nImport alpha.first~nImport be~nFramework al~nImport "
Local parsedInterfacesBeforeImportCompletion:Int = catalogueDependencies.ParsedInterfaceCount()
Local betaModuleItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(importNameDocument, importNameContext, 2, 9))
Local betaModuleItem:TJSONObject = FindCompletionItem(betaModuleItems, "beta.second")
Local betaModuleEdit:TJSONObject = TJSONObject(betaModuleItem.Get("textEdit"))
Local betaModuleRange:TJSONObject = TJSONObject(betaModuleEdit.Get("range"))
Check(betaModuleItem <> Null And betaModuleItem.GetInteger("kind") = 9 And betaModuleEdit.GetString("newText") = "beta.second" And TJSONObject(betaModuleRange.Get("start")).GetInteger("character") = 7 And TJSONObject(betaModuleRange.Get("end")).GetInteger("character") = 9, "module import completion discovers configured SDK modules and replaces the partial target")
Local frameworkModuleItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(importNameDocument, importNameContext, 3, 12))
Check(FindCompletionItem(frameworkModuleItems, "alpha.third") <> Null, "Framework directives share installed module-name completion")
Local familyModuleItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(importNameDocument, importNameContext, 4, 7))
Check(FindCompletionItem(familyModuleItems, "alpha.third").GetString("sortText").Compare(FindCompletionItem(familyModuleItems, "beta.second").GetString("sortText"), True) < 0, "module completion ranks unused modules from an already imported family ahead of unrelated families")
importNameDocument.text = "SuperStrict~nImport alpha.first."
Local nestedPrefixItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(importNameDocument, importNameContext, 1, 19))
Check(FindCompletionItem(nestedPrefixItems, "alpha.first.deep") <> Null And FindCompletionItem(nestedPrefixItems, "alpha.first") <> Null, "module completion supports deep dotted prefixes without inventing namespace modules")
Check(importNameCatalogueStore.Count() = 0 And catalogueDependencies.ParsedInterfaceCount() = parsedInterfacesBeforeImportCompletion, "module-name completion remains separate from the parsed installed-symbol catalogue")
Local catalogueImplementationConfiguration:TLspWorkspaceConfiguration = catalogueConfiguration.Copy()
catalogueImplementationConfiguration.useDependencySnapshots = True
catalogueImplementationConfiguration.requireCoreInterface = False
Local catalogueImplementationStore:TLspInstalledModuleCatalogueStore = New TLspInstalledModuleCatalogueStore
Local catalogueImplementationContext:TLspWorkspaceContext = TLspWorkspaceContext.Create("file:///catalogue-implementation", "catalogue implementation", catalogueImplementationConfiguration, catalogueDependencies, Null, catalogueImplementationStore)
Check(TBlitzMaxLspCodeActions.UniqueModuleForValue(catalogueImplementationContext, "FileType") = "beta.second", "missing-import lookup treats overloads in one module as one exact match")
Check(TBlitzMaxLspCodeActions.UniqueModuleForValue(catalogueImplementationContext, "SharedProbe") = "", "missing-import lookup declines an exact name exported by multiple modules")
Check(TBlitzMaxLspCodeActions.UniqueModuleForType(catalogueImplementationContext, "TSecond") = "beta.second", "missing-import lookup finds a uniquely installed type")
Local missingTypeDocument:TLspDocument = New TLspDocument
missingTypeDocument.uri = "file:///catalogue-implementation/missing-type.bmx"
missingTypeDocument.path = "/catalogue-implementation/missing-type.bmx"
missingTypeDocument.text = "SuperStrict~nLocal sb:TSecond = New TSecond()"
Local missingTypeAnalysis:TLanguageAnalysis = catalogueImplementationContext.Analyze(missingTypeDocument)
Local missingTypeDeclarationDiagnostic:TDiagnostic
Local missingTypeExpressionDiagnostic:TDiagnostic
For Local missingTypeDiagnostic:TDiagnostic = EachIn missingTypeAnalysis.model.diagnostics
	If missingTypeDiagnostic.code <> "BMX3100" Then Continue
	If missingTypeDiagnostic.span.start = missingTypeDocument.text.Find("TSecond") Then
		missingTypeDeclarationDiagnostic = missingTypeDiagnostic
	Else If missingTypeDiagnostic.span.start = missingTypeDocument.text.Find("TSecond", missingTypeDocument.text.Find("TSecond") + 1) Then
		missingTypeExpressionDiagnostic = missingTypeDiagnostic
	End If
Next
Check(missingTypeDeclarationDiagnostic <> Null And missingTypeExpressionDiagnostic <> Null, "LSP analysis diagnoses unresolved declaration and New-expression types")
Local requestedMissingType:TJSONObject = TBlitzMaxLspDiagnostics.ToLspDiagnostic(missingTypeDeclarationDiagnostic, missingTypeAnalysis.syntaxTree.source)
Local requestedMissingTypes:TJSONArray = JsonArray()
requestedMissingTypes.Append(requestedMissingType)
Local missingTypeContext:TJSONObject = JsonObject()
missingTypeContext.Set("diagnostics", requestedMissingTypes)
Local missingTypeOnly:TJSONArray = JsonArray()
missingTypeOnly.Append(New TJSONString.Create("quickfix"))
missingTypeContext.Set("only", missingTypeOnly)
Local missingTypeParams:TJSONObject = JsonObject()
missingTypeParams.Set("context", missingTypeContext)
missingTypeParams.Set("range", requestedMissingType.Get("range"))
Local missingTypeActions:TJSONArray = TJSONArray(TBlitzMaxLspCodeActions.Query(missingTypeDocument, catalogueImplementationContext, missingTypeParams))
Local missingTypeAction:TJSONObject = TJSONObject(missingTypeActions.Get(0))
Local missingTypeEdits:TJSONArray = WorkspaceEditEdits(TJSONObject(missingTypeAction.Get("edit")), missingTypeDocument.uri)
Check(missingTypeActions.Size() = 1 And missingTypeAction.GetString("title") = "Import beta.second" And missingTypeAction.GetBool("isPreferred"), "an unresolved installed type offers one preferred import quick fix")
Check(missingTypeEdits.Size() = 1 And TJSONObject(missingTypeEdits.Get(0)).GetString("newText") = "~n~nImport beta.second", "the unresolved-type quick fix inserts the unique module import")
Local catalogueImplementationDocument:TLspDocument = New TLspDocument
catalogueImplementationDocument.uri = "file:///catalogue-implementation/main.bmx"
catalogueImplementationDocument.path = "/catalogue-implementation/main.bmx"
catalogueImplementationDocument.text = "SuperStrict~nImport alpha.first~nLocal worker:IFirst~nworker.Run(1)"
catalogueImplementationContext.Analyze(catalogueImplementationDocument)
Local autoImportDocument:TLspDocument = New TLspDocument
autoImportDocument.uri = "file:///catalogue-implementation/auto-import.bmx"
autoImportDocument.path = "/catalogue-implementation/auto-import.bmx"
autoImportDocument.text = "SuperStrict~nLocal kind:Int = FileT"
Local autoImportItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(autoImportDocument, catalogueImplementationContext, 1, 27, True))
Local autoImportItem:TJSONObject = FindCompletionItemWithLabelDetail(autoImportItems, "FileType", "(path:String)")
Check(autoImportItem <> Null, "auto-import completion finds FileType from beta.second")
Local autoImportEdits:TJSONArray = TJSONArray(autoImportItem.Get("additionalTextEdits"))
Local autoImportEdit:TJSONObject = TJSONObject(autoImportEdits.Get(0))
Local autoImportStart:TJSONObject = TJSONObject(TJSONObject(autoImportEdit.Get("range")).Get("start"))
Check(CompletionItemCount(autoImportItems, "FileType") = 2, "auto-import completion preserves installed Function overloads")
Check(autoImportItem.GetString("insertText") = "FileType(${1:path})$0" And autoImportItem.GetInteger("insertTextFormat") = 2, "auto-import completion retains call snippets")
Check(TJSONObject(autoImportItem.Get("labelDetails")).GetString("description") = "beta.second" And autoImportItem.GetString("detail").Contains("auto import from beta.second"), "auto-import completion identifies its installed module")
Check(autoImportEdits.Size() = 1 And autoImportEdit.GetString("newText") = "~n~nImport beta.second" And autoImportStart.GetInteger("line") = 0 And autoImportStart.GetInteger("character") = 11, "auto-import completion inserts a module after SuperStrict")
Local resolvedAutoImport:TJSONObject = TBlitzMaxLspCompletion.Resolve(autoImportItem, autoImportDocument, catalogueImplementationContext)
Check(TJSONObject(resolvedAutoImport.Get("documentation")).GetString("value").Contains("Returns the kind of a file.") And TJSONObject(resolvedAutoImport.Get("documentation")).GetString("value").Contains("Auto import from `beta.second`"), "auto-import completion resolve retains installed declaration identity and documentation")
autoImportDocument.text = "SuperStrict~nImport alpha.first~nLocal kind:Int = FileT"
catalogueImplementationContext.Forget(autoImportDocument.uri)
autoImportItems = TJSONArray(TBlitzMaxLspCompletion.Query(autoImportDocument, catalogueImplementationContext, 2, 27))
autoImportItem = FindCompletionItem(autoImportItems, "FileType")
autoImportEdit = TJSONObject(TJSONArray(autoImportItem.Get("additionalTextEdits")).Get(0))
autoImportStart = TJSONObject(TJSONObject(autoImportEdit.Get("range")).Get("start"))
Check(autoImportEdit.GetString("newText") = "~nImport beta.second" And autoImportStart.GetInteger("line") = 1, "auto-import completion extends an existing top-level import group")
autoImportDocument.text = "SuperStrict~nLocal worker:TSec"
catalogueImplementationContext.Forget(autoImportDocument.uri)
Local autoImportTypeItem:TJSONObject = FindCompletionItem(TJSONArray(TBlitzMaxLspCompletion.Query(autoImportDocument, catalogueImplementationContext, 1, 19)), "TSecond")
Check(autoImportTypeItem <> Null And autoImportTypeItem.GetInteger("kind") = 7, "auto-import completion offers installed Types in type positions")
autoImportDocument.text = "SuperStrict~nLocal kind:Int = Fi"
catalogueImplementationContext.Forget(autoImportDocument.uri)
Check(FindCompletionItem(TJSONArray(TBlitzMaxLspCompletion.Query(autoImportDocument, catalogueImplementationContext, 1, 19)), "FileType") = Null, "auto-import completion waits for a selective three-character prefix")
autoImportDocument.text = "SuperStrict~nFunction FileType:Int(path:String)~nReturn 1~nEnd Function~nLocal kind:Int = FileT"
catalogueImplementationContext.Forget(autoImportDocument.uri)
Check(CompletionItemCount(TJSONArray(TBlitzMaxLspCompletion.Query(autoImportDocument, catalogueImplementationContext, 4, 27)), "FileType") = 1, "a visible declaration suppresses installed auto-import candidates with the same name")
autoImportDocument.text = "SuperStrict~nImport beta.second~nLocal kind:Int = FileT"
catalogueImplementationContext.Forget(autoImportDocument.uri)
autoImportItems = TJSONArray(TBlitzMaxLspCompletion.Query(autoImportDocument, catalogueImplementationContext, 2, 27))
Local importedAutoEdit:Int
For Local autoImportIndex:Int = 0 Until autoImportItems.Size()
	Local importedItem:TJSONObject = TJSONObject(autoImportItems.Get(autoImportIndex))
	If importedItem.GetString("label") = "FileType" And importedItem.Get("additionalTextEdits") Then importedAutoEdit = True
Next
Check(CompletionItemCount(autoImportItems, "FileType") = 2 And Not importedAutoEdit, "an already imported module provides ordinary overload completion without duplicate import edits")
autoImportDocument.text = "Local kind:Int = FileT"
catalogueImplementationContext.Forget(autoImportDocument.uri)
autoImportItem = FindCompletionItem(TJSONArray(TBlitzMaxLspCompletion.Query(autoImportDocument, catalogueImplementationContext, 0, 22)), "FileType")
autoImportEdit = TJSONObject(TJSONArray(autoImportItem.Get("additionalTextEdits")).Get(0))
Check(autoImportEdit.GetString("newText") = "Import beta.second~n~n" And TJSONObject(TJSONObject(autoImportEdit.Get("range")).Get("start")).GetInteger("character") = 0, "auto-import completion tolerates incomplete files without a source-mode declaration")
Local installedTypeImplementations:TJSONArray = TJSONArray(TBlitzMaxLspImplementation.Query(catalogueImplementationDocument, catalogueImplementationContext, store, 2, 15))
Check(installedTypeImplementations.Size() = 1 And HasLocation(installedTypeImplementations, "file://" + catalogueBetaDirectory + "/second.bmx", 2, 5), "go to implementation discovers unimported installed-module Types while suppressing raw interface locations")
Local installedMethodImplementations:TJSONArray = TJSONArray(TBlitzMaxLspImplementation.Query(catalogueImplementationDocument, catalogueImplementationContext, store, 3, 8))
Check(HasLocation(installedMethodImplementations, "file://" + catalogueBetaDirectory + "/second.bmx", 3, 7), "go to implementation discovers installed interface-method implementations")
Local nestedNavigationDocument:TLspDocument = New TLspDocument
nestedNavigationDocument.uri = "file:///catalogue-implementation/nested.bmx"
nestedNavigationDocument.path = "/catalogue-implementation/nested.bmx"
nestedNavigationDocument.text = "SuperStrict~nImport alpha.first.deep~nLocal nested:TDeep"
Local nestedNavigationAnalysis:TLanguageAnalysis = catalogueImplementationContext.Analyze(nestedNavigationDocument)
Check(nestedNavigationAnalysis.model.ImportedScope("alpha.first.deep").LookupLocal("TDeep").length = 1, "analysis resolves an exact deeply nested module interface")
Local nestedNavigationHover:TJSONObject = TJSONObject(TBlitzMaxLspHover.Query(nestedNavigationDocument, catalogueImplementationContext, 2, 16))
Check(TJSONObject(nestedNavigationHover.Get("contents")).GetString("value").Contains("/alpha.mod/first.mod/deep.mod/deep.bmx"), "hover over a nested imported Type reports original source provenance")
Local nestedNavigationDefinition:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.Definition(nestedNavigationDocument, catalogueImplementationContext, store, 2, 16))
Check(nestedNavigationDefinition.GetString("uri") = "file://" + catalogueAlphaNestedDirectory + "/deep.bmx", "definition navigation follows a nested compiler interface to its primary source")
Local catalogueWorkspaceStore:TLspWorkspaceStore = New TLspWorkspaceStore
catalogueWorkspaceStore.adHoc = catalogueImplementationContext
Local installedWorkspaceSymbols:TJSONArray = TJSONArray(TBlitzMaxLspWorkspaceSymbols.Query("TSecond", catalogueWorkspaceStore, store))
Local installedWorkspaceType:TJSONObject = FindWorkspaceSymbol(installedWorkspaceSymbols, "TSecond", "/second.bmx")
Check(installedWorkspaceType <> Null And installedWorkspaceType.GetString("containerName") = "beta.second", "workspace symbols discover source-backed declarations in unimported installed modules")
Check(TJSONArray(TBlitzMaxLspWorkspaceSymbols.Query("TNoSource", catalogueWorkspaceStore, store)).Size() = 0, "workspace symbols suppress declarations without .bmx source provenance")
Local unchangedCatalogueGeneration:Int = installedCatalogue.generation
Check(Not installedCatalogue.Refresh(catalogueConfiguration, catalogueDependencies) And installedCatalogue.generation = unchangedCatalogueGeneration, "unchanged interfaces reuse the existing catalogue generation")
SaveText("superstrict~nimport alpha.first~nTSecond^Object@IFirst{ '@source ~qsecond.bmx~q,3,0~n-Run:Int(amount:Int) '@source ~qsecond.bmx~q,4,0~n}F=~qbeta_second_TSecond~q~nTNoSource^Object@IFirst{~n-Run:Int(amount:Int)~n}F=~qbeta_second_TNoSource~q~nFileType:Int(path:String)=~qbeta_second_FileType~q '@source ~qsecond.bmx~q,11,0~nFileType:Int(path:String,followLinks:Int)=~qbeta_second_FileType2~q '@source ~qsecond.bmx~q,14,0~nSharedProbe:Int()=~qbeta_second_SharedProbe~q~nTAdded^Object{ '@source ~qsecond.bmx~q,17,0~n}F=~qbeta_second_TAdded~q", catalogueBetaDirectory + "/second." + catalogueMung + ".i")
Check(installedCatalogue.Refresh(catalogueConfiguration, catalogueDependencies) And installedCatalogue.catalogue.SymbolsQualified("beta.second.TAdded").length = 1, "changed interfaces refresh their indexed declarations")
DeleteFile(catalogueAlphaDirectory + "/first." + catalogueMung + ".i")
Check(installedCatalogue.Refresh(catalogueConfiguration, catalogueDependencies) And installedCatalogue.catalogue.FindModule("alpha.first") = Null, "removed interfaces leave the catalogue")
Local sharedCatalogueStore:TLspInstalledModuleCatalogueStore = New TLspInstalledModuleCatalogueStore
Local catalogueContextOne:TLspWorkspaceContext = TLspWorkspaceContext.Create("file:///catalogue-one", "one", catalogueConfiguration.Copy(), catalogueDependencies, Null, sharedCatalogueStore)
Local catalogueContextTwo:TLspWorkspaceContext = TLspWorkspaceContext.Create("file:///catalogue-two", "two", catalogueConfiguration.Copy(), catalogueDependencies, Null, sharedCatalogueStore)
Check(catalogueContextOne.InstalledCatalogue() = catalogueContextTwo.InstalledCatalogue() And sharedCatalogueStore.Count() = 1, "workspace roots share an installed catalogue for the same environment")
Local isolatedCatalogueDocument:TLspDocument = New TLspDocument
isolatedCatalogueDocument.uri = "file:///catalogue-one/isolation.bmx"
isolatedCatalogueDocument.path = "/catalogue-one/isolation.bmx"
isolatedCatalogueDocument.text = "SuperStrict~nLocal value:Int"
catalogueContextOne.configuration.useDependencySnapshots = False
Local isolatedCatalogueAnalysis:TLanguageAnalysis = catalogueContextOne.Analyze(isolatedCatalogueDocument)
Check(isolatedCatalogueAnalysis.model.ImportedScope("beta.second") = Null, "catalogue modules do not become visible imports in document analysis")
Local alternateNestedDirectory:String = catalogueSdk + "/mod/alpha.first.mod/deep.mod"
CreateDir(alternateNestedDirectory, True)
SaveText("SuperStrict~nType TDeepDuplicate~nEnd Type", alternateNestedDirectory + "/deep.bmx")
SaveText("TDeepDuplicate^Object{~n}F=~qalpha_first_deep_TDeepDuplicate~q", alternateNestedDirectory + "/deep." + catalogueMung + ".i")
Local invalidNestedWarnings:TList = New TList
Local catalogueWithInvalidDirectory:TMap = TLspInstalledModuleCatalogue.Discover(catalogueConfiguration, invalidNestedWarnings)
Check(catalogueWithInvalidDirectory.Contains("alpha.first.deep") And catalogueWithInvalidDirectory.Contains("beta.second"), "installed catalogue skips an invalid .mod directory and its subtree without losing valid modules")
Check(invalidNestedWarnings.Count() = 1 And String(invalidNestedWarnings.First()).Contains("basename 'alpha.first' must be a single BlitzMax identifier"), "installed catalogue reports skipped malformed module directories")
Local strictInvalidNestedDirectory:Int
Try
	EnumModuleDirectories(catalogueSdk + "/mod")
Catch exception:Object
	strictInvalidNestedDirectory = String(exception).Contains("basename 'alpha.first' must be a single BlitzMax identifier")
End Try
Check(strictInvalidNestedDirectory, "shared module enumeration remains strict unless a caller explicitly collects malformed-directory issues")
Local duplicateNestedModules:TMap = New TMap
TLspInstalledModuleCatalogue.AddDiscovered(duplicateNestedModules, "alpha.first.deep", "/first/deep.i", False)
Local ambiguousNestedCatalogue:Int
Try
	TLspInstalledModuleCatalogue.AddDiscovered(duplicateNestedModules, "ALPHA.FIRST.DEEP", "/second/deep.i", False)
Catch exception:Object
	ambiguousNestedCatalogue = String(exception).Contains("Ambiguous module 'alpha.first.deep'")
End Try
Check(ambiguousNestedCatalogue, "installed catalogue rejects duplicate case-insensitive logical identities")
DeleteDir(catalogueSdk, True)

Local unsignedHoverAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nConst SIGNBIT_64:ULong = $8000000000000000:ULong", "unsigned-hover.bmx")
Local unsignedHoverSymbol:TSymbol = unsignedHoverAnalysis.model.globalScope.LookupLocal("SIGNBIT_64")[0]
Check(TBlitzMaxLspHover.SymbolDisplay(unsignedHoverSymbol, Null, unsignedHoverAnalysis.model.SymbolConstantValue(unsignedHoverSymbol)) = "Const SIGNBIT_64:ULong = 9223372036854775808", "hover displays ULong constants using unsigned decimal text")

Local defaultSymbols:String[] = DefaultConditionalSymbols(HostTargetPlatform(), HostTargetArchitecture())
Check("threaded" = defaultSymbols[3], "default LSP snapshot matches bcc threaded mode")
Check("bmxng" = defaultSymbols[4], "default LSP snapshot identifies the current compiler generation")
Check("bmxng2" = defaultSymbols[5], "default LSP snapshot identifies the bcc2 language generation")

Local snapshotConfiguration:TLspWorkspaceConfiguration = TLspWorkspaceConfiguration.CreateDefault()
snapshotConfiguration.sdkPath = TestSdkPath()
Local sharedDependencies:TLspDependencyCache = New TLspDependencyCache
Local snapshotResolver:TLspFileSnapshotResolver = TLspFileSnapshotResolver.Create(snapshotConfiguration, sharedDependencies)
Local localImportDirectory:String = "/tmp/blitzmax-lsp-local-interface-layout-test"
Local localImportSource:String = localImportDirectory + "/main.bmx"
Local localImportInterface:String = localImportDirectory + "/.bmx/common.bmx." + snapshotConfiguration.InterfaceMung() + ".i"
CreateDir(localImportDirectory + "/.bmx", True)
SaveText("SuperStrict~nCachedValue%", localImportInterface)
Local commonInterface:TSnapshotText = snapshotResolver.ResolveInterface(localImportSource, "common.bmx", True, False)
Check(commonInterface <> Null, "quoted source import loads its compiler interface from the sibling .bmx directory")
Check(commonInterface.path = localImportInterface, "quoted source interface retains its generated path")
Local cachedCommonInterface:TSnapshotText = snapshotResolver.ResolveInterface(localImportSource, "common.bmx", True, False)
Check(sharedDependencies.ParsedInterfaceCount() = 1, "unchanged compiler interfaces are parsed once across LSP snapshots")
Check(commonInterface.interfaceFile <> cachedCommonInterface.interfaceFile And commonInterface.interfaceFile.declarations[0] <> cachedCommonInterface.interfaceFile.declarations[0], "parsed interface reuse returns a request-owned record graph")
commonInterface.interfaceFile.declarations[0].documentationPath = "mutated"
Check(Not cachedCommonInterface.interfaceFile.declarations[0].documentationPath.length, "request-local interface enrichment cannot leak through the LSP cache")
SaveText("SuperStrict~nReplacementValue%", localImportInterface)
Local replacedCommonInterface:TSnapshotText = snapshotResolver.ResolveInterface(localImportSource, "common.bmx", True, False)
Check(replacedCommonInterface.interfaceFile.declarations[0].name = "ReplacementValue" And sharedDependencies.ParsedInterfaceCount() = 1, "interface publication invalidation replaces the parsed LSP cache entry")
DeleteDir(localImportDirectory, True)

Local importPathDirectory:String = "/tmp/blitzmax-lsp-import-path-completion-test"
Local importPathHelpers:String = importPathDirectory + "/helpers"
CreateDir(importPathHelpers + "/subdir", True)
SaveText("SuperStrict", importPathHelpers + "/string.bmx")
SaveText("void helper(void) {}", importPathHelpers + "/native.c")
SaveText("not an import", importPathHelpers + "/notes.txt")
SaveText("SuperStrict", importPathHelpers + "/.hidden.bmx")
Local importPathDocument:TLspDocument = New TLspDocument
Local importPathContext:TLspWorkspaceContext = TLspWorkspaceContext.Create("file:///tmp/blitzmax-lsp-import-path-completion-test", "path completion", snapshotConfiguration.Copy(), sharedDependencies)
importPathDocument.uri = "file:///tmp/blitzmax-lsp-import-path-completion-test/main.bmx"
importPathDocument.path = importPathDirectory + "/main.bmx"
importPathDocument.text = "SuperStrict~nImport ~qhel~nImport ~qhelpers/str~nInclude ~qhelpers/str~q~nImport ~qhelpers/na~nInclude ~qhelpers/na~nImport ~qhelpers/sub~nImport ~qmain"
SaveText(importPathDocument.text, importPathDocument.path)
Local importPathSource:TSourceText = TSourceText.Create(importPathDocument.text, importPathDocument.path)
Local directoryCompletionOffset:Int = importPathDocument.text.Find("Import ~qhel") + "Import ~qhel".length
Local directoryCompletionPosition:TSourcePosition = importPathSource.Position(directoryCompletionOffset)
Local directoryCompletionItem:TJSONObject = FindCompletionItem(TJSONArray(TBlitzMaxLspCompletion.Query(importPathDocument, importPathContext, directoryCompletionPosition.line, directoryCompletionPosition.column)), "helpers/")
Check(directoryCompletionItem <> Null And directoryCompletionItem.GetInteger("kind") = 19 And TJSONObject(directoryCompletionItem.Get("textEdit")).GetString("newText") = "helpers/", "quoted path completion offers directories progressively without closing the string")
Local sourcePathCompletionOffset:Int = importPathDocument.text.Find("Import ~qhelpers/str") + "Import ~qhelpers/str".length
Local sourcePathCompletionPosition:TSourcePosition = importPathSource.Position(sourcePathCompletionOffset)
Local sourcePathCompletionItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(importPathDocument, importPathContext, sourcePathCompletionPosition.line, sourcePathCompletionPosition.column))
Local sourcePathCompletionItem:TJSONObject = FindCompletionItem(sourcePathCompletionItems, "helpers/string.bmx")
Local sourcePathCompletionEdit:TJSONObject = TJSONObject(sourcePathCompletionItem.Get("textEdit"))
Local sourcePathCompletionRange:TJSONObject = TJSONObject(sourcePathCompletionEdit.Get("range"))
Check(sourcePathCompletionEdit.GetString("newText") = "helpers/string.bmx~q" And TJSONObject(sourcePathCompletionRange.Get("start")).GetInteger("character") = 8 And TJSONObject(sourcePathCompletionRange.Get("end")).GetInteger("character") = 19, "unterminated quoted Import completion replaces the path content and supplies the closing quote")
Check(FindCompletionItem(sourcePathCompletionItems, "helpers/notes.txt") = Null And FindCompletionItem(sourcePathCompletionItems, "helpers/.hidden.bmx") = Null, "quoted Import completion excludes irrelevant and hidden files")
Local closedIncludeOffset:Int = importPathDocument.text.Find("Include ~qhelpers/str~q") + "Include ~qhelpers/str".length
Local closedIncludePosition:TSourcePosition = importPathSource.Position(closedIncludeOffset)
Local closedIncludeItem:TJSONObject = FindCompletionItem(TJSONArray(TBlitzMaxLspCompletion.Query(importPathDocument, importPathContext, closedIncludePosition.line, closedIncludePosition.column)), "helpers/string.bmx")
Check(TJSONObject(closedIncludeItem.Get("textEdit")).GetString("newText") = "helpers/string.bmx", "path completion preserves an existing closing quote")
Local nativePathCompletionOffset:Int = importPathDocument.text.Find("Import ~qhelpers/na") + "Import ~qhelpers/na".length
Local nativePathCompletionPosition:TSourcePosition = importPathSource.Position(nativePathCompletionOffset)
Check(FindCompletionItem(TJSONArray(TBlitzMaxLspCompletion.Query(importPathDocument, importPathContext, nativePathCompletionPosition.line, nativePathCompletionPosition.column)), "helpers/native.c") <> Null, "quoted Import completion includes native build inputs")
Local includeNativeOffset:Int = importPathDocument.text.Find("Include ~qhelpers/na") + "Include ~qhelpers/na".length
Local includeNativePosition:TSourcePosition = importPathSource.Position(includeNativeOffset)
Check(FindCompletionItem(TJSONArray(TBlitzMaxLspCompletion.Query(importPathDocument, importPathContext, includeNativePosition.line, includeNativePosition.column)), "helpers/native.c") = Null, "Include path completion remains restricted to BlitzMax source files")
Local nestedDirectoryOffset:Int = importPathDocument.text.Find("Import ~qhelpers/sub") + "Import ~qhelpers/sub".length
Local nestedDirectoryPosition:TSourcePosition = importPathSource.Position(nestedDirectoryOffset)
Check(FindCompletionItem(TJSONArray(TBlitzMaxLspCompletion.Query(importPathDocument, importPathContext, nestedDirectoryPosition.line, nestedDirectoryPosition.column)), "helpers/subdir/") <> Null, "quoted path completion traverses only the currently written directory segment")
Local selfImportOffset:Int = importPathDocument.text.Find("Import ~qmain") + "Import ~qmain".length
Local selfImportPosition:TSourcePosition = importPathSource.Position(selfImportOffset)
Check(FindCompletionItem(TJSONArray(TBlitzMaxLspCompletion.Query(importPathDocument, importPathContext, selfImportPosition.line, selfImportPosition.column)), "main.bmx") = Null, "quoted path completion does not suggest importing the current document")
DeleteDir(importPathDirectory, True)

Local transitiveDirectory:String = "/tmp/blitzmax-lsp-transitive-interface-origin-test"
Local transitiveMung:String = snapshotConfiguration.InterfaceMung()
CreateDir(transitiveDirectory + "/.bmx", True)
CreateDir(transitiveDirectory + "/generated/.bmx", True)
SaveText("SuperStrict~nimport ~qimgui_internal.bmx~q", transitiveDirectory + "/.bmx/imgui_image.bmx." + transitiveMung + ".i")
SaveText("SuperStrict", transitiveDirectory + "/.bmx/imgui_internal.bmx." + transitiveMung + ".i")
SaveText("SuperStrict~nimport ~q../source.bmx~q", transitiveDirectory + "/generated/.bmx/common_gen.bmx." + transitiveMung + ".i")
SaveText("SuperStrict", transitiveDirectory + "/.bmx/source.bmx." + transitiveMung + ".i")
Local transitiveSnapshot:TCompilationSnapshot = TCompilationSnapshotBuilder.Build(transitiveDirectory + "/main.bmx", "SuperStrict~nImport ~qimgui_image.bmx~q~nImport ~qgenerated/common_gen.bmx~q", snapshotResolver, snapshotConfiguration.SnapshotOptions())
Check(transitiveSnapshot.succeeded, "transitive quoted imports are resolved relative to their original source files: " + SnapshotDiagnosticSummary(transitiveSnapshot))
Check(transitiveSnapshot.diagnostics.length = 0, "hidden interface directories do not shift sibling or parent-relative imports")
DeleteDir(transitiveDirectory, True)
Local stringBuilderModuleDirectory:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/brl.mod/stringbuilder.mod"
Check(ModuleInterfacePath(snapshotConfiguration.sdkPath, "brl.stringbuilder", snapshotConfiguration.InterfaceMung()) = stringBuilderModuleDirectory + "/stringbuilder." + snapshotConfiguration.InterfaceMung() + ".i", "module interface remains beside its primary source")
Check(ModuleInterfacePath(snapshotConfiguration.sdkPath, "BRL.Stream", snapshotConfiguration.InterfaceMung()).Contains("/mod/brl.mod/stream.mod/stream."), "module interface lookup preserves canonical lowercase filesystem paths")
Local firstContext:TLspWorkspaceContext = TLspWorkspaceContext.Create("file:///first", "first", snapshotConfiguration.Copy(), sharedDependencies)
Local secondContext:TLspWorkspaceContext = TLspWorkspaceContext.Create("file:///second", "second", snapshotConfiguration.Copy(), sharedDependencies)
Local liveUnitDirectory:String = "/tmp/blitzmax-lsp-live-compilation-interface-test"
Local liveUnitTypePath:String = liveUnitDirectory + "/type.bmx"
Local liveUnitDeclPath:String = liveUnitDirectory + "/decl.bmx"
Local liveUnitParserPath:String = liveUnitDirectory + "/parser.bmx"
Local liveUnitInterfacePath:String = liveUnitDirectory + "/.bmx/type.bmx." + snapshotConfiguration.InterfaceMung() + ".i"
CreateDir(liveUnitDirectory + "/.bmx", True)
SaveText("SuperStrict~nInclude ~qdecl.bmx~q", liveUnitTypePath)
SaveText("Global ExistingValue:Int", liveUnitDeclPath)
SaveText("superstrict~nExistingValue%&", liveUnitInterfacePath)
SaveText("SuperStrict~nImport ~qtype.bmx~q~nLocal first:Int = ExistingValue", liveUnitParserPath)
Local liveUnitStore:TLspDocumentStore = New TLspDocumentStore
Local liveUnitContext:TLspWorkspaceContext = TLspWorkspaceContext.Create("file://" + liveUnitDirectory, "live-unit", snapshotConfiguration.Copy(), New TLspDependencyCache, liveUnitStore)
Local liveTypeDocument:TLspDocument = liveUnitStore.Open("file://" + liveUnitTypePath, "blitzmax", 1, LoadText(liveUnitTypePath))
Local liveDeclDocument:TLspDocument = liveUnitStore.Open("file://" + liveUnitDeclPath, "blitzmax", 1, LoadText(liveUnitDeclPath))
Local liveParserDocument:TLspDocument = liveUnitStore.Open("file://" + liveUnitParserPath, "blitzmax", 1, LoadText(liveUnitParserPath))
Check(liveUnitContext.Analyze(liveTypeDocument).Succeeded(), "including source compilation unit is available for live navigation")
Local diskInterfaceAnalysis:TLanguageAnalysis = liveUnitContext.Analyze(liveParserDocument)
Check(diskInterfaceAnalysis.model.diagnostics.length = 0, "dependent source initially resolves through its disk interface")
Local existingOffset:Int = liveParserDocument.text.Find("ExistingValue")
Local existingPosition:TSourcePosition = diskInterfaceAnalysis.syntaxTree.source.Position(existingOffset)
Local existingDefinition:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.Definition(liveParserDocument, liveUnitContext, liveUnitStore, existingPosition.line, existingPosition.column))
Check(existingDefinition.GetString("uri") = liveDeclDocument.uri, "disk interface reference redirects to the matching live included declaration")
Local existingHover:TJSONObject = TJSONObject(TBlitzMaxLspHover.Query(liveParserDocument, liveUnitContext, existingPosition.line, existingPosition.column))
Check(TJSONObject(existingHover.Get("contents")).GetString("value").Contains("Defined in [`decl.bmx:1`](file://" + liveUnitDeclPath + "#L1)"), "hover links live included-source provenance to its declaration line")
liveUnitStore.Change(liveDeclDocument.uri, 2, "Global ExistingValue:Int~nGlobal LiveValue:Int")
Check(liveUnitContext.Analyze(liveDeclDocument).Succeeded(), "edited include refreshes its owning source compilation unit")
liveParserDocument.text :+ "~nLocal second:Int = LiveValue"
liveParserDocument.version :+ 1
Local liveInterfaceAnalysis:TLanguageAnalysis = liveUnitContext.Analyze(liveParserDocument)
Check(liveInterfaceAnalysis.model.diagnostics.length = 0, "dependent source resolves declarations from the successful live compilation-unit interface")
Check(liveUnitContext.DependsOnPath(liveParserDocument.uri, liveUnitTypePath), "dependent analysis records the live interface root for invalidation")
Local liveOffset:Int = liveParserDocument.text.Find("LiveValue")
Local livePosition:TSourcePosition = liveInterfaceAnalysis.syntaxTree.source.Position(liveOffset)
Local liveDefinition:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.Definition(liveParserDocument, liveUnitContext, liveUnitStore, livePosition.line, livePosition.column))
Check(liveDefinition.GetString("uri") = liveDeclDocument.uri, "live interface declaration navigates to its edited included source")
DeleteDir(liveUnitDirectory, True)
Local arrayTypeHoverDocument:TLspDocument = New TLspDocument
arrayTypeHoverDocument.uri = "file:///first/array-type-hover.bmx"
arrayTypeHoverDocument.path = "/first/array-type-hover.bmx"
arrayTypeHoverDocument.text = "SuperStrict~nType TNewsEventSportTeam~nEnd Type~nType TNewsEventSportCollection~nMethod AddTeams(teams:TNewsEventSportTeam[])~nEnd Method~nEnd Type"
Local arrayTypeHoverAnalysis:TLanguageAnalysis = firstContext.Analyze(arrayTypeHoverDocument)
Local arrayTypeHoverOffset:Int = arrayTypeHoverDocument.text.Find("TNewsEventSportTeam", arrayTypeHoverDocument.text.Find("TNewsEventSportTeam") + 1)
Local arrayTypeHoverPosition:TSourcePosition = arrayTypeHoverAnalysis.syntaxTree.source.Position(arrayTypeHoverOffset)
Local arrayTypeHover:TJSONObject = TJSONObject(TBlitzMaxLspHover.Query(arrayTypeHoverDocument, firstContext, arrayTypeHoverPosition.line, arrayTypeHoverPosition.column))
Local arrayTypeHoverText:String = TJSONObject(arrayTypeHover.Get("contents")).GetString("value")
Check(arrayTypeHoverText.Contains("Type TNewsEventSportTeam") And arrayTypeHoverText.Contains("Defined in [`array-type-hover.bmx:2`](file:///first/array-type-hover.bmx#L2)"), "array element type hover links its local declaration provenance")
Local genericMemberHoverDocument:TLspDocument = New TLspDocument
genericMemberHoverDocument.uri = "file:///first/generic-member-hover.bmx"
genericMemberHoverDocument.path = "/first/generic-member-hover.bmx"
genericMemberHoverDocument.text = "SuperStrict~nType TBox<T>~nField value:T~nMethod Echo:T(input:T)~nReturn input~nEnd Method~nEnd Type~nType TDerived<T> Extends TBox<T>~nEnd Type~nType TPair<A, B>~nField second:B~nEnd Type~nLocal pair:TPair<String, TBox<Int>> = New TPair<String, TBox<Int>>()~npair.second.value = ~qhello~q~npair.second.Echo(1)~nLocal inherited:TDerived<Long> = New TDerived<Long>()~ninherited.value = 1"
Local genericMemberHoverAnalysis:TLanguageAnalysis = firstContext.Analyze(genericMemberHoverDocument)
Local pairSecondOffset:Int = genericMemberHoverDocument.text.Find("second", genericMemberHoverDocument.text.Find("pair.second"))
Local pairSecondPosition:TSourcePosition = genericMemberHoverAnalysis.syntaxTree.source.Position(pairSecondOffset)
Local pairSecondHover:TJSONObject = TJSONObject(TBlitzMaxLspHover.Query(genericMemberHoverDocument, firstContext, pairSecondPosition.line, pairSecondPosition.column))
Local pairSecondHoverText:String = TJSONObject(pairSecondHover.Get("contents")).GetString("value")
Check(pairSecondHoverText.Contains("Field second:TBox<Int>") And pairSecondHoverText.Contains("Declared as:") And pairSecondHoverText.Contains("Field second:B"), "hover presents a nested generic field's instantiated type and original declaration")
Local pairValueOffset:Int = genericMemberHoverDocument.text.Find("value", genericMemberHoverDocument.text.Find("pair.second"))
Local pairValuePosition:TSourcePosition = genericMemberHoverAnalysis.syntaxTree.source.Position(pairValueOffset)
Local pairValueHover:TJSONObject = TJSONObject(TBlitzMaxLspHover.Query(genericMemberHoverDocument, firstContext, pairValuePosition.line, pairValuePosition.column))
Local pairValueHoverText:String = TJSONObject(pairValueHover.Get("contents")).GetString("value")
Check(pairValueHoverText.Contains("Field value:Int") And pairValueHoverText.Contains("Field value:T"), "hover carries generic substitution through a chained member expression")
Local pairEchoOffset:Int = genericMemberHoverDocument.text.Find("Echo", genericMemberHoverDocument.text.Find("pair.second.Echo"))
Local pairEchoPosition:TSourcePosition = genericMemberHoverAnalysis.syntaxTree.source.Position(pairEchoOffset)
Local pairEchoHover:TJSONObject = TJSONObject(TBlitzMaxLspHover.Query(genericMemberHoverDocument, firstContext, pairEchoPosition.line, pairEchoPosition.column))
Local pairEchoHoverText:String = TJSONObject(pairEchoHover.Get("contents")).GetString("value")
Check(pairEchoHoverText.Contains("Method Echo:Int(input:Int)") And pairEchoHoverText.Contains("Method Echo:T(input:T)"), "hover presents instantiated parameter and return types for a generic owner's Method")
Local inheritedValueOffset:Int = genericMemberHoverDocument.text.Find("value", genericMemberHoverDocument.text.Find("inherited.value"))
Local inheritedValuePosition:TSourcePosition = genericMemberHoverAnalysis.syntaxTree.source.Position(inheritedValueOffset)
Local inheritedValueHover:TJSONObject = TJSONObject(TBlitzMaxLspHover.Query(genericMemberHoverDocument, firstContext, inheritedValuePosition.line, inheritedValuePosition.column))
Local inheritedValueHoverText:String = TJSONObject(inheritedValueHover.Get("contents")).GetString("value")
Check(inheritedValueHoverText.Contains("Field value:Long") And inheritedValueHoverText.Contains("Field value:T"), "hover substitutes inherited generic members at their use site")
Local genericMemberCompletionDocument:TLspDocument = New TLspDocument
genericMemberCompletionDocument.uri = "file:///first/generic-member-completion.bmx"
genericMemberCompletionDocument.path = "/first/generic-member-completion.bmx"
genericMemberCompletionDocument.text = "SuperStrict~nType TBox<T>~nField value:T~nMethod Echo:T(input:T)~nReturn input~nEnd Method~nEnd Type~nType TDerived<T> Extends TBox<T>~nEnd Type~nType TPair<A, B>~nField second:B~nEnd Type~nLocal pair:TPair<String, TBox<Int>> = New TPair<String, TBox<Int>>()~nLocal inherited:TDerived<Long> = New TDerived<Long>()~npair.~npair.second.~ninherited."
Local genericMemberCompletionAnalysis:TLanguageAnalysis = firstContext.Analyze(genericMemberCompletionDocument)
Local pairCompletionOffset:Int = genericMemberCompletionDocument.text.Find("pair.~n") + "pair.".length
Local pairCompletionPosition:TSourcePosition = genericMemberCompletionAnalysis.syntaxTree.source.Position(pairCompletionOffset)
Local pairCompletionItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(genericMemberCompletionDocument, firstContext, pairCompletionPosition.line, pairCompletionPosition.column))
Local secondCompletionItem:TJSONObject = FindCompletionItem(pairCompletionItems, "second")
Local secondCompletionLabel:TJSONObject = TJSONObject(secondCompletionItem.Get("labelDetails"))
Check(secondCompletionItem.GetString("detail").Contains("Field second:TBox<Int>") And secondCompletionLabel.GetString("description") = ":TBox<Int>", "member completion presents a generic field's instantiated type in its detail and label")
Check(TBlitzMaxLspCompletion.FindSymbol(genericMemberCompletionAnalysis.model.globalScope, TJSONObject(secondCompletionItem.Get("data"))).name = "second", "instantiated completion detail retains the original symbol identity for completion-item resolution")
Local nestedCompletionOffset:Int = genericMemberCompletionDocument.text.Find("pair.second.") + "pair.second.".length
Local nestedCompletionPosition:TSourcePosition = genericMemberCompletionAnalysis.syntaxTree.source.Position(nestedCompletionOffset)
Local nestedCompletionItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(genericMemberCompletionDocument, firstContext, nestedCompletionPosition.line, nestedCompletionPosition.column))
Local valueCompletionItem:TJSONObject = FindCompletionItem(nestedCompletionItems, "value")
Local echoCompletionItem:TJSONObject = FindCompletionItemWithLabelDetail(nestedCompletionItems, "Echo", "(input:Int)")
Check(valueCompletionItem.GetString("detail").Contains("Field value:Int") And TJSONObject(valueCompletionItem.Get("labelDetails")).GetString("description") = ":Int", "chained member completion carries nested generic substitution into a field")
Check(echoCompletionItem.GetString("detail").Contains("Method Echo:Int(input:Int)") And TJSONObject(echoCompletionItem.Get("labelDetails")).GetString("description") = ":Int", "chained member completion substitutes a generic owner's Method signature")
Local nestedSnippetItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(genericMemberCompletionDocument, firstContext, nestedCompletionPosition.line, nestedCompletionPosition.column, True))
Local nestedEchoSnippet:TJSONObject = FindCompletionItemWithLabelDetail(nestedSnippetItems, "Echo", "(input:Int)")
Check(nestedEchoSnippet.GetInteger("insertTextFormat") = 2 And nestedEchoSnippet.GetString("insertText") = "Echo(${1:input})$0", "constructed generic Method completion supplies a named call placeholder without changing its instantiated presentation")
Local resolvedEchoCompletion:TJSONObject = TBlitzMaxLspCompletion.Resolve(echoCompletionItem, genericMemberCompletionDocument, firstContext)
Local resolvedEchoDocumentation:String = TJSONObject(resolvedEchoCompletion.Get("documentation")).GetString("value")
Check(resolvedEchoDocumentation.Contains("Method Echo:Int(input:Int)") And resolvedEchoDocumentation.Contains("Declared as:") And resolvedEchoDocumentation.Contains("Method Echo:T(input:T)"), "completion item resolve presents the constructed signature and original generic declaration")
Local inheritedCompletionOffset:Int = genericMemberCompletionDocument.text.Find("inherited.") + "inherited.".length
Local inheritedCompletionPosition:TSourcePosition = genericMemberCompletionAnalysis.syntaxTree.source.Position(inheritedCompletionOffset)
Local inheritedCompletionItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(genericMemberCompletionDocument, firstContext, inheritedCompletionPosition.line, inheritedCompletionPosition.column))
Check(FindCompletionItem(inheritedCompletionItems, "value").GetString("detail").Contains("Field value:Long"), "member completion substitutes inherited generic fields")
Local inheritedEchoCompletionItem:TJSONObject = FindCompletionItemWithLabelDetail(inheritedCompletionItems, "Echo", "(input:Long)")
Check(inheritedEchoCompletionItem.GetString("detail").Contains("Method Echo:Long(input:Long)"), "member completion substitutes inherited generic Methods")
Local genericSignatureDocument:TLspDocument = New TLspDocument
genericSignatureDocument.uri = "file:///first/generic-signature-help.bmx"
genericSignatureDocument.path = "/first/generic-signature-help.bmx"
genericSignatureDocument.text = "SuperStrict~nInterface IValue~nEnd Interface~nStruct SValue~nEnd Struct~nType TBox<T>~nMethod Describe:T(value:T, text:String, values:Int[], objectValue:Object, interfaceValue:IValue, structValue:SValue, callback:Closure<T(input:T)>)~nReturn value~nEnd Method~nEnd Type~nType TDerived<T> Extends TBox<T>~nEnd Type~nType TPair<A, B>~nField second:B~nEnd Type~nLocal box:TBox<String>~nLocal pair:TPair<String, TBox<Int>>~nLocal inherited:TDerived<Long>~nbox.Describe(~npair.second.Describe(~ninherited.Describe("
Local genericSignatureAnalysis:TLanguageAnalysis = firstContext.Analyze(genericSignatureDocument)
Local directSignature:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.SignatureHelp(genericSignatureDocument, firstContext, 18, genericSignatureDocument.text.Split("~n")[18].length))
Check(HasSignatureLabel(directSignature, "Method Describe:String(value:String, text:String, values:Int[], objectValue:Object, interfaceValue:IValue, structValue:SValue, callback:Closure<String(input:String)>)"), "signature help survives an empty incomplete call and renders scalar, String, Array, Object, Interface, Struct, and Closure types")
Local nestedSignature:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.SignatureHelp(genericSignatureDocument, firstContext, 19, genericSignatureDocument.text.Split("~n")[19].length))
Check(HasSignatureLabel(nestedSignature, "Method Describe:Int(value:Int") And HasSignatureLabel(nestedSignature, "callback:Closure<Int(input:Int)>)"), "signature help carries nested constructed generic substitutions through an incomplete member call")
Local inheritedSignature:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.SignatureHelp(genericSignatureDocument, firstContext, 20, genericSignatureDocument.text.Split("~n")[20].length))
Check(HasSignatureLabel(inheritedSignature, "Method Describe:Long(value:Long") And inheritedSignature.GetInteger("activeParameter") = 0, "signature help substitutes inherited generic members while an argument is malformed")
Local genericInterfaceSignatureDocument:TLspDocument = New TLspDocument
genericInterfaceSignatureDocument.uri = "file:///first/generic-interface-signature-help.bmx"
genericInterfaceSignatureDocument.path = "/first/generic-interface-signature-help.bmx"
genericInterfaceSignatureDocument.text = "SuperStrict~nInterface IProvider<T>~nMethod Provide:T(value:T)~nEnd Interface~nLocal provider:IProvider<String>~nprovider.Provide("
firstContext.Analyze(genericInterfaceSignatureDocument)
Local genericInterfaceSignature:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.SignatureHelp(genericInterfaceSignatureDocument, firstContext, 5, genericInterfaceSignatureDocument.text.Split("~n")[5].length))
Check(HasSignatureLabel(genericInterfaceSignature, "Method Provide:String(value:String)"), "signature help substitutes constructed generic Interface methods during incomplete calls")

Local genericRoutineSignatureDocument:TLspDocument = New TLspDocument
genericRoutineSignatureDocument.uri = "file:///first/generic-routine-signature-help.bmx"
genericRoutineSignatureDocument.path = "/first/generic-routine-signature-help.bmx"
genericRoutineSignatureDocument.text = "SuperStrict~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nIdentity(~qtext~q"
firstContext.Analyze(genericRoutineSignatureDocument)
Local genericRoutineSignature:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.SignatureHelp(genericRoutineSignatureDocument, firstContext, 4, genericRoutineSignatureDocument.text.Split("~n")[4].length))
Check(HasSignatureLabel(genericRoutineSignature, "Function Identity<T>:String(value:String)"), "signature help retains inferred generic routine types while the closing parenthesis is missing")

Local overloadSignatureDocument:TLspDocument = New TLspDocument
overloadSignatureDocument.uri = "file:///first/overload-signature-help.bmx"
overloadSignatureDocument.path = "/first/overload-signature-help.bmx"
overloadSignatureDocument.text = "SuperStrict~nFunction Choose:Int(value:Object, position:Int = 0)~nReturn 1~nEnd Function~nFunction Choose:String(value:String, suffix:String = ~q~q)~nReturn value + suffix~nEnd Function~nLocal selected:String = Choose(~qvalue~q)~nChoose(~qvalue~q,"
firstContext.Analyze(overloadSignatureDocument)
Local selectedOverloadSignature:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.SignatureHelp(overloadSignatureDocument, firstContext, 7, 39))
Check(TJSONArray(selectedOverloadSignature.Get("signatures")).Size() = 2 And selectedOverloadSignature.GetInteger("activeSignature") = 1, "signature help returns compatible overloads and identifies the semantically selected overload")
Local malformedOverloadSignature:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.SignatureHelp(overloadSignatureDocument, firstContext, 8, overloadSignatureDocument.text.Split("~n")[8].length))
Check(malformedOverloadSignature <> Null And TJSONArray(malformedOverloadSignature.Get("signatures")).Size() = 2 And malformedOverloadSignature.GetInteger("activeParameter") = 1, "signature help remains available and advances the active parameter after a trailing comma without a closing parenthesis")
Local privateNavigationDocument:TLspDocument = New TLspDocument
privateNavigationDocument.uri = "file:///first/private-navigation.bmx"
privateNavigationDocument.path = "/first/private-navigation.bmx"
privateNavigationDocument.text = "SuperStrict~nType TSecret~nPrivate~nFunction Hidden()~nEnd Function~nEnd Type~nTSecret.Hidden()"
Local privateNavigationAnalysis:TLanguageAnalysis = firstContext.Analyze(privateNavigationDocument)
Check(HasDiagnostic(privateNavigationAnalysis.model.diagnostics, "BMX3318"), "Private Type declarations remain inaccessible outside their declaring Type in the same compilation unit")
Local privateDefinition:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.Definition(privateNavigationDocument, firstContext, store, 6, 10))
Local privateDefinitionStart:TJSONObject = TJSONObject(TJSONObject(privateDefinition.Get("range")).Get("start"))
Check(privateDefinition.GetString("uri") = privateNavigationDocument.uri And privateDefinitionStart.GetInteger("line") = 3 And privateDefinitionStart.GetInteger("character") = 9, "definition navigation still reaches an inaccessible Private declaration for correction")
Local stringBuilderDocument:TLspDocument = New TLspDocument
stringBuilderDocument.uri = "file:///first/stringbuilder-override.bmx"
stringBuilderDocument.path = "/first/stringbuilder-override.bmx"
stringBuilderDocument.text = "SuperStrict~nImport BRL.StringBuilder~nFunction Render:String()~nLocal matchTimes:TStringBuilder = New TStringBuilder()~nReturn matchTimes.ToString()~nEnd Function"
Local stringBuilderAnalysis:TLanguageAnalysis = firstContext.Analyze(stringBuilderDocument)
Local stringBuilderAmbiguity:Int
For Local stringBuilderDiagnostic:TDiagnostic = EachIn stringBuilderAnalysis.model.diagnostics
	If stringBuilderDiagnostic.code = "BMX3303" Then stringBuilderAmbiguity :+ 1
Next
Check(stringBuilderAmbiguity = 0, "an imported overriding ToString method wins over Object.ToString during overload resolution")
Local stringBuilderCall:TCallExpressionSyntax = FindCall(stringBuilderAnalysis, stringBuilderDocument.text, "matchTimes.ToString()")
Check(stringBuilderAnalysis.model.ResolvedCall(stringBuilderCall).routine.containingScope.owner.name = "TStringBuilder", "the overriding TStringBuilder.ToString method is selected")
Local csvSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/text.mod/csv.mod/csv.bmx"
Local csvDocument:TLspDocument = New TLspDocument
csvDocument.uri = "file://" + csvSourcePath
csvDocument.path = csvSourcePath
csvDocument.text = LoadText(csvSourcePath)
Local csvAnalysis:TLanguageAnalysis = firstContext.Analyze(csvDocument)
For Local diagnostic:TDiagnostic = EachIn csvAnalysis.model.diagnostics
	Check(Not (diagnostic.code = "BMX3302" And diagnostic.message.Contains("ReadStream") And diagnostic.message.Contains("String")), "text.csv Parse falls back from its incompatible member to BRL.Stream.ReadStream")
Next
Local jsonSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/text.mod/json.mod/json.bmx"
Local jsonDocument:TLspDocument = New TLspDocument
jsonDocument.uri = "file://" + jsonSourcePath
jsonDocument.path = jsonSourcePath
jsonDocument.text = LoadText(jsonSourcePath)
Local jsonAnalysis:TLanguageAnalysis = firstContext.Analyze(jsonDocument)
For Local diagnostic:TDiagnostic = EachIn jsonAnalysis.model.diagnostics
	Check(Not (diagnostic.code = "BMX3302" And (diagnostic.message.Contains("call 'Read'") Or diagnostic.message.Contains("call 'Write'")) And diagnostic.message.Contains("Size_T")), "text.json callbacks pass Size_T counts to TStream Long methods")
Next
Local httpSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/net.mod/http.mod/http_util.bmx"
Local httpDocument:TLspDocument = New TLspDocument
httpDocument.uri = "file://" + httpSourcePath
httpDocument.path = httpSourcePath
httpDocument.text = LoadText(httpSourcePath)
Local httpAnalysis:TLanguageAnalysis = firstContext.Analyze(httpDocument)
For Local diagnostic:TDiagnostic = EachIn httpAnalysis.model.diagnostics
	Check(Not (diagnostic.code = "BMX3303" And diagnostic.message.Contains("TryGetValue")), "net.http generic map member hides its substituted IMap declaration")
Next
Local systemDriverDocument:TLspDocument = New TLspDocument
systemDriverDocument.uri = "file:///first/system-driver-provenance.bmx"
systemDriverDocument.path = "/first/system-driver-provenance.bmx"
systemDriverDocument.text = "SuperStrict~nImport BRL.System~nLocal driver:TSystemDriver"
Local systemDriverAnalysis:TLanguageAnalysis = firstContext.Analyze(systemDriverDocument)
Local systemDriverScope:TScope = systemDriverAnalysis.model.ImportedScope("brl.system")
Check(systemDriverScope <> Null, "BRL.System publishes an imported scope from " + snapshotConfiguration.sdkPath)
Local systemDriverSymbols:TSymbol[] = systemDriverScope.LookupLocal("TSystemDriver")
Check(systemDriverSymbols.length > 0, "BRL.System publishes TSystemDriver from its quoted driver source")
Local systemDriverSymbol:TSymbol = systemDriverSymbols[0]
Local systemDriverSource:String = RealPath(NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/brl.mod/system.mod/driver.bmx").Replace("\", "/")
Check(systemDriverSymbol.originPath = systemDriverSource And systemDriverSymbol.originLine = 4, "semantic imports follow aggregate and per-source interfaces to the original BRL.System source (expected " + systemDriverSource + ":4, received " + systemDriverSymbol.originPath + ":" + systemDriverSymbol.originLine + ")")
Local systemDriverDefinition:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.Definition(systemDriverDocument, firstContext, store, 2, 18))
Local systemDriverDefinitionStart:TJSONObject = TJSONObject(TJSONObject(systemDriverDefinition.Get("range")).Get("start"))
Check(systemDriverDefinition.GetString("uri").EndsWith("/mod/brl.mod/system.mod/driver.bmx") And systemDriverDefinitionStart.GetInteger("line") = 3 And systemDriverDefinitionStart.GetInteger("character") = 5, "definition navigation follows a transitive compiler-interface source chain")
Local threadedDocument:TLspDocument = New TLspDocument
threadedDocument.uri = "file:///first/threaded-imports.bmx"
threadedDocument.path = "/first/threaded-imports.bmx"
threadedDocument.text = "SuperStrict~n?Threaded~nImport BRL.Time~nImport Pub.Stdc~n?~nFunction Probe(timeout:ULong, unit:ETimeUnit = ETimeUnit.Milliseconds)~nLocal timeoutMs:ULong = TimeUnitToMillis(timeout, unit)~nLocal now:ULong = CurrentUnixTime()~nEnd Function"
Local threadedAnalysis:TLanguageAnalysis = firstContext.Analyze(threadedDocument)
Check(threadedAnalysis.model.diagnostics.length = 0, "threaded imports expose enum defaults and imported functions")
Local objectInheritanceDocument:TLspDocument = New TLspDocument
objectInheritanceDocument.uri = "file:///first/implicit-object-members.bmx"
objectInheritanceDocument.path = "/first/implicit-object-members.bmx"
objectInheritanceDocument.text = "SuperStrict~nFramework BRL.StandardIO~nLocal plain:TPlainHash = New TPlainHash~nLocal inherited:UInt = plain.HashCode()~nLocal overridden:TOverrideHash = New TOverrideHash~nLocal own:UInt = overridden.HashCode()~nType TPlainHash~nEnd Type~nType TOverrideHash~nMethod HashCode:UInt()~nReturn 1234~nEnd Method~nEnd Type"
Local objectInheritanceAnalysis:TLanguageAnalysis = firstContext.Analyze(objectInheritanceDocument)
Check(objectInheritanceAnalysis.model.diagnostics.length = 0, "ordinary Types inherit Object runtime members while direct overrides win")
Local objectRuntimeSymbol:TSymbol = objectInheritanceAnalysis.model.BuiltinType("Object").runtimeSymbol
Check(objectRuntimeSymbol.documentation <> Null And objectRuntimeSymbol.documentation.summary.Contains("root reference type"), "Object receives companion type documentation")
Check(objectRuntimeSymbol.memberScope.LookupLocal("HashCode")[0].documentation.summary.Contains("hash code"), "Object methods receive companion documentation")
Local contextualDocument:TLspDocument = New TLspDocument
contextualDocument.uri = "file:///first/contextual-completion.bmx"
contextualDocument.path = "/first/contextual-completion.bmx"
contextualDocument.text = "SuperStrict~nGlobal shared:Int~nConst LIMIT:Int = 1~nFunction Choose:Int(value:Int)~nReturn value~nEnd Function~nFunction Choose:Int(left:Int, right:Int)~nReturn left + right~nEnd Function~nFunction Probe:Int(parameter:Int)~nLocal shared:String~nLocal before:Int~nLocal result:Int = bef~nLocal after:Int~nReturn result~nEnd Function~nType TContext~nField value:Int~nGlobal total:Int~nMethod Work:Int(amount:Int)~nLocal methodResult:Int = val~nEnd Method~nFunction StaticWork:Int()~nLocal staticResult:Int = tot~nEnd Function~nEnd Type"
firstContext.Analyze(contextualDocument)
Local contextualItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(contextualDocument, firstContext, 12, 100))
Check(FindCompletionItem(contextualItems, "before") <> Null And FindCompletionItem(contextualItems, "before").GetInteger("kind") = 6, "ordinary completion includes preceding locals")
Check(FindCompletionItem(contextualItems, "parameter") <> Null, "ordinary completion includes routine parameters")
Check(FindCompletionItem(contextualItems, "LIMIT") <> Null And FindCompletionItem(contextualItems, "LIMIT").GetInteger("kind") = 21, "ordinary completion includes constants")
Check(CompletionItemCount(contextualItems, "Choose") = 2, "ordinary completion preserves visible routine overloads")
Check(CompletionItemCount(contextualItems, "shared") = 1, "a nearer local suppresses a shadowed global completion")
Check(FindCompletionItem(contextualItems, "after") = Null, "ordinary completion excludes locals declared after the cursor")
Local beforeCompletion:TJSONObject = FindCompletionItem(contextualItems, "before")
Local beforeTextEdit:TJSONObject = TJSONObject(beforeCompletion.Get("textEdit"))
Local beforeEditRange:TJSONObject = TJSONObject(beforeTextEdit.Get("range"))
Check(beforeCompletion.GetString("filterText") = "before" And beforeTextEdit.GetString("newText") = "before" And TJSONObject(beforeEditRange.Get("start")).GetInteger("line") = 12 And TJSONObject(beforeEditRange.Get("start")).GetInteger("character") = 19 And TJSONObject(beforeEditRange.Get("end")).GetInteger("character") = 22, "ordinary completion explicitly replaces the written identifier prefix")
Local methodContextItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(contextualDocument, firstContext, 20, 100))
Check(FindCompletionItem(methodContextItems, "value") <> Null And FindCompletionItem(methodContextItems, "Work") <> Null, "Methods receive implicit instance member completions")
Check(FindCompletionItem(methodContextItems, "total") <> Null And FindCompletionItem(methodContextItems, "StaticWork") <> Null, "Methods also receive implicit type member completions")
Local functionContextItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(contextualDocument, firstContext, 23, 100))
Check(FindCompletionItem(functionContextItems, "total") <> Null And FindCompletionItem(functionContextItems, "StaticWork") <> Null, "type Functions receive static member completions")
Check(FindCompletionItem(functionContextItems, "value") = Null And FindCompletionItem(functionContextItems, "Work") = Null, "type Functions exclude implicit instance members")

Local stringCompletionDocument:TLspDocument = New TLspDocument
stringCompletionDocument.uri = "file:///first/string-completion.bmx"
stringCompletionDocument.path = "/first/string-completion.bmx"
stringCompletionDocument.text = "SuperStrict~nFunction MakeText:String()~nReturn ~qtext~q~nEnd Function~nFunction Accept(value:String)~nEnd Function~nAccept(~qhello~q)~nAccept(~q~q)~nAccept(~qunfinished"
Local stringCompletionAnalysis:TLanguageAnalysis = firstContext.Analyze(stringCompletionDocument)
Local closedStringOffset:Int = stringCompletionDocument.text.Find("~qhello~q") + "~qhel".length
Local closedStringPosition:TSourcePosition = stringCompletionAnalysis.syntaxTree.source.Position(closedStringOffset)
Check(TJSONArray(TBlitzMaxLspCompletion.Query(stringCompletionDocument, firstContext, closedStringPosition.line, closedStringPosition.column)).Size() = 0, "ordinary completion is suppressed within a populated String literal")
Local emptyStringOffset:Int = stringCompletionDocument.text.Find("Accept(~q~q)") + "Accept(~q".length
Local emptyStringPosition:TSourcePosition = stringCompletionAnalysis.syntaxTree.source.Position(emptyStringOffset)
Check(TJSONArray(TBlitzMaxLspCompletion.Query(stringCompletionDocument, firstContext, emptyStringPosition.line, emptyStringPosition.column)).Size() = 0, "ordinary completion is suppressed between the quotes of an empty String literal")
Local unterminatedStringPosition:TSourcePosition = stringCompletionAnalysis.syntaxTree.source.Position(stringCompletionDocument.text.length)
Check(TJSONArray(TBlitzMaxLspCompletion.Query(stringCompletionDocument, firstContext, unterminatedStringPosition.line, unterminatedStringPosition.column)).Size() = 0, "ordinary completion is suppressed at the end of an unterminated String literal during live editing")
Local afterStringOffset:Int = stringCompletionDocument.text.Find("~qhello~q") + "~qhello~q".length
Check(Not TBlitzMaxLspCompletion.IsStringContentPosition(TSyntaxNavigator.Create(stringCompletionAnalysis.syntaxTree), afterStringOffset), "the position immediately after a closing quote is not treated as String content")

Local rankedCompletionDocument:TLspDocument = New TLspDocument
rankedCompletionDocument.uri = "file:///first/ranked-completion.bmx"
rankedCompletionDocument.path = "/first/ranked-completion.bmx"
rankedCompletionDocument.text = "SuperStrict~nType TBox<T>~nEnd Type~nGlobal choiceGlobal:Int~nFunction MakeText:String()~nReturn ~qtext~q~nEnd Function~nFunction MakeObject:Object()~nReturn Null~nEnd Function~nFunction MakeStringBox:TBox<String>()~nReturn Null~nEnd Function~nFunction MakeIntBox:TBox<Int>()~nReturn Null~nEnd Function~nFunction Accept(value:String)~nEnd Function~nFunction Build:String()~nLocal choiceLocal:Int~nLocal chosen:Int = choice~nLocal text:String = Make~nLocal box:TBox<String> = Make~nAccept(Make)~nReturn Make~nEnd Function"
firstContext.Analyze(rankedCompletionDocument)
Local assignmentRankedItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(rankedCompletionDocument, firstContext, 21, 100))
Local makeTextCompletion:TJSONObject = FindCompletionItem(assignmentRankedItems, "MakeText")
Local makeObjectCompletion:TJSONObject = FindCompletionItem(assignmentRankedItems, "MakeObject")
Check(makeTextCompletion <> Null And makeObjectCompletion <> Null And makeTextCompletion.GetString("sortText").Compare(makeObjectCompletion.GetString("sortText"), True) < 0, "assignment completion ranks an exact expected return type ahead of an incompatible result without hiding either")
Local genericRankedItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(rankedCompletionDocument, firstContext, 22, 100))
Check(FindCompletionItem(genericRankedItems, "MakeStringBox").GetString("sortText").Compare(FindCompletionItem(genericRankedItems, "MakeIntBox").GetString("sortText"), True) < 0, "expected-type ranking distinguishes constructed generic result types")
Local argumentRankedItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(rankedCompletionDocument, firstContext, 23, 100))
Check(FindCompletionItem(argumentRankedItems, "MakeText").GetString("sortText").Compare(FindCompletionItem(argumentRankedItems, "MakeObject").GetString("sortText"), True) < 0, "call-argument completion uses the selected parameter type for ranking")
Local returnRankedItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(rankedCompletionDocument, firstContext, 24, 100))
Check(FindCompletionItem(returnRankedItems, "MakeText").GetString("sortText").Compare(FindCompletionItem(returnRankedItems, "MakeObject").GetString("sortText"), True) < 0, "Return completion ranks candidates using the enclosing routine return type")
Local scopeRankedItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(rankedCompletionDocument, firstContext, 20, 100))
Check(FindCompletionItem(scopeRankedItems, "choiceLocal").GetString("sortText").Compare(FindCompletionItem(scopeRankedItems, "choiceGlobal").GetString("sortText"), True) < 0, "ordinary completion preserves nearest-scope precedence in explicit sort keys")
Local inferredCompletionDocument:TLspDocument = New TLspDocument
inferredCompletionDocument.uri = "file:///first/inferred-completion.bmx"
inferredCompletionDocument.path = "/first/inferred-completion.bmx"
inferredCompletionDocument.text = "SuperStrict~nFunction MakeText:String()~nReturn ~qtext~q~nEnd Function~nFunction MakeObject:Object()~nReturn Null~nEnd Function~nLocal inferred := "
Local inferredCompletionAnalysis:TLanguageAnalysis = firstContext.Analyze(inferredCompletionDocument)
Local inferredCompletionContext:TCompletionRankingContext = TCompletionRankingContext.Query(inferredCompletionAnalysis.model, TSyntaxNavigator.Create(inferredCompletionAnalysis.syntaxTree), inferredCompletionDocument.text.length)
Local inferredCompletionItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(inferredCompletionDocument, firstContext, 7, 100))
Check(inferredCompletionContext.expectedType = Null And FindCompletionItem(inferredCompletionItems, "MakeText") <> Null And FindCompletionItem(inferredCompletionItems, "MakeObject") <> Null, "incomplete ':=' completion remains safe and does not invent an expected target type")
Local overloadRankedDocument:TLspDocument = New TLspDocument
overloadRankedDocument.uri = "file:///first/overload-ranked-completion.bmx"
overloadRankedDocument.path = "/first/overload-ranked-completion.bmx"
overloadRankedDocument.text = "SuperStrict~nFunction Pick:Object(value:Object)~nReturn value~nEnd Function~nFunction Pick:String(value:String)~nReturn value~nEnd Function~nPick(~qtext~q)"
firstContext.Analyze(overloadRankedDocument)
Local overloadRankedItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(overloadRankedDocument, firstContext, 7, 4))
Local objectPickCompletion:TJSONObject = FindCompletionItemWithLabelDetail(overloadRankedItems, "Pick", "(value:Object)")
Local stringPickCompletion:TJSONObject = FindCompletionItemWithLabelDetail(overloadRankedItems, "Pick", "(value:String)")
Check(objectPickCompletion <> Null And stringPickCompletion <> Null And stringPickCompletion.GetString("sortText").Compare(objectPickCompletion.GetString("sortText"), True) < 0, "completion ranks the overload selected by already-written arguments first while retaining compatible alternatives")
Local snippetCompletionDocument:TLspDocument = New TLspDocument
snippetCompletionDocument.uri = "file:///first/snippet-completion.bmx"
snippetCompletionDocument.path = "/first/snippet-completion.bmx"
snippetCompletionDocument.text = "SuperStrict~nFunction Required:Int(value:Int)~nReturn value~nEnd Function~nFunction Optional:Int(required:Int, extra:String = ~qvalue~q)~nReturn required~nEnd Function~nFunction NoArgs:Int()~nReturn 0~nEnd Function~nFunction Choose:Int(value:Int)~nReturn value~nEnd Function~nFunction Choose:Int(left:Int, right:Int)~nReturn left + right~nEnd Function~nLocal callback:Int(value:Int) = Req~nLocal invoked:Int = Opt~nLocal zero:Int = NoA~nLocal choice:Int = Cho~nLocal existing:Int = Opt()"
Local snippetCompletionAnalysis:TLanguageAnalysis = firstContext.Analyze(snippetCompletionDocument)
Local callableCaptureOffset:Int = snippetCompletionDocument.text.Find("= Req") + "= Req".length
Local callableCapturePosition:TSourcePosition = snippetCompletionAnalysis.syntaxTree.source.Position(callableCaptureOffset)
Local callableCaptureItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(snippetCompletionDocument, firstContext, callableCapturePosition.line, callableCapturePosition.column, True))
Local callableCaptureItem:TJSONObject = FindCompletionItem(callableCaptureItems, "Required")
Check(callableCaptureItem.GetString("insertText") = "Required" And callableCaptureItem.Get("insertTextFormat") = Null, "callable-typed completion keeps a routine reference as a bare name even when snippets are supported")
Local optionalSnippetOffset:Int = snippetCompletionDocument.text.Find("= Opt") + "= Opt".length
Local optionalSnippetPosition:TSourcePosition = snippetCompletionAnalysis.syntaxTree.source.Position(optionalSnippetOffset)
Local optionalSnippetItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(snippetCompletionDocument, firstContext, optionalSnippetPosition.line, optionalSnippetPosition.column, True))
Local optionalSnippetItem:TJSONObject = FindCompletionItem(optionalSnippetItems, "Optional")
Check(optionalSnippetItem.GetInteger("insertTextFormat") = 2 And optionalSnippetItem.GetString("insertText") = "Optional(${1:required})$0" And TJSONObject(optionalSnippetItem.Get("textEdit")).GetString("newText") = "Optional(${1:required})$0", "call snippets insert required named placeholders while omitting trailing optional parameters")
Local zeroSnippetOffset:Int = snippetCompletionDocument.text.Find("= NoA") + "= NoA".length
Local zeroSnippetPosition:TSourcePosition = snippetCompletionAnalysis.syntaxTree.source.Position(zeroSnippetOffset)
Local zeroSnippetItem:TJSONObject = FindCompletionItem(TJSONArray(TBlitzMaxLspCompletion.Query(snippetCompletionDocument, firstContext, zeroSnippetPosition.line, zeroSnippetPosition.column, True)), "NoArgs")
Check(zeroSnippetItem.GetString("insertText") = "NoArgs()$0", "parameterless routine completion inserts a call with the final cursor after its parentheses")
Local overloadSnippetOffset:Int = snippetCompletionDocument.text.Find("= Cho") + "= Cho".length
Local overloadSnippetPosition:TSourcePosition = snippetCompletionAnalysis.syntaxTree.source.Position(overloadSnippetOffset)
Local overloadSnippetItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(snippetCompletionDocument, firstContext, overloadSnippetPosition.line, overloadSnippetPosition.column, True))
Local oneArgumentChooseSnippet:TJSONObject = FindCompletionItemWithLabelDetail(overloadSnippetItems, "Choose", "(value:Int)")
Local twoArgumentChooseSnippet:TJSONObject = FindCompletionItemWithLabelDetail(overloadSnippetItems, "Choose", "(left:Int, right:Int)")
Check(oneArgumentChooseSnippet.GetString("insertText") = "Choose(${1:value})$0" And twoArgumentChooseSnippet.GetString("insertText") = "Choose(${1:left}, ${2:right})$0", "each overload supplies placeholders from its own parameter list")
Local existingParenthesisOffset:Int = snippetCompletionDocument.text.Find("Opt()") + "Opt".length
Local existingParenthesisPosition:TSourcePosition = snippetCompletionAnalysis.syntaxTree.source.Position(existingParenthesisOffset)
Local existingParenthesisItem:TJSONObject = FindCompletionItem(TJSONArray(TBlitzMaxLspCompletion.Query(snippetCompletionDocument, firstContext, existingParenthesisPosition.line, existingParenthesisPosition.column, True)), "Optional")
Check(existingParenthesisItem.GetString("insertText") = "Optional" And existingParenthesisItem.Get("insertTextFormat") = Null, "completion does not duplicate parentheses which already follow the completed name")
Local printCompletionDocument:TLspDocument = New TLspDocument
printCompletionDocument.uri = "file:///first/print-contextual-completion.bmx"
printCompletionDocument.path = "/first/print-contextual-completion.bmx"
printCompletionDocument.text = "SuperStrict~nFramework BRL.StandardIO~nLocal water:UInt~nwater :+ 100~nIf water > 50 Then~nPrint ~qwater = ~q + wat~nEndIf"
firstContext.Analyze(printCompletionDocument)
Local printContextItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(printCompletionDocument, firstContext, 5, 22))
Check(FindCompletionItem(printContextItems, "water") <> Null, "ordinary completion remains available in an incomplete Print expression")
Local typePositionDocument:TLspDocument = New TLspDocument
typePositionDocument.uri = "file:///first/type-position-completion.bmx"
typePositionDocument.path = "/first/type-position-completion.bmx"
typePositionDocument.text = "SuperStrict~nType TWidget~nEnd Type~nInterface IWidget~nEnd Interface~nEnum EWidget~nReady~nEnd Enum~nLocal typed:TWi~nLocal made:Object = New TWi~nLocal value:Int~nType TGeneric<T>~nMethod Convert<U>:U(value:T)~nLocal result:U~nEnd Method~nEnd Type"
firstContext.Analyze(typePositionDocument)
Local typePositionItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(typePositionDocument, firstContext, 8, 100))
Check(FindCompletionItem(typePositionItems, "TWidget") <> Null And FindCompletionItem(typePositionItems, "TWidget").GetInteger("kind") = 7, "type-position completion includes source Types")
Check(FindCompletionItem(typePositionItems, "IWidget") <> Null And FindCompletionItem(typePositionItems, "EWidget") <> Null, "type-position completion includes interfaces and enums")
Check(FindCompletionItem(typePositionItems, "String") <> Null And FindCompletionItem(typePositionItems, "String").GetInteger("kind") = 14, "type-position completion includes built-in types")
Check(FindCompletionItem(typePositionItems, "value") = Null And FindCompletionItem(typePositionItems, "Choose") = Null, "type-position completion excludes value and routine symbols")
Local newTypeItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(typePositionDocument, firstContext, 9, 100))
Check(FindCompletionItem(newTypeItems, "TWidget") <> Null And FindCompletionItem(newTypeItems, "Int") <> Null, "New completion includes source Types and primitive array element types")
Check(FindCompletionItem(newTypeItems, "IWidget") = Null And FindCompletionItem(newTypeItems, "EWidget") = Null, "New completion excludes interfaces and enums")
Local genericTypeItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(typePositionDocument, firstContext, 13, 100))
Check(FindCompletionItem(genericTypeItems, "T") <> Null And FindCompletionItem(genericTypeItems, "T").GetInteger("kind") = 25 And FindCompletionItem(genericTypeItems, "U") <> Null, "type-position completion includes visible generic type parameters")
Local constrainedTypeCompletionDocument:TLspDocument = New TLspDocument
constrainedTypeCompletionDocument.uri = "file:///first/constrained-type-completion.bmx"
constrainedTypeCompletionDocument.path = "/first/constrained-type-completion.bmx"
constrainedTypeCompletionDocument.text = "SuperStrict~nInterface IMarker~nEnd Interface~nType TMarked Implements IMarker~nEnd Type~nType TMissing~nEnd Type~nType TConstrained<T> Where T Extends IMarker~nEnd Type~nType TDependent<A, B> Where B Extends A~nEnd Type~nType TPair<A, B>~nEnd Type~nFunction Keep<T>:T(value:T) Where T Extends IMarker~nReturn value~nEnd Function~nType TOwner~nMethod Convert<T>:T(value:T) Where T Extends IMarker~nReturn value~nEnd Method~nEnd Type~nLocal owner:TOwner~nLocal direct:TConstrained<TM~nLocal nested:TPair<String, TConstrained<TM~nLocal dependent:TDependent<IMarker, TM~nLocal routine := Keep<TM~nLocal member := owner.Convert<TM~nLocal comparison:Int = 1 < TM"
Local constrainedTypeCompletionAnalysis:TLanguageAnalysis = firstContext.Analyze(constrainedTypeCompletionDocument)
Local directGenericOffset:Int = constrainedTypeCompletionDocument.text.Find("TConstrained<TM") + "TConstrained<TM".length
Local directGenericPosition:TSourcePosition = constrainedTypeCompletionAnalysis.syntaxTree.source.Position(directGenericOffset)
Local directGenericItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(constrainedTypeCompletionDocument, firstContext, directGenericPosition.line, directGenericPosition.column))
Check(FindCompletionItem(directGenericItems, "TMarked") <> Null And FindCompletionItem(directGenericItems, "TMissing") <> Null, "incomplete generic arguments offer visible type candidates without hiding incompatible recovery choices")
Check(FindCompletionItem(directGenericItems, "TMarked").GetString("sortText").Compare(FindCompletionItem(directGenericItems, "TMissing").GetString("sortText"), True) < 0, "generic argument completion ranks a type satisfying the active constraint ahead of an equally prefix-matched incompatible type")
Local nestedGenericOffset:Int = constrainedTypeCompletionDocument.text.Find("TConstrained<TM", directGenericOffset) + "TConstrained<TM".length
Local nestedGenericPosition:TSourcePosition = constrainedTypeCompletionAnalysis.syntaxTree.source.Position(nestedGenericOffset)
Local nestedGenericItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(constrainedTypeCompletionDocument, firstContext, nestedGenericPosition.line, nestedGenericPosition.column))
Check(FindCompletionItem(nestedGenericItems, "TMarked").GetString("sortText").Compare(FindCompletionItem(nestedGenericItems, "TMissing").GetString("sortText"), True) < 0, "nested incomplete generic argument completion applies the innermost owner's constraint")
Local dependentGenericOffset:Int = constrainedTypeCompletionDocument.text.Find("TDependent<IMarker, TM") + "TDependent<IMarker, TM".length
Local dependentGenericPosition:TSourcePosition = constrainedTypeCompletionAnalysis.syntaxTree.source.Position(dependentGenericOffset)
Local dependentGenericItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(constrainedTypeCompletionDocument, firstContext, dependentGenericPosition.line, dependentGenericPosition.column))
Check(FindCompletionItem(dependentGenericItems, "TMarked").GetString("sortText").Compare(FindCompletionItem(dependentGenericItems, "TMissing").GetString("sortText"), True) < 0, "generic argument completion substitutes an earlier argument into a dependent bound")
Local routineGenericOffset:Int = constrainedTypeCompletionDocument.text.Find("Keep<TM") + "Keep<TM".length
Local routineGenericPosition:TSourcePosition = constrainedTypeCompletionAnalysis.syntaxTree.source.Position(routineGenericOffset)
Local routineGenericItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(constrainedTypeCompletionDocument, firstContext, routineGenericPosition.line, routineGenericPosition.column))
Check(FindCompletionItem(routineGenericItems, "TMarked").GetString("sortText").Compare(FindCompletionItem(routineGenericItems, "TMissing").GetString("sortText"), True) < 0, "explicit generic routine arguments use routine constraints for ranking")
Local memberGenericOffset:Int = constrainedTypeCompletionDocument.text.Find("owner.Convert<TM") + "owner.Convert<TM".length
Local memberGenericPosition:TSourcePosition = constrainedTypeCompletionAnalysis.syntaxTree.source.Position(memberGenericOffset)
Local memberGenericItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(constrainedTypeCompletionDocument, firstContext, memberGenericPosition.line, memberGenericPosition.column))
Check(FindCompletionItem(memberGenericItems, "TMarked").GetString("sortText").Compare(FindCompletionItem(memberGenericItems, "TMissing").GetString("sortText"), True) < 0, "incomplete member routine specializations use the selected Method's constraints")
Local comparisonGenericOffset:Int = constrainedTypeCompletionDocument.text.length
Local comparisonGenericPosition:TSourcePosition = constrainedTypeCompletionAnalysis.syntaxTree.source.Position(comparisonGenericOffset)
Local comparisonGenericItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(constrainedTypeCompletionDocument, firstContext, comparisonGenericPosition.line, comparisonGenericPosition.column))
Check(FindCompletionItem(comparisonGenericItems, "TMarked") = Null, "a less-than comparison is not mistaken for a generic type-argument completion context")
Local forwardTypeDocument:TLspDocument = New TLspDocument
forwardTypeDocument.uri = "file:///first/forward-type-completion.bmx"
forwardTypeDocument.path = "/first/forward-type-completion.bmx"
forwardTypeDocument.text = "SuperStrict~nLocal tt:TOver~nType TOverload~nMethod Calc:Int(value:Int)~nReturn value~nEnd Method~nEnd Type"
firstContext.Analyze(forwardTypeDocument)
Local forwardTypeItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(forwardTypeDocument, firstContext, 1, 16))
Check(FindCompletionItem(forwardTypeItems, "TOverload") <> Null, "type-position completion includes source Types declared after the cursor")
Check(FindCompletionItem(forwardTypeItems, "TOverload").GetString("sortText").StartsWith("00"), "exact-prefix source Types receive the highest completion rank")
Local forwardTypeEdit:TJSONObject = TJSONObject(FindCompletionItem(forwardTypeItems, "TOverload").Get("textEdit"))
Local forwardTypeEditRange:TJSONObject = TJSONObject(forwardTypeEdit.Get("range"))
Check(forwardTypeEdit.GetString("newText") = "TOverload" And TJSONObject(forwardTypeEditRange.Get("start")).GetInteger("character") = 9 And TJSONObject(forwardTypeEditRange.Get("end")).GetInteger("character") = 14, "type completion explicitly replaces only the partial type name")
Local hierarchyDocument:TLspDocument = New TLspDocument
hierarchyDocument.uri = "file:///first/type-hierarchy.bmx"
hierarchyDocument.path = "/first/type-hierarchy.bmx"
hierarchyDocument.text = "SuperStrict~nInterface IBase~nEnd Interface~nInterface IChild Extends IBase~nEnd Interface~nType TBase Implements IChild~nEnd Type~nType TChild Extends TBase~nEnd Type~nStruct SValue~nEnd Struct"
firstContext.Analyze(hierarchyDocument)
Local preparedBaseItems:TJSONArray = TJSONArray(TBlitzMaxLspTypeHierarchy.Prepare(hierarchyDocument, firstContext, store, 5, 7))
Local preparedBase:TJSONObject = FindHierarchyItem(preparedBaseItems, "TBase")
Check(preparedBase <> Null And preparedBase.GetInteger("kind") = 5, "type hierarchy prepares BlitzMax Type declarations")
Local baseSupertypes:TJSONArray = TJSONArray(TBlitzMaxLspTypeHierarchy.Supertypes(preparedBase, firstContext, store))
Check(baseSupertypes.Size() = 1 And FindHierarchyItem(baseSupertypes, "IChild") <> Null, "type hierarchy exposes directly implemented interfaces")
Local baseSubtypes:TJSONArray = TJSONArray(TBlitzMaxLspTypeHierarchy.Subtypes(preparedBase, firstContext, store))
Check(baseSubtypes.Size() = 1 And FindHierarchyItem(baseSubtypes, "TChild") <> Null, "type hierarchy exposes direct derived Types")
Local preparedInterfaceItems:TJSONArray = TJSONArray(TBlitzMaxLspTypeHierarchy.Prepare(hierarchyDocument, firstContext, store, 3, 12))
Local preparedInterface:TJSONObject = FindHierarchyItem(preparedInterfaceItems, "IChild")
Check(preparedInterface <> Null And preparedInterface.GetInteger("kind") = 11, "type hierarchy prepares BlitzMax Interface declarations")
Local interfaceSupertypes:TJSONArray = TJSONArray(TBlitzMaxLspTypeHierarchy.Supertypes(preparedInterface, firstContext, store))
Check(interfaceSupertypes.Size() = 1 And FindHierarchyItem(interfaceSupertypes, "IBase") <> Null, "interface hierarchy exposes extended interfaces")
Local interfaceSubtypes:TJSONArray = TJSONArray(TBlitzMaxLspTypeHierarchy.Subtypes(preparedInterface, firstContext, store))
Check(interfaceSubtypes.Size() = 1 And FindHierarchyItem(interfaceSubtypes, "TBase") <> Null, "interface hierarchy exposes direct implementing Types")
Check(TJSONNull(TBlitzMaxLspTypeHierarchy.Prepare(hierarchyDocument, firstContext, store, 9, 8)) <> Null, "Struct declarations are intentionally excluded from type hierarchy")

' A base document does not import its children. Combine open workspace analyses
' so its subtype list can still discover a derived type from an importing file.
Local hierarchyStore:TLspDocumentStore = New TLspDocumentStore
Local crossHierarchyContext:TLspWorkspaceContext = TLspWorkspaceContext.Create("file:///hierarchy", "hierarchy", snapshotConfiguration.Copy(), sharedDependencies, hierarchyStore)
Local openBaseDocument:TLspDocument = hierarchyStore.Open("file:///hierarchy/base.bmx", "blitzmax", 1, "SuperStrict~nType TOpenBase~nEnd Type")
Local openChildDocument:TLspDocument = hierarchyStore.Open("file:///hierarchy/child.bmx", "blitzmax", 1, "SuperStrict~nImport ~qbase.bmx~q~nType TOpenChild Extends TOpenBase~nEnd Type")
crossHierarchyContext.Analyze(openBaseDocument)
crossHierarchyContext.Analyze(openChildDocument)
Local openBaseItems:TJSONArray = TJSONArray(TBlitzMaxLspTypeHierarchy.Prepare(openBaseDocument, crossHierarchyContext, hierarchyStore, 1, 7))
Local openBaseItem:TJSONObject = FindHierarchyItem(openBaseItems, "TOpenBase")
Local openBaseSubtypes:TJSONArray = TJSONArray(TBlitzMaxLspTypeHierarchy.Subtypes(openBaseItem, crossHierarchyContext, hierarchyStore))
Local openChildItem:TJSONObject = FindHierarchyItem(openBaseSubtypes, "TOpenChild")
Check(openChildItem <> Null And openChildItem.GetString("uri") = "file:///hierarchy/child.bmx", "subtype discovery combines open workspace analyses without reverse imports")
Local openChildSupertypes:TJSONArray = TJSONArray(TBlitzMaxLspTypeHierarchy.Supertypes(openChildItem, crossHierarchyContext, hierarchyStore))
Check(FindHierarchyItem(openChildSupertypes, "TOpenBase") <> Null And FindHierarchyItem(openChildSupertypes, "TOpenBase").GetString("uri") = "file:///hierarchy/base.bmx", "cross-file hierarchy navigates through exact live source provenance")
Local typeDefinitionDocument:TLspDocument = New TLspDocument
typeDefinitionDocument.uri = "file:///first/type-definition.bmx"
typeDefinitionDocument.path = "/first/type-definition.bmx"
typeDefinitionDocument.text = "SuperStrict~nType TWidget~nEnd Type~nStruct SWidget~nEnd Struct~nInterface IWidget~nEnd Interface~nLocal explicit:TWidget = New TWidget~nLocal inferred := New TWidget~nLocal widgets:TWidget[]~nLocal pointer:TWidget Ptr~nLocal use:TWidget = explicit~nLocal made:Object = inferred"
firstContext.Analyze(typeDefinitionDocument)
Local explicitTypeDefinition:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.TypeDefinition(typeDefinitionDocument, firstContext, store, 7, 8))
Local explicitTypeRange:TJSONObject = TJSONObject(explicitTypeDefinition.Get("range"))
Local explicitTypeStart:TJSONObject = TJSONObject(explicitTypeRange.Get("start"))
Check(explicitTypeDefinition.GetString("uri") = typeDefinitionDocument.uri And explicitTypeStart.GetInteger("line") = 1 And explicitTypeStart.GetInteger("character") = 5, "go to type definition resolves explicitly typed locals")
Local inferredTypeDefinition:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.TypeDefinition(typeDefinitionDocument, firstContext, store, 8, 8))
Check(inferredTypeDefinition <> Null And TJSONObject(TJSONObject(inferredTypeDefinition.Get("range")).Get("start")).GetInteger("line") = 1, "go to type definition resolves inferred local initializers")
Local inferredLocalHover:TJSONObject = TJSONObject(TBlitzMaxLspHover.Query(typeDefinitionDocument, firstContext, 12, 22))
Check(TJSONObject(inferredLocalHover.Get("contents")).GetString("value").Contains("Local inferred:TWidget"), "hover consumes the fixed semantic type of a ':=' Local")
Local referencedTypeDefinition:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.TypeDefinition(typeDefinitionDocument, firstContext, store, 11, 22))
Check(referencedTypeDefinition <> Null And TJSONObject(TJSONObject(referencedTypeDefinition.Get("range")).Get("start")).GetInteger("line") = 1, "go to type definition resolves bound local references")
Local arrayTypeDefinition:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.TypeDefinition(typeDefinitionDocument, firstContext, store, 9, 8))
Local pointerTypeDefinition:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.TypeDefinition(typeDefinitionDocument, firstContext, store, 10, 8))
Check(arrayTypeDefinition <> Null And pointerTypeDefinition <> Null, "go to type definition unwraps arrays and pointers to their declared element type")
Local structTypeDefinition:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.TypeDefinition(typeDefinitionDocument, firstContext, store, 3, 8))
Local interfaceTypeDefinition:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.TypeDefinition(typeDefinitionDocument, firstContext, store, 5, 11))
Check(structTypeDefinition <> Null And interfaceTypeDefinition <> Null, "go to type definition supports Struct and Interface declarations")
Local deconstructDocument:TLspDocument = New TLspDocument
deconstructDocument.uri = "file:///first/mod/brl.mod/blitz.mod/blitz.bmx"
deconstructDocument.path = "/first/mod/brl.mod/blitz.mod/blitz.bmx"
deconstructDocument.text = "SuperStrict~nInterface IDeconstruct2<A, B>~nMethod Deconstruct(first:A Var, second:B Var)~nEnd Interface~nType TPair Implements IDeconstruct2<String, Int>~nMethod Deconstruct(first:String Var, second:Int Var)~nEnd Method~nEnd Type~nLocal pairs:TPair[]~nFor Local key, value = EachIn pairs~nLocal text:String = key + value~nNext"
firstContext.Analyze(deconstructDocument)
Local deconstructHover:TJSONObject = TJSONObject(TBlitzMaxLspHover.Query(deconstructDocument, firstContext, 10, 28))
Check(deconstructHover <> Null And TJSONObject(deconstructHover.Get("contents")).GetString("value").Contains("Local value:Int"), "hover reports the inferred type of the second EachIn deconstruction binding")
Local deconstructDefinition:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.Definition(deconstructDocument, firstContext, store, 10, 28))
Local deconstructDefinitionStart:TJSONObject = TJSONObject(TJSONObject(deconstructDefinition.Get("range")).Get("start"))
Check(deconstructDefinition.GetString("uri") = deconstructDocument.uri And deconstructDefinitionStart.GetInteger("line") = 9 And deconstructDefinitionStart.GetInteger("character") = 15, "definition navigation reaches the second EachIn binding declaration")
Local deconstructHints:TJSONArray = TJSONArray(TBlitzMaxLspInlayHints.Query(deconstructDocument, firstContext, Null))
Check(FindInlayHint(deconstructHints, 9, 13, ": String", 1) <> Null And FindInlayHint(deconstructHints, 9, 20, ": Int", 1) <> Null, "inlay hints show both inferred IDeconstruct2 component types")
Local implementationDocument:TLspDocument = New TLspDocument
implementationDocument.uri = "file:///first/implementation.bmx"
implementationDocument.path = "/first/implementation.bmx"
implementationDocument.text = "SuperStrict~nInterface IWorker~nMethod Work:Int(value:Int)~nEnd Interface~nType TBase Implements IWorker~nMethod Work:Int(amount:Int)~nReturn amount~nEnd Method~nEnd Type~nType TChild Extends TBase~nMethod Work:Int(value:Int) Override~nReturn value~nEnd Method~nEnd Type~nLocal worker:IWorker = New TBase~nworker.Work(1)"
firstContext.Analyze(implementationDocument)
Local interfaceImplementations:TJSONArray = TJSONArray(TBlitzMaxLspImplementation.Query(implementationDocument, firstContext, store, 1, 12))
Check(HasLocation(interfaceImplementations, implementationDocument.uri, 4, 5) And HasLocation(interfaceImplementations, implementationDocument.uri, 9, 5), "go to implementation finds direct and inherited Interface implementations")
Local interfaceMethodImplementations:TJSONArray = TJSONArray(TBlitzMaxLspImplementation.Query(implementationDocument, firstContext, store, 2, 9))
Check(HasLocation(interfaceMethodImplementations, implementationDocument.uri, 5, 7) And HasLocation(interfaceMethodImplementations, implementationDocument.uri, 10, 7), "go to implementation finds interface method implementations despite parameter-name differences")
Local derivedTypeImplementations:TJSONArray = TJSONArray(TBlitzMaxLspImplementation.Query(implementationDocument, firstContext, store, 4, 7))
Check(derivedTypeImplementations.Size() = 1 And HasLocation(derivedTypeImplementations, implementationDocument.uri, 9, 5), "go to implementation on a Type finds derived Types")
Local overridingMethodImplementations:TJSONArray = TJSONArray(TBlitzMaxLspImplementation.Query(implementationDocument, firstContext, store, 5, 9))
Check(overridingMethodImplementations.Size() = 1 And HasLocation(overridingMethodImplementations, implementationDocument.uri, 10, 7), "go to implementation on a Method finds overriding Methods")
Local callImplementations:TJSONArray = TJSONArray(TBlitzMaxLspImplementation.Query(implementationDocument, firstContext, store, 15, 8))
Check(HasLocation(callImplementations, implementationDocument.uri, 5, 7) And HasLocation(callImplementations, implementationDocument.uri, 10, 7), "go to implementation works from a bound interface call")
Local foldingDocument:TLspDocument = New TLspDocument
foldingDocument.uri = "file:///first/folding.bmx"
foldingDocument.path = "/first/folding.bmx"
foldingDocument.text = "SuperStrict~nImport BRL.Map~nImport BRL.LinkedList~nRem~nbbdoc: Folding probe.~nEnd Rem~nType TFold~nMethod Run()~nIf True Then~nPrint ~qfold~q~nEnd If~nEnd Method~nEnd Type"
firstContext.Analyze(foldingDocument)
Local foldingRanges:TJSONArray = TJSONArray(TBlitzMaxLspFoldingRanges.Query(foldingDocument, firstContext))
Check(HasFoldingRange(foldingRanges, 1, 2, "imports"), "folding groups consecutive imports")
Check(HasFoldingRange(foldingRanges, 3, 5, "comment"), "folding includes multiline Rem comments")
Check(HasFoldingRange(foldingRanges, 6, 12), "folding uses the parsed Type extent")
Check(HasFoldingRange(foldingRanges, 7, 11), "folding includes nested Method declarations")
Check(HasFoldingRange(foldingRanges, 8, 10), "folding uses control-flow syntax independently of indentation")

Local functionLiteralDocument:TLspDocument = New TLspDocument
functionLiteralDocument.uri = "file:///first/function-literal.bmx"
functionLiteralDocument.path = "/first/function-literal.bmx"
functionLiteralDocument.text = "SuperStrict~nLocal add:Int(value:Int) = Function(value)~nReturn value + 1~nEnd Function"
Local functionLiteralAnalysis:TLanguageAnalysis = firstContext.Analyze(functionLiteralDocument)
Check(functionLiteralAnalysis.model.diagnostics.length = 0, "LSP analysis retains context and scope for a non-capturing Function literal")
Local functionLiteralFoldingRanges:TJSONArray = TJSONArray(TBlitzMaxLspFoldingRanges.Query(functionLiteralDocument, firstContext))
Check(HasFoldingRange(functionLiteralFoldingRanges, 1, 3), "folding includes a block Function literal")
Local functionLiteralRename:TJSONObject = TJSONObject(TBlitzMaxLspRename.Rename(functionLiteralDocument, firstContext, 2, 8, "item"))
Check(WorkspaceEditEdits(functionLiteralRename, functionLiteralDocument.uri).Size() = 2, "rename follows a contextual Function literal parameter through its body")

Local loopClosureDocument:TLspDocument = New TLspDocument
loopClosureDocument.uri = "file:///first/loop-closure.bmx"
loopClosureDocument.path = "/first/loop-closure.bmx"
loopClosureDocument.text = "SuperStrict~nFunction Build()~nFor Local index:Int = 0 Until 2~nLocal action:Closure<Int()> = Function()~nReturn index~nEnd Function~nNext~nEnd Function"
Local loopClosureAnalysis:TLanguageAnalysis = firstContext.Analyze(loopClosureDocument)
Check(loopClosureAnalysis.model.diagnostics.length = 0, "LSP analysis accepts managed capture of a fresh loop iteration binding")
Local loopClosureRename:TJSONObject = TJSONObject(TBlitzMaxLspRename.Rename(loopClosureDocument, firstContext, 4, 8, "iteration"))
Check(WorkspaceEditEdits(loopClosureRename, loopClosureDocument.uri).Size() = 2, "rename follows a loop-scoped declaration into its managed Closure body")
Local loopClosureReferences:TJSONArray = TJSONArray(TBlitzMaxLspReferences.Query(loopClosureDocument, firstContext, 4, 8, True))
Check(loopClosureReferences.Size() = 2, "references follow a loop-scoped declaration into its managed Closure body")

Local catchClosureDocument:TLspDocument = New TLspDocument
catchClosureDocument.uri = "file:///first/catch-closure.bmx"
catchClosureDocument.path = "/first/catch-closure.bmx"
catchClosureDocument.text = "SuperStrict~nFunction Build:Closure<String()>()~nTry~nThrow ~qvalue~q~nCatch problem:String~nReturn Function()~nReturn problem~nEnd Function~nEnd Try~nEnd Function"
Local catchClosureAnalysis:TLanguageAnalysis = firstContext.Analyze(catchClosureDocument)
Check(catchClosureAnalysis.model.diagnostics.length = 0, "LSP analysis accepts a managed Catch activation capture")
Local catchClosureRename:TJSONObject = TJSONObject(TBlitzMaxLspRename.Rename(catchClosureDocument, firstContext, 6, 8, "caughtValue"))
Check(WorkspaceEditEdits(catchClosureRename, catchClosureDocument.uri).Size() = 2, "rename follows a Catch parameter into its escaping managed Closure body")
Local catchClosureReferences:TJSONArray = TJSONArray(TBlitzMaxLspReferences.Query(catchClosureDocument, firstContext, 6, 8, True))
Check(catchClosureReferences.Size() = 2, "references follow a Catch parameter into its escaping managed Closure body")

Local topLevelClosureDocument:TLspDocument = New TLspDocument
topLevelClosureDocument.uri = "file:///first/top-level-closure.bmx"
topLevelClosureDocument.path = "/first/top-level-closure.bmx"
topLevelClosureDocument.text = "SuperStrict~nLocal value:Int = 1~nLocal action:Closure<Int()> = Function()~nReturn value~nEnd Function"
Local topLevelClosureAnalysis:TLanguageAnalysis = firstContext.Analyze(topLevelClosureDocument)
Check(topLevelClosureAnalysis.model.diagnostics.length = 0, "LSP analysis accepts a managed top-level Local capture")
Local topLevelClosureRename:TJSONObject = TJSONObject(TBlitzMaxLspRename.Rename(topLevelClosureDocument, firstContext, 3, 8, "moduleValue"))
Check(WorkspaceEditEdits(topLevelClosureRename, topLevelClosureDocument.uri).Size() = 2, "rename follows a top-level Local into its managed Closure body")
Local topLevelClosureReferences:TJSONArray = TJSONArray(TBlitzMaxLspReferences.Query(topLevelClosureDocument, firstContext, 3, 8, True))
Check(topLevelClosureReferences.Size() = 2, "references follow a top-level Local into its managed Closure body")

Local closureCallDocument:TLspDocument = New TLspDocument
closureCallDocument.uri = "file:///first/closure-call.bmx"
closureCallDocument.path = "/first/closure-call.bmx"
closureCallDocument.text = "SuperStrict~nLocal add:Closure<Int(value:Int)> = Function(value)~nReturn value + 1~nEnd Function~nLocal result:Int = add(41)"
Local closureCallAnalysis:TLanguageAnalysis = firstContext.Analyze(closureCallDocument)
Check(closureCallAnalysis.model.diagnostics.length = 0, "LSP analysis accepts an indirect managed Closure call")
Local closureCallHover:TJSONObject = TJSONObject(TBlitzMaxLspHover.Query(closureCallDocument, firstContext, 4, 20))
Check(closureCallHover <> Null And TJSONObject(closureCallHover.Get("contents")).GetString("value").Contains("Closure<Int(value:Int)>") , "hover displays the structural managed Closure signature")
Local closureCallSignature:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.SignatureHelp(closureCallDocument, firstContext, 4, 24))
Check(closureCallSignature <> Null, "signature help is available for an indirect managed Closure call")
Local closureCallSignatures:TJSONArray = TJSONArray(closureCallSignature.Get("signatures"))
Local closureCallSignatureInfo:TJSONObject = TJSONObject(closureCallSignatures.Get(0))
Check(closureCallSignatureInfo.GetString("label") = "Closure<Int(value:Int)>", "signature help displays the structural managed Closure signature")
Local closureCallParameters:TJSONArray = TJSONArray(closureCallSignatureInfo.Get("parameters"))
Check(TJSONObject(closureCallParameters.Get(0)).GetString("label") = "value:Int", "signature help preserves managed Closure parameter names")
Local chainedIfDocument:TLspDocument = New TLspDocument
chainedIfDocument.uri = "file:///first/chained-if.bmx"
chainedIfDocument.path = "/first/chained-if.bmx"
chainedIfDocument.text = "SuperStrict~nLocal a:Int = 1~nLocal b:Int = 1~nIf a Then If b~nLocal both:Int = 1~nEnd If"
Local chainedIfAnalysis:TLanguageAnalysis = firstContext.Analyze(chainedIfDocument)
Check(chainedIfAnalysis.syntaxTree.diagnostics.length = 0 And chainedIfAnalysis.model.diagnostics.length = 0, "LSP analysis accepts a chained multiline If with one deepest terminator")
Local chainedIfFoldingRanges:TJSONArray = TJSONArray(TBlitzMaxLspFoldingRanges.Query(chainedIfDocument, firstContext))
Check(HasFoldingRange(chainedIfFoldingRanges, 3, 5), "LSP folding follows the complete chained multiline If extent")

Local conditionalFoldingDocument:TLspDocument = New TLspDocument
conditionalFoldingDocument.uri = "file:///first/conditional-folding.bmx"
conditionalFoldingDocument.path = "/first/conditional-folding.bmx"
conditionalFoldingDocument.text = "?Not bmxng~n'using custom reflection~nImport ~qexternal/reflection.bmx~q~n'Import BRL.Reflection~n?bmxng~n'ng has it built-in!"
firstContext.Analyze(conditionalFoldingDocument)
Local conditionalFoldingRanges:TJSONArray = TJSONArray(TBlitzMaxLspFoldingRanges.Query(conditionalFoldingDocument, firstContext))
Check(HasFoldingRange(conditionalFoldingRanges, 0, 3, "region"), "folding gives the first compiler-conditional branch its own range")
Check(HasFoldingRange(conditionalFoldingRanges, 4, 5, "region"), "folding gives the following compiler-conditional branch its own range")
Check(Not HasFoldingRange(conditionalFoldingRanges, 0, 5, "region"), "folding does not collapse an entire compiler-conditional region into its first branch")
Local pathCompletionDocument:TLspDocument = New TLspDocument
pathCompletionDocument.uri = "file:///first/path-completion.bmx"
pathCompletionDocument.path = "/first/path-completion.bmx"
pathCompletionDocument.text = "SuperStrict~nFramework brl.standardio~nImport brl.path~nLocal path:TPath = TPath.FromString(~qfile.txt~q)~nPrint path."
firstContext.Analyze(pathCompletionDocument)
Local pathMemberItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(pathCompletionDocument, firstContext, 4, 11))
Check(FindCompletionItem(pathMemberItems, "Name") <> Null And FindCompletionItem(pathMemberItems, "Parent") <> Null, "BRL.Path member completion works inside a parenthesis-free Print call")
Local pathTypeCompletionDocument:TLspDocument = New TLspDocument
pathTypeCompletionDocument.uri = "file:///first/path-type-completion.bmx"
pathTypeCompletionDocument.path = "/first/path-type-completion.bmx"
pathTypeCompletionDocument.text = "SuperStrict~nFramework brl.standardio~nImport brl.path~nLocal path:TPath = TPath."
Local pathTypeCompletionAnalysis:TLanguageAnalysis = firstContext.Analyze(pathTypeCompletionDocument)
Local pathTypeCompletionOffset:Int = pathTypeCompletionDocument.text.length
Local pathTypeCompletionResult:TMemberCompletionResult = TMemberCompletion.Query(pathTypeCompletionAnalysis.model, TSyntaxNavigator.Create(pathTypeCompletionAnalysis.syntaxTree), pathTypeCompletionOffset)
Check(pathTypeCompletionResult <> Null And pathTypeCompletionResult.owner.name = "TPath" And pathTypeCompletionResult.isStatic, "import-aware member completion recognizes an imported Type receiver")
Local pathTypeMemberItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(pathTypeCompletionDocument, firstContext, 3, 25))
Local pathFromStringItem:TJSONObject = FindCompletionItem(pathTypeMemberItems, "FromString")
Check(pathFromStringItem <> Null And pathFromStringItem.GetInteger("kind") = 3 And pathFromStringItem.GetString("detail").Contains("Function FromString:TPath(path:String)"), "imported Type completion includes its type Functions")
Check(FindCompletionItem(pathTypeMemberItems, "Name") = Null And FindCompletionItem(pathTypeMemberItems, "New") = Null, "imported Type completion excludes instance Methods and constructors")
Local selectionDocument:TLspDocument = New TLspDocument
selectionDocument.uri = "file:///first/selection.bmx"
selectionDocument.path = "/first/selection.bmx"
selectionDocument.text = "SuperStrict~nType TSelection~nMethod Sum:Int(left:Int, right:Int)~nReturn left + right~nEnd Method~nEnd Type"
firstContext.Analyze(selectionDocument)
Local selectionPositions:TJSONArray = JsonArray()
Local selectionPosition:TJSONObject = JsonObject()
selectionPosition.Set("line", 3)
selectionPosition.Set("character", 16)
selectionPositions.Append(selectionPosition)
Local selectionRanges:TJSONArray = TJSONArray(TBlitzMaxLspSelectionRanges.Query(selectionDocument, firstContext, selectionPositions))
Local smartSelection:TJSONObject = TJSONObject(selectionRanges.Get(0))
Check(SelectionChainContains(smartSelection, 3, 14, 3, 19), "smart selection begins with the token at the cursor")
Check(SelectionChainContains(smartSelection, 3, 0, 3, 19), "smart selection expands through the containing statement")
Check(SelectionChainContains(smartSelection, 2, 0, 4, 10), "smart selection expands through the containing Method")
Check(SelectionChainContains(smartSelection, 1, 0, 5, 8), "smart selection expands through the containing Type")
Check(SelectionChainContains(smartSelection, 0, 0, 5, 8), "smart selection finishes at the complete document")
Local renameDocument:TLspDocument = New TLspDocument
renameDocument.uri = "file:///first/rename.bmx"
renameDocument.path = "/first/rename.bmx"
renameDocument.text = "SuperStrict~nFunction Total:Int(amount:Int)~nLocal result := amount + 1~nIf result > 2 Then~nLocal nested:Int = result~nReturn nested + amount~nEnd If~nReturn result~nEnd Function"
firstContext.Analyze(renameDocument)
Local preparedRename:TJSONObject = TJSONObject(TBlitzMaxLspRename.Prepare(renameDocument, firstContext, 3, 5))
Check(preparedRename <> Null And preparedRename.GetString("placeholder") = "result", "prepare rename identifies a bound local reference")
Local preparedRenameRange:TJSONObject = TJSONObject(preparedRename.Get("range"))
Check(TJSONObject(preparedRenameRange.Get("start")).GetInteger("line") = 3 And TJSONObject(preparedRenameRange.Get("start")).GetInteger("character") = 3, "prepare rename selects the reference under the cursor")
Local localRenameEdit:TJSONObject = TJSONObject(TBlitzMaxLspRename.Rename(renameDocument, firstContext, 3, 5, "totalValue"))
Local localRenameEdits:TJSONArray = WorkspaceEditEdits(localRenameEdit, renameDocument.uri)
Check(localRenameEdits.Size() = 4 And AllEditsUseName(localRenameEdits, "totalValue"), "local rename edits its declaration and every semantically bound reference")
Local parameterRenameEdit:TJSONObject = TJSONObject(TBlitzMaxLspRename.Rename(renameDocument, firstContext, 1, 20, "inputAmount"))
Check(WorkspaceEditEdits(parameterRenameEdit, renameDocument.uri).Size() = 3, "document-local rename supports routine parameters")
Check(TJSONObject(TBlitzMaxLspRename.Rename(renameDocument, firstContext, 3, 5, "If")) = Null, "rename rejects BlitzMax keywords")
Check(TJSONObject(TBlitzMaxLspRename.Rename(renameDocument, firstContext, 3, 5, "amount")) = Null, "rename rejects names that collide in an affected lexical scope")
Check(TJSONObject(TBlitzMaxLspRename.Prepare(renameDocument, firstContext, 1, 11)) = Null, "prepare rename refuses routines that could have cross-file references")
Local documentationDocument:TLspDocument = New TLspDocument
documentationDocument.uri = "file:///first/documentation.bmx"
documentationDocument.path = "/first/documentation.bmx"
documentationDocument.text = "SuperStrict~nRem~nbbdoc: Adds #TDocValue values.~nreturns: The combined value.~nparam: The @left value.~nparam: The @right value.~nabout: Additional **Markdown** detail.~nEnd Rem~nFunction Add:Int(left:Int, right:Int)~nReturn left + right~nEnd Function~nType TDocValue~nEnd Type~nLocal sum:Int = Add(1, 2)"
Local documentationAnalysis:TLanguageAnalysis = firstContext.Analyze(documentationDocument)
Local addSymbol:TSymbol = documentationAnalysis.model.globalScope.LookupLocal("Add")[0]
Check(addSymbol.documentation <> Null And addSymbol.documentation.parameters.length = 2, "source bbdoc is associated with semantic routine symbols")
Local documentationHover:TJSONObject = TJSONObject(TBlitzMaxLspHover.Query(documentationDocument, firstContext, 13, 18))
Check(documentationHover <> Null And TJSONObject(documentationHover.Get("contents")) <> Null, "documented source hover is available")
Local documentationHoverValue:String = TJSONObject(documentationHover.Get("contents")).GetString("value")
Check(documentationHoverValue.Contains("Adds [TDocValue](file:///first/documentation.bmx#L12) values."), "bbdoc references become source links in hover Markdown")
Check(documentationHoverValue.Contains("Defined in [`documentation.bmx:9`](file:///first/documentation.bmx#L9)"), "local routine hover links directly to its declaration line")
Check(documentationHoverValue.Contains("**left** - The **left** value.") And documentationHoverValue.Contains("**Returns:** The combined value."), "hover links ordered param entries to routine parameters and renders custom emphasis")
Check(documentationHoverValue.Contains("Additional **Markdown** detail."), "bbdoc about sections preserve Markdown")
Local documentationSignature:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.SignatureHelp(documentationDocument, firstContext, 13, 23))
Check(documentationSignature <> Null And TJSONArray(documentationSignature.Get("signatures")) <> Null, "documented source signature help is available")
Local documentationSignatures:TJSONArray = TJSONArray(documentationSignature.Get("signatures"))
Local documentedSignature:TJSONObject = TJSONObject(documentationSignatures.Get(0))
Check(documentedSignature <> Null And TJSONObject(documentedSignature.Get("documentation")) <> Null, "documented signature contains Markdown")
Check(TJSONObject(documentedSignature.Get("documentation")).GetString("value").Contains("Adds"), "signature help includes routine bbdoc")
Local documentedParameters:TJSONArray = TJSONArray(documentedSignature.Get("parameters"))
Check(TJSONObject(TJSONObject(documentedParameters.Get(0)).Get("documentation")).GetString("value").Contains("**left**"), "signature help includes parameter bbdoc by ordinal position")
Local documentedCompletionItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(documentationDocument, firstContext, 13, 18))
Local unresolvedAddCompletion:TJSONObject = FindCompletionItem(documentedCompletionItems, "Add")
Check(unresolvedAddCompletion <> Null And unresolvedAddCompletion.Get("data") <> Null And unresolvedAddCompletion.Get("documentation") = Null, "initial completion items carry compact identity without eager documentation")
Local resolvedAddCompletion:TJSONObject = TBlitzMaxLspCompletion.Resolve(unresolvedAddCompletion, documentationDocument, firstContext)
Check(TJSONObject(resolvedAddCompletion.Get("documentation")).GetString("value").Contains("Adds [TDocValue]"), "completion item resolve adds source bbdoc Markdown lazily")
Local provenanceSdk:String = "/tmp/blitzmax-lsp-provenance-sdk"
Local provenanceConfig:TLspWorkspaceConfiguration = snapshotConfiguration.Copy()
provenanceConfig.sdkPath = provenanceSdk
Local provenanceCoreDirectory:String = provenanceSdk + "/mod/brl.mod/blitz.mod"
Local provenanceModuleDirectory:String = provenanceSdk + "/mod/brl.mod/stream.mod"
CreateDir(provenanceCoreDirectory, True)
CreateDir(provenanceModuleDirectory, True)
SaveText("Object^Null{~n-HashCode:UInt()=~qbbObjectHashCode~q~n}=~qbbObjectClass~q", provenanceCoreDirectory + "/blitz_classes.i")
SaveText("SuperStrict~nRem~nbbdoc: Compiler interface wrapper.~nEnd Rem~nType TStreamWrapper Implements IReadable~nRem~nbbdoc: Reads bytes from the wrapper.~nreturns: The number of bytes read.~nparam: The requested @count.~nabout: Read details from source provenance.~nEnd Rem~nMethod Read:Int(count:Int)~nReturn count~nEnd Method~nEnd Type~nInterface IReadable~nEnd Interface~nType TDerivedWrapper Extends TStreamWrapper~nEnd Type~nType TImportedBox<T>~nMethod Value:T()~nEnd Method~nMethod ValueOr:T(fallback:T)~nEnd Method~nEnd Type~nType TImportedConstrained<T> Where T Extends IReadable~nEnd Type", provenanceModuleDirectory + "/stream.bmx")
SaveText("IReadable^Null{ '@source ~qstream.bmx~q,16,0~n}AI=~qbrl_stream_IReadable~q~nTStreamWrapper^Object@IReadable{ '@source ~qstream.bmx~q,5,0~n-Read:Int(count:Int) '@source ~qstream.bmx~q,12,0~n}F=~qbrl_stream_TStreamWrapper~q~nTDerivedWrapper^TStreamWrapper{ '@source ~qstream.bmx~q,18,0~n}F=~qbrl_stream_TDerivedWrapper~q~nTImportedBox<T>^Object{~n-Value:T()~n-ValueOr:T(fallback:T)~n}K~n'@generic-template 30,~qbrl.stream::timportedbox#type/1~q,~qfixture-revision~q,~qtimportedbox.bmxgt~q,~qbmx-language-1~q~nTImportedConstrained<T> Where T Extends IReadable^Object{~n}K~n'@generic-template 31,~qbrl.stream::timportedconstrained#type/1~q,~qfixture-revision~q,~qtimportedconstrained.bmxgt~q,~qbmx-language-1~q~nImportedProbe:Int(value:Int)=~qbrl_stream_ImportedProbe~q '@source ~qstream.bmx~q,4,0~nPrivateProbe:Int()P=~qbrl_stream_PrivateProbe~q~nImportedLimit%=42%~nImportedGlobal%&=mem:p(~qbrl_stream_ImportedGlobal~q)", ModuleInterfacePath(provenanceSdk, "BRL.Stream", provenanceConfig.InterfaceMung()))
Local provenanceContext:TLspWorkspaceContext = TLspWorkspaceContext.Create("file:///provenance", "provenance", provenanceConfig, New TLspDependencyCache)
Local provenanceDocument:TLspDocument = New TLspDocument
provenanceDocument.uri = "file:///provenance/interface-provenance.bmx"
provenanceDocument.path = "/provenance/interface-provenance.bmx"
provenanceDocument.text = "SuperStrict~nImport BRL.Stream~nLocal wrapper:TStreamWrapper~nwrapper.~nwrapper.Read(10)~nLocal importedValue:Int = Imp"
Local provenanceAnalysis:TLanguageAnalysis = provenanceContext.Analyze(provenanceDocument)
Local streamWrapperSymbol:TSymbol = provenanceAnalysis.model.ImportedScope("brl.stream").LookupLocal("TStreamWrapper")[0]
Check(streamWrapperSymbol.originPath = provenanceModuleDirectory + "/stream.bmx" And streamWrapperSymbol.originLine = 5, "compiler interface provenance resolves to canonical source path and line")
Local importedHierarchyItems:TJSONArray = TJSONArray(TBlitzMaxLspTypeHierarchy.Prepare(provenanceDocument, provenanceContext, store, 2, 16))
Local importedHierarchyItem:TJSONObject = FindHierarchyItem(importedHierarchyItems, "TStreamWrapper")
Check(importedHierarchyItem <> Null And importedHierarchyItem.GetString("uri").EndsWith("/stream.bmx"), "type hierarchy prepares imported Types at source provenance")
Local importedHierarchySupertypes:TJSONArray = TJSONArray(TBlitzMaxLspTypeHierarchy.Supertypes(importedHierarchyItem, provenanceContext, store))
Check(FindHierarchyItem(importedHierarchySupertypes, "IReadable") <> Null And Not FindHierarchyItem(importedHierarchySupertypes, "IReadable").GetString("uri").Contains(".i"), "imported hierarchy exposes interfaces without navigating to compiler interfaces")
Local importedHierarchySubtypes:TJSONArray = TJSONArray(TBlitzMaxLspTypeHierarchy.Subtypes(importedHierarchyItem, provenanceContext, store))
Check(FindHierarchyItem(importedHierarchySubtypes, "TDerivedWrapper") <> Null And Not FindHierarchyItem(importedHierarchySubtypes, "TDerivedWrapper").GetString("uri").Contains(".i"), "imported hierarchy discovers derived Types from compiler interface relationships")
Local provenanceTypeDefinition:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.TypeDefinition(provenanceDocument, provenanceContext, store, 2, 8))
Local provenanceTypeDefinitionStart:TJSONObject = TJSONObject(TJSONObject(provenanceTypeDefinition.Get("range")).Get("start"))
Check(provenanceTypeDefinition.GetString("uri").EndsWith("/mod/brl.mod/stream.mod/stream.bmx") And provenanceTypeDefinitionStart.GetInteger("line") = 4, "go to type definition follows compiler-interface provenance to source")
Local provenanceHover:TJSONObject = TJSONObject(TBlitzMaxLspHover.Query(provenanceDocument, provenanceContext, 2, 16))
Local provenanceHoverContents:TJSONObject = TJSONObject(provenanceHover.Get("contents"))
Check(provenanceHoverContents.GetString("value").Contains("/brl.mod/stream.mod/stream.bmx") And Not provenanceHoverContents.GetString("value").Contains(".arm64.i"), "hover presents original source rather than compiler interface")
Check(provenanceHoverContents.GetString("value").Contains("Defined in `BRL.Stream` · [`stream.bmx:5`](file:///tmp/blitzmax-lsp-provenance-sdk/mod/brl.mod/stream.mod/stream.bmx#L5)"), "imported hover labels its module and links to exact source provenance")
Check(provenanceHoverContents.GetString("value").Contains("Compiler interface wrapper."), "hover lazily recovers bbdoc from compiler-interface source provenance")
Local provenanceDefinition:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.Definition(provenanceDocument, provenanceContext, store, 2, 16))
Local provenanceDefinitionStart:TJSONObject = TJSONObject(TJSONObject(provenanceDefinition.Get("range")).Get("start"))
Check(provenanceDefinition.GetString("uri").EndsWith("/mod/brl.mod/stream.mod/stream.bmx") And provenanceDefinitionStart.GetInteger("line") = 4 And provenanceDefinitionStart.GetInteger("character") = 5, "definition follows interface provenance to the source declaration name")
Local provenanceCompletions:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(provenanceDocument, provenanceContext, 3, 8))
Local provenanceReadCompletion:TJSONObject = FindCompletionItem(provenanceCompletions, "Read")
Check(provenanceReadCompletion <> Null And provenanceReadCompletion.GetInteger("kind") = 2, "member completion is populated from the compiler interface catalogue")
Check(provenanceReadCompletion.Get("documentation") = Null, "imported completion does not load source documentation eagerly")
Local resolvedReadCompletion:TJSONObject = TBlitzMaxLspCompletion.Resolve(provenanceReadCompletion, provenanceDocument, provenanceContext)
Check(TJSONObject(resolvedReadCompletion.Get("documentation")).GetString("value").Contains("Reads bytes from the wrapper."), "completion item resolve lazily recovers imported bbdoc from source provenance")
Local provenanceContextualCompletions:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(provenanceDocument, provenanceContext, 5, 100))
Local importedProbeCompletion:TJSONObject = FindCompletionItem(provenanceContextualCompletions, "ImportedProbe")
Check(importedProbeCompletion <> Null And importedProbeCompletion.GetInteger("kind") = 3, "ordinary completion includes routines from an imported compiler interface")
Check(FindCompletionItem(provenanceContextualCompletions, "ImportedLimit") <> Null And FindCompletionItem(provenanceContextualCompletions, "ImportedLimit").GetInteger("kind") = 21, "ordinary completion includes constants from an imported compiler interface")
Check(FindCompletionItem(provenanceContextualCompletions, "ImportedGlobal") <> Null And FindCompletionItem(provenanceContextualCompletions, "ImportedGlobal").GetInteger("kind") = 6, "ordinary completion includes globals from an imported compiler interface")
Check(FindCompletionItem(provenanceContextualCompletions, "PrivateProbe") = Null, "ordinary completion excludes private imported symbols")
Local provenanceTypeDocument:TLspDocument = New TLspDocument
provenanceTypeDocument.uri = "file:///provenance/interface-type-completion.bmx"
provenanceTypeDocument.path = "/provenance/interface-type-completion.bmx"
provenanceTypeDocument.text = "SuperStrict~nImport BRL.Stream~nLocal stream:TStr"
provenanceContext.Analyze(provenanceTypeDocument)
Local provenanceTypeCompletions:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(provenanceTypeDocument, provenanceContext, 2, 100))
Check(FindCompletionItem(provenanceTypeCompletions, "TStreamWrapper") <> Null And FindCompletionItem(provenanceTypeCompletions, "TStreamWrapper").GetInteger("kind") = 7, "type-position completion includes public Types from compiler interfaces")
Local importedConstraintCompletionDocument:TLspDocument = New TLspDocument
importedConstraintCompletionDocument.uri = "file:///provenance/imported-constraint-completion.bmx"
importedConstraintCompletionDocument.path = "/provenance/imported-constraint-completion.bmx"
importedConstraintCompletionDocument.text = "SuperStrict~nImport BRL.Stream~nType TStreamMissing~nEnd Type~nLocal value:TImportedConstrained<TStr"
Local importedConstraintCompletionAnalysis:TLanguageAnalysis = provenanceContext.Analyze(importedConstraintCompletionDocument)
Local importedConstraintCompletionPosition:TSourcePosition = importedConstraintCompletionAnalysis.syntaxTree.source.Position(importedConstraintCompletionDocument.text.length)
Local importedConstraintCompletionItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(importedConstraintCompletionDocument, provenanceContext, importedConstraintCompletionPosition.line, importedConstraintCompletionPosition.column))
Check(FindCompletionItem(importedConstraintCompletionItems, "TStreamWrapper") <> Null And FindCompletionItem(importedConstraintCompletionItems, "TStreamMissing") <> Null, "generic argument completion keeps imported and local type candidates available across a module boundary")
Check(FindCompletionItem(importedConstraintCompletionItems, "TStreamWrapper").GetString("sortText").Compare(FindCompletionItem(importedConstraintCompletionItems, "TStreamMissing").GetString("sortText"), True) < 0, "an imported generic constraint ranks a satisfying module type ahead of an equally prefix-matched local type")
Local provenanceSignature:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.SignatureHelp(provenanceDocument, provenanceContext, 4, 14))
Check(provenanceSignature <> Null And TJSONArray(provenanceSignature.Get("signatures")) <> Null, "imported documented signature help is available")
Local provenanceSignatures:TJSONArray = TJSONArray(provenanceSignature.Get("signatures"))
Local provenanceSignatureInfo:TJSONObject = TJSONObject(provenanceSignatures.Get(0))
Check(provenanceSignatureInfo <> Null And TJSONObject(provenanceSignatureInfo.Get("documentation")) <> Null, "imported signature contains Markdown")
Check(TJSONObject(provenanceSignatureInfo.Get("documentation")).GetString("value").Contains("Reads bytes from the wrapper."), "signature help lazily recovers routine bbdoc from source provenance")
Local provenanceParameters:TJSONArray = TJSONArray(provenanceSignatureInfo.Get("parameters"))
Check(TJSONObject(TJSONObject(provenanceParameters.Get(0)).Get("documentation")).GetString("value").Contains("**count**"), "imported parameter documentation is linked by ordinal position")
Local importedGenericCompletionDocument:TLspDocument = New TLspDocument
importedGenericCompletionDocument.uri = "file:///provenance/imported-generic-completion.bmx"
importedGenericCompletionDocument.path = "/provenance/imported-generic-completion.bmx"
importedGenericCompletionDocument.text = "SuperStrict~nImport BRL.Stream~nLocal holder:TImportedBox<String>~nholder."
Local importedGenericCompletionAnalysis:TLanguageAnalysis = provenanceContext.Analyze(importedGenericCompletionDocument)
Local importedGenericCompletionOffset:Int = importedGenericCompletionDocument.text.length
Local importedGenericCompletionPosition:TSourcePosition = importedGenericCompletionAnalysis.syntaxTree.source.Position(importedGenericCompletionOffset)
Local importedGenericCompletionItems:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(importedGenericCompletionDocument, provenanceContext, importedGenericCompletionPosition.line, importedGenericCompletionPosition.column))
Check(FindCompletionItemWithLabelDetail(importedGenericCompletionItems, "ValueOr", "(fallback:String)").GetString("detail").Contains("Method ValueOr:String(fallback:String)"), "member completion substitutes generic parameter types from an imported module interface")
Check(FindCompletionItemWithLabelDetail(importedGenericCompletionItems, "Value", "()").GetString("detail").Contains("Method Value:String()"), "member completion substitutes generic return types from an imported module interface")
Local importedResolvedValueOr:TJSONObject = TBlitzMaxLspCompletion.Resolve(FindCompletionItemWithLabelDetail(importedGenericCompletionItems, "ValueOr", "(fallback:String)"), importedGenericCompletionDocument, provenanceContext)
Local importedResolvedValueOrDocumentation:String = TJSONObject(importedResolvedValueOr.Get("documentation")).GetString("value")
Check(importedResolvedValueOrDocumentation.Contains("Method ValueOr:String(fallback:String)") And importedResolvedValueOrDocumentation.Contains("Declared as:") And importedResolvedValueOrDocumentation.Contains("Method ValueOr:T(fallback:T)"), "imported generic completion resolve retains provenance identity while showing constructed and declared signatures")
Local importedGenericSignatureDocument:TLspDocument = New TLspDocument
importedGenericSignatureDocument.uri = "file:///provenance/imported-generic-signature.bmx"
importedGenericSignatureDocument.path = "/provenance/imported-generic-signature.bmx"
importedGenericSignatureDocument.text = "SuperStrict~nImport BRL.Stream~nLocal holder:TImportedBox<String>~nholder.ValueOr("
Local importedGenericSignatureAnalysis:TLanguageAnalysis = provenanceContext.Analyze(importedGenericSignatureDocument)
Local importedGenericSignature:TJSONObject = TJSONObject(TBlitzMaxLspNavigation.SignatureHelp(importedGenericSignatureDocument, provenanceContext, 3, importedGenericSignatureDocument.text.Split("~n")[3].length))
Check(HasSignatureLabel(importedGenericSignature, "Method ValueOr:String(fallback:String)"), "signature help survives an incomplete imported generic member call with constructed types")
SaveText("SuperStrict~nRem~nbbdoc: Updated compiler interface wrapper documentation.~nEnd Rem~nType TStreamWrapper~nRem~nbbdoc: Reads bytes from the wrapper.~nreturns: The number of bytes read.~nparam: The requested @count.~nabout: Read details from source provenance.~nEnd Rem~nMethod Read:Int(count:Int)~nReturn count~nEnd Method~nEnd Type", provenanceModuleDirectory + "/stream.bmx")
Local refreshedProvenanceHover:TJSONObject = TJSONObject(TBlitzMaxLspHover.Query(provenanceDocument, provenanceContext, 2, 16))
Check(TJSONObject(refreshedProvenanceHover.Get("contents")).GetString("value").Contains("Updated compiler interface wrapper documentation."), "provenance documentation cache refreshes when source size or timestamp changes")
Local provenanceHintRange:TJSONObject = JsonObject()
Local provenanceHintStart:TJSONObject = JsonObject()
provenanceHintStart.Set("line", 4)
provenanceHintStart.Set("character", 0)
Local provenanceHintEnd:TJSONObject = JsonObject()
provenanceHintEnd.Set("line", 4)
provenanceHintEnd.Set("character", 100)
provenanceHintRange.Set("start", provenanceHintStart)
provenanceHintRange.Set("end", provenanceHintEnd)
Local provenanceHints:TJSONArray = TJSONArray(TBlitzMaxLspInlayHints.Query(provenanceDocument, provenanceContext, provenanceHintRange))
Check(FindInlayHint(provenanceHints, 4, 13, "count:", 2) <> Null, "parameter hints use names decoded from compiler interfaces")
Check(InlayTooltip(FindInlayHint(provenanceHints, 4, 13, "count:", 2)) = "`count: Int`", "imported parameter hints expose decoded semantic types")
Local importedGenericInlayDocument:TLspDocument = New TLspDocument
importedGenericInlayDocument.uri = "file:///provenance/imported-generic-inlay.bmx"
importedGenericInlayDocument.path = "/provenance/imported-generic-inlay.bmx"
importedGenericInlayDocument.text = "SuperStrict~nImport BRL.Stream~nLocal holder:TImportedBox<String>~nLocal importedValue := holder.ValueOr(~qfallback~q)"
provenanceContext.Analyze(importedGenericInlayDocument)
Local importedGenericHints:TJSONArray = TJSONArray(TBlitzMaxLspInlayHints.Query(importedGenericInlayDocument, provenanceContext, Null))
Check(FindInlayHint(importedGenericHints, 3, 19, ": String", 1) <> Null, "inferred type hints preserve constructed generic results across a module interface")
Local importedFallbackHint:TJSONObject = FindInlayHint(importedGenericHints, 3, 38, "fallback:", 2)
Check(InlayTooltip(importedFallbackHint).Contains("`fallback: String`") And InlayTooltip(importedFallbackHint).Contains("Declared as: `fallback: T`"), "imported generic parameter hints show instantiated and declared types")
DeleteDir(provenanceSdk, True)
Local optionalTestConfiguration:TLspWorkspaceConfiguration = snapshotConfiguration.Copy()
optionalTestConfiguration.sdkPath = RealPath(AppDir + "/../../../BlitzMax-bcc2")
Local optionalTestContext:TLspWorkspaceContext = TLspWorkspaceContext.Create("file:///optional-tests", "optional-tests", optionalTestConfiguration, New TLspDependencyCache)
Local optionalTestSourcePath:String = NormalizeWorkspacePath(optionalTestConfiguration.sdkPath) + "/mod/brl.mod/optional.mod/tests/test.bmx"
Local optionalTestDocument:TLspDocument = New TLspDocument
optionalTestDocument.uri = "file://" + optionalTestSourcePath
optionalTestDocument.path = optionalTestSourcePath
optionalTestDocument.text = LoadText(optionalTestSourcePath)
Check(optionalTestDocument.text.Contains("Type TOptionalTest"), "Optional MaxUnit regression fixture is present in the SDK")
Local optionalTestAnalysis:TLanguageAnalysis = optionalTestContext.Analyze(optionalTestDocument)
Check(optionalTestAnalysis <> Null And optionalTestAnalysis.syntaxTree <> Null And optionalTestAnalysis.model <> Null, "LSP analysis of the complete Optional MaxUnit suite does not fail")
Local threadsSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/brl.mod/threads.mod/threads.bmx"
Local threadsDocument:TLspDocument = New TLspDocument
threadsDocument.uri = "file://" + threadsSourcePath
threadsDocument.path = threadsSourcePath
threadsDocument.text = LoadText(threadsSourcePath)
Local threadsAnalysis:TLanguageAnalysis = firstContext.Analyze(threadsDocument)
For Local diagnostic:TDiagnostic = EachIn threadsAnalysis.model.diagnostics
	Check(Not (diagnostic.code = "BMX3310" And diagnostic.message.Contains("Byte Ptr") And diagnostic.message.Contains("assignment")), "brl.threads accepts zero as a null thread handle")
	Check(Not (diagnostic.code = "BMX3610" And diagnostic.message.Contains("unit")), "brl.threads enum parameter default is constant")
	Check(Not (diagnostic.code = "BMX3302" And diagnostic.message.Contains("TimeUnitToMillis")), "brl.threads resolves TimeUnitToMillis through its threaded import")
	Check(Not (diagnostic.code = "BMX3300" And diagnostic.message.Contains("CurrentUnixTime")), "brl.threads resolves CurrentUnixTime through its threaded import")
Next

Local freeTypeFontSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/brl.mod/freetypefont.mod/freetypefont.bmx"
Local freeTypeFontDocument:TLspDocument = New TLspDocument
freeTypeFontDocument.uri = "file://" + freeTypeFontSourcePath
freeTypeFontDocument.path = freeTypeFontSourcePath
freeTypeFontDocument.text = LoadText(freeTypeFontSourcePath)
Local freeTypeFontAnalysis:TLanguageAnalysis = firstContext.Analyze(freeTypeFontDocument)
For Local diagnostic:TDiagnostic = EachIn freeTypeFontAnalysis.model.diagnostics
	Check(diagnostic.code <> "BMX3211", "brl.freetypefont accepts a TPixmap result as a covariant override of Object")
	Check(diagnostic.code <> "BMX3316", "brl.freetypefont recognizes TFreeTypeGlyph as concrete after its imported covariant override")
Next

Local globSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/brl.mod/glob.mod/glob.bmx"
Local globDocument:TLspDocument = New TLspDocument
globDocument.uri = "file://" + globSourcePath
globDocument.path = globSourcePath
globDocument.text = LoadText(globSourcePath)
Local globAnalysis:TLanguageAnalysis = firstContext.Analyze(globDocument)
For Local diagnostic:TDiagnostic = EachIn globAnalysis.model.diagnostics
	Check(diagnostic.code <> "BMX3211", "brl.glob follows ICloseableIterator through the production bcc embedded generic Interface")
Next

Local pathSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/brl.mod/path.mod/path.bmx"
Local pathSourceDocument:TLspDocument = New TLspDocument
pathSourceDocument.uri = "file://" + pathSourcePath
pathSourceDocument.path = pathSourcePath
pathSourceDocument.text = LoadText(pathSourcePath)
Local pathSourceAnalysis:TLanguageAnalysis = firstContext.Analyze(pathSourceDocument)
For Local diagnostic:TDiagnostic = EachIn pathSourceAnalysis.model.diagnostics
	Check(Not (diagnostic.code = "BMX3310" And diagnostic.message.Contains("TGlobIter") And diagnostic.message.Contains("IIterator<String>")), "brl.path converts TGlobIter through the canonical generic iterator Interface")
Next

Local reflectionSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/brl.mod/reflection.mod/reflection.bmx"
Local reflectionDocument:TLspDocument = New TLspDocument
reflectionDocument.uri = "file://" + reflectionSourcePath
reflectionDocument.path = reflectionSourcePath
reflectionDocument.text = LoadText(reflectionSourcePath)
Local reflectionAnalysis:TLanguageAnalysis = firstContext.Analyze(reflectionDocument)
For Local diagnostic:TDiagnostic = EachIn reflectionAnalysis.syntaxTree.diagnostics
	Check(Not (diagnostic.code = "BMX2102" And diagnostic.message.Contains("Ptr")), "brl.reflection accepts unparenthesized pointer casts")
Next
Local reflectionPointerOffset:Int = reflectionDocument.text.Find("Byte Ptr GetSizet(obj)")
Local reflectionPointerLocation:TSyntaxLocation = TSyntaxLocation.Locate(TSyntaxNavigator.Create(reflectionAnalysis.syntaxTree), reflectionPointerOffset)
Local reflectionPointerCast:TCastExpressionSyntax
For Local candidate:TSyntaxNode = EachIn reflectionPointerLocation.parents
	If Not reflectionPointerCast Then reflectionPointerCast = TCastExpressionSyntax(candidate)
Next
Check(reflectionPointerCast <> Null And reflectionAnalysis.model.ExpressionType(reflectionPointerCast).DisplayName() = "Byte Ptr", "brl.reflection pointer prefix cast has the expected semantic type")
Local reflectionSizeOffset:Int = reflectionDocument.text.Find("Size_T value", reflectionDocument.text.Find("Method SetPointer(obj:Object"))
Local reflectionSizeLocation:TSyntaxLocation = TSyntaxLocation.Locate(TSyntaxNavigator.Create(reflectionAnalysis.syntaxTree), reflectionSizeOffset)
Local reflectionSizeCast:TCastExpressionSyntax
For Local candidate:TSyntaxNode = EachIn reflectionSizeLocation.parents
	If Not reflectionSizeCast Then reflectionSizeCast = TCastExpressionSyntax(candidate)
Next
Check(reflectionSizeCast <> Null And reflectionAnalysis.model.ExpressionType(reflectionSizeCast) = reflectionAnalysis.model.BuiltinType("Size_T"), "brl.reflection numeric prefix cast binds inside a braceless method call")

Local queueSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/collections.mod/queue.mod/queue.bmx"
Local queueDocument:TLspDocument = New TLspDocument
queueDocument.uri = "file://" + queueSourcePath
queueDocument.path = queueSourcePath
queueDocument.text = LoadText(queueSourcePath)
Local queueAnalysis:TLanguageAnalysis = firstContext.Analyze(queueDocument)
For Local diagnostic:TDiagnostic = EachIn queueAnalysis.model.diagnostics
	Check(Not (diagnostic.code = "BMX3310" And diagnostic.message.Contains("Null") And diagnostic.message.Contains("T")), "collections.queue accepts Null as the contextual default for a generic array element")
Next

Local blockingQueueSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/collections.mod/blockingqueue.mod/blockingqueue.bmx"
Local blockingQueueDocument:TLspDocument = New TLspDocument
blockingQueueDocument.uri = "file://" + blockingQueueSourcePath
blockingQueueDocument.path = blockingQueueSourcePath
blockingQueueDocument.text = LoadText(blockingQueueSourcePath)
Local blockingQueueAnalysis:TLanguageAnalysis = firstContext.Analyze(blockingQueueDocument)
For Local diagnostic:TDiagnostic = EachIn blockingQueueAnalysis.model.diagnostics
	Check(Not (diagnostic.code = "BMX3300" And diagnostic.message.Contains("full")), "collections.blockingqueue resolves the inherited protected full field")
Next

Local objectListSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/collections.mod/objectlist.mod/objectlist.bmx"
Local objectListDocument:TLspDocument = New TLspDocument
objectListDocument.uri = "file://" + objectListSourcePath
objectListDocument.path = objectListSourcePath
objectListDocument.text = LoadText(objectListSourcePath)
Local objectListAnalysis:TLanguageAnalysis = firstContext.Analyze(objectListDocument)
For Local diagnostic:TDiagnostic = EachIn objectListAnalysis.model.diagnostics
	Check(Not (diagnostic.code = "BMX3610" And diagnostic.message.Contains("compareFunc")), "collections.objectlist accepts _CompareObjects as a constant callable default")
Next

Local treeMapSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/collections.mod/treemap.mod/treemap.bmx"
Local treeMapDocument:TLspDocument = New TLspDocument
treeMapDocument.uri = "file://" + treeMapSourcePath
treeMapDocument.path = treeMapSourcePath
treeMapDocument.text = LoadText(treeMapSourcePath)
Local treeMapAnalysis:TLanguageAnalysis = firstContext.Analyze(treeMapDocument)
For Local diagnostic:TDiagnostic = EachIn treeMapAnalysis.model.diagnostics
	Check(Not (diagnostic.code = "BMX3310" And diagnostic.message.Contains("TTreeMapNode")), "collections.treemap preserves adjacent generic close and initializer assignment tokens")
	Check(Not (diagnostic.code = "BMX3302" And diagnostic.message.Contains("DefaultComparator_Compare")), "collections.treemap defers DefaultComparator_Compare for its open key type")
Next
Local treeCompareCall:TCallExpressionSyntax = FindCall(treeMapAnalysis, treeMapDocument.text, "DefaultComparator_Compare(key, node.key)")
Check(treeCompareCall <> Null And treeMapAnalysis.model.ResolvedCall(treeCompareCall).isDeferred And treeMapAnalysis.model.ResolvedCall(treeCompareCall).returnType = treeMapAnalysis.model.BuiltinType("Int"), "collections.treemap retains a deferred comparator overload set with an Int result")

Local stringMapSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/collections.mod/stringmap.mod/stringmap.bmx"
Local stringMapDocument:TLspDocument = New TLspDocument
stringMapDocument.uri = "file://" + stringMapSourcePath
stringMapDocument.path = stringMapSourcePath
stringMapDocument.text = LoadText(stringMapSourcePath)
Local stringMapAnalysis:TLanguageAnalysis = firstContext.Analyze(stringMapDocument)
Local iteratorCastOffset:Int = stringMapDocument.text.Find("IIterator<IMapNode<String,Object>>(_map.GetIterator())")
Local iteratorCastSyntax:TSyntaxLocation = TSyntaxLocation.Locate(TSyntaxNavigator.Create(stringMapAnalysis.syntaxTree), iteratorCastOffset)
Local iteratorCastCall:TCallExpressionSyntax
For Local candidate:TSyntaxNode = EachIn iteratorCastSyntax.parents
	If Not iteratorCastCall Then iteratorCastCall = TCallExpressionSyntax(candidate)
Next
Check(iteratorCastCall <> Null And stringMapAnalysis.model.NamedCastTarget(iteratorCastCall).DisplayName() = "IIterator<IMapNode<String, Object>>", "collections.stringmap iterator cast retains its nested generic target")
Local mapNodeCastOffset:Int = stringMapDocument.text.Find("IMapNode<String,Object>(iter.Current())")
Local mapNodeCastSyntax:TSyntaxLocation = TSyntaxLocation.Locate(TSyntaxNavigator.Create(stringMapAnalysis.syntaxTree), mapNodeCastOffset)
Local mapNodeCastCall:TCallExpressionSyntax
For Local candidate:TSyntaxNode = EachIn mapNodeCastSyntax.parents
	If Not mapNodeCastCall Then mapNodeCastCall = TCallExpressionSyntax(candidate)
Next
Check(mapNodeCastCall <> Null And stringMapAnalysis.model.NamedCastTarget(mapNodeCastCall).DisplayName() = "IMapNode<String, Object>", "collections.stringmap map-node cast retains both generic arguments")

Local hashMapTestPath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/collections.mod/hashmap.mod/tests/test.bmx"
Local hashMapTestDocument:TLspDocument = New TLspDocument
hashMapTestDocument.uri = "file://" + hashMapTestPath
hashMapTestDocument.path = hashMapTestPath
hashMapTestDocument.text = LoadText(hashMapTestPath)
Local hashMapTestAnalysis:TLanguageAnalysis = firstContext.Analyze(hashMapTestDocument)
Local mapLocalOffset:Int = hashMapTestDocument.text.Find("m:THashMap<String,String>")
Local mapLocalLocation:TSemanticLocation = TSemanticLocation.Query(hashMapTestAnalysis.model, TSyntaxNavigator.Create(hashMapTestAnalysis.syntaxTree), mapLocalOffset)
Local mapLocalDeclaration:TVariableDeclaratorSyntax = TVariableDeclaratorSyntax(mapLocalLocation.symbol.declaration)
Local mapCreation:TNewExpressionSyntax = TNewExpressionSyntax(mapLocalDeclaration.initializer)
Check(mapCreation.createdType.genericArguments.length = 2 And hashMapTestAnalysis.model.ExpressionType(mapLocalDeclaration.initializer).DisplayName() = "THashMap<String, String>", "actual hashmap New expression preserves both generic arguments")
For Local diagnostic:TDiagnostic = EachIn hashMapTestAnalysis.model.diagnostics
	Check(Not (diagnostic.code = "BMX3101" And diagnostic.message.Contains("IMapNode")), "hashmap test ignores compiler-only IMapNode specializations")
	Check(Not (diagnostic.code = "BMX3310" And diagnostic.message.Contains("THashMap")), "constructed THashMap initializer retains its generic arguments")
	Check(Not (diagnostic.code = "BMX3310" And diagnostic.message.Contains("index expression")), "hashmap String keys are validated by the overloaded index operator")
Next
Local gotLocalOffset:Int = hashMapTestDocument.text.Find("got:String")
Local gotLocalLocation:TSemanticLocation = TSemanticLocation.Query(hashMapTestAnalysis.model, TSyntaxNavigator.Create(hashMapTestAnalysis.syntaxTree), gotLocalOffset)
Local gotLocalDeclaration:TVariableDeclaratorSyntax = TVariableDeclaratorSyntax(gotLocalLocation.symbol.declaration)
Local gotIndexExpression:TIndexExpressionSyntax = TIndexExpressionSyntax(gotLocalDeclaration.initializer)
Local gotIndexCall:TResolvedCall = hashMapTestAnalysis.model.ResolvedCall(gotIndexExpression)
Check(gotIndexCall <> Null And gotIndexCall.routine.name = "[]" And gotIndexCall.parameterTypes[0] = hashMapTestAnalysis.model.BuiltinType("String") And gotIndexCall.returnType = hashMapTestAnalysis.model.BuiltinType("String"), "hashmap getter resolves its substituted String signature")
Local setterKeyOffset:Int = hashMapTestDocument.text.Find("~qa~q", hashMapTestDocument.text.Find("m[~qa~q] = ~qalpha~q")) + 1
Local setterKeyPosition:TSourcePosition = hashMapTestAnalysis.syntaxTree.source.Position(setterKeyOffset)
Local setterKeyHover:TJSONObject = TJSONObject(TBlitzMaxLspHover.Query(hashMapTestDocument, firstContext, setterKeyPosition.line, setterKeyPosition.column))
Check(setterKeyHover <> Null And Not TJSONObject(setterKeyHover.Get("contents")).GetString("value").Contains("Method []="), "hovering a hashmap key literal does not claim the literal is the setter")
Local setterBracketOffset:Int = hashMapTestDocument.text.Find("[~qa~q]", hashMapTestDocument.text.Find("m[~qa~q] = ~qalpha~q"))
Local setterBracketPosition:TSourcePosition = hashMapTestAnalysis.syntaxTree.source.Position(setterBracketOffset)
Local setterBracketHover:TJSONObject = TJSONObject(TBlitzMaxLspHover.Query(hashMapTestDocument, firstContext, setterBracketPosition.line, setterBracketPosition.column))
Check(setterBracketHover <> Null And TJSONObject(setterBracketHover.Get("contents")).GetString("value").Contains("Method []="), "hashmap setter remains navigable from the index brackets")
Local loopMapNodeOffset:Int = hashMapTestDocument.text.Find("IMapNode<String,String>")
Local loopMapNodeLocation:TSemanticLocation = TSemanticLocation.Query(hashMapTestAnalysis.model, TSyntaxNavigator.Create(hashMapTestAnalysis.syntaxTree), loopMapNodeOffset)
Check(loopMapNodeLocation.symbol <> Null And loopMapNodeLocation.symbol.name = "IMapNode" And loopMapNodeLocation.symbol.originModule.ToLower() = "collections.imap", "hashmap EachIn variable navigates to canonical IMapNode")

Local hashMapSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/collections.mod/hashmap.mod/hashmap.bmx"
Local hashMapSourceDocument:TLspDocument = New TLspDocument
hashMapSourceDocument.uri = "file://" + hashMapSourcePath
hashMapSourceDocument.path = hashMapSourcePath
hashMapSourceDocument.text = LoadText(hashMapSourcePath)
Local hashMapSourceAnalysis:TLanguageAnalysis = firstContext.Analyze(hashMapSourceDocument)
Local iteratorMapNodeOffset:Int = hashMapSourceDocument.text.Find("IMapNode", hashMapSourceDocument.text.Find("Method GetIterator"))
Local iteratorMapNodeLocation:TSemanticLocation = TSemanticLocation.Query(hashMapSourceAnalysis.model, TSyntaxNavigator.Create(hashMapSourceAnalysis.syntaxTree), iteratorMapNodeOffset)
Check(iteratorMapNodeLocation.symbol <> Null And iteratorMapNodeLocation.symbol.name = "IMapNode", "nested GetIterator return type navigates to IMapNode rather than IIterator")
For Local diagnostic:TDiagnostic = EachIn hashMapSourceAnalysis.model.diagnostics
	Check(Not (diagnostic.code = "BMX3302" And diagnostic.message.Contains("DefaultComparator_Equals")), "collections.hashmap defers DefaultComparator_Equals for its open key type")
	Check(Not (diagnostic.code = "BMX3302" And diagnostic.message.Contains("DefaultComparator_HashCode")), "collections.hashmap defers DefaultComparator_HashCode for its open key type")
Next
Local hashEqualsCall:TCallExpressionSyntax = FindCall(hashMapSourceAnalysis, hashMapSourceDocument.text, "DefaultComparator_Equals(a, b)")
Local hashCodeCall:TCallExpressionSyntax = FindCall(hashMapSourceAnalysis, hashMapSourceDocument.text, "DefaultComparator_HashCode(key)")
Check(hashEqualsCall <> Null And hashMapSourceAnalysis.model.ResolvedCall(hashEqualsCall).isDeferred And hashMapSourceAnalysis.model.ResolvedCall(hashEqualsCall).returnType = hashMapSourceAnalysis.model.BuiltinType("Int"), "collections.hashmap retains the deferred equality overload set")
Check(hashCodeCall <> Null And hashMapSourceAnalysis.model.ResolvedCall(hashCodeCall).isDeferred And hashMapSourceAnalysis.model.ResolvedCall(hashCodeCall).returnType = hashMapSourceAnalysis.model.BuiltinType("UInt"), "collections.hashmap retains the deferred hash overload set")

Local linkedHashMapSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/collections.mod/linkedhashmap.mod/linkedhashmap.bmx"
Local linkedHashMapDocument:TLspDocument = New TLspDocument
linkedHashMapDocument.uri = "file://" + linkedHashMapSourcePath
linkedHashMapDocument.path = linkedHashMapSourcePath
linkedHashMapDocument.text = LoadText(linkedHashMapSourcePath)
Local linkedHashMapAnalysis:TLanguageAnalysis = firstContext.Analyze(linkedHashMapDocument)
For Local diagnostic:TDiagnostic = EachIn linkedHashMapAnalysis.model.diagnostics
	Check(Not (diagnostic.code = "BMX3302" And diagnostic.message.Contains("DefaultComparator_Equals")), "collections.linkedhashmap defers DefaultComparator_Equals for its open key type")
	Check(Not (diagnostic.code = "BMX3302" And diagnostic.message.Contains("DefaultComparator_HashCode")), "collections.linkedhashmap defers DefaultComparator_HashCode for its open key type")
Next

Local freeProcessSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/pub.mod/freeprocess.mod/freeprocess.bmx"
Local freeProcessDocument:TLspDocument = New TLspDocument
freeProcessDocument.uri = "file://" + freeProcessSourcePath
freeProcessDocument.path = freeProcessSourcePath
freeProcessDocument.text = LoadText(freeProcessSourcePath)
Local freeProcessAnalysis:TLanguageAnalysis = firstContext.Analyze(freeProcessDocument)
For Local diagnostic:TDiagnostic = EachIn freeProcessAnalysis.model.diagnostics
	Check(Not (diagnostic.code = "BMX3300" And diagnostic.message.Contains("handle")), "active conditional field is visible throughout TProcess")
	Check(Not (diagnostic.code = "BMX3300" And diagnostic.message.Contains("fdProcessStatus")), "active conditional extern routine is visible after its region")
	Check(Not (diagnostic.code = "BMX3302" And diagnostic.message.Contains("OnEnd")), "type-qualified static routine is accepted as an OnEnd callback")
Next
Local flecsSourcePath:String = NormalizeWorkspacePath(snapshotConfiguration.sdkPath) + "/mod/ecs.mod/flecs.mod/flecs.bmx"
Local flecsDocument:TLspDocument = New TLspDocument
flecsDocument.uri = "file://" + flecsSourcePath
flecsDocument.path = flecsSourcePath
flecsDocument.text = LoadText(flecsSourcePath)
Local flecsAnalysis:TLanguageAnalysis = firstContext.Analyze(flecsDocument)
For Local diagnostic:TDiagnostic = EachIn flecsAnalysis.model.diagnostics
	Check(Not (diagnostic.code = "BMX3101" And diagnostic.message.Contains("THashMap")), "direct generic import wins over transitive specializations")
	Check(Not (diagnostic.code = "BMX3302" And diagnostic.message.Contains("Enqueue")), "TQueue ULong member substitution resolves Enqueue")
	Check(Not (diagnostic.code = "BMX3302" And diagnostic.message.Contains("bmx_ecs_register_struct_meta")), "struct array decays to the native Byte Ptr parameter")
	Check(Not (diagnostic.code = "BMX3310" And diagnostic.message.Contains("deltaTime")), "Float parameter accepts an untyped floating default")
	Check(Not (diagnostic.code = "BMX3300" And diagnostic.message.Contains("StackAlloc")), "StackAlloc is recognized as a builtin expression")
	Check(Not (diagnostic.code = "BMX3300" And diagnostic.message.Contains("SizeOf")), "SizeOf is recognized as a builtin expression")
Next
Local dependencyDocument:TLspDocument = New TLspDocument
dependencyDocument.uri = "file:///first/main.bmx"
dependencyDocument.path = "/first/main.bmx"
dependencyDocument.text = "SuperStrict~nImport BRL.StandardIO"
Local dependencyAnalysis:TLanguageAnalysis = firstContext.Analyze(dependencyDocument)
Check(dependencyAnalysis.snapshot <> Null And dependencyAnalysis.snapshot.coreInterface <> Null, "workspace analysis creates an immutable dependency snapshot")
Check(dependencyAnalysis.snapshot.interfaces.length > 1, "module interfaces are loaded into the snapshot")
Local importedConstFailure:Int
Local importedEnumDefaultFailure:Int
For Local diagnostic:TDiagnostic = EachIn dependencyAnalysis.model.diagnostics
	If diagnostic.code = "BMX3601" And diagnostic.message.Contains("CHARSFORMAT_SCIENTIFIC") Then importedConstFailure = True
	If diagnostic.code = "BMX3611" And diagnostic.message.Contains("ETextStreamFormat") Then
		importedEnumDefaultFailure = True
		Check(diagnostic.path.length > 0 And diagnostic.path <> dependencyDocument.path, "imported semantic diagnostic retains dependency provenance")
	End If
Next
Check(Not importedConstFailure, "ULong constants imported from brl.blitz interface are evaluable")
Check(Not importedEnumDefaultFailure, "enum defaults imported from module interfaces retain enum compatibility")
Local dependencyPublication:TJSONObject = TBlitzMaxLspDiagnostics.Publish(dependencyDocument, firstContext)
Local dependencyParams:TJSONObject = TJSONObject(dependencyPublication.Get("params"))
Local dependencyDiagnostics:TJSONArray = TJSONArray(dependencyParams.Get("diagnostics"))
For Local index:Int = 0 Until dependencyDiagnostics.Size()
	Local published:TJSONObject = TJSONObject(dependencyDiagnostics.Get(index))
	Check(Not (published.GetString("code") = "BMX3611" And published.GetString("message").Contains("ETextStreamFormat")), "imported semantic diagnostic is not published on importer")
Next
Local builtinMemberDocument:TLspDocument = New TLspDocument
builtinMemberDocument.uri = "file:///first/builtin-members.bmx"
builtinMemberDocument.path = "/first/builtin-members.bmx"
builtinMemberDocument.text = "SuperStrict~nLocal buf:Short[1024], i:Int~nIf buf.length = i Then buf = buf[..i + 1024]~nLocal text:String = String.FromShorts(buf, i)~nLocal found:Int = text.Find(~qe~q)"
Local builtinMemberAnalysis:TLanguageAnalysis = firstContext.Analyze(builtinMemberDocument)
Check(builtinMemberAnalysis.model.diagnostics.length = 0, "core Array members and String static methods resolve through blitz_classes.i")
Local builtinMemberRoot:TCompilationUnitSyntax = builtinMemberAnalysis.syntaxTree.root
Local bufferLengthCondition:TIfStatementSyntax = TIfStatementSyntax(builtinMemberRoot.members[2])
Local bufferLengthComparison:TBinaryExpressionSyntax = TBinaryExpressionSyntax(bufferLengthCondition.condition)
Local bufferLengthMember:TMemberAccessExpressionSyntax = TMemberAccessExpressionSyntax(bufferLengthComparison.left)
Check(builtinMemberAnalysis.model.ReferencedSymbol(bufferLengthMember).name.ToLower() = "length", "array length resolves to the ___Array runtime member")
Local arrayLengthSymbol:TSymbol = builtinMemberAnalysis.model.ReferencedSymbol(bufferLengthMember)
Check(arrayLengthSymbol.documentation <> Null And arrayLengthSymbol.documentation.summary.Contains("number of elements"), "array runtime members receive companion documentation")
Local staticArrayMemberDocument:TLspDocument = New TLspDocument
staticArrayMemberDocument.uri = "file:///first/static-array-members.bmx"
staticArrayMemberDocument.path = "/first/static-array-members.bmx"
staticArrayMemberDocument.text = "SuperStrict~nType TStack~nField StaticArray callstack:Int[50]~nMethod Depth:Int()~nReturn callstack.length~nEnd Method~nEnd Type"
Local staticArrayMemberAnalysis:TLanguageAnalysis = firstContext.Analyze(staticArrayMemberDocument)
Check(staticArrayMemberAnalysis.model.diagnostics.length = 0, "StaticArray length binds without diagnostics in an LSP analysis")
Local staticArrayCompletions:TJSONArray = TJSONArray(TBlitzMaxLspCompletion.Query(staticArrayMemberDocument, firstContext, 4, 17))
Local staticArrayLengthCompletion:TJSONObject = FindCompletionItem(staticArrayCompletions, "length")
Check(staticArrayLengthCompletion <> Null And staticArrayLengthCompletion.GetString("detail").Contains("Int"), "StaticArray member completion exposes its Int length intrinsic")
Local convertedStringDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(builtinMemberRoot.members[3])
Local fromShortsCall:TCallExpressionSyntax = TCallExpressionSyntax(convertedStringDeclaration.declarators[0].initializer)
Local boundFromShortsCall:TBoundCallExpression = TBoundCallExpression(builtinMemberAnalysis.model.BoundExpression(fromShortsCall))
Check(boundFromShortsCall <> Null And TBoundConversionExpression(boundFromShortsCall.arguments[0]).conversionKind = CONVERSION_ARRAY_TO_POINTER, "String.FromShorts receives an explicit array-to-pointer bound conversion")
Local stringRuntimeSymbol:TSymbol = builtinMemberAnalysis.model.BuiltinType("String").runtimeSymbol
Local stringFindSymbol:TSymbol = stringRuntimeSymbol.memberScope.LookupLocal("Find")[0]
Check(stringRuntimeSymbol.documentation <> Null And stringRuntimeSymbol.documentation.summary.Contains("Unicode characters"), "String receives companion type documentation")
Check(stringFindSymbol.documentation <> Null And stringFindSymbol.documentation.summary.Contains("first occurrence"), "String methods receive companion documentation")
Check(stringFindSymbol.documentationPath.EndsWith("/blitz_classes.docs.bmx"), "core documentation retains its companion source provenance")
Local stringFindOffset:Int = builtinMemberDocument.text.Find(".Find") + 2
Local stringFindPosition:TSourcePosition = builtinMemberAnalysis.syntaxTree.source.Position(stringFindOffset)
Local stringFindHover:TJSONObject = TJSONObject(TBlitzMaxLspHover.Query(builtinMemberDocument, firstContext, stringFindPosition.line, stringFindPosition.column))
Check(stringFindHover <> Null And TJSONObject(stringFindHover.Get("contents")).GetString("value").Contains("Finds the first occurrence"), "LSP hover consumes companion documentation without special-case handling")
Local recoveryDocument:TLspDocument = New TLspDocument
recoveryDocument.uri = "file:///first/incomplete-array.bmx"
recoveryDocument.path = "/first/incomplete-array.bmx"
recoveryDocument.text = "SuperStrict~nFunction NeedInt(value:Int)~nEnd Function~nNeedInt([MissingElement])"
Local recoveryAnalysis:TLanguageAnalysis = firstContext.Analyze(recoveryDocument)
Local recoveryOverloadDiagnostic:Int
For Local diagnostic:TDiagnostic = EachIn recoveryAnalysis.model.diagnostics
	If diagnostic.code = "BMX3302" And diagnostic.message.Contains("<unresolved array element>[]") Then recoveryOverloadDiagnostic = True
Next
Check(recoveryOverloadDiagnostic, "LSP analysis formats incomplete array argument types without crashing")
Local streamConversionDocument:TLspDocument = New TLspDocument
streamConversionDocument.uri = "file:///first/stream-conversions.bmx"
streamConversionDocument.path = "/first/stream-conversions.bmx"
streamConversionDocument.text = "SuperStrict~nImport BRL.Stream~nLocal path:String = ~qdata.txt~q~nLocal pathLength:Int = Len(path)~nLocal stream:TStream = OpenStream(path, True, 0)~nLocal url:Object~nLocal casted:TStream = TStream(url)~nType TWriteProbe~nMethod WriteChar(char:Int)~nEnd Method~nMethod WriteString(str:String)~nFor Local i:Long = 0 Until str.length~nWriteChar str[i]~nNext~nEnd Method~nEnd Type~nLocal data:Byte[1024]~nLocal size:Int~nsize :+ stream.Read((Byte Ptr data) + size, data.length - size - 1)~nLocal shortValue:Short~nstream.ReadBytes VarPtr shortValue, 2"
Local streamConversionAnalysis:TLanguageAnalysis = firstContext.Analyze(streamConversionDocument)
Check(streamConversionAnalysis.model.diagnostics.length = 0, "real BRL.Stream conversions, String indexing, and pointer arithmetic calls")
Local cachedDependencyCount:Int = sharedDependencies.Count()
dependencyDocument.uri = "file:///second/main.bmx"
dependencyDocument.path = "/second/main.bmx"
secondContext.Analyze(dependencyDocument)
Check(sharedDependencies.Count() = cachedDependencyCount, "workspace contexts share immutable interface text")
Check(firstContext.dependencyCache = secondContext.dependencyCache, "contexts share one dependency cache")

Local legacyServer:TBlitzMaxLspServer = NewTestServer()
legacyServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:1,~qmethod~q:~qinitialize~q,~qparams~q:{~qrootUri~q:~qfile:///legacy~q}}")
Check(legacyServer.workspaces.Get("file:///legacy") <> Null, "legacy rootUri initializes a workspace")
Check(Not legacyServer.completionSnippetSupport, "a client which does not advertise snippet support retains plain-text completion edits")
Check(Not legacyServer.workspaceSnippetEditSupport, "a legacy client retains plain-text workspace edits")

Local snippetCapabilityServer:TBlitzMaxLspServer = NewTestServer()
snippetCapabilityServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:1,~qmethod~q:~qinitialize~q,~qparams~q:{~qcapabilities~q:{~qtextDocument~q:{~qcompletion~q:{~qcompletionItem~q:{~qsnippetSupport~q:true}}},~qworkspace~q:{~qworkspaceEdit~q:{~qsnippetEditSupport~q:true}}}}}")
Check(snippetCapabilityServer.completionSnippetSupport, "initialize records completion-item snippet support from the client capabilities")
Check(snippetCapabilityServer.workspaceSnippetEditSupport, "initialize records workspace snippet-edit support independently")
snippetCapabilityServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/snippet-capability.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\nFunction Add:Int(left:Int, right:Int)\nReturn left + right\nEnd Function\nAd~q}}}")
Local snippetCapabilityResponses:String[] = snippetCapabilityServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:2,~qmethod~q:~qtextDocument/completion~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/snippet-capability.bmx~q},~qposition~q:{~qline~q:4,~qcharacter~q:2}}}")
Local snippetCapabilityResult:TJSONArray = TJSONArray(ObjectFrom(snippetCapabilityResponses[0]).Get("result"))
Local addSnippetCapabilityItem:TJSONObject = FindCompletionItem(snippetCapabilityResult, "Add")
Check(addSnippetCapabilityItem.GetInteger("insertTextFormat") = 2 And addSnippetCapabilityItem.GetString("insertText") = "Add(${1:left}, ${2:right})$0", "snippet-capable clients receive overload-specific call placeholders through JSON-RPC completion")

Local server:TBlitzMaxLspServer = NewTestServer()
Local responses:String[] = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:1,~qmethod~q:~qinitialize~q,~qparams~q:{~qworkspaceFolders~q:[{~quri~q:~qfile:///workspace~q,~qname~q:~qouter~q},{~quri~q:~qfile:///workspace/nested~q,~qname~q:~qnested~q}]}}")
Check(responses.length = 1, "initialize has one response")
Local initialize:TJSONObject = ObjectFrom(responses[0])
Local result:TJSONObject = TJSONObject(initialize.Get("result"))
Local capabilities:TJSONObject = TJSONObject(result.Get("capabilities"))
Check(capabilities.Get("textDocumentSync") <> Null, "initialize advertises document sync")
Check(capabilities.GetBool("hoverProvider"), "initialize advertises hover support")
Check(capabilities.GetBool("typeHierarchyProvider"), "initialize advertises type hierarchy support")
Check(capabilities.Get("documentLinkProvider") <> Null, "initialize advertises document links")
Check(capabilities.GetBool("referencesProvider"), "initialize advertises references")
Local codeActionCapability:TJSONObject = TJSONObject(capabilities.Get("codeActionProvider"))
Local codeActionKinds:TJSONArray = TJSONArray(codeActionCapability.Get("codeActionKinds"))
Check(codeActionCapability <> Null And Not codeActionCapability.GetBool("resolveProvider") And codeActionKinds.Size() = 2 And TJSONString(codeActionKinds.Get(0)).Value() = "quickfix" And TJSONString(codeActionKinds.Get(1)).Value() = "refactor.rewrite", "initialize advertises quick fixes and rewrite refactorings")
Local completionCapability:TJSONObject = TJSONObject(capabilities.Get("completionProvider"))
Check(completionCapability <> Null And completionCapability.GetBool("resolveProvider"), "initialize advertises lazy completion documentation resolution")
Local completionTriggers:TJSONArray = TJSONArray(completionCapability.Get("triggerCharacters"))
Check(completionTriggers.Size() = 6 And TJSONString(completionTriggers.Get(0)).Value() = "." And TJSONString(completionTriggers.Get(1)).Value() = " " And TJSONString(completionTriggers.Get(2)).Value() = ":" And TJSONString(completionTriggers.Get(3)).Value() = Chr(34) And TJSONString(completionTriggers.Get(4)).Value() = "/" And TJSONString(completionTriggers.Get(5)).Value() = Chr(92), "member, ordinary, type and quoted-path completion advertise compatible trigger characters")
Local semanticTokensCapability:TJSONObject = TJSONObject(capabilities.Get("semanticTokensProvider"))
Check(semanticTokensCapability <> Null And semanticTokensCapability.GetBool("full") And Not semanticTokensCapability.GetBool("range"), "initialize advertises full-document semantic tokens")
Local semanticLegend:TJSONObject = TJSONObject(semanticTokensCapability.Get("legend"))
Check(TJSONArray(semanticLegend.Get("tokenTypes")).Size() = 12 And TJSONArray(semanticLegend.Get("tokenModifiers")).Size() = 3, "semantic token legend matches the encoded classifier")
Local inlayHintCapability:TJSONObject = TJSONObject(capabilities.Get("inlayHintProvider"))
Check(inlayHintCapability <> Null And Not inlayHintCapability.GetBool("resolveProvider"), "initialize advertises resolved inlay hints")
Check(capabilities.GetBool("definitionProvider"), "initialize advertises definition support")
Check(capabilities.GetBool("typeDefinitionProvider"), "initialize advertises go to type definition support")
Check(capabilities.GetBool("implementationProvider"), "initialize advertises go to implementation support")
Check(capabilities.GetBool("foldingRangeProvider"), "initialize advertises syntax-aware folding support")
Check(capabilities.GetBool("selectionRangeProvider"), "initialize advertises syntax-aware smart selection")
Check(capabilities.GetBool("workspaceSymbolProvider"), "initialize advertises workspace symbol search")
Local renameCapability:TJSONObject = TJSONObject(capabilities.Get("renameProvider"))
Check(renameCapability <> Null And renameCapability.GetBool("prepareProvider"), "initialize advertises guarded rename preparation")
Check(capabilities.GetBool("documentSymbolProvider"), "initialize advertises document symbols")
Check(capabilities.GetBool("documentHighlightProvider"), "initialize advertises document highlights")
Check(capabilities.Get("signatureHelpProvider") <> Null, "initialize advertises signature help")
Local workspaceCapability:TJSONObject = TJSONObject(capabilities.Get("workspace"))
Local folderCapability:TJSONObject = TJSONObject(workspaceCapability.Get("workspaceFolders"))
Check(folderCapability.GetBool("supported") And folderCapability.GetBool("changeNotifications"), "initialize advertises dynamic workspace folders")
Check(server.workspaces.Count() = 2, "initialize records all workspace folders")
responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qinitialized~q,~qparams~q:{}}")
Check(responses.length = 0 And server.workspaces.installedCatalogues.Count() = 0, "initialized leaves the installed-module catalogue lazy so document analysis is not blocked by global discovery")
Local lazyInstalledCatalogue:TLspInstalledModuleCatalogue = server.workspaces.adHoc.InstalledCatalogue()
Check(lazyInstalledCatalogue.ModuleCount() > 0 And lazyInstalledCatalogue.catalogue.FindModule("brl.stream") <> Null, "the installed environment catalogue is built on first discovery request")
server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///workspace/implementation-json.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\nInterface IJson\nEnd Interface\nType TJson Implements IJson\nEnd Type~q}}}")
responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:70,~qmethod~q:~qtextDocument/implementation~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///workspace/implementation-json.bmx~q},~qposition~q:{~qline~q:1,~qcharacter~q:12}}}")
Local implementationResponse:TJSONObject = ObjectFrom(responses[0])
Local implementationResult:TJSONArray = TJSONArray(implementationResponse.Get("result"))
Check(implementationResult <> Null And HasLocation(implementationResult, "file:///workspace/implementation-json.bmx", 3, 5), "textDocument/implementation round-trips through JSON-RPC")
responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:71,~qmethod~q:~qtextDocument/foldingRange~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///workspace/implementation-json.bmx~q}}}")
Local foldingResponse:TJSONObject = ObjectFrom(responses[0])
Local protocolFoldingRanges:TJSONArray = TJSONArray(foldingResponse.Get("result"))
Check(HasFoldingRange(protocolFoldingRanges, 1, 2) And HasFoldingRange(protocolFoldingRanges, 3, 4), "textDocument/foldingRange round-trips through JSON-RPC")
responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:72,~qmethod~q:~qtextDocument/selectionRange~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///workspace/implementation-json.bmx~q},~qpositions~q:[{~qline~q:1,~qcharacter~q:12},{~qline~q:3,~qcharacter~q:7}]}}")
Local selectionResponse:TJSONObject = ObjectFrom(responses[0])
Local protocolSelectionRanges:TJSONArray = TJSONArray(selectionResponse.Get("result"))
Check(protocolSelectionRanges.Size() = 2 And TJSONObject(protocolSelectionRanges.Get(0)).Get("parent") <> Null, "textDocument/selectionRange preserves request order and nested parents through JSON-RPC")
responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:73,~qmethod~q:~qworkspace/symbol~q,~qparams~q:{~qquery~q:~qIJson~q}}")
Local workspaceSymbolResponse:TJSONObject = ObjectFrom(responses[0])
Local liveWorkspaceSymbols:TJSONArray = TJSONArray(workspaceSymbolResponse.Get("result"))
Check(FindWorkspaceSymbol(liveWorkspaceSymbols, "IJson", "implementation-json.bmx") <> Null, "workspace/symbol finds declarations from live workspace analyses")
responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:74,~qmethod~q:~qworkspace/symbol~q,~qparams~q:{~qquery~q:~qTPath~q}}")
workspaceSymbolResponse = ObjectFrom(responses[0])
Local installedSdkSymbols:TJSONArray = TJSONArray(workspaceSymbolResponse.Get("result"))
Check(FindWorkspaceSymbol(installedSdkSymbols, "TPath", "/path.mod/path.bmx") <> Null, "workspace/symbol searches installed SDK declarations with source provenance")
server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didClose~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///workspace/implementation-json.bmx~q}}}")

Local renameServer:TBlitzMaxLspServer = NewTestServer()
renameServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:80,~qmethod~q:~qinitialize~q,~qparams~q:{}}")
renameServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/rename-json.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\nFunction Double:Int(value:Int)\nLocal result:Int = value * 2\nReturn result\nEnd Function~q}}}")
responses = renameServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:81,~qmethod~q:~qtextDocument/prepareRename~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/rename-json.bmx~q},~qposition~q:{~qline~q:3,~qcharacter~q:9}}}")
Local prepareRenameResponse:TJSONObject = ObjectFrom(responses[0])
Check(TJSONObject(prepareRenameResponse.Get("result")).GetString("placeholder") = "result", "textDocument/prepareRename round-trips through JSON-RPC")
responses = renameServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:82,~qmethod~q:~qtextDocument/rename~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/rename-json.bmx~q},~qposition~q:{~qline~q:3,~qcharacter~q:9},~qnewName~q:~qdoubled~q}}")
Local renameResponse:TJSONObject = ObjectFrom(responses[0])
Local protocolRenameEdit:TJSONObject = TJSONObject(renameResponse.Get("result"))
Check(WorkspaceEditEdits(protocolRenameEdit, "file:///tmp/rename-json.bmx").Size() = 2, "textDocument/rename returns declaration and reference edits through JSON-RPC")

Local codeActionServer:TBlitzMaxLspServer = NewTestServer()
codeActionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:83,~qmethod~q:~qinitialize~q,~qparams~q:{}}")
Local codeActionUri:String = "file:///tmp/postfix-quick-fix.bmx"
Local codeActionSource:String = "SuperStrict~nType TGNetMsg~nEnd Type~nLocal msg:TGNetMsg~nmsg:TGNetMsg = New TGNetMsg"
responses = codeActionServer.HandlePayload(DidOpenPayload(codeActionUri, codeActionSource))
Local codeActionPublication:TJSONObject = ObjectFrom(responses[0])
Local codeActionPublishParams:TJSONObject = TJSONObject(codeActionPublication.Get("params"))
Local codeActionDiagnostics:TJSONArray = TJSONArray(codeActionPublishParams.Get("diagnostics"))
Local postfixDiagnostic:TJSONObject = FindProtocolDiagnostic(codeActionDiagnostics, "BMX2105")
Check(postfixDiagnostic <> Null, "opening a legacy postfix assignment publishes BMX2105")
Local postfixDiagnosticRange:TJSONObject = TJSONObject(postfixDiagnostic.Get("range"))
Local postfixDiagnosticStart:TJSONObject = TJSONObject(postfixDiagnosticRange.Get("start"))
Local postfixDiagnosticEnd:TJSONObject = TJSONObject(postfixDiagnosticRange.Get("end"))
Check(postfixDiagnosticStart.GetInteger("line") = 4 And postfixDiagnosticStart.GetInteger("character") = 3 And postfixDiagnosticEnd.GetInteger("line") = 4 And postfixDiagnosticEnd.GetInteger("character") = 12, "BMX2105 highlights only :TGNetMsg")
Local requestedPostfixDiagnostics:TJSONArray = JsonArray()
requestedPostfixDiagnostics.Append(postfixDiagnostic)
responses = codeActionServer.HandlePayload(CodeActionPayload(84, codeActionUri, postfixDiagnosticRange, requestedPostfixDiagnostics, "quickfix"))
Local codeActionResponse:TJSONObject = ObjectFrom(responses[0])
Local postfixActions:TJSONArray = TJSONArray(codeActionResponse.Get("result"))
Check(postfixActions.Size() = 1, "BMX2105 offers one quick fix")
Local removePostfixAction:TJSONObject = TJSONObject(postfixActions.Get(0))
Check(removePostfixAction.GetString("title") = "Remove postfix type annotation" And removePostfixAction.GetString("kind") = "quickfix" And removePostfixAction.GetBool("isPreferred"), "postfix removal is the preferred quick fix")
Local postfixEdit:TJSONObject = TJSONObject(removePostfixAction.Get("edit"))
Local postfixEdits:TJSONArray = WorkspaceEditEdits(postfixEdit, codeActionUri)
Local postfixTextEdit:TJSONObject = TJSONObject(postfixEdits.Get(0))
Check(postfixEdits.Size() = 1 And postfixTextEdit.GetString("newText") = "" And TBlitzMaxLspCodeActions.SameRange(TJSONObject(postfixTextEdit.Get("range")), postfixDiagnosticRange), "postfix quick fix deletes exactly the diagnosed type annotation")
postfixDiagnosticStart.Set("character", 4)
responses = codeActionServer.HandlePayload(CodeActionPayload(85, codeActionUri, postfixDiagnosticRange, requestedPostfixDiagnostics, "quickfix"))
Check(TJSONArray(ObjectFrom(responses[0]).Get("result")).Size() = 0, "a stale or fabricated BMX2105 range receives no edit")

Local missingImportUri:String = "file:///tmp/missing-import-quick-fix.bmx"
Local missingImportSource:String = "SuperStrict~n~nImport brl.filesystem~n~n~nPrint FileType(~qhello~q)"
responses = codeActionServer.HandlePayload(DidOpenPayload(missingImportUri, missingImportSource))
Local missingImportPublication:TJSONObject = ObjectFrom(responses[0])
Local missingImportDiagnostics:TJSONArray = TJSONArray(TJSONObject(missingImportPublication.Get("params")).Get("diagnostics"))
Local unresolvedPrintDiagnostic:TJSONObject = FindProtocolDiagnostic(missingImportDiagnostics, "BMX3300")
Check(unresolvedPrintDiagnostic <> Null And unresolvedPrintDiagnostic.GetString("message").Contains("'Print'"), "an unresolved Print publishes BMX3300")
Local unresolvedPrintRange:TJSONObject = TJSONObject(unresolvedPrintDiagnostic.Get("range"))
Local requestedPrintDiagnostics:TJSONArray = JsonArray()
requestedPrintDiagnostics.Append(unresolvedPrintDiagnostic)
responses = codeActionServer.HandlePayload(CodeActionPayload(86, missingImportUri, unresolvedPrintRange, requestedPrintDiagnostics, "quickfix"))
Local missingImportActions:TJSONArray = TJSONArray(ObjectFrom(responses[0]).Get("result"))
Check(missingImportActions.Size() = 1, "a uniquely installed unresolved value offers one missing-import quick fix")
Local importStandardIoAction:TJSONObject = TJSONObject(missingImportActions.Get(0))
Local missingImportEdits:TJSONArray = WorkspaceEditEdits(TJSONObject(importStandardIoAction.Get("edit")), missingImportUri)
Local missingImportEdit:TJSONObject = TJSONObject(missingImportEdits.Get(0))
Local missingImportEditStart:TJSONObject = TJSONObject(TJSONObject(missingImportEdit.Get("range")).Get("start"))
Check(importStandardIoAction.GetString("title") = "Import brl.standardio" And importStandardIoAction.GetBool("isPreferred"), "the BRL.StandardIO import is the preferred unresolved-Print quick fix")
Check(missingImportEdits.Size() = 1 And missingImportEdit.GetString("newText") = "~nImport brl.standardio" And missingImportEditStart.GetInteger("line") = 2, "the missing-import quick fix extends the existing import group")

Local bbdocServer:TBlitzMaxLspServer = NewTestServer()
bbdocServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:90,~qmethod~q:~qinitialize~q,~qparams~q:{~qcapabilities~q:{~qworkspace~q:{~qworkspaceEdit~q:{~qsnippetEditSupport~q:true}}}}}")
Local bbdocUri:String = "file:///tmp/generated-bbdoc.bmx"
Local bbdocSource:String = "SuperStrict~nType TSample~n~tField value:Int~n~tMethod Hello:String(x:Int, y:Int)~n~t~tReturn ~qok~q~n~tEnd Method~n~tMethod Reset()~n~tEnd Method~n~tMethod New(value:Int)~n~tEnd Method~nEnd Type~nStruct TValue~nEnd Struct~nInterface IThing~n~tMethod Run:Int(input:String)~nEnd Interface~nEnum TChoice~n~tFirst~nEnd Enum~nGlobal count:Int~nConst LIMIT:Int = 1~nLocal excluded:Int"
bbdocServer.HandlePayload(DidOpenPayload(bbdocUri, bbdocSource, 7))
Local bbdocActions:TJSONArray = CodeActionsAt(bbdocServer, 91, bbdocUri, 3, 8, "refactor")
Check(bbdocActions.Size() = 1, "a parent refactor filter includes generated bbdoc rewrites on a routine header")
Local helloBBDocAction:TJSONObject = TJSONObject(bbdocActions.Get(0))
Check(helloBBDocAction.GetString("title") = "Generate bbdoc for Method Hello" And helloBBDocAction.GetString("kind") = "refactor.rewrite.bbdoc", "generated routine bbdoc has a specific title and action kind")
Local helloDocumentEdit:TJSONObject = VersionedWorkspaceEdit(TJSONObject(helloBBDocAction.Get("edit")))
Local helloIdentifier:TJSONObject = TJSONObject(helloDocumentEdit.Get("textDocument"))
Local helloEdits:TJSONArray = TJSONArray(helloDocumentEdit.Get("edits"))
Local helloSnippetEdit:TJSONObject = TJSONObject(helloEdits.Get(0))
Local helloSnippet:TJSONObject = TJSONObject(helloSnippetEdit.Get("snippet"))
Check(helloIdentifier.GetString("uri") = bbdocUri And helloIdentifier.GetInteger("version") = 7 And helloEdits.Size() = 1, "generated bbdoc uses a versioned document edit")
Check(helloSnippet.GetString("kind") = "snippet" And helloSnippet.GetString("value") = "~tRem~n~tbbdoc: ${1:Summary of Hello.}~n~treturns: ${2:Description of the returned value.}~n~tparam: ${3:Description of x.}~n~tparam: ${4:Description of y.}~n~tEnd Rem~n$0", "routine bbdoc snippets provide contextual tab stops without an about section")
Local helloInsertStart:TJSONObject = TJSONObject(TJSONObject(helloSnippetEdit.Get("range")).Get("start"))
Check(helloInsertStart.GetInteger("line") = 3 And helloInsertStart.GetInteger("character") = 0, "generated bbdoc inserts before the declaration indentation")
Check(CodeActionsAt(bbdocServer, 92, bbdocUri, 4, 2).Size() = 0, "generated bbdoc is not offered from inside a routine body")
Check(CodeActionsAt(bbdocServer, 93, bbdocUri, 1, 2).Size() = 1, "type declarations offer summary documentation")
Local fieldActions:TJSONArray = CodeActionsAt(bbdocServer, 94, bbdocUri, 2, 5)
Local fieldDocumentEdit:TJSONObject = VersionedWorkspaceEdit(TJSONObject(TJSONObject(fieldActions.Get(0)).Get("edit")))
Local fieldSnippet:TJSONObject = TJSONObject(TJSONObject(TJSONArray(fieldDocumentEdit.Get("edits")).Get(0)).Get("snippet"))
Check(fieldSnippet.GetString("value") = "~tRem~n~tbbdoc: ${1:Summary of value.}~n~tEnd Rem~n$0", "fields receive a concise summary-only bbdoc snippet")
Local resetActions:TJSONArray = CodeActionsAt(bbdocServer, 95, bbdocUri, 6, 5)
Local resetDocumentEdit:TJSONObject = VersionedWorkspaceEdit(TJSONObject(TJSONObject(resetActions.Get(0)).Get("edit")))
Local resetSnippet:String = TJSONObject(TJSONObject(TJSONArray(resetDocumentEdit.Get("edits")).Get(0)).Get("snippet")).GetString("value")
Check(Not resetSnippet.Contains("returns:") And Not resetSnippet.Contains("param:") And resetSnippet.Contains("Summary of Reset."), "Void routines omit returns and parameter stubs")
Local constructorActions:TJSONArray = CodeActionsAt(bbdocServer, 96, bbdocUri, 8, 5)
Local constructorDocumentEdit:TJSONObject = VersionedWorkspaceEdit(TJSONObject(TJSONObject(constructorActions.Get(0)).Get("edit")))
Local constructorSnippet:String = TJSONObject(TJSONObject(TJSONArray(constructorDocumentEdit.Get("edits")).Get(0)).Get("snippet")).GetString("value")
Check(Not constructorSnippet.Contains("returns:") And constructorSnippet.Contains("Description of value."), "constructors omit returns while retaining parameter stubs")
Check(CodeActionsAt(bbdocServer, 97, bbdocUri, 11, 3).Size() = 1 And CodeActionsAt(bbdocServer, 98, bbdocUri, 13, 4).Size() = 1, "Struct and Interface declarations offer generated bbdoc")
Local interfaceMethodActions:TJSONArray = CodeActionsAt(bbdocServer, 99, bbdocUri, 14, 8)
Local interfaceMethodEdit:TJSONObject = VersionedWorkspaceEdit(TJSONObject(TJSONObject(interfaceMethodActions.Get(0)).Get("edit")))
Local interfaceMethodSnippet:String = TJSONObject(TJSONObject(TJSONArray(interfaceMethodEdit.Get("edits")).Get(0)).Get("snippet")).GetString("value")
Check(interfaceMethodSnippet.Contains("returns: ${2:Description of the returned value.}") And interfaceMethodSnippet.Contains("param: ${3:Description of input.}"), "abstract interface methods use resolved return and parameter documentation")
Check(CodeActionsAt(bbdocServer, 100, bbdocUri, 16, 3).Size() = 1 And CodeActionsAt(bbdocServer, 101, bbdocUri, 17, 3).Size() = 1, "Enum declarations and members offer generated bbdoc")
Check(CodeActionsAt(bbdocServer, 102, bbdocUri, 19, 2).Size() = 1 And CodeActionsAt(bbdocServer, 103, bbdocUri, 20, 2).Size() = 1, "Global and Const declarations offer generated bbdoc")
Check(CodeActionsAt(bbdocServer, 104, bbdocUri, 21, 2).Size() = 0, "Local declarations are excluded from generated API documentation")
Check(CodeActionsAt(bbdocServer, 105, bbdocUri, 3, 8, "quickfix").Size() = 0, "quick-fix-only requests exclude generated bbdoc refactorings")

Local existingBBDocUri:String = "file:///tmp/existing-bbdoc.bmx"
Local existingBBDocSource:String = "SuperStrict~nRem~nbbdoc:~nEnd Rem~nFunction Done()~nEnd Function~nRem~nordinary note~nEnd Rem~nFunction NeedsDocs()~nEnd Function"
bbdocServer.HandlePayload(DidOpenPayload(existingBBDocUri, existingBBDocSource))
Check(CodeActionsAt(bbdocServer, 106, existingBBDocUri, 4, 5).Size() = 0, "an attached empty bbdoc marker suppresses duplicate generation")
Check(CodeActionsAt(bbdocServer, 107, existingBBDocUri, 9, 5).Size() = 1, "an ordinary Rem block does not masquerade as bbdoc")

Local crlfBBDocUri:String = "file:///tmp/crlf-bbdoc.bmx"
bbdocServer.HandlePayload(DidOpenPayload(crlfBBDocUri, "SuperStrict~r~n  Function WindowsLine:Int(value:Int)~r~n  Return value~r~n  End Function"))
Local crlfActions:TJSONArray = CodeActionsAt(bbdocServer, 108, crlfBBDocUri, 1, 4)
Local crlfDocumentEdit:TJSONObject = VersionedWorkspaceEdit(TJSONObject(TJSONObject(crlfActions.Get(0)).Get("edit")))
Local crlfSnippet:String = TJSONObject(TJSONObject(TJSONArray(crlfDocumentEdit.Get("edits")).Get(0)).Get("snippet")).GetString("value")
Check(crlfSnippet.StartsWith("  Rem~r~n  bbdoc: ${1:Summary of WindowsLine.}~r~n") And crlfSnippet.Contains("  End Rem~r~n$0"), "generated bbdoc preserves declaration indentation and CRLF line endings")

Local strictBBDocUri:String = "file:///tmp/strict-bbdoc.bmx"
bbdocServer.HandlePayload(DidOpenPayload(strictBBDocUri, "Strict~nFunction LegacyDefault()~nReturn 1~nEnd Function"))
Local strictActions:TJSONArray = CodeActionsAt(bbdocServer, 111, strictBBDocUri, 1, 5)
Local strictDocumentEdit:TJSONObject = VersionedWorkspaceEdit(TJSONObject(TJSONObject(strictActions.Get(0)).Get("edit")))
Local strictSnippet:String = TJSONObject(TJSONObject(TJSONArray(strictDocumentEdit.Get("edits")).Get(0)).Get("snippet")).GetString("value")
Check(strictSnippet.Contains("returns:"), "Strict routines with an implicit Int return include a returns stub from semantic resolution")

Local inlineBBDocUri:String = "file:///tmp/inline-bbdoc.bmx"
bbdocServer.HandlePayload(DidOpenPayload(inlineBBDocUri, "SuperStrict~nFunction Inline:Int() Return 1 End Function"))
Check(CodeActionsAt(bbdocServer, 112, inlineBBDocUri, 1, 5).Size() = 1 And CodeActionsAt(bbdocServer, 113, inlineBBDocUri, 1, 27).Size() = 0, "same-line routine bodies do not count as declaration headers")

Local plainBBDocUri:String = "file:///tmp/plain-bbdoc.bmx"
codeActionServer.HandlePayload(DidOpenPayload(plainBBDocUri, "SuperStrict~nFunction Legacy:Int(value:Int)~nReturn value~nEnd Function", 3))
Local plainActions:TJSONArray = CodeActionsAt(codeActionServer, 109, plainBBDocUri, 1, 4)
Local plainDocumentEdit:TJSONObject = VersionedWorkspaceEdit(TJSONObject(TJSONObject(plainActions.Get(0)).Get("edit")))
Local plainEdit:TJSONObject = TJSONObject(TJSONArray(plainDocumentEdit.Get("edits")).Get(0))
Check(plainEdit.Get("snippet") = Null And plainEdit.GetString("newText") = "Rem~nbbdoc: ~nreturns: ~nparam: ~nEnd Rem~n", "clients without snippet edits receive a plain fill-in skeleton")

Local malformedBBDocUri:String = "file:///tmp/malformed-bbdoc.bmx"
bbdocServer.HandlePayload(DidOpenPayload(malformedBBDocUri, "SuperStrict~nFunction Broken:Int(value:"))
Check(CodeActionsAt(bbdocServer, 110, malformedBBDocUri, 1, 8) <> Null, "generated bbdoc remains safe for an incomplete declaration during live editing")

Local implicitConversionServer:TBlitzMaxLspServer = NewTestServer()
implicitConversionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:87,~qmethod~q:~qinitialize~q,~qparams~q:{}}")
Local implicitConversionUri:String = "file:///tmp/implicit-string-numeric.bmx"
Local implicitConversionSource:String = "SuperStrict~nType TBox<T>~nField value:T~nMethod New(value:T)~nSelf.value=value~nEnd Method~nEnd Type~nType TPair<A,B>~nField first:A~nField second:B~nEnd Type~nLocal box:TBox<Int>=New TBox<Int>(~qhello~q)~nLocal pair:TPair<String,TBox<Int>>~npair.second.value=~qhello~q"
responses = implicitConversionServer.HandlePayload(DidOpenPayload(implicitConversionUri, implicitConversionSource))
Local implicitConversionPublication:TJSONObject = ObjectFrom(responses[0])
Local implicitConversionParams:TJSONObject = TJSONObject(implicitConversionPublication.Get("params"))
Local implicitConversionDiagnostics:TJSONArray = TJSONArray(implicitConversionParams.Get("diagnostics"))
Check(FindProtocolDiagnostic(implicitConversionDiagnostics, "BMX3302") <> Null, "LSP publishes the rejected String argument for a closed generic constructor")
Check(FindProtocolDiagnostic(implicitConversionDiagnostics, "BMX3310") <> Null, "LSP publishes the rejected String assignment through a nested closed generic member")

responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/test.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\\nLocal value:Int =~q}}}")
Check(responses.length = 1, "open publishes diagnostics")
Local publication:TJSONObject = ObjectFrom(responses[0])
Check(publication.GetString("method") = "textDocument/publishDiagnostics", "diagnostic notification method")
Local publishParams:TJSONObject = TJSONObject(publication.Get("params"))
Local diagnostics:TJSONArray = TJSONArray(publishParams.Get("diagnostics"))
Check(diagnostics.Size() > 0, "invalid source has a parser diagnostic")
Check(server.documents.Count() = 1, "server tracks open document")
Check(server.documents.Get("file:///tmp/test.bmx").workspaceUri = "", "outside document uses ad-hoc context")
Local openAnalysis:TLanguageAnalysis = server.workspaces.adHoc.LatestAnalysis("file:///tmp/test.bmx")
Check(openAnalysis <> Null And openAnalysis.snapshot <> Null, "context retains the latest immutable document snapshot")

responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qworkspace/didChangeWorkspaceFolders~q,~qparams~q:{~qevent~q:{~qadded~q:[{~quri~q:~qfile:///tmp~q,~qname~q:~qtemporary~q}],~qremoved~q:[]}}}")
Check(responses.length = 1 And server.workspaces.Count() = 3, "workspace folder can be added and diagnostics refreshed")
Check(server.documents.Get("file:///tmp/test.bmx").workspaceUri = "file:///tmp", "open document is rerouted to added workspace")

responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qworkspace/didChangeWorkspaceFolders~q,~qparams~q:{~qevent~q:{~qadded~q:[],~qremoved~q:[{~quri~q:~qfile:///tmp~q,~qname~q:~qtemporary~q}]}}}")
Check(responses.length = 1 And server.workspaces.Count() = 2, "workspace folder can be removed and diagnostics refreshed")
Check(server.documents.Get("file:///tmp/test.bmx").workspaceUri = "", "open document returns to ad-hoc context")

Local previousGeneration:Int = server.workspaces.dependencyCache.generation
responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qworkspace/didChangeConfiguration~q,~qparams~q:{~qsettings~q:{~qblitzmax~q:{~qbuildMode~q:~qdebug~q,~quseDependencySnapshots~q:false},~qworkspaces~q:[{~quri~q:~qfile:///workspace~q,~qbuildMode~q:~qrelease~q}]}}}")
Check(responses.length = 1, "configuration change republishes open document diagnostics")
Check(server.workspaces.dependencyCache.generation = previousGeneration + 1, "configuration change replaces dependency cache generation")
Check(server.workspaces.adHoc.configuration.buildMode = "debug" And Not server.workspaces.adHoc.configuration.useDependencySnapshots, "default workspace configuration changes")
Check(server.workspaces.Get("file:///workspace").configuration.buildMode = "release", "workspace-specific configuration overrides defaults")
Check(server.workspaces.adHoc.LatestAnalysis("file:///tmp/test.bmx").snapshot = Null, "configuration change rebuilds analysis with new snapshot setting")

previousGeneration = server.workspaces.dependencyCache.generation
responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qworkspace/didChangeWatchedFiles~q,~qparams~q:{~qchanges~q:[{~quri~q:~qfile:///sdk/module.i~q,~qtype~q:2}]}}")
Check(responses.length = 1 And server.workspaces.dependencyCache.generation = previousGeneration + 1, "dependency change starts a new cache generation and republishes diagnostics")

responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didChange~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/test.bmx~q,~qversion~q:2},~qcontentChanges~q:[{~qtext~q:~qSuperStrict\nLocal value:Int = 1~q}]}}")
Check(responses.length = 1, "change republishes diagnostics")
Check(server.documents.Get("file:///tmp/test.bmx").version = 2, "server applies full change")

responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:20,~qmethod~q:~qtextDocument/hover~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/test.bmx~q},~qposition~q:{~qline~q:1,~qcharacter~q:6}}}")
Check(responses.length = 1, "hover request has one response")
Local hoverResponse:TJSONObject = ObjectFrom(responses[0])
Local hoverResult:TJSONObject = TJSONObject(hoverResponse.Get("result"))
Check(hoverResult <> Null, "hover over local returns a result")
Local hoverContents:TJSONObject = TJSONObject(hoverResult.Get("contents"))
Check(hoverContents <> Null, "hover result contains markup")
Check(hoverContents.GetString("kind") = "markdown" And hoverContents.GetString("value").Contains("Local value:Int"), "hover displays local symbol and type")
Local hoverRange:TJSONObject = TJSONObject(hoverResult.Get("range"))
Check(hoverRange <> Null, "hover result contains a range")
Local hoverStart:TJSONObject = TJSONObject(hoverRange.Get("start"))
Local hoverEnd:TJSONObject = TJSONObject(hoverRange.Get("end"))
Check(hoverStart.GetInteger("character") = 6 And hoverEnd.GetInteger("character") = 11, "hover returns identifier range")

responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:21,~qmethod~q:~qtextDocument/hover~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/test.bmx~q},~qposition~q:{~qline~q:1,~qcharacter~q:5}}}")
hoverResponse = ObjectFrom(responses[0])
Check(TJSONNull(hoverResponse.Get("result")) <> Null, "hover over whitespace returns null")

Local emojiBytes:Byte[] = [Byte($F0), Byte($9F), Byte($98), Byte($80)]
Local unicodeSource:TSourceText = TSourceText.Create(String.FromUTF8Bytes(emojiBytes, emojiBytes.length) + " value", "unicode.bmx")
Local unicodeOffset:Int = unicodeSource.text.Find("value")
Local unicodePosition:TJSONObject = TBlitzMaxLspHover.Utf16Position(unicodeSource, unicodeOffset)
Check(unicodePosition.GetInteger("character") = 3, "outbound hover position counts supplementary character as two UTF-16 units")
Check(TBlitzMaxLspHover.Utf16PositionOffset(unicodeSource, 0, 3) = unicodeOffset, "inbound UTF-16 position converts to language offset")

Local featureServer:TBlitzMaxLspServer = NewTestServer()
featureServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:30,~qmethod~q:~qinitialize~q,~qparams~q:{}}")
featureServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/features.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\nFunction Add:Int(left:Int, right:Int)\nReturn left + right\nEnd Function\nLocal value:Int = Add(1, 2)\nLocal copy:Int = value~q}}}")

responses = featureServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:31,~qmethod~q:~qtextDocument/definition~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/features.bmx~q},~qposition~q:{~qline~q:4,~qcharacter~q:18}}}")
Local definitionResponse:TJSONObject = ObjectFrom(responses[0])
Local definitionResult:TJSONObject = TJSONObject(definitionResponse.Get("result"))
Check(definitionResult <> Null And definitionResult.GetString("uri") = "file:///tmp/features.bmx", "definition returns source declaration location")
Local definitionRange:TJSONObject = TJSONObject(definitionResult.Get("range"))
Local definitionStart:TJSONObject = TJSONObject(definitionRange.Get("start"))
Check(definitionStart.GetInteger("line") = 1 And definitionStart.GetInteger("character") = 9, "definition selects routine name")

responses = featureServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:32,~qmethod~q:~qtextDocument/definition~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/features.bmx~q},~qposition~q:{~qline~q:4,~qcharacter~q:12}}}")
definitionResponse = ObjectFrom(responses[0])
Check(TJSONNull(definitionResponse.Get("result")) <> Null, "definition never navigates to compiler interface symbols")

responses = featureServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:36,~qmethod~q:~qtextDocument/typeDefinition~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/features.bmx~q},~qposition~q:{~qline~q:4,~qcharacter~q:7}}}")
Local builtinTypeDefinitionResponse:TJSONObject = ObjectFrom(responses[0])
Check(TJSONNull(builtinTypeDefinitionResponse.Get("result")) <> Null, "go to type definition never exposes a raw compiler-interface location")

responses = featureServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:33,~qmethod~q:~qtextDocument/documentSymbol~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/features.bmx~q}}}")
Local symbolsResponse:TJSONObject = ObjectFrom(responses[0])
Local documentSymbols:TJSONArray = TJSONArray(symbolsResponse.Get("result"))
Check(documentSymbols.Size() = 3, "document symbols expose routine and top-level variables")
Check(TJSONObject(documentSymbols.Get(0)).GetString("name") = "Add", "document symbols preserve declaration order")
Local incompleteEnumSymbolUri:String = "file:///tmp/incomplete-enum-rem.bmx"
featureServer.HandlePayload(DidOpenPayload(incompleteEnumSymbolUri, "SuperStrict~nEnum ETest~n~tRem~n~tOne~n~tTwo~n~tThree~nEnd Enum"))
responses = featureServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:330,~qmethod~q:~qtextDocument/documentSymbol~q,~qparams~q:{~qtextDocument~q:{~quri~q:~q" + incompleteEnumSymbolUri + "~q}}}")
Local incompleteEnumSymbolsResponse:TJSONObject = ObjectFrom(responses[0])
Local incompleteEnumSymbols:TJSONArray = TJSONArray(incompleteEnumSymbolsResponse.Get("result"))
Check(incompleteEnumSymbols.Size() = 1 And TJSONObject(incompleteEnumSymbols.Get(0)).GetString("name") = "ETest", "unfinished Rem keeps the surrounding enum in the document outline")
Check(DocumentSymbolRangesValid(incompleteEnumSymbols), "document-symbol selection ranges remain contained during unfinished Rem editing")

responses = featureServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:34,~qmethod~q:~qtextDocument/documentHighlight~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/features.bmx~q},~qposition~q:{~qline~q:4,~qcharacter~q:6}}}")
Local highlightsResponse:TJSONObject = ObjectFrom(responses[0])
Local highlights:TJSONArray = TJSONArray(highlightsResponse.Get("result"))
Check(highlights.Size() = 2, "document highlights include declaration and reference")

responses = featureServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:35,~qmethod~q:~qtextDocument/signatureHelp~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/features.bmx~q},~qposition~q:{~qline~q:4,~qcharacter~q:25}}}")
Local signatureResponse:TJSONObject = ObjectFrom(responses[0])
Local signatureResult:TJSONObject = TJSONObject(signatureResponse.Get("result"))
Check(signatureResult <> Null And signatureResult.GetInteger("activeParameter") = 1, "signature help selects active parameter")
Local signatures:TJSONArray = TJSONArray(signatureResult.Get("signatures"))
Check(TJSONObject(signatures.Get(0)).GetString("label").Contains("Function Add:Int(left:Int, right:Int)"), "signature help displays resolved routine")

Local hierarchyServer:TBlitzMaxLspServer = NewTestServer()
hierarchyServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:60,~qmethod~q:~qinitialize~q,~qparams~q:{}}")
hierarchyServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/hierarchy.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\nInterface IRoot\nEnd Interface\nType TParent Implements IRoot\nEnd Type\nType TLeaf Extends TParent\nEnd Type\nLocal parent:TParent = New TParent~q}}}")
responses = hierarchyServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:61,~qmethod~q:~qtextDocument/prepareTypeHierarchy~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/hierarchy.bmx~q},~qposition~q:{~qline~q:3,~qcharacter~q:7}}}")
Local hierarchyPrepareResponse:TJSONObject = ObjectFrom(responses[0])
Local hierarchyPrepareItems:TJSONArray = TJSONArray(hierarchyPrepareResponse.Get("result"))
Local hierarchyParentItem:TJSONObject = FindHierarchyItem(hierarchyPrepareItems, "TParent")
Check(hierarchyParentItem <> Null, "prepareTypeHierarchy round-trips through JSON-RPC")
responses = hierarchyServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:62,~qmethod~q:~qtypeHierarchy/supertypes~q,~qparams~q:{~qitem~q:" + hierarchyParentItem.SaveString(JSON_COMPACT) + "}}")
Local hierarchySuperResponse:TJSONObject = ObjectFrom(responses[0])
Check(FindHierarchyItem(TJSONArray(hierarchySuperResponse.Get("result")), "IRoot") <> Null, "typeHierarchy/supertypes round-trips through JSON-RPC")
responses = hierarchyServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:63,~qmethod~q:~qtypeHierarchy/subtypes~q,~qparams~q:{~qitem~q:" + hierarchyParentItem.SaveString(JSON_COMPACT) + "}}")
Local hierarchySubResponse:TJSONObject = ObjectFrom(responses[0])
Check(FindHierarchyItem(TJSONArray(hierarchySubResponse.Get("result")), "TLeaf") <> Null, "typeHierarchy/subtypes round-trips through JSON-RPC")
responses = hierarchyServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:64,~qmethod~q:~qtextDocument/typeDefinition~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/hierarchy.bmx~q},~qposition~q:{~qline~q:7,~qcharacter~q:8}}}")
Local typeDefinitionResponse:TJSONObject = ObjectFrom(responses[0])
Local typeDefinitionResult:TJSONObject = TJSONObject(typeDefinitionResponse.Get("result"))
Local typeDefinitionStart:TJSONObject = TJSONObject(TJSONObject(typeDefinitionResult.Get("range")).Get("start"))
Check(typeDefinitionResult.GetString("uri") = "file:///tmp/hierarchy.bmx" And typeDefinitionStart.GetInteger("line") = 3 And typeDefinitionStart.GetInteger("character") = 5, "textDocument/typeDefinition round-trips through JSON-RPC")

Local completionServer:TBlitzMaxLspServer = NewTestServer()
completionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:40,~qmethod~q:~qinitialize~q,~qparams~q:{}}")
completionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/completion.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\nType TBase\nField inherited:Int\nMethod BaseMethod:Int()\nEnd Method\nEnd Type\nType TOverload Extends TBase\nMethod New(amount:Int)\nEnd Method\nField value:Int\nMethod Calc:Int(amount:Int)\nEnd Method\nMethod Calc:Int(left:Int, right:Int)\nEnd Method\nFunction Create:TOverload()\nEnd Function\nEnd Type\nLocal t := New TOverload(1)\nt.\nTOverload.\nt.Ca\nPrint t.~q}}}")
responses = completionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:41,~qmethod~q:~qtextDocument/completion~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/completion.bmx~q},~qposition~q:{~qline~q:18,~qcharacter~q:2},~qcontext~q:{~qtriggerKind~q:2,~qtriggerCharacter~q:~q.~q}}}")
Local completionResponse:TJSONObject = ObjectFrom(responses[0])
Local completionItems:TJSONArray = TJSONArray(completionResponse.Get("result"))
Check(CompletionItemCount(completionItems, "Calc") = 2, "instance completion preserves overload signatures")
Check(FindCompletionItem(completionItems, "value") <> Null And FindCompletionItem(completionItems, "value").GetInteger("kind") = 5, "instance completion includes fields")
Check(FindCompletionItem(completionItems, "BaseMethod") <> Null And FindCompletionItem(completionItems, "inherited") <> Null, "instance completion includes inherited members")
Check(FindCompletionItem(completionItems, "Create") = Null, "instance completion excludes type functions")
Check(FindCompletionItem(completionItems, "New") = Null, "instance completion excludes constructors")
Local unresolvedCalcItem:TJSONObject = FindCompletionItem(completionItems, "Calc")
Local oneArgumentCalc:TJSONObject = FindCompletionItemWithLabelDetail(completionItems, "Calc", "(amount:Int)")
Local twoArgumentCalc:TJSONObject = FindCompletionItemWithLabelDetail(completionItems, "Calc", "(left:Int, right:Int)")
Check(oneArgumentCalc <> Null And twoArgumentCalc <> Null, "overloaded completion items expose distinct parameter label details")
Check(oneArgumentCalc.GetString("label") = "Calc" And oneArgumentCalc.GetString("insertText") = "Calc" And TJSONObject(oneArgumentCalc.Get("labelDetails")).GetString("description") = ":Int", "completion label details preserve the bare label and insertion text while displaying the return type")
responses = completionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:45,~qmethod~q:~qcompletionItem/resolve~q,~qparams~q:" + unresolvedCalcItem.SaveString(JSON_COMPACT) + "}")
Local resolvedCompletionResponse:TJSONObject = ObjectFrom(responses[0])
Local resolvedCompletionItem:TJSONObject = TJSONObject(resolvedCompletionResponse.Get("result"))
Check(resolvedCompletionItem.GetString("label") = "Calc", "completionItem/resolve round-trips a server completion item")
Check(TJSONObject(resolvedCompletionItem.Get("labelDetails")).GetString("detail") = TJSONObject(unresolvedCalcItem.Get("labelDetails")).GetString("detail"), "completionItem/resolve preserves overload label details")
responses = completionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:42,~qmethod~q:~qtextDocument/completion~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/completion.bmx~q},~qposition~q:{~qline~q:19,~qcharacter~q:10}}}")
completionResponse = ObjectFrom(responses[0])
completionItems = TJSONArray(completionResponse.Get("result"))
Check(FindCompletionItem(completionItems, "Create") <> Null And FindCompletionItem(completionItems, "Create").GetInteger("kind") = 3, "type completion includes type functions")
Check(FindCompletionItem(completionItems, "Calc") = Null And FindCompletionItem(completionItems, "value") = Null, "type completion excludes instance members")
Check(FindCompletionItem(completionItems, "New") = Null, "type completion excludes constructors")
responses = completionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:43,~qmethod~q:~qtextDocument/completion~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/completion.bmx~q},~qposition~q:{~qline~q:20,~qcharacter~q:4}}}")
completionResponse = ObjectFrom(responses[0])
completionItems = TJSONArray(completionResponse.Get("result"))
Check(CompletionItemCount(completionItems, "Calc") = 2, "completion remains available while a member prefix is incomplete")
Local prefixedCalcCompletion:TJSONObject = FindCompletionItem(completionItems, "Calc")
Local prefixedCalcEdit:TJSONObject = TJSONObject(prefixedCalcCompletion.Get("textEdit"))
Local prefixedCalcRange:TJSONObject = TJSONObject(prefixedCalcEdit.Get("range"))
Check(prefixedCalcCompletion.GetString("filterText") = "Calc" And prefixedCalcEdit.GetString("newText") = "Calc" And TJSONObject(prefixedCalcRange.Get("start")).GetInteger("character") = 2 And TJSONObject(prefixedCalcRange.Get("end")).GetInteger("character") = 4, "member completion replaces the prefix after the receiver dot")
Check(prefixedCalcCompletion.GetString("sortText").Compare(FindCompletionItem(completionItems, "BaseMethod").GetString("sortText"), True) < 0, "member completion ranks prefix matches ahead of non-matches while retaining inherited members")
responses = completionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:46,~qmethod~q:~qtextDocument/completion~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/completion.bmx~q},~qposition~q:{~qline~q:21,~qcharacter~q:8},~qcontext~q:{~qtriggerKind~q:2,~qtriggerCharacter~q:~q.~q}}}")
completionResponse = ObjectFrom(responses[0])
completionItems = TJSONArray(completionResponse.Get("result"))
Check(CompletionItemCount(completionItems, "Calc") = 2 And FindCompletionItem(completionItems, "BaseMethod") <> Null, "member completion recovers a typed receiver inside a parenthesis-free call argument")
Local literalCompletionServer:TBlitzMaxLspServer = NewTestServer()
literalCompletionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:47,~qmethod~q:~qinitialize~q,~qparams~q:{}}")
literalCompletionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/literal-completion.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\nFramework BRL.StandardIO\nImport BRL.Path\n\~qhello\~q.\nPrint(\~qnested\~q.\nLocal path:TPath = TPath.FromString(\~qfile.txt\~q.)~q}}}")
responses = literalCompletionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:48,~qmethod~q:~qtextDocument/completion~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/literal-completion.bmx~q},~qposition~q:{~qline~q:3,~qcharacter~q:8},~qcontext~q:{~qtriggerKind~q:2,~qtriggerCharacter~q:~q.~q}}}")
completionResponse = ObjectFrom(responses[0])
completionItems = TJSONArray(completionResponse.Get("result"))
Check(FindCompletionItem(completionItems, "Trim") <> Null And FindCompletionItem(completionItems, "Trim").GetInteger("kind") = 2 And FindCompletionItem(completionItems, "ToLower") <> Null And FindCompletionItem(completionItems, "ToLower").GetInteger("kind") = 2, "member completion recovers the intrinsic String type of a literal receiver")
responses = literalCompletionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:49,~qmethod~q:~qtextDocument/completion~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/literal-completion.bmx~q},~qposition~q:{~qline~q:4,~qcharacter~q:15},~qcontext~q:{~qtriggerKind~q:2,~qtriggerCharacter~q:~q.~q}}}")
completionResponse = ObjectFrom(responses[0])
completionItems = TJSONArray(completionResponse.Get("result"))
Check(FindCompletionItem(completionItems, "Trim") <> Null And FindCompletionItem(completionItems, "Trim").GetInteger("kind") = 2 And FindCompletionItem(completionItems, "ToLower") <> Null And FindCompletionItem(completionItems, "ToLower").GetInteger("kind") = 2, "member completion recovers a String literal receiver inside an unfinished call")
responses = literalCompletionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:50,~qmethod~q:~qtextDocument/completion~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/literal-completion.bmx~q},~qposition~q:{~qline~q:5,~qcharacter~q:47},~qcontext~q:{~qtriggerKind~q:2,~qtriggerCharacter~q:~q.~q}}}")
completionResponse = ObjectFrom(responses[0])
completionItems = TJSONArray(completionResponse.Get("result"))
Check(FindCompletionItem(completionItems, "Trim") <> Null And FindCompletionItem(completionItems, "Trim").GetInteger("kind") = 2 And FindCompletionItem(completionItems, "ToLower") <> Null And FindCompletionItem(completionItems, "ToLower").GetInteger("kind") = 2, "member completion recovers a String literal receiver inside a typed initializer call")
Local builtinTypeCompletionServer:TBlitzMaxLspServer = NewTestServer()
builtinTypeCompletionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:51,~qmethod~q:~qinitialize~q,~qparams~q:{}}")
builtinTypeCompletionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/builtin-type-completion.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\nFramework BRL.StandardIO\nLocal t:String = String.~q}}}")
responses = builtinTypeCompletionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:52,~qmethod~q:~qtextDocument/completion~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/builtin-type-completion.bmx~q},~qposition~q:{~qline~q:2,~qcharacter~q:24},~qcontext~q:{~qtriggerKind~q:2,~qtriggerCharacter~q:~q.~q}}}")
completionResponse = ObjectFrom(responses[0])
completionItems = TJSONArray(completionResponse.Get("result"))
Check(FindCompletionItem(completionItems, "FromInt") <> Null And FindCompletionItem(completionItems, "FromInt").GetInteger("kind") = 3, "built-in String type completion includes compiler-provided type functions")
Check(FindCompletionItem(completionItems, "Trim") = Null, "built-in String type completion excludes instance methods")
Check(FindCompletionItem(completionItems, "Print") = Null, "built-in String type completion does not fall back to unrelated visible symbols")

responses = completionServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:44,~qmethod~q:~qtextDocument/semanticTokens/full~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/completion.bmx~q}}}")
Local semanticResponse:TJSONObject = ObjectFrom(responses[0])
Local semanticResult:TJSONObject = TJSONObject(semanticResponse.Get("result"))
Local semanticData:TJSONArray = TJSONArray(semanticResult.Get("data"))
Check(semanticData <> Null And semanticData.Size() > 0 And semanticData.Size() Mod 5 = 0, "semantic tokens use the LSP five-integer encoding")
Check(HasSemanticToken(semanticData, 6, 5, 9, 0, 1), "Type declaration is classified as a declared class")
Check(HasSemanticToken(semanticData, 9, 6, 5, 7, 1), "field declaration is classified as a declared property")
Check(HasSemanticToken(semanticData, 10, 7, 4, 10, 1), "method declaration is classified as a declared method")
Check(HasSemanticToken(semanticData, 10, 16, 6, 5, 1), "routine parameter is classified as a declared parameter")
Check(HasSemanticToken(semanticData, 14, 9, 6, 9, 5), "type function carries declaration and static modifiers")
Check(HasSemanticToken(semanticData, 17, 6, 1, 6, 1), "local declaration is classified as a declared variable")
Check(HasSemanticToken(semanticData, 17, 15, 9, 0), "the initializer type of an inferred Local is classified semantically")
Check(HasSemanticToken(semanticData, 18, 0, 1, 6), "local reference is classified independently of its declaration")

Local inlayServer:TBlitzMaxLspServer = NewTestServer()
inlayServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:50,~qmethod~q:~qinitialize~q,~qparams~q:{}}")
inlayServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/inlay.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\nFunction Format:String(value:Int, width:Int)\nReturn \\qok\\q\nEnd Function\nLocal count := 1\nLocal text := Format(1, 20)\nLocal value:Int = 1\nLocal width:Int = 2\nLocal same := Format(value, width)\nStruct b2Vec2\nMethod New(x:Float, y:Float)\nEnd Method\nEnd Struct\nLocal vec := New b2Vec2(1.0, 2.0)~q}}}")
responses = inlayServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:51,~qmethod~q:~qtextDocument/inlayHint~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/inlay.bmx~q},~qrange~q:{~qstart~q:{~qline~q:4,~qcharacter~q:0},~qend~q:{~qline~q:6,~qcharacter~q:0}}}}")
Local inlayResponse:TJSONObject = ObjectFrom(responses[0])
Local inlayHints:TJSONArray = TJSONArray(inlayResponse.Get("result"))
Check(FindInlayHint(inlayHints, 4, 11, ": Int", 1) <> Null, "inlay hints show an inferred local type")
Check(FindInlayHint(inlayHints, 5, 10, ": String", 1) <> Null, "inlay hints use the resolved call return type")
Local valueHint:TJSONObject = FindInlayHint(inlayHints, 5, 21, "value:", 2)
Local widthHint:TJSONObject = FindInlayHint(inlayHints, 5, 24, "width:", 2)
Check(valueHint <> Null And valueHint.GetBool("paddingRight") And widthHint <> Null And widthHint.GetBool("paddingRight"), "inlay hints label resolved call parameters")
Check(InlayTooltip(valueHint) = "`value: Int`" And InlayTooltip(FindInlayHint(inlayHints, 5, 10, ": String", 1)) = "Inferred type: `String`", "inlay hints expose compact semantic type tooltips")
responses = inlayServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:52,~qmethod~q:~qtextDocument/inlayHint~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/inlay.bmx~q},~qrange~q:{~qstart~q:{~qline~q:8,~qcharacter~q:0},~qend~q:{~qline~q:8,~qcharacter~q:100}}}}")
inlayResponse = ObjectFrom(responses[0])
inlayHints = TJSONArray(inlayResponse.Get("result"))
Check(FindInlayHint(inlayHints, 8, 10, ": String", 1) <> Null, "inlay hint requests respect the requested range")
Check(FindInlayHint(inlayHints, 8, 21, "value:", 2) = Null And FindInlayHint(inlayHints, 8, 28, "width:", 2) = Null, "parameter hints are suppressed when argument names already match")
responses = inlayServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:53,~qmethod~q:~qtextDocument/inlayHint~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/inlay.bmx~q},~qrange~q:{~qstart~q:{~qline~q:13,~qcharacter~q:0},~qend~q:{~qline~q:13,~qcharacter~q:100}}}}")
inlayResponse = ObjectFrom(responses[0])
inlayHints = TJSONArray(inlayResponse.Get("result"))
Check(FindInlayHint(inlayHints, 13, 24, "x:", 2) <> Null And FindInlayHint(inlayHints, 13, 29, "y:", 2) <> Null, "constructor arguments receive parameter inlay hints")

Local genericInlayDocument:TLspDocument = New TLspDocument
genericInlayDocument.uri = "file:///tmp/generic-inlay.bmx"
genericInlayDocument.path = "/tmp/generic-inlay.bmx"
genericInlayDocument.text = "SuperStrict~nInterface IValue~nEnd Interface~nStruct SValue~nEnd Struct~nInterface IProvider<T>~nMethod Provide:T(value:T)~nEnd Interface~nType TBox<T>~nMethod Describe:T(value:T, values:Int[], objectValue:Object, interfaceValue:IValue, structValue:SValue, callback:Closure<T(input:T)>)~nReturn value~nEnd Method~nMethod Echo:T(input:T)~nReturn input~nEnd Method~nEnd Type~nType TDerived<T> Extends TBox<T>~nEnd Type~nType TPair<A, B>~nField second:B~nEnd Type~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nLocal box:TBox<String>~nLocal pair:TPair<String, TBox<Int>>~nLocal inherited:TDerived<Long>~nLocal provider:IProvider<String>~nLocal arr:Int[]~nLocal obj:Object~nLocal iface:IValue~nLocal item:SValue~nLocal handler:Closure<String(input:String)>~nLocal described := box.Describe(~qtext~q, arr, obj, iface, item, handler)~nLocal nested := pair.second.Echo(1)~nLocal inheritedValue := inherited.Echo(1)~nLocal interfaceValue := provider.Provide(~qtext~q)~nLocal routineValue := Identity(~qtext~q)"
firstContext.Analyze(genericInlayDocument)
Local genericInlayHints:TJSONArray = TJSONArray(TBlitzMaxLspInlayHints.Query(genericInlayDocument, firstContext, Null))
Check(FindInlayHint(genericInlayHints, 33, 15, ": String", 1) <> Null And FindInlayHint(genericInlayHints, 34, 12, ": Int", 1) <> Null And FindInlayHint(genericInlayHints, 35, 20, ": Long", 1) <> Null, "inferred type hints carry direct, nested, and inherited generic substitutions")
Check(FindInlayHint(genericInlayHints, 36, 20, ": String", 1) <> Null And FindInlayHint(genericInlayHints, 37, 18, ": String", 1) <> Null, "inferred type hints carry generic Interface and routine inference results")
Local genericValueHint:TJSONObject = FindInlayHint(genericInlayHints, 33, 32, "value:", 2)
Check(InlayTooltip(genericValueHint).Contains("`value: String`") And InlayTooltip(genericValueHint).Contains("Declared as: `value: T`"), "generic parameter hints show the instantiated type and retain the original declaration")
Check(InlayTooltip(FindInlayHint(genericInlayHints, 33, 40, "values:", 2)) = "`values: Int[]`" And InlayTooltip(FindInlayHint(genericInlayHints, 33, 45, "objectValue:", 2)) = "`objectValue: Object`", "parameter hint tooltips render Array and Object types")
Check(InlayTooltip(FindInlayHint(genericInlayHints, 33, 50, "interfaceValue:", 2)) = "`interfaceValue: IValue`" And InlayTooltip(FindInlayHint(genericInlayHints, 33, 57, "structValue:", 2)) = "`structValue: SValue`", "parameter hint tooltips render Interface and Struct types")
Local genericCallbackHint:TJSONObject = FindInlayHint(genericInlayHints, 33, 63, "callback:", 2)
Check(InlayTooltip(genericCallbackHint).Contains("`callback: Closure<String(input:String)>`") And InlayTooltip(genericCallbackHint).Contains("Declared as: `callback: Closure<T(input:T)>`"), "parameter hint tooltips substitute nested Closure types")
Check(InlayTooltip(FindInlayHint(genericInlayHints, 34, 33, "input:", 2)).Contains("`input: Int`") And InlayTooltip(FindInlayHint(genericInlayHints, 35, 39, "input:", 2)).Contains("`input: Long`"), "nested and inherited generic calls use their constructed parameter types")
Check(InlayTooltip(FindInlayHint(genericInlayHints, 36, 41, "value:", 2)).Contains("`value: String`") And InlayTooltip(FindInlayHint(genericInlayHints, 37, 31, "value:", 2)).Contains("`value: String`"), "Interface and routine-generic calls expose inferred parameter types")
Local malformedGenericInlayDocument:TLspDocument = New TLspDocument
malformedGenericInlayDocument.uri = "file:///tmp/malformed-generic-inlay.bmx"
malformedGenericInlayDocument.path = "/tmp/malformed-generic-inlay.bmx"
malformedGenericInlayDocument.text = "SuperStrict~nType TBox<T>~nMethod Echo:T(input:T)~nReturn input~nEnd Method~nEnd Type~nLocal box:TBox<String>~nbox.Echo("
firstContext.Analyze(malformedGenericInlayDocument)
Local malformedGenericHints:TJSONArray = TJSONArray(TBlitzMaxLspInlayHints.Query(malformedGenericInlayDocument, firstContext, Null))
Check(malformedGenericHints <> Null And FindInlayHint(malformedGenericHints, 7, 9, "input:", 2) = Null, "inlay hint requests tolerate an incomplete generic call without inventing a parameter hint")
responses = inlayServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:54,~qmethod~q:~qtextDocument/hover~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/inlay.bmx~q},~qposition~q:{~qline~q:13,~qcharacter~q:18}}}")
Local constructorHoverResponse:TJSONObject = ObjectFrom(responses[0])
Local constructorHover:TJSONObject = TJSONObject(constructorHoverResponse.Get("result"))
Check(constructorHover <> Null And TJSONObject(constructorHover.Get("contents")).GetString("value").Contains("Method New(x:Float, y:Float)"), "hover over a constructed type displays the selected constructor overload")

responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didClose~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/test.bmx~q}}}")
Check(responses.length = 1 And server.documents.Count() = 0, "close clears diagnostics and state")

' Open source overlays are keyed by canonical path, not basename. An importer
' sees unsaved declarations from its exact quoted dependency and is refreshed
' when that dependency changes or closes.
Local liveServer:TBlitzMaxLspServer = NewTestServer()
liveServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:10,~qmethod~q:~qinitialize~q,~qparams~q:{~qworkspaceFolders~q:[{~quri~q:~qfile:///workspace~q,~qname~q:~qlive~q}]}}")
liveServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///other/helper.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\nFunction WrongValue:Int()\nReturn 2\nEnd Function~q}}}")
liveServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///workspace/helper-part.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qFunction PartValue:Int()\nReturn 4\nEnd Function~q}}}")
responses = liveServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///workspace/main.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\nImport \~qhelper.bmx\~q\nLocal result:Int = LiveValue() + PartValue()~q}}}")
Check(responses.length = 1, "opening importer publishes its diagnostics")
responses = liveServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///workspace/helper.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\nInclude \~qhelper-part.bmx\~q\nFunction LiveValue:Int()\nReturn 1\nEnd Function~q}}}")
Check(responses.length = 3, "opening a missing dependency republishes its importer and newly contextualized transitive include")
Local liveMain:TLanguageAnalysis = liveServer.workspaces.Get("file:///workspace").LatestAnalysis("file:///workspace/main.bmx")
Local liveScope:TScope = liveMain.model.ImportedScope("helper.bmx")
Check(liveScope <> Null And liveScope.LookupLocal("LiveValue").length = 1, "quoted import uses exact open source buffer")
Check(liveScope.LookupLocal("WrongValue").length = 0, "same basename in another directory is not confused with dependency")
Check(liveScope.LookupLocal("PartValue").length = 1 And liveScope.LookupLocal("PartValue")[0].originPath = "/workspace/helper-part.bmx", "live interface includes declarations with their own source path")
responses = liveServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:36,~qmethod~q:~qtextDocument/definition~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///workspace/main.bmx~q},~qposition~q:{~qline~q:2,~qcharacter~q:20}}}")
definitionResponse = ObjectFrom(responses[0])
definitionResult = TJSONObject(definitionResponse.Get("result"))
Check(definitionResult <> Null And definitionResult.GetString("uri") = "file:///workspace/helper.bmx", "definition follows the exact live imported source")
definitionRange = TJSONObject(definitionResult.Get("range"))
definitionStart = TJSONObject(definitionRange.Get("start"))
Check(definitionStart.GetInteger("line") = 2 And definitionStart.GetInteger("character") = 9, "cross-file definition selects the imported routine name")

responses = liveServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didChange~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///workspace/helper-part.bmx~q,~qversion~q:2},~qcontentChanges~q:[{~qtext~q:~qFunction UpdatedPart:Int()\nReturn 5\nEnd Function~q}]}}")
Check(responses.length = 3, "changing transitive included dependency republishes all affected open documents")
liveMain = liveServer.workspaces.Get("file:///workspace").LatestAnalysis("file:///workspace/main.bmx")
liveScope = liveMain.model.ImportedScope("helper.bmx")
Check(liveScope.LookupLocal("UpdatedPart").length = 1 And liveScope.LookupLocal("PartValue").length = 0, "importer receives transitive included source change")

responses = liveServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didChange~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///workspace/helper.bmx~q,~qversion~q:2},~qcontentChanges~q:[{~qtext~q:~qSuperStrict\nFunction UpdatedValue:Int()\nReturn 3\nEnd Function~q}]}}")
Check(responses.length = 3, "changing dependency republishes its importer and a transitive include detached by the edit")
liveMain = liveServer.workspaces.Get("file:///workspace").LatestAnalysis("file:///workspace/main.bmx")
liveScope = liveMain.model.ImportedScope("helper.bmx")
Check(liveScope.LookupLocal("UpdatedValue").length = 1 And liveScope.LookupLocal("LiveValue").length = 0, "importer receives unsaved dependency change")

responses = liveServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didClose~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///workspace/helper.bmx~q}}}")
Check(responses.length = 2, "closing dependency clears it and republishes importer")
liveMain = liveServer.workspaces.Get("file:///workspace").LatestAnalysis("file:///workspace/main.bmx")
Local missingClosedInterface:Int
For Local snapshotDiagnostic:TSnapshotDiagnostic = EachIn liveMain.snapshot.diagnostics
	If snapshotDiagnostic.code = "BMX4003" And snapshotDiagnostic.message.Contains("helper.bmx") Then missingClosedInterface = True
Next
Check(missingClosedInterface, "closed dependency falls back to compiler interface")

liveServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///workspace/include-main.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\nInclude \~qshared.bmx\~q\nLocal included:Int = SharedLive~q}}}")
responses = liveServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///workspace/shared.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qConst SharedLive:Int = 1~q}}}")
Check(responses.length = 2, "opening a missing include republishes its existing includer")
Local includeAnalysis:TLanguageAnalysis = liveServer.workspaces.Get("file:///workspace").LatestAnalysis("file:///workspace/include-main.bmx")
Check(includeAnalysis.model.globalScope.LookupLocal("SharedLive").length = 1, "include uses unsaved open source buffer")
responses = liveServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didChange~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///workspace/shared.bmx~q,~qversion~q:2},~qcontentChanges~q:[{~qtext~q:~qConst SharedUpdated:Int = 2~q}]}}")
Check(responses.length = 2, "changing included source republishes includer")
includeAnalysis = liveServer.workspaces.Get("file:///workspace").LatestAnalysis("file:///workspace/include-main.bmx")
Check(includeAnalysis.model.globalScope.LookupLocal("SharedUpdated").length = 1 And includeAnalysis.model.globalScope.LookupLocal("SharedLive").length = 0, "includer receives unsaved source change")

' An included document becomes a file-local view over the known root
' compilation unit. Membership follows recursive Include edges, while an
' unrelated standalone document retains its original one-file analysis.
Local unitDirectory:String = "/tmp/blitzmax-lsp-include-unit-test"
DeleteDir(unitDirectory, True)
CreateDir(unitDirectory, True)
Local unitRootPath:String = unitDirectory + "/root.bmx"
Local unitMiddlePath:String = unitDirectory + "/middle.bmx"
Local unitLeafPath:String = unitDirectory + "/leaf.bmx"
Local unitStandalonePath:String = unitDirectory + "/standalone.bmx"
Local unitRootSource:String = "SuperStrict~nFunction RootValue:Int()~nReturn 1~nEnd Function~nInclude ~qmiddle.bmx~q"
Local unitMiddleSource:String = "Function MiddleValue:Int()~nReturn 2~nEnd Function~nInclude ~qleaf.bmx~q"
Local unitLeafSource:String = "Function LeafValue:Int()~nReturn RootValue() + MiddleValue()~nEnd Function~nFunction IncludedProcedure()~nEnd Function"
Local unitStandaloneSource:String = "SuperStrict~nLocal standalone:Int = 1"
SaveText(unitRootSource, unitRootPath)
SaveText(unitMiddleSource, unitMiddlePath)
SaveText(unitLeafSource, unitLeafPath)
SaveText(unitStandaloneSource, unitStandalonePath)
Local unitServer:TBlitzMaxLspServer = NewTestServer()
unitServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:90,~qmethod~q:~qinitialize~q,~qparams~q:{~qworkspaceFolders~q:[{~quri~q:~qfile://" + unitDirectory + "~q,~qname~q:~qinclude-unit~q}]}}")
responses = unitServer.HandlePayload(DidOpenPayload("file://" + unitLeafPath, unitLeafSource))
Check(responses.length = 1, "an included source opened before its root is initially analysed as a standalone file")
Local unitWorkspace:TLspWorkspaceContext = unitServer.workspaces.Get("file://" + unitDirectory)
Check(unitWorkspace.CompilationRootForPath(unitLeafPath) = "", "standalone analysis does not guess an including root")
Check(unitWorkspace.LatestAnalysis("file://" + unitLeafPath).model.globalScope.LookupLocal("IncludedProcedure")[0].declaredType = unitWorkspace.LatestAnalysis("file://" + unitLeafPath).model.BuiltinType("Int"), "unknown include opened alone uses its own implicit Strict mode")
responses = unitServer.HandlePayload(DidOpenPayload("file://" + unitRootPath, unitRootSource))
Check(responses.length = 2 And HasPublishedUri(responses, "file://" + unitLeafPath), "loading an including root republishes an already-open transitive include")
Local unitLeafAnalysis:TLanguageAnalysis = unitWorkspace.LatestAnalysis("file://" + unitLeafPath)
Check(unitLeafAnalysis <> Null And unitLeafAnalysis.syntaxTree.source.path = unitLeafPath, "included document view retains its own source and positions")
Check(unitLeafAnalysis.snapshot.rootDocument.path = unitRootPath, "transitively included document shares its root compilation snapshot")
Check(unitLeafAnalysis.model.globalScope.LookupLocal("RootValue").length = 1 And unitLeafAnalysis.model.globalScope.LookupLocal("MiddleValue").length = 1, "transitive include sees declarations from its root and sibling include context")
Check(unitLeafAnalysis.model.globalScope.LookupLocal("IncludedProcedure")[0].declaredType = unitLeafAnalysis.model.BuiltinType("Void"), "included document view inherits its root SuperStrict return defaults")
responses = unitServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:91,~qmethod~q:~qtextDocument/hover~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile://" + unitLeafPath + "~q},~qposition~q:{~qline~q:1,~qcharacter~q:8}}}")
Local unitHoverResponse:TJSONObject = ObjectFrom(responses[0])
Local unitHover:TJSONObject = TJSONObject(unitHoverResponse.Get("result"))
Check(unitHover <> Null And TJSONObject(unitHover.Get("contents")).GetString("value").Contains("Function RootValue:Int()"), "hover in a transitive include uses the shared compilation-unit model")
Local unitUpdatedLeafSource:String = "Function UpdatedLeaf:Int()~nReturn RootValue() + MiddleValue()~nEnd Function"
responses = unitServer.HandlePayload(DidChangePayload("file://" + unitLeafPath, unitUpdatedLeafSource, 2))
unitLeafAnalysis = unitWorkspace.LatestAnalysis("file://" + unitLeafPath)
Check(responses.length = 2 And unitLeafAnalysis.snapshot.rootDocument.path = unitRootPath, "editing a transitive include rebuilds and republishes its known compilation unit")
Check(unitLeafAnalysis.model.globalScope.LookupLocal("UpdatedLeaf").length = 1 And unitLeafAnalysis.model.globalScope.LookupLocal("RootValue").length = 1, "unsaved transitive include content is analysed in root context")
Local unitDetachedRootSource:String = "SuperStrict~nFunction RootValue:Int()~nReturn 1~nEnd Function"
responses = unitServer.HandlePayload(DidChangePayload("file://" + unitRootPath, unitDetachedRootSource, 2))
unitLeafAnalysis = unitWorkspace.LatestAnalysis("file://" + unitLeafPath)
Check(responses.length = 2 And unitWorkspace.CompilationRootForPath(unitLeafPath) = "", "removing an Include detaches and republishes its formerly included open documents")
Check(unitLeafAnalysis.snapshot.rootDocument.path = unitLeafPath, "detached included document returns to standalone analysis without guessing another owner")
responses = unitServer.HandlePayload(DidOpenPayload("file://" + unitStandalonePath, unitStandaloneSource))
Local unitStandaloneAnalysis:TLanguageAnalysis = unitWorkspace.LatestAnalysis("file://" + unitStandalonePath)
Check(responses.length = 1 And unitWorkspace.CompilationRootForPath(unitStandalonePath) = "", "ordinary standalone files keep the original one-document analysis path")
Check(unitStandaloneAnalysis.snapshot.documents.length = 1 And unitStandaloneAnalysis.syntaxTree.source.path = unitStandalonePath, "standalone compilation snapshot remains unchanged")

Local linkDirectory:String = "/tmp/blitzmax-lsp-document-link-test"
DeleteDir(linkDirectory, True)
CreateDir(linkDirectory + "/sdk/mod/demo.mod/link.mod", True)
SaveText("SuperStrict", linkDirectory + "/dependency.bmx")
SaveText("Const IncludedValue:Int = 1", linkDirectory + "/included.bmx")
SaveText("SuperStrict~nModule Demo.Link", linkDirectory + "/sdk/mod/demo.mod/link.mod/link.bmx")
Local linkSource:String = "SuperStrict~nImport ~qdependency.bmx~q~nInclude ~qincluded.bmx~q~nImport Demo.Link~nImport ~qmissing.bmx~q"
SaveText(linkSource, linkDirectory + "/main.bmx")
Local linkServer:TBlitzMaxLspServer = NewTestServer()
linkServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:100,~qmethod~q:~qinitialize~q,~qparams~q:{~qworkspaceFolders~q:[{~quri~q:~qfile:///tmp/blitzmax-lsp-document-link-test~q,~qname~q:~qlinks~q}],~qinitializationOptions~q:{~qblitzmax~q:{~qsdkPath~q:~q" + linkDirectory + "/sdk~q,~quseDependencySnapshots~q:false}}}}")
linkServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/blitzmax-lsp-document-link-test/main.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\nImport \~qdependency.bmx\~q\nInclude \~qincluded.bmx\~q\nImport Demo.Link\nImport \~qmissing.bmx\~q~q}}}")
responses = linkServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:101,~qmethod~q:~qtextDocument/documentLink~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/blitzmax-lsp-document-link-test/main.bmx~q}}}")
Local linkResponse:TJSONObject = ObjectFrom(responses[0])
Local documentLinks:TJSONArray = TJSONArray(linkResponse.Get("result"))
Check(documentLinks.Size() = 3, "document links include existing quoted imports, Includes and logical module sources while omitting missing targets")
Local dependencyLink:TJSONObject = FindDocumentLink(documentLinks, "/dependency.bmx")
Local includeLink:TJSONObject = FindDocumentLink(documentLinks, "/included.bmx")
Local moduleLink:TJSONObject = FindDocumentLink(documentLinks, "/sdk/mod/demo.mod/link.mod/link.bmx")
Check(dependencyLink <> Null And includeLink <> Null And moduleLink <> Null, "document links resolve relative and module paths to source files")
Local dependencyLinkRange:TJSONObject = TJSONObject(dependencyLink.Get("range"))
Local dependencyLinkStart:TJSONObject = TJSONObject(dependencyLinkRange.Get("start"))
Check(dependencyLinkStart.GetInteger("line") = 1 And dependencyLinkStart.GetInteger("character") = 8, "quoted document-link range selects the path without quote characters")
DeleteDir(linkDirectory, True)

Local referencesServer:TBlitzMaxLspServer = NewTestServer()
referencesServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:110,~qmethod~q:~qinitialize~q,~qparams~q:{~qinitializationOptions~q:{~qblitzmax~q:{~quseDependencySnapshots~q:false}}}}")
referencesServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/references.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\nLocal water := 0\nwater :+ 1\nPrint water~q}}}")
responses = referencesServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:111,~qmethod~q:~qtextDocument/references~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/references.bmx~q},~qposition~q:{~qline~q:2,~qcharacter~q:2},~qcontext~q:{~qincludeDeclaration~q:true}}}")
Local referencesResponse:TJSONObject = ObjectFrom(responses[0])
Local references:TJSONArray = TJSONArray(referencesResponse.Get("result"))
Check(references.Size() = 3 And HasLocation(references, "file:///tmp/references.bmx", 1, 6) And HasLocation(references, "file:///tmp/references.bmx", 2, 0) And HasLocation(references, "file:///tmp/references.bmx", 3, 6), "current-document references include the declaration and semantically bound uses")
responses = referencesServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:112,~qmethod~q:~qtextDocument/references~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/references.bmx~q},~qposition~q:{~qline~q:2,~qcharacter~q:2},~qcontext~q:{~qincludeDeclaration~q:false}}}")
referencesResponse = ObjectFrom(responses[0])
references = TJSONArray(referencesResponse.Get("result"))
Check(references.Size() = 2 And Not HasLocation(references, "file:///tmp/references.bmx", 1, 6), "references honour includeDeclaration=false")
referencesServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didOpen~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/type-references.bmx~q,~qlanguageId~q:~qblitzmax~q,~qversion~q:1,~qtext~q:~qSuperStrict\nType TWater\nEnd Type\nLocal first:TWater\nLocal second:TWater~q}}}")
responses = referencesServer.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:113,~qmethod~q:~qtextDocument/references~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///tmp/type-references.bmx~q},~qposition~q:{~qline~q:3,~qcharacter~q:14},~qcontext~q:{~qincludeDeclaration~q:true}}}")
referencesResponse = ObjectFrom(responses[0])
references = TJSONArray(referencesResponse.Get("result"))
Check(references.Size() = 3 And HasLocation(references, "file:///tmp/type-references.bmx", 1, 5) And HasLocation(references, "file:///tmp/type-references.bmx", 3, 12) And HasLocation(references, "file:///tmp/type-references.bmx", 4, 13), "references include written type occurrences as well as expression-bound symbols")

responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:2,~qmethod~q:~qshutdown~q}")
Check(responses.length = 1, "shutdown responds")
responses = server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qexit~q}")
Check(server.exitRequested And server.cleanExit, "exit after shutdown is clean")

Print "BlitzMax.LSP server tests passed"
