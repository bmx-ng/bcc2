SuperStrict

Framework BRL.StandardIO

Import BRL.Map
Import BRL.FileSystem
Import BRL.TextStream
Import BlitzMax.Compiler

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Function Contains:Int(text:String, fragment:String)
	Return text.Find(fragment) >= 0
End Function

Function AppearsBefore:Int(text:String, first:String, second:String)
	Local firstIndex:Int = text.Find(first)
	Local secondIndex:Int = text.Find(second)
	Return firstIndex >= 0 And secondIndex > firstIndex
End Function

Function Occurrences:Int(text:String, fragment:String)
	If Not fragment.length Then Return 0
	Local count:Int
	Local offset:Int
	While offset < text.length
		Local found:Int = text.Find(fragment, offset)
		If found < 0 Then Exit
		count :+ 1
		offset = found + fragment.length
	Wend
	Return count
End Function

Function Compact:String(text:String)
	Return text.Replace(" ", "").Replace("~t", "").Replace("~r", "").Replace("~n", "")
End Function

Function HasCompilerDiagnostic:Int(result:TCompilerResult, code:String)
	For Local diagnostic:TCompilerDiagnostic = EachIn result.diagnostics
		If diagnostic.code = code Then Return True
	Next
	Return False
End Function

Function CompilerDiagnosticSummary:String(result:TCompilerResult)
	Local summary:String
	For Local diagnostic:TCompilerDiagnostic = EachIn result.diagnostics
		If summary.length Then summary :+ "; "
		summary :+ diagnostic.Format()
	Next
	If result.analysis And result.analysis.syntaxTree Then
		For Local diagnostic:TDiagnostic = EachIn result.analysis.syntaxTree.diagnostics
			If summary.length Then summary :+ "; "
			summary :+ diagnostic.Format(result.analysis.syntaxTree.source)
		Next
	End If
	If result.analysis And result.analysis.model Then
		For Local diagnostic:TDiagnostic = EachIn result.analysis.model.diagnostics
			If summary.length Then summary :+ "; "
			summary :+ diagnostic.Format(result.analysis.syntaxTree.source)
		Next
	End If
	Return summary
End Function

Function HasLanguageDiagnostic:Int(result:TCompilerResult, code:String)
	If Not result Or Not result.analysis Or Not result.analysis.model Then Return False
	For Local diagnostic:TDiagnostic = EachIn result.analysis.model.diagnostics
		If diagnostic.code = code Then Return True
	Next
	Return False
End Function

Function HasSyntaxDiagnostic:Int(result:TCompilerResult, code:String)
	If Not result Or Not result.analysis Or Not result.analysis.syntaxTree Then Return False
	For Local diagnostic:TDiagnostic = EachIn result.analysis.syntaxTree.diagnostics
		If diagnostic.code = code Then Return True
	Next
	Return False
End Function

Function HasDiagnostic:Int(diagnostics:TCompilerDiagnostic[], code:String)
	For Local diagnostic:TCompilerDiagnostic = EachIn diagnostics
		If diagnostic.code = code Then Return True
	Next
	Return False
End Function

Function HasConditionalSymbol:Int(symbols:String[], name:String)
	For Local symbol:String = EachIn symbols
		If symbol = name Then Return True
	Next
	Return False
End Function

Function SnapshotHasConditionalRegion:Int(snapshot:TCompilationSnapshot)
	If Not snapshot Then Return False
	For Local document:TSourceDocumentModel = EachIn snapshot.documents
		If Not document Or Not document.tree Then Continue
		For Local token:TSyntaxToken = EachIn document.tree.root.tokens
			If token.kind = TOKEN_DIRECTIVE Then Return True
		Next
	Next
	Return False
End Function

Type TCompilerTestResolver Extends TSnapshotResolver
	Field includes:TMap = New TMap
	Field interfaces:TMap = New TMap
	Field genericTemplates:TMap = New TMap
	Field core:TSnapshotText

	Method AddInclude(path:String, text:String)
		includes.Insert(path.ToLower(), TSnapshotText.Create(path, text))
	End Method

	Method AddInterface(name:String, path:String, text:String)
		interfaces.Insert(name.ToLower(), TSnapshotText.Create(path, text))
	End Method

	Method AddGenericTemplate(reference:String, path:String, text:String)
		genericTemplates.Insert(reference.ToLower(), TSnapshotText.Create(path, text))
	End Method

	Method ResolveInclude:TSnapshotText(includingPath:String, includePath:String)
		Return TSnapshotText(includes.ValueForKey(includePath.ToLower()))
	End Method

	Method ResolveInterface:TSnapshotText(importingPath:String, target:String, isFileImport:Int, isFramework:Int)
		Return TSnapshotText(interfaces.ValueForKey(target.ToLower()))
	End Method

	Method ResolveCoreInterface:TSnapshotText(targetPlatform:String)
		Return core
	End Method

	Method ResolveGenericTemplate:TSnapshotText(interfacePath:String, artifactReference:String)
		Return TSnapshotText(genericTemplates.ValueForKey(artifactReference.ToLower()))
	End Method
End Type

Function TestOptions:TCompilerOptions()
	Local options:TCompilerOptions = New TCompilerOptions
	options.sdkPath = "sdk"
	options.buildMode = "release"
	options.targetPlatform = "test"
	options.targetArchitecture = "x64"
	options.conditionalSymbols = ["test", "x64", "ptr64", "threaded", "bmxng"]
	options.requireCoreInterface = True
	Return options
End Function

Function DebugTestOptions:TCompilerOptions()
	Local options:TCompilerOptions = TestOptions()
	options.buildMode = "debug"
	Return options
End Function

Local resolver:TCompilerTestResolver = New TCompilerTestResolver
resolver.core = TSnapshotText.Create("sdk/blitz_classes.i", "Object^Null{~n-ToString:String()=~qbbObjectToString~q~n-Compare:Int(other:Object)=~qbbObjectCompare~q~n-SendMessage:Object(message:Object,source:Object)=~qbbObjectSendMessage~q~n-HashCode:UInt()=~qbbObjectHashCode~q~n-Equals:Int(other:Object)=~qbbObjectEquals~q~n}=~qbbObjectClass~q~nString^Object{~n@length%~n-ToString:String()=~qbbStringToString~q~n-Find:Int(subString:String,startIndex:Int=0)=~qbbStringFind~q~n-Replace:String(subString:String,withString:String)=~qbbStringReplace~q~n+FromInt:String(value:Int)=~qbbStringFromInt~q~n}AF=~qbbStringClass~q~n___Array^Object{~n@length%~n}AF=~qbbArrayClass~q")
resolver.AddInterface("brl.blitz", "sdk/brl.blitz.i", "superstrict")
resolver.AddInterface("brl.range", "sdk/brl.range.i", "superstrict~nRangeEndpoint^Null{~n+Open:RangeEndpoint()=~qbrl_range_RangeEndpoint_Open~q~n+FromStart:RangeEndpoint(coordinate%)=~qbrl_range_RangeEndpoint_FromStart__Bint~q~n+FromEnd:RangeEndpoint(distance%)=~qbrl_range_RangeEndpoint_FromEnd__Bint~q~n}S=~qbrl_range_RangeEndpoint~q~nRange^Null{~n+FromEndpoints:Range(startEndpoint:RangeEndpoint,endEndpoint:RangeEndpoint)=~qbrl_range_Range_FromEndpoints__NRangeEndpointE__NRangeEndpointE~q~n-ResolveStart%(length%)=~qbrl_range_Range_ResolveStart__Bint~q~n-ResolveEndExclusive%(length%)=~qbrl_range_Range_ResolveEndExclusive__Bint~q~n}S=~qbrl_range_Range~q")
Local receiverRelativeRange:TCompilerResult = TBlitzMaxCompiler.Compile("receiver-relative-range.bmx", "SuperStrict~nImport brl.range~nLocal source:String=~qabcdef~q~nLocal bounds:Range~nLocal sliced:String=source[bounds]", resolver, TestOptions())
Local receiverRelativeRangeDiagnostics:TCompilerDiagnostic[]
Local receiverRelativeRangeC:String = TBlitzMaxCompiler.EmitRuntimeC(receiverRelativeRange, receiverRelativeRangeDiagnostics)
Check(receiverRelativeRange.Succeeded() And receiverRelativeRangeDiagnostics.length = 0, "canonical Range slicing accepts receiver-relative start and end protocol methods")
Check(Contains(receiverRelativeRangeC, "brl_range_Range_ResolveStart__Bint") And Contains(receiverRelativeRangeC, "brl_range_Range_ResolveEndExclusive__Bint"), "Range slice lowering calls both receiver-relative bound methods")
Local rangeLiteralCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("range-literal.bmx", "SuperStrict~nImport brl.range~nLocal source:String=~qabcdef~q~nLocal selected:Range=1..^2~nLocal sliced:String=source[2..^1]", resolver, TestOptions())
Local rangeLiteralDiagnostics:TCompilerDiagnostic[]
Local rangeLiteralC:String = TBlitzMaxCompiler.EmitRuntimeC(rangeLiteralCompilation, rangeLiteralDiagnostics)
Check(rangeLiteralCompilation.Succeeded() And rangeLiteralDiagnostics.length = 0, "Range literals and direct from-end slices cross semantic binding and typed IR")
Check(Contains(rangeLiteralC, "brl_range_RangeEndpoint_FromStart__Bint") And Contains(rangeLiteralC, "brl_range_RangeEndpoint_FromEnd__Bint") And Contains(rangeLiteralC, "brl_range_Range_FromEndpoints"), "Range literal lowering uses the source-free BRL.Range construction contract")
Check(Contains(rangeLiteralC, "->length - (1)"), "direct String slicing resolves a from-end bound against receiver length")
Local missingRangeImport:TCompilerResult = TBlitzMaxCompiler.Compile("range-literal-missing-import.bmx", "SuperStrict~nLocal selected:Object=1..2", resolver, TestOptions())
Check(Not missingRangeImport.Succeeded() And HasLanguageDiagnostic(missingRangeImport, "BMX3350"), "Range literal syntax requires an explicit BRL.Range import")
Local gdbSource:String = "SuperStrict~nFunction SourceMapped:Int(value:Int)~nLocal nextValue:Int = value + 1~nReturn nextValue~nEnd Function"
Local gdbOptions:TCompilerOptions = TestOptions()
gdbOptions.gdbDebug = True
Local gdbCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("/workspace/gdb-source.bmx", gdbSource, resolver, gdbOptions)
Local gdbDiagnostics:TCompilerDiagnostic[]
Local gdbC:String = TBlitzMaxCompiler.EmitRuntimeC(gdbCompilation, gdbDiagnostics)
Check(gdbCompilation.Succeeded(), "gdb source-mapping fixture compiles")
Check(gdbDiagnostics.length = 0, "gdb source-mapping fixture emits runtime C without diagnostics")
Check(gdbCompilation.ir.gdbDebug, "typed IR retains the opt-in native source-mapping mode")
Check(Contains(gdbC, "#line 2 ~q/workspace/gdb-source.bmx~q") And Contains(gdbC, "#line 3 ~q/workspace/gdb-source.bmx~q") And Contains(gdbC, "#line 4 ~q/workspace/gdb-source.bmx~q"), "gdb C maps routine and statement boundaries back to one-based BlitzMax source lines")
Check(Contains(gdbC, "#line 1 ~q<bcc-generated>~q"), "gdb C resets compiler scaffolding so it cannot inherit a user source line")
Local ordinaryGdbControl:TCompilerResult = TBlitzMaxCompiler.Compile("/workspace/gdb-source.bmx", gdbSource, resolver, TestOptions())
Local ordinaryGdbControlDiagnostics:TCompilerDiagnostic[]
Local ordinaryGdbControlC:String = TBlitzMaxCompiler.EmitRuntimeC(ordinaryGdbControl, ordinaryGdbControlDiagnostics)
Check(ordinaryGdbControlDiagnostics.length = 0 And Not Contains(ordinaryGdbControlC, "#line "), "ordinary C output remains free of source directives unless -gdb is selected")
Local macConditionalSymbols:String[] = CompilerDefaultConditionalSymbols("macos", "arm64")
Local hasOsxConditional:Int
Local hasPtr64Conditional:Int
Local hasLongInt8Conditional:Int
Local hasBmxng2Conditional:Int
For Local conditionalSymbol:String = EachIn macConditionalSymbols
	If conditionalSymbol = "osx" Then hasOsxConditional = True
	If conditionalSymbol = "ptr64" Then hasPtr64Conditional = True
	If conditionalSymbol = "longint8" Then hasLongInt8Conditional = True
	If conditionalSymbol = "bmxng2" Then hasBmxng2Conditional = True
Next
Check(hasOsxConditional, "macOS compiler options retain the production ?osx conditional alias")
Check(hasPtr64Conditional And hasLongInt8Conditional, "arm64 compiler options select the native pointer and LongInt widths")
Check(hasBmxng2Conditional, "bcc2 compiler options always expose the intrinsic bmxng2 language-generation symbol")
Local crossTargetSymbols:String[] = CompilerDefaultConditionalSymbols("win32", "x64", "debug", "console", False, True, True, False, "feature,disabled=0,enabled=1")
Local hasWin64Conditional:Int
Local hasWin32X64Conditional:Int
Local hasCrossPtr64Conditional:Int
Local hasLongInt4Conditional:Int
Local hasLittleEndianConditional:Int
Local hasConsoleConditional:Int
Local hasDebugConditional:Int
Local hasCoverageConditional:Int
Local hasGdbDebugConditional:Int
Local hasFeatureConditional:Int
Local hasEnabledConditional:Int
Local hasDisabledConditional:Int
Local hasThreadedConditional:Int
For Local conditionalSymbol:String = EachIn crossTargetSymbols
	Select conditionalSymbol
		Case "win64" hasWin64Conditional = True
		Case "win32x64" hasWin32X64Conditional = True
		Case "ptr64" hasCrossPtr64Conditional = True
		Case "longint4" hasLongInt4Conditional = True
		Case "littleendian" hasLittleEndianConditional = True
		Case "console" hasConsoleConditional = True
		Case "debug" hasDebugConditional = True
		Case "coverage" hasCoverageConditional = True
		Case "gdbdebug" hasGdbDebugConditional = True
		Case "feature" hasFeatureConditional = True
		Case "enabled" hasEnabledConditional = True
		Case "disabled" hasDisabledConditional = True
		Case "threaded" hasThreadedConditional = True
	End Select
Next
Check(hasWin64Conditional And hasWin32X64Conditional And hasCrossPtr64Conditional And hasLongInt4Conditional And hasLittleEndianConditional, "win32/x64 cross-target options expose production platform, pointer, LongInt and endian aliases")
Check(hasConsoleConditional And hasDebugConditional And hasCoverageConditional And hasGdbDebugConditional And hasFeatureConditional And hasEnabledConditional And Not hasDisabledConditional And Not hasThreadedConditional, "application, build, instrumentation, user-definition and threading conditionals follow the selected bmk configuration")
Local win64TargetSymbols:String[] = CompilerDefaultConditionalSymbols("win64", "x64")
Check(HasConditionalSymbol(win64TargetSymbols, "win32x64") And HasConditionalSymbol(win64TargetSymbols, "win64"), "legacy win64/x64 target spelling retains the production win32x64 alias")
Local androidTargetSymbols:String[] = CompilerDefaultConditionalSymbols("android", "arm64v8a")
Check(HasConditionalSymbol(androidTargetSymbols, "androidarm") And HasConditionalSymbol(androidTargetSymbols, "androidarm64v8a") And HasConditionalSymbol(androidTargetSymbols, "linuxarm") And HasConditionalSymbol(androidTargetSymbols, "linuxarm64") And HasConditionalSymbol(androidTargetSymbols, "ptr64") And HasConditionalSymbol(androidTargetSymbols, "opengles"), "Android cross-target options expose their production Android, Linux-family, pointer and GLES aliases")
Local iosTargetSymbols:String[] = CompilerDefaultConditionalSymbols("ios", "arm64")
Check(HasConditionalSymbol(iosTargetSymbols, "iosarm64") And HasConditionalSymbol(iosTargetSymbols, "macosarm64") And HasConditionalSymbol(iosTargetSymbols, "opengles"), "iOS cross-target options retain the production iOS, macOS-family and GLES aliases")
Local riscvTargetSymbols:String[] = CompilerDefaultConditionalSymbols("linux", "riscv32")
Check(HasConditionalSymbol(riscvTargetSymbols, "linuxriscv32") And HasConditionalSymbol(riscvTargetSymbols, "ptr32"), "Linux RISC-V cross-target options retain their combined target and pointer-width aliases")
Local haikuArm64TargetSymbols:String[] = CompilerDefaultConditionalSymbols("haiku", "arm64")
Check(HasConditionalSymbol(haikuArm64TargetSymbols, "haikuarm64") And HasConditionalSymbol(haikuArm64TargetSymbols, "ptr64"), "Haiku arm64 bootstrap options expose their combined target and pointer-width aliases")
Local supportedDesktopTargets:String[] = ["macos/x86", "macos/x64", "macos/ppc", "macos/arm64", "win32/x86", "win32/x64", "win32/armv7", "win32/arm64", "linux/x86", "linux/x64", "linux/arm", "linux/arm64", "linux/riscv32", "linux/riscv64", "haiku/x86", "haiku/x64", "haiku/arm64"]
For Local supportedTarget:String = EachIn supportedDesktopTargets
	Local supportedParts:String[] = supportedTarget.Split("/")
	Check(CompilerTargetSupported(supportedParts[0], supportedParts[1]), "compiler accepts bmk desktop target " + supportedTarget)
Next
Local rejectedDesktopTargets:String[] = ["macos/riscv64", "win32/arm", "linux/ppc", "windows/x64", "linux/unknown"]
For Local rejectedTarget:String = EachIn rejectedDesktopTargets
	Local rejectedParts:String[] = rejectedTarget.Split("/")
	Check(Not CompilerTargetSupported(rejectedParts[0], rejectedParts[1]), "compiler rejects unsupported desktop target " + rejectedTarget)
Next

Local stdcallSource:String = "SuperStrict~nModule Acme.StdCall~nExtern ~qWin32~q~nFunction NativeAdd:Int(value:Int)=~qnative_add~q~nEnd Extern~nExtern ~qOs~q~nFunction NativeOs:Int(value:Int)=~qnative_os~q~nEnd Extern~nGlobal NativeCallback:Int(value:Int) ~qWin32~q~nFunction SourceCallback:Int(value:Int) ~qWin32~q~nReturn value~nEnd Function~nFunction ExplicitStdCall:Int(value:Int) StdCall~nReturn value~nEnd Function~nFunction Factory:Int(value:Int) ~qWin32~q(seed:Int) ~qWin32~q~nReturn SourceCallback~nEnd Function~nFunction Invoke:Int(value:Int)~nReturn NativeCallback(value)+NativeAdd(value)+NativeOs(value)+SourceCallback(value)+ExplicitStdCall(value)~nEnd Function"
Local stdcallResolver:TCompilerTestResolver = New TCompilerTestResolver
stdcallResolver.core = resolver.core
stdcallResolver.AddInterface("brl.blitz", "sdk/brl.blitz.i", "superstrict")
Local win32StdCallOptions:TCompilerOptions = TestOptions()
win32StdCallOptions.targetPlatform = "win32"
win32StdCallOptions.targetArchitecture = "x86"
win32StdCallOptions.conditionalSymbols = CompilerDefaultConditionalSymbols("win32", "x86")
Local win32StdCall:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/stdcall.mod/stdcall.bmx", stdcallSource, stdcallResolver, win32StdCallOptions)
Local win32StdCallDiagnostics:TCompilerDiagnostic[]
Local win32StdCallC:String = TBlitzMaxCompiler.EmitRuntimeC(win32StdCall, win32StdCallDiagnostics)
Local win32StdCallInterfaceDiagnostics:TCompilerDiagnostic[]
Local win32StdCallInterface:String = TBlitzMaxCompiler.EmitInterface(win32StdCall, win32StdCallInterfaceDiagnostics)
Check(win32StdCall.Succeeded() And win32StdCallDiagnostics.length = 0 And win32StdCallInterfaceDiagnostics.length = 0, "Win32/x86 accepts routine and callable-value stdcall declarations")
Check(win32StdCall.ir.externalFunctions.length = 2 And win32StdCall.ir.externalFunctions[0].callingConvention = "stdcall" And win32StdCall.ir.externalFunctions[1].callingConvention = "stdcall", "typed IR retains Win32 and Os routine ABI")
Check(Occurrences(TCompilerIrDumper.Dump(win32StdCall.ir), "[stdcall]") >= 6, "typed IR diagnostics expose stdcall routines, callable storage, and indirect dispatch")
Check(Contains(win32StdCallC, "__stdcall native_add(") And Contains(win32StdCallC, "__stdcall native_os(") And Contains(win32StdCallC, "(__stdcall *acme_stdcall_NativeCallback)(") And Contains(win32StdCallC, "__stdcall acme_stdcall_SourceCallback(") And Contains(win32StdCallC, "__stdcall acme_stdcall_ExplicitStdCall(") And Contains(win32StdCallC, "(__stdcall *__stdcall ") And Contains(win32StdCallC, "Factory"), "Win32/x86 C preserves stdcall on native routines, source routines, callable returns, and callable storage")
Check(Contains(win32StdCallInterface, "NativeAdd%(value%)W=~qnative_add~q") And Contains(win32StdCallInterface, "NativeOs%(value%)W=~qnative_os~q") And Contains(win32StdCallInterface, "NativeCallback%(value%)W&=mem:p(") And Contains(win32StdCallInterface, "SourceCallback%(value%)W=") And Contains(win32StdCallInterface, "ExplicitStdCall%(value%)W=") And Contains(win32StdCallInterface, "Factory%(value%)W(seed%)W="), "compact interfaces preserve routine, callable-return, and callable-value stdcall flags")
Local portableWin32ExternSource:String = "SuperStrict~nModule Acme.PortableWin32Extern~nExtern ~qwin32~q~nFunction NativeOne:Int(value:Int)=~qnative_one~q~nEnd Extern"
Local portableWin32Extern:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/portablewin32extern.mod/portablewin32extern.bmx", portableWin32ExternSource, stdcallResolver, win32StdCallOptions)
Local portableWin32ExternDiagnostics:TCompilerDiagnostic[]
Local portableWin32ExternC:String = TBlitzMaxCompiler.EmitRuntimeC(portableWin32Extern, portableWin32ExternDiagnostics)
Check(portableWin32Extern.Succeeded() And portableWin32ExternDiagnostics.length = 0 And portableWin32Extern.ir.externalFunctions.length = 1 And portableWin32Extern.ir.externalFunctions[0].callingConvention = "stdcall" And Contains(portableWin32ExternC, "__stdcall native_one("), "Win32-targeted Extern win32 lowers to stdcall")
Local portableMacExtern:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/portablewin32extern.mod/portablewin32extern.bmx", portableWin32ExternSource, stdcallResolver, TestOptions())
Local portableMacExternDiagnostics:TCompilerDiagnostic[]
Local portableMacExternC:String = TBlitzMaxCompiler.EmitRuntimeC(portableMacExtern, portableMacExternDiagnostics)
Check(portableMacExtern.Succeeded() And portableMacExternDiagnostics.length = 0 And portableMacExtern.ir.externalFunctions.length = 1 And portableMacExtern.ir.externalFunctions[0].callingConvention = "c" And Not Contains(portableMacExternC, "__stdcall"), "non-Windows Extern win32 collapses to the platform C convention")
Local conditionalStdCallSource:String = "SuperStrict~nModule Acme.ConditionalStdCall~n?win32~nExtern ~qwin32~q~n?linux~nExtern~n?macos~nExtern~n?~nFunction NativeTwo:Int(value:Int)=~qnative_two~q~nEnd Extern"
Local conditionalStdCall:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/conditionalstdcall.mod/conditionalstdcall.bmx", conditionalStdCallSource, stdcallResolver, win32StdCallOptions)
Local conditionalStdCallDiagnostics:TCompilerDiagnostic[]
Local conditionalStdCallC:String = TBlitzMaxCompiler.EmitRuntimeC(conditionalStdCall, conditionalStdCallDiagnostics)
Check(conditionalStdCall.Succeeded() And conditionalStdCallDiagnostics.length = 0 And conditionalStdCall.ir.externalFunctions.length = 1 And conditionalStdCall.ir.externalFunctions[0].callingConvention = "stdcall" And Contains(conditionalStdCallC, "__stdcall native_two("), "shared conditional Extern bodies preserve the active Win32 ABI")
Local conditionalMacOptions:TCompilerOptions = TestOptions()
conditionalMacOptions.targetPlatform = "macos"
conditionalMacOptions.targetArchitecture = "arm64"
conditionalMacOptions.conditionalSymbols = CompilerDefaultConditionalSymbols("macos", "arm64")
Local conditionalMacExtern:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/conditionalstdcall.mod/conditionalstdcall.bmx", conditionalStdCallSource, stdcallResolver, conditionalMacOptions)
Local conditionalMacExternDiagnostics:TCompilerDiagnostic[]
Local conditionalMacExternC:String = TBlitzMaxCompiler.EmitRuntimeC(conditionalMacExtern, conditionalMacExternDiagnostics)
Check(conditionalMacExtern.Succeeded() And conditionalMacExternDiagnostics.length = 0 And conditionalMacExtern.ir.externalFunctions.length = 1 And conditionalMacExtern.ir.externalFunctions[0].callingConvention = "c" And Not Contains(conditionalMacExternC, "__stdcall"), "shared conditional Extern bodies preserve the active macOS ABI")
Local conditionalBoundarySource:String = "SuperStrict~nLocal total:Long~n?ptr64~nFunction PlatformWidth:Long()~n?Not ptr64~nFunction PlatformWidth:Int()~n?~nReturn 64~nEnd Function~n?ptr64~nFor Local index:Long=0 Until 2~n?Not ptr64~nFor Local index:Int=0 Until 2~n?~n?ptr64~nIf index<2~n?Not ptr64~nIf Int(index)<2~n?~ntotal:+index+PlatformWidth()~nElse~ntotal:-1~nEnd If~nNext"
Local conditionalBoundary64:TCompilerResult = TBlitzMaxCompiler.Compile("conditional-boundaries-64.bmx", conditionalBoundarySource, resolver, TestOptions())
Check(conditionalBoundary64.Succeeded(), "Ptr64 compilation accepts conditional routine, For and If headers with shared bodies and terminators: " + CompilerDiagnosticSummary(conditionalBoundary64))
Local conditionalBoundary32Options:TCompilerOptions = TestOptions()
conditionalBoundary32Options.targetArchitecture = "x86"
conditionalBoundary32Options.conditionalSymbols = ["test", "x86", "ptr32", "bmxng"]
Local conditionalBoundary32:TCompilerResult = TBlitzMaxCompiler.Compile("conditional-boundaries-32.bmx", conditionalBoundarySource, resolver, conditionalBoundary32Options)
Check(conditionalBoundary32.Succeeded(), "Ptr32 compilation accepts conditional routine, For and If headers with shared bodies and terminators: " + CompilerDiagnosticSummary(conditionalBoundary32))
Local selectedInvalidSource:String = "SuperStrict~n?debug~nLocal selected:Int=MissingRoutine()~n?Not debug~nLocal selected:Int=1~n?"
Local selectedInvalidRelease:TCompilerResult = TBlitzMaxCompiler.Compile("conditional-selected-invalid.bmx", selectedInvalidSource, resolver, TestOptions())
Check(selectedInvalidRelease.Succeeded(), "semantic errors in an inactive conditional branch do not reject the selected configuration: " + CompilerDiagnosticSummary(selectedInvalidRelease))
Local selectedInvalidDebugOptions:TCompilerOptions = DebugTestOptions()
selectedInvalidDebugOptions.conditionalSymbols :+ ["debug"]
Local selectedInvalidDebug:TCompilerResult = TBlitzMaxCompiler.Compile("conditional-selected-invalid.bmx", selectedInvalidSource, resolver, selectedInvalidDebugOptions)
Check(Not selectedInvalidDebug.Succeeded(), "the same semantic error is diagnosed when its conditional branch is active: " + CompilerDiagnosticSummary(selectedInvalidDebug))
Local arbitraryConditionalSource:String = "SuperStrict~nFunction Choose:Int()~nLocal value:Int = 1 + ..~n?debug~n2~n?Not debug~n3~n?~nTry~nvalue:+1~n?debug~nCatch problem:Object~n?Not debug~nCatch problem:String~n?~nvalue:+2~nEnd Try~nReturn value~nEnd Function~n?bmxng~nStruct TConfiguredValue~n?Not bmxng~nType TConfiguredValue~n?~nField value:Int~n?bmxng~nEnd Struct~n?Not bmxng~nEnd Type~n?"
Local arbitraryConditionalDebugOptions:TCompilerOptions = DebugTestOptions()
arbitraryConditionalDebugOptions.conditionalSymbols :+ ["debug"]
Local arbitraryConditionalDebug:TCompilerResult = TBlitzMaxCompiler.Compile("arbitrary-conditional-debug.bmx", arbitraryConditionalSource, resolver, arbitraryConditionalDebugOptions)
Check(arbitraryConditionalDebug.Succeeded(), "configured compiler parsing accepts conditional lines inside expressions, Catch headers and Type/Struct declarations: " + CompilerDiagnosticSummary(arbitraryConditionalDebug))
Check(Not SnapshotHasConditionalRegion(arbitraryConditionalDebug.analysis.snapshot), "configured compiler snapshots contain no conditional-region syntax")
Local arbitraryConditionalRelease:TCompilerResult = TBlitzMaxCompiler.Compile("arbitrary-conditional-release.bmx", arbitraryConditionalSource, resolver, TestOptions())
Check(arbitraryConditionalRelease.Succeeded(), "the alternative configured compiler view accepts the same arbitrary conditional boundaries: " + CompilerDiagnosticSummary(arbitraryConditionalRelease))
Local arbitraryInvalidSource:String = "SuperStrict~n?debug~nLocal selected:Int=1+~n?Not debug~nLocal selected:Int=1~n?"
Check(TBlitzMaxCompiler.Compile("arbitrary-invalid-release.bmx", arbitraryInvalidSource, resolver, TestOptions()).Succeeded(), "inactive invalid syntax is removed before configured compiler parsing")
Check(Not TBlitzMaxCompiler.Compile("arbitrary-invalid-debug.bmx", arbitraryInvalidSource, resolver, arbitraryConditionalDebugOptions).Succeeded(), "active invalid syntax is rejected after configured compiler parsing")
resolver.AddInclude("configured-include.bmx", "Local included:Int = 1 + ..~n?debug~n2~n?Not debug~n3~n?")
Local configuredInclude:TCompilerResult = TBlitzMaxCompiler.Compile("configured-include-root.bmx", "SuperStrict~nInclude ~qconfigured-include.bmx~q~nLocal copied:Int=included", resolver, arbitraryConditionalDebugOptions)
Check(configuredInclude.Succeeded(), "configured conditional token selection is applied to included source documents: " + CompilerDiagnosticSummary(configuredInclude))
Check(Not SnapshotHasConditionalRegion(configuredInclude.analysis.snapshot), "configured compiler root and included documents contain no conditional-region syntax")
Local allBranchesOptions:TCompilationSnapshotOptions = arbitraryConditionalDebugOptions.SnapshotOptions()
allBranchesOptions.parseConfiguredConditionals = False
Local allBranchesAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("all-branches-compiler-invariant.bmx", "SuperStrict~n?debug~nLocal value:Int=1~n?", resolver, allBranchesOptions)
Check(HasDiagnostic(TBlitzMaxCompiler.ConfiguredSyntaxDiagnostics(allBranchesAnalysis), "BMXC0002"), "the compiler entry boundary rejects an all-branches syntax tree")
Local allBranchesLoweringDiagnostics:TCompilerDiagnostic[]
TCompilerIrLowerer.Lower(allBranchesAnalysis, arbitraryConditionalDebugOptions, allBranchesLoweringDiagnostics)
Check(HasDiagnostic(allBranchesLoweringDiagnostics, "BMXC0002"), "IR lowering rejects an all-branches syntax tree instead of selecting conditionals again")
stdcallResolver.AddInterface("acme.nativeabi", "/sdk/mod/acme.mod/nativeabi.mod/nativeabi.release.win32.x86.i", "superstrict~nNativeAdd%(value%)W=~qnative_add~q~nNativeCallback%(value%)W&=mem:p(~qnative_callback~q)")
Local importedStdCall:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/stdcallconsumer.mod/stdcallconsumer.bmx", "SuperStrict~nModule Acme.StdCallConsumer~nImport Acme.NativeAbi~nLocal result:Int=NativeAdd(1)+NativeCallback(2)", stdcallResolver, win32StdCallOptions)
Check(importedStdCall.Succeeded() And importedStdCall.ir.externalFunctions.length = 1 And importedStdCall.ir.externalFunctions[0].callingConvention = "stdcall" And importedStdCall.ir.externalGlobals.length = 1 And importedStdCall.ir.externalGlobals[0].callableCallingConvention = "stdcall", "compact-interface W flags reconstruct routine and callable-value ABI in a consumer")
Local sequencedImportedStdCall:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/stdcallsequence.mod/stdcallsequence.bmx", "SuperStrict~nModule Acme.StdCallSequence~nImport Acme.NativeAbi~nFunction NextValue:Int()~nReturn 2~nEnd Function~nLocal result:Int=NativeCallback(NextValue())", stdcallResolver, win32StdCallOptions)
Local sequencedImportedStdCallDiagnostics:TCompilerDiagnostic[]
Local sequencedImportedStdCallC:String = TBlitzMaxCompiler.EmitRuntimeC(sequencedImportedStdCall, sequencedImportedStdCallDiagnostics)
Check(sequencedImportedStdCall.Succeeded() And sequencedImportedStdCallDiagnostics.length = 0 And Contains(sequencedImportedStdCallC, "__typeof__(native_callback) bmx_tmp_t0;") And Not Contains(sequencedImportedStdCallC, "(__stdcall *bmx_tmp_t0)"), "sequenced Win32 callable Globals derive the complete header type instead of reconstructing the stdcall pointer")

Local win64StdCallOptions:TCompilerOptions = TestOptions()
win64StdCallOptions.targetPlatform = "win32"
win64StdCallOptions.targetArchitecture = "x64"
win64StdCallOptions.conditionalSymbols = CompilerDefaultConditionalSymbols("win32", "x64")
Local win64StdCall:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/stdcall.mod/stdcall.bmx", stdcallSource, stdcallResolver, win64StdCallOptions)
Local win64StdCallDiagnostics:TCompilerDiagnostic[]
Local win64StdCallC:String = TBlitzMaxCompiler.EmitRuntimeC(win64StdCall, win64StdCallDiagnostics)
Check(win64StdCall.Succeeded() And win64StdCallDiagnostics.length = 0 And Contains(win64StdCallC, "__stdcall native_add(") And Contains(win64StdCallC, "(__stdcall *acme_stdcall_NativeCallback)("), "Win32/x64 retains the declared ABI contract even though the native x64 ABI is unified")

Local nativeInterfaceSource:String = "SuperStrict~nModule Acme.NativeInterface~nExtern ~qWin32~q~nInterface IUnknown_~nMethod QueryInterface:Int(riid:Byte Ptr,value:IUnknown_ Var)~nMethod AddRef:Int()~nMethod Release_:Int()~nEnd Interface~nInterface IDispatch_ Extends IUnknown_~nMethod GetTypeInfoCount:Int(value:Int Var)~nEnd Interface~nEnd Extern~nFunction AddReference:Int(value:IUnknown_)~nReturn value.AddRef()~nEnd Function~nFunction TypeInfoCount:Int(value:IDispatch_)~nLocal count:Int~nvalue.GetTypeInfoCount(count)~nReturn count~nEnd Function~nFunction AsUnknown:IUnknown_(value:IDispatch_)~nReturn value~nEnd Function~nFunction EmptyUnknown:IUnknown_()~nReturn Null~nEnd Function"
Local nativeInterface:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nativeinterface.mod/nativeinterface.bmx", nativeInterfaceSource, stdcallResolver, win32StdCallOptions)
Local nativeInterfaceRuntimeDiagnostics:TCompilerDiagnostic[]
Local nativeInterfaceC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeInterface, nativeInterfaceRuntimeDiagnostics)
Local nativeInterfaceHeaderDiagnostics:TCompilerDiagnostic[]
Local nativeInterfaceHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(nativeInterface, nativeInterfaceHeaderDiagnostics)
Local nativeInterfaceCompactDiagnostics:TCompilerDiagnostic[]
Local nativeInterfaceCompact:String = TBlitzMaxCompiler.EmitInterface(nativeInterface, nativeInterfaceCompactDiagnostics)
Local nativeInterfaceDump:String = TCompilerIrDumper.Dump(nativeInterface.ir)
Check(nativeInterface.Succeeded() And nativeInterfaceRuntimeDiagnostics.length = 0 And nativeInterfaceHeaderDiagnostics.length = 0 And nativeInterfaceCompactDiagnostics.length = 0, "Win32/x86 native external Interfaces lower through typed IR")
Check(Contains(nativeInterfaceDump, "IUnknown_:IUnknown_ [external-native abi IUnknown_]") And Contains(nativeInterfaceDump, "IDispatch_:IDispatch_ [external-native abi IDispatch_] extends") And AppearsBefore(nativeInterfaceDump, "method %im2 Release_", "method %im3 GetTypeInfoCount"), "native Interface IR retains ownership and base-first COM slot order")
Check(Contains(nativeInterfaceHeader, "typedef struct IUnknown_ IUnknown_;") And Contains(nativeInterfaceHeader, "struct IUnknown_Vtbl {") And Contains(nativeInterfaceHeader, "struct IDispatch_Vtbl {") And Contains(nativeInterfaceHeader, "(__stdcall *QueryInterface)(struct IUnknown_ *, BBBYTE *, struct IUnknown_ * *);") And AppearsBefore(nativeInterfaceHeader, "*Release_)", "*GetTypeInfoCount)"), "native Interface headers publish forward declarations, inherited vtables, exact receiver types, Var pointers, and Win32 ABI")
Check(Contains(nativeInterfaceC, "->vtbl->AddRef((struct IUnknown_ *)") And Contains(nativeInterfaceC, "->vtbl->GetTypeInfoCount((struct IDispatch_ *)") And Not Contains(nativeInterfaceC, "bbObjectInterface") And Not Contains(nativeInterfaceC, "bbObjectRegisterInterface"), "native Interface calls dispatch directly through their externally compatible vtable without managed Interface machinery")
Check(Contains(nativeInterfaceC, "return ((struct IUnknown_ *)(bmx_p0_value));") And Contains(nativeInterfaceC, "return 0;"), "native Interface upcasts and Null use ordinary C pointer representation rather than a managed sentinel")
Check(Contains(nativeInterfaceCompact, "IUnknown_^Null{") And Contains(nativeInterfaceCompact, "}EI=0") And Contains(nativeInterfaceCompact, "value??IUnknown_") And Contains(nativeInterfaceCompact, ")WA=~qAddRef~q"), "compact interfaces publish native ownership, native reference encoding, and stdcall method slots")

Local nativeInterfacePointerSource:String = "SuperStrict~nModule Acme.NativeInterfacePointers~nExtern ~qWin32~q~nInterface INativeSurface~nMethod CreateSurface(surface:INativeSurface Ptr)~nEnd Interface~nEnd Extern~nGlobal CreateNative(surface:INativeSurface Ptr) ~qWin32~q~nGlobal EnumerateNative(callback(surface:INativeSurface Ptr,context:Byte Ptr),context:Byte Ptr) ~qWin32~q"
Local nativeInterfacePointers:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nativeinterfacepointers.mod/nativeinterfacepointers.bmx", nativeInterfacePointerSource, stdcallResolver, win32StdCallOptions)
Local nativeInterfacePointerDiagnostics:TCompilerDiagnostic[]
Local nativeInterfacePointerC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeInterfacePointers, nativeInterfacePointerDiagnostics)
Check(nativeInterfacePointers.Succeeded() And nativeInterfacePointerDiagnostics.length = 0, "Win32 native Interface pointers and nested callback parameters lower through typed IR")
Check(Contains(nativeInterfacePointerC, "struct INativeSurface * *") And Contains(nativeInterfacePointerC, "(__stdcall *acme_nativeinterfacepointers_CreateNative)") And Contains(nativeInterfacePointerC, "(__stdcall *acme_nativeinterfacepointers_EnumerateNative)") And Contains(nativeInterfacePointerC, "void (*)(struct INativeSurface * *, BBBYTE *)"), "Win32 C preserves native Interface pointer depth and nested callback storage ABI")

stdcallResolver.AddInterface("acme.nativeinterface", "/sdk/mod/acme.mod/nativeinterface.mod/nativeinterface.release.win32.x86.i", nativeInterfaceCompact)
Local nativeInterfaceConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nativeconsumer.mod/nativeconsumer.bmx", "SuperStrict~nModule Acme.NativeConsumer~nImport Acme.NativeInterface~nFunction Consume:Int(value:IDispatch_)~nReturn value.AddRef()~nEnd Function", stdcallResolver, win32StdCallOptions)
Local nativeInterfaceConsumerDiagnostics:TCompilerDiagnostic[]
Local nativeInterfaceConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeInterfaceConsumer, nativeInterfaceConsumerDiagnostics)
Check(nativeInterfaceConsumer.Succeeded(), "source-free native Interface consumer compiles: " + CompilerDiagnosticSummary(nativeInterfaceConsumer))
Check(nativeInterfaceConsumerDiagnostics.length = 0, "source-free native Interface consumer emits C without diagnostics")
Check(Contains(nativeInterfaceConsumerC, "->vtbl->AddRef((struct IUnknown_ *)") And Not Contains(nativeInterfaceConsumerC, "bbObjectInterface"), "a source-free compact consumer reconstructs native Interface inheritance and direct dispatch: " + nativeInterfaceConsumerC)

Local nativeInterfaceWin64:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nativeinterface.mod/nativeinterface.bmx", nativeInterfaceSource, stdcallResolver, win64StdCallOptions)
Local nativeInterfaceWin64Diagnostics:TCompilerDiagnostic[]
Local nativeInterfaceWin64Header:String = TBlitzMaxCompiler.EmitRuntimeHeader(nativeInterfaceWin64, nativeInterfaceWin64Diagnostics)
Check(nativeInterfaceWin64.Succeeded() And nativeInterfaceWin64Diagnostics.length = 0 And Contains(nativeInterfaceWin64Header, "(__stdcall *AddRef)(struct IUnknown_ *)"), "Win32/x64 structurally retains the declared COM calling convention pending native Windows validation")

Local macStdCallOptions:TCompilerOptions = TestOptions()
macStdCallOptions.targetPlatform = "macos"
macStdCallOptions.targetArchitecture = "arm64"
macStdCallOptions.conditionalSymbols = CompilerDefaultConditionalSymbols("macos", "arm64")
Local aliasConventionSource:String = "SuperStrict~nModule Acme.StdCall~nExtern ~qWin32~q~nFunction NativeAdd:Int(value:Int)=~qnative_add~q~nEnd Extern~nExtern ~qOs~q~nFunction NativeOs:Int(value:Int)=~qnative_os~q~nEnd Extern~nGlobal NativeCallback:Int(value:Int) ~qWin32~q"
Local macStdCall:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/stdcall.mod/stdcall.bmx", aliasConventionSource, stdcallResolver, macStdCallOptions)
Local macStdCallDiagnostics:TCompilerDiagnostic[]
Local macStdCallC:String = TBlitzMaxCompiler.EmitRuntimeC(macStdCall, macStdCallDiagnostics)
Local macStdCallInterfaceDiagnostics:TCompilerDiagnostic[]
Local macStdCallInterface:String = TBlitzMaxCompiler.EmitInterface(macStdCall, macStdCallInterfaceDiagnostics)
Check(macStdCall.Succeeded() And macStdCallDiagnostics.length = 0 And macStdCallInterfaceDiagnostics.length = 0, "non-Windows targets accept portable Win32/Os declarations as cdecl")
Check(Not Contains(macStdCallC, "__stdcall") And Not Contains(macStdCallInterface, ")W"), "Win32 and Os convention aliases collapse to cdecl away from Windows")
Local invalidExternConvention:TCompilerResult = TBlitzMaxCompiler.Compile("invalid-extern-convention.bmx", "SuperStrict~nExtern ~qPascal~q~nFunction Native()~nEnd Extern", stdcallResolver, win32StdCallOptions)
Check(Not invalidExternConvention.Succeeded() And HasLanguageDiagnostic(invalidExternConvention, "BMX3016"), "unknown Extern calling conventions diagnose instead of silently becoming cdecl")
Local invalidCallableConvention:TCompilerResult = TBlitzMaxCompiler.Compile("invalid-callable-convention.bmx", "SuperStrict~nGlobal callback:Int(value:Int) ~qPascal~q", stdcallResolver, win32StdCallOptions)
Check(Not invalidCallableConvention.Succeeded() And HasLanguageDiagnostic(invalidCallableConvention, "BMX3119"), "unknown callable-value calling conventions diagnose instead of silently becoming cdecl")
Local applicationImportSdk:String = "/tmp/bcc2-application-imports-" + MilliSecs()
CreateDir(applicationImportSdk + "/mod/brl.mod/zeta.mod", True)
CreateDir(applicationImportSdk + "/mod/brl.mod/alpha.mod", True)
CreateDir(applicationImportSdk + "/mod/brl.mod/blitz.mod", True)
CreateDir(applicationImportSdk + "/mod/brl.mod/appstub.mod", True)
CreateDir(applicationImportSdk + "/mod/brl.mod/missing.mod", True)
CreateDir(applicationImportSdk + "/mod/pub.mod/beta.mod", True)
SaveText("SuperStrict", applicationImportSdk + "/mod/brl.mod/zeta.mod/zeta.bmx")
SaveText("SuperStrict", applicationImportSdk + "/mod/brl.mod/alpha.mod/alpha.bmx")
SaveText("SuperStrict", applicationImportSdk + "/mod/brl.mod/blitz.mod/blitz.bmx")
SaveText("SuperStrict", applicationImportSdk + "/mod/brl.mod/appstub.mod/appstub.bmx")
SaveText("SuperStrict", applicationImportSdk + "/mod/pub.mod/beta.mod/beta.bmx")
Local applicationImports:String[] = CompilerDefaultApplicationImports(applicationImportSdk)
Check(applicationImports.length = 3 And applicationImports[0] = "brl.alpha" And applicationImports[1] = "brl.zeta" And applicationImports[2] = "pub.beta", "default application imports deterministically include source-backed BRL/Pub modules while excluding brl.blitz, brl.appstub and directories without a module source")
DeleteDir(applicationImportSdk, True)
Local snapshotCachePath:String = "/tmp/bcc2-snapshot-text-cache-" + MilliSecs() + ".i"
SaveText("alpha", snapshotCachePath)
Local snapshotTextCache:TCompilerSnapshotTextCache = New TCompilerSnapshotTextCache
Local cachedSnapshot1:TSnapshotText = snapshotTextCache.Load(snapshotCachePath)
Local cachedSnapshot2:TSnapshotText = snapshotTextCache.Load(snapshotCachePath)
Check(cachedSnapshot1.text = "alpha" And cachedSnapshot2.text = "alpha" And snapshotTextCache.misses = 1 And snapshotTextCache.hits = 1, "build-scoped snapshot text is loaded once and reused while file freshness is unchanged")
SaveText("changed", snapshotCachePath)
Local cachedSnapshot3:TSnapshotText = snapshotTextCache.Load(snapshotCachePath)
Check(cachedSnapshot3.text = "changed" And snapshotTextCache.misses = 2, "snapshot text cache observes a same-build file size change without explicit invalidation")
SaveText("bravo!", snapshotCachePath)
snapshotTextCache.Invalidate(snapshotCachePath)
Local cachedSnapshot4:TSnapshotText = snapshotTextCache.Load(snapshotCachePath)
Check(cachedSnapshot4.text = "bravo!" And snapshotTextCache.misses = 3, "explicit publication invalidation handles same-length changes within filesystem timestamp resolution")
DeleteFile(snapshotCachePath)
Local interfaceCachePath:String = "/tmp/bcc2-interface-parse-cache-" + MilliSecs() + ".i"
SaveText("superstrict~nValue%=~qvalue~q", interfaceCachePath)
Local cachedInterface1:TSnapshotText = snapshotTextCache.LoadInterface(interfaceCachePath)
Local cachedInterface2:TSnapshotText = snapshotTextCache.LoadInterface(interfaceCachePath)
Check(cachedInterface1.interfaceFile <> cachedInterface2.interfaceFile And cachedInterface1.interfaceFile.declarations[0] <> cachedInterface2.interfaceFile.declarations[0], "parsed interface cache returns a request-owned file and record graph")
cachedInterface1.interfaceFile.declarations[0].documentationPath = "request-one"
cachedInterface1.interfaceFile.AddDeclaration(New TInterfaceRecord)
Check(cachedInterface2.interfaceFile.declarations.length = 1 And Not cachedInterface2.interfaceFile.declarations[0].documentationPath.length, "request-local interface mutation cannot leak through the parsed cache")
Check(snapshotTextCache.interfaceParseMisses = 1 And snapshotTextCache.interfaceParseHits = 1, "an unchanged interface is parsed once and cloned on reuse")
Local resolverCache:TCompilerSnapshotTextCache = New TCompilerSnapshotTextCache
Local resolverOptions:TCompilerOptions = TestOptions()
Local requestResolver1:TCompilerFileSnapshotResolver = TCompilerFileSnapshotResolver.Create(resolverOptions, resolverCache)
Local requestInterface1:TSnapshotText = requestResolver1.LoadInterfaceSnapshot(interfaceCachePath)
Local requestInterface2:TSnapshotText = requestResolver1.LoadInterfaceSnapshot(interfaceCachePath)
Local requestResolver2:TCompilerFileSnapshotResolver = TCompilerFileSnapshotResolver.Create(resolverOptions, resolverCache)
Local nextRequestInterface:TSnapshotText = requestResolver2.LoadInterfaceSnapshot(interfaceCachePath)
Check(requestInterface1 = requestInterface2 And resolverCache.interfaceResolutionHits = 1, "one compilation request reuses its resolved interface clone across repeated transitive import edges")
Check(nextRequestInterface <> requestInterface1 And nextRequestInterface.interfaceFile <> requestInterface1.interfaceFile, "separate compilation requests retain isolated mutable interface graphs")
SaveText("superstrict~nValue%=~qother~q", interfaceCachePath)
snapshotTextCache.Invalidate(interfaceCachePath)
Local cachedInterface3:TSnapshotText = snapshotTextCache.LoadInterface(interfaceCachePath)
Check(cachedInterface3.interfaceFile.declarations[0].externalName = "other" And snapshotTextCache.interfaceParseMisses = 2, "interface publication invalidation replaces a same-length parsed cache entry")
DeleteFile(interfaceCachePath)
Local templateCachePath:String = "/tmp/bcc2-template-decode-cache-" + MilliSecs() + ".bmxgt"
Local templateCacheArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
templateCacheArtifact.identity = New TGenericTemplateIdentity
templateCacheArtifact.identity.moduleName = "example.cache"
templateCacheArtifact.identity.qualifiedName = "TBox"
templateCacheArtifact.identity.arity = 0
templateCacheArtifact.languageLinkageRevision = COMPILER_GENERIC_LANGUAGE_LINKAGE_REVISION
Local templateCacheDiagnostics:String[]
Local templateCacheText:String = TGenericTemplateArtifactCodec.Encode(templateCacheArtifact, templateCacheDiagnostics)
SaveText(templateCacheText, templateCachePath)
Local cachedTemplate1:TSnapshotText = snapshotTextCache.LoadGenericTemplate(templateCachePath)
Local cachedTemplate2:TSnapshotText = snapshotTextCache.LoadGenericTemplate(templateCachePath)
Check(templateCacheDiagnostics.length = 0 And cachedTemplate1.genericTemplateArtifact And cachedTemplate1.genericTemplateArtifact = cachedTemplate2.genericTemplateArtifact, "decoded generic template cache shares one immutable artifact")
Check(snapshotTextCache.genericTemplateDecodeMisses = 1 And snapshotTextCache.genericTemplateDecodeHits = 1, "an unchanged generic template artifact is decoded once per build")
SaveText("invalid generic template", templateCachePath)
snapshotTextCache.Invalidate(templateCachePath)
Local cachedTemplate3:TSnapshotText = snapshotTextCache.LoadGenericTemplate(templateCachePath)
Check(Not cachedTemplate3.genericTemplateArtifact And cachedTemplate3.genericTemplateDiagnostics.length = 1 And snapshotTextCache.genericTemplateDecodeMisses = 2, "generic template publication invalidation replaces the decoded cache entry and retains validation diagnostics")
DeleteFile(templateCachePath)
resolver.AddInterface("brl.blitz", "sdk/brl.blitz.i", "superstrict~nMilliSecs%()=~qbbMilliSecs~q~nbbMemAlloc@*(size%z)=~qbbMemAlloc~q~nbbMemFree(mem@*)=~qbbMemFree~q~nMemAlloc@*(size%z)=~qbrl_blitz_MemAlloc~q~nMemFree(mem@*)=~qbrl_blitz_MemFree~q~nWriteStdout(str$)=~qbbWriteStdout~q~nAppDir$&=mem:p(~qbbAppDir~q)~nAppArgs$&[]&=mem:p(~qbbAppArgs~q)~nCountObjectInstances%&=mem:p(~qbbCountInstances~q)~nICloseable^Object{~n-Close()A=~qbrl_blitz_ICloseable_Close~q~n}AI=~qbrl_blitz_ICloseable~q")
Local applicationSourceOptions:TCompilerOptions = TestOptions()
applicationSourceOptions.applicationBuild = True
applicationSourceOptions.applicationSourceUnit = True
applicationSourceOptions.applicationIdentity = "application.demo"
applicationSourceOptions.applicationType = "console"
applicationSourceOptions.sourceModuleName = "application.demo"
Local applicationSourceResult:TCompilerResult = TBlitzMaxCompiler.Compile("/work/common.bmx", "SuperStrict~nFunction CommonValue:Int()~nReturn 42~nEnd Function", resolver, applicationSourceOptions)
Local applicationSourceInterfaceDiagnostics:TCompilerDiagnostic[]
Local applicationSourceInterface:String = TBlitzMaxCompiler.EmitInterface(applicationSourceResult, applicationSourceInterfaceDiagnostics)
Local applicationSourceBackendDiagnostics:TCompilerDiagnostic[]
Local applicationSourceC:String = TBlitzMaxCompiler.EmitRuntimeC(applicationSourceResult, applicationSourceBackendDiagnostics)
Check(applicationSourceResult.Succeeded() And applicationSourceInterfaceDiagnostics.length = 0 And applicationSourceBackendDiagnostics.length = 0, "an application-owned quoted source lowers and publishes a compact private interface")
Check(applicationSourceResult.ir.initializationPlan.unitKind = IR_UNIT_MODULE And applicationSourceResult.ir.initializationPlan.unitName = "__bb_application_demo_common", "an application-owned quoted source has a deterministic non-main runtime unit")
Check(Contains(applicationSourceInterface, "CommonValue%()=~qapplication_demo_CommonValue~q") And Contains(applicationSourceC, "BBINT application_demo_CommonValue("), "application-owned declarations use the shared readable application linkage identity")
resolver.AddInterface("common.bmx", "/work/.bmx/common.bmx.release.test.x64.i", applicationSourceInterface)
Local applicationMainOptions:TCompilerOptions = TestOptions()
applicationMainOptions.applicationBuild = True
applicationMainOptions.applicationIdentity = "application.demo"
applicationMainOptions.applicationType = "console"
Local applicationMainResult:TCompilerResult = TBlitzMaxCompiler.Compile("/work/demo.bmx", "SuperStrict~nImport ~qcommon.bmx~q~nGlobal Result:Int = CommonValue()", resolver, applicationMainOptions)
Local applicationMainBackendDiagnostics:TCompilerDiagnostic[]
Local applicationMainC:String = TBlitzMaxCompiler.EmitRuntimeC(applicationMainResult, applicationMainBackendDiagnostics)
Check(applicationMainResult.Succeeded() And applicationMainBackendDiagnostics.length = 0 And applicationMainResult.ir.initializationPlan.unitKind = IR_UNIT_APPLICATION And applicationMainResult.ir.initializationPlan.unitName = "_bb_main", "the primary application retains the canonical _bb_main runtime unit")
Local applicationSourceDependency:TCompilerIrDependency
For Local dependency:TCompilerIrDependency = EachIn applicationMainResult.ir.initializationPlan.dependencies
	If dependency.logicalName = "common.bmx" Then applicationSourceDependency = dependency
Next
Check(applicationSourceDependency And applicationSourceDependency.initializeFunctionName = "__bb_application_demo_common" And applicationSourceDependency.headerPath = ".bmx/common.bmx.release.test.x64.h", "the primary application references its quoted source header and initialization unit through the shared application identity")
Check(Contains(applicationMainC, "__bb_application_demo_common_register();") And Contains(applicationMainC, "__bb_application_demo_common();") And Contains(applicationMainC, "application_demo_CommonValue()"), "the primary application emits declarations and initialization calls without owning the quoted implementation")
Local shadowBaseOptions:TCompilerOptions = TestOptions()
shadowBaseOptions.applicationBuild = True
shadowBaseOptions.applicationSourceUnit = True
shadowBaseOptions.applicationIdentity = "application.shadow"
shadowBaseOptions.applicationType = "console"
shadowBaseOptions.sourceModuleName = "application.shadow"
Local shadowBase:TCompilerResult = TBlitzMaxCompiler.Compile("/shadow/base.bmx", "SuperStrict~nType TShadowBase~nEnd Type~nFunction SharedService:TShadowBase()~nReturn New TShadowBase~nEnd Function", resolver, shadowBaseOptions)
Local shadowBaseInterfaceDiagnostics:TCompilerDiagnostic[]
Local shadowBaseInterface:String = TBlitzMaxCompiler.EmitInterface(shadowBase, shadowBaseInterfaceDiagnostics)
resolver.AddInterface("base.bmx", "/shadow/.bmx/base.bmx.release.test.x64.i", shadowBaseInterface)
Local shadowDerivedOptions:TCompilerOptions = TestOptions()
shadowDerivedOptions.applicationBuild = True
shadowDerivedOptions.applicationSourceUnit = True
shadowDerivedOptions.applicationIdentity = "application.shadow"
shadowDerivedOptions.applicationType = "console"
shadowDerivedOptions.sourceModuleName = "application.shadow"
Local shadowDerived:TCompilerResult = TBlitzMaxCompiler.Compile("/shadow/derived.bmx", "SuperStrict~nImport ~qbase.bmx~q~nType TShadowDerived Extends TShadowBase~nEnd Type~nFunction SharedService:TShadowDerived()~nReturn New TShadowDerived~nEnd Function", resolver, shadowDerivedOptions)
Local shadowDerivedInterfaceDiagnostics:TCompilerDiagnostic[]
Local shadowDerivedInterface:String = TBlitzMaxCompiler.EmitInterface(shadowDerived, shadowDerivedInterfaceDiagnostics)
Local shadowDerivedBackendDiagnostics:TCompilerDiagnostic[]
Local shadowDerivedC:String = TBlitzMaxCompiler.EmitRuntimeC(shadowDerived, shadowDerivedBackendDiagnostics)
Local shadowDerivedHeaderDiagnostics:TCompilerDiagnostic[]
Local shadowDerivedHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(shadowDerived, shadowDerivedHeaderDiagnostics)
Check(shadowBase.Succeeded() And shadowBaseInterfaceDiagnostics.length = 0 And shadowDerived.Succeeded() And shadowDerivedInterfaceDiagnostics.length = 0 And shadowDerivedBackendDiagnostics.length = 0 And shadowDerivedHeaderDiagnostics.length = 0, "an application source may covariantly replace an imported source-unit service routine")
Check(Contains(shadowBaseInterface, "SharedService:TShadowBase()=~qapplication_shadow_SharedService~q") And Contains(shadowDerivedInterface, "SharedService:TShadowDerived()=~qapplication_shadow_SharedService2~q"), "a shadowing source routine receives the production numeric linkage suffix in its compact interface")
Check(Contains(shadowDerivedC, "application_shadow_SharedService2(void)") And Contains(shadowDerivedHeader, "application_shadow_SharedService2(void)") And Not Contains(shadowDerivedC, "application_shadow_SharedService(void) {"), "shadowing source C and headers retain separate callable ABIs without recreating the occupied base alias")
resolver.AddInterface("nested/dep.bmx", "/work/nested/.bmx/dep.bmx.release.test.x64.i", "superstrict~nimport ~qshared.bmx~q")
resolver.AddInterface("shared.bmx", "/work/nested/.bmx/shared.bmx.release.test.x64.i", "superstrict")
resolver.AddInterface("nested/shared.bmx", "/work/nested/.bmx/shared.bmx.release.test.x64.i", "superstrict")
Local routedImportOptions:TCompilerOptions = TestOptions()
routedImportOptions.applicationBuild = True
routedImportOptions.applicationSourceUnit = True
routedImportOptions.applicationIdentity = "application.routes"
routedImportOptions.sourceModuleName = "application.routes"
routedImportOptions.sourceUnitPath = "main.bmx"
Local routedImportCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("/work/main.bmx", "SuperStrict~nImport ~qnested/dep.bmx~q~nImport ~qnested/shared.bmx~q", resolver, routedImportOptions)
Local routedImportInterfaceDiagnostics:TCompilerDiagnostic[]
Local routedImportInterface:String = TBlitzMaxCompiler.EmitInterface(routedImportCompilation, routedImportInterfaceDiagnostics)
Check(routedImportCompilation.Succeeded() And routedImportInterfaceDiagnostics.length = 0 And Contains(routedImportInterface, "import ~qnested/dep.bmx~q") And Contains(routedImportInterface, "import ~qnested/shared.bmx~q") And Not Contains(routedImportInterface, "import ~qshared.bmx~q"), "interface publication retains each root source edge spelling when a shared file dependency was interned first through a transitive relative route")
resolver.AddInterface("test.scopefunctions", "sdk/test.scopefunctions.i", "superstrict~nFlip(mode%)=~qtest_scopefunctions_Flip~q~nSetViewport(x%,y%,w%,h%)=~qtest_scopefunctions_SetViewport~q")
Local scopedGlobalCalls:TCompilerResult = TBlitzMaxCompiler.Compile("scoped-global-calls.bmx", "SuperStrict~nImport test.scopefunctions~nType TGraphics~nMethod Flip()~nIf True Then .Flip 1 Else .Flip 0~n.SetViewport(1,2,3,4)~nEnd Method~nEnd Type", resolver, TestOptions())
Local scopedGlobalCallDiagnostics:TCompilerDiagnostic[]
Local scopedGlobalCallC:String = TBlitzMaxCompiler.EmitRuntimeC(scopedGlobalCalls, scopedGlobalCallDiagnostics)
Check(scopedGlobalCalls.Succeeded() And scopedGlobalCallDiagnostics.length = 0 And Occurrences(scopedGlobalCallC, "test_scopefunctions_Flip(") = 2 And Contains(scopedGlobalCallC, "test_scopefunctions_SetViewport(1, 2, 3, 4)"), "leading-dot calls escape an enclosing Type while retaining imported module-level routine lookup")
resolver.AddInterface("test.inheritedfallback", "sdk/test.inheritedfallback.i", "superstrict~nClientWidth%(gadget:Object)=~qtest_inheritedfallback_ClientWidth~q~nPostGuiEvent%(id%,source:Object)=~qtest_inheritedfallback_PostGuiEvent~q")
Local importedInheritedFallbackSource:String = "SuperStrict~nImport test.inheritedfallback~nType TWindowsBase~nMethod ClientWidth:Int()~nReturn 1~nEnd Method~nMethod PostGuiEvent(id:Int,data:Int=0,mods:Int=0,x:Int=0,y:Int=0,extra:Object=Null)~nEnd Method~nEnd Type~nType TWindowsDerived Extends TWindowsBase~nMethod Resize:Int(group:Object)~nReturn ClientWidth(group)~nEnd Method~nMethod Notify()~nPostGuiEvent(1,Self)~nEnd Method~nEnd Type"
Local importedInheritedFallback:TCompilerResult = TBlitzMaxCompiler.Compile("imported-inherited-fallback.bmx", importedInheritedFallbackSource, resolver, TestOptions())
Local importedInheritedFallbackDiagnostics:TCompilerDiagnostic[]
Local importedInheritedFallbackC:String = TBlitzMaxCompiler.EmitRuntimeC(importedInheritedFallback, importedInheritedFallbackDiagnostics)
Check(importedInheritedFallback.Succeeded() And importedInheritedFallbackDiagnostics.length = 0, "inapplicable inherited members fall back to imported global routine overloads: " + CompilerDiagnosticSummary(importedInheritedFallback))
Check(Contains(importedInheritedFallbackC, "test_inheritedfallback_ClientWidth(") And Contains(importedInheritedFallbackC, "test_inheritedfallback_PostGuiEvent("), "imported global fallbacks lower to their published linkage names")
Local routineGlobal:TCompilerResult = TBlitzMaxCompiler.Compile("routine-global.bmx", "SuperStrict~nFunction NextValue:Int()~nIf True Then~nGlobal count:Int = 40~ncount :+ 1~nReturn count~nEnd If~nEnd Function~nGlobal first:Int = NextValue()~nGlobal second:Int = NextValue()", resolver, TestOptions())
Local routineGlobalDiagnostics:TCompilerDiagnostic[]
Local routineGlobalC:String = TBlitzMaxCompiler.EmitRuntimeC(routineGlobal, routineGlobalDiagnostics)
Check(routineGlobal.Succeeded() And routineGlobalDiagnostics.length = 0, "a routine-local Global lowers to persistent file-owned C storage")
Check(Contains(routineGlobalC, "static BBINT bmx_global_") And Contains(routineGlobalC, "_count;") And Contains(routineGlobalC, "_count_inited") And Contains(routineGlobalC, "_count = 40;"), "a nested routine Global has one deterministic storage cell and guarded first-use initialization")
Local crossTargetOptions:TCompilerOptions = TestOptions()
crossTargetOptions.targetPlatform = "win32"
crossTargetOptions.targetArchitecture = "x64"
crossTargetOptions.buildMode = "debug"
crossTargetOptions.debugInstrumentation = True
crossTargetOptions.applicationBuild = True
crossTargetOptions.applicationType = "console"
crossTargetOptions.threaded = False
crossTargetOptions.coverageInstrumentation = True
crossTargetOptions.userDefinitions = "enabled=1"
crossTargetOptions.RefreshConditionalSymbols()
Local crossTargetSource:String = "SuperStrict~n?win64 And win32x64 And ptr64 And longint4 And littleendian And console And debug And coverage And enabled And Not threaded And Not gui~nGlobal CrossTargetValue:Int=64~n?Not (win64 And win32x64 And ptr64 And longint4 And littleendian And console And debug And coverage And enabled And Not threaded And Not gui)~nGlobal CrossTargetValue:Int=0~n?"
Local crossTargetResult:TCompilerResult = TBlitzMaxCompiler.Compile("cross-target.bmx", crossTargetSource, resolver, crossTargetOptions)
Local crossTargetDump:String = TCompilerIrDumper.Dump(crossTargetResult.ir)
Check(crossTargetResult.Succeeded() And Contains(crossTargetDump, "target win32/x64 debug") And Contains(crossTargetDump, "CrossTargetValue:Int") And Contains(crossTargetDump, "literal 64 : Int") And Not Contains(crossTargetDump, "literal 0 : Int"), "cross-target compilation selects source branches from requested bmk platform, architecture, application and build options")
Local conditionalElseOptions:TCompilerOptions = TestOptions()
conditionalElseOptions.buildMode = "debug"
conditionalElseOptions.RefreshConditionalSymbols()
Local conditionalElseCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("conditional-else.bmx", "SuperStrict~nFunction SelectValue:Int(flag:Int)~nLocal result:Int=3~nIf flag~nresult=1~n?debug~nElse~nresult=2~n?~nEndIf~nReturn result~nEnd Function~nLocal selected:Int=SelectValue(False)", resolver, conditionalElseOptions)
Local conditionalElseDump:String = TCompilerIrDumper.Dump(conditionalElseCompilation.ir)
Local conditionalElseDiagnostics:TCompilerDiagnostic[]
Local conditionalElseC:String = TBlitzMaxCompiler.EmitRuntimeC(conditionalElseCompilation, conditionalElseDiagnostics)
Check(conditionalElseCompilation.Succeeded() And conditionalElseDiagnostics.length = 0 And Contains(conditionalElseC, "} else {") And Contains(conditionalElseDump, "literal 1 : Int") And Contains(conditionalElseDump, "literal 2 : Int"), "an active compile-time region may introduce Else between an ordinary If and EndIf")
resolver.AddInterface("sample.contracts", "sdk/sample.contracts.i", "superstrict~nTImportedValue^Object{~n.count%&~n.name$&~n.peer:TImportedValue&~n-New()=~q_sample_contracts_TImportedValue_New~q~n-New(size%,flag%=3%)=~qsample_contracts_TImportedValue_New_ii~q~n-IsEmpty%()=~qsample_contracts_TImportedValue_IsEmpty~q~n-Copy:TImportedValue()=~qsample_contracts_TImportedValue_Copy~q~n-Accept%(value:TImportedValue,flag%=7%)=~qsample_contracts_TImportedValue_Accept_TTImportedValuei~q~n}=~qsample_contracts_TImportedValue~q~nTImportedChild^TImportedValue{~n.text$&~n-New()=~q_sample_contracts_TImportedChild_New~q~n-ChildValue%()=~qsample_contracts_TImportedChild_ChildValue~q~n}=~qsample_contracts_TImportedChild~q~nTImportedIterator^Object{~n-HasNext%()=~qsample_contracts_TImportedIterator_HasNext~q~n-NextObject%()=~qsample_contracts_TImportedIterator_NextObject~q~n}=~qsample_contracts_TImportedIterator~q~nTImportedValues^Object{~n-ObjectEnumerator:TImportedIterator()=~qsample_contracts_TImportedValues_ObjectEnumerator~q~n}=~qsample_contracts_TImportedValues~q~nCreateImportedValue:TImportedValue()=~qsample_contracts_CreateImportedValue~q~nCreateImportedChild:TImportedChild()=~qsample_contracts_CreateImportedChild~q~nCreateImportedValues:TImportedValues()=~qsample_contracts_CreateImportedValues~q~nUseImportedValue%(value:TImportedValue,flag%=9%)=~qsample_contracts_UseImportedValue~q~nDefaultPair%(left%=2%,right%=3%)=~qsample_contracts_DefaultPair~q~nDefaultText%(value$=$~qhello~q)=~qsample_contracts_DefaultText~q~nDefaultObject%(value:Object=~qbbNullObject~q)=~qsample_contracts_DefaultObject~q~nDefaultArray%(items%&[]=~qbbEmptyArray~q)=~qsample_contracts_DefaultArray~q~nImportedValue:TImportedValue&=mem:p(~qsample_contracts_ImportedValue~q)~nIImportedFactory^Object{~n-Get:TImportedValue()A=~qsample_contracts_IImportedFactory_Get~q~n-Set(value:TImportedValue,flag%=11%)A=~qsample_contracts_IImportedFactory_Set~q~n}AI=~qsample_contracts_IImportedFactory~q~nIImportedBase^Object{~n-BaseValue%(delta%)A=~qsample_contracts_IImportedBase_BaseValue_i~q~n}AI=~qsample_contracts_IImportedBase~q~nIImportedChild^IImportedBase{~n-ChildValue%()A=~qsample_contracts_IImportedChild_ChildValue~q~n}AI=~qsample_contracts_IImportedChild~q")
Local genericFieldTemplate:TGenericTemplateArtifact = New TGenericTemplateArtifact
genericFieldTemplate.identity = New TGenericTemplateIdentity
genericFieldTemplate.identity.moduleName = "genericfield.boxes"
genericFieldTemplate.identity.qualifiedName = "TImportedBox"
genericFieldTemplate.identity.arity = 1
Local genericFieldParameter:TGenericTemplateParameter = New TGenericTemplateParameter
genericFieldParameter.name = "T"
genericFieldParameter.ordinal = 0
genericFieldTemplate.parameters = [genericFieldParameter]
genericFieldTemplate.languageLinkageRevision = COMPILER_GENERIC_LANGUAGE_LINKAGE_REVISION
Local genericFieldTemplateDiagnostics:String[]
Local genericFieldTemplateText:String = TGenericTemplateArtifactCodec.FinalizeAndEncode(genericFieldTemplate, genericFieldTemplateDiagnostics)
Check(genericFieldTemplateDiagnostics.length = 0, "imported generic-field fixture artifact encodes canonically")
resolver.AddGenericTemplate("timportedbox.bmxgt", "sdk/timportedbox.bmxgt", genericFieldTemplateText)
resolver.AddInterface("genericfield.boxes", "sdk/genericfield.boxes.i", "superstrict~nTImportedBox<T>^Object{~n.value:T&~n}=~qgenericfield_boxes_TImportedBox~q~n'@generic-template 1,~q" + genericFieldTemplate.identity.StableName() + "~q,~q" + genericFieldTemplate.contentRevision + "~q,~qtimportedbox.bmxgt~q,~q" + COMPILER_GENERIC_LANGUAGE_LINKAGE_REVISION + "~q")
resolver.AddInterface("genericfield.contracts", "sdk/genericfield.contracts.i", "superstrict~nimport genericfield.boxes~nTImportedGenericOwner^Object{~n.box:TImportedBox<String>&~n-New()=~q_genericfield_contracts_TImportedGenericOwner_New~q~n}=~qgenericfield_contracts_TImportedGenericOwner~q")
resolver.AddInterface("default.contracts", "sdk/default.contracts.i", "superstrict~nIDefaultContract^Object{~n-Describe$()D=~qdefault_contracts_IDefaultContract_Describe~q~n}AI=~qdefault_contracts_IDefaultContract~q")
resolver.AddInterface("implicit.contracts", "sdk/implicit.contracts.i", "superstrict~nTImplicitValue^Object{~n.text$&~n}=~qimplicit_contracts_TImplicitValue~q")
resolver.AddInterface("callable.contracts", "sdk/callable.contracts.i", "superstrict~nTCallableList^Object{~n-Sort%(ascending%=1%,compareFunc%(left:Object,right:Object)=~qcallable_contracts_CompareObjects~q)=~qcallable_contracts_TCallableList_Sort_iF_TObjectTObject_i_~q~n}=~qcallable_contracts_TCallableList~q~nCompareObjects%(left:Object,right:Object)=~qcallable_contracts_CompareObjects~q~nCreateList:TCallableList()=~qcallable_contracts_CreateList~q~nSortList%(list:TCallableList,ascending%=1%,compareFunc%(left:Object,right:Object)=~qcallable_contracts_CompareObjects~q)=~qcallable_contracts_SortList~q")
resolver.AddInterface("callable.fields", "sdk/callable.fields.i", "superstrict~nTImportedCallableFields^Object{~n.active%(left:Object,right:Object)&~n.missing%(left:Object,right:Object)&~n}=~qcallable_fields_TImportedCallableFields~q~nTImportedCallableChild^TImportedCallableFields{~n}=~qcallable_fields_TImportedCallableChild~q~nExternalFieldCompare%(left:Object,right:Object)=~qcallable_fields_ExternalFieldCompare~q~nCreateCallableFields:TImportedCallableFields()=~qcallable_fields_CreateCallableFields~q~nCreateCallableChild:TImportedCallableChild()=~qcallable_fields_CreateCallableChild~q")
resolver.AddInterface("callable.globals", "sdk/callable.globals.i", "superstrict~nActiveCompare%(left:Object,right:Object)&=mem:p(~qcallable_globals_ActiveCompare~q)~nMissingCompare%(left:Object,right:Object)&=mem:p(~qcallable_globals_MissingCompare~q)~nExternalGlobalCompare%(left:Object,right:Object)=~qcallable_globals_ExternalGlobalCompare~q")
resolver.AddInterface("qualified.globals", "sdk/qualified.globals.i", "superstrict~nTQualifiedState^Object{~nEnabled%&=mem:p(~qqualified_globals_TQualifiedState_Enabled~q)~n}=~qqualified_globals_TQualifiedState~q")
resolver.AddInterface("header.leaf", "sdk/header.leaf.i", "superstrict~nLeafValue%()=~qheader_leaf_LeafValue~q")
resolver.AddInterface("header.root", "sdk/header.root.i", "superstrict~nimport header.leaf~nRootValue%()=~qheader_root_RootValue~q")
resolver.AddInterface("header.companion", "sdk/header.companion.i", "superstrict~nimport ~qnative-source.bmx~q")
resolver.AddInterface("native-source.bmx", "sdk/mod/header.mod/companion.mod/.bmx/native-source.bmx.release.test.x64.i", "superstrict~nimport header.native~n")
resolver.AddInterface("native-direct.bmx", "sdk/mod/header.mod/direct.mod/.bmx/native-direct.bmx.release.test.x64.i", "superstrict~nNativeDirect%(callback@*)=~qnative_direct~q~n")
resolver.AddInterface("header.native", "sdk/header.native.i", "superstrict~nNativeValue%()=~qheader_native_NativeValue~q~nNativeCallback%(value%)&=mem:p(~qheader_native_NativeCallback~q)")
resolver.AddInterface("source.bmx", "sdk/mod/acme.mod/multisource.mod/.bmx/source.bmx.release.test.x64.i", "superstrict~nSourceValue%()=~qacme_multisource_SourceValue~q")
resolver.AddInterface("common.bmx", "sdk/mod/acme.mod/multisource.mod/.bmx/common.bmx.release.test.x64.i", "superstrict~nimport ~qsource.bmx~q~nSharedValue%()=~qacme_multisource_SharedValue~q")
resolver.AddInterface("acme.selfstruct", "sdk/acme.selfstruct.i", "superstrict~nSSelf^Null{~n.value%&~n+Identity:SSelf(value:SSelf Var)=~qacme_selfstruct_SSelf_Identity~q~n-New()=~qacme_selfstruct_SSelf_New~q~n-Compare%(other:SSelf Var)=~qacme_selfstruct_SSelf_Compare~q~n-Split(value% Var)=~qacme_selfstruct_SSelf_Split~q~n}S=~qacme_selfstruct_SSelf~q")
resolver.AddInterface("acme.enumstruct", "sdk/acme.enumstruct.i", "superstrict~nEImportedState\%{~nUnknown=0~nReady=1~n}=~qacme_enumstruct_EImportedState~q~nSEnumCell^Null{~n.state/EImportedState&~n}S=~qacme_enumstruct_SEnumCell~q")
resolver.AddInterface("acme.pointerstruct", "sdk/acme.pointerstruct.i", "superstrict~nSPointerNode^Null{~n.next:SPointerNode*&~n}S=~qacme_pointerstruct_SPointerNode~q")
resolver.AddInclude("shared.bmx", "Global Included:Int = 1")

Local source:String = "SuperStrict~nInclude ~qshared.bmx~q~nGlobal Seed:Int = 40 { reflect category=~qseed~q }~nFunction Twice:Int(value:Int)~nLocal result:Int = value * 2~nReturn result~nEnd Function~nFunction SumTo:Int(limit:Int)~nLocal total:Int = 0~nLocal index:Int = 0~nWhile index < limit~ntotal = total + index~nindex = index + 1~nWend~nIf total > 10~nReturn total~nElse~nReturn 10~nEnd If~nEnd Function~nFunction LegacyCallback:Int(value:Int) { nomangle }~nReturn value~nEnd Function~nLocal answer:Int = Twice(21)~nanswer = answer + Seed"
Local compiled:TCompilerResult = TBlitzMaxCompiler.Compile("main.bmx", source, resolver, TestOptions())
Check(compiled.Succeeded(), "scalar snapshot lowers successfully")
Check(compiled.ir.functions.length = 4, "global entry and free routines are emitted")

Local inferredCompilerSource:String = "SuperStrict~nType TInferredObject~nField value:Int~nEnd Type~nStruct SInferredValue~nField value:Int~nEnd Struct~nInterface IInferredView~nMethod Read:Int()~nEnd Interface~nType TInferredView Implements IInferredView~nMethod Read:Int()~nReturn 42~nEnd Method~nEnd Type~nFunction View:IInferredView()~nReturn New TInferredView~nEnd Function~nFunction AddOne:Int(value:Int)~nReturn value+1~nEnd Function~nLocal number := 42~nLocal text := ~qhello~q~nLocal values := [1,2,3]~nLocal objectValue := New TInferredObject~nLocal structValue := New SInferredValue~nLocal interfaceValue := View()~nLocal callback := AddOne~nLocal raw:Int~nLocal pointer := Varptr raw~nLocal result := callback(number)+values[0]+interfaceValue.Read()"
Local inferredCompiler:TCompilerResult = TBlitzMaxCompiler.Compile("inferred-locals-ir.bmx", inferredCompilerSource, resolver, TestOptions())
Local inferredCompilerDump:String = TCompilerIrDumper.Dump(inferredCompiler.ir)
Local inferredCompilerDiagnostics:TCompilerDiagnostic[]
Local inferredCompilerC:String = TBlitzMaxCompiler.EmitRuntimeC(inferredCompiler, inferredCompilerDiagnostics)
Check(inferredCompiler.Succeeded() And inferredCompilerDiagnostics.length = 0, "inferred locals lower through the ordinary compiler pipeline")
Check(Contains(inferredCompilerDump, "number:Int") And Contains(inferredCompilerDump, "text:String") And Contains(inferredCompilerDump, "values:Int[]") And Contains(inferredCompilerDump, "objectValue:TInferredObject") And Contains(inferredCompilerDump, "structValue:SInferredValue") And Contains(inferredCompilerDump, "interfaceValue:IInferredView") And Contains(inferredCompilerDump, "callback:Int(Int)") And Contains(inferredCompilerDump, "pointer:Int Ptr"), "typed IR retains every inferred local's concrete semantic type")
Check(Contains(inferredCompilerC, "BBINT bmx_v0_number = 42;") And Contains(inferredCompilerC, "BBSTRING bmx_v1_text = (BBString*)&bmx_string_str0;") And Contains(inferredCompilerC, "BBINT * bmx_v8_pointer = (&bmx_v7_raw);"), "runtime C declares inferred locals with the same fixed storage shapes as explicit locals")

Local explicitScalarCompiler:TCompilerResult = TBlitzMaxCompiler.Compile("explicit-local-equivalence.bmx", "SuperStrict~nLocal value:Int=42~nLocal result:Int=value+1", resolver, TestOptions())
Local inferredScalarCompiler:TCompilerResult = TBlitzMaxCompiler.Compile("inferred-local-equivalence.bmx", "SuperStrict~nLocal value := 42~nLocal result := value+1", resolver, TestOptions())
Local explicitScalarDiagnostics:TCompilerDiagnostic[]
Local inferredScalarDiagnostics:TCompilerDiagnostic[]
Local explicitScalarC:String = TBlitzMaxCompiler.EmitRuntimeC(explicitScalarCompiler, explicitScalarDiagnostics)
Local inferredScalarC:String = TBlitzMaxCompiler.EmitRuntimeC(inferredScalarCompiler, inferredScalarDiagnostics)
Check(explicitScalarCompiler.Succeeded() And inferredScalarCompiler.Succeeded() And explicitScalarDiagnostics.length = 0 And inferredScalarDiagnostics.length = 0, "explicit and inferred scalar locals both compile")
Check(Contains(explicitScalarC, "BBINT bmx_v0_value = 42;") And Contains(inferredScalarC, "BBINT bmx_v0_value = 42;") And Contains(explicitScalarC, "BBINT bmx_v1_result = (bmx_v0_value + 1);") And Contains(inferredScalarC, "BBINT bmx_v1_result = (bmx_v0_value + 1);"), "inferred and explicitly typed scalar locals lower identically")

Local inferredGenericSource:String = "SuperStrict~nType TGenericBase<T>~nMethod Echo:T(value:T)~nReturn value~nEnd Method~nEnd Type~nType TGenericChild<T> Extends TGenericBase<T>~nEnd Type~nType TPair<A,B>~nField second:B~nEnd Type~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nLocal child:TGenericChild<Long>=New TGenericChild<Long>~nLocal pair:TPair<String,TGenericChild<Int>>=New TPair<String,TGenericChild<Int>>~nLocal direct := New TGenericChild<String>~nLocal inherited := child.Echo(1)~nLocal nested := pair.second.Echo(1)~nLocal routineResult := Identity(~qresult~q)"
Local inferredGeneric:TCompilerResult = TBlitzMaxCompiler.Compile("inferred-generic-locals.bmx", inferredGenericSource, resolver, TestOptions())
Local inferredGenericDump:String = TCompilerIrDumper.Dump(inferredGeneric.ir)
Check(inferredGeneric.Succeeded() And Contains(inferredGenericDump, "direct:TGenericChild<String>") And Contains(inferredGenericDump, "inherited:Long") And Contains(inferredGenericDump, "nested:Int") And Contains(inferredGenericDump, "routineResult:String"), "direct, nested, inherited, and routine-result generic types remain concrete through inferred-local IR: " + CompilerDiagnosticSummary(inferredGeneric))

Local importedInference:TCompilerResult = TBlitzMaxCompiler.Compile("imported-inferred-local.bmx", "SuperStrict~nImport genericfield.contracts~nLocal owner:TImportedGenericOwner=New TImportedGenericOwner~nLocal imported := owner.box", resolver, TestOptions())
Local importedInferenceDump:String = TCompilerIrDumper.Dump(importedInference.ir)
Check(importedInference.Succeeded() And Contains(importedInferenceDump, "imported:TImportedBox<String>"), "an imported module-interface member supplies its fully constructed type to inferred-local IR: " + CompilerDiagnosticSummary(importedInference))
Local multipleDeclarators:TCompilerResult = TBlitzMaxCompiler.Compile("multiple-declarators.bmx", "SuperStrict~nGlobal First:Int=1,Second:Int=2~nLocal text:String=~qx~q,count:Int=First+Second", resolver, TestOptions())
Local multipleDeclaratorsDump:String = TCompilerIrDumper.Dump(multipleDeclarators.ir)
Check(multipleDeclarators.Succeeded() And AppearsBefore(multipleDeclaratorsDump, "First:Int", "Second:Int") And AppearsBefore(multipleDeclaratorsDump, "text:String", "count:Int") And Not HasCompilerDiagnostic(multipleDeclarators, "BMXC1001"), "multiple bound Global and Local declarators expand to distinct typed IR storage in source order")

Local nestedRoutineSource:String = "SuperStrict~nFunction Increment:Int(value:Int)~nFunction Step:Int(input:Int)~nReturn input+1~nEnd Function~nReturn Step(value)~nEnd Function~nFunction Factorial:Int(value:Int)~nFunction Step:Int(input:Int)~nIf input<=1 Then Return 1~nReturn input*Step(input-1)~nEnd Function~nReturn Step(value)~nEnd Function~nGlobal NestedResult:Int=Increment(40)+Factorial(1)"
Local nestedRoutines:TCompilerResult = TBlitzMaxCompiler.Compile("nested-routines.bmx", nestedRoutineSource, resolver, TestOptions())
Local nestedRoutinesDump:String = TCompilerIrDumper.Dump(nestedRoutines.ir)
Local nestedRoutinesDiagnostics:TCompilerDiagnostic[]
Local nestedRoutinesC:String = TBlitzMaxCompiler.EmitRuntimeC(nestedRoutines, nestedRoutinesDiagnostics)
Check(nestedRoutines.Succeeded() And nestedRoutines.ir.functions.length = 5 And Contains(nestedRoutinesDump, "function @fn1 Step(") And Contains(nestedRoutinesDump, "function @fn3 Step(") And Contains(nestedRoutinesDump, "call @fn3 Step : Int"), "nested routines are lifted from bound routine scopes and retain recursive canonical call identity")
Check(nestedRoutinesDiagnostics.length = 0 And Contains(nestedRoutinesC, "bmx_fn1_Step") And Contains(nestedRoutinesC, "bmx_fn3_Step") And Not Contains(nestedRoutinesC, "nested_routines_Step"), "same-named nested routines receive distinct private deterministic C identities")
Local blockNestedRoutineSource:String = "SuperStrict~nFunction Outer:Int(value:Int)~nIf value~nFunction Contains:Int(item:Int)~nReturn item=42~nEnd Function~nReturn Contains(value)~nEnd If~nReturn False~nEnd Function~nGlobal BlockNestedResult:Int=Outer(42)"
Local blockNestedRoutine:TCompilerResult = TBlitzMaxCompiler.Compile("block-nested-routine.bmx", blockNestedRoutineSource, resolver, TestOptions())
Local blockNestedRoutineDump:String = TCompilerIrDumper.Dump(blockNestedRoutine.ir)
Check(blockNestedRoutine.Succeeded() And Contains(blockNestedRoutineDump, "function @fn1 Contains(") And Contains(blockNestedRoutineDump, "call @fn1 Contains : Int"), "nested routines declared in lexical control-flow scopes receive lifted typed IR ownership")

Local dump:String = TCompilerIrDumper.Dump(compiled.ir)
Check(Contains(dump, "initialization application _bb_main register _bb_main_register init _bb_main"), "application initialization identity is explicit")
Check(Contains(dump, "register-dependency brl.blitz") And Contains(dump, "initialize-dependency brl.blitz"), "runtime dependency registration and initialization are explicit")
Check(Not Contains(dump, "initialize-globals") And Contains(dump, "run-atstart") And Contains(dump, "execute-global-body"), "application initialization retains AtStart and one source-ordered global body")
Check(Contains(dump, "function @main $main() -> Int [global-entry]"), "Int-returning global entry is explicit")
Check(Contains(dump, "function @fn0 Twice(%p0 value:Int) -> Int"), "free routine and typed parameter")
Check(Contains(dump, "function @fn2 LegacyCallback(%p0 value:Int) -> Int [abi _bb_main_LegacyCallback] [nomangle]"), "NoMangle ABI identity is explicit in typed IR")
Check(Contains(dump, "binary * : Int"), "typed binary expression")
Check(Contains(dump, "call @fn0 Twice : Int"), "resolved free-routine call")
Check(Contains(dump, "@shared.bmx:"), "included statement retains its source path")
Check(Contains(dump, "while @main.bmx:"), "While lowers to structured typed IR")
Check(Contains(dump, "if @main.bmx:"), "If lowers to structured typed IR")
Check(Contains(dump, "metadata reflect=~q1~q written=~q1~q") And Contains(dump, "metadata category=~qseed~q"), "normalized declaration metadata is attached to typed IR")

Local repeated:TCompilerResult = TBlitzMaxCompiler.Compile("main.bmx", source, resolver, TestOptions())
Check(repeated.Succeeded() And TCompilerIrDumper.Dump(repeated.ir) = dump, "IR dump is deterministic")

Local qualifiedStaticGlobal:TCompilerResult = TBlitzMaxCompiler.Compile("qualified-static-global.bmx", "SuperStrict~nImport qualified.globals~nLocal initial:Int=TQualifiedState.Enabled~nTQualifiedState.Enabled=False~nLocal changed:Int=TQualifiedState.Enabled", resolver, TestOptions())
Local qualifiedStaticGlobalDump:String = TCompilerIrDumper.Dump(qualifiedStaticGlobal.ir)
Local qualifiedStaticGlobalDiagnostics:TCompilerDiagnostic[]
Local qualifiedStaticGlobalC:String = TBlitzMaxCompiler.EmitRuntimeC(qualifiedStaticGlobal, qualifiedStaticGlobalDiagnostics)
Check(qualifiedStaticGlobal.Succeeded() And Contains(qualifiedStaticGlobalDump, "external-global %extg0 Enabled:Int abi qualified_globals_TQualifiedState_Enabled") And Contains(qualifiedStaticGlobalDump, "symbol external %extg0 Enabled"), "receiverless Type-qualified imported Globals lower to canonical external storage")
Check(qualifiedStaticGlobalDiagnostics.length = 0 And Contains(qualifiedStaticGlobalC, "qualified_globals_TQualifiedState_Enabled = 0"), "receiverless Type-qualified imported Globals support reads and assignments")

Local ownedSourceOptions:TCompilerOptions = TestOptions()
ownedSourceOptions.sourceModuleName = "Acme.MultiSource"
Local ownedSource:TCompilerResult = TBlitzMaxCompiler.Compile("src/common.bmx", "SuperStrict~nPrivate Function PrivateValue:Int()~nReturn 42~nEnd Function~nPublic Function SharedValue:Int()~nReturn PrivateValue()~nEnd Function", resolver, ownedSourceOptions)
Local ownedSourceDiagnostics:TCompilerDiagnostic[]
Local ownedSourceInterface:String = TBlitzMaxCompiler.EmitInterface(ownedSource, ownedSourceDiagnostics)
Local ownedSourceRuntimeDiagnostics:TCompilerDiagnostic[]
Local ownedSourceRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(ownedSource, ownedSourceRuntimeDiagnostics)
Check(ownedSource.Succeeded() And ownedSource.analysis.model.moduleName = "acme.multisource", "compiler accepts an explicit owning module for a secondary source")
Check(ownedSourceDiagnostics.length = 0 And Contains(ownedSourceInterface, "SharedValue%()=~qacme_multisource_SharedValue~q"), "owned secondary source publishes the module ABI while retaining a private per-source interface")
Check(ownedSourceRuntimeDiagnostics.length = 0 And Contains(ownedSourceRuntimeC, "bmx_acme_multisource_fn0_PrivateValue"), "private module routines include their owning module in deterministic C linkage")
Check(Contains(TCompilerIrDumper.Dump(ownedSource.ir), "initialization module __bb_acme_multisource_common register __bb_acme_multisource_common_register init __bb_acme_multisource_common"), "owned secondary source receives a distinct deterministic module-unit identity")

Local ownedNativeSource:TCompilerResult = TBlitzMaxCompiler.Compile("src/native-common.bmx", "SuperStrict~nExtern~nFunction SharedNative:Int(value:Int)=~qshared_native~q~nGlobal SharedHandle:Byte Ptr=~qshared_handle~q~nEnd Extern~nPrivate~nExtern~nFunction HiddenNative:Int()=~qhidden_native~q~nEnd Extern", resolver, ownedSourceOptions)
Local ownedNativeDiagnostics:TCompilerDiagnostic[]
Local ownedNativeInterface:String = TBlitzMaxCompiler.EmitInterface(ownedNativeSource, ownedNativeDiagnostics)
Check(ownedNativeSource.Succeeded() And ownedNativeDiagnostics.length = 0 And Contains(ownedNativeInterface, "SharedNative%(value%)=~qshared_native~q") And Contains(ownedNativeInterface, "SharedHandle@*&=mem:p(~qshared_handle~q)") And Not Contains(ownedNativeInterface, "HiddenNative"), "owned secondary sources publish public native declarations and retain explicit Private boundaries")
resolver.AddInterface("native-common.bmx", "sdk/mod/acme.mod/multisource.mod/.bmx/native-common.bmx.release.test.i", ownedNativeInterface)
Local ownedNativeConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/acme.mod/multisource.mod/native-consumer.bmx", "SuperStrict~nImport ~qnative-common.bmx~q~nLocal result:Int=SharedNative(1)~nSharedHandle=Null", resolver, TestOptions())
Check(ownedNativeConsumer.Succeeded() And ownedNativeConsumer.ir.externalFunctions.length = 1 And ownedNativeConsumer.ir.externalGlobals.length = 1, "another source in the owning module consumes public native declarations through the compact interface")

Local externStruct:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/native.mod/native.bmx", "SuperStrict~nModule acme.native~nExtern~nStruct SNativeStats~nField count:Int~nField bytes:ULongInt~nEnd Struct~nFunction FillStats(stats:SNativeStats Var)=~qacme_fill_stats~q~nEnd Extern", resolver, TestOptions())
Local externStructDiagnostics:TCompilerDiagnostic[]
Local externStructHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(externStruct, externStructDiagnostics)
Local externStructInterfaceDiagnostics:TCompilerDiagnostic[]
Local externStructInterface:String = TBlitzMaxCompiler.EmitInterface(externStruct, externStructInterfaceDiagnostics)
Check(externStruct.Succeeded() And externStructDiagnostics.length = 0 And externStructInterfaceDiagnostics.length = 0, "Extern Struct ABI declarations lower without an unsupported-declaration diagnostic")
Check(Contains(externStructHeader, "struct SNativeStats {") And Not Contains(externStructHeader, "struct acme_native_SNativeStats {"), "Extern Struct preserves its unqualified native C tag")
Check(Contains(externStructInterface, "}S=~qSNativeStats~q"), "Extern Struct publishes the same native ABI identity to consumers")

Local coreRuntimeAbi:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/brl.mod/blitz.mod/blitz.bmx", "SuperStrict~nModule brl.blitz~nFunction RuntimeError(message:String)~nEnd Function~nFunction IllegalArgumentError(message:String)~nEnd Function~nFunction Max:Int(left:Int,right:Int)~nReturn left~nEnd Function", resolver, TestOptions())
Local coreRuntimeAbiDiagnostics:TCompilerDiagnostic[]
Local coreRuntimeAbiHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(coreRuntimeAbi, coreRuntimeAbiDiagnostics)
Check(coreRuntimeAbi.Succeeded() And coreRuntimeAbiDiagnostics.length = 0, "runtime-header-owned BRL.Blitz entry points lower successfully")
Check(Contains(coreRuntimeAbiHeader, "brl_blitz_RuntimeError(") And Not Contains(coreRuntimeAbiHeader, "brl_blitz_RuntimeError__") And Contains(coreRuntimeAbiHeader, "brl_blitz_IllegalArgumentError(") And Contains(coreRuntimeAbiHeader, "brl_blitz_Max("), "BRL.Blitz retains native runtime ABI names when rebuilt canonically")

Local incbinIntrinsic:TCompilerResult = TBlitzMaxCompiler.Compile("incbin-intrinsic.bmx", "SuperStrict~nLocal path:String=~qasset.dat~q~nLocal data:Byte Ptr=IncbinPtr(path)~nLocal size:Int=IncbinLen(path)", resolver, TestOptions())
Check(incbinIntrinsic.Succeeded() And incbinIntrinsic.ir.externalFunctions.length = 2 And incbinIntrinsic.ir.externalFunctions[0].abiName = "bbIncbinPtr" And incbinIntrinsic.ir.externalFunctions[1].abiName = "bbIncbinLen", "snapshot core publishes the runtime Incbin query intrinsics")
Local incbinDirectiveOptions:TCompilerOptions = TestOptions()
incbinDirectiveOptions.sourceModuleName = "acme.assets"
Local incbinDirective:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/assets.mod/source.bmx", "SuperStrict~nModule acme.assets~nIncbin ~qasset.dat~q~nLocal size:Int=IncbinLen(~qasset.dat~q)", resolver, incbinDirectiveOptions)
Local incbinDirectiveDiagnostics:TCompilerDiagnostic[]
Local incbinDirectiveC:String = TBlitzMaxCompiler.EmitRuntimeC(incbinDirective, incbinDirectiveDiagnostics)
Check(incbinDirective.Succeeded() And incbinDirective.ir.incbins.length = 1 And incbinDirective.ir.incbins[0].path = "asset.dat" And incbinDirectiveDiagnostics.length = 0 And Contains(incbinDirectiveC, "extern const unsigned char *_ib_bb_acme_assets_source_1_data;") And Contains(incbinDirectiveC, "bbIncbinAdd(") And Contains(incbinDirectiveC, "&_ib_bb_acme_assets_source_1_data, _ib_bb_acme_assets_source_1_size"), "Incbin directives retain deterministic resource identities and emit runtime registration without becoming executable statements")
Local conditionalIncbin:TCompilerResult = TBlitzMaxCompiler.Compile("conditional-incbin.bmx", "SuperStrict~n?test~nIncbin ~qactive.dat~q~n?disabled~nIncbin ~qinactive.dat~q~n?", resolver, TestOptions())
Local conditionalIncbinDiagnostics:TCompilerDiagnostic[]
Local conditionalIncbinC:String = TBlitzMaxCompiler.EmitRuntimeC(conditionalIncbin, conditionalIncbinDiagnostics)
Check(conditionalIncbin.Succeeded() And conditionalIncbinDiagnostics.length = 0 And conditionalIncbin.ir.incbins.length = 1 And conditionalIncbin.ir.incbins[0].path = "active.dat", "Incbin collection follows active conditional branches")
Check(Contains(conditionalIncbinC, "&_ib_bb_main_1_data, _ib_bb_main_1_size"), "an active conditional Incbin receives the same deterministic application symbol and registration as a root directive")

Local standaloneConstruction:TCompilerResult = TBlitzMaxCompiler.Compile("standalone-construction.bmx", "SuperStrict~nType TFactory~nEnd Type~nNew TFactory", resolver, TestOptions())
Check(standaloneConstruction.Succeeded() And Contains(TCompilerIrDumper.Dump(standaloneConstruction.ir), "object-new @"), "standalone New expression is not rebound as a zero-argument command call")
Local standaloneConstructionDiagnostics:TCompilerDiagnostic[]
Local standaloneConstructionC:String = TBlitzMaxCompiler.EmitRuntimeC(standaloneConstruction, standaloneConstructionDiagnostics)
Check(standaloneConstructionDiagnostics.length = 0 And Contains(standaloneConstructionC, "(void)((struct bmx_cls0_TFactory_obj *)bbObject"), "discarded ordinary expressions retain side effects while making their unused result explicit to the C compiler")

Local multiSourceRoot:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/acme.mod/multisource.mod/multisource.bmx", "SuperStrict~nImport ~qcommon.bmx~q~nFunction RootValue:Int()~nReturn SharedValue()+1~nEnd Function", resolver, TestOptions())
Local multiSourceRootDump:String = TCompilerIrDumper.Dump(multiSourceRoot.ir)
Check(multiSourceRoot.Succeeded() And Contains(multiSourceRootDump, "dependency common.bmx"), "module root accepts a canonical quoted-source dependency")
Local importedSharedValue:TSymbol = multiSourceRoot.analysis.model.ImportedScope("common.bmx").LookupLocal("SharedValue")[0]
Check(importedSharedValue.originModule = "acme.multisource" And importedSharedValue.originPath = "sdk/mod/acme.mod/multisource.mod/.bmx/common.bmx.release.test.x64.i", "quoted-source API symbols inherit module ownership while retaining interface provenance")
Check(Contains(multiSourceRootDump, "register __bb_acme_multisource_common_register") And Contains(multiSourceRootDump, "init __bb_acme_multisource_common"), "module root references the secondary source's deterministic runtime unit")
Local multiSourceRootInterfaceDiagnostics:TCompilerDiagnostic[]
Local multiSourceRootInterface:String = TBlitzMaxCompiler.EmitInterface(multiSourceRoot, multiSourceRootInterfaceDiagnostics)
Check(multiSourceRootInterfaceDiagnostics.length = 0 And Contains(multiSourceRootInterface, "'@source-aggregate 1") And Contains(multiSourceRootInterface, "import ~qcommon.bmx~q"), "primary module interface marks and retains its quoted source dependency graph")
Check(Occurrences(multiSourceRootInterface, "SourceValue%()") = 1 And Occurrences(multiSourceRootInterface, "SharedValue%()") = 1 And AppearsBefore(multiSourceRootInterface, "SourceValue%()", "SharedValue%()"), "module interface aggregates each transitive quoted-source public declaration once in dependency order")
Local aggregateRebaseEmitter:TCompilerInterfaceEmitter = New TCompilerInterfaceEmitter
aggregateRebaseEmitter.irModule = New TCompilerIrModule
aggregateRebaseEmitter.irModule.path = "sdk/mod/acme.mod/multisource.mod/multisource.bmx"
Local rebasedTemplateLine:String = aggregateRebaseEmitter.RebaseGenericTemplateLine("'@generic-template 4,~qacme.multisource::box#type/1~q,~qrevision~q,~qgeneric-templates/box.bmxgt~q,~qbmx-language-1~q", "sdk/mod/acme.mod/multisource.mod/.bmx/common.bmx.release.test.x64.i")
Check(Contains(rebasedTemplateLine, "~q.bmx/generic-templates/box.bmxgt~q"), "aggregated canonical template references are rebased from the source-interface directory to the module interface")
Local multiSourceRootHeaderDiagnostics:TCompilerDiagnostic[]
Local multiSourceRootHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(multiSourceRoot, multiSourceRootHeaderDiagnostics)
Check(multiSourceRootHeaderDiagnostics.length = 0 And Contains(multiSourceRootHeader, "#include <acme.mod/multisource.mod/.bmx/common.bmx.release.test.x64.h>"), "module headers qualify owned secondary headers from the SDK include root")

Local nestedDriverOptions:TCompilerOptions = TestOptions()
nestedDriverOptions.sourceModuleName = "acme.multisource"
nestedDriverOptions.sourceUnitPath = "drivers/common.bmx"
Local nestedDriver:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/acme.mod/multisource.mod/drivers/common.bmx", "SuperStrict~nPublic Function DriverValue:Int()~nReturn 20~nEnd Function", resolver, nestedDriverOptions)
Local nestedDriverInterfaceDiagnostics:TCompilerDiagnostic[]
Local nestedDriverInterface:String = TBlitzMaxCompiler.EmitInterface(nestedDriver, nestedDriverInterfaceDiagnostics)
resolver.AddInterface("drivers/common.bmx", "sdk/mod/acme.mod/multisource.mod/drivers/.bmx/common.bmx.release.test.x64.i", nestedDriverInterface)
Local nestedPlatformOptions:TCompilerOptions = TestOptions()
nestedPlatformOptions.sourceModuleName = "acme.multisource"
nestedPlatformOptions.sourceUnitPath = "platform/common.bmx"
Local nestedPlatform:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/acme.mod/multisource.mod/platform/common.bmx", "SuperStrict~nPublic Function PlatformValue:Int()~nReturn 22~nEnd Function", resolver, nestedPlatformOptions)
Local nestedPlatformInterfaceDiagnostics:TCompilerDiagnostic[]
Local nestedPlatformInterface:String = TBlitzMaxCompiler.EmitInterface(nestedPlatform, nestedPlatformInterfaceDiagnostics)
resolver.AddInterface("platform/common.bmx", "sdk/mod/acme.mod/multisource.mod/platform/.bmx/common.bmx.release.test.x64.i", nestedPlatformInterface)
Local nestedRootOptions:TCompilerOptions = TestOptions()
nestedRootOptions.sourceModuleName = "acme.multisource"
nestedRootOptions.sourceUnitPath = "multisource.bmx"
Local nestedRoot:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/acme.mod/multisource.mod/multisource.bmx", "SuperStrict~nImport ~qdrivers/common.bmx~q~nImport ~qplatform/common.bmx~q~nGlobal NestedTotal:Int=DriverValue()+PlatformValue()", resolver, nestedRootOptions)
Local nestedRootDump:String = TCompilerIrDumper.Dump(nestedRoot.ir)
Local nestedRootHeaderDiagnostics:TCompilerDiagnostic[]
Local nestedRootHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(nestedRoot, nestedRootHeaderDiagnostics)
Local driverUnitIdentity:String = TCompilerIrLowerer.SourceUnitIdentity("drivers/common")
Local platformUnitIdentity:String = TCompilerIrLowerer.SourceUnitIdentity("platform/common")
Check(nestedDriver.Succeeded() And nestedPlatform.Succeeded() And nestedDriverInterfaceDiagnostics.length = 0 And nestedPlatformInterfaceDiagnostics.length = 0 And nestedRoot.Succeeded(), "nested same-basename quoted sources compile under one owning module")
Check(driverUnitIdentity <> platformUnitIdentity And Contains(nestedRootDump, "register __bb_acme_multisource_" + TCompilerAbiNamer.Sanitize(driverUnitIdentity) + "_register") And Contains(nestedRootDump, "register __bb_acme_multisource_" + TCompilerAbiNamer.Sanitize(platformUnitIdentity) + "_register"), "nested source paths produce readable collision-resistant runtime-unit identities")
Check(nestedRootHeaderDiagnostics.length = 0 And Contains(nestedRootHeader, "#include <acme.mod/multisource.mod/drivers/.bmx/common.bmx.release.test.x64.h>") And Contains(nestedRootHeader, "#include <acme.mod/multisource.mod/platform/.bmx/common.bmx.release.test.x64.h>"), "nested source dependencies retain their path-qualified generated headers")

resolver.AddInterface("Mixed/Helper.bmx", "sdk/mod/acme.mod/mixedcase.mod/Mixed/.bmx/Helper.bmx.release.test.x64.i", nestedDriverInterface)
Local mixedCaseRootOptions:TCompilerOptions = TestOptions()
mixedCaseRootOptions.sourceModuleName = "acme.mixedcase"
mixedCaseRootOptions.sourceUnitPath = "Root.bmx"
Local mixedCaseRoot:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/acme.mod/mixedcase.mod/Root.bmx", "SuperStrict~nImport ~qMixed/Helper.bmx~q", resolver, mixedCaseRootOptions)
Local mixedCaseRootHeaderDiagnostics:TCompilerDiagnostic[]
Local mixedCaseRootHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(mixedCaseRoot, mixedCaseRootHeaderDiagnostics)
Local mixedCaseRootInterfaceDiagnostics:TCompilerDiagnostic[]
Local mixedCaseRootInterface:String = TBlitzMaxCompiler.EmitInterface(mixedCaseRoot, mixedCaseRootInterfaceDiagnostics)
Check(mixedCaseRoot.Succeeded() And mixedCaseRootHeaderDiagnostics.length = 0 And Contains(mixedCaseRootHeader, "#include <acme.mod/mixedcase.mod/Mixed/.bmx/Helper.bmx.release.test.x64.h>"), "resolved quoted-source headers preserve filesystem case while source identities remain case-insensitive")
Check(mixedCaseRootInterfaceDiagnostics.length = 0 And Contains(mixedCaseRootInterface, "import ~qMixed/Helper.bmx~q"), "published quoted-source imports preserve authored filesystem case")

resolver.AddInterface("Fallback/Helper.bmx", "cache/Fallback/.bmx/Helper.bmx.release.test.x64.i", nestedDriverInterface)
Local mixedCaseFallbackOptions:TCompilerOptions = TestOptions()
mixedCaseFallbackOptions.sourceModuleName = "application.mixedcase"
mixedCaseFallbackOptions.sourceUnitPath = "source/Root.bmx"
mixedCaseFallbackOptions.applicationIdentity = "application.mixedcase"
mixedCaseFallbackOptions.applicationBuild = True
Local mixedCaseFallback:TCompilerResult = TBlitzMaxCompiler.Compile("workspace/source/Root.bmx", "SuperStrict~nImport ~qFallback/Helper.bmx~q", resolver, mixedCaseFallbackOptions)
Local mixedCaseFallbackHeaderDiagnostics:TCompilerDiagnostic[]
Local mixedCaseFallbackHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(mixedCaseFallback, mixedCaseFallbackHeaderDiagnostics)
Check(mixedCaseFallback.Succeeded() And mixedCaseFallbackHeaderDiagnostics.length = 0 And Contains(mixedCaseFallbackHeader, "#include <source/Fallback/.bmx/Helper.bmx.release.test.x64.h>"), "quoted-source header fallback paths preserve authored filesystem case when resolved source provenance is unavailable")

resolver.AddInterface("../outside.bmx", "sdk/mod/acme.mod/outside.bmx.release.test.x64.i", nestedDriverInterface)
Local escapingUnitOptions:TCompilerOptions = TestOptions()
escapingUnitOptions.sourceModuleName = "acme.multisource"
escapingUnitOptions.sourceUnitPath = "root.bmx"
Local escapingUnit:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/acme.mod/multisource.mod/root.bmx", "SuperStrict~nImport ~q../outside.bmx~q", resolver, escapingUnitOptions)
Check(HasCompilerDiagnostic(escapingUnit, "BMXC1110"), "a quoted source cannot escape its owning source-root identity")

Local cDiagnostics:TCompilerDiagnostic[]
Local cSource:String = TBlitzMaxCompiler.EmitC(compiled, cDiagnostics)
Check(cDiagnostics.length = 0, "supported scalar IR emits C without backend diagnostics")
Check(Contains(cSource, "#include <stdint.h>"), "C backend emits fixed-width scalar types")
Check(Contains(cSource, "int32_t bmx_fn0_Twice"), "C backend emits deterministic free-routine names")
Check(Contains(cSource, "int32_t _bb_main_LegacyCallback"), "C backend preserves the legacy NoMangle application name")
Check(Contains(cSource, "while ("), "C backend emits While")
Check(Contains(cSource, "if ("), "C backend emits If")
Check(Contains(cSource, "int main(void)"), "C backend emits a standalone entry point")
Local repeatedCDiagnostics:TCompilerDiagnostic[]
Check(TBlitzMaxCompiler.EmitC(repeated, repeatedCDiagnostics) = cSource, "C output is deterministic")

Local globalReturn:TCompilerResult = TBlitzMaxCompiler.Compile("global-return.bmx", "Strict~nIf True Then Return~nLocal skipped:Int=1", resolver, TestOptions())
Local globalReturnDiagnostics:TCompilerDiagnostic[]
Local globalReturnC:String = TBlitzMaxCompiler.EmitC(globalReturn, globalReturnDiagnostics)
Check(globalReturn.Succeeded() And globalReturnDiagnostics.length = 0 And Contains(globalReturnC, "return 0;"), "Strict module-level Return exits the generated Int entry routine")

Local implicitReturn:TCompilerResult = TBlitzMaxCompiler.Compile("implicit-return.bmx", "SuperStrict~nFunction Maybe:Int(value:Int)~nIf value Return 1~nEnd Function~nLocal fallback:Int = Maybe(0)", resolver, TestOptions())
Local implicitReturnDiagnostics:TCompilerDiagnostic[]
Local implicitReturnC:String = TBlitzMaxCompiler.EmitC(implicitReturn, implicitReturnDiagnostics)
Check(implicitReturn.Succeeded() And implicitReturnDiagnostics.length = 0 And Contains(implicitReturnC, "return 0;"), "non-Void routines that fall through return the BlitzMax default value instead of undefined C state")
Local bareValueReturn:TCompilerResult = TBlitzMaxCompiler.Compile("bare-value-return.bmx", "SuperStrict~nFunction Maybe:Int(value:Int)~nIf Not value Return~nReturn value~nEnd Function~nLocal fallback:Int = Maybe(0)", resolver, TestOptions())
Local bareValueReturnDiagnostics:TCompilerDiagnostic[]
Local bareValueReturnC:String = TBlitzMaxCompiler.EmitC(bareValueReturn, bareValueReturnDiagnostics)
Check(bareValueReturn.Succeeded() And bareValueReturnDiagnostics.length = 0 And Contains(bareValueReturnC, "return 0;") And Not Contains(bareValueReturnC, "return;"), "a bare Return in a non-Void ordinary routine returns the declared type's BlitzMax default")

Local chainedMultilineIf:TCompilerResult = TBlitzMaxCompiler.Compile("chained-multiline-if.bmx", "SuperStrict~nFunction Both:Int(a:Int, b:Int)~nIf a If b~nReturn 7~nEndIf~nReturn 0~nEnd Function~nFunction All:Int(a:Int, b:Int, c:Int)~nIf a Then If b If c Then~nReturn 9~nEnd If~nReturn 0~nEnd Function", resolver, TestOptions())
Local chainedMultilineIfDiagnostics:TCompilerDiagnostic[]
Local chainedMultilineIfC:String = TBlitzMaxCompiler.EmitRuntimeC(chainedMultilineIf, chainedMultilineIfDiagnostics)
Local compactChainedMultilineIfC:String = Compact(chainedMultilineIfC)
Check(chainedMultilineIf.Succeeded() And chainedMultilineIfDiagnostics.length = 0, "chained multiline If conditions lower without requiring duplicate EndIf terminators: " + CompilerDiagnosticSummary(chainedMultilineIf))
Check(Contains(compactChainedMultilineIfC, "if(bmx_p0_a){if(bmx_p1_b){return7;}}") And Contains(compactChainedMultilineIfC, "if(bmx_p0_a){if(bmx_p1_b){if(bmx_p2_c){return9;}}}"), "runtime C preserves every chained condition as a nested branch")

Local scalarEnumSource:String = "SuperStrict~nEnum EState:Byte~nUnknown = 5~nReady~nDone = 9~nEnd Enum~nEnum EAccess:UInt Flags~nRead~nWrite~nExecute~nEnd Enum~nFunction Advance:EState(value:EState)~nIf value = EState.Unknown Then Return EState.Ready~nReturn EState.Done~nEnd Function~nLocal current:EState~nLocal nextState:EState = Advance(current)~nLocal access:EAccess~nLocal matched:Int = nextState = EState.Ready"
Local scalarEnum:TCompilerResult = TBlitzMaxCompiler.Compile("scalar-enum.bmx", scalarEnumSource, resolver, TestOptions())
Local scalarEnumDump:String = TCompilerIrDumper.Dump(scalarEnum.ir)
Local scalarEnumDiagnostics:TCompilerDiagnostic[]
Local scalarEnumC:String = TBlitzMaxCompiler.EmitRuntimeC(scalarEnum, scalarEnumDiagnostics)
Check(scalarEnum.Succeeded() And Contains(scalarEnumDump, "enum @en0 EState:EState underlying Byte") And Contains(scalarEnumDump, "value Unknown = 5") And Contains(scalarEnumDump, "value Ready = 6") And Contains(scalarEnumDump, "enum @en1 EAccess:EAccess underlying UInt [flags]") And Contains(scalarEnumDump, "value Execute = 4"), "typed IR retains scalar Enum identity, underlying storage, values and Flags progression")
Check(Contains(scalarEnumDump, "function @fn0 Advance(%p0 value:EState) -> EState") And Contains(scalarEnumDump, "var local %v0 current:EState") And Contains(scalarEnumDump, "literal 5 : EState") And Contains(scalarEnumDump, "var local %v2 access:EAccess") And Contains(scalarEnumDump, "literal 0 : EAccess"), "Enum values cross routine and local-storage boundaries while defaults follow BlitzMax semantics")
Check(scalarEnumDiagnostics.length = 0 And Contains(scalarEnumC, "BBBYTE bmx_fn0_Advance(BBBYTE bmx_p0_value)") And Contains(scalarEnumC, "BBBYTE bmx_v0_current = 5;") And Contains(scalarEnumC, "BBUINT bmx_v2_access = 0;"), "runtime C represents scalar Enums with their declared integral ABI types")
Local publicEnum:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/states.mod/states.bmx", "SuperStrict~nModule acme.states~nEnum EState:Byte~nUnknown = 5~nReady~nEnd Enum~nEnum EAccess:UInt Flags~nRead~nWrite~nEnd Enum~nEnum EWide:ULongInt~nSmall=1~nEnd Enum~nConst DefaultState:EState=EState.Ready~nFunction Advance:EState(value:EState=EState.Unknown)~nIf value = EState.Unknown Then Return EState.Ready~nReturn value~nEnd Function", resolver, TestOptions())
Local publicEnumInterfaceDiagnostics:TCompilerDiagnostic[]
Local publicEnumInterface:String = TBlitzMaxCompiler.EmitInterface(publicEnum, publicEnumInterfaceDiagnostics)
Local publicEnumHeaderDiagnostics:TCompilerDiagnostic[]
Local publicEnumHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(publicEnum, publicEnumHeaderDiagnostics)
Check(publicEnum.Succeeded() And publicEnumInterfaceDiagnostics.length = 0 And Contains(publicEnumInterface, "EState\@{") And Contains(publicEnumInterface, "Unknown=5") And Contains(publicEnumInterface, "}=" + Chr(34) + "acme_states_EState" + Chr(34)) And Contains(publicEnumInterface, "EAccess\|{") And Contains(publicEnumInterface, "}F=" + Chr(34) + "acme_states_EAccess" + Chr(34)) And Contains(publicEnumInterface, "EWide\%e{") And Contains(publicEnumInterface, "Advance/EState(value/EState=5)=") And Contains(publicEnumInterface, "DefaultState/EState=6"), "public scalar Enums, Enum constants, and Enum routine signatures emit the production compact interface shape")
Check(publicEnumHeaderDiagnostics.length = 0 And Contains(publicEnumHeader, "extern BBEnum *acme_states_EState_BBEnum_impl;") And Contains(publicEnumHeader, "BBSTRING acme_states_EState_ToString(BBBYTE ordinal);") And Contains(publicEnumHeader, "BBINT acme_states_EState_TryConvert(BBBYTE ordinalValue, BBBYTE *ordinalResult);") And Contains(publicEnumHeader, "BBBYTE acme_states_EState_FromString(BBSTRING name);") And Contains(publicEnumHeader, "extern const BBUINT bbEnumacme_states_EAccess_Mask;"), "public runtime headers expose the production-compatible Enum descriptor, helper, and Flags-mask ABI")
Local parsedPublicEnumInterface:TInterfaceFile = TInterfaceFileParser.Parse(publicEnumInterface, "sdk/acme.states.i")
Check(parsedPublicEnumInterface.diagnostics.length = 0 And parsedPublicEnumInterface.declarations.length = 5 And parsedPublicEnumInterface.declarations[0].kind = INTERFACE_RECORD_ENUM And parsedPublicEnumInterface.declarations[0].members.length = 2 And parsedPublicEnumInterface.declarations[1].flags.Contains("F"), "emitted Enum interfaces and constants round-trip through the shared interface parser")
resolver.AddInterface("acme.states", "sdk/acme.states.i", publicEnumInterface)
Local importedEnumContract:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/stateconsumer.mod/stateconsumer.bmx", "SuperStrict~nModule acme.stateconsumer~nImport acme.states~nConst DefaultImportedState:EState=EState.Ready~nFunction KeepState:EState(value:EState=DefaultImportedState)~nReturn value~nEnd Function", resolver, TestOptions())
Local importedEnumContractDiagnostics:TCompilerDiagnostic[]
Local importedEnumContractInterface:String = TBlitzMaxCompiler.EmitInterface(importedEnumContract, importedEnumContractDiagnostics)
Check(importedEnumContract.Succeeded() And importedEnumContractDiagnostics.length = 0 And Contains(importedEnumContractInterface, "import acme.states") And Contains(importedEnumContractInterface, "KeepState/EState(value/EState=6)") And Contains(importedEnumContractInterface, "DefaultImportedState/EState=6") And Not Contains(importedEnumContractInterface, "EState\@{"), "a public imported-Enum constant and default retain their defining import without republishing the Enum declaration")
Local importedEnumConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("enum-consumer.bmx", "SuperStrict~nImport acme.states~nLocal raw:Int=6~nLocal state:EState=DefaultState~nLocal nextState:EState=Advance(state)~nLocal ordinal:Int=Int(nextState)~nLocal text:String=nextState.ToString()~nLocal values:EState[]=EState.Values()~nLocal converted:EState~nLocal convertedOk:Int=EState.TryConvert(6,converted)~nLocal parsed:EState=EState.FromString(~qReady~q)~nLocal access:EAccess=EAccess.Write~nLocal matched:Int=nextState=EState.Ready", resolver, TestOptions())
Local importedEnumDump:String = TCompilerIrDumper.Dump(importedEnumConsumer.ir)
Local importedEnumDiagnostics:TCompilerDiagnostic[]
Local importedEnumC:String = TBlitzMaxCompiler.EmitRuntimeC(importedEnumConsumer, importedEnumDiagnostics)
Check(importedEnumConsumer.Succeeded() And Contains(importedEnumDump, "EState:EState underlying Byte [imported abi acme_states_EState from acme.states]") And Contains(importedEnumDump, "value Ready = 6") And Contains(importedEnumDump, "EAccess:EAccess underlying UInt [flags] [imported abi acme_states_EAccess from acme.states]"), "a separate consumer restores imported Enum identity, values, Flags, provenance, and ABI names")
Check(importedEnumDiagnostics.length = 0 And Not Contains(importedEnumC, "extern BBBYTE acme_states_Advance__NEStateE(BBBYTE bmx_ep0_value);") And Not Contains(importedEnumC, "bbEnumCast_b(") And Contains(importedEnumC, "acme_states_Advance__NEStateE(") And Contains(importedEnumC, "acme_states_EState_ToString(") And Contains(importedEnumC, "bbEnumValues(acme_states_EState_BBEnum_impl)") And Contains(importedEnumC, "acme_states_EState_TryConvert(") And Contains(importedEnumC, "acme_states_EState_FromString("), "imported Enums defer declarations to their header while retaining scalar ABI, release casts, and producer-owned runtime helpers")

Local enumRuntimeSource:String = "SuperStrict~nEnum ERuntimeState:Byte~nUnknown=5~nReady~nDone=9~nEnd Enum~nEnum ERuntimeAccess:UInt Flags~nNone=0~nRead~nWrite~nExecute~nEnd Enum~nLocal raw:Int=6~nLocal state:ERuntimeState=ERuntimeState(raw)~nLocal numeric:Int=Int(state)~nLocal ordinal:Byte=state.Ordinal()~nLocal text:String=state.ToString()~nLocal coerced:String=state~nLocal message:String=~qstate=~q+state~nLocal values:ERuntimeState[]=ERuntimeState.Values()~nLocal converted:ERuntimeState~nLocal ok:Int=ERuntimeState.TryConvert(9,converted)~nLocal parsed:ERuntimeState=ERuntimeState.FromString(~qready~q)~nLocal access:ERuntimeAccess=ERuntimeAccess.Read|ERuntimeAccess.Write~nLocal accessText:String=access.ToString()~nLocal parsedAccess:ERuntimeAccess=ERuntimeAccess.FromString(~qRead|Write~q)~nLocal created:ERuntimeState[]=New ERuntimeState[2]~nLocal literal:ERuntimeState[]=[ERuntimeState.Ready,ERuntimeState.Done]~nLocal joined:ERuntimeState[]=values+literal"
Local enumRuntime:TCompilerResult = TBlitzMaxCompiler.Compile("enum-runtime.bmx", enumRuntimeSource, resolver, TestOptions())
Local enumRuntimeDump:String = TCompilerIrDumper.Dump(enumRuntime.ir)
Local enumRuntimeDiagnostics:TCompilerDiagnostic[]
Local enumRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(enumRuntime, enumRuntimeDiagnostics)
Local enumRuntimeAbiName:String = enumRuntime.ir.enums[0].abiName
Check(enumRuntime.Succeeded() And enumRuntimeAbiName.StartsWith("bmx_direct_eruntimestate_") And Contains(enumRuntimeDump, "[runtime b /ERuntimeState descriptor " + enumRuntimeAbiName + "_BBEnum_impl]") And Contains(enumRuntimeDump, "enum-ordinal @en0") And Contains(enumRuntimeDump, "enum-to-string @en0") And Contains(enumRuntimeDump, "enum-values @en0") And Contains(enumRuntimeDump, "enum-try-convert @en0") And Contains(enumRuntimeDump, "enum-from-string @en0"), "typed IR retains canonical Enum runtime descriptors, built-in operations, and Enum-to-String conversion")
Check(Contains(enumRuntimeDump, "string-concat") And Contains(enumRuntimeC, "bbStringConcat(") And Not HasCompilerDiagnostic(enumRuntime, "BMXC2026"), "String concatenation adapts Enum operands through their retained runtime descriptor rather than numeric formatting")
Check(Contains(enumRuntimeDump, "convert explicit explicit checked-enum @en0") And Contains(enumRuntimeDump, "array-concat") And Contains(enumRuntimeDump, "element-layout enum @en0"), "typed IR retains the checked numeric-to-Enum boundary and Enum array-concatenation layout")
Check(enumRuntimeDiagnostics.length = 0 And Contains(enumRuntimeC, "struct BCC2_BBEnum_en0_ERuntimeState") And Contains(enumRuntimeC, "BBDEBUGSCOPE_USERENUM") And Contains(enumRuntimeC, enumRuntimeAbiName + "_values[3] = {5,6,9}") And Contains(enumRuntimeC, "bbEnumRegister(" + enumRuntimeAbiName + "_BBEnum_impl") And Contains(enumRuntimeC, "bbEnumValues(" + enumRuntimeAbiName + "_BBEnum_impl)") And Contains(enumRuntimeC, enumRuntimeAbiName + "_ToString(") And Contains(enumRuntimeC, enumRuntimeAbiName + "_TryConvert(") And Contains(enumRuntimeC, enumRuntimeAbiName + "_FromString("), "runtime C owns one canonical Enum descriptor, reflection scope, value table, registration, and compatibility wrappers")
Check(Not Contains(enumRuntimeC, "bbEnumCast_b(") And Contains(enumRuntimeC, "bbArrayNew1DEnum(~q/ERuntimeState~q, 2, " + enumRuntimeAbiName + "_BBEnum_impl)") And Contains(enumRuntimeC, "bbArrayFromDataSize(~q/ERuntimeState~q, 2, (BBBYTE[])") And Contains(enumRuntimeC, "bbArrayConcat(~q/ERuntimeState~q") And Contains(enumRuntimeC, "sizeof(BBBYTE)"), "release Enum casts remain scalar while array allocation, literals, and concatenation retain Enum layout")
Local contextualEmptyNestedArray:TCompilerResult = TBlitzMaxCompiler.Compile("contextual-empty-nested-array.bmx", "SuperStrict~nType THolder~nField total:Int[][2]~nMethod Reset:Int()~ntotal=[]~nReturn total.length~nEnd Method~nEnd Type", resolver, TestOptions())
Local contextualEmptyNestedArrayDiagnostics:TCompilerDiagnostic[]
Local contextualEmptyNestedArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(contextualEmptyNestedArray, contextualEmptyNestedArrayDiagnostics)
Check(contextualEmptyNestedArray.Succeeded() And contextualEmptyNestedArrayDiagnostics.length = 0 And Contains(contextualEmptyNestedArrayC, "= &bbEmptyArray;"), "an empty literal uses its known nested heap-array assignment type and lowers to the canonical empty-array sentinel")

Local nestedArrayFieldDimensions:TCompilerResult = TBlitzMaxCompiler.Compile("nested-array-field-dimensions.bmx", "SuperStrict~nType TNestedArrayFields~nField leading:String[4][]~nField trailing:String[][4]~nEnd Type~nLocal holder:TNestedArrayFields=New TNestedArrayFields~nLocal first:String[]=holder.leading[0]~nLocal second:String[]=holder.trailing[0]", resolver, TestOptions())
Local nestedArrayFieldDimensionsDiagnostics:TCompilerDiagnostic[]
Local nestedArrayFieldDimensionsC:String = TBlitzMaxCompiler.EmitRuntimeC(nestedArrayFieldDimensions, nestedArrayFieldDimensionsDiagnostics)
Check(nestedArrayFieldDimensions.Succeeded() And nestedArrayFieldDimensionsDiagnostics.length = 0 And Occurrences(nestedArrayFieldDimensionsC, "bbArrayNew1D(~q[]$~q, 4)") = 2, "a fixed outer length initializes nested-array fields whether the allocated suffix precedes or follows the empty nested suffix")
Local debugDependentArrayOptions:TCompilerOptions = DebugTestOptions()
debugDependentArrayOptions.debugInstrumentation = True
Local debugDependentArray:TCompilerResult = TBlitzMaxCompiler.Compile("debug-dependent-array.bmx", "SuperStrict~nFunction Build:Int[]()~nLocal count:Int=8~nLocal values:Int[count]~nReturn values~nEnd Function", resolver, debugDependentArrayOptions)
Local debugDependentArrayDiagnostics:TCompilerDiagnostic[]
Local debugDependentArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(debugDependentArray, debugDependentArrayDiagnostics)
Check(debugDependentArray.Succeeded() And debugDependentArrayDiagnostics.length = 0 And Contains(debugDependentArrayC, "BBARRAY bmx_v1_values = &bbEmptyArray;") And Contains(debugDependentArrayC, "bmx_v1_values = bbArrayNew1D(~qi~q, bmx_v0_count);"), "debug dynamic Array allocation remains at its source declaration after local predeclaration")
Local debugEnumRuntime:TCompilerResult = TBlitzMaxCompiler.Compile("enum-runtime-debug.bmx", enumRuntimeSource, resolver, DebugTestOptions())
Local debugEnumDiagnostics:TCompilerDiagnostic[]
Local debugEnumC:String = TBlitzMaxCompiler.EmitRuntimeC(debugEnumRuntime, debugEnumDiagnostics)
Local debugEnumRuntimeAbiName:String = debugEnumRuntime.ir.enums[0].abiName
Check(debugEnumRuntime.Succeeded() And debugEnumDiagnostics.length = 0 And Contains(debugEnumC, "bbEnumCast_b(" + debugEnumRuntimeAbiName + "_BBEnum_impl, bmx_v0_raw)"), "debug numeric-to-Enum conversion calls the typed runtime validator with the canonical descriptor")

Local repeatFlowSource:String = "SuperStrict~nLocal total:Int = 0~nLocal outer:Int = 0~n#Outer~nRepeat~nouter = outer + 1~nLocal inner:Int = 0~nRepeat~ninner = inner + 1~nIf inner = 2 Then Continue~nIf outer = 2 Then Continue Outer~nIf inner = 4 Then Exit~ntotal = total + 1~nForever~nIf outer = 3 Then Exit Outer~nUntil outer = 10"
Local repeatFlow:TCompilerResult = TBlitzMaxCompiler.Compile("repeat-flow.bmx", repeatFlowSource, resolver, TestOptions())
Check(repeatFlow.Succeeded(), "Repeat Until, Repeat Forever and labelled loop control lower successfully")
Local repeatFlowDump:String = TCompilerIrDumper.Dump(repeatFlow.ir)
Check(Contains(repeatFlowDump, "repeat until @repeat-flow.bmx:") And Contains(repeatFlowDump, "[loop @loop0] label outer") And Contains(repeatFlowDump, "repeat forever @repeat-flow.bmx:") And Contains(repeatFlowDump, "[loop @loop1]"), "Repeat forms retain explicit loop identities and source labels in typed IR")
Check(Contains(repeatFlowDump, "continue @loop1") And Contains(repeatFlowDump, "continue @loop0") And Contains(repeatFlowDump, "exit @loop1") And Contains(repeatFlowDump, "exit @loop0"), "Exit and Continue retain their resolved target loop identities")
Local repeatFlowDiagnostics:TCompilerDiagnostic[]
Local repeatFlowC:String = TBlitzMaxCompiler.EmitRuntimeC(repeatFlow, repeatFlowDiagnostics)
Check(repeatFlowDiagnostics.length = 0, "runtime backend emits Repeat and resolved loop control")
Check(Contains(repeatFlowC, "do {") And Contains(repeatFlowC, "for (;;) {") And Contains(repeatFlowC, "} while (!(") , "runtime C preserves post-test and forever loop shapes")
Check(Contains(repeatFlowC, "goto bmx_loop1_continue;") And Contains(repeatFlowC, "goto bmx_loop0_continue;") And Contains(repeatFlowC, "goto bmx_loop1_exit;") And Contains(repeatFlowC, "goto bmx_loop0_exit;"), "runtime C maps nested and labelled control to deterministic loop labels")

Local whileFlow:TCompilerResult = TBlitzMaxCompiler.Compile("while-flow.bmx", "SuperStrict~nLocal index:Int = 0~nLocal total:Int = 0~nWhile index < 6~nindex = index + 1~nIf index = 2 Then Continue~nIf index = 5 Then Exit~ntotal = total + index~nWend", resolver, TestOptions())
Check(whileFlow.Succeeded(), "Exit and Continue also lower inside While loops")
Local whileFlowDiagnostics:TCompilerDiagnostic[]
Local whileFlowC:String = TBlitzMaxCompiler.EmitRuntimeC(whileFlow, whileFlowDiagnostics)
Check(whileFlowDiagnostics.length = 0 And Contains(whileFlowC, "goto bmx_loop0_continue;") And Contains(whileFlowC, "bmx_loop0_continue: ;") And Contains(whileFlowC, "goto bmx_loop0_exit;") And Contains(whileFlowC, "bmx_loop0_exit: ;"), "While control uses the same explicit loop-target backend contract")

Local forRangeSource:String = "SuperStrict~nExtern~nFunction Mark:Int(value:Int) = ~qbcc2_mark~q~nEnd Extern~nLocal total:Int~nFor Local value:Int = Mark(1) To Mark(5) Step Mark(2)~ntotal = total + value~nNext~nFor Local down:Int = 5 To 1 Step -2~ntotal = total + down~nNext~nFor Local exclusive:Int = 0 Until 3~ntotal = total + exclusive~nNext~nLocal existing:Int~n#Outer~nFor existing = 1 To 3~nIf existing = 2 Then Continue Outer~nIf existing = 3 Then Exit Outer~ntotal = total + existing~nNext"
Local forRange:TCompilerResult = TBlitzMaxCompiler.Compile("for-range.bmx", forRangeSource, resolver, TestOptions())
Check(forRange.Succeeded(), "numeric For To/Until, positive/negative/default Step, existing targets, and labelled control lower successfully")
Local forRangeDump:String = TCompilerIrDumper.Dump(forRange.ir)
Check(Contains(forRangeDump, "for-range to ascending @for-range.bmx:") And Contains(forRangeDump, "declare %v1 value:Int") And Contains(forRangeDump, "for-range to descending") And Contains(forRangeDump, "for-range until ascending"), "range For IR retains declaration ownership, bound kind and syntactic direction")
Check(Contains(forRangeDump, "[loop @loop3] label outer") And Contains(forRangeDump, "continue @loop3") And Contains(forRangeDump, "exit @loop3"), "range For participates in resolved labelled loop control")
Local forRangeDiagnostics:TCompilerDiagnostic[]
Local forRangeC:String = TBlitzMaxCompiler.EmitRuntimeC(forRange, forRangeDiagnostics)
Check(forRangeDiagnostics.length = 0, "runtime backend emits numeric range For loops")
Local rejectedTypedExistingFor:TCompilerResult = TBlitzMaxCompiler.Compile("rejected-typed-existing-for.bmx", "SuperStrict~nLocal existing:Int~nFor existing:Int = 0 Until 2~nNext", resolver, TestOptions())
Check(Not rejectedTypedExistingFor.Succeeded() And CompilerDiagnosticSummary(rejectedTypedExistingFor).Contains("BMX2105"), "an already-declared For control variable cannot carry a postfix named type")
Check(Contains(forRangeC, "<= ((BBINT)(bcc2_mark(5)))") And Contains(forRangeC, "+ ((BBINT)(bcc2_mark(2)))") And Contains(forRangeC, ">= ((BBINT)(1))") And Contains(forRangeC, "+ ((BBINT)((-2)))") And Contains(forRangeC, "< ((BBINT)(3))"), "runtime C preserves inclusive, exclusive, descending and repeated bound/step evaluation semantics")
Check(Contains(forRangeC, "goto bmx_loop3_continue;") And Contains(forRangeC, "bmx_loop3_continue: ;") And Contains(forRangeC, "goto bmx_loop3_exit;") And Contains(forRangeC, "bmx_loop3_exit: ;"), "range For emits deterministic continue and exit targets")

Local arrayEachInSource:String = "SuperStrict~nFunction MakeValues:Int[]()~nReturn [1, 2, 3, 4]~nEnd Function~nLocal total:Int~n#Outer~nFor Local value:Int = EachIn MakeValues()~nIf value = 2 Then Continue~nIf value = 4 Then Exit Outer~ntotal = total + value~nNext~nLocal words:String[] = [~qone~q, ~qtwo~q]~nFor Local word:String = EachIn words~nIf word Then total = total + 1~nNext~nLocal rows:Int[][] = [[1], [2, 3]]~nFor Local row:Int[] = EachIn rows~ntotal = total + row.length~nNext~nLocal existing:Int~nLocal values:Int[] = [5, 6]~nFor existing = EachIn values~ntotal = total + existing~nNext"
Local arrayEachIn:TCompilerResult = TBlitzMaxCompiler.Compile("array-eachin.bmx", arrayEachInSource, resolver, TestOptions())
Check(arrayEachIn.Succeeded(), "managed scalar, String and nested Array EachIn loops lower successfully")
Local arrayEachInDump:String = TCompilerIrDumper.Dump(arrayEachIn.ir)
Check(Contains(arrayEachInDump, "for-each-array Int @array-eachin.bmx:") And Contains(arrayEachInDump, "[loop @loop0] label outer") And Contains(arrayEachInDump, "declare %v1 value:Int") And Contains(arrayEachInDump, "[collection %t") And Contains(arrayEachInDump, "[index %t"), "Array EachIn IR retains collection/index temporaries, loop identity and local declaration ownership")
Check(Contains(arrayEachInDump, "for-each-array String") And Contains(arrayEachInDump, "for-each-array Int[]") And Contains(arrayEachInDump, "continue @loop0") And Contains(arrayEachInDump, "exit @loop0"), "managed element types and resolved EachIn control remain explicit in IR")
Local arrayEachInDiagnostics:TCompilerDiagnostic[]
Local arrayEachInC:String = TBlitzMaxCompiler.EmitRuntimeC(arrayEachIn, arrayEachInDiagnostics)
Check(arrayEachInDiagnostics.length = 0, "runtime backend emits managed Array EachIn loops")
Check(Contains(arrayEachInC, "BBARRAY bmx_tmp_") And Contains(arrayEachInC, " = bmx_fn0_MakeValues();") And Contains(arrayEachInC, "BBUINT bmx_tmp_") And Contains(arrayEachInC, "< (BBUINT)bmx_tmp_") And Contains(arrayEachInC, "BBARRAYDATA("), "runtime C evaluates the collection once and iterates with hidden unsigned index storage")
Check(Contains(arrayEachInC, "BBSTRING bmx_") And Contains(arrayEachInC, "BBARRAY bmx_") And Contains(arrayEachInC, "goto bmx_loop0_continue;") And Contains(arrayEachInC, "goto bmx_loop0_exit;"), "runtime C uses typed element cells and the shared loop-control contract")

Local convertedArrayEachInSource:String = "SuperStrict~nLocal bytes:Byte[] = [1, 2, 255]~nLocal widened:Int~nFor Local value:Int = EachIn bytes~nwidened :+ value~nNext~nLocal integers:Int[] = [257, 258, 511]~nLocal narrowed:Int~nFor Local value:Byte = EachIn integers~nnarrowed :+ value~nNext"
Local convertedArrayEachIn:TCompilerResult = TBlitzMaxCompiler.Compile("converted-array-eachin.bmx", convertedArrayEachInSource, resolver, TestOptions())
Check(convertedArrayEachIn.Succeeded(), "managed numeric Array EachIn applies ordinary assignment conversions to loop variables")
Local convertedArrayEachInDump:String = TCompilerIrDumper.Dump(convertedArrayEachIn.ir)
Check(Contains(convertedArrayEachInDump, "convert implicit numeric-widening") And Contains(convertedArrayEachInDump, "convert implicit numeric-narrowing"), "Array EachIn IR retains widening and narrowing element conversions explicitly")
Local convertedArrayEachInDiagnostics:TCompilerDiagnostic[]
Local convertedArrayEachInC:String = TBlitzMaxCompiler.EmitRuntimeC(convertedArrayEachIn, convertedArrayEachInDiagnostics)
Check(convertedArrayEachInDiagnostics.length = 0 And Contains(convertedArrayEachInC, "BBINT bmx_v") And Contains(convertedArrayEachInC, "= ((BBINT)(bmx_tmp_") And Contains(convertedArrayEachInC, "BBBYTE bmx_v") And Contains(convertedArrayEachInC, "= ((BBBYTE)(bmx_tmp_"), "runtime C assigns converted numeric Array elements through typed loop-variable storage")

Local deconstructEachInSource:String = "SuperStrict~nInterface IDeconstruct2<A, B>~nMethod Deconstruct(first:A Var, second:B Var)~nEnd Interface~nType TPair Implements IDeconstruct2<String, Int>~nField key:String~nField value:Int~nMethod Deconstruct(first:String Var, second:Int Var)~nfirst=key~nsecond=value~nEnd Method~nEnd Type~nLocal pairs:TPair[]=[New TPair]~nLocal total:Int~nFor Local key:String, value:Int = EachIn pairs~ntotal :+ key.length + value~nNext~nFor Local inferredKey, inferredValue = EachIn pairs~ntotal :+ inferredKey.length + inferredValue~nNext"
Local deconstructEachIn:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/brl.mod/blitz.mod/blitz.bmx", deconstructEachInSource, resolver, TestOptions())
Check(deconstructEachIn.Succeeded(), "explicit and inferred IDeconstruct2 Array bindings lower successfully: " + CompilerDiagnosticSummary(deconstructEachIn))
Local deconstructEachInDump:String = TCompilerIrDumper.Dump(deconstructEachIn.ir)
Check(Occurrences(deconstructEachInDump, "for-each-array TPair") = 2 And Contains(deconstructEachInDump, "$deconstruct0:TPair") And Contains(deconstructEachInDump, "key:String") And Contains(deconstructEachInDump, "value:Int"), "typed IR keeps one yielded element and two independently typed component locals")
Check(Occurrences(deconstructEachInDump, "call interface") = 2 And Contains(deconstructEachInDump, "Deconstruct : Void") And Contains(deconstructEachInDump, "address-of : String") And Contains(deconstructEachInDump, "address-of : Int"), "typed IR performs one closed IDeconstruct2 call per iteration with exact Var component identities")
Local deconstructEachInDiagnostics:TCompilerDiagnostic[]
Local deconstructEachInC:String = TBlitzMaxCompiler.EmitRuntimeC(deconstructEachIn, deconstructEachInDiagnostics)
Check(deconstructEachInDiagnostics.length = 0 And Occurrences(deconstructEachInC, "m_deconstruct_0") >= 2, "runtime C dispatches deconstruction through the resolved generic Interface slot")

Local stringEachInSource:String = "SuperStrict~nFunction MakeText:String()~nReturn ~qAz!~q~nEnd Function~nLocal total:Int~n#Outer~nFor Local code:Int = EachIn MakeText()~nIf code = 122 Then Continue Outer~nIf code = 33 Then Exit Outer~ntotal = total + code~nNext~nLocal existing:Short~nFor existing = EachIn ~qB~q~ntotal = total + existing~nNext"
Local stringEachIn:TCompilerResult = TBlitzMaxCompiler.Compile("string-eachin.bmx", stringEachInSource, resolver, TestOptions())
Check(stringEachIn.Succeeded(), "String EachIn lowers local and existing numeric code-unit targets")
Local stringEachInDump:String = TCompilerIrDumper.Dump(stringEachIn.ir)
Check(Contains(stringEachInDump, "for-each-string Int @string-eachin.bmx:") And Contains(stringEachInDump, "[loop @loop0] label outer") And Contains(stringEachInDump, "declare %v1 code:Int") And Contains(stringEachInDump, "[collection %t") And Contains(stringEachInDump, "[index %t") And Contains(stringEachInDump, "[element %t"), "String EachIn IR retains evaluate-once storage, UTF-16 element identity and declaration ownership")
Check(Contains(stringEachInDump, "continue @loop0") And Contains(stringEachInDump, "exit @loop0") And Contains(stringEachInDump, "for-each-string Int") And Contains(stringEachInDump, "existing : Short"), "String EachIn retains resolved control and typed existing targets")
Local stringEachInDiagnostics:TCompilerDiagnostic[]
Local stringEachInC:String = TBlitzMaxCompiler.EmitRuntimeC(stringEachIn, stringEachInDiagnostics)
Check(stringEachInDiagnostics.length = 0, "runtime backend emits String EachIn loops")
Check(Contains(stringEachInC, "BBSTRING bmx_tmp_") And Contains(stringEachInC, " = bmx_fn0_MakeText();") And Contains(stringEachInC, "BBUINT bmx_tmp_") And Contains(stringEachInC, "->length") And Contains(stringEachInC, "->buf[") And Contains(stringEachInC, "BBINT bmx_tmp_"), "runtime C evaluates String collections once and reads BBChar code units through hidden typed storage")
Check(Contains(stringEachInC, "((BBSHORT)(bmx_tmp_") And Contains(stringEachInC, "goto bmx_loop0_continue;") And Contains(stringEachInC, "goto bmx_loop0_exit;"), "runtime C converts code units to the loop target type and shares deterministic loop-control labels")

Local invalidStringEachIn:TCompilerResult = TBlitzMaxCompiler.Compile("invalid-string-eachin.bmx", "SuperStrict~nFor Local value:String = EachIn ~qabc~q~nNext", resolver, TestOptions())
Check(HasCompilerDiagnostic(invalidStringEachIn, "BMXC1018"), "String EachIn rejects nonnumeric code-unit targets explicitly")

Local staticArrayEachInSource:String = "SuperStrict~nLocal StaticArray values:Int[4]~nvalues[0] = 1~nvalues[1] = 2~nvalues[2] = 3~nvalues[3] = 4~nLocal total:Int = values.length~n#Outer~nFor Local value:Short = EachIn values~nIf value = 2 Then Continue Outer~nIf value = 4 Then Exit Outer~ntotal = total + value~nNext~nLocal existing:Int~nFor existing = EachIn values~ntotal = total + existing~nNext"
Local staticArrayEachIn:TCompilerResult = TBlitzMaxCompiler.Compile("static-array-eachin.bmx", staticArrayEachInSource, resolver, TestOptions())
Check(staticArrayEachIn.Succeeded(), "numeric StaticArray storage, indexing, length and EachIn lower successfully")
Local staticArrayEachInDump:String = TCompilerIrDumper.Dump(staticArrayEachIn.ir)
Check(Contains(staticArrayEachInDump, "[static-array Int x 4]") And Contains(staticArrayEachInDump, "static-array-element Int") And Contains(staticArrayEachInDump, "literal 4 : Int"), "StaticArray IR retains fixed storage shape, direct indexed access and constant extent")
Check(Contains(staticArrayEachInDump, "for-each-static-array Int x 4") And Contains(staticArrayEachInDump, "label outer") And Contains(staticArrayEachInDump, "value:Short") And Contains(staticArrayEachInDump, "[collection %t") And Contains(staticArrayEachInDump, "[index %t") And Contains(staticArrayEachInDump, "[element %t"), "StaticArray EachIn IR retains element type, extent, pointer materialization and loop ownership")
Local staticArrayEachInDiagnostics:TCompilerDiagnostic[]
Local staticArrayEachInC:String = TBlitzMaxCompiler.EmitRuntimeC(staticArrayEachIn, staticArrayEachInDiagnostics)
Check(staticArrayEachInDiagnostics.length = 0, "runtime backend emits numeric StaticArray operations")
Check(Contains(staticArrayEachInC, "BBINT bmx_v0_values[4] = {0};") And Contains(staticArrayEachInC, "bmx_v0_values[0] = 1;") And Contains(staticArrayEachInC, "BBINT *bmx_tmp_") And Contains(staticArrayEachInC, "< (BBUINT)4") And Contains(staticArrayEachInC, "((BBSHORT)(bmx_tmp_"), "runtime C uses fixed C storage, direct indexing, a typed pointer temporary and numeric element conversion")
Check(Contains(staticArrayEachInC, "goto bmx_loop0_continue;") And Contains(staticArrayEachInC, "goto bmx_loop0_exit;"), "StaticArray EachIn shares resolved deterministic loop-control labels")

Local broadStaticArraySource:String = "SuperStrict~nEnum EFixedValue:Byte~nFirst=5~nSecond=9~nEnd Enum~nGlobal StaticArray globalWords:String[2]~nStruct SFixedStrings~nField StaticArray values:String[2]~nEnd Struct~nLocal globalEmptyLength:Int=globalWords[0].length~nLocal raw:Byte~nLocal StaticArray pointers:Byte Ptr[2]~npointers[1]=Varptr raw~nLocal pointerCount:Int~nFor Local pointer:Byte Ptr=EachIn pointers~nIf pointer Then pointerCount:+1~nNext~nLocal StaticArray states:EFixedValue[2]~nstates[0]=EFixedValue.First~nstates[1]=EFixedValue.Second~nLocal stateTotal:Int~nFor Local state:EFixedValue=EachIn states~nstateTotal:+state.Ordinal()~nNext~nLocal StaticArray words:String[2]~nLocal emptyLength:Int=words[0].length~nwords[0]=~qfirst~q~nwords[1]=~qsecond~q~nLocal text:String~nFor Local word:String=EachIn words~ntext:+word~nNext~nLocal fixedStrings:SFixedStrings~nLocal fieldEmptyLength:Int=fixedStrings.values[0].length"
Local broadStaticArray:TCompilerResult = TBlitzMaxCompiler.Compile("broad-static-array.bmx", broadStaticArraySource, resolver, TestOptions())
Local broadStaticArrayDump:String = TCompilerIrDumper.Dump(broadStaticArray.ir)
Check(broadStaticArray.Succeeded() And broadStaticArray.ir.structs[0].containsManagedReferences, "Pointer, Enum and managed-reference StaticArray storage and exact EachIn targets lower successfully")
Check(Contains(broadStaticArrayDump, "for-each-static-array Byte Ptr x 2") And Contains(broadStaticArrayDump, "for-each-static-array EFixedValue x 2") And Contains(broadStaticArrayDump, "for-each-static-array String x 2"), "typed IR retains Pointer, Enum and String StaticArray iteration identities")
Local broadStaticArrayDiagnostics:TCompilerDiagnostic[]
Local broadStaticArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(broadStaticArray, broadStaticArrayDiagnostics)
Check(broadStaticArrayDiagnostics.length = 0 And Contains(broadStaticArrayC, "BBBYTE * bmx_v") And Contains(broadStaticArrayC, "BBBYTE bmx_v") And Contains(broadStaticArrayC, "BBSTRING bmx_v"), "runtime C uses typed Pointer, Enum-underlying and String fixed cells")
Check(Contains(broadStaticArrayC, "= &bbEmptyString;") And Contains(broadStaticArrayC, "for (BBUINT bmx_static_init_g") And Contains(broadStaticArrayC, "for (BBUINT bmx_static_init_v") And Contains(broadStaticArrayC, "for (BBUINT bmx_static_field_init_"), "global, local and Struct-field managed StaticArrays initialize every cell with the canonical String sentinel")

Local staticArrayParameterSource:String = "SuperStrict~nStruct SParameterCell~nField value:Int~nMethod Add(delta:Int)~nvalue=value+delta~nEnd Method~nEnd Struct~nFunction AddCell(value:SParameterCell Var,delta:Int)~nvalue.value=value.value+delta~nEnd Function~nFunction Sum:Int(StaticArray values:Int[4])~nLocal total:Int=values.length~nFor Local value:Int=EachIn values~ntotal=total+value~nNext~nReturn total~nEnd Function~nFunction Touch(StaticArray cells:SParameterCell[2])~ncells[0].Add(2)~nAddCell(cells[1],3)~nEnd Function~nType TStaticParameterBase~nMethod Size:Int(StaticArray values:Int[4])~nReturn values.length~nEnd Method~nEnd Type~nType TStaticParameterDerived Extends TStaticParameterBase~nMethod Size:Int(StaticArray values:Int[4]) Override~nReturn values.length+1~nEnd Method~nEnd Type~nLocal StaticArray numbers:Int[4]~nLocal StaticArray cells:SParameterCell[2]~nTouch(cells)~nLocal owner:TStaticParameterBase=New TStaticParameterDerived~nLocal total:Int=Sum(numbers)+owner.Size(numbers)"
Local staticArrayParameter:TCompilerResult = TBlitzMaxCompiler.Compile("static-array-parameter.bmx", staticArrayParameterSource, resolver, TestOptions())
Local staticArrayParameterDump:String = TCompilerIrDumper.Dump(staticArrayParameter.ir)
Check(staticArrayParameter.Succeeded() And Contains(staticArrayParameterDump, "Sum(%p0 values:StaticArray Int[4])") And Contains(staticArrayParameterDump, "Touch(%p0 cells:StaticArray SParameterCell[2])") And Contains(staticArrayParameterDump, "Size(%p0 values:StaticArray Int[4])"), "routine parameter IR retains fixed extent and element type for free functions, Struct cells and overridden methods")
Check(Contains(staticArrayParameterDump, "static-array-element SParameterCell") And Contains(staticArrayParameterDump, "for-each-static-array Int x 4") And Contains(staticArrayParameterDump, "literal 4 : Int"), "StaticArray parameters remain typed storage inside the callee for indexing, EachIn and compile-time length")
Local staticArrayParameterDiagnostics:TCompilerDiagnostic[]
Local staticArrayParameterC:String = TBlitzMaxCompiler.EmitRuntimeC(staticArrayParameter, staticArrayParameterDiagnostics)
Check(staticArrayParameterDiagnostics.length = 0 And Contains(staticArrayParameterC, "BBINT bmx_p0_values[4]") And Contains(staticArrayParameterC, "struct bmx_struct_st0_SParameterCell bmx_p0_cells[2]") And Contains(staticArrayParameterC, "BBINT *") And Contains(staticArrayParameterC, "bmx_fn2_Touch(bmx_v") And Contains(staticArrayParameterC, "bmx_fn1_Sum(bmx_v"), "runtime C publishes production-shaped fixed-array declarations, pointer-compatible slots and zero-copy storage decay at calls")
Check(Contains(staticArrayParameterC, "bmx_fn0_AddCell((&bmx_p0_cells[1]), 3)") And Contains(staticArrayParameterC, "bmx_fn5_Add((&bmx_p0_cells[0]), 2)"), "Struct cells reached through a StaticArray parameter remain lvalues for methods and Var arguments")
Local mismatchedStaticArrayParameter:TCompilerResult = TBlitzMaxCompiler.Compile("mismatched-static-array-parameter.bmx", "SuperStrict~nFunction Need(StaticArray values:Int[4])~nEnd Function~nLocal StaticArray values:Int[3]~nNeed(values)", resolver, TestOptions())
Check(Not mismatchedStaticArrayParameter.Succeeded() And HasCompilerDiagnostic(mismatchedStaticArrayParameter, "BMXC1022"), "StaticArray routine calls require the declared fixed extent instead of accepting a different pointer-compatible storage shape")

Local globalStaticArray:TCompilerResult = TBlitzMaxCompiler.Compile("global-static-array.bmx", "SuperStrict~nGlobal StaticArray fixed:Byte[2]~nfixed[0] = 7~nfixed[1] = 9~nLocal total:Int~nFor Local value:Int = EachIn fixed~ntotal = total + value~nNext", resolver, TestOptions())
Check(globalStaticArray.Succeeded(), "global numeric StaticArray storage participates in indexing and EachIn")
Local globalStaticArrayDiagnostics:TCompilerDiagnostic[]
Local globalStaticArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(globalStaticArray, globalStaticArrayDiagnostics)
Check(globalStaticArrayDiagnostics.length = 0 And Contains(globalStaticArrayC, "static BBBYTE bmx_global_g0_fixed[2];") And Contains(globalStaticArrayC, "bmx_global_g0_fixed[0] = ((BBBYTE)(7));") And Contains(globalStaticArrayC, "BBBYTE *bmx_tmp_"), "runtime C owns global fixed storage and materializes its typed iteration pointer")

Local structStaticArraySource:String = "SuperStrict~nStruct SFixedItem~nField number:Int=3~nField text:String~nMethod Add(delta:Int)~nnumber=number+delta~nEnd Method~nEnd Struct~nFunction Mutate(value:SFixedItem Var,delta:Int)~nvalue.number=value.number+delta~nEnd Function~nGlobal StaticArray shared:SFixedItem[2]~nLocal StaticArray values:SFixedItem[2]~nvalues[0].number=20~nvalues[0].Add(2)~nMutate(values[1],3)~nshared[0]=values[0]~nLocal first:SFixedItem=values[0]~nLocal total:Int=first.number+shared.length~nFor Local item:SFixedItem=EachIn values~ntotal=total+item.number~nNext"
Local structStaticArray:TCompilerResult = TBlitzMaxCompiler.Compile("struct-static-array.bmx", structStaticArraySource, resolver, TestOptions())
Local structStaticArrayDump:String = TCompilerIrDumper.Dump(structStaticArray.ir)
Check(structStaticArray.Succeeded() And Contains(structStaticArrayDump, "[static-array SFixedItem x 2] [element-layout struct @st0]") And Contains(structStaticArrayDump, "static-array-element SFixedItem") And Contains(structStaticArrayDump, "for-each-static-array SFixedItem x 2") And Contains(structStaticArrayDump, "element-layout struct @st0"), "Struct StaticArray IR retains source layout identity for storage, indexed lvalues and EachIn copies")
Local structStaticArrayDiagnostics:TCompilerDiagnostic[]
Local structStaticArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(structStaticArray, structStaticArrayDiagnostics)
Check(structStaticArrayDiagnostics.length = 0 And Contains(structStaticArrayC, "struct bmx_struct_st0_SFixedItem bmx_global_g0_shared[2];") And Contains(structStaticArrayC, "struct bmx_struct_st0_SFixedItem bmx_v") And Contains(structStaticArrayC, "[2] = {0};") And Contains(structStaticArrayC, "for (BBUINT bmx_static_init_g0") And Contains(structStaticArrayC, "for (BBUINT bmx_static_init_v") And Contains(structStaticArrayC, "= bmx_struct_new_bmx_class_st0_SFixedItem_default();"), "source Struct StaticArrays use fixed by-value C storage and default-construct every global and local cell")
Check(Contains(structStaticArrayC, "&bmx_v") And Contains(structStaticArrayC, "[1]") And Contains(structStaticArrayC, "struct bmx_struct_st0_SFixedItem *bmx_tmp_") And Not Contains(structStaticArrayC, "((struct bmx_struct_st0_SFixedItem)("), "indexed Struct cells remain addressable for methods and Var calls while EachIn copies exact Struct values without illegal C casts")
Local parameterizedStructStaticArray:TCompilerResult = TBlitzMaxCompiler.Compile("parameterized-struct-static-array.bmx", "SuperStrict~nStruct SFixedParameterized~nField value:Int=7~nField text:String~nMethod New(seed:Int)~nvalue=seed~nEnd Method~nEnd Struct~nLocal StaticArray values:SFixedParameterized[2]~nLocal result:Int=values[0].value", resolver, TestOptions())
Local parameterizedStructStaticArrayDiagnostics:TCompilerDiagnostic[]
Local parameterizedStructStaticArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(parameterizedStructStaticArray, parameterizedStructStaticArrayDiagnostics)
Check(parameterizedStructStaticArray.Succeeded() And parameterizedStructStaticArrayDiagnostics.length = 0 And Contains(parameterizedStructStaticArrayC, "bmx_struct_new_bmx_class_st0_SFixedParameterized_default") And Contains(parameterizedStructStaticArrayC, "_sfixedparameterized_value = 7;") And Contains(parameterizedStructStaticArrayC, "_sfixedparameterized_text = &bbEmptyString;"), "source fixed Struct storage uses field defaults and managed sentinels even when only parameterized constructors are declared")

Local parameterizedStructLocal:TCompilerResult = TBlitzMaxCompiler.Compile("parameterized-struct-local.bmx", "SuperStrict~nStruct SLocalParameterized~nField value:Int=7~nMethod New(seed:Int)~nvalue=seed~nEnd Method~nEnd Struct~nLocal value:SLocalParameterized~nLocal result:Int=value.value", resolver, TestOptions())
Local parameterizedStructLocalDiagnostics:TCompilerDiagnostic[]
Local parameterizedStructLocalC:String = TBlitzMaxCompiler.EmitRuntimeC(parameterizedStructLocal, parameterizedStructLocalDiagnostics)
Check(parameterizedStructLocal.Succeeded() And parameterizedStructLocalDiagnostics.length = 0 And Contains(parameterizedStructLocalC, "bmx_struct_new_bmx_class_st0_SLocalParameterized_default()") And Contains(parameterizedStructLocalC, "_slocalparameterized_value = 7;"), "ordinary Struct storage retains implicit value-default construction when only parameterized New overloads are declared")

Local parameterizedNestedStruct:TCompilerResult = TBlitzMaxCompiler.Compile("parameterized-nested-struct.bmx", "SuperStrict~nStruct SInnerParameterized~nField value:Int=7~nMethod New(seed:Int)~nvalue=seed~nEnd Method~nEnd Struct~nStruct SOuterParameterized~nField inner:SInnerParameterized~nEnd Struct~nLocal outer:SOuterParameterized~nLocal result:Int=outer.inner.value", resolver, TestOptions())
Local parameterizedNestedStructDiagnostics:TCompilerDiagnostic[]
Local parameterizedNestedStructC:String = TBlitzMaxCompiler.EmitRuntimeC(parameterizedNestedStruct, parameterizedNestedStructDiagnostics)
Check(parameterizedNestedStruct.Succeeded() And parameterizedNestedStructDiagnostics.length = 0 And Contains(parameterizedNestedStructC, "_souterparameterized_inner = bmx_struct_new_bmx_class_st0_SInnerParameterized_default();") And Contains(parameterizedNestedStructC, "_sinnerparameterized_value = 7;"), "nested Struct fields use the implicit value-default helper when their type only declares parameterized constructors")

Local explicitDefaultStruct:TCompilerResult = TBlitzMaxCompiler.Compile("explicit-default-struct.bmx", "SuperStrict~nStruct SExplicitDefault~nField value:Int~nMethod New()~nvalue=7~nEnd Method~nEnd Struct~nLocal item:SExplicitDefault", resolver, TestOptions())
Local explicitDefaultStructDiagnostics:TCompilerDiagnostic[]
Local explicitDefaultStructC:String = TBlitzMaxCompiler.EmitRuntimeC(explicitDefaultStruct, explicitDefaultStructDiagnostics)
Check(explicitDefaultStruct.Succeeded() And explicitDefaultStructDiagnostics.length = 0 And explicitDefaultStructC.Find("SExplicitDefault_New_ObjectNew(void)") = explicitDefaultStructC.FindLast("SExplicitDefault_New_ObjectNew(void)"), "an explicit zero-argument Struct New owns the default value-helper ABI exactly once")

Local forwardDescriptorSource:String = "SuperStrict~nType TBefore~nField later:TLater=New TLater~nEnd Type~nType TLater~nEnd Type"
Local forwardDescriptor:TCompilerResult = TBlitzMaxCompiler.Compile("forward-descriptor.bmx", forwardDescriptorSource, resolver, TestOptions())
Local forwardDescriptorDiagnostics:TCompilerDiagnostic[]
Local forwardDescriptorC:String = TBlitzMaxCompiler.EmitRuntimeC(forwardDescriptor, forwardDescriptorDiagnostics)
Check(forwardDescriptor.Succeeded() And forwardDescriptorDiagnostics.length = 0 And AppearsBefore(forwardDescriptorC, "extern struct BCC2_BBClass_cls1_TLater bmx_class_cls1_TLater;", "bbObjectAtomicNew((BBClass *)&bmx_class_cls1_TLater)"), "class descriptors are declared before earlier Type field initializers can construct a later Type")

Local forwardCallbackModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/forwardcallback.mod/forwardcallback.bmx", "SuperStrict~nModule acme.forwardcallback~nType TWorld~nMethod Register(callback:Void(iter:TIter))~nEnd Method~nEnd Type~nType TIter~nEnd Type", resolver, TestOptions())
Local forwardCallbackHeaderDiagnostics:TCompilerDiagnostic[]
Local forwardCallbackHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(forwardCallbackModule, forwardCallbackHeaderDiagnostics)
Check(forwardCallbackModule.Succeeded() And forwardCallbackHeaderDiagnostics.length = 0 And AppearsBefore(forwardCallbackHeader, "struct acme_forwardcallback_TIter_obj;", "struct BBClass_acme_forwardcallback_TWorld {"), "runtime headers publish every Type tag before an earlier class slot can reference a later Type in a callback signature")

Local privateSlotTypeModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/privateslot.mod/privateslot.bmx", "SuperStrict~nModule acme.privateslot~nType TWorker~nPrivate~nMethod Process(value:THidden)~nEnd Method~nEnd Type~nPrivate~nType THidden~nEnd Type", resolver, TestOptions())
Local privateSlotTypeHeaderDiagnostics:TCompilerDiagnostic[]
Local privateSlotTypeHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(privateSlotTypeModule, privateSlotTypeHeaderDiagnostics)
Local privateSlotTypeInterfaceDiagnostics:TCompilerDiagnostic[]
Local privateSlotTypeInterface:String = TBlitzMaxCompiler.EmitInterface(privateSlotTypeModule, privateSlotTypeInterfaceDiagnostics)
Check(privateSlotTypeModule.Succeeded() And privateSlotTypeHeaderDiagnostics.length = 0 And privateSlotTypeInterfaceDiagnostics.length = 0, "private slot parameter Type fixture compiles and emits both artifacts")
Check(AppearsBefore(privateSlotTypeHeader, "struct bmx_cls1_THidden_obj;", "struct BBClass_acme_privateslot_TWorker {"), "runtime headers give private slot parameter Types file-scope C tags before published class layouts")
Check(Not Contains(privateSlotTypeInterface, "THidden^") And Not Contains(privateSlotTypeInterface, "value:THidden"), "compact interfaces do not expose the private slot parameter Type as a declaration or language signature")
Check(Contains(privateSlotTypeInterface, "Process(value:Object)P="), "compact interfaces retain a private Object-erased record for class layout reconstruction")

Local nestedCallableInterfaceSource:String = "SuperStrict~nModule acme.nestedcallables~nType TMatrix~nField callbacks:Int(values:String[,])[,]~nMethod Use:Int(callback:Int(values:String[,]), values:String[,])~nReturn 0~nEnd Method~nMethod Factory:Int(values:String[,])(enabled:Int)~nReturn Null~nEnd Method~nEnd Type~nGlobal MatrixCallbacks:Int(values:String[,])[,]~nFunction Apply:Int(callback:Int(values:String[,]), values:String[,])~nReturn 0~nEnd Function"
Local nestedCallableInterfaceModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nestedcallables.mod/nestedcallables.bmx", nestedCallableInterfaceSource, resolver, TestOptions())
Local nestedCallableInterfaceDiagnostics:TCompilerDiagnostic[]
Local nestedCallableInterface:String = TBlitzMaxCompiler.EmitInterface(nestedCallableInterfaceModule, nestedCallableInterfaceDiagnostics)
Check(nestedCallableInterfaceModule.Succeeded() And nestedCallableInterfaceDiagnostics.length = 0 And Contains(nestedCallableInterface, ".callbacks%(values$&[,])&[,]&") And Contains(nestedCallableInterface, "-Use%(callback%(values$&[,]),values$&[,])=") And Contains(nestedCallableInterface, "-Factory%(values$&[,])(enabled%)=") And Contains(nestedCallableInterface, "MatrixCallbacks%(values$&[,])&[,]&=mem:p("), "compact interfaces preserve production-ranked callable fields, parameters, results, Globals, and source parameter names")
Local parsedNestedCallableInterface:TInterfaceFile = TInterfaceFileParser.Parse(nestedCallableInterface, "sdk/acme.nestedcallables.i")
Check(parsedNestedCallableInterface.diagnostics.length = 0 And parsedNestedCallableInterface.declarations.length = 3, "nested ranked callable compact records round-trip through the shared interface parser")
resolver.AddInterface("acme.nestedcallables", "sdk/acme.nestedcallables.i", nestedCallableInterface)
Local nestedCallableInterfaceConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("nested-callable-interface-consumer.bmx", "SuperStrict~nImport acme.nestedcallables~nLocal callbacks:Int(values:String[,])[,] = MatrixCallbacks", resolver, TestOptions())
Check(nestedCallableInterfaceConsumer.Succeeded(), "a source-free consumer reconstructs a published ranked callable Global: " + CompilerDiagnosticSummary(nestedCallableInterfaceConsumer))

Local deepNestedCallableSource:String = "SuperStrict~nModule acme.deepnestedcallables~nType TDeepProbe~nField callbackArrays:String[,](values:Int[,,])[]~nMethod Make:String[,](values:Int[,,])(enabled:Int)~nReturn Null~nEnd Method~nEnd Type~nGlobal CallbackArrays:String[,](values:Int[,,])[]~nFunction Apply:String[,](callback:String[,](values:Int[,,]),values:Int[,,])~nReturn callback(values)~nEnd Function"
Local deepNestedCallableModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/deepnestedcallables.mod/deepnestedcallables.bmx", deepNestedCallableSource, resolver, TestOptions())
Local deepNestedCallableDiagnostics:TCompilerDiagnostic[]
Local deepNestedCallableInterface:String = TBlitzMaxCompiler.EmitInterface(deepNestedCallableModule, deepNestedCallableDiagnostics)
Check(deepNestedCallableModule.Succeeded() And deepNestedCallableDiagnostics.length = 0 And Contains(deepNestedCallableInterface, ".callbackArrays$&[,](values%&[,,])&[]&") And Contains(deepNestedCallableInterface, "-Make$&[,](values%&[,,])(enabled%)=") And Contains(deepNestedCallableInterface, "Apply$&[,](callback$&[,](values%&[,,]),values%&[,,])=") And Contains(deepNestedCallableInterface, "CallbackArrays$&[,](values%&[,,])&[]&=mem:p("), "compact interfaces match production for ranked-array callable results, parameters, fields, methods, and callable arrays")
Local parsedDeepNestedCallableInterface:TInterfaceFile = TInterfaceFileParser.Parse(deepNestedCallableInterface, "sdk/acme.deepnestedcallables.i")
Check(parsedDeepNestedCallableInterface.diagnostics.length = 0 And parsedDeepNestedCallableInterface.declarations.length = 3, "deeply nested ranked callable compact records round-trip through the shared interface parser")
resolver.AddInterface("acme.deepnestedcallables", "sdk/acme.deepnestedcallables.i", deepNestedCallableInterface)
Local deepNestedCallableConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("deep-nested-callable-consumer.bmx", "SuperStrict~nImport acme.deepnestedcallables~nLocal callbacks:String[,](values:Int[,,])[]=CallbackArrays~nLocal callback:String[,](values:Int[,,])=callbacks[0]~nLocal values:Int[,,]=New Int[1,1,1]~nLocal result:String[,]=Apply(callback,values)", resolver, TestOptions())
Check(deepNestedCallableConsumer.Succeeded(), "a source-free consumer reconstructs and calls a published deeply nested ranked callable contract: " + CompilerDiagnosticSummary(deepNestedCallableConsumer))

Local nativeBridgeModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nativebridge.mod/nativebridge.bmx", "SuperStrict~nModule acme.nativebridge~nFunction CreateValue:Int(value:Int)~nReturn value~nEnd Function~nFunction _close(stream:Object)~nEnd Function", resolver, TestOptions())
Local nativeBridgeDiagnostics:TCompilerDiagnostic[]
Local nativeBridgeC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeBridgeModule, nativeBridgeDiagnostics)
Local nativeBridgeHeaderDiagnostics:TCompilerDiagnostic[]
Local nativeBridgeHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(nativeBridgeModule, nativeBridgeHeaderDiagnostics)
Check(nativeBridgeModule.Succeeded() And nativeBridgeDiagnostics.length = 0 And nativeBridgeHeaderDiagnostics.length = 0 And Contains(nativeBridgeC, "BBINT acme_nativebridge_CreateValue(BBINT") And Contains(nativeBridgeC, "return acme_nativebridge_CreateValue__Bint(") And Contains(nativeBridgeC, "void acme_nativebridge__close(BBOBJECT") And Contains(nativeBridgeHeader, "BBINT acme_nativebridge_CreateValue(BBINT"), "unique module routines retain legacy unsuffixed native-link aliases while their canonical signature ABI remains authoritative")
Local nativeBridgeUnitOptions:TCompilerOptions = TestOptions()
nativeBridgeUnitOptions.sourceModuleName = "acme.nativebridge"
nativeBridgeUnitOptions.sourceUnitPath = "helpers.bmx"
Local nativeBridgeUnit:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nativebridge.mod/helpers.bmx", "SuperStrict~nPublic Function CreateValue:UInt(value:UInt)~nReturn value~nEnd Function", resolver, nativeBridgeUnitOptions)
Local nativeBridgeUnitDiagnostics:TCompilerDiagnostic[]
Local nativeBridgeUnitC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeBridgeUnit, nativeBridgeUnitDiagnostics)
Local nativeBridgeUnitHeaderDiagnostics:TCompilerDiagnostic[]
Local nativeBridgeUnitHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(nativeBridgeUnit, nativeBridgeUnitHeaderDiagnostics)
Check(nativeBridgeUnit.Succeeded() And nativeBridgeUnitDiagnostics.length = 0 And nativeBridgeUnitHeaderDiagnostics.length = 0 And Contains(nativeBridgeUnitC, "BBUINT acme_nativebridge_helpers_CreateValue(BBUINT") And Contains(nativeBridgeUnitHeader, "BBUINT acme_nativebridge_helpers_CreateValue(BBUINT") And Not Contains(nativeBridgeUnitHeader, "BBUINT acme_nativebridge_CreateValue(BBUINT"), "secondary module sources scope production-compatible routine aliases to their physical source unit")

Local structStaticArrayFieldSource:String = "SuperStrict~nStruct SFieldCell~nField number:Int=5~nField text:String~nMethod Add(delta:Int)~nnumber=number+delta~nEnd Method~nEnd Struct~nStruct SFieldGrid~nField StaticArray cells:SFieldCell[2]~nField StaticArray counts:Int[3]~nEnd Struct~nType TGridHolder~nField grid:SFieldGrid~nEnd Type~nFunction Mutate(value:SFieldCell Var,delta:Int)~nvalue.number=value.number+delta~nEnd Function~nLocal grid:SFieldGrid~nLocal holder:TGridHolder=New TGridHolder~ngrid.cells[0].number=20~ngrid.cells[0].Add(2)~nMutate(grid.cells[1],3)~ngrid.counts[2]=grid.cells[0].number~nLocal first:SFieldCell=grid.cells[0]~nLocal total:Int=first.number+grid.cells.length+grid.counts.length~nFor Local item:SFieldCell=EachIn grid.cells~ntotal=total+item.number~nNext"
Local structStaticArrayField:TCompilerResult = TBlitzMaxCompiler.Compile("struct-static-array-field.bmx", structStaticArrayFieldSource, resolver, TestOptions())
Local structStaticArrayFieldDump:String = TCompilerIrDumper.Dump(structStaticArrayField.ir)
Check(structStaticArrayField.Succeeded() And structStaticArrayField.ir.structs[0].containsManagedReferences And structStaticArrayField.ir.structs[1].containsManagedReferences And structStaticArrayField.ir.classes[0].hasManagedFields And Contains(structStaticArrayFieldDump, "cells:StaticArray SFieldCell[2]") And Contains(structStaticArrayFieldDump, "[static-array SFieldCell x 2] [element-layout struct @st0]") And Contains(structStaticArrayFieldDump, "counts:StaticArray Int[3]") And Contains(structStaticArrayFieldDump, "for-each-static-array SFieldCell x 2"), "Struct fields retain fixed extents and element layouts while managed-reference classification propagates through embedded storage")
Local structStaticArrayFieldDiagnostics:TCompilerDiagnostic[]
Local structStaticArrayFieldC:String = TBlitzMaxCompiler.EmitRuntimeC(structStaticArrayField, structStaticArrayFieldDiagnostics)
Check(structStaticArrayFieldDiagnostics.length = 0 And Contains(structStaticArrayFieldC, "struct bmx_struct_st0_SFieldCell _bmx_class_st1_sfieldgrid_cells[2];") And Contains(structStaticArrayFieldC, "BBINT _bmx_class_st1_sfieldgrid_counts[3];") And Contains(structStaticArrayFieldC, "for (BBUINT bmx_static_field_init_sf0") And Contains(structStaticArrayFieldC, "= bmx_struct_new_bmx_class_st0_SFieldCell_default();") And Contains(structStaticArrayFieldC, "_sfieldcell_text = &bbEmptyString;") And Contains(structStaticArrayFieldC, "bbObjectNew((BBClass *)&bmx_class_cls0_TGridHolder)"), "embedded Struct arrays use real C members, recursively default-construct managed cells, and keep containing Types on scanned allocation")
Check(Contains(structStaticArrayFieldC, "bmx_fn1_Add((&(bmx_v0_grid._bmx_class_st1_sfieldgrid_cells)[0]), 2)") And Contains(structStaticArrayFieldC, "bmx_fn0_Mutate((&(bmx_v0_grid._bmx_class_st1_sfieldgrid_cells)[1]), 3)") And Contains(structStaticArrayFieldC, "struct bmx_struct_st0_SFieldCell *bmx_tmp_"), "embedded fixed-array cells remain addressable for methods and Var and field collections lower through the evaluate-once EachIn path")
Local parameterizedStructStaticArrayField:TCompilerResult = TBlitzMaxCompiler.Compile("parameterized-struct-static-array-field.bmx", "SuperStrict~nStruct SFieldParameterized~nField value:Int=9~nField text:String~nMethod New(seed:Int)~nvalue=seed~nEnd Method~nEnd Struct~nStruct SFieldContainer~nField StaticArray values:SFieldParameterized[2]~nEnd Struct~nLocal container:SFieldContainer~nLocal result:Int=container.values[0].value", resolver, TestOptions())
Local parameterizedStructStaticArrayFieldDiagnostics:TCompilerDiagnostic[]
Local parameterizedStructStaticArrayFieldC:String = TBlitzMaxCompiler.EmitRuntimeC(parameterizedStructStaticArrayField, parameterizedStructStaticArrayFieldDiagnostics)
Check(parameterizedStructStaticArrayField.Succeeded() And parameterizedStructStaticArrayFieldDiagnostics.length = 0 And Contains(parameterizedStructStaticArrayFieldC, "bmx_static_field_init_sf0") And Contains(parameterizedStructStaticArrayFieldC, "bmx_struct_new_bmx_class_st0_SFieldParameterized_default()") And Contains(parameterizedStructStaticArrayFieldC, "_sfieldparameterized_value = 9;") And Contains(parameterizedStructStaticArrayFieldC, "_sfieldparameterized_text = &bbEmptyString;"), "embedded source Struct arrays retain field defaults when their element type only declares parameterized constructors")

Local typeStaticArrayFieldSource:String = "SuperStrict~nStruct SObjectCell~nField number:Int=5~nField text:String~nMethod Add(delta:Int)~nnumber=number+delta~nEnd Method~nEnd Struct~nType TFixedBase~nField StaticArray cells:SObjectCell[2]~nField StaticArray counts:Int[3]~nMethod First:Int()~nReturn cells[0].number~nEnd Method~nEnd Type~nType TFixedDerived Extends TFixedBase~nField marker:Int=7~nEnd Type~nFunction Mutate(value:SObjectCell Var,delta:Int)~nvalue.number=value.number+delta~nEnd Function~nLocal base:TFixedBase=New TFixedBase~nbase.cells[0].number=20~nbase.cells[0].Add(2)~nMutate(base.cells[1],3)~nbase.counts[2]=base.First()~nLocal derived:TFixedDerived=New TFixedDerived~nderived.cells[0]=base.cells[0]~nderived.counts[1]=derived.cells.length+derived.counts.length+derived.marker~nLocal total:Int=derived.counts[1]~nFor Local item:SObjectCell=EachIn base.cells~ntotal=total+item.number~nNext"
Local typeStaticArrayField:TCompilerResult = TBlitzMaxCompiler.Compile("type-static-array-field.bmx", typeStaticArrayFieldSource, resolver, TestOptions())
Local typeStaticArrayFieldDump:String = TCompilerIrDumper.Dump(typeStaticArrayField.ir)
Check(typeStaticArrayField.Succeeded() And typeStaticArrayField.ir.classes[0].hasManagedFields And typeStaticArrayField.ir.classes[1].hasManagedFields And Contains(typeStaticArrayFieldDump, "cells:StaticArray SObjectCell[2] [static-array SObjectCell x 2] [element-layout struct @st0]") And Contains(typeStaticArrayFieldDump, "counts:StaticArray Int[3] [static-array Int x 3]") And Contains(typeStaticArrayFieldDump, "cells:StaticArray SObjectCell[2] [inherited @cls0]") And Contains(typeStaticArrayFieldDump, "for-each-static-array SObjectCell x 2"), "Type StaticArray fields retain extent and element layout through inheritance while managed containment propagates to derived allocation")
Local typeStaticArrayFieldDiagnostics:TCompilerDiagnostic[]
Local typeStaticArrayFieldC:String = TBlitzMaxCompiler.EmitRuntimeC(typeStaticArrayField, typeStaticArrayFieldDiagnostics)
Check(typeStaticArrayFieldDiagnostics.length = 0 And Contains(typeStaticArrayFieldC, "struct bmx_struct_st0_SObjectCell bmx_field_f0_cells[2];") And Contains(typeStaticArrayFieldC, "BBINT bmx_field_f1_counts[3];") And Contains(typeStaticArrayFieldC, "for (BBUINT bmx_static_field_init_f0") And Contains(typeStaticArrayFieldC, "= bmx_struct_new_bmx_class_st0_SObjectCell_default();") And Contains(typeStaticArrayFieldC, "for (BBUINT bmx_static_field_init_f1") And Contains(typeStaticArrayFieldC, "= 0;") And Contains(typeStaticArrayFieldC, "bbObjectNew((BBClass *)&bmx_class_cls0_TFixedBase)") And Contains(typeStaticArrayFieldC, "bbObjectNew((BBClass *)&bmx_class_cls1_TFixedDerived)"), "object constructors initialize every fixed member cell and managed elements select scanned allocation for base and derived Types")
Check(Contains(typeStaticArrayFieldC, "bmx_ctor_cls0_TFixedBase((struct bmx_cls0_TFixedBase_obj *)o);") And Contains(typeStaticArrayFieldC, "bmx_fn2_Add((&(bmx_v0_base->bmx_field_f0_cells)[0]), 2)") And Contains(typeStaticArrayFieldC, "bmx_fn0_Mutate((&(bmx_v0_base->bmx_field_f0_cells)[1]), 3)") And Contains(typeStaticArrayFieldC, "struct bmx_struct_st0_SObjectCell *bmx_tmp_"), "derived construction delegates fixed-field initialization once while indexed cells preserve method, Var, and EachIn lvalue semantics")
Local referenceTypeStaticArrayField:TCompilerResult = TBlitzMaxCompiler.Compile("reference-type-static-array-field.bmx", "SuperStrict~nType TReferenceCell~nField value:Int~nEnd Type~nType TReferenceHolder~nField StaticArray cells:TReferenceCell[8]~nEnd Type~nLocal holder:TReferenceHolder=New TReferenceHolder~nholder.cells[0]=New TReferenceCell~nLocal cell:TReferenceCell=holder.cells[0]", resolver, TestOptions())
Local referenceTypeStaticArrayFieldDiagnostics:TCompilerDiagnostic[]
Local referenceTypeStaticArrayFieldC:String = TBlitzMaxCompiler.EmitRuntimeC(referenceTypeStaticArrayField, referenceTypeStaticArrayFieldDiagnostics)
Check(referenceTypeStaticArrayField.Succeeded() And referenceTypeStaticArrayField.ir.classes[1].hasManagedFields And referenceTypeStaticArrayFieldDiagnostics.length = 0 And Contains(referenceTypeStaticArrayFieldC, "struct bmx_cls0_TReferenceCell_obj * bmx_field_f0_cells[8];") And Contains(referenceTypeStaticArrayFieldC, "= ((struct bmx_cls0_TReferenceCell_obj *)&bbNullObject);") And Contains(referenceTypeStaticArrayFieldC, "bbObjectNew((BBClass *)&bmx_class_cls1_TReferenceHolder)"), "Type-reference StaticArray fields use inline C pointer cells, managed defaults, and scanned object allocation")
Local numericTypeStaticArrayField:TCompilerResult = TBlitzMaxCompiler.Compile("numeric-type-static-array-field.bmx", "SuperStrict~nType TNumericFixed~nField StaticArray values:Int[2]~nEnd Type~nLocal value:TNumericFixed=New TNumericFixed~nvalue.values[0]=3", resolver, TestOptions())
Local numericTypeStaticArrayFieldDiagnostics:TCompilerDiagnostic[]
Local numericTypeStaticArrayFieldC:String = TBlitzMaxCompiler.EmitRuntimeC(numericTypeStaticArrayField, numericTypeStaticArrayFieldDiagnostics)
Check(numericTypeStaticArrayField.Succeeded() And Not numericTypeStaticArrayField.ir.classes[0].hasManagedFields And numericTypeStaticArrayFieldDiagnostics.length = 0 And Contains(numericTypeStaticArrayFieldC, "BBINT bmx_field_f0_values[2];") And Contains(numericTypeStaticArrayFieldC, "bbObjectAtomicNew((BBClass *)&bmx_class_cls0_TNumericFixed)") And Contains(numericTypeStaticArrayFieldC, "bmx_static_field_init_f0"), "numeric-only fixed Type fields retain atomic allocation while receiving deterministic per-cell initialization")
Local parameterizedTypeStaticArrayField:TCompilerResult = TBlitzMaxCompiler.Compile("parameterized-type-static-array-field.bmx", "SuperStrict~nStruct STypeFieldParameterized~nField value:Int=13~nField text:String~nMethod New(seed:Int)~nvalue=seed~nEnd Method~nEnd Struct~nType TTypeFieldContainer~nField StaticArray values:STypeFieldParameterized[2]~nEnd Type~nLocal container:TTypeFieldContainer=New TTypeFieldContainer~nLocal result:Int=container.values[0].value", resolver, TestOptions())
Local parameterizedTypeStaticArrayFieldDiagnostics:TCompilerDiagnostic[]
Local parameterizedTypeStaticArrayFieldC:String = TBlitzMaxCompiler.EmitRuntimeC(parameterizedTypeStaticArrayField, parameterizedTypeStaticArrayFieldDiagnostics)
Check(parameterizedTypeStaticArrayField.Succeeded() And parameterizedTypeStaticArrayField.ir.classes[0].hasManagedFields And parameterizedTypeStaticArrayFieldDiagnostics.length = 0 And Contains(parameterizedTypeStaticArrayFieldC, "bmx_struct_new_bmx_class_st0_STypeFieldParameterized_default()") And Contains(parameterizedTypeStaticArrayFieldC, "_stypefieldparameterized_value = 13;") And Contains(parameterizedTypeStaticArrayFieldC, "_stypefieldparameterized_text = &bbEmptyString;"), "Type fixed fields use source Struct field defaults even when the element only declares parameterized constructors")

Local legacyEachInSource:String = "SuperStrict~nType TLegacyIterator~nField index:Int~nMethod HasNext:Int()~nindex = index + 1~nReturn index <= 4~nEnd Method~nMethod NextObject:Object()~nReturn Self~nEnd Method~nEnd Type~nType TLegacyValues~nMethod ObjectEnumerator:TLegacyIterator()~nReturn New TLegacyIterator~nEnd Method~nEnd Type~nLocal count:Int~nLocal total:Int~n#Outer~nFor Local value:TLegacyIterator = EachIn New TLegacyValues~ncount = count + 1~nIf count = 2 Then Continue Outer~nIf count = 4 Then Exit Outer~nIf value Then total = total + 1~nNext"
Local legacyEachIn:TCompilerResult = TBlitzMaxCompiler.Compile("legacy-eachin.bmx", legacyEachInSource, resolver, TestOptions())
Check(legacyEachIn.Succeeded(), "source ObjectEnumerator protocol lowers through the semantic iteration contract")
Local legacyEachInDump:String = TCompilerIrDumper.Dump(legacyEachIn.ir)
Check(Contains(legacyEachInDump, "for-each-object object-enumerator Object") And Contains(legacyEachInDump, "label outer") And Contains(legacyEachInDump, "[collection %t") And Contains(legacyEachInDump, "TLegacyValues]") And Contains(legacyEachInDump, "[iterator %t") And Contains(legacyEachInDump, "TLegacyIterator]") And Contains(legacyEachInDump, "[element %t") And Contains(legacyEachInDump, "[object-filter]"), "ObjectEnumerator IR retains evaluate-once collection, iterator and filtered element storage with source provenance")
Check(Contains(legacyEachInDump, "ObjectEnumerator : TLegacyIterator") And Contains(legacyEachInDump, "HasNext : Int") And Contains(legacyEachInDump, "NextObject : Object") And Contains(legacyEachInDump, "object-cast @cls0 : TLegacyIterator") And Contains(legacyEachInDump, "continue @loop0") And Contains(legacyEachInDump, "exit @loop0"), "ObjectEnumerator IR carries the resolved protocol methods, checked target cast and loop-control targets")
Local legacyEachInDiagnostics:TCompilerDiagnostic[]
Local legacyEachInC:String = TBlitzMaxCompiler.EmitRuntimeC(legacyEachIn, legacyEachInDiagnostics)
Check(legacyEachInDiagnostics.length = 0, "runtime backend emits source ObjectEnumerator loops")
Check(Contains(legacyEachInC, "bmx_tmp_t0 = ") And Contains(legacyEachInC, "bmx_tmp_t1 = bmx_tmp_t0->clas->") And Contains(legacyEachInC, "while (bmx_tmp_t1->clas->") And Contains(legacyEachInC, "BBOBJECT bmx_tmp_t2 = bmx_tmp_t1->clas->") And Contains(legacyEachInC, "bbObjectDowncast((BBOBJECT)bmx_tmp_t2") And Contains(legacyEachInC, "== (BBOBJECT)&bbNullObject) { continue; }"), "runtime C evaluates the collection once, dispatches virtually and filters incompatible legacy elements")
Check(Contains(legacyEachInC, "goto bmx_loop0_continue;") And Contains(legacyEachInC, "goto bmx_loop0_exit;"), "ObjectEnumerator C uses deterministic resolved control labels")

Local legacyInterfaceEachInSource:String = "SuperStrict~nInterface ILegacyItem~nEnd Interface~nType TLegacyInterfaceIterator Implements ILegacyItem~nMethod HasNext:Int()~nReturn False~nEnd Method~nMethod NextObject:Object()~nReturn Self~nEnd Method~nEnd Type~nType TLegacyInterfaceValues~nMethod ObjectEnumerator:TLegacyInterfaceIterator()~nReturn New TLegacyInterfaceIterator~nEnd Method~nEnd Type~nFor Local value:ILegacyItem = EachIn New TLegacyInterfaceValues~nNext"
Local legacyInterfaceEachIn:TCompilerResult = TBlitzMaxCompiler.Compile("legacy-interface-eachin.bmx", legacyInterfaceEachInSource, resolver, TestOptions())
Check(legacyInterfaceEachIn.Succeeded(), "legacy ObjectEnumerator results support checked Interface loop targets")
Local legacyInterfaceEachInDump:String = TCompilerIrDumper.Dump(legacyInterfaceEachIn.ir)
Check(Contains(legacyInterfaceEachInDump, "for-each-object object-enumerator Object") And Contains(legacyInterfaceEachInDump, "[object-filter]") And Contains(legacyInterfaceEachInDump, "interface-cast @if0 : ILegacyItem"), "legacy Interface target filtering is explicit in iterator IR")
Local legacyInterfaceEachInDiagnostics:TCompilerDiagnostic[]
Local legacyInterfaceEachInC:String = TBlitzMaxCompiler.EmitRuntimeC(legacyInterfaceEachIn, legacyInterfaceEachInDiagnostics)
Check(legacyInterfaceEachInDiagnostics.length = 0 And Contains(legacyInterfaceEachInC, "bbInterfaceDowncast((BBOBJECT)bmx_tmp_t2") And Contains(legacyInterfaceEachInC, "== (BBOBJECT)&bbNullObject) { continue; }"), "legacy Interface iterator C filters values before the user body")

Local legacyStringEachInSource:String = "SuperStrict~nType TLegacyStringIterator~nField available:Int=True~nMethod HasNext:Int()~nLocal result:Int=available~navailable=False~nReturn result~nEnd Method~nMethod NextObject:Object()~nReturn ~qvalue~q~nEnd Method~nEnd Type~nType TLegacyStringValues~nMethod ObjectEnumerator:TLegacyStringIterator()~nReturn New TLegacyStringIterator~nEnd Method~nEnd Type~nLocal result:String~nFor Local value:String = EachIn New TLegacyStringValues~nresult=value~nNext"
Local legacyStringEachIn:TCompilerResult = TBlitzMaxCompiler.Compile("legacy-string-eachin.bmx", legacyStringEachInSource, resolver, TestOptions())
Local legacyStringEachInDump:String = TCompilerIrDumper.Dump(legacyStringEachIn.ir)
Local legacyStringEachInDiagnostics:TCompilerDiagnostic[]
Local legacyStringEachInC:String = TBlitzMaxCompiler.EmitRuntimeC(legacyStringEachIn, legacyStringEachInDiagnostics)
Check(legacyStringEachIn.Succeeded() And Contains(legacyStringEachInDump, "for-each-object object-enumerator Object") And Contains(legacyStringEachInDump, "object-string-cast : String") And Contains(legacyStringEachInDump, "[string-filter]") And Not Contains(legacyStringEachInDump, "[object-filter]"), "legacy ObjectEnumerator Object results retain their production String filter and conversion in typed IR")
Check(legacyStringEachInDiagnostics.length = 0 And Contains(legacyStringEachInC, "bbObjectIsString((BBOBJECT)bmx_tmp_") And Contains(legacyStringEachInC, "bbObjectStringcast((BBOBJECT)bmx_tmp_") And Not Contains(legacyStringEachInC, "== (BBOBJECT)&bbNullObject) { continue; }"), "runtime C filters legacy ObjectEnumerator values by String identity before conversion")

Local importedEachInSource:String = "SuperStrict~nImport sample.contracts~nLocal total:Int~n#Outer~nFor Local value:Int = EachIn CreateImportedValues()~nIf value = 2 Then Continue Outer~nIf value = 4 Then Exit Outer~ntotal = total + value~nNext"
Local importedEachIn:TCompilerResult = TBlitzMaxCompiler.Compile("imported-eachin.bmx", importedEachInSource, resolver, TestOptions())
Check(importedEachIn.Succeeded(), "imported ObjectEnumerator protocol lowers from published Interface ABI records")
Local importedEachInDump:String = TCompilerIrDumper.Dump(importedEachIn.ir)
Check(Contains(importedEachInDump, "for-each-object object-enumerator Int") And Contains(importedEachInDump, "imported-class @icls0 TImportedValues:TImportedValues abi sample_contracts_TImportedValues") And Contains(importedEachInDump, "imported-class @icls1 TImportedIterator:TImportedIterator abi sample_contracts_TImportedIterator"), "imported ObjectEnumerator IR owns only dependency identities and typed iterator storage")
Check(Contains(importedEachInDump, "ObjectEnumerator : TImportedIterator") And Contains(importedEachInDump, "HasNext : Int") And Contains(importedEachInDump, "NextObject : Int") And Contains(importedEachInDump, "call imported-virtual") And Contains(importedEachInDump, "continue @loop0") And Contains(importedEachInDump, "exit @loop0"), "imported ObjectEnumerator IR retains published virtual operations and resolved control targets")
Local importedEachInDiagnostics:TCompilerDiagnostic[]
Local importedEachInC:String = TBlitzMaxCompiler.EmitRuntimeC(importedEachIn, importedEachInDiagnostics)
Check(importedEachInDiagnostics.length = 0, "runtime backend emits imported ObjectEnumerator loops")
Check(Contains(importedEachInC, "struct sample_contracts_TImportedValues_obj * bmx_tmp_t0") And Contains(importedEachInC, "bmx_tmp_t0 = sample_contracts_CreateImportedValues()") And Contains(importedEachInC, "struct sample_contracts_TImportedIterator_obj * bmx_tmp_t1"), "imported ObjectEnumerator C evaluates the collection once and retains dependency-owned struct types")
Check(Contains(importedEachInC, "->clas->m_ObjectEnumerator") And Contains(importedEachInC, "while (bmx_tmp_t1->clas->m_HasNext") And Contains(importedEachInC, "BBINT bmx_tmp_t2 = bmx_tmp_t1->clas->m_NextObject") And Contains(importedEachInC, "goto bmx_loop0_continue;") And Contains(importedEachInC, "goto bmx_loop0_exit;"), "imported ObjectEnumerator C dispatches entirely through published class slots")
Local inheritedImportedEachIn:TCompilerResult = TBlitzMaxCompiler.Compile("inherited-imported-eachin.bmx", "SuperStrict~nImport sample.contracts~nType TInheritedValues Extends TImportedValues~nMethod Sum:Int()~nLocal result:Int~nFor Local value:Int = EachIn Self~nresult :+ value~nNext~nReturn result~nEnd Method~nEnd Type", resolver, TestOptions())
Local inheritedImportedEachInDiagnostics:TCompilerDiagnostic[]
Local inheritedImportedEachInC:String = TBlitzMaxCompiler.EmitRuntimeC(inheritedImportedEachIn, inheritedImportedEachInDiagnostics)
Check(inheritedImportedEachIn.Succeeded() And inheritedImportedEachInDiagnostics.length = 0, "a source Type inherits an imported ObjectEnumerator protocol across its source class layout")
Check(Contains(inheritedImportedEachInC, "->clas->m_ObjectEnumerator") And Contains(inheritedImportedEachInC, "->clas->m_HasNext") And Contains(inheritedImportedEachInC, "->clas->m_NextObject"), "inherited imported ObjectEnumerator operations dispatch through the source receiver's inherited virtual slots")

Local interfaceEachInSource:String = "SuperStrict~nInterface IIterator~nMethod Current:Int()~nMethod MoveNext:Int()~nEnd Interface~nInterface IIterable~nMethod GetIterator:IIterator()~nEnd Interface~nType TProtocolIterator Implements IIterator~nField index:Int~nMethod Current:Int()~nReturn index~nEnd Method~nMethod MoveNext:Int()~nindex = index + 1~nReturn index <= 3~nEnd Method~nEnd Type~nType TProtocolValues Implements IIterable~nField created:Int~nMethod GetIterator:IIterator()~ncreated = created + 1~nReturn New TProtocolIterator~nEnd Method~nEnd Type~nLocal total:Int~n#Outer~nFor Local value:Int = EachIn New TProtocolValues~nIf value = 2 Then Continue Outer~ntotal = total + value~nNext~nLocal direct:TProtocolIterator = New TProtocolIterator~nFor Local value:Int = EachIn direct~nIf value = 2 Then Exit~ntotal = total + value~nNext"
Local interfaceEachIn:TCompilerResult = TBlitzMaxCompiler.Compile("interface-eachin.bmx", interfaceEachInSource, resolver, TestOptions())
Check(interfaceEachIn.Succeeded(), "source IIterable and direct IIterator protocols lower successfully")
Local interfaceEachInDump:String = TCompilerIrDumper.Dump(interfaceEachIn.ir)
Check(Contains(interfaceEachInDump, "for-each-object iterable Int") And Contains(interfaceEachInDump, "GetIterator : IIterator") And Contains(interfaceEachInDump, "call interface @if0.%im") And Contains(interfaceEachInDump, "MoveNext : Int") And Contains(interfaceEachInDump, "Current : Int"), "IIterable IR retains its source factory and Interface-dispatched iterator operations")
Check(Contains(interfaceEachInDump, "for-each-object iterator Int") And Contains(interfaceEachInDump, "iterator-initializer~n        symbol %t") And Contains(interfaceEachInDump, "continue @loop0") And Contains(interfaceEachInDump, "exit @loop1"), "direct IIterator IR aliases the evaluate-once collection and retains resolved control targets")
Check(Occurrences(interfaceEachInDump, "iterator-cleanup %") = 2 And Occurrences(interfaceEachInDump, "interface-cast @") >= 2 And Occurrences(interfaceEachInDump, "Close : Void") >= 2, "IIterable and direct IIterator IR retain dynamic ICloseable cleanup without changing their public iterator types")
Local interfaceEachInDiagnostics:TCompilerDiagnostic[]
Local interfaceEachInC:String = TBlitzMaxCompiler.EmitRuntimeC(interfaceEachIn, interfaceEachInDiagnostics)
Check(interfaceEachInDiagnostics.length = 0, "runtime backend emits source interface iterator loops")
Check(Contains(interfaceEachInC, "bbObjectInterface((BBOBJECT)bmx_tmp_") And Contains(interfaceEachInC, "while (((struct BCC2_InterfaceMethods_if0_") And Contains(interfaceEachInC, "BBOBJECT bmx_tmp_") And Contains(interfaceEachInC, "BBINT bmx_tmp_"), "runtime C dispatches generic-shaped iterator operations through the Interface table with typed temporaries")
Check(Contains(interfaceEachInC, "goto bmx_loop0_continue;") And Contains(interfaceEachInC, "goto bmx_loop1_exit;"), "Interface iterator C shares deterministic loop-control labels")
Check(Occurrences(interfaceEachInC, "bbExTry") >= 2 And Occurrences(interfaceEachInC, "brl_blitz_ICloseable_ifc") >= 2, "runtime Interface iterator loops protect cleanup across normal and non-local control flow")

Local genericEachInPadding:String
For Local index:Int = 0 Until 45
	genericEachInPadding :+ "~nMethod Padding" + index + ":Int()~nReturn " + index + "~nEnd Method"
Next
Local genericEachInSelfSource:String = "SuperStrict~nInterface IIterator<T>~nMethod Current:T()~nMethod MoveNext:Int()~nEnd Interface~nInterface IIterable<T>~nMethod GetIterator:IIterator<T>()~nEnd Interface~nType TGenericIterator<T> Implements IIterator<T>~nMethod Current:T()~nLocal value:T~nReturn value~nEnd Method~nMethod MoveNext:Int()~nReturn False~nEnd Method~nEnd Type~nType TGenericIterable<T> Implements IIterable<T>" + genericEachInPadding + "~nMethod GetIterator:IIterator<T>()~nReturn New TGenericIterator<T>~nEnd Method~nMethod Visit()~nFor Local value:T = EachIn Self~nNext~nEnd Method~nEnd Type"
Local genericEachInSelf:TCompilerResult = TBlitzMaxCompiler.Compile("generic-eachin-self.bmx", genericEachInSelfSource, resolver, TestOptions())
Check(genericEachInSelf.Succeeded() And genericEachInSelf.genericPlan.templateOutputs.length >= 2 And Not HasCompilerDiagnostic(genericEachInSelf, "BMXC3059"), "generic EachIn Self remains specialization-dispatched even when its source Type has more than 40 virtual methods: " + CompilerDiagnosticSummary(genericEachInSelf))

Local objectEachInSource:String = "SuperStrict~nInterface IEachItem~nEnd Interface~nType TEachBase~nEnd Type~nType TEachChild Extends TEachBase~nEnd Type~nType TEachOther~nEnd Type~nType TEachMarked Implements IEachItem~nEnd Type~nLocal empty:Object~nLocal values:Object[] = [New TEachBase, New TEachChild, empty, New TEachOther, New TEachMarked]~nLocal count:Int~nFor Local child:TEachChild = EachIn values~ncount = count + 1~nNext~nFor Local item:Object = EachIn values~ncount = count + 10~nNext~nFor Local marked:IEachItem = EachIn values~ncount = count + 100~nNext~nLocal existing:TEachChild~nFor existing = EachIn values~ncount = count + 1000~nNext"
Local objectEachIn:TCompilerResult = TBlitzMaxCompiler.Compile("object-eachin.bmx", objectEachInSource, resolver, TestOptions())
Check(objectEachIn.Succeeded(), "Object Array EachIn lowers subtype, Object, Interface and existing-variable filters")
Local objectEachInDump:String = TCompilerIrDumper.Dump(objectEachIn.ir)
Check(Contains(objectEachInDump, "for-each-array Object") And Contains(objectEachInDump, "[object-filter]") And Contains(objectEachInDump, "object-cast @cls1 : TEachChild") And Contains(objectEachInDump, "interface-cast @if0 : IEachItem"), "Object EachIn IR explicitly retains runtime casts and null filtering")
Local objectEachInDiagnostics:TCompilerDiagnostic[]
Local objectEachInC:String = TBlitzMaxCompiler.EmitRuntimeC(objectEachIn, objectEachInDiagnostics)
Check(objectEachInDiagnostics.length = 0, "runtime backend emits source Object Array EachIn filtering")
Check(Contains(objectEachInC, "bbObjectDowncast((BBOBJECT)bmx_tmp_") And Contains(objectEachInC, "(BBClass *)&bmx_class_cls1_TEachChild") And Contains(objectEachInC, "bbInterfaceDowncast((BBOBJECT)bmx_tmp_") And Contains(objectEachInC, "if ((BBOBJECT)bmx_") And Contains(objectEachInC, "== (BBOBJECT)&bbNullObject) { continue; }"), "runtime C skips null and incompatible source Object elements before the user body")

Local typedArrayObjectEachInSource:String = "SuperStrict~nType TTypedEachItem~nEnd Type~nLocal values:TTypedEachItem[] = [New TTypedEachItem]~nFor Local value:Object = EachIn values~nNext"
Local typedArrayObjectEachIn:TCompilerResult = TBlitzMaxCompiler.Compile("typed-array-object-eachin.bmx", typedArrayObjectEachInSource, resolver, TestOptions())
Local typedArrayObjectEachInDump:String = TCompilerIrDumper.Dump(typedArrayObjectEachIn.ir)
Check(typedArrayObjectEachIn.Succeeded(), "typed managed Array EachIn compiles through an Object loop variable")
Check(Contains(typedArrayObjectEachInDump, "convert implicit reference") And Contains(typedArrayObjectEachInDump, ": Object"), "typed managed Array EachIn retains its class-to-Object reference conversion in IR: " + typedArrayObjectEachInDump)
Local typedArrayObjectEachInDiagnostics:TCompilerDiagnostic[]
Local typedArrayObjectEachInC:String = TBlitzMaxCompiler.EmitRuntimeC(typedArrayObjectEachIn, typedArrayObjectEachInDiagnostics)
Check(typedArrayObjectEachInDiagnostics.length = 0 And Contains(typedArrayObjectEachInC, "BBOBJECT bmx_v") And Contains(typedArrayObjectEachInC, "_value = ((BBOBJECT)(bmx_tmp_"), "runtime C explicitly upcasts typed managed Array elements assigned to Object loop variables")

Local importedObjectEachIn:TCompilerResult = TBlitzMaxCompiler.Compile("imported-object-eachin.bmx", "SuperStrict~nImport sample.contracts~nLocal empty:Object~nLocal values:Object[] = [CreateImportedValue(), CreateImportedChild(), empty]~nLocal count:Int~nFor Local child:TImportedChild = EachIn values~ncount = count + child.ChildValue()~nNext", resolver, TestOptions())
Check(importedObjectEachIn.Succeeded(), "imported object targets participate in Object Array EachIn filtering")
Local importedObjectEachInDiagnostics:TCompilerDiagnostic[]
Local importedObjectEachInC:String = TBlitzMaxCompiler.EmitRuntimeC(importedObjectEachIn, importedObjectEachInDiagnostics)
Check(importedObjectEachInDiagnostics.length = 0 And Contains(importedObjectEachInC, "bbObjectDowncast((BBOBJECT)bmx_tmp_") And Contains(importedObjectEachInC, "(BBClass *)&sample_contracts_TImportedChild") And Contains(importedObjectEachInC, "== (BBOBJECT)&bbNullObject) { continue; }"), "runtime C filters imported Object elements through the dependency-owned descriptor")

Local runtimeDiagnostics:TCompilerDiagnostic[]
Local runtimeC:String = TBlitzMaxCompiler.EmitRuntimeC(compiled, runtimeDiagnostics)
Check(runtimeDiagnostics.length = 0, "supported scalar IR emits a BlitzMax runtime compilation unit")
Check(Contains(runtimeC, "#include <brl.mod/blitz.mod/blitz.h>"), "runtime unit consumes brl.blitz")
Check(Contains(runtimeC, "void _bb_main_register(void)") And Contains(runtimeC, "int _bb_main(void)"), "runtime unit exports the AppStub application contract")
Check(Not Contains(runtimeC, "int main(void)"), "runtime unit leaves platform main ownership to brl.appstub")
Check(Contains(runtimeC, "__bb_brl_blitz_blitz_register();") And Contains(runtimeC, "__bb_brl_blitz_blitz();"), "runtime unit initializes the implicit brl.blitz dependency")
Check(runtimeC.Find("_bb_main_register();") < runtimeC.Find("bb_init_strings();") And runtimeC.Find("bb_init_strings();") < runtimeC.Find("__bb_brl_blitz_blitz();") And runtimeC.Find("__bb_brl_blitz_blitz();") < runtimeC.Find("bbRunAtstart();"), "runtime C follows the production initialization phase order")

Local globalSourceOrder:TCompilerResult = TBlitzMaxCompiler.Compile("global-source-order.bmx", "SuperStrict~nFunction Mark:Int(value:Int) { nomangle }~nReturn value~nEnd Function~nMark(1)~nGlobal First:Int=Mark(2)~nMark(3)~nGlobal Second:Int=Mark(4)", resolver, TestOptions())
Local globalSourceOrderDiagnostics:TCompilerDiagnostic[]
Local globalSourceOrderC:String = TBlitzMaxCompiler.EmitRuntimeC(globalSourceOrder, globalSourceOrderDiagnostics)
Check(globalSourceOrder.Succeeded() And globalSourceOrderDiagnostics.length = 0 And AppearsBefore(globalSourceOrderC, "bbRunAtstart();", "_bb_main_Mark(1);") And AppearsBefore(globalSourceOrderC, "_bb_main_Mark(1);", "bmx_global_g0_First = _bb_main_Mark(2);") And AppearsBefore(globalSourceOrderC, "bmx_global_g0_First = _bb_main_Mark(2);", "_bb_main_Mark(3);") And AppearsBefore(globalSourceOrderC, "_bb_main_Mark(3);", "bmx_global_g1_Second = _bb_main_Mark(4);"), "runtime C interleaves Global initializers and executable statements in production source order after AtStart")

Local headerDiagnostics:TCompilerDiagnostic[]
Local runtimeHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(compiled, headerDiagnostics)
Check(headerDiagnostics.length = 0, "supported scalar IR emits a runtime unit header")
Check(Contains(runtimeHeader, "#include <brl.mod/blitz.mod/.bmx/blitz.bmx.release.test.x64.h>"), "runtime header includes the resolved module ABI header")
Check(Contains(runtimeHeader, "void _bb_main_register(void);") And Contains(runtimeHeader, "int _bb_main(void);"), "runtime header publishes the AppStub unit boundary")
Check(Contains(runtimeHeader, "BBINT bmx_fn0_Twice(BBINT bmx_p0_value);"), "runtime header uses exact brl.blitz scalar ABI typedefs")

Local importedCall:TCompilerResult = TBlitzMaxCompiler.Compile("imported-call.bmx", "SuperStrict~nLocal ticks:Int = MilliSecs()", resolver, TestOptions())
Check(importedCall.Succeeded(), "scalar imported routine call lowers successfully")
Check(importedCall.ir.externalFunctions.length = 1 And importedCall.ir.externalFunctions[0].abiName = "bbMilliSecs", "imported interface ABI name is retained in typed IR")
Local importedDump:String = TCompilerIrDumper.Dump(importedCall.ir)
Check(Contains(importedDump, "header-owner brl.blitz") And Contains(importedDump, "external @ext0 MilliSecs abi bbMilliSecs() -> Int from brl.blitz"), "IR dump exposes imported routine identity, provenance, and header ownership")
Check(Contains(importedDump, "call external @ext0 MilliSecs : Int"), "typed call explicitly targets the imported routine declaration")
Local importedRuntimeDiagnostics:TCompilerDiagnostic[]
Local importedRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(importedCall, importedRuntimeDiagnostics)
Check(importedRuntimeDiagnostics.length = 0, "runtime backend emits imported scalar calls")
Check(Contains(importedRuntimeC, "#include <brl.mod/blitz.mod/.bmx/blitz.bmx.release.test.x64.h>") And Not Contains(importedRuntimeC, "extern BBINT bbMilliSecs(void);") And Contains(importedRuntimeC, "bbMilliSecs()"), "runtime backend defers the imported ABI declaration to its dependency header")
Local importedStandaloneDiagnostics:TCompilerDiagnostic[]
Local importedStandaloneC:String = TBlitzMaxCompiler.EmitC(importedCall, importedStandaloneDiagnostics)
Check(importedStandaloneDiagnostics.length = 0 And Contains(importedStandaloneC, "extern int32_t bbMilliSecs(void);"), "standalone C synthesizes imported ABI declarations when it has no dependency headers")

Local importedGlobal:TCompilerResult = TBlitzMaxCompiler.Compile("imported-global.bmx", "SuperStrict~nGlobal InstanceCount:Int = CountObjectInstances", resolver, TestOptions())
Check(importedGlobal.Succeeded(), "imported interface Global lowers successfully")
Check(importedGlobal.ir.externalGlobals.length = 1 And importedGlobal.ir.externalGlobals[0].abiName = "bbCountInstances" And importedGlobal.ir.externalGlobals[0].originModule = "brl.blitz", "imported Global ABI identity and module provenance are retained in IR")
Local importedGlobalRuntimeDiagnostics:TCompilerDiagnostic[]
Local importedGlobalRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(importedGlobal, importedGlobalRuntimeDiagnostics)
Check(importedGlobalRuntimeDiagnostics.length = 0 And Not Contains(importedGlobalRuntimeC, "extern BBINT bbCountInstances;") And Not Contains(importedGlobalRuntimeC, "static BBINT bbCountInstances;") And Contains(importedGlobalRuntimeC, "bbCountInstances"), "imported Globals use dependency-header declarations and directly address runtime-owned C storage")
Local importedGlobalStandaloneDiagnostics:TCompilerDiagnostic[]
Local importedGlobalStandaloneC:String = TBlitzMaxCompiler.EmitC(importedGlobal, importedGlobalStandaloneDiagnostics)
Check(importedGlobalStandaloneDiagnostics.length = 0 And Contains(importedGlobalStandaloneC, "extern int32_t bbCountInstances;"), "standalone C retains synthesized imported Global declarations")

Local routineGlobalIdentity:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/routineglobal.mod/routineglobal.bmx", "SuperStrict~nModule acme.routineglobal~nType TDriver~nEnd Type~nGlobal Driver:TDriver~nFunction Current:TDriver()~nGlobal Done:Int~nIf Not Done Then Driver=New TDriver; Done=True~nReturn Driver~nEnd Function", resolver, TestOptions())
Local routineGlobalIdentityDiagnostics:TCompilerDiagnostic[]
Local routineGlobalIdentityC:String = TBlitzMaxCompiler.EmitRuntimeC(routineGlobalIdentity, routineGlobalIdentityDiagnostics)
Check(routineGlobalIdentity.Succeeded() And Contains(TCompilerIrDumper.Dump(routineGlobalIdentity.ir), "var global %g0 Driver:TDriver") And Contains(TCompilerIrDumper.Dump(routineGlobalIdentity.ir), "var global %g1 Done:Int"), "module and function-scope Globals receive distinct module-wide IR identities")
Check(routineGlobalIdentityDiagnostics.length = 0 And Contains(routineGlobalIdentityC, "static BBINT bmx_global_g1_Done;") And Contains(routineGlobalIdentityC, "static int bmx_global_g1_Done_inited = 0;") And Contains(routineGlobalIdentityC, "return acme_routineglobal_Driver;") And Not Contains(routineGlobalIdentityC, "return bmx_global_g1_Done;"), "function-scope Global storage is persistent and lazily initialized while references to module Globals retain their own ABI identity")

Local transitiveHeaderCall:TCompilerResult = TBlitzMaxCompiler.Compile("transitive-header-call.bmx", "SuperStrict~nImport header.root~nLocal value:Int=LeafValue()", resolver, TestOptions())
Local transitiveHeaderDump:String = TCompilerIrDumper.Dump(transitiveHeaderCall.ir)
Local transitiveHeaderDiagnostics:TCompilerDiagnostic[]
Local transitiveHeaderC:String = TBlitzMaxCompiler.EmitRuntimeC(transitiveHeaderCall, transitiveHeaderDiagnostics)
Check(transitiveHeaderCall.Succeeded() And Contains(transitiveHeaderDump, "header-owner header.root") And Contains(transitiveHeaderDump, "header-owner header.leaf"), "typed IR records the complete transitive dependency-header ownership closure")
Check(transitiveHeaderDiagnostics.length = 0 And Contains(transitiveHeaderC, "#include <header.mod/root.mod/.bmx/root.bmx.release.test.x64.h>") And Not Contains(transitiveHeaderC, "#include <header.mod/leaf.mod/") And Not Contains(transitiveHeaderC, "extern BBINT header_leaf_LeafValue(void);") And Contains(transitiveHeaderC, "header_leaf_LeafValue()"), "a direct header owns declarations reachable through its transitive header includes")

Local companionHeaderCall:TCompilerResult = TBlitzMaxCompiler.Compile("companion-header-call.bmx", "SuperStrict~nImport header.companion~nLocal value:Int=NativeValue()~nLocal callback:Int(value:Int)=NativeCallback", resolver, TestOptions())
Local companionHeaderDump:String = TCompilerIrDumper.Dump(companionHeaderCall.ir)
Local companionHeaderDiagnostics:TCompilerDiagnostic[]
Local companionHeaderC:String = TBlitzMaxCompiler.EmitRuntimeC(companionHeaderCall, companionHeaderDiagnostics)
Check(companionHeaderCall.Succeeded() And Contains(companionHeaderDump, "header-owner header.companion") And Contains(companionHeaderDump, "header-owner header.native") And Not Contains(companionHeaderDump, "header-owner native-source.bmx"), "header ownership traverses quoted companion sources without treating them as nominal modules")
Check(companionHeaderDiagnostics.length = 0 And Not Contains(companionHeaderC, "extern BBINT header_native_NativeValue(void);") And Not Contains(companionHeaderC, "extern BBINT (*header_native_NativeCallback)(BBINT);") And Contains(companionHeaderC, "header_native_NativeValue()") And Contains(companionHeaderC, "header_native_NativeCallback"), "native declarations reached through a companion-source header remain owned by the transitive native module header")

Local directCompanionNative:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/header.mod/direct.mod/direct.bmx", "SuperStrict~nModule header.direct~nImport ~qnative-direct.bmx~q~nFunction Callback:Int(value:Int)~nReturn value~nEnd Function~nGlobal Result:Int=NativeDirect(Callback)", resolver, TestOptions())
Local directCompanionNativeDump:String = TCompilerIrDumper.Dump(directCompanionNative.ir)
Local directCompanionNativeDiagnostics:TCompilerDiagnostic[]
Local directCompanionNativeC:String = TBlitzMaxCompiler.EmitRuntimeC(directCompanionNative, directCompanionNativeDiagnostics)
Check(directCompanionNative.Succeeded() And Contains(directCompanionNativeDump, "dependency native-direct.bmx") And Contains(directCompanionNativeDump, "external @ext") And Contains(directCompanionNativeDump, "NativeDirect abi native_direct"), "typed IR retains native declarations owned directly by a quoted companion source")
Check(directCompanionNativeDiagnostics.length = 0 And Contains(directCompanionNativeC, "native_direct(") And Not Contains(directCompanionNativeC, "extern BBINT native_direct("), "a directly included companion header remains the sole authority for its native prototype")

Local fixedObjectMethods:TCompilerResult = TBlitzMaxCompiler.Compile("fixed-object-methods.bmx", "SuperStrict~nLocal left:Object~nLocal right:Object~nLocal text:String=left.ToString()~nLocal ordering:Int=left.Compare(right)~nLocal message:Object=left.SendMessage(right,left)~nLocal hash:UInt=left.HashCode()~nLocal equal:Int=left.Equals(right)", resolver, TestOptions())
Local fixedObjectMethodsDump:String = TCompilerIrDumper.Dump(fixedObjectMethods.ir)
Local fixedObjectMethodsDiagnostics:TCompilerDiagnostic[]
Local fixedObjectMethodsC:String = TBlitzMaxCompiler.EmitRuntimeC(fixedObjectMethods, fixedObjectMethodsDiagnostics)
Check(fixedObjectMethods.Succeeded() And Not HasCompilerDiagnostic(fixedObjectMethods, "BMXC1172"), "core Object fixed methods lower without requiring owner-derived ordinary class-slot names")
Check(Contains(fixedObjectMethodsDump, "imported-class @icls0 Object:Object abi bbObjectClass") And Contains(fixedObjectMethodsDump, "method %icm0 ToString() -> String slot ToString abi bbObjectToString implementation bbObjectToString") And Contains(fixedObjectMethodsDump, "slot Compare abi bbObjectCompare implementation bbObjectCompare"), "core Object fixed methods retain their runtime class-slot and implementation identities in typed IR")
Check(fixedObjectMethodsDiagnostics.length = 0 And Contains(fixedObjectMethodsC, "->clas->ToString((BBOBJECT)") And Contains(fixedObjectMethodsC, "->clas->Compare((BBOBJECT)") And Contains(fixedObjectMethodsC, "->clas->SendMessage((BBOBJECT)") And Contains(fixedObjectMethodsC, "->clas->HashCode((BBOBJECT)") And Contains(fixedObjectMethodsC, "->clas->Equals((BBOBJECT)") And Not Contains(fixedObjectMethodsC, "_bbObject"), "runtime C dispatches every fixed Object method through BBClass without inventing underscored implementation symbols")

Local inheritedObjectMethod:TCompilerResult = TBlitzMaxCompiler.Compile("inherited-object-method.bmx", "SuperStrict~nType TPlainObject~nEnd Type~nLocal value:TPlainObject = New TPlainObject~nLocal text:String = value.ToString()", resolver, TestOptions())
Local inheritedObjectMethodDiagnostics:TCompilerDiagnostic[]
Local inheritedObjectMethodC:String = TBlitzMaxCompiler.EmitRuntimeC(inheritedObjectMethod, inheritedObjectMethodDiagnostics)
Check(inheritedObjectMethod.Succeeded() And inheritedObjectMethodDiagnostics.length = 0 And Contains(inheritedObjectMethodC, "->clas->ToString((BBOBJECT)") And Not HasCompilerDiagnostic(inheritedObjectMethod, "BMXC1173"), "source Types dispatch inherited fixed Object methods without requiring an appended local method-table slot")

Local importedDefault:TCompilerResult = TBlitzMaxCompiler.Compile("imported-default.bmx", "SuperStrict~nImport default.contracts~nType TDefaultImplementation Implements IDefaultContract~nEnd Type~nLocal concrete:TDefaultImplementation=New TDefaultImplementation~nLocal view:IDefaultContract=concrete~nLocal description:String=view.Describe()", resolver, TestOptions())
Local importedDefaultDiagnostics:TCompilerDiagnostic[]
Local importedDefaultC:String = TBlitzMaxCompiler.EmitRuntimeC(importedDefault, importedDefaultDiagnostics)
Check(importedDefault.Succeeded() And importedDefaultDiagnostics.length = 0, "an imported Interface Default satisfies a source Type without a local override")
Check(Contains(importedDefaultC, "default_contracts_IDefaultContract_Describe") And Contains(importedDefaultC, "->m_Describe(") And Not Contains(importedDefaultC, "BBSTRING default_contracts_IDefaultContract_Describe("), "the source Type table references the dependency-owned Default ABI exactly once while calls remain Interface-dispatched")

Local importedObjectSource:String = "SuperStrict~nImport sample.contracts~nGlobal Shared:TImportedValue = ImportedValue~nFunction Pass:TImportedValue(value:TImportedValue)~nReturn value~nEnd Function~nType TFactory Implements IImportedFactory~nField value:TImportedValue~nMethod Get:TImportedValue()~nReturn value~nEnd Method~nMethod Set(value:TImportedValue,flag:Int=11)~nSelf.value = value~nEnd Method~nEnd Type~nLocal created:TImportedValue = CreateImportedValue()~nLocal emptyState:Int = created.IsEmpty()~nLocal copied:TImportedValue = created.Copy()~nLocal accepted:Int = created.Accept(copied)~nLocal description:String = created.ToString()~nLocal complex:Int = CreateImportedValue().IsEmpty()~ncreated.count = 40~ncreated.name = ~qnamed~q~ncreated.peer = copied~nLocal count:Int = created.count~nLocal name:String = created.name~nLocal peer:TImportedValue = created.peer~nCreateImportedValue().count = 5~nLocal complexField:Int = CreateImportedValue().count~nLocal child:TImportedChild = CreateImportedChild()~nchild.text = ~qchild~q~nchild.count = 41~nLocal childText:String = child.text~nLocal inheritedCount:Int = child.count~nLocal inherited:Int = child.IsEmpty()~nLocal childValue:Int = child.ChildValue()~nLocal passed:TImportedValue = Pass(created)~nLocal empty:TImportedValue~nLocal alive:Int = passed <> empty~nUseImportedValue(passed)~nLocal firstPair:Int = DefaultPair()~nLocal secondPair:Int = DefaultPair(,4)~nLocal textDefault:Int = DefaultText()~nLocal objectDefault:Int = DefaultObject()~nLocal arrayDefault:Int = DefaultArray()~nLocal down:TImportedValue = TImportedValue(Object(passed))~nLocal factory:IImportedFactory = New TFactory~nfactory.Set(passed)~nLocal fetched:TImportedValue = factory.Get()"
Local importedObject:TCompilerResult = TBlitzMaxCompiler.Compile("imported-object.bmx", importedObjectSource, resolver, TestOptions())
Check(importedObject.Succeeded(), "imported Type references lower without taking ownership of the dependency layout")
Check(importedObject.ir.importedClasses.length = 2 And importedObject.ir.importedClasses[0].abiName = "sample_contracts_TImportedValue" And importedObject.ir.importedClasses[0].originModule = "sample.contracts" And importedObject.ir.importedClasses[1].abiName = "sample_contracts_TImportedChild", "imported Type ABI identity and module provenance are canonicalized once per class")
Local importedObjectDump:String = TCompilerIrDumper.Dump(importedObject.ir)
Check(Contains(importedObjectDump, "imported-class @icls0 TImportedValue:TImportedValue abi sample_contracts_TImportedValue [managed-fields] from sample.contracts") And Contains(importedObjectDump, "field %icf0 count:Int abi _sample_contracts_timportedvalue_count") And Contains(importedObjectDump, "method %icm0 IsEmpty() -> Int slot m_IsEmpty") And Contains(importedObjectDump, "method %icm1 Copy() -> TImportedValue slot m_Copy") And Contains(importedObjectDump, "call imported-virtual @icls0.%icm0") And Contains(importedObjectDump, "object-cast @icls0 : TImportedValue"), "typed IR distinguishes imported class, field, virtual method and checked-cast ABI identities")
Local importedObjectDiagnostics:TCompilerDiagnostic[]
Local importedObjectC:String = TBlitzMaxCompiler.EmitRuntimeC(importedObject, importedObjectDiagnostics)
Check(importedObjectDiagnostics.length = 0, "runtime backend emits imported object reference ABI values")
Check(Not Contains(importedObjectC, "extern struct sample_contracts_TImportedValue_obj * sample_contracts_CreateImportedValue(void);") And Not Contains(importedObjectC, "extern BBINT sample_contracts_UseImportedValue(") And Not Contains(importedObjectC, "extern struct sample_contracts_TImportedValue_obj * sample_contracts_ImportedValue;") And Contains(importedObjectC, "sample_contracts_CreateImportedValue()") And Contains(importedObjectC, "sample_contracts_UseImportedValue(") And Contains(importedObjectC, "sample_contracts_ImportedValue"), "imported routines and Globals use dependency-header object declarations directly")
Check(Contains(importedObjectC, "struct sample_contracts_IImportedFactory_methods") And Contains(importedObjectC, "sample_contracts_IImportedFactory_ifc") And Contains(importedObjectC, "->m_Set(") And Not Contains(importedObjectC, "struct sample_contracts_IImportedFactory_methods {"), "imported Interface dispatch uses the dependency-published method-table type and slot names without republishing its layout")
Check(Contains(importedObjectC, "->clas->m_IsEmpty((struct sample_contracts_TImportedValue_obj *)") And Contains(importedObjectC, "->clas->m_Copy((struct sample_contracts_TImportedValue_obj *)") And Contains(importedObjectC, "->clas->m_Accept_TTImportedValuei((struct sample_contracts_TImportedValue_obj *)"), "imported instance methods dispatch through dependency-published class slots with typed receivers")
Check(Contains(importedObjectDump, "call imported-virtual @icls0.ToString") And Contains(importedObjectC, "->clas->ToString((BBOBJECT)"), "imported receivers use fixed BBClass slots for reserved Object methods")
Check(Contains(importedObjectDump, "imported-class @icls1 TImportedChild:TImportedChild abi sample_contracts_TImportedChild extends @icls0") And Contains(importedObjectDump, "call imported-virtual @icls1.%icm0") And Contains(importedObjectDump, "method %icm3 ChildValue() -> Int slot m_ChildValue") And Contains(importedObjectC, "struct sample_contracts_TImportedChild_obj *"), "imported inheritance dispatch retains the base relationship, derived table identity and declaring receiver ABI")
Check(Contains(importedObjectC, "struct sample_contracts_TImportedValue_obj * bmx_tmp_t0;") And Contains(importedObjectC, "bmx_tmp_t0 = sample_contracts_CreateImportedValue()"), "imported virtual dispatch evaluates complex receivers once")
Check(Contains(importedObjectC, "->_sample_contracts_timportedvalue_count") And Contains(importedObjectC, "->_sample_contracts_timportedvalue_name") And Contains(importedObjectC, "->_sample_contracts_timportedvalue_peer") And Contains(importedObjectC, "->_sample_contracts_timportedchild_text"), "imported scalar and managed fields use dependency-published struct member names")
Check(Contains(importedObjectC, "bmx_tmp_t1 = sample_contracts_CreateImportedValue()") And Contains(importedObjectC, "bmx_tmp_t2 = sample_contracts_CreateImportedValue()"), "imported field writes and reads evaluate complex receivers once")
Check(Contains(importedObjectC, "((struct sample_contracts_TImportedValue_obj *)&bbNullObject)") And Contains(importedObjectC, "bbObjectDowncast((BBOBJECT)") And Contains(importedObjectC, "(BBClass *)&sample_contracts_TImportedValue"), "imported object defaults and explicit casts preserve BlitzMax runtime semantics")
Check(Not Contains(importedObjectC, "struct sample_contracts_TImportedValue_obj {") And Not Contains(importedObjectC, "BBClass sample_contracts_TImportedValue ="), "the consuming unit neither defines the imported object layout nor its class descriptor")
Check(Contains(importedObjectC, "sample_contracts_UseImportedValue(") And Contains(importedObjectC, ", 9)") And Contains(importedObjectC, "->clas->m_Accept_TTImportedValuei(") And Contains(importedObjectC, ", 7)"), "imported free and virtual calls materialize trailing numeric defaults")
Check(Contains(importedObjectC, "sample_contracts_DefaultPair(2, 3)") And Contains(importedObjectC, "sample_contracts_DefaultPair(2, 4)"), "trailing and explicitly omitted arguments materialize the selected defaults")
Check(Contains(importedObjectC, "sample_contracts_DefaultText((BBString*)&bmx_string_str") And Contains(importedObjectC, "sample_contracts_DefaultObject(((BBOBJECT)&bbNullObject))") And Contains(importedObjectC, "sample_contracts_DefaultArray(&bbEmptyArray)"), "String, Object and Array defaults lower to ordinary managed IR values")
Check(Contains(importedObjectC, "->m_Set((struct sample_contracts_IImportedFactory_obj *)") And Contains(importedObjectC, ", 11)"), "Interface dispatch uses the dependency-owned typed receiver and materializes omitted defaults before backend emission")
Local importedSuperCall:TCompilerResult = TBlitzMaxCompiler.Compile("imported-super-call.bmx", "SuperStrict~nImport sample.contracts~nType TDerivedValue Extends TImportedValue~nMethod BaseEmpty:Int()~nReturn Super.IsEmpty()~nEnd Method~nEnd Type~nLocal value:TDerivedValue=New TDerivedValue~nLocal empty:Int=value.BaseEmpty()", resolver, TestOptions())
Local importedSuperCallDump:String = TCompilerIrDumper.Dump(importedSuperCall.ir)
Local importedSuperCallDiagnostics:TCompilerDiagnostic[]
Local importedSuperCallC:String = TBlitzMaxCompiler.EmitRuntimeC(importedSuperCall, importedSuperCallDiagnostics)
Check(importedSuperCall.Succeeded() And Contains(importedSuperCallDump, "call super @icls0.%icm0"), "Super calls from a source-derived Type retain the exact imported base implementation identity")
Check(importedSuperCallDiagnostics.length = 0 And Contains(importedSuperCallC, "_sample_contracts_TImportedValue_IsEmpty((struct sample_contracts_TImportedValue_obj *)bmx_self_self)") And Not Contains(importedSuperCallC, "bmx_self_self->clas->m_IsEmpty"), "imported Super calls invoke the selected base implementation directly instead of redispatching through Self")
resolver.AddInterface("comparebase.bmx", "/work/.bmx/comparebase.bmx.release.test.x64.i", "superstrict~nTCompareBase^Object{~n-Compare%(other:Object)=~qapplication_super_TCompareBase_Compare__Bobject~q~n}=~qapplication_super_TCompareBase~q")
resolver.AddInterface("intermediate.bmx", "/work/.bmx/intermediate.bmx.release.test.x64.i", "superstrict~nimport ~qcomparebase.bmx~q~nTIntermediate^TCompareBase{~n}=~qapplication_super_TIntermediate~q")
Local transitiveImportedSuper:TCompilerResult = TBlitzMaxCompiler.Compile("transitive-imported-super.bmx", "SuperStrict~nImport ~qintermediate.bmx~q~nType TLeaf Extends TIntermediate~nMethod BaseCompare:Int(other:Object)~nReturn Super.Compare(other)~nEnd Method~nEnd Type", resolver, TestOptions())
Local transitiveImportedSuperDump:String = TCompilerIrDumper.Dump(transitiveImportedSuper.ir)
Local transitiveImportedSuperDiagnostics:TCompilerDiagnostic[]
Local transitiveImportedSuperC:String = TBlitzMaxCompiler.EmitRuntimeC(transitiveImportedSuper, transitiveImportedSuperDiagnostics)
Local transitiveImportedSuperHeaderDiagnostics:TCompilerDiagnostic[]
Local transitiveImportedSuperHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(transitiveImportedSuper, transitiveImportedSuperHeaderDiagnostics)
Check(transitiveImportedSuper.Succeeded() And transitiveImportedSuperDiagnostics.length = 0 And transitiveImportedSuperHeaderDiagnostics.length = 0, "a Super call through an intermediate imported Type retains the declaring implementation")
Check(Contains(transitiveImportedSuperDump, "Compare abi application_super_TCompareBase_Compare__Bobject(self:TCompareBase, other:Object) -> Int [implementation _application_super_TCompareBase_Compare__Bobject] [direct-method]") And Contains(transitiveImportedSuperDump, "convert implicit reference : TCompareBase") And Contains(transitiveImportedSuperC, "_application_super_TCompareBase_Compare__Bobject") And Not Contains(transitiveImportedSuperC, "return application_super_TCompareBase_Compare__Bobject") And Contains(transitiveImportedSuperC, "struct application_super_TCompareBase_obj") And Not Contains(transitiveImportedSuperHeader, "_application_super_TCompareBase_Compare__Bobject(struct application_super_TIntermediate_obj"), "direct imported Object-slot method IR and calls use the declaring implementation ABI and owner receiver rather than the compact slot name or a derived expression type")
Local coreObjectSuper:TCompilerResult = TBlitzMaxCompiler.Compile("core-object-super.bmx", "SuperStrict~nType TNamedValue~nMethod ToString:String()~nReturn Super.ToString()~nEnd Method~nEnd Type", resolver, TestOptions())
Local coreObjectSuperDiagnostics:TCompilerDiagnostic[]
Local coreObjectSuperC:String = TBlitzMaxCompiler.EmitRuntimeC(coreObjectSuper, coreObjectSuperDiagnostics)
Check(coreObjectSuper.Succeeded() And coreObjectSuperDiagnostics.length = 0 And Contains(coreObjectSuperC, "bbObjectToString(((BBOBJECT)bmx_self_self))"), "direct Super calls into the runtime Object ABI explicitly upcast source Type receivers for strict C compilers")
Local callableDefaults:TCompilerResult = TBlitzMaxCompiler.Compile("callable-defaults.bmx", "SuperStrict~nImport callable.contracts~nFunction LocalCompare:Int(left:Object,right:Object) { nomangle }~nReturn 0~nEnd Function~nLocal list:TCallableList = CreateList()~nLocal methodResult:Int = list.Sort()~nLocal functionResult:Int = SortList(list)~nLocal explicitMethodResult:Int = list.Sort(,LocalCompare)~nLocal explicitSourceResult:Int = SortList(list,,LocalCompare)~nLocal explicitImportedResult:Int = SortList(list,,CompareObjects)", resolver, TestOptions())
Check(callableDefaults.Succeeded(), "imported free and virtual calls lower omitted and explicit callable arguments")
Local callableDefaultsDump:String = TCompilerIrDumper.Dump(callableDefaults.ir)
Check(Contains(callableDefaultsDump, "callable external @ext") And Contains(callableDefaultsDump, "CompareObjects abi callable_contracts_CompareObjects : Int(Object, Object)"), "callable-reference IR retains the canonical external target and complete semantic signature")
Check(Contains(callableDefaultsDump, "callable source @fn0 LocalCompare abi _bb_main_LocalCompare : Int(Object, Object)"), "explicit source callable IR retains its NoMangle ABI identity")
Local callableDefaultsDiagnostics:TCompilerDiagnostic[]
Local callableDefaultsC:String = TBlitzMaxCompiler.EmitRuntimeC(callableDefaults, callableDefaultsDiagnostics)
Check(callableDefaultsDiagnostics.length = 0, "runtime backend emits imported callable default arguments")
Check(Not Contains(callableDefaultsC, "extern BBINT callable_contracts_SortList") And Contains(callableDefaultsC, "callable_contracts_SortList(") And Contains(callableDefaultsC, ", 1, callable_contracts_CompareObjects)"), "imported free calls use dependency-header ordinary-C function-pointer declarations")
Check(Contains(callableDefaultsC, "->clas->m_Sort_iF_TObjectTObject_i_(") And Contains(callableDefaultsC, ", 1, callable_contracts_CompareObjects)"), "imported virtual calls pass the same callable ABI target through the published class slot")
Check(Contains(callableDefaultsC, ", 1, _bb_main_LocalCompare)") And Contains(callableDefaultsC, ", 1, callable_contracts_CompareObjects)"), "explicit source and imported callable arguments use their canonical ABI symbols")
Local sourceCallableDefaults:TCompilerResult = TBlitzMaxCompiler.Compile("source-callable-defaults.bmx", "SuperStrict~nImport callable.contracts~nFunction SourceDefaultCompare:Int(left:Object,right:Object) { nomangle }~nReturn 0~nEnd Function~nFunction ApplyCompare:Int(left:Object,right:Object,compareFunc:Int(left:Object,right:Object)=SourceDefaultCompare)~nReturn compareFunc(left,right)~nEnd Function~nFunction UseCallableLocal:Int(left:Object,right:Object)~nLocal compare:Int(a:Object,b:Object)=SourceDefaultCompare~nLocal first:Int=compare(left,right)~ncompare=CompareObjects~nReturn first + ApplyCompare(left,right,compare)~nEnd Function~nLocal list:TCallableList = CreateList()~nLocal defaultResult:Int = ApplyCompare(list,list)~nLocal sourceResult:Int = ApplyCompare(list,list,SourceDefaultCompare)~nLocal importedResult:Int = ApplyCompare(list,list,CompareObjects)~nLocal localResult:Int = UseCallableLocal(list,list)", resolver, TestOptions())
Check(sourceCallableDefaults.Succeeded(), "source free routines accept, invoke, and default typed callable parameters and initialized callable locals")
Local sourceCallableDefaultsDump:String = TCompilerIrDumper.Dump(sourceCallableDefaults.ir)
Check(Contains(sourceCallableDefaultsDump, "compareFunc:Int(Object, Object)=callable(_bb_main_SourceDefaultCompare)") And Contains(sourceCallableDefaultsDump, "call-indirect (Int)") And Contains(sourceCallableDefaultsDump, "symbol %p2 compareFunc : Int(Object, Object)") And Contains(sourceCallableDefaultsDump, "var local %v2 compare:Int(Object, Object) [callable Int(Object, Object)]") And Contains(sourceCallableDefaultsDump, "symbol %v2 compare : Int(Object, Object)") And Contains(sourceCallableDefaultsDump, "callable source @fn0 SourceDefaultCompare abi _bb_main_SourceDefaultCompare : Int(Object, Object)") And Contains(sourceCallableDefaultsDump, "callable external @ext") And Contains(sourceCallableDefaultsDump, "CompareObjects abi callable_contracts_CompareObjects : Int(Object, Object)"), "callable parameters, normalized defaults, local storage, indirect invocation, and target identities remain explicit in typed IR")
Local sourceCallableDefaultsDiagnostics:TCompilerDiagnostic[]
Local sourceCallableDefaultsC:String = TBlitzMaxCompiler.EmitRuntimeC(sourceCallableDefaults, sourceCallableDefaultsDiagnostics)
Check(sourceCallableDefaultsDiagnostics.length = 0, "runtime backend emits source free-routine callable parameters and defaults")
Check(Contains(sourceCallableDefaultsC, "BBINT (*bmx_p2_compareFunc)(BBOBJECT, BBOBJECT)") And Contains(sourceCallableDefaultsC, "(bmx_p2_compareFunc)(bmx_p0_left, bmx_p1_right)") And Contains(sourceCallableDefaultsC, "BBINT (*bmx_v2_compare)(BBOBJECT, BBOBJECT) = _bb_main_SourceDefaultCompare;") And Contains(sourceCallableDefaultsC, "bmx_v2_compare = callable_contracts_CompareObjects;") And Contains(sourceCallableDefaultsC, "_bb_main_SourceDefaultCompare)") And Contains(sourceCallableDefaultsC, "callable_contracts_CompareObjects)"), "source callable parameters and locals use exact ordinary-C function-pointer declarations, assignments, and calls")
Local callableNullDefaultModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/callable.mod/nulldefault.mod/nulldefault.bmx", "SuperStrict~nModule callable.nulldefault~nType TCallableNullDefault~nFunction Create:Int(value:Int, callback:Int(data:Int)=Null)~nReturn callback(value)~nEnd Function~nEnd Type", resolver, TestOptions())
Local callableNullDefaultInterfaceDiagnostics:TCompilerDiagnostic[]
Local callableNullDefaultInterface:String = TBlitzMaxCompiler.EmitInterface(callableNullDefaultModule, callableNullDefaultInterfaceDiagnostics)
Check(callableNullDefaultModule.Succeeded() And callableNullDefaultInterfaceDiagnostics.length = 0 And Contains(callableNullDefaultInterface, "callback%(data%)=Null"), "compact interfaces publish a callable Null default semantically rather than copying the production sentinel-name convention")
resolver.AddInterface("callable.nulldefault", "sdk/callable.nulldefault.i", callableNullDefaultInterface)
Local callableNullDefaultConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("callable-null-default-consumer.bmx", "SuperStrict~nImport callable.nulldefault~nLocal result:Int=TCallableNullDefault.Create(42)", resolver, TestOptions())
Local callableNullDefaultConsumerDiagnostics:TCompilerDiagnostic[]
Local callableNullDefaultConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(callableNullDefaultConsumer, callableNullDefaultConsumerDiagnostics)
Check(callableNullDefaultConsumer.Succeeded() And callableNullDefaultConsumerDiagnostics.length = 0 And Contains(callableNullDefaultConsumerC, "brl_blitz_NullFunctionError"), "an imported omitted callable Null default materializes the typed runtime throwing sentinel")
Local callableStaticArraySource:String = "SuperStrict~nConst WIDTH:Int=4~nFunction SumFixed:Int(StaticArray values:Int[WIDTH])~nReturn values[0]+values.length~nEnd Function~nLocal callback:Int(StaticArray values:Int[WIDTH])=SumFixed~nLocal StaticArray values:Int[WIDTH]~nvalues[0]=38~nLocal result:Int=callback(values)"
Local callableStaticArray:TCompilerResult = TBlitzMaxCompiler.Compile("callable-static-array.bmx", callableStaticArraySource, resolver, TestOptions())
Check(callableStaticArray.Succeeded(), "callable storage accepts a fixed-array parameter with a compile-time extent")
Local callableStaticArrayDump:String = TCompilerIrDumper.Dump(callableStaticArray.ir)
Check(Contains(callableStaticArrayDump, "callback:Int(StaticArray Int[4]) [callable Int(StaticArray Int[4])]") And Contains(callableStaticArrayDump, "call-indirect (Int)") And Contains(callableStaticArrayDump, "SumFixed(%p0 values:StaticArray Int[4])"), "callable IR retains the nested StaticArray element type and extent through storage, target, and invocation")
Local callableStaticArrayDiagnostics:TCompilerDiagnostic[]
Local callableStaticArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(callableStaticArray, callableStaticArrayDiagnostics)
Check(callableStaticArrayDiagnostics.length = 0 And Contains(callableStaticArrayC, "callback)(BBINT *) = bmx_fn0_SumFixed;") And Contains(callableStaticArrayC, "_callback)(bmx_v"), "runtime C lowers a fixed-array callable parameter to its exact pointer-compatible function signature")
Local mismatchedCallableStaticArray:TCompilerResult = TBlitzMaxCompiler.Compile("mismatched-callable-static-array.bmx", "SuperStrict~nFunction SumFixed:Int(StaticArray values:Int[4])~nReturn 0~nEnd Function~nLocal callback:Int(StaticArray values:Int[4])=SumFixed~nLocal StaticArray values:Int[3]~nLocal result:Int=callback(values)", resolver, TestOptions())
Check(Not mismatchedCallableStaticArray.Succeeded() And HasCompilerDiagnostic(mismatchedCallableStaticArray, "BMXC1022"), "indirect calls reject fixed-array arguments with a different extent")
Local callableVarSource:String = "SuperStrict~nStruct SCallableVarCell~nField value:Int~nEnd Struct~nFunction Increment:Int(value:Int Var)~nvalue=value+1~nReturn value~nEnd Function~nFunction IncrementCell:Int(cell:SCallableVarCell Var)~ncell.value=cell.value+1~nReturn cell.value~nEnd Function~nLocal scalarCallback:Int(value:Int Var)=Increment~nLocal structCallback:Int(cell:SCallableVarCell Var)=IncrementCell~nLocal value:Int=40~nLocal cell:SCallableVarCell~ncell.value=40~nLocal result:Int=scalarCallback(value)+structCallback(cell)"
Local callableVar:TCompilerResult = TBlitzMaxCompiler.Compile("callable-var.bmx", callableVarSource, resolver, TestOptions())
Check(callableVar.Succeeded(), "scalar and Struct Var parameters lower through callable storage and indirect invocation")
Local callableVarDump:String = TCompilerIrDumper.Dump(callableVar.ir)
Check(Contains(callableVarDump, "scalarCallback:Int(Int Var) [callable Int(Int Var)]") And Contains(callableVarDump, "structCallback:Int(SCallableVarCell Var) [callable Int(SCallableVarCell Var)]") And Contains(callableVarDump, "symbol by-reference %p0 value") And Contains(callableVarDump, "address-of : Int") And Contains(callableVarDump, "address-of : SCallableVarCell"), "typed IR retains Var modes, callee dereferences, and caller address operations for callable signatures")
Local callableVarDiagnostics:TCompilerDiagnostic[]
Local callableVarC:String = TBlitzMaxCompiler.EmitRuntimeC(callableVar, callableVarDiagnostics)
Check(callableVarDiagnostics.length = 0 And Contains(callableVarC, "BBINT bmx_fn0_Increment(BBINT * bmx_p0_value)") And Contains(callableVarC, "BBINT (*bmx_v0_scalarCallback)(BBINT *)") And Contains(callableVarC, "(*bmx_p0_value) =") And Contains(callableVarC, "_scalarCallback)((&bmx_v") And Contains(callableVarC, "_structCallback)((&bmx_v"), "runtime C emits exact scalar and Struct pointer signatures at both sides of callable Var invocation")
Local nativeBytePointerCallback:TCompilerResult = TBlitzMaxCompiler.Compile("native-byte-pointer-callback.bmx", "SuperStrict~nFunction ReadCallback:Int(buffer:Byte Ptr,count:Int,context:Object)~nReturn count~nEnd Function~nExtern~nFunction InstallCallback:Int(callback:Byte Ptr)=~qbcc2_install_callback~q~nEnd Extern~nGlobal Installed:Int=InstallCallback(ReadCallback)", resolver, TestOptions())
Local nativeBytePointerCallbackDump:String = TCompilerIrDumper.Dump(nativeBytePointerCallback.ir)
Local nativeBytePointerCallbackDiagnostics:TCompilerDiagnostic[]
Local nativeBytePointerCallbackC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeBytePointerCallback, nativeBytePointerCallbackDiagnostics)
Check(nativeBytePointerCallback.Succeeded() And Contains(nativeBytePointerCallbackDump, "convert implicit callable-reference-to-byte-pointer : Byte Ptr") And Contains(nativeBytePointerCallbackDump, "callable source @fn0 ReadCallback"), "typed IR retains a direct routine callback crossing a legacy native Byte Ptr boundary")
Check(nativeBytePointerCallbackDiagnostics.length = 0 And Contains(nativeBytePointerCallbackC, "bcc2_install_callback(") And Contains(nativeBytePointerCallbackC, "bmx_fn0_ReadCallback"), "runtime C passes the source routine entry point to the native Byte Ptr callback parameter")
Local callableReturnSource:String = "SuperStrict~nFunction IncrementReturned:Int(value:Int Var)~nvalue=value+1~nReturn value~nEnd Function~nFunction ChooseReturned:Int(value:Int Var)(enabled:Int)~nIf enabled Then Return IncrementReturned~nReturn Null~nEnd Function~nLocal callback:Int(value:Int Var)=ChooseReturned(True)~nLocal value:Int=40~nLocal first:Int=callback(value)~nLocal second:Int=ChooseReturned(True)(value)"
Local callableReturn:TCompilerResult = TBlitzMaxCompiler.Compile("callable-return.bmx", callableReturnSource, resolver, TestOptions())
Local callableReturnDump:String = TCompilerIrDumper.Dump(callableReturn.ir)
Check(callableReturn.Succeeded() And Contains(callableReturnDump, "ChooseReturned(%p0 enabled:Int) -> Int(Int Var)") And Contains(callableReturnDump, "callable-default Int(Int Var)") And Contains(callableReturnDump, "materialize %t0:Int(Int Var)") And Contains(callableReturnDump, "callee~n              symbol %t0 callable") And Contains(callableReturnDump, "address-of : Int"), "typed IR retains callable return signatures, Null defaults, and sequenced immediate indirect invocation")
Local callableReturnDiagnostics:TCompilerDiagnostic[]
Local callableReturnC:String = TBlitzMaxCompiler.EmitRuntimeC(callableReturn, callableReturnDiagnostics)
Check(callableReturnDiagnostics.length = 0 And Contains(callableReturnC, "BBINT (*bmx_fn1_ChooseReturned(BBINT bmx_p0_enabled))(BBINT *)") And Contains(callableReturnC, "BBINT (*bmx_v0_callback)(BBINT *) = bmx_fn1_ChooseReturned(1)") And Contains(callableReturnC, "bmx_tmp_t0 = bmx_fn1_ChooseReturned(1)") And Contains(callableReturnC, "(bmx_tmp_t0)((&bmx_v"), "runtime C emits nested function-pointer return declarations and sequences returned Var callable invocation")
Local callableMethodReturnSource:String = "SuperStrict~nFunction IncrementFromMethod:Int(value:Int Var)~nvalue=value+1~nReturn value~nEnd Function~nType TCallableReturnBase~nMethod Choose:Int(value:Int Var)(enabled:Int)~nIf enabled Then Return IncrementFromMethod~nReturn Null~nEnd Method~nEnd Type~nType TCallableReturnDerived Extends TCallableReturnBase~nMethod Choose:Int(value:Int Var)(enabled:Int) Override~nReturn Super.Choose(enabled)~nEnd Method~nEnd Type~nInterface ICallableReturn~nMethod Choose:Int(value:Int Var)(enabled:Int)~nEnd Interface~nType TCallableReturnImplementation Implements ICallableReturn~nMethod Choose:Int(value:Int Var)(enabled:Int)~nIf enabled Then Return IncrementFromMethod~nReturn Null~nEnd Method~nEnd Type~nLocal base:TCallableReturnBase=New TCallableReturnDerived~nLocal iface:ICallableReturn=New TCallableReturnImplementation~nLocal callback:Int(value:Int Var)=base.Choose(True)~nLocal value:Int=40~ncallback(value)~niface.Choose(True)(value)"
Local callableMethodReturn:TCompilerResult = TBlitzMaxCompiler.Compile("callable-method-return.bmx", callableMethodReturnSource, resolver, TestOptions())
Local callableMethodReturnDump:String = TCompilerIrDumper.Dump(callableMethodReturn.ir)
Local callableMethodReturnDiagnostics:TCompilerDiagnostic[]
Local callableMethodReturnC:String = TBlitzMaxCompiler.EmitRuntimeC(callableMethodReturn, callableMethodReturnDiagnostics)
Check(callableMethodReturn.Succeeded() And Contains(callableMethodReturnDump, "Choose(%p0 enabled:Int) -> Int(Int Var)") And Contains(callableMethodReturnDump, "call virtual") And Contains(callableMethodReturnDump, "call interface"), "typed IR retains callable results through overrides, Super calls, virtual dispatch, and Interface dispatch")
Check(callableMethodReturnDiagnostics.length = 0 And Contains(callableMethodReturnC, "BBINT (*(*m_cf0_Choose)(struct bmx_cls0_TCallableReturnBase_obj *, BBINT))(BBINT *);") And Contains(callableMethodReturnC, "BBINT (*(*m_im0_Choose)(BBOBJECT, BBINT))(BBINT *);") And Contains(callableMethodReturnC, "->clas->m_cf0_Choose(") And Contains(callableMethodReturnC, "->m_im0_Choose("), "runtime C emits receiver-aware nested function-pointer slots for callable virtual and Interface results")
Check(Contains(callableMethodReturnC, "BBDEBUGDECL_TYPEMETHOD, ~qChoose~q, ~q(i)(&i)i~q") And Contains(callableMethodReturnC, "*((BBINT (**)(BBINT *))(buf)) = bmx_fn") And Contains(callableMethodReturnC, "_Choose_ReflectionWrapper"), "ordinary Type methods publish typed callable-return reflection wrappers")
Local callableTypeFunctionReturn:TCompilerResult = TBlitzMaxCompiler.Compile("callable-type-function-return.bmx", "SuperStrict~nFunction IncrementFromTypeFunction:Int(value:Int Var)~nvalue=value+1~nReturn value~nEnd Function~nType TCallableReturnFunctions~nFunction Choose:Int(value:Int Var)(enabled:Int)~nIf enabled Then Return IncrementFromTypeFunction~nReturn Null~nEnd Function~nEnd Type~nLocal callback:Int(value:Int Var)=TCallableReturnFunctions.Choose(True)~nLocal value:Int=40~ncallback(value)~nTCallableReturnFunctions.Choose(True)(value)", resolver, TestOptions())
Local callableTypeFunctionReturnDump:String = TCompilerIrDumper.Dump(callableTypeFunctionReturn.ir)
Local callableTypeFunctionReturnDiagnostics:TCompilerDiagnostic[]
Local callableTypeFunctionReturnC:String = TBlitzMaxCompiler.EmitRuntimeC(callableTypeFunctionReturn, callableTypeFunctionReturnDiagnostics)
Check(callableTypeFunctionReturn.Succeeded() And Contains(callableTypeFunctionReturnDump, "Choose(%p0 enabled:Int) -> Int(Int Var)") And Contains(callableTypeFunctionReturnDump, "function-slot %cf0 @fn1 Choose(Int) -> Int(Int Var)"), "typed IR retains callable results on source Type functions and their descriptor slots")
Check(callableTypeFunctionReturnDiagnostics.length = 0 And Contains(callableTypeFunctionReturnC, "BBINT (*(*f_cf0_Choose)(BBINT))(BBINT *);") And Contains(callableTypeFunctionReturnC, "BBINT (*bmx_fn1_Choose(BBINT bmx_p0_enabled))(BBINT *)") And Contains(callableTypeFunctionReturnC, "((bmx_tmp_t0 = bmx_fn1_Choose(1)), ((bmx_tmp_t0)((&bmx_v"), "runtime C emits receiver-free nested Type-function slots and sequenced callable-result invocation")
Local callableStructRoutineReturn:TCompilerResult = TBlitzMaxCompiler.Compile("callable-struct-routine-return.bmx", "SuperStrict~nFunction IncrementFromStruct:Int(value:Int Var)~nvalue=value+1~nReturn value~nEnd Function~nStruct SCallableReturn~nMethod Choose:Int(value:Int Var)(enabled:Int)~nIf enabled Then Return IncrementFromStruct~nReturn Null~nEnd Method~nFunction Pick:Int(value:Int Var)(enabled:Int)~nIf enabled Then Return IncrementFromStruct~nReturn Null~nEnd Function~nEnd Struct~nLocal owner:SCallableReturn~nLocal methodCallback:Int(value:Int Var)=owner.Choose(True)~nLocal functionCallback:Int(value:Int Var)=SCallableReturn.Pick(True)~nLocal value:Int=40~nmethodCallback(value)~nSCallableReturn.Pick(True)(value)", resolver, TestOptions())
Local callableStructRoutineReturnDump:String = TCompilerIrDumper.Dump(callableStructRoutineReturn.ir)
Local callableStructRoutineReturnDiagnostics:TCompilerDiagnostic[]
Local callableStructRoutineReturnC:String = TBlitzMaxCompiler.EmitRuntimeC(callableStructRoutineReturn, callableStructRoutineReturnDiagnostics)
Check(callableStructRoutineReturn.Succeeded() And Contains(callableStructRoutineReturnDump, "Choose(%p0 enabled:Int) -> Int(Int Var) [abi bmx_fn1_Choose] [struct @st0] [method receiver SCallableReturn]") And Contains(callableStructRoutineReturnDump, "Pick(%p0 enabled:Int) -> Int(Int Var) [abi bmx_fn2_Pick] [struct @st0]") And Contains(callableStructRoutineReturnDump, "call struct-direct @fn1 Choose : Int(Int Var)"), "typed IR retains callable results for source Struct methods and functions")
Check(callableStructRoutineReturnDiagnostics.length = 0 And Contains(callableStructRoutineReturnC, "BBINT (*bmx_fn1_Choose(struct bmx_struct_st0_SCallableReturn * bmx_self_self, BBINT bmx_p0_enabled))(BBINT *)") And Contains(callableStructRoutineReturnC, "BBINT (*bmx_fn2_Pick(BBINT bmx_p0_enabled))(BBINT *)") And Contains(callableStructRoutineReturnC, "= bmx_fn2_Pick(1)), ((bmx_tmp_") And Contains(callableStructRoutineReturnC, ")((&bmx_v"), "runtime C emits pointer-receiver and receiver-free sequenced callable-result declarations for Struct routines")
Check(Contains(callableStructRoutineReturnC, "BBDEBUGDECL_TYPEMETHOD, ~qChoose~q, ~q(i)(&i)i~q") And Contains(callableStructRoutineReturnC, "BBDEBUGDECL_TYPEFUNCTION, ~qPick~q, ~q(i)(&i)i~q") And Contains(callableStructRoutineReturnC, "*((BBINT (**)(BBINT *))buf) = bmx_fn") And Contains(callableStructRoutineReturnC, "_Pick_ReflectionWrapper"), "ordinary Struct methods and functions publish typed callable-return reflection wrappers")
Local unsetCallableLocal:TCompilerResult = TBlitzMaxCompiler.Compile("unset-callable-local.bmx", "SuperStrict~nFunction Compare:Int(left:Object,right:Object)~nReturn 0~nEnd Function~nFunction IsUnset:Int()~nLocal compare:Int(left:Object,right:Object)=Compare~ncompare=Null~nIf compare Then Return 0~nIf Not compare Then Return 1~nReturn 0~nEnd Function~nFunction InvokeUnset:Int(left:Object,right:Object)~nLocal compare:Int(a:Object,b:Object)~nReturn compare(left,right)~nEnd Function", resolver, TestOptions())
Check(unsetCallableLocal.Succeeded(), "uninitialized callable locals lower through the production null-function sentinel contract")
Local unsetCallableDump:String = TCompilerIrDumper.Dump(unsetCallableLocal.ir)
Check(Contains(unsetCallableDump, "assign @unset-callable-local.bmx:") And Contains(unsetCallableDump, "callable-default Int(Object, Object)") And Contains(unsetCallableDump, "callable-truth Int(Object, Object)") And Contains(unsetCallableDump, "callable-not Int(Object, Object)") And Contains(unsetCallableDump, "call-indirect (Int)"), "unset initialization, explicit Null reset, truth, Not, and invocation remain distinct typed callable IR operations")
Local unsetCallableDiagnostics:TCompilerDiagnostic[]
Local unsetCallableC:String = TBlitzMaxCompiler.EmitRuntimeC(unsetCallableLocal, unsetCallableDiagnostics)
Check(unsetCallableDiagnostics.length = 0 And Contains(unsetCallableC, "union { BBFuncPtr source; BBINT (*target)(BBOBJECT, BBOBJECT);") And Contains(unsetCallableC, ".source = &brl_blitz_NullFunctionError }.target") And Contains(unsetCallableC, "!= 0) &&") And Contains(unsetCallableC, "== 0) ||") And Contains(unsetCallableC, "(bmx_v2_compare)(bmx_p0_left, bmx_p1_right)"), "runtime C preserves the production sentinel address with a warning-clean typed representation for initialization, truth tests, and eventual throwing invocation")
Local callableLogical:TCompilerResult = TBlitzMaxCompiler.Compile("callable-logical.bmx", "SuperStrict~nFunction ApplyFilter:Int(value:Int, filter:Int(value:Int)=Null)~nIf filter And Not filter(value) Then Return 0~nIf Not filter Or filter(value) Then Return 1~nReturn 0~nEnd Function~nLocal result:Int=ApplyFilter(42)", resolver, TestOptions())
Local callableLogicalDump:String = TCompilerIrDumper.Dump(callableLogical.ir)
Local callableLogicalDiagnostics:TCompilerDiagnostic[]
Local callableLogicalC:String = TBlitzMaxCompiler.EmitRuntimeC(callableLogical, callableLogicalDiagnostics)
Check(callableLogical.Succeeded() And Contains(callableLogicalDump, "callable-truth Int(Int)") And Contains(callableLogicalDump, "callable-not Int(Int)"), "callable operands of short-circuit And and Or normalize through explicit sentinel-aware truth IR")
Check(callableLogicalDiagnostics.length = 0 And Occurrences(callableLogicalC, "brl_blitz_NullFunctionError") >= 3 And Contains(callableLogicalC, "!= 0) &&") And Contains(callableLogicalC, "== 0) ||"), "runtime C short-circuits callable And and Or without invoking the production Null-function sentinel")
Local callableGlobals:TCompilerResult = TBlitzMaxCompiler.Compile("callable-globals.bmx", "SuperStrict~nImport callable.contracts~nFunction LocalCompare:Int(left:Object,right:Object) { nomangle }~nReturn 0~nEnd Function~nGlobal ActiveCompare:Int(left:Object,right:Object)=LocalCompare~nGlobal MissingCompare:Int(left:Object,right:Object)~nFunction UseGlobalCompare:Int(left:Object,right:Object)~nLocal first:Int=ActiveCompare(left,right)~nActiveCompare=CompareObjects~nIf MissingCompare Then Return 100~nReturn first + ActiveCompare(left,right)~nEnd Function~nLocal list:TCallableList=CreateList()~nLocal result:Int=UseGlobalCompare(list,list)", resolver, TestOptions())
Check(callableGlobals.Succeeded(), "unit-owned callable Globals support source initialization, unset defaults, assignment, truth, and invocation")
Local callableGlobalsDump:String = TCompilerIrDumper.Dump(callableGlobals.ir)
Check(Contains(callableGlobalsDump, "var global %g0 ActiveCompare:Int(Object, Object) [callable Int(Object, Object)]") And Contains(callableGlobalsDump, "var global %g1 MissingCompare:Int(Object, Object) [callable Int(Object, Object)]") And Contains(callableGlobalsDump, "callable-default Int(Object, Object)") And Contains(callableGlobalsDump, "symbol %g0 ActiveCompare : Int(Object, Object)"), "callable Global IR retains storage, signature, default, and symbol identity")
Local callableGlobalsDiagnostics:TCompilerDiagnostic[]
Local callableGlobalsC:String = TBlitzMaxCompiler.EmitRuntimeC(callableGlobals, callableGlobalsDiagnostics)
Check(callableGlobalsDiagnostics.length = 0 And Contains(callableGlobalsC, "static BBINT (*bmx_global_g0_ActiveCompare)(BBOBJECT, BBOBJECT);") And Contains(callableGlobalsC, "static BBINT (*bmx_global_g1_MissingCompare)(BBOBJECT, BBOBJECT);") And Contains(callableGlobalsC, "bmx_global_g0_ActiveCompare = _bb_main_LocalCompare;") And Contains(callableGlobalsC, "bmx_global_g0_ActiveCompare = callable_contracts_CompareObjects;") And Contains(callableGlobalsC, "GC_add_roots(&bmx_global_g0_ActiveCompare") And Contains(callableGlobalsC, "GC_add_roots(&bmx_global_g1_MissingCompare"), "runtime C gives callable Globals exact typed storage, initialization order, assignment, and conservative root-range participation")
Local importedCallableGlobals:TCompilerResult = TBlitzMaxCompiler.Compile("imported-callable-globals.bmx", "SuperStrict~nImport callable.globals~nFunction ImportedGlobalCompare:Int(left:Object,right:Object) { nomangle }~nReturn 0~nEnd Function~nLocal left:Object~nLocal right:Object~nLocal first:Int=ActiveCompare(left,right)~nActiveCompare=ImportedGlobalCompare~nLocal second:Int=ActiveCompare(left,right)~nActiveCompare=ExternalGlobalCompare~nIf MissingCompare Then second=100~nLocal unset:Int=Not MissingCompare", resolver, TestOptions())
Check(importedCallableGlobals.Succeeded(), "imported callable Globals support invocation, assignment, truth, and source or imported targets")
Local importedCallableGlobalsDump:String = TCompilerIrDumper.Dump(importedCallableGlobals.ir)
Check(Contains(importedCallableGlobalsDump, "external-global %extg0 ActiveCompare:Int(Object, Object) abi callable_globals_ActiveCompare [callable Int(Object, Object)] from callable.globals") And Contains(importedCallableGlobalsDump, "external-global %extg1 MissingCompare:Int(Object, Object) abi callable_globals_MissingCompare [callable Int(Object, Object)] from callable.globals") And Contains(importedCallableGlobalsDump, "call-indirect (Int)") And Contains(importedCallableGlobalsDump, "callable-not Int(Object, Object)"), "imported callable Global IR retains external storage identity, signature, indirect calls, and truth")
Local importedCallableGlobalsDiagnostics:TCompilerDiagnostic[]
Local importedCallableGlobalsC:String = TBlitzMaxCompiler.EmitRuntimeC(importedCallableGlobals, importedCallableGlobalsDiagnostics)
Check(importedCallableGlobalsDiagnostics.length = 0 And Not Contains(importedCallableGlobalsC, "extern BBINT (*callable_globals_ActiveCompare)(BBOBJECT, BBOBJECT);") And Not Contains(importedCallableGlobalsC, "extern BBINT (*callable_globals_MissingCompare)(BBOBJECT, BBOBJECT);") And Contains(importedCallableGlobalsC, "callable_globals_ActiveCompare = _bb_main_ImportedGlobalCompare;") And Contains(importedCallableGlobalsC, "callable_globals_ActiveCompare = callable_globals_ExternalGlobalCompare;"), "runtime C defers callable Global declarations to the dependency header and directly addresses their storage")
Local callableFields:TCompilerResult = TBlitzMaxCompiler.Compile("callable-fields.bmx", "SuperStrict~nImport callable.contracts~nFunction FieldCompare:Int(left:Object,right:Object) { nomangle }~nReturn 0~nEnd Function~nType TCallableHolder~nField Active:Int(left:Object,right:Object)=FieldCompare~nField Missing:Int(left:Object,right:Object)~nMethod Run:Int(left:Object,right:Object)~nLocal first:Int=Active(left,right)~nActive=CompareObjects~nIf Missing Then Return 100~nReturn first + Active(left,right)~nEnd Method~nEnd Type~nLocal list:TCallableList=CreateList()~nLocal holder:TCallableHolder=New TCallableHolder~nLocal methodResult:Int=holder.Run(list,list)~nholder.Active=FieldCompare~nLocal directResult:Int=holder.Active(list,list)~nholder.Active=Null~nLocal unsetResult:Int=Not holder.Active", resolver, TestOptions())
Check(callableFields.Succeeded(), "source callable fields support typed layout, declared and unset initialization, access, assignment, truth, and invocation")
Local callableFieldsDump:String = TCompilerIrDumper.Dump(callableFields.ir)
Check(Contains(callableFieldsDump, "class @cls0 TCallableHolder:TCallableHolder [atomic-fields]") And Contains(callableFieldsDump, "field %f0 Active:Int(Object, Object) [callable Int(Object, Object)]") And Contains(callableFieldsDump, "field %f1 Missing:Int(Object, Object) [callable Int(Object, Object)]") And Contains(callableFieldsDump, "callable-default Int(Object, Object)") And Contains(callableFieldsDump, "call-indirect (Int)"), "callable field IR retains its ordinary-C shape without changing managed-field classification")
Local callableFieldsDiagnostics:TCompilerDiagnostic[]
Local callableFieldsC:String = TBlitzMaxCompiler.EmitRuntimeC(callableFields, callableFieldsDiagnostics)
Check(callableFieldsDiagnostics.length = 0 And Contains(callableFieldsC, "BBINT (*bmx_field_f0_Active)(BBOBJECT, BBOBJECT);") And Contains(callableFieldsC, "BBINT (*bmx_field_f1_Missing)(BBOBJECT, BBOBJECT);") And Contains(callableFieldsC, "->bmx_field_f0_Active = _bb_main_FieldCompare;") And Contains(callableFieldsC, "->bmx_field_f1_Missing = ((union { BBFuncPtr source;") And Contains(callableFieldsC, "->bmx_field_f0_Active) = callable_contracts_CompareObjects;") And Contains(callableFieldsC, "->bmx_field_f0_Active))(") And Contains(callableFieldsC, "sizeof(((struct bmx_cls0_TCallableHolder_obj *)0)->bmx_field_f1_Missing)"), "runtime C emits exact callable field layout, constructor defaults, access, assignment, invocation, and field-size metadata")
Local reflectionCallableBridge:TCompilerResult = TBlitzMaxCompiler.Compile("reflection-callable-bridge.bmx", "SuperStrict~nType TReflectionPeer~nEnd Type~nType TReflectionCallback~nField callback:Int(value:Int)~nField callbacks:Int(index:Int, sender:TReflectionPeer)[]~nEnd Type~nStruct SReflectionCallback~nField callback:Int(value:Int)~nField callbacks:Int(index:Int, sender:TReflectionPeer)[,]~nEnd Struct~nLocal raw:Byte Ptr~nLocal holder:TReflectionCallback=New TReflectionCallback~nholder.callback=raw", resolver, TestOptions())
Local reflectionCallableBridgeDiagnostics:TCompilerDiagnostic[]
Local reflectionCallableBridgeC:String = TBlitzMaxCompiler.EmitRuntimeC(reflectionCallableBridge, reflectionCallableBridgeDiagnostics)
Check(reflectionCallableBridge.Succeeded() And reflectionCallableBridgeDiagnostics.length = 0 And Contains(reflectionCallableBridgeC, "bmx_field_f0_callback) = ((BBINT (*)(BBINT))(bmx_v0_raw))"), "reflection Byte Ptr metadata lowers to an explicitly typed native callable cast")
Check(Contains(reflectionCallableBridgeC, "BBDEBUGDECL_FIELD, ~qcallback~q, ~q(i)i~q") And Contains(reflectionCallableBridgeC, "BBDEBUGDECL_FIELD, ~qcallbacks~q, ~q[](i,:TReflectionPeer)i~q") And Contains(reflectionCallableBridgeC, "BBDEBUGDECL_FIELD, ~qcallbacks~q, ~q[,](i,:TReflectionPeer)i~q"), "Type and Struct callable fields publish production-compatible direct and ranked-array reflection tags")
Check(Contains(reflectionCallableBridgeC, "bmx_class_field_cls1_f0_ReflectionWrapper(void **buf)") And Contains(reflectionCallableBridgeC, "BBINT (**)(BBINT)") And Contains(reflectionCallableBridgeC, ".reflection_wrapper = bmx_class_field_cls1_f0_ReflectionWrapper"), "callable fields publish a typed reflection invocation adapter")
Check(Contains(reflectionCallableBridgeC, "bmx_struct_field_st0_sf0_ReflectionWrapper(void **buf)") And Contains(reflectionCallableBridgeC, ".reflection_wrapper = bmx_struct_field_st0_sf0_ReflectionWrapper"), "callable Struct fields publish a typed reflection invocation adapter")
Local reflectionCallableInvocationAdapters:TCompilerResult = TBlitzMaxCompiler.Compile("reflection-callable-invocation-adapters.bmx", "SuperStrict~nType TReflectionCallableAdapters~nField callback:Int(value:Int)~nGlobal globalCallback:Int(value:Int)~nMethod InvokeNested:Int(callback:Int(value:Int), value:Int)~nReturn callback(value)~nEnd Method~nEnd Type", resolver, TestOptions())
Local reflectionCallableInvocationAdapterDiagnostics:TCompilerDiagnostic[]
Local reflectionCallableInvocationAdapterC:String = TBlitzMaxCompiler.EmitRuntimeC(reflectionCallableInvocationAdapters, reflectionCallableInvocationAdapterDiagnostics)
Check(reflectionCallableInvocationAdapters.Succeeded() And reflectionCallableInvocationAdapterDiagnostics.length = 0 And Contains(reflectionCallableInvocationAdapterC, "bmx_global_g0_ReflectionWrapper(void **buf)") And Contains(reflectionCallableInvocationAdapterC, ".reflection_wrapper = bmx_global_g0_ReflectionWrapper") And Contains(reflectionCallableInvocationAdapterC, "bmx_fn0_InvokeNested_ReflectionWrapper(void **buf)") And Contains(reflectionCallableInvocationAdapterC, "*((BBINT (**)(BBINT))"), "callable Globals and ordinary routine callable parameters publish typed reflection invocation adapters")
Local reflectedStructRoutines:TCompilerResult = TBlitzMaxCompiler.Compile("reflected-struct-routines.bmx", "SuperStrict~nStruct SReflectedValue~nField value:Int = 7~nMethod New(value:Int)~nSelf.value = value~nEnd Method~nMethod Read:Int()~nReturn value~nEnd Method~nEnd Struct~nLocal defaultValue:SReflectedValue = New SReflectedValue~nLocal selectedValue:SReflectedValue = New SReflectedValue(42)", resolver, TestOptions())
Local reflectedStructRoutineDiagnostics:TCompilerDiagnostic[]
Local reflectedStructRoutineC:String = TBlitzMaxCompiler.EmitRuntimeC(reflectedStructRoutines, reflectedStructRoutineDiagnostics)
Check(reflectedStructRoutines.Succeeded() And reflectedStructRoutineDiagnostics.length = 0 And Contains(reflectedStructRoutineC, "BBDEBUGDECL_TYPEMETHOD, ~qNew~q, ~q(i)~q") And Contains(reflectedStructRoutineC, "BBDEBUGDECL_TYPEMETHOD, ~qNew~q, ~q()~q") And Contains(reflectedStructRoutineC, "BBDEBUGDECL_TYPEMETHOD, ~qRead~q, ~q()i~q"), "ordinary Struct reflection publishes explicit and implicit constructors plus instance methods")
Check(Contains(reflectedStructRoutineC, "_ReflectionWrapper(void **buf)") And Contains(reflectedStructRoutineC, "= bmx_struct_new_") And Contains(reflectedStructRoutineC, "bbObjectRegisterStruct"), "ordinary Struct reflection wrappers construct boxed values through initialized value helpers")
Local callableStructField:TCompilerResult = TBlitzMaxCompiler.Compile("callable-struct-field.bmx", "SuperStrict~nFunction Increment:Int(value:Int)~nReturn value + 1~nEnd Function~nStruct SCallbackRecord~nField context:Byte Ptr~nField callback:Int(value:Int)~nEnd Struct~nGlobal Record:SCallbackRecord~nFunction InvokeRecord:Int(value:Int)~nRecord.callback = Increment~nReturn Record.callback(value)~nEnd Function", resolver, TestOptions())
Local callableStructFieldDump:String = TCompilerIrDumper.Dump(callableStructField.ir)
Local callableStructFieldDiagnostics:TCompilerDiagnostic[]
Local callableStructFieldC:String = TBlitzMaxCompiler.EmitRuntimeC(callableStructField, callableStructFieldDiagnostics)
Check(callableStructField.Succeeded() And Contains(callableStructFieldDump, "callback:Int(Int) [callable Int(Int)]"), "Struct callable fields retain their exact function-pointer signature in typed IR")
Check(callableStructFieldDiagnostics.length = 0 And Contains(callableStructFieldC, "BBINT (*") And Contains(callableStructFieldC, "_callback)(BBINT);") And Contains(callableStructFieldC, "_callback) = bmx_fn0_Increment") And Contains(callableStructFieldC, "_callback))(bmx_p0_value)"), "runtime C emits, assigns, and invokes an exact Struct function-pointer member")
Local complexCallableField:TCompilerResult = TBlitzMaxCompiler.Compile("complex-callable-field.bmx", "SuperStrict~nImport callable.contracts~nFunction Compare:Int(left:Object,right:Object)~nReturn 0~nEnd Function~nType THolder~nField active:Int(left:Object,right:Object)=Compare~nField missing:Int(left:Object,right:Object)~nEnd Type~nFunction MakeHolder:THolder()~nReturn New THolder~nEnd Function~nLocal list:TCallableList=CreateList()~nLocal called:Int=MakeHolder().active(list,list)~nLocal unset:Int=Not MakeHolder().missing", resolver, TestOptions())
Check(complexCallableField.Succeeded() And Contains(TCompilerIrDumper.Dump(complexCallableField.ir), "materialize %t") And Contains(TCompilerIrDumper.Dump(complexCallableField.ir), "callable-not Int(Object, Object)"), "callable field invocation and truth materialize complex receivers in backend-independent IR")
Local complexCallableFieldDiagnostics:TCompilerDiagnostic[]
Local complexCallableFieldC:String = TBlitzMaxCompiler.EmitRuntimeC(complexCallableField, complexCallableFieldDiagnostics)
Check(complexCallableFieldDiagnostics.length = 0 And Occurrences(complexCallableFieldC, "= bmx_fn1_MakeHolder()") = 2 And Contains(complexCallableFieldC, "bmx_tmp_t1 = ((bmx_tmp_t0 = bmx_fn1_MakeHolder())"), "complex callable field receivers are evaluated exactly once and the callable value is captured before invocation")
Local importedCallableFields:TCompilerResult = TBlitzMaxCompiler.Compile("imported-callable-fields.bmx", "SuperStrict~nImport callable.fields~nFunction ImportedFieldCompare:Int(left:Object,right:Object) { nomangle }~nReturn 0~nEnd Function~nLocal holder:TImportedCallableFields=CreateCallableFields()~nholder.active=ImportedFieldCompare~nLocal first:Int=holder.active(holder,holder)~nholder.active=ExternalFieldCompare~nIf holder.missing Then first=100~nLocal unset:Int=Not holder.missing~nLocal complex:Int=CreateCallableFields().active(holder,holder)~nLocal child:TImportedCallableChild=CreateCallableChild()~nchild.active=ImportedFieldCompare~nLocal inherited:Int=child.active(child,child)", resolver, TestOptions())
Check(importedCallableFields.Succeeded(), "imported callable fields support assignment, truth, invocation, inheritance, and complex receivers")
Local importedCallableFieldsDump:String = TCompilerIrDumper.Dump(importedCallableFields.ir)
Check(Contains(importedCallableFieldsDump, "field %icf0 active:Int(Object, Object) abi _callable_fields_timportedcallablefields_active [callable Int(Object, Object)]") And Contains(importedCallableFieldsDump, "field imported %icf0") And Contains(importedCallableFieldsDump, "call-indirect (Int)") And Contains(importedCallableFieldsDump, "materialize %t"), "imported callable field IR retains dependency identity, exact signature, operations, and evaluate-once sequencing")
Local importedCallableFieldsDiagnostics:TCompilerDiagnostic[]
Local importedCallableFieldsC:String = TBlitzMaxCompiler.EmitRuntimeC(importedCallableFields, importedCallableFieldsDiagnostics)
Check(importedCallableFieldsDiagnostics.length = 0 And Contains(importedCallableFieldsC, "->_callable_fields_timportedcallablefields_active) = _bb_main_ImportedFieldCompare;") And Contains(importedCallableFieldsC, "->_callable_fields_timportedcallablefields_active) = callable_fields_ExternalFieldCompare;") And Contains(importedCallableFieldsC, "->_callable_fields_timportedcallablefields_active))(") And Contains(importedCallableFieldsC, "->_callable_fields_timportedcallablefields_missing)") And Contains(importedCallableFieldsC, "bmx_tmp_t0 = callable_fields_CreateCallableFields()"), "runtime C accesses dependency-owned callable members directly while preserving targets, truth, invocation, inheritance, and receiver materialization")
Local callableArraySource:String = "SuperStrict~nModule callable.arrays~nType TCallableArrayValue~nEnd Type~nFunction KeepValue:TCallableArrayValue(value:TCallableArrayValue)~nReturn value~nEnd Function~nType TCallableArrayOwner~nField callbacks:TCallableArrayValue(value:TCallableArrayValue)[]~nMethod Set(callback:TCallableArrayValue(value:TCallableArrayValue))~ncallbacks=callbacks[..1]~ncallbacks[0]=callback~nEnd Method~nMethod Apply:TCallableArrayValue(value:TCallableArrayValue)~nLocal callback:TCallableArrayValue(value:TCallableArrayValue)=callbacks[0]~nReturn callback(value)~nEnd Method~nEnd Type~nLocal owner:TCallableArrayOwner=New TCallableArrayOwner~nowner.Set(KeepValue)~nLocal result:TCallableArrayValue=owner.Apply(New TCallableArrayValue)"
Local callableArray:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/callable.mod/arrays.mod/arrays.bmx", callableArraySource, resolver, TestOptions())
Local callableArrayDump:String = TCompilerIrDumper.Dump(callableArray.ir)
Local callableArrayDiagnostics:TCompilerDiagnostic[]
Local callableArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(callableArray, callableArrayDiagnostics)
Check(callableArray.Succeeded() And callableArrayDiagnostics.length = 0 And Contains(callableArrayDump, "array-slice TCallableArrayValue(TCallableArrayValue) encoding ~q(~q") And Contains(callableArrayDump, "call-indirect (TCallableArrayValue)"), "callable heap arrays retain their runtime encoding, indexed values and indirect-call signature")
Check(Contains(callableArrayC, "bbArraySlice(~q(~q") And Contains(callableArrayC, "(**)(struct callable_arrays_TCallableArrayValue_obj *)") And Contains(callableArrayC, "BBARRAYDATA"), "runtime C stores callable array cells as typed function pointers and invokes indexed values through their exact ABI")
Local callableArrayInterfaceDiagnostics:TCompilerDiagnostic[]
Local callableArrayInterface:String = TBlitzMaxCompiler.EmitInterface(callableArray, callableArrayInterfaceDiagnostics)
Check(callableArrayInterfaceDiagnostics.length = 0 And Contains(callableArrayInterface, ".callbacks:TCallableArrayValue(value:TCallableArrayValue)&[]&"), "compact interfaces publish a callable array's exact element signature without source text")
resolver.AddInterface("callable.arrays", "sdk/callable.arrays.i", callableArrayInterface)
Local callableArrayConsumerSource:String = "SuperStrict~nImport callable.arrays~nFunction KeepImported:TCallableArrayValue(value:TCallableArrayValue)~nReturn value~nEnd Function~nLocal owner:TCallableArrayOwner=New TCallableArrayOwner~nowner.callbacks=owner.callbacks[..1]~nowner.callbacks[0]=KeepImported~nLocal callback:TCallableArrayValue(value:TCallableArrayValue)=owner.callbacks[0]~nLocal result:TCallableArrayValue=callback(New TCallableArrayValue)"
Local callableArrayConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("callable-array-consumer.bmx", callableArrayConsumerSource, resolver, TestOptions())
Local callableArrayConsumerDiagnostics:TCompilerDiagnostic[]
Local callableArrayConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(callableArrayConsumer, callableArrayConsumerDiagnostics)
Check(callableArrayConsumer.Succeeded() And callableArrayConsumerDiagnostics.length = 0 And Contains(callableArrayConsumerC, "bbArraySlice(~q(~q") And Contains(callableArrayConsumerC, "(**)(struct callable_arrays_TCallableArrayValue_obj *)"), "separate consumers reconstruct callable array fields and their exact C ABI from the compact interface")
Local callableSourceMethod:TCompilerResult = TBlitzMaxCompiler.Compile("callable-source-method.bmx", "SuperStrict~nFunction AddValues:Int(left:Int,right:Int) { nomangle }~nReturn left + right~nEnd Function~nType TCallableBase~nMethod Apply:Int(left:Int,right:Int,operation:Int(a:Int,b:Int))~nReturn operation(left,right)~nEnd Method~nEnd Type~nType TCallableInherited Extends TCallableBase~nEnd Type~nType TCallableOverride Extends TCallableBase~nMethod Apply:Int(left:Int,right:Int,operation:Int(a:Int,b:Int)) Override~nReturn operation(left,right) + 1~nEnd Method~nEnd Type~nLocal inherited:TCallableBase = New TCallableInherited~nLocal overridden:TCallableBase = New TCallableOverride~nLocal inheritedResult:Int = inherited.Apply(20,22,AddValues)~nLocal overrideResult:Int = overridden.Apply(20,21,AddValues)", resolver, TestOptions())
Check(callableSourceMethod.Succeeded(), "source methods accept ordinary-C-compatible callable parameters across inheritance and overrides")
Local callableSourceMethodDump:String = TCompilerIrDumper.Dump(callableSourceMethod.ir)
Check(Contains(callableSourceMethodDump, "Apply(Int, Int, Int(Int, Int)) -> Int") And Contains(callableSourceMethodDump, "[inherited-slot @cls0]") And Contains(callableSourceMethodDump, "call-indirect (Int)"), "effective base, inherited, and overriding class slots retain callable parameter shapes in typed IR")
Local callableSourceMethodDiagnostics:TCompilerDiagnostic[]
Local callableSourceMethodC:String = TBlitzMaxCompiler.EmitRuntimeC(callableSourceMethod, callableSourceMethodDiagnostics)
Check(callableSourceMethodDiagnostics.length = 0 And Contains(callableSourceMethodC, "BBINT (*)(BBINT, BBINT)") And Contains(callableSourceMethodC, "BBINT (*bmx_p2_operation)(BBINT, BBINT)") And Contains(callableSourceMethodC, "->clas->m_cf0_Apply(") And Contains(callableSourceMethodC, "_bb_main_AddValues)"), "runtime C emits exact callable method declarations, slots, bodies, and virtual-call arguments")
Local callableConstructor:TCompilerResult = TBlitzMaxCompiler.Compile("callable-constructor.bmx", "SuperStrict~nFunction CombineValues:Int(left:Int,right:Int) { nomangle }~nReturn left + right~nEnd Function~nType TCallableConstructorBase~nField result:Int~nMethod New(operation:Int(a:Int,b:Int))~nresult = operation(20,22)~nEnd Method~nEnd Type~nType TCallableConstructor Extends TCallableConstructorBase~nMethod New(operation:Int(a:Int,b:Int)=CombineValues)~nSuper.New(operation)~nEnd Method~nEnd Type~nLocal defaultValue:TCallableConstructor = New TCallableConstructor~nLocal explicitValue:TCallableConstructor = New TCallableConstructor(CombineValues)", resolver, TestOptions())
Check(callableConstructor.Succeeded(), "source constructors accept, default, invoke, and chain ordinary-C-compatible callable parameters")
Local callableConstructorDump:String = TCompilerIrDumper.Dump(callableConstructor.ir)
Check(Contains(callableConstructorDump, "operation:Int(Int, Int)") And Contains(callableConstructorDump, "call-indirect (Int)") And Contains(callableConstructorDump, "[constructor] [chains @fn1]"), "callable constructor parameters and base-chain arguments remain explicit in typed IR")
Local callableConstructorDiagnostics:TCompilerDiagnostic[]
Local callableConstructorC:String = TBlitzMaxCompiler.EmitRuntimeC(callableConstructor, callableConstructorDiagnostics)
Check(callableConstructorDiagnostics.length = 0 And Contains(callableConstructorC, "_ObjectNew(BBClass *clas, BBINT (*bmx_p0_operation)(BBINT, BBINT))") And Contains(callableConstructorC, "bmx_fn1_New((struct bmx_cls0_TCallableConstructorBase_obj *)bmx_self_self, bmx_p0_operation);") And Contains(callableConstructorC, "_bb_main_CombineValues)"), "constructor allocation helpers and base chaining preserve exact callable declarations and targets")
Local capturedMethodCallable:TCompilerResult = TBlitzMaxCompiler.Compile("captured-method-callable.bmx", "SuperStrict~nImport callable.contracts~nType TComparator~nMethod Compare:Int(left:Object,right:Object)~nReturn 0~nEnd Method~nEnd Type~nLocal list:TCallableList = CreateList()~nLocal comparator:TComparator = New TComparator~nSortList(list,,comparator.Compare)", resolver, TestOptions())
Check(Not capturedMethodCallable.Succeeded(), "a receiver-bound managed Closure is not silently passed through a legacy thin callable ABI")
Local boundMethodClosure:TCompilerResult = TBlitzMaxCompiler.Compile("bound-method-closure.bmx", "SuperStrict~nType TComparator~nField offset:Int~nMethod Compare:Int(left:Int,right:Int)~nReturn left-right+offset~nEnd Method~nEnd Type~nLocal comparator:TComparator = New TComparator~nLocal callback:Closure<Int(left:Int,right:Int)> = comparator.Compare~nLocal result:Int = callback(43,1)", resolver, TestOptions())
Local boundMethodClosureDump:String = TCompilerIrDumper.Dump(boundMethodClosure.ir)
Local boundMethodClosureDiagnostics:TCompilerDiagnostic[]
Local boundMethodClosureC:String = TBlitzMaxCompiler.EmitRuntimeC(boundMethodClosure, boundMethodClosureDiagnostics)
Check(boundMethodClosure.Succeeded() And boundMethodClosureDiagnostics.length = 0 And Contains(boundMethodClosureDump, "closure-literal") And Contains(boundMethodClosureDump, "closure-call"), "typed IR retains a bound Method receiver environment and managed invocation")
Check(Contains(boundMethodClosureC, "bmx_closure_capture_new") And Contains(boundMethodClosureC, "->clas->m_cf0_Compare") And Contains(boundMethodClosureC, "->environment"), "runtime C constructs the receiver-retaining Closure and preserves virtual dispatch")
Local importedObjectHeaderDiagnostics:TCompilerDiagnostic[]
Local importedObjectHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(importedObject, importedObjectHeaderDiagnostics)
Check(importedObjectHeaderDiagnostics.length = 0 And Contains(importedObjectHeader, "sample.mod/contracts.mod/.bmx/contracts.bmx.release.test.x64.h") And Contains(importedObjectHeader, "struct sample_contracts_TImportedValue_obj * bmx_fn0_Pass(struct sample_contracts_TImportedValue_obj * bmx_p0_value);"), "runtime headers obtain imported layouts from dependency headers and retain object ABI signatures")
Local importedObjectAllocation:TCompilerResult = TBlitzMaxCompiler.Compile("imported-object-new.bmx", "SuperStrict~nImport sample.contracts~nLocal defaultValue:TImportedValue = New TImportedValue~nLocal sizedValue:TImportedValue = New TImportedValue(8)~nLocal childValue:TImportedChild = New TImportedChild", resolver, TestOptions())
Check(importedObjectAllocation.Succeeded(), "default and parameterized imported constructors lower through their published allocation contracts")
Local importedObjectAllocationDump:String = TCompilerIrDumper.Dump(importedObjectAllocation.ir)
Check(Contains(importedObjectAllocationDump, "TImportedValue:TImportedValue abi sample_contracts_TImportedValue [managed-fields]") And Contains(importedObjectAllocationDump, "constructor %icn0() abi _sample_contracts_TImportedValue_New") And Contains(importedObjectAllocationDump, "constructor %icn1(Int, Int) abi sample_contracts_TImportedValue_New_ii object-new _sample_contracts_TImportedValue_New_ii_ObjectNew") And Contains(importedObjectAllocationDump, "TImportedChild:TImportedChild abi sample_contracts_TImportedChild extends @icls0 [managed-fields]"), "constructor IR retains overload ABI helpers and traced imported layouts")
Local importedObjectAllocationDiagnostics:TCompilerDiagnostic[]
Local importedObjectAllocationC:String = TBlitzMaxCompiler.EmitRuntimeC(importedObjectAllocation, importedObjectAllocationDiagnostics)
Check(importedObjectAllocationDiagnostics.length = 0 And Contains(importedObjectAllocationC, "bbObjectNew((BBClass *)&sample_contracts_TImportedValue)") And Contains(importedObjectAllocationC, "_sample_contracts_TImportedValue_New_ii_ObjectNew((BBClass *)&sample_contracts_TImportedValue, 8, 3)") And Contains(importedObjectAllocationC, "bbObjectNew((BBClass *)&sample_contracts_TImportedChild)"), "runtime C uses descriptor construction, materialized constructor defaults and imported GC field classification")
Local importedGenericFieldAllocation:TCompilerResult = TBlitzMaxCompiler.Compile("imported-generic-field-new.bmx", "SuperStrict~nImport genericfield.contracts~nLocal owner:TImportedGenericOwner = New TImportedGenericOwner", resolver, TestOptions())
Local importedGenericFieldAllocationDiagnostics:TCompilerDiagnostic[]
Local importedGenericFieldAllocationC:String = TBlitzMaxCompiler.EmitRuntimeC(importedGenericFieldAllocation, importedGenericFieldAllocationDiagnostics)
Check(importedGenericFieldAllocation.Succeeded() And importedGenericFieldAllocation.ir.importedClasses.length = 2 And importedGenericFieldAllocation.ir.importedClasses[1].abiName = "genericfield_contracts_TImportedGenericOwner" And importedGenericFieldAllocation.ir.importedClasses[1].hasManagedFields, "a constructed-generic dependency field classifies its imported owner as managed")
Check(importedGenericFieldAllocationDiagnostics.length = 0 And Contains(importedGenericFieldAllocationC, "bbObjectNew((BBClass *)&genericfield_contracts_TImportedGenericOwner)") And Not Contains(importedGenericFieldAllocationC, "bbObjectAtomicNew((BBClass *)&genericfield_contracts_TImportedGenericOwner)"), "imported Types with dependency-owned generic reference fields use traced descriptor construction")

resolver.AddInterface("defaultctor.contracts", "sdk/defaultctor.contracts.i", "superstrict~nTImportedDefaultOnly^Object{~n-New(value%=7%)=~qdefaultctor_contracts_TImportedDefaultOnly_New_i~q~n}=~qdefaultctor_contracts_TImportedDefaultOnly~q")
Local importedDefaultOnlyAllocation:TCompilerResult = TBlitzMaxCompiler.Compile("imported-default-only-new.bmx", "SuperStrict~nImport defaultctor.contracts~nLocal value:TImportedDefaultOnly=New TImportedDefaultOnly", resolver, TestOptions())
Local importedDefaultOnlyDiagnostics:TCompilerDiagnostic[]
Local importedDefaultOnlyC:String = TBlitzMaxCompiler.EmitRuntimeC(importedDefaultOnlyAllocation, importedDefaultOnlyDiagnostics)
Check(importedDefaultOnlyAllocation.Succeeded() And importedDefaultOnlyDiagnostics.length = 0 And Contains(importedDefaultOnlyC, "defaultctor_contracts_TImportedDefaultOnly_New_i_ObjectNew((BBClass *)&defaultctor_contracts_TImportedDefaultOnly, 7)"), "an imported constructor whose parameters are all optional materializes defaults when New omits the complete argument list")

Local implicitImportedAllocation:TCompilerResult = TBlitzMaxCompiler.Compile("implicit-imported-new.bmx", "SuperStrict~nImport implicit.contracts~nLocal value:TImplicitValue=New TImplicitValue", resolver, TestOptions())
Local implicitImportedAllocationDump:String = TCompilerIrDumper.Dump(implicitImportedAllocation.ir)
Local implicitImportedAllocationDiagnostics:TCompilerDiagnostic[]
Local implicitImportedAllocationC:String = TBlitzMaxCompiler.EmitRuntimeC(implicitImportedAllocation, implicitImportedAllocationDiagnostics)
Check(implicitImportedAllocation.Succeeded() And Contains(implicitImportedAllocationDump, "constructor %icn0()") And Contains(implicitImportedAllocationDump, "object-new imported @icls0 constructor %icn0"), "an imported Type without an explicit New record receives a canonical implicit default-construction record")
Check(implicitImportedAllocationDiagnostics.length = 0 And Contains(implicitImportedAllocationC, "bbObjectNew((BBClass *)&implicit_contracts_TImplicitValue)") And Not Contains(implicitImportedAllocationC, "_ObjectNew"), "implicit imported construction delegates to the published descriptor hook and preserves managed-field allocation")

Local sourceDefaultsSource:String = "SuperStrict~nFunction AddDefaults:Int(left:Int=2,right:Int=3)~nReturn left + right~nEnd Function~nType TDefaultConstructor~nField value:Int~nMethod New(initial:Int=5)~nvalue = initial~nEnd Method~nEnd Type~nLocal sum:Int = AddDefaults(,4)~nLocal item:TDefaultConstructor = New TDefaultConstructor"
Local sourceDefaults:TCompilerResult = TBlitzMaxCompiler.Compile("source-defaults.bmx", sourceDefaultsSource, resolver, TestOptions())
Check(sourceDefaults.Succeeded(), "source routine and constructor defaults lower successfully")
Local sourceDefaultsDiagnostics:TCompilerDiagnostic[]
Local sourceDefaultsC:String = TBlitzMaxCompiler.EmitRuntimeC(sourceDefaults, sourceDefaultsDiagnostics)
Check(sourceDefaultsDiagnostics.length = 0 And Contains(sourceDefaultsC, "AddDefaults(2, 4)") And Contains(sourceDefaultsC, ", 5)"), "source calls and object construction share explicit default-argument materialization")

Local pointerCall:TCompilerResult = TBlitzMaxCompiler.Compile("pointer-call.bmx", "SuperStrict~nGlobal Buffer:Byte Ptr = MemAlloc(16)~nMemFree(Buffer)~nGlobal Empty:Byte Ptr = 0", resolver, TestOptions())
Check(pointerCall.Succeeded(), "imported pointer ABI calls and null pointer conversion lower successfully")
Check(pointerCall.ir.externalFunctions.length = 2 And pointerCall.ir.externalFunctions[0].returnType = "Byte Ptr" And pointerCall.ir.externalFunctions[1].parameters[0].semanticType = "Byte Ptr", "pointer types are retained on imported function IR")
Local pointerDump:String = TCompilerIrDumper.Dump(pointerCall.ir)
Check(Contains(pointerDump, "convert implicit null : Byte Ptr"), "integer zero to pointer is explicit null conversion IR")
Local pointerRuntimeDiagnostics:TCompilerDiagnostic[]
Local pointerRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(pointerCall, pointerRuntimeDiagnostics)
Check(pointerRuntimeDiagnostics.length = 0, "runtime backend emits pointer ABI calls")
Check(Not Contains(pointerRuntimeC, "extern void * brl_blitz_MemAlloc(BBSIZET bmx_ep0_size);") And Not Contains(pointerRuntimeC, "extern void brl_blitz_MemFree(void * bmx_ep0_mem);") And Contains(pointerRuntimeC, "brl_blitz_MemAlloc(") And Contains(pointerRuntimeC, "brl_blitz_MemFree("), "runtime C leaves source-wrapper pointer ABI spelling to the dependency header")
Local pointerStandaloneDiagnostics:TCompilerDiagnostic[]
Local pointerStandaloneC:String = TBlitzMaxCompiler.EmitC(pointerCall, pointerStandaloneDiagnostics)
Check(pointerStandaloneDiagnostics.length = 0 And Contains(pointerStandaloneC, "extern void * brl_blitz_MemAlloc(size_t bmx_ep0_size);") And Contains(pointerStandaloneC, "extern void brl_blitz_MemFree(void * bmx_ep0_mem);"), "standalone C reconstructs pointer prototypes when dependency headers are unavailable")
Local structPointer:TCompilerResult = TBlitzMaxCompiler.Compile("struct-pointer.bmx", "SuperStrict~nStruct SPointerCell~nField value:Int~nEnd Struct~nFunction ReadPointer:Int(cell:SPointerCell Ptr)~nReturn cell[0].value~nEnd Function", resolver, TestOptions())
Local structPointerDump:String = TCompilerIrDumper.Dump(structPointer.ir)
Local structPointerDiagnostics:TCompilerDiagnostic[]
Local structPointerC:String = TBlitzMaxCompiler.EmitRuntimeC(structPointer, structPointerDiagnostics)
Check(structPointer.Succeeded() And Contains(structPointerDump, "cell:SPointerCell Ptr") And Contains(structPointerDump, "pointer-element SPointerCell") And Contains(structPointerDump, "element-layout struct @st0"), "Struct pointers are retained as typed ordinary-C ABI parameters and indexed lvalues")
Check(structPointerDiagnostics.length = 0 And Contains(structPointerC, "BBINT bmx_fn0_ReadPointer(struct bmx_struct_st0_SPointerCell * bmx_p0_cell)") And Contains(structPointerC, "((struct bmx_struct_st0_SPointerCell *)bmx_p0_cell)[0]"), "runtime C emits direct C-compatible Struct pointer declarations and member access")

Local debugPointerOptions:TCompilerOptions = DebugTestOptions()
debugPointerOptions.debugInstrumentation = True
Local debugPointerSource:String = "SuperStrict~nFunction IncrementByte(value:Byte Var)~nvalue=value+1~nEnd Function~nGlobal Buffer:Byte Ptr=bbMemAlloc(4)~nBuffer[0]=20~nBuffer[1]=21~nLocal first:Byte=Buffer[0]~nIncrementByte(Buffer[1])~nLocal second:Byte=Buffer[1]~nbbMemFree(Buffer)"
Local debugPointer:TCompilerResult = TBlitzMaxCompiler.Compile("debug-pointer.bmx", debugPointerSource, resolver, debugPointerOptions)
Local debugPointerDump:String = TCompilerIrDumper.Dump(debugPointer.ir)
Local debugPointerDiagnostics:TCompilerDiagnostic[]
Local debugPointerC:String = TBlitzMaxCompiler.EmitRuntimeC(debugPointer, debugPointerDiagnostics)
Check(debugPointer.Succeeded() And Contains(debugPointerDump, "pointer-element Byte") And Contains(debugPointerDump, "null-check raw-pointer"), "raw pointer element access retains its typed lvalue and debug null-check requirement in IR")
Check(debugPointerDiagnostics.length = 0 And Contains(debugPointerC, "bmx_debug_pointer_element(void *data, ptrdiff_t index, size_t element_size)") And Contains(debugPointerC, "brl_blitz_RuntimeError(bbStringFromCString(~qAttempt to access null pointer~q))") And Contains(debugPointerC, "(*((BBBYTE *)bmx_debug_pointer_element") And Contains(debugPointerC, "bmx_fn0_IncrementByte((&(*((BBBYTE *)bmx_debug_pointer_element"), "debug pointer reads, writes and Var arguments share a single-evaluation null-checked lvalue")
Local pointerVarArgument:TCompilerResult = TBlitzMaxCompiler.Compile("pointer-var-argument.bmx", "SuperStrict~nFunction CompareAndSwap:Int(target:Int Var,oldValue:Int,newValue:Int)~nIf target=oldValue Then target=newValue; Return True~nReturn False~nEnd Function~nLocal value:Int=40~nLocal pointer:Int Ptr=Varptr value~nLocal changed:Int=CompareAndSwap(pointer,40,42)", resolver, TestOptions())
Local pointerVarArgumentDump:String = TCompilerIrDumper.Dump(pointerVarArgument.ir)
Local pointerVarArgumentDiagnostics:TCompilerDiagnostic[]
Local pointerVarArgumentC:String = TBlitzMaxCompiler.EmitRuntimeC(pointerVarArgument, pointerVarArgumentDiagnostics)
Check(pointerVarArgument.Succeeded() And Contains(pointerVarArgumentDump, "convert implicit pointer-to-var-reference : Int"), "typed IR retains the pointer dereference supplying a Var argument")
Check(pointerVarArgumentDiagnostics.length = 0 And Contains(pointerVarArgumentC, "bmx_fn0_CompareAndSwap((&(*(bmx_v1_pointer)))"), "runtime C passes the pointed Int storage rather than the pointer variable's own address")
Local qualifiedTypeGlobal:TCompilerResult = TBlitzMaxCompiler.Compile("qualified-type-global.bmx", "SuperStrict~nType TQualifiedGlobal~nGlobal Value:Int~nMethod Update:Int(nextValue:Int)~nSelf.Value=nextValue~nReturn Self.Value~nEnd Method~nEnd Type~nTQualifiedGlobal.Value=3~nLocal instance:TQualifiedGlobal=New TQualifiedGlobal~nLocal result:Int=instance.Update(7)", resolver, TestOptions())
Local qualifiedTypeGlobalDiagnostics:TCompilerDiagnostic[]
Local qualifiedTypeGlobalC:String = TBlitzMaxCompiler.EmitRuntimeC(qualifiedTypeGlobal, qualifiedTypeGlobalDiagnostics)
Check(qualifiedTypeGlobal.Succeeded() And qualifiedTypeGlobalDiagnostics.length = 0 And Contains(qualifiedTypeGlobalC, "bmx_global_") And Not HasCompilerDiagnostic(qualifiedTypeGlobal, "BMXC1015"), "Self- and Type-qualified access to Type-owned Globals lowers to the declaration-owned static storage")
Local releasePointer:TCompilerResult = TBlitzMaxCompiler.Compile("release-pointer.bmx", debugPointerSource, resolver, TestOptions())
Local releasePointerDump:String = TCompilerIrDumper.Dump(releasePointer.ir)
Local releasePointerDiagnostics:TCompilerDiagnostic[]
Local releasePointerC:String = TBlitzMaxCompiler.EmitRuntimeC(releasePointer, releasePointerDiagnostics)
Check(releasePointer.Succeeded() And releasePointerDiagnostics.length = 0 And Contains(releasePointerDump, "pointer-element Byte") And Not Contains(releasePointerDump, "null-check raw-pointer") And Not Contains(releasePointerC, "bmx_debug_pointer_element") And Contains(releasePointerC, "(((BBBYTE *)bmx_global_") And Contains(releasePointerC, ")[0])"), "release pointer IR and C retain ordinary unchecked typed indexing")
Local unsupportedPointerRank:TCompilerResult = TBlitzMaxCompiler.Compile("unsupported-pointer-rank.bmx", "SuperStrict~nLocal values:Int Ptr~nLocal value:Int=values[0,1]", resolver, debugPointerOptions)
Check(Not unsupportedPointerRank.Succeeded() And HasCompilerDiagnostic(unsupportedPointerRank, "BMXC1206"), "raw pointer indexing rejects a fabricated multidimensional access with no extent contract")

Local stringValues:TCompilerResult = TBlitzMaxCompiler.Compile("string-values.bmx", "SuperStrict~nGlobal Greeting:String = ~qhello~q~nLocal Same:String = ~qhello~q~nLocal ExplicitEmpty:String = ~q~q~nGlobal Empty:String~nGlobal RuntimeDirectory:String = AppDir~nWriteStdout(Greeting)", resolver, TestOptions())
Check(stringValues.Succeeded(), "String literals, values, imported calls and imported Globals lower successfully")
Check(stringValues.ir.stringLiterals.length = 2 And stringValues.ir.stringLiterals[0].value = "hello" And stringValues.ir.stringLiterals[1].value = "", "written String literals are canonicalized by value in deterministic first-use order")
Check(stringValues.ir.externalFunctions.length = 1 And stringValues.ir.externalFunctions[0].parameters[0].semanticType = "String", "String parameters are retained on external function IR")
Check(stringValues.ir.externalGlobals.length = 1 And stringValues.ir.externalGlobals[0].semanticType = "String" And stringValues.ir.externalGlobals[0].abiName = "bbAppDir", "imported String Global ABI identity is retained in IR")
Local stringDump:String = TCompilerIrDumper.Dump(stringValues.ir)
Check(Contains(stringDump, "string @str0 ~qhello~q") And Contains(stringDump, "string @str1 ~q~q") And Contains(stringDump, "string-literal @str0 : String") And Contains(stringDump, "managed-default String : String"), "IR dump distinguishes canonical written literals from managed String defaults")
Local directStringMethods:TCompilerResult = TBlitzMaxCompiler.Compile("direct-string-methods.bmx", "SuperStrict~nLocal text:String=~qabc~q~nLocal found:Int=text.Find(~qb~q)~nLocal replaced:String=text.Replace(~qa~q,~qz~q)~nLocal same:String=text.ToString()~nLocal number:String=String.FromInt(42)", resolver, TestOptions())
Local directStringMethodsDump:String = TCompilerIrDumper.Dump(directStringMethods.ir)
Local directStringMethodsDiagnostics:TCompilerDiagnostic[]
Local directStringMethodsC:String = TBlitzMaxCompiler.EmitRuntimeC(directStringMethods, directStringMethodsDiagnostics)
Check(directStringMethods.Succeeded() And Contains(directStringMethodsDump, "bbStringFind(self:String, subString:String, startIndex:Int) -> Int [direct-method]") And Contains(directStringMethodsDump, "bbStringReplace(self:String, subString:String, withString:String) -> String [direct-method]") And Contains(directStringMethodsDump, "bbStringToString(self:String) -> String [direct-method]") And Contains(directStringMethodsDump, "bbStringFromInt(value:Int) -> String") And Not HasCompilerDiagnostic(directStringMethods, "BMXC1172"), "core String methods retain direct runtime-function identity while Type functions remain receiverless")
Check(directStringMethodsDiagnostics.length = 0 And Not Contains(directStringMethodsC, "extern BBINT bbStringFind(") And Not Contains(directStringMethodsC, "extern BBSTRING bbStringFromInt(") And Contains(directStringMethodsC, "bbStringFind(bmx_v0_text,") And Contains(directStringMethodsC, "bbStringReplace(bmx_v0_text,") And Contains(directStringMethodsC, "bbStringToString(bmx_v0_text)") And Contains(directStringMethodsC, "bbStringFromInt(42)"), "runtime C uses the authoritative core header for direct and static String functions while passing method receivers explicitly")
Local stringRuntimeDiagnostics:TCompilerDiagnostic[]
Local stringRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(stringValues, stringRuntimeDiagnostics)
Check(stringRuntimeDiagnostics.length = 0, "runtime backend emits managed String values")
Check(Contains(stringRuntimeC, "struct BCC2_BBString_5") And Contains(stringRuntimeC, "{104,101,108,108,111}") And Contains(stringRuntimeC, "bbStringHash((BBString*)&bmx_string_str0);") And Not Contains(stringRuntimeC, "BCC2_BBString_0"), "runtime C emits production-layout UTF-16 literal storage and uses bbEmptyString for empty text")
Check(Contains(stringRuntimeC, "_Empty = &bbEmptyString;"), "uninitialized String storage receives the BlitzMax empty-string default")
Check(Not Contains(stringRuntimeC, "extern BBSTRING bbAppDir;") And Not Contains(stringRuntimeC, "extern void bbWriteStdout(BBSTRING bmx_ep0_str);") And Contains(stringRuntimeC, "bbAppDir") And Contains(stringRuntimeC, "bbWriteStdout(bmx_global_"), "runtime C uses dependency-header managed String declarations and calls")
Check(stringRuntimeC.Find("bb_init_strings();") < stringRuntimeC.Find(" = (BBString*)&bmx_string_str0;"), "String hashes initialize before String-backed global initializers")
Local standaloneStringDiagnostics:TCompilerDiagnostic[]
TBlitzMaxCompiler.EmitC(stringValues, standaloneStringDiagnostics)
Check(HasDiagnostic(standaloneStringDiagnostics, "BMXC2025"), "standalone scalar C mode explicitly rejects managed String runtime values")

Local stringOperation:TCompilerResult = TBlitzMaxCompiler.Compile("string-operation.bmx", "SuperStrict~nLocal combined:String = ~qa~q + 2~nLocal equal:Int = combined = ~qa2~q~nLocal ordered:Int = ~qa~q < ~qb~q~nLocal truth:Int~nIf combined Then truth = 1~nIf ~q~q Then truth = 2~nIf Not ~q~q Then truth = truth + 4~nLocal parsed:Int = Int(~q42~q)~nLocal formatted:String = 7", resolver, TestOptions())
Check(stringOperation.Succeeded(), "String concatenation, comparison, truth and scalar conversions lower successfully")
Local stringOperationDump:String = TCompilerIrDumper.Dump(stringOperation.ir)
Check(Contains(stringOperationDump, "string-concat : String") And Contains(stringOperationDump, "convert implicit numeric-to-string : String") And Contains(stringOperationDump, "string-compare = : Int") And Contains(stringOperationDump, "string-compare < : Int"), "String value operations are explicit typed IR")
Check(Contains(stringOperationDump, "managed-truth String : Int") And Contains(stringOperationDump, "managed-not String : Int") And Contains(stringOperationDump, "convert explicit string-to-numeric : Int"), "managed sentinel truth and explicit String-to-numeric conversion are typed IR")
Local stringOperationRuntimeDiagnostics:TCompilerDiagnostic[]
Local stringOperationRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(stringOperation, stringOperationRuntimeDiagnostics)
Check(stringOperationRuntimeDiagnostics.length = 0, "runtime backend emits supported String operations")
Check(Contains(stringOperationRuntimeC, "bbStringConcat(") And Contains(stringOperationRuntimeC, "bbStringFromInt(2)") And Contains(stringOperationRuntimeC, "bbStringEquals(") And Contains(stringOperationRuntimeC, "bbStringCompare("), "runtime C maps String value operations to brl.blitz")
Check(Contains(stringOperationRuntimeC, "!= &bbEmptyString") And Contains(stringOperationRuntimeC, "== &bbEmptyString") And Contains(stringOperationRuntimeC, "bbStringToInt(") And Contains(stringOperationRuntimeC, "bbStringFromInt(7)"), "runtime C uses managed sentinels for truth and runtime scalar conversion functions")

Local stringConversionBreadth:TCompilerResult = TBlitzMaxCompiler.Compile("string-conversions.bmx", "SuperStrict~nLocal unsignedValue:UInt = 3~nLocal unsignedText:String = unsignedValue~nLocal doubleValue:Double = 1.5~nLocal doubleText:String = doubleValue~nLocal longValue:Long = Long(~q4~q)", resolver, TestOptions())
Check(stringConversionBreadth.Succeeded(), "unsigned, floating and wide String conversions lower successfully")
Local stringConversionDiagnostics:TCompilerDiagnostic[]
Local stringConversionC:String = TBlitzMaxCompiler.EmitRuntimeC(stringConversionBreadth, stringConversionDiagnostics)
Check(stringConversionDiagnostics.length = 0 And Contains(stringConversionC, "bbStringFromUInt(") And Contains(stringConversionC, "bbStringFromDouble(") And Contains(stringConversionC, "bbStringToLong("), "runtime conversion mapping preserves representative scalar ABI widths")

Local piLiteral:TCompilerResult = TBlitzMaxCompiler.Compile("pi-literal.bmx", "SuperStrict~nLocal circle:Double=Pi", resolver, TestOptions())
Local piLiteralDiagnostics:TCompilerDiagnostic[]
Local piLiteralC:String = TBlitzMaxCompiler.EmitRuntimeC(piLiteral, piLiteralDiagnostics)
Check(piLiteral.Succeeded() And piLiteralDiagnostics.length = 0 And Not Contains(piLiteralC, "= Pi;") And Contains(piLiteralC, "3.14159"), "Pi lowers to a target-independent numeric IR literal before strict C99 emission")

Local binaryLiteral:TCompilerResult = TBlitzMaxCompiler.Compile("binary-literal.bmx", "SuperStrict~nLocal flags:Int=%11111~nLocal allBits:Int=%11111111111111111111111111111111", resolver, TestOptions())
Local binaryLiteralDiagnostics:TCompilerDiagnostic[]
Local binaryLiteralC:String = TBlitzMaxCompiler.EmitRuntimeC(binaryLiteral, binaryLiteralDiagnostics)
Check(binaryLiteral.Succeeded() And binaryLiteralDiagnostics.length = 0 And Contains(binaryLiteralC, "= 31;") And Contains(binaryLiteralC, "= -1;"), "binary bit-pattern literals normalize to their typed numeric IR values before strict C99 emission")

Local stringBoolean:TCompilerResult = TBlitzMaxCompiler.Compile("string-boolean.bmx", "SuperStrict~nLocal both:Int = ~qa~q And ~qb~q~nLocal either:Int = ~q~q Or ~qb~q", resolver, TestOptions())
Local stringBooleanDump:String = TCompilerIrDumper.Dump(stringBoolean.ir)
Local stringBooleanDiagnostics:TCompilerDiagnostic[]
Local stringBooleanC:String = TBlitzMaxCompiler.EmitRuntimeC(stringBoolean, stringBooleanDiagnostics)
Check(stringBoolean.Succeeded() And Contains(stringBooleanDump, "binary And : Int") And Contains(stringBooleanDump, "binary Or : Int") And Contains(stringBooleanDump, "managed-truth String : Int"), "String And/Or lower through explicit managed truth operands in short-circuit binary IR")
Check(stringBooleanDiagnostics.length = 0 And Contains(stringBooleanC, "!= &bbEmptyString") And Contains(stringBooleanC, " && ") And Contains(stringBooleanC, " || "), "runtime C preserves left-to-right short-circuit String truth semantics")

Local objectBoolean:TCompilerResult = TBlitzMaxCompiler.Compile("object-boolean.bmx", "SuperStrict~nType TTruthNode~nField next:TTruthNode~nEnd Type~nLocal node:TTruthNode=New TTruthNode~nLocal both:Int=node And node.next~nLocal either:Int=node.next Or node", resolver, TestOptions())
Local objectBooleanDump:String = TCompilerIrDumper.Dump(objectBoolean.ir)
Local objectBooleanDiagnostics:TCompilerDiagnostic[]
Local objectBooleanC:String = TBlitzMaxCompiler.EmitRuntimeC(objectBoolean, objectBooleanDiagnostics)
Check(objectBoolean.Succeeded() And Contains(objectBooleanDump, "binary And : Int") And Contains(objectBooleanDump, "binary Or : Int") And Occurrences(objectBooleanDump, "managed-truth Object") = 4, "Object And/Or lower through explicit managed truth operands in short-circuit binary IR")
Check(objectBooleanDiagnostics.length = 0 And Contains(objectBooleanC, " && ") And Contains(objectBooleanC, " || ") And Occurrences(objectBooleanC, "&bbNullObject") >= 4, "runtime C preserves left-to-right short-circuit Object truth semantics")

Local arrayBoolean:TCompilerResult = TBlitzMaxCompiler.Compile("array-boolean.bmx", "SuperStrict~nLocal left:Int[]=[1]~nLocal right:Int[]~nLocal both:Int=left And right~nLocal either:Int=left Or right", resolver, TestOptions())
Local arrayBooleanDump:String = TCompilerIrDumper.Dump(arrayBoolean.ir)
Local arrayBooleanDiagnostics:TCompilerDiagnostic[]
Local arrayBooleanC:String = TBlitzMaxCompiler.EmitRuntimeC(arrayBoolean, arrayBooleanDiagnostics)
Check(arrayBoolean.Succeeded() And Contains(arrayBooleanDump, "binary And : Int") And Contains(arrayBooleanDump, "binary Or : Int") And Occurrences(arrayBooleanDump, "managed-truth Array") = 4, "Array And/Or lower through explicit managed truth operands in short-circuit binary IR")
Check(arrayBooleanDiagnostics.length = 0 And Contains(arrayBooleanC, " && ") And Contains(arrayBooleanC, " || ") And Occurrences(arrayBooleanC, "&bbEmptyArray") >= 4, "runtime C preserves left-to-right short-circuit Array truth semantics")

Local contextualNullAssignmentSource:String = "SuperStrict~nType TResetNode~nField peer:TResetNode~nEnd Type~nLocal node:TResetNode=New TResetNode~nLocal text:String=~qvalue~q~nLocal values:Int[]=[1]~nLocal raw:Byte Ptr=Byte Ptr(1)~nnode.peer=Null~ntext=Null~nvalues=Null~nraw=Null~nLocal missing:Int=node.peer=Null"
Local contextualNullAssignment:TCompilerResult = TBlitzMaxCompiler.Compile("contextual-null-assignment.bmx", contextualNullAssignmentSource, resolver, TestOptions())
Local contextualNullAssignmentDiagnostics:TCompilerDiagnostic[]
Local contextualNullAssignmentC:String = TBlitzMaxCompiler.EmitRuntimeC(contextualNullAssignment, contextualNullAssignmentDiagnostics)
Check(contextualNullAssignment.Succeeded() And Not HasCompilerDiagnostic(contextualNullAssignment, "BMXC1010"), "assignment lowers an unconverted Null using the managed or pointer type of its target")
Check(contextualNullAssignmentDiagnostics.length = 0 And Contains(contextualNullAssignmentC, "&bbNullObject") And Contains(contextualNullAssignmentC, "= &bbEmptyString;") And Contains(contextualNullAssignmentC, "= &bbEmptyArray;") And Contains(contextualNullAssignmentC, "bmx_v3_raw = 0;"), "runtime C emits the canonical target-specific Null representation")
resolver.AddInterface("collision.imported", "sdk/collision.imported.i", "superstrict~nTNode^Object{~n}=~qcollision_imported_TNode~q")
Local sourceClassCollision:TCompilerResult = TBlitzMaxCompiler.Compile("source-class-collision.bmx", "SuperStrict~nImport collision.imported~nType TNode~nField parent:TNode~nEnd Type~nFunction Missing:TNode()~nReturn Null~nEnd Function", resolver, TestOptions())
Local sourceClassCollisionDiagnostics:TCompilerDiagnostic[]
Local sourceClassCollisionC:String = TBlitzMaxCompiler.EmitRuntimeC(sourceClassCollision, sourceClassCollisionDiagnostics)
Check(sourceClassCollision.Succeeded() And sourceClassCollisionDiagnostics.length = 0, "a source class may shadow an imported class with the same simple name")
Check(Contains(sourceClassCollisionC, "struct bmx_cls0_TNode_obj *") And Not Contains(sourceClassCollisionC, "struct collision_imported_TNode_obj *)&bbNullObject"), "source-class Null defaults use the selected source class rather than a same-named imported class")
Local overloadNull:TCompilerResult = TBlitzMaxCompiler.Compile("overload-null.bmx", "SuperStrict~nType TNullComparable~nMethod Operator =:Int(other:Object)~nReturn other=Null~nEnd Method~nEnd Type~nLocal value:TNullComparable=New TNullComparable~nLocal missing:Int=value=Null", resolver, TestOptions())
Check(overloadNull.Succeeded() And Contains(TCompilerIrDumper.Dump(overloadNull.ir), "managed-default Object : Object") And Not HasCompilerDiagnostic(overloadNull, "BMXC1010"), "a selected overload lowers an explicit Null argument using its value parameter's managed type")

Local stringCompound:TCompilerResult = TBlitzMaxCompiler.Compile("string-compound.bmx", "SuperStrict~nType TPathNode~nField targetText:String~nEnd Type~nType TPathRoot~nField node:TPathNode=New TPathNode~nEnd Type~nLocal path:String=~qroot~q~npath:+~q/~q~nLocal count:Int=12~npath:+(count/2)~nGlobal suffix:String=~q.txt~q~nsuffix:+~q.bak~q~nLocal node:TPathNode=New TPathNode~nnode.targetText:+~qmodule~q~nLocal root:TPathRoot=New TPathRoot~nroot.node.targetText:+~qnested~q", resolver, TestOptions())
Local stringCompoundDump:String = TCompilerIrDumper.Dump(stringCompound.ir)
Local stringCompoundDiagnostics:TCompilerDiagnostic[]
Local stringCompoundC:String = TBlitzMaxCompiler.EmitRuntimeC(stringCompound, stringCompoundDiagnostics)
Check(stringCompound.Succeeded() And Occurrences(stringCompoundDump, "string-concat : String") = 5 And Contains(stringCompoundDump, "convert implicit numeric-to-string : String") And Not HasCompilerDiagnostic(stringCompound, "BMXC1005"), "stable local, Global and field-chain String :+ assignments lower to explicit typed concatenation with numeric operand conversion")
Check(stringCompoundDiagnostics.length = 0 And Occurrences(stringCompoundC, "= bbStringConcat(") = 5 And Contains(stringCompoundC, "bbStringFromInt((bmx_v1_count / 2))"), "runtime C emits String compound concatenation as an ordinary assignment with explicit numeric formatting")
Local castReceiverCompound:TCompilerResult = TBlitzMaxCompiler.Compile("cast-receiver-compound.bmx", "SuperStrict~nType TCastAppender~nField text:String~nEnd Type~nFunction Append(value:Object)~nTCastAppender(value).text :+ ~qx~q~nEnd Function", resolver, TestOptions())
Local castReceiverCompoundDiagnostics:TCompilerDiagnostic[]
Local castReceiverCompoundC:String = TBlitzMaxCompiler.EmitRuntimeC(castReceiverCompound, castReceiverCompoundDiagnostics)
Check(castReceiverCompound.Succeeded() And castReceiverCompoundDiagnostics.length = 0 And Not HasCompilerDiagnostic(castReceiverCompound, "BMXC1005"), "a cast of a stable Object symbol remains a stable String compound-assignment receiver")
Check(Contains(castReceiverCompoundC, "= bbStringConcat("), "runtime C lowers String :+ through a stable cast-qualified field receiver")

Local selfManagedCompoundSource:String = "SuperStrict~nType TManagedAppender~nField text:String~nField values:Int[]~nMethod Append()~nSelf.text :+ ~qx~q~nSelf.values :+ [1]~nEnd Method~nEnd Type"
Local selfManagedCompound:TCompilerResult = TBlitzMaxCompiler.Compile("self-managed-compound.bmx", selfManagedCompoundSource, resolver, TestOptions())
Local selfManagedCompoundDump:String = TCompilerIrDumper.Dump(selfManagedCompound.ir)
Local selfManagedCompoundDiagnostics:TCompilerDiagnostic[]
Local selfManagedCompoundC:String = TBlitzMaxCompiler.EmitRuntimeC(selfManagedCompound, selfManagedCompoundDiagnostics)
Check(selfManagedCompound.Succeeded() And selfManagedCompoundDiagnostics.length = 0 And Contains(selfManagedCompoundDump, "string-concat : String") And Contains(selfManagedCompoundDump, "array-concat Int encoding"), "Self-qualified String and heap-array fields are stable compound-assignment targets")
Check(Contains(selfManagedCompoundC, "= bbStringConcat(") And Contains(selfManagedCompoundC, "= bbArrayConcat("), "runtime C evaluates Self-qualified managed concatenation as an ordinary field assignment")
Check(Not Contains(selfManagedCompoundC, "bbStringConcat(((bmx_tmp_") And Not Contains(selfManagedCompoundC, "bbArrayConcat(~qi~q, ((bmx_tmp_"), "runtime C reuses the sequenced assignment receiver instead of assigning its temporary again inside the right-hand expression")

Local stringSliceSource:String = "SuperStrict~nFunction MakeText:String()~nReturn ~qabcdef~q~nEnd Function~nLocal text:String=~qabcdef~q~nLocal textLength:Int=text.length~nLocal legacyLength:Int=Len(text)~nLocal character:Int=text[2]~nLocal slash:Int=Asc(~q/~q)~nLocal letter:String=Chr(65)~nLocal first:Int=Asc(text)~nLocal rebuilt:String=Chr(first)~nLocal middle:String=text[1..4]~nLocal prefix:String=text[..3]~nLocal suffix:String=text[3..]~nLocal temporary:String=MakeText()[1..]"
Local stringSlices:TCompilerResult = TBlitzMaxCompiler.Compile("string-slices.bmx", stringSliceSource, resolver, TestOptions())
Local stringSlicesDump:String = TCompilerIrDumper.Dump(stringSlices.ir)
Local stringSlicesDiagnostics:TCompilerDiagnostic[]
Local stringSlicesC:String = TBlitzMaxCompiler.EmitRuntimeC(stringSlices, stringSlicesDiagnostics)
Check(stringSlices.Succeeded() And Occurrences(stringSlicesDump, "string-length : Int") = 2 And Contains(stringSlicesDump, "string-element : Int") And Contains(stringSlicesDump, "string-asc : Int") And Contains(stringSlicesDump, "string-chr : String") And Occurrences(stringSlicesDump, "string-slice : String") = 4 And Contains(stringSlicesDump, "upper receiver-length") And Contains(stringSlicesDump, "materialize %t0:String"), "String member and intrinsic operations, indexing, and bounded or omitted slices lower to distinct typed IR")
Check(stringSlicesDiagnostics.length = 0 And Occurrences(stringSlicesC, "bbStringSlice(") = 4 And Contains(stringSlicesC, "->length)") And Contains(stringSlicesC, "->buf[(BBUINT)2]") And Occurrences(stringSlicesC, "bbStringAsc(") = 1 And Occurrences(stringSlicesC, "bbStringFromChar(") = 1 And Contains(stringSlicesC, "= 47;") And Occurrences(stringSlicesC, "bmx_fn0_MakeText()") = 1, "runtime C folds constant Asc/Chr operands and emits production calls only for dynamic String intrinsics")
Local constantStringLength:TCompilerResult = TBlitzMaxCompiler.Compile("constant-string-length.bmx", "SuperStrict~nConst Magic:String=~qBMXGT~q~nLocal length:Int=Magic.length~nLocal suffix:String=~qheader~q[Magic.length..]", resolver, TestOptions())
Local constantStringLengthDiagnostics:TCompilerDiagnostic[]
Local constantStringLengthC:String = TBlitzMaxCompiler.EmitRuntimeC(constantStringLength, constantStringLengthDiagnostics)
Check(constantStringLength.Succeeded() And constantStringLengthDiagnostics.length = 0 And Contains(constantStringLengthC, ")->length") And Not Contains(constantStringLengthC, "&bmx_string_str0->length"), "runtime C parenthesizes literal-backed managed receivers before String length access")
Local leadingZeroDecimals:TCompilerResult = TBlitzMaxCompiler.Compile("leading-zero-decimals.bmx", "SuperStrict~nLocal values:Int[16]~nLocal index:Int=1~nvalues[index+08]=1~nvalues[index+09]=2", resolver, TestOptions())
Local leadingZeroDecimalDiagnostics:TCompilerDiagnostic[]
Local leadingZeroDecimalC:String = TBlitzMaxCompiler.EmitRuntimeC(leadingZeroDecimals, leadingZeroDecimalDiagnostics)
Check(leadingZeroDecimals.Succeeded() And leadingZeroDecimalDiagnostics.length = 0 And Contains(leadingZeroDecimalC, " + 8)") And Contains(leadingZeroDecimalC, " + 9)") And Not Contains(leadingZeroDecimalC, " + 08)") And Not Contains(leadingZeroDecimalC, " + 09)"), "BlitzMax decimal integer literals are canonicalized before strict C emission instead of acquiring C octal semantics")
Local floatingModulo:TCompilerResult = TBlitzMaxCompiler.Compile("floating-modulo.bmx", "SuperStrict~nLocal left:Float=8.5~nLocal right:Float=3.0~nLocal floatResult:Float=left Mod right~nLocal doubleResult:Double=Double(left) Mod 2.0", resolver, TestOptions())
Local floatingModuloDiagnostics:TCompilerDiagnostic[]
Local floatingModuloC:String = TBlitzMaxCompiler.EmitRuntimeC(floatingModulo, floatingModuloDiagnostics)
Check(floatingModulo.Succeeded() And floatingModuloDiagnostics.length = 0 And Occurrences(floatingModuloC, "bbFloatMod(") = 2 And Not Contains(floatingModuloC, " % "), "Float and Double Mod use the production floating remainder runtime instead of C's integral-only percent operator")
Local floatingCompoundModulo:TCompilerResult = TBlitzMaxCompiler.Compile("floating-compound-modulo.bmx", "SuperStrict~nGlobal angle:Double=721.5~nangle :Mod 360~nLocal phase:Float=8.5~nphase :Mod 3", resolver, TestOptions())
Local floatingCompoundModuloDiagnostics:TCompilerDiagnostic[]
Local floatingCompoundModuloC:String = TBlitzMaxCompiler.EmitRuntimeC(floatingCompoundModulo, floatingCompoundModuloDiagnostics)
Check(floatingCompoundModulo.Succeeded() And floatingCompoundModuloDiagnostics.length = 0 And Occurrences(floatingCompoundModuloC, "bbFloatMod(") = 2 And Not Contains(floatingCompoundModuloC, "%="), "Float and Double :Mod assignments use the floating remainder runtime rather than invalid C percent assignment")
Local unsignedLongLiteral:TCompilerResult = TBlitzMaxCompiler.Compile("unsigned-long-literal.bmx", "SuperStrict~nConst SIGNBIT_64:ULong=$8000000000000000:ULong~nLocal value:ULong=SIGNBIT_64", resolver, TestOptions())
Local unsignedLongLiteralDiagnostics:TCompilerDiagnostic[]
Local unsignedLongLiteralC:String = TBlitzMaxCompiler.EmitRuntimeC(unsignedLongLiteral, unsignedLongLiteralDiagnostics)
Check(unsignedLongLiteral.Succeeded() And unsignedLongLiteralDiagnostics.length = 0 And Contains(unsignedLongLiteralC, "9223372036854775808ULL"), "ULong constants carry an explicit unsigned 64-bit C suffix")
Local debugStringElementOptions:TCompilerOptions = DebugTestOptions()
debugStringElementOptions.debugInstrumentation = True
Local debugStringElement:TCompilerResult = TBlitzMaxCompiler.Compile("debug-string-element.bmx", "SuperStrict~nLocal text:String=~qabc~q~nLocal character:Int=text[1]", resolver, debugStringElementOptions)
Local debugStringElementDiagnostics:TCompilerDiagnostic[]
Local debugStringElementC:String = TBlitzMaxCompiler.EmitRuntimeC(debugStringElement, debugStringElementDiagnostics)
Check(debugStringElement.Succeeded() And debugStringElementDiagnostics.length = 0 And Contains(TCompilerIrDumper.Dump(debugStringElement.ir), "string-element [bounds-check] : Int") And Contains(debugStringElementC, "bmx_debug_string_element(") And Contains(debugStringElementC, "brl_blitz_ArrayBoundsError();"), "debug String indexing retains and emits its bounds-check contract")

Local arraySliceSource:String = "SuperStrict~nFunction MakeValues:Int[]()~nReturn [1,2,3]~nEnd Function~nLocal values:Int[]=[1,2,3,4]~nLocal middle:Int[]=values[1..3]~nLocal tail:Int[]=values[2..]~nLocal temporary:Int[]=MakeValues()[..2]"
Local arraySlices:TCompilerResult = TBlitzMaxCompiler.Compile("array-slices.bmx", arraySliceSource, resolver, TestOptions())
Local arraySlicesDump:String = TCompilerIrDumper.Dump(arraySlices.ir)
Local arraySlicesDiagnostics:TCompilerDiagnostic[]
Local arraySlicesC:String = TBlitzMaxCompiler.EmitRuntimeC(arraySlices, arraySlicesDiagnostics)
Check(arraySlices.Succeeded() And Occurrences(arraySlicesDump, "array-slice Int encoding ~qi~q") = 3 And Contains(arraySlicesDump, "upper receiver-length") And Contains(arraySlicesDump, "materialize %t"), "ordinary heap Array slices retain element encoding, omitted bounds, and single-evaluation receiver intent in typed IR")
Check(arraySlicesDiagnostics.length = 0 And Occurrences(arraySlicesC, "bbArraySlice(~qi~q,") = 3 And Occurrences(arraySlicesC, "bmx_fn0_MakeValues()") = 1, "runtime C emits canonical slices and evaluates a temporary heap Array receiver once")
Local structSlice:TCompilerResult = TBlitzMaxCompiler.Compile("struct-array-slice.bmx", "SuperStrict~nStruct SSliceCell~nField value:Int~nEnd Struct~nLocal values:SSliceCell[]=New SSliceCell[2]~nLocal first:SSliceCell[]=values[..1]", resolver, TestOptions())
Local structSliceDiagnostics:TCompilerDiagnostic[]
Local structSliceC:String = TBlitzMaxCompiler.EmitRuntimeC(structSlice, structSliceDiagnostics)
Check(structSlice.Succeeded() And structSliceDiagnostics.length = 0 And Contains(TCompilerIrDumper.Dump(structSlice.ir), "array-slice SSliceCell encoding ~q@SSliceCell~q") And Contains(structSliceC, "bbArraySliceStruct(~q@SSliceCell~q,") And Contains(structSliceC, "sizeof(struct bmx_struct_st0_SSliceCell)") And Contains(structSliceC, "bmx_struct_array_init_st0"), "Struct heap Array slicing retains layout identity and uses its typed copy/default helper")

Local stackAllocation:TCompilerResult = TBlitzMaxCompiler.Compile("stack-allocation.bmx", "SuperStrict~nLocal buffer:Byte Ptr = StackAlloc(50)", resolver, TestOptions())
Local stackAllocationDiagnostics:TCompilerDiagnostic[]
Local stackAllocationC:String = TBlitzMaxCompiler.EmitRuntimeC(stackAllocation, stackAllocationDiagnostics)
Check(stackAllocation.Succeeded() And stackAllocationDiagnostics.length = 0 And Contains(TCompilerIrDumper.Dump(stackAllocation.ir), "unary StackAlloc : Byte Ptr") And Contains(stackAllocationC, "bbStackAlloc("), "StackAlloc has an explicit pointer-valued unary IR and runtime C lowering")

Local selectSource:String = "SuperStrict~nGlobal SelectCalls:Int~nFunction Choose:Int()~nSelectCalls:+1~nReturn 2~nEnd Function~nEnum EChoice~nFirst~nSecond~nEnd Enum~nLocal result:Int~nSelect Choose()~nCase 1,2~nresult=20~nCase 3~nresult=30~nDefault~nresult=40~nEnd Select~nLocal path:String=~q.~q~nSelect path~nCase ~q~q~nCase ~q.~q,~q..~q~nresult:+1~nDefault~nresult:+2~nEnd Select~nLocal choice:EChoice=EChoice.Second~nSelect choice~nCase EChoice.First~nresult:+4~nCase EChoice.Second~nresult:+8~nEnd Select"
Local selectValues:TCompilerResult = TBlitzMaxCompiler.Compile("select-values.bmx", selectSource, resolver, TestOptions())
Local selectValuesDump:String = TCompilerIrDumper.Dump(selectValues.ir)
Local selectValuesDiagnostics:TCompilerDiagnostic[]
Local selectValuesC:String = TBlitzMaxCompiler.EmitRuntimeC(selectValues, selectValuesDiagnostics)
Check(selectValues.Succeeded() And Contains(selectValuesDump, "select scalar Int [selector %t") And Contains(selectValuesDump, "select string String [selector %t") And Contains(selectValuesDump, "select scalar EChoice [selector %t") And Occurrences(selectValuesDump, "case @") = 6, "scalar, String, and Enum Select statements retain typed selectors, ordered cases, multi-value cases, empty bodies, and defaults in IR")
Check(selectValuesDiagnostics.length = 0 And Occurrences(selectValuesC, "bmx_fn0_Choose()") = 1 And Contains(selectValuesC, " || ") And Contains(selectValuesC, "bbStringEquals(") And Contains(selectValuesC, " else {") And Not Contains(selectValuesC, "if ((bmx_tmp_"), "runtime C evaluates Select once and emits ordered warning-clean scalar or runtime String comparisons")

Local conditionalSelect:TCompilerResult = TBlitzMaxCompiler.Compile("conditional-select.bmx", "SuperStrict~nLocal value:Int=2~nLocal result:Int~nSelect value~n?BigEndian~nCase 1~nresult=10~n?x64~nCase 2~nresult=20~n?~nEnd Select", resolver, TestOptions())
Local conditionalSelectDump:String = TCompilerIrDumper.Dump(conditionalSelect.ir)
Check(conditionalSelect.Succeeded() And Occurrences(conditionalSelectDump, "case @") = 1 And Contains(conditionalSelectDump, "literal 2 : Int") And Not Contains(conditionalSelectDump, "literal 1 : Int"), "Select lowers only Case clauses active for the target conditional-symbol set")

Local conditionalDefaultSelect:TCompilerResult = TBlitzMaxCompiler.Compile("conditional-default-select.bmx", "SuperStrict~nLocal value:Int~nLocal result:Int~nSelect value~n?BigEndian~nDefault~nresult=10~n?x64~nDefault~nresult=20~n?~nEnd Select", resolver, TestOptions())
Local conditionalDefaultSelectDump:String = TCompilerIrDumper.Dump(conditionalDefaultSelect.ir)
Check(conditionalDefaultSelect.Succeeded() And Contains(conditionalDefaultSelectDump, "literal 20 : Int") And Not Contains(conditionalDefaultSelectDump, "literal 10 : Int"), "Select lowers only the Default clause active for the target conditional-symbol set")
Local duplicateActiveDefault:TCompilerResult = TBlitzMaxCompiler.Compile("duplicate-active-default.bmx", "SuperStrict~nLocal value:Int~nSelect value~n?x64~nDefault~nPrint 1~n?test~nDefault~nPrint 2~n?~nEnd Select", resolver, TestOptions())
Check(Not duplicateActiveDefault.Succeeded() And HasLanguageDiagnostic(duplicateActiveDefault, "BMX2400"), "multiple conditionally active Default clauses diagnose after target evaluation")
Local activeCaseAfterDefault:TCompilerResult = TBlitzMaxCompiler.Compile("active-case-after-default.bmx", "SuperStrict~nLocal value:Int~nSelect value~n?x64~nDefault~nPrint 1~n?test~nCase 2~nPrint 2~n?~nEnd Select", resolver, TestOptions())
Check(Not activeCaseAfterDefault.Succeeded() And HasLanguageDiagnostic(activeCaseAfterDefault, "BMX2401"), "a conditionally active Case following an active Default diagnoses after target evaluation")

Local objectSelect:TCompilerResult = TBlitzMaxCompiler.Compile("object-select.bmx", "SuperStrict~nType TChoice~nEnd Type~nGlobal First:TChoice=New TChoice~nGlobal Second:TChoice=New TChoice~nLocal selected:TChoice=Second~nLocal result:Int~nSelect selected~nCase First~nresult=1~nCase Second~nresult=2~nEnd Select", resolver, TestOptions())
Local objectSelectDiagnostics:TCompilerDiagnostic[]
Local objectSelectC:String = TBlitzMaxCompiler.EmitRuntimeC(objectSelect, objectSelectDiagnostics)
Check(objectSelect.Succeeded() And objectSelectDiagnostics.length = 0 And Contains(objectSelectC, "(BBOBJECT)bmx_tmp_") And Contains(objectSelectC, "== (BBOBJECT)bmx_global_"), "Object-valued Select evaluates once and compares managed identities")

Local arraySelect:TCompilerResult = TBlitzMaxCompiler.Compile("array-select.bmx", "SuperStrict~nGlobal First:Int[]=New Int[1]~nGlobal Second:Int[]=New Int[1]~nLocal selected:Int[]=Second~nLocal result:Int~nSelect selected~nCase First~nresult=1~nCase Second~nresult=2~nEnd Select", resolver, TestOptions())
Local arraySelectDiagnostics:TCompilerDiagnostic[]
Local arraySelectC:String = TBlitzMaxCompiler.EmitRuntimeC(arraySelect, arraySelectDiagnostics)
Check(arraySelect.Succeeded() And arraySelectDiagnostics.length = 0 And Contains(TCompilerIrDumper.Dump(arraySelect.ir), "select identity Int[]") And Contains(arraySelectC, "(BBOBJECT)bmx_tmp_") And Contains(arraySelectC, "== (BBOBJECT)bmx_global_"), "Array-valued Select evaluates once and compares managed identities")

Local tryCatchSource:String = "SuperStrict~nType TProblem~nEnd Type~nGlobal caught:Int~nTry~nThrow New TProblem~nCatch problem:TProblem~ncaught=1~nCatch message:String~ncaught=2~nEnd Try~nTry~nThrow ~qtext~q~nCatch problem:TProblem~ncaught=3~nCatch message:String~ncaught=4~nEnd Try"
Local tryCatch:TCompilerResult = TBlitzMaxCompiler.Compile("try-catch.bmx", tryCatchSource, resolver, TestOptions())
Local tryCatchDump:String = TCompilerIrDumper.Dump(tryCatch.ir)
Local tryCatchDiagnostics:TCompilerDiagnostic[]
Local tryCatchC:String = TBlitzMaxCompiler.EmitRuntimeC(tryCatch, tryCatchDiagnostics)
Check(tryCatch.Succeeded() And Occurrences(tryCatchDump, "try @") = 2 And Contains(tryCatchDump, "catch class %") And Contains(tryCatchDump, "catch string %") And Occurrences(tryCatchDump, "throw @") = 2, "catch-only exception control flow retains ordered typed catches, catch symbols, bodies, and Throw values in IR")
Check(tryCatchDiagnostics.length = 0 And Occurrences(tryCatchC, "bbExTry {") = 2 And Contains(tryCatchC, "bbExCatch()") And Contains(tryCatchC, "bbObjectDowncast(") And Contains(tryCatchC, "bbObjectStringcast(") And Contains(tryCatchC, "bbExThrow((BBObject *)"), "runtime C uses the existing exception stack and type matchers for catch-only Try blocks")
Local objectStringCast:TCompilerResult = TBlitzMaxCompiler.Compile("object-string-cast.bmx", "SuperStrict~nFunction AsString:String(value:Object)~nReturn String(value)~nEnd Function~nLocal missing:Object~nLocal text:String=AsString(missing)", resolver, TestOptions())
Local objectStringCastDump:String = TCompilerIrDumper.Dump(objectStringCast.ir)
Local objectStringCastDiagnostics:TCompilerDiagnostic[]
Local objectStringCastC:String = TBlitzMaxCompiler.EmitRuntimeC(objectStringCast, objectStringCastDiagnostics)
Check(objectStringCast.Succeeded() And Contains(objectStringCastDump, "object-string-cast : String"), "explicit Object-to-String conversion retains its managed runtime cast in typed IR")
Check(objectStringCastDiagnostics.length = 0 And Contains(objectStringCastC, "bbObjectStringcast((BBOBJECT)") And Not Contains(objectStringCastC, "((BBSTRING)(((BBOBJECT)"), "Object-to-String C normalizes bbNullObject to the canonical empty String")
Local tryFinallySource:String = "SuperStrict~nGlobal CleanupCount:Int~nFunction Read:Int()~nTry~nCleanupCount:+1~nReturn 42~nFinally~nCleanupCount:+10~nEnd Try~nEnd Function~nFunction Normal()~nTry~nCleanupCount:+100~nFinally~nCleanupCount:+1000~nEnd Try~nEnd Function~nGlobal CleanupResult:Int=Read()"
Local tryFinally:TCompilerResult = TBlitzMaxCompiler.Compile("try-finally.bmx", tryFinallySource, resolver, TestOptions())
Local tryFinallyDump:String = TCompilerIrDumper.Dump(tryFinally.ir)
Local tryFinallyDiagnostics:TCompilerDiagnostic[]
Local tryFinallyC:String = TBlitzMaxCompiler.EmitRuntimeC(tryFinally, tryFinallyDiagnostics)
Check(tryFinally.Succeeded() And Contains(tryFinallyDump, "leave-exception-frame finally") And Occurrences(tryFinallyDump, "finally") >= 3, "Finally and protected Return retain explicit ordered cleanup edges in typed IR")
Check(tryFinallyDiagnostics.length = 0 And Contains(tryFinallyC, "bmx_cleanup_return_0 = 42;") And AppearsBefore(tryFinallyC, "bmx_cleanup_return_0 = 42;", "bbExLeave();") And Contains(tryFinallyC, "if (bmx_try0_failed) bbExThrow"), "runtime C evaluates Return before leaving the exception frame, runs Finally, and rethrows an unhandled exception after cleanup")
Local tryOuterContinue:TCompilerResult = TBlitzMaxCompiler.Compile("try-outer-continue.bmx", "SuperStrict~nGlobal CleanupCount:Int~n#Outer~nFor Local index:Int=0 Until 1~nTry~nContinue Outer~nFinally~nCleanupCount:+1~nEnd Try~nNext", resolver, TestOptions())
Local tryOuterContinueDiagnostics:TCompilerDiagnostic[]
Local tryOuterContinueC:String = TBlitzMaxCompiler.EmitRuntimeC(tryOuterContinue, tryOuterContinueDiagnostics)
Check(tryOuterContinue.Succeeded() And tryOuterContinueDiagnostics.length = 0 And Contains(TCompilerIrDumper.Dump(tryOuterContinue.ir), "continue @loop0 [cleanup 1]"), "labelled Continue crossing a Try boundary retains one explicit Finally cleanup edge")
Check(AppearsBefore(tryOuterContinueC, "CleanupCount", "goto bmx_loop0_continue;"), "runtime C executes Finally before transferring to the outer loop continuation")
Local tryReturn:TCompilerResult = TBlitzMaxCompiler.Compile("try-return.bmx", "SuperStrict~nFunction Read:Int()~nTry~nReturn 1~nCatch problem:Object~nReturn 2~nEnd Try~nEnd Function", resolver, TestOptions())
Check(tryReturn.Succeeded() And Contains(TCompilerIrDumper.Dump(tryReturn.ir), "leave-exception-frame"), "Return from a catch-only protected body explicitly leaves its exception frame")
Local combinedCatchFinally:TCompilerResult = TBlitzMaxCompiler.Compile("combined-catch-finally-boundary.bmx", "SuperStrict~nTry~nThrow ~qproblem~q~nCatch problem:Object~nFinally~nEnd Try", resolver, TestOptions())
Local combinedCatchFinallyDiagnostics:TCompilerDiagnostic[]
Local combinedCatchFinallyC:String = TBlitzMaxCompiler.EmitRuntimeC(combinedCatchFinally, combinedCatchFinallyDiagnostics)
Check(combinedCatchFinally.Succeeded() And combinedCatchFinallyDiagnostics.length = 0 And Occurrences(combinedCatchFinallyC, "bbExTry {") = 2, "combined Catch and Finally lowers as nested exception frames")
Local dataSource:String = "SuperStrict~nEnum EDataValue:Int~nAnswer=42~nEnd Enum~nLocal Number:Int~nLocal Text:String~nRestoreData values~nReadData Number, Text~n#values~nDefData EDataValue.Answer, ~qanswer~q"
Local dataCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("data-runtime.bmx", dataSource, resolver, TestOptions())
Local dataDump:String = TCompilerIrDumper.Dump(dataCompilation.ir)
Local dataDiagnostics:TCompilerDiagnostic[]
Local dataC:String = TBlitzMaxCompiler.EmitRuntimeC(dataCompilation, dataDiagnostics)
Check(dataCompilation.Succeeded() And Contains(dataDump, "data 0 i") And Contains(dataDump, "data 1 $") And Contains(dataDump, "restore-data 0") And Contains(dataDump, "read-data 2"), "DefData, RestoreData, and ReadData lower to typed cursor operations and an indexed constant data section")
Check(dataDiagnostics.length = 0 And Contains(dataC, "static struct bbDataDef bmx_data[2]") And Contains(dataC, "bmx_data_offset = &bmx_data[0]") And Contains(dataC, "bbConvertToInt(bmx_data_offset++)") And Contains(dataC, "bbConvertToString(bmx_data_offset++)"), "runtime C emits the established tagged Data ABI, cursor reset, bounds checks, and target conversions")

Local nativeString:TCompilerResult = TBlitzMaxCompiler.Compile("native-string.bmx", "SuperStrict~nExtern~nFunction NativeStringLength:Int(value:String) = ~qbcc2_native_string_length~q~nGlobal NativeString:String = ~qbcc2_native_string~q~nEnd Extern~nGlobal Message:String = ~qnative~q~nGlobal MessageLength:Int = NativeStringLength(Message)~nNativeString = Message", resolver, TestOptions())
Check(nativeString.Succeeded(), "source Extern String function and Global ABI lower successfully")
Check(nativeString.ir.externalFunctions.length = 1 And nativeString.ir.externalFunctions[0].parameters[0].semanticType = "String" And nativeString.ir.externalGlobals.length = 1 And nativeString.ir.externalGlobals[0].semanticType = "String", "source native String ABI is retained in typed IR")
Local nativeStringRuntimeDiagnostics:TCompilerDiagnostic[]
Local nativeStringRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeString, nativeStringRuntimeDiagnostics)
Check(nativeStringRuntimeDiagnostics.length = 0 And Contains(nativeStringRuntimeC, "extern BBINT bcc2_native_string_length(BBSTRING bmx_ep0_value);") And Contains(nativeStringRuntimeC, "extern BBSTRING bcc2_native_string;"), "runtime C publishes exact source native String ABI declarations")

Local arrayValues:TCompilerResult = TBlitzMaxCompiler.Compile("array-values.bmx", "SuperStrict~nLocal Empty:Int[]~nLocal Values:Int[] = New Int[2]~nValues[0] = 20~nValues[1] = 22~nLocal Tail:Int[] = New Int[1]~nTail[0] = 1~nLocal Joined:Int[] = Values + Tail~nLocal Total:Int = Values[0] + Values[1]~nLocal Count:Int = Joined.length~nLocal CountByFunction:Int = Len(Joined)~nLocal Same:Int = Empty = Empty~nIf Empty~nTotal = -1~nEnd If~nIf Not Empty~nTotal = Total + Count + CountByFunction~nEnd If", resolver, TestOptions())
Check(arrayValues.Succeeded(), "one-dimensional scalar array allocation, indexing, assignment, concatenation, length and truth lower successfully")
Local arrayDump:String = TCompilerIrDumper.Dump(arrayValues.ir)
Check(Contains(arrayDump, "managed-default Array : Int[]") And Contains(arrayDump, "array-new Int encoding ~qi~q rank 1") And Contains(arrayDump, "array-element Int rank 1"), "array defaults, allocation and typed elements are explicit IR")
Check(Contains(arrayDump, "array-concat Int encoding ~qi~q") And Occurrences(arrayDump, "array-length : Int") = 2 And Contains(arrayDump, "managed-identity = Array") And Contains(arrayDump, "managed-not Array"), "array concatenation, member and unary length, identity and sentinel truth are explicit IR")
Local arrayRuntimeDiagnostics:TCompilerDiagnostic[]
Local arrayRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(arrayValues, arrayRuntimeDiagnostics)
Check(arrayRuntimeDiagnostics.length = 0, "runtime backend emits supported scalar array operations")
Check(Contains(arrayRuntimeC, "BBARRAY bmx_") And Contains(arrayRuntimeC, "= &bbEmptyArray;") And Contains(arrayRuntimeC, "bbArrayNew1D(~qi~q, 2)") And Contains(arrayRuntimeC, "bbArrayConcat(~qi~q"), "runtime C uses BBARRAY, its sentinel, element encoding and allocation/concat APIs")
Check(Contains(arrayRuntimeC, "BBARRAYDATA(") And Contains(arrayRuntimeC, "->scales[0]") And Contains(arrayRuntimeC, "== &bbEmptyArray"), "runtime C emits element storage, length and managed Array truth semantics")

Local arrayLiteralSource:String = "SuperStrict~nExtern~nFunction Mark:Int(value:Int) = ~qbcc2_mark~q~nEnd Extern~nLocal Values:Int[] = [Mark(1), Mark(2), Mark(3)]~nLocal Text:String[] = [~qleft~q, ~qright~q]~nLocal Empty:Int[] = []~nLocal Rows:Int[][] = [Values, [4, 5]]~nLocal Total:Int = Values[0] + Values[2] + Text.length + Empty.length + Rows.length"
Local arrayLiterals:TCompilerResult = TBlitzMaxCompiler.Compile("array-literals.bmx", arrayLiteralSource, resolver, TestOptions())
Check(arrayLiterals.Succeeded(), "contextual scalar, String, empty and nested array literals lower successfully")
Local arrayLiteralDump:String = TCompilerIrDumper.Dump(arrayLiterals.ir)
Check(Contains(arrayLiteralDump, "array-literal Int encoding ~qi~q count 3") And Contains(arrayLiteralDump, "array-literal String encoding ~q$~q count 2") And Contains(arrayLiteralDump, "managed-default Array : Int[]") And Contains(arrayLiteralDump, "array-literal Int[] encoding ~q[]i~q count 2"), "array literal IR retains element types, runtime encodings and element counts while canonicalizing the empty literal")
Check(AppearsBefore(arrayLiteralDump, "materialize %t0", "materialize %t1") And AppearsBefore(arrayLiteralDump, "materialize %t1", "materialize %t2"), "array literal element evaluation is explicitly sequenced in source order")
Local arrayLiteralDiagnostics:TCompilerDiagnostic[]
Local arrayLiteralC:String = TBlitzMaxCompiler.EmitRuntimeC(arrayLiterals, arrayLiteralDiagnostics)
Check(arrayLiteralDiagnostics.length = 0, "runtime backend emits supported array literals")
Check(Contains(arrayLiteralC, "bbArrayFromData(~qi~q, 3, (BBINT[]){bmx_tmp_t0, bmx_tmp_t1, bmx_tmp_t2})") And Contains(arrayLiteralC, "bbArrayFromData(~q$~q, 2, (BBSTRING[])") And Contains(arrayLiteralC, "bbArrayFromData(~q[]i~q, 2, (BBARRAY[])"), "runtime C uses typed compound data and the production array-copy ABI")
Check(Contains(arrayLiteralC, "= &bbEmptyArray;") And Not Contains(arrayLiteralC, "bbArrayFromData(~qi~q, 0"), "empty array literals use the canonical managed sentinel")
Check(Contains(arrayLiteralC, "((bmx_tmp_t0 = bcc2_mark(1)), ((bmx_tmp_t1 = bcc2_mark(2)), ((bmx_tmp_t2 = bcc2_mark(3)), bbArrayFromData"), "runtime C preserves left-to-right side-effect evaluation before copying literal data")

Local referenceArrayContext:TCompilerResult = TBlitzMaxCompiler.Compile("reference-array-context.bmx", "SuperStrict~nType TContextNode~nEnd Type~nFunction AcceptObjects(values:Object[])~nEnd Function~nLocal node:TContextNode = New TContextNode~nLocal value:Object = Null~nAcceptObjects([node, value])", resolver, TestOptions())
Local referenceArrayContextDiagnostics:TCompilerDiagnostic[]
Local referenceArrayContextC:String = TBlitzMaxCompiler.EmitRuntimeC(referenceArrayContext, referenceArrayContextDiagnostics)
Check(referenceArrayContext.Succeeded() And referenceArrayContextDiagnostics.length = 0, "mixed derived/Object array literals lower in Object[] call context")
Check(Contains(referenceArrayContextC, "bbArrayFromData(~q:Object~q, 2, (BBOBJECT[])") And Contains(referenceArrayContextC, "((BBOBJECT)(bmx_"), "runtime C emits Object compound storage and an explicit derived-element upcast")

Local whileEquality:TCompilerResult = TBlitzMaxCompiler.Compile("while-equality.bmx", "SuperStrict~nLocal left:Int~nLocal right:Int~nWhile left = right~nExit~nWend", resolver, TestOptions())
Local whileEqualityDiagnostics:TCompilerDiagnostic[]
Local whileEqualityC:String = TBlitzMaxCompiler.EmitRuntimeC(whileEquality, whileEqualityDiagnostics)
Check(whileEquality.Succeeded() And whileEqualityDiagnostics.length = 0 And Contains(whileEqualityC, "while (") And Not Contains(whileEqualityC, "while (("), "runtime C gives While conditions one syntactic parenthesis layer")

Local callableArrayNull:TCompilerResult = TBlitzMaxCompiler.Compile("callable-array-null.bmx", "SuperStrict~nFunction FormatFirst:String(value:Int)~nReturn ~qfirst~q~nEnd Function~nFunction FormatSecond:String(value:Int)~nReturn ~qsecond~q~nEnd Function~nLocal Callbacks:String(value:Int)[] = [FormatFirst, Null]~nCallbacks[1] = FormatSecond~nLocal Result:String = Callbacks[0](1) + Callbacks[1](2)", resolver, TestOptions())
Local callableArrayNullDump:String = TCompilerIrDumper.Dump(callableArrayNull.ir)
Check(callableArrayNull.Succeeded() And Contains(callableArrayNullDump, "array-literal String(Int)") And Contains(callableArrayNullDump, "callable-default String(Int)"), "callable array literals lower contextual Null elements as typed callable defaults")
Local callableArrayNullDiagnostics:TCompilerDiagnostic[]
Local callableArrayNullC:String = TBlitzMaxCompiler.EmitRuntimeC(callableArrayNull, callableArrayNullDiagnostics)
Check(callableArrayNullDiagnostics.length = 0 And Contains(callableArrayNullC, "brl_blitz_NullFunctionError") And Contains(callableArrayNullC, "bmx_fn0_FormatFirst") And Contains(callableArrayNullC, "bmx_fn1_FormatSecond"), "runtime C emits callable array literal sentinels, assignments, and invocation targets")

Local importedArray:TCompilerResult = TBlitzMaxCompiler.Compile("imported-array.bmx", "SuperStrict~nGlobal Arguments:String[] = AppArgs", resolver, TestOptions())
Check(importedArray.Succeeded() And importedArray.ir.externalGlobals.length = 1 And importedArray.ir.externalGlobals[0].semanticType = "String[]" And importedArray.ir.externalGlobals[0].abiName = "bbAppArgs", "imported managed Array Global ABI identity is retained in IR")
Local importedArrayDiagnostics:TCompilerDiagnostic[]
Local importedArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(importedArray, importedArrayDiagnostics)
Check(importedArrayDiagnostics.length = 0 And Not Contains(importedArrayC, "extern BBARRAY bbAppArgs;") And Contains(importedArrayC, "bbAppArgs"), "runtime C uses the dependency-header BBARRAY ABI")

Local importedObjectArraySource:String = "SuperStrict~nImport sample.contracts~nLocal Values:TImportedValue[] = New TImportedValue[2]~nLocal Parent:TImportedValue = CreateImportedValue()~nLocal Child:TImportedChild = CreateImportedChild()~nValues[0] = Parent~nValues[1] = Child~nLocal First:TImportedValue = Values[0]~nLocal Joined:TImportedValue[] = Values + Values~nLocal Count:Int = Joined.length"
Local importedObjectArray:TCompilerResult = TBlitzMaxCompiler.Compile("imported-object-array.bmx", importedObjectArraySource, resolver, TestOptions())
Check(importedObjectArray.Succeeded(), "imported Type arrays support allocation, base-compatible assignment, reads, concatenation and length")
Local importedObjectArrayDump:String = TCompilerIrDumper.Dump(importedObjectArray.ir)
Check(Contains(importedObjectArrayDump, "array-new TImportedValue encoding ~q:TImportedValue~q rank 1") And Contains(importedObjectArrayDump, "array-element TImportedValue rank 1") And Contains(importedObjectArrayDump, "array-concat TImportedValue encoding ~q:TImportedValue~q"), "imported object-array IR retains the source type tag and typed elements")
Local importedObjectArrayDiagnostics:TCompilerDiagnostic[]
Local importedObjectArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(importedObjectArray, importedObjectArrayDiagnostics)
Check(importedObjectArrayDiagnostics.length = 0 And Contains(importedObjectArrayC, "bbArrayNew1D(~q:TImportedValue~q, 2)") And Contains(importedObjectArrayC, "struct sample_contracts_TImportedValue_obj **)BBARRAYDATA(") And Contains(importedObjectArrayC, "bbArrayConcat(~q:TImportedValue~q"), "runtime C stores imported object pointers in traced managed arrays")

Local importedObjectArrayLiteral:TCompilerResult = TBlitzMaxCompiler.Compile("imported-object-array-literal.bmx", "SuperStrict~nImport sample.contracts~nLocal Values:TImportedValue[] = [CreateImportedValue(), CreateImportedChild()]~nLocal First:TImportedValue = Values[0]", resolver, TestOptions())
Check(importedObjectArrayLiteral.Succeeded(), "imported object array literals apply contextual derived-to-base reference conversions")
Local importedObjectArrayLiteralDiagnostics:TCompilerDiagnostic[]
Local importedObjectArrayLiteralC:String = TBlitzMaxCompiler.EmitRuntimeC(importedObjectArrayLiteral, importedObjectArrayLiteralDiagnostics)
Check(importedObjectArrayLiteralDiagnostics.length = 0 And Contains(importedObjectArrayLiteralC, "bbArrayFromData(~q:TImportedValue~q, 2, (struct sample_contracts_TImportedValue_obj *[])") And Contains(importedObjectArrayLiteralC, "sample_contracts_CreateImportedChild()"), "runtime C copies typed imported object references into traced literal arrays")

Local nativeArray:TCompilerResult = TBlitzMaxCompiler.Compile("native-array.bmx", "SuperStrict~nExtern~nFunction NativeArraySum:Int(values:Int[]) = ~qbcc2_native_array_sum~q~nGlobal NativeArray:Int[] = ~qbcc2_native_array~q~nEnd Extern~nLocal Values:Int[] = New Int[2]~nValues[0] = 20~nValues[1] = 22~nLocal Result:Int = NativeArraySum(Values)~nNativeArray = Values", resolver, TestOptions())
Check(nativeArray.Succeeded() And nativeArray.ir.externalFunctions.length = 1 And nativeArray.ir.externalFunctions[0].parameters[0].semanticType = "Int[]" And nativeArray.ir.externalGlobals.length = 1, "source Extern Array function and Global ABI lower successfully")
Local nativeArrayDiagnostics:TCompilerDiagnostic[]
Local nativeArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeArray, nativeArrayDiagnostics)
Check(nativeArrayDiagnostics.length = 0 And Contains(nativeArrayC, "extern BBINT bcc2_native_array_sum(BBARRAY bmx_ep0_values);") And Contains(nativeArrayC, "extern BBARRAY bcc2_native_array;"), "runtime C publishes exact source native Array ABI declarations")

Local simpleTypeSource:String = "SuperStrict~nType TSimple~nField a:Int~nField b:Int~nField c:Int~nFunction Create:TSimple(a:Int, b:Int, c:Int)~nLocal Value:TSimple = New TSimple~nValue.a = a~nValue.b = b~nValue.c = c~nReturn Value~nEnd Function~nMethod Sum:Int()~nReturn a + b + c~nEnd Method~nEnd Type~nLocal Empty:TSimple~nLocal Value:TSimple = TSimple.Create(20, 21, 1)~nLocal Total:Int = Value.Sum()~nLocal Different:Int = Value <> Empty~nIf Value~nIf Different~nIf Not Empty Then Total = Total + 1~nEnd If~nEnd If"
Local simpleType:TCompilerResult = TBlitzMaxCompiler.Compile("simple-type.bmx", simpleTypeSource, resolver, TestOptions())
Check(simpleType.Succeeded(), "simple Object-derived Type layout, allocation, fields, identity and truth lower successfully")
Check(simpleType.ir.classes.length = 1 And simpleType.ir.classes[0].fields.length = 3 And simpleType.ir.classes[0].functionSlots.length = 2 And Not simpleType.ir.classes[0].hasManagedFields, "typed IR owns one atomic class descriptor, its ordered fields, and appended Type-function/method slots")

Local binaryOperatorCall:TCompilerResult = TBlitzMaxCompiler.Compile("binary-operator-call.bmx", "SuperStrict~nType TJoinPath~nMethod Operator/:TJoinPath(part:String)~nReturn Self~nEnd Method~nEnd Type~nLocal base:TJoinPath=New TJoinPath~nLocal child:TJoinPath=base / ~qchild~q", resolver, TestOptions())
Local binaryOperatorCallDump:String = TCompilerIrDumper.Dump(binaryOperatorCall.ir)
Local binaryOperatorCallDiagnostics:TCompilerDiagnostic[]
Local binaryOperatorCallC:String = TBlitzMaxCompiler.EmitRuntimeC(binaryOperatorCall, binaryOperatorCallDiagnostics)
Check(binaryOperatorCall.Succeeded() And Contains(binaryOperatorCallDump, "call virtual") And Contains(binaryOperatorCallDump, "@fn0 / : TJoinPath"), "a resolved user-defined binary operator lowers as its typed virtual method call")
Check(binaryOperatorCallDiagnostics.length = 0 And Contains(binaryOperatorCallC, "->m_cf0__div("), "runtime C dispatches a user-defined binary operator through its readable ordinary class slot")

Local compoundOperatorCall:TCompilerResult = TBlitzMaxCompiler.Compile("compound-operator-call.bmx", "SuperStrict~nStruct SMutableAmount~nField value:Int~nMethod Operator :+:SMutableAmount(delta:Int)~nvalue :+ delta~nReturn Self~nEnd Method~nEnd Struct~nLocal amount:SMutableAmount~namount :+ 2", resolver, TestOptions())
Local compoundOperatorCallDump:String = TCompilerIrDumper.Dump(compoundOperatorCall.ir)
Local compoundOperatorCallDiagnostics:TCompilerDiagnostic[]
Local compoundOperatorCallC:String = TBlitzMaxCompiler.EmitRuntimeC(compoundOperatorCall, compoundOperatorCallDiagnostics)
Check(compoundOperatorCall.Succeeded() And Contains(compoundOperatorCallDump, "call struct-direct") And Contains(compoundOperatorCallDump, "@fn0 :+ : SMutableAmount"), "a resolved user-defined compound assignment lowers as its typed Struct method call")
Check(compoundOperatorCallDiagnostics.length = 0 And Contains(compoundOperatorCallC, "((&bmx_v0_amount), 2);") And Not Contains(compoundOperatorCallC, "bmx_v0_amount += 2"), "runtime C calls the mutating operator with an addressable Struct receiver instead of applying native compound assignment")

Local publishedCompoundOperator:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/compoundops.mod/compoundops.bmx", "SuperStrict~nModule acme.compoundops~nStruct SPublishedAmount~nField value:Int~nMethod Operator :+:SPublishedAmount(delta:Int)~nvalue :+ delta~nReturn Self~nEnd Method~nEnd Struct", resolver, TestOptions())
Local publishedCompoundOperatorInterfaceDiagnostics:TCompilerDiagnostic[]
Local publishedCompoundOperatorInterface:String = TBlitzMaxCompiler.EmitInterface(publishedCompoundOperator, publishedCompoundOperatorInterfaceDiagnostics)
resolver.AddInterface("acme.compoundops", "/sdk/mod/acme.mod/compoundops.mod/compoundops.release.test.x64.i", publishedCompoundOperatorInterface)
Local importedCompoundOperator:TCompilerResult = TBlitzMaxCompiler.Compile("imported-compound-operator-call.bmx", "SuperStrict~nImport acme.compoundops~nLocal amount:SPublishedAmount~namount :+ 3", resolver, TestOptions())
Local importedCompoundOperatorDump:String = TCompilerIrDumper.Dump(importedCompoundOperator.ir)
Local importedCompoundOperatorDiagnostics:TCompilerDiagnostic[]
Local importedCompoundOperatorC:String = TBlitzMaxCompiler.EmitRuntimeC(importedCompoundOperator, importedCompoundOperatorDiagnostics)
Check(publishedCompoundOperator.Succeeded() And publishedCompoundOperatorInterfaceDiagnostics.length = 0 And importedCompoundOperator.Succeeded() And Contains(importedCompoundOperatorDump, "call struct-direct"), "an imported Struct compound operator retains its published selected-call identity")
Check(importedCompoundOperatorDiagnostics.length = 0 And Contains(importedCompoundOperatorC, "SPublishedAmount") And Contains(importedCompoundOperatorC, "((&bmx_v0_amount), 3);") And Not Contains(importedCompoundOperatorC, "bmx_v0_amount += 3"), "a consumer calls the dependency-owned mutating operator ABI without reproducing native assignment")

Local assignmentOperatorCall:TCompilerResult = TBlitzMaxCompiler.Compile("assignment-operator-call.bmx", "SuperStrict~nType TMutableValue~nField value:Int~nMethod Operator :=:TMutableValue(nextValue:Int)~nvalue=nextValue~nReturn Self~nEnd Method~nEnd Type~nLocal current:TMutableValue=New TMutableValue~ncurrent=42", resolver, TestOptions())
Local assignmentOperatorCallDump:String = TCompilerIrDumper.Dump(assignmentOperatorCall.ir)
Local assignmentOperatorCallDiagnostics:TCompilerDiagnostic[]
Local assignmentOperatorCallC:String = TBlitzMaxCompiler.EmitRuntimeC(assignmentOperatorCall, assignmentOperatorCallDiagnostics)
Check(assignmentOperatorCall.Succeeded() And Contains(assignmentOperatorCallDump, "call virtual") And Contains(assignmentOperatorCallDump, "@fn0 := : TMutableValue"), "ordinary assignment selects and lowers a matching assignment-initialization operator")
Check(assignmentOperatorCallDiagnostics.length = 0 And Contains(assignmentOperatorCallC, "->m_cf0__assign(") And Not Contains(assignmentOperatorCallC, "bmx_v0_current = 42"), "runtime C calls the readable collision-free := slot instead of replacing the object reference")
Local directAssignmentOperatorSyntax:TCompilerResult = TBlitzMaxCompiler.Compile("direct-assignment-operator-syntax.bmx", "SuperStrict~nType TMutableValue~nMethod Operator :=:TMutableValue(nextValue:Int)~nReturn Self~nEnd Method~nEnd Type~nLocal current:TMutableValue=New TMutableValue~ncurrent := 42", resolver, TestOptions())
Check(Not directAssignmentOperatorSyntax.Succeeded() And HasSyntaxDiagnostic(directAssignmentOperatorSyntax, "BMX2053"), "explicit existing-value ':=' is rejected while ordinary '=' remains the source spelling for Operator := dispatch")

Local scalarXor:TCompilerResult = TBlitzMaxCompiler.Compile("scalar-xor.bmx", "SuperStrict~nLocal left:Int=40~nLocal right:Int=2~nLocal result:Int=left ~~ right", resolver, TestOptions())
Local scalarXorDiagnostics:TCompilerDiagnostic[]
Local scalarXorC:String = TBlitzMaxCompiler.EmitRuntimeC(scalarXor, scalarXorDiagnostics)
Check(scalarXor.Succeeded() And scalarXorDiagnostics.length = 0 And Contains(scalarXorC, "(bmx_v0_left ^ bmx_v1_right)"), "BlitzMax's binary tilde operator lowers to scalar C xor")
Local scalarPower:TCompilerResult = TBlitzMaxCompiler.Compile("scalar-power.bmx", "SuperStrict~nLocal base:Long=2~nLocal integerPower:Long=base^3~nLocal floatingPower:Double=2.0^3.0", resolver, TestOptions())
Local scalarPowerDiagnostics:TCompilerDiagnostic[]
Local scalarPowerC:String = TBlitzMaxCompiler.EmitRuntimeC(scalarPower, scalarPowerDiagnostics)
Check(scalarPower.Succeeded() And scalarPowerDiagnostics.length = 0 And Occurrences(scalarPowerC, "bbFloatPow(") = 2 And Contains(scalarPowerC, "((BBLONG)bbFloatPow(") And Contains(scalarPowerC, "((BBDOUBLE)bbFloatPow("), "BlitzMax exponentiation lowers through the runtime power helper and converts to the typed result")
Local simpleTypeDump:String = TCompilerIrDumper.Dump(simpleType.ir)
Check(Contains(simpleTypeDump, "class @cls0 TSimple:TSimple [atomic-fields]") And Contains(simpleTypeDump, "function-slot %cf0 @fn0 Create(Int, Int, Int) -> TSimple") And Contains(simpleTypeDump, "[class @cls0 slot %cf0]") And Contains(simpleTypeDump, "object-new @cls0") And Contains(simpleTypeDump, "field @cls0.%f0") And Contains(simpleTypeDump, "managed-default Object : TSimple"), "Type-function slots, object allocation, field access and sentinel defaults remain explicit in IR")
Check(Contains(simpleTypeDump, "call virtual @cls0.%cf1 @fn1 Sum") And Contains(simpleTypeDump, "[method receiver TSimple]") And Contains(simpleTypeDump, "symbol %self self : TSimple"), "virtual calls and implicit Self field receivers remain explicit in typed IR")
Local simpleTypeRuntimeDiagnostics:TCompilerDiagnostic[]
Local simpleTypeRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(simpleType, simpleTypeRuntimeDiagnostics)
Check(simpleTypeRuntimeDiagnostics.length = 0, "runtime backend emits a simple Type class descriptor and instance layout")
Check(Contains(simpleTypeRuntimeC, "struct BCC2_BBClass_cls0_TSimple") And Contains(simpleTypeRuntimeC, "struct bmx_cls0_TSimple_obj") And Contains(simpleTypeRuntimeC, "struct BCC2_BBClass_cls0_TSimple *clas;") And Contains(simpleTypeRuntimeC, "BBINT bmx_field_f2_c;"), "runtime C preserves class-pointer-first object layout and ordered fields")
Check(Contains(simpleTypeRuntimeC, "&bbObjectClass, bbObjectFree, (BBDebugScope *)&bmx_type_scope_cls0, sizeof(struct bmx_cls0_TSimple_obj)") And Contains(simpleTypeRuntimeC, "bbObjectAtomicNew((BBClass *)&bmx_class_cls0_TSimple)") And Contains(simpleTypeRuntimeC, "bbObjectRegisterType((BBCLASS)&bmx_class_cls0_TSimple);"), "descriptor inheritance, reflection identity, allocation and single registration use the brl.blitz object ABI")
Check(Contains(simpleTypeRuntimeC, "(*f_cf0_Create)(BBINT, BBINT, BBINT);") And Contains(simpleTypeRuntimeC, "bmx_fn0_Create") And Contains(simpleTypeRuntimeC, "bmx_class_cls0_TSimple ="), "runtime class descriptors append callable Type-function slots initialized with their direct ABI symbol")
Check(Contains(simpleTypeRuntimeC, "(*m_cf1_Sum)(struct bmx_cls0_TSimple_obj *);") And Contains(simpleTypeRuntimeC, "->clas->m_cf1_Sum(") And Contains(simpleTypeRuntimeC, "bmx_fn1_Sum(struct bmx_cls0_TSimple_obj * bmx_self_self)"), "runtime C emits receiver-first method ABI and virtual descriptor-slot calls")
Check(Contains(simpleTypeRuntimeC, "&bbNullObject") And Contains(simpleTypeRuntimeC, "bmx_ctor_cls0_TSimple") And Contains(simpleTypeRuntimeC, "bbObjectCtor((BBOBJECT)o);"), "object defaults and construction preserve the non-C-null sentinel contract")

Local reflectedMethodSource:String = "SuperStrict~nType TReflectedTest~nConst Label:String=~qfixture~q~nGlobal Shared:Int=7~nField state:Int~nField tagged:Int { first=~qone~q second=~qtwo,three~q }~nFunction Product:Int(left:Int,right:Int)~nReturn left*right~nEnd Function~nMethod Before() { before }~nstate=1~nEnd Method~nMethod Run() { test }~nstate:+1~nEnd Method~nMethod Step:Int(amount:Int) { tracked=~qyes~q }~nstate:+amount~nReturn state~nEnd Method~nEnd Type"
Local reflectedMethodCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("reflected-method.bmx", reflectedMethodSource, resolver, TestOptions())
Local reflectedMethodDump:String = TCompilerIrDumper.Dump(reflectedMethodCompilation.ir)
Local reflectedMethodDiagnostics:TCompilerDiagnostic[]
Local reflectedMethodC:String = TBlitzMaxCompiler.EmitRuntimeC(reflectedMethodCompilation, reflectedMethodDiagnostics)
Check(reflectedMethodCompilation.Succeeded() And reflectedMethodDiagnostics.length = 0, "reflected zero-argument Type methods lower and emit")
Check(Contains(reflectedMethodDump, "var constant %g") And Contains(reflectedMethodDump, "Label:String [class @cls0]") And Contains(reflectedMethodDump, "Shared:Int [class @cls0]"), "Type-static reflection ownership is explicit in deterministic typed IR")
Check(Contains(reflectedMethodC, "BBDEBUGDECL_FIELD, ~qstate~q, ~qi~q") And Contains(reflectedMethodC, "BBDEBUGDECL_FIELD, ~qtagged~q, ~qi{first=one second=two,three}~q") And Contains(reflectedMethodC, "BBDEBUGDECL_TYPEMETHOD, ~qBefore~q, ~q(){before=1}~q") And Contains(reflectedMethodC, "BBDEBUGDECL_TYPEMETHOD, ~qRun~q, ~q(){test=1}~q") And Contains(reflectedMethodC, "BBDEBUGDECL_TYPEMETHOD, ~qStep~q, ~q(i)i{tracked=yes}~q"), "Type debug scope publishes field and valued method metadata in the production reflection encoding without losing the implementation")
Check(Contains(reflectedMethodC, "bmx_fn1_Before_ReflectionWrapper(void **buf)") And Contains(reflectedMethodC, ".reflection_wrapper = bmx_fn2_Run_ReflectionWrapper"), "zero-argument Void methods publish callable reflection wrappers")
Check(Contains(reflectedMethodC, "static void bmx_fn3_Step_ReflectionWrapper(void **buf)") And Contains(Compact(reflectedMethodC), "*((BBINT*)(buf))=bmx_fn3_Step(") And Contains(reflectedMethodC, "sizeof(BBINT) + sizeof(void *) - 1") And Contains(reflectedMethodC, ".reflection_wrapper = bmx_fn3_Step_ReflectionWrapper"), "reflected methods with arguments and results use the production pointer-slot invocation buffer ABI")
Check(Contains(reflectedMethodC, "BBDEBUGDECL_CONST, ~qLabel~q, ~q$~q") And Contains(reflectedMethodC, "BBDEBUGDECL_GLOBAL, ~qShared~q, ~qi~q") And Contains(reflectedMethodC, "BBDEBUGDECL_TYPEFUNCTION, ~qProduct~q, ~q(i,i)i~q"), "Type constants, Globals and Functions are owned by the Type reflection scope")
Check(Contains(reflectedMethodC, "static void bmx_fn0_Product_ReflectionWrapper(void **buf)") And Contains(Compact(reflectedMethodC), "*((BBINT*)(buf))=bmx_fn0_Product(") And Contains(reflectedMethodC, ".reflection_wrapper = bmx_fn0_Product_ReflectionWrapper"), "reflected Type functions share the canonical return-and-argument buffer ABI without a receiver slot")

Local sourceObjectArraySource:String = "SuperStrict~nInterface IArrayItem~nEnd Interface~nType TArrayBase Implements IArrayItem~nField value:Int~nEnd Type~nType TArrayChild Extends TArrayBase~nEnd Type~nLocal Values:TArrayBase[] = New TArrayBase[2]~nValues[0] = New TArrayBase~nValues[1] = New TArrayChild~nLocal Literal:TArrayBase[] = [New TArrayBase, New TArrayChild]~nLocal First:TArrayBase = Values[0]~nLocal Interfaces:IArrayItem[] = New IArrayItem[1]~nInterfaces[0] = Values[1]~nLocal AsInterface:IArrayItem = Interfaces[0]~nLocal Objects:Object[] = New Object[1]~nObjects[0] = AsInterface~nLocal AsObject:Object = Objects[0]"
Local sourceObjectArray:TCompilerResult = TBlitzMaxCompiler.Compile("source-object-array.bmx", sourceObjectArraySource, resolver, TestOptions())
Check(sourceObjectArray.Succeeded(), "source Type, Interface and Object arrays lower with reference conversions")
Local sourceObjectArrayDump:String = TCompilerIrDumper.Dump(sourceObjectArray.ir)
Check(Contains(sourceObjectArrayDump, "array-new TArrayBase encoding ~q:TArrayBase~q rank 1") And Contains(sourceObjectArrayDump, "array-new IArrayItem encoding ~q:IArrayItem~q rank 1") And Contains(sourceObjectArrayDump, "array-new Object encoding ~q:Object~q rank 1"), "source managed-reference arrays retain production source-name tags")
Local sourceObjectArrayDiagnostics:TCompilerDiagnostic[]
Local sourceObjectArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(sourceObjectArray, sourceObjectArrayDiagnostics)
Check(sourceObjectArrayDiagnostics.length = 0 And Contains(sourceObjectArrayC, "struct bmx_cls0_TArrayBase_obj **)BBARRAYDATA(") And Contains(sourceObjectArrayC, "BBOBJECT*)BBARRAYDATA(") And Contains(sourceObjectArrayC, "bbArrayNew1D(~q:IArrayItem~q, 1)") And Contains(sourceObjectArrayC, "bbArrayNew1D(~q:Object~q, 1)"), "runtime C uses typed source object pointers and BBOBJECT Interface/Object cells")
Check(Contains(sourceObjectArrayC, "bbArrayFromData(~q:TArrayBase~q, 2, (struct bmx_cls0_TArrayBase_obj *[])") , "source object array literals use typed traced storage")
Local explicitObjectArrayCastSource:String = "SuperStrict~nType TArrayCastItem~nEnd Type~nLocal boxed:Object~nLocal items:TArrayCastItem[] = TArrayCastItem[](boxed)~nFor Local item:TArrayCastItem = EachIn items~nNext"
Local explicitObjectArrayCast:TCompilerResult = TBlitzMaxCompiler.Compile("explicit-object-array-cast.bmx", explicitObjectArrayCastSource, resolver, TestOptions())
Local explicitObjectArrayCastDump:String = TCompilerIrDumper.Dump(explicitObjectArrayCast.ir)
Local explicitObjectArrayCastDiagnostics:TCompilerDiagnostic[]
Local explicitObjectArrayCastC:String = TBlitzMaxCompiler.EmitRuntimeC(explicitObjectArrayCast, explicitObjectArrayCastDiagnostics)
Check(explicitObjectArrayCast.Succeeded() And explicitObjectArrayCastDiagnostics.length = 0, "explicit Object-to-Array conversion lowers successfully")
Check(Contains(explicitObjectArrayCastDump, "convert explicit explicit array-cast encoding ~q:TArrayCastItem~q"), "typed IR retains the checked Array target encoding before backend emission")
Check(Contains(explicitObjectArrayCastC, "bbArrayCastFromObject((BBOBJECT)") And Contains(explicitObjectArrayCastC, "~q:TArrayCastItem~q") And Not Contains(explicitObjectArrayCastC, "((BBARRAY)(bmx_v0_boxed))"), "runtime Object-to-Array conversion canonicalizes Null and validates the target element category")
Local debugManagedConversionSource:String = "SuperStrict~nLocal boxed:Object~nLocal items:Int[] = Int[](boxed)~nLocal count:Int = items.length~nIf items Then count :+ 1~nFor Local item:Int = EachIn items~ncount :+ item~nNext~nLocal text:String = String(boxed)~nIf text Then count :+ text.length"
Local debugManagedConversionOptions:TCompilerOptions = DebugTestOptions()
debugManagedConversionOptions.debugInstrumentation = True
Local debugManagedConversion:TCompilerResult = TBlitzMaxCompiler.Compile("debug-managed-conversion.bmx", debugManagedConversionSource, resolver, debugManagedConversionOptions)
Local debugManagedConversionDiagnostics:TCompilerDiagnostic[]
Local debugManagedConversionC:String = TBlitzMaxCompiler.EmitRuntimeC(debugManagedConversion, debugManagedConversionDiagnostics)
Check(debugManagedConversion.Succeeded() And debugManagedConversionDiagnostics.length = 0, "debug managed conversions lower successfully")
Check(Contains(debugManagedConversionC, "bbArrayCastFromObject((BBOBJECT)") And Occurrences(debugManagedConversionC, "bbManagedArrayAssert((BBARRAY)") >= 3, "debug Array truth, length, and EachIn validate the managed sentinel family before use")
Check(Contains(debugManagedConversionC, "bbObjectStringcast((BBOBJECT)") And Occurrences(debugManagedConversionC, "bbManagedStringAssert((BBSTRING)") >= 2, "debug String truth and length validate the managed sentinel family before use")
Local eachInAdaptationSource:String = "SuperStrict~nType TDefaultProtocolIterator~nMethod HasNext:Int(step:Int=1)~nReturn False~nEnd Method~nMethod NextObject:Object(index:Int=0)~nReturn Null~nEnd Method~nEnd Type~nType TDefaultProtocolValues~nMethod ObjectEnumerator:TDefaultProtocolIterator(seed:Int=0)~nReturn New TDefaultProtocolIterator~nEnd Method~nEnd Type~nLocal objects:Object[]=[~qtext~q]~nFor Local text:String=EachIn objects~nNext~nLocal values:TDefaultProtocolValues=New TDefaultProtocolValues~nFor Local text:String=EachIn values~nNext~nFor Local number:Int=EachIn values~nNext"
Local eachInAdaptation:TCompilerResult = TBlitzMaxCompiler.Compile("eachin-adaptation.bmx", eachInAdaptationSource, resolver, TestOptions())
Check(eachInAdaptation.Succeeded(), "Array and ObjectEnumerator EachIn lower Object-to-String/numeric adaptation and defaulted protocol parameters")
Local eachInAdaptationDiagnostics:TCompilerDiagnostic[]
Local eachInAdaptationC:String = TBlitzMaxCompiler.EmitRuntimeC(eachInAdaptation, eachInAdaptationDiagnostics)
Check(eachInAdaptationDiagnostics.length = 0 And Contains(eachInAdaptationC, "bbObjectIsString") And Contains(eachInAdaptationC, "bbObjectStringcast") And Contains(eachInAdaptationC, "bbObjectToFieldOffset") And Contains(eachInAdaptationC, ", 0)") And Contains(eachInAdaptationC, ", 1)"), "runtime C emits production legacy adaptation and every retained protocol default")

Local interfaceSource:String = "SuperStrict~nInterface IReadable~nMethod Read:Int(delta:Int)~nEnd Interface~nInterface INamed~nMethod Name:String()~nEnd Interface~nType TItem Implements IReadable, INamed~nField base:Int~nMethod Read:Int(delta:Int)~nReturn base + delta~nEnd Method~nMethod Name:String()~nReturn ~qitem~q~nEnd Method~nEnd Type~nType TSpecial Extends TItem~nMethod Read:Int(delta:Int) Override~nReturn base + delta + 1~nEnd Method~nEnd Type~nLocal item:TItem = New TItem~nitem.base = 40~nLocal readable:IReadable = item~nLocal named:INamed = item~nLocal result:Int = readable.Read(2)~nLocal label:String = named.Name()~nLocal same:Int = readable = named~nLocal special:TSpecial = New TSpecial~nspecial.base = 40~nLocal specialReadable:IReadable = special~nLocal specialResult:Int = specialReadable.Read(2)~nIf readable Then result = result + 1"
Local interfaceDispatch:TCompilerResult = TBlitzMaxCompiler.Compile("interface-dispatch.bmx", interfaceSource, resolver, TestOptions())
Check(interfaceDispatch.Succeeded(), "source Interface conversion, identity, truth and dispatch lower successfully")
Check(interfaceDispatch.ir.interfaces.length = 2 And interfaceDispatch.ir.classes[0].interfaceImplementations.length = 2, "typed IR owns two independent Interface layouts for one implementing class")
Local interfaceDump:String = TCompilerIrDumper.Dump(interfaceDispatch.ir)
Check(Contains(interfaceDump, "interface @if0 IReadable:IReadable") And Contains(interfaceDump, "method %im0 Read(Int) -> Int") And Contains(interfaceDump, "interface @if1 INamed:INamed") And Contains(interfaceDump, "method %im0 Name() -> String"), "Interface declarations and ordered method slots are explicit in typed IR")
Check(Contains(interfaceDump, "implements @if0") And Contains(interfaceDump, "slot %im0 @fn0 receiver @cls0") And Contains(interfaceDump, "implements @if1") And Contains(interfaceDump, "slot %im0 @fn1 receiver @cls0"), "each Interface table maps its own slot to the concrete implementation")
Check(Contains(interfaceDump, "class @cls1 TSpecial:TSpecial extends @cls0") And Contains(interfaceDump, "slot %im0 @fn2 receiver @cls1") And Contains(interfaceDump, "slot %im0 @fn1 receiver @cls0"), "a derived class rebuilds inherited Interface tables with local overrides and inherited implementations")
Check(Contains(interfaceDump, "interface-cast @if0") And Contains(interfaceDump, "interface-cast @if1") And Contains(interfaceDump, "call interface @if0.%im0") And Contains(interfaceDump, "call interface @if1.%im0"), "Interface conversion and dispatch remain distinct typed IR operations")
Local interfaceDiagnostics:TCompilerDiagnostic[]
Local interfaceC:String = TBlitzMaxCompiler.EmitRuntimeC(interfaceDispatch, interfaceDiagnostics)
Check(interfaceDiagnostics.length = 0, "runtime backend emits source Interface descriptors and dispatch tables")
Check(Contains(interfaceC, "struct BCC2_InterfaceVdef_cls0") And Contains(interfaceC, "interface_if0") And Contains(interfaceC, "interface_if1") And Contains(interfaceC, "offsetof(struct BCC2_InterfaceVdef_cls0, interface_if0)") And Contains(interfaceC, "offsetof(struct BCC2_InterfaceVdef_cls0, interface_if1)"), "one class vdef retains separate offsets for both Interface method tables")
Check(Contains(interfaceC, "bbInterfaceDowncast((BBOBJECT)") And Contains(interfaceC, "bbObjectInterface((BBOBJECT)") And Contains(interfaceC, "bbObjectRegisterInterface((BBInterface *)&bmx_interface_if0_IReadable)"), "runtime C uses the production Interface conversion, dispatch and registration APIs")
Check(Contains(interfaceC, "BBDEBUGSCOPE_USERTYPE, ~qIReadable~q") And Contains(interfaceC, ".debug_scope = (BBDebugScope *)&bmx_interface_if0_IReadable_debug_scope"), "source Interface descriptors publish non-null runtime reflection identities")
Check(Contains(interfaceC, "&bmx_interface_table_cls0") And Contains(interfaceC, "((BBOBJECT)&bbNullObject)"), "the class descriptor owns its Interface table and Interface defaults use the managed object sentinel")
Local interfaceHeaderDiagnostics:TCompilerDiagnostic[]
Local interfaceHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(interfaceDispatch, interfaceHeaderDiagnostics)
Check(interfaceHeaderDiagnostics.length = 0 And Contains(interfaceHeader, "struct BCC2_InterfaceMethods_if0_IReadable") And Contains(interfaceHeader, "extern const struct BBInterface bmx_interface_if1_INamed;"), "runtime headers publish Interface method and descriptor ABI records")

Local inheritedGenericArrayInterfaceSource:String = "SuperStrict~nInterface IArrayTransform<T>~nMethod Transform:T(value:T)~nEnd Interface~nType TArrayTransformBase<T> Implements IArrayTransform<T>~nMethod Transform:T(value:T)~nReturn value~nEnd Method~nEnd Type~nType TArrayTransformDerived Extends TArrayTransformBase<Int[]>~nMethod Transform:Int[](value:Int[]) Override~nReturn value~nEnd Method~nEnd Type~nLocal owner:TArrayTransformDerived=New TArrayTransformDerived~nLocal contract:IArrayTransform<Int[]>=owner~nLocal result:Int[]=contract.Transform([41])"
Local inheritedGenericArrayInterface:TCompilerResult = TBlitzMaxCompiler.Compile("inherited-generic-array-interface.bmx", inheritedGenericArrayInterfaceSource, resolver, TestOptions())
Check(inheritedGenericArrayInterface.Succeeded(), "an ordinary derived Type rebuilds an inherited generic Interface table with canonical Array signatures: " + CompilerDiagnosticSummary(inheritedGenericArrayInterface))

Local mixedGenericInterfaceSource:String = "SuperStrict~nImport brl.blitz~nInterface ITestIterator<T>~nMethod Current:T()~nMethod MoveNext:Int()~nEnd Interface~nInterface ITestCloseableIterator<T> Extends ITestIterator<T>, ICloseable~nEnd Interface~nType TTestCloseableIterator Implements ITestCloseableIterator<Int>~nField current:Int~nField closed:Int~nMethod Current:Int()~nReturn current~nEnd Method~nMethod MoveNext:Int()~ncurrent:+1~nReturn current<2~nEnd Method~nMethod Close()~nclosed=True~nEnd Method~nEnd Type~nLocal concrete:TTestCloseableIterator=New TTestCloseableIterator~nLocal combined:ITestCloseableIterator<Int>=concrete~ncombined.Close()~nLocal closeable:ICloseable=combined"
Local mixedGenericInterface:TCompilerResult = TBlitzMaxCompiler.Compile("mixed-generic-interface-inheritance.bmx", mixedGenericInterfaceSource, resolver, TestOptions())
Local mixedCombinedInterface:TCompilerIrInterface
For Local candidate:TCompilerIrInterface = EachIn mixedGenericInterface.ir.interfaces
	If candidate.name = "ITestCloseableIterator" Then mixedCombinedInterface = candidate; Exit
Next
Local mixedGenericInterfaceDiagnostics:TCompilerDiagnostic[]
Local mixedGenericInterfaceC:String = TBlitzMaxCompiler.EmitRuntimeC(mixedGenericInterface, mixedGenericInterfaceDiagnostics)
Check(mixedGenericInterface.Succeeded() And mixedGenericInterfaceDiagnostics.length = 0, "a generic Interface can combine a generic parent with an ordinary imported Interface: " + CompilerDiagnosticSummary(mixedGenericInterface))
Check(mixedCombinedInterface And mixedCombinedInterface.baseInterfaceIds.length = 2, "closed generic Interface IR retains both generic and ordinary parent descriptor identities")
Check(Contains(mixedGenericInterfaceC, "brl_blitz_ICloseable_ifc") And Contains(mixedGenericInterfaceC, "->m_Close("), "inherited ordinary Interface calls retain their independently published dispatch ABI")

Local staticArrayCallableBoundarySource:String = "SuperStrict~nInterface IFixedReader~nMethod Read:Int(StaticArray values:Int[4])~nEnd Interface~nType TFixedReader Implements IFixedReader~nField seed:Int~nMethod New(StaticArray values:Int[4])~nseed=values[0]~nEnd Method~nMethod Read:Int(StaticArray values:Int[4])~nReturn seed+values.length~nEnd Method~nEnd Type~nStruct SFixedSummary~nField total:Int~nMethod New(StaticArray values:Int[4])~ntotal=values[0]+values.length~nEnd Method~nEnd Struct~nLocal StaticArray values:Int[4]~nvalues[0]=38~nLocal concrete:TFixedReader=New TFixedReader(values)~nLocal reader:IFixedReader=concrete~nLocal summary:SFixedSummary=New SFixedSummary(values)~nLocal result:Int=reader.Read(values)+summary.total"
Local staticArrayCallableBoundary:TCompilerResult = TBlitzMaxCompiler.Compile("static-array-callable-boundary.bmx", staticArrayCallableBoundarySource, resolver, TestOptions())
Local staticArrayCallableBoundaryDump:String = TCompilerIrDumper.Dump(staticArrayCallableBoundary.ir)
Check(staticArrayCallableBoundary.Succeeded() And Contains(staticArrayCallableBoundaryDump, "method %im0 Read(StaticArray Int[4]) -> Int") And Contains(staticArrayCallableBoundaryDump, "New(%p0 values:StaticArray Int[4])") And Contains(staticArrayCallableBoundaryDump, "call interface @if0.%im0"), "StaticArray shape crosses Type construction, Struct construction and Interface dispatch in typed IR")
Local staticArrayCallableBoundaryDiagnostics:TCompilerDiagnostic[]
Local staticArrayCallableBoundaryC:String = TBlitzMaxCompiler.EmitRuntimeC(staticArrayCallableBoundary, staticArrayCallableBoundaryDiagnostics)
Check(staticArrayCallableBoundaryDiagnostics.length = 0 And Contains(staticArrayCallableBoundaryC, "(*m_im0_Read)(BBOBJECT, BBINT *);") And Contains(staticArrayCallableBoundaryC, "BBINT bmx_p0_values[4]") And Contains(staticArrayCallableBoundaryC, "bmx_v0_values"), "runtime C uses one pointer-compatible StaticArray ABI across constructors and Interface slots")
Local staticArrayCallableBoundaryHeaderDiagnostics:TCompilerDiagnostic[]
Local staticArrayCallableBoundaryHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(staticArrayCallableBoundary, staticArrayCallableBoundaryHeaderDiagnostics)
Check(staticArrayCallableBoundaryHeaderDiagnostics.length = 0 And Contains(staticArrayCallableBoundaryHeader, "(*m_im0_Read)(BBOBJECT, BBINT *);"), "runtime headers publish the same StaticArray Interface slot ABI")

Local callableInterfaceSource:String = "SuperStrict~nFunction InterfaceAdd:Int(left:Int,right:Int) { nomangle }~nReturn left + right~nEnd Function~nInterface ICallableBase~nMethod Apply:Int(left:Int,right:Int,operation:Int(a:Int,b:Int))~nEnd Interface~nInterface ICallableChild Extends ICallableBase~nMethod Offset:Int()~nEnd Interface~nType TCallableInterface Implements ICallableChild~nMethod Apply:Int(left:Int,right:Int,operation:Int(a:Int,b:Int))~nReturn operation(left,right)~nEnd Method~nMethod Offset:Int()~nReturn 0~nEnd Method~nEnd Type~nType TCallableInterfaceOverride Extends TCallableInterface~nMethod Apply:Int(left:Int,right:Int,operation:Int(a:Int,b:Int)) Override~nReturn operation(left,right) + 1~nEnd Method~nEnd Type~nLocal child:ICallableChild = New TCallableInterface~nLocal base:ICallableBase = child~nLocal overridden:ICallableBase = New TCallableInterfaceOverride~nLocal result:Int = base.Apply(20,22,InterfaceAdd)~nLocal overrideResult:Int = overridden.Apply(20,21,InterfaceAdd)"
Local callableInterface:TCompilerResult = TBlitzMaxCompiler.Compile("callable-interface.bmx", callableInterfaceSource, resolver, TestOptions())
Check(callableInterface.Succeeded(), "source Interface methods accept ordinary-C-compatible callable parameters")
Local callableInterfaceDump:String = TCompilerIrDumper.Dump(callableInterface.ir)
Check(Contains(callableInterfaceDump, "Apply(Int, Int, Int(Int, Int)) -> Int") And Contains(callableInterfaceDump, "call interface @if0.%im0") And Contains(callableInterfaceDump, "slot %im0 @fn") And Contains(callableInterfaceDump, "callable source @fn0 InterfaceAdd"), "callable Interface signatures, implementations, dispatch, and targets remain explicit in typed IR")
Local callableInterfaceDiagnostics:TCompilerDiagnostic[]
Local callableInterfaceC:String = TBlitzMaxCompiler.EmitRuntimeC(callableInterface, callableInterfaceDiagnostics)
Check(callableInterfaceDiagnostics.length = 0 And Contains(callableInterfaceC, "(*m_im0_Apply)(BBOBJECT, BBINT, BBINT, BBINT (*)(BBINT, BBINT));") And Contains(callableInterfaceC, "(BBINT (*)(BBOBJECT, BBINT, BBINT, BBINT (*)(BBINT, BBINT)))bmx_fn") And Contains(callableInterfaceC, "_bb_main_InterfaceAdd)"), "Interface method tables, implementation casts, and calls preserve the exact callable ABI")
Local callableInterfaceHeaderDiagnostics:TCompilerDiagnostic[]
Local callableInterfaceHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(callableInterface, callableInterfaceHeaderDiagnostics)
Check(callableInterfaceHeaderDiagnostics.length = 0 And Contains(callableInterfaceHeader, "(*m_im0_Apply)(BBOBJECT, BBINT, BBINT, BBINT (*)(BBINT, BBINT));"), "runtime headers publish the exact callable Interface slot declaration")

Local structCallableBoundariesSource:String = "SuperStrict~nStruct SCallableCell~nField value:Int~nEnd Struct~nFunction SumCallableCells:Int(StaticArray cells:SCallableCell[2])~nReturn cells[0].value+cells[1].value~nEnd Function~nGlobal ActiveCells:Int(StaticArray cells:SCallableCell[2])=SumCallableCells~nType TStructCallbackHolder~nField callback:Int(StaticArray cells:SCallableCell[2])=SumCallableCells~nEnd Type~nType TStructCallbackBase~nMethod Apply:Int(callback:Int(StaticArray cells:SCallableCell[2]),StaticArray cells:SCallableCell[2])~nReturn callback(cells)~nEnd Method~nEnd Type~nType TStructCallbackDerived Extends TStructCallbackBase~nMethod Apply:Int(callback:Int(StaticArray cells:SCallableCell[2]),StaticArray cells:SCallableCell[2]) Override~nReturn callback(cells)+1~nEnd Method~nEnd Type~nInterface IStructCallback~nMethod Apply:Int(callback:Int(StaticArray cells:SCallableCell[2]),StaticArray cells:SCallableCell[2])~nEnd Interface~nType TStructCallbackInterface Implements IStructCallback~nMethod Apply:Int(callback:Int(StaticArray cells:SCallableCell[2]),StaticArray cells:SCallableCell[2])~nReturn callback(cells)~nEnd Method~nEnd Type~nLocal StaticArray cells:SCallableCell[2]~ncells[0].value=20~ncells[1].value=22~nLocal holder:TStructCallbackHolder=New TStructCallbackHolder~nLocal base:TStructCallbackBase=New TStructCallbackDerived~nLocal iface:IStructCallback=New TStructCallbackInterface~nLocal result:Int=ActiveCells(cells)+holder.callback(cells)+base.Apply(SumCallableCells,cells)+iface.Apply(SumCallableCells,cells)"
Local structCallableBoundaries:TCompilerResult = TBlitzMaxCompiler.Compile("struct-callable-boundaries.bmx", structCallableBoundariesSource, resolver, TestOptions())
Check(structCallableBoundaries.Succeeded(), "Struct StaticArrays flow through callable Globals, fields, virtual methods, and Interface slots")
Local structCallableBoundariesDump:String = TCompilerIrDumper.Dump(structCallableBoundaries.ir)
Check(Contains(structCallableBoundariesDump, "ActiveCells:Int(StaticArray SCallableCell[2]) [callable Int(StaticArray SCallableCell[2])]") And Contains(structCallableBoundariesDump, "field %f0 callback:Int(StaticArray SCallableCell[2]) [callable Int(StaticArray SCallableCell[2])]") And Contains(structCallableBoundariesDump, "Apply(Int(StaticArray SCallableCell[2]), StaticArray SCallableCell[2]) -> Int") And Contains(structCallableBoundariesDump, "call interface @if0.%im0"), "typed IR retains the Struct element identity and extent through every callable storage and dispatch boundary")
Local structCallableBoundariesDiagnostics:TCompilerDiagnostic[]
Local structCallableBoundariesC:String = TBlitzMaxCompiler.EmitRuntimeC(structCallableBoundaries, structCallableBoundariesDiagnostics)
Check(structCallableBoundariesDiagnostics.length = 0 And Contains(structCallableBoundariesC, "(*bmx_global_g0_ActiveCells)(struct bmx_struct_st0_SCallableCell *);") And Contains(structCallableBoundariesC, "(*bmx_field_f0_callback)(struct bmx_struct_st0_SCallableCell *);") And Contains(structCallableBoundariesC, "(*m_cf0_Apply)(struct bmx_cls1_TStructCallbackBase_obj *, BBINT (*)(struct bmx_struct_st0_SCallableCell *), struct bmx_struct_st0_SCallableCell *);") And Contains(structCallableBoundariesC, "(*m_im0_Apply)(BBOBJECT, BBINT (*)(struct bmx_struct_st0_SCallableCell *), struct bmx_struct_st0_SCallableCell *);"), "runtime C uses one canonical Struct-pointer function signature for Globals, fields, virtual slots, and Interface tables")

Local importedInterfaceSource:String = "SuperStrict~nType TCloseable Implements ICloseable~nField closed:Int~nMethod Close()~nclosed = 1~nEnd Method~nEnd Type~nLocal item:TCloseable = New TCloseable~nLocal closeable:ICloseable = item~ncloseable.Close()~nLocal result:Int = item.closed"
Local importedInterface:TCompilerResult = TBlitzMaxCompiler.Compile("imported-interface.bmx", importedInterfaceSource, resolver, TestOptions())
Check(importedInterface.Succeeded(), "a source Type can implement and dispatch through an imported Interface")
Check(importedInterface.ir.interfaces.length = 1 And importedInterface.ir.interfaces[0].isImported And importedInterface.ir.interfaces[0].abiName = "brl_blitz_ICloseable" And importedInterface.ir.interfaces[0].originModule = "brl.blitz", "imported Interface IR retains external descriptor ownership and module provenance")
Local importedInterfaceDump:String = TCompilerIrDumper.Dump(importedInterface.ir)
Check(Contains(importedInterfaceDump, "interface @if0 ICloseable:ICloseable [imported abi brl_blitz_ICloseable from brl.blitz]") And Contains(importedInterfaceDump, "method %im0 Close() -> Void") And Contains(importedInterfaceDump, "call interface @if0.%im0"), "imported Interface layout and calls remain explicit in typed IR")
Local importedInterfaceDiagnostics:TCompilerDiagnostic[]
Local importedInterfaceC:String = TBlitzMaxCompiler.EmitRuntimeC(importedInterface, importedInterfaceDiagnostics)
Check(importedInterfaceDiagnostics.length = 0, "runtime backend emits imported Interface implementation and dispatch")
Check(Not Contains(importedInterfaceC, "extern const struct BBInterface brl_blitz_ICloseable_ifc;") And Contains(importedInterfaceC, "brl_blitz_ICloseable_ifc"), "runtime C references the Interface descriptor declared by the dependency header")
Check(Not Contains(importedInterfaceC, "const struct BBInterface brl_blitz_ICloseable_ifc =") And Not Contains(importedInterfaceC, "bbObjectRegisterInterface((BBInterface *)&brl_blitz_ICloseable_ifc)"), "runtime C neither defines nor registers an imported Interface descriptor")
Check(Contains(importedInterfaceC, "struct brl_blitz_ICloseable_methods interface_if0;") And Contains(importedInterfaceC, "->m_Close(") And Not Contains(importedInterfaceC, "struct brl_blitz_ICloseable_methods {"), "implementors and consumers use the imported Interface method-table layout published by BRL.Blitz")
Local importedInterfaceHeaderDiagnostics:TCompilerDiagnostic[]
Local importedInterfaceHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(importedInterface, importedInterfaceHeaderDiagnostics)
Check(importedInterfaceHeaderDiagnostics.length = 0 And Not Contains(importedInterfaceHeader, "BCC2_InterfaceMethods_if0_ICloseable") And Contains(importedInterfaceHeader, "blitz.bmx.release.test.x64.h"), "runtime headers rely on the dependency header rather than republishing imported Interface internals")

resolver.AddInterface("closeable.chain", "sdk/closeable.chain.i", "superstrict~nimport brl.blitz~nTIO^Object@ICloseable{~n}=~qcloseable_chain_TIO~q~nTStream^TIO{~n}=~qcloseable_chain_TStream~q")
Local importedUsingBase:TCompilerResult = TBlitzMaxCompiler.Compile("imported-using-base.bmx", "SuperStrict~nImport closeable.chain~nLocal candidate:TStream=Null~nUsing~nLocal stream:TStream=candidate~nDo~nEnd Using", resolver, TestOptions())
Local importedUsingBaseDiagnostics:TCompilerDiagnostic[]
Local importedUsingBaseC:String = TBlitzMaxCompiler.EmitRuntimeC(importedUsingBase, importedUsingBaseDiagnostics)
Check(importedUsingBase.Succeeded() And importedUsingBaseDiagnostics.length = 0 And Contains(importedUsingBaseC, "->m_Close("), "Using follows an imported Type base chain to its inherited ICloseable contract")

Local usingSource:String = "SuperStrict~nType TUsingResource Implements ICloseable~nField sequence:Int~nMethod Close()~nsequence:+1~nEnd Method~nEnd Type~nLocal first:TUsingResource=New TUsingResource~nLocal second:TUsingResource=New TUsingResource~nUsing~nLocal outer:TUsingResource=first~nLocal inner:TUsingResource=second~nDo~nouter.sequence=10~ninner.sequence=20~nWhile True~nExit~nWend~nEnd Using"
Local usingResult:TCompilerResult = TBlitzMaxCompiler.Compile("using.bmx", usingSource, resolver, TestOptions())
Local usingDump:String = TCompilerIrDumper.Dump(usingResult.ir)
Local usingDiagnostics:TCompilerDiagnostic[]
Local usingC:String = TBlitzMaxCompiler.EmitRuntimeC(usingResult, usingDiagnostics)
Check(usingResult.Succeeded() And Contains(usingDump, "using @using0") And Occurrences(usingDump, "resource %") = 2 And Occurrences(usingDump, "call interface @if0.%im0") = 2, "Using resources retain explicit initialization, imported ICloseable dispatch, and cleanup ownership in typed IR")
Check(usingDiagnostics.length = 0 And Contains(usingC, "bmx_using0_exception") And Contains(usingC, "bmx_using0_failed") And Occurrences(usingC, "bbExTry {") = 3 And Occurrences(usingC, "->m_Close(") = 2 And Contains(usingC, " * volatile bmx_") And Contains(usingC, "bbExThrow((BBObject *)bmx_using0_exception)"), "runtime C protects the body, keeps resources defined across longjmp, closes each initialized resource, and preserves the original exception")
Local debugUsingOptions:TCompilerOptions = DebugTestOptions()
debugUsingOptions.debugInstrumentation = True
Local debugUsingResult:TCompilerResult = TBlitzMaxCompiler.Compile("using-debug.bmx", usingSource, resolver, debugUsingOptions)
Local debugUsingDiagnostics:TCompilerDiagnostic[]
Local debugUsingC:String = TBlitzMaxCompiler.EmitRuntimeC(debugUsingResult, debugUsingDiagnostics)
Check(debugUsingResult.Succeeded() And debugUsingDiagnostics.length = 0 And Occurrences(debugUsingC, "bbExTry {") = 3 And Occurrences(debugUsingC, "bbOnDebugPushExState();") = 3 And Occurrences(debugUsingC, "bbOnDebugPopExState();") = 6, "debug Using balances the protected body and every suppressed Close exception frame")
Local usingReturn:TCompilerResult = TBlitzMaxCompiler.Compile("using-return.bmx", "SuperStrict~nType TReturningResource Implements ICloseable~nMethod Close()~nEnd Method~nEnd Type~nFunction Read:Int()~nUsing~nLocal resource:TReturningResource=New TReturningResource~nDo~nReturn 1~nEnd Using~nEnd Function", resolver, TestOptions())
Local usingReturnDiagnostics:TCompilerDiagnostic[]
Local usingReturnC:String = TBlitzMaxCompiler.EmitRuntimeC(usingReturn, usingReturnDiagnostics)
Check(usingReturn.Succeeded() And usingReturnDiagnostics.length = 0 And Contains(TCompilerIrDumper.Dump(usingReturn.ir), "leave-exception-frame using 1"), "Return inside Using retains an explicit resource-cleanup edge in typed IR")
Check(Contains(usingReturnC, "BBINT bmx_cleanup_return_0 = 1;") And Contains(usingReturnC, "bbExLeave();") And Contains(usingReturnC, "->m_Close(") And Contains(usingReturnC, "return bmx_cleanup_return_0;"), "runtime C preserves the return value, leaves the Using exception frame, closes the resource, and then returns")
Local debugUsingReturn:TCompilerResult = TBlitzMaxCompiler.Compile("using-return-debug.bmx", "SuperStrict~nType TReturningResource Implements ICloseable~nMethod Close()~nEnd Method~nEnd Type~nFunction Read:Int()~nUsing~nLocal resource:TReturningResource=New TReturningResource~nDo~nReturn 1~nEnd Using~nEnd Function", resolver, debugUsingOptions)
Local debugUsingReturnDiagnostics:TCompilerDiagnostic[]
Local debugUsingReturnC:String = TBlitzMaxCompiler.EmitRuntimeC(debugUsingReturn, debugUsingReturnDiagnostics)
Check(debugUsingReturn.Succeeded() And debugUsingReturnDiagnostics.length = 0 And Occurrences(debugUsingReturnC, "bbOnDebugPushExState();") = 3 And Occurrences(debugUsingReturnC, "bbOnDebugPopExState();") = 7 And AppearsBefore(debugUsingReturnC, "bbExLeave();", "return bmx_cleanup_return_0;"), "debug Return across Using leaves and restores each exception frame before returning")
Local usingOuterExit:TCompilerResult = TBlitzMaxCompiler.Compile("using-outer-exit.bmx", "SuperStrict~nType TExitResource Implements ICloseable~nMethod Close()~nEnd Method~nEnd Type~n#Outer~nWhile True~nUsing~nLocal resource:TExitResource=New TExitResource~nDo~nExit Outer~nEnd Using~nWend", resolver, TestOptions())
Local usingOuterExitDiagnostics:TCompilerDiagnostic[]
Local usingOuterExitC:String = TBlitzMaxCompiler.EmitRuntimeC(usingOuterExit, usingOuterExitDiagnostics)
Check(usingOuterExit.Succeeded() And usingOuterExitDiagnostics.length = 0 And Contains(TCompilerIrDumper.Dump(usingOuterExit.ir), "exit @loop0 [cleanup 1]"), "labelled loop control crossing a Using boundary retains one explicit resource-cleanup edge")
Check(AppearsBefore(usingOuterExitC, "->m_Close(", "goto bmx_loop0_exit;"), "runtime C closes the Using resource before transferring to the outer loop exit")

Local importedInterfaceInheritanceSource:String = "SuperStrict~nImport sample.contracts~nType TImportedChild Implements IImportedChild~nField base:Int~nMethod BaseValue:Int(delta:Int)~nReturn base + delta~nEnd Method~nMethod ChildValue:Int()~nReturn base + 2~nEnd Method~nEnd Type~nLocal item:TImportedChild = New TImportedChild~nitem.base = 40~nLocal child:IImportedChild = item~nLocal parent:IImportedBase = child~nLocal result:Int = child.BaseValue(2) + child.ChildValue() + parent.BaseValue(2)"
Local importedInterfaceInheritance:TCompilerResult = TBlitzMaxCompiler.Compile("imported-interface-inheritance.bmx", importedInterfaceInheritanceSource, resolver, TestOptions())
Check(importedInterfaceInheritance.Succeeded(), "imported Interface inheritance lowers from compact snapshot records")
Check(importedInterfaceInheritance.ir.interfaces.length = 2 And importedInterfaceInheritance.ir.interfaces[0].name = "IImportedChild" And importedInterfaceInheritance.ir.interfaces[0].baseInterfaceIds.length = 1 And importedInterfaceInheritance.ir.interfaces[0].methods.length = 2 And importedInterfaceInheritance.ir.classes[0].interfaceImplementations.length = 2, "imported child layout flattens its parent and publishes both external descriptor identities")
Local importedInterfaceInheritanceDump:String = TCompilerIrDumper.Dump(importedInterfaceInheritance.ir)
Check(Contains(importedInterfaceInheritanceDump, "IImportedBase:IImportedBase [imported abi sample_contracts_IImportedBase from sample.contracts]") And Contains(importedInterfaceInheritanceDump, "IImportedChild:IImportedChild extends @if1 [imported abi sample_contracts_IImportedChild from sample.contracts]") And Contains(importedInterfaceInheritanceDump, "BaseValue(Int) -> Int [inherited @if1]"), "imported Interface inheritance retains ABI provenance and inherited slot ownership")
Local importedInterfaceInheritanceDiagnostics:TCompilerDiagnostic[]
Local importedInterfaceInheritanceC:String = TBlitzMaxCompiler.EmitRuntimeC(importedInterfaceInheritance, importedInterfaceInheritanceDiagnostics)
Check(importedInterfaceInheritanceDiagnostics.length = 0 And Contains(importedInterfaceInheritanceC, "sample_contracts_IImportedBase_ifc") And Contains(importedInterfaceInheritanceC, "sample_contracts_IImportedChild_ifc"), "runtime C references every externally owned descriptor in an imported Interface hierarchy")

Local interfaceInheritanceSource:String = "SuperStrict~nInterface IBaseValue~nMethod BaseValue:Int(delta:Int)~nEnd Interface~nInterface ILeftValue Extends IBaseValue~nMethod LeftValue:Int()~nEnd Interface~nInterface IRightValue Extends IBaseValue~nMethod RightValue:Int()~nEnd Interface~nInterface IDiamondValue Extends ILeftValue, IRightValue~nMethod DiamondValue:Int()~nEnd Interface~nType TDiamondValue Implements IDiamondValue~nField base:Int~nMethod BaseValue:Int(delta:Int)~nReturn base + delta~nEnd Method~nMethod LeftValue:Int()~nReturn base + 1~nEnd Method~nMethod RightValue:Int()~nReturn base + 2~nEnd Method~nMethod DiamondValue:Int()~nReturn base + 3~nEnd Method~nEnd Type~nLocal item:TDiamondValue = New TDiamondValue~nitem.base = 39~nLocal root:IBaseValue = item~nLocal left:ILeftValue = item~nLocal right:IRightValue = item~nLocal diamond:IDiamondValue = item~nLocal inheritedRoot:IBaseValue = diamond~nLocal result:Int = root.BaseValue(3) + left.LeftValue() + right.RightValue() + diamond.DiamondValue() + diamond.BaseValue(3) + inheritedRoot.BaseValue(3)"
Local interfaceInheritance:TCompilerResult = TBlitzMaxCompiler.Compile("interface-inheritance.bmx", interfaceInheritanceSource, resolver, TestOptions())
Check(interfaceInheritance.Succeeded(), "source Interface inheritance and diamond dispatch lower successfully")
Check(interfaceInheritance.ir.interfaces.length = 4 And interfaceInheritance.ir.interfaces[3].baseInterfaceIds.length = 2 And interfaceInheritance.ir.interfaces[3].methods.length = 4, "diamond Interface IR retains direct parents and one deduplicated inherited root slot")
Check(interfaceInheritance.ir.classes[0].interfaceImplementations.length = 4, "an implementing class publishes separate tables for the child and every ancestor Interface")
Local interfaceInheritanceDump:String = TCompilerIrDumper.Dump(interfaceInheritance.ir)
Check(Contains(interfaceInheritanceDump, "interface @if3 IDiamondValue:IDiamondValue extends @if1, @if2") And Contains(interfaceInheritanceDump, "method %im0 BaseValue(Int) -> Int [inherited @if0]") And Contains(interfaceInheritanceDump, "method %im1 LeftValue() -> Int [inherited @if1]") And Contains(interfaceInheritanceDump, "method %im2 RightValue() -> Int [inherited @if2]") And Contains(interfaceInheritanceDump, "method %im3 DiamondValue() -> Int"), "effective Interface layout is inherited-first, parent-ordered and diamond-deduplicated")
Check(Contains(interfaceInheritanceDump, "call interface @if3.%im0") And Contains(interfaceInheritanceDump, "call interface @if3.%im3"), "calls through a child Interface use its flattened inherited and declared slots")
Local interfaceInheritanceDiagnostics:TCompilerDiagnostic[]
Local interfaceInheritanceC:String = TBlitzMaxCompiler.EmitRuntimeC(interfaceInheritance, interfaceInheritanceDiagnostics)
Check(interfaceInheritanceDiagnostics.length = 0 And Contains(interfaceInheritanceC, "struct BCC2_InterfaceMethods_if3_IDiamondValue") And Contains(interfaceInheritanceC, "interface_if0") And Contains(interfaceInheritanceC, "interface_if1") And Contains(interfaceInheritanceC, "interface_if2") And Contains(interfaceInheritanceC, "interface_if3"), "runtime C emits every effective Interface table and the flattened diamond method struct")
Local reverseInterfaceInheritance:TCompilerResult = TBlitzMaxCompiler.Compile("reverse-interface-inheritance.bmx", "SuperStrict~nInterface IChildValue Extends IParentValue~nMethod ChildValue:Int()~nEnd Interface~nInterface IParentValue~nMethod ParentValue:Int()~nEnd Interface~nType TReverseValue Implements IChildValue~nMethod ParentValue:Int()~nReturn 20~nEnd Method~nMethod ChildValue:Int()~nReturn 22~nEnd Method~nEnd Type~nLocal value:IChildValue = New TReverseValue~nLocal result:Int = value.ParentValue() + value.ChildValue()", resolver, TestOptions())
Check(reverseInterfaceInheritance.Succeeded() And reverseInterfaceInheritance.ir.interfaces[0].methods.length = 2 And reverseInterfaceInheritance.ir.interfaces[0].methods[0].declaringInterfaceId = "if1", "Interface shell completion makes inherited layout independent of declaration order")

Local abstractInterfaceObligationSource:String = "SuperStrict~nModule acme.abstractinterfaceobligation~nInterface IAbstractLoader~nMethod Load:Int(delta:Int)~nEnd Interface~nType TAbstractLoader Implements IAbstractLoader Abstract~nEnd Type~nType TConcreteLoader Extends TAbstractLoader~nMethod Load:Int(delta:Int)~nReturn 42 + delta~nEnd Method~nEnd Type~nLocal loader:TAbstractLoader=New TConcreteLoader~nLocal value:Int=loader.Load(0)"
Local abstractInterfaceObligation:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/abstractinterfaceobligation.mod/abstractinterfaceobligation.bmx", abstractInterfaceObligationSource, resolver, TestOptions())
Local abstractInterfaceObligationDiagnostics:TCompilerDiagnostic[]
Local abstractInterfaceObligationC:String = TBlitzMaxCompiler.EmitRuntimeC(abstractInterfaceObligation, abstractInterfaceObligationDiagnostics)
Check(abstractInterfaceObligation.Succeeded() And abstractInterfaceObligation.ir.classes.length = 2 And abstractInterfaceObligation.ir.classes[0].functionSlots.length = 1 And abstractInterfaceObligation.ir.classes[0].functionSlots[0].isAbstract And abstractInterfaceObligation.ir.classes[1].functionSlots.length = 1 And Not abstractInterfaceObligation.ir.classes[1].functionSlots[0].isAbstract, "an abstract Type materializes an unimplemented Interface obligation and a concrete child replaces that slot in place")
Check(abstractInterfaceObligationDiagnostics.length = 0, "abstract Interface-obligation runtime C emits without backend diagnostics")
Check(Contains(abstractInterfaceObligationC, "brl_blitz_NullMethodError()"), "an abstract Interface obligation retains its deterministic failing thunk")
Check(Not Contains(abstractInterfaceObligationC, "acme_abstractinterfaceobligation_IAbstractLoader_Load(BBINT"), "an Interface-owned failing thunk is not mispublished as a top-level compatibility alias")

Local inheritanceSource:String = "SuperStrict~nType TBase~nField baseValue:Int~nMethod Value:Int()~nReturn baseValue~nEnd Method~nMethod Stable:Int()~nReturn baseValue + 1~nEnd Method~nEnd Type~nType TDerived Extends TBase~nField derivedValue:Int~nMethod Value:Int() Override~nReturn baseValue + derivedValue~nEnd Method~nMethod Extra:Int()~nReturn derivedValue + 2~nEnd Method~nEnd Type~nLocal Value:TDerived = New TDerived~nValue.baseValue = 20~nValue.derivedValue = 22~nLocal Base:TBase = Value~nLocal Result:Int = Base.Value() + Value.Stable() + Value.Extra()"
Local inheritance:TCompilerResult = TBlitzMaxCompiler.Compile("inheritance.bmx", inheritanceSource, resolver, TestOptions())
Check(inheritance.Succeeded(), "single source-Type inheritance and overrides lower successfully")
Check(inheritance.ir.classes.length = 2 And inheritance.ir.classes[1].baseClassId = "cls0" And inheritance.ir.classes[1].fields.length = 2 And inheritance.ir.classes[1].declaredFieldStart = 1 And inheritance.ir.classes[1].declaredFieldCount = 1, "derived IR flattens inherited fields while retaining its declared-field boundary")
Check(inheritance.ir.classes[1].functionSlots.length = 3 And inheritance.ir.classes[1].functionSlots[0].slotId = "cf0" And inheritance.ir.classes[1].functionSlots[0].functionId = "fn2" And inheritance.ir.classes[1].functionSlots[1].functionId = "fn1", "override replacement preserves the base slot and inherited methods preserve their implementation")
Local inheritanceDump:String = TCompilerIrDumper.Dump(inheritance.ir)
Check(Contains(inheritanceDump, "class @cls1 TDerived:TDerived extends @cls0") And Contains(inheritanceDump, "field %f0 baseValue:Int [inherited @cls0]") And Contains(inheritanceDump, "call virtual @cls0.%cf0 @fn0 Value") And Contains(inheritanceDump, "call virtual @cls1.%cf1 @fn1 Stable"), "inheritance provenance and static-receiver virtual dispatch remain explicit in IR")
Local inheritanceRuntimeDiagnostics:TCompilerDiagnostic[]
Local inheritanceRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(inheritance, inheritanceRuntimeDiagnostics)
Check(inheritanceRuntimeDiagnostics.length = 0, "runtime backend emits a derived object layout and effective class descriptor")
Check(Contains(inheritanceRuntimeC, "(BBClass *)&bmx_class_cls0_TBase") And Contains(inheritanceRuntimeC, "bmx_ctor_cls0_TBase((struct bmx_cls0_TBase_obj *)o);") And Contains(inheritanceRuntimeC, "BBINT bmx_field_f0_baseValue;") And Contains(inheritanceRuntimeC, "BBINT bmx_field_f0_derivedValue;"), "derived runtime layout chains construction and flattens base-before-derived fields")
Check(Contains(inheritanceRuntimeC, "offsetof(struct bmx_cls1_TDerived_obj, bmx_field_f0_derivedValue) - offsetof(struct bmx_cls1_TDerived_obj, bmx_field_f0_baseValue)"), "derived descriptor GC range spans inherited and declared fields")
Check(Contains(inheritanceRuntimeC, "(*m_cf0_Value)(struct bmx_cls1_TDerived_obj *);") And Contains(inheritanceRuntimeC, "(*m_cf1_Stable)(struct bmx_cls0_TBase_obj *);") And Contains(inheritanceRuntimeC, "bmx_fn2_Value") And Contains(inheritanceRuntimeC, "bmx_fn1_Stable"), "derived descriptors replace override slots in place and retain inherited receiver ABI")

Local dynamicNew:TCompilerResult = TBlitzMaxCompiler.Compile("dynamic-new.bmx", "SuperStrict~nType TDynamicBase~nField marker:Int~nMethod New(value:Int)~nmarker=value~nEnd Method~nEnd Type~nType TDynamicChild Extends TDynamicBase~nEnd Type~nGlobal prototype:TDynamicBase=New TDynamicChild(0)~nLocal typedCopy:TDynamicBase=New prototype(42)~nFunction Clone:Object(value:Object)~nReturn New value~nEnd Function~nLocal objectCopy:Object=Clone(prototype)", resolver, TestOptions())
Local dynamicNewDiagnostics:TCompilerDiagnostic[]
Local dynamicNewC:String = TBlitzMaxCompiler.EmitRuntimeC(dynamicNew, dynamicNewDiagnostics)
Check(dynamicNew.Succeeded() And dynamicNewDiagnostics.length = 0, "deprecated New <Object instance> lowers through typed IR without becoming an unresolved type")
Check(Contains(TCompilerIrDumper.Dump(dynamicNew.ir), "dynamic-class") And Contains(dynamicNewC, "New_ObjectNew(((BBOBJECT)bmx_global_g0_prototype)->clas, 42)") And Contains(dynamicNewC, "bbObjectNew(((BBOBJECT)bmx_p0_value)->clas)"), "dynamic New obtains the actual runtime class for parameterized typed and default root-Object construction")

Local shadowedFieldSource:String = "SuperStrict~nType TGrand~nField prop:String=~qgrand~q~nEnd Type~nType TParent Extends TGrand~nField prop:String=~qparent~q~nEnd Type~nType TChild Extends TParent~nField prop:String=~qchild~q~nEnd Type~nLocal child:TChild=New TChild~nLocal value:String=child.prop"
Local shadowedField:TCompilerResult = TBlitzMaxCompiler.Compile("shadowed-field.bmx", shadowedFieldSource, resolver, TestOptions())
Local shadowedFieldDiagnostics:TCompilerDiagnostic[]
Local shadowedFieldC:String = TBlitzMaxCompiler.EmitRuntimeC(shadowedField, shadowedFieldDiagnostics)
Check(shadowedField.Succeeded() And shadowedFieldDiagnostics.length = 0, "same-named fields may be redeclared through a Type hierarchy")
Check(Contains(shadowedFieldC, "BBSTRING bmx_field_f0_prop;") And Contains(shadowedFieldC, "BBSTRING bmx_field_cls1_f0_prop;") And Contains(shadowedFieldC, "BBSTRING bmx_field_cls2_f0_prop;"), "flattened local object layouts owner-qualify only field names that would otherwise collide")
Check(Contains(shadowedFieldC, "o->bmx_field_cls1_f0_prop =") And Contains(shadowedFieldC, "o->bmx_field_cls2_f0_prop ="), "constructors address each shadowed field through its declaring-Type identity")

Local typeFunctionHidingSource:String = "SuperStrict~nType TFactoryBase~nFunction Create:TFactoryBase(value:Int)~nReturn New TFactoryBase~nEnd Function~nFunction Stable:Int()~nReturn 1~nEnd Function~nEnd Type~nType TFactoryDerived Extends TFactoryBase~nFunction Create:TFactoryDerived(value:Int)~nReturn New TFactoryDerived~nEnd Function~nEnd Type~nLocal base:TFactoryBase=TFactoryBase.Create(1)~nLocal derived:TFactoryDerived=TFactoryDerived.Create(2)~nLocal stable:Int=TFactoryDerived.Stable()~nLocal polymorphic:TFactoryBase=New TFactoryDerived~nLocal dynamic:TFactoryBase=polymorphic.Create(3)"
Local typeFunctionHiding:TCompilerResult = TBlitzMaxCompiler.Compile("type-function-hiding.bmx", typeFunctionHidingSource, resolver, TestOptions())
Local typeFunctionHidingDiagnostics:TCompilerDiagnostic[]
Local typeFunctionHidingC:String = TBlitzMaxCompiler.EmitRuntimeC(typeFunctionHiding, typeFunctionHidingDiagnostics)
Check(typeFunctionHiding.Succeeded() And typeFunctionHiding.ir.classes.length = 2 And typeFunctionHiding.ir.classes[1].functionSlots.length = 2 And typeFunctionHiding.ir.classes[1].functionSlots[0].functionId = "fn2", "a derived Type function hides its same-signature inherited class-table entry in place")
Check(typeFunctionHidingDiagnostics.length = 0 And Occurrences(typeFunctionHidingC, "(*f_cf0_Create)") = 2 And Not Contains(typeFunctionHidingC, "(*f_cf2_Create)"), "runtime class layouts contain one Create entry per class and retain inherited Type functions that are not hidden")
Check(Contains(TCompilerIrDumper.Dump(typeFunctionHiding.ir), "call type-function @cls0.%cf0") And Contains(typeFunctionHidingC, "->clas->f_cf0_Create(3)"), "an object-qualified Type Function dispatches through the receiver's most-derived class-table slot without passing an instance argument")

Local abstractTypeFunctionDispatch:TCompilerResult = TBlitzMaxCompiler.Compile("abstract-type-function-dispatch.bmx", "SuperStrict~nType TAbstractDriver~nFunction Create:Int(value:Int) Abstract~nMethod Forward:Int(value:Int)~nReturn Create(value)~nEnd Method~nEnd Type~nType TConcreteDriver Extends TAbstractDriver~nFunction Create:Int(value:Int)~nReturn value + 1~nEnd Function~nEnd Type~nLocal driver:TAbstractDriver=New TConcreteDriver~nLocal explicitResult:Int=driver.Create(40)~nLocal implicitResult:Int=driver.Forward(41)", resolver, TestOptions())
Local abstractTypeFunctionDispatchDiagnostics:TCompilerDiagnostic[]
Local abstractTypeFunctionDispatchC:String = TBlitzMaxCompiler.EmitRuntimeC(abstractTypeFunctionDispatch, abstractTypeFunctionDispatchDiagnostics)
Check(abstractTypeFunctionDispatch.Succeeded() And abstractTypeFunctionDispatchDiagnostics.length = 0, "abstract Type Functions dispatch through concrete object receivers")
Check(Occurrences(TCompilerIrDumper.Dump(abstractTypeFunctionDispatch.ir), "call type-function @cls0.%cf0") = 2 And Occurrences(abstractTypeFunctionDispatchC, "->clas->f_cf0_Create") = 2, "object-qualified and implicit-Self abstract Type Function calls use the dynamic class-table slot")

Local handleReleaseAndPointerSelect:TCompilerResult = TBlitzMaxCompiler.Compile("handle-release-pointer-select.bmx", "SuperStrict~nLocal handle:Size_T=0~nRelease handle~nLocal window:Byte Ptr~nLocal client:Byte Ptr~nSelect window~nCase client~nhandle=1~nEnd Select", resolver, TestOptions())
Local handleReleaseAndPointerSelectDiagnostics:TCompilerDiagnostic[]
Local handleReleaseAndPointerSelectC:String = TBlitzMaxCompiler.EmitRuntimeC(handleReleaseAndPointerSelect, handleReleaseAndPointerSelectDiagnostics)
Check(handleReleaseAndPointerSelect.Succeeded() And handleReleaseAndPointerSelectDiagnostics.length = 0, "Release and pointer-valued Select lower through typed IR: " + CompilerDiagnosticSummary(handleReleaseAndPointerSelect))
Check(Contains(TCompilerIrDumper.Dump(handleReleaseAndPointerSelect.ir), "release ") And Contains(handleReleaseAndPointerSelectC, "bbHandleRelease((size_t)(") And Contains(handleReleaseAndPointerSelectC, "== bmx_v2_client"), "Release emits the runtime handle operation and pointer Select uses scalar identity")

Local methodTypeFunctionBridge:TCompilerResult = TBlitzMaxCompiler.Compile("method-type-function-bridge.bmx", "SuperStrict~nType TTargetBase~nField value:Object~nMethod Resolve:Int()~nReturn Resolve(value)~nEnd Method~nFunction Resolve:Int(value:Object)~nReturn 1~nEnd Function~nEnd Type~nType TTargetDerived Extends TTargetBase~nFunction Resolve:Int(value:Object)~nReturn 2~nEnd Function~nEnd Type~nLocal target:TTargetBase=New TTargetDerived~nLocal result:Int=target.Resolve()", resolver, TestOptions())
Local methodTypeFunctionBridgeDiagnostics:TCompilerDiagnostic[]
Local methodTypeFunctionBridgeC:String = TBlitzMaxCompiler.EmitRuntimeC(methodTypeFunctionBridge, methodTypeFunctionBridgeDiagnostics)
Check(methodTypeFunctionBridge.Succeeded() And methodTypeFunctionBridgeDiagnostics.length = 0 And Contains(TCompilerIrDumper.Dump(methodTypeFunctionBridge.ir), "call type-function @cls0.%cf1") And Contains(methodTypeFunctionBridgeC, "bmx_self_self->clas->f_cf1_Resolve"), "an inherited Method dispatches an unqualified same-Type Type Function through the receiver's most-derived class table")

Local typeFunctionSelfSource:String = "SuperStrict~nType TSelfFactory~nFunction Create:TSelfFactory()~nReturn New TSelfFactory~nEnd Function~nFunction Forward:TSelfFactory()~nReturn Self.Create()~nEnd Function~nEnd Type~nLocal value:TSelfFactory=TSelfFactory.Forward()"
Local typeFunctionSelf:TCompilerResult = TBlitzMaxCompiler.Compile("type-function-self.bmx", typeFunctionSelfSource, resolver, TestOptions())
Local typeFunctionSelfDiagnostics:TCompilerDiagnostic[]
Local typeFunctionSelfC:String = TBlitzMaxCompiler.EmitRuntimeC(typeFunctionSelf, typeFunctionSelfDiagnostics)
Check(typeFunctionSelf.Succeeded() And typeFunctionSelfDiagnostics.length = 0 And Not Contains(TCompilerIrDumper.Dump(typeFunctionSelf.ir), "call type-function"), "Self inside a Type Function remains a static enclosing-Type qualifier and does not require an instance receiver")

Local superDispatchSource:String = "SuperStrict~nType TSuperBase~nMethod Score:Int(value:Int)~nReturn value + 1~nEnd Method~nMethod ToString:String() Override~nReturn ~qbase~q~nEnd Method~nEnd Type~nType TSuperDerived Extends TSuperBase~nMethod Score:Int(value:Int) Override~nReturn Super.Score(value) + 1~nEnd Method~nMethod ToString:String() Override~nReturn Super.ToString() + ~q-derived~q~nEnd Method~nEnd Type~nType TSuperLeaf Extends TSuperDerived~nMethod Score:Int(value:Int) Override~nReturn Super.Score(value) + 1~nEnd Method~nEnd Type~nLocal Derived:TSuperDerived = New TSuperDerived~nLocal Leaf:TSuperLeaf = New TSuperLeaf~nLocal DerivedScore:Int = Derived.Score(40)~nLocal LeafScore:Int = Leaf.Score(40)~nLocal LeafText:String = Leaf.ToString()"
Local superDispatch:TCompilerResult = TBlitzMaxCompiler.Compile("super-dispatch.bmx", superDispatchSource, resolver, TestOptions())
Check(superDispatch.Succeeded(), "explicit Super method and fixed Object-slot calls lower successfully")
Local superDispatchDump:String = TCompilerIrDumper.Dump(superDispatch.ir)
Check(Contains(superDispatchDump, "call super @cls1.%cf0 @fn0 Score") And Contains(superDispatchDump, "call super @cls2.%cf0 @fn2 Score"), "Super IR retains the static current-class descriptor anchor at each inheritance level")
Check(Contains(superDispatchDump, "call super @cls1.ToString @fn1 ToString"), "fixed Object Super dispatch remains distinct from appended method slots")
Local superDispatchDiagnostics:TCompilerDiagnostic[]
Local superDispatchC:String = TBlitzMaxCompiler.EmitRuntimeC(superDispatch, superDispatchDiagnostics)
Check(superDispatchDiagnostics.length = 0, "runtime backend emits explicit Super calls")
Check(Contains(superDispatchC, "((struct BCC2_BBClass_cls0_TSuperBase *)bmx_class_cls1_TSuperDerived.super)->m_cf0_Score((struct bmx_cls0_TSuperBase_obj *)bmx_self_self") And Contains(superDispatchC, "((struct BCC2_BBClass_cls1_TSuperDerived *)bmx_class_cls2_TSuperLeaf.super)->m_cf0_Score((struct bmx_cls1_TSuperDerived_obj *)bmx_self_self"), "ordinary Super calls use the statically anchored immediate-base descriptor and receiver ABI")
Check(Contains(superDispatchC, "bmx_class_cls1_TSuperDerived.super->ToString((BBOBJECT)bmx_self_self)"), "fixed Object Super calls use the immediate BBClass descriptor slot")

Local reverseInheritance:TCompilerResult = TBlitzMaxCompiler.Compile("reverse-inheritance.bmx", "SuperStrict~nType TDerived Extends TBase~nField child:Int~nEnd Type~nType TBase~nField parent:Int~nEnd Type~nLocal Value:TDerived = New TDerived~nValue.parent = 1", resolver, TestOptions())
Check(reverseInheritance.Succeeded() And reverseInheritance.ir.classes.length = 2 And reverseInheritance.ir.classes[0].name = "TBase" And reverseInheritance.ir.classes[1].name = "TDerived" And reverseInheritance.ir.classes[1].baseClassId = reverseInheritance.ir.classes[0].classId, "class emission order is base-first even when source declarations are derived-first")

Local lifecycleSource:String = "SuperStrict~nType TBase~nField baseValue:Int~nMethod New(value:Int)~nbaseValue = value~nEnd Method~nMethod Delete()~nEnd Method~nEnd Type~nType TDerived Extends TBase~nField derivedValue:Int~nMethod New(baseValue:Int, derivedValue:Int)~nSuper.New(baseValue)~nSelf.derivedValue = derivedValue~nEnd Method~nMethod Delete()~nEnd Method~nEnd Type~nLocal Value:TDerived = New TDerived(20, 22)"
Local lifecycle:TCompilerResult = TBlitzMaxCompiler.Compile("lifecycle.bmx", lifecycleSource, resolver, TestOptions())
Check(lifecycle.Succeeded(), "parameterized source constructors, explicit Super chaining and destructors lower successfully")
Check(lifecycle.ir.classes[0].functionSlots.length = 0 And lifecycle.ir.classes[1].functionSlots.length = 0 And lifecycle.ir.classes[0].destructorFunctionId = "fn1" And lifecycle.ir.classes[1].destructorFunctionId = "fn3", "constructors and destructors remain lifecycle hooks rather than ordinary virtual slots")
Local lifecycleDump:String = TCompilerIrDumper.Dump(lifecycle.ir)
Check(Contains(lifecycleDump, "[constructor]") And Contains(lifecycleDump, "[chains @fn0]") And Contains(lifecycleDump, "[destructor]") And Contains(lifecycleDump, "object-new @cls1 constructor @fn2"), "constructor selection, base chaining and destruction remain explicit in typed IR")
Local lifecycleRuntimeDiagnostics:TCompilerDiagnostic[]
Local lifecycleRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(lifecycle, lifecycleRuntimeDiagnostics)
Check(lifecycleRuntimeDiagnostics.length = 0, "runtime backend emits lifecycle hooks")
Check(Contains(lifecycleRuntimeC, "bbObjectAtomicNewNC(clas)") And Contains(lifecycleRuntimeC, "bmx_fn2_New_ObjectNew((BBClass *)&bmx_class_cls1_TDerived, 20, 22)") And Contains(lifecycleRuntimeC, "bmx_fn0_New((struct bmx_cls0_TBase_obj *)bmx_self_self"), "parameterized object creation allocates without invoking the descriptor hook and then runs the selected constructor chain")
Check(Contains(lifecycleRuntimeC, "(void (*)(BBOBJECT))bmx_fn1_Delete") And Contains(lifecycleRuntimeC, "(void (*)(BBOBJECT))bmx_fn3_Delete") And Contains(lifecycleRuntimeC, "bmx_fn1_Delete((struct bmx_cls0_TBase_obj *)bmx_self_self);"), "descriptor destructor hooks and derived-to-base destruction order are explicit in runtime C")

Local inheritedDestructor:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/deleteforward.mod/deleteforward.bmx", "SuperStrict~nModule acme.deleteforward~nType TDeleteBase~nMethod Delete()~nEnd Method~nEnd Type~nType TDeleteMiddle Extends TDeleteBase~nEnd Type~nType TDeleteDerived Extends TDeleteMiddle~nMethod Delete()~nEnd Method~nEnd Type", resolver, TestOptions())
Local inheritedDestructorDiagnostics:TCompilerDiagnostic[]
Local inheritedDestructorC:String = TBlitzMaxCompiler.EmitRuntimeC(inheritedDestructor, inheritedDestructorDiagnostics)
Check(inheritedDestructor.Succeeded() And inheritedDestructorDiagnostics.length = 0 And Contains(inheritedDestructorC, "_acme_deleteforward_TDeleteBase_Delete((struct acme_deleteforward_TDeleteBase_obj *)bmx_self_self);") And Contains(inheritedDestructorC, "void _acme_deleteforward_TDeleteMiddle_Delete(struct acme_deleteforward_TDeleteMiddle_obj *o) { _acme_deleteforward_TDeleteBase_Delete((struct acme_deleteforward_TDeleteBase_obj *)o); }"), "destructor chaining and published forwarding thunks call the declaring class ABI directly through a correctly typed receiver")

Local importedDestructorBase:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/streambase.mod/streambase.bmx", "SuperStrict~nModule acme.streambase~nType TIO~nMethod Delete()~nEnd Method~nEnd Type~nType TStream Extends TIO~nEnd Type", resolver, TestOptions())
Local importedDestructorInterfaceDiagnostics:TCompilerDiagnostic[]
Local importedDestructorInterface:String = TBlitzMaxCompiler.EmitInterface(importedDestructorBase, importedDestructorInterfaceDiagnostics)
resolver.AddInterface("acme.streambase", "sdk/acme.streambase.i", importedDestructorInterface)
Local importedDestructorConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("imported-destructor-consumer.bmx", "SuperStrict~nImport acme.streambase~nType TDerivedStream Extends TStream~nMethod Delete()~nEnd Method~nEnd Type", resolver, TestOptions())
Local importedDestructorConsumerDiagnostics:TCompilerDiagnostic[]
Local importedDestructorConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(importedDestructorConsumer, importedDestructorConsumerDiagnostics)
Check(importedDestructorBase.Succeeded() And importedDestructorInterfaceDiagnostics.length = 0 And importedDestructorConsumer.Succeeded() And importedDestructorConsumerDiagnostics.length = 0 And Contains(importedDestructorConsumerC, "_acme_streambase_TIO_Delete((struct acme_streambase_TIO_obj *)bmx_self_self);"), "a derived local destructor calls an imported inherited destructor through its declaring-class receiver type")

Local inheritedConstructor:TCompilerResult = TBlitzMaxCompiler.Compile("inherited-constructor.bmx", "SuperStrict~nType TMessageBase~nField message:String~nMethod New(message:String)~nSelf.message = message~nEnd Method~nEnd Type~nType TMessageMiddle Extends TMessageBase~nEnd Type~nType TMessageLeaf Extends TMessageMiddle~nField marker:Int = 42~nEnd Type~nLocal value:TMessageLeaf = New TMessageLeaf(~qready~q)", resolver, TestOptions())
Local inheritedConstructorDiagnostics:TCompilerDiagnostic[]
Local inheritedConstructorC:String = TBlitzMaxCompiler.EmitRuntimeC(inheritedConstructor, inheritedConstructorDiagnostics)
Check(inheritedConstructor.Succeeded() And Contains(TCompilerIrDumper.Dump(inheritedConstructor.ir), "object-new @cls2 constructor @fn1") And Contains(TCompilerIrDumper.Dump(inheritedConstructor.ir), "[constructor] [chains @fn0]"), "inherited constructor selection creates an explicit derived forwarding constructor in typed IR")
Check(inheritedConstructorDiagnostics.length = 0 And Contains(inheritedConstructorC, "bmx_fn1_New_ObjectNew((BBClass *)&bmx_class_cls2_TMessageLeaf") And Contains(inheritedConstructorC, "bmx_fn0_New((struct bmx_cls0_TMessageBase_obj *)bmx_self_self") And Contains(inheritedConstructorC, "bmx_self_self->bmx_field_f0_marker = 42;"), "the forwarding constructor allocates the derived layout, invokes the inherited implementation, and initializes derived fields")

Local importedConstructorChain:TCompilerResult = TBlitzMaxCompiler.Compile("imported-constructor-chain.bmx", "SuperStrict~nImport sample.contracts~nType TImportedDerived Extends TImportedValue~nMethod New(size:Int,flag:Int)~nSuper.New(size,flag)~nEnd Method~nEnd Type~nLocal value:TImportedDerived=New TImportedDerived(4,5)", resolver, TestOptions())
Local importedConstructorChainDiagnostics:TCompilerDiagnostic[]
Local importedConstructorChainC:String = TBlitzMaxCompiler.EmitRuntimeC(importedConstructorChain, importedConstructorChainDiagnostics)
Check(importedConstructorChain.Succeeded() And importedConstructorChainDiagnostics.length = 0 And Contains(TCompilerIrDumper.Dump(importedConstructorChain.ir), "[chains imported @") And Contains(importedConstructorChainC, "_sample_contracts_TImportedValue_New_ii((struct sample_contracts_TImportedValue_obj *)bmx_self_self, bmx_p0_size, bmx_p1_flag);") And Not Contains(importedConstructorChainC, "->m_New"), "Super constructor chaining into an imported base uses its direct implementation ABI rather than a virtual slot")

Local inheritedImportedConstructor:TCompilerResult = TBlitzMaxCompiler.Compile("inherited-imported-constructor.bmx", "SuperStrict~nImport sample.contracts~nType TInheritedImportedValue Extends TImportedValue~nField marker:Int = 42~nEnd Type~nLocal value:TInheritedImportedValue=New TInheritedImportedValue(4,5)", resolver, TestOptions())
Local inheritedImportedConstructorDiagnostics:TCompilerDiagnostic[]
Local inheritedImportedConstructorC:String = TBlitzMaxCompiler.EmitRuntimeC(inheritedImportedConstructor, inheritedImportedConstructorDiagnostics)
Check(inheritedImportedConstructor.Succeeded() And inheritedImportedConstructorDiagnostics.length = 0 And Contains(TCompilerIrDumper.Dump(inheritedImportedConstructor.ir), "[constructor] [chains imported @"), "a source Type can inherit a published dependency constructor without declaring a forwarding New method")
Check(Contains(inheritedImportedConstructorC, "New_ObjectNew((BBClass *)&bmx_class_cls0_TInheritedImportedValue, 4, 5)") And Contains(inheritedImportedConstructorC, "_sample_contracts_TImportedValue_New_ii((struct sample_contracts_TImportedValue_obj *)bmx_self_self") And Contains(inheritedImportedConstructorC, "bmx_self_self->bmx_field_f0_marker = 42;"), "the synthetic source wrapper calls the dependency-owned constructor ABI and then initializes the derived fields")

Local delegationSource:String = "SuperStrict~nExtern~nFunction Mark:Int(value:Int) = ~qbcc2_mark~q~nEnd Extern~nType TBase~nField baseValue:Int = Mark(5)~nEnd Type~nType TDelegating Extends TBase~nField value:Int = Mark(1)~nMethod New()~nNew(Mark(4))~nMark(3)~nEnd Method~nMethod New(value:Int)~nMark(2)~nSelf.value = value~nEnd Method~nEnd Type~nLocal item:TDelegating = New TDelegating"
Local delegation:TCompilerResult = TBlitzMaxCompiler.Compile("constructor-delegation.bmx", delegationSource, resolver, TestOptions())
Check(delegation.Succeeded(), "same-Type constructor delegation lowers successfully")
Check(delegation.ir.functions[1].constructorChainKind = IR_CONSTRUCTOR_CHAIN_SAME_TYPE And delegation.ir.functions[1].chainedConstructorFunctionId = "fn1" And delegation.ir.functions[1].chainedConstructorArguments.length = 1, "typed IR distinguishes same-Type delegation from base-constructor chaining")
Local delegationDump:String = TCompilerIrDumper.Dump(delegation.ir)
Check(Contains(delegationDump, "[chains @fn1] [same-type-chain]") And Not Contains(delegationDump, "BoundError"), "same-Type constructor edges and consumed delegation statements remain explicit in IR")
Local delegationDiagnostics:TCompilerDiagnostic[]
Local delegationC:String = TBlitzMaxCompiler.EmitRuntimeC(delegation, delegationDiagnostics)
Check(delegationDiagnostics.length = 0, "runtime backend emits same-Type constructor delegation")
Check(Contains(delegationC, "bmx_fn1_New((struct bmx_cls1_TDelegating_obj *)bmx_self_self, bcc2_mark(4));") And Contains(delegationC, "bmx_self_self->clas = &bmx_class_cls1_TDelegating;"), "delegating constructors evaluate arguments before invoking the selected same-Type constructor and restore class identity")
Check(Not Contains(delegationC, "void bmx_fn0_New(struct bmx_cls1_TDelegating_obj * bmx_self_self) {~n    bmx_ctor_cls0_TBase") And Not Contains(delegationC, "bmx_fn1_New((struct bmx_cls1_TDelegating_obj *)bmx_self_self, bcc2_mark(4));~n    bmx_self_self->clas = &bmx_class_cls1_TDelegating;~n    bmx_self_self->bmx_field_f0_value"), "delegating constructors do not repeat base construction or field initialization")

Local fieldInitializerSource:String = "SuperStrict~nExtern~nFunction Mark:Int(value:Int) = ~qbcc2_mark~q~nEnd Extern~nType TBase~nField first:Int = Mark(1)~nField second:Int = first + Mark(2)~nMethod New(value:Int)~nMark(3)~nsecond = second + value~nEnd Method~nEnd Type~nType TDerived Extends TBase~nField third:Int = Mark(4)~nField total:Int = second + third~nMethod New(value:Int)~nSuper.New(value)~nMark(5)~nEnd Method~nEnd Type~nType TPlain~nField value:Int = Mark(6)~nField text:String = ~qready~q~nField child:TBase = New TBase(7)~nEnd Type~nLocal derived:TDerived = New TDerived(10)~nLocal plain:TPlain = New TPlain"
Local fieldInitializers:TCompilerResult = TBlitzMaxCompiler.Compile("field-initializers.bmx", fieldInitializerSource, resolver, TestOptions())
Check(fieldInitializers.Succeeded(), "typed scalar, managed and object field initializers lower successfully")
Check(fieldInitializers.ir.classes[0].fields[0].initializer <> Null And fieldInitializers.ir.classes[0].fields[1].initializer <> Null And fieldInitializers.ir.classes[2].fields[1].initializer <> Null And fieldInitializers.ir.classes[2].fields[2].initializer <> Null, "field initializer expressions are retained on their declaring field IR")
Check(fieldInitializers.ir.classes[2].hasManagedFields, "managed field initializer declarations retain traced allocation classification")
Local fieldInitializersDump:String = TCompilerIrDumper.Dump(fieldInitializers.ir)
Check(Contains(fieldInitializersDump, "field %f1 second:Int") And Contains(fieldInitializersDump, "initializer") And Contains(fieldInitializersDump, "symbol %self self : TBase") And Contains(fieldInitializersDump, "object-new @cls0 constructor @fn0"), "field dependency, Self receiver and nested allocation provenance remain explicit in IR")
Local fieldInitializerDiagnostics:TCompilerDiagnostic[]
Local fieldInitializerC:String = TBlitzMaxCompiler.EmitRuntimeC(fieldInitializers, fieldInitializerDiagnostics)
Check(fieldInitializerDiagnostics.length = 0, "runtime backend emits supported field initializer expressions")
Check(Contains(fieldInitializerC, "bmx_self_self->bmx_field_f0_first = bcc2_mark(1);") And Contains(fieldInitializerC, "bmx_self_self->bmx_field_f1_second = ((bmx_self_self->bmx_field_f0_first) + bcc2_mark(2));"), "explicit initializers replace defaults and may read earlier fields")
Check(AppearsBefore(fieldInitializerC, "bmx_fn0_New((struct bmx_cls0_TBase_obj *)bmx_self_self", "bmx_self_self->bmx_field_f0_third = bcc2_mark(4);") And AppearsBefore(fieldInitializerC, "bmx_self_self->bmx_field_f0_third = bcc2_mark(4);", "bcc2_mark(5);"), "derived construction runs the selected base constructor, then declared field initializers, then the user body")
Check(Contains(fieldInitializerC, "o->bmx_field_f0_value = bcc2_mark(6);") And Contains(fieldInitializerC, "o->bmx_field_f1_text = (BBString*)&") And Contains(fieldInitializerC, "o->bmx_field_f2_child = bmx_fn0_New_ObjectNew((BBClass *)&bmx_class_cls0_TBase, 7);") And Contains(fieldInitializerC, "bbObjectNew((BBClass *)&bmx_class_cls2_TPlain)"), "synthetic constructors execute managed and nested-object initializers while preserving traced allocation")

Local arrayFieldInitializer:TCompilerResult = TBlitzMaxCompiler.Compile("array-field-initializer.bmx", "SuperStrict~nType TArrayOwner~nField values:Int[] = [1, 2, 3]~nEnd Type~nLocal owner:TArrayOwner = New TArrayOwner", resolver, TestOptions())
Local arrayFieldInitializerDiagnostics:TCompilerDiagnostic[]
Local arrayFieldInitializerC:String = TBlitzMaxCompiler.EmitRuntimeC(arrayFieldInitializer, arrayFieldInitializerDiagnostics)
Check(arrayFieldInitializer.Succeeded() And arrayFieldInitializerDiagnostics.length = 0, "array literal field initializers lower in an implicit Type constructor")
Check(Contains(arrayFieldInitializerC, "BBINT bmx_tmp_") And AppearsBefore(arrayFieldInitializerC, "BBINT bmx_tmp_", "o->bmx_field_f0_values = ((bmx_tmp_"), "implicit Type constructors declare array-literal sequencing temporaries before their field initializer")

Local sizedHeapArrayField:TCompilerResult = TBlitzMaxCompiler.Compile("sized-heap-array-field.bmx", "SuperStrict~nType TPipeBuffer~nField bytes:Byte[4096]~nEnd Type~nLocal buffer:TPipeBuffer = New TPipeBuffer", resolver, TestOptions())
Local sizedHeapArrayFieldDiagnostics:TCompilerDiagnostic[]
Local sizedHeapArrayFieldC:String = TBlitzMaxCompiler.EmitRuntimeC(sizedHeapArrayField, sizedHeapArrayFieldDiagnostics)
Check(sizedHeapArrayField.Succeeded() And sizedHeapArrayFieldDiagnostics.length = 0, "a sized heap-Array Type field lowers successfully without becoming StaticArray storage")
Check(Contains(sizedHeapArrayFieldC, "BBARRAY bmx_field_f0_bytes;") And Contains(sizedHeapArrayFieldC, "o->bmx_field_f0_bytes = bbArrayNew1D(~qb~q, 4096);"), "a declaration bound such as Byte[4096] allocates its heap Array during Type construction")

Local globalFieldDefaultSource:String = "SuperStrict~nGlobal nil:TNode=New TNode~nType TNode~nField parent:TNode=nil~nEnd Type~nLocal node:TNode=New TNode"
Local globalFieldDefault:TCompilerResult = TBlitzMaxCompiler.Compile("global-field-default.bmx", globalFieldDefaultSource, resolver, TestOptions())
Local globalFieldDefaultDiagnostics:TCompilerDiagnostic[]
Local globalFieldDefaultC:String = TBlitzMaxCompiler.EmitRuntimeC(globalFieldDefault, globalFieldDefaultDiagnostics)
Check(globalFieldDefault.Succeeded() And globalFieldDefaultDiagnostics.length = 0, "a Type field initializer may reference module Global storage")
Check(AppearsBefore(globalFieldDefaultC, "static struct bmx_cls0_TNode_obj * bmx_global_g0_nil;", "void bmx_ctor_cls0_TNode(") And Contains(globalFieldDefaultC, "o->bmx_field_f0_parent = bmx_global_g0_nil;"), "runtime C declares module Globals before class constructors that consume them")

Local objectSlotsSource:String = "SuperStrict~nType TBase~nField value:Int~nMethod ToString:String() Override~nReturn ~qbase~q~nEnd Method~nMethod Compare:Int(other:Object) Override~nReturn value~nEnd Method~nMethod SendMessage:Object(message:Object, sender:Object) Override~nReturn message~nEnd Method~nMethod HashCode:UInt() Override~nReturn UInt(value)~nEnd Method~nMethod Equals:Int(other:Object) Override~nReturn Self = other~nEnd Method~nEnd Type~nType TDerived Extends TBase~nMethod ToString:String() Override~nReturn ~qderived~q~nEnd Method~nMethod Compare:Int(other:Object) Override~nReturn value + 1~nEnd Method~nEnd Type~nLocal item:TDerived = New TDerived~nitem.value = 41~nLocal text:String = item.ToString()~nLocal ordering:Int = item.Compare(item)~nLocal hash:UInt = item.HashCode()~nLocal equal:Int = item.Equals(item)~nLocal message:Object = item.SendMessage(item, item)"
Local objectSlots:TCompilerResult = TBlitzMaxCompiler.Compile("object-slots.bmx", objectSlotsSource, resolver, TestOptions())
Check(objectSlots.Succeeded(), "fixed Object method overrides lower successfully")
Check(objectSlots.ir.classes[0].functionSlots.length = 0 And objectSlots.ir.classes[1].functionSlots.length = 0, "Object overrides never extend the per-Type virtual layout")
Check(objectSlots.ir.classes[0].toStringFunctionId = "fn0" And objectSlots.ir.classes[0].compareFunctionId = "fn1" And objectSlots.ir.classes[0].sendMessageFunctionId = "fn2" And objectSlots.ir.classes[0].hashCodeFunctionId = "fn3" And objectSlots.ir.classes[0].equalsFunctionId = "fn4", "base Object overrides occupy their five fixed IR slots")
Check(objectSlots.ir.classes[1].toStringFunctionId = "fn5" And objectSlots.ir.classes[1].compareFunctionId = "fn6" And objectSlots.ir.classes[1].sendMessageFunctionId = "fn2" And objectSlots.ir.classes[1].hashCodeFunctionId = "fn3" And objectSlots.ir.classes[1].equalsFunctionId = "fn4", "derived Object slots replace local overrides and retain inherited implementations")
Local objectSlotsDump:String = TCompilerIrDumper.Dump(objectSlots.ir)
Check(Contains(objectSlotsDump, "object-slot ToString @fn5") And Contains(objectSlotsDump, "object-slot SendMessage @fn2") And Contains(objectSlotsDump, "call virtual @cls1.ToString @fn5 ToString") And Contains(objectSlotsDump, "[class @cls1 object-slot Compare]"), "fixed Object descriptor ownership and dispatch remain explicit in the IR dump")
Local objectSlotsDiagnostics:TCompilerDiagnostic[]
Local objectSlotsC:String = TBlitzMaxCompiler.EmitRuntimeC(objectSlots, objectSlotsDiagnostics)
Check(objectSlotsDiagnostics.length = 0, "runtime backend emits fixed Object override slots")
Check(Contains(objectSlotsC, "(BBSTRING (*)(BBOBJECT))bmx_fn5_ToString") And Contains(objectSlotsC, "(int (*)(BBOBJECT, BBOBJECT))bmx_fn6_Compare") And Contains(objectSlotsC, "(BBOBJECT (*)(BBOBJECT, BBOBJECT, BBOBJECT))bmx_fn2_SendMessage") And Contains(objectSlotsC, "(BBUINT (*)(BBOBJECT))bmx_fn3_HashCode") And Contains(objectSlotsC, "(BBINT (*)(BBOBJECT, BBOBJECT))bmx_fn4_Equals"), "derived descriptors use the production Object-slot C ABI and inherited implementation identity")
Check(Contains(objectSlotsC, "->clas->ToString((BBOBJECT)") And Contains(objectSlotsC, "->clas->Compare((BBOBJECT)") And Contains(objectSlotsC, "->clas->SendMessage((BBOBJECT)") And Contains(objectSlotsC, "->clas->HashCode((BBOBJECT)") And Contains(objectSlotsC, "->clas->Equals((BBOBJECT)"), "Object method calls dispatch through their fixed descriptor fields")

Local defaultConstructor:TCompilerResult = TBlitzMaxCompiler.Compile("default-constructor.bmx", "SuperStrict~nType TDefault~nField value:Int~nMethod New()~nvalue = 7~nEnd Method~nEnd Type~nLocal Value:TDefault = New TDefault", resolver, TestOptions())
Check(defaultConstructor.Succeeded() And defaultConstructor.ir.classes[0].defaultConstructorFunctionId = "fn0", "an explicit zero-argument constructor becomes the descriptor default hook")
Local defaultConstructorDiagnostics:TCompilerDiagnostic[]
Local defaultConstructorC:String = TBlitzMaxCompiler.EmitRuntimeC(defaultConstructor, defaultConstructorDiagnostics)
Check(defaultConstructorDiagnostics.length = 0 And Contains(defaultConstructorC, "(void (*)(BBOBJECT))bmx_fn0_New") And Contains(defaultConstructorC, "bbObjectAtomicNew((BBClass *)&bmx_class_cls0_TDefault)") And Not Contains(defaultConstructorC, "bmx_fn0_New_ObjectNew"), "default object creation delegates exactly once through the descriptor constructor hook")

Local managedFieldType:TCompilerResult = TBlitzMaxCompiler.Compile("managed-field-type.bmx", "SuperStrict~nType THolder~nField text:String~nField values:Int[]~nEnd Type~nLocal Holder:THolder = New THolder", resolver, TestOptions())
Check(managedFieldType.Succeeded() And managedFieldType.ir.classes[0].hasManagedFields, "managed fields classify the object allocation contract")
Local managedFieldDiagnostics:TCompilerDiagnostic[]
Local managedFieldC:String = TBlitzMaxCompiler.EmitRuntimeC(managedFieldType, managedFieldDiagnostics)
Check(managedFieldDiagnostics.length = 0 And Contains(managedFieldC, "bbObjectNew((BBClass *)&bmx_class_cls0_THolder)") And Contains(managedFieldC, "= &bbEmptyString;") And Contains(managedFieldC, "= &bbEmptyArray;"), "managed-field objects use traced allocation and runtime empty sentinels")

Local receiverMaterializationSource:String = "SuperStrict~nGlobal ReceiverCount:Int~nType TReceiver~nField value:Int~nMethod Read:Int()~nReturn value~nEnd Method~nEnd Type~nFunction MakeReceiver:TReceiver(value:Int)~nReceiverCount = ReceiverCount + 1~nLocal receiver:TReceiver = New TReceiver~nreceiver.value = value~nReturn receiver~nEnd Function~nLocal MethodValue:Int = MakeReceiver(20).Read()~nLocal FieldValue:Int = MakeReceiver(22).value~nMakeReceiver(1).value = 7~nLocal NewValue:Int = (New TReceiver).Read()"
Local receiverMaterialization:TCompilerResult = TBlitzMaxCompiler.Compile("receiver-materialization.bmx", receiverMaterializationSource, resolver, TestOptions())
Check(receiverMaterialization.Succeeded(), "call, allocation and field-chain receivers lower successfully")
Local receiverMaterializationDump:String = TCompilerIrDumper.Dump(receiverMaterialization.ir)
Check(Contains(receiverMaterializationDump, "materialize %t0:TReceiver") And Contains(receiverMaterializationDump, "materialize %t1:TReceiver") And Contains(receiverMaterializationDump, "materialize %t2:TReceiver") And Contains(receiverMaterializationDump, "materialize %t3:TReceiver"), "evaluate-once receiver temporaries are explicit and typed in IR")
Check(Contains(receiverMaterializationDump, "call virtual @cls0.%cf0") And Contains(receiverMaterializationDump, "field @cls0.%f0"), "materialized receivers feed ordinary virtual-call and field-access IR")
Local receiverMaterializationDiagnostics:TCompilerDiagnostic[]
Local receiverMaterializationC:String = TBlitzMaxCompiler.EmitRuntimeC(receiverMaterialization, receiverMaterializationDiagnostics)
Check(receiverMaterializationDiagnostics.length = 0, "runtime backend emits complex receiver materialization")
Check(Contains(receiverMaterializationC, "struct bmx_cls0_TReceiver_obj * bmx_tmp_t0;") And Contains(receiverMaterializationC, "((bmx_tmp_t0 = bmx_fn0_MakeReceiver(20)), bmx_tmp_t0->clas->m_cf0_Read((struct bmx_cls0_TReceiver_obj *)bmx_tmp_t0))"), "virtual dispatch evaluates its receiver once and reuses typed temporary storage")
Check(Contains(receiverMaterializationC, "((bmx_tmp_t1 = bmx_fn0_MakeReceiver(22)), (bmx_tmp_t1->bmx_field_f0_value))"), "field reads evaluate complex receivers once")
Check(Contains(receiverMaterializationC, "bmx_tmp_t2 = bmx_fn0_MakeReceiver(1);") And Contains(receiverMaterializationC, "(bmx_tmp_t2->bmx_field_f0_value) = 7;"), "field assignment materializes its receiver before the C lvalue operation")
Check(Contains(receiverMaterializationC, "((bmx_tmp_t3 = ((struct bmx_cls0_TReceiver_obj *)bbObjectAtomicNew((BBClass *)&bmx_class_cls0_TReceiver))), bmx_tmp_t3->clas->m_cf0_Read"), "new-object method receivers use the same evaluate-once IR operation")

Local callArgumentOrderSource:String = "SuperStrict~nGlobal Position:Int~nFunction Current:Int()~nReturn Position~nEnd Function~nFunction Advance:Int()~nPosition :+ 1~nReturn Position~nEnd Function~nFunction Pair:Int(first:Int, second:Int)~nReturn first * 10 + second~nEnd Function~nLocal Value:Int = Pair(Current(), Advance())"
Local callArgumentOrder:TCompilerResult = TBlitzMaxCompiler.Compile("call-argument-order.bmx", callArgumentOrderSource, resolver, TestOptions())
Check(callArgumentOrder.Succeeded(), "computed call arguments lower successfully")
Local callArgumentOrderDump:String = TCompilerIrDumper.Dump(callArgumentOrder.ir)
Check(AppearsBefore(callArgumentOrderDump, "materialize %t0", "materialize %t1"), "call argument evaluation is explicitly sequenced in source order")
Local callArgumentOrderDiagnostics:TCompilerDiagnostic[]
Local callArgumentOrderC:String = TBlitzMaxCompiler.EmitRuntimeC(callArgumentOrder, callArgumentOrderDiagnostics)
Check(callArgumentOrderDiagnostics.length = 0 And Contains(callArgumentOrderC, "((bmx_tmp_t0 = bmx_fn0_Current()), ((bmx_tmp_t1 = bmx_fn1_Advance()), bmx_fn2_Pair(bmx_tmp_t0, bmx_tmp_t1)))"), "runtime C evaluates computed call arguments left-to-right before invocation")

Local varStructArgumentOrderSource:String = "SuperStrict~nStruct SOrderedConfig~nField value:Int~nEnd Struct~nType TOrderedConfigHolder~nField state:SOrderedConfig~nEnd Type~nFunction UseOrderedConfig:Int(config:SOrderedConfig Var, value:Int)~nReturn config.value + value~nEnd Function~nType TOrderedRunner~nField holder:TOrderedConfigHolder~nMethod MakeValue:Int()~nReturn 2~nEnd Method~nMethod Test:Int()~nReturn UseOrderedConfig(Self.holder.state, MakeValue())~nEnd Method~nEnd Type"
Local varStructArgumentOrder:TCompilerResult = TBlitzMaxCompiler.Compile("var-struct-argument-order.bmx", varStructArgumentOrderSource, resolver, TestOptions())
Local varStructArgumentOrderDump:String = TCompilerIrDumper.Dump(varStructArgumentOrder.ir)
Local varStructArgumentOrderDiagnostics:TCompilerDiagnostic[]
Local varStructArgumentOrderC:String = TBlitzMaxCompiler.EmitRuntimeC(varStructArgumentOrder, varStructArgumentOrderDiagnostics)
Check(varStructArgumentOrder.Succeeded() And Contains(varStructArgumentOrderDump, "SOrderedConfig [address]"), "sequenced Var Struct fields retain an explicit pointer-temporary contract in typed IR")
Check(varStructArgumentOrderDiagnostics.length = 0 And Contains(varStructArgumentOrderC, "struct bmx_struct_st0_SOrderedConfig * bmx_tmp_") And Contains(varStructArgumentOrderC, "bmx_fn0_UseOrderedConfig(bmx_tmp_"), "runtime C stores a sequenced Var Struct field address in pointer-typed temporary storage")

Local indirectArgumentOrderSource:String = "SuperStrict~nGlobal Position:Int~nFunction Current:Int()~nReturn Position~nEnd Function~nFunction Advance:Int()~nPosition :+ 1~nReturn Position~nEnd Function~nFunction Pair:Int(first:Int, second:Int)~nReturn first * 10 + second~nEnd Function~nLocal Callback:Int(first:Int, second:Int) = Pair~nLocal Value:Int = Callback(Current(), Advance())"
Local indirectArgumentOrder:TCompilerResult = TBlitzMaxCompiler.Compile("indirect-argument-order.bmx", indirectArgumentOrderSource, resolver, TestOptions())
Check(indirectArgumentOrder.Succeeded(), "computed indirect-call arguments lower successfully")
Local indirectArgumentOrderDump:String = TCompilerIrDumper.Dump(indirectArgumentOrder.ir)
Check(AppearsBefore(indirectArgumentOrderDump, "materialize %t0", "materialize %t1") And AppearsBefore(indirectArgumentOrderDump, "materialize %t1", "materialize %t2") And Contains(indirectArgumentOrderDump, "call-indirect"), "indirect callable and argument evaluation are explicitly sequenced in source order")

Local constructorArgumentOrderSource:String = "SuperStrict~nGlobal Position:Int~nFunction Current:Int()~nReturn Position~nEnd Function~nFunction Advance:Int()~nPosition :+ 1~nReturn Position~nEnd Function~nType TPair~nField first:Int~nField second:Int~nMethod New(first:Int, second:Int)~nSelf.first = first~nSelf.second = second~nEnd Method~nEnd Type~nLocal Value:TPair = New TPair(Current(), Advance())"
Local constructorArgumentOrder:TCompilerResult = TBlitzMaxCompiler.Compile("constructor-argument-order.bmx", constructorArgumentOrderSource, resolver, TestOptions())
Check(constructorArgumentOrder.Succeeded(), "computed constructor arguments lower successfully")
Local constructorArgumentOrderDump:String = TCompilerIrDumper.Dump(constructorArgumentOrder.ir)
Check(AppearsBefore(constructorArgumentOrderDump, "materialize %t0", "materialize %t1"), "constructor argument evaluation is explicitly sequenced in source order")

Local crossType:TCompilerResult = TBlitzMaxCompiler.Compile("cross-type.bmx", "SuperStrict~nType TFirst~nField second:TSecond~nEnd Type~nType TSecond~nField first:TFirst~nEnd Type~nLocal Value:TFirst = New TFirst", resolver, TestOptions())
Check(crossType.Succeeded() And crossType.ir.classes.length = 2 And crossType.ir.classes[0].hasManagedFields And crossType.ir.classes[1].hasManagedFields, "class shells make cross-Type field identities declaration-order independent")

Local multiDimensionalArray:TCompilerResult = TBlitzMaxCompiler.Compile("multidimensional-array.bmx", "SuperStrict~nLocal Grid:Int[,] = New Int[2, 3]~nGrid[1,2]=42~nLocal Value:Int=Grid[1,2]~nLocal Total:Int~nFor Local Cell:Int=EachIn Grid~nTotal:+Cell~nNext", resolver, TestOptions())
Check(multiDimensionalArray.Succeeded(), "multidimensional Arrays lower through rank-aware allocation, indexing, and flattened EachIn")
Local multiDimensionalArrayDump:String = TCompilerIrDumper.Dump(multiDimensionalArray.ir)
Local multiDimensionalArrayDiagnostics:TCompilerDiagnostic[]
Local multiDimensionalArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(multiDimensionalArray, multiDimensionalArrayDiagnostics)
Check(multiDimensionalArrayDiagnostics.length = 0 And Contains(multiDimensionalArrayDump, "rank 2") And Contains(multiDimensionalArrayC, "bbArrayNew(~qi~q, 2, 2, 3)") And Contains(multiDimensionalArrayC, "->scales[1]") And Contains(multiDimensionalArrayC, "->scales[0]"), "multidimensional typed IR emits the production row-major scale and total-length contracts")

Local jaggedArray:TCompilerResult = TBlitzMaxCompiler.Compile("jagged-array.bmx", "SuperStrict~nLocal Rows:Int[][] = New Int[3][]~nLocal RowIndex:Int~nRows[RowIndex] :+ [40, 2]~nLocal Value:Int = Rows[0][1]", resolver, TestOptions())
Local jaggedArrayDiagnostics:TCompilerDiagnostic[]
Local jaggedArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(jaggedArray, jaggedArrayDiagnostics)
Check(jaggedArray.Succeeded() And jaggedArrayDiagnostics.length = 0, "partially allocated jagged arrays lower successfully")
Check(Contains(jaggedArrayC, "bbArrayNew1D(~q[]i~q, 3)"), "jagged outer-array allocation retains its managed array element encoding")
Check(Contains(jaggedArrayC, "bbArrayConcat(~qi~q"), "managed array concatenation writes back through a stable indexed array target")

Local structTruth:TCompilerResult = TBlitzMaxCompiler.Compile("struct-truth.bmx", "SuperStrict~nStruct STruth~nField Value:Int~nEnd Struct~nLocal Flag:STruth~nLocal Result:Int~nIf Flag Then Result = 1~nIf Not Flag Then Result = 2", resolver, TestOptions())
Local structTruthDiagnostics:TCompilerDiagnostic[]
Local structTruthC:String = TBlitzMaxCompiler.EmitRuntimeC(structTruth, structTruthDiagnostics)
Check(structTruth.Succeeded() And structTruthDiagnostics.length = 0, "Struct values lower through their production always-present truth contract")
Check(Contains(structTruthC, "if (1)") And Contains(structTruthC, "if (0)"), "Struct truth and Not-Struct emit explicit scalar constants rather than invalid C struct predicates")

Local nestedStructLValue:TCompilerResult = TBlitzMaxCompiler.Compile("nested-struct-lvalue.bmx", "SuperStrict~nStruct SState~nField Value:Int~nEnd Struct~nType THolder~nField State:SState~nEnd Type~nType TOuter~nField Holder:THolder~nEnd Type~nFunction SetState(State:SState Var)~nState.Value=42~nEnd Function~nLocal Outer:TOuter=New TOuter~nOuter.Holder=New THolder~nSetState(Outer.Holder.State)~nOuter.Holder.State.Value=7", resolver, TestOptions())
Local nestedStructLValueDiagnostics:TCompilerDiagnostic[]
Local nestedStructLValueC:String = TBlitzMaxCompiler.EmitRuntimeC(nestedStructLValue, nestedStructLValueDiagnostics)
Check(nestedStructLValue.Succeeded() And nestedStructLValueDiagnostics.length = 0, "nested Struct lvalues through object fields lower successfully")
Check(Not Contains(nestedStructLValueC, "(&((") And Contains(nestedStructLValueC, "(&(bmx_tmp_"), "materialized receivers remain outside Var-address and nested-field lvalues in generated C")

Local referenceVarLValue:TCompilerResult = TBlitzMaxCompiler.Compile("reference-var-lvalue.bmx", "SuperStrict~nType TBase~nEnd Type~nType TDerived Extends TBase~nEnd Type~nGlobal Current:TBase~nFunction Replace(target:Object Var)~ntarget=Null~nEnd Function~nReplace(Current)", resolver, TestOptions())
Local referenceVarLValueDiagnostics:TCompilerDiagnostic[]
Local referenceVarLValueC:String = TBlitzMaxCompiler.EmitRuntimeC(referenceVarLValue, referenceVarLValueDiagnostics)
Check(referenceVarLValue.Succeeded() And referenceVarLValueDiagnostics.length = 0 And Contains(referenceVarLValueC, "((BBOBJECT *)(&bmx_global_") And Not Contains(referenceVarLValueC, "&((BBOBJECT)"), "reference-compatible Var arguments cast the address of the original typed storage instead of taking the address of a converted rvalue")

Local largeArraySource:String = "SuperStrict~nLocal Values:String[]~nValues = ["
For Local largeArrayIndex:Int = 0 Until 300
	If largeArrayIndex Then largeArraySource :+ ","
	largeArraySource :+ "~qvalue~q"
Next
largeArraySource :+ "]"
Local largeArrayAssignment:TCompilerResult = TBlitzMaxCompiler.Compile("large-array-assignment.bmx", largeArraySource, resolver, TestOptions())
Local largeArrayAssignmentDiagnostics:TCompilerDiagnostic[]
Local largeArrayAssignmentC:String = TBlitzMaxCompiler.EmitRuntimeC(largeArrayAssignment, largeArrayAssignmentDiagnostics)
Check(largeArrayAssignment.Succeeded() And largeArrayAssignmentDiagnostics.length = 0, "large managed array literal assignments lower successfully")
Check(Not Contains(largeArrayAssignmentC, "), ((bmx_tmp_"), "assignment emission flattens materialized array elements instead of generating unbounded C bracket nesting")

Local rankedArrayModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/rankedarray.mod/rankedarray.bmx", "SuperStrict~nModule acme.rankedarray~nType TRankedArray~nField Values:Int[,]~nEnd Type~nFunction CreateGrid:Int[,](width:Int,height:Int)~nReturn New Int[width,height]~nEnd Function", resolver, TestOptions())
Local rankedArrayInterfaceDiagnostics:TCompilerDiagnostic[]
Local rankedArrayInterface:String = TBlitzMaxCompiler.EmitInterface(rankedArrayModule, rankedArrayInterfaceDiagnostics)
Check(rankedArrayModule.Succeeded() And rankedArrayInterfaceDiagnostics.length = 0 And Contains(rankedArrayInterface, ".Values%&[,]&") And Contains(rankedArrayInterface, "CreateGrid%&[,](width%,height%)"), "compact interfaces preserve managed-array rank on fields and routine results")
resolver.AddInterface("acme.rankedarray", "sdk/acme.rankedarray.i", rankedArrayInterface)
Local rankedArrayConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("ranked-array-consumer.bmx", "SuperStrict~nImport acme.rankedarray~nLocal holder:TRankedArray=New TRankedArray~nholder.Values=CreateGrid(2,3)~nholder.Values[1,2]=42~nLocal result:Int=holder.Values[1,2]", resolver, TestOptions())
Local rankedArrayConsumerDump:String = TCompilerIrDumper.Dump(rankedArrayConsumer.ir)
Local rankedArrayConsumerDiagnostics:TCompilerDiagnostic[]
Local rankedArrayConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(rankedArrayConsumer, rankedArrayConsumerDiagnostics)
Check(rankedArrayConsumer.Succeeded(), "a separate consumer reconstructs the published multidimensional managed-array signature")
Check(rankedArrayConsumerDiagnostics.length = 0, "the backend accepts a consumed multidimensional managed-array signature")
Check(Contains(rankedArrayConsumerC, "acme_rankedarray_CreateGrid__Bint__Bint"), "the consumed multidimensional managed-array routine retains its published ABI identity")
Check(Occurrences(rankedArrayConsumerDump, "rank 2") >= 2, "the consumed multidimensional managed array retains its rank on write and read indexing operations")

Local nativeCall:TCompilerResult = TBlitzMaxCompiler.Compile("native-call.bmx", "SuperStrict~nExtern~nFunction NativeAdd:Int(left:Int, right:Int) = ~qbcc2_native_add~q~nEnd Extern~nGlobal NativeResult:Int = NativeAdd(20, 22)", resolver, TestOptions())
Check(nativeCall.Succeeded(), "scalar source Extern call lowers successfully")
Check(nativeCall.ir.externalFunctions.length = 1 And nativeCall.ir.externalFunctions[0].abiName = "bcc2_native_add", "source Extern ABI name is retained in typed IR")
Local nativeRuntimeDiagnostics:TCompilerDiagnostic[]
Local nativeRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeCall, nativeRuntimeDiagnostics)
Check(nativeRuntimeDiagnostics.length = 0 And Contains(nativeRuntimeC, "extern BBINT bcc2_native_add(BBINT bmx_ep0_left, BBINT bmx_ep1_right);") And Contains(nativeRuntimeC, "bcc2_native_add(20, 22)"), "runtime backend declares and calls source native routines")

Local externallyOwnedNativePrototype:TCompilerResult = TBlitzMaxCompiler.Compile("externally-owned-native-prototype.bmx", "SuperStrict~nExtern~nFunction Atomic:Int(target:Int Ptr)=~qint Atomic(int *)!~q~nEnd Extern~nLocal value:Int~nLocal result:Int=Atomic(Varptr value)", resolver, TestOptions())
Local externallyOwnedNativePrototypeDump:String = TCompilerIrDumper.Dump(externallyOwnedNativePrototype.ir)
Local externallyOwnedNativePrototypeDiagnostics:TCompilerDiagnostic[]
Local externallyOwnedNativePrototypeC:String = TBlitzMaxCompiler.EmitRuntimeC(externallyOwnedNativePrototype, externallyOwnedNativePrototypeDiagnostics)
Check(externallyOwnedNativePrototype.Succeeded() And Contains(externallyOwnedNativePrototypeDump, "[prototype-owned-externally]"), "a trailing native-declaration bang retains external prototype ownership in typed IR")
Check(externallyOwnedNativePrototypeDiagnostics.length = 0 And Contains(externallyOwnedNativePrototypeC, "Atomic(") And Not Contains(externallyOwnedNativePrototypeC, "extern int Atomic(int *);"), "runtime C calls but does not redeclare a native routine whose header owns its prototype")

Local nativeCallCasts:TCompilerResult = TBlitzMaxCompiler.Compile("native-call-casts.bmx", "SuperStrict~nExtern~nFunction someFunc(value:Byte Ptr)=~qvoid someFunc(void*)!~q~nEnd Extern~nLocal arg:Byte Ptr~nsomeFunc(arg)", resolver, TestOptions())
Local nativeCallCastDiagnostics:TCompilerDiagnostic[]
Local nativeCallCastC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeCallCasts, nativeCallCastDiagnostics)
Check(nativeCallCasts.Succeeded() And nativeCallCastDiagnostics.length = 0 And Contains(nativeCallCastC, "someFunc(((void*)bmx_v0_arg))") And Not Contains(nativeCallCastC, "extern void someFunc(void*);"), "a complete native declaration supplies production-compatible call argument casts even when trailing bang suppresses its prototype")

Local nativeHandleResult:TCompilerResult = TBlitzMaxCompiler.Compile("native-handle-result.bmx", "SuperStrict~nExtern~nFunction LoadHandle:Byte Ptr(name$z)=~qHMODULE LoadHandle(BBBYTE*)!~q~nEnd Extern~nGlobal handle:Byte Ptr=LoadHandle(~qsample.dll~q)", resolver, TestOptions())
Local nativeHandleResultDiagnostics:TCompilerDiagnostic[]
Local nativeHandleResultC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeHandleResult, nativeHandleResultDiagnostics)
Check(nativeHandleResult.Succeeded() And nativeHandleResultDiagnostics.length = 0 And Contains(nativeHandleResultC, "bbStringToCString(") And Contains(nativeHandleResultC, "LoadHandle(((BBBYTE*)") And Contains(nativeHandleResultC, "((BBBYTE *)(LoadHandle(") And Not Contains(nativeHandleResultC, "LoadHandle(((BBBYTE *)(BBString*)"), "prototype-owned native $z calls marshal managed Strings and explicitly convert opaque native handle results")

Local nativeManagedResult:TCompilerResult = TBlitzMaxCompiler.Compile("native-managed-result.bmx", "SuperStrict~nExtern~nFunction NativeArray:Object(length:Int)=~qBBArray* NativeArray(int)!~q~nEnd Extern~nLocal value:Object=NativeArray(1)", resolver, TestOptions())
Local nativeManagedResultDiagnostics:TCompilerDiagnostic[]
Local nativeManagedResultC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeManagedResult, nativeManagedResultDiagnostics)
Check(nativeManagedResult.Succeeded() And nativeManagedResultDiagnostics.length = 0 And nativeManagedResult.ir.externalFunctions[0].nativeReturnType = "BBArray*" And Contains(nativeManagedResultC, "((BBOBJECT)(NativeArray(((int)1))))"), "a specific managed native pointer result is explicitly converted to its broader BlitzMax Object ABI type")

Local publishedNativeCasts:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nativecasts.mod/nativecasts.bmx", "SuperStrict~nModule acme.nativecasts~nExtern~nFunction NativeRead:Size_T(buffer:Byte Ptr,size:Size_T,count:Size_T,stream:Byte Ptr)=~qsize_t fread(void*,size_t,size_t,FILE*)!~q~nEnd Extern", resolver, TestOptions())
Local publishedNativeCastsInterfaceDiagnostics:TCompilerDiagnostic[]
Local publishedNativeCastsInterface:String = TBlitzMaxCompiler.EmitInterface(publishedNativeCasts, publishedNativeCastsInterfaceDiagnostics)
Check(publishedNativeCasts.Succeeded() And publishedNativeCastsInterfaceDiagnostics.length = 0 And Contains(publishedNativeCastsInterface, "=~qsize_t fread(void*,size_t,size_t,FILE*)!~q"), "compact interfaces preserve complete native declarations and their trailing prototype-ownership marker")
resolver.AddInterface("acme.nativecasts", "sdk/acme.nativecasts.i", publishedNativeCastsInterface)
Local publishedNativeCastsConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("published-native-casts-consumer.bmx", "SuperStrict~nImport acme.nativecasts~nLocal buffer:Byte Ptr~nLocal stream:Byte Ptr~nLocal count:Size_T=NativeRead(buffer,1,1,stream)", resolver, TestOptions())
Local publishedNativeCastsConsumerDiagnostics:TCompilerDiagnostic[]
Local publishedNativeCastsConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(publishedNativeCastsConsumer, publishedNativeCastsConsumerDiagnostics)
Check(publishedNativeCastsConsumer.Succeeded() And publishedNativeCastsConsumerDiagnostics.length = 0 And publishedNativeCastsConsumer.ir.externalFunctions.length = 1 And publishedNativeCastsConsumer.ir.externalFunctions[0].nativeParameterTypes[3] = "FILE*" And Contains(publishedNativeCastsConsumerC, "((FILE*)bmx_v1_stream)"), "a later compilation reconstructs typedef-rich native call casts from the compact interface")

Local winParamOptions:TCompilerOptions = TestOptions()
winParamOptions.targetPlatform = "win32"
winParamOptions.conditionalSymbols = ["win32", "x64", "ptr64", "threaded", "bmxng"]
Local publishedWinParams:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/winparams.mod/winparams.bmx", "SuperStrict~nModule acme.winparams~nExtern ~qWin32~q~nFunction NativeWParam:WParam(value:LParam)=~qWPARAM NativeWParam(LPARAM)!~q~nEnd Extern", resolver, winParamOptions)
Local publishedWinParamDiagnostics:TCompilerDiagnostic[]
Local publishedWinParamInterface:String = TBlitzMaxCompiler.EmitInterface(publishedWinParams, publishedWinParamDiagnostics)
Check(publishedWinParams.Succeeded() And publishedWinParamDiagnostics.length = 0 And Contains(publishedWinParamInterface, "NativeWParam%w(value%x)"), "compact interfaces publish the Win32 WParam and LParam primitive encodings")
resolver.AddInterface("acme.winparams", "sdk/acme.winparams.i", publishedWinParamInterface)
Local publishedWinParamConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("winparam-consumer.bmx", "SuperStrict~nImport acme.winparams~nLocal value:WParam=NativeWParam(LParam(0))", resolver, winParamOptions)
Check(publishedWinParamConsumer.Succeeded(), "compact-interface consumers reconstruct WParam and LParam signatures")

Local retainedLineDiagnostic:TCompilerDiagnostic = TCompilerDiagnostic.Create("BMXC9999", "location probe", "user32.bmx", Null, 1184, 0)
Check(retainedLineDiagnostic.Format() = "user32.bmx:1184:1: error BMXC9999: location probe", "compiler diagnostics use retained IR line and column when no source span is available")

Local standardNativePrototype:TCompilerResult = TBlitzMaxCompiler.Compile("standard-native-prototype.bmx", "SuperStrict~nExtern~nFunction strlen:Size_T(value:Byte Ptr)~nFunction bmx_custom_length:Size_T(value:Byte Ptr)~nEnd Extern", resolver, TestOptions())
Local standardNativePrototypeDiagnostics:TCompilerDiagnostic[]
Local standardNativePrototypeC:String = TBlitzMaxCompiler.EmitRuntimeC(standardNativePrototype, standardNativePrototypeDiagnostics)
Check(standardNativePrototype.Succeeded() And standardNativePrototypeDiagnostics.length = 0 And Not Contains(standardNativePrototypeC, "extern BBSIZET strlen(") And Contains(standardNativePrototypeC, "extern BBSIZET bmx_custom_length("), "standard C routines retain system-header prototype authority without suppressing ordinary native declarations")

Local externalConstants:TCompilerResult = TBlitzMaxCompiler.Compile("external-constants.bmx", "SuperStrict~nExtern~nConst MASK_COLOR:Int=2~nConst MASK_ALPHA:Int=4~nConst TYPE_RGBA:Int=MASK_COLOR|MASK_ALPHA~nEnd Extern~nGlobal Selected:Int=TYPE_RGBA", resolver, TestOptions())
Local externalConstantsDiagnostics:TCompilerDiagnostic[]
Local externalConstantsC:String = TBlitzMaxCompiler.EmitRuntimeC(externalConstants, externalConstantsDiagnostics)
Check(externalConstants.Succeeded() And externalConstants.ir.externalGlobals.length = 0, "Extern Const values lower without native Global storage")
Check(externalConstantsDiagnostics.length = 0 And Contains(externalConstantsC, " = 6;"), "Extern Const references fold into their consuming runtime initializer")

Local nativeStrings:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nativestrings.mod/nativestrings.bmx", "SuperStrict~nModule acme.nativestrings~nExtern~nFunction NativeText:Int(utf8$z,utf16$w)=~qbcc2_native_text~q~nEnd Extern~nFunction Probe:Int(value:String)~nReturn NativeText(value,value)~nEnd Function", resolver, TestOptions())
Local nativeStringsDiagnostics:TCompilerDiagnostic[]
Local nativeStringsC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeStrings, nativeStringsDiagnostics)
Local nativeStringsInterfaceDiagnostics:TCompilerDiagnostic[]
Local nativeStringsInterface:String = TBlitzMaxCompiler.EmitInterface(nativeStrings, nativeStringsInterfaceDiagnostics)
Check(nativeStrings.Succeeded() And nativeStrings.ir.externalFunctions[0].parameters[0].nativeStringEncoding = NATIVE_STRING_UTF8 And nativeStrings.ir.externalFunctions[0].parameters[1].nativeStringEncoding = NATIVE_STRING_UTF16, "typed IR retains distinct native String parameter encodings")
Check(nativeStringsDiagnostics.length = 0 And Contains(nativeStringsC, "extern BBINT bcc2_native_text(BBBYTE * ") And Contains(nativeStringsC, "BBChar * ") And Contains(nativeStringsC, "bbStringToCString(") And Contains(nativeStringsC, "bbStringToWString(") And Occurrences(nativeStringsC, "bbMemFree(") >= 2, "runtime C wraps $z and $w calls with encoded temporary allocation and cleanup")
Check(nativeStringsInterfaceDiagnostics.length = 0 And Contains(nativeStringsInterface, "utf8$z") And Contains(nativeStringsInterface, "utf16$w"), "compact interfaces preserve $z and $w native String contracts")

Local nativeStringReturn:TCompilerResult = TBlitzMaxCompiler.Compile("native-string-return.bmx", "SuperStrict~nExtern~nFunction NativeWide$w(name$w)=~qbcc2_native_wide~q~nEnd Extern~nFunction Probe:String(name:String)~nReturn NativeWide(name)~nEnd Function", resolver, TestOptions())
Local nativeStringReturnDiagnostics:TCompilerDiagnostic[]
Local nativeStringReturnC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeStringReturn, nativeStringReturnDiagnostics)
Check(nativeStringReturn.Succeeded(), "native $w result fixture compiles")
Check(nativeStringReturnDiagnostics.length = 0, "native $w result fixture emits runtime C without diagnostics")
Check(nativeStringReturn.ir.externalFunctions.length = 1 And nativeStringReturn.ir.externalFunctions[0].nativeStringReturnEncoding = NATIVE_STRING_UTF16, "typed IR retains native $w result encoding")
Check(Contains(nativeStringReturnC, "extern BBChar * bcc2_native_wide(BBChar * "), "native $w result publishes the native pointer prototype")
Check(Contains(nativeStringReturnC, "BBChar * bmx_native_result = bcc2_native_wide("), "native $w result wrapper receives a native pointer")
Check(Contains(nativeStringReturnC, "return bbStringFromWString(bmx_native_result);"), "runtime C converts native $w results back into managed BlitzMax strings")

Local implicitNativeString:TCompilerResult = TBlitzMaxCompiler.Compile("implicit-native-string.bmx", "SuperStrict~nExtern~nFunction NativeBytes:Int(value:Byte Ptr)=~qbcc2_native_bytes~q~nEnd Extern~nFunction Probe:Int(value:String)~nReturn NativeBytes(value)~nEnd Function", resolver, TestOptions())
Local implicitNativeStringDiagnostics:TCompilerDiagnostic[]
Local implicitNativeStringC:String = TBlitzMaxCompiler.EmitRuntimeC(implicitNativeString, implicitNativeStringDiagnostics)
Check(implicitNativeString.Succeeded() And implicitNativeStringDiagnostics.length = 0, "implicit String-to-Byte Ptr calls lower through an owned native temporary")
Check(Contains(implicitNativeStringC, "BBBYTE *bmx_native_string_0 = (BBBYTE *)bbStringToCString(") And Contains(implicitNativeStringC, "bcc2_native_bytes(bmx_native_string_0)") And Contains(implicitNativeStringC, "bbMemFree(bmx_native_string_0);"), "implicit String-to-Byte Ptr calls allocate, consume, and free one named C string")
Check(AppearsBefore(implicitNativeStringC, "bcc2_native_bytes(bmx_native_string_0)", "bbMemFree(bmx_native_string_0);") And AppearsBefore(implicitNativeStringC, "bbMemFree(bmx_native_string_0);", "return bmx_native_return_0;"), "a native-call return value is materialized before its temporary is freed")

Local multipleImplicitNativeStrings:TCompilerResult = TBlitzMaxCompiler.Compile("multiple-implicit-native-strings.bmx", "SuperStrict~nExtern~nFunction NativePair:Int(left:Byte Ptr,right:Byte Ptr)=~qbcc2_native_pair~q~nEnd Extern~nFunction Probe:Int(left:String,right:String)~nReturn NativePair(left,right)~nEnd Function", resolver, TestOptions())
Local multipleImplicitNativeStringDiagnostics:TCompilerDiagnostic[]
Local multipleImplicitNativeStringC:String = TBlitzMaxCompiler.EmitRuntimeC(multipleImplicitNativeStrings, multipleImplicitNativeStringDiagnostics)
Check(multipleImplicitNativeStrings.Succeeded() And multipleImplicitNativeStringDiagnostics.length = 0 And Occurrences(multipleImplicitNativeStringC, "bbStringToCString(") = 2 And Occurrences(multipleImplicitNativeStringC, "bbMemFree(bmx_native_string_") = 2, "each implicit native String argument owns exactly one temporary")
Check(AppearsBefore(multipleImplicitNativeStringC, "bbMemFree(bmx_native_string_1);", "bbMemFree(bmx_native_string_0);"), "multiple implicit native String temporaries are released in reverse allocation order")

Local statementImplicitNativeStrings:TCompilerResult = TBlitzMaxCompiler.Compile("statement-implicit-native-strings.bmx", "SuperStrict~nExtern~nFunction NativeConsume(value:Byte Ptr)=~qbcc2_native_consume~q~nEnd Extern~nFunction Probe(value:String)~nNativeConsume(value)~nLocal pointer:Byte Ptr=value~npointer=value~nEnd Function", resolver, TestOptions())
Local statementImplicitNativeStringDiagnostics:TCompilerDiagnostic[]
Local statementImplicitNativeStringC:String = TBlitzMaxCompiler.EmitRuntimeC(statementImplicitNativeStrings, statementImplicitNativeStringDiagnostics)
Check(statementImplicitNativeStrings.Succeeded() And statementImplicitNativeStringDiagnostics.length = 0 And Occurrences(statementImplicitNativeStringC, "bbStringToCString(") = 3 And Occurrences(statementImplicitNativeStringC, "bbMemFree(bmx_native_string_") = 3, "expression, declaration, and assignment statements release each implicit native String temporary")

Local conditionalImplicitNativeStrings:TCompilerResult = TBlitzMaxCompiler.Compile("conditional-implicit-native-strings.bmx", "SuperStrict~nExtern~nFunction NativeTruth:Int(value:Byte Ptr)=~qbcc2_native_truth~q~nEnd Extern~nGlobal NativeConditionCount:Int~nFunction Probe(value:String)~nIf NativeTruth(value) Then~nNativeConditionCount:+1~nElseIf NativeTruth(value) Then~nNativeConditionCount:+2~nEnd If~nWhile NativeTruth(value)~nExit~nWend~nRepeat~nUntil NativeTruth(value)~nEnd Function", resolver, TestOptions())
Local conditionalImplicitNativeStringDiagnostics:TCompilerDiagnostic[]
Local conditionalImplicitNativeStringC:String = TBlitzMaxCompiler.EmitRuntimeC(conditionalImplicitNativeStrings, conditionalImplicitNativeStringDiagnostics)
Check(conditionalImplicitNativeStrings.Succeeded() And conditionalImplicitNativeStringDiagnostics.length = 0 And Occurrences(conditionalImplicitNativeStringC, "bbStringToCString(") = 4 And Occurrences(conditionalImplicitNativeStringC, "bbMemFree(bmx_native_string_") = 4, "branch and loop conditions release every implicit native String temporary")
Check(Occurrences(conditionalImplicitNativeStringC, "for (;;) {") >= 2 And Occurrences(conditionalImplicitNativeStringC, "BBINT bmx_native_condition_") = 4, "temporary-owning While and Repeat conditions materialize a scalar result before cleanup on every test")

Local selectImplicitNativeString:TCompilerResult = TBlitzMaxCompiler.Compile("select-implicit-native-string.bmx", "SuperStrict~nExtern~nFunction NativeValue:Int(value:Byte Ptr)=~qbcc2_native_value~q~nEnd Extern~nFunction Probe:Int(value:String)~nSelect NativeValue(value)~nCase 1~nReturn 1~nEnd Select~nReturn 0~nEnd Function", resolver, TestOptions())
Local selectImplicitNativeStringDiagnostics:TCompilerDiagnostic[]
Local selectImplicitNativeStringC:String = TBlitzMaxCompiler.EmitRuntimeC(selectImplicitNativeString, selectImplicitNativeStringDiagnostics)
Check(selectImplicitNativeString.Succeeded() And selectImplicitNativeStringDiagnostics.length = 0 And AppearsBefore(selectImplicitNativeStringC, "bbMemFree(bmx_native_string_0);", "if (bmx_tmp_"), "Select materializes its selector and frees the implicit native String before dispatching a case")

Local conditionalNative:TCompilerResult = TBlitzMaxCompiler.Compile("conditional-native.bmx", "SuperStrict~nExtern~n?test~nGlobal NativeHandle:Byte Ptr = ~qbcc2_native_handle~q~n?win32~nGlobal NativeHandle:Byte Ptr = ~qbcc2_windows_handle~q~n?~nEnd Extern~nNativeHandle=Null", resolver, TestOptions())
Check(conditionalNative.Succeeded() And conditionalNative.ir.externalGlobals.length = 1 And conditionalNative.ir.externalGlobals[0].abiName = "bcc2_native_handle", "active conditional Extern declarations flatten through the configured snapshot")
Local conditionalTopLevelNative:TCompilerResult = TBlitzMaxCompiler.Compile("conditional-top-level-native.bmx", "SuperStrict~n?test~nExtern~nFunction NativeVersion:Int(major:Int Var)=~qbcc2_native_version~q~nEnd Extern~n?~nLocal major:Int~nNativeVersion(major)", resolver, TestOptions())
Check(conditionalTopLevelNative.Succeeded() And conditionalTopLevelNative.ir.externalFunctions.length = 1 And conditionalTopLevelNative.ir.externalFunctions[0].abiName = "bcc2_native_version", "an active top-level conditional region publishes and lowers its Extern declarations")

Local nativeGlobal:TCompilerResult = TBlitzMaxCompiler.Compile("native-global.bmx", "SuperStrict~nExtern~nGlobal NativeCounter:Int = ~qbcc2_native_counter~q~nGlobal NativeBuffer:Byte Ptr = ~qbcc2_native_buffer~q~nGlobal NativeCallback:Int(left:Int,right:Int) = ~qbcc2_native_callback~q~nEnd Extern~nFunction NativeReplacement:Int(left:Int,right:Int)~nReturn left + right~nEnd Function~nGlobal Result:Int = NativeCounter~nGlobal CallbackResult:Int = NativeCallback(20,22)~nNativeCounter = Result + 1~nNativeBuffer = 0~nNativeCallback = NativeReplacement", resolver, TestOptions())
Check(nativeGlobal.Succeeded(), "source Extern scalar, pointer, and callable Globals lower successfully")
Check(nativeGlobal.ir.externalGlobals.length = 3 And nativeGlobal.ir.externalGlobals[0].abiName = "bcc2_native_counter" And nativeGlobal.ir.externalGlobals[1].semanticType = "Byte Ptr" And nativeGlobal.ir.externalGlobals[2].callableReturnType = "Int", "external Global storage identity and scalar, pointer, and callable ABI types are retained in IR")
Local nativeGlobalDump:String = TCompilerIrDumper.Dump(nativeGlobal.ir)
Check(Contains(nativeGlobalDump, "external-global %extg0 NativeCounter:Int abi bcc2_native_counter") And Contains(nativeGlobalDump, "external-global %extg2 NativeCallback:Int(Int, Int) abi bcc2_native_callback [callable Int(Int, Int)]") And Contains(nativeGlobalDump, "symbol external %extg0 NativeCounter : Int") And Contains(nativeGlobalDump, "call-indirect (Int)"), "IR dump distinguishes external Global declarations, references, and callable invocation")
Local nativeGlobalRuntimeDiagnostics:TCompilerDiagnostic[]
Local nativeGlobalRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeGlobal, nativeGlobalRuntimeDiagnostics)
Check(nativeGlobalRuntimeDiagnostics.length = 0, "runtime backend emits external Global references")
Check(Contains(nativeGlobalRuntimeC, "extern BBINT bcc2_native_counter;") And Contains(nativeGlobalRuntimeC, "extern BBBYTE * bcc2_native_buffer;") And Contains(nativeGlobalRuntimeC, "extern BBINT (*bcc2_native_callback)(BBINT, BBINT);") And Contains(nativeGlobalRuntimeC, "bcc2_native_counter =") And Contains(nativeGlobalRuntimeC, "(bcc2_native_callback)(20, 22)") And Contains(nativeGlobalRuntimeC, "bcc2_native_callback = bmx_fn0_NativeReplacement;"), "runtime C declares scalar, production-typed Byte pointers, and callable native Global storage")

Local pointerArithmetic:TCompilerResult = TBlitzMaxCompiler.Compile("pointer-arithmetic.bmx", "SuperStrict~nLocal buffer:Byte Ptr = bbMemAlloc(16)~nLocal shifted:Byte Ptr = buffer + 1~nLocal previous:Byte Ptr=shifted-1~nLocal distance:Size_T=shifted-buffer~nLocal fixed:Byte[16]~nLocal used:Size_T=shifted-fixed~nLocal same:Int=buffer=previous~nbuffer:+2~nbuffer:-1~nbbMemFree(buffer)", resolver, TestOptions())
Local pointerArithmeticDump:String = TCompilerIrDumper.Dump(pointerArithmetic.ir)
Local pointerArithmeticDiagnostics:TCompilerDiagnostic[]
Local pointerArithmeticC:String = TBlitzMaxCompiler.EmitRuntimeC(pointerArithmetic, pointerArithmeticDiagnostics)
Check(pointerArithmetic.Succeeded() And Contains(pointerArithmeticDump, "pointer-binary + : Byte Ptr") And Contains(pointerArithmeticDump, "pointer-binary - : Byte Ptr") And Contains(pointerArithmeticDump, "pointer-binary - : Int") And Contains(pointerArithmeticDump, "convert implicit array-to-pointer : Byte Ptr") And Contains(pointerArithmeticDump, "pointer-binary = : Int"), "typed IR distinguishes raw pointer movement, pointer differences including managed Array decay, and comparison from scalar binary operations")
Check(pointerArithmeticDiagnostics.length = 0 And Contains(pointerArithmeticC, "bmx_v0_buffer + 1") And Contains(pointerArithmeticC, "bmx_v1_shifted - 1") And Contains(pointerArithmeticC, "bmx_v1_shifted - bmx_v0_buffer") And Contains(pointerArithmeticC, "bmx_v1_shifted - ((BBBYTE *)BBARRAYDATA(bmx_v4_fixed, 1))") And Contains(pointerArithmeticC, "bmx_v0_buffer += 2;") And Contains(pointerArithmeticC, "bmx_v0_buffer -= 1;"), "runtime C emits typed pointer movement, pointer and Array-storage differences, comparison, and compound movement directly")
Local pointerArrayDecay:TCompilerResult = TBlitzMaxCompiler.Compile("pointer-array-decay.bmx", "SuperStrict~nExtern~nFunction NativeRows(rows:Byte Ptr)=~qbcc2_native_rows~q~nEnd Extern~nLocal rows:Byte Ptr[4]~nNativeRows(rows)", resolver, TestOptions())
Local pointerArrayDecayDump:String = TCompilerIrDumper.Dump(pointerArrayDecay.ir)
Local pointerArrayDecayDiagnostics:TCompilerDiagnostic[]
Local pointerArrayDecayC:String = TBlitzMaxCompiler.EmitRuntimeC(pointerArrayDecay, pointerArrayDecayDiagnostics)
Check(pointerArrayDecay.Succeeded() And Contains(pointerArrayDecayDump, "convert implicit array-to-pointer : Byte Ptr"), "typed IR retains heap pointer-Array raw-storage conversion")
Check(pointerArrayDecayDiagnostics.length = 0 And Contains(pointerArrayDecayC, "bcc2_native_rows(((BBBYTE *)BBARRAYDATA(bmx_v0_rows, 1)))"), "runtime C exposes contiguous pointer-Array storage at the native Byte Ptr boundary")
Local regroupedArrayDecay:TCompilerResult = TBlitzMaxCompiler.Compile("regrouped-array-decay.bmx", "SuperStrict~nStruct SNativeVec~nField x:Float~nField y:Float~nEnd Struct~nExtern~nFunction NativeVecs(values:SNativeVec Ptr,count:Int)=~qbcc2_native_vecs~q~nEnd Extern~nLocal coordinates:Float[]~nNativeVecs(coordinates,coordinates.Length/2)", resolver, TestOptions())
Local regroupedArrayDecayDiagnostics:TCompilerDiagnostic[]
Local regroupedArrayDecayC:String = TBlitzMaxCompiler.EmitRuntimeC(regroupedArrayDecay, regroupedArrayDecayDiagnostics)
Check(regroupedArrayDecay.Succeeded() And regroupedArrayDecayDiagnostics.length = 0, "numeric Array storage lowers through a differently grouped native Struct pointer ABI")
Check(Contains(regroupedArrayDecayC, "bcc2_native_vecs(((struct bmx_struct_st0_SNativeVec *)BBARRAYDATA(bmx_v0_coordinates, 1))"), "runtime C casts contiguous numeric cells to the requested native Struct pointer")
Local objectFieldStorage:TCompilerResult = TBlitzMaxCompiler.Compile("object-field-storage.bmx", "SuperStrict~nType THeader~nField kind:Byte~nField size:Int~nEnd Type~nFunction ReadStorage(buffer:Byte Ptr,count:Long)~nEnd Function~nLocal header:THeader=New THeader~nReadStorage(header,5)", resolver, TestOptions())
Local objectFieldStorageDump:String = TCompilerIrDumper.Dump(objectFieldStorage.ir)
Local objectFieldStorageDiagnostics:TCompilerDiagnostic[]
Local objectFieldStorageC:String = TBlitzMaxCompiler.EmitRuntimeC(objectFieldStorage, objectFieldStorageDiagnostics)
Check(objectFieldStorage.Succeeded() And Contains(objectFieldStorageDump, "convert implicit object-to-byte-pointer : Byte Ptr"), "typed IR retains managed Type field-storage conversion independently from its object header")
Check(objectFieldStorageDiagnostics.length = 0 And Contains(objectFieldStorageC, "bbObjectToFieldOffset((BBObject *)"), "runtime C addresses the first managed Type field through the runtime field-offset helper")
Local invalidBaseObjectFieldStorage:TCompilerResult = TBlitzMaxCompiler.Compile("invalid-base-object-field-storage.bmx", "SuperStrict~nType TStorageOwner~nField storage:Byte Ptr~nMethod SetStorage(value:Object)~nstorage=value~nEnd Method~nEnd Type", resolver, TestOptions())
Check(Not invalidBaseObjectFieldStorage.Succeeded() And HasLanguageDiagnostic(invalidBaseObjectFieldStorage, "BMX3310"), "compiler rejects arbitrary Object assignment to a native field-storage pointer")
Local pointerUnary:TCompilerResult = TBlitzMaxCompiler.Compile("pointer-unary.bmx", "SuperStrict~nLocal value:Int=42~nLocal address:Int Ptr=VarPtr value~nLocal missing:Int=Not address", resolver, TestOptions())
Local pointerUnaryDump:String = TCompilerIrDumper.Dump(pointerUnary.ir)
Local pointerUnaryDiagnostics:TCompilerDiagnostic[]
Local pointerUnaryC:String = TBlitzMaxCompiler.EmitRuntimeC(pointerUnary, pointerUnaryDiagnostics)
Check(pointerUnary.Succeeded() And Contains(pointerUnaryDump, "address-of : Int Ptr") And Contains(pointerUnaryDump, "pointer-not : Int"), "VarPtr and pointer Not retain distinct typed address and truth operations")
Check(pointerUnaryDiagnostics.length = 0 And Contains(pointerUnaryC, "BBINT * bmx_v1_address = (&bmx_v0_value);") And Contains(pointerUnaryC, "(bmx_v1_address == 0)"), "runtime C emits direct address-taking and null pointer truth without integer coercion")
Local pointerMeasure:TCompilerResult = TBlitzMaxCompiler.Compile("pointer-measure.bmx", "SuperStrict~nStruct SMeasured~nField value:Int~nEnd Struct~nLocal byteSize:Size_T=SizeOf Byte Null~nLocal intAlignment:Size_T=AlignOf Int Null~nLocal pointerSize:Size_T=SizeOf Byte Ptr Null~nLocal pointerAlignment:Size_T=AlignOf Byte Ptr Null~nLocal structSize:Size_T=SizeOf(SMeasured)", resolver, TestOptions())
Local pointerMeasureDiagnostics:TCompilerDiagnostic[]
Local pointerMeasureC:String = TBlitzMaxCompiler.EmitRuntimeC(pointerMeasure, pointerMeasureDiagnostics)
Check(pointerMeasure.Succeeded() And pointerMeasureDiagnostics.length = 0 And Contains(pointerMeasureC, "sizeof(BBBYTE)") And Contains(pointerMeasureC, "__alignof__(BBINT)") And Contains(pointerMeasureC, "sizeof(BBBYTE *)") And Contains(pointerMeasureC, "__alignof__(BBBYTE *)") And Contains(pointerMeasureC, "sizeof(struct bmx_struct_st0_SMeasured)"), "SizeOf and AlignOf preserve scalar, pointer, and parenthesized Struct type expressions without evaluating their operands")
Local x64VectorMeasure:TCompilerResult = TBlitzMaxCompiler.Compile("x64-vector-measure.bmx", "SuperStrict~n? x64~nLocal float64Size:Size_T=SizeOf(Float64 Null)~nLocal float128Size:Size_T=SizeOf(Float128 Null)~nLocal double128Size:Size_T=SizeOf(Double128 Null)~nLocal int128Size:Size_T=SizeOf(Int128 Null)~n?", resolver, win64StdCallOptions)
Local x64VectorMeasureDiagnostics:TCompilerDiagnostic[]
Local x64VectorMeasureC:String = TBlitzMaxCompiler.EmitRuntimeC(x64VectorMeasure, x64VectorMeasureDiagnostics)
Check(x64VectorMeasure.Succeeded() And x64VectorMeasureDiagnostics.length = 0 And Contains(x64VectorMeasureC, "sizeof(BBFLOAT64)") And Contains(x64VectorMeasureC, "sizeof(BBFLOAT128)") And Contains(x64VectorMeasureC, "sizeof(BBDOUBLE128)") And Contains(x64VectorMeasureC, "sizeof(BBINT128)"), "x64 SIMD SizeOf expressions use the production runtime typedef ABI")
Local x64VectorNative:TCompilerResult = TBlitzMaxCompiler.Compile("x64-vector-native.bmx", "SuperStrict~nExtern~nFunction SetFloat128:Float128(value:Float)=~q__m128 _mm_set1_ps(float)!~q~nFunction AddFloat128:Float128(left:Float128,right:Float128)=~q__m128 _mm_add_ps(__m128,__m128)!~q~nFunction AddDouble128:Double128(left:Double128,right:Double128)=~q__m128d _mm_add_pd(__m128d,__m128d)!~q~nFunction AddInt128:Int128(left:Int128,right:Int128)=~q__m128i _mm_add_epi32(__m128i,__m128i)!~q~nFunction StoreFloat128(target:Float Ptr,value:Float128)=~qvoid _mm_storeu_ps(float*,__m128)!~q~nEnd Extern~nLocal left:Float128=SetFloat128(20)~nLocal right:Float128=SetFloat128(22)~nLocal combined:Float128=AddFloat128(left,right)~nLocal output:Float[4]~nStoreFloat128(output,combined)", resolver, win64StdCallOptions)
Local x64VectorNativeDiagnostics:TCompilerDiagnostic[]
Local x64VectorNativeC:String = TBlitzMaxCompiler.EmitRuntimeC(x64VectorNative, x64VectorNativeDiagnostics)
Check(x64VectorNative.Succeeded() And x64VectorNativeDiagnostics.length = 0 And x64VectorNative.ir.externalFunctions.length = 5, "x64 SIMD values cross native routine result and parameter ABIs")
Check(Contains(x64VectorNativeC, "BBFLOAT128 bmx_v0_left") And Contains(x64VectorNativeC, "_mm_add_ps(((__m128)bmx_v0_left), ((__m128)bmx_v1_right))") And Contains(x64VectorNativeC, "_mm_storeu_ps(((float*)") And Contains(x64VectorNativeC, "((__m128)bmx_v2_combined)"), "runtime C retains SIMD typedef storage and intrinsic-native call casts")
Local x64VectorModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/vector.mod/vector.bmx", "SuperStrict~nModule acme.vector~nExtern~nFunction AddFloat64:Float64(left:Float64,right:Float64)=~q__m64 _mm_add_pi32(__m64,__m64)!~q~nFunction AddInt128:Int128(left:Int128,right:Int128)=~q__m128i _mm_add_epi32(__m128i,__m128i)!~q~nFunction AddFloat128:Float128(left:Float128,right:Float128)=~q__m128 _mm_add_ps(__m128,__m128)!~q~nFunction AddDouble128:Double128(left:Double128,right:Double128)=~q__m128d _mm_add_pd(__m128d,__m128d)!~q~nEnd Extern", resolver, win64StdCallOptions)
Local x64VectorInterfaceDiagnostics:TCompilerDiagnostic[]
Local x64VectorInterface:String = TBlitzMaxCompiler.EmitInterface(x64VectorModule, x64VectorInterfaceDiagnostics)
Check(x64VectorModule.Succeeded() And x64VectorInterfaceDiagnostics.length = 0 And Contains(x64VectorInterface, "AddFloat64!h(left!h,right!h)") And Contains(x64VectorInterface, "AddInt128%j(left%j,right%j)") And Contains(x64VectorInterface, "AddFloat128!k(left!k,right!k)") And Contains(x64VectorInterface, "AddDouble128!m(left!m,right!m)"), "compact interfaces publish every production SIMD value encoding")
resolver.AddInterface("acme.vector", "sdk/acme.vector.i", x64VectorInterface)
Local x64VectorConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("x64-vector-consumer.bmx", "SuperStrict~nImport acme.vector~nLocal left:Float128~nLocal right:Float128~nLocal result:Float128=AddFloat128(left,right)", resolver, win64StdCallOptions)
Local x64VectorConsumerDiagnostics:TCompilerDiagnostic[]
Local x64VectorConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(x64VectorConsumer, x64VectorConsumerDiagnostics)
Check(x64VectorConsumer.Succeeded() And x64VectorConsumerDiagnostics.length = 0 And Contains(x64VectorConsumerC, "_mm_add_ps(((__m128)bmx_v0_left), ((__m128)bmx_v1_right))"), "a source-free compact-interface consumer reconstructs the SIMD native call ABI")
Local pointerLogic:TCompilerResult = TBlitzMaxCompiler.Compile("pointer-logic.bmx", "SuperStrict~nLocal left:Byte Ptr~nLocal right:Byte Ptr~nLocal either:Int=left Or right~nLocal both:Int=left And right", resolver, TestOptions())
Local pointerLogicDiagnostics:TCompilerDiagnostic[]
Local pointerLogicC:String = TBlitzMaxCompiler.EmitRuntimeC(pointerLogic, pointerLogicDiagnostics)
Check(pointerLogic.Succeeded() And pointerLogicDiagnostics.length = 0 And Contains(pointerLogicC, "(bmx_v0_left || bmx_v1_right)") And Contains(pointerLogicC, "(bmx_v0_left && bmx_v1_right)"), "pointer operands participate in short-circuit truth without becoming integer pointers")
Local contextualNull:TCompilerResult = TBlitzMaxCompiler.Compile("contextual-null.bmx", "SuperStrict~nType TNullValue~nField parent:TNullValue=Null~nEnd Type~nStruct SNullValue~nField text:String~nField amount:Int~nEnd Struct~nFunction EmptyString:String()~nReturn Null~nEnd Function~nFunction EmptyArray:Int[]()~nReturn Null~nEnd Function~nFunction EmptyObject:TNullValue()~nReturn Null~nEnd Function~nFunction EmptyStruct:SNullValue()~nReturn Null~nEnd Function~nFunction EmptyPointer:Byte Ptr()~nReturn Null~nEnd Function", resolver, TestOptions())
Local contextualNullDump:String = TCompilerIrDumper.Dump(contextualNull.ir)
Local contextualNullDiagnostics:TCompilerDiagnostic[]
Local contextualNullC:String = TBlitzMaxCompiler.EmitRuntimeC(contextualNull, contextualNullDiagnostics)
Check(contextualNull.Succeeded() And Contains(contextualNullDump, "managed-default String : String") And Contains(contextualNullDump, "managed-default Array : Int[]") And Contains(contextualNullDump, "managed-default Object : TNullValue") And Contains(contextualNullDump, "struct-new @st0 : SNullValue") And Contains(contextualNullDump, "literal 0 : Byte Ptr"), "contextual Null returns lower to the declared managed, Struct, or pointer default without retaining an untyped Null expression")
Local scalarNull:TCompilerResult = TBlitzMaxCompiler.Compile("scalar-null.bmx", "SuperStrict~nEnum ENullState~nMissing~nEnd Enum~nFunction EmptyByte:Byte()~nReturn Null~nEnd Function~nFunction EmptyState:ENullState()~nReturn Null~nEnd Function", resolver, TestOptions())
Check(scalarNull.Succeeded() And Contains(TCompilerIrDumper.Dump(scalarNull.ir), "literal 0 : Byte") And Contains(TCompilerIrDumper.Dump(scalarNull.ir), "literal 0 : ENullState"), "contextual Null lowers to scalar and Enum zero defaults")
Check(contextualNullDiagnostics.length = 0 And Contains(contextualNullC, "return &bbEmptyString;") And Contains(contextualNullC, "return &bbEmptyArray;") And Contains(contextualNullC, "return ((struct bmx_cls0_TNullValue_obj *)&bbNullObject);") And Contains(contextualNullC, "return bmx_struct_new_bmx_class_st0_SNullValue_default();") And Contains(contextualNullC, "return 0;"), "runtime C uses the ABI sentinel or typed value default for each contextual Null return type")
Local structPointerField:TCompilerResult = TBlitzMaxCompiler.Compile("struct-pointer-field.bmx", "SuperStrict~nStruct SPointedValue~nField value:Int~nEnd Struct~nFunction SetPointedValue:Int(item:SPointedValue Ptr)~nitem.value=42~nReturn item.value~nEnd Function~nLocal item:SPointedValue~nLocal result:Int=SetPointedValue(VarPtr item)", resolver, TestOptions())
Local structPointerFieldDump:String = TCompilerIrDumper.Dump(structPointerField.ir)
Local structPointerFieldDiagnostics:TCompilerDiagnostic[]
Local structPointerFieldC:String = TBlitzMaxCompiler.EmitRuntimeC(structPointerField, structPointerFieldDiagnostics)
Check(structPointerField.Succeeded() And Occurrences(structPointerFieldDump, "[pointer-receiver]") = 2, "Struct-pointer field reads and writes retain their pointer receiver independently from the Struct layout")
Check(structPointerFieldDiagnostics.length = 0 And Contains(structPointerFieldC, "(bmx_p0_item->_bmx_class_st0_spointedvalue_value) = 42") And Contains(structPointerFieldC, "return (bmx_p0_item->_bmx_class_st0_spointedvalue_value);"), "runtime C uses direct pointer-member access for Struct Ptr receivers")

Local moduleResult:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/sample.mod/sample.bmx", "SuperStrict~nModule acme.sample~nPrivate~nFunction CompareValues:Int(left:Int,right:Int)~nReturn left-right~nEnd Function~nPublic~nFunction DefaultCompare:Int(a:Int,b:Int)~nReturn a-b~nEnd Function~nFunction Apply:Int(left:Int,right:Int=1,callback:Int(a:Int,b:Int)=DefaultCompare)~nReturn callback(left,right)~nEnd Function~nFunction Describe:String(value:String=~qready~q)~nReturn value~nEnd Function~nGlobal Value:Int = 1~nGlobal Compare:Int(left:Int,right:Int)=CompareValues~nPrivate~nGlobal Hidden:Int~nPublic~nConst DefaultValue:Int=3+4~nConst Label:String=~qsample~q", resolver, TestOptions())
Check(moduleResult.Succeeded(), "module unit with scalar and callable Globals lowers successfully")
Check(moduleResult.ir.initializationPlan.unitKind = IR_UNIT_MODULE And moduleResult.ir.initializationPlan.unitName = "__bb_acme_sample_sample", "module unit uses the production module initialization identity")
Local nestedModuleResult:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nested.mod/leaf.mod/leaf.bmx", "SuperStrict~nModule acme.nested.leaf~nFunction NestedValue:Int()~nReturn 42~nEnd Function", resolver, TestOptions())
Check(nestedModuleResult.Succeeded() And nestedModuleResult.analysis.model.moduleName = "acme.nested.leaf" And nestedModuleResult.ir.initializationPlan.unitName = "__bb_acme_nested_leaf_leaf", "nested module identity uses every namespace component while retaining the final source basename")
Local mismatchedNestedModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nested.mod/leaf.mod/leaf.bmx", "SuperStrict~nModule acme.nested.wrong~nFunction NestedValue:Int()~nReturn 42~nEnd Function", resolver, TestOptions())
Check(HasCompilerDiagnostic(mismatchedNestedModule, "BMXC0003") And CompilerDiagnosticSummary(mismatchedNestedModule).Contains("acme.nested.wrong") And CompilerDiagnosticSummary(mismatchedNestedModule).Contains("acme.nested.leaf"), "module declaration mismatch reports both the declared and path-derived nested identities")
Local moduleDump:String = TCompilerIrDumper.Dump(moduleResult.ir)
Check(Contains(moduleDump, "var global %g0 Value:Int [published abi acme_sample_Value]") And Contains(moduleDump, "var global %g1 Compare:Int(Int, Int) [published abi acme_sample_Compare] [callable Int(Int, Int)]") And Contains(moduleDump, "var global %g2 Hidden:Int") And Not Contains(moduleDump, "Hidden:Int [published") And Contains(moduleDump, "right:Int=1") And Contains(moduleDump, "callback:Int(Int, Int)=callable(acme_sample_DefaultCompare__Bint__Bint)") And Contains(moduleDump, "value:String=~qready~q"), "typed IR owns public module ABI identity, normalized defaults, and private storage state")
Local moduleRuntimeDiagnostics:TCompilerDiagnostic[]
Local moduleRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(moduleResult, moduleRuntimeDiagnostics)
Check(moduleRuntimeDiagnostics.length = 0 And Contains(moduleRuntimeC, "int __bb_acme_sample_sample(void)") And Contains(moduleRuntimeC, "BBINT acme_sample_Value;") And Contains(moduleRuntimeC, "BBINT (*acme_sample_Compare)(BBINT, BBINT);") And Contains(moduleRuntimeC, "static BBINT bmx_global_g2_Hidden;") And Not Contains(moduleRuntimeC, "bmx_global_g3_DefaultValue") And Not Contains(moduleRuntimeC, "bmx_global_g4_Label"), "runtime backend emits Global storage but keeps compile-time constants out of C storage")
Check(Not Contains(moduleRuntimeC, "__bb_acme_sample_sample_register();") And Not Contains(moduleRuntimeC, "bbRunAtstart();"), "module initialization leaves registration ownership and application AtStart execution to its importer")
Local moduleHeaderDiagnostics:TCompilerDiagnostic[]
Local moduleHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(moduleResult, moduleHeaderDiagnostics)
Check(moduleHeaderDiagnostics.length = 0 And Contains(moduleHeader, "int __bb_acme_sample_sample(void);") And Contains(moduleHeader, "void __bb_acme_sample_sample_register(void);") And Contains(moduleHeader, "extern BBINT acme_sample_Value;") And Contains(moduleHeader, "extern BBINT (*acme_sample_Compare)(BBINT, BBINT);") And Not Contains(moduleHeader, "Hidden"), "module header publishes its guarded unit boundary and exact public Global declarations")
Local moduleInterfaceDiagnostics:TCompilerDiagnostic[]
Local moduleInterface:String = TBlitzMaxCompiler.EmitInterface(moduleResult, moduleInterfaceDiagnostics)
Check(moduleInterfaceDiagnostics.length = 0 And moduleInterface.StartsWith("superstrict~n") And Contains(moduleInterface, "DefaultCompare%(a%,b%)=~qacme_sample_DefaultCompare__Bint__Bint~q") And Contains(moduleInterface, "Apply%(left%,right%=1%,callback%(a%,b%)=~qacme_sample_DefaultCompare__Bint__Bint~q)=~qacme_sample_Apply__Bint__Bint__FBint_Bint_BintE~q") And Contains(moduleInterface, "Describe$(value$=$~qready~q)=~qacme_sample_Describe__Bstring~q") And Contains(moduleInterface, "Value%&=mem:p(~qacme_sample_Value~q)") And Contains(moduleInterface, "Compare%(left%,right%)&=mem:p(~qacme_sample_Compare~q)") And Contains(moduleInterface, "DefaultValue%=7%") And Contains(moduleInterface, "Label$=$~qsample~q") And Not Contains(moduleInterface, "Hidden") And Not Contains(moduleInterface, "CompareValues"), "compact interface emission publishes stable routines, typed defaults, constants, and the exact Global contract")
Local parsedModuleInterface:TInterfaceFile = TInterfaceFileParser.Parse(moduleInterface, "sdk/acme.sample.i")
Check(parsedModuleInterface.diagnostics.length = 0 And parsedModuleInterface.declarations.length = 7 And parsedModuleInterface.declarations[1].routineSignature.parameters[2].callableType <> Null And parsedModuleInterface.declarations[1].routineSignature.parameters[2].defaultValue <> Null And parsedModuleInterface.declarations[4].callableTypeSyntax <> Null And parsedModuleInterface.declarations[5].kind = INTERFACE_RECORD_CONST And parsedModuleInterface.declarations[6].valueSyntax <> Null, "emitted routine defaults, Globals, and constants round-trip through the shared parser")
resolver.AddInterface("acme.sample", "sdk/acme.sample.i", moduleInterface)
Local moduleConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("module-consumer.bmx", "SuperStrict~nImport acme.sample~nLocal result:Int=Apply(DefaultValue)~nLocal explicitResult:Int=Apply(Value,1,Compare)~nLocal description:String=Describe(Label)", resolver, TestOptions())
Check(moduleConsumer.Succeeded(), "a separate compilation consumes published constants, routine defaults, and the Global contract")
Local moduleConsumerDiagnostics:TCompilerDiagnostic[]
Local moduleConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(moduleConsumer, moduleConsumerDiagnostics)
Check(moduleConsumerDiagnostics.length = 0 And Not Contains(moduleConsumerC, "extern BBINT acme_sample_Value;") And Not Contains(moduleConsumerC, "extern BBINT (*acme_sample_Compare)(BBINT, BBINT);") And Contains(moduleConsumerC, "acme_sample_Value") And Contains(moduleConsumerC, "acme_sample_Compare") And Contains(moduleConsumerC, "(7, 1, acme_sample_DefaultCompare__Bint__Bint)") And Contains(moduleConsumerC, "acme_sample_Describe__Bstring(") And Not Contains(moduleConsumerC, "acme_sample_DefaultValue") And Not Contains(moduleConsumerC, "acme_sample_Label"), "consumer C uses header-owned declarations, folds imported constants, and expands numeric, callable, and String defaults")

Local typeGlobalModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/state.mod/state.bmx", "SuperStrict~nModule acme.state~nType TState~nGlobal Enabled:Int~nEnd Type", resolver, TestOptions())
Local typeGlobalInterfaceDiagnostics:TCompilerDiagnostic[]
Local typeGlobalInterface:String = TBlitzMaxCompiler.EmitInterface(typeGlobalModule, typeGlobalInterfaceDiagnostics)
Check(typeGlobalModule.Succeeded() And typeGlobalInterfaceDiagnostics.length = 0 And Contains(typeGlobalInterface, "TState^Object{") And Contains(typeGlobalInterface, "Enabled%&=mem:p(~qacme_state_TState_Enabled~q)") And typeGlobalInterface.Find("Enabled%&") < typeGlobalInterface.Find("}=~qacme_state_TState~q"), "compact interfaces retain a public Type Global inside its declaring Type contract")
resolver.AddInterface("acme.state", "sdk/acme.state.i", typeGlobalInterface)
Local typeGlobalConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("type-global-consumer.bmx", "SuperStrict~nImport acme.state~nIf TState.Enabled Then TState.Enabled=False", resolver, TestOptions())
Check(typeGlobalConsumer.Succeeded() And typeGlobalConsumer.ir.externalGlobals.length = 1 And typeGlobalConsumer.ir.externalGlobals[0].abiName = "acme_state_TState_Enabled", "a separate source resolves and accesses an imported Type Global")

Local arrayApiSource:String = "SuperStrict~nModule acme.arrayapi~nGlobal Names:String[]~nFunction LoadNames:String[]()~nReturn Names~nEnd Function~nFunction EchoNumbers:Int[](values:Int[]=Null)~nReturn values~nEnd Function"
Local arrayApi:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/arrayapi.mod/arrayapi.bmx", arrayApiSource, resolver, TestOptions())
Local arrayApiInterfaceDiagnostics:TCompilerDiagnostic[]
Local arrayApiInterface:String = TBlitzMaxCompiler.EmitInterface(arrayApi, arrayApiInterfaceDiagnostics)
Check(arrayApi.Succeeded() And arrayApiInterfaceDiagnostics.length = 0 And Contains(arrayApiInterface, "LoadNames$&[]()=~qacme_arrayapi_LoadNames~q") And Contains(arrayApiInterface, "EchoNumbers%&[](values%&[]=~qbbEmptyArray~q)=~qacme_arrayapi_EchoNumbers__A1_Bint~q") And Contains(arrayApiInterface, "Names$&[]&=mem:p(~qacme_arrayapi_Names~q)"), "compact interfaces publish heap Array routine results, parameters, managed defaults, and Globals")
Local parsedArrayApiInterface:TInterfaceFile = TInterfaceFileParser.Parse(arrayApiInterface, "sdk/acme.arrayapi.i")
Check(parsedArrayApiInterface.diagnostics.length = 0 And parsedArrayApiInterface.declarations.length = 3 And parsedArrayApiInterface.declarations[0].routineSignature.returnType.suffixes.length = 1 And parsedArrayApiInterface.declarations[1].routineSignature.parameters[0].declaredType.suffixes.length = 1 And parsedArrayApiInterface.declarations[2].declaredTypeSyntax.suffixes.length = 1, "heap Array compact signatures round-trip through the shared interface parser")
resolver.AddInterface("acme.arrayapi", "sdk/acme.arrayapi.i", arrayApiInterface)
Local arrayApiConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("array-api-consumer.bmx", "SuperStrict~nImport acme.arrayapi~nLocal loadedNames:String[]=LoadNames()~nLocal numbers:Int[]=EchoNumbers()~nNames=loadedNames~nLocal total:Int=loadedNames.length+numbers.length", resolver, TestOptions())
Local arrayApiConsumerDiagnostics:TCompilerDiagnostic[]
Local arrayApiConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(arrayApiConsumer, arrayApiConsumerDiagnostics)
Check(arrayApiConsumer.Succeeded() And arrayApiConsumerDiagnostics.length = 0 And Contains(arrayApiConsumerC, "acme_arrayapi_LoadNames()") And Contains(arrayApiConsumerC, "acme_arrayapi_EchoNumbers__A1_Bint(&bbEmptyArray)") And Contains(arrayApiConsumerC, "acme_arrayapi_Names = bmx_v0_loadedNames"), "a separate compilation consumes heap Array routine and Global contracts without source access")

Local moduleTypesSource:String = "SuperStrict~nModule acme.types~nType TPublished~nField Value:Int~nField Peer:TSecond~nField Items:Int[]~nMethod New(initialValue:Int)~nValue = initialValue~nEnd Method~nMethod Read:Int(delta:Int)~nReturn Value + delta~nEnd Method~nMethod EchoPeer:TSecond(newPeer:TSecond = Null)~nPeer = newPeer~nReturn Peer~nEnd Method~nMethod EchoItems:Int[](newItems:Int[] = Null)~nItems = newItems~nReturn Items~nEnd Method~nFunction Identity:Int(value:Int)~nReturn value~nEnd Function~nEnd Type~nType TSecond~nField Value:Int~nMethod New(initialValue:Int)~nValue = initialValue~nEnd Method~nMethod Read:Int(delta:Int)~nReturn Value + delta~nEnd Method~nEnd Type~nPrivate~nType THidden~nField Value:Int~nMethod Read:Int(delta:Int)~nReturn Value + delta~nEnd Method~nEnd Type"
Local moduleTypes:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/types.mod/types.bmx", moduleTypesSource, resolver, TestOptions())
Check(moduleTypes.Succeeded() And moduleTypes.ir.classes.length = 3, "module Types lower with public and private publication state")
Local moduleTypesDump:String = TCompilerIrDumper.Dump(moduleTypes.ir)
Check(Contains(moduleTypesDump, "TPublished:TPublished [published abi acme_types_TPublished]") And Contains(moduleTypesDump, "Value:Int [abi _acme_types_tpublished_value]") And Contains(moduleTypesDump, "abi acme_types_TPublished_Read__Bint slot m_Read__Bint") And Contains(moduleTypesDump, "[abi acme_types_TPublished_Read__Bint] [implementation _acme_types_TPublished_Read__Bint]") And Contains(moduleTypesDump, "abi acme_types_TPublished_Identity__Bint slot f_Identity__Bint"), "typed IR separates public Type method linkage, implementation, and class-slot identities")
Check(Contains(moduleTypesDump, "abi acme_types_TSecond_Read__Bint slot m_Read__Bint") And Not Contains(moduleTypesDump, "THidden:THidden [published"), "method implementations are owner-qualified while equivalent slots retain their structural identity and private Types remain internal")
Local moduleTypesDiagnostics:TCompilerDiagnostic[]
Local moduleTypesC:String = TBlitzMaxCompiler.EmitRuntimeC(moduleTypes, moduleTypesDiagnostics)
Check(moduleTypesDiagnostics.length = 0 And Contains(moduleTypesC, "struct acme_types_TPublished_obj") And Contains(moduleTypesC, "BBDEBUGSCOPE_USERTYPE, ~qTPublished~q") And Contains(moduleTypesC, "bbObjectFree, (BBDebugScope *)&bmx_type_scope_") And Contains(moduleTypesC, "struct BBClass_acme_types_TPublished acme_types_TPublished =") And Contains(moduleTypesC, "BBINT _acme_types_tpublished_value;"), "runtime C emits the stable public Type descriptor, minimal release reflection identity, object layout, and field identity")
Check(Contains(moduleTypesC, "(*m_Read__Bint)") And Contains(moduleTypesC, "(*f_Identity__Bint)") And Contains(moduleTypesC, "_acme_types_TPublished_Read__Bint") And Contains(moduleTypesC, "_acme_types_TSecond_Read__Bint"), "runtime C separates stable class slots from production-compatible owner-qualified method implementations")
Check(Contains(moduleTypesC, "struct acme_types_TPublished_obj * _acme_types_TPublished_New__Bint_ObjectNew("), "parameterized public constructors publish the imported-construction helper ABI")
Check(Contains(moduleTypesC, "struct bmx_cls2_THidden_obj") And Contains(moduleTypesC, "bmx_class_cls2_THidden") And Not Contains(moduleTypesC, "acme_types_THidden"), "private module Types retain compiler-internal C identities")
Local moduleTypesHeaderDiagnostics:TCompilerDiagnostic[]
Local moduleTypesHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(moduleTypes, moduleTypesHeaderDiagnostics)
Check(moduleTypesHeaderDiagnostics.length = 0 And Contains(moduleTypesHeader, "extern struct BBClass_acme_types_TPublished acme_types_TPublished;") And Contains(moduleTypesHeader, "struct acme_types_TPublished_obj") And Contains(moduleTypesHeader, "_acme_types_tpublished_value") And Contains(moduleTypesHeader, "_acme_types_TPublished_New__Bint_ObjectNew(") And Not Contains(moduleTypesHeader, "THidden"), "module headers publish the exact reusable public Type layout and construction helper without leaking private class layouts")
Check(Contains(moduleTypesHeader, "typedef BBINT (*acme_types_TPublished_Read_i_m)(struct acme_types_TPublished_obj *, BBINT);") And Contains(moduleTypesHeader, "(*m_Read__Bint)") And Contains(moduleTypesHeader, "(*m_Read_i)") And Not Contains(moduleTypesHeader, "#define m_Read_i"), "module headers retain class-scoped legacy compact method-slot typedef and member aliases during mixed bcc/bcc2 bootstrap")
Local moduleTypesInterfaceDiagnostics:TCompilerDiagnostic[]
Local moduleTypesInterface:String = TBlitzMaxCompiler.EmitInterface(moduleTypes, moduleTypesInterfaceDiagnostics)
Check(moduleTypesInterfaceDiagnostics.length = 0 And Contains(moduleTypesInterface, "TPublished^Object{") And Contains(moduleTypesInterface, ".Value%&") And Contains(moduleTypesInterface, ".Peer:TSecond&") And Contains(moduleTypesInterface, ".Items%&[]&") And Contains(moduleTypesInterface, "-New(initialValue%)=~q_acme_types_TPublished_New__Bint~q") And Contains(moduleTypesInterface, "-Read%(delta%)=~qacme_types_TPublished_Read__Bint~q") And Contains(moduleTypesInterface, "-EchoPeer:TSecond(newPeer:TSecond=~qbbNullObject~q)=~qacme_types_TPublished_EchoPeer__NTSecondE~q") And Contains(moduleTypesInterface, "-EchoItems%&[](newItems%&[]=~qbbEmptyArray~q)=~qacme_types_TPublished_EchoItems__A1_Bint~q") And Contains(moduleTypesInterface, "+Identity%(value%)=~qacme_types_TPublished_Identity__Bint~q") And Contains(moduleTypesInterface, "}=~qacme_types_TPublished~q") And Contains(moduleTypesInterface, "TSecond^Object{") And Not Contains(moduleTypesInterface, "THidden"), "compact interface emission publishes production constructor linkage, method linkage, object/array fields, and managed defaults")
Local scalarNullDefaultModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/scalarnulldefault.mod/scalarnulldefault.bmx", "SuperStrict~nModule acme.scalarnulldefault~nEnum EOptionalState~nMissing~nReady~nEnd Enum~nType TScalarNullDefault~nMethod GetInt:Int(value:Int = Null)~nReturn value~nEnd Method~nMethod GetState:EOptionalState(value:EOptionalState = Null)~nReturn value~nEnd Method~nEnd Type", resolver, TestOptions())
Local scalarNullDefaultDiagnostics:TCompilerDiagnostic[]
Local scalarNullDefaultInterface:String = TBlitzMaxCompiler.EmitInterface(scalarNullDefaultModule, scalarNullDefaultDiagnostics)
Check(scalarNullDefaultModule.Succeeded() And scalarNullDefaultDiagnostics.length = 0 And Contains(scalarNullDefaultInterface, "-GetInt%(value%=0)") And Contains(scalarNullDefaultInterface, "-GetState/EOptionalState(value/EOptionalState=0)"), "compact Type interfaces publish contextual Null scalar and Enum defaults as zero")
Local parsedModuleTypesInterface:TInterfaceFile = TInterfaceFileParser.Parse(moduleTypesInterface, "sdk/acme.types.i")
Check(parsedModuleTypesInterface.diagnostics.length = 0 And parsedModuleTypesInterface.declarations.length = 2 And parsedModuleTypesInterface.declarations[0].members.length = 8 And parsedModuleTypesInterface.declarations[0].members[0].kind = INTERFACE_RECORD_FIELD And parsedModuleTypesInterface.declarations[0].members[3].kind = INTERFACE_RECORD_METHOD And parsedModuleTypesInterface.declarations[0].members[7].kind = INTERFACE_RECORD_TYPE_FUNCTION, "emitted object/array Type records round-trip through the shared compact-interface parser")
resolver.AddInterface("acme.types", "sdk/acme.types.i", moduleTypesInterface)
Local moduleTypesConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("types-consumer.bmx", "SuperStrict~nImport acme.types~nLocal value:TPublished = New TPublished(40)~nLocal second:TSecond = New TSecond(2)~nvalue.Peer = second~nLocal items:Int[] = New Int[1]~nitems[0] = 3~nvalue.Items = items~nLocal readResult:Int = value.Read(1)~nLocal peerResult:TSecond = value.EchoPeer(second)~nLocal arrayResult:Int[] = value.EchoItems(items)~nLocal identityResult:Int = TPublished.Identity(42)~nvalue.Value = readResult + peerResult.Value + arrayResult[0] + identityResult", resolver, TestOptions())
Check(moduleTypesConsumer.Succeeded(), "a separate compilation consumes emitted object/array fields and method signatures")
Local moduleTypesConsumerDiagnostics:TCompilerDiagnostic[]
Local moduleTypesConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(moduleTypesConsumer, moduleTypesConsumerDiagnostics)
Check(moduleTypesConsumerDiagnostics.length = 0 And Contains(moduleTypesConsumerC, "->_acme_types_tpublished_peer") And Contains(moduleTypesConsumerC, "->_acme_types_tpublished_items") And Contains(moduleTypesConsumerC, "->clas->m_EchoPeer__NTSecondE(") And Contains(moduleTypesConsumerC, "->clas->m_EchoItems__A1_Bint("), "consumer C uses dependency-owned object/array field and virtual-slot ABI identities")

Local privateFieldTypeSource:String = "SuperStrict~nModule acme.privatefield~nPrivate~nType THiddenResource~nEnd Type~nPublic~nType TPublishedHolder~nPrivate~nField resource:THiddenResource~nField resources:THiddenResource[]~nEnd Type"
Local privateFieldType:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/privatefield.mod/privatefield.bmx", privateFieldTypeSource, resolver, TestOptions())
Local privateFieldTypeDiagnostics:TCompilerDiagnostic[]
Local privateFieldTypeInterface:String = TBlitzMaxCompiler.EmitInterface(privateFieldType, privateFieldTypeDiagnostics)
Check(privateFieldType.Succeeded() And privateFieldTypeDiagnostics.length = 0 And Contains(privateFieldTypeInterface, ".resource:Object&") And Contains(privateFieldTypeInterface, ".resources:Object&[]&") And Not Contains(privateFieldTypeInterface, "THiddenResource"), "compact interfaces erase private source Types used by scalar and Array fields to the production Object contract")
Local invalidPrivateApi:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/invalidprivateapi.mod/invalidprivateapi.bmx", "SuperStrict~nModule acme.invalidprivateapi~nPrivate~nType THidden~nEnd Type~nPublic~nType TPublished~nField exposed:THidden~nEnd Type", resolver, TestOptions())
Check(Not invalidPrivateApi.Succeeded() And HasLanguageDiagnostic(invalidPrivateApi, "BMX3217"), "the compiler rejects a public field that exposes a private Type before compact-interface emission")

Local privateStructFieldSource:String = "SuperStrict~nModule acme.privatestructfield~nPrivate~nStruct SPrivateState~nField StaticArray words:ULong[4]~nEnd Struct~nPublic~nType TPublishedState~nPrivate~nField state:SPrivateState~nPublic~nMethod New(seed:Int)~nstate.words[0]=ULong(seed)~nEnd Method~nEnd Type"
Local privateStructField:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/privatestructfield.mod/privatestructfield.bmx", privateStructFieldSource, resolver, TestOptions())
Local privateStructFieldDiagnostics:TCompilerDiagnostic[]
Local privateStructFieldInterface:String = TBlitzMaxCompiler.EmitInterface(privateStructField, privateStructFieldDiagnostics)
Check(privateStructField.Succeeded() And privateStructFieldDiagnostics.length = 0 And AppearsBefore(privateStructFieldInterface, "SPrivateState^Null{", "TPublishedState^Object{") And Contains(privateStructFieldInterface, "}SP=~qacme_privatestructfield_SPrivateState~q") And Contains(privateStructFieldInterface, ".state:SPrivateState&`"), "compact interfaces retain private Struct layouts required by a published Type's by-value ABI without changing source visibility")
Local parsedPrivateStructField:TInterfaceFile = TInterfaceFileParser.Parse(privateStructFieldInterface, "sdk/acme.privatestructfield.i")
Check(parsedPrivateStructField.diagnostics.length = 0 And parsedPrivateStructField.declarations[0].visibility = VISIBILITY_PRIVATE, "the shared interface parser reconstructs a layout-only Struct as private")
resolver.AddInterface("acme.privatestructfield", "sdk/acme.privatestructfield.i", privateStructFieldInterface)
Local privateStructFieldConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("private-struct-field-consumer.bmx", "SuperStrict~nImport acme.privatestructfield~nLocal value:TPublishedState=New TPublishedState(42)", resolver, TestOptions())
Check(privateStructFieldConsumer.Succeeded(), "a separate consumer reconstructs a published Type whose private layout embeds a private Struct")
Local privateStructNameConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("private-struct-name-consumer.bmx", "SuperStrict~nImport acme.privatestructfield~nLocal value:SPrivateState", resolver, TestOptions())
Check(Not privateStructNameConsumer.Succeeded(), "a layout-only private Struct remains inaccessible to source-free consumers")

Local transitivePrivateLayoutSource:String = "SuperStrict~nModule acme.transitiveprivatelayout~nPrivate~nEnum EPrivateMode~nIdle~nReady~nEnd Enum~nStruct SPrivateState~nField leaf:SPrivateLeaf~nField pointer:SPrivatePointer Ptr~nField StaticArray fixed:SStaticLeaf[2]~nField transform:SCallableOnly(value:SCallableOnly)~nField transforms:SCallableArray(value:SCallableArray)[]~nEnd Struct~nStruct SPrivateLeaf~nField mode:EPrivateMode~nEnd Struct~nStruct SPrivatePointer~nField value:Int~nEnd Struct~nStruct SStaticLeaf~nField value:Int~nEnd Struct~nStruct SCallableOnly~nField value:Int~nEnd Struct~nStruct SCallableArray~nField value:Int~nEnd Struct~nStruct SUnused~nField value:Int~nEnd Struct~nPublic~nType TPublishedPrivateLayout~nPrivate Field state:SPrivateState~nPublic~nEnd Type"
Local transitivePrivateLayout:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/transitiveprivatelayout.mod/transitiveprivatelayout.bmx", transitivePrivateLayoutSource, resolver, TestOptions())
Local transitivePrivateLayoutDiagnostics:TCompilerDiagnostic[]
Local transitivePrivateLayoutInterface:String = TBlitzMaxCompiler.EmitInterface(transitivePrivateLayout, transitivePrivateLayoutDiagnostics)
Check(transitivePrivateLayout.Succeeded() And transitivePrivateLayoutDiagnostics.length = 0 And Contains(transitivePrivateLayoutInterface, "SPrivateState^Null{") And Contains(transitivePrivateLayoutInterface, ".leaf:SPrivateLeaf&") And Contains(transitivePrivateLayoutInterface, ".pointer:SPrivatePointer*&") And Contains(transitivePrivateLayoutInterface, "~~fixed:SStaticLeaf&[2]&") And Contains(transitivePrivateLayoutInterface, ".transform:SCallableOnly(value:SCallableOnly)&") And Contains(transitivePrivateLayoutInterface, ".transforms:SCallableArray(value:SCallableArray)&[]&") And Contains(transitivePrivateLayoutInterface, "SPrivateLeaf^Null{") And Contains(transitivePrivateLayoutInterface, ".mode/EPrivateMode&") And Contains(transitivePrivateLayoutInterface, "SPrivatePointer^Null{") And Contains(transitivePrivateLayoutInterface, "SStaticLeaf^Null{") And Contains(transitivePrivateLayoutInterface, "SCallableOnly^Null{") And Contains(transitivePrivateLayoutInterface, "SCallableArray^Null{") And Contains(transitivePrivateLayoutInterface, "EPrivateMode\%{") And Not Contains(transitivePrivateLayoutInterface, "SUnused^Null{"), "compact interfaces retain transitive Struct, pointer, StaticArray, callable, callable-array, and Enum dependencies of a private published layout without publishing unrelated private declarations")
Local parsedTransitivePrivateLayout:TInterfaceFile = TInterfaceFileParser.Parse(transitivePrivateLayoutInterface, "sdk/acme.transitiveprivatelayout.i")
Check(parsedTransitivePrivateLayout.diagnostics.length = 0 And parsedTransitivePrivateLayout.declarations.length = 8, "the shared interface parser reconstructs all required transitive private-layout declarations")
resolver.AddInterface("acme.transitiveprivatelayout", "sdk/acme.transitiveprivatelayout.i", transitivePrivateLayoutInterface)
Local transitivePrivateLayoutConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("transitive-private-layout-consumer.bmx", "SuperStrict~nImport acme.transitiveprivatelayout~nLocal value:TPublishedPrivateLayout=New TPublishedPrivateLayout", resolver, TestOptions())
Check(transitivePrivateLayoutConsumer.Succeeded(), "a source-free consumer reconstructs a published Type with transitive private Struct, callable, and Enum layout dependencies: " + CompilerDiagnosticSummary(transitivePrivateLayoutConsumer))
Local transitivePrivateNameConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("transitive-private-name-consumer.bmx", "SuperStrict~nImport acme.transitiveprivatelayout~nLocal state:SPrivateState~nLocal callback:SCallableOnly", resolver, TestOptions())
Check(Not transitivePrivateNameConsumer.Succeeded(), "transitively published private layout helpers remain inaccessible to source-free consumers")

Local reflectionBoundarySource:String = "SuperStrict~nModule acme.reflectionboundary~nPrivate~nEnum EPrivateFlags Flags~nFirst~nSecond~nEnd Enum~nType THiddenEnumerator~nEnd Type~nPublic~nType TPublishedApi~nPrivate~nField flags:EPrivateFlags~nMethod HiddenEnumerator:THiddenEnumerator()~nReturn New THiddenEnumerator~nEnd Method~nPublic~nMethod ReadLongInt:LongInt()~nReturn 1~nEnd Method~nMethod ReadULongInt:ULongInt()~nReturn 2~nEnd Method~nMethod PointerDefault:Byte Ptr(value:Byte Ptr = Null)~nReturn value~nEnd Method~nMethod PointerZeroDefault:Byte Ptr(value:Byte Ptr = 0)~nReturn value~nEnd Method~nMethod StringDefault:String(value:String = Null)~nReturn value~nEnd Method~nEnd Type"
Local reflectionBoundary:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/reflectionboundary.mod/reflectionboundary.bmx", reflectionBoundarySource, resolver, TestOptions())
Local reflectionBoundaryDiagnostics:TCompilerDiagnostic[]
Local reflectionBoundaryInterface:String = TBlitzMaxCompiler.EmitInterface(reflectionBoundary, reflectionBoundaryDiagnostics)
Check(reflectionBoundary.Succeeded() And reflectionBoundaryDiagnostics.length = 0 And Contains(reflectionBoundaryInterface, "EPrivateFlags\%{") And Contains(reflectionBoundaryInterface, ".flags/EPrivateFlags&`") And Contains(reflectionBoundaryInterface, "-ReadLongInt%v()=") And Contains(reflectionBoundaryInterface, "-ReadULongInt%e()=") And Contains(reflectionBoundaryInterface, "-HiddenEnumerator:Object()P=") And Contains(reflectionBoundaryInterface, "-PointerDefault@*(value@*=0)=") And Contains(reflectionBoundaryInterface, "-PointerZeroDefault@*(value@*=0)=") And Not Contains(reflectionBoundaryInterface, "value@*=0@*") And Contains(reflectionBoundaryInterface, "-StringDefault$(value$=$~q~q)=") And Not Contains(reflectionBoundaryInterface, "THiddenEnumerator"), "compact interfaces publish private Enum dependencies, wide integers, canonical pointer-zero defaults, managed String defaults, and production-compatible Object erasure for private routine result Types")
Local parsedReflectionBoundaryInterface:TInterfaceFile = TInterfaceFileParser.Parse(reflectionBoundaryInterface, "sdk/acme.reflectionboundary.i")
Check(parsedReflectionBoundaryInterface.diagnostics.length = 0 And parsedReflectionBoundaryInterface.declarations.length = 2 And parsedReflectionBoundaryInterface.declarations[1].members.length = 7, "Reflection boundary signatures round-trip through the shared compact-interface parser")

Local constructedGenericMembers:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/genericholder.mod/genericholder.bmx", "SuperStrict~nModule acme.genericholder~nType TGenericHolder~nField map:Int~nField iterator:Int~nEnd Type", resolver, TestOptions())
Local importedGenericMap:TCompilerIrImportedClass = New TCompilerIrImportedClass
importedGenericMap.importedClassId = "generic-map"
importedGenericMap.name = "THashMap"
importedGenericMap.semanticType = "THashMap<Byte Ptr, Object>"
importedGenericMap.abiName = "bmx_gen_collections_hashmap_thashmap_test"
importedGenericMap.isGenericSpecialization = True
constructedGenericMembers.ir.importedClasses :+ [importedGenericMap]
Local importedGenericIterator:TCompilerIrInterface = New TCompilerIrInterface
importedGenericIterator.interfaceId = "generic-iterator"
importedGenericIterator.name = "IIterator"
importedGenericIterator.semanticType = "IIterator<IMapNode<Byte Ptr, Object>>"
importedGenericIterator.abiName = "bmx_gen_brl_blitz_iiterator_test"
importedGenericIterator.isImported = True
constructedGenericMembers.ir.interfaces :+ [importedGenericIterator]
constructedGenericMembers.ir.classes[0].fields[0].semanticType = "THashMap<Byte Ptr,Object>"
constructedGenericMembers.ir.classes[0].fields[1].semanticType = "IIterator<IMapNode<Byte Ptr,Object>>"
Local constructedGenericMemberDiagnostics:TCompilerDiagnostic[]
Local constructedGenericMemberInterface:String = TBlitzMaxCompiler.EmitInterface(constructedGenericMembers, constructedGenericMemberDiagnostics)
Local parsedConstructedGenericMemberInterface:TInterfaceFile = TInterfaceFileParser.Parse(constructedGenericMemberInterface, "sdk/acme.genericholder.i")
Check(constructedGenericMembers.Succeeded() And constructedGenericMemberDiagnostics.length = 0 And Contains(constructedGenericMemberInterface, ".map:THashMap<Byte Ptr, Object>&") And Contains(constructedGenericMemberInterface, ".iterator:IIterator<IMapNode<Byte Ptr, Object>>&"), "compact interfaces publish canonical constructed generic Type and Interface field identities independent of display whitespace")
Check(parsedConstructedGenericMemberInterface.diagnostics.length = 0 And parsedConstructedGenericMemberInterface.declarations.length = 1 And parsedConstructedGenericMemberInterface.declarations[0].members.length = 2, "constructed generic member signatures round-trip through the shared compact-interface parser")

Local compactPointerSlotSource:String = "SuperStrict~nModule acme.compactslot~nType TCompactIO~nMethod Read:Long(buffer:Byte Ptr,count:Long)~nReturn 0~nEnd Method~nEnd Type"
Local compactPointerSlot:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/compactslot.mod/compactslot.bmx", compactPointerSlotSource, resolver, TestOptions())
Local compactPointerSlotDiagnostics:TCompilerDiagnostic[]
Local compactPointerSlotHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(compactPointerSlot, compactPointerSlotDiagnostics)
Check(compactPointerSlot.Succeeded() And compactPointerSlotDiagnostics.length = 0 And Contains(compactPointerSlotHeader, "acme_compactslot_TCompactIO_Read_pbl_m") And Contains(compactPointerSlotHeader, "acme_compactslot_TCompactIO_Read__PBbyte__Blong_m") And Contains(compactPointerSlotHeader, "(*m_Read_pbl)") And Not Contains(compactPointerSlotHeader, "#define m_Read_pbl"), "runtime headers bridge production pointer/scalar slot spelling with a class-scoped alias and unchanged canonical bcc2 slot identity")

Local wideLegacySlots:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/wideslots.mod/wideslots.bmx", "SuperStrict~nModule acme.wideslots~nType TWideSlots~nMethod Set(value:Long)~nEnd Method~nMethod Set(value:LongInt)~nEnd Method~nMethod SetUnsigned(value:ULong)~nEnd Method~nMethod SetUnsigned(value:ULongInt)~nEnd Method~nMethod Text(value:String)~nEnd Method~nMethod Text(value:Short)~nEnd Method~nEnd Type", resolver, TestOptions())
Local wideLegacySlotDiagnostics:TCompilerDiagnostic[]
Local wideLegacySlotHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(wideLegacySlots, wideLegacySlotDiagnostics)
Check(wideLegacySlots.Succeeded() And wideLegacySlotDiagnostics.length = 0 And Contains(wideLegacySlotHeader, "TWideSlots_Set_l_m") And Contains(wideLegacySlotHeader, "TWideSlots_Set_g_m") And Contains(wideLegacySlotHeader, "TWideSlots_SetUnsigned_y_m") And Contains(wideLegacySlotHeader, "TWideSlots_SetUnsigned_G_m") And Contains(wideLegacySlotHeader, "TWideSlots_Text_S_m") And Contains(wideLegacySlotHeader, "TWideSlots_Text_s_m"), "legacy header aliases preserve production-distinct LongInt, ULongInt, String, and narrow scalar slot codes")

Local operatorHeader:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/operatorheader.mod/operatorheader.bmx", "SuperStrict~nModule acme.operatorheader~nType TIndexed~nMethod Operator[]:Object(key:Byte Ptr)~nReturn Null~nEnd Method~nMethod Operator[]=(key:Byte Ptr,value:Object)~nEnd Method~nEnd Type", resolver, TestOptions())
Local operatorHeaderDiagnostics:TCompilerDiagnostic[]
Local operatorHeaderText:String = TBlitzMaxCompiler.EmitRuntimeHeader(operatorHeader, operatorHeaderDiagnostics)
Check(operatorHeader.Succeeded() And operatorHeaderDiagnostics.length = 0 And Contains(operatorHeaderText, "acme_operatorheader_TIndexed__iget_pb_m") And Contains(operatorHeaderText, "acme_operatorheader_TIndexed__iset_pbTObject_m") And Contains(operatorHeaderText, "(*m__iget_pb)") And Contains(operatorHeaderText, "(*m__iset_pbTObject)") And Not Contains(operatorHeaderText, "#define m__iget_pb") And Not Contains(operatorHeaderText, "TIndexed_[]"), "runtime header compatibility members map index operators and Object parameters to class-scoped production C identifiers")

Local inheritedSlotHeader:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/inheritedslot.mod/inheritedslot.bmx", "SuperStrict~nModule acme.inheritedslot~nType TSlotBase~nMethod Read:Int(value:Int)~nReturn value~nEnd Method~nMethod SetPeer(peer:TSlotBase)~nEnd Method~nEnd Type~nType TSlotDerived Extends TSlotBase~nEnd Type", resolver, TestOptions())
Local inheritedSlotHeaderDiagnostics:TCompilerDiagnostic[]
Local inheritedSlotHeaderText:String = TBlitzMaxCompiler.EmitRuntimeHeader(inheritedSlotHeader, inheritedSlotHeaderDiagnostics)
Check(inheritedSlotHeader.Succeeded() And inheritedSlotHeaderDiagnostics.length = 0 And Contains(inheritedSlotHeaderText, "acme_inheritedslot_TSlotBase_Read_i_m") And Contains(inheritedSlotHeaderText, "acme_inheritedslot_TSlotDerived_Read_i_m") And Contains(inheritedSlotHeaderText, "acme_inheritedslot_TSlotDerived_SetPeer__NTSlotBaseE_m"), "runtime headers publish receiver-specific canonical and compact compatibility typedefs for inherited slots used by legacy-derived headers")

resolver.AddInterface("closeable.override", "sdk/closeable.override.i", "superstrict~nimport brl.blitz~nTIO^Object@ICloseable{~n-Close()=~qcloseable_override_TIO_Close~q~n}=~qcloseable_override_TIO~q~nTStream^TIO{~n}=~qcloseable_override_TStream~q")
Local importedCloseOverride:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/closeoverride.mod/closeoverride.bmx", "SuperStrict~nModule acme.closeoverride~nImport closeable.override~nType TCloseStream Extends TStream Abstract~nMethod Close()~nEnd Method~nEnd Type", resolver, TestOptions())
Local importedCloseSlots:Int
If importedCloseOverride.ir And importedCloseOverride.ir.classes.length Then
	For Local closeSlot:TCompilerIrClassFunctionSlot = EachIn importedCloseOverride.ir.classes[0].functionSlots
		If closeSlot.name.ToLower() = "close" Then importedCloseSlots :+ 1
	Next
End If
Local importedCloseDiagnostics:TCompilerDiagnostic[]
Local importedCloseHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(importedCloseOverride, importedCloseDiagnostics)
Check(importedCloseOverride.Succeeded() And importedCloseDiagnostics.length = 0 And importedCloseSlots = 1 And Contains(importedCloseHeader, "(*m_Close)") And Not Contains(importedCloseHeader, "(*f_Close)"), "an imported Interface requirement reuses an existing concrete method override instead of appending a Type-function-shaped abstract slot")

Local interfaceValueModuleSource:String = "SuperStrict~nModule acme.interfacevalues~nImport brl.blitz~nGlobal Shared:ICloseable~nType TInterfaceHolder~nField Value:ICloseable~nMethod New()~nEnd Method~nMethod Store:ICloseable(value:ICloseable = Null)~nSelf.Value = value~nReturn Self.Value~nEnd Method~nFunction Identity:ICloseable(value:ICloseable)~nReturn value~nEnd Function~nEnd Type~nFunction EchoCloseable:ICloseable(value:ICloseable = Null)~nReturn value~nEnd Function"
Local interfaceValueModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/interfacevalues.mod/interfacevalues.bmx", interfaceValueModuleSource, resolver, TestOptions())
Check(interfaceValueModule.Succeeded(), "Interface-valued fields, parameters, and returns lower as managed reference values")
Local interfaceValueModuleDiagnostics:TCompilerDiagnostic[]
Local interfaceValueModuleC:String = TBlitzMaxCompiler.EmitRuntimeC(interfaceValueModule, interfaceValueModuleDiagnostics)
Check(interfaceValueModuleDiagnostics.length = 0 And Contains(interfaceValueModuleC, "BBOBJECT acme_interfacevalues_Shared;") And Contains(interfaceValueModuleC, "GC_add_roots(&acme_interfacevalues_Shared, &acme_interfacevalues_Shared + 1);") And Contains(interfaceValueModuleC, "BBOBJECT _acme_interfacevalues_tinterfaceholder_value;") And Contains(interfaceValueModuleC, "BBOBJECT _acme_interfacevalues_TInterfaceHolder_Store__NICloseableE(") And Contains(interfaceValueModuleC, "BBOBJECT acme_interfacevalues_TInterfaceHolder_Identity__NICloseableE(") And Contains(interfaceValueModuleC, "BBOBJECT acme_interfacevalues_EchoCloseable__NICloseableE("), "runtime C uses rooted production object-reference storage and distinct method and Type-function ABI boundaries for Interface values")
Local interfaceValueModuleHeaderDiagnostics:TCompilerDiagnostic[]
Local interfaceValueModuleHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(interfaceValueModule, interfaceValueModuleHeaderDiagnostics)
Check(interfaceValueModuleHeaderDiagnostics.length = 0 And Contains(interfaceValueModuleHeader, "#include <brl.mod/blitz.mod/.bmx/blitz.bmx.release.test.x64.h>") And Contains(interfaceValueModuleHeader, "extern BBOBJECT acme_interfacevalues_Shared;") And Contains(interfaceValueModuleHeader, "BBOBJECT _acme_interfacevalues_tinterfaceholder_value;") And Contains(interfaceValueModuleHeader, "BBOBJECT acme_interfacevalues_EchoCloseable__NICloseableE(BBOBJECT"), "public headers retain the dependency and exact Interface-valued Global/member ABI")
Local interfaceValueModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local interfaceValueModuleInterface:String = TBlitzMaxCompiler.EmitInterface(interfaceValueModule, interfaceValueModuleInterfaceDiagnostics)
Check(interfaceValueModuleInterfaceDiagnostics.length = 0 And Contains(interfaceValueModuleInterface, "import brl.blitz") And Contains(interfaceValueModuleInterface, ".Value:ICloseable&") And Contains(interfaceValueModuleInterface, "-Store:ICloseable(value:ICloseable=~qbbNullObject~q)=~qacme_interfacevalues_TInterfaceHolder_Store__NICloseableE~q") And Contains(interfaceValueModuleInterface, "+Identity:ICloseable(value:ICloseable)=~qacme_interfacevalues_TInterfaceHolder_Identity__NICloseableE~q") And Contains(interfaceValueModuleInterface, "EchoCloseable:ICloseable(value:ICloseable=~qbbNullObject~q)=~qacme_interfacevalues_EchoCloseable__NICloseableE~q") And Contains(interfaceValueModuleInterface, "Shared:ICloseable&=mem:p(~qacme_interfacevalues_Shared~q)"), "compact interfaces publish Interface Globals and managed Null defaults alongside member and routine signatures")
resolver.AddInterface("acme.interfacevalues", "sdk/acme.interfacevalues.i", interfaceValueModuleInterface)
Local interfaceValueConsumerSource:String = "SuperStrict~nImport acme.interfacevalues~nType TConsumerCloseable Implements ICloseable~nField Closed:Int~nMethod Close()~nClosed = 1~nEnd Method~nEnd Type~nLocal item:TConsumerCloseable = New TConsumerCloseable~nLocal holder:TInterfaceHolder = New TInterfaceHolder~nShared = item~nholder.Value = Shared~nholder.Store()~nLocal stored:ICloseable = holder.Store(Shared)~nLocal identity:ICloseable = TInterfaceHolder.Identity(stored)~nEchoCloseable()~nLocal echoed:ICloseable = EchoCloseable(identity)~nechoed.Close()"
Local interfaceValueConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("interface-value-consumer.bmx", interfaceValueConsumerSource, resolver, TestOptions())
Check(interfaceValueConsumer.Succeeded(), "a separate compilation consumes Interface-valued field and routine contracts")
Local interfaceValueConsumerDiagnostics:TCompilerDiagnostic[]
Local interfaceValueConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(interfaceValueConsumer, interfaceValueConsumerDiagnostics)
Check(interfaceValueConsumerDiagnostics.length = 0 And Not Contains(interfaceValueConsumerC, "extern BBOBJECT acme_interfacevalues_Shared;") And Contains(interfaceValueConsumerC, "acme_interfacevalues_Shared = ((BBOBJECT)bbInterfaceDowncast") And Contains(interfaceValueConsumerC, "->_acme_interfacevalues_tinterfaceholder_value") And Contains(interfaceValueConsumerC, "->clas->m_Store__NICloseableE(") And Contains(interfaceValueConsumerC, "(BBOBJECT)&bbNullObject") And Contains(interfaceValueConsumerC, "acme_interfacevalues_TInterfaceHolder_Identity__NICloseableE(") And Contains(interfaceValueConsumerC, "acme_interfacevalues_EchoCloseable__NICloseableE(") And Contains(interfaceValueConsumerC, "bbObjectInterface((BBOBJECT)"), "consumer C uses the dependency header while preserving rooted Interface Globals, managed defaults, validation, direct calls, and dispatch")

Local baseModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/base.mod/base.bmx", "SuperStrict~nModule acme.base~nType TBase~nField BaseValue:Int~nMethod Score:Int(delta:Int)~nReturn BaseValue + delta~nEnd Method~nMethod Stable:Int()~nReturn BaseValue~nEnd Method~nMethod ToString:String() Override~nIf BaseValue Then Return ~qbase~q~nReturn ~qbase~q~nEnd Method~nMethod Compare:Int(other:Object) Override~nIf other Then Return BaseValue~nReturn BaseValue~nEnd Method~nMethod SendMessage:Object(message:Object,sender:Object) Override~nIf Self = sender Then Return message~nReturn message~nEnd Method~nMethod HashCode:UInt() Override~nReturn UInt(BaseValue)~nEnd Method~nMethod Equals:Int(other:Object) Override~nReturn Self = other~nEnd Method~nMethod Delete()~nBaseValue = 0~nEnd Method~nFunction Double:Int(value:Int)~nReturn value * 2~nEnd Function~nEnd Type", resolver, TestOptions())
Local baseModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local baseModuleInterface:String = TBlitzMaxCompiler.EmitInterface(baseModule, baseModuleInterfaceDiagnostics)
Check(baseModule.Succeeded() And baseModuleInterfaceDiagnostics.length = 0 And Contains(baseModuleInterface, "TBase^Object{") And Contains(baseModuleInterface, ".BaseValue%&") And Contains(baseModuleInterface, "-Score%(delta%)=~qacme_base_TBase_Score__Bint~q") And Contains(baseModuleInterface, "-Stable%()=~qacme_base_TBase_Stable~q") And Contains(baseModuleInterface, "-ToString$()=~qacme_base_TBase_ToString~q") And Contains(baseModuleInterface, "-HashCode|()=~qacme_base_TBase_HashCode~q") And Contains(baseModuleInterface, "-Delete()=~qacme_base_TBase_Delete~q") And Contains(baseModuleInterface, "+Double%(value%)=~qacme_base_TBase_Double__Bint~q") And Contains(baseModuleInterface, "}=~qacme_base_TBase~q"), "a public base Type emits reusable field, lifecycle, fixed-slot, and appended-slot contracts")
Local baseModuleHeaderDiagnostics:TCompilerDiagnostic[]
Local baseModuleHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(baseModule, baseModuleHeaderDiagnostics)
Check(baseModuleHeaderDiagnostics.length = 0 And Contains(baseModuleHeader, "(*m_Score__Bint)") And Contains(baseModuleHeader, "(*f_Double__Bint)") And Contains(baseModuleHeader, "_acme_base_TBase_Score__Bint(") And Contains(baseModuleHeader, "_acme_base_TBase_ToString(") And Contains(baseModuleHeader, "_acme_base_TBase_Delete(") And Contains(baseModuleHeader, "acme_base_TBase_Double__Bint("), "base headers publish the full class-table shape, underscored method implementations, and receiver-free Type functions")
resolver.AddInterface("acme.base", "sdk/acme.base.i", baseModuleInterface)
Local sourceDerivedCall:TCompilerResult = TBlitzMaxCompiler.Compile("source-derived-imported-call.bmx", "SuperStrict~nImport acme.base~nType TCallingDerived Extends TBase~nMethod ReadStable:Int()~nReturn Stable()~nEnd Method~nEnd Type~nLocal value:TCallingDerived=New TCallingDerived~nLocal result:Int=value.Stable()+value.ReadStable()", resolver, TestOptions())
Check(sourceDerivedCall.Succeeded(), "a source-derived Type calls an inherited imported virtual method through implicit Self and an explicit derived receiver")
Local sourceDerivedCallDiagnostics:TCompilerDiagnostic[]
Local sourceDerivedCallC:String = TBlitzMaxCompiler.EmitRuntimeC(sourceDerivedCall, sourceDerivedCallDiagnostics)
Check(sourceDerivedCallDiagnostics.length = 0 And Contains(sourceDerivedCallC, "->clas->m_Stable(") And Contains(sourceDerivedCallC, "struct acme_base_TBase_obj *"), "inherited imported calls dispatch through the source-derived class table using the imported declaring receiver ABI")
resolver.AddInterface("acme.recursiveimport", "sdk/acme.recursiveimport.i", "superstrict~nTRecursiveBase^Object{~n.Peer:TRecursiveChild&~n.Value%&~n-GetSelf:TRecursiveBase()=~qacme_recursiveimport_TRecursiveBase_GetSelf~q~n}=~qacme_recursiveimport_TRecursiveBase~q~nTRecursiveChild^TRecursiveBase{~n.Marker%&~n}=~qacme_recursiveimport_TRecursiveChild~q")
Local recursiveImportedSource:TCompilerResult = TBlitzMaxCompiler.Compile("recursive-imported-layout.bmx", "SuperStrict~nImport acme.recursiveimport~nType TRecursiveConsumer Extends TRecursiveChild~nMethod Read:Int()~nValue = 41~nReturn GetSelf().Value + 1~nEnd Method~nEnd Type~nLocal item:TRecursiveConsumer = New TRecursiveConsumer~nLocal result:Int = item.Read()", resolver, TestOptions())
Local recursiveImportedDiagnostics:TCompilerDiagnostic[]
Local recursiveImportedC:String = TBlitzMaxCompiler.EmitRuntimeC(recursiveImportedSource, recursiveImportedDiagnostics)
Check(recursiveImportedSource.Succeeded() And recursiveImportedSource.ir.importedClasses.length = 2, "recursive imported member signatures intern one nominal shell per class ABI")
Check(recursiveImportedDiagnostics.length = 0 And Contains(recursiveImportedC, "->_acme_recursiveimport_trecursivebase_value") And Contains(recursiveImportedC, "->clas->m_GetSelf("), "source-derived layouts retain transitive imported fields and virtual slots after recursive shell completion")
Local runtimeInterfaceCast:TCompilerResult = TBlitzMaxCompiler.Compile("runtime-interface-cast.bmx", "SuperStrict~nType TDriver Abstract~nEnd Type~nInterface IWrappedDriver~nMethod SetDriver(driver:TDriver)~nEnd Interface~nFunction Wrap(driver:TDriver)~nIf IWrappedDriver(driver) Then IWrappedDriver(driver).SetDriver(driver)~nEnd Function", resolver, TestOptions())
Local runtimeInterfaceCastDiagnostics:TCompilerDiagnostic[]
Local runtimeInterfaceCastC:String = TBlitzMaxCompiler.EmitRuntimeC(runtimeInterfaceCast, runtimeInterfaceCastDiagnostics)
Check(runtimeInterfaceCast.Succeeded() And runtimeInterfaceCastDiagnostics.length = 0 And Contains(runtimeInterfaceCastC, "bbInterfaceDowncast") And Contains(runtimeInterfaceCastC, "bbObjectInterface"), "a runtime-derived Type-to-Interface cast lowers to checked Interface conversion and dispatch")
Local plainAssignment:TCompilerResult = TBlitzMaxCompiler.Compile("plain-assignment.bmx", "SuperStrict~nType TMessage~nField value:Int~nEnd Type~nLocal message:TMessage~nIf Not message~nmessage=New TMessage~nmessage.value=42~nEnd If", resolver, TestOptions())
Local plainAssignmentDiagnostics:TCompilerDiagnostic[]
Local plainAssignmentC:String = TBlitzMaxCompiler.EmitRuntimeC(plainAssignment, plainAssignmentDiagnostics)
Check(plainAssignment.Succeeded() And plainAssignmentDiagnostics.length = 0 And Contains(plainAssignmentC, "bmx_v0_message = "), "an ordinary assignment to existing typed storage remains writable")
Local rejectedAscribedAssignment:TCompilerResult = TBlitzMaxCompiler.Compile("rejected-ascribed-assignment.bmx", "SuperStrict~nType TMessage~nEnd Type~nLocal message:TMessage~nmessage:TMessage=New TMessage", resolver, TestOptions())
Check(Not rejectedAscribedAssignment.Succeeded() And CompilerDiagnosticSummary(rejectedAscribedAssignment).Contains("BMX2105"), "an existing assignment target cannot carry a postfix named type")
Local rejectedGenericPostfix:TCompilerResult = TBlitzMaxCompiler.Compile("rejected-generic-postfix.bmx", "SuperStrict~nFunction Convert<A, B>:B(value:A)~nReturn value:B~nEnd Function~nLocal converted:Int = Convert<String, Int>(~q1~q)", resolver, TestOptions())
Check(Not rejectedGenericPostfix.Succeeded() And CompilerDiagnosticSummary(rejectedGenericPostfix).Contains("BMX2105"), "a generic postfix type cannot bypass explicit conversion syntax")
Local derivedModuleSource:String = "SuperStrict~nModule acme.derived~nImport acme.base~nType TDerived Extends TBase~nField DerivedValue:Int~nMethod New(initialBaseValue:Int,initialDerivedValue:Int)~nBaseValue = initialBaseValue~nDerivedValue = initialDerivedValue~nEnd Method~nMethod Sum:Int()~nReturn BaseValue + DerivedValue~nEnd Method~nMethod Score:Int(delta:Int) Override~nReturn BaseValue + DerivedValue + delta~nEnd Method~nMethod ToString:String() Override~nIf DerivedValue Then Return ~qderived~q~nReturn ~qderived~q~nEnd Method~nMethod Compare:Int(other:Object) Override~nIf other Then Return BaseValue + DerivedValue~nReturn BaseValue + DerivedValue~nEnd Method~nMethod Delete()~nDerivedValue = 0~nEnd Method~nEnd Type"
Local derivedModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/derived.mod/derived.bmx", derivedModuleSource, resolver, TestOptions())
Check(derivedModule.Succeeded() And derivedModule.ir.classes.length = 1 And derivedModule.ir.classes[0].baseImportedClassId.length And derivedModule.ir.classes[0].declaredFieldStart = 1, "a source Type retains its imported base identity and flattened field prefix")
Local derivedModuleDump:String = TCompilerIrDumper.Dump(derivedModule.ir)
Check(Contains(derivedModuleDump, "extends imported @icls0") And Contains(derivedModuleDump, "BaseValue:Int [inherited imported @icls0] [abi _acme_base_tbase_basevalue]") And Contains(derivedModuleDump, "DerivedValue:Int [abi _acme_derived_tderived_derivedvalue]") And Contains(derivedModuleDump, "abi acme_derived_TDerived_Score__Bint slot m_Score__Bint [inherited-slot imported @icls0]") And Contains(derivedModuleDump, "abi acme_base_TBase_Double__Bint slot f_Double__Bint") And Contains(derivedModuleDump, "object-slot ToString @") And Contains(derivedModuleDump, "object-slot SendMessage @"), "derived IR retains imported slot order and fixed-slot identities while replacing overrides")
Local derivedModuleDiagnostics:TCompilerDiagnostic[]
Local derivedModuleC:String = TBlitzMaxCompiler.EmitRuntimeC(derivedModule, derivedModuleDiagnostics)
Check(derivedModuleDiagnostics.length = 0 And Contains(derivedModuleC, "struct acme_derived_TDerived_obj") And AppearsBefore(derivedModuleC, "_acme_base_tbase_basevalue", "_acme_derived_tderived_derivedvalue") And Contains(derivedModuleC, "(BBClass *)&acme_base_TBase") And Contains(derivedModuleC, "acme_base_TBase.ctor((BBOBJECT)bmx_self_self);") And Contains(derivedModuleC, "(BBSTRING (*)(BBOBJECT))_acme_derived_TDerived_ToString") And Contains(derivedModuleC, "(BBOBJECT (*)(BBOBJECT, BBOBJECT, BBOBJECT))_acme_base_TBase_SendMessage") And Contains(derivedModuleC, "_acme_base_TBase_Delete((struct acme_base_TBase_obj *)bmx_self_self);") And AppearsBefore(derivedModuleC, "(*m_Score__Bint)", "(*f_Double__Bint)") And AppearsBefore(derivedModuleC, "(*f_Double__Bint)", "(*m_Sum)"), "derived C replaces fixed slots with production method symbols, inherits dependency identities, and chains destruction into the imported base")
Local derivedModuleHeaderDiagnostics:TCompilerDiagnostic[]
Local derivedModuleHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(derivedModule, derivedModuleHeaderDiagnostics)
Check(derivedModuleHeaderDiagnostics.length = 0 And Contains(derivedModuleHeader, "#include <acme.mod/base.mod/.bmx/base.bmx.release.test.x64.h>") And AppearsBefore(derivedModuleHeader, "_acme_base_tbase_basevalue", "_acme_derived_tderived_derivedvalue") And AppearsBefore(derivedModuleHeader, "(*m_Score__Bint)", "(*f_Double__Bint)") And AppearsBefore(derivedModuleHeader, "(*f_Double__Bint)", "(*m_Sum)"), "derived headers reproduce imported object and class-table prefixes")
Local derivedModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local derivedModuleInterface:String = TBlitzMaxCompiler.EmitInterface(derivedModule, derivedModuleInterfaceDiagnostics)
Check(derivedModuleInterfaceDiagnostics.length = 0 And Contains(derivedModuleInterface, "import acme.base") And Contains(derivedModuleInterface, "TDerived^TBase{") And Contains(derivedModuleInterface, ".DerivedValue%&") And Contains(derivedModuleInterface, "-Score%(delta%)=~qacme_derived_TDerived_Score__Bint~q") And Contains(derivedModuleInterface, "-ToString$()=~qacme_derived_TDerived_ToString~q") And Contains(derivedModuleInterface, "-Delete()=~qacme_derived_TDerived_Delete~q") And Not Contains(derivedModuleInterface, ".BaseValue%&") And Not Contains(derivedModuleInterface, "+Double%") And Contains(derivedModuleInterface, "}=~qacme_derived_TDerived~q"), "derived compact interfaces name the imported base and serialize only declared members and overrides")
resolver.AddInterface("acme.derived", "sdk/acme.derived.i", derivedModuleInterface)
Local inheritanceConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("inheritance-consumer.bmx", "SuperStrict~nImport acme.derived~nLocal value:TDerived = New TDerived(20,22)~nLocal result:Int = value.Sum()~nLocal score:Int = value.Score(1)~nLocal doubled:Int = TDerived.Double(2)~nLocal ordering:Int = value.Compare(value)~nLocal hash:UInt = value.HashCode()~nLocal equal:Int = value.Equals(value)~nvalue.ToString()~nvalue.SendMessage(value,value)~nvalue.BaseValue = result + score + doubled + ordering + Int(hash) + equal", resolver, TestOptions())
Check(inheritanceConsumer.Succeeded(), "a third compilation consumes a derived Type and its transitively imported base field")
Local inheritanceConsumerDiagnostics:TCompilerDiagnostic[]
Local inheritanceConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(inheritanceConsumer, inheritanceConsumerDiagnostics)
Check(inheritanceConsumerDiagnostics.length = 0 And Contains(inheritanceConsumerC, "->clas->m_Score__Bint(") And Contains(inheritanceConsumerC, "->clas->ToString(") And Contains(inheritanceConsumerC, "->clas->Compare(") And Contains(inheritanceConsumerC, "->clas->SendMessage(") And Contains(inheritanceConsumerC, "->clas->HashCode(") And Contains(inheritanceConsumerC, "->clas->Equals(") And Contains(inheritanceConsumerC, "acme_base_TBase_Double__Bint(2)") And Contains(inheritanceConsumerC, "->_acme_base_tbase_basevalue"), "consumer C uses appended and fixed virtual dispatch, inherited Type-function ABI, and dependency-owned field identity")
Local sourceAbstractModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/abstractsource.mod/abstractsource.bmx", "SuperStrict~nModule acme.abstractsource~nType TFactory~nMethod Create:Object(value:Int) Abstract~nEnd Type~nType TConcreteFactory Extends TFactory~nMethod Create:Object(value:Int) Override~nReturn Self~nEnd Method~nEnd Type~nGlobal factory:TFactory=New TConcreteFactory~nFunction CreateValue:Object(value:Int)~nReturn factory.Create(value)~nEnd Function", resolver, TestOptions())
Local sourceAbstractDump:String = TCompilerIrDumper.Dump(sourceAbstractModule.ir)
Local sourceAbstractDiagnostics:TCompilerDiagnostic[]
Local sourceAbstractC:String = TBlitzMaxCompiler.EmitRuntimeC(sourceAbstractModule, sourceAbstractDiagnostics)
Local sourceAbstractInterfaceDiagnostics:TCompilerDiagnostic[]
Local sourceAbstractInterface:String = TBlitzMaxCompiler.EmitInterface(sourceAbstractModule, sourceAbstractInterfaceDiagnostics)
Check(sourceAbstractModule.Succeeded() And sourceAbstractModule.ir.classes[0].isAbstract And Contains(sourceAbstractDump, "class @cls0 TFactory:TFactory [published abi acme_abstractsource_TFactory] [abstract]") And Contains(sourceAbstractDump, "function-slot %cf0 @fn1 Create(Int) -> Object") And Contains(sourceAbstractDump, "[abstract]"), "a source Type that declares an abstract method retains its abstract class and slot identity in typed IR")
Check(sourceAbstractDiagnostics.length = 0 And Contains(sourceAbstractC, "brl_blitz_NullMethodError();") And Contains(sourceAbstractC, "return ((BBOBJECT)&bbNullObject);") And Contains(sourceAbstractC, "->clas->m_Create__Bint("), "runtime C emits the production null-method trap while concrete derived dispatch replaces the abstract slot")
Check(sourceAbstractInterfaceDiagnostics.length = 0 And Contains(sourceAbstractInterface, "TFactory^Object{") And Contains(sourceAbstractInterface, "-Create:Object(value%)A=") And Contains(sourceAbstractInterface, "}A=~qacme_abstractsource_TFactory~q"), "compact interfaces publish source abstract methods and Types with production A flags")
Local sourceAbstractTypeFunction:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/abstractfunction.mod/abstractfunction.bmx", "SuperStrict~nModule acme.abstractfunction~nType TAbstractFactory~nFunction Create:Object(value:Int) Abstract~nEnd Type", resolver, TestOptions())
Local sourceAbstractTypeFunctionInterfaceDiagnostics:TCompilerDiagnostic[]
Local sourceAbstractTypeFunctionInterface:String = TBlitzMaxCompiler.EmitInterface(sourceAbstractTypeFunction, sourceAbstractTypeFunctionInterfaceDiagnostics)
Check(sourceAbstractTypeFunction.Succeeded() And sourceAbstractTypeFunctionInterfaceDiagnostics.length = 0 And Contains(sourceAbstractTypeFunctionInterface, "+Create:Object(value%)A="), "compact interfaces publish abstract Type Functions with their distinct static-member record kind")
resolver.AddInterface("acme.abstractfunction", "sdk/acme.abstractfunction.i", sourceAbstractTypeFunctionInterface)
Local importedAbstractTypeFunction:TCompilerResult = TBlitzMaxCompiler.Compile("abstract-function-consumer.bmx", "SuperStrict~nImport acme.abstractfunction~nLocal invalid:Object=TAbstractFactory.Create(1)", resolver, TestOptions())
Check(Not importedAbstractTypeFunction.Succeeded() And HasLanguageDiagnostic(importedAbstractTypeFunction, "BMX3319"), "a source-free consumer rejects a direct call to an imported abstract Type Function before IR lowering")
Local markerAbstractType:TCompilerResult = TBlitzMaxCompiler.Compile("marker-abstract-type.bmx", "SuperStrict~nType TMarker Abstract~nMethod Name:String()~nReturn ~qmarker~q~nEnd Method~nEnd Type", resolver, TestOptions())
Check(markerAbstractType.Succeeded() And markerAbstractType.ir.classes[0].isAbstract, "an explicitly abstract marker Type need not invent an abstract method")
resolver.AddInterface("acme.abstractbase", "sdk/acme.abstractbase.i", "superstrict~nTAbstractBase^Object{~n.Seed%&~n-Value%()A=~qacme_abstractbase_TAbstractBase_Value~q~n-Stable%()=~qacme_abstractbase_TAbstractBase_Stable~q~n}A=~qacme_abstractbase_TAbstractBase~q~nTAbstractMiddle^TAbstractBase{~n-Extra%(delta%)A=~qacme_abstractbase_TAbstractMiddle_Extra__Bint~q~n}A=~qacme_abstractbase_TAbstractMiddle~q")
Local concreteDerivedSource:String = "SuperStrict~nModule acme.concrete~nImport acme.abstractbase~nType TConcrete Extends TAbstractMiddle~nField Offset:Int~nMethod New()~nEnd Method~nMethod Value:Int() Override~nReturn Seed + Offset~nEnd Method~nMethod Extra:Int(delta:Int) Override~nReturn Seed + Offset + delta~nEnd Method~nEnd Type"
Local concreteDerived:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/concrete.mod/concrete.bmx", concreteDerivedSource, resolver, TestOptions())
Check(concreteDerived.Succeeded() And concreteDerived.ir.classes.length = 1 And concreteDerived.ir.classes[0].functionSlots.length = 3, "a source Type can satisfy transitive abstract imported-base obligations")
Local concreteDerivedDump:String = TCompilerIrDumper.Dump(concreteDerived.ir)
Check(Contains(concreteDerivedDump, "imported-class @icls1 TAbstractBase:TAbstractBase abi acme_abstractbase_TAbstractBase [abstract]") And Contains(concreteDerivedDump, "imported-class @icls0 TAbstractMiddle:TAbstractMiddle abi acme_abstractbase_TAbstractMiddle extends @icls1 [abstract]") And Contains(concreteDerivedDump, "method %icm0 Value() -> Int slot m_Value abi acme_abstractbase_TAbstractBase_Value implementation _acme_abstractbase_TAbstractBase_Value [abstract]") And Contains(concreteDerivedDump, "method %icm2 Extra(Int) -> Int slot m_Extra__Bint abi acme_abstractbase_TAbstractMiddle_Extra__Bint implementation _acme_abstractbase_TAbstractMiddle_Extra__Bint [abstract]") And Contains(concreteDerivedDump, "abi acme_concrete_TConcrete_Value slot m_Value [inherited-slot imported @icls1]") And Contains(concreteDerivedDump, "[abi acme_concrete_TConcrete_Value] [implementation _acme_concrete_TConcrete_Value]") And Contains(concreteDerivedDump, "abi acme_concrete_TConcrete_Extra__Bint slot m_Extra__Bint [inherited-slot imported @icls0]") And Not Contains(concreteDerivedDump, "abi acme_concrete_TConcrete_Value slot m_Value [inherited-slot imported @icls1] [abstract]") And Not Contains(concreteDerivedDump, "abi acme_concrete_TConcrete_Extra__Bint slot m_Extra__Bint [inherited-slot imported @icls0] [abstract]"), "abstract imported slots retain linkage and implementation identities while matching source overrides replace them in place")
Local concreteDerivedDiagnostics:TCompilerDiagnostic[]
Local concreteDerivedC:String = TBlitzMaxCompiler.EmitRuntimeC(concreteDerived, concreteDerivedDiagnostics)
Check(concreteDerivedDiagnostics.length = 0 And AppearsBefore(concreteDerivedC, "(*m_Value)", "(*m_Stable)") And AppearsBefore(concreteDerivedC, "(*m_Stable)", "(*m_Extra__Bint)") And Contains(concreteDerivedC, "_acme_concrete_TConcrete_Value") And Contains(concreteDerivedC, "_acme_abstractbase_TAbstractBase_Stable") And Contains(concreteDerivedC, "_acme_concrete_TConcrete_Extra__Bint"), "a concrete derived descriptor uses implementation symbols while replacing transitive abstract slots and retaining concrete base slots")
Local concreteDerivedInterfaceDiagnostics:TCompilerDiagnostic[]
Local concreteDerivedInterface:String = TBlitzMaxCompiler.EmitInterface(concreteDerived, concreteDerivedInterfaceDiagnostics)
Check(concreteDerivedInterfaceDiagnostics.length = 0 And Contains(concreteDerivedInterface, "TConcrete^TAbstractMiddle{") And Contains(concreteDerivedInterface, "-New()=") And Contains(concreteDerivedInterface, "-Value%()=~qacme_concrete_TConcrete_Value~q") And Contains(concreteDerivedInterface, "-Extra%(delta%)=~qacme_concrete_TConcrete_Extra__Bint~q") And Not Contains(concreteDerivedInterface, "-Stable%"), "the concrete derived interface publishes only its implementations and declared layout")
resolver.AddInterface("acme.concrete", "sdk/acme.concrete.i", concreteDerivedInterface)
Local concreteConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("concrete-consumer.bmx", "SuperStrict~nImport acme.concrete~nLocal value:TConcrete = New TConcrete~nvalue.Seed = 20~nvalue.Offset = 22~nvalue.Seed = value.Value() + value.Stable() + value.Extra(1)", resolver, TestOptions())
Check(concreteConsumer.Succeeded(), "a third compilation consumes the concrete implementation of an imported abstract contract")
Local concreteConsumerDiagnostics:TCompilerDiagnostic[]
Local concreteConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(concreteConsumer, concreteConsumerDiagnostics)
Check(concreteConsumerDiagnostics.length = 0 And Contains(concreteConsumerC, "->_acme_abstractbase_tabstractbase_seed") And Contains(concreteConsumerC, "->clas->m_Value(") And Contains(concreteConsumerC, "->clas->m_Stable(") And Contains(concreteConsumerC, "->clas->m_Extra__Bint("), "consumer C accesses the transitive field prefix and dispatches through the preserved abstract-base slot order")
Local incompleteImportedAbstractBase:TCompilerResult = TBlitzMaxCompiler.Compile("incomplete-imported-abstract-base.bmx", "SuperStrict~nImport acme.abstractbase~nType TIncomplete Extends TAbstractMiddle~nMethod Value:Int() Override~nReturn 1~nEnd Method~nEnd Type", resolver, TestOptions())
Check(incompleteImportedAbstractBase.Succeeded() And incompleteImportedAbstractBase.ir.classes.length = 1 And incompleteImportedAbstractBase.ir.classes[0].isAbstract, "a source Type that leaves one transitive imported abstract obligation unresolved remains an abstract intermediate Type")

Local publicRoutineModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/routines.mod/routines.bmx", "SuperStrict~nModule acme.routines~nFunction PublicApi:Int(callback:Int(a:Int,b:Int)=Null)~nReturn 1~nEnd Function", resolver, TestOptions())
Local publicRoutineInterfaceDiagnostics:TCompilerDiagnostic[]
Local publicRoutineInterface:String = TBlitzMaxCompiler.EmitInterface(publicRoutineModule, publicRoutineInterfaceDiagnostics)
Check(publicRoutineModule.Succeeded() And publicRoutineInterfaceDiagnostics.length = 0 And Contains(publicRoutineInterface, "callback%(a%,b%)=Null"), "compact interfaces publish free-routine callable Null defaults semantically")
resolver.AddInterface("acme.routines", "sdk/acme.routines.i", publicRoutineInterface)
Local publicRoutineConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("public-routine-consumer.bmx", "SuperStrict~nImport acme.routines~nLocal result:Int=PublicApi()", resolver, TestOptions())
Local publicRoutineConsumerDiagnostics:TCompilerDiagnostic[]
Local publicRoutineConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(publicRoutineConsumer, publicRoutineConsumerDiagnostics)
Check(publicRoutineConsumer.Succeeded() And publicRoutineConsumerDiagnostics.length = 0 And Contains(publicRoutineConsumerC, "brl_blitz_NullFunctionError"), "imported free-routine omissions materialize the typed callable Null sentinel")
Local computedConstantModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/constants.mod/constants.bmx", "SuperStrict~nModule acme.constants~nConst Computed:Int=1+2", resolver, TestOptions())
Local computedConstantInterfaceDiagnostics:TCompilerDiagnostic[]
Local computedConstantInterface:String = TBlitzMaxCompiler.EmitInterface(computedConstantModule, computedConstantInterfaceDiagnostics)
Check(computedConstantInterfaceDiagnostics.length = 0 And Contains(computedConstantInterface, "Computed%=3%"), "compact interface emission uses the semantic value of a computed constant")
Local signBitConstantModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/signbitconstant.mod/signbitconstant.bmx", "SuperStrict~nModule acme.signbitconstant~nConst SignBit:Int = 1 Shl 31", resolver, TestOptions())
Local signBitConstantDiagnostics:TCompilerDiagnostic[]
Local signBitConstantInterface:String = TBlitzMaxCompiler.EmitInterface(signBitConstantModule, signBitConstantDiagnostics)
Check(signBitConstantDiagnostics.length = 0 And Contains(signBitConstantInterface, "SignBit%=-2147483648%"), "compact interfaces publish Int operator results in their signed 32-bit representation")
resolver.AddInterface("acme.constants", "sdk/acme.constants.i", computedConstantInterface)
Local computedConstantConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("constant-consumer.bmx", "SuperStrict~nImport acme.constants~nLocal constantResult:Int=Computed", resolver, TestOptions())
Local computedConstantConsumerDiagnostics:TCompilerDiagnostic[]
Local computedConstantConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(computedConstantConsumer, computedConstantConsumerDiagnostics)
Check(computedConstantConsumer.Succeeded() And computedConstantConsumerDiagnostics.length = 0 And Contains(computedConstantConsumerC, "bmx_v0_constantResult = 3;"), "computed constants round-trip and fold in a separate consumer")

Local compactQuote:String = Chr(34)
Local compactEscape:String = Chr(126)
Local escapedDefaultSource:String = "SuperStrict~nModule acme.escapeddefaults~nConst Escaped:String=" + compactQuote + "line" + compactEscape + "nquote=" + compactEscape + "q tilde=" + compactEscape + compactEscape + " tab=" + compactEscape + "t cr=" + compactEscape + "r end caf" + Chr(233) + compactQuote + "~nFunction DefaultString:String(value:String=Escaped)~nReturn value~nEnd Function"
Local escapedDefaultModule:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/escapeddefaults.mod/escapeddefaults.bmx", escapedDefaultSource, resolver, TestOptions())
Local escapedDefaultDiagnostics:TCompilerDiagnostic[]
Local escapedDefaultInterface:String = TBlitzMaxCompiler.EmitInterface(escapedDefaultModule, escapedDefaultDiagnostics)
Local escapedDefaultEncoding:String = "$" + compactQuote + "line" + compactEscape + "nquote=" + compactEscape + "q tilde=" + compactEscape + compactEscape + " tab=" + compactEscape + "t cr=" + compactEscape + "r end caf" + compactEscape + "233" + compactEscape + compactQuote
Check(escapedDefaultModule.Succeeded() And escapedDefaultDiagnostics.length = 0 And Contains(escapedDefaultInterface, "Escaped$=" + escapedDefaultEncoding) And Contains(escapedDefaultInterface, "value$=" + escapedDefaultEncoding) And Not Contains(escapedDefaultInterface, "$" + compactQuote + "line" + Chr(10)), "compact String constants and defaults use production escape spelling instead of embedding control or non-ASCII characters")
Local parsedEscapedDefaultInterface:TInterfaceFile = TInterfaceFileParser.Parse(escapedDefaultInterface, "sdk/acme.escapeddefaults.i")
Check(parsedEscapedDefaultInterface.diagnostics.length = 0 And parsedEscapedDefaultInterface.declarations.length = 2, "escaped String constants and defaults round-trip through the shared compact-interface parser")
resolver.AddInterface("acme.escapeddefaults", "sdk/acme.escapeddefaults.i", escapedDefaultInterface)
Local escapedDefaultConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("escaped-default-consumer.bmx", "SuperStrict~nImport acme.escapeddefaults~nLocal direct:String=Escaped~nLocal omitted:String=DefaultString()", resolver, TestOptions())
Local escapedDefaultConsumerDiagnostics:TCompilerDiagnostic[]
Local escapedDefaultConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(escapedDefaultConsumer, escapedDefaultConsumerDiagnostics)
Check(escapedDefaultConsumer.Succeeded() And escapedDefaultConsumerDiagnostics.length = 0 And Contains(escapedDefaultConsumerC, "acme_escapeddefaults_DefaultString"), "a source-free consumer restores escaped String constants and omitted defaults")

Local moduleAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction _TimerFired(data:Int) { nomangle }~nEnd Function", "/sdk/mod/brl.mod/timerdefault.mod/timerdefault.bmx")
Check(moduleAnalysis.Succeeded(), "module NoMangle naming fixture analyzes")
Local timerFired:TSymbol = moduleAnalysis.model.globalScope.LookupLocal("_TimerFired")[0]
Check(TCompilerAbiNamer.LegacyRoutineName(moduleAnalysis.model, timerFired) = "brl_timerdefault__TimerFired", "module NoMangle ABI matches the production runtime contract")
Check(TCompilerAbiNamer.LegacySourceRoutineName(moduleAnalysis.model, timerFired, "/sdk/mod/brl.mod/timerdefault.mod/callbacks.bmx") = "brl_timerdefault_callbacks__TimerFired", "included-source NoMangle ABI retains the production source-unit component used by native glue")
Local applicationNoMangleOptions:TCompilerOptions = TestOptions()
applicationNoMangleOptions.applicationBuild = True
applicationNoMangleOptions.applicationSourceUnit = True
applicationNoMangleOptions.applicationIdentity = "application.maxide"
applicationNoMangleOptions.sourceModuleName = "application.maxide"
applicationNoMangleOptions.sourceUnitPath = "common.bmx"
Local applicationNoMangle:TCompilerResult = TBlitzMaxCompiler.Compile("/work/common.bmx", "SuperStrict~nType TSCNotification~nFunction _update(n:TSCNotification, code:Int) { nomangle }~nEnd Function~nEnd Type", resolver, applicationNoMangleOptions)
Local applicationNoMangleDiagnostics:TCompilerDiagnostic[]
Local applicationNoMangleC:String = TBlitzMaxCompiler.EmitRuntimeC(applicationNoMangle, applicationNoMangleDiagnostics)
Local applicationNoMangleInterfaceDiagnostics:TCompilerDiagnostic[]
Local applicationNoMangleInterface:String = TBlitzMaxCompiler.EmitInterface(applicationNoMangle, applicationNoMangleInterfaceDiagnostics)
Check(applicationNoMangle.Succeeded() And applicationNoMangleDiagnostics.length = 0 And applicationNoMangleInterfaceDiagnostics.length = 0 And Contains(applicationNoMangleC, "_m_common_TSCNotification__update(") And Contains(applicationNoMangleInterface, "_m_common_TSCNotification__update"), "application-owned quoted-source NoMangle ABI retains and publishes the production m_<file> scope used by native glue")
Check(TCompilerAbiNamer.RoutineSourceName(":=") = "_assign" And TCompilerAbiNamer.RoutineSourceName(":+") = "_addeq" And TCompilerAbiNamer.RoutineSourceName(":*") = "_muleq" And TCompilerAbiNamer.RoutineSourceName("=") = "_eq" And TCompilerAbiNamer.RoutineSourceName("<>") = "_ne", "symbolic operators receive distinct readable ABI components before C sanitization")

Local structSource:String = "SuperStrict~nStruct SPoint~nField x:Int~nField y:Int~nMethod Translate(dx:Int,dy:Int)~nx=x+dx~ny=y+dy~nEnd Method~nEnd Struct~nFunction Offset:SPoint(value:SPoint,dx:Int)~nvalue.x=value.x+dx~nReturn value~nEnd Function~nFunction Move(value:SPoint Var,dx:Int,dy:Int)~nvalue.x=value.x+dx~nvalue.y=value.y+dy~nEnd Function~nFunction ForwardMove(value:SPoint Var,dx:Int,dy:Int)~nMove(value,dx,dy)~nEnd Function~nLocal original:SPoint~noriginal.x=20~noriginal.y=22~nLocal copied:SPoint=original~ncopied.x=1~ncopied.Translate(2,3)~nLocal shifted:SPoint=Offset(original,2)~nForwardMove(shifted,3,4)~nLocal result:Int=original.x+copied.x+copied.y+shifted.x+shifted.y"
Local structValue:TCompilerResult = TBlitzMaxCompiler.Compile("struct-value.bmx", structSource, resolver, TestOptions())
Check(structValue.Succeeded() And structValue.ir.structs.length = 1 And structValue.ir.structs[0].fields.length = 2, "scalar Struct declarations lower to explicit typed layouts")
Local structDump:String = TCompilerIrDumper.Dump(structValue.ir)
Check(Contains(structDump, "struct @st0 SPoint:SPoint") And Contains(structDump, "field struct @st0.%sf0") And Contains(structDump, "address-of : SPoint") And Contains(structDump, "symbol by-reference %p0 value") And Contains(structDump, "call struct-direct") And Contains(structDump, "[struct @st0] [method receiver SPoint]"), "Struct IR retains field identity, pointer receivers, and explicit Var address semantics")
Local structDiagnostics:TCompilerDiagnostic[]
Local structC:String = TBlitzMaxCompiler.EmitC(structValue, structDiagnostics)
Check(structDiagnostics.length = 0 And Contains(structC, "struct bmx_struct_st0_SPoint {") And Contains(structC, "struct bmx_struct_st0_SPoint bmx_fn0_Offset(struct bmx_struct_st0_SPoint") And Contains(structC, "void bmx_fn1_Move(struct bmx_struct_st0_SPoint *") And Contains(structC, "void bmx_fn3_Translate(struct bmx_struct_st0_SPoint *") And Contains(structC, "bmx_fn3_Translate((&bmx_v1_copied), 2, 3)") And Contains(structC, "((*bmx_p0_value).") And Contains(structC, "bmx_fn1_Move((&(*bmx_p0_value))") And Contains(structC, "bmx_v0_original = bmx_struct_new_bmx_class_st0_SPoint_default()"), "C emission preserves Struct value copy, pointer methods, return, default construction, and Var pointer ABI")
Local structRuntimeDiagnostics:TCompilerDiagnostic[]
Local structRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(structValue, structRuntimeDiagnostics)
Check(structRuntimeDiagnostics.length = 0 And Contains(structRuntimeC, "BBDEBUGSCOPE_USERSTRUCT, ~qSPoint~q") And Contains(structRuntimeC, "BBDEBUGDECL_FIELD, ~qx~q, ~qi~q") And Contains(structRuntimeC, ".struct_size = sizeof(struct bmx_struct_st0_SPoint)") And Contains(structRuntimeC, "bbObjectRegisterStruct((BBDebugScope *)&bmx_struct_scope_st0)"), "ordinary Structs publish and register their reflected field layout and byte size")
Local nestedStructSource:String = "SuperStrict~nStruct SBounds~nField lower:SCoordinate~nField upper:SCoordinate~nEnd Struct~nStruct SCoordinate~nField x:Int=1~nField y:Int=2~nMethod Move(delta:Int)~nx=x+delta~ny=y+delta~nEnd Method~nEnd Struct~nFunction AdjustCoordinate(value:SCoordinate Var,delta:Int)~nvalue.x=value.x+delta~nEnd Function~nLocal bounds:SBounds=New SBounds~nbounds.lower.x=20~nbounds.lower.y=22~nbounds.upper=bounds.lower~nbounds.lower.Move(1)~nAdjustCoordinate(bounds.upper,2)~nLocal result:Int=bounds.upper.x+bounds.upper.y"
Local nestedStruct:TCompilerResult = TBlitzMaxCompiler.Compile("nested-struct.bmx", nestedStructSource, resolver, TestOptions())
Local nestedStructDump:String = TCompilerIrDumper.Dump(nestedStruct.ir)
Check(nestedStruct.Succeeded() And nestedStruct.ir.structs.length = 2 And Contains(nestedStructDump, "lower:SCoordinate") And Contains(nestedStructDump, "[struct @st1]"), "nested source Struct fields retain explicit value-layout dependencies even when declared before their field type")
Local nestedStructDiagnostics:TCompilerDiagnostic[]
Local nestedStructC:String = TBlitzMaxCompiler.EmitC(nestedStruct, nestedStructDiagnostics)
Check(nestedStructDiagnostics.length = 0 And AppearsBefore(nestedStructC, "struct bmx_struct_st1_SCoordinate {", "struct bmx_struct_st0_SBounds {") And Contains(nestedStructC, "struct bmx_struct_st1_SCoordinate _bmx_class_st0_sbounds_lower;") And Contains(nestedStructC, "_bmx_class_st0_sbounds_lower = bmx_struct_new_bmx_class_st1_SCoordinate_default();") And Contains(nestedStructC, "_bmx_class_st0_sbounds_upper = bmx_struct_new_bmx_class_st1_SCoordinate_default();") And Contains(nestedStructC, "((bmx_v0_bounds._bmx_class_st0_sbounds_lower)._bmx_class_st1_scoordinate_x) = 20;") And Contains(nestedStructC, "bmx_fn1_Move((&(bmx_v0_bounds._bmx_class_st0_sbounds_lower)), 1)") And Contains(nestedStructC, "bmx_fn0_AdjustCoordinate((&(bmx_v0_bounds._bmx_class_st0_sbounds_upper)), 2)"), "C layouts are dependency ordered, recursively default constructed, and preserve nested assignment, method-receiver, and Var lvalues")
Local recursiveStruct:TCompilerResult = TBlitzMaxCompiler.Compile("recursive-struct.bmx", "SuperStrict~nStruct SRecursive~nField child:SRecursive~nEnd Struct", resolver, TestOptions())
Check(Not recursiveStruct.Succeeded() And HasCompilerDiagnostic(recursiveStruct, "BMXC1192"), "recursive by-value Struct layouts are diagnosed before C emission")
Local importedSelfRoutineStruct:TCompilerResult = TBlitzMaxCompiler.Compile("imported-self-routine-struct.bmx", "SuperStrict~nImport acme.selfstruct~nLocal first:SSelf~nLocal second:SSelf=first~nLocal scalar:Int~nfirst.Split(scalar)", resolver, TestOptions())
Local importedSelfRoutineStructDiagnostics:TCompilerDiagnostic[]
Local importedSelfRoutineStructC:String = TBlitzMaxCompiler.EmitRuntimeC(importedSelfRoutineStruct, importedSelfRoutineStructDiagnostics)
Check(importedSelfRoutineStruct.Succeeded() And importedSelfRoutineStruct.ir.importedStructs.length = 1 And importedSelfRoutineStruct.ir.importedStructs[0].routines.length = 4 And Not HasCompilerDiagnostic(importedSelfRoutineStruct, "BMXC1192"), "imported Struct routines may return or accept their owning value without creating a layout-cycle edge")
Check(importedSelfRoutineStructDiagnostics.length = 0 And Contains(importedSelfRoutineStructC, "acme_selfstruct_SSelf_New_ObjectNew()") And Contains(importedSelfRoutineStructC, "_acme_selfstruct_SSelf_Split((&bmx_v0_first), (&bmx_v2_scalar))"), "an imported self-referential routine signature remains independent from default value construction while scalar Var parameters use pointer ABI")
Local importedPointerStruct:TCompilerResult = TBlitzMaxCompiler.Compile("imported-pointer-struct.bmx", "SuperStrict~nImport acme.pointerstruct~nLocal node:SPointerNode~nLocal nextNode:SPointerNode Ptr=node.next", resolver, TestOptions())
Check(importedPointerStruct.Succeeded() And importedPointerStruct.ir.importedStructs.length = 1 And importedPointerStruct.ir.importedStructs[0].fields.length = 1 And Not HasCompilerDiagnostic(importedPointerStruct, "BMXC1192"), "an imported Struct pointer to its own type is indirection rather than a value-layout cycle")
Local importedEnumStruct:TCompilerResult = TBlitzMaxCompiler.Compile("imported-enum-struct.bmx", "SuperStrict~nImport acme.enumstruct~nLocal empty:SEnumCell=New SEnumCell~nFunction StateValue:Int(cell:SEnumCell Var)~ncell.state=EImportedState.Ready~nReturn Int(cell.state)~nEnd Function", resolver, TestOptions())
Local importedEnumStructDump:String = TCompilerIrDumper.Dump(importedEnumStruct.ir)
Local importedEnumStructDiagnostics:TCompilerDiagnostic[]
Local importedEnumStructC:String = TBlitzMaxCompiler.EmitRuntimeC(importedEnumStruct, importedEnumStructDiagnostics)
Check(importedEnumStruct.Succeeded() And Contains(importedEnumStructDump, "field %isf0 state:EImportedState") And Contains(importedEnumStructDump, "field imported-struct @ist0.%isf0"), "imported Struct layouts retain imported Enum fields as their canonical underlying ABI values")
Check(importedEnumStructDiagnostics.length = 0 And Contains(importedEnumStructC, "_acme_enumstruct_senumcell_state") And Contains(importedEnumStructC, "(struct acme_enumstruct_SEnumCell){0}") And Not Contains(importedEnumStructC, "struct acme_enumstruct_SEnumCell {"), "runtime C uses the dependency-owned Struct layout for zero construction and Enum field access")
Local managedStructSource:String = "SuperStrict~nInterface IMarker~nEnd Interface~nType TPeer~nEnd Type~nStruct SManaged~nField text:String~nField values:Int[]~nField owner:Object~nField peer:TPeer~nField marker:IMarker~nEnd Struct~nStruct SOuter~nField value:SManaged~nEnd Struct~nType THolder~nField state:SOuter~nEnd Type~nLocal localValue:SManaged~nLocal holder:THolder=New THolder"
Local managedStruct:TCompilerResult = TBlitzMaxCompiler.Compile("managed-struct.bmx", managedStructSource, resolver, TestOptions())
Local managedStructDump:String = TCompilerIrDumper.Dump(managedStruct.ir)
Check(managedStruct.Succeeded() And managedStruct.ir.structs[0].containsManagedReferences And managedStruct.ir.structs[1].containsManagedReferences And Not managedStruct.ir.classes[0].hasManagedFields And managedStruct.ir.classes[1].hasManagedFields And Contains(managedStructDump, "SManaged:SManaged [managed-references]") And Contains(managedStructDump, "SOuter:SOuter [managed-references]"), "String, Array, Object, Type, and Interface references classify a Struct and propagate recursively into containing Types")
Local managedStructDiagnostics:TCompilerDiagnostic[]
Local managedStructC:String = TBlitzMaxCompiler.EmitRuntimeC(managedStruct, managedStructDiagnostics)
Check(managedStructDiagnostics.length = 0 And Contains(managedStructC, "BBSTRING _bmx_class_st0_smanaged_text;") And Contains(managedStructC, "BBARRAY _bmx_class_st0_smanaged_values;") And Contains(managedStructC, "BBOBJECT _bmx_class_st0_smanaged_owner;") And Contains(managedStructC, "struct bmx_cls0_TPeer_obj * _bmx_class_st0_smanaged_peer;") And Contains(managedStructC, "BBOBJECT _bmx_class_st0_smanaged_marker;") And Contains(managedStructC, "_bmx_class_st0_smanaged_text = &bbEmptyString;") And Contains(managedStructC, "_bmx_class_st0_smanaged_values = &bbEmptyArray;") And Contains(managedStructC, "_bmx_class_st0_smanaged_owner = ((BBOBJECT)&bbNullObject);") And Contains(managedStructC, "_bmx_class_st0_smanaged_peer = ((struct bmx_cls0_TPeer_obj *)&bbNullObject);") And Contains(managedStructC, "_bmx_class_st0_smanaged_marker = ((BBOBJECT)&bbNullObject);") And Contains(managedStructC, "bmx_v0_localValue = bmx_struct_new_bmx_class_st0_SManaged_default()") And Contains(managedStructC, "bbObjectNew((BBClass *)&bmx_class_cls1_THolder)") And Contains(managedStructC, "->bmx_field_f0_state = bmx_struct_new_bmx_class_st1_SOuter_default();"), "managed Struct construction installs typed runtime sentinels while containing Types use scanned allocation and recursive default helpers")
Local structArraySource:String = "SuperStrict~nStruct SItem~nField number:Int=3~nField text:String~nMethod Add(delta:Int)~nnumber=number+delta~nEnd Method~nEnd Struct~nFunction Mutate(value:SItem Var,delta:Int)~nvalue.number=value.number+delta~nEnd Function~nLocal values:SItem[]=New SItem[2]~nvalues[0].number=20~nvalues[0].Add(2)~nvalues[1]=values[0]~nMutate(values[1],3)~nLocal first:SItem=values[0]~nLocal literal:SItem[]=[values[0],values[1]]~nLocal joined:SItem[]=values+literal~nLocal total:Int=joined.length+first.number~nFor Local item:SItem=EachIn values~ntotal=total+item.number~nNext"
Local structArray:TCompilerResult = TBlitzMaxCompiler.Compile("struct-array.bmx", structArraySource, resolver, TestOptions())
Local structArrayDump:String = TCompilerIrDumper.Dump(structArray.ir)
Check(structArray.Succeeded() And Contains(structArrayDump, "array-new SItem encoding ~q@SItem~q rank 1") And Contains(structArrayDump, "array-element SItem rank 1") And Contains(structArrayDump, "array-literal SItem encoding ~q@SItem~q count 2") And Contains(structArrayDump, "array-concat SItem encoding ~q@SItem~q") And Contains(structArrayDump, "element-layout struct @st0"), "Struct-array IR retains the value layout identity across allocation, indexing, literals, and concatenation")
Local structArrayDiagnostics:TCompilerDiagnostic[]
Local structArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(structArray, structArrayDiagnostics)
Check(structArrayDiagnostics.length = 0 And Contains(structArrayC, "static inline void bmx_struct_array_init_st0(void *bmx_value)") And Contains(structArrayC, "= bmx_struct_new_bmx_class_st0_SItem_default();") And Contains(structArrayC, "bbArrayNew1DStruct(~q@SItem~q, 2, sizeof(struct bmx_struct_st0_SItem), bmx_struct_array_init_st0)") And Contains(structArrayC, "bbArrayFromDataStruct(~q@SItem~q, 2, (struct bmx_struct_st0_SItem[]){") And Contains(structArrayC, "bbArrayConcat(~q@SItem~q"), "Struct arrays use scanned @ storage, element-sized runtime allocation, default construction, literal copying, and concatenation")
Check(Contains(structArrayC, "bmx_fn1_Add((&((struct bmx_struct_st0_SItem*)BBARRAYDATA(") And Contains(structArrayC, "bmx_fn0_Mutate((&((struct bmx_struct_st0_SItem*)BBARRAYDATA(") And Contains(structArrayC, "struct bmx_struct_st0_SItem bmx_tmp_") And Contains(structArrayC, "->scales[0]"), "indexed Struct elements remain addressable for methods and Var while reads and EachIn copy values")
Local parameterizedStructArray:TCompilerResult = TBlitzMaxCompiler.Compile("parameterized-struct-array.bmx", "SuperStrict~nStruct SParameterizedItem~nField value:Int=7~nMethod New(seed:Int)~nvalue=seed~nEnd Method~nEnd Struct~nLocal values:SParameterizedItem[]=New SParameterizedItem[1]~nLocal result:Int=values[0].value", resolver, TestOptions())
Local parameterizedStructArrayDiagnostics:TCompilerDiagnostic[]
Local parameterizedStructArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(parameterizedStructArray, parameterizedStructArrayDiagnostics)
Check(parameterizedStructArray.Succeeded() And parameterizedStructArrayDiagnostics.length = 0 And Contains(parameterizedStructArrayC, "bmx_struct_new_bmx_class_st0_SParameterizedItem_default") And Contains(parameterizedStructArrayC, "_sparameterizeditem_value = 7;") And Contains(parameterizedStructArrayC, "bbArrayNew1DStruct(~q@SParameterizedItem~q, 1"), "Struct arrays retain field-default initialization even when the element type only declares parameterized constructors")
Local structConstructorSource:String = "SuperStrict~nStruct SRange~nField first:Int=2~nField last:Int=first+3~nMethod Add(delta:Int)~nfirst=first+delta~nlast=last+delta~nEnd Method~nMethod Span:Int()~nReturn last-first~nEnd Method~nMethod New(seed:Int)~nAdd(seed)~nEnd Method~nEnd Struct~nLocal range:SRange=New SRange(10)~nLocal span:Int=range.Span()~nLocal temporarySpan:Int=New SRange(20).Span()"
Local structConstructor:TCompilerResult = TBlitzMaxCompiler.Compile("struct-constructor.bmx", structConstructorSource, resolver, TestOptions())
Local structConstructorDump:String = TCompilerIrDumper.Dump(structConstructor.ir)
Check(structConstructor.Succeeded() And Contains(structConstructorDump, "initializer") And Contains(structConstructorDump, "struct-new @st0 constructor @") And Contains(structConstructorDump, "materialize %t0:SRange") And Contains(structConstructorDump, "[constructor]"), "Struct construction retains ordered field initializers, selected constructor, and temporary receiver materialization")
Local structConstructorDiagnostics:TCompilerDiagnostic[]
Local structConstructorC:String = TBlitzMaxCompiler.EmitC(structConstructor, structConstructorDiagnostics)
Check(structConstructorDiagnostics.length = 0 And Contains(structConstructorC, "bmx_struct_new_") And Contains(structConstructorC, "bmx_struct_value_st0 = {0};") And AppearsBefore(structConstructorC, "_srange_first = 2;", "_srange_last =") And AppearsBefore(structConstructorC, "_srange_last =", "bmx_fn2_New(&bmx_struct_value_st0") And Contains(structConstructorC, "bmx_fn0_Add((&(*bmx_self_self))"), "Struct construction zeroes storage, initializes fields in order, then invokes pointer-receiver constructor code")
Local structDelegationSource:String = "SuperStrict~nExtern~nFunction Mark:Int(value:Int)=~qbcc2_mark~q~nEnd Extern~nStruct SDelegating~nField first:Int=Mark(1)~nField second:Int=Mark(2)~nMethod New()~nNew(Mark(4))~nfirst=first+Mark(3)~nEnd Method~nMethod New(seed:Int)~nfirst=seed~nEnd Method~nEnd Struct~nLocal value:SDelegating=New SDelegating"
Local structDelegation:TCompilerResult = TBlitzMaxCompiler.Compile("struct-delegation.bmx", structDelegationSource, resolver, TestOptions())
Local structDelegationDump:String = TCompilerIrDumper.Dump(structDelegation.ir)
Check(structDelegation.Succeeded() And Contains(structDelegationDump, "[chains @fn1] [same-type-chain]"), "Struct constructor delegation retains its selected same-Struct edge and consumes the first statement")
Local structDelegationDiagnostics:TCompilerDiagnostic[]
Local structDelegationC:String = TBlitzMaxCompiler.EmitC(structDelegation, structDelegationDiagnostics)
Check(structDelegationDiagnostics.length = 0 And Contains(structDelegationC, "bmx_fn1_New((struct bmx_struct_st0_SDelegating *)bmx_self_self, bcc2_mark(4));") And AppearsBefore(structDelegationC, "_sdelegating_first = bcc2_mark(1);", "_sdelegating_second = bcc2_mark(2);") And AppearsBefore(structDelegationC, "_sdelegating_second = bcc2_mark(2);", "bmx_fn0_New(&bmx_struct_value_st0)") And Not Contains(structDelegationC, "void bmx_fn0_New(struct bmx_struct_st0_SDelegating * bmx_self_self) {~n    bmx_struct_value"), "Struct fields initialize once in the value helper before the selected constructor delegates on the same pointer receiver")
Local recursiveStructDelegation:TCompilerResult = TBlitzMaxCompiler.Compile("recursive-struct-delegation.bmx", "SuperStrict~nStruct SRecursiveNew~nMethod New()~nNew(1)~nEnd Method~nMethod New(value:Int)~nNew()~nEnd Method~nEnd Struct~nLocal value:SRecursiveNew=New SRecursiveNew", resolver, TestOptions())
Check(Not recursiveStructDelegation.Succeeded() And HasCompilerDiagnostic(recursiveStructDelegation, "BMXC1201"), "indirect recursive Struct constructor delegation is rejected")
Local destructorStruct:TCompilerResult = TBlitzMaxCompiler.Compile("destructor-struct.bmx", "SuperStrict~nStruct SDelete~nMethod Delete()~nEnd Method~nEnd Struct", resolver, TestOptions())
Check(Not destructorStruct.Succeeded() And HasCompilerDiagnostic(destructorStruct, "BMXC1195"), "Struct Delete methods are rejected because Structs have ordinary C value lifetime")
Local publicStructSource:String = "SuperStrict~nModule acme.values~nStruct SValue~nField first:Int=2~nField second:Int=3~nMethod New(seed:Int)~nfirst=first+seed~nsecond=second+seed~nEnd Method~nMethod Move(delta:Int)~nfirst=first+delta~nsecond=second+delta~nEnd Method~nMethod Sum:Int()~nReturn first+second~nEnd Method~nEnd Struct~nFunction MakeValue:SValue(seed:Int)~nReturn New SValue(seed)~nEnd Function~nFunction Adjust(value:SValue Var,delta:Int)~nvalue.Move(delta)~nEnd Function"
Local publicStruct:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/values.mod/values.bmx", publicStructSource, resolver, TestOptions())
Local publicStructDump:String = TCompilerIrDumper.Dump(publicStruct.ir)
Check(publicStruct.Succeeded() And publicStruct.ir.structs.length = 1 And publicStruct.ir.structs[0].isPublished And Contains(publicStructDump, "[abi acme_values_SValue_Move__Bint] [implementation _acme_values_SValue_Move__Bint]"), "public Structs lower with separate compact linkage and C implementation identities")
Local publicStructInterfaceDiagnostics:TCompilerDiagnostic[]
Local publicStructInterface:String = TBlitzMaxCompiler.EmitInterface(publicStruct, publicStructInterfaceDiagnostics)
Check(publicStructInterfaceDiagnostics.length = 0 And Contains(publicStructInterface, "SValue^Null{") And Contains(publicStructInterface, ".first%&") And Contains(publicStructInterface, ".second%&") And Contains(publicStructInterface, "-New(seed%)=") And Contains(publicStructInterface, "-Move(delta%)=") And Contains(publicStructInterface, "-Sum%()=") And Contains(publicStructInterface, "}S=~qacme_values_SValue~q") And Contains(publicStructInterface, "MakeValue:SValue(seed%)=") And Contains(publicStructInterface, "Adjust(value:SValue Var,delta%)="), "compact interfaces publish Struct layout, pointer methods, constructors, and Struct-valued routine signatures")
Local publicStructHeaderDiagnostics:TCompilerDiagnostic[]
Local publicStructHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(publicStruct, publicStructHeaderDiagnostics)
Check(publicStructHeaderDiagnostics.length = 0 And Contains(publicStructHeader, "struct acme_values_SValue {") And Contains(publicStructHeader, "BBINT _acme_values_svalue_first;") And Contains(publicStructHeader, "void _acme_values_SValue_New__Bint(struct acme_values_SValue *") And Contains(publicStructHeader, "struct acme_values_SValue acme_values_SValue_New__Bint_ObjectNew(") And Contains(publicStructHeader, "void _acme_values_SValue_Move__Bint(struct acme_values_SValue *") And Contains(publicStructHeader, "BBINT _acme_values_SValue_Sum(struct acme_values_SValue *"), "runtime headers expose the complete public Struct C ABI")
Local structConstructorForward:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/forwardvalue.mod/forwardvalue.bmx", "SuperStrict~nModule acme.forwardvalue~nStruct SHolder~nMethod New(value:TLater)~nEnd Method~nEnd Struct~nType TLater~nEnd Type", resolver, TestOptions())
Local structConstructorForwardHeaderDiagnostics:TCompilerDiagnostic[]
Local structConstructorForwardHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(structConstructorForward, structConstructorForwardHeaderDiagnostics)
Check(structConstructorForward.Succeeded() And structConstructorForwardHeaderDiagnostics.length = 0 And AppearsBefore(structConstructorForwardHeader, "struct acme_forwardvalue_TLater_obj;", "acme_forwardvalue_SHolder_New__NTLaterE_ObjectNew(struct acme_forwardvalue_TLater_obj *"), "runtime headers give later Type parameters file-scope C tags before public Struct constructor helpers")
Local structGlobalSource:String = "SuperStrict~nModule acme.palette~nStruct SPalette~nField value:Int~nGlobal Red:SPalette = New SPalette~nEnd Struct"
Local structGlobal:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/palette.mod/palette.bmx", structGlobalSource, resolver, TestOptions())
Local structGlobalInterfaceDiagnostics:TCompilerDiagnostic[]
Local structGlobalInterface:String = TBlitzMaxCompiler.EmitInterface(structGlobal, structGlobalInterfaceDiagnostics)
Check(structGlobal.Succeeded() And structGlobalInterfaceDiagnostics.length = 0 And Contains(structGlobalInterface, "SPalette^Null{") And AppearsBefore(structGlobalInterface, "Red:SPalette&=mem:p(", "}S=~qacme_palette_SPalette~q"), "public Struct Globals retain their declaring Struct ownership inside the compact interface")
resolver.AddInterface("acme.palette", "sdk/acme.palette.i", structGlobalInterface)
Local structGlobalConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("struct-global-consumer.bmx", "SuperStrict~nImport acme.palette~nLocal value:Int = SPalette.Red.value", resolver, TestOptions())
Local structGlobalConsumerDiagnostics:TCompilerDiagnostic[]
Local structGlobalConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(structGlobalConsumer, structGlobalConsumerDiagnostics)
Check(structGlobalConsumer.Succeeded() And structGlobalConsumerDiagnostics.length = 0 And Contains(structGlobalConsumerC, "acme_palette_SPalette_Red._acme_palette_spalette_value"), "a separate consumer resolves an imported Struct Global and its value layout")
resolver.AddInterface("acme.values", "sdk/acme.values.i", publicStructInterface)
Local importedStructStaticArray:TCompilerResult = TBlitzMaxCompiler.Compile("imported-struct-static-array.bmx", "SuperStrict~nImport acme.values~nLocal StaticArray values:SValue[2]", resolver, TestOptions())
Local importedStructStaticArrayDiagnostics:TCompilerDiagnostic[]
Local importedStructStaticArrayC:String = TBlitzMaxCompiler.EmitRuntimeC(importedStructStaticArray, importedStructStaticArrayDiagnostics)
Check(importedStructStaticArray.Succeeded() And importedStructStaticArrayDiagnostics.length = 0 And Contains(importedStructStaticArrayC, "acme_values_SValue_New_ObjectNew()"), "imported Struct StaticArray storage uses the guaranteed implicit value helper even when the snapshot publishes only parameterized constructors")
Local importedStructStaticArrayField:TCompilerResult = TBlitzMaxCompiler.Compile("imported-struct-static-array-field.bmx", "SuperStrict~nImport acme.values~nStruct SValueContainer~nField StaticArray values:SValue[2]~nEnd Struct", resolver, TestOptions())
Local importedStructStaticArrayFieldDiagnostics:TCompilerDiagnostic[]
Local importedStructStaticArrayFieldC:String = TBlitzMaxCompiler.EmitRuntimeC(importedStructStaticArrayField, importedStructStaticArrayFieldDiagnostics)
Check(importedStructStaticArrayField.Succeeded() And importedStructStaticArrayFieldDiagnostics.length = 0 And Contains(importedStructStaticArrayFieldC, "acme_values_SValue_New_ObjectNew()"), "embedded imported Struct arrays use the guaranteed implicit value helper")
Local importedStructTypeStaticArrayField:TCompilerResult = TBlitzMaxCompiler.Compile("imported-struct-type-static-array-field.bmx", "SuperStrict~nImport acme.values~nType TValueOwner~nField StaticArray values:SValue[2]~nEnd Type", resolver, TestOptions())
Local importedStructTypeStaticArrayFieldDiagnostics:TCompilerDiagnostic[]
Local importedStructTypeStaticArrayFieldC:String = TBlitzMaxCompiler.EmitRuntimeC(importedStructTypeStaticArrayField, importedStructTypeStaticArrayFieldDiagnostics)
Check(importedStructTypeStaticArrayField.Succeeded() And importedStructTypeStaticArrayFieldDiagnostics.length = 0 And Contains(importedStructTypeStaticArrayFieldC, "acme_values_SValue_New_ObjectNew()"), "Type fixed fields default-construct imported Struct cells through the guaranteed implicit value helper")
Local publicStructConsumerSource:String = "SuperStrict~nImport acme.values~nLocal value:SValue=New SValue(10)~nvalue.Move(2)~nLocal copied:SValue=value~nAdjust(copied,3)~nLocal total:Int=value.Sum()+copied.first~nLocal made:SValue=MakeValue(4)"
Local publicStructConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("public-struct-consumer.bmx", publicStructConsumerSource, resolver, TestOptions())
Local publicStructConsumerDump:String = TCompilerIrDumper.Dump(publicStructConsumer.ir)
Check(publicStructConsumer.Succeeded() And publicStructConsumer.ir.importedStructs.length = 1 And Contains(publicStructConsumerDump, "imported-struct @ist0 SValue:SValue abi acme_values_SValue from acme.values") And Contains(publicStructConsumerDump, "Move(Int) -> Void abi acme_values_SValue_Move__Bint implementation _acme_values_SValue_Move__Bint") And Contains(publicStructConsumerDump, "struct-new imported @ist0 constructor %") And Contains(publicStructConsumerDump, "call struct-direct") And Contains(publicStructConsumerDump, "field imported-struct @ist0.%"), "a separate consumer reconstructs the producer's linkage and implementation identities for construction, methods, fields, values, and Var calls")
Local publicStructConsumerDiagnostics:TCompilerDiagnostic[]
Local publicStructConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(publicStructConsumer, publicStructConsumerDiagnostics)
Check(publicStructConsumerDiagnostics.length = 0 And Contains(publicStructConsumerC, "#include <acme.mod/values.mod/.bmx/values.bmx.release.test.x64.h>") And Contains(publicStructConsumerC, "struct acme_values_SValue bmx_v0_value") And Contains(publicStructConsumerC, "acme_values_SValue_New__Bint_ObjectNew(10)") And Contains(publicStructConsumerC, "_acme_values_SValue_Move__Bint((&bmx_v0_value), 2)") And Contains(publicStructConsumerC, "acme_values_Adjust__NSValueEV__Bint((&bmx_v1_copied), 3)") And Contains(publicStructConsumerC, "bmx_v1_copied._acme_values_svalue_first") And Contains(publicStructConsumerC, "acme_values_MakeValue__Bint(4)"), "consumer C uses the producer-owned Struct layout, value helper, pointer methods, field ABI, value copies, and Var ABI")
Local implicitPublicStruct:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/plain.mod/plain.bmx", "SuperStrict~nModule acme.plain~nStruct SPlain~nField value:Int=42~nEnd Struct", resolver, TestOptions())
Local implicitPublicStructInterfaceDiagnostics:TCompilerDiagnostic[]
Local implicitPublicStructInterface:String = TBlitzMaxCompiler.EmitInterface(implicitPublicStruct, implicitPublicStructInterfaceDiagnostics)
Local implicitPublicStructHeaderDiagnostics:TCompilerDiagnostic[]
Local implicitPublicStructHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(implicitPublicStruct, implicitPublicStructHeaderDiagnostics)
Local implicitPublicStructRuntimeDiagnostics:TCompilerDiagnostic[]
Local implicitPublicStructRuntime:String = TBlitzMaxCompiler.EmitRuntimeC(implicitPublicStruct, implicitPublicStructRuntimeDiagnostics)
Check(implicitPublicStruct.Succeeded() And implicitPublicStructInterfaceDiagnostics.length = 0 And Contains(implicitPublicStructInterface, "-New()=~qacme_plain_SPlain_New~q") And Contains(implicitPublicStructInterface, "}S=~qacme_plain_SPlain~q"), "a public Struct without an explicit constructor publishes the production-compatible implicit New record")
Check(implicitPublicStructHeaderDiagnostics.length = 0 And implicitPublicStructRuntimeDiagnostics.length = 0 And Contains(implicitPublicStructHeader, "void _acme_plain_SPlain_New(struct acme_plain_SPlain *") And Contains(implicitPublicStructHeader, "struct acme_plain_SPlain acme_plain_SPlain_New_ObjectNew(void);") And Contains(implicitPublicStructRuntime, "void _acme_plain_SPlain_New(struct acme_plain_SPlain *bmx_self)") And Contains(implicitPublicStructRuntime, "_acme_plain_SPlain_New(&bmx_struct_value_st0);"), "public implicit Struct constructor and value-helper symbols are both defined by the owning module")
resolver.AddInterface("acme.plain", "sdk/acme.plain.i", implicitPublicStructInterface)
Local implicitPublicStructConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("implicit-public-struct-consumer.bmx", "SuperStrict~nImport acme.plain~nLocal value:SPlain=New SPlain~nLocal result:Int=value.value", resolver, TestOptions())
Local implicitPublicStructConsumerDiagnostics:TCompilerDiagnostic[]
Local implicitPublicStructConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(implicitPublicStructConsumer, implicitPublicStructConsumerDiagnostics)
Check(implicitPublicStructConsumer.Succeeded() And implicitPublicStructConsumerDiagnostics.length = 0 And Contains(implicitPublicStructConsumerC, "acme_plain_SPlain_New_ObjectNew()") And Contains(implicitPublicStructConsumerC, "bmx_v0_value._acme_plain_splain_value"), "a separate compilation consumes the implicit constructor helper and dependency-owned field layout")
Local publicStructDelegationSource:String = "SuperStrict~nModule acme.chain~nStruct SChained~nField first:Int=1~nField second:Int=2~nMethod New()~nNew(4)~nsecond=second+3~nEnd Method~nMethod New(seed:Int)~nfirst=seed~nEnd Method~nEnd Struct"
Local publicStructDelegation:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/chain.mod/chain.bmx", publicStructDelegationSource, resolver, TestOptions())
Local publicStructDelegationInterfaceDiagnostics:TCompilerDiagnostic[]
Local publicStructDelegationInterface:String = TBlitzMaxCompiler.EmitInterface(publicStructDelegation, publicStructDelegationInterfaceDiagnostics)
Local publicStructDelegationRuntimeDiagnostics:TCompilerDiagnostic[]
Local publicStructDelegationRuntime:String = TBlitzMaxCompiler.EmitRuntimeC(publicStructDelegation, publicStructDelegationRuntimeDiagnostics)
Check(publicStructDelegation.Succeeded() And publicStructDelegationInterfaceDiagnostics.length = 0 And Contains(publicStructDelegationInterface, "-New()=~qacme_chain_SChained_New~q") And Contains(publicStructDelegationInterface, "-New(seed%)=~qacme_chain_SChained_New__Bint~q"), "public compact interfaces retain every constructor participating in a Struct delegation chain")
Check(publicStructDelegationRuntimeDiagnostics.length = 0 And Contains(publicStructDelegationRuntime, "_acme_chain_SChained_New__Bint((struct acme_chain_SChained *)bmx_self_self, 4);") And AppearsBefore(publicStructDelegationRuntime, "_acme_chain_schained_first = 1;", "_acme_chain_schained_second = 2;") And AppearsBefore(publicStructDelegationRuntime, "_acme_chain_schained_second = 2;", "_acme_chain_SChained_New(&bmx_struct_value_st0);"), "the module-owned value helper initializes once before its public constructor chain")
resolver.AddInterface("acme.chain", "sdk/acme.chain.i", publicStructDelegationInterface)
Local publicStructDelegationConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("public-struct-delegation-consumer.bmx", "SuperStrict~nImport acme.chain~nLocal value:SChained=New SChained~nLocal result:Int=value.first+value.second", resolver, TestOptions())
Local publicStructDelegationConsumerDiagnostics:TCompilerDiagnostic[]
Local publicStructDelegationConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(publicStructDelegationConsumer, publicStructDelegationConsumerDiagnostics)
Check(publicStructDelegationConsumer.Succeeded() And publicStructDelegationConsumerDiagnostics.length = 0 And Contains(publicStructDelegationConsumerC, "acme_chain_SChained_New_ObjectNew()"), "consumers remain insulated from the producer-owned Struct constructor chain")
Local nestedPublicStructSource:String = "SuperStrict~nModule acme.geometry~nStruct SBox~nField lower:SPoint~nField upper:SPoint~nEnd Struct~nStruct SPoint~nField x:Int=1~nField y:Int=2~nMethod Move(delta:Int)~nx=x+delta~ny=y+delta~nEnd Method~nEnd Struct~nFunction AdjustPoint(point:SPoint Var,delta:Int)~npoint.x=point.x+delta~nEnd Function"
Local nestedPublicStruct:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/geometry.mod/geometry.bmx", nestedPublicStructSource, resolver, TestOptions())
Local nestedPublicStructInterfaceDiagnostics:TCompilerDiagnostic[]
Local nestedPublicStructInterface:String = TBlitzMaxCompiler.EmitInterface(nestedPublicStruct, nestedPublicStructInterfaceDiagnostics)
Local nestedPublicStructHeaderDiagnostics:TCompilerDiagnostic[]
Local nestedPublicStructHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(nestedPublicStruct, nestedPublicStructHeaderDiagnostics)
Local nestedPublicStructRuntimeDiagnostics:TCompilerDiagnostic[]
Local nestedPublicStructRuntime:String = TBlitzMaxCompiler.EmitRuntimeC(nestedPublicStruct, nestedPublicStructRuntimeDiagnostics)
Check(nestedPublicStruct.Succeeded() And nestedPublicStructInterfaceDiagnostics.length = 0 And AppearsBefore(nestedPublicStructInterface, "SPoint^Null{", "SBox^Null{") And Contains(nestedPublicStructInterface, ".lower:SPoint&") And Contains(nestedPublicStructInterface, "}S=~qacme_geometry_SBox~q"), "compact interfaces publish nested Struct dependencies before their containing layout")
Check(nestedPublicStructHeaderDiagnostics.length = 0 And AppearsBefore(nestedPublicStructHeader, "struct acme_geometry_SPoint {", "struct acme_geometry_SBox {") And Contains(nestedPublicStructHeader, "struct acme_geometry_SPoint _acme_geometry_sbox_lower;"), "runtime headers define nested public Struct layouts in strict C dependency order")
Check(nestedPublicStructRuntimeDiagnostics.length = 0 And Contains(nestedPublicStructRuntime, "_acme_geometry_sbox_lower = acme_geometry_SPoint_New_ObjectNew();") And Contains(nestedPublicStructRuntime, "_acme_geometry_sbox_upper = acme_geometry_SPoint_New_ObjectNew();"), "the producer-owned outer constructor recursively applies nested Struct field defaults")
resolver.AddInterface("acme.geometry", "sdk/acme.geometry.i", nestedPublicStructInterface)
Local nestedPublicStructConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("nested-public-struct-consumer.bmx", "SuperStrict~nImport acme.geometry~nLocal box:SBox=New SBox~nbox.lower.x=20~nbox.lower.y=22~nbox.upper=box.lower~nbox.lower.Move(1)~nAdjustPoint(box.upper,2)~nLocal result:Int=box.upper.x+box.upper.y", resolver, TestOptions())
Local nestedPublicStructConsumerDump:String = TCompilerIrDumper.Dump(nestedPublicStructConsumer.ir)
Local nestedPublicStructConsumerDiagnostics:TCompilerDiagnostic[]
Local nestedPublicStructConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(nestedPublicStructConsumer, nestedPublicStructConsumerDiagnostics)
Check(nestedPublicStructConsumer.Succeeded() And Contains(nestedPublicStructConsumerDump, "lower:SPoint abi _acme_geometry_sbox_lower [imported-struct @") And nestedPublicStructConsumer.ir.importedStructs.length = 2, "consumer IR retains both imported nested layouts and the field dependency edge")
Check(nestedPublicStructConsumerDiagnostics.length = 0 And Contains(nestedPublicStructConsumerC, "acme_geometry_SBox_New_ObjectNew()") And Contains(nestedPublicStructConsumerC, "._acme_geometry_sbox_lower)._acme_geometry_spoint_x") And Contains(nestedPublicStructConsumerC, "_acme_geometry_SPoint_Move__Bint((&(") And Contains(nestedPublicStructConsumerC, "acme_geometry_AdjustPoint__NSPointEV__Bint((&("), "consumer C uses the dependency-owned nested layout and preserves imported nested method and Var lvalues")

Local fixedFieldPublicStructSource:String = "SuperStrict~nModule acme.fixedfields~nStruct SFixedFieldGrid~nField StaticArray cells:SFixedFieldCell[2]~nField StaticArray counts:Int[3]~nEnd Struct~nStruct SFixedFieldCell~nField number:Int=7~nField text:String~nEnd Struct"
Local fixedFieldPublicStruct:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/fixedfields.mod/fixedfields.bmx", fixedFieldPublicStructSource, resolver, TestOptions())
Local fixedFieldPublicStructInterfaceDiagnostics:TCompilerDiagnostic[]
Local fixedFieldPublicStructInterface:String = TBlitzMaxCompiler.EmitInterface(fixedFieldPublicStruct, fixedFieldPublicStructInterfaceDiagnostics)
Local fixedFieldPublicStructHeaderDiagnostics:TCompilerDiagnostic[]
Local fixedFieldPublicStructHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(fixedFieldPublicStruct, fixedFieldPublicStructHeaderDiagnostics)
Local fixedFieldPublicStructRuntimeDiagnostics:TCompilerDiagnostic[]
Local fixedFieldPublicStructRuntime:String = TBlitzMaxCompiler.EmitRuntimeC(fixedFieldPublicStruct, fixedFieldPublicStructRuntimeDiagnostics)
Check(fixedFieldPublicStruct.Succeeded() And fixedFieldPublicStructInterfaceDiagnostics.length = 0 And AppearsBefore(fixedFieldPublicStructInterface, "SFixedFieldCell^Null{", "SFixedFieldGrid^Null{") And Contains(fixedFieldPublicStructInterface, "~~cells:SFixedFieldCell&[2]&") And Contains(fixedFieldPublicStructInterface, "~~counts%&[3]&"), "compact interfaces publish embedded StaticArray element layouts, element types, and fixed extents")
Check(fixedFieldPublicStructHeaderDiagnostics.length = 0 And AppearsBefore(fixedFieldPublicStructHeader, "struct acme_fixedfields_SFixedFieldCell {", "struct acme_fixedfields_SFixedFieldGrid {") And Contains(fixedFieldPublicStructHeader, "struct acme_fixedfields_SFixedFieldCell _acme_fixedfields_sfixedfieldgrid_cells[2];") And Contains(fixedFieldPublicStructHeader, "BBINT _acme_fixedfields_sfixedfieldgrid_counts[3];"), "public runtime headers expose production-shaped fixed C members in dependency order")
Check(fixedFieldPublicStructRuntimeDiagnostics.length = 0 And Contains(fixedFieldPublicStructRuntime, "for (BBUINT bmx_static_field_init_sf0") And Contains(fixedFieldPublicStructRuntime, "= acme_fixedfields_SFixedFieldCell_New_ObjectNew();") And Contains(fixedFieldPublicStructRuntime, "_acme_fixedfields_sfixedfieldcell_text = &bbEmptyString;"), "the producer recursively default-constructs every managed Struct cell in a public embedded StaticArray")
resolver.AddInterface("acme.fixedfields", "sdk/acme.fixedfields.i", fixedFieldPublicStructInterface)
Local fixedFieldPublicStructConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("fixed-field-public-struct-consumer.bmx", "SuperStrict~nImport acme.fixedfields~nLocal grid:SFixedFieldGrid=New SFixedFieldGrid~ngrid.cells[0].number=20~ngrid.counts[1]=grid.cells[0].number~nLocal total:Int~nFor Local item:SFixedFieldCell=EachIn grid.cells~ntotal=total+item.number~nNext", resolver, TestOptions())
Local fixedFieldPublicStructConsumerDump:String = TCompilerIrDumper.Dump(fixedFieldPublicStructConsumer.ir)
Local fixedFieldPublicStructConsumerDiagnostics:TCompilerDiagnostic[]
Local fixedFieldPublicStructConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(fixedFieldPublicStructConsumer, fixedFieldPublicStructConsumerDiagnostics)
Check(fixedFieldPublicStructConsumer.Succeeded() And fixedFieldPublicStructConsumer.ir.importedStructs.length = 2 And fixedFieldPublicStructConsumer.ir.importedStructs[1].containsManagedReferences And Contains(fixedFieldPublicStructConsumerDump, "cells:StaticArray SFixedFieldCell[2]") And Contains(fixedFieldPublicStructConsumerDump, "[static-array SFixedFieldCell x 2] [element-layout imported-struct @") And Contains(fixedFieldPublicStructConsumerDump, "for-each-static-array SFixedFieldCell x 2"), "dependency ingestion reconstructs fixed field extent, imported element identity, managed containment, and iteration shape without source")
Check(fixedFieldPublicStructConsumerDiagnostics.length = 0 And Contains(fixedFieldPublicStructConsumerC, "acme_fixedfields_SFixedFieldGrid_New_ObjectNew()") And Contains(fixedFieldPublicStructConsumerC, "._acme_fixedfields_sfixedfieldgrid_cells)[0]") And Contains(fixedFieldPublicStructConsumerC, "struct acme_fixedfields_SFixedFieldCell *bmx_tmp_"), "consumer C uses the producer-owned embedded layout for indexing and evaluate-once EachIn")

Local fixedObjectPublicSource:String = "SuperStrict~nModule acme.fixedobjects~nStruct SFixedObjectCell~nField number:Int=11~nField text:String~nEnd Struct~nType TFixedObjectBase~nField StaticArray cells:SFixedObjectCell[2]~nField StaticArray counts:Int[3]~nEnd Type~nType TFixedObjectChild Extends TFixedObjectBase~nField marker:Int=7~nEnd Type~nFunction CreateFixedObjectChild:TFixedObjectChild()~nReturn New TFixedObjectChild~nEnd Function"
Local fixedObjectPublic:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/fixedobjects.mod/fixedobjects.bmx", fixedObjectPublicSource, resolver, TestOptions())
Local fixedObjectPublicInterfaceDiagnostics:TCompilerDiagnostic[]
Local fixedObjectPublicInterface:String = TBlitzMaxCompiler.EmitInterface(fixedObjectPublic, fixedObjectPublicInterfaceDiagnostics)
Local fixedObjectPublicHeaderDiagnostics:TCompilerDiagnostic[]
Local fixedObjectPublicHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(fixedObjectPublic, fixedObjectPublicHeaderDiagnostics)
Local fixedObjectPublicRuntimeDiagnostics:TCompilerDiagnostic[]
Local fixedObjectPublicRuntime:String = TBlitzMaxCompiler.EmitRuntimeC(fixedObjectPublic, fixedObjectPublicRuntimeDiagnostics)
Check(fixedObjectPublic.Succeeded() And fixedObjectPublicInterfaceDiagnostics.length = 0 And Contains(fixedObjectPublicInterface, "TFixedObjectBase^Object{") And Contains(fixedObjectPublicInterface, "~~cells:SFixedObjectCell&[2]&") And Contains(fixedObjectPublicInterface, "~~counts%&[3]&") And Contains(fixedObjectPublicInterface, "TFixedObjectChild^TFixedObjectBase{"), "public Type interfaces preserve fixed field element types and extents across inheritance")
Check(fixedObjectPublicHeaderDiagnostics.length = 0 And Contains(fixedObjectPublicHeader, "struct acme_fixedobjects_TFixedObjectBase_obj") And Contains(fixedObjectPublicHeader, "struct acme_fixedobjects_SFixedObjectCell _acme_fixedobjects_tfixedobjectbase_cells[2];") And Contains(fixedObjectPublicHeader, "BBINT _acme_fixedobjects_tfixedobjectbase_counts[3];") And Contains(fixedObjectPublicHeader, "struct acme_fixedobjects_TFixedObjectChild_obj"), "public runtime headers expose fixed object members with the producer-owned Struct layout")
Check(fixedObjectPublicRuntimeDiagnostics.length = 0 And Contains(fixedObjectPublicRuntime, "for (BBUINT bmx_static_field_init_f0") And Contains(fixedObjectPublicRuntime, "= acme_fixedobjects_SFixedObjectCell_New_ObjectNew();") And Contains(fixedObjectPublicRuntime, "for (BBUINT bmx_static_field_init_f1") And Contains(fixedObjectPublicRuntime, "_acme_fixedobjects_sfixedobjectcell_text = &bbEmptyString;") And Contains(fixedObjectPublicRuntime, "(BBClass *)&acme_fixedobjects_TFixedObjectBase") And Contains(fixedObjectPublicRuntime, "->_acme_fixedobjects_tfixedobjectchild_marker = 7;") And Contains(fixedObjectPublicRuntime, "bbObjectNew((BBClass *)&acme_fixedobjects_TFixedObjectChild)"), "the public base constructor initializes fixed members once and the derived descriptor, constructor, and producer allocation retain their inherited runtime relationship")
resolver.AddInterface("acme.fixedobjects", "sdk/acme.fixedobjects.i", fixedObjectPublicInterface)
Local fixedObjectPublicConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("fixed-object-public-consumer.bmx", "SuperStrict~nImport acme.fixedobjects~nLocal value:TFixedObjectChild=CreateFixedObjectChild()~nvalue.cells[0].number=20~nvalue.counts[1]=value.cells.length+value.counts.length+value.marker~nLocal total:Int~nFor Local item:SFixedObjectCell=EachIn value.cells~ntotal=total+item.number~nNext", resolver, TestOptions())
Local fixedObjectPublicConsumerDump:String = TCompilerIrDumper.Dump(fixedObjectPublicConsumer.ir)
Local fixedObjectPublicConsumerDiagnostics:TCompilerDiagnostic[]
Local fixedObjectPublicConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(fixedObjectPublicConsumer, fixedObjectPublicConsumerDiagnostics)
Check(fixedObjectPublicConsumer.Succeeded() And fixedObjectPublicConsumer.ir.importedClasses.length = 2 And fixedObjectPublicConsumer.ir.importedStructs.length = 1 And fixedObjectPublicConsumer.ir.importedClasses[0].hasManagedFields And fixedObjectPublicConsumer.ir.importedClasses[1].hasManagedFields And Contains(fixedObjectPublicConsumerDump, "cells:StaticArray SFixedObjectCell[2]") And Contains(fixedObjectPublicConsumerDump, "[static-array SFixedObjectCell x 2] [element-layout imported-struct @") And Contains(fixedObjectPublicConsumerDump, "for-each-static-array SFixedObjectCell x 2"), "imported Type ingestion retains inherited fixed members, element identity, managed allocation classification, and iteration shape")
Check(fixedObjectPublicConsumerDiagnostics.length = 0 And Contains(fixedObjectPublicConsumerC, "acme_fixedobjects_CreateFixedObjectChild()") And Contains(fixedObjectPublicConsumerC, "->_acme_fixedobjects_tfixedobjectbase_cells)[0]") And Contains(fixedObjectPublicConsumerC, "struct acme_fixedobjects_SFixedObjectCell *bmx_tmp_"), "consumer C indexes and iterates the dependency-owned inherited fixed object layout returned by its producer")

Local fixedParameterPublicSource:String = "SuperStrict~nModule acme.fixedparams~nStruct SFixedParameterCell~nField value:Int~nMethod Add(delta:Int)~nvalue=value+delta~nEnd Method~nEnd Struct~nFunction SumFixed:Int(StaticArray values:Int[4])~nReturn values.length~nEnd Function~nFunction TouchFixed(StaticArray cells:SFixedParameterCell[2])~ncells[0].Add(1)~nEnd Function~nType TFixedParameterBase~nMethod Size:Int(StaticArray values:Int[4])~nReturn values.length~nEnd Method~nEnd Type~nType TFixedParameterDerived Extends TFixedParameterBase~nMethod Size:Int(StaticArray values:Int[4]) Override~nReturn values.length+1~nEnd Method~nEnd Type~nFunction CreateFixedParameterBase:TFixedParameterBase()~nReturn New TFixedParameterDerived~nEnd Function"
Local fixedParameterPublic:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/fixedparams.mod/fixedparams.bmx", fixedParameterPublicSource, resolver, TestOptions())
Local fixedParameterPublicInterfaceDiagnostics:TCompilerDiagnostic[]
Local fixedParameterPublicInterface:String = TBlitzMaxCompiler.EmitInterface(fixedParameterPublic, fixedParameterPublicInterfaceDiagnostics)
Local fixedParameterPublicHeaderDiagnostics:TCompilerDiagnostic[]
Local fixedParameterPublicHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(fixedParameterPublic, fixedParameterPublicHeaderDiagnostics)
Local fixedParameterPublicRuntimeDiagnostics:TCompilerDiagnostic[]
Local fixedParameterPublicRuntime:String = TBlitzMaxCompiler.EmitRuntimeC(fixedParameterPublic, fixedParameterPublicRuntimeDiagnostics)
Check(fixedParameterPublic.Succeeded() And fixedParameterPublicInterfaceDiagnostics.length = 0 And Contains(fixedParameterPublicInterface, "SumFixed%(values%&[4])=") And Contains(fixedParameterPublicInterface, "TouchFixed(cells:SFixedParameterCell&[2])=") And Contains(fixedParameterPublicInterface, "-Size%(values%&[4])="), "compact interfaces publish StaticArray routine parameter element types and fixed extents")
Check(fixedParameterPublicHeaderDiagnostics.length = 0 And Contains(fixedParameterPublicHeader, "SumFixed__S4_Bint(BBINT bmx_p0_values[4])") And Contains(fixedParameterPublicHeader, "TouchFixed__S2_NSFixedParameterCellE(struct acme_fixedparams_SFixedParameterCell bmx_p0_cells[2])") And Contains(fixedParameterPublicHeader, "BBINT (*m_") And Contains(fixedParameterPublicHeader, "BBINT *"), "runtime headers use production-shaped array declarations and pointer-compatible class slots")
Check(fixedParameterPublicRuntimeDiagnostics.length = 0 And Contains(fixedParameterPublicRuntime, "SumFixed__S4_Bint(BBINT bmx_p0_values[4])") And Contains(fixedParameterPublicRuntime, "TouchFixed__S2_NSFixedParameterCellE(struct acme_fixedparams_SFixedParameterCell bmx_p0_cells[2])"), "module implementations retain fixed parameter declarations without copying storage")
resolver.AddInterface("acme.fixedparams", "sdk/acme.fixedparams.i", fixedParameterPublicInterface)
Local fixedParameterPublicConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("fixed-parameter-public-consumer.bmx", "SuperStrict~nImport acme.fixedparams~nLocal StaticArray values:Int[4]~nLocal StaticArray cells:SFixedParameterCell[2]~nTouchFixed(cells)~nLocal owner:TFixedParameterBase=CreateFixedParameterBase()~nLocal total:Int=SumFixed(values)+owner.Size(values)", resolver, TestOptions())
Local fixedParameterPublicConsumerDump:String = TCompilerIrDumper.Dump(fixedParameterPublicConsumer.ir)
Local fixedParameterPublicConsumerDiagnostics:TCompilerDiagnostic[]
Local fixedParameterPublicConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(fixedParameterPublicConsumer, fixedParameterPublicConsumerDiagnostics)
Check(fixedParameterPublicConsumer.Succeeded() And Contains(fixedParameterPublicConsumerDump, "external @") And Contains(fixedParameterPublicConsumerDump, "values:StaticArray Int[4]") And Contains(fixedParameterPublicConsumerDump, "cells:StaticArray SFixedParameterCell[2]") And Contains(fixedParameterPublicConsumerDump, "method %icm0 Size(StaticArray Int[4])"), "interface ingestion reconstructs imported free-function and virtual-method StaticArray parameter shapes")
Check(fixedParameterPublicConsumerDiagnostics.length = 0 And Contains(fixedParameterPublicConsumerC, "acme_fixedparams_TouchFixed__S2_NSFixedParameterCellE(bmx_v") And Contains(fixedParameterPublicConsumerC, "acme_fixedparams_SumFixed__S4_Bint(bmx_v") And Contains(fixedParameterPublicConsumerC, "->m_") And Contains(fixedParameterPublicConsumerC, "bmx_v0_values"), "consumer C decays fixed local storage directly into imported functions and inherited virtual dispatch")

Local fixedCallablePublicSource:String = "SuperStrict~nModule acme.fixedcallbacks~nFunction SumFixed:Int(StaticArray values:Int[4])~nReturn values[0]+values.length~nEnd Function~nFunction ApplyFixed:Int(callback:Int(StaticArray values:Int[4]),StaticArray values:Int[4])~nReturn callback(values)~nEnd Function"
Local fixedCallablePublic:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/fixedcallbacks.mod/fixedcallbacks.bmx", fixedCallablePublicSource, resolver, TestOptions())
Local fixedCallablePublicInterfaceDiagnostics:TCompilerDiagnostic[]
Local fixedCallablePublicInterface:String = TBlitzMaxCompiler.EmitInterface(fixedCallablePublic, fixedCallablePublicInterfaceDiagnostics)
Local fixedCallablePublicHeaderDiagnostics:TCompilerDiagnostic[]
Local fixedCallablePublicHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(fixedCallablePublic, fixedCallablePublicHeaderDiagnostics)
Check(fixedCallablePublic.Succeeded() And fixedCallablePublicInterfaceDiagnostics.length = 0 And Contains(fixedCallablePublicInterface, "ApplyFixed%(callback%(values%&[4]),values%&[4])="), "compact interfaces publish StaticArray extents nested inside callable parameters")
Check(fixedCallablePublicHeaderDiagnostics.length = 0 And Contains(fixedCallablePublicHeader, "BBINT (*bmx_p0_callback)(BBINT *)") And Contains(fixedCallablePublicHeader, "BBINT bmx_p1_values[4]"), "module headers preserve the nested callable and direct fixed-array ABI shapes")
resolver.AddInterface("acme.fixedcallbacks", "sdk/acme.fixedcallbacks.i", fixedCallablePublicInterface)
Local fixedCallablePublicConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("fixed-callable-public-consumer.bmx", "SuperStrict~nImport acme.fixedcallbacks~nLocal callback:Int(StaticArray values:Int[4])=SumFixed~nLocal StaticArray values:Int[4]~nvalues[0]=38~nLocal total:Int=ApplyFixed(callback,values)", resolver, TestOptions())
Local fixedCallablePublicConsumerDump:String = TCompilerIrDumper.Dump(fixedCallablePublicConsumer.ir)
Local fixedCallablePublicConsumerDiagnostics:TCompilerDiagnostic[]
Local fixedCallablePublicConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(fixedCallablePublicConsumer, fixedCallablePublicConsumerDiagnostics)
Check(fixedCallablePublicConsumer.Succeeded() And Contains(fixedCallablePublicConsumerDump, "callback:Int(StaticArray Int[4]) [callable Int(StaticArray Int[4])]") And Contains(fixedCallablePublicConsumerDump, "ApplyFixed"), "snapshot ingestion reconstructs nested callable StaticArray extents for downstream type checking")
Check(fixedCallablePublicConsumerDiagnostics.length = 0 And Contains(fixedCallablePublicConsumerC, "acme_fixedcallbacks_ApplyFixed") And Contains(fixedCallablePublicConsumerC, "BBINT (*bmx_v0_callback)(BBINT *)"), "consumer C passes the exact function-pointer shape to the dependency-owned routine")

Local callableVarPublicSource:String = "SuperStrict~nModule acme.varcallbacks~nFunction Increment:Int(value:Int Var)~nvalue=value+1~nReturn value~nEnd Function~nGlobal Active:Int(value:Int Var)=Increment~nType TVarCallbackHolder~nField callback:Int(value:Int Var)=Increment~nMethod Apply:Int(operation:Int(value:Int Var),value:Int Var)~nReturn operation(value)~nEnd Method~nEnd Type~nInterface IVarCallback~nMethod Apply:Int(operation:Int(value:Int Var),value:Int Var)~nEnd Interface~nType TVarCallbackImplementation Implements IVarCallback~nMethod Apply:Int(operation:Int(value:Int Var),value:Int Var)~nReturn operation(value)~nEnd Method~nEnd Type~nFunction CreateVarCallbackHolder:TVarCallbackHolder()~nReturn New TVarCallbackHolder~nEnd Function~nFunction CreateVarCallbackImplementation:TVarCallbackImplementation()~nReturn New TVarCallbackImplementation~nEnd Function"
Local callableVarPublic:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/varcallbacks.mod/varcallbacks.bmx", callableVarPublicSource, resolver, TestOptions())
Local callableVarPublicInterfaceDiagnostics:TCompilerDiagnostic[]
Local callableVarPublicInterface:String = TBlitzMaxCompiler.EmitInterface(callableVarPublic, callableVarPublicInterfaceDiagnostics)
Local callableVarPublicHeaderDiagnostics:TCompilerDiagnostic[]
Local callableVarPublicHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(callableVarPublic, callableVarPublicHeaderDiagnostics)
Check(callableVarPublic.Succeeded() And callableVarPublicInterfaceDiagnostics.length = 0 And Contains(callableVarPublicInterface, "Increment%(value% Var)=") And Contains(callableVarPublicInterface, "Active%(value% Var)&=mem:p(") And Contains(callableVarPublicInterface, ".callback%(value% Var)&") And Contains(callableVarPublicInterface, "-Apply%(operation%(value% Var),value% Var)=") And Contains(callableVarPublicInterface, "-Apply%(operation%(value% Var),value% Var)A="), "compact snapshots publish direct and nested Var modes for callable routines, Globals, fields, virtual methods, and Interface slots")
Check(callableVarPublicHeaderDiagnostics.length = 0 And Contains(callableVarPublicHeader, "acme_varcallbacks_Increment__BintV(BBINT * bmx_p0_value)") And Contains(callableVarPublicHeader, "extern BBINT (*acme_varcallbacks_Active)(BBINT *);") And Contains(callableVarPublicHeader, "BBINT (*_acme_varcallbacks_tvarcallbackholder_callback)(BBINT *);") And Contains(callableVarPublicHeader, "BBINT (*)(BBINT *)") And Contains(callableVarPublicHeader, "BBINT *"), "producer headers express callable and direct Var parameters as matching pointer ABI types")
resolver.AddInterface("acme.varcallbacks", "sdk/acme.varcallbacks.i", callableVarPublicInterface)
Local callableVarPublicConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("callable-var-public-consumer.bmx", "SuperStrict~nImport acme.varcallbacks~nLocal value:Int=38~nLocal holder:TVarCallbackHolder=CreateVarCallbackHolder()~nLocal iface:IVarCallback=CreateVarCallbackImplementation()~nLocal first:Int=Active(value)~nLocal second:Int=holder.callback(value)~nLocal third:Int=holder.Apply(Increment,value)~nLocal fourth:Int=iface.Apply(Increment,value)", resolver, TestOptions())
Local callableVarPublicConsumerDump:String = TCompilerIrDumper.Dump(callableVarPublicConsumer.ir)
Local callableVarPublicConsumerDiagnostics:TCompilerDiagnostic[]
Local callableVarPublicConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(callableVarPublicConsumer, callableVarPublicConsumerDiagnostics)
Check(callableVarPublicConsumer.Succeeded() And Contains(callableVarPublicConsumerDump, "external-global %extg0 Active:Int(Int Var)") And Contains(callableVarPublicConsumerDump, "[callable Int(Int Var)]") And Contains(callableVarPublicConsumerDump, "field %icf0 callback:Int(Int Var)") And Contains(callableVarPublicConsumerDump, "Apply(Int(Int Var), Int Var)") And Contains(callableVarPublicConsumerDump, "address-of : Int") And Contains(callableVarPublicConsumerDump, "call interface @if0.%im0"), "consumer snapshot ingestion retains Var through callable storage, imported virtual dispatch, and Interface dispatch")
Check(callableVarPublicConsumerDiagnostics.length = 0 And Not Contains(callableVarPublicConsumerC, "extern BBINT (*acme_varcallbacks_Active)(BBINT *);") And Contains(callableVarPublicConsumerC, "acme_varcallbacks_Active") And Contains(callableVarPublicConsumerC, "_acme_varcallbacks_tvarcallbackholder_callback"), "consumer C uses dependency-header-owned callable Global and field storage")

Local returnedCallablePublicSource:String = "SuperStrict~nModule acme.returnedcallbacks~nFunction Increment:Int(value:Int Var)~nvalue=value+1~nReturn value~nEnd Function~nFunction Choose:Int(value:Int Var)(enabled:Int)~nIf enabled Then Return Increment~nReturn Null~nEnd Function"
Local returnedCallablePublic:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/returnedcallbacks.mod/returnedcallbacks.bmx", returnedCallablePublicSource, resolver, TestOptions())
Local returnedCallablePublicInterfaceDiagnostics:TCompilerDiagnostic[]
Local returnedCallablePublicInterface:String = TBlitzMaxCompiler.EmitInterface(returnedCallablePublic, returnedCallablePublicInterfaceDiagnostics)
Local returnedCallablePublicHeaderDiagnostics:TCompilerDiagnostic[]
Local returnedCallablePublicHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(returnedCallablePublic, returnedCallablePublicHeaderDiagnostics)
Check(returnedCallablePublic.Succeeded() And returnedCallablePublicInterfaceDiagnostics.length = 0 And Contains(returnedCallablePublicInterface, "Choose%(value% Var)(enabled%)=~qacme_returnedcallbacks_Choose__Bint~q"), "compact snapshots publish callable routine return signatures separately from invocation parameters")
Check(returnedCallablePublicHeaderDiagnostics.length = 0 And Contains(returnedCallablePublicHeader, "BBINT (*acme_returnedcallbacks_Choose__Bint(BBINT bmx_p0_enabled))(BBINT *);"), "producer headers publish the nested C function-pointer return declaration")
resolver.AddInterface("acme.returnedcallbacks", "sdk/acme.returnedcallbacks.i", returnedCallablePublicInterface)
Local returnedCallablePublicConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("returned-callable-public-consumer.bmx", "SuperStrict~nImport acme.returnedcallbacks~nLocal callback:Int(value:Int Var)=Choose(True)~nLocal value:Int=40~nLocal first:Int=callback(value)~nLocal second:Int=Choose(True)(value)", resolver, TestOptions())
Local returnedCallablePublicConsumerDump:String = TCompilerIrDumper.Dump(returnedCallablePublicConsumer.ir)
Local returnedCallablePublicConsumerDiagnostics:TCompilerDiagnostic[]
Local returnedCallablePublicConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(returnedCallablePublicConsumer, returnedCallablePublicConsumerDiagnostics)
Check(returnedCallablePublicConsumer.Succeeded() And Contains(returnedCallablePublicConsumerDump, "external @ext0 Choose abi acme_returnedcallbacks_Choose__Bint(enabled:Int) -> Int(Int Var)") And Contains(returnedCallablePublicConsumerDump, "materialize %t0:Int(Int Var)") And Contains(returnedCallablePublicConsumerDump, "call external @ext0 Choose : Int(Int Var)"), "consumer snapshot ingestion reconstructs callable returns for assignment and sequenced immediate invocation")
Check(returnedCallablePublicConsumerDiagnostics.length = 0 And Not Contains(returnedCallablePublicConsumerC, "extern BBINT (*acme_returnedcallbacks_Choose__Bint(BBINT bmx_ep0_enabled))(BBINT *);") And Contains(returnedCallablePublicConsumerC, "BBINT (*bmx_v0_callback)(BBINT *) = acme_returnedcallbacks_Choose__Bint(1)") And Contains(returnedCallablePublicConsumerC, "((bmx_tmp_t0 = acme_returnedcallbacks_Choose__Bint(1)), ((bmx_tmp_t0)((&bmx_v"), "consumer C uses and sequences the dependency-header callable-return ABI without local wrappers")

Local returnedMethodCallablePublicSource:String = "SuperStrict~nModule acme.returnedmethodcallbacks~nFunction Increment:Int(value:Int Var)~nvalue=value+1~nReturn value~nEnd Function~nType TReturnedBase~nMethod Choose:Int(value:Int Var)(enabled:Int)~nIf enabled Then Return Increment~nReturn Null~nEnd Method~nEnd Type~nType TReturnedDerived Extends TReturnedBase~nMethod Choose:Int(value:Int Var)(enabled:Int) Override~nReturn Super.Choose(enabled)~nEnd Method~nEnd Type~nInterface IReturnedChooser~nMethod Choose:Int(value:Int Var)(enabled:Int)~nEnd Interface~nType TReturnedImplementation Implements IReturnedChooser~nMethod Choose:Int(value:Int Var)(enabled:Int)~nIf enabled Then Return Increment~nReturn Null~nEnd Method~nEnd Type~nType TReturnedFunctions~nFunction Choose:Int(value:Int Var)(enabled:Int)~nIf enabled Then Return Increment~nReturn Null~nEnd Function~nEnd Type~nFunction CreateReturned:TReturnedBase()~nReturn New TReturnedDerived~nEnd Function~nFunction CreateReturnedImplementation:TReturnedImplementation()~nReturn New TReturnedImplementation~nEnd Function"
Local returnedMethodCallablePublic:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/returnedmethodcallbacks.mod/returnedmethodcallbacks.bmx", returnedMethodCallablePublicSource, resolver, TestOptions())
Local returnedMethodCallablePublicInterfaceDiagnostics:TCompilerDiagnostic[]
Local returnedMethodCallablePublicInterface:String = TBlitzMaxCompiler.EmitInterface(returnedMethodCallablePublic, returnedMethodCallablePublicInterfaceDiagnostics)
Local returnedMethodCallablePublicHeaderDiagnostics:TCompilerDiagnostic[]
Local returnedMethodCallablePublicHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(returnedMethodCallablePublic, returnedMethodCallablePublicHeaderDiagnostics)
Check(returnedMethodCallablePublic.Succeeded() And returnedMethodCallablePublicInterfaceDiagnostics.length = 0 And Contains(returnedMethodCallablePublicInterface, "-Choose%(value% Var)(enabled%)=~qacme_returnedmethodcallbacks_TReturnedBase_Choose__Bint~q") And Contains(returnedMethodCallablePublicInterface, "-Choose%(value% Var)(enabled%)A=~qacme_returnedmethodcallbacks_IReturnedChooser_Choose__Bint~q") And Contains(returnedMethodCallablePublicInterface, "+Choose%(value% Var)(enabled%)=~qacme_returnedmethodcallbacks_TReturnedFunctions_Choose__Bint~q"), "compact snapshots publish callable results on virtual methods, Interface requirements, and Type functions")
Check(returnedMethodCallablePublicHeaderDiagnostics.length = 0 And Contains(returnedMethodCallablePublicHeader, "BBINT (*(*m_Choose__Bint)(struct acme_returnedmethodcallbacks_TReturnedBase_obj *, BBINT))(BBINT *);") And Contains(returnedMethodCallablePublicHeader, "BBINT (*(*m_Choose__Bint)(struct acme_returnedmethodcallbacks_IReturnedChooser_obj *, BBINT))(BBINT *);") And Contains(returnedMethodCallablePublicHeader, "BBINT (*(*f_Choose__Bint)(BBINT))(BBINT *);") And Contains(returnedMethodCallablePublicHeader, "BBINT (*acme_returnedmethodcallbacks_TReturnedFunctions_Choose__Bint(BBINT bmx_p0_enabled))(BBINT *);"), "producer headers retain receiver and invocation parameters in callable-return member slots")
resolver.AddInterface("acme.returnedmethodcallbacks", "sdk/acme.returnedmethodcallbacks.i", returnedMethodCallablePublicInterface)
Local returnedMethodCallablePublicConsumerSource:String = "SuperStrict~nImport acme.returnedmethodcallbacks~nLocal owner:TReturnedBase=CreateReturned()~nLocal iface:IReturnedChooser=CreateReturnedImplementation()~nLocal callback:Int(value:Int Var)=owner.Choose(True)~nLocal value:Int=40~ncallback(value)~niface.Choose(True)(value)~nLocal typeCallback:Int(value:Int Var)=TReturnedFunctions.Choose(True)~nLocal typeValue:Int=40~ntypeCallback(typeValue)~nTReturnedFunctions.Choose(True)(typeValue)"
Local returnedMethodCallablePublicConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("returned-method-callable-public-consumer.bmx", returnedMethodCallablePublicConsumerSource, resolver, TestOptions())
Local returnedMethodCallablePublicConsumerDump:String = TCompilerIrDumper.Dump(returnedMethodCallablePublicConsumer.ir)
Local returnedMethodCallablePublicConsumerDiagnostics:TCompilerDiagnostic[]
Local returnedMethodCallablePublicConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(returnedMethodCallablePublicConsumer, returnedMethodCallablePublicConsumerDiagnostics)
Check(returnedMethodCallablePublicConsumer.Succeeded() And Contains(returnedMethodCallablePublicConsumerDump, "method %icm0 Choose(Int) -> Int(Int Var)") And Contains(returnedMethodCallablePublicConsumerDump, "call imported-virtual") And Contains(returnedMethodCallablePublicConsumerDump, "call interface") And Contains(returnedMethodCallablePublicConsumerDump, "external @ext2 Choose abi acme_returnedmethodcallbacks_TReturnedFunctions_Choose__Bint(enabled:Int) -> Int(Int Var)"), "separate compilation reconstructs callable results for imported virtual, Interface, and Type-function dispatch")
Check(returnedMethodCallablePublicConsumerDiagnostics.length = 0 And Not Contains(returnedMethodCallablePublicConsumerC, "extern BBINT (*acme_returnedmethodcallbacks_TReturnedFunctions_Choose__Bint(BBINT bmx_ep0_enabled))(BBINT *);") And Contains(returnedMethodCallablePublicConsumerC, "acme_returnedmethodcallbacks_TReturnedFunctions_Choose__Bint(1)"), "consumer C uses the dependency-header direct Type-function ABI without regenerating declarations")

Local returnedStructCallablePublicSource:String = "SuperStrict~nModule acme.returnedstructcallbacks~nFunction Increment:Int(value:Int Var)~nvalue=value+1~nReturn value~nEnd Function~nStruct SReturnedCallbacks~nMethod Choose:Int(value:Int Var)(enabled:Int)~nIf enabled Then Return Increment~nReturn Null~nEnd Method~nFunction Pick:Int(value:Int Var)(enabled:Int)~nIf enabled Then Return Increment~nReturn Null~nEnd Function~nEnd Struct"
Local returnedStructCallablePublic:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/returnedstructcallbacks.mod/returnedstructcallbacks.bmx", returnedStructCallablePublicSource, resolver, TestOptions())
Local returnedStructCallablePublicInterfaceDiagnostics:TCompilerDiagnostic[]
Local returnedStructCallablePublicInterface:String = TBlitzMaxCompiler.EmitInterface(returnedStructCallablePublic, returnedStructCallablePublicInterfaceDiagnostics)
Local returnedStructCallablePublicHeaderDiagnostics:TCompilerDiagnostic[]
Local returnedStructCallablePublicHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(returnedStructCallablePublic, returnedStructCallablePublicHeaderDiagnostics)
Check(returnedStructCallablePublic.Succeeded() And returnedStructCallablePublicInterfaceDiagnostics.length = 0 And Contains(returnedStructCallablePublicInterface, "SReturnedCallbacks^Null{") And Contains(returnedStructCallablePublicInterface, "-Choose%(value% Var)(enabled%)=~qacme_returnedstructcallbacks_SReturnedCallbacks_Choose__Bint~q") And Contains(returnedStructCallablePublicInterface, "+Pick%(value% Var)(enabled%)=~qacme_returnedstructcallbacks_SReturnedCallbacks_Pick__Bint~q"), "compact snapshots publish callable results on Struct methods and functions")
Check(returnedStructCallablePublicHeaderDiagnostics.length = 0 And Contains(returnedStructCallablePublicHeader, "BBINT (*_acme_returnedstructcallbacks_SReturnedCallbacks_Choose__Bint(struct acme_returnedstructcallbacks_SReturnedCallbacks * bmx_self_self, BBINT bmx_p0_enabled))(BBINT *);") And Contains(returnedStructCallablePublicHeader, "BBINT (*acme_returnedstructcallbacks_SReturnedCallbacks_Pick__Bint(BBINT bmx_p0_enabled))(BBINT *);"), "producer headers publish pointer-receiver and receiver-free Struct callable-result declarations")
resolver.AddInterface("acme.returnedstructcallbacks", "sdk/acme.returnedstructcallbacks.i", returnedStructCallablePublicInterface)
Local returnedStructCallablePublicConsumerSource:String = "SuperStrict~nImport acme.returnedstructcallbacks~nLocal owner:SReturnedCallbacks~nLocal methodCallback:Int(value:Int Var)=owner.Choose(True)~nLocal functionCallback:Int(value:Int Var)=SReturnedCallbacks.Pick(True)~nLocal methodValue:Int=40~nmethodCallback(methodValue)~nowner.Choose(True)(methodValue)~nLocal functionValue:Int=40~nfunctionCallback(functionValue)~nSReturnedCallbacks.Pick(True)(functionValue)"
Local returnedStructCallablePublicConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("returned-struct-callable-public-consumer.bmx", returnedStructCallablePublicConsumerSource, resolver, TestOptions())
Local returnedStructCallablePublicConsumerDump:String = TCompilerIrDumper.Dump(returnedStructCallablePublicConsumer.ir)
Local returnedStructCallablePublicConsumerDiagnostics:TCompilerDiagnostic[]
Local returnedStructCallablePublicConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(returnedStructCallablePublicConsumer, returnedStructCallablePublicConsumerDiagnostics)
Check(returnedStructCallablePublicConsumer.Succeeded() And Contains(returnedStructCallablePublicConsumerDump, "method %isr0 Choose(Int) -> Int(Int Var)") And Contains(returnedStructCallablePublicConsumerDump, "function %isr1 Pick(Int) -> Int(Int Var)") And Contains(returnedStructCallablePublicConsumerDump, "call struct-direct @isr0 Choose : Int(Int Var)") And Contains(returnedStructCallablePublicConsumerDump, "call external @isr1 Pick : Int(Int Var)"), "separate compilation reconstructs callable results on imported Struct routines")
Check(returnedStructCallablePublicConsumerDiagnostics.length = 0 And Not Contains(returnedStructCallablePublicConsumerC, "extern BBINT (*_acme_returnedstructcallbacks_SReturnedCallbacks_Choose__Bint(") And Not Contains(returnedStructCallablePublicConsumerC, "extern BBINT (*acme_returnedstructcallbacks_SReturnedCallbacks_Pick__Bint(") And Contains(returnedStructCallablePublicConsumerC, "= _acme_returnedstructcallbacks_SReturnedCallbacks_Choose__Bint((&bmx_v") And Contains(returnedStructCallablePublicConsumerC, "= acme_returnedstructcallbacks_SReturnedCallbacks_Pick__Bint(1)"), "consumer C sequences dependency-header Struct callable-result ABIs without wrappers or reconstructed declarations")

Local nativeStructPointerPublicSource:String = "SuperStrict~nModule acme.nativecallbacks~nStruct SNativeContext~nField value:Int~nEnd Struct~nStruct SNativeRegistration~nField callback:Int(context:SNativeContext Ptr)~nEnd Struct~nExtern~nFunction RegisterNative:Int(registration:SNativeRegistration Ptr)~nEnd Extern"
Local nativeStructPointerPublic:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nativecallbacks.mod/nativecallbacks.bmx", nativeStructPointerPublicSource, resolver, TestOptions())
Local nativeStructPointerInterfaceDiagnostics:TCompilerDiagnostic[]
Local nativeStructPointerInterface:String = TBlitzMaxCompiler.EmitInterface(nativeStructPointerPublic, nativeStructPointerInterfaceDiagnostics)
Local nativeStructPointerHeaderDiagnostics:TCompilerDiagnostic[]
Local nativeStructPointerHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(nativeStructPointerPublic, nativeStructPointerHeaderDiagnostics)
Check(nativeStructPointerPublic.Succeeded() And nativeStructPointerInterfaceDiagnostics.length = 0 And Contains(nativeStructPointerInterface, ".callback%(context:SNativeContext*)&") And Contains(nativeStructPointerInterface, "RegisterNative%(registration:SNativeRegistration*)="), "compact snapshots publish callable Struct fields and pointers to published Structs")
Check(nativeStructPointerHeaderDiagnostics.length = 0 And Contains(nativeStructPointerHeader, "BBINT (*_acme_nativecallbacks_snativeregistration_callback)(struct acme_nativecallbacks_SNativeContext *);") And Contains(nativeStructPointerHeader, "RegisterNative(struct acme_nativecallbacks_SNativeRegistration *"), "producer headers preserve exact nested C Struct pointer signatures")
resolver.AddInterface("acme.nativecallbacks", "sdk/acme.nativecallbacks.i", nativeStructPointerInterface)
Local nativeStructPointerConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("native-struct-pointer-consumer.bmx", "SuperStrict~nImport acme.nativecallbacks~nFunction ReadContext:Int(context:SNativeContext Ptr)~nReturn context.value~nEnd Function~nLocal registration:SNativeRegistration~nregistration.callback=ReadContext~nLocal result:Int=RegisterNative(Varptr registration)", resolver, TestOptions())
Local nativeStructPointerConsumerDiagnostics:TCompilerDiagnostic[]
Local nativeStructPointerConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeStructPointerConsumer, nativeStructPointerConsumerDiagnostics)
Check(nativeStructPointerConsumer.Succeeded() And nativeStructPointerConsumerDiagnostics.length = 0 And Contains(nativeStructPointerConsumerC, "_callback) = bmx_fn0_ReadContext") And Contains(nativeStructPointerConsumerC, "RegisterNative((&bmx_v"), "separate compilation reconstructs imported Struct pointer and callable-field ABIs")

Local structCallablePublicSource:String = "SuperStrict~nModule acme.structcallbacks~nStruct SBoundaryCell~nField value:Int~nEnd Struct~nFunction SumCells:Int(StaticArray cells:SBoundaryCell[2])~nReturn cells[0].value+cells[1].value~nEnd Function~nGlobal ActiveCells:Int(StaticArray cells:SBoundaryCell[2])=SumCells~nType TBoundaryBase~nField callback:Int(StaticArray cells:SBoundaryCell[2])=SumCells~nMethod Apply:Int(operation:Int(StaticArray cells:SBoundaryCell[2]),StaticArray cells:SBoundaryCell[2])~nReturn operation(cells)+callback(cells)~nEnd Method~nEnd Type~nType TBoundaryDerived Extends TBoundaryBase~nMethod Apply:Int(operation:Int(StaticArray cells:SBoundaryCell[2]),StaticArray cells:SBoundaryCell[2]) Override~nReturn Super.Apply(operation,cells)+1~nEnd Method~nEnd Type~nInterface IBoundaryCallback~nMethod Apply:Int(operation:Int(StaticArray cells:SBoundaryCell[2]),StaticArray cells:SBoundaryCell[2])~nEnd Interface~nType TBoundaryImplementation Implements IBoundaryCallback~nMethod Apply:Int(operation:Int(StaticArray cells:SBoundaryCell[2]),StaticArray cells:SBoundaryCell[2])~nReturn operation(cells)~nEnd Method~nEnd Type~nFunction CreateBoundary:TBoundaryBase()~nReturn New TBoundaryDerived~nEnd Function~nFunction CreateBoundaryImplementation:TBoundaryImplementation()~nReturn New TBoundaryImplementation~nEnd Function"
Local structCallablePublic:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/structcallbacks.mod/structcallbacks.bmx", structCallablePublicSource, resolver, TestOptions())
Local structCallablePublicInterfaceDiagnostics:TCompilerDiagnostic[]
Local structCallablePublicInterface:String = TBlitzMaxCompiler.EmitInterface(structCallablePublic, structCallablePublicInterfaceDiagnostics)
Local structCallablePublicHeaderDiagnostics:TCompilerDiagnostic[]
Local structCallablePublicHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(structCallablePublic, structCallablePublicHeaderDiagnostics)
Check(structCallablePublic.Succeeded() And structCallablePublicInterfaceDiagnostics.length = 0 And Contains(structCallablePublicInterface, "ActiveCells%(cells:SBoundaryCell&[2])&=mem:p(") And Contains(structCallablePublicInterface, ".callback%(cells:SBoundaryCell&[2])&") And Contains(structCallablePublicInterface, "-Apply%(operation%(cells:SBoundaryCell&[2]),cells:SBoundaryCell&[2])=") And Contains(structCallablePublicInterface, "-Apply%(operation%(cells:SBoundaryCell&[2]),cells:SBoundaryCell&[2])A="), "compact snapshots publish Struct StaticArray callable Globals, fields, virtual methods, and Interface slots")
Check(structCallablePublicHeaderDiagnostics.length = 0 And Contains(structCallablePublicHeader, "extern BBINT (*acme_structcallbacks_ActiveCells)(struct acme_structcallbacks_SBoundaryCell *);") And Contains(structCallablePublicHeader, "BBINT (*_acme_structcallbacks_tboundarybase_callback)(struct acme_structcallbacks_SBoundaryCell *);") And Contains(structCallablePublicHeader, "struct acme_structcallbacks_IBoundaryCallback_methods") And Contains(structCallablePublicHeader, "(*m_Apply_"), "producer headers use the same published Struct pointer in storage, class, and Interface callable signatures")
resolver.AddInterface("acme.structcallbacks", "sdk/acme.structcallbacks.i", structCallablePublicInterface)
Local structCallablePublicConsumerSource:String = "SuperStrict~nImport acme.structcallbacks~nLocal StaticArray cells:SBoundaryCell[2]~ncells[0].value=20~ncells[1].value=22~nLocal holder:TBoundaryBase=CreateBoundary()~nLocal iface:IBoundaryCallback=CreateBoundaryImplementation()~nLocal total:Int=ActiveCells(cells)+holder.callback(cells)+holder.Apply(SumCells,cells)+iface.Apply(SumCells,cells)"
Local structCallablePublicConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("struct-callable-public-consumer.bmx", structCallablePublicConsumerSource, resolver, TestOptions())
Local structCallablePublicConsumerDump:String = TCompilerIrDumper.Dump(structCallablePublicConsumer.ir)
Local structCallablePublicConsumerDiagnostics:TCompilerDiagnostic[]
Local structCallablePublicConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(structCallablePublicConsumer, structCallablePublicConsumerDiagnostics)
Check(structCallablePublicConsumer.Succeeded() And Contains(structCallablePublicConsumerDump, "external-global %extg0 ActiveCells:Int(StaticArray SBoundaryCell[2])") And Contains(structCallablePublicConsumerDump, "field %icf0 callback:Int(StaticArray SBoundaryCell[2])") And Contains(structCallablePublicConsumerDump, "Apply(Int(StaticArray SBoundaryCell[2]), StaticArray SBoundaryCell[2])") And Contains(structCallablePublicConsumerDump, "call interface @if0.%im0"), "consumer snapshot ingestion reconstructs the nested Struct extent for storage and both dispatch models")
Check(structCallablePublicConsumerDiagnostics.length = 0 And Not Contains(structCallablePublicConsumerC, "extern BBINT (*acme_structcallbacks_ActiveCells)(struct acme_structcallbacks_SBoundaryCell *);") And Contains(structCallablePublicConsumerC, "(acme_structcallbacks_ActiveCells)(") And Contains(structCallablePublicConsumerC, "->_acme_structcallbacks_tboundarybase_callback)") And Contains(structCallablePublicConsumerC, "->clas->m_") And Contains(structCallablePublicConsumerC, "->m_Apply_") And Not Contains(structCallablePublicConsumerC, "struct acme_structcallbacks_IBoundaryCallback_methods {"), "consumer C calls header-owned callable storage and slots without duplicating the Struct ABI")

Local fixedInterfacePublicSource:String = "SuperStrict~nModule acme.fixedinterfaces~nInterface IFixedInterfaceBase~nMethod Read:Int(StaticArray values:Int[4])~nEnd Interface~nInterface IFixedInterfaceExtra~nMethod Extra:Int()~nEnd Interface~nInterface IFixedInterfaceChild Extends IFixedInterfaceBase, IFixedInterfaceExtra~nMethod Offset:Int()~nEnd Interface~nType TFixedPublishedReader Implements IFixedInterfaceChild~nMethod Read:Int(StaticArray values:Int[4])~nReturn values[0]+values.length~nEnd Method~nMethod Extra:Int()~nReturn 1~nEnd Method~nMethod Offset:Int()~nReturn 1~nEnd Method~nEnd Type~nFunction CreateFixedPublishedReader:TFixedPublishedReader()~nReturn New TFixedPublishedReader~nEnd Function"
Local fixedInterfacePublic:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/fixedinterfaces.mod/fixedinterfaces.bmx", fixedInterfacePublicSource, resolver, TestOptions())
Local fixedInterfacePublicInterfaceDiagnostics:TCompilerDiagnostic[]
Local fixedInterfacePublicInterface:String = TBlitzMaxCompiler.EmitInterface(fixedInterfacePublic, fixedInterfacePublicInterfaceDiagnostics)
Local fixedInterfacePublicHeaderDiagnostics:TCompilerDiagnostic[]
Local fixedInterfacePublicHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(fixedInterfacePublic, fixedInterfacePublicHeaderDiagnostics)
Local fixedInterfacePublicRuntimeDiagnostics:TCompilerDiagnostic[]
Local fixedInterfacePublicRuntime:String = TBlitzMaxCompiler.EmitRuntimeC(fixedInterfacePublic, fixedInterfacePublicRuntimeDiagnostics)
Check(fixedInterfacePublic.Succeeded() And fixedInterfacePublicInterfaceDiagnostics.length = 0 And Contains(fixedInterfacePublicInterface, "IFixedInterfaceBase^Object{") And Contains(fixedInterfacePublicInterface, "-Read%(values%&[4])A=~qacme_fixedinterfaces_IFixedInterfaceBase_Read__S4_Bint~q") And Contains(fixedInterfacePublicInterface, "}AI=~qacme_fixedinterfaces_IFixedInterfaceBase~q") And Contains(fixedInterfacePublicInterface, "IFixedInterfaceChild^IFixedInterfaceBase@IFixedInterfaceExtra{") And Contains(fixedInterfacePublicInterface, "TFixedPublishedReader^Object@IFixedInterfaceChild{"), "compact snapshots publish multiple source Interface parents, implementing Types, method ABI identities and StaticArray parameter extents")
Check(fixedInterfacePublicHeaderDiagnostics.length = 0 And Contains(fixedInterfacePublicHeader, "extern const struct BBInterface acme_fixedinterfaces_IFixedInterfaceBase_ifc;") And Contains(fixedInterfacePublicHeader, "struct acme_fixedinterfaces_IFixedInterfaceBase_methods") And Contains(fixedInterfacePublicHeader, "(*m_Read__S4_Bint)(struct acme_fixedinterfaces_IFixedInterfaceBase_obj *, BBINT *);"), "producer runtime headers expose the public Interface descriptor and production-compatible method table")
Check(fixedInterfacePublicRuntimeDiagnostics.length = 0 And Contains(fixedInterfacePublicRuntime, "const struct BBInterface acme_fixedinterfaces_IFixedInterfaceBase_ifc =") And Contains(fixedInterfacePublicRuntime, "bbObjectRegisterInterface((BBInterface *)&acme_fixedinterfaces_IFixedInterfaceChild_ifc);"), "the owning module defines and registers its canonical public Interface descriptors")
resolver.AddInterface("acme.fixedinterfaces", "sdk/acme.fixedinterfaces.i", fixedInterfacePublicInterface)
Local fixedInterfacePublicConsumerSource:String = "SuperStrict~nImport acme.fixedinterfaces~nType TFixedInterfaceConsumer Implements IFixedInterfaceChild~nMethod Read:Int(StaticArray values:Int[4])~nReturn values[0]+values.length~nEnd Method~nMethod Extra:Int()~nReturn 1~nEnd Method~nMethod Offset:Int()~nReturn 1~nEnd Method~nEnd Type~nLocal StaticArray values:Int[4]~nvalues[0]=36~nLocal child:IFixedInterfaceChild=New TFixedInterfaceConsumer~nLocal base:IFixedInterfaceBase=child~nLocal extra:IFixedInterfaceExtra=child~nLocal published:TFixedPublishedReader=CreateFixedPublishedReader()~nLocal importedChild:IFixedInterfaceChild=published~nLocal result:Int=base.Read(values)+extra.Extra()+child.Offset()+importedChild.Read(values)"
Local fixedInterfacePublicConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("fixed-interface-public-consumer.bmx", fixedInterfacePublicConsumerSource, resolver, TestOptions())
Local fixedInterfacePublicConsumerDump:String = TCompilerIrDumper.Dump(fixedInterfacePublicConsumer.ir)
Local fixedInterfacePublicConsumerDiagnostics:TCompilerDiagnostic[]
Local fixedInterfacePublicConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(fixedInterfacePublicConsumer, fixedInterfacePublicConsumerDiagnostics)
Check(fixedInterfacePublicConsumer.Succeeded() And Contains(fixedInterfacePublicConsumerDump, "IFixedInterfaceChild:IFixedInterfaceChild extends @") And Contains(fixedInterfacePublicConsumerDump, "Read(StaticArray Int[4]) -> Int [inherited @") And Contains(fixedInterfacePublicConsumerDump, "Extra() -> Int [inherited @") And Contains(fixedInterfacePublicConsumerDump, "imported-class @") And Contains(fixedInterfacePublicConsumerDump, "call interface @"), "a separate compilation reconstructs multiple inherited Interface branches, imported implementors and StaticArray slots without source text")
Check(fixedInterfacePublicConsumerDiagnostics.length = 0 And Contains(fixedInterfacePublicConsumerC, "acme_fixedinterfaces_IFixedInterfaceBase_ifc") And Contains(fixedInterfacePublicConsumerC, "acme_fixedinterfaces_IFixedInterfaceExtra_ifc") And Contains(fixedInterfacePublicConsumerC, "acme_fixedinterfaces_IFixedInterfaceChild_ifc") And Contains(fixedInterfacePublicConsumerC, "acme_fixedinterfaces_CreateFixedPublishedReader()") And Contains(fixedInterfacePublicConsumerC, "->m_Read__S4_Bint(") And Not Contains(fixedInterfacePublicConsumerC, "struct acme_fixedinterfaces_IFixedInterfaceBase_methods {"), "consumer C converts producer-owned implementing Types and dispatches through dependency-owned Interface tables without redeclaring their published layouts")

Local parameterizedPublicStructSource:String = "SuperStrict~nModule acme.parameterizedvalue~nStruct SParameterizedValue~nField value:Int~nMethod New(value:Int)~nSelf.value=value~nEnd Method~nEnd Struct"
Local parameterizedPublicStruct:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/parameterizedvalue.mod/parameterizedvalue.bmx", parameterizedPublicStructSource, resolver, TestOptions())
Local parameterizedPublicStructInterfaceDiagnostics:TCompilerDiagnostic[]
Local parameterizedPublicStructInterface:String = TBlitzMaxCompiler.EmitInterface(parameterizedPublicStruct, parameterizedPublicStructInterfaceDiagnostics)
Local parameterizedPublicStructHeaderDiagnostics:TCompilerDiagnostic[]
Local parameterizedPublicStructHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(parameterizedPublicStruct, parameterizedPublicStructHeaderDiagnostics)
Check(parameterizedPublicStruct.Succeeded() And parameterizedPublicStructInterfaceDiagnostics.length = 0 And parameterizedPublicStructHeaderDiagnostics.length = 0 And Contains(parameterizedPublicStructHeader, "struct acme_parameterizedvalue_SParameterizedValue acme_parameterizedvalue_SParameterizedValue_New_ObjectNew(void);") And Contains(parameterizedPublicStructHeader, "acme_parameterizedvalue_SParameterizedValue_New__Bint_ObjectNew"), "published Structs retain the implicit value-default ABI alongside parameterized New overloads")
resolver.AddInterface("acme.parameterizedvalue", "sdk/acme.parameterizedvalue.i", parameterizedPublicStructInterface)
Local parameterizedPublicStructConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("parameterized-public-struct-consumer.bmx", "SuperStrict~nImport acme.parameterizedvalue~nType TParameterizedHolder~nField value:SParameterizedValue~nEnd Type~nLocal holder:TParameterizedHolder=New TParameterizedHolder", resolver, TestOptions())
Local parameterizedPublicStructConsumerDiagnostics:TCompilerDiagnostic[]
Local parameterizedPublicStructConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(parameterizedPublicStructConsumer, parameterizedPublicStructConsumerDiagnostics)
Check(parameterizedPublicStructConsumer.Succeeded() And parameterizedPublicStructConsumerDiagnostics.length = 0 And Contains(parameterizedPublicStructConsumerC, "->bmx_field_f0_value = acme_parameterizedvalue_SParameterizedValue_New_ObjectNew();"), "consumers default-construct imported Struct fields through the implicit value helper even when snapshots publish only parameterized constructors")

Local managedPublicStructSource:String = "SuperStrict~nModule acme.managedvalues~nStruct SManagedValue~nField text:String~nField items:Int[]~nField owner:Object~nEnd Struct"
Local managedPublicStruct:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/managedvalues.mod/managedvalues.bmx", managedPublicStructSource, resolver, TestOptions())
Local managedPublicStructInterfaceDiagnostics:TCompilerDiagnostic[]
Local managedPublicStructInterface:String = TBlitzMaxCompiler.EmitInterface(managedPublicStruct, managedPublicStructInterfaceDiagnostics)
Local managedPublicStructRuntimeDiagnostics:TCompilerDiagnostic[]
Local managedPublicStructRuntime:String = TBlitzMaxCompiler.EmitRuntimeC(managedPublicStruct, managedPublicStructRuntimeDiagnostics)
Local managedPublicStructHeaderDiagnostics:TCompilerDiagnostic[]
Local managedPublicStructHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(managedPublicStruct, managedPublicStructHeaderDiagnostics)
Check(managedPublicStruct.Succeeded() And managedPublicStruct.ir.structs[0].containsManagedReferences And managedPublicStructInterfaceDiagnostics.length = 0 And Contains(managedPublicStructInterface, ".text$&") And Contains(managedPublicStructInterface, ".items%&[]&") And Contains(managedPublicStructInterface, ".owner:Object&"), "public Struct interfaces preserve managed reference field types without serializing lifetime machinery")
Check(managedPublicStructRuntimeDiagnostics.length = 0 And managedPublicStructHeaderDiagnostics.length = 0 And Contains(managedPublicStructRuntime, "_acme_managedvalues_smanagedvalue_text = &bbEmptyString;") And Contains(managedPublicStructRuntime, "_acme_managedvalues_smanagedvalue_items = &bbEmptyArray;") And Contains(managedPublicStructRuntime, "_acme_managedvalues_smanagedvalue_owner = ((BBOBJECT)&bbNullObject);") And Contains(managedPublicStructRuntime, "void bbStructElementInit_acme_managedvalues_SManagedValue(void *bmx_value)") And Contains(managedPublicStructRuntime, "BBArray *bbArrayNew1DStruct_acme_managedvalues_SManagedValue(int length)") And Contains(managedPublicStructHeader, "void bbStructElementInit_acme_managedvalues_SManagedValue(void *bmx_value);") And Contains(managedPublicStructHeader, "BBArray *bbArrayNew1DStruct_acme_managedvalues_SManagedValue(int length);"), "the producer owns managed Struct defaults and publishes its rank-independent element initializer plus production-shaped one-dimensional allocator ABI")
resolver.AddInterface("acme.managedvalues", "sdk/acme.managedvalues.i", managedPublicStructInterface)
Local managedPublicStructConsumerSource:String = "SuperStrict~nImport acme.managedvalues~nType TManagedValueHolder~nField value:SManagedValue~nEnd Type~nGlobal StaticArray sharedFixed:SManagedValue[2]~nLocal direct:SManagedValue~nLocal holder:TManagedValueHolder=New TManagedValueHolder~nholder.value=direct~nLocal values:SManagedValue[]=New SManagedValue[2]~nvalues[0]=direct~nvalues[1]=holder.value~nLocal grid:SManagedValue[,]=New SManagedValue[2,3]~ngrid[1,2]=direct~nLocal gridValue:SManagedValue=grid[1,2]~nLocal first:SManagedValue=values[0]~nLocal literal:SManagedValue[]=[values[0],values[1]]~nLocal joined:SManagedValue[]=values+literal~nLocal StaticArray fixed:SManagedValue[2]~nfixed[0]=direct~nsharedFixed[1]=fixed[0]~nFor Local item:SManagedValue=EachIn fixed~nfirst=item~nNext"
Local managedPublicStructConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("managed-public-struct-consumer.bmx", managedPublicStructConsumerSource, resolver, TestOptions())
Local managedPublicStructConsumerDump:String = TCompilerIrDumper.Dump(managedPublicStructConsumer.ir)
Local managedPublicStructConsumerDiagnostics:TCompilerDiagnostic[]
Local managedPublicStructConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(managedPublicStructConsumer, managedPublicStructConsumerDiagnostics)
Check(managedPublicStructConsumer.Succeeded() And managedPublicStructConsumer.ir.importedStructs[0].containsManagedReferences And managedPublicStructConsumer.ir.classes[0].hasManagedFields And Contains(managedPublicStructConsumerDump, "SManagedValue:SManagedValue abi acme_managedvalues_SManagedValue from acme.managedvalues [element-initializer bbStructElementInit_acme_managedvalues_SManagedValue] [managed-references]") And Contains(managedPublicStructConsumerDump, "array-new SManagedValue encoding ~q@SManagedValue~q rank 1") And Contains(managedPublicStructConsumerDump, "array-new SManagedValue encoding ~q@SManagedValue~q rank 2") And Contains(managedPublicStructConsumerDump, "[static-array SManagedValue x 2] [element-layout imported-struct @ist0]") And Contains(managedPublicStructConsumerDump, "for-each-static-array SManagedValue x 2") And Contains(managedPublicStructConsumerDump, "element-layout imported-struct @ist0"), "managed-reference, ranked dynamic-array, element-initializer, and fixed-array Struct identities are reconstructed from a dependency interface")
Check(managedPublicStructConsumerDiagnostics.length = 0 And Contains(managedPublicStructConsumerC, "acme_managedvalues_SManagedValue_New_ObjectNew()") And Contains(managedPublicStructConsumerC, "bbObjectNew((BBClass *)&bmx_class_cls0_TManagedValueHolder)") And Contains(managedPublicStructConsumerC, "->bmx_field_f0_value = acme_managedvalues_SManagedValue_New_ObjectNew();") And Contains(managedPublicStructConsumerC, "bbArrayNew1DStruct_acme_managedvalues_SManagedValue(2)") And Contains(managedPublicStructConsumerC, "bbArrayNewStruct(~q@SManagedValue~q, sizeof(struct acme_managedvalues_SManagedValue), bbStructElementInit_acme_managedvalues_SManagedValue, 2, 2, 3)") And Not Contains(managedPublicStructConsumerC, "bmx_imported_struct_array_init_ist0") And Contains(managedPublicStructConsumerC, "bbArrayFromDataStruct(~q@SManagedValue~q") And Contains(managedPublicStructConsumerC, "struct acme_managedvalues_SManagedValue bmx_global_") And Contains(managedPublicStructConsumerC, "for (BBUINT bmx_static_init_") And Contains(managedPublicStructConsumerC, "struct acme_managedvalues_SManagedValue *bmx_tmp_"), "a consumer uses the producer element initializer for multidimensional allocation while retaining existing one-dimensional, literal, and fixed-storage ABIs")

Local markerInterface:TCompilerResult = TBlitzMaxCompiler.Compile("marker-interface.bmx", "SuperStrict~nInterface IMarker~nEnd Interface~nType TMarked Implements IMarker~nEnd Type~nLocal marked:IMarker = New TMarked", resolver, TestOptions())
Check(markerInterface.Succeeded(), "method-free marker Interfaces retain a valid runtime layout")
Local markerDiagnostics:TCompilerDiagnostic[]
Local markerC:String = TBlitzMaxCompiler.EmitRuntimeC(markerInterface, markerDiagnostics)
Check(markerDiagnostics.length = 0 And Contains(markerC, "void *reserved;") And Contains(markerC, "{ 0 },"), "marker Interface tables remain valid standard C structs and initializers")

Local genericInterface:TCompilerResult = TBlitzMaxCompiler.Compile("generic-interface.bmx", "SuperStrict~nInterface IValue<T>~nMethod Get:T()~nEnd Interface", resolver, TestOptions())
Check(genericInterface.Succeeded() And genericInterface.genericPlan.templateOutputs.length = 1 And genericInterface.genericPlan.units.length = 0, "an open generic Interface publishes a canonical template without taking runtime ownership until a closed specialization is requested")
Local objectGenericSource:String = "SuperStrict~nType TArgumentBox<T>~nField value:T~nEnd Type~nLocal objects:TArgumentBox<Object>=New TArgumentBox<Object>"
Local objectGeneric:TCompilerResult = TBlitzMaxCompiler.Compile("object-generic.bmx", objectGenericSource, resolver, TestOptions())
Check(objectGeneric.Succeeded() And objectGeneric.genericPlan.registry.nodes.length = 1 And Not HasCompilerDiagnostic(objectGeneric, "BMXC3040"), "Object generic arguments receive a stable specialization identity and lower completely")
Local enumGenericSource:String = "SuperStrict~nEnum EGenericArgument~nFirst~nSecond~nEnd Enum~nFunction SelectEquals:Int(left:Int,right:Int)~nReturn left=right~nEnd Function~nFunction SelectEquals:Int(left:String,right:String)~nReturn left=right~nEnd Function~nType TEnumArgumentBox<T>~nField value:T~nField values:T[]~nMethod Initialize()~nvalues=New T[2]~nEnd Method~nMethod Same:Int(left:T,right:T)~nReturn left=right~nEnd Method~nMethod Deferred:Int(left:T,right:T)~nReturn SelectEquals(left,right)~nEnd Method~nEnd Type~nLocal box:TEnumArgumentBox<EGenericArgument>=New TEnumArgumentBox<EGenericArgument>~nbox.Initialize()~nLocal same:Int=box.Same(EGenericArgument.First,EGenericArgument.Second)~nLocal deferred:Int=box.Deferred(EGenericArgument.First,EGenericArgument.Second)"
Local enumGeneric:TCompilerResult = TBlitzMaxCompiler.Compile("enum-generic.bmx", enumGenericSource, resolver, TestOptions())
Check(enumGeneric.Succeeded() And enumGeneric.genericPlan.registry.nodes.length = 1 And enumGeneric.genericPlan.units.length = 1 And Not HasCompilerDiagnostic(enumGeneric, "BMXC3040") And Not HasCompilerDiagnostic(enumGeneric, "BMXC3011") And Not HasCompilerDiagnostic(enumGeneric, "BMXC3027") And Not HasCompilerDiagnostic(enumGeneric, "BMXC3047") And Not HasCompilerDiagnostic(enumGeneric, "BMXC3063"), "Enum generic arguments retain value identity, Array descriptors, equality and underlying-value overload resolution")
Local stringOrderingGenericSource:String = "SuperStrict~nType TStringOrdering<T>~nField value:T~nMethod Before:Int(other:TStringOrdering<T>)~nReturn value < other.value~nEnd Method~nMethod After:Int(other:TStringOrdering<T>)~nReturn value > other.value~nEnd Method~nEnd Type~nLocal first:TStringOrdering<String> = New TStringOrdering<String>()~nLocal second:TStringOrdering<String> = New TStringOrdering<String>()"
Local stringOrderingGeneric:TCompilerResult = TBlitzMaxCompiler.Compile("string-ordering-generic.bmx", stringOrderingGenericSource, resolver, TestOptions())
Check(stringOrderingGeneric.Succeeded() And stringOrderingGeneric.ir <> Null And stringOrderingGeneric.ir.genericInstances.length = 1 And stringOrderingGeneric.genericPlan.units.length = 1 And Not HasCompilerDiagnostic(stringOrderingGeneric, "BMXC3047") And Not HasCompilerDiagnostic(stringOrderingGeneric, "BMXC1015"), "typed application IR retains allocations of a generic Type whose closed String fields use ordering operators")
Local genericFieldInitializerSource:String = "SuperStrict~nFunction BuildMarker:Object()~nReturn ~qmarker~q~nEnd Function~nType TFieldValue<T>~nField value:T~nEnd Type~nType TFieldOwner<T>~nField nested:TFieldValue<T>=New TFieldValue<T>~nField marker:Object=BuildMarker()~nEnd Type~nLocal owner:TFieldOwner<Int>=New TFieldOwner<Int>"
Local genericFieldInitializers:TCompilerResult = TBlitzMaxCompiler.Compile("generic-field-initializers.bmx", genericFieldInitializerSource, resolver, TestOptions())
Check(genericFieldInitializers.Succeeded() And genericFieldInitializers.genericPlan.registry.nodes.length = 2 And genericFieldInitializers.genericPlan.units.length = 2 And Not HasCompilerDiagnostic(genericFieldInitializers, "BMXC3033"), "generic instance fields retain closed constructor and routine-call initialization expressions")
Local genericNativeSource:String = "SuperStrict~nExtern~nFunction NativeWrite(value:Byte Ptr)=~qvoid native_write(void*)!~q~nFunction NativeArray:Object(length:Int)=~qBBArray* native_array(int)!~q~nEnd Extern~nType TGenericNative<T>~nMethod Write(value:Byte Ptr)~nNativeWrite(value)~nEnd Method~nMethod Array:Object(length:Int)~nReturn NativeArray(length)~nEnd Method~nEnd Type~nLocal bridge:TGenericNative<Int>=New TGenericNative<Int>~nbridge.Write(Null)~nLocal value:Object=bridge.Array(1)"
Local genericNative:TCompilerResult = TBlitzMaxCompiler.Compile("generic-native.bmx", genericNativeSource, resolver, TestOptions())
Local genericNativeUnit:String
If genericNative.genericPlan And genericNative.genericPlan.units.length Then genericNativeUnit = genericNative.genericPlan.units[0].declarations + genericNative.genericPlan.units[0].implementation
Check(genericNative.Succeeded() And genericNative.genericPlan.units.length = 1 And Contains(genericNativeUnit, "native_write(((void*)") And Contains(genericNativeUnit, "((BBOBJECT)(native_array(((int)") And Not Contains(genericNativeUnit, "void void native_write") And Not Contains(genericNativeUnit, "void native_write(void*);") And Not Contains(genericNativeUnit, "BBArray* native_array(int);"), "canonical generic calls retain parsed native linker names, call-site casts, managed result conversion, and external prototype ownership")
Local pointerGeneric:TCompilerResult = TBlitzMaxCompiler.Compile("pointer-generic.bmx", "SuperStrict~nType TPointerArgumentBox<T>~nField value:T~nEnd Type~nLocal pointers:TPointerArgumentBox<Byte Ptr>=New TPointerArgumentBox<Byte Ptr>", resolver, TestOptions())
Check(pointerGeneric.Succeeded() And pointerGeneric.genericPlan.registry.nodes.length = 1 And pointerGeneric.genericPlan.units.length = 1 And Not HasCompilerDiagnostic(pointerGeneric, "BMXC3040") And Not HasCompilerDiagnostic(pointerGeneric, "BMXC3011"), "pointer generic arguments receive a stable specialization identity and lower completely")
Local semanticFailure:TCompilerResult = TBlitzMaxCompiler.Compile("semantic-error.bmx", "SuperStrict~nLocal missing:Int = DoesNotExist()", resolver, TestOptions())
Check(Not semanticFailure.Succeeded() And semanticFailure.ir = Null, "semantic errors prevent IR lowering")

Local missingInterface:TCompilerResult = TBlitzMaxCompiler.Compile("missing-import.bmx", "SuperStrict~nImport absent.api", resolver, TestOptions())
Check(Not missingInterface.Succeeded() And missingInterface.analysis.snapshot.diagnostics.length > 0, "missing required interface prevents compilation")

Local instrumentedOptions:TCompilerOptions = TestOptions()
instrumentedOptions.debugInstrumentation = True
instrumentedOptions.coverageInstrumentation = True
Local instrumented:TCompilerResult = TBlitzMaxCompiler.Compile("instrumented.bmx", "SuperStrict~nLocal value:Int = 1", resolver, instrumentedOptions)
Local instrumentedDump:String = TCompilerIrDumper.Dump(instrumented.ir)
Check(Contains(instrumentedDump, "[debug] [coverage]"), "instrumentation intent is retained in IR")
Local unsupportedInstrumentation:TCompilerDiagnostic[]
TBlitzMaxCompiler.EmitC(instrumented, unsupportedInstrumentation)
Check(HasDiagnostic(unsupportedInstrumentation, "BMXC2030") And HasDiagnostic(unsupportedInstrumentation, "BMXC2031"), "C backend does not silently omit requested instrumentation")

Local debugRuntimeOptions:TCompilerOptions = DebugTestOptions()
debugRuntimeOptions.debugInstrumentation = True
Local debugRuntimeSource:String = "SuperStrict~nType TDebugValue~nField value:Int~nMethod Read:Int(delta:Int)~nReturn value+delta~nEnd Method~nEnd Type~nStruct SDebugValue~nField value:Int~nMethod Read:Int()~nReturn value~nEnd Method~nEnd Struct~nFunction Increment:Int(value:Int Var)~nvalue=value+1~nReturn value~nEnd Function~nLocal item:TDebugValue=New TDebugValue~nitem.value=40~nLocal cell:SDebugValue~ncell.value=1~nLocal result:Int=item.Read(Increment(item.value))+cell.Read()"
Local debugRuntime:TCompilerResult = TBlitzMaxCompiler.Compile("debug-runtime.bmx", debugRuntimeSource, resolver, debugRuntimeOptions)
Local debugRuntimeDump:String = TCompilerIrDumper.Dump(debugRuntime.ir)
Local debugRuntimeDiagnostics:TCompilerDiagnostic[]
Local debugRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(debugRuntime, debugRuntimeDiagnostics)
Check(debugRuntime.Succeeded() And Contains(debugRuntimeDump, "debug-source ") And Contains(debugRuntimeDump, "~qdebug-runtime.bmx~q") And Contains(debugRuntimeDump, "debug-scope ") And Contains(debugRuntimeDump, "debug-variable %") And Contains(debugRuntimeDump, "[receiver]") And Contains(debugRuntimeDump, "[var]"), "debug source, function scope, receiver and parameter identities survive typed IR lowering")
Check(debugRuntimeDiagnostics.length = 0 And Contains(debugRuntimeC, "bbRegisterSource(") And Contains(debugRuntimeC, "BBDEBUGSCOPE_FUNCTION") And Contains(debugRuntimeC, "BBDEBUGDECL_LOCAL, ~qSelf~q, ~q:TDebugValue~q, .var_address = &bmx_self_self") And Contains(debugRuntimeC, "BBDEBUGDECL_LOCAL, ~qSelf~q, ~q@SDebugValue~q, .var_address = bmx_self_self") And Contains(debugRuntimeC, "BBDEBUGDECL_VARPARAM, ~qvalue~q, ~q&i~q") And Contains(debugRuntimeC, "bbOnDebugEnterScope(") And Contains(debugRuntimeC, "BBDebugStm ") And Contains(debugRuntimeC, "bbOnDebugEnterStm(") And Contains(debugRuntimeC, "bbOnDebugLeaveScope()") And Contains(debugRuntimeC, "bbNullObjectTest((BBObject *)"), "runtime C emits production-compatible debug type tags, receiver addresses, scope, statement and object checks")

Local debugTypeTagSource:String = "SuperStrict~nEnum EDebugTag:Int~nReady~nEnd Enum~nStruct SDebugTag~nField value:Int~nEnd Struct~nInterface IDebugTag~nEnd Interface~nFunction KeepDebugTag:Int(value:Int)~nReturn value~nEnd Function~nFunction InspectDebugTags(callback:Int(value:Int), pointer:Byte Ptr Ptr, pointerVar:Int Ptr Var)~nLocal localCallback:Int(value:Int)=callback~nLocal callbacks:Int(value:Int)[]~ncallbacks=callbacks[..1]~ncallbacks[0]=localCallback~nLocal closureValue:Closure<Int(value:Int)>=Function(value:Int)~nReturn value~nEnd Function~nLocal StaticArray fixed:Int[4]~nLocal record:SDebugTag~nLocal iface:IDebugTag~nLocal state:EDebugTag=EDebugTag.Ready~nEnd Function~nLocal pointer:Int Ptr~nInspectDebugTags(KeepDebugTag, Byte Ptr Ptr Null, pointer)"
Local debugTypeTags:TCompilerResult = TBlitzMaxCompiler.Compile("debug-type-tags.bmx", debugTypeTagSource, resolver, debugRuntimeOptions)
Local debugTypeTagDiagnostics:TCompilerDiagnostic[]
Local debugTypeTagC:String = TBlitzMaxCompiler.EmitRuntimeC(debugTypeTags, debugTypeTagDiagnostics)
Check(debugTypeTags.Succeeded() And debugTypeTagDiagnostics.length = 0, "debug typetag coverage source compiles across callable, pointer, array, Closure, Struct, Interface and enum categories: " + CompilerDiagnosticSummary(debugTypeTags))
Check(Contains(debugTypeTagC, "BBDEBUGDECL_LOCAL, ~qcallback~q, ~q(i)i~q") And Contains(debugTypeTagC, "BBDEBUGDECL_LOCAL, ~qpointer~q, ~q**b~q") And Contains(debugTypeTagC, "BBDEBUGDECL_VARPARAM, ~qpointerVar~q, ~q&*i~q"), "debug parameters preserve complete callable signatures, recursive pointer depth and Var composition")
Check(Contains(debugTypeTagC, "BBDEBUGDECL_LOCAL, ~qlocalCallback~q, ~q(i)i~q") And Contains(debugTypeTagC, "BBDEBUGDECL_LOCAL, ~qcallbacks~q, ~q[](i)i~q") And Contains(debugTypeTagC, "BBDEBUGDECL_LOCAL, ~qclosureValue~q, ~q!(i)i~q"), "debug locals preserve callable, callable-array and managed Closure tags")
Check(Contains(debugTypeTagC, "BBDEBUGDECL_LOCAL, ~qfixed~q, ~q[4]i~q") And Contains(debugTypeTagC, "BBDEBUGDECL_LOCAL, ~qrecord~q, ~q@SDebugTag~q") And Contains(debugTypeTagC, "BBDEBUGDECL_LOCAL, ~qiface~q, ~q:IDebugTag~q") And Contains(debugTypeTagC, "BBDEBUGDECL_LOCAL, ~qstate~q, ~q/EDebugTag~q"), "debug locals preserve StaticArray, Struct, Interface and enum tags")
Check(Not Contains(debugTypeTagC, ", ~q?~q, .var_address") And Not Contains(debugTypeTagC, ", ~q*~q, .var_address") And Not Contains(debugTypeTagC, ", ~q[]*~q, .var_address") And Not Contains(debugTypeTagC, ", ~q[]?~q, .var_address"), "debug declarations never publish incomplete object, pointer or array typetags")
Local debugScalarTagSource:String = "SuperStrict~nLocal byteValue:Byte~nLocal shortValue:Short~nLocal intValue:Int~nLocal uintValue:UInt~nLocal longValue:Long~nLocal ulongValue:ULong~nLocal longIntValue:LongInt~nLocal ulongIntValue:ULongInt~nLocal sizeValue:Size_T~nLocal wparamValue:WParam~nLocal lparamValue:LParam~nLocal floatValue:Float~nLocal doubleValue:Double~nLocal float64Value:Float64~nLocal int128Value:Int128~nLocal float128Value:Float128~nLocal double128Value:Double128~nLocal stringValue:String~nLocal objectValue:Object"
Local debugScalarTags:TCompilerResult = TBlitzMaxCompiler.Compile("debug-scalar-tags.bmx", debugScalarTagSource, resolver, debugRuntimeOptions)
Local debugScalarTagDiagnostics:TCompilerDiagnostic[]
Local debugScalarTagC:String = TBlitzMaxCompiler.EmitRuntimeC(debugScalarTags, debugScalarTagDiagnostics)
Check(debugScalarTags.Succeeded() And debugScalarTagDiagnostics.length = 0 And Contains(debugScalarTagC, "~qbyteValue~q, ~qb~q") And Contains(debugScalarTagC, "~qshortValue~q, ~qs~q") And Contains(debugScalarTagC, "~qintValue~q, ~qi~q") And Contains(debugScalarTagC, "~quintValue~q, ~qu~q") And Contains(debugScalarTagC, "~qlongValue~q, ~ql~q") And Contains(debugScalarTagC, "~qulongValue~q, ~qy~q") And Contains(debugScalarTagC, "~qlongIntValue~q, ~qv~q") And Contains(debugScalarTagC, "~qulongIntValue~q, ~qe~q") And Contains(debugScalarTagC, "~qsizeValue~q, ~qt~q") And Contains(debugScalarTagC, "~qwparamValue~q, ~qW~q") And Contains(debugScalarTagC, "~qlparamValue~q, ~qX~q"), "debug integral and platform scalar declarations use the debugger's canonical tags: " + CompilerDiagnosticSummary(debugScalarTags))
Check(Contains(debugScalarTagC, "~qfloatValue~q, ~qf~q") And Contains(debugScalarTagC, "~qdoubleValue~q, ~qd~q") And Contains(debugScalarTagC, "~qfloat64Value~q, ~qh~q") And Contains(debugScalarTagC, "~qint128Value~q, ~qj~q") And Contains(debugScalarTagC, "~qfloat128Value~q, ~qk~q") And Contains(debugScalarTagC, "~qdouble128Value~q, ~qm~q") And Contains(debugScalarTagC, "~qstringValue~q, ~q$~q") And Contains(debugScalarTagC, "~qobjectValue~q, ~q:Object~q"), "debug floating, wide numeric, String and Object declarations use distinct canonical tags")

Local debugVirtualCondition:TCompilerResult = TBlitzMaxCompiler.Compile("debug-virtual-condition.bmx", "SuperStrict~nType TCondition~nMethod Ready:Int()~nReturn True~nEnd Method~nEnd Type~nFunction Probe:Int(value:TCondition)~nIf value.Ready() Then Return True~nReturn False~nEnd Function", resolver, debugRuntimeOptions)
Local debugVirtualConditionDiagnostics:TCompilerDiagnostic[]
Local debugVirtualConditionC:String = TBlitzMaxCompiler.EmitRuntimeC(debugVirtualCondition, debugVirtualConditionDiagnostics)
Check(debugVirtualCondition.Succeeded() And debugVirtualConditionDiagnostics.length = 0 And Contains(debugVirtualConditionC, "if (((struct ") And Contains(debugVirtualConditionC, "bbNullObjectTest((BBObject *)") And Contains(debugVirtualConditionC, "))->clas->m_"), "debug virtual calls retain the complete null-checked receiver expression when used as conditions")

Local pointerCondition:TCompilerResult = TBlitzMaxCompiler.Compile("pointer-condition.bmx", "SuperStrict~nFunction IsEmpty:Int(value:Byte Ptr)~nIf value = Null Then Return True~nReturn False~nEnd Function", resolver, TestOptions())
Local pointerConditionDiagnostics:TCompilerDiagnostic[]
Local pointerConditionC:String = TBlitzMaxCompiler.EmitRuntimeC(pointerCondition, pointerConditionDiagnostics)
Check(pointerCondition.Succeeded() And pointerConditionDiagnostics.length = 0 And Contains(pointerConditionC, "if (bmx_p0_value == 0)") And Not Contains(pointerConditionC, "if ((bmx_p0_value == 0))"), "conditions remove only a balanced outer pair and avoid strict C equality-parenthesis warnings")

Local routineNoDebugSource:String = "SuperStrict~nFunction Quiet:Int() NoDebug~nLocal hidden:Int=1~nReturn hidden~nEnd Function~nFunction Loud:Int()~nLocal visible:Int=2~nReturn visible~nEnd Function~nLocal result:Int=Quiet()+Loud()"
Local routineNoDebug:TCompilerResult = TBlitzMaxCompiler.Compile("routine-nodebug.bmx", routineNoDebugSource, resolver, debugRuntimeOptions)
Local routineNoDebugDump:String = TCompilerIrDumper.Dump(routineNoDebug.ir)
Local quietDumpStart:Int = routineNoDebugDump.Find("function @fn0 Quiet")
Local loudDumpStart:Int = routineNoDebugDump.Find("function @fn1 Loud")
Local quietDump:String = routineNoDebugDump[quietDumpStart..loudDumpStart]
Local routineNoDebugDiagnostics:TCompilerDiagnostic[]
Local routineNoDebugC:String = TBlitzMaxCompiler.EmitRuntimeC(routineNoDebug, routineNoDebugDiagnostics)
Local quietCStart:Int = routineNoDebugC.Find("BBINT bmx_fn0_Quiet(void) {")
Local loudCStart:Int = routineNoDebugC.Find("BBINT bmx_fn1_Loud(void) {")
Local quietC:String = routineNoDebugC[quietCStart..loudCStart]
Check(routineNoDebug.Succeeded() And Contains(quietDump, "[debug] [nodebug]") And Not Contains(quietDump, "debug-scope") And Contains(routineNoDebugDump[loudDumpStart..], "[debug]") And Contains(routineNoDebugDump[loudDumpStart..], "debug-scope"), "routine NoDebug remains explicit IR while suppressing only its debugger scope")
Check(routineNoDebugDiagnostics.length = 0 And Not Contains(quietC, "bbOnDebugEnterScope") And Not Contains(quietC, "bbOnDebugEnterStm") And Contains(routineNoDebugC[loudCStart..], "bbOnDebugEnterScope") And Contains(routineNoDebugC[loudCStart..], "bbOnDebugEnterStm"), "routine NoDebug suppresses callbacks without affecting a debug-visible sibling")

Local compilationNoDebugSource:String = "SuperStrict~nNoDebug~nType TNoDebugValue~nField value:Int~nEnd Type~nLocal item:TNoDebugValue~nLocal values:Int[]=[1]~nLocal result:Int=item.value+values[0]~nAssert result"
Local compilationNoDebug:TCompilerResult = TBlitzMaxCompiler.Compile("compilation-nodebug.bmx", compilationNoDebugSource, resolver, debugRuntimeOptions)
Local compilationNoDebugDump:String = TCompilerIrDumper.Dump(compilationNoDebug.ir)
Local compilationNoDebugDiagnostics:TCompilerDiagnostic[]
Local compilationNoDebugC:String = TBlitzMaxCompiler.EmitRuntimeC(compilationNoDebug, compilationNoDebugDiagnostics)
Check(compilationNoDebug.Succeeded() And Contains(compilationNoDebugDump, "function @main $main() -> Int [global-entry] [debug] [nodebug]") And Not Contains(compilationNoDebugDump, "debug-scope") And Contains(compilationNoDebugDump, "bounds-check dynamic-array"), "compilation NoDebug suppresses debugger scopes while retaining debug safety IR")
Check(compilationNoDebugDiagnostics.length = 0 And Not Contains(compilationNoDebugC, "bbRegisterSource(") And Not Contains(compilationNoDebugC, "BBDEBUGSCOPE_FUNCTION") And Not Contains(compilationNoDebugC, "bbOnDebugEnterStm") And Contains(compilationNoDebugC, "bbNullObjectTest((BBObject *)") And Contains(compilationNoDebugC, "bmx_debug_array_element((BBARRAY)") And Contains(compilationNoDebugC, "brl_blitz_RuntimeError("), "compilation NoDebug omits source/debugger registration while retaining null, bounds, and Assert checks")

Local debugBlocksSource:String = "SuperStrict~nFunction Scoped:Int()~nLocal total:Int=0~n#Outer~nFor Local outer:Int=0 Until 4~nLocal current:Int=outer~nWhile current>0~nLocal nested:Int=current~nIf nested=99 Then Return total~ncurrent=current-1~nIf nested=3 Then Continue Outer~nIf nested=2 Then Exit~ntotal=total+nested~nWend~nNext~nReturn total~nEnd Function~nLocal result:Int=Scoped()"
Local debugBlocks:TCompilerResult = TBlitzMaxCompiler.Compile("debug-blocks.bmx", debugBlocksSource, resolver, debugRuntimeOptions)
Local debugBlocksDump:String = TCompilerIrDumper.Dump(debugBlocks.ir)
Local debugBlocksDiagnostics:TCompilerDiagnostic[]
Local debugBlocksC:String = TBlitzMaxCompiler.EmitRuntimeC(debugBlocks, debugBlocksDiagnostics)
Local compactDebugBlocksC:String = Compact(debugBlocksC)
Check(debugBlocks.Succeeded() And Contains(debugBlocksDump, "debug-scope local-block") And Contains(debugBlocksDump, " outer:Int") And Contains(debugBlocksDump, " current:Int") And Contains(debugBlocksDump, " nested:Int"), "nested lexical scopes and loop variables retain explicit debugger ownership in typed IR")
Check(debugBlocksDiagnostics.length = 0 And AppearsBefore(debugBlocksC, "BBINT bmx_v0_total = 0;", "BBDEBUGSCOPE_FUNCTION, ~qScoped~q") And Contains(debugBlocksC, "BBDEBUGSCOPE_LOCALBLOCK") And Contains(debugBlocksC, "BBDEBUGDECL_LOCAL, ~qouter~q, ~qi~q") And Contains(debugBlocksC, "BBDEBUGDECL_LOCAL, ~qcurrent~q, ~qi~q") And Contains(debugBlocksC, "BBDEBUGDECL_LOCAL, ~qnested~q, ~qi~q"), "debug locals are safely initialized before their production-shaped function and local-block scope records")
Check(Contains(compactDebugBlocksC, "bbOnDebugLeaveScope();bbOnDebugLeaveScope();bbOnDebugLeaveScope();gotobmx_loop0_continue;") And Contains(compactDebugBlocksC, "bbOnDebugLeaveScope();bbOnDebugLeaveScope();gotobmx_loop1_exit;"), "labelled Continue and inner Exit unwind every departed debugger scope before their C labels")
Check(Contains(compactDebugBlocksC, "bbOnDebugLeaveScope();bbOnDebugLeaveScope();bbOnDebugLeaveScope();bbOnDebugLeaveScope();returnbmx_v0_total;"), "Return unwinds nested If, loop-body, and function debugger scopes before leaving the routine")

Local debugDeclarationsSource:String = "SuperStrict~nConst DebugAnswer:Int=40+2~nConst DebugLabel:String=~qready~q~nConst DebugEmpty:String=~q~q~nGlobal debugTotal:Int=DebugAnswer~nGlobal debugText:String=DebugLabel~nFunction ReadDebug:Int()~nConst Offset:Int=1~nReturn debugTotal+Offset~nEnd Function~nLocal result:Int=ReadDebug()"
Local debugDeclarations:TCompilerResult = TBlitzMaxCompiler.Compile("debug-declarations.bmx", debugDeclarationsSource, resolver, debugRuntimeOptions)
Local debugDeclarationsDump:String = TCompilerIrDumper.Dump(debugDeclarations.ir)
Local debugDeclarationsDiagnostics:TCompilerDiagnostic[]
Local debugDeclarationsC:String = TBlitzMaxCompiler.EmitRuntimeC(debugDeclarations, debugDeclarationsDiagnostics)
Check(debugDeclarations.Succeeded() And Contains(debugDeclarationsDump, "debug-constant %") And Contains(debugDeclarationsDump, " DebugAnswer:Int [value-string %") And Contains(debugDeclarationsDump, " DebugLabel:String [value-string %") And Contains(debugDeclarationsDump, " Offset:Int [value-string %") And Contains(debugDeclarationsDump, "debug-global %") And Contains(debugDeclarationsDump, " debugTotal:Int") And Contains(debugDeclarationsDump, " debugText:String"), "constants and Globals retain explicit debugger declaration kinds and folded value-string identities in typed IR")
Check(debugDeclarationsDiagnostics.length = 0 And Contains(debugDeclarationsC, "BBDEBUGDECL_CONST, ~qDebugAnswer~q, ~qi~q, .const_value = (BBString*)&bmx_string_") And Contains(debugDeclarationsC, "BBDEBUGDECL_CONST, ~qDebugLabel~q, ~q$~q, .const_value = (BBString*)&bmx_string_") And Contains(debugDeclarationsC, "BBDEBUGDECL_CONST, ~qDebugEmpty~q, ~q$~q, .const_value = &bbEmptyString") And Contains(debugDeclarationsC, "BBDEBUGDECL_CONST, ~qOffset~q, ~qi~q, .const_value = (BBString*)&bmx_string_") And Contains(debugDeclarationsC, "BBDEBUGDECL_GLOBAL, ~qdebugTotal~q, ~qi~q, .var_address = (void *)&") And Contains(debugDeclarationsC, "BBDEBUGDECL_GLOBAL, ~qdebugText~q, ~q$~q, .var_address = (void *)&"), "runtime C emits production-shaped folded constant strings and stable Global storage addresses")
Check(AppearsBefore(debugDeclarationsC, "BBDEBUGDECL_CONST, ~qDebugAnswer~q", "BBDEBUGDECL_GLOBAL, ~qdebugTotal~q") And AppearsBefore(debugDeclarationsC, "BBDEBUGDECL_GLOBAL, ~qdebugText~q", "BBDEBUGDECL_LOCAL, ~qresult~q"), "application debugger declarations retain production ordering of constants, Globals, then locals")
Local releaseDeclarations:TCompilerResult = TBlitzMaxCompiler.Compile("release-declarations.bmx", debugDeclarationsSource, resolver, TestOptions())
Local releaseDeclarationsDiagnostics:TCompilerDiagnostic[]
Local releaseDeclarationsC:String = TBlitzMaxCompiler.EmitRuntimeC(releaseDeclarations, releaseDeclarationsDiagnostics)
Check(releaseDeclarations.Succeeded() And releaseDeclarationsDiagnostics.length = 0 And Not Contains(releaseDeclarationsC, "BBDEBUGDECL_GLOBAL") And Not Contains(releaseDeclarationsC, "BBDEBUGDECL_CONST"), "release runtime C does not retain debugger-only constant or Global records")
Local threadedDebugGlobal:TCompilerResult = TBlitzMaxCompiler.Compile("threaded-debug-global.bmx", "SuperStrict~nThreadedGlobal current:Int", resolver, debugRuntimeOptions)
Local threadedDebugGlobalDiagnostics:TCompilerDiagnostic[]
Local threadedDebugGlobalC:String = TBlitzMaxCompiler.EmitRuntimeC(threadedDebugGlobal, threadedDebugGlobalDiagnostics)
Check(threadedDebugGlobal.Succeeded() And threadedDebugGlobalDiagnostics.length = 0 And Contains(TCompilerIrDumper.Dump(threadedDebugGlobal.ir), "[threaded]"), "debug application ThreadedGlobal remains explicit typed TLS storage")
Check(Contains(threadedDebugGlobalC, "static BBThreadLocal BBINT") And Contains(threadedDebugGlobalC, "BBDEBUGDECL_GLOBAL, ~qcurrent~q") And Contains(threadedDebugGlobalC, ".var_address = (void *)&"), "debug application scope resolves its ThreadedGlobal address on the executing thread")

Local debugAssertSource:String = "SuperStrict~nGlobal assertionChecks:Int~nFunction CheckAssertion:Int(value:Int)~nassertionChecks=assertionChecks+1~nReturn value~nEnd Function~nFunction AssertionMessage:String()~nassertionChecks=assertionChecks+100~nReturn ~qlazy failure~q~nEnd Function~nAssert CheckAssertion(1), AssertionMessage()~nAssert 1 Else 7~nAssert 1~nAssert ~qpresent~q~nLocal result:Int=assertionChecks"
Local debugAssert:TCompilerResult = TBlitzMaxCompiler.Compile("debug-assert.bmx", debugAssertSource, resolver, debugRuntimeOptions)
Local debugAssertDump:String = TCompilerIrDumper.Dump(debugAssert.ir)
Local debugAssertDiagnostics:TCompilerDiagnostic[]
Local debugAssertC:String = TBlitzMaxCompiler.EmitRuntimeC(debugAssert, debugAssertDiagnostics)
Check(debugAssert.Succeeded() And Contains(debugAssertDump, "assert @debug-assert.bmx:") And Contains(debugAssertDump, "failure-message") And Contains(debugAssertDump, "~qAssert failed~q"), "debug assertions retain condition, lazy failure message, default message and source provenance in typed IR")
Check(debugAssertDiagnostics.length = 0 And Contains(debugAssertC, "if (!(bmx_fn0_CheckAssertion(1))) {") And Contains(debugAssertC, "brl_blitz_RuntimeError(bmx_fn1_AssertionMessage());") And Contains(debugAssertC, "brl_blitz_RuntimeError(bbStringFromInt(7));") And Contains(debugAssertC, "brl_blitz_RuntimeError((BBString*)&bmx_string_") And Contains(debugAssertC, " != &bbEmptyString") And AppearsBefore(debugAssertC, "bbOnDebugEnterStm(", "if (!(bmx_fn0_CheckAssertion(1)))"), "runtime C emits source callback, managed-sentinel truth, single condition evaluation, lazy message evaluation and production RuntimeError ABI")
Local nativeDebugAssert:TCompilerResult = TBlitzMaxCompiler.Compile("native-debug-assert.bmx", "SuperStrict~nExtern~nFunction NativeTruth:Int(value:Byte Ptr)=~qbcc2_native_truth~q~nEnd Extern~nLocal value:String=~qpresent~q~nAssert NativeTruth(value)", resolver, debugRuntimeOptions)
Local nativeDebugAssertDiagnostics:TCompilerDiagnostic[]
Local nativeDebugAssertC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeDebugAssert, nativeDebugAssertDiagnostics)
Check(nativeDebugAssert.Succeeded() And nativeDebugAssertDiagnostics.length = 0 And Occurrences(nativeDebugAssertC, "bbStringToCString(") = 1 And Occurrences(nativeDebugAssertC, "bbMemFree(bmx_native_string_") = 1 And AppearsBefore(nativeDebugAssertC, "bbMemFree(bmx_native_string_0);", "if (!(bmx_native_condition_"), "Assert materializes its truth result and frees the implicit native String before branching")
Local releaseAssert:TCompilerResult = TBlitzMaxCompiler.Compile("release-assert.bmx", debugAssertSource, resolver, TestOptions())
Local releaseAssertDump:String = TCompilerIrDumper.Dump(releaseAssert.ir)
Local releaseAssertDiagnostics:TCompilerDiagnostic[]
Local releaseAssertC:String = TBlitzMaxCompiler.EmitRuntimeC(releaseAssert, releaseAssertDiagnostics)
Check(releaseAssert.Succeeded() And releaseAssertDiagnostics.length = 0 And Not Contains(releaseAssertDump, "assert release-assert.bmx") And Not Contains(releaseAssertC, "brl_blitz_RuntimeError(") And Not Contains(releaseAssertC, "bmx_fn0_CheckAssertion(1)"), "release assertions omit both condition and message evaluation like production bcc")
Local unsupportedAssertCondition:TCompilerResult = TBlitzMaxCompiler.Compile("unsupported-assert-condition.bmx", "SuperStrict~nStruct SFlag~nEnd Struct~nLocal flag:SFlag~nAssert flag", resolver, debugRuntimeOptions)
Check(Not unsupportedAssertCondition.Succeeded() And HasCompilerDiagnostic(unsupportedAssertCondition, "BMXC1204"), "non-truth-convertible Assert conditions remain an explicit lowering diagnostic")
Local unsupportedAssertMessage:TCompilerResult = TBlitzMaxCompiler.Compile("unsupported-assert-message.bmx", "SuperStrict~nStruct SMessage~nEnd Struct~nLocal message:SMessage~nAssert 0, message", resolver, debugRuntimeOptions)
Check(Not unsupportedAssertMessage.Succeeded() And HasCompilerDiagnostic(unsupportedAssertMessage, "BMXC1205"), "Assert message conversions outside the current String IR remain explicit")

Local reflectionAssignmentsSource:String = "SuperStrict~nEnum EReflectionFlags~nNone=0~nPublicValue=1~nPrivateValue=2~nEnd Enum~nType TReflectionBucket~nField values:Int[]~nMethod Add(value:Int)~nvalues :+ [value]~nEnd Method~nEnd Type~nType TReflectionRoot~nField bucket:TReflectionBucket=New TReflectionBucket~nEnd Type~nLocal flags:EReflectionFlags~nflags :| EReflectionFlags.PublicValue~nLocal isPublic:Int=(flags & EReflectionFlags.PublicValue)<>Null~nLocal bucket:TReflectionBucket=New TReflectionBucket~nbucket.Add(42)~nLocal root:TReflectionRoot=New TReflectionRoot~nroot.bucket.values :+ [7]"
Local reflectionAssignments:TCompilerResult = TBlitzMaxCompiler.Compile("reflection-assignments.bmx", reflectionAssignmentsSource, resolver, TestOptions())
Local reflectionAssignmentsDiagnostics:TCompilerDiagnostic[]
Local reflectionAssignmentsC:String = TBlitzMaxCompiler.EmitRuntimeC(reflectionAssignments, reflectionAssignmentsDiagnostics)
Check(reflectionAssignments.Succeeded() And reflectionAssignmentsDiagnostics.length = 0, "Reflection-style Enum flags, scalar Null defaults, and stable field-chain array append lower without compatibility source")
Check(Contains(reflectionAssignmentsC, " |= ") And Contains(reflectionAssignmentsC, " != 0") And Occurrences(reflectionAssignmentsC, "bbArrayConcat(~qi~q") = 2, "runtime C preserves Enum bit flags and lowers heap-array :+ through the array runtime")

Local legacyNativePrototypeSource:String = "SuperStrict~nExtern~nFunction NativeNew:Object(class:Byte Ptr)=~qBBObject* bbObjectNew(BBClass*)!~q~nEnd Extern~nLocal value:Object=NativeNew(Null)"
Local legacyNativePrototype:TCompilerResult = TBlitzMaxCompiler.Compile("legacy-native-prototype.bmx", legacyNativePrototypeSource, resolver, TestOptions())
Local legacyNativePrototypeDiagnostics:TCompilerDiagnostic[]
Local legacyNativePrototypeC:String = TBlitzMaxCompiler.EmitRuntimeC(legacyNativePrototype, legacyNativePrototypeDiagnostics)
Check(legacyNativePrototype.Succeeded() And legacyNativePrototypeDiagnostics.length = 0 And Contains(legacyNativePrototypeC, "bbObjectNew(") And Not Contains(legacyNativePrototypeC, "extern BBObject* bbObjectNew(BBClass*);") And Not Contains(legacyNativePrototypeC, "BBObject* bbObjectNew(BBClass*)!") And Not Contains(legacyNativePrototypeC, "extern BBOBJECT bbObjectNew(BBBYTE *"), "a bang-marked native declaration retains typedef-rich call authority while suppressing its header-owned prototype")

Local nativeHeaderOwner:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nativeheader.mod/nativeheader.bmx", "SuperStrict~nModule acme.nativeheader~nImport ~qnative_api.h~q~nImport ~qvendor/include/*.h~q~nExtern~nFunction NativeValue:Int()=~qint acme_native_value(void)!~q~nEnd Extern", resolver, TestOptions())
Local nativeHeaderOwnerDiagnostics:TCompilerDiagnostic[]
Local nativeHeaderOwnerHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(nativeHeaderOwner, nativeHeaderOwnerDiagnostics)
Local nativeHeaderOwnerC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeHeaderOwner, nativeHeaderOwnerDiagnostics)
Check(nativeHeaderOwner.Succeeded() And nativeHeaderOwnerDiagnostics.length = 0 And Contains(nativeHeaderOwnerHeader, "#include ~q../native_api.h~q") And Contains(nativeHeaderOwnerC, "#include ~q../native_api.h~q") And Not Contains(nativeHeaderOwnerHeader, "*.h") And Not Contains(nativeHeaderOwnerC, "*.h") And Not Contains(nativeHeaderOwnerHeader, "acme_native_value(void);") And Not Contains(nativeHeaderOwnerC, "acme_native_value(void);"), "a module's generated header and implementation carry concrete native-header imports, leave wildcard build inputs to bmk, and keep bang-marked declarations header-owned")

Local nativeCallableGlobal:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nativeglobal.mod/nativeglobal.bmx", "SuperStrict~nModule acme.nativeglobal~nImport ~qnative_api.h~q~nExtern ~qC~q~nGlobal NativeCallback:Int(value:Int)=~qint __native_callback(int)!~q~nEnd Extern~nFunction Invoke:Int()~nReturn NativeCallback(7)~nEnd Function", resolver, TestOptions())
Local nativeCallableGlobalDiagnostics:TCompilerDiagnostic[]
Local nativeCallableGlobalC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeCallableGlobal, nativeCallableGlobalDiagnostics)
Check(nativeCallableGlobal.Succeeded() And nativeCallableGlobalDiagnostics.length = 0 And Contains(nativeCallableGlobalC, "(__native_callback)(7)") And Not Contains(nativeCallableGlobalC, "extern BBINT (*__native_callback)") And Not Contains(nativeCallableGlobalC, "int __native_callback(int)!"), "bang-marked callable Globals use their parsed linker identity while retaining native-header declaration authority")

Local sequencedNativeCallableSource:String = "SuperStrict~nModule acme.nativecallsequence~nImport ~qnative_api.h~q~nExtern~nGlobal NativeCallback(first:Int,second:Int)=~qvoid __native_callback(NativeA, NativeB)!~q~nEnd Extern~nFunction NextValue:Int()~nReturn 2~nEnd Function~nNativeCallback(1,NextValue())"
Local sequencedNativeCallable:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nativecallsequence.mod/nativecallsequence.bmx", sequencedNativeCallableSource, resolver, TestOptions())
Local sequencedNativeCallableDump:String = TCompilerIrDumper.Dump(sequencedNativeCallable.ir)
Local sequencedNativeCallableDiagnostics:TCompilerDiagnostic[]
Local sequencedNativeCallableC:String = TBlitzMaxCompiler.EmitRuntimeC(sequencedNativeCallable, sequencedNativeCallableDiagnostics)
Check(sequencedNativeCallable.Succeeded() And Contains(sequencedNativeCallableDump, "[native-callable __native_callback]"), "sequenced header-owned callable materialization retains its native ABI authority in typed IR")
Check(sequencedNativeCallableDiagnostics.length = 0 And Contains(sequencedNativeCallableC, "__typeof__(__native_callback) bmx_tmp_t0;") And Contains(sequencedNativeCallableC, "((bmx_tmp_t0 = __native_callback),") And Not Contains(sequencedNativeCallableC, "BBINT (*bmx_tmp_t0)(BBINT, BBINT)"), "runtime C derives a sequenced header-owned callable temporary from the imported native symbol")

resolver.AddInterface("acme.nativecallowner", "/sdk/mod/acme.mod/nativecallowner.mod/nativecallowner.release.test.x64.i", "superstrict~nNativeCallback%(first%,second%)&=mem:p(~q__native_callback~q)")
Local importedSequencedNativeCallable:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nativecallconsumer.mod/nativecallconsumer.bmx", "SuperStrict~nModule acme.nativecallconsumer~nImport acme.nativecallowner~nFunction NextValue:Int()~nReturn 2~nEnd Function~nNativeCallback(1,NextValue())", resolver, TestOptions())
Local importedSequencedNativeCallableDiagnostics:TCompilerDiagnostic[]
Local importedSequencedNativeCallableC:String = TBlitzMaxCompiler.EmitRuntimeC(importedSequencedNativeCallable, importedSequencedNativeCallableDiagnostics)
Check(importedSequencedNativeCallable.Succeeded() And importedSequencedNativeCallableDiagnostics.length = 0 And Contains(TCompilerIrDumper.Dump(importedSequencedNativeCallable.ir), "[native-callable __native_callback]") And Contains(importedSequencedNativeCallableC, "__typeof__(__native_callback) bmx_tmp_t0;") And Not Contains(importedSequencedNativeCallableC, "BBINT (*bmx_tmp_t0)(BBINT, BBINT)"), "compact-interface callable Globals retain header-owned native temporary authority without the producer declaration text")

Local nativeCallableAssignment:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/nativecallback.mod/nativecallback.bmx", "SuperStrict~nModule acme.nativecallback~nImport ~qnative_api.h~q~nExtern~nGlobal NativeCallback(value:Int Ptr)=~qvoid __native_callback(BBDebugStm *)!~q~nEnd Extern~nFunction Replacement(value:Int Ptr)~nEnd Function~nNativeCallback=Replacement", resolver, TestOptions())
Local nativeCallableAssignmentDiagnostics:TCompilerDiagnostic[]
Local nativeCallableAssignmentC:String = TBlitzMaxCompiler.EmitRuntimeC(nativeCallableAssignment, nativeCallableAssignmentDiagnostics)
Check(nativeCallableAssignment.Succeeded() And nativeCallableAssignmentDiagnostics.length = 0 And Contains(nativeCallableAssignmentC, "__native_callback = (void (*)(BBDebugStm *))") And Not Contains(nativeCallableAssignmentC, "extern void (*__native_callback)"), "header-owned callable Global assignment retains its typedef-rich native function-pointer ABI cast")

Local literalStringElement:TCompilerResult = TBlitzMaxCompiler.Compile("literal-string-element.bmx", "SuperStrict~nLocal value:Int=~qABC~q[1]", resolver, TestOptions())
Local literalStringElementDiagnostics:TCompilerDiagnostic[]
Local literalStringElementC:String = TBlitzMaxCompiler.EmitRuntimeC(literalStringElement, literalStringElementDiagnostics)
Check(literalStringElement.Succeeded() And literalStringElementDiagnostics.length = 0 And Contains(literalStringElementC, "((BBString*)&bmx_string_") And Contains(literalStringElementC, ")->buf[(BBUINT)1]"), "String-literal indexing parenthesizes the cast receiver before selecting its UTF-16 buffer")

Local builtinPointerCastTarget:TCompilerResult = TBlitzMaxCompiler.Compile("builtin-pointer-cast-target.bmx", "SuperStrict~nStruct SPacked~nField b:Byte~nMethod Set(value:Int)~nInt Ptr(Varptr b)[0]=value~nEnd Method~nMethod Get:Int()~nReturn Int Ptr(Varptr b)[0]~nEnd Method~nEnd Struct~nLocal packed:SPacked~npacked.Set(42)~nLocal result:Int=packed.Get()", resolver, TestOptions())
Local builtinPointerCastTargetDiagnostics:TCompilerDiagnostic[]
Local builtinPointerCastTargetC:String = TBlitzMaxCompiler.EmitRuntimeC(builtinPointerCastTarget, builtinPointerCastTargetDiagnostics)
Check(builtinPointerCastTarget.Succeeded() And builtinPointerCastTargetDiagnostics.length = 0 And Contains(builtinPointerCastTargetC, "((BBINT *)") And Contains(builtinPointerCastTargetC, ")[0]) = bmx_p0_value;"), "builtin pointer-cast/index assignment targets lower as typed pointer lvalues")

Local typeStaticGlobalsSource:String = "SuperStrict~nModule acme.typestatics~nType TAlpha~nGlobal Shared:Int=40~nFunction Read:Int()~nReturn Shared~nEnd Function~nEnd Type~nType TBeta~nGlobal Shared:Int=2~nFunction Read:Int()~nReturn Shared~nEnd Function~nEnd Type~nLocal result:Int=TAlpha.Read()+TBeta.Read()"
Local typeStaticGlobals:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/typestatics.mod/typestatics.bmx", typeStaticGlobalsSource, resolver, TestOptions())
Local typeStaticGlobalsDiagnostics:TCompilerDiagnostic[]
Local typeStaticGlobalsC:String = TBlitzMaxCompiler.EmitRuntimeC(typeStaticGlobals, typeStaticGlobalsDiagnostics)
Check(typeStaticGlobals.Succeeded() And typeStaticGlobalsDiagnostics.length = 0, "Type-owned static Globals are registered before Type-function body lowering")
Check(Contains(typeStaticGlobalsC, "acme_typestatics_TAlpha_Shared") And Contains(typeStaticGlobalsC, "acme_typestatics_TBeta_Shared"), "same-named Type Globals receive distinct deterministic owner-qualified ABI identities")

Local directTypeStaticAssignment:TCompilerResult = TBlitzMaxCompiler.Compile("direct-type-static-assignment.bmx", "SuperStrict~nType TClock~nGlobal Started:Long~nFunction Now:Long()~nReturn 42~nEnd Function~nEnd Type~nTClock.Started=TClock.Now()", resolver, TestOptions())
Local directTypeStaticAssignmentDiagnostics:TCompilerDiagnostic[]
Local directTypeStaticAssignmentC:String = TBlitzMaxCompiler.EmitRuntimeC(directTypeStaticAssignment, directTypeStaticAssignmentDiagnostics)
Check(directTypeStaticAssignment.Succeeded() And directTypeStaticAssignmentDiagnostics.length = 0 And directTypeStaticAssignmentC.length > 0, "module initialization can assign Type-owned static storage")

Local threadedTypeGlobal:TCompilerResult = TBlitzMaxCompiler.Compile("threaded-type-global.bmx", "SuperStrict~nType TThreadContext~nEnd Type~nType TThreadState~nThreadedGlobal context:TThreadContext~nFunction Set(value:TThreadContext)~ncontext=value~nEnd Function~nFunction Get:TThreadContext()~nReturn context~nEnd Function~nEnd Type~nTThreadState.Set(New TThreadContext)~nLocal current:TThreadContext=TThreadState.Get()", resolver, TestOptions())
Local threadedTypeGlobalDiagnostics:TCompilerDiagnostic[]
Local threadedTypeGlobalC:String = TBlitzMaxCompiler.EmitRuntimeC(threadedTypeGlobal, threadedTypeGlobalDiagnostics)
Check(threadedTypeGlobal.Succeeded() And Contains(TCompilerIrDumper.Dump(threadedTypeGlobal.ir), "context:TThreadContext") And Contains(TCompilerIrDumper.Dump(threadedTypeGlobal.ir), "[threaded]"), "a release ThreadedGlobal is retained as Type-owned per-thread storage IR")
Check(threadedTypeGlobalDiagnostics.length = 0 And Contains(threadedTypeGlobalC, "static BBThreadLocal struct bmx_cls0_TThreadContext_obj *") And Contains(threadedTypeGlobalC, ".var_address = 0") And Contains(threadedTypeGlobalC, ".decls[0].var_address = (void *)&") And Contains(threadedTypeGlobalC, "GC_add_roots(&bmx_global_"), "runtime C emits BBThreadLocal storage and registers the current thread's slot as a managed root while refreshing its reflected address")
Local debugThreadedOptions:TCompilerOptions = DebugTestOptions()
debugThreadedOptions.debugInstrumentation = True
Local debugThreadedTypeGlobal:TCompilerResult = TBlitzMaxCompiler.Compile("debug-threaded-type-global.bmx", "SuperStrict~nType TThreadState~nThreadedGlobal value:Int~nEnd Type", resolver, debugThreadedOptions)
Local debugThreadedTypeGlobalDiagnostics:TCompilerDiagnostic[]
Local debugThreadedTypeGlobalC:String = TBlitzMaxCompiler.EmitRuntimeC(debugThreadedTypeGlobal, debugThreadedTypeGlobalDiagnostics)
Check(debugThreadedTypeGlobal.Succeeded() And debugThreadedTypeGlobalDiagnostics.length = 0 And Contains(debugThreadedTypeGlobalC, ".var_address = 0") And Contains(debugThreadedTypeGlobalC, ".decls[0].var_address = (void *)&"), "debug Type ThreadedGlobal uses a static-safe reflected declaration and runtime current-thread address refresh")

Local typeStaticInitializationOrder:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/staticorder.mod/staticorder.bmx", "SuperStrict~nModule acme.staticorder~nType TSettings~nGlobal Value:Int=42~nFunction Read:Int()~nReturn Value~nEnd Function~nEnd Type~nGlobal Observed:Int=TSettings.Read()", resolver, TestOptions())
Local typeStaticInitializationOrderDiagnostics:TCompilerDiagnostic[]
Local typeStaticInitializationOrderC:String = TBlitzMaxCompiler.EmitRuntimeC(typeStaticInitializationOrder, typeStaticInitializationOrderDiagnostics)
Check(typeStaticInitializationOrder.Succeeded() And typeStaticInitializationOrderDiagnostics.length = 0 And AppearsBefore(typeStaticInitializationOrderC, "acme_staticorder_TSettings_Value = 42;", "acme_staticorder_Observed = acme_staticorder_TSettings_Read();"), "Type-owned static state initializes before module Globals that consume it")

Local nestedTypeSource:String = "SuperStrict~nType TOuter~nType TInner~nField Value:Int=42~nMethod Read:Int()~nReturn Value~nEnd Method~nEnd Type~nMethod Create:TInner()~nReturn New TInner~nEnd Method~nEnd Type~nLocal outer:TOuter=New TOuter~nLocal inner:TOuter.TInner=outer.Create()~nLocal result:Int=inner.Read()"
Local nestedType:TCompilerResult = TBlitzMaxCompiler.Compile("nested-type.bmx", nestedTypeSource, resolver, TestOptions())
Local nestedTypeDump:String = TCompilerIrDumper.Dump(nestedType.ir)
Local nestedTypeDiagnostics:TCompilerDiagnostic[]
Local nestedTypeC:String = TBlitzMaxCompiler.EmitRuntimeC(nestedType, nestedTypeDiagnostics)
Check(nestedType.Succeeded() And nestedTypeDiagnostics.length = 0 And Contains(nestedTypeDump, "class @cls0 TOuter:TOuter") And Contains(nestedTypeDump, "class @cls1 TInner:TOuter.TInner") And Contains(nestedTypeDump, "object-new @cls1"), "a nested Type receives its own class identity, layout, routines and construction IR")
Check(Contains(nestedTypeC, "struct bmx_cls1_TInner_obj") And Contains(nestedTypeC, "BBINT bmx_fn1_Read(") And Contains(nestedTypeC, "o->bmx_field_f0_Value = 42;"), "runtime C emits the nested Type implementation and field initializer instead of leaving its bound New expression unresolved")

Local callableStorageAddressSource:String = "SuperStrict~nFunction ConsumeStorage(value:Byte Ptr)~nEnd Function~nLocal callback()~nConsumeStorage(Varptr callback)"
Local callableStorageAddress:TCompilerResult = TBlitzMaxCompiler.Compile("callable-storage-address.bmx", callableStorageAddressSource, resolver, TestOptions())
Local callableStorageAddressDiagnostics:TCompilerDiagnostic[]
Local callableStorageAddressC:String = TBlitzMaxCompiler.EmitRuntimeC(callableStorageAddress, callableStorageAddressDiagnostics)
Check(callableStorageAddress.Succeeded() And callableStorageAddressDiagnostics.length = 0 And Contains(callableStorageAddressC, "&bmx_v0_callback"), "typed IR preserves Varptr of a callable storage cell as an address before raw Byte Ptr conversion")

Local debugBoundsSource:String = "SuperStrict~nFunction NextIndex:Int(index:Int Var)~nLocal result:Int=index~nindex=index+1~nReturn result~nEnd Function~nLocal values:Int[]=[20,22]~nLocal dynamicIndex:Int~nLocal dynamicValue:Int=values[NextIndex(dynamicIndex)]~nvalues[NextIndex(dynamicIndex)]=21~nLocal StaticArray fixed:Int[2]~nLocal fixedIndex:Int~nLocal fixedValue:Int=fixed[NextIndex(fixedIndex)]~nfixed[NextIndex(fixedIndex)]=2"
Local debugBounds:TCompilerResult = TBlitzMaxCompiler.Compile("debug-bounds.bmx", debugBoundsSource, resolver, debugRuntimeOptions)
Local debugBoundsDump:String = TCompilerIrDumper.Dump(debugBounds.ir)
Local debugBoundsDiagnostics:TCompilerDiagnostic[]
Local debugBoundsC:String = TBlitzMaxCompiler.EmitRuntimeC(debugBounds, debugBoundsDiagnostics)
Check(debugBounds.Succeeded() And Contains(debugBoundsDump, "bounds-check dynamic-array") And Contains(debugBoundsDump, "bounds-check static-array length 2"), "debug bounds requirements and fixed extents remain explicit typed IR operations")
Check(debugBoundsDiagnostics.length = 0 And Contains(debugBoundsC, "bbArrayIndex(array, 1, index)") And Contains(debugBoundsC, "brl_blitz_ArrayBoundsError()") And Contains(debugBoundsC, "bmx_debug_array_element((BBARRAY)") And Contains(debugBoundsC, "bmx_debug_static_array_element((void *)") And Contains(debugBoundsC, "(*((BBINT *)bmx_debug_array_element") And Contains(debugBoundsC, "(*((BBINT *)bmx_debug_static_array_element"), "debug reads and assignment lvalues use single-evaluation dynamic and StaticArray bounds helpers")
Local releaseBounds:TCompilerResult = TBlitzMaxCompiler.Compile("release-bounds.bmx", debugBoundsSource, resolver, TestOptions())
Local releaseBoundsDump:String = TCompilerIrDumper.Dump(releaseBounds.ir)
Local releaseBoundsDiagnostics:TCompilerDiagnostic[]
Local releaseBoundsC:String = TBlitzMaxCompiler.EmitRuntimeC(releaseBounds, releaseBoundsDiagnostics)
Check(releaseBounds.Succeeded() And releaseBoundsDiagnostics.length = 0 And Not Contains(releaseBoundsDump, "bounds-check ") And Not Contains(releaseBoundsC, "bmx_debug_array_element") And Contains(releaseBoundsC, "BBARRAYDATA("), "release IR and runtime C preserve unchecked production-shaped array indexing")

Local debugCoverageOptions:TCompilerOptions = DebugTestOptions()
debugCoverageOptions.debugInstrumentation = True
debugCoverageOptions.coverageInstrumentation = True
Local debugCoverageSource:String = "SuperStrict~nFunction Covered:Int(value:Int)~nIf value Then Return 1~nReturn 2~nEnd Function~nLocal hit:Int=Covered(True)"
Local debugCoverage:TCompilerResult = TBlitzMaxCompiler.Compile("debug-coverage.bmx", debugCoverageSource, resolver, debugCoverageOptions)
Local debugCoverageDump:String = TCompilerIrDumper.Dump(debugCoverage.ir)
Local debugCoverageDiagnostics:TCompilerDiagnostic[]
Local debugCoverageC:String = TBlitzMaxCompiler.EmitRuntimeC(debugCoverage, debugCoverageDiagnostics)
Check(Contains(debugCoverageDump, "coverage-file ~qdebug-coverage.bmx~q") And Contains(debugCoverageDump, "coverage-line 3") And Contains(debugCoverageDump, "coverage-line 4") And Contains(debugCoverageDump, "coverage-line 6") And Contains(debugCoverageDump, "coverage-function 2 ~qCovered~q"), "ordinary source lines and function entries have an explicit typed IR coverage catalogue")
Check(debugCoverageDiagnostics.length = 0 And Contains(debugCoverageC, "static BBCoverageFileInfo bmx_coverage_files[]") And Contains(debugCoverageC, "bbCoverageRegisterFile(bmx_coverage_files)") And Contains(debugCoverageC, "bbCoverageUpdateFunctionLineInfo(~qdebug-coverage.bmx~q, ~qCovered~q, 2)") And Contains(debugCoverageC, "bbCoverageUpdateLineInfo(~qdebug-coverage.bmx~q, 6)"), "runtime C emits and registers the ordinary coverage catalogue and probes")

Local applicationEnd:TCompilerResult = TBlitzMaxCompiler.Compile("application-end.bmx", "SuperStrict~nFunction StopNow()~nEnd~nEnd Function~nStopNow()", resolver, TestOptions())
Local applicationEndDiagnostics:TCompilerDiagnostic[]
Local applicationEndDump:String = TCompilerIrDumper.Dump(applicationEnd.ir)
Local applicationEndC:String = TBlitzMaxCompiler.EmitRuntimeC(applicationEnd, applicationEndDiagnostics)
Check(applicationEnd.Succeeded(), "ordinary End statements compile as a supported terminal application operation")
Check(applicationEndDiagnostics.length = 0, "ordinary End statements emit runtime C without diagnostics")
Check(Contains(applicationEndDump, "application-end "), "ordinary End statements remain explicit in typed IR")
Check(Contains(applicationEndC, "bbEnd();"), "runtime C lowers End through the BlitzMax application termination ABI")

Local functionLiteralSource:String = "SuperStrict~nLocal add:Int(value:Int) = Function(value)~nReturn value + 1~nEnd Function~nLocal answer:Int = add(41)"
Local functionLiteralResult:TCompilerResult = TBlitzMaxCompiler.Compile("function-literal-ir.bmx", functionLiteralSource, resolver, TestOptions())
Local functionLiteralDiagnostics:TCompilerDiagnostic[]
Local functionLiteralC:String = TBlitzMaxCompiler.EmitRuntimeC(functionLiteralResult, functionLiteralDiagnostics)
Local synthesizedFunction:TCompilerIrFunction
For Local candidate:TCompilerIrFunction = EachIn functionLiteralResult.ir.functions
	If candidate.name = "<Function>" Then synthesizedFunction = candidate; Exit
Next
Check(functionLiteralResult.Succeeded() And functionLiteralDiagnostics.length = 0 And synthesizedFunction And synthesizedFunction.parameters.length = 1 And synthesizedFunction.returnType = "Int", "non-capturing Function literal lowers to a private typed-IR function")
Check(Contains(functionLiteralC, synthesizedFunction.abiName) And Contains(functionLiteralC, "bmx_v0_add") And Contains(functionLiteralC, "(41)"), "runtime C stores and invokes the synthesized Function literal through the existing thin-callable ABI")
Local functionLiteralCoverage:TCompilerResult = TBlitzMaxCompiler.Compile("function-literal-coverage.bmx", functionLiteralSource, resolver, debugCoverageOptions)
Local functionLiteralCoverageDiagnostics:TCompilerDiagnostic[]
Local functionLiteralCoverageDump:String = TCompilerIrDumper.Dump(functionLiteralCoverage.ir)
Local functionLiteralCoverageC:String = TBlitzMaxCompiler.EmitRuntimeC(functionLiteralCoverage, functionLiteralCoverageDiagnostics)
Check(functionLiteralCoverageDiagnostics.length = 0 And Contains(functionLiteralCoverageDump, "coverage-function 2 ~qFunction in module initialization at line 2 column ") And Contains(functionLiteralCoverageDump, "coverage-line 3") And Contains(functionLiteralCoverageC, "bbCoverageUpdateFunctionLineInfo(~qfunction-literal-coverage.bmx~q, ~qFunction in module initialization at line 2 column ") And Contains(functionLiteralCoverageC, "bbCoverageUpdateLineInfo(~qfunction-literal-coverage.bmx~q, 3)"), "thin Function literals have deterministic source-facing entry names and body probes")

Local genericFunctionLiteral:TCompilerResult = TBlitzMaxCompiler.Compile("generic-function-literal.bmx", "SuperStrict~nFunction Identity<T>:T(value:T)()~nReturn Function(value:T)~nReturn value~nEnd Function~nEnd Function~nLocal callback:Int(value:Int) = Identity<Int>()~nLocal answer:Int = callback(42)", resolver, TestOptions())
Local genericFunctionLiteralDiagnostics:TCompilerDiagnostic[]
Local genericFunctionLiteralC:String = TBlitzMaxCompiler.EmitRuntimeC(genericFunctionLiteral, genericFunctionLiteralDiagnostics)
Check(genericFunctionLiteral.Succeeded() And genericFunctionLiteralDiagnostics.length = 0 And genericFunctionLiteral.genericPlan.units.length = 1, "non-capturing thin Function literals specialize inside generic declarations: " + CompilerDiagnosticSummary(genericFunctionLiteral))
Check(Contains(genericFunctionLiteral.genericPlan.units[0].implementation, "_function_") And Contains(genericFunctionLiteral.genericPlan.units[0].implementation, "return value;") And Not Contains(genericFunctionLiteral.genericPlan.units[0].implementation, "static BBClosure") And Contains(genericFunctionLiteralC, "(42)"), "generic thin literals emit a typed private function pointer without managed Closure storage")
Local genericRoutineReference:TCompilerResult = TBlitzMaxCompiler.Compile("generic-routine-reference-ir.bmx", "SuperStrict~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nLocal callback:Int(value:Int)=Identity<Int>~nLocal answer:Int=callback(42)", resolver, TestOptions())
Local genericRoutineReferenceDiagnostics:TCompilerDiagnostic[]
Local genericRoutineReferenceC:String = TBlitzMaxCompiler.EmitRuntimeC(genericRoutineReference, genericRoutineReferenceDiagnostics)
Check(genericRoutineReference.Succeeded() And genericRoutineReferenceDiagnostics.length = 0 And genericRoutineReference.genericPlan.units.length = 1, "an explicit generic routine reference requests one closed specialization: " + CompilerDiagnosticSummary(genericRoutineReference))
Local genericRoutineReferenceAbi:String = genericRoutineReference.genericPlan.units[0].specialization.readableAbiName
Check(Contains(genericRoutineReferenceC, "= " + genericRoutineReferenceAbi) And Contains(genericRoutineReferenceC, "(42)"), "an explicit generic routine reference lowers to the specialized thin-function entry point")
Local nestedGenericRoutineReference:TCompilerResult = TBlitzMaxCompiler.Compile("nested-generic-routine-reference-ir.bmx", "SuperStrict~nType TPair<K,V>~nField first:K~nField second:V~nEnd Type~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nLocal callback:TPair<String,Closure<Int()>>(value:TPair<String,Closure<Int()>>)=Identity<TPair<String,Closure<Int()>>>", resolver, TestOptions())
Check(nestedGenericRoutineReference.Succeeded() And nestedGenericRoutineReference.genericPlan.units.length = 2, "nested multi-argument and callable Types remain inside a specialized routine-reference declaration and signature: " + CompilerDiagnosticSummary(nestedGenericRoutineReference))
Local closureGenericRoutineReference:TCompilerResult = TBlitzMaxCompiler.Compile("closure-generic-routine-reference-ir.bmx", "SuperStrict~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nLocal callback:Closure<Int()>(value:Closure<Int()>)=Identity<Closure<Int()>>", resolver, TestOptions())
Check(closureGenericRoutineReference.Succeeded() And closureGenericRoutineReference.genericPlan.units.length = 1, "a Closure-valued thin callable declaration retains its outer parameter signature around a specialized routine reference: " + CompilerDiagnosticSummary(closureGenericRoutineReference))
Local transitiveGenericRoutineReference:TCompilerResult = TBlitzMaxCompiler.Compile("transitive-generic-routine-reference-ir.bmx", "SuperStrict~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nFunction ApplyIdentity<T>:T(value:T)~nLocal callback:T(value:T)=Identity<T>~nReturn callback(value)~nEnd Function~nLocal answer:Int=ApplyIdentity<Int>(42)", resolver, TestOptions())
Local transitiveGenericRoutineReferenceDiagnostics:TCompilerDiagnostic[]
Local transitiveGenericRoutineReferenceC:String = TBlitzMaxCompiler.EmitRuntimeC(transitiveGenericRoutineReference, transitiveGenericRoutineReferenceDiagnostics)
Check(transitiveGenericRoutineReference.Succeeded() And transitiveGenericRoutineReferenceDiagnostics.length = 0 And transitiveGenericRoutineReference.genericPlan.units.length = 2, "a generic routine reference inside another generic body creates a closed transitive specialization edge: " + CompilerDiagnosticSummary(transitiveGenericRoutineReference))
Check(Not Contains(transitiveGenericRoutineReferenceC, "bmx_generic_dependency_identity") And Contains(transitiveGenericRoutineReferenceC, "ApplyIdentity"), "a transitive generic routine reference emits the closed specialization rather than an unresolved ordinary dependency")
Local genericMemberRoutineReference:TCompilerResult = TBlitzMaxCompiler.Compile("generic-member-routine-reference-ir.bmx", "SuperStrict~nType TFunctions<T>~nFunction Identity<U>:U(value:U)~nReturn value~nEnd Function~nEnd Type~nLocal callback:String(value:String)=TFunctions<Int>.Identity<String>~nLocal answer:String=callback(~qmember~q)", resolver, TestOptions())
Local genericMemberRoutineReferenceDiagnostics:TCompilerDiagnostic[]
Local genericMemberRoutineReferenceC:String = TBlitzMaxCompiler.EmitRuntimeC(genericMemberRoutineReference, genericMemberRoutineReferenceDiagnostics)
Check(genericMemberRoutineReference.Succeeded() And genericMemberRoutineReferenceDiagnostics.length = 0 And genericMemberRoutineReference.genericPlan.units.length >= 1, "generic routine and containing-Type arguments compose in a callable reference: " + CompilerDiagnosticSummary(genericMemberRoutineReference))
Check(Contains(genericMemberRoutineReferenceC, "Identity") And Contains(genericMemberRoutineReferenceC, "member"), "a generic Type member routine reference lowers to its closed function entry point")
Local localNominalGenericSource:String = "SuperStrict~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nType TLocalNominal~nField value:Int~nEnd Type~nLocal original:TLocalNominal=New TLocalNominal~nLocal same:TLocalNominal=Identity<TLocalNominal>(original)"
Local localNominalGeneric:TCompilerResult = TBlitzMaxCompiler.Compile("local-nominal-generic.bmx", localNominalGenericSource, resolver, TestOptions())
Local localNominalGenericDiagnostics:TCompilerDiagnostic[]
Local localNominalGenericC:String = TBlitzMaxCompiler.EmitRuntimeC(localNominalGeneric, localNominalGenericDiagnostics)
Check(localNominalGeneric.Succeeded() And localNominalGenericDiagnostics.length = 0 And localNominalGeneric.genericPlan.units.length = 1, "an application-local nominal Type is a complete canonical generic routine argument: " + CompilerDiagnosticSummary(localNominalGeneric))
Local localNominalSpecializationAbi:String = localNominalGeneric.genericPlan.units[0].specialization.readableAbiName
Check(Contains(localNominalGenericC, localNominalSpecializationAbi + "(") And Contains(localNominalGenericC, "TLocalNominal"), "a local nominal generic routine specialization links against the application-owned class ABI")
Local genericClosureContract:TCompilerResult = TBlitzMaxCompiler.Compile("generic-closure-contract.bmx", "SuperStrict~nFunction Keep<T>:Closure<T(value:T)>(callback:Closure<T(value:T)>)~nReturn callback~nEnd Function", resolver, TestOptions())
Check(genericClosureContract.Succeeded() And Not HasCompilerDiagnostic(genericClosureContract, "BMXC3035"), "Closure contracts in generic declarations lower through the structural format-27 source-free model")

Local managedClosureSource:String = "SuperStrict~nLocal add:Closure<Int(value:Int)> = Function(value)~nReturn value + 1~nEnd Function~nLocal answer:Int = add(41)~nLocal missing:Closure<Int(value:Int)> = Null~nLocal defaultMissing:Closure<Int(value:Int)>~nLocal empty:Int = Not missing Or Not defaultMissing"
Local managedClosureResult:TCompilerResult = TBlitzMaxCompiler.Compile("managed-closure-ir.bmx", managedClosureSource, resolver, TestOptions())
Local managedClosureDiagnostics:TCompilerDiagnostic[]
Local managedClosureDump:String = TCompilerIrDumper.Dump(managedClosureResult.ir)
Local managedClosureC:String = TBlitzMaxCompiler.EmitRuntimeC(managedClosureResult, managedClosureDiagnostics)
Check(managedClosureResult.Succeeded() And managedClosureDiagnostics.length = 0 And managedClosureResult.ir.closureLiterals.length = 1, "non-capturing managed Closure lowers to one compiler-owned intrinsic literal")
Check(Contains(managedClosureDump, "closure-literal") And Contains(managedClosureDump, "closure-call"), "typed IR preserves managed Closure construction and invocation explicitly")
Check(Contains(managedClosureC, "BBClosure") And Contains(managedClosureC, "->environment") And Contains(managedClosureC, "bbNullObject") And Occurrences(managedClosureC, "((BBClosure *)&bbNullObject)") >= 4, "runtime C uses the erased Closure object, hidden environment ABI, and managed null sentinel for explicit and default Null values")
Local managedClosureCoverage:TCompilerResult = TBlitzMaxCompiler.Compile("managed-closure-coverage.bmx", managedClosureSource, resolver, debugCoverageOptions)
Local managedClosureCoverageDiagnostics:TCompilerDiagnostic[]
Local managedClosureCoverageDump:String = TCompilerIrDumper.Dump(managedClosureCoverage.ir)
Local managedClosureCoverageC:String = TBlitzMaxCompiler.EmitRuntimeC(managedClosureCoverage, managedClosureCoverageDiagnostics)
Check(managedClosureCoverageDiagnostics.length = 0 And Contains(managedClosureCoverageDump, "coverage-function 2 ~qClosure in module initialization at line 2 column ") And Contains(managedClosureCoverageDump, "coverage-line 3") And Contains(managedClosureCoverageC, "bbCoverageUpdateFunctionLineInfo(~qmanaged-closure-coverage.bmx~q, ~qClosure in module initialization at line 2 column "), "managed Closure invoke routines share the deterministic literal coverage model")

Local closureReflectionSource:String = "SuperStrict~nType TClosureReflection~nField callback:Closure<Int(value:Int)>~nField callbacks:Closure<Int()>[]~nField rankedCallbacks:Closure<Int(values:String[,])>[]~nField nested:Closure<Closure<Int()>()>~nField mutate:Closure<(value:Int Var)>~nMethod Keep:Closure<Int(value:Int)>(operation:Closure<Int(value:Int)>)~nReturn operation~nEnd Method~nEnd Type"
Local closureReflectionResult:TCompilerResult = TBlitzMaxCompiler.Compile("closure-reflection-ir.bmx", closureReflectionSource, resolver, TestOptions())
Local closureReflectionDiagnostics:TCompilerDiagnostic[]
Local closureReflectionC:String = TBlitzMaxCompiler.EmitRuntimeC(closureReflectionResult, closureReflectionDiagnostics)
Check(closureReflectionResult.Succeeded() And closureReflectionDiagnostics.length = 0 And Contains(closureReflectionC, "BBDEBUGDECL_FIELD, ~qcallback~q, ~q!(i)i~q") And Contains(closureReflectionC, "BBDEBUGDECL_FIELD, ~qnested~q, ~q!()!()i~q"), "Closure-valued fields publish structural reflection tags, including Closure-valued returns")
Check(Contains(closureReflectionC, "BBDEBUGDECL_FIELD, ~qcallbacks~q, ~q[]!()i~q"), "Arrays of managed Closures retain the exact structural element signature in reflection metadata")
Check(Contains(closureReflectionC, "BBDEBUGDECL_FIELD, ~qrankedCallbacks~q, ~q[]!([,]$)i~q"), "a Closure Array reflection tag preserves ranked Array parameters inside its element signature")
Check(Contains(closureReflectionC, "BBDEBUGDECL_FIELD, ~qmutate~q, ~q!(&i)~q"), "Closure reflection tags retain Var parameter modes and an implied no-return signature")
Check(Contains(closureReflectionC, "BBDEBUGDECL_TYPEMETHOD, ~qKeep~q, ~q(!(i)i)!(i)i~q"), "methods expose managed Closure parameter and return signatures to reflection without changing the erased value ABI")

Local capturedClosureSource:String = "SuperStrict~nFunction Make:Closure<Int()>(initial:Int)~nLocal count:Int = initial~nLocal result:Closure<Int()> = Function()~ncount :+ 1~nReturn count + initial~nEnd Function~ncount :+ 10~nReturn result~nEnd Function"
Local capturedClosureResult:TCompilerResult = TBlitzMaxCompiler.Compile("captured-closure-ir.bmx", capturedClosureSource, resolver, TestOptions())
Local capturedClosureDiagnostics:TCompilerDiagnostic[]
Local capturedClosureDump:String = TCompilerIrDumper.Dump(capturedClosureResult.ir)
Local capturedClosureC:String = TBlitzMaxCompiler.EmitRuntimeC(capturedClosureResult, capturedClosureDiagnostics)
Check(capturedClosureResult.Succeeded() And capturedClosureDiagnostics.length = 0 And capturedClosureResult.ir.closureLiterals.length = 1 And capturedClosureResult.ir.closureLiterals[0].environment And capturedClosureResult.ir.classes.length = 1 And capturedClosureResult.ir.classes[0].fields.length = 2, "captured Local and value-parameter identities lower into one shared synthesized environment")
Check(Contains(capturedClosureDump, "$ClosureEnvironment") And Contains(capturedClosureC, "bmx_closure_capture_new") And Contains(capturedClosureC, "bbObjectDowncast") And Contains(capturedClosureC, "offsetof(BBClosure, environment)"), "capturing Closure IR emits a traced environment, checked invoke view, and GC-described Closure allocation")
Local capturedClosureCoverage:TCompilerResult = TBlitzMaxCompiler.Compile("captured-closure-coverage.bmx", capturedClosureSource, resolver, debugCoverageOptions)
Local capturedClosureCoverageDiagnostics:TCompilerDiagnostic[]
Local capturedClosureCoverageDump:String = TCompilerIrDumper.Dump(capturedClosureCoverage.ir)
Local capturedClosureCoverageC:String = TBlitzMaxCompiler.EmitRuntimeC(capturedClosureCoverage, capturedClosureCoverageDiagnostics)
Check(capturedClosureCoverageDiagnostics.length = 0 And Contains(capturedClosureCoverageDump, "coverage-function 4 ~qClosure in Make at line 4 column ") And Contains(capturedClosureCoverageDump, "coverage-line 5") And Contains(capturedClosureCoverageDump, "coverage-line 6") And Contains(capturedClosureCoverageC, "bbCoverageUpdateLineInfo(~qcaptured-closure-coverage.bmx~q, 5)"), "capturing Closure coverage instruments only source body statements, not environment access or allocation plumbing")

Local debugCapturedClosureOptions:TCompilerOptions = DebugTestOptions()
debugCapturedClosureOptions.debugInstrumentation = True
Local debugCapturedClosureResult:TCompilerResult = TBlitzMaxCompiler.Compile("captured-closure-debug.bmx", capturedClosureSource, resolver, debugCapturedClosureOptions)
Local debugCapturedClosureDiagnostics:TCompilerDiagnostic[]
Local debugCapturedClosureC:String = TBlitzMaxCompiler.EmitRuntimeC(debugCapturedClosureResult, debugCapturedClosureDiagnostics)
Check(debugCapturedClosureResult.Succeeded() And debugCapturedClosureDiagnostics.length = 0 And Contains(debugCapturedClosureC, "BBDEBUGSCOPE_FUNCTION, ~qClosure in Make at line 4~q"), "a managed Closure debugger frame identifies its source owner and literal line")
Check(Contains(debugCapturedClosureC, "BBDEBUGDECL_LOCAL, ~qcount~q, ~qi~q") And Contains(debugCapturedClosureC, "BBDEBUGDECL_LOCAL, ~qinitial~q, ~qi~q") And Not Contains(debugCapturedClosureC, "BBDEBUGDECL_LOCAL, ~qenvironment~q"), "a managed Closure debugger scope exposes captured source values and hides its erased environment parameter")

Local nestedClosureSource:String = "SuperStrict~nFunction MakeNested:Closure<Closure<Int()>()>(initial:Int)~nLocal parentValue:Int = initial~nReturn Function()~nLocal childValue:Int = 10~nReturn Function()~nparentValue :+ 1~nchildValue :+ 2~nReturn parentValue + childValue~nEnd Function~nEnd Function~nEnd Function~nLocal factory:Closure<Closure<Int()>()> = MakeNested(10)~nLocal callback:Closure<Int()> = factory()"
Local nestedClosureResult:TCompilerResult = TBlitzMaxCompiler.Compile("nested-closure-ir.bmx", nestedClosureSource, resolver, TestOptions())
Local nestedClosureDiagnostics:TCompilerDiagnostic[]
Local nestedClosureC:String = TBlitzMaxCompiler.EmitRuntimeC(nestedClosureResult, nestedClosureDiagnostics)
Local nestedClosureParentClass:TCompilerIrClass
Local nestedClosureParentField:TCompilerIrClassField
For Local irClass:TCompilerIrClass = EachIn nestedClosureResult.ir.classes
	For Local irField:TCompilerIrClassField = EachIn irClass.fields
		If irField.name = "$Parent" Then nestedClosureParentClass = irClass; nestedClosureParentField = irField
	Next
Next
Check(nestedClosureResult.Succeeded() And nestedClosureDiagnostics.length = 0 And nestedClosureResult.ir.closureLiterals.length = 2 And nestedClosureResult.ir.classes.length = 2, "nested capturing Closures lower to distinct lexical environment identities")
Check(nestedClosureParentClass And nestedClosureParentClass.hasManagedFields And nestedClosureParentField And Contains(nestedClosureC, "bbObjectDowncast") And Contains(nestedClosureC, "->" + nestedClosureParentField.abiName), "a nested Closure environment retains its traced parent environment instead of copying inherited cells")
Local nestedClosureCoverage:TCompilerResult = TBlitzMaxCompiler.Compile("nested-closure-coverage.bmx", nestedClosureSource, resolver, debugCoverageOptions)
Local nestedClosureCoverageDiagnostics:TCompilerDiagnostic[]
Local nestedClosureCoverageDump:String = TCompilerIrDumper.Dump(nestedClosureCoverage.ir)
TBlitzMaxCompiler.EmitRuntimeC(nestedClosureCoverage, nestedClosureCoverageDiagnostics)
Check(nestedClosureCoverageDiagnostics.length = 0 And Contains(nestedClosureCoverageDump, "coverage-function 4 ~qClosure in MakeNested at line 4 column ") And Contains(nestedClosureCoverageDump, "coverage-function 6 ~qClosure in MakeNested at line 6 column ") And Contains(nestedClosureCoverageDump, "coverage-line 7") And Contains(nestedClosureCoverageDump, "coverage-line 9"), "nested Closure invoke routines retain distinct source-facing entries and body lines")

Local debugNestedClosureResult:TCompilerResult = TBlitzMaxCompiler.Compile("nested-closure-debug.bmx", nestedClosureSource, resolver, debugCapturedClosureOptions)
Local debugNestedClosureDiagnostics:TCompilerDiagnostic[]
Local debugNestedClosureC:String = TBlitzMaxCompiler.EmitRuntimeC(debugNestedClosureResult, debugNestedClosureDiagnostics)
Check(debugNestedClosureResult.Succeeded() And debugNestedClosureDiagnostics.length = 0 And Contains(debugNestedClosureC, "BBDEBUGSCOPE_FUNCTION, ~qClosure in MakeNested at line 4~q") And Contains(debugNestedClosureC, "BBDEBUGSCOPE_FUNCTION, ~qClosure in MakeNested at line 6~q"), "nested managed Closure debugger frames retain distinct source lines and the user-authored owner")
Check(Occurrences(debugNestedClosureC, "BBDEBUGDECL_LOCAL, ~qparentValue~q, ~qi~q") >= 2 And Contains(debugNestedClosureC, "BBDEBUGDECL_LOCAL, ~qchildValue~q, ~qi~q"), "nested managed Closure debugger scopes traverse parent environments while presenting source capture names")

Local loopClosureSource:String = "SuperStrict~nGlobal first:Closure<Int()>~nGlobal second:Closure<Int()>~nFunction Build()~nFor Local index:Int = 0 Until 2~nLocal value:Int = index * 10~nLocal action:Closure<Int()> = Function()~nindex :+ 1~nvalue :+ 2~nReturn index + value~nEnd Function~nIf index = 0 Then first = action Else second = action~nNext~nEnd Function"
Local loopClosureResult:TCompilerResult = TBlitzMaxCompiler.Compile("loop-closure-ir.bmx", loopClosureSource, resolver, TestOptions())
Local loopClosureDiagnostics:TCompilerDiagnostic[]
Local loopClosureC:String = TBlitzMaxCompiler.EmitRuntimeC(loopClosureResult, loopClosureDiagnostics)
Check(loopClosureResult.Succeeded() And loopClosureDiagnostics.length = 0 And loopClosureResult.ir.closureLiterals.length = 1 And loopClosureResult.ir.classes.length = 1 And loopClosureResult.ir.classes[0].fields.length = 2, "captured loop-header and body locals lower into one iteration-owned environment")
Check(Contains(loopClosureC, "closure_environment_loop_") And Contains(loopClosureC, "bmx_closure_capture_new") And Contains(loopClosureC, "for ("), "loop Closure C allocates and captures a fresh managed environment inside the generated loop")
Local loopClosureCoverage:TCompilerResult = TBlitzMaxCompiler.Compile("loop-closure-coverage.bmx", loopClosureSource, resolver, debugCoverageOptions)
Local loopClosureCoverageDiagnostics:TCompilerDiagnostic[]
Local loopClosureCoverageDump:String = TCompilerIrDumper.Dump(loopClosureCoverage.ir)
TBlitzMaxCompiler.EmitRuntimeC(loopClosureCoverage, loopClosureCoverageDiagnostics)
Check(loopClosureCoverageDiagnostics.length = 0 And Contains(loopClosureCoverageDump, "coverage-function 7 ~qClosure in Build at line 7 column ") And Contains(loopClosureCoverageDump, "coverage-line 8") And Contains(loopClosureCoverageDump, "coverage-line 10"), "a loop-created Closure has one literal function identity whose invocation count spans all runtime environments")

Local capturedSelfSource:String = "SuperStrict~nType TOwner~nField offset:Int~nMethod Apply:Int(value:Int)~nReturn value + offset~nEnd Method~nMethod Make:Closure<Int(value:Int)>()~nReturn Function(value)~nReturn Self.Apply(value)~nEnd Function~nEnd Method~nEnd Type"
Local capturedSelfResult:TCompilerResult = TBlitzMaxCompiler.Compile("captured-self-ir.bmx", capturedSelfSource, resolver, TestOptions())
Local capturedSelfDiagnostics:TCompilerDiagnostic[]
Local capturedSelfC:String = TBlitzMaxCompiler.EmitRuntimeC(capturedSelfResult, capturedSelfDiagnostics)
Local capturedSelfEnvironment:TCompilerIrClass
For Local irClass:TCompilerIrClass = EachIn capturedSelfResult.ir.classes
	If irClass.name.StartsWith("$ClosureEnvironment") Then capturedSelfEnvironment = irClass; Exit
Next
Check(capturedSelfResult.Succeeded() And capturedSelfDiagnostics.length = 0 And capturedSelfEnvironment And capturedSelfEnvironment.fields.length = 1 And capturedSelfEnvironment.fields[0].name = "Self" And capturedSelfEnvironment.hasManagedFields, "captured Self remains a distinct traced field in the typed Closure environment")
Check(Contains(capturedSelfC, "bmx_closure_capture_new") And Contains(capturedSelfC, "bbObjectDowncast") And Contains(capturedSelfC, "->clas->"), "captured Self invocation retains the managed environment and virtual method dispatch")

Local capturedSuperSource:String = "SuperStrict~nType TBase~nMethod Apply:Int(value:Int)~nReturn value~nEnd Method~nEnd Type~nType TDerived Extends TBase~nMethod Apply:Int(value:Int)~nReturn value + 1~nEnd Method~nMethod Make:Closure<Int(value:Int)>()~nReturn Function(value)~nReturn Super.Apply(value)~nEnd Function~nEnd Method~nEnd Type"
Local capturedSuperResult:TCompilerResult = TBlitzMaxCompiler.Compile("captured-super-ir.bmx", capturedSuperSource, resolver, TestOptions())
Local capturedSuperDiagnostics:TCompilerDiagnostic[]
Local capturedSuperDump:String = TCompilerIrDumper.Dump(capturedSuperResult.ir)
Local capturedSuperC:String = TBlitzMaxCompiler.EmitRuntimeC(capturedSuperResult, capturedSuperDiagnostics)
Check(capturedSuperResult.Succeeded() And capturedSuperDiagnostics.length = 0 And Contains(capturedSuperDump, "call super"), "captured Super remains an explicit statically dispatched operation in typed IR")
Check(Contains(capturedSuperC, "bmx_closure_capture_new") And Contains(capturedSuperC, "bbObjectDowncast"), "captured Super reads its managed receiver from the traced Closure environment")

Local nativeClosure:TCompilerResult = TBlitzMaxCompiler.Compile("native-closure.bmx", "SuperStrict~nExtern~nFunction Register(callback:Closure<()>)=~qregister_closure~q~nEnd Extern~nRegister(Null)", resolver, TestOptions())
Check(HasCompilerDiagnostic(nativeClosure, "BMXC1244"), "managed Closure is rejected explicitly at native ABI boundaries")

Local publicClosure:TCompilerResult = TBlitzMaxCompiler.Compile("/sdk/mod/acme.mod/closures.mod/closures.bmx", "SuperStrict~nModule acme.closures~nGlobal shared:Closure<Int(value:Int)>~nType TClosureHolder~nField callback:Closure<Int(value:Int)>~nEnd Type~nFunction Identity:Closure<Int(value:Int)>(callback:Closure<Int(value:Int)>=Null)~nReturn callback~nEnd Function", resolver, TestOptions())
Local publicClosureInterfaceDiagnostics:TCompilerDiagnostic[]
Local publicClosureInterface:String = TBlitzMaxCompiler.EmitInterface(publicClosure, publicClosureInterfaceDiagnostics)
Check(publicClosure.Succeeded() And publicClosureInterfaceDiagnostics.length = 0 And Contains(publicClosureInterface, "shared:Closure<Int(value:Int)>&=mem:p(") And Contains(publicClosureInterface, ".callback:Closure<Int(value:Int)>&") And Contains(publicClosureInterface, ":Closure<Int(value:Int)>"), "compact interfaces publish explicit managed Closure routine, field, and Global contracts")
resolver.AddInterface("acme.closures", "/sdk/mod/acme.mod/closures.mod/closures.i", publicClosureInterface)
Local publicClosureConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("closure-consumer.bmx", "SuperStrict~nImport acme.closures~nLocal action:Closure<Int(value:Int)> = Identity()~nLocal imported:Closure<Int(value:Int)> = shared~nLocal holder:TClosureHolder = New TClosureHolder~nLocal member:Closure<Int(value:Int)> = holder.callback", resolver, TestOptions())
Check(publicClosureConsumer.Succeeded(), "a source-free consumer reconstructs public managed Closure routine, field, and Global signatures from the compact interface: " + CompilerDiagnosticSummary(publicClosureConsumer))

Print "BlitzMax.Compiler IR tests passed"
