' Copyright (c) 2026 Bruce A Henderson and contributors
' SPDX-License-Identifier: Zlib

SuperStrict

Framework BRL.StandardIO

Import BRL.FileSystem
Import BlitzMax.Compiler
Import "bcc2_engine.bmx"
Import "version.bmx"

If AppArgs.length = 2 And AppArgs[1] = "--engine" Then
	TBcc2Engine.Run()
	exit_(0)
End If

Function PrintVersion()
	Print "bcc Release Version " + BCC_VERSION
End Function

Function Usage()
Print "Usage: bcc [--dump-ir|--emit-c|--emit-runtime-c|--emit-runtime-header|--emit-interface|--emit-build] [-o <path>] [--build-c <relative-path>] [--build-header <relative-path>] [--build-interface <relative-path>] [--build-manifest <relative-path>] [--build-reference-root <path>] [--sdk <path>] [--module <name>] [--source-unit <relative-path>] [--application-identity <name>] [--application-source] [--debug|--release] [--no-debug-instrumentation] [--coverage] [--platform <name>] [--arch <name>] [--app-type console|gui] [--framework <module>] [--threaded|--single-threaded] [--no-runtime] <source.bmx>"
End Function

If AppArgs.length < 2 Then
	PrintVersion()
	exit_(0)
End If
If AppArgs.length = 2 And AppArgs[1] = "--version" Then
	PrintVersion()
	exit_(0)
End If

Local options:TCompilerOptions = TCompilerOptions.CreateDefault()
' Like production bcc, a direct invocation is a debug build unless -r or
' --release is supplied. bmk always passes the selected mode explicitly.
options.buildMode = "debug"
options.debugInstrumentation = True
Local sourcePath:String
Local outputPath:String
Local buildCPath:String = "application.c"
Local buildHeaderPath:String
Local buildInterfacePath:String
Local buildManifestPath:String = "bcc-build.manifest"
Local buildReferenceRootPath:String
Local emitC:Int
Local index:Int = 1
While index < AppArgs.length
	Local argument:String = AppArgs[index]
	Select argument
		Case "--dump-ir"
			emitC = False
		Case "--emit-c"
			emitC = True
		Case "--emit-runtime-c"
			emitC = 2
		Case "--emit-runtime-header"
			emitC = 3
		Case "--emit-interface"
			emitC = 4
		Case "--emit-build"
			emitC = 5
		Case "--build-c"
			index :+ 1
			If index >= AppArgs.length Then Usage(); exit_(1)
			buildCPath = AppArgs[index]
		Case "--build-header"
			index :+ 1
			If index >= AppArgs.length Then Usage(); exit_(1)
			buildHeaderPath = AppArgs[index]
		Case "--build-interface"
			index :+ 1
			If index >= AppArgs.length Then Usage(); exit_(1)
			buildInterfacePath = AppArgs[index]
		Case "--build-manifest"
			index :+ 1
			If index >= AppArgs.length Then Usage(); exit_(1)
			buildManifestPath = AppArgs[index]
		Case "--build-reference-root"
			index :+ 1
			If index >= AppArgs.length Then Usage(); exit_(1)
			buildReferenceRootPath = AppArgs[index]
		Case "-o", "--output"
			index :+ 1
			If index >= AppArgs.length Then Usage(); exit_(1)
			outputPath = AppArgs[index]
		Case "--sdk"
			index :+ 1
			If index >= AppArgs.length Then Usage(); exit_(1)
			options.sdkPath = AppArgs[index]
		Case "--module", "-m"
			index :+ 1
			If index >= AppArgs.length Then Usage(); exit_(1)
			options.sourceModuleName = AppArgs[index].ToLower()
		Case "--source-unit"
			index :+ 1
			If index >= AppArgs.length Then Usage(); exit_(1)
			options.sourceUnitPath = AppArgs[index].Replace("\\", "/").ToLower()
		Case "--application-identity"
			index :+ 1
			If index >= AppArgs.length Then Usage(); exit_(1)
			options.applicationIdentity = AppArgs[index].ToLower()
		Case "--application-source"
			options.applicationSourceUnit = True
			options.applicationBuild = True
		Case "--debug"
			options.buildMode = "debug"
			options.debugInstrumentation = True
		Case "--release", "-r"
			options.buildMode = "release"
			options.debugInstrumentation = False
		Case "--no-debug-instrumentation"
			options.debugInstrumentation = False
		Case "--coverage", "-cov"
			options.coverageInstrumentation = True
		Case "--platform", "-p"
			index :+ 1
			If index >= AppArgs.length Then Usage(); exit_(1)
			options.targetPlatform = AppArgs[index].ToLower()
		Case "--arch", "-g"
			index :+ 1
			If index >= AppArgs.length Then Usage(); exit_(1)
			options.targetArchitecture = AppArgs[index].ToLower()
		Case "--app-type", "-t"
			index :+ 1
			If index >= AppArgs.length Then Usage(); exit_(1)
			options.applicationType = AppArgs[index].ToLower()
			If options.applicationType <> "console" And options.applicationType <> "gui" Then
				Print "Invalid application type: " + options.applicationType
				exit_(1)
			End If
			options.applicationBuild = True
		Case "--framework", "-f"
			index :+ 1
			If index >= AppArgs.length Then Usage(); exit_(1)
			options.frameworkModule = AppArgs[index].ToLower()
			options.applicationBuild = True
		Case "--threaded", "-h"
			options.threaded = True
		Case "--single-threaded"
			options.threaded = False
		Case "--no-runtime"
			options.implicitRuntime = False
		Case "--verbose", "-v"
			options.verbose = True
		Case "--gdb-debug", "-d"
			options.gdbDebug = True
		Case "--musl", "-musl"
			options.musl = True
		Case "--user-defs", "-ud"
			index :+ 1
			If index >= AppArgs.length Then Usage(); exit_(1)
			options.userDefinitions = AppArgs[index]
		Case "--quiet", "-q"
			' Accepted for production-driver compatibility. Diagnostics remain
			' deterministic and successful compilation is otherwise silent.
		Default
			If argument.StartsWith("-") Or sourcePath.length Then
				Print "Unknown or duplicate argument: " + argument
				Usage()
				exit_(1)
			End If
			sourcePath = argument
	End Select
	index :+ 1
