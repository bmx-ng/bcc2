' Copyright (c) 2026 Bruce A Henderson and contributors
' SPDX-License-Identifier: Zlib

SuperStrict

Import BRL.Base64
Import BRL.StandardIO
Import BRL.StringBuilder
Import BlitzMax.Compiler

Const BCC2_ENGINE_PROTOCOL_VERSION:Int = 2

Type TBcc2EngineCompileResult
	Field exitCode:Int
	Field output:String
End Type

Type TBcc2Engine
	Global snapshotTextCache:TCompilerSnapshotTextCache = New TCompilerSnapshotTextCache
	Global genericBackendUnitCache:TCompilerGenericBackendUnitCache = New TCompilerGenericBackendUnitCache

	Function Run()
		WriteProtocolLine("bcc2-engine " + BCC2_ENGINE_PROTOCOL_VERSION)
		While True
			Local line:String = StandardIOStream.ReadLine()
			If Not line.length Then Exit
			If line = "shutdown" Then
				WriteProtocolLine("shutdown")
				Exit
			End If
			Local parts:String[] = line.Split(" ")
			If parts.length >= 3 And parts[0] = "invalidate" Then
				Invalidate(parts)
				Continue
			End If
			If parts.length < 3 Or parts[0] <> "compile" Then
				WriteResult("0", Failure(New TStringBuilder, "Malformed engine request."))
				Continue
			End If
			Local requestId:String = parts[1]
			Local count:Int = Int(parts[2])
			If count < 1 Or parts.length <> count + 3 Then
				WriteResult(requestId, Failure(New TStringBuilder, "Malformed engine argument count."))
				Continue
			End If
			Local arguments:String[] = New String[count]
			Local valid:Int = True
			For Local index:Int = 0 Until count
				Try
					arguments[index] = Decode(parts[index + 3])
				Catch exception:Object
					valid = False
					Exit
				End Try
			Next
			If Not valid Then
				WriteResult(requestId, Failure(New TStringBuilder, "Malformed engine argument encoding."))
				Continue
			End If
			Local result:TBcc2EngineCompileResult
			Try
				result = Compile(arguments)
			Catch exception:Object
				result = Failure(New TStringBuilder, InternalFailureMessage(exception, arguments))
			End Try
			WriteResult(requestId, result)
		Wend
	End Function

	Function Invalidate(parts:String[])
		Local requestId:String = parts[1]
		Local count:Int = Int(parts[2])
		If count < 0 Or parts.length <> count + 3 Then
			WriteProtocolLine("invalidated " + requestId + " 0")
			Return
		End If
		Local valid:Int = True
		For Local index:Int = 0 Until count
			Try
				snapshotTextCache.Invalidate(Decode(parts[index + 3]))
			Catch exception:Object
				valid = False
			End Try
		Next
		WriteProtocolLine("invalidated " + requestId + " " + valid)
	End Function

	Function InternalFailureMessage:String(exception:Object, arguments:String[])
		Local detail:String = ExceptionDetail(exception)
		Local message:String = "Internal compiler engine failure"
		If detail.length Then message :+ ": " + detail Else message :+ ": <exception supplied no detail>"
		Local sourcePath:String = SourcePathFromArguments(arguments)
		If sourcePath.length Then message :+ "~nWhile compiling: " + sourcePath
		Return message
	End Function

	Function ExceptionDetail:String(exception:Object)
		If Not exception Then Return "<Null exception>"
		Local text:String = String(exception)
		If text.length Then Return text
		Try
			text = exception.ToString()
		Catch formattingException:Object
			Return "<exception ToString() failed>"
		End Try
		Return text
	End Function

	Function SourcePathFromArguments:String(arguments:String[])
		If Not arguments Then Return ""
		For Local index:Int = arguments.length - 1 To 0 Step -1
			Local argument:String = arguments[index]
			If argument.length And Not argument.StartsWith("-") And argument.ToLower().EndsWith(".bmx") Then Return argument
		Next
		Return ""
	End Function

	Function WriteResult(requestId:String, result:TBcc2EngineCompileResult)
		' Pub.FreeProcess has a bounded line buffer, so large diagnostics are
		' framed as several short lines rather than one unbounded response.
		Local encoded:String = Encode(result.output)
		WriteProtocolLine("result " + requestId + " " + result.exitCode + " " + encoded.length)
		Local offset:Int
		While offset < encoded.length
			Local nextOffset:Int = Min(offset + 3000, encoded.length)
			WriteProtocolLine("data " + requestId + " " + encoded[offset..nextOffset])
			offset = nextOffset
		Wend
		WriteProtocolLine("end " + requestId)
	End Function

	Function Compile:TBcc2EngineCompileResult(arguments:String[])
		Local response:TBcc2EngineCompileResult = New TBcc2EngineCompileResult
		Local output:TStringBuilder = New TStringBuilder
		Local options:TCompilerOptions = TCompilerOptions.CreateDefault()
		options.buildMode = "debug"
		options.debugInstrumentation = True
		Local sourcePath:String
		Local outputPath:String
		Local buildCPath:String = "application.c"
		Local buildHeaderPath:String
		Local buildInterfacePath:String
		Local buildManifestPath:String = "bcc-build.manifest"
		Local buildReferenceRootPath:String
		Local emitBuild:Int
		Local index:Int
		While index < arguments.length
			Local argument:String = arguments[index]
			Select argument
				Case "--emit-build"
					emitBuild = True
				Case "--build-c"
					index :+ 1
					If index >= arguments.length Then Return Failure(output, "Missing --build-c value.")
					buildCPath = arguments[index]
				Case "--build-header"
					index :+ 1
					If index >= arguments.length Then Return Failure(output, "Missing --build-header value.")
					buildHeaderPath = arguments[index]
				Case "--build-interface"
					index :+ 1
					If index >= arguments.length Then Return Failure(output, "Missing --build-interface value.")
					buildInterfacePath = arguments[index]
				Case "--build-manifest"
					index :+ 1
					If index >= arguments.length Then Return Failure(output, "Missing --build-manifest value.")
					buildManifestPath = arguments[index]
				Case "--build-reference-root"
					index :+ 1
					If index >= arguments.length Then Return Failure(output, "Missing --build-reference-root value.")
					buildReferenceRootPath = arguments[index]
				Case "-o", "--output"
					index :+ 1
					If index >= arguments.length Then Return Failure(output, "Missing output path.")
					outputPath = arguments[index]
				Case "--sdk"
					index :+ 1
					If index >= arguments.length Then Return Failure(output, "Missing SDK path.")
					options.sdkPath = arguments[index]
				Case "--module", "-m"
					index :+ 1
					If index >= arguments.length Then Return Failure(output, "Missing module identity.")
					options.sourceModuleName = arguments[index].ToLower()
				Case "--source-unit"
					index :+ 1
					If index >= arguments.length Then Return Failure(output, "Missing source-unit path.")
					options.sourceUnitPath = arguments[index].Replace("\\", "/").ToLower()
				Case "--application-identity"
					index :+ 1
					If index >= arguments.length Then Return Failure(output, "Missing application identity.")
					options.applicationIdentity = arguments[index].ToLower()
				Case "--application-source"
					options.applicationSourceUnit = True
					options.applicationBuild = True
				Case "--debug"
					options.buildMode = "debug"
					options.debugInstrumentation = True
				Case "--release", "-r"
					options.buildMode = "release"
					options.debugInstrumentation = False
				Case "--coverage", "-cov"
					options.coverageInstrumentation = True
				Case "--platform", "-p"
					index :+ 1
					If index >= arguments.length Then Return Failure(output, "Missing platform.")
					options.targetPlatform = arguments[index].ToLower()
				Case "--arch", "-g"
					index :+ 1
					If index >= arguments.length Then Return Failure(output, "Missing architecture.")
					options.targetArchitecture = arguments[index].ToLower()
				Case "--app-type", "-t"
					index :+ 1
					If index >= arguments.length Then Return Failure(output, "Missing application type.")
					options.applicationType = arguments[index].ToLower()
					If options.applicationType <> "console" And options.applicationType <> "gui" Then Return Failure(output, "Invalid application type.")
					options.applicationBuild = True
				Case "--framework", "-f"
					index :+ 1
					If index >= arguments.length Then Return Failure(output, "Missing framework module.")
					options.frameworkModule = arguments[index].ToLower()
					options.applicationBuild = True
				Case "--threaded", "-h"
					options.threaded = True
				Case "--single-threaded"
					options.threaded = False
				Case "--verbose", "-v"
					options.verbose = True
				Case "--gdb-debug", "-d"
					options.gdbDebug = True
				Case "--musl", "-musl"
					options.musl = True
				Case "--user-defs", "-ud"
					index :+ 1
					If index >= arguments.length Then Return Failure(output, "Missing user definitions.")
					options.userDefinitions = arguments[index]
				Case "--quiet", "-q"
				Default
					If argument.StartsWith("-") Or sourcePath.length Then Return Failure(output, "Unknown or duplicate engine argument: " + argument)
					sourcePath = argument
			End Select
			index :+ 1
		Wend

		If Not emitBuild Then Return Failure(output, "Engine requests currently require --emit-build.")
		If Not sourcePath.length Then Return Failure(output, "Engine request has no source path.")
		If Not outputPath.length Then Return Failure(output, "Engine request has no output root.")
		If Not CompilerTargetSupported(options.targetPlatform, options.targetArchitecture) Then
			Return Failure(output, "Invalid platform/architecture configuration: " + options.targetPlatform + "/" + options.targetArchitecture)
		End If
		If options.applicationSourceUnit And (Not options.sourceModuleName.length Or Not options.applicationIdentity.length) Then
			Return Failure(output, "--application-source requires --module and --application-identity.")
		End If

		options.RefreshConditionalSymbols()
		Local cacheHitsBefore:Long = snapshotTextCache.hits
		Local cacheMissesBefore:Long = snapshotTextCache.misses
		Local interfaceParseHitsBefore:Long = snapshotTextCache.interfaceParseHits
		Local interfaceParseMissesBefore:Long = snapshotTextCache.interfaceParseMisses
		Local interfaceResolutionHitsBefore:Long = snapshotTextCache.interfaceResolutionHits
		Local genericTemplateDecodeHitsBefore:Long = snapshotTextCache.genericTemplateDecodeHits
		Local genericTemplateDecodeMissesBefore:Long = snapshotTextCache.genericTemplateDecodeMisses
		Local genericBackendHitsBefore:Long = genericBackendUnitCache.hits
		Local genericBackendMissesBefore:Long = genericBackendUnitCache.misses
		Local result:TCompilerResult = TBlitzMaxCompiler.CompileFile(sourcePath, options, snapshotTextCache, genericBackendUnitCache)
		If options.verbose Then AppendTimings(output, result)
		If options.verbose Then AppendLine(output, "bcc timing snapshot-text-cache hits=" + (snapshotTextCache.hits - cacheHitsBefore) + " misses=" + (snapshotTextCache.misses - cacheMissesBefore))
		If options.verbose Then AppendLine(output, "bcc timing interface-parse-cache hits=" + (snapshotTextCache.interfaceParseHits - interfaceParseHitsBefore) + " misses=" + (snapshotTextCache.interfaceParseMisses - interfaceParseMissesBefore))
		If options.verbose Then AppendLine(output, "bcc timing interface-request-reuse hits=" + (snapshotTextCache.interfaceResolutionHits - interfaceResolutionHitsBefore))
		If options.verbose Then AppendLine(output, "bcc timing generic-template-decode-cache hits=" + (snapshotTextCache.genericTemplateDecodeHits - genericTemplateDecodeHitsBefore) + " misses=" + (snapshotTextCache.genericTemplateDecodeMisses - genericTemplateDecodeMissesBefore))
		If options.verbose Then AppendLine(output, "bcc timing generic-backend-unit-cache hits=" + (genericBackendUnitCache.hits - genericBackendHitsBefore) + " misses=" + (genericBackendUnitCache.misses - genericBackendMissesBefore))
		AppendDiagnostics(output, result)
		If Not result.Succeeded() Then
			response.exitCode = 1
			response.output = output.ToString()
			Return response
		End If

		Local planDiagnostics:TCompilerDiagnostic[]
		Local planStarted:Int = MilliSecs()
		Local buildPlan:TCompilerBuildOutputPlan = TBlitzMaxCompiler.PlanBuildOutputs(result, buildCPath, buildHeaderPath, buildInterfacePath, planDiagnostics)
		Local planMilliseconds:Int = MilliSecs() - planStarted
		AppendCompilerDiagnostics(output, planDiagnostics, Null)
		If planDiagnostics.length Then
			response.exitCode = 1
			response.output = output.ToString()
			Return response
		End If

		Local materializationDiagnostics:TCompilerDiagnostic[]
		Local materializationStarted:Int = MilliSecs()
		Local materialization:TCompilerBuildMaterializationResult = TCompilerBuildOutputMaterializer.Materialize(buildPlan, outputPath, buildManifestPath, materializationDiagnostics, buildReferenceRootPath)
		Local materializationMilliseconds:Int = MilliSecs() - materializationStarted
		' Published dependency interfaces and template artifacts can be consumed
		' by a later request in the same engine. Explicit invalidation avoids
		' relying on second-resolution filesystem timestamps when content length
		' is unchanged.
		For Local publishedFile:TCompilerBuildOutputFile = EachIn buildPlan.files
			If publishedFile.role = "interface" Or publishedFile.role = "generic-template" Then
				snapshotTextCache.Invalidate(outputPath + "/" + publishedFile.relativePath)
			End If
		Next
		AppendCompilerDiagnostics(output, materializationDiagnostics, Null)
		If materializationDiagnostics.length Then
			response.exitCode = 1
			response.output = output.ToString()
			Return response
		End If
		If options.verbose Then AppendLine(output, "bcc timing output-plan=" + planMilliseconds + "ms materialize=" + materializationMilliseconds + "ms")
		If options.verbose Then AppendLine(output, "bcc timing output-components application=" + buildPlan.applicationMilliseconds + "ms header=" + buildPlan.headerMilliseconds + "ms interface=" + buildPlan.interfaceMilliseconds + "ms generic-files=" + buildPlan.genericFilesMilliseconds + "ms manifest=" + buildPlan.manifestMilliseconds + "ms")
		If options.verbose Then AppendLine(output, "bcc build manifest=" + outputPath + "/" + materialization.manifestPath)
		response.output = output.ToString()
		Return response
	End Function

	Function AppendTimings(output:TStringBuilder, result:TCompilerResult)
		AppendLine(output, "bcc timing source-load=" + result.sourceLoadMilliseconds + "ms analysis=" + result.analysisMilliseconds + "ms generic-plan=" + result.genericPlanMilliseconds + "ms lowering=" + result.loweringMilliseconds + "ms")
		If result.analysis Then
			AppendLine(output, "bcc timing language snapshot=" + result.analysis.snapshotMilliseconds + "ms semantic=" + result.analysis.semanticMilliseconds + "ms binding=" + result.analysis.bindingMilliseconds + "ms compile-time=" + result.analysis.compileTimeMilliseconds + "ms control-flow=" + result.analysis.controlFlowMilliseconds + "ms data-flow=" + result.analysis.dataFlowMilliseconds + "ms")
		End If
		If result.genericPlan Then
			AppendLine(output, "bcc timing generics publish=" + result.genericPlan.publishMilliseconds + "ms index=" + result.genericPlan.indexMilliseconds + "ms discover=" + result.genericPlan.discoveryMilliseconds + "ms expand=" + result.genericPlan.expansionMilliseconds + "ms cycles=" + result.genericPlan.cycleValidationMilliseconds + "ms units=" + result.genericPlan.unitLoweringMilliseconds + "ms manifest=" + result.genericPlan.manifestMilliseconds + "ms")
			AppendLine(output, "bcc timing generic-units ir=" + result.genericPlan.specializationIrMilliseconds + "ms declarations=" + result.genericPlan.declarationEmissionMilliseconds + "ms implementations=" + result.genericPlan.implementationEmissionMilliseconds + "ms application-declarations=" + result.genericPlan.applicationDeclarationMilliseconds + "ms")
			AppendLine(output, "bcc timing generic-graph nodes=" + result.genericPlan.nodeCount + " edges=" + result.genericPlan.edgeCount + " requests=" + result.genericPlan.requestCount)
		End If
		If result.loweringProfile Then
			Local profile:TCompilerIrLoweringProfile = result.loweringProfile
			AppendLine(output, "bcc timing lowering initialization=" + profile.initializationMilliseconds + "ms input=" + profile.inputMilliseconds + "ms generic-references=" + profile.genericReferenceMilliseconds + "ms type-shells=" + profile.typeShellMilliseconds + "ms function-shells=" + profile.functionShellMilliseconds + "ms closures=" + profile.closureMilliseconds + "ms interfaces=" + profile.interfaceMilliseconds + "ms bodies=" + profile.bodyMilliseconds + "ms finalization=" + profile.finalizationMilliseconds + "ms")
			AppendLine(output, "bcc timing lowering-input documents=" + profile.documentCount + " interfaces=" + profile.interfaceCount)
		End If
	End Function

	Function AppendDiagnostics(output:TStringBuilder, result:TCompilerResult)
		If result.analysis And result.analysis.snapshot Then
			For Local diagnostic:TSnapshotDiagnostic = EachIn result.analysis.snapshot.diagnostics
				AppendLine(output, diagnostic.Format(result.analysis.snapshot))
			Next
		End If
		If result.analysis And result.analysis.model Then
			For Local diagnostic:TDiagnostic = EachIn result.analysis.model.diagnostics
				AppendLine(output, diagnostic.Format(result.analysis.snapshot.SourceForPath(diagnostic.path)))
			Next
		End If
		AppendCompilerDiagnostics(output, result.diagnostics, result)
	End Function

	Function AppendCompilerDiagnostics(output:TStringBuilder, diagnostics:TCompilerDiagnostic[], result:TCompilerResult)
		For Local diagnostic:TCompilerDiagnostic = EachIn diagnostics
			If result And result.analysis And result.analysis.snapshot Then
				AppendLine(output, diagnostic.Format(result.analysis.snapshot.SourceForPath(diagnostic.path)))
			Else
				AppendLine(output, diagnostic.Format())
			End If
		Next
	End Function

	Function Failure:TBcc2EngineCompileResult(output:TStringBuilder, message:String)
		AppendLine(output, message)
		Local result:TBcc2EngineCompileResult = New TBcc2EngineCompileResult
		result.exitCode = 2
		result.output = output.ToString()
		Return result
	End Function

	Function AppendLine(output:TStringBuilder, value:String)
		output.Append(value).Append("~n")
	End Function

	Function Encode:String(value:String)
		Return TBase64.Encode(value, EBase64Options.DontBreakLines)
	End Function

	Function Decode:String(value:String)
		Local bytes:Byte[] = TBase64.Decode(value)
		Return String.FromUTF8Bytes(bytes, bytes.length)
	End Function

	Function WriteProtocolLine(value:String)
		StandardIOStream.WriteLine(value)
		StandardIOStream.Flush()
	End Function
End Type