Wend

If Not sourcePath.length Then
	Usage()
	exit_(1)
End If
If Not CompilerTargetSupported(options.targetPlatform, options.targetArchitecture) Then
	Print "Invalid platform/architecture configuration: " + options.targetPlatform + "/" + options.targetArchitecture
	exit_(1)
End If
If options.applicationSourceUnit And (Not options.sourceModuleName.length Or Not options.applicationIdentity.length) Then
	Print "--application-source requires --module and --application-identity"
	exit_(1)
End If
If Not options.implicitRuntime And emitC > 1 And emitC <> 4 And emitC <> 5 Then
	Print "--no-runtime is supported only by standalone C, IR, or interface emission"
	exit_(1)
End If

options.RefreshConditionalSymbols()
Local result:TCompilerResult = TBlitzMaxCompiler.CompileFile(sourcePath, options)
If options.verbose Then
	Print "bcc timing source-load=" + result.sourceLoadMilliseconds + "ms analysis=" + result.analysisMilliseconds + "ms generic-plan=" + result.genericPlanMilliseconds + "ms lowering=" + result.loweringMilliseconds + "ms"
	If result.analysis Then
		Print "bcc timing language snapshot=" + result.analysis.snapshotMilliseconds + "ms semantic=" + result.analysis.semanticMilliseconds + "ms binding=" + result.analysis.bindingMilliseconds + "ms compile-time=" + result.analysis.compileTimeMilliseconds + "ms control-flow=" + result.analysis.controlFlowMilliseconds + "ms data-flow=" + result.analysis.dataFlowMilliseconds + "ms"
	End If
	If result.genericPlan Then
		Print "bcc timing generics publish=" + result.genericPlan.publishMilliseconds + "ms index=" + result.genericPlan.indexMilliseconds + "ms discover=" + result.genericPlan.discoveryMilliseconds + "ms expand=" + result.genericPlan.expansionMilliseconds + "ms cycles=" + result.genericPlan.cycleValidationMilliseconds + "ms units=" + result.genericPlan.unitLoweringMilliseconds + "ms manifest=" + result.genericPlan.manifestMilliseconds + "ms"
		Print "bcc timing generic-units ir=" + result.genericPlan.specializationIrMilliseconds + "ms declarations=" + result.genericPlan.declarationEmissionMilliseconds + "ms implementations=" + result.genericPlan.implementationEmissionMilliseconds + "ms application-declarations=" + result.genericPlan.applicationDeclarationMilliseconds + "ms"
		Print "bcc timing generic-graph nodes=" + result.genericPlan.nodeCount + " edges=" + result.genericPlan.edgeCount + " requests=" + result.genericPlan.requestCount
	End If
	If result.loweringProfile Then
		Local profile:TCompilerIrLoweringProfile = result.loweringProfile
		Print "bcc timing lowering initialization=" + profile.initializationMilliseconds + "ms input=" + profile.inputMilliseconds + "ms generic-references=" + profile.genericReferenceMilliseconds + "ms type-shells=" + profile.typeShellMilliseconds + "ms function-shells=" + profile.functionShellMilliseconds + "ms closures=" + profile.closureMilliseconds + "ms interfaces=" + profile.interfaceMilliseconds + "ms bodies=" + profile.bodyMilliseconds + "ms finalization=" + profile.finalizationMilliseconds + "ms"
		Print "bcc timing lowering-input documents=" + profile.documentCount + " interfaces=" + profile.interfaceCount
	End If
End If

If result.analysis And result.analysis.snapshot Then
	For Local diagnostic:TSnapshotDiagnostic = EachIn result.analysis.snapshot.diagnostics
		Print diagnostic.Format(result.analysis.snapshot)
	Next
End If
If result.analysis And result.analysis.model Then
	For Local diagnostic:TDiagnostic = EachIn result.analysis.model.diagnostics
		Print diagnostic.Format(result.analysis.snapshot.SourceForPath(diagnostic.path))
	Next
End If
For Local diagnostic:TCompilerDiagnostic = EachIn result.diagnostics
	If result.analysis And result.analysis.snapshot Then
		Print diagnostic.Format(result.analysis.snapshot.SourceForPath(diagnostic.path))
	Else
		Print diagnostic.Format()
	End If
Next

If Not result.Succeeded() Then exit_(1)

Local output:String
If emitC = 5 Then
	If Not outputPath.length Then
		Print "--emit-build requires an output directory via -o"
		exit_(1)
	End If
	Local planDiagnostics:TCompilerDiagnostic[]
	Local planStarted:Int = MilliSecs()
	Local buildPlan:TCompilerBuildOutputPlan = TBlitzMaxCompiler.PlanBuildOutputs(result, buildCPath, buildHeaderPath, buildInterfacePath, planDiagnostics)
	Local planMilliseconds:Int = MilliSecs() - planStarted
	For Local diagnostic:TCompilerDiagnostic = EachIn planDiagnostics
		Print diagnostic.Format()
	Next
	If planDiagnostics.length Then exit_(1)
	Local materializationDiagnostics:TCompilerDiagnostic[]
	Local materializationStarted:Int = MilliSecs()
	Local materialization:TCompilerBuildMaterializationResult = TCompilerBuildOutputMaterializer.Materialize(buildPlan, outputPath, buildManifestPath, materializationDiagnostics, buildReferenceRootPath)
	Local materializationMilliseconds:Int = MilliSecs() - materializationStarted
	For Local diagnostic:TCompilerDiagnostic = EachIn materializationDiagnostics
		Print diagnostic.Format()
	Next
	If materializationDiagnostics.length Then exit_(1)
	If options.verbose Then Print "bcc timing output-plan=" + planMilliseconds + "ms materialize=" + materializationMilliseconds + "ms"
	If options.verbose Then Print "bcc build manifest=" + outputPath + "/" + materialization.manifestPath
	exit_(0)
Else If emitC = 4 Then
	Local backendDiagnostics:TCompilerDiagnostic[]
	output = TBlitzMaxCompiler.EmitInterface(result, backendDiagnostics)
	For Local diagnostic:TCompilerDiagnostic = EachIn backendDiagnostics
		Print diagnostic.Format(result.analysis.snapshot.SourceForPath(diagnostic.path))
	Next
	If backendDiagnostics.length Then exit_(1)
Else If emitC = 3 Then
	Local backendDiagnostics:TCompilerDiagnostic[]
	output = TBlitzMaxCompiler.EmitRuntimeHeader(result, backendDiagnostics)
	For Local diagnostic:TCompilerDiagnostic = EachIn backendDiagnostics
		Print diagnostic.Format(result.analysis.snapshot.SourceForPath(diagnostic.path))
	Next
	If backendDiagnostics.length Then exit_(1)
Else If emitC = 2 Then
	Local backendDiagnostics:TCompilerDiagnostic[]
	output = TBlitzMaxCompiler.EmitRuntimeC(result, backendDiagnostics)
	For Local diagnostic:TCompilerDiagnostic = EachIn backendDiagnostics
		Print diagnostic.Format(result.analysis.snapshot.SourceForPath(diagnostic.path))
	Next
	If backendDiagnostics.length Then exit_(1)
Else If emitC Then
	Local backendDiagnostics:TCompilerDiagnostic[]
	output = TBlitzMaxCompiler.EmitC(result, backendDiagnostics)
	For Local diagnostic:TCompilerDiagnostic = EachIn backendDiagnostics
		Print diagnostic.Format(result.analysis.snapshot.SourceForPath(diagnostic.path))
	Next
	If backendDiagnostics.length Then exit_(1)
Else
	output = TCompilerIrDumper.Dump(result.ir)
End If

If outputPath.length Then
	SaveText(output, outputPath)
Else
	Print output
End If
