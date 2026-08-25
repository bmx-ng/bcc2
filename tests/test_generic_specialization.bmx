SuperStrict

Framework BRL.StandardIO

Import BlitzMax.Compiler
Import BRL.FileSystem
Import BRL.Map

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Function Occurrences:Int(value:String, token:String)
	If Not token.length Then Return 0
	Local count:Int
	Local offset:Int
	While offset < value.length
		Local found:Int = value.Find(token, offset)
		If found < 0 Then Exit
		count :+ 1
		offset = found + token.length
	Wend
	Return count
End Function

Function AppearsBefore:Int(value:String, first:String, second:String)
	Local firstIndex:Int = value.Find(first)
	Local secondIndex:Int = value.Find(second)
	Return firstIndex >= 0 And secondIndex > firstIndex
End Function

Function HasCompilerDiagnostic:Int(result:TCompilerResult, code:String)
	If Not result Then Return False
	For Local diagnostic:TCompilerDiagnostic = EachIn result.diagnostics
		If diagnostic.code = code Then Return True
	Next
	Return False
End Function

Function HasCompilerDiagnosticMessage:Int(result:TCompilerResult, text:String)
	If Not result Then Return False
	For Local diagnostic:TCompilerDiagnostic = EachIn result.diagnostics
		If diagnostic.message.Contains(text) Then Return True
	Next
	Return False
End Function

Function HasCompilerDiagnosticCode:Int(diagnostics:TCompilerDiagnostic[], code:String)
	For Local diagnostic:TCompilerDiagnostic = EachIn diagnostics
		If diagnostic.code = code Then Return True
	Next
	Return False
End Function

Function HasLanguageDiagnostic:Int(result:TCompilerResult, code:String)
	If Not result Or Not result.analysis Then Return False
	If result.analysis.syntaxTree Then
		For Local diagnostic:TDiagnostic = EachIn result.analysis.syntaxTree.diagnostics
			If diagnostic.code = code Then Return True
		Next
	End If
	If result.analysis.model Then
		For Local diagnostic:TDiagnostic = EachIn result.analysis.model.diagnostics
			If diagnostic.code = code Then Return True
		Next
	End If
	Return False
End Function

Function CompilationSummary:String(result:TCompilerResult)
	If Not result Then Return "no compiler result"
	Local summary:String = "succeeded=" + result.Succeeded()
	If result.analysis Then
		summary :+ ", analysis=" + result.analysis.Succeeded()
		If result.analysis.syntaxTree Then
			For Local diagnostic:TDiagnostic = EachIn result.analysis.syntaxTree.diagnostics
				summary :+ "; " + diagnostic.code + " " + diagnostic.message
			Next
		End If
		If result.analysis.model Then
			For Local diagnostic:TDiagnostic = EachIn result.analysis.model.diagnostics
				summary :+ "; " + diagnostic.code + " " + diagnostic.message
			Next
		End If
	End If
	For Local diagnostic:TCompilerDiagnostic = EachIn result.diagnostics
		summary :+ "; " + diagnostic.code + " " + diagnostic.message
	Next
	If result.genericPlan And result.genericPlan.registry Then
		summary :+ ", nodes=" + result.genericPlan.registry.nodes.length + ", units=" + result.genericPlan.units.length
	End If
	Return summary
End Function

Type TGenericSnapshotResolver Extends TSnapshotResolver
	Field includes:TMap = New TMap
	Field interfaces:TMap = New TMap
	Field genericTemplates:TMap = New TMap

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
		Return Null
	End Method

	Method ResolveGenericTemplate:TSnapshotText(interfacePath:String, artifactReference:String)
		Return TSnapshotText(genericTemplates.ValueForKey(artifactReference.ToLower()))
	End Method
End Type

Function Builtin:TTemplateTypeReference(name:String)
	Local result:TTemplateTypeReference = New TTemplateTypeReference
	result.kind = TEMPLATE_TYPE_BUILTIN
	result.symbolName = name
	Return result
End Function

Function ParameterType:TTemplateTypeReference(index:Int)
	Local result:TTemplateTypeReference = New TTemplateTypeReference
	result.kind = TEMPLATE_TYPE_PARAMETER
	result.parameterIndex = index
	Return result
End Function

Function RequestSite:TGenericSpecializationRequestSite(unitName:String, reason:Int)
	Local result:TGenericSpecializationRequestSite = New TGenericSpecializationRequestSite
	result.requestingUnit = unitName
	result.reason = reason
	result.source = New TTemplateSourceLocation
	result.source.path = unitName + ".bmx"
	result.source.start = 10
	result.source.length = 18
	Return result
End Function

Function ListArtifact:TGenericTemplateArtifact(moduleName:String, revision:String)
	Local identity:TGenericTemplateIdentity = New TGenericTemplateIdentity
	identity.moduleName = moduleName
	identity.qualifiedName = "TArrayList"
	identity.arity = 1

	Local parameter:TGenericTemplateParameter = New TGenericTemplateParameter
	parameter.name = "T"
	parameter.ordinal = 0

	Local valueField:TGenericTemplateMember = New TGenericTemplateMember
	valueField.kind = TEMPLATE_MEMBER_FIELD
	valueField.identity = "field:value"
	valueField.name = "value"
	valueField.semanticType = ParameterType(0)

	Local fieldReference:TGenericTemplateNode = New TGenericTemplateNode
	fieldReference.kind = TEMPLATE_NODE_MEMBER
	fieldReference.valueText = "value"
	fieldReference.semanticType = ParameterType(0)
	Local returnNode:TGenericTemplateNode = New TGenericTemplateNode
	returnNode.kind = TEMPLATE_NODE_RETURN
	returnNode.semanticType = ParameterType(0)
	returnNode.children = [fieldReference]
	Local methodBody:TGenericTemplateNode = New TGenericTemplateNode
	methodBody.kind = TEMPLATE_NODE_BLOCK
	methodBody.children = [returnNode]
	Local firstMethod:TGenericTemplateMember = New TGenericTemplateMember
	firstMethod.kind = TEMPLATE_MEMBER_METHOD
	firstMethod.identity = "method:first/0"
	firstMethod.name = "First"
	firstMethod.semanticType = ParameterType(0)
	firstMethod.body = methodBody

	Local artifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
	artifact.identity = identity
	artifact.contentRevision = revision
	artifact.languageLinkageRevision = "bmx-language-1"
	artifact.parameters = [parameter]
	artifact.members = [valueField, firstMethod]
	Return artifact
End Function

Function Configuration:TCompilerGenericConfiguration(target:String = "macos", architecture:String = "arm64")
	Local result:TCompilerGenericConfiguration = New TCompilerGenericConfiguration
	result.languageLinkageRevision = "bmx-language-1"
	result.compilerIrRevision = "compiler-ir-1"
	result.runtimeAbiRevision = "runtime-abi-1"
	result.compilerBackendRevision = "backend-1"
	result.targetPlatform = target
	result.targetArchitecture = architecture
	result.pointerWidth = 64
	result.buildMode = "release"
	result.threadingMode = "single"
	result.exceptionMode = "default"
	result.garbageCollectorMode = "default"
	result.cpuMode = "generic"
	result.fpuMode = "default"
	result.simdMode = "default"
	result.conditionalEnvironmentRevision = "conditions-1"
	Return result
End Function

Local quotedStructArgument:TTemplateTypeReference = New TTemplateTypeReference
quotedStructArgument.kind = TEMPLATE_TYPE_NAMED
quotedStructArgument.moduleName = "shared/left.bmx"
quotedStructArgument.symbolName = "SValue"
quotedStructArgument.runtimeKind = TEMPLATE_RUNTIME_STRUCT
quotedStructArgument.runtimeAbiName = "application_demo_SValue"
Local quotedStructIncludes:TMap = New TMap
Check(TCompilerGenericCUnitEmitter.RuntimeTypeHeaderIncludes(quotedStructArgument, Configuration(), quotedStructIncludes).Contains("#include <shared/.bmx/left.bmx.release.macos.arm64.h>"), "ordinary Struct arguments owned by quoted sources select the sibling source-unit runtime header")
Local sourceLocalStructArgument:TTemplateTypeReference = New TTemplateTypeReference
sourceLocalStructArgument.kind = TEMPLATE_TYPE_NAMED
sourceLocalStructArgument.moduleName = "source:/tmp/application.bmx"
sourceLocalStructArgument.symbolName = "SValue"
sourceLocalStructArgument.runtimeKind = TEMPLATE_RUNTIME_STRUCT
sourceLocalStructArgument.runtimeAbiName = "application_demo_SValue"
Check(TCompilerGenericCUnitEmitter.RuntimeTypeHeaderIncludes(sourceLocalStructArgument, Configuration(), New TMap) = "", "source-local Struct arguments rely on the build-planned owning runtime header")

Local genericSource:String = "SuperStrict~nType TArrayList<T>~nField value:T~nMethod First:T()~nReturn value~nEnd Method~nEnd Type"
Local genericAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(genericSource, "collections-core.bmx")
Check(genericAnalysis.Succeeded(), "simple source generic Type binds before artifact construction")
Local genericSymbol:TSymbol
For Local candidate:TSymbol = EachIn genericAnalysis.model.globalScope.declaredSymbols
	If candidate.kind = SYMBOL_TYPE And candidate.name = "TArrayList" Then genericSymbol = candidate; Exit
Next
Local artifactDiagnostics:String[]
Local artifact:TGenericTemplateArtifact = TCompilerGenericTemplateBuilder.Build(genericAnalysis.model, genericSymbol, "Collections.Core", "bmx-language-1", artifactDiagnostics)
Check(artifactDiagnostics.length = 0 And artifact And artifact.members.length = 2 And artifact.contentRevision.length = 64, "bound source generic Type becomes a versioned high-level artifact without reparsing")
Check(artifact.members[0].semanticType.CanonicalName() = "!type:0" And artifact.members[1].body.children[0].children[0].valueText = "value", "artifact retains parameter identity and bound method member reference")
Local displayCaseArtifact:TGenericTemplateArtifact = ListArtifact("Collections.Core", "revision")
Local normalizedCaseArtifact:TGenericTemplateArtifact = ListArtifact("collections.core", "revision")
Local displayCaseKey:TCanonicalSpecializationKey = New TCanonicalSpecializationKey
displayCaseKey.templateIdentity = displayCaseArtifact.identity
displayCaseKey.typeArguments = [Builtin("String")]
Local normalizedCaseKey:TCanonicalSpecializationKey = New TCanonicalSpecializationKey
normalizedCaseKey.templateIdentity = normalizedCaseArtifact.identity
normalizedCaseKey.typeArguments = [Builtin("String")]
Local caseIdentityDigest:String = TCompilerStableDigest.Sha256(displayCaseKey.CanonicalName())
Check(displayCaseKey.CanonicalName() = normalizedCaseKey.CanonicalName() And TGenericSpecializationRegistry.ReadableAbiNameFor(displayCaseArtifact, displayCaseKey, caseIdentityDigest) = TGenericSpecializationRegistry.ReadableAbiNameFor(normalizedCaseArtifact, normalizedCaseKey, caseIdentityDigest), "case-insensitive module identity produces one deterministic readable specialization ABI")

Local dependencyRegistry1:TGenericSpecializationRegistry = TGenericSpecializationRegistry.Create(Configuration())
Local dependencyParent1:TGenericSpecializationNode = dependencyRegistry1.Request(ListArtifact("Example.Parent", "parent-revision"), [Builtin("String")], RequestSite("parent", GENERIC_REQUEST_TYPE_USE))
Local dependencyChild1:TGenericSpecializationNode = dependencyRegistry1.Request(ListArtifact("Example.Child", "child-revision-1"), [Builtin("String")], RequestSite("child", GENERIC_REQUEST_TYPE_USE))
dependencyRegistry1.AddEdge(dependencyParent1, dependencyChild1, RequestSite("parent-child", GENERIC_REQUEST_TRANSITIVE))
dependencyRegistry1.FinalizeCacheKeys()
Local dependencyRegistry2:TGenericSpecializationRegistry = TGenericSpecializationRegistry.Create(Configuration())
Local dependencyParent2:TGenericSpecializationNode = dependencyRegistry2.Request(ListArtifact("Example.Parent", "parent-revision"), [Builtin("String")], RequestSite("parent", GENERIC_REQUEST_TYPE_USE))
Local dependencyChild2:TGenericSpecializationNode = dependencyRegistry2.Request(ListArtifact("Example.Child", "child-revision-2"), [Builtin("String")], RequestSite("child", GENERIC_REQUEST_TYPE_USE))
dependencyRegistry2.AddEdge(dependencyParent2, dependencyChild2, RequestSite("parent-child", GENERIC_REQUEST_TRANSITIVE))
dependencyRegistry2.FinalizeCacheKeys()
Check(dependencyParent1.cacheKey <> dependencyParent2.cacheKey And dependencyParent1.generatedObject <> dependencyParent2.generatedObject, "transitive specialization content revisions invalidate parent implementation cache identity")

Local compilerOptions:TCompilerOptions = TCompilerOptions.CreateDefault()
compilerOptions.requireCoreInterface = False
compilerOptions.targetPlatform = "test"
compilerOptions.targetArchitecture = "x64"
compilerOptions.conditionalSymbols = ["bmxng", "ptr64"]
compilerOptions.debugInstrumentation = True
compilerOptions.gdbDebug = True

Local inheritedConstructorSource:String = "SuperStrict~nType TInheritedBase<T>~nField value:T~nMethod New(value:T)~nSelf.value = value~nEnd Method~nEnd Type~nType TInheritedDerived<T> Extends TInheritedBase<T>~nEnd Type~nLocal inherited:TInheritedDerived<String> = New TInheritedDerived<String>(~qhello~q)"
Local inheritedConstructorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("inherited-generic-constructor.bmx", inheritedConstructorSource, Null, compilerOptions)
Local inheritedConstructorRuntimeDiagnostics:TCompilerDiagnostic[]
Local inheritedConstructorRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(inheritedConstructorCompilation, inheritedConstructorRuntimeDiagnostics)
Local inheritedConstructorUnit:TCompilerGenericUnit
For Local unit:TCompilerGenericUnit = EachIn inheritedConstructorCompilation.genericPlan.units
	If unit.specialization.artifact.identity.qualifiedName = "TInheritedDerived" Then inheritedConstructorUnit = unit; Exit
Next
Local inheritedConstructorC:String
Local inheritedBaseInitializer:String
If inheritedConstructorUnit And inheritedConstructorUnit.ir.constructors.length = 1 Then
	Local inheritedConstructor:TCompilerGenericMethodIr = inheritedConstructorUnit.ir.constructors[0]
	inheritedConstructorC = inheritedConstructorUnit.implementation
	If inheritedConstructor.delegatedConstructor Then inheritedBaseInitializer = inheritedConstructor.delegatedConstructor.abiName + "_init"
End If
Check(inheritedConstructorCompilation.Succeeded() And inheritedConstructorUnit And inheritedConstructorUnit.ir.constructors.length = 1 And inheritedConstructorUnit.ir.constructors[0].isInheritedConstructorForwarder, "a derived generic Type retains its inherited parameterized constructor as a derived specialization helper: " + CompilationSummary(inheritedConstructorCompilation))
Check(inheritedBaseInitializer.length And inheritedConstructorC.Contains(inheritedBaseInitializer + "((struct ") And inheritedConstructorRuntimeDiagnostics.length = 0 And inheritedConstructorRuntimeC.Contains(inheritedConstructorUnit.ir.constructors[0].abiName), "the inherited generic constructor allocates through the derived helper and chains into the base initializer")

Local inheritedDefaultConstructorSource:String = "SuperStrict~nType TInheritedDefaultBase<T>~nField initialized:Int~nMethod New()~ninitialized = 41~nEnd Method~nEnd Type~nType TInheritedDefaultDerived<T> Extends TInheritedDefaultBase<T>~nEnd Type~nLocal inherited:TInheritedDefaultDerived<String> = New TInheritedDefaultDerived<String>()"
Local inheritedDefaultConstructorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("inherited-generic-default-constructor.bmx", inheritedDefaultConstructorSource, Null, compilerOptions)
Local inheritedDefaultConstructorUnit:TCompilerGenericUnit
For Local unit:TCompilerGenericUnit = EachIn inheritedDefaultConstructorCompilation.genericPlan.units
	If unit.specialization.artifact.identity.qualifiedName = "TInheritedDefaultDerived" Then inheritedDefaultConstructorUnit = unit; Exit
Next
Local inheritedDefaultConstructor:TCompilerGenericMethodIr
If inheritedDefaultConstructorUnit And inheritedDefaultConstructorUnit.ir.constructors.length = 1 Then inheritedDefaultConstructor = inheritedDefaultConstructorUnit.ir.constructors[0]
Check(inheritedDefaultConstructorCompilation.Succeeded() And inheritedDefaultConstructor And inheritedDefaultConstructor.isInheritedConstructorForwarder And inheritedDefaultConstructor.parameters.length = 0, "a derived generic Type retains its inherited explicit zero-argument constructor: " + CompilationSummary(inheritedDefaultConstructorCompilation))
Check(inheritedDefaultConstructor.delegatedConstructor And inheritedDefaultConstructorUnit.implementation.Contains(inheritedDefaultConstructor.delegatedConstructor.abiName + "_init((struct "), "the inherited zero-argument constructor chains into the base initializer")

Local reflectedTypeSource:String = "SuperStrict~nFunction ReflectedIncrement:Int(value:Int Var)~nvalue:+1~nReturn value~nEnd Function~nType TReflected<T> { entity=~qgeneric~q }~nThreadedGlobal current:Int { reflect category=~qtls~q }~nField value:T { reflect category=~qstate~q }~nMethod New(input:T) { role=~qconstructor~q }~nvalue = input~nEnd Method~nMethod Echo:T(input:T) { role=~qmethod~q }~nReturn input~nEnd Method~nMethod Apply:Int(callback:Int(value:Int), value:Int)~nReturn callback(value)~nEnd Method~nMethod Choose:Int(value:Int Var)(enabled:Int) { role=~qcallable-return~q }~nIf enabled Then Return ReflectedIncrement~nReturn Null~nEnd Method~nMethod Hold:Int(callback:Int(value:Int) Var)~nReturn 0~nEnd Method~nEnd Type~nGlobal reflected:TReflected<String> = New TReflected<String>(~qvalue~q)"
Local reflectedTypeCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-reflection.bmx", reflectedTypeSource, Null, compilerOptions)
Check(reflectedTypeCompilation.Succeeded() And reflectedTypeCompilation.genericPlan.units.length = 1, "generic reflection fixture specializes successfully: " + CompilationSummary(reflectedTypeCompilation))
Local reflectedTypeUnit:TCompilerGenericUnit = reflectedTypeCompilation.genericPlan.units[0]
Local reflectedTypeArtifact:TGenericTemplateArtifact = reflectedTypeUnit.specialization.artifact
Local reflectedTypeImplementation:String = reflectedTypeUnit.implementation
Local reflectedValueMember:TGenericTemplateMember
For Local reflectedMember:TGenericTemplateMember = EachIn reflectedTypeArtifact.members
	If reflectedMember.name.ToLower() = "value" Then reflectedValueMember = reflectedMember; Exit
Next
Check(reflectedTypeArtifact.metadata.length = 1 And reflectedTypeArtifact.metadata[0].value = "generic" And reflectedValueMember And reflectedValueMember.metadata.length = 2 And reflectedValueMember.metadata[1].value = "state", "bound declaration metadata is retained in the canonical generic artifact")
Check(reflectedValueMember.source.line > 0 And reflectedValueMember.source.path = "generic-reflection.bmx", "generic member provenance retains a source line and path")
Local reflectedDebugSourceFound:Int
For Local reflectedDebugSource:TCompilerIrDebugSource = EachIn reflectedTypeCompilation.ir.debugSources
	If reflectedDebugSource.path = "generic-reflection.bmx" Then reflectedDebugSourceFound = True; Exit
Next
Check(reflectedDebugSourceFound, "specialization provenance registers its defining path in application debug metadata")
Check(reflectedTypeImplementation.Contains("BBDEBUGSCOPE_USERTYPE, ~qTReflected<string>") And reflectedTypeImplementation.Contains("BBDEBUGDECL_FIELD, ~qvalue~q") And reflectedTypeImplementation.Contains("BBDEBUGDECL_GLOBAL, ~qcurrent~q"), "specialized Type owns production-shaped reflected Type, field, and static declarations")
Check(reflectedTypeImplementation.Contains("category="), "specialized field reflection carries declaration metadata")
Check(reflectedTypeImplementation.Contains("_init_ReflectionWrapper") And reflectedTypeImplementation.Contains("_Echo_ReflectionWrapper") And reflectedTypeImplementation.Contains(".func_ptr = (BBFuncPtr)&") And reflectedTypeImplementation.Contains("_init, .reflection_wrapper ="), "specialized constructors and ordinary methods own deterministic reflection invocation wrappers")
Check(reflectedTypeImplementation.Contains("BBDEBUGDECL_TYPEMETHOD, ~qApply~q, ~q((i)i,i)i~q") And reflectedTypeImplementation.Contains("_Apply_ReflectionWrapper") And reflectedTypeImplementation.Contains("*((BBINT (**)(BBINT p0))"), "specialized methods with callable parameters publish a typed reflection invocation wrapper")
Check(reflectedTypeImplementation.Contains("BBDEBUGDECL_TYPEMETHOD, ~qChoose~q, ~q(i)(&i)i") And reflectedTypeImplementation.Contains("_Choose_ReflectionWrapper") And reflectedTypeImplementation.Contains("BBINT (**)(BBINT * p0)") And reflectedTypeImplementation.Contains("))(BBINT * p0)"), "specialized Type methods preserve exact callable-return C declarations and publish typed reflection invocation wrappers")
Check(reflectedTypeImplementation.Contains("BBDEBUGDECL_TYPEMETHOD, ~qHold~q, ~q(&(i)i)i~q") And Not reflectedTypeImplementation.Contains("_Hold_ReflectionWrapper"), "generic Var callable parameters remain discoverable while invocation stays behind an explicit null-wrapper guardrail")
Check(reflectedTypeImplementation.Contains(".var_address = 0") And reflectedTypeImplementation.Contains(".var_address = (void *)&" + reflectedTypeUnit.ir.staticFields[0].abiName), "specialized ThreadedGlobal reflection patches the current thread address during registration")
Check(reflectedTypeImplementation.Contains("BBDebugStm bmx_generic_debug_stm_") And reflectedTypeImplementation.Contains("bbOnDebugEnterStm(&bmx_generic_debug_stm_"), "debug specializations emit deterministic source-line entry records")
Check(reflectedTypeImplementation.Contains("#line 9 ~qgeneric-reflection.bmx~q") And reflectedTypeImplementation.Contains("#line 10 ~qgeneric-reflection.bmx~q") And reflectedTypeImplementation.Contains("#line 13 ~qgeneric-reflection.bmx~q"), "gdb specializations map method and statement bodies to source-free template provenance")
Check(reflectedTypeImplementation.Contains("#line 1 ~q<bcc-generated>~q"), "gdb specializations reset generated epilogues and helpers to an explicit synthetic source")
Check(reflectedTypeImplementation.Contains("BBDEBUGSCOPE_FUNCTION"), "debug generic methods publish function scopes")
Check(reflectedTypeImplementation.Contains("BBDEBUGDECL_LOCAL, ~qSelf~q") And reflectedTypeImplementation.Contains("BBDEBUGDECL_LOCAL, ~qinput~q"), "debug generic methods publish addressable receiver and parameter declarations")
Check(reflectedTypeImplementation.Contains("bbOnDebugEnterScope((BBDebugScope *)&bmx_generic_debug_scope)") And reflectedTypeImplementation.Contains("bbOnDebugLeaveScope();"), "debug generic methods enter and leave their routine scopes")
Local genericDebugTagSource:String = "SuperStrict~nType TGenericDebugTags<T>~nMethod Inspect(callback:Int(value:Int), pointer:Byte Ptr Ptr)~nLocal localCallback:Int(value:Int)=callback~nLocal localPointer:Byte Ptr Ptr=pointer~nLocal values:T[,]=New T[1,1]~nLocal StaticArray fixed:Int[4]~nLocal closureValue:Closure<Int(value:Int)>=Function(value:Int)~nReturn value~nEnd Function~nEnd Method~nEnd Type~nGlobal genericDebugTags:TGenericDebugTags<String>=New TGenericDebugTags<String>"
Local genericDebugTagCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-debug-tags.bmx", genericDebugTagSource, Null, compilerOptions)
Local genericDebugTagImplementation:String
If genericDebugTagCompilation.Succeeded() And genericDebugTagCompilation.genericPlan.units.length Then genericDebugTagImplementation = genericDebugTagCompilation.genericPlan.units[0].implementation
Check(genericDebugTagCompilation.Succeeded() And genericDebugTagImplementation.Contains("BBDEBUGDECL_LOCAL, ~qcallback~q, ~q(i)i~q") And genericDebugTagImplementation.Contains("BBDEBUGDECL_LOCAL, ~qpointer~q, ~q**b~q") And genericDebugTagImplementation.Contains("BBDEBUGDECL_LOCAL, ~qlocalCallback~q, ~q(i)i~q") And genericDebugTagImplementation.Contains("BBDEBUGDECL_LOCAL, ~qlocalPointer~q, ~q**b~q") And genericDebugTagImplementation.Contains("BBDEBUGDECL_LOCAL, ~qvalues~q, ~q[,]$~q") And genericDebugTagImplementation.Contains("BBDEBUGDECL_LOCAL, ~qfixed~q, ~q[4]i~q") And genericDebugTagImplementation.Contains("BBDEBUGDECL_LOCAL, ~qclosureValue~q, ~q!(i)i~q"), "generic debug scopes retain complete callable, recursive-pointer, ranked-array, static-array, Closure, and substituted element tags: " + CompilationSummary(genericDebugTagCompilation))
Check(Not genericDebugTagImplementation.Contains(", ~q?~q,") And Not genericDebugTagImplementation.Contains(", ~q*~q,") And Not genericDebugTagImplementation.Contains(", ~q[]*~q,"), "generic debug scopes never publish incomplete fallback tags")
Check(TCompilerGenericCUnitEmitter.TemplateDebugTypeTag(Builtin("Float64"), Null) = "h" And TCompilerGenericCUnitEmitter.TemplateDebugTypeTag(Builtin("Int128"), Null) = "j" And TCompilerGenericCUnitEmitter.TemplateDebugTypeTag(Builtin("Float128"), Null) = "k" And TCompilerGenericCUnitEmitter.TemplateDebugTypeTag(Builtin("Double128"), Null) = "m", "generic reflection typetags distinguish Float64 and every wide numeric category")
Local staticStructDebugSource:String = "SuperStrict~nStruct TStaticFactory<T>~nFunction Create:TStaticFactory<T>()~nReturn New TStaticFactory<T>~nEnd Function~nEnd Struct~nGlobal staticFactory:TStaticFactory<Int> = TStaticFactory<Int>.Create()"
Local staticStructDebugCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-static-struct-debug.bmx", staticStructDebugSource, Null, compilerOptions)
Local staticStructDebugImplementation:String = staticStructDebugCompilation.genericPlan.units[0].implementation
Check(staticStructDebugCompilation.Succeeded() And staticStructDebugImplementation.Contains("BBDEBUGSCOPE_FUNCTION, ~qCreate~q") And Not staticStructDebugImplementation.Contains("BBDEBUGDECL_LOCAL, ~qSelf~q"), "debug static generic-Struct routines publish a function scope without a nonexistent Self local: " + CompilationSummary(staticStructDebugCompilation))
compilerOptions.debugInstrumentation = False
compilerOptions.gdbDebug = False
compilerOptions.coverageInstrumentation = True
Local coverageModuleSource:String = "SuperStrict~nModule Collections.CoverageClosures~nFunction Identity<T>:Closure<T(value:T)>()~nReturn Function(value:T)~nReturn value~nEnd Function~nEnd Function"
Local coverageModulePath:String = "sdk/mod/collections.mod/coverageclosures.mod/coverageclosures.bmx"
Local coverageModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile(coverageModulePath, coverageModuleSource, Null, compilerOptions)
Local coverageArtifactDiagnostics:TCompilerDiagnostic[]
Local coverageOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(coverageModuleCompilation, coverageArtifactDiagnostics)
Local coverageInterfaceDiagnostics:TCompilerDiagnostic[]
Local coverageInterface:String = TBlitzMaxCompiler.EmitInterface(coverageModuleCompilation, coverageInterfaceDiagnostics)
Check(coverageModuleCompilation.Succeeded() And coverageArtifactDiagnostics.length = 0 And coverageInterfaceDiagnostics.length = 0 And coverageOutputs.length = 1, "coverage module publishes its generic Closure body as one source-free compiler artifact: " + CompilationSummary(coverageModuleCompilation))
Check(Not coverageInterface.Contains("bbCoverage") And Not coverageInterface.Contains("register-generic-coverage"), "compact interfaces expose the generic callable signature without compiler-only coverage planning")
Local coverageResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
coverageResolver.AddInterface("collections.coverageclosures", "sdk/collections.coverageclosures.i", coverageInterface)
coverageResolver.AddGenericTemplate(coverageOutputs[0].artifactReference, "sdk/" + coverageOutputs[0].artifactReference, coverageOutputs[0].content)
Local coverageConsumerSource:String = "SuperStrict~nImport Collections.CoverageClosures~nGlobal intIdentity:Closure<Int(value:Int)> = Identity<Int>()~nGlobal stringIdentity:Closure<String(value:String)> = Identity<String>()"
Local coverageConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-coverage-consumer.bmx", coverageConsumerSource, coverageResolver, compilerOptions)
Check(coverageConsumer.Succeeded() And coverageConsumer.genericPlan.units.length = 2 And coverageConsumer.ir.initializationPlan.genericCoverageRegistrations.length = 2, "an imported generic Closure body plans coverage independently for two source-free specializations: " + CompilationSummary(coverageConsumer))
For Local coverageUnit:TCompilerGenericUnit = EachIn coverageConsumer.genericPlan.units
	Check(coverageUnit.implementation.Contains("bbCoverageUpdateFunctionLineInfo(" + Chr(34) + coverageModulePath + Chr(34)), "source-free specialization function probes retain the producer path")
	Check(coverageUnit.implementation.Contains("Closure in Identity<") And coverageUnit.implementation.Contains("at line 4"), "source-free specialization Closure coverage retains its specialized owner and producer location")
	Check(coverageUnit.implementation.Contains("bbCoverageUpdateLineInfo(" + Chr(34) + coverageModulePath + Chr(34)), "source-free specialization statement probes retain the producer path")
	Check(coverageUnit.implementation.Contains("BBCoverageFileInfo bmx_generic_coverage_"), "source-free specialization C owns its coverage catalog")
	Check(coverageUnit.implementation.Contains("_register_coverage(void)"), "source-free specialization C owns its coverage registration hook")
Next
Local coverageRuntimeDiagnostics:TCompilerDiagnostic[]
Local coverageRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(coverageConsumer, coverageRuntimeDiagnostics)
Check(coverageRuntimeDiagnostics.length = 0 And Occurrences(coverageRuntimeC, "extern void bmx_gen_") >= 2 And Occurrences(coverageRuntimeC, "_register_coverage();") = 2, "ordinary source registration calls every specialization-owned coverage hook across the imported module boundary")
compilerOptions.coverageInstrumentation = False
Local nonCoverageConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-coverage-consumer.bmx", coverageConsumerSource, coverageResolver, compilerOptions)
Check(nonCoverageConsumer.Succeeded() And nonCoverageConsumer.genericPlan.units.length = coverageConsumer.genericPlan.units.length And Not nonCoverageConsumer.genericPlan.units[0].implementation.Contains("bbCoverage") And nonCoverageConsumer.genericPlan.units[0].specialization.cacheKey <> coverageConsumer.genericPlan.units[0].specialization.cacheKey, "coverage mode receives a distinct generic implementation cache identity without changing semantic specialization identity")

Local receivedMemberSource:String = "SuperStrict~nType TNode<T>~nField value:T~nEnd Type~nType TList<T>~nField node:TNode<T>~nMethod First:T()~nReturn node.value~nEnd Method~nEnd Type~nLocal list:TList<String> = New TList<String>~nLocal first:String = list.First()"
Local receivedMemberCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("received-member.bmx", receivedMemberSource, Null, compilerOptions)
Local receivedMemberArtifact:TGenericTemplateArtifact
For Local receivedMemberOutput:TCompilerGenericTemplateOutput = EachIn receivedMemberCompilation.genericPlan.templateOutputs
	If receivedMemberOutput.artifact.identity.qualifiedName.ToLower() = "tlist" Then receivedMemberArtifact = receivedMemberOutput.artifact; Exit
Next
Local receivedMemberNode:TGenericTemplateNode
If receivedMemberArtifact Then receivedMemberNode = receivedMemberArtifact.members[1].body.children[0].children[0]
Check(receivedMemberNode And receivedMemberNode.kind = TEMPLATE_NODE_MEMBER And receivedMemberNode.children.length = 1 And receivedMemberNode.children[0].valueText = "node", "bound member templates retain their explicit receiver")
Check(receivedMemberCompilation.Succeeded(), "member access across canonical generic specializations lowers through the receiver specialization: " + CompilationSummary(receivedMemberCompilation))

Local plannedSource:String = genericSource + "~nGlobal list1:TArrayList<String> = New TArrayList<String>~nlist1.value = ~qcanonical~q~nGlobal list2:TArrayList<String> = New TArrayList<String>~nGlobal list:TArrayList<String> = list1~nGlobal first:String = list.First()"
Local plannedCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-application.bmx", plannedSource, Null, compilerOptions)
Check(plannedCompilation.analysis.Succeeded() And plannedCompilation.genericPlan And plannedCompilation.genericPlan.registry.nodes.length = 1, "ordinary compiler entry point discovers and interns constructed source generic uses application-wide")
Check(plannedCompilation.genericPlan.units.length = 1 And plannedCompilation.genericPlan.declarations.length And plannedCompilation.genericPlan.units[0].implementation.length, "compiler result exposes one typed specialization implementation unit and its consumer declarations")
Local backendUnitCache:TCompilerGenericBackendUnitCache = New TCompilerGenericBackendUnitCache
Local cachedPlan1:TCompilerResult = TBlitzMaxCompiler.Compile("generic-cache.bmx", plannedSource, Null, compilerOptions, backendUnitCache)
Local cachedPlan2:TCompilerResult = TBlitzMaxCompiler.Compile("generic-cache.bmx", plannedSource, Null, compilerOptions, backendUnitCache)
Check(cachedPlan1.Succeeded() And cachedPlan2.Succeeded() And backendUnitCache.misses = 1 And backendUnitCache.hits = 1, "build-scoped generic backend catalogue emits one deterministic specialization unit for equivalent requests")
Check(cachedPlan1.genericPlan.units[0].implementation = cachedPlan2.genericPlan.units[0].implementation And cachedPlan1.genericPlan.declarations = cachedPlan2.genericPlan.declarations, "cached specialization backend text is byte-identical while request plans remain distinct")
Check(plannedCompilation.genericPlan.units[0].implementation.Contains("#ifndef BMX_GENERIC_CLASS_" + plannedCompilation.genericPlan.units[0].specialization.readableAbiName.ToUpper()), "specialization C shares the guarded canonical Type layout published by a defining-module runtime header")
Check(plannedCompilation.genericPlan.linkInputs.length = 1 And plannedCompilation.genericPlan.linkInputs[0].objectPath = plannedCompilation.genericPlan.units[0].specialization.generatedObject, "application plan supplies one deterministic cache-addressed object link input")
Local plannedManifestDiagnostics:TCompilerDiagnostic[]
Local plannedManifest:String = TBlitzMaxCompiler.EmitGenericManifest(plannedCompilation, plannedManifestDiagnostics)
Check(plannedManifestDiagnostics.length = 0 And plannedManifest.Contains("generic-application.bmx") And plannedManifest.Contains("generated-unit .generics/units/") And plannedManifest.Contains("generated-object .generics/objects/"), "compiler API emits deterministic specialization source and object ownership: " + CompilationSummary(plannedCompilation))
Check(plannedCompilation.Succeeded() And plannedCompilation.ir.genericInstances.length = 1, "ordinary typed compiler IR retains the canonical specialization reference and skips the open template declaration")
Local plannedRuntimeDiagnostics:TCompilerDiagnostic[]
Local plannedRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(plannedCompilation, plannedRuntimeDiagnostics)
Local plannedAbiName:String = plannedCompilation.genericPlan.units[0].specialization.readableAbiName
Check(plannedRuntimeDiagnostics.length = 0 And plannedRuntimeC.Contains("struct " + plannedAbiName + "_obj;"), "application C receives the canonical specialization declaration")
Check(plannedRuntimeC.Contains("extern struct " + plannedAbiName + "_class " + plannedAbiName + ";") And plannedRuntimeC.Contains(plannedAbiName + "_register();") And Not plannedRuntimeC.Contains("struct " + plannedAbiName + "_class " + plannedAbiName + " = {"), "application C contains specialization ABI declarations and references while the separate unit owns descriptor storage")
Local buildPlanDiagnostics:TCompilerDiagnostic[]
Local buildPlan:TCompilerBuildOutputPlan = TBlitzMaxCompiler.PlanBuildOutputs(plannedCompilation, "application.c", "", "", buildPlanDiagnostics)
Check(buildPlanDiagnostics.length = 0 And buildPlan.files.length = 2 And buildPlan.linkInputs.length = 1, "compiler build-output plan contains the application unit, one specialization unit, and one exact link input")
Check(buildPlan.manifest.StartsWith("BMXBUILD 1~n") And buildPlan.manifest.Contains(plannedCompilation.genericPlan.linkInputs[0].cacheKey), "build-output manifest is versioned and exposes the exact specialization cache key")
Check(buildPlan.files[0].relativePath = plannedCompilation.genericPlan.units[0].specialization.generatedUnit And buildPlan.files[1].relativePath = "application.c", "build outputs have deterministic bounded relative paths")
Local decodedBuildManifestDiagnostics:TCompilerDiagnostic[]
Local decodedBuildManifest:TCompilerBuildManifest = TCompilerBuildOutputPlanner.DecodeManifest(buildPlan.manifest, decodedBuildManifestDiagnostics)
Check(decodedBuildManifestDiagnostics.length = 0 And decodedBuildManifest.files.length = 2 And decodedBuildManifest.linkInputs.length = 1 And decodedBuildManifest.linkInputs[0].objectPath = buildPlan.linkInputs[0].objectPath, "versioned build manifest round-trips exact file and link records")
Local unsafeManifestDiagnostics:TCompilerDiagnostic[]
TCompilerBuildOutputPlanner.DecodeManifest(buildPlan.manifest.Replace(TCompilerBuildOutputPlanner.Enc("application.c"), TCompilerBuildOutputPlanner.Enc("../escape.c")), unsafeManifestDiagnostics)
Check(HasCompilerDiagnosticCode(unsafeManifestDiagnostics, "BMXC3074"), "build manifest ingestion rejects an encoded path traversal")
Local unknownManifestDiagnostics:TCompilerDiagnostic[]
TCompilerBuildOutputPlanner.DecodeManifest(buildPlan.manifest.Replace("BMXBUILD 1", "BMXBUILD 99"), unknownManifestDiagnostics)
Check(HasCompilerDiagnosticCode(unknownManifestDiagnostics, "BMXC3072"), "build manifest ingestion rejects unknown versions")
Local materializationRoot:String = "/tmp/bcc2-canonical-generics-build-output"
Local materializationDiagnostics:TCompilerDiagnostic[]
Local firstMaterialization:TCompilerBuildMaterializationResult = TCompilerBuildOutputMaterializer.Materialize(buildPlan, materializationRoot, "bcc2-build.manifest", materializationDiagnostics)
Check(materializationDiagnostics.length = 0 And firstMaterialization.writtenPaths.length + firstMaterialization.reusedPaths.length = 3, "build-output materializer writes every declared file and the manifest")
Local secondMaterializationDiagnostics:TCompilerDiagnostic[]
Local secondMaterialization:TCompilerBuildMaterializationResult = TCompilerBuildOutputMaterializer.Materialize(buildPlan, materializationRoot, "bcc2-build.manifest", secondMaterializationDiagnostics)
Check(secondMaterializationDiagnostics.length = 0 And secondMaterialization.writtenPaths.length = 0 And secondMaterialization.reusedPaths.length = 3, "unchanged build outputs are exact-content cache hits")
Local referenceMaterializationRoot:String = "/tmp/bcc2-canonical-generics-reference-output"
Local stagedMaterializationRoot:String = "/tmp/bcc2-canonical-generics-staged-output"
If FileType(referenceMaterializationRoot) = FILETYPE_DIR Then DeleteDir(referenceMaterializationRoot, True)
If FileType(stagedMaterializationRoot) = FILETYPE_DIR Then DeleteDir(stagedMaterializationRoot, True)
Local referenceMaterializationDiagnostics:TCompilerDiagnostic[]
TCompilerBuildOutputMaterializer.Materialize(buildPlan, referenceMaterializationRoot, "bcc2-build.manifest", referenceMaterializationDiagnostics)
Local stagedMaterializationDiagnostics:TCompilerDiagnostic[]
Local stagedMaterialization:TCompilerBuildMaterializationResult = TCompilerBuildOutputMaterializer.Materialize(buildPlan, stagedMaterializationRoot, "bcc2-build.manifest", stagedMaterializationDiagnostics, referenceMaterializationRoot)
Check(referenceMaterializationDiagnostics.length = 0 And stagedMaterializationDiagnostics.length = 0 And stagedMaterialization.reusedPaths.length = buildPlan.files.length And stagedMaterialization.writtenPaths.length = 1, "staged build outputs reuse exact files from a separate published reference root while always writing their manifest")
Check(FileType(stagedMaterializationRoot + "/" + buildPlan.files[0].relativePath) = FILETYPE_NONE And FileType(stagedMaterializationRoot + "/bcc2-build.manifest") = FILETYPE_FILE, "reference-root reuse omits unchanged staged files without omitting the staged manifest")
SaveText("stale generated output", referenceMaterializationRoot + "/" + buildPlan.files[0].relativePath)
DeleteDir(stagedMaterializationRoot, True)
Local staleReferenceDiagnostics:TCompilerDiagnostic[]
Local staleReferenceMaterialization:TCompilerBuildMaterializationResult = TCompilerBuildOutputMaterializer.Materialize(buildPlan, stagedMaterializationRoot, "bcc2-build.manifest", staleReferenceDiagnostics, referenceMaterializationRoot)
Check(staleReferenceDiagnostics.length = 0 And staleReferenceMaterialization.reusedPaths.length = buildPlan.files.length - 1 And staleReferenceMaterialization.writtenPaths.length = 2, "a stale reference output is regenerated in staging along with the manifest")
Check(LoadText(stagedMaterializationRoot + "/" + buildPlan.files[0].relativePath) = buildPlan.files[0].content, "stale reference output regeneration preserves the planned content")
DeleteDir(referenceMaterializationRoot, True)
DeleteDir(stagedMaterializationRoot, True)
Local unsafeBuildPlanDiagnostics:TCompilerDiagnostic[]
Local unsafeBuildPlan:TCompilerBuildOutputPlan = TBlitzMaxCompiler.PlanBuildOutputs(plannedCompilation, "../escaped.c", "", "", unsafeBuildPlanDiagnostics)
Check(unsafeBuildPlanDiagnostics.length = 1 And HasCompilerDiagnosticCode(unsafeBuildPlanDiagnostics, "BMXC3060"), "build-output planning rejects paths outside the materialization root")

Local multiFileResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
multiFileResolver.AddInclude("generic-list.bmx", "Type TArrayList<T>~nField value:T~nMethod First:T()~nReturn value~nEnd Method~nEnd Type")
multiFileResolver.AddInclude("file1.bmx", "Global list1:TArrayList<String> = New TArrayList<String>")
multiFileResolver.AddInclude("file2.bmx", "Global list2:TArrayList<String> = New TArrayList<String>")
multiFileResolver.AddInclude("file3.bmx", "Global list:TArrayList<String> = list1~nlist.value = ~qshared~q~nGlobal first:String = list.First()")
Local multiFileSource:String = "SuperStrict~nInclude ~qgeneric-list.bmx~q~nInclude ~qfile1.bmx~q~nInclude ~qfile2.bmx~q~nInclude ~qfile3.bmx~q"
Local multiFileCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("three-file-main.bmx", multiFileSource, multiFileResolver, compilerOptions)
Check(multiFileCompilation.Succeeded() And multiFileCompilation.genericPlan.registry.nodes.length = 1 And multiFileCompilation.genericPlan.units.length = 1, "independent included source files request one application-wide specialization")
Local multiFileNode:TGenericSpecializationNode = multiFileCompilation.genericPlan.registry.nodes[0]
Check(multiFileNode.requests.length >= 3 And multiFileCompilation.ir.genericInstances.length = 1, "one canonical IR identity retains the independent request sites")
Check(multiFileCompilation.genericPlan.units[0].ir.fields[0].source.path = "generic-list.bmx" And multiFileCompilation.genericPlan.units[0].ir.methods[0].source.path = "generic-list.bmx", "template substitution preserves declaration provenance from an included source document")
Local multiFileManifest:String = multiFileCompilation.genericPlan.manifest
Check(multiFileManifest.Contains("file1.bmx") And multiFileManifest.Contains("file2.bmx") And multiFileManifest.Contains("file3.bmx"), "manifest records request ownership in all three source documents")
Local multiFileRuntimeDiagnostics:TCompilerDiagnostic[]
Local multiFileRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(multiFileCompilation, multiFileRuntimeDiagnostics)
Check(multiFileRuntimeDiagnostics.length = 0 And multiFileRuntimeC.Contains("struct " + multiFileNode.readableAbiName + "_obj *"), "the third source consumer uses the same compatible C specialization identity")
Check(Not multiFileRuntimeC.Contains("struct " + multiFileNode.readableAbiName + "_class " + multiFileNode.readableAbiName + " = {"), "the combined application unit does not own specialization descriptor storage or implementation bodies")
Local reversedMultiFileSource:String = "SuperStrict~nInclude ~qgeneric-list.bmx~q~nInclude ~qfile2.bmx~q~nInclude ~qfile1.bmx~q~nInclude ~qfile3.bmx~q"
Local reversedMultiFileCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("three-file-main.bmx", reversedMultiFileSource, multiFileResolver, compilerOptions)
Check(reversedMultiFileCompilation.Succeeded() And reversedMultiFileCompilation.genericPlan.manifest = multiFileManifest, "source specialization output is independent of unrelated producer include order")

Local routineResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
routineResolver.AddInclude("generic-routine.bmx", "Function Identity<T>:T(value:T)~nReturn value~nEnd Function")
routineResolver.AddInclude("routine-file1.bmx", "Global identity1:String = Identity(~qfirst~q)")
routineResolver.AddInclude("routine-file2.bmx", "Global identity2:String = Identity<String>(~qsecond~q)")
routineResolver.AddInclude("routine-file3.bmx", "Global identity3:String = Identity(identity1)")
Local routineSource:String = "SuperStrict~nInclude ~qgeneric-routine.bmx~q~nInclude ~qroutine-file1.bmx~q~nInclude ~qroutine-file2.bmx~q~nInclude ~qroutine-file3.bmx~q"
Local routineCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-routine-main.bmx", routineSource, routineResolver, compilerOptions)
Check(routineCompilation.Succeeded() And routineCompilation.genericPlan.registry.nodes.length = 1 And routineCompilation.genericPlan.units.length = 1, "independent inferred and explicit calls intern one canonical generic routine specialization: " + CompilationSummary(routineCompilation))
Local routineNode:TGenericSpecializationNode = routineCompilation.genericPlan.registry.nodes[0]
Local routineUnit:TCompilerGenericUnit = routineCompilation.genericPlan.units[0]
Check(routineNode.artifact.identity.declarationKind = GENERIC_DECLARATION_ROUTINE And routineNode.requests.length = 3 And routineUnit.ir.isRoutine, "generic routine requests retain routine identity and all independent call sites")
Check(routineUnit.implementation.Contains("BBSTRING " + routineNode.readableAbiName + "(BBSTRING value)") And routineUnit.implementation.Contains("return value;"), "bound generic routine body lowers to one deterministic source-free implementation unit")
Local routineRuntimeDiagnostics:TCompilerDiagnostic[]
Local routineRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(routineCompilation, routineRuntimeDiagnostics)
Check(routineRuntimeDiagnostics.length = 0 And routineRuntimeC.Contains(routineNode.readableAbiName + "((BBString*)&") And Not routineRuntimeC.Contains("BBSTRING " + routineNode.readableAbiName + "(BBSTRING value) {"), "application C references the canonical routine ABI without owning its implementation")
Local reversedRoutineSource:String = "SuperStrict~nInclude ~qgeneric-routine.bmx~q~nInclude ~qroutine-file2.bmx~q~nInclude ~qroutine-file1.bmx~q~nInclude ~qroutine-file3.bmx~q"
Local reversedRoutineCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-routine-main.bmx", reversedRoutineSource, routineResolver, compilerOptions)
Check(reversedRoutineCompilation.Succeeded() And reversedRoutineCompilation.genericPlan.manifest = routineCompilation.genericPlan.manifest, "generic routine specialization output is independent of producer include order")
Local routineCollisionSource:String = "SuperStrict~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nGlobal textIdentity:String = Identity(~qtext~q)~nGlobal intIdentity:Int = Identity(42)"
Local routineCollisionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-routine-arguments.bmx", routineCollisionSource, Null, compilerOptions)
Check(routineCollisionCompilation.Succeeded() And routineCollisionCompilation.genericPlan.registry.nodes.length = 2 And routineCollisionCompilation.genericPlan.units.length = 2 And routineCollisionCompilation.genericPlan.registry.nodes[0].identityDigest <> routineCollisionCompilation.genericPlan.registry.nodes[1].identityDigest, "different generic routine type arguments own distinct canonical identities and units")
Local optionalRoutineSource:String = "SuperStrict~nFunction AddDefault<T>:Int(value:Int, delta:Int = 3)~nReturn value + delta~nEnd Function~nGlobal defaulted:Int = AddDefault<String>(39)"
Local optionalRoutineCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-optional-routine.bmx", optionalRoutineSource, Null, compilerOptions)
Local optionalRoutineRuntimeDiagnostics:TCompilerDiagnostic[]
Local optionalRoutineRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(optionalRoutineCompilation, optionalRoutineRuntimeDiagnostics)
Check(optionalRoutineCompilation.Succeeded() And optionalRoutineCompilation.genericPlan.units.length = 1 And optionalRoutineCompilation.genericPlan.units[0].ir.routine.parameters[1].optional And optionalRoutineCompilation.genericPlan.units[0].ir.routine.parameters[1].defaultValue.valueText = "3", "a generic routine retains its bound numeric optional parameter in specialization IR: " + CompilationSummary(optionalRoutineCompilation))
Check(optionalRoutineRuntimeDiagnostics.length = 0 And optionalRoutineRuntimeC.Contains(optionalRoutineCompilation.genericPlan.registry.nodes[0].readableAbiName + "(39, 3)"), "application IR materializes a generic routine default before calling the separately owned specialization")
Local managedNullDefaultSource:String = "SuperStrict~nFunction ManagedDefault<T>:T(value:T=Null)~nReturn value~nEnd Function~nGlobal text:String=ManagedDefault<String>()~nGlobal values:Int[]=ManagedDefault<Int[]>()~nGlobal object:Object=ManagedDefault<Object>()~nGlobal action:Closure<Int()>=ManagedDefault<Closure<Int()>>()"
Local managedNullDefaultCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-managed-null-defaults.bmx", managedNullDefaultSource, Null, compilerOptions)
Local managedNullDefaultDiagnostics:TCompilerDiagnostic[]
Local managedNullDefaultC:String = TBlitzMaxCompiler.EmitRuntimeC(managedNullDefaultCompilation, managedNullDefaultDiagnostics)
Check(managedNullDefaultCompilation.Succeeded() And managedNullDefaultDiagnostics.length = 0, "managed Null defaults use the closed generic parameter type while lowering omitted arguments: " + CompilationSummary(managedNullDefaultCompilation))
Check(managedNullDefaultC.Contains("&bbEmptyString") And managedNullDefaultC.Contains("&bbEmptyArray") And managedNullDefaultC.Contains("(BBOBJECT)&bbNullObject") And managedNullDefaultC.Contains("(BBClosure *)&bbNullObject"), "closed generic omitted Null defaults preserve every managed runtime sentinel")
Local stringDefaultRoutineSource:String = "SuperStrict~nFunction TextDefault<T>:String(value:String = ~qa~q + ~qb~q)~nReturn value~nEnd Function~nGlobal defaultText:String = TextDefault<Int>()"
Local stringDefaultRoutineCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-string-default-routine.bmx", stringDefaultRoutineSource, Null, compilerOptions)
Local stringDefaultRoutineDiagnostics:TCompilerDiagnostic[]
Local stringDefaultRoutineC:String = TBlitzMaxCompiler.EmitRuntimeC(stringDefaultRoutineCompilation, stringDefaultRoutineDiagnostics)
Check(stringDefaultRoutineCompilation.Succeeded() And stringDefaultRoutineCompilation.genericPlan.units[0].ir.routine.parameters[0].defaultValue.identity = "string-code-units" And stringDefaultRoutineCompilation.genericPlan.units[0].ir.routine.parameters[0].defaultValue.valueText = "97,98", "folded String defaults are retained as target-independent UTF-16 code units in canonical generic routine IR: " + CompilationSummary(stringDefaultRoutineCompilation))
Check(stringDefaultRoutineDiagnostics.length = 0 And stringDefaultRoutineC.Contains(stringDefaultRoutineCompilation.genericPlan.registry.nodes[0].readableAbiName + "((BBString*)&"), "application IR materializes a folded String default as an ordinary runtime String literal without retaining or reparsing its source expression")
Local transitiveOptionalRoutineSource:String = "SuperStrict~nFunction AddDefault<T>:Int(value:Int, delta:Int = 3)~nReturn value + delta~nEnd Function~nFunction ForwardDefault<T>:Int(value:Int)~nReturn AddDefault<T>(value)~nEnd Function~nGlobal defaulted:Int = ForwardDefault<String>(39)"
Local transitiveOptionalRoutineCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-transitive-optional-routine.bmx", transitiveOptionalRoutineSource, Null, compilerOptions)
Local transitiveOptionalRoutineImplementation:String
For Local transitiveOptionalRoutineUnit:TCompilerGenericUnit = EachIn transitiveOptionalRoutineCompilation.genericPlan.units
	transitiveOptionalRoutineImplementation :+ transitiveOptionalRoutineUnit.implementation
Next
Check(transitiveOptionalRoutineCompilation.Succeeded() And transitiveOptionalRoutineCompilation.genericPlan.units.length = 2 And transitiveOptionalRoutineImplementation.Contains("(value, 3)"), "a generic caller materializes its callee's bound optional default in source-free specialization IR: " + CompilationSummary(transitiveOptionalRoutineCompilation))
Local ordinaryOptionalCallSource:String = "SuperStrict~nFunction StableDefault:Int(value:Int, delta:Int = 3) { nomangle }~nReturn value + delta~nEnd Function~nFunction ViaStableDefault<T>:Int(value:Int)~nReturn StableDefault(value)~nEnd Function~nGlobal defaulted:Int = ViaStableDefault<String>(39)"
Local ordinaryOptionalCallCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-ordinary-optional-call.bmx", ordinaryOptionalCallSource, Null, compilerOptions)
Check(ordinaryOptionalCallCompilation.Succeeded() And ordinaryOptionalCallCompilation.genericPlan.units.length = 1 And ordinaryOptionalCallCompilation.genericPlan.units[0].implementation.Contains("_bb_main_StableDefault(((BBINT)value), ((BBINT)3))"), "a generic body materializes the bound default for a stable ordinary routine call: " + CompilationSummary(ordinaryOptionalCallCompilation))
Local optionalRoutineModuleSource:String = "SuperStrict~nModule Collections.OptionalRoutine~nFunction AddDefault<T>:Int(value:Int, delta:Int = 3)~nReturn value + delta~nEnd Function~nFunction ForwardDefault<T>:Int(value:Int)~nReturn AddDefault<T>(value)~nEnd Function"
Local optionalRoutineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/optionalroutine.mod/optionalroutine.bmx", optionalRoutineModuleSource, Null, compilerOptions)
Local optionalRoutineArtifactDiagnostics:TCompilerDiagnostic[]
Local optionalRoutineOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(optionalRoutineModuleCompilation, optionalRoutineArtifactDiagnostics)
Local optionalRoutineInterfaceDiagnostics:TCompilerDiagnostic[]
Local optionalRoutineInterface:String = TBlitzMaxCompiler.EmitInterface(optionalRoutineModuleCompilation, optionalRoutineInterfaceDiagnostics)
Local optionalRoutineResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
optionalRoutineResolver.AddInterface("collections.optionalroutine", "sdk/collections.optionalroutine.i", optionalRoutineInterface)
For Local optionalRoutineOutput:TCompilerGenericTemplateOutput = EachIn optionalRoutineOutputs
	optionalRoutineResolver.AddGenericTemplate(optionalRoutineOutput.artifactReference, "sdk/" + optionalRoutineOutput.artifactReference, optionalRoutineOutput.content)
Next
Local optionalRoutineConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-imported-optional-routine.bmx", "SuperStrict~nImport Collections.OptionalRoutine~nGlobal result:Int = ForwardDefault<String>(39)", optionalRoutineResolver, compilerOptions)
Local optionalRoutineConsumerDiagnostics:TCompilerDiagnostic[]
Local optionalRoutineConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(optionalRoutineConsumer, optionalRoutineConsumerDiagnostics)
Local optionalRoutineConsumerImplementations:String
For Local optionalRoutineConsumerUnit:TCompilerGenericUnit = EachIn optionalRoutineConsumer.genericPlan.units
	optionalRoutineConsumerImplementations :+ optionalRoutineConsumerUnit.implementation
Next
Check(optionalRoutineModuleCompilation.Succeeded() And optionalRoutineArtifactDiagnostics.length = 0 And optionalRoutineInterfaceDiagnostics.length = 0 And optionalRoutineOutputs.length = 2 And optionalRoutineInterface.Contains("delta%=3"), "a module publishes a generic routine default as source-free canonical template data")
Check(optionalRoutineConsumer.Succeeded() And optionalRoutineConsumerDiagnostics.length = 0 And optionalRoutineConsumer.genericPlan.units.length = 2 And optionalRoutineConsumerImplementations.Contains("(value, 3)"), "an imported generic routine default round-trips through a transitive call without reparsing source: " + CompilationSummary(optionalRoutineConsumer))
Local stringDefaultModuleSource:String = "SuperStrict~nModule Collections.StringDefault~nFunction TextDefault<T>:String(value:String = ~qleft~q + ~q-right~q)~nReturn value~nEnd Function"
Local stringDefaultModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/stringdefault.mod/stringdefault.bmx", stringDefaultModuleSource, Null, compilerOptions)
Local stringDefaultArtifactDiagnostics:TCompilerDiagnostic[]
Local stringDefaultOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(stringDefaultModuleCompilation, stringDefaultArtifactDiagnostics)
Local stringDefaultInterfaceDiagnostics:TCompilerDiagnostic[]
Local stringDefaultInterface:String = TBlitzMaxCompiler.EmitInterface(stringDefaultModuleCompilation, stringDefaultInterfaceDiagnostics)
Local stringDefaultResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
stringDefaultResolver.AddInterface("collections.stringdefault", "sdk/collections.stringdefault.i", stringDefaultInterface)
For Local stringDefaultOutput:TCompilerGenericTemplateOutput = EachIn stringDefaultOutputs
	stringDefaultResolver.AddGenericTemplate(stringDefaultOutput.artifactReference, "sdk/" + stringDefaultOutput.artifactReference, stringDefaultOutput.content)
Next
Local stringDefaultConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-imported-string-default.bmx", "SuperStrict~nImport Collections.StringDefault~nGlobal text:String = TextDefault<Int>()", stringDefaultResolver, compilerOptions)
Local stringDefaultConsumerDiagnostics:TCompilerDiagnostic[]
Local stringDefaultConsumerC:String = TBlitzMaxCompiler.EmitRuntimeC(stringDefaultConsumer, stringDefaultConsumerDiagnostics)
Check(stringDefaultModuleCompilation.Succeeded() And stringDefaultArtifactDiagnostics.length = 0 And stringDefaultInterfaceDiagnostics.length = 0 And stringDefaultOutputs.length = 1 And stringDefaultInterface.Contains("value$=$~qleft-right~q"), "a module publishes a folded generic String default in its compact public signature and source-free artifact")
Check(stringDefaultConsumer.Succeeded() And stringDefaultConsumerDiagnostics.length = 0 And stringDefaultConsumer.genericPlan.units.length = 1 And stringDefaultConsumerC.Contains("TextDefault_int_"), "an imported folded String default round-trips through the canonical artifact without source ingestion: " + CompilationSummary(stringDefaultConsumer))
Local varRoutineModuleSource:String = "SuperStrict~nModule Collections.VarRoutine~nFunction Replace<T>:T(value:T Var, replacement:T)~nvalue = replacement~nReturn value~nEnd Function"
Local varRoutineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/varroutine.mod/varroutine.bmx", varRoutineModuleSource, Null, compilerOptions)
Local varRoutineArtifactDiagnostics:TCompilerDiagnostic[]
Local varRoutineOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(varRoutineModuleCompilation, varRoutineArtifactDiagnostics)
Local varRoutineInterfaceDiagnostics:TCompilerDiagnostic[]
Local varRoutineInterface:String = TBlitzMaxCompiler.EmitInterface(varRoutineModuleCompilation, varRoutineInterfaceDiagnostics)
Local varRoutineResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
varRoutineResolver.AddInterface("collections.varroutine", "sdk/collections.varroutine.i", varRoutineInterface)
For Local varRoutineOutput:TCompilerGenericTemplateOutput = EachIn varRoutineOutputs
	varRoutineResolver.AddGenericTemplate(varRoutineOutput.artifactReference, "sdk/" + varRoutineOutput.artifactReference, varRoutineOutput.content)
Next
Local importedVarRoutineConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-imported-var-routine.bmx", "SuperStrict~nImport Collections.VarRoutine~nGlobal input:Int = 1~nGlobal result:Int = Replace<Int>(input, 7)", varRoutineResolver, compilerOptions)
Local importedVarRoutineDiagnostics:TCompilerDiagnostic[]
Local importedVarRoutineC:String = TBlitzMaxCompiler.EmitRuntimeC(importedVarRoutineConsumer, importedVarRoutineDiagnostics)
Check(varRoutineModuleCompilation.Succeeded() And varRoutineArtifactDiagnostics.length = 0 And varRoutineInterfaceDiagnostics.length = 0 And varRoutineOutputs.length = 1 And varRoutineInterface.Contains("value:T Var"), "a module publishes a canonical generic Var signature and source-free implementation artifact")
Check(importedVarRoutineConsumer.Succeeded() And importedVarRoutineDiagnostics.length = 0 And importedVarRoutineConsumer.genericPlan.units[0].implementation.Contains("BBINT * value") And importedVarRoutineC.Contains("&bmx_"), "an imported generic Var routine preserves one compatible pointer ABI through interface ingestion and specialization: " + CompilationSummary(importedVarRoutineConsumer))
Local thinLiteralModuleSource:String = "SuperStrict~nModule Collections.ThinLiteral~nFunction Identity<T>:T(value:T)()~nReturn Function(value:T)~nReturn value~nEnd Function~nEnd Function~nFunction VarIdentity<T>:T(value:T Var)()~nReturn Function(value:T Var)~nReturn value~nEnd Function~nEnd Function"
Local thinLiteralModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/thinliteral.mod/thinliteral.bmx", thinLiteralModuleSource, Null, compilerOptions)
Local thinLiteralArtifactDiagnostics:TCompilerDiagnostic[]
Local thinLiteralOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(thinLiteralModuleCompilation, thinLiteralArtifactDiagnostics)
Local thinLiteralInterfaceDiagnostics:TCompilerDiagnostic[]
Local thinLiteralInterface:String = TBlitzMaxCompiler.EmitInterface(thinLiteralModuleCompilation, thinLiteralInterfaceDiagnostics)
Local thinLiteralResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
thinLiteralResolver.AddInterface("collections.thinliteral", "sdk/collections.thinliteral.i", thinLiteralInterface)
For Local thinLiteralOutput:TCompilerGenericTemplateOutput = EachIn thinLiteralOutputs
	thinLiteralResolver.AddGenericTemplate(thinLiteralOutput.artifactReference, "sdk/" + thinLiteralOutput.artifactReference, thinLiteralOutput.content)
Next
Local thinLiteralConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-imported-thin-literal.bmx", "SuperStrict~nImport Collections.ThinLiteral~nGlobal callback:Int(value:Int) = Identity<Int>()~nGlobal input:Int = 42~nGlobal varCallback:Int(value:Int Var) = VarIdentity<Int>()~nGlobal direct:Int = callback(input)~nGlobal throughVar:Int = varCallback(input)", thinLiteralResolver, compilerOptions)
Check(thinLiteralConsumer.Succeeded(), "an imported thin Function literal consumer binds before specialization inspection: " + CompilationSummary(thinLiteralConsumer) + " interface=" + thinLiteralInterface)
Local thinLiteralImplementations:String
For Local thinLiteralUnit:TCompilerGenericUnit = EachIn thinLiteralConsumer.genericPlan.units
	thinLiteralImplementations :+ thinLiteralUnit.implementation
Next
Check(thinLiteralModuleCompilation.Succeeded() And thinLiteralArtifactDiagnostics.length = 0 And thinLiteralInterfaceDiagnostics.length = 0 And thinLiteralOutputs.length = 2 And thinLiteralInterface.Contains(":T(arg0:T)()") And thinLiteralInterface.Contains(":T(arg0:T Var)()"), "a module publishes thin Function literal bodies and callable return signatures through format-27 source-free artifacts: " + thinLiteralInterface)
Check(thinLiteralConsumer.Succeeded() And thinLiteralConsumer.genericPlan.units.length = 2 And thinLiteralImplementations.Contains("_function_") And thinLiteralImplementations.Contains("BBINT * value") And Not thinLiteralImplementations.Contains("static BBClosure"), "imported generic thin literals specialize to typed private function pointers without defining source or managed allocation: " + CompilationSummary(thinLiteralConsumer))
Local closureRoutineModuleSource:String = "SuperStrict~nModule Collections.ClosureRoutine~nFunction Apply<T,R>:R(value:T, operation:Closure<R(value:T)>)~nReturn operation(value)~nEnd Function~nFunction Identity<T>:Closure<T(value:T)>()~nReturn Function(value:T)~nReturn value~nEnd Function~nEnd Function~nFunction Remember<T>:Closure<T()>(value:T)~nReturn Function()~nReturn value~nEnd Function~nEnd Function~nFunction Bind<T,R>:Closure<R()>(value:T,operation:Closure<R(value:T)>)~nReturn Function()~nReturn operation(value)~nEnd Function~nEnd Function~nFunction BindAll<T,R>:Closure<R()>[](values:T[],operation:Closure<R(value:T)>)~nLocal result:Closure<R()>[]=New Closure<R()>[values.length]~nFor Local index:Int=0 Until values.length~nresult[index]=Bind<T,R>(values[index],operation)~nNext~nReturn result~nEnd Function"
Local closureRoutineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/closureroutine.mod/closureroutine.bmx", closureRoutineModuleSource, Null, compilerOptions)
Local closureRoutineArtifactDiagnostics:TCompilerDiagnostic[]
Local closureRoutineOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(closureRoutineModuleCompilation, closureRoutineArtifactDiagnostics)
Local closureRoutineInterfaceDiagnostics:TCompilerDiagnostic[]
Local closureRoutineInterface:String = TBlitzMaxCompiler.EmitInterface(closureRoutineModuleCompilation, closureRoutineInterfaceDiagnostics)
Local closureRoutineResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
closureRoutineResolver.AddInterface("collections.closureroutine", "sdk/collections.closureroutine.i", closureRoutineInterface)
For Local closureRoutineOutput:TCompilerGenericTemplateOutput = EachIn closureRoutineOutputs
	closureRoutineResolver.AddGenericTemplate(closureRoutineOutput.artifactReference, "sdk/" + closureRoutineOutput.artifactReference, closureRoutineOutput.content)
Next
Local closureRoutineConsumerSource:String = "SuperStrict~nImport Collections.ClosureRoutine~nGlobal increment:Closure<Int(value:Int)> = Function(value:Int)~nReturn value + 1~nEnd Function~nGlobal applied:Int = Apply<Int,Int>(41, increment)~nGlobal identityClosure:Closure<String(value:String)> = Identity<String>()~nGlobal remembered:Closure<String()> = Remember<String>(~qsource-free-capture~q)~nGlobal bound:Closure<Int()>[]=BindAll<Int,Int>([40,41],increment)"
Local closureRoutineConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-imported-closure-routine.bmx", closureRoutineConsumerSource, closureRoutineResolver, compilerOptions)
Local closureRoutineImplementations:String
Local closureRoutineApplyAbi:String
For Local closureRoutineUnit:TCompilerGenericUnit = EachIn closureRoutineConsumer.genericPlan.units
	closureRoutineImplementations :+ closureRoutineUnit.implementation
	If closureRoutineUnit.ir And closureRoutineUnit.ir.routine And closureRoutineUnit.ir.routine.name.ToLower() = "apply" Then closureRoutineApplyAbi = closureRoutineUnit.ir.routine.abiName
Next
Local closureRoutineRuntimeDiagnostics:TCompilerDiagnostic[]
Local closureRoutineRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(closureRoutineConsumer, closureRoutineRuntimeDiagnostics)
Check(closureRoutineModuleCompilation.Succeeded() And closureRoutineArtifactDiagnostics.length = 0 And closureRoutineInterfaceDiagnostics.length = 0 And closureRoutineOutputs.length = 5 And closureRoutineInterface.Contains("operation:Closure<R(value:T)>") And closureRoutineInterface.Contains(":Closure<T(value:T)>()") And closureRoutineInterface.Contains(":Closure<T()>(value:T)") And closureRoutineInterface.Contains("BindAll<T,R>:Closure<R()>&[](values:T&[]"), "a module publishes generic Closure contracts, Closure Arrays, capture records, and literal bodies through compact interfaces and format-27 source-free artifacts: " + closureRoutineInterface)
Check(closureRoutineConsumer.Succeeded() And closureRoutineConsumer.genericPlan.units.length = 5 And closureRoutineImplementations.Contains("bmx_closure_call_") And closureRoutineImplementations.Contains("static BBClosure") And closureRoutineImplementations.Contains("_closure_environment") And closureRoutineImplementations.Contains("_closure_new") And closureRoutineImplementations.Contains("bbArrayNew1D(~q!()i~q"), "imported generic Closure values and Closure Arrays specialize without ingesting defining source: " + CompilationSummary(closureRoutineConsumer))
Check(closureRoutineRuntimeDiagnostics.length = 0 And closureRoutineApplyAbi.length And Occurrences(closureRoutineRuntimeC, closureRoutineApplyAbi) >= 2, "an application-owned imported generic Closure routine is explicitly declared as well as called in the consuming C unit")
Local nestedClosureModuleSource:String = "SuperStrict~nModule Collections.NestedClosure~nFunction MakeNested<T>:Closure<Closure<Int()>()>(initial:Int)~nLocal parentValue:Int = initial~nReturn Function()~nLocal childValue:Int = 10~nReturn Function()~nparentValue :+ 1~nchildValue :+ 2~nReturn parentValue + childValue~nEnd Function~nEnd Function~nEnd Function"
Local nestedClosureModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/nestedclosure.mod/nestedclosure.bmx", nestedClosureModuleSource, Null, compilerOptions)
Local nestedClosureArtifactDiagnostics:TCompilerDiagnostic[]
Local nestedClosureOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(nestedClosureModuleCompilation, nestedClosureArtifactDiagnostics)
Local nestedClosureInterfaceDiagnostics:TCompilerDiagnostic[]
Local nestedClosureInterface:String = TBlitzMaxCompiler.EmitInterface(nestedClosureModuleCompilation, nestedClosureInterfaceDiagnostics)
Local nestedClosureResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
nestedClosureResolver.AddInterface("collections.nestedclosure", "sdk/collections.nestedclosure.i", nestedClosureInterface)
For Local nestedClosureOutput:TCompilerGenericTemplateOutput = EachIn nestedClosureOutputs
	nestedClosureResolver.AddGenericTemplate(nestedClosureOutput.artifactReference, "sdk/" + nestedClosureOutput.artifactReference, nestedClosureOutput.content)
Next
Local nestedClosureConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-imported-nested-closure.bmx", "SuperStrict~nImport Collections.NestedClosure~nGlobal factory:Closure<Closure<Int()>()> = MakeNested<String>(10)~nGlobal callback:Closure<Int()> = factory()", nestedClosureResolver, compilerOptions)
Local nestedClosureImplementations:String
For Local nestedClosureUnit:TCompilerGenericUnit = EachIn nestedClosureConsumer.genericPlan.units
	nestedClosureImplementations :+ nestedClosureUnit.implementation
Next
Check(nestedClosureModuleCompilation.Succeeded() And nestedClosureArtifactDiagnostics.length = 0 And nestedClosureInterfaceDiagnostics.length = 0 And nestedClosureOutputs.length = 1 And nestedClosureInterface.Contains("MakeNested<T>:Closure<Closure<Int()>()>(initial%"), "a module publishes a Closure-valued nested generic Closure hierarchy as one source-free canonical routine artifact")
Check(nestedClosureConsumer.Succeeded() And nestedClosureConsumer.genericPlan.units.length = 1 And nestedClosureImplementations.Contains("capture_parent_") And nestedClosureImplementations.Contains("parentValue") And nestedClosureImplementations.Contains("childValue"), "an imported nested generic Closure reconstructs owned and incoming environments without defining source: " + CompilationSummary(nestedClosureConsumer))
Local loopClosureModuleSource:String = "SuperStrict~nModule Collections.LoopClosure~nFunction Last<T>:Closure<Int()>(count:Int)~nLocal result:Closure<Int()>~nFor Local index:Int = 0 Until count~nresult = Function()~nindex :+ 1~nReturn index~nEnd Function~nNext~nReturn result~nEnd Function"
Local loopClosureModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/loopclosure.mod/loopclosure.bmx", loopClosureModuleSource, Null, compilerOptions)
Local loopClosureArtifactDiagnostics:TCompilerDiagnostic[]
Local loopClosureOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(loopClosureModuleCompilation, loopClosureArtifactDiagnostics)
Local loopClosureInterfaceDiagnostics:TCompilerDiagnostic[]
Local loopClosureInterface:String = TBlitzMaxCompiler.EmitInterface(loopClosureModuleCompilation, loopClosureInterfaceDiagnostics)
Local loopClosureResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
loopClosureResolver.AddInterface("collections.loopclosure", "sdk/collections.loopclosure.i", loopClosureInterface)
For Local loopClosureOutput:TCompilerGenericTemplateOutput = EachIn loopClosureOutputs
	loopClosureResolver.AddGenericTemplate(loopClosureOutput.artifactReference, "sdk/" + loopClosureOutput.artifactReference, loopClosureOutput.content)
Next
Local loopClosureConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-imported-loop-closure.bmx", "SuperStrict~nImport Collections.LoopClosure~nGlobal callback:Closure<Int()> = Last<String>(3)", loopClosureResolver, compilerOptions)
Local loopClosureImplementations:String
For Local loopClosureUnit:TCompilerGenericUnit = EachIn loopClosureConsumer.genericPlan.units
	loopClosureImplementations :+ loopClosureUnit.implementation
Next
Check(loopClosureModuleCompilation.Succeeded() And loopClosureArtifactDiagnostics.length = 0 And loopClosureInterfaceDiagnostics.length = 0 And loopClosureOutputs.length = 1, "a generic routine with loop-scoped Closure capture publishes one source-free canonical artifact")
Check(loopClosureConsumer.Succeeded() And loopClosureConsumer.genericPlan.units.length = 1 And loopClosureImplementations.Contains("closure_environment_loop0") And loopClosureImplementations.Contains("for ("), "an imported generic loop Closure allocates its reconstructed managed environment inside each specialized iteration: " + CompilationSummary(loopClosureConsumer))
Local selfClosureModuleSource:String = "SuperStrict~nModule Collections.SelfClosure~nType TFactory<T>~nField value:T~nMethod New(value:T)~nSelf.value = value~nEnd Method~nMethod Read:T()~nReturn value~nEnd Method~nMethod Remember:Closure<T()>()~nReturn Function()~nReturn Self.Read()~nEnd Function~nEnd Method~nEnd Type"
Local selfClosureModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/selfclosure.mod/selfclosure.bmx", selfClosureModuleSource, Null, compilerOptions)
Local selfClosureArtifactDiagnostics:TCompilerDiagnostic[]
Local selfClosureOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(selfClosureModuleCompilation, selfClosureArtifactDiagnostics)
Local selfClosureInterfaceDiagnostics:TCompilerDiagnostic[]
Local selfClosureInterface:String = TBlitzMaxCompiler.EmitInterface(selfClosureModuleCompilation, selfClosureInterfaceDiagnostics)
Local selfClosureResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
selfClosureResolver.AddInterface("collections.selfclosure", "sdk/collections.selfclosure.i", selfClosureInterface)
For Local selfClosureOutput:TCompilerGenericTemplateOutput = EachIn selfClosureOutputs
	selfClosureResolver.AddGenericTemplate(selfClosureOutput.artifactReference, "sdk/" + selfClosureOutput.artifactReference, selfClosureOutput.content)
Next
Local selfClosureConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-imported-self-closure.bmx", "SuperStrict~nImport Collections.SelfClosure~nGlobal factory:TFactory<String> = New TFactory<String>(~qretained-self~q)~nGlobal callback:Closure<String()> = factory.Remember()", selfClosureResolver, compilerOptions)
Local selfClosureImplementations:String
For Local selfClosureUnit:TCompilerGenericUnit = EachIn selfClosureConsumer.genericPlan.units
	selfClosureImplementations :+ selfClosureUnit.implementation
Next
Check(selfClosureModuleCompilation.Succeeded() And selfClosureArtifactDiagnostics.length = 0 And selfClosureInterfaceDiagnostics.length = 0 And selfClosureOutputs.length = 1 And selfClosureInterface.Contains("Remember:Closure<T()>()"), "a generic Type publishes Self-capturing Closure code through its compact interface and canonical artifact: outputs=" + selfClosureOutputs.length + " interface=" + selfClosureInterface + " compilation=" + CompilationSummary(selfClosureModuleCompilation))
Check(selfClosureConsumer.Succeeded() And selfClosureConsumer.genericPlan.units.length = 1 And selfClosureImplementations.Contains("capture_Self_") And selfClosureImplementations.Contains("_closure_environment") And selfClosureImplementations.Contains("->clas->"), "an imported generic Type specializes a Self-capturing Closure without access to defining source: " + CompilationSummary(selfClosureConsumer))
Local superClosureModuleSource:String = "SuperStrict~nModule Collections.SuperClosure~nType TBase<T>~nField baseValue:T~nMethod Read:T()~nReturn baseValue~nEnd Method~nEnd Type~nType TDerived<T> Extends TBase<T>~nField derivedValue:T~nMethod Read:T()~nReturn derivedValue~nEnd Method~nMethod RememberBase:Closure<T()>()~nReturn Function()~nReturn Super.Read()~nEnd Function~nEnd Method~nEnd Type"
Local superClosureModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/superclosure.mod/superclosure.bmx", superClosureModuleSource, Null, compilerOptions)
Local superClosureArtifactDiagnostics:TCompilerDiagnostic[]
Local superClosureOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(superClosureModuleCompilation, superClosureArtifactDiagnostics)
Local superClosureInterfaceDiagnostics:TCompilerDiagnostic[]
Local superClosureInterface:String = TBlitzMaxCompiler.EmitInterface(superClosureModuleCompilation, superClosureInterfaceDiagnostics)
Local superClosureResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
superClosureResolver.AddInterface("collections.superclosure", "sdk/collections.superclosure.i", superClosureInterface)
For Local superClosureOutput:TCompilerGenericTemplateOutput = EachIn superClosureOutputs
	superClosureResolver.AddGenericTemplate(superClosureOutput.artifactReference, "sdk/" + superClosureOutput.artifactReference, superClosureOutput.content)
Next
Local superClosureConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-imported-super-closure.bmx", "SuperStrict~nImport Collections.SuperClosure~nGlobal factory:TDerived<String> = New TDerived<String>~nGlobal callback:Closure<String()> = factory.RememberBase()", superClosureResolver, compilerOptions)
Local superClosureImplementations:String
For Local superClosureUnit:TCompilerGenericUnit = EachIn superClosureConsumer.genericPlan.units
	superClosureImplementations :+ superClosureUnit.implementation
Next
Check(superClosureModuleCompilation.Succeeded() And superClosureArtifactDiagnostics.length = 0 And superClosureInterfaceDiagnostics.length = 0 And superClosureOutputs.length = 2 And superClosureInterface.Contains("RememberBase:Closure<T()>()"), "generic inheritance publishes a Super-capturing Closure through compact interfaces and canonical artifacts: outputs=" + superClosureOutputs.length + " compilation=" + CompilationSummary(superClosureModuleCompilation))
Check(superClosureConsumer.Succeeded() And superClosureConsumer.genericPlan.units.length = 2 And superClosureImplementations.Contains("capture_Self_") And superClosureImplementations.Contains("_closure_environment"), "an imported generic derived Type specializes a Super-capturing Closure without access to defining source: " + CompilationSummary(superClosureConsumer))
Local interfaceCallSource:String = "SuperStrict~nInterface ITransform<T>~nMethod Apply:T(value:T)~nEnd Interface~nType TTransform<T> Implements ITransform<T>~nMethod Apply:T(value:T)~nReturn value~nEnd Method~nEnd Type~nFunction Invoke<T>:T(transform:ITransform<T>, value:T)~nReturn transform.Apply(value)~nEnd Function~nGlobal concreteTransform:TTransform<String> = New TTransform<String>~nGlobal abstractTransform:ITransform<String> = concreteTransform~nGlobal transformedInterfaceValue:String = Invoke<String>(abstractTransform, ~qinterface-call~q)"
Local interfaceCallCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-interface-call.bmx", interfaceCallSource, Null, compilerOptions)
Check(interfaceCallCompilation.Succeeded() And interfaceCallCompilation.genericPlan.registry.nodes.length = 3 And interfaceCallCompilation.genericPlan.units.length = 3, "generic routine calls through a canonical generic Interface parameter: " + CompilationSummary(interfaceCallCompilation))
Local interfaceCallRoutineUnit:TCompilerGenericUnit
Local interfaceCallInterfaceNode:TGenericSpecializationNode
For Local interfaceCallUnit:TCompilerGenericUnit = EachIn interfaceCallCompilation.genericPlan.units
	If interfaceCallUnit.ir.isRoutine Then interfaceCallRoutineUnit = interfaceCallUnit
	If interfaceCallUnit.ir.isInterface Then interfaceCallInterfaceNode = interfaceCallUnit.specialization
Next
Check(interfaceCallRoutineUnit And interfaceCallInterfaceNode And interfaceCallRoutineUnit.implementation.Contains("bbObjectInterface") And interfaceCallRoutineUnit.implementation.Contains(interfaceCallInterfaceNode.readableAbiName + "_ifc") And interfaceCallRoutineUnit.implementation.Contains("_call_m_apply_0((BBOBJECT)transform, value)"), "specialization C selects the canonical Interface slot and passes its bound value arguments")
Check(Not interfaceCallRoutineUnit.implementation.Contains(interfaceCallInterfaceNode.readableAbiName + "_Apply(BBOBJECT"), "generic Interface calls do not invent direct implementation ownership")

Local interfaceValueFlowSource:String = "SuperStrict~nInterface IFlowTransform<T>~nMethod Apply:T(value:T)~nEnd Interface~nType TFlowTransform<T> Implements IFlowTransform<T>~nMethod Apply:T(value:T)~nReturn value~nEnd Method~nEnd Type~nType TFlowForwarder<T>~nField transform:IFlowTransform<T>~nMethod Invoke:T(value:T)~nLocal current:IFlowTransform<T> = transform~nReturn current.Apply(value)~nEnd Method~nEnd Type~nInterface IFlowProvider<T>~nMethod Current:IFlowTransform<T>()~nEnd Interface~nType TFlowProvider<T> Implements IFlowProvider<T>~nField transform:IFlowTransform<T>~nMethod Current:IFlowTransform<T>()~nReturn transform~nEnd Method~nEnd Type~nFunction InvokeReturned<T>:T(provider:IFlowProvider<T>, value:T)~nReturn provider.Current().Apply(value)~nEnd Function~nGlobal flowTransform:TFlowTransform<String> = New TFlowTransform<String>~nGlobal flowTransformView:IFlowTransform<String> = flowTransform~nGlobal flowForwarder:TFlowForwarder<String> = New TFlowForwarder<String>~nflowForwarder.transform = flowTransformView~nGlobal flowForwarded:String = flowForwarder.Invoke(~qfield-local~q)~nGlobal flowProvider:TFlowProvider<String> = New TFlowProvider<String>~nflowProvider.transform = flowTransformView~nGlobal flowProviderView:IFlowProvider<String> = flowProvider~nGlobal flowReturned:String = InvokeReturned<String>(flowProviderView, ~qreturned-interface~q)"
Local interfaceValueFlowCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-interface-value-flow.bmx", interfaceValueFlowSource, Null, compilerOptions)
Check(interfaceValueFlowCompilation.Succeeded(), "generic Interface values flow through fields, locals, and Interface-valued returns: " + CompilationSummary(interfaceValueFlowCompilation))
Local interfaceValueFlowImplementations:String
For Local interfaceValueFlowUnit:TCompilerGenericUnit = EachIn interfaceValueFlowCompilation.genericPlan.units
	interfaceValueFlowImplementations :+ interfaceValueFlowUnit.implementation
Next
Check(interfaceValueFlowImplementations.Contains("BBOBJECT bmx_local_current = self->") And interfaceValueFlowImplementations.Contains("_call_m_apply_0((BBOBJECT)bmx_local_current, value)"), "generic Type methods preserve Interface-typed field and local identities during dispatch")
Check(interfaceValueFlowImplementations.Contains("_call_m_apply_0((BBOBJECT)bmx_gen_") And interfaceValueFlowImplementations.Contains("_call_m_current_0((BBOBJECT)provider), value)"), "a generic Interface call result is evaluated once and serves as the receiver of a second canonical Interface call")

Local inheritedInterfaceCallSource:String = "SuperStrict~nInterface IRootTransform<T>~nMethod Apply:T(value:T)~nEnd Interface~nInterface IChildTransform<T> Extends IRootTransform<T>~nMethod Extra:T(value:T)~nEnd Interface~nType TChildTransform<T> Implements IChildTransform<T>~nMethod Apply:T(value:T)~nReturn value~nEnd Method~nMethod Extra:T(value:T)~nReturn value~nEnd Method~nEnd Type~nFunction InvokeInherited<T>:T(transform:IChildTransform<T>, value:T)~nReturn transform.Apply(value)~nEnd Function~nGlobal concreteChild:TChildTransform<Int> = New TChildTransform<Int>~nGlobal abstractChild:IChildTransform<Int> = concreteChild~nGlobal inheritedInterfaceValue:Int = InvokeInherited<Int>(abstractChild, 42)"
Local inheritedInterfaceCallCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-inherited-interface-call.bmx", inheritedInterfaceCallSource, Null, compilerOptions)
Check(inheritedInterfaceCallCompilation.Succeeded() And inheritedInterfaceCallCompilation.genericPlan.registry.nodes.length = 4, "generic calls resolve inherited Interface operations through the canonical closure: " + CompilationSummary(inheritedInterfaceCallCompilation))
Local inheritedInterfaceCallRoutineUnit:TCompilerGenericUnit
For Local inheritedInterfaceCallUnit:TCompilerGenericUnit = EachIn inheritedInterfaceCallCompilation.genericPlan.units
	If inheritedInterfaceCallUnit.ir.isRoutine Then inheritedInterfaceCallRoutineUnit = inheritedInterfaceCallUnit; Exit
Next
Check(inheritedInterfaceCallRoutineUnit And inheritedInterfaceCallRoutineUnit.implementation.Contains("_call_m_apply_0((BBOBJECT)transform, value)"), "inherited generic Interface calls preserve the root slot ordinal")
Local scalarExpressionSource:String = "SuperStrict~nFunction Transform<T>:T(left:T, right:T)~nReturn -(left + right * right)~nEnd Function~nFunction Narrow<T>:Int(value:Long)~nReturn Int(value)~nEnd Function~nGlobal transformed:Int = Transform(2, 4)~nGlobal narrowed:Int = Narrow<String>(42)"
Local scalarExpressionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-scalar-expressions.bmx", scalarExpressionSource, Null, compilerOptions)
Check(scalarExpressionCompilation.Succeeded() And scalarExpressionCompilation.genericPlan.units.length = 2, "generic routines retain bound scalar operator and numeric conversion expressions: " + CompilationSummary(scalarExpressionCompilation))
Local scalarExpressionImplementations:String
For Local scalarExpressionUnit:TCompilerGenericUnit = EachIn scalarExpressionCompilation.genericPlan.units
	scalarExpressionImplementations :+ scalarExpressionUnit.implementation
Next
Check(scalarExpressionImplementations.Contains("return (-(left + (right * right)));") And scalarExpressionImplementations.Contains("return ((BBINT)value);"), "closed generic scalar expressions lower deterministically in specialization-owned C units")
Local managedExpressionSource:String = "SuperStrict~nFunction Join<T>:T(left:T, right:T)~nReturn left + right~nEnd Function~nGlobal joined:String = Join(~qleft~q, ~qright~q)"
Local managedExpressionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-managed-expression.bmx", managedExpressionSource, Null, compilerOptions)
Check(managedExpressionCompilation.Succeeded() And managedExpressionCompilation.genericPlan.units.length = 1 And managedExpressionCompilation.genericPlan.units[0].implementation.Contains("return bbStringConcat(left, right);"), "closed generic String concatenation lowers through the managed runtime helper")
Local invalidIntegralExpressionSource:String = "SuperStrict~nFunction Remainder<T>:T(left:T, right:T)~nReturn left Mod right~nEnd Function~nGlobal remainder:Float = Remainder(5.0, 2.0)"
Local invalidIntegralExpressionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-invalid-integral-expression.bmx", invalidIntegralExpressionSource, Null, compilerOptions)
Check(HasCompilerDiagnostic(invalidIntegralExpressionCompilation, "BMXC3047"), "closed floating-point specializations reject integral-only operators before C emission")
Local sequentialBodySource:String = "SuperStrict~nFunction Accumulate<T>:T(first:T, second:T)~nLocal result:T = first~nresult = result + second~nLocal doubled:T~ndoubled = result + result~nReturn doubled~nEnd Function~nGlobal accumulated:Int = Accumulate(20, 1)"
Local sequentialBodyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-sequential-body.bmx", sequentialBodySource, Null, compilerOptions)
Check(sequentialBodyCompilation.Succeeded() And sequentialBodyCompilation.genericPlan.units.length = 1, "generic routine retains typed locals and sequential assignments: " + CompilationSummary(sequentialBodyCompilation))
Local sequentialBodyImplementation:String = sequentialBodyCompilation.genericPlan.units[0].implementation
Check(sequentialBodyImplementation.Contains("BBINT bmx_local_result = first;") And sequentialBodyImplementation.Contains("bmx_local_result = (bmx_local_result + second);") And sequentialBodyImplementation.Contains("BBINT bmx_local_doubled = 0;") And sequentialBodyImplementation.Contains("return bmx_local_doubled;"), "generic local declarations, defaults, assignments, and references lower in source order")
Local compoundAssignmentSource:String = "SuperStrict~nFunction CompoundUpdate<T>:Int(value:Int)~nvalue :+ 5~nvalue :* 2~nvalue :- 4~nvalue :/ 2~nReturn value~nEnd Function~nGlobal compoundUpdated:Int = CompoundUpdate<String>(3)"
Local compoundAssignmentCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-compound-assignment.bmx", compoundAssignmentSource, Null, compilerOptions)
Check(compoundAssignmentCompilation.Succeeded() And compoundAssignmentCompilation.genericPlan.units.length = 1, "generic scalar compound assignments are retained in bound template IR: " + CompilationSummary(compoundAssignmentCompilation))
Local compoundAssignmentImplementation:String = compoundAssignmentCompilation.genericPlan.units[0].implementation
Check(compoundAssignmentImplementation.Contains("value += 5;") And compoundAssignmentImplementation.Contains("value *= 2;") And compoundAssignmentImplementation.Contains("value -= 4;") And compoundAssignmentImplementation.Contains("value /= 2;"), "scalar compound assignments lower deterministically without duplicating their target expression")
Local managedCompoundAssignmentSource:String = "SuperStrict~nFunction ManagedCompound<T>:String(value:String)~nvalue :+ ~qx~q~nReturn value~nEnd Function~nGlobal managedCompound:String = ManagedCompound<Int>(~qvalue~q)"
Local managedCompoundAssignmentCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-managed-compound-assignment.bmx", managedCompoundAssignmentSource, Null, compilerOptions)
Check(HasCompilerDiagnostic(managedCompoundAssignmentCompilation, "BMXC3049"), "managed compound assignment remains explicitly diagnosed rather than receiving scalar C lowering")
Local userCompoundAssignmentSource:String = "SuperStrict~nType TMutableAmount<T>~nField value:Int~nMethod Operator :+:TMutableAmount<T>(delta:Int)~nvalue :+ delta~nReturn Self~nEnd Method~nMethod Apply:Int(delta:Int)~nSelf :+ delta~nReturn value~nEnd Method~nEnd Type~nGlobal mutableAmount:TMutableAmount<String> = New TMutableAmount<String>~nGlobal updatedAmount:Int = mutableAmount.Apply(42)"
Local userCompoundAssignmentCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-user-compound-assignment.bmx", userCompoundAssignmentSource, Null, compilerOptions)
Check(userCompoundAssignmentCompilation.Succeeded() And userCompoundAssignmentCompilation.genericPlan.units.length = 1, "a generic Type method retains its resolved user-defined compound assignment call: " + CompilationSummary(userCompoundAssignmentCompilation))
Local userCompoundAssignmentImplementation:String = userCompoundAssignmentCompilation.genericPlan.units[0].implementation
Check(userCompoundAssignmentImplementation.Contains("self->clas->") And userCompoundAssignmentImplementation.Contains(", delta);") And Not userCompoundAssignmentImplementation.Contains("self += delta"), "specialization C dispatches the selected mutating operator rather than applying native compound assignment")
Local compoundOperatorModuleSource:String = "SuperStrict~nModule Collections.MutableAmount~nType TPublishedMutableAmount<T>~nField value:Int~nMethod Operator :+:TPublishedMutableAmount<T>(delta:Int)~nvalue :+ delta~nReturn Self~nEnd Method~nMethod Apply:Int(delta:Int)~nSelf :+ delta~nReturn value~nEnd Method~nEnd Type"
Local compoundOperatorModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/mutableamount.mod/mutableamount.bmx", compoundOperatorModuleSource, Null, compilerOptions)
Local compoundOperatorArtifactDiagnostics:TCompilerDiagnostic[]
Local compoundOperatorOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(compoundOperatorModuleCompilation, compoundOperatorArtifactDiagnostics)
Local compoundOperatorInterfaceDiagnostics:TCompilerDiagnostic[]
Local compoundOperatorInterface:String = TBlitzMaxCompiler.EmitInterface(compoundOperatorModuleCompilation, compoundOperatorInterfaceDiagnostics)
Local compoundOperatorResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
compoundOperatorResolver.AddInterface("collections.mutableamount", "sdk/collections.mutableamount.i", compoundOperatorInterface)
If compoundOperatorOutputs.length Then compoundOperatorResolver.AddGenericTemplate(compoundOperatorOutputs[0].artifactReference, "sdk/" + compoundOperatorOutputs[0].artifactReference, compoundOperatorOutputs[0].content)
Local compoundOperatorConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-imported-user-compound-assignment.bmx", "SuperStrict~nImport Collections.MutableAmount~nGlobal amount:TPublishedMutableAmount<String> = New TPublishedMutableAmount<String>~nGlobal result:Int = amount.Apply(7)", compoundOperatorResolver, compilerOptions)
Check(compoundOperatorModuleCompilation.Succeeded() And compoundOperatorArtifactDiagnostics.length = 0 And compoundOperatorInterfaceDiagnostics.length = 0 And compoundOperatorOutputs.length = 1 And Not compoundOperatorOutputs[0].content.Contains("Self :+ delta"), "a module publishes its generic compound operator call as source-free canonical template data")
Check(compoundOperatorConsumer.Succeeded() And compoundOperatorConsumer.genericPlan.units.length = 1 And compoundOperatorConsumer.genericPlan.units[0].implementation.Contains("self->clas->") And Not compoundOperatorConsumer.genericPlan.units[0].implementation.Contains("self += delta"), "an imported artifact round-trips the selected compound operator and specializes it without reparsing source: " + CompilationSummary(compoundOperatorConsumer))
Local expressionOperatorSource:String = "SuperStrict~nType TExpressionAmount<T>~nField value:Int~nMethod Operator +:TExpressionAmount<T>(delta:Int)~nReturn Self~nEnd Method~nMethod Operator -:TExpressionAmount<T>()~nReturn Self~nEnd Method~nMethod Adjust:TExpressionAmount<T>(delta:Int)~nReturn -(Self + delta)~nEnd Method~nEnd Type~nGlobal expressionAmount:TExpressionAmount<String> = New TExpressionAmount<String>~nGlobal adjustedAmount:TExpressionAmount<String> = expressionAmount.Adjust(7)"
Local expressionOperatorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-user-expression-operators.bmx", expressionOperatorSource, Null, compilerOptions)
Check(expressionOperatorCompilation.Succeeded() And expressionOperatorCompilation.genericPlan.units.length = 1, "a generic Type retains resolved unary and binary operator calls: " + CompilationSummary(expressionOperatorCompilation))
Local expressionOperatorImplementation:String = expressionOperatorCompilation.genericPlan.units[0].implementation
Check(expressionOperatorImplementation.Contains("self->clas->") And expressionOperatorImplementation.Contains(", delta)") And Not expressionOperatorImplementation.Contains("self + delta") And Not expressionOperatorImplementation.Contains("-(self"), "specialization C dispatches selected unary and binary operators rather than applying native operators to managed receivers")
Local expressionOperatorModuleSource:String = "SuperStrict~nModule Collections.ExpressionAmount~nType TPublishedExpressionAmount<T>~nMethod Operator +:TPublishedExpressionAmount<T>(delta:Int)~nReturn Self~nEnd Method~nMethod Operator -:TPublishedExpressionAmount<T>()~nReturn Self~nEnd Method~nMethod Adjust:TPublishedExpressionAmount<T>(delta:Int)~nReturn -(Self + delta)~nEnd Method~nEnd Type"
Local expressionOperatorModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/expressionamount.mod/expressionamount.bmx", expressionOperatorModuleSource, Null, compilerOptions)
Local expressionOperatorArtifactDiagnostics:TCompilerDiagnostic[]
Local expressionOperatorOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(expressionOperatorModuleCompilation, expressionOperatorArtifactDiagnostics)
Local expressionOperatorInterfaceDiagnostics:TCompilerDiagnostic[]
Local expressionOperatorInterface:String = TBlitzMaxCompiler.EmitInterface(expressionOperatorModuleCompilation, expressionOperatorInterfaceDiagnostics)
Local expressionOperatorResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
expressionOperatorResolver.AddInterface("collections.expressionamount", "sdk/collections.expressionamount.i", expressionOperatorInterface)
If expressionOperatorOutputs.length Then expressionOperatorResolver.AddGenericTemplate(expressionOperatorOutputs[0].artifactReference, "sdk/" + expressionOperatorOutputs[0].artifactReference, expressionOperatorOutputs[0].content)
Local expressionOperatorConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-imported-user-expression-operators.bmx", "SuperStrict~nImport Collections.ExpressionAmount~nGlobal amount:TPublishedExpressionAmount<String> = New TPublishedExpressionAmount<String>~nGlobal result:TPublishedExpressionAmount<String> = amount.Adjust(7)", expressionOperatorResolver, compilerOptions)
Check(expressionOperatorModuleCompilation.Succeeded() And expressionOperatorArtifactDiagnostics.length = 0 And expressionOperatorInterfaceDiagnostics.length = 0 And expressionOperatorOutputs.length = 1 And Not expressionOperatorOutputs[0].content.Contains("Self + delta"), "a module publishes unary and binary generic operator calls as source-free canonical template data")
Check(expressionOperatorConsumer.Succeeded() And expressionOperatorConsumer.genericPlan.units.length = 1 And expressionOperatorConsumer.genericPlan.units[0].implementation.Contains("self->clas->") And Not expressionOperatorConsumer.genericPlan.units[0].implementation.Contains("self + delta"), "an imported artifact round-trips unary and binary operator calls without reparsing source: " + CompilationSummary(expressionOperatorConsumer))
Local structExpressionOperatorSource:String = "SuperStrict~nStruct SExpressionAmount<T>~nField value:Int~nMethod Operator +:SExpressionAmount<T>(delta:Int)~nReturn Self~nEnd Method~nMethod Operator -:SExpressionAmount<T>()~nReturn Self~nEnd Method~nMethod Adjust:SExpressionAmount<T>(delta:Int)~nReturn -(Self + delta)~nEnd Method~nEnd Struct~nGlobal expressionAmount:SExpressionAmount<String> = New SExpressionAmount<String>~nGlobal adjustedAmount:SExpressionAmount<String> = expressionAmount.Adjust(7)"
Local structExpressionOperatorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-struct-expression-operators.bmx", structExpressionOperatorSource, Null, compilerOptions)
Check(structExpressionOperatorCompilation.Succeeded() And structExpressionOperatorCompilation.genericPlan.units.length = 1 And Not structExpressionOperatorCompilation.genericPlan.units[0].implementation.Contains("self + delta") And Not structExpressionOperatorCompilation.genericPlan.units[0].implementation.Contains("-(self"), "generic Struct unary and binary operators lower as selected direct value-method calls: " + CompilationSummary(structExpressionOperatorCompilation))
Check(structExpressionOperatorCompilation.Succeeded() And structExpressionOperatorCompilation.genericPlan.units[0].implementation.Contains("(*((struct ") And structExpressionOperatorCompilation.genericPlan.units[0].implementation.Contains(" *)self))"), "generic Struct Self expressions dereference the method receiver when used as values")
Local userAssignmentOperatorSource:String = "SuperStrict~nType TMutableValue<T>~nField value:Int~nMethod Operator :=:TMutableValue<T>(nextValue:Int)~nvalue=nextValue~nReturn Self~nEnd Method~nMethod Apply:Int(nextValue:Int)~nSelf=nextValue~nReturn value~nEnd Method~nEnd Type~nGlobal mutableValue:TMutableValue<String>=New TMutableValue<String>~nGlobal assignedValue:Int=mutableValue.Apply(42)"
Local userAssignmentOperatorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-user-assignment-operator.bmx", userAssignmentOperatorSource, Null, compilerOptions)
Check(userAssignmentOperatorCompilation.Succeeded() And userAssignmentOperatorCompilation.genericPlan.units.length = 1, "a generic Type retains its resolved := call in canonical specialization data: " + CompilationSummary(userAssignmentOperatorCompilation))
Local userAssignmentOperatorImplementation:String = userAssignmentOperatorCompilation.genericPlan.units[0].implementation
Check(userAssignmentOperatorImplementation.Contains("self->clas->") And userAssignmentOperatorImplementation.Contains(", nextValue);") And Not userAssignmentOperatorImplementation.Contains("self = nextValue"), "specialization C invokes the selected := implementation rather than replacing the generic receiver")
Local managedArraySource:String = "SuperStrict~nFunction ArrayRoundTrip<T>:T(value:T)~nLocal data:T[] = New T[2]~ndata[0] = value~nLocal count:Int = data.length~nReturn data[count - 2]~nEnd Function~nGlobal arrayText:String = ArrayRoundTrip<String>(~qvalue~q)"
Local managedArrayCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-managed-array.bmx", managedArraySource, Null, compilerOptions)
Check(managedArrayCompilation.Succeeded() And managedArrayCompilation.genericPlan.units.length = 1, "generic managed Array allocation, length, indexed write, and indexed read survive source-free specialization: " + CompilationSummary(managedArrayCompilation))
Local managedArrayImplementation:String = managedArrayCompilation.genericPlan.units[0].implementation
Check(managedArrayImplementation.Contains("BBARRAY bmx_local_data = bbArrayNew1D(~q$~q, 2);") And managedArrayImplementation.Contains("((BBSTRING*)BBARRAYDATA(bmx_local_data, 1))[0] = value;") And managedArrayImplementation.Contains("BBINT bmx_local_count = (bmx_local_data->scales[0]);") And managedArrayImplementation.Contains("return ((BBSTRING*)BBARRAYDATA(bmx_local_data, 1))[(bmx_local_count - 2)];"), "closed String Array operations lower to the established runtime ABI only in the specialization C unit")
Local managedArrayAppendSource:String = "SuperStrict~nFunction AppendOne<T>:T[](values:T[],value:T)~nvalues :+ [value]~nReturn values~nEnd Function~nGlobal appended:String[]=AppendOne<String>([~qfirst~q],~qsecond~q)"
Local managedArrayAppendCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-managed-array-append.bmx", managedArrayAppendSource, Null, compilerOptions)
Check(managedArrayAppendCompilation.Succeeded() And managedArrayAppendCompilation.genericPlan.units.length = 1, "generic managed Array compound append survives source-free specialization: " + CompilationSummary(managedArrayAppendCompilation))
Local managedArrayAppendImplementation:String = managedArrayAppendCompilation.genericPlan.units[0].implementation
Check(managedArrayAppendImplementation.Contains("values = bbArrayConcat(~q$~q, values,") And managedArrayAppendImplementation.Contains("bbArrayNew1D(~q$~q, 1)"), "generic Array :+ lowers through the managed Array concatenation ABI after element substitution")
Local managedArrayExpressionSource:String = "SuperStrict~nStruct SArrayExpressionCell<T>~nField value:T~nEnd Struct~nFunction Duplicate<T>:SArrayExpressionCell<T>[](value:T)~nLocal cell:SArrayExpressionCell<T>~ncell.value=value~nLocal values:SArrayExpressionCell<T>[]=[cell]~nReturn values + [cell]~nEnd Function~nGlobal duplicated:SArrayExpressionCell<String>[]=Duplicate<String>(~qvalue~q)"
Local managedArrayExpressionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-managed-array-expression.bmx", managedArrayExpressionSource, Null, compilerOptions)
Check(managedArrayExpressionCompilation.Succeeded() And managedArrayExpressionCompilation.genericPlan.units.length >= 1, "generic Array + accepts matching closed arrays of generic Struct values: " + CompilationSummary(managedArrayExpressionCompilation))
Local managedArrayExpressionImplementation:String
For Local unit:TCompilerGenericUnit = EachIn managedArrayExpressionCompilation.genericPlan.units
	managedArrayExpressionImplementation :+ unit.implementation
Next
Check(managedArrayExpressionImplementation.Contains("bbArrayConcat("), "generic Array + lowers through the managed Array concatenation ABI")
Check(Not managedArrayExpressionImplementation.Contains("bbArrayNew1DStruct_("), "generic Struct Array allocation names the specialization-owned element initializer helper")
Local genericStructClosureCallSource:String = "SuperStrict~nStruct SClosureCell<T>~nField value:T~nField transform:Closure<T(value:T)>~nEnd Struct~nType TClosurePayload~nField text:String~nEnd Type~nGlobal cell:SClosureCell<TClosurePayload>~nGlobal transformed:TClosurePayload=cell.transform(cell.value)"
Local genericStructClosureCallCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-struct-closure-call.bmx", genericStructClosureCallSource, Null, compilerOptions)
Check(genericStructClosureCallCompilation.Succeeded(), "a Closure field read from a closed generic Struct retains its substituted callable signature during ordinary IR lowering: " + CompilationSummary(genericStructClosureCallCompilation))
Local multiLevelGenericInheritanceSource:String = "SuperStrict~nType TInheritanceBase<A,B>~nMethod Describe:String()~nReturn ~qbase~q~nEnd Method~nEnd Type~nType TInheritanceMiddle<X> Extends TInheritanceBase<String,X[]>~nMethod Describe:String() Override~nReturn ~qmiddle~q~nEnd Method~nEnd Type~nType TInheritanceLeaf<Y> Extends TInheritanceMiddle<Y>~nMethod Describe:String() Override~nReturn ~qleaf~q~nEnd Method~nEnd Type~nType TInheritancePayload~nEnd Type~nGlobal leaf:TInheritanceLeaf<TInheritancePayload>=New TInheritanceLeaf<TInheritancePayload>~nGlobal base:TInheritanceBase<String,TInheritancePayload[]>=leaf~nGlobal description:String=base.Describe()"
Local multiLevelGenericInheritanceCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-multilevel-inheritance.bmx", multiLevelGenericInheritanceSource, Null, compilerOptions)
Check(multiLevelGenericInheritanceCompilation.Succeeded(), "a multi-level generic base whose type argument is itself an Array retains its closed virtual dispatch identity: " + CompilationSummary(multiLevelGenericInheritanceCompilation))
Local compositionModuleSource:String = "SuperStrict~nModule Acme.CompositionBoundary~nStruct SPublishedCell<T>~nField value:T~nField transform:Closure<T(value:T)>~nEnd Struct~nFunction DuplicatePublished<T>:SPublishedCell<T>[](value:T,transform:Closure<T(value:T)>)~nLocal cell:SPublishedCell<T>~ncell.value=value~ncell.transform=transform~nLocal values:SPublishedCell<T>[]=[cell]~nReturn values+[cell]~nEnd Function~nFunction PublishedDefault<T>:T(value:T=Null)~nReturn value~nEnd Function~nType TPublishedBase<A,B>~nMethod Describe:String()~nReturn ~qbase~q~nEnd Method~nEnd Type~nType TPublishedMiddle<X> Extends TPublishedBase<String,X[]>~nMethod Describe:String() Override~nReturn ~qmiddle~q~nEnd Method~nEnd Type~nType TPublishedLeaf<Y> Extends TPublishedMiddle<Y>~nMethod Describe:String() Override~nReturn ~qleaf~q~nEnd Method~nEnd Type"
Local compositionModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/acme.mod/compositionboundary.mod/compositionboundary.bmx", compositionModuleSource, Null, compilerOptions)
Local compositionArtifactDiagnostics:TCompilerDiagnostic[]
Local compositionOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(compositionModuleCompilation, compositionArtifactDiagnostics)
Local compositionInterfaceDiagnostics:TCompilerDiagnostic[]
Local compositionInterface:String = TBlitzMaxCompiler.EmitInterface(compositionModuleCompilation, compositionInterfaceDiagnostics)
Local compositionResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
compositionResolver.AddInterface("acme.compositionboundary", "sdk/acme.compositionboundary.i", compositionInterface)
For Local compositionOutput:TCompilerGenericTemplateOutput = EachIn compositionOutputs
	compositionResolver.AddGenericTemplate(compositionOutput.artifactReference, "sdk/" + compositionOutput.artifactReference, compositionOutput.content)
Next
Local compositionConsumerSource:String = "SuperStrict~nImport Acme.CompositionBoundary~nGlobal transform:Closure<String(value:String)>=Function(value:String)~nReturn value+~q!~q~nEnd Function~nGlobal cells:SPublishedCell<String>[]=DuplicatePublished<String>(~qx~q,transform)~nGlobal defaultAction:Closure<Int()>=PublishedDefault<Closure<Int()>>()~nGlobal leaf:TPublishedLeaf<String>=New TPublishedLeaf<String>~nGlobal base:TPublishedBase<String,String[]>=leaf~nGlobal label:String=base.Describe()"
Local compositionConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-imported-composition-boundaries.bmx", compositionConsumerSource, compositionResolver, compilerOptions)
Local compositionImplementations:String
If compositionConsumer.genericPlan Then
	For Local compositionUnit:TCompilerGenericUnit = EachIn compositionConsumer.genericPlan.units
		compositionImplementations :+ compositionUnit.implementation
	Next
End If
Check(compositionModuleCompilation.Succeeded() And compositionArtifactDiagnostics.length = 0 And compositionInterfaceDiagnostics.length = 0 And compositionConsumer.Succeeded(), "generic composition boundaries round-trip through compact interfaces and source-free templates: " + CompilationSummary(compositionConsumer))
Check(compositionImplementations.Contains("bbArrayConcat(") And Not compositionImplementations.Contains("bbArrayNew1DStruct_("), "source-free generic Struct Array composition retains its specialization-owned helpers")
Local managedArrayAppendModuleSource:String = "SuperStrict~nModule Collections.ArrayAppend~nFunction AppendOne<T>:T[](values:T[],value:T)~nvalues :+ [value]~nReturn values~nEnd Function"
Local managedArrayAppendModule:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/arrayappend.mod/arrayappend.bmx", managedArrayAppendModuleSource, Null, compilerOptions)
Local managedArrayAppendArtifactDiagnostics:TCompilerDiagnostic[]
Local managedArrayAppendOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(managedArrayAppendModule, managedArrayAppendArtifactDiagnostics)
Local managedArrayAppendInterfaceDiagnostics:TCompilerDiagnostic[]
Local managedArrayAppendInterface:String = TBlitzMaxCompiler.EmitInterface(managedArrayAppendModule, managedArrayAppendInterfaceDiagnostics)
Local managedArrayAppendResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
managedArrayAppendResolver.AddInterface("collections.arrayappend", "sdk/collections.arrayappend.i", managedArrayAppendInterface)
If managedArrayAppendOutputs.length Then managedArrayAppendResolver.AddGenericTemplate(managedArrayAppendOutputs[0].artifactReference, "sdk/" + managedArrayAppendOutputs[0].artifactReference, managedArrayAppendOutputs[0].content)
Local managedArrayAppendConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-imported-array-append.bmx", "SuperStrict~nImport Collections.ArrayAppend~nGlobal appended:String[]=AppendOne<String>([~qfirst~q],~qsecond~q)", managedArrayAppendResolver, compilerOptions)
Check(managedArrayAppendModule.Succeeded() And managedArrayAppendArtifactDiagnostics.length = 0 And managedArrayAppendInterfaceDiagnostics.length = 0 And managedArrayAppendOutputs.length = 1 And managedArrayAppendConsumer.Succeeded() And managedArrayAppendConsumer.genericPlan.units.length = 1 And managedArrayAppendConsumer.genericPlan.units[0].implementation.Contains("values = bbArrayConcat(~q$~q, values,"), "imported generic Array :+ round-trips through its source-free canonical template: " + CompilationSummary(managedArrayAppendConsumer))
Local managedArraySliceSource:String = "SuperStrict~nFunction ArraySliceRoundTrip<T>:T(value:T)~nLocal data:T[] = New T[3]~ndata[1] = value~nLocal selected:T[] = data[1..]~nReturn selected[0]~nEnd Function~nGlobal slicedText:String = ArraySliceRoundTrip<String>(~qvalue~q)"
Local managedArraySliceCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-managed-array-slice.bmx", managedArraySliceSource, Null, compilerOptions)
Check(managedArraySliceCompilation.Succeeded() And managedArraySliceCompilation.genericPlan.units.length = 1, "generic managed Array slicing survives source-free specialization: " + CompilationSummary(managedArraySliceCompilation))
Local managedArraySliceImplementation:String = managedArraySliceCompilation.genericPlan.units[0].implementation
Check(managedArraySliceImplementation.Contains("BBARRAY bmx_local_selected = bbArraySlice(~q$~q, bmx_local_data, 1, (bmx_local_data->scales[0]));") And managedArraySliceImplementation.Contains("return ((BBSTRING*)BBARRAYDATA(bmx_local_selected, 1))[0];"), "closed String Array slicing lowers through the established runtime ABI with normalized omitted bounds")
Local multidimensionalGenericArraySource:String = "SuperStrict~nFunction MatrixRoundTrip<T>:T(value:T)~nLocal matrix:T[,] = New T[2,3]~nmatrix[1,2] = value~nFor Local item:T = EachIn matrix~nIf item = value Then Return matrix[1,2]~nNext~nEnd Function~nGlobal matrixText:String = MatrixRoundTrip<String>(~qmatrix~q)"
Local multidimensionalGenericArrayCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-multidimensional-array.bmx", multidimensionalGenericArraySource, Null, compilerOptions)
Check(multidimensionalGenericArrayCompilation.Succeeded() And multidimensionalGenericArrayCompilation.genericPlan.units.length = 1, "multidimensional generic managed Arrays survive source-free allocation, indexing, and flattened EachIn: " + CompilationSummary(multidimensionalGenericArrayCompilation))
Local multidimensionalGenericArrayImplementation:String = multidimensionalGenericArrayCompilation.genericPlan.units[0].implementation
Check(multidimensionalGenericArrayImplementation.Contains("bbArrayNew(~q$~q, 2, 2, 3)") And multidimensionalGenericArrayImplementation.Contains("->scales[1]") And multidimensionalGenericArrayImplementation.Contains("->scales[0]"), "multidimensional generic Arrays emit rank-aware allocation, row-major scale indexing, and total-length iteration")
Local importedGridStructModule:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/acme.mod/genericgrid.mod/genericgrid.bmx", "SuperStrict~nModule Acme.GenericGrid~nStruct SGridCell~nField text:String~nEnd Struct", Null, compilerOptions)
Local importedGridStructInterfaceDiagnostics:TCompilerDiagnostic[]
Local importedGridStructInterface:String = TBlitzMaxCompiler.EmitInterface(importedGridStructModule, importedGridStructInterfaceDiagnostics)
Local importedGridStructResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
importedGridStructResolver.AddInterface("acme.genericgrid", "sdk/acme.genericgrid.i", importedGridStructInterface)
Local importedGridGenericSource:String = "SuperStrict~nImport Acme.GenericGrid~nFunction BuildImportedGrid<T>:T(value:T)~nLocal grid:SGridCell[,] = New SGridCell[2,3]~ngrid[1,2].text = ~qcell~q~nReturn value~nEnd Function~nGlobal importedGridValue:String = BuildImportedGrid<String>(~qvalue~q)"
Local importedGridGenericCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-imported-struct-grid.bmx", importedGridGenericSource, importedGridStructResolver, compilerOptions)
Check(importedGridStructModule.Succeeded() And importedGridStructInterfaceDiagnostics.length = 0 And importedGridGenericCompilation.Succeeded() And importedGridGenericCompilation.genericPlan.units.length = 1, "a generic body retains a published ordinary Struct identity for multidimensional allocation: " + CompilationSummary(importedGridGenericCompilation))
Local importedGridGenericImplementation:String = importedGridGenericCompilation.genericPlan.units[0].implementation
Check(importedGridGenericImplementation.Contains("bbArrayNewStruct(~q@SGridCell~q, sizeof(struct acme_genericgrid_SGridCell), bbStructElementInit_acme_genericgrid_SGridCell, 2, 2, 3)") And importedGridGenericImplementation.Contains("->scales[1]"), "a generic specialization delegates every imported Struct cell to the producer-owned rank-independent initializer ABI")
Local genericObjectArrayAdaptationSource:String = "SuperStrict~nFunction ProbeObjectElements<T>:T(value:T, objects:Object[])~nFor Local text:String = EachIn objects~nNext~nFor Local number:Int = EachIn objects~nNext~nFor Local row:T[] = EachIn objects~nNext~nReturn value~nEnd Function~nGlobal objectElements:Object[] = [~qtext~q]~nGlobal adaptedObjectElements:String = ProbeObjectElements<String>(~qvalue~q, objectElements)"
Local genericObjectArrayAdaptationCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-object-array-adaptation.bmx", genericObjectArrayAdaptationSource, Null, compilerOptions)
Check(genericObjectArrayAdaptationCompilation.Succeeded(), "generic Object Array EachIn supports String, numeric, and nested managed-Array targets: " + CompilationSummary(genericObjectArrayAdaptationCompilation))
Local genericObjectArrayAdaptationImplementation:String = genericObjectArrayAdaptationCompilation.genericPlan.units[0].implementation
Check(genericObjectArrayAdaptationImplementation.Contains("bbObjectIsString") And genericObjectArrayAdaptationImplementation.Contains("bbObjectStringcast") And genericObjectArrayAdaptationImplementation.Contains("bbObjectToFieldOffset") And genericObjectArrayAdaptationImplementation.Contains("bbArrayCastFromObject") And genericObjectArrayAdaptationImplementation.Contains("~q[]$~q"), "generic Object Array adaptation emits the production String filter, numeric unbox, and complete nested-Array runtime encoding")
Local genericObjectToArrayCastSource:String = "SuperStrict~nFunction CastObjectArray<T>:T[](value:Object)~nReturn T[](value)~nEnd Function~nGlobal missing:Object~nGlobal emptyStrings:String[] = CastObjectArray<String>(missing)"
Local genericObjectToArrayCastCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-object-to-array-cast.bmx", genericObjectToArrayCastSource, Null, compilerOptions)
Check(genericObjectToArrayCastCompilation.Succeeded() And genericObjectToArrayCastCompilation.genericPlan.units.length = 1, "generic Object-to-Array casts retain their closed target shape: " + CompilationSummary(genericObjectToArrayCastCompilation))
Local genericObjectToArrayCastImplementation:String = genericObjectToArrayCastCompilation.genericPlan.units[0].implementation
Check(genericObjectToArrayCastImplementation.Contains("bbArrayCastFromObject((BBOBJECT)") And genericObjectToArrayCastImplementation.Contains("~q$~q") And Not genericObjectToArrayCastImplementation.Contains("((BBARRAY)"), "generic Object-to-Array casts canonicalize Null through the runtime with the closed element encoding")
Local genericManagedNarrowingSource:String = "SuperStrict~nInterface IManagedCast~nEnd Interface~nType TManagedCast Implements IManagedCast~nEnd Type~nFunction CastManagedType<T>:TManagedCast(value:Object)~nReturn TManagedCast(value)~nEnd Function~nFunction CastManagedInterface<T>:IManagedCast(value:Object)~nReturn IManagedCast(value)~nEnd Function~nFunction CastManagedString<T>:String(value:Object)~nReturn String(value)~nEnd Function~nGlobal managedCastType:TManagedCast = CastManagedType<Int>(Null)~nGlobal managedCastInterface:IManagedCast = CastManagedInterface<Int>(Null)~nGlobal managedCastString:String = CastManagedString<Int>(Null)"
Local genericManagedNarrowingCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-managed-narrowing.bmx", genericManagedNarrowingSource, Null, compilerOptions)
Local genericManagedNarrowingImplementation:String
For Local genericManagedNarrowingUnit:TCompilerGenericUnit = EachIn genericManagedNarrowingCompilation.genericPlan.units
	genericManagedNarrowingImplementation :+ genericManagedNarrowingUnit.implementation
Next
Check(genericManagedNarrowingCompilation.Succeeded() And genericManagedNarrowingImplementation.Contains("bbObjectDowncast((BBOBJECT)") And genericManagedNarrowingImplementation.Contains("bbInterfaceDowncast((BBOBJECT)") And genericManagedNarrowingImplementation.Contains("bbObjectStringcast((BBOBJECT)"), "explicit managed narrowing in generic bodies uses target-specific runtime checks instead of the raw C cast fallback: " + CompilationSummary(genericManagedNarrowingCompilation))
Local sideEffectingSliceSource:String = "SuperStrict~nType TSliceFactory<T>~nField value:T~nMethod Values:T[]()~nReturn [value,value]~nEnd Method~nMethod Read:T()~nLocal selected:T[] = Values()[1..]~nReturn selected[0]~nEnd Method~nEnd Type~nGlobal sliceFactory:TSliceFactory<String> = New TSliceFactory<String>~nsliceFactory.value = ~qonce~q~nGlobal sideEffectSlice:String = sliceFactory.Read()"
Local sideEffectingSliceCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-side-effecting-slice.bmx", sideEffectingSliceSource, Null, compilerOptions)
Check(sideEffectingSliceCompilation.Succeeded(), "side-effecting generic Array slice receivers survive source-free specialization: " + CompilationSummary(sideEffectingSliceCompilation))
Local sideEffectingSliceImplementation:String = sideEffectingSliceCompilation.genericPlan.units[0].implementation
Check(sideEffectingSliceImplementation.Contains("BBARRAY bmx_array_receiver_materialized_receiver_") And Occurrences(sideEffectingSliceImplementation, "->clas->m_values_") = 1 And sideEffectingSliceImplementation.Contains("bbArraySlice(~q$~q, bmx_array_receiver_"), "generic Array slices materialize an unstable receiver exactly once and reuse it for omitted bounds")
Local genericStaticArrayStorageSource:String = "SuperStrict~nStruct SStaticCell<T>~nField value:T~nEnd Struct~nFunction StaticCells<T>:T(value:T)~nLocal StaticArray cells:SStaticCell<T>[2]~ncells[1].value = value~nFor Local cell:SStaticCell<T> = EachIn cells~nIf cell.value = value Then Return cell.value~nNext~nEnd Function~nGlobal staticCellText:String = StaticCells<String>(~qfixed~q)"
Local genericStaticArrayStorageCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-static-array-storage.bmx", genericStaticArrayStorageSource, Null, compilerOptions)
Check(genericStaticArrayStorageCompilation.Succeeded(), "generic-local Struct-element StaticArray storage, indexing, and EachIn specialize without source: " + CompilationSummary(genericStaticArrayStorageCompilation))
Local genericStaticArrayStorageImplementation:String = genericStaticArrayStorageCompilation.genericPlan.units[genericStaticArrayStorageCompilation.genericPlan.units.length - 1].implementation
Check(genericStaticArrayStorageImplementation.Contains("#ifndef BMX_GENERIC_STRUCT_") And genericStaticArrayStorageImplementation.Contains("_New(void);") And genericStaticArrayStorageImplementation.Contains("bmx_local_cells[2] = {0}") And genericStaticArrayStorageImplementation.Contains("_New_ObjectNew()") And genericStaticArrayStorageImplementation.Contains("bmx_loop0_collection[bmx_loop0_index]"), "generic-local Struct StaticArrays emit a complete dependency layout, fixed inline storage, element construction, and typed iteration")
Local indexOperatorSource:String = "SuperStrict~nType TIndexBox<T>~nField value:T~nMethod Operator[]:T(index:Int)~nReturn value~nEnd Method~nMethod Operator[]=(index:Int, newValue:T)~nvalue = newValue~nEnd Method~nEnd Type~nFunction ReadIndex<T>:T(box:TIndexBox<T>)~nReturn box[0]~nEnd Function~nFunction WriteIndex<T>:T(box:TIndexBox<T>, value:T)~nbox[0] = value~nReturn value~nEnd Function~nGlobal indexedBox:TIndexBox<String> = New TIndexBox<String>~nGlobal writtenValue:String = WriteIndex<String>(indexedBox, ~qvalue~q)~nGlobal indexedValue:String = ReadIndex<String>(indexedBox)"
Local indexOperatorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-index-operator.bmx", indexOperatorSource, Null, compilerOptions)
Check(indexOperatorCompilation.Succeeded() And indexOperatorCompilation.genericPlan.units.length = 3, "generic user-defined index getter and setter calls create one canonical receiver specialization: " + CompilationSummary(indexOperatorCompilation))
Local indexOperatorImplementations:String
For Local indexOperatorUnit:TCompilerGenericUnit = EachIn indexOperatorCompilation.genericPlan.units
	indexOperatorImplementations :+ indexOperatorUnit.implementation
Next
Check(indexOperatorImplementations.Contains("->clas->") And indexOperatorImplementations.Contains("indexedBox") = False, "generic index access lowers to specialization-owned virtual slots without copied source or application globals")
Local expressionStatementSource:String = "SuperStrict~nFunction Observe<T>(value:T)~nEnd Function~nFunction UseObserve<T>:T(value:T)~nObserve<T>(value)~nReturn value~nEnd Function~nGlobal observedText:String = UseObserve<String>(~qvalue~q)"
Local expressionStatementCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-expression-statement.bmx", expressionStatementSource, Null, compilerOptions)
Check(expressionStatementCompilation.Succeeded() And expressionStatementCompilation.genericPlan.units.length = 2, "generic call expression statements retain their transitive specialization request: " + CompilationSummary(expressionStatementCompilation))
Local expressionStatementImplementations:String
For Local expressionStatementUnit:TCompilerGenericUnit = EachIn expressionStatementCompilation.genericPlan.units
	expressionStatementImplementations :+ expressionStatementUnit.implementation
Next
Check(expressionStatementImplementations.Contains("(void)bmx_gen_") And expressionStatementImplementations.Contains("_Observe_") And expressionStatementImplementations.Contains("return value;") And expressionStatementImplementations.Contains("return;"), "generic call expression statement emits an owned call and valid empty Void callee without moving the callee implementation into the caller unit")
Local throwSource:String = "SuperStrict~nModule Collections.GenericThrow~nType TGenericFailure~nEnd Type~nFunction RequireNonNegative<T>:Int(value:Int)~nIf value < 0 Then~nThrow New TGenericFailure~nEnd If~nReturn value~nEnd Function~nGlobal requiredValue:Int = RequireNonNegative<String>(42)"
Local throwCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/genericthrow.mod/genericthrow.bmx", throwSource, Null, compilerOptions)
Check(throwCompilation.Succeeded() And throwCompilation.genericPlan.units.length = 1, "generic Throw retains an ordinary zero-argument exception allocation: " + CompilationSummary(throwCompilation))
Local throwImplementation:String = throwCompilation.genericPlan.units[0].implementation
Check(throwImplementation.Contains("bbExThrow((BBObject *)((struct ") And throwImplementation.Contains("_obj *)bbObjectNew((BBClass *)&") And throwImplementation.Contains("return value;"), "generic Throw lowers ordinary default construction and the established exception runtime call in its specialization unit")
Local invalidThrowSource:String = "SuperStrict~nFunction ThrowScalar<T>()~nThrow 1~nEnd Function~nThrowScalar<Int>()"
Local invalidThrowCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-invalid-throw.bmx", invalidThrowSource, Null, compilerOptions)
Check(HasCompilerDiagnostic(invalidThrowCompilation, "BMXC3066"), "generic Throw rejects scalar expressions explicitly")
Local unsupportedManagedArraySource:String = "SuperStrict~nFunction ObjectArray<T>:Object(value:Object)~nLocal data:Object[] = New Object[1]~ndata[0] = value~nReturn data[0]~nEnd Function~nGlobal objectArrayValue:Object = ObjectArray<Int>(~qvalue~q)"
Local unsupportedManagedArrayCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-managed-object-array.bmx", unsupportedManagedArraySource, Null, compilerOptions)
Check(unsupportedManagedArrayCompilation.Succeeded() And unsupportedManagedArrayCompilation.genericPlan.units[0].implementation.Contains("bbArrayNew1D(~q:Object~q, 1)") And unsupportedManagedArrayCompilation.genericPlan.units[0].implementation.Contains("((BBOBJECT*)BBARRAYDATA"), "generic Object Arrays use the managed-reference Array ABI: " + CompilationSummary(unsupportedManagedArrayCompilation))
Local canonicalTypeArraySource:String = "SuperStrict~nType TArrayNode<T>~nField value:T~nEnd Type~nFunction CanonicalTypeArray<T>:T(value:T)~nLocal nodes:TArrayNode<T>[] = New TArrayNode<T>[1]~nLocal node:TArrayNode<T> = New TArrayNode<T>~nnode.value = value~nnodes[0] = node~nReturn nodes[0].value~nEnd Function~nGlobal canonicalArrayValue:String = CanonicalTypeArray<String>(~qvalue~q)"
Local canonicalTypeArrayCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-managed-canonical-type-array.bmx", canonicalTypeArraySource, Null, compilerOptions)
Local canonicalTypeArrayImplementation:String
For Local canonicalTypeArrayUnit:TCompilerGenericUnit = EachIn canonicalTypeArrayCompilation.genericPlan.units
	If canonicalTypeArrayUnit.ir.isRoutine Then canonicalTypeArrayImplementation = canonicalTypeArrayUnit.implementation; Exit
Next
Check(canonicalTypeArrayCompilation.Succeeded() And canonicalTypeArrayImplementation.Contains("bbArrayNew1D(~q:bmx_gen_") And canonicalTypeArrayImplementation.Contains("_obj **)BBARRAYDATA"), "generic Arrays of canonical Type references retain their specialization identity and pointer element ABI: " + CompilationSummary(canonicalTypeArrayCompilation))
Local pointerValueSource:String = "SuperStrict~nType TPointerBox<T>~nField value:T~nField values:T[]~nMethod Store:T(item:T)~nvalue = item~nvalues = New T[1]~nvalues[0] = item~nReturn values[0]~nEnd Method~nMethod IsSet:Int()~nReturn value <> Null~nEnd Method~nEnd Type~nGlobal pointerBox:TPointerBox<Byte Ptr> = New TPointerBox<Byte Ptr>~nGlobal pointerValue:Byte Ptr = pointerBox.Store(Null)~nGlobal pointerSet:Int = pointerBox.IsSet()"
Local pointerValueCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-pointer-value.bmx", pointerValueSource, Null, compilerOptions)
Local pointerValueImplementation:String
If pointerValueCompilation.genericPlan And pointerValueCompilation.genericPlan.units.length Then pointerValueImplementation = pointerValueCompilation.genericPlan.units[0].implementation
Check(pointerValueCompilation.Succeeded() And pointerValueImplementation.Contains("BBBYTE *") And pointerValueImplementation.Contains("bbArrayNew1D(~q*b~q, 1)") And pointerValueImplementation.Contains("((BBBYTE **)BBARRAYDATA") And pointerValueImplementation.Contains("((BBBYTE *)0)"), "generic pointer fields, parameters, returns, Null conversions, equality, and heap Arrays retain their closed pointer ABI: " + CompilationSummary(pointerValueCompilation))
Local arraySentinelSource:String = "SuperStrict~nType TArraySentinel<T>~nField values:Int[]~nMethod Clear()~nvalues = Null~nEnd Method~nMethod IsEmpty:Int()~nReturn values = Null~nEnd Method~nEnd Type~nGlobal arraySentinel:TArraySentinel<String> = New TArraySentinel<String>"
Local arraySentinelCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-array-sentinel.bmx", arraySentinelSource, Null, compilerOptions)
Local arraySentinelImplementation:String
If arraySentinelCompilation.genericPlan And arraySentinelCompilation.genericPlan.units.length Then arraySentinelImplementation = arraySentinelCompilation.genericPlan.units[0].implementation
Check(arraySentinelCompilation.Succeeded() And arraySentinelImplementation.Contains("values = &bbEmptyArray") And arraySentinelImplementation.Contains("values == &bbEmptyArray") And Not arraySentinelImplementation.Contains("((BBARRAY)&bbNullObject)") And Not arraySentinelImplementation.Contains("(BBOBJECT)&bbNullObject"), "generic managed Array assignment and equality use the canonical Array sentinel: " + CompilationSummary(arraySentinelCompilation))
Local sourceArgumentSource:String = "SuperStrict~nType TSourceKey~nField id:Int~nEnd Type~nType TSourceBox<T>~nField value:T~nMethod Store:T(item:T)~nvalue=item~nReturn value~nEnd Method~nEnd Type~nGlobal sourceBox:TSourceBox<TSourceKey>~nGlobal sourceKey:TSourceKey~nGlobal sourceValue:TSourceKey=sourceBox.Store(sourceKey)"
Local sourceArgumentCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-source-argument.bmx", sourceArgumentSource, Null, compilerOptions)
Local sourceArgumentDiagnostics:TCompilerDiagnostic[]
Local sourceArgumentC:String = TBlitzMaxCompiler.EmitRuntimeC(sourceArgumentCompilation, sourceArgumentDiagnostics)
Local sourceArgumentAbi:String
If sourceArgumentCompilation.genericPlan Then sourceArgumentAbi = String(sourceArgumentCompilation.genericPlan.runtimeArgumentSymbols.ValueForKey(sourceArgumentCompilation.analysis.model.globalScope.LookupLocal("TSourceKey")[0]))
Check(sourceArgumentCompilation.Succeeded() And sourceArgumentCompilation.genericPlan.units.length = 1 And sourceArgumentAbi.StartsWith("bmx_direct_tsourcekey_"), "a source-local ordinary Type has a canonical source identity and stable runtime ABI when used as a specialization argument: " + CompilationSummary(sourceArgumentCompilation))
Check(sourceArgumentDiagnostics.length = 0 And sourceArgumentC.Contains("struct BBClass_" + sourceArgumentAbi) And sourceArgumentC.Contains(" " + sourceArgumentAbi + " = {") And sourceArgumentCompilation.genericPlan.units[0].implementation.Contains("struct " + sourceArgumentAbi + "_obj *"), "the application descriptor and separate specialization unit agree on the source-argument C identity")
Local sourceArgumentInterfaceSource:String = "SuperStrict~nInterface ISourceCompare<T>~nMethod Same:Int(left:T,right:T)~nEnd Interface~nType TComparedKey~nField id:Int~nEnd Type~nType TSourceComparator Implements ISourceCompare<TComparedKey>~nMethod Same:Int(left:TComparedKey,right:TComparedKey)~nReturn left=right~nEnd Method~nEnd Type~nGlobal sourceComparator:TSourceComparator"
Local sourceArgumentInterfaceCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-source-argument-interface.bmx", sourceArgumentInterfaceSource, Null, compilerOptions)
Check(sourceArgumentInterfaceCompilation.Succeeded() And sourceArgumentInterfaceCompilation.genericPlan.units.length = 1 And sourceArgumentInterfaceCompilation.ir.classes.length = 2 And sourceArgumentInterfaceCompilation.ir.classes[1].interfaceImplementations.length = 1 And sourceArgumentInterfaceCompilation.ir.classes[1].interfaceImplementations[0].slots[0].functionId.length, "source methods satisfy a canonical generic Interface after its source-local Type argument is mapped back from stable runtime identity: " + CompilationSummary(sourceArgumentInterfaceCompilation))
Local sourceArgumentInterfaceAbi:String = String(sourceArgumentInterfaceCompilation.genericPlan.runtimeArgumentSymbols.ValueForKey(sourceArgumentInterfaceCompilation.analysis.model.globalScope.LookupLocal("TComparedKey")[0]))
Local sourceArgumentInterfaceUnit:TCompilerGenericUnit = sourceArgumentInterfaceCompilation.genericPlan.units[0]
Check(AppearsBefore(sourceArgumentInterfaceUnit.implementation, "struct " + sourceArgumentInterfaceAbi + "_obj;", "struct " + sourceArgumentInterfaceUnit.specialization.readableAbiName + "_methods {"), "standalone generic Interface units forward ordinary Type arguments before method-table prototypes give their C tags prototype scope")
Local structReturningInterfaceSource:String = "SuperStrict~nStruct SInterfaceValue<T>~nField value:T~nEnd Struct~nInterface IStructIterator<T>~nMethod Current:T()~nEnd Interface~nGlobal structIterator:IStructIterator<SInterfaceValue<Int>>"
Local structReturningInterfaceCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-interface-struct-result.bmx", structReturningInterfaceSource, Null, compilerOptions)
Local structReturningInterfaceUnit:TCompilerGenericUnit
Local interfaceResultStructUnit:TCompilerGenericUnit
For Local unit:TCompilerGenericUnit = EachIn structReturningInterfaceCompilation.genericPlan.units
	If unit.ir.isInterface Then structReturningInterfaceUnit = unit
	If unit.ir.isStruct Then interfaceResultStructUnit = unit
Next
Check(structReturningInterfaceCompilation.Succeeded() And structReturningInterfaceUnit And interfaceResultStructUnit And AppearsBefore(structReturningInterfaceUnit.implementation, "struct " + interfaceResultStructUnit.specialization.readableAbiName + " {", "struct " + structReturningInterfaceUnit.specialization.readableAbiName + "_methods {"), "standalone generic Interface units define generic Struct results before C method tables and inline helpers")
Local interfaceArgumentStructSource:String = "SuperStrict~nInterface IValueMarker<T>~nMethod Read:T()~nEnd Interface~nStruct SInterfaceHolder<T>~nField value:T~nEnd Struct~nGlobal interfaceHolder:SInterfaceHolder<IValueMarker<Int>>"
Local interfaceArgumentStructCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-struct-interface-argument.bmx", interfaceArgumentStructSource, Null, compilerOptions)
Local interfaceArgumentUnit:TCompilerGenericUnit
Local interfaceHolderUnit:TCompilerGenericUnit
For Local unit:TCompilerGenericUnit = EachIn interfaceArgumentStructCompilation.genericPlan.units
	If unit.ir.isInterface Then interfaceArgumentUnit = unit
	If unit.ir.isStruct Then interfaceHolderUnit = unit
Next
Check(interfaceArgumentStructCompilation.Succeeded() And interfaceArgumentUnit And interfaceHolderUnit And AppearsBefore(interfaceHolderUnit.implementation, "void " + interfaceArgumentUnit.specialization.readableAbiName + "_register(void);", interfaceArgumentUnit.specialization.readableAbiName + "_register();"), "generic Struct units declare referenced generic Interface registration before generated registration calls")
Local genericArrayConstructorSource:String = "SuperStrict~nType TArrayConstructor<T>~nField count:Int~nMethod New(values:T[])~ncount=values.length~nEnd Method~nEnd Type~nGlobal arrayConstructor:TArrayConstructor<String>=New TArrayConstructor<String>([~qa~q,~qb~q])"
Local genericArrayConstructorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-array-constructor.bmx", genericArrayConstructorSource, Null, compilerOptions)
Check(genericArrayConstructorCompilation.Succeeded() And genericArrayConstructorCompilation.genericPlan.units.length = 1 And genericArrayConstructorCompilation.genericPlan.units[0].ir.constructors.length = 1, "generic constructor selection compares substituted heap-Array signatures by canonical semantic shape: " + CompilationSummary(genericArrayConstructorCompilation))
Local genericManagedDefaultConstructorSource:String = "SuperStrict~nInterface IOptionalChoice<T>~nMethod Choose:Int(left:T,right:T)~nEnd Interface~nType TManagedDefaultConstructor<T>~nMethod New(value:T, choice:IOptionalChoice<T> = Null)~nEnd Method~nEnd Type~nGlobal managedDefaultConstructor:TManagedDefaultConstructor<String> = New TManagedDefaultConstructor<String>(~qvalue~q)"
Local genericManagedDefaultConstructorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-managed-default-constructor.bmx", genericManagedDefaultConstructorSource, Null, compilerOptions)
Local genericManagedDefaultConstructorDiagnostics:TCompilerDiagnostic[]
Local genericManagedDefaultConstructorC:String = TBlitzMaxCompiler.EmitRuntimeC(genericManagedDefaultConstructorCompilation, genericManagedDefaultConstructorDiagnostics)
Check(genericManagedDefaultConstructorCompilation.Succeeded() And genericManagedDefaultConstructorDiagnostics.length = 0 And genericManagedDefaultConstructorC.Contains("((BBOBJECT)&bbNullObject)"), "omitted closed generic Interface constructor arguments use the BlitzMax managed Null sentinel rather than scalar C zero: " + CompilationSummary(genericManagedDefaultConstructorCompilation))
Local varParameterSource:String = "SuperStrict~nType TVarBox<T>~nMethod Store:T(value:T Var, newValue:T)~nvalue = newValue~nReturn value~nEnd Method~nEnd Type~nGlobal varBox:TVarBox<Int>~nGlobal varStored:Int~nGlobal varResult:Int = varBox.Store(varStored, 7)"
Local varParameterCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-var-parameter.bmx", varParameterSource, Null, compilerOptions)
Check(varParameterCompilation.Succeeded() And varParameterCompilation.genericPlan.units[0].implementation.Contains("(*value) = newValue;") And varParameterCompilation.genericPlan.units[0].implementation.Contains("return (*value);"), "generic Type methods dereference Var parameters for reads and writes: " + CompilationSummary(varParameterCompilation))
Local varRoutineSource:String = "SuperStrict~nFunction ReplaceValue<T>:T(value:T Var, replacement:T)~nLocal previous:T = value~nvalue = replacement~nReturn previous~nEnd Function~nFunction ForwardReplace<T>:T(value:T Var, replacement:T)~nReturn ReplaceValue<T>(value, replacement)~nEnd Function~nGlobal varRoutineInput:Int = 1~nGlobal varRoutinePrevious:Int = ForwardReplace<Int>(varRoutineInput, 7)"
Local varRoutineCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-var-routine.bmx", varRoutineSource, Null, compilerOptions)
Local varRoutineDiagnostics:TCompilerDiagnostic[]
Local varRoutineRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(varRoutineCompilation, varRoutineDiagnostics)
Local varRoutineImplementations:String
For Local varRoutineUnit:TCompilerGenericUnit = EachIn varRoutineCompilation.genericPlan.units
	varRoutineImplementations :+ varRoutineUnit.implementation
Next
Check(varRoutineCompilation.Succeeded() And varRoutineCompilation.genericPlan.units.length = 2 And varRoutineImplementations.Contains("(BBINT * value, BBINT replacement)") And varRoutineImplementations.Contains("(*value) = replacement;") And varRoutineImplementations.Contains("ReplaceValue_int_"), "generic free routines and transitive generic calls retain one canonical Var pointer ABI: " + CompilationSummary(varRoutineCompilation))
Check(varRoutineDiagnostics.length = 0 And varRoutineRuntimeC.Contains("ForwardReplace_int_") And varRoutineRuntimeC.Contains("&bmx_"), "application calls pass an address to a canonical generic routine Var parameter")
Local ordinaryVarCallSource:String = "SuperStrict~nFunction StableReplace:Int(value:Int Var, replacement:Int) { nomangle }~nvalue = replacement~nReturn value~nEnd Function~nFunction ViaStableReplace<T>:Int(value:Int Var, replacement:Int)~nReturn StableReplace(value, replacement)~nEnd Function~nGlobal ordinaryVarInput:Int = 1~nGlobal ordinaryVarResult:Int = ViaStableReplace<String>(ordinaryVarInput, 7)"
Local ordinaryVarCallCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-ordinary-var-call.bmx", ordinaryVarCallSource, Null, compilerOptions)
Local ordinaryVarCallImplementation:String = ordinaryVarCallCompilation.genericPlan.units[0].implementation
Check(ordinaryVarCallCompilation.Succeeded() And ordinaryVarCallImplementation.Contains("_bb_main_StableReplace(BBINT *, BBINT)") And ordinaryVarCallImplementation.Contains("_bb_main_StableReplace((&((*value))), ((BBINT)replacement))"), "generic bodies retain published ordinary-routine Var declarations and pass an addressable reference: " + CompilationSummary(ordinaryVarCallCompilation))
Local hexadecimalLiteralSource:String = "SuperStrict~nType THexMask<T>~nMethod Mask:Int(value:Int)~nReturn value & $7fffffff~nEnd Method~nEnd Type~nGlobal hexMask:THexMask<String>~nGlobal maskedValue:Int = hexMask.Mask(-1)"
Local hexadecimalLiteralCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-hexadecimal-literal.bmx", hexadecimalLiteralSource, Null, compilerOptions)
Check(hexadecimalLiteralCompilation.Succeeded() And hexadecimalLiteralCompilation.genericPlan.units[0].implementation.Contains("0x7fffffff"), "generic numeric literals translate BlitzMax hexadecimal spelling to deterministic C spelling: " + CompilationSummary(hexadecimalLiteralCompilation))
Local implicitDefaultConstructorSource:String = "SuperStrict~nType TImplicitDefault<T>~nField value:T~nMethod New(initial:T)~nvalue = initial~nEnd Method~nEnd Type~nGlobal implicitDefault:TImplicitDefault<String> = New TImplicitDefault<String>"
Local implicitDefaultConstructorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-implicit-default-constructor.bmx", implicitDefaultConstructorSource, Null, compilerOptions)
Check(implicitDefaultConstructorCompilation.Succeeded(), "canonical Types retain implicit zero-argument construction alongside explicit New overloads: " + CompilationSummary(implicitDefaultConstructorCompilation))
Local deferredObjectOverloadProducer:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/test.mod/hash.mod/hash.bmx", "SuperStrict~nModule Test.Hash~nFunction HashObject:Long(value:Object)~nReturn 1~nEnd Function", Null, compilerOptions)
Local deferredObjectOverloadInterfaceDiagnostics:TCompilerDiagnostic[]
Local deferredObjectOverloadInterface:String = TBlitzMaxCompiler.EmitInterface(deferredObjectOverloadProducer, deferredObjectOverloadInterfaceDiagnostics)
Local deferredObjectOverloadResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
deferredObjectOverloadResolver.AddInterface("test.hash", "sdk/test.hash.i", deferredObjectOverloadInterface)
Local deferredObjectOverloadSource:String = "SuperStrict~nImport Test.Hash~nType THashProbe<K>~nMethod Hash:Long(value:K)~nReturn HashObject(value)~nEnd Method~nEnd Type~nGlobal hashProbe:THashProbe<String>~nGlobal hashValue:Long = hashProbe.Hash(~qkey~q)"
Local deferredObjectOverloadCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-deferred-object-overload.bmx", deferredObjectOverloadSource, deferredObjectOverloadResolver, compilerOptions)
Check(deferredObjectOverloadCompilation.Succeeded() And deferredObjectOverloadCompilation.genericPlan.units[0].implementation.Contains("HashObject") And deferredObjectOverloadCompilation.genericPlan.units[0].implementation.Contains("((BBOBJECT)"), "closed generic overload selection applies the ordinary String-to-Object widening conversion: " + CompilationSummary(deferredObjectOverloadCompilation))
Local sequentialTypeBodySource:String = "SuperStrict~nType TLocalBox<T>~nMethod Combine:T(first:T, second:T)~nLocal result:T = first~nresult = result + second~nReturn result~nEnd Method~nEnd Type~nGlobal localBox:TLocalBox<Int>"
Local sequentialTypeBodyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-type-sequential-body.bmx", sequentialTypeBodySource, Null, compilerOptions)
Check(sequentialTypeBodyCompilation.Succeeded() And sequentialTypeBodyCompilation.genericPlan.units.length = 1 And sequentialTypeBodyCompilation.genericPlan.units[0].implementation.Contains("BBINT bmx_local_result = first;") And sequentialTypeBodyCompilation.genericPlan.units[0].implementation.Contains("return bmx_local_result;"), "generic Type method units share the typed sequential-local body lowering")
Local multipleLocalSource:String = "SuperStrict~nFunction MultipleLocals<T>:T(value:T)~nLocal first:T = value, second:T = value~nReturn first~nEnd Function~nGlobal multipleLocal:Int = MultipleLocals(1)"
Local multipleLocalCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-multiple-locals.bmx", multipleLocalSource, Null, compilerOptions)
Check(multipleLocalCompilation.Succeeded() And multipleLocalCompilation.genericPlan.units.length = 1 And multipleLocalCompilation.genericPlan.units[0].implementation.Contains("BBINT bmx_local_first = value;") And multipleLocalCompilation.genericPlan.units[0].implementation.Contains("BBINT bmx_local_second = value;"), "multiple generic local declarators retain individual ordered identities in one lexical scope: " + CompilationSummary(multipleLocalCompilation))
Local readOnlyLocalSource:String = "SuperStrict~nFunction LocalConstant<T>:Int()~nConst answer:Int = 42~nReturn answer~nEnd Function~nGlobal localConstantValue:Int = LocalConstant<String>()"
Local readOnlyLocalCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-readonly-local.bmx", readOnlyLocalSource, Null, compilerOptions)
Check(readOnlyLocalCompilation.Succeeded() And readOnlyLocalCompilation.genericPlan.units[0].implementation.Contains("BBINT bmx_local_answer = 42;") And readOnlyLocalCompilation.genericPlan.units[0].implementation.Contains("return 42;"), "generic local Const declarations retain read-only declaration identity while their uses remain compile-time values: " + CompilationSummary(readOnlyLocalCompilation))
Local nonCallExpressionSource:String = "SuperStrict~nFunction ObserveExpression<T>:Int(value:Int)~nNew Int[1]~nReturn value~nEnd Function~nGlobal observedExpression:Int = ObserveExpression<String>(41)"
Local nonCallExpressionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-noncall-expression.bmx", nonCallExpressionSource, Null, compilerOptions)
Check(nonCallExpressionCompilation.Succeeded() And nonCallExpressionCompilation.genericPlan.units[0].implementation.Contains("(void)bbArrayNew1D(~qi~q, 1);"), "generic non-call expression statements retain and emit their typed expression: " + CompilationSummary(nonCallExpressionCompilation))
Local selectBodySource:String = "SuperStrict~nFunction SelectValue<T>:T(value:Int, first:T, second:T)~nSelect value~nCase 1, 2~nReturn first~nDefault~nReturn second~nEnd Select~nEnd Function~nGlobal selectedGeneric:Int = SelectValue<Int>(2, 42, 7)"
Local selectBodyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-select-body.bmx", selectBodySource, Null, compilerOptions)
Check(selectBodyCompilation.Succeeded() And selectBodyCompilation.genericPlan.units[0].implementation.Contains("BBINT bmx_select0_value = value;") And selectBodyCompilation.genericPlan.units[0].implementation.Contains("if (bmx_select0_value == 1 || bmx_select0_value == 2)"), "generic Select retains one evaluated selector, ordered case values, and Default body: " + CompilationSummary(selectBodyCompilation))
Local releaseBodySource:String = "SuperStrict~nType THandleBox<T>~nField handle:Size_T~nField handles:Size_T[]~nMethod ReleaseAll(localHandle:Size_T)~nRelease localHandle~nRelease handle~nRelease handles[0]~nEnd Method~nEnd Type~nGlobal handleBox:THandleBox<Int>"
Local releaseBodyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-release-body.bmx", releaseBodySource, Null, compilerOptions)
Local releaseBodyImplementation:String
If releaseBodyCompilation.genericPlan And releaseBodyCompilation.genericPlan.units.length Then releaseBodyImplementation = releaseBodyCompilation.genericPlan.units[0].implementation
Check(releaseBodyCompilation.Succeeded() And Occurrences(releaseBodyImplementation, "bbHandleRelease((size_t)(") = 3 And releaseBodyImplementation.Contains("localHandle") And releaseBodyImplementation.Contains("handle") And releaseBodyImplementation.Contains("BBARRAYDATA"), "generic Release retains parameter, field, and indexed handle operands in source-free specialization C: " + CompilationSummary(releaseBodyCompilation))
Local releaseModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/releasegeneric.mod/releasegeneric.bmx", "SuperStrict~nModule Collections.ReleaseGeneric~nFunction ReleaseHandle<T>(handle:Size_T)~nRelease handle~nEnd Function", Null, compilerOptions)
Local releaseModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local releaseModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(releaseModuleCompilation, releaseModuleArtifactDiagnostics)
Local releaseModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local releaseModuleInterface:String = TBlitzMaxCompiler.EmitInterface(releaseModuleCompilation, releaseModuleInterfaceDiagnostics)
Local releaseModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
releaseModuleResolver.AddInterface("collections.releasegeneric", "sdk/collections.releasegeneric.i", releaseModuleInterface)
If releaseModuleOutputs.length Then releaseModuleResolver.AddGenericTemplate(releaseModuleOutputs[0].artifactReference, "sdk/" + releaseModuleOutputs[0].artifactReference, releaseModuleOutputs[0].content)
Local releaseModuleConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-release-consumer.bmx", "SuperStrict~nImport Collections.ReleaseGeneric~nReleaseHandle<String>(0)", releaseModuleResolver, compilerOptions)
Check(releaseModuleCompilation.Succeeded() And releaseModuleArtifactDiagnostics.length = 0 And releaseModuleInterfaceDiagnostics.length = 0 And releaseModuleOutputs.length = 1 And releaseModuleConsumer.Succeeded() And releaseModuleConsumer.genericPlan.units.length = 1 And releaseModuleConsumer.genericPlan.units[0].implementation.Contains("bbHandleRelease((size_t)(handle))"), "a cross-module consumer specializes Release entirely from the format-29 source-free artifact: " + CompilationSummary(releaseModuleConsumer))
Local invalidReleaseBody:TCompilerResult = TBlitzMaxCompiler.Compile("generic-invalid-release-body.bmx", "SuperStrict~nFunction InvalidRelease<T>(value:Float)~nRelease value~nEnd Function~nGlobal invalidRelease:Int=InvalidRelease<String>(1.0)", Null, compilerOptions)
Check(Not invalidReleaseBody.Succeeded() And HasLanguageDiagnostic(invalidReleaseBody, "BMX3310"), "generic Release rejects a non-integral operand before template publication")
Local genericLifecycleSource:String = "SuperStrict~nGlobal lifecycleOrder:Int~nType TGenericLifecycleBase<T>~nMethod Delete()~nlifecycleOrder=lifecycleOrder*10+1~nEnd Method~nMethod Read:T(value:T)~nReturn value~nEnd Method~nEnd Type~nType TGenericLifecycleDerived<T> Extends TGenericLifecycleBase<T>~nMethod Delete()~nlifecycleOrder=lifecycleOrder*10+2~nEnd Method~nMethod ReadDerived:T(value:T)~nReturn value~nEnd Method~nEnd Type~nType TGenericLifecycleLeaf<T> Extends TGenericLifecycleDerived<T>~nMethod ReadLeaf:T(value:T)~nReturn value~nEnd Method~nEnd Type~nGlobal genericLifecycleLeaf:TGenericLifecycleLeaf<String>=New TGenericLifecycleLeaf<String>"
Local genericLifecycleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-lifecycle.bmx", genericLifecycleSource, Null, compilerOptions)
Local genericLifecycleBaseUnit:TCompilerGenericUnit
Local genericLifecycleDerivedUnit:TCompilerGenericUnit
Local genericLifecycleLeafUnit:TCompilerGenericUnit
For Local genericLifecycleUnit:TCompilerGenericUnit = EachIn genericLifecycleCompilation.genericPlan.units
	Select genericLifecycleUnit.specialization.artifact.identity.qualifiedName.ToLower()
		Case "tgenericlifecyclebase"
			genericLifecycleBaseUnit = genericLifecycleUnit
		Case "tgenericlifecyclederived"
			genericLifecycleDerivedUnit = genericLifecycleUnit
		Case "tgenericlifecycleleaf"
			genericLifecycleLeafUnit = genericLifecycleUnit
	End Select
Next
Check(genericLifecycleCompilation.Succeeded() And genericLifecycleBaseUnit And genericLifecycleDerivedUnit And genericLifecycleLeafUnit, "generic Type destructor inheritance produces every closed lifecycle unit: " + CompilationSummary(genericLifecycleCompilation))
Check(genericLifecycleBaseUnit.implementation.Contains("_Delete_body(") And genericLifecycleBaseUnit.implementation.Contains("bbObjectDtor((BBOBJECT)self)") And Not genericLifecycleBaseUnit.implementation.Contains("m_delete_") And genericLifecycleBaseUnit.implementation.Contains("m_read_0"), "a base generic Delete is a descriptor lifecycle hook, chains to Object destruction, and does not consume a virtual slot")
Check(genericLifecycleDerivedUnit.implementation.Contains("_Delete_body(") And genericLifecycleDerivedUnit.implementation.Contains("((BBClass *)&" + genericLifecycleBaseUnit.specialization.readableAbiName + ")->dtor((BBOBJECT)self)"), "a derived generic Delete runs its retained body before the immediate base descriptor destructor")
Check(Not genericLifecycleLeafUnit.implementation.Contains("_Delete_body(") And genericLifecycleLeafUnit.implementation.Contains("(void (*)(BBOBJECT))" + genericLifecycleDerivedUnit.specialization.readableAbiName + "_Delete") And Not genericLifecycleLeafUnit.implementation.Contains("m_delete_"), "a generic Type without its own Delete inherits the effective destructor without synthesizing a method slot or duplicate body")
Local genericLifecycleRuntimeDiagnostics:TCompilerDiagnostic[]
Local genericLifecycleRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(genericLifecycleCompilation, genericLifecycleRuntimeDiagnostics)
Check(genericLifecycleRuntimeDiagnostics.length = 0 And Not genericLifecycleRuntimeC.Contains("void (*)(struct " + genericLifecycleBaseUnit.specialization.readableAbiName + "_obj *);") And Not genericLifecycleRuntimeC.Contains("void (*)(struct " + genericLifecycleDerivedUnit.specialization.readableAbiName + "_obj *);") And Not genericLifecycleRuntimeC.Contains("void (*)(struct " + genericLifecycleLeafUnit.specialization.readableAbiName + "_obj *);"), "application-side generic class declarations omit Delete rather than emitting an anonymous function-pointer member")
Local arrayLiteralBodySource:String = "SuperStrict~nFunction Pair<T>:T[](first:T, second:T)~nReturn [first, second]~nEnd Function~nGlobal pairValues:Int[] = Pair<Int>(20, 22)"
Local arrayLiteralBodyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-array-literal-body.bmx", arrayLiteralBodySource, Null, compilerOptions)
Check(arrayLiteralBodyCompilation.Succeeded() And arrayLiteralBodyCompilation.genericPlan.units[0].implementation.Contains("bbArrayNew1D(~qi~q, 2)") And arrayLiteralBodyCompilation.genericPlan.units[0].implementation.Contains("BBARRAYDATA("), "generic managed Array literals retain closed elements and runtime encoding without source reparsing: " + CompilationSummary(arrayLiteralBodyCompilation))
Local orderedArrayLiteralSource:String = "SuperStrict~nFunction MarkOrdered:Int(value:Int) { nomangle }~nReturn value~nEnd Function~nFunction OrderedArray<T>:Int()~nLocal values:Int[]=[MarkOrdered(1),MarkOrdered(2)]~nReturn values[0]+values[1]~nEnd Function~nGlobal orderedArrayResult:Int=OrderedArray<String>()"
Local orderedArrayLiteralCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-ordered-array-literal.bmx", orderedArrayLiteralSource, Null, compilerOptions)
Local orderedArrayLiteralImplementation:String
If orderedArrayLiteralCompilation.genericPlan And orderedArrayLiteralCompilation.genericPlan.units.length Then orderedArrayLiteralImplementation = orderedArrayLiteralCompilation.genericPlan.units[0].implementation
Check(orderedArrayLiteralCompilation.Succeeded() And orderedArrayLiteralImplementation.Contains("bbArrayNew1D(~qi~q, 2)") And AppearsBefore(orderedArrayLiteralImplementation, "MarkOrdered(((BBINT)1))", "MarkOrdered(((BBINT)2))"), "generic managed Array literal elements retain deterministic left-to-right evaluation without a compound source blob: " + CompilationSummary(orderedArrayLiteralCompilation))
Local callableValueSource:String = "SuperStrict~nFunction IncrementGenericCallable:Int(value:Int) { nomangle }~nReturn value+1~nEnd Function~nFunction InvokeStored<T>:Int(value:Int)~nLocal callback:Int(item:Int)=IncrementGenericCallable~nLocal assigned:Int(item:Int)~nassigned=callback~nReturn assigned(value)~nEnd Function~nGlobal callableValueResult:Int=InvokeStored<String>(41)"
Local callableValueCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-callable-value.bmx", callableValueSource, Null, compilerOptions)
Local callableValueImplementation:String
If callableValueCompilation.genericPlan And callableValueCompilation.genericPlan.units.length Then callableValueImplementation = callableValueCompilation.genericPlan.units[0].implementation
Check(callableValueCompilation.Succeeded() And callableValueImplementation.Contains("extern BBINT _bb_main_IncrementGenericCallable(BBINT p0);") And callableValueImplementation.Contains("(*bmx_local_callback)(BBINT p0)") And callableValueImplementation.Contains("= _bb_main_IncrementGenericCallable;") And callableValueImplementation.Contains("&brl_blitz_NullFunctionError") And callableValueImplementation.Contains("(bmx_local_assigned)(value)"), "generic templates retain callable signatures, stable routine identities, callable sentinels, local storage, and indirect calls: " + CompilationSummary(callableValueCompilation))
Local callableParameterSource:String = "SuperStrict~nFunction IncrementGenericParameter:Int(value:Int) { nomangle }~nReturn value+1~nEnd Function~nFunction InvokeParameter<T>:Int(callback:Int(item:Int),value:Int)~nIf callback(value) Then Return 1~nReturn 0~nEnd Function~nGlobal callableParameterResult:Int=InvokeParameter<String>(IncrementGenericParameter,41)"
Local callableParameterCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-callable-parameter.bmx", callableParameterSource, Null, compilerOptions)
Local callableParameterDiagnostics:TCompilerDiagnostic[]
Local callableParameterC:String = TBlitzMaxCompiler.EmitRuntimeC(callableParameterCompilation, callableParameterDiagnostics)
Local callableParameterImplementation:String
If callableParameterCompilation.genericPlan And callableParameterCompilation.genericPlan.units.length Then callableParameterImplementation = callableParameterCompilation.genericPlan.units[0].implementation
Check(callableParameterCompilation.Succeeded() And callableParameterDiagnostics.length = 0 And callableParameterImplementation.Contains("(*callback)(BBINT p0)") And callableParameterImplementation.Contains("if ((") And callableParameterImplementation.Contains("(callback)(value)") And callableParameterC.Contains("_bb_main_IncrementGenericParameter"), "callable generic routine parameters retain their exact function-pointer ABI and a grouped indirect-call condition: " + CompilationSummary(callableParameterCompilation))
Local callableVarParameterSource:String = "SuperStrict~nFunction IncrementGenericVarCallable:Int(value:Int) { nomangle }~nReturn value+1~nEnd Function~nFunction ResetCallable<T>:Int(callback:Int(item:Int) Var,value:Int)~ncallback=IncrementGenericVarCallable~nReturn callback(value)~nEnd Function~nGlobal storedGenericCallback:Int(item:Int)~nGlobal callableVarParameterResult:Int=ResetCallable<String>(storedGenericCallback,41)"
Local callableVarParameterCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-callable-var-parameter.bmx", callableVarParameterSource, Null, compilerOptions)
Local callableVarParameterDiagnostics:TCompilerDiagnostic[]
Local callableVarParameterC:String = TBlitzMaxCompiler.EmitRuntimeC(callableVarParameterCompilation, callableVarParameterDiagnostics)
Local callableVarParameterImplementation:String
If callableVarParameterCompilation.genericPlan And callableVarParameterCompilation.genericPlan.units.length Then callableVarParameterImplementation = callableVarParameterCompilation.genericPlan.units[0].implementation
Check(callableVarParameterCompilation.Succeeded() And callableVarParameterDiagnostics.length = 0 And callableVarParameterImplementation.Contains("(**callback)(BBINT p0)") And callableVarParameterImplementation.Contains("(*callback) = _bb_main_IncrementGenericVarCallable;") And callableVarParameterC.Contains("&bmx_"), "Var callable generic parameters retain their pointer-to-function-pointer ABI across assignment, indirect invocation, and application calls: " + CompilationSummary(callableVarParameterCompilation))
Local callableReturnGenericSource:String = "SuperStrict~nFunction IncrementGenericReturn:Int(value:Int Var) { nomangle }~nvalue:+1~nReturn value~nEnd Function~nFunction PickGeneric<T>:Int(value:Int Var)(enabled:Int)~nIf enabled Then Return IncrementGenericReturn~nReturn Null~nEnd Function~nInterface IGenericCallableReturn<T>~nMethod Choose:Int(value:Int Var)(enabled:Int)~nEnd Interface~nType TGenericCallableReturn<T> Implements IGenericCallableReturn<T>~nMethod Choose:Int(value:Int Var)(enabled:Int)~nIf enabled Then Return IncrementGenericReturn~nReturn Null~nEnd Method~nEnd Type~nStruct SGenericCallableReturn<T>~nMethod Choose:Int(value:Int Var)(enabled:Int)~nIf enabled Then Return IncrementGenericReturn~nReturn Null~nEnd Method~nEnd Struct~nGlobal callableReturnOwner:TGenericCallableReturn<String> = New TGenericCallableReturn<String>~nGlobal callableReturnView:IGenericCallableReturn<String> = callableReturnOwner~nGlobal callableReturnStruct:SGenericCallableReturn<String>~nGlobal callableReturnRoutine:Int(value:Int Var) = PickGeneric<String>(True)~nGlobal callableReturnMethod:Int(value:Int Var) = callableReturnView.Choose(True)~nGlobal callableReturnStructMethod:Int(value:Int Var) = callableReturnStruct.Choose(True)"
Local callableReturnGenericCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-callable-return-abi.bmx", callableReturnGenericSource, Null, compilerOptions)
Local callableReturnGenericText:String
If callableReturnGenericCompilation.genericPlan Then
	For Local callableReturnUnit:TCompilerGenericUnit = EachIn callableReturnGenericCompilation.genericPlan.units
		callableReturnGenericText :+ callableReturnUnit.declarations + callableReturnUnit.implementation
	Next
End If
Check(callableReturnGenericCompilation.Succeeded() And callableReturnGenericText.Contains("))(BBINT * p0)") And callableReturnGenericText.Contains("BBINT (*(*") And callableReturnGenericText.Contains("BBINT (**)(BBINT * p0)") And callableReturnGenericText.Contains("_Choose_ReflectionWrapper"), "generic routines, Types, Structs, Interfaces, dispatch slots, and reflection wrappers retain one exact callable-return ABI: " + CompilationSummary(callableReturnGenericCompilation))
Local genericTrySource:String = "SuperStrict~nFunction CatchAndClean<T>:Int(value:Int)~nTry~nIf value<0 Then Throw ~qproblem~q~nReturn value~nCatch problem:String~nReturn 40~nFinally~nvalue:+2~nEnd Try~nEnd Function~nGlobal genericTryResult:Int=CatchAndClean<String>(0)"
Local genericTryCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-try-catch-finally.bmx", genericTrySource, Null, compilerOptions)
Local genericTryImplementation:String
If genericTryCompilation.genericPlan And genericTryCompilation.genericPlan.units.length Then genericTryImplementation = genericTryCompilation.genericPlan.units[0].implementation
Check(genericTryCompilation.Succeeded() And Occurrences(genericTryImplementation, "bbExTry {") = 2 And genericTryImplementation.Contains("bbObjectStringcast") And genericTryImplementation.Contains("bbExLeave()"), "generic Catch and Finally retain typed matching and explicit nested cleanup routing: " + CompilationSummary(genericTryCompilation))
Local genericLoopTargetSource:String = "SuperStrict~nPrivate~nGlobal genericLoopIndex:Int~nPublic~nFunction UpdateLoopTargets<T>:Int(values:Int[])~nFor genericLoopIndex=0 Until 2~nvalues[genericLoopIndex]=genericLoopIndex+1~nNext~nFor values[0]=0 Until 2~nNext~nReturn values[1]~nEnd Function~nGlobal genericLoopValues:Int[]=New Int[2]~nGlobal genericLoopResult:Int=UpdateLoopTargets<String>(genericLoopValues)"
Local genericLoopTargetCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-loop-targets-private-global.bmx", genericLoopTargetSource, Null, compilerOptions)
Local genericLoopTargetImplementation:String
If genericLoopTargetCompilation.genericPlan And genericLoopTargetCompilation.genericPlan.units.length Then genericLoopTargetImplementation = genericLoopTargetCompilation.genericPlan.units[0].implementation
Check(genericLoopTargetCompilation.Succeeded() And genericLoopTargetImplementation.Contains("bmx_private_global_genericLoopIndex_") And genericLoopTargetImplementation.Contains("BBARRAYDATA("), "generic range loops support specialization-linked private Globals and rank-one Array elements as writable targets: " + CompilationSummary(genericLoopTargetCompilation))
Local genericDataSource:String = "SuperStrict~nFunction ReadGenericData<T>:Int()~n#values~nDefData 42~nLocal value:Int~nRestoreData values~nReadData value~nReturn value~nEnd Function~nGlobal genericDataResult:Int=ReadGenericData<String>()"
Local genericDataCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-data.bmx", genericDataSource, Null, compilerOptions)
Local genericDataImplementation:String
If genericDataCompilation.genericPlan And genericDataCompilation.genericPlan.units.length Then genericDataImplementation = genericDataCompilation.genericPlan.units[0].implementation
Local genericDataDiagnostics:TCompilerDiagnostic[]
Local genericDataApplicationC:String = TBlitzMaxCompiler.EmitRuntimeC(genericDataCompilation, genericDataDiagnostics)
Check(genericDataCompilation.Succeeded() And genericDataDiagnostics.length = 0 And genericDataImplementation.Contains("struct bbDataDef") And genericDataImplementation.Contains("bbConvertToInt") And genericDataImplementation.Contains("_data_offset") And Not genericDataApplicationC.Contains("static struct bbDataDef bmx_data"), "generic DefData, RestoreData, and ReadData use a deterministic specialization-owned tagged data section without duplicating it in the application unit: " + CompilationSummary(genericDataCompilation))
Local tryFinallyBodySource:String = "SuperStrict~nFunction ProtectedValue<T>:T(value:T, cleanup:Int Var)~nTry~nReturn value~nFinally~ncleanup :+ 1~nEnd Try~nEnd Function~nGlobal protectedCleanup:Int~nGlobal protectedValue:Int = ProtectedValue<Int>(42, protectedCleanup)"
Local tryFinallyBodyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-try-finally-body.bmx", tryFinallyBodySource, Null, compilerOptions)
Local tryFinallyBodyImplementation:String = tryFinallyBodyCompilation.genericPlan.units[0].implementation
Check(tryFinallyBodyCompilation.Succeeded() And tryFinallyBodyImplementation.Contains("bmx_cleanup_return_") And tryFinallyBodyImplementation.Contains("bbExLeave();") And tryFinallyBodyImplementation.Contains("(*cleanup) += 1;"), "generic Try/Finally captures Return values and retains an explicit cleanup edge before transfer: " + CompilationSummary(tryFinallyBodyCompilation))
Local tryLoopTransferSource:String = "SuperStrict~nFunction ContinueProtected<T>:Int(cleanup:Int Var)~n#Outer~nFor Local index:Int = 0 Until 1~nTry~nContinue Outer~nFinally~ncleanup :+ 1~nEnd Try~nNext~nReturn cleanup~nEnd Function~nGlobal transferCleanup:Int~nGlobal transferValue:Int = ContinueProtected<String>(transferCleanup)"
Local tryLoopTransferCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-try-loop-transfer.bmx", tryLoopTransferSource, Null, compilerOptions)
Local tryLoopTransferImplementation:String = tryLoopTransferCompilation.genericPlan.units[0].implementation
Check(tryLoopTransferCompilation.Succeeded() And tryLoopTransferImplementation.Contains("(*cleanup) += 1;") And tryLoopTransferImplementation.Contains("goto bmx_loop0_continue;"), "generic labelled Continue crossing Try retains and emits its Finally cleanup edge: " + CompilationSummary(tryLoopTransferCompilation))
Local usingLoopTransferSource:String = "SuperStrict~nModule Test.GenericUsing~nInterface ICloseable~nMethod Close()~nEnd Interface~nType TUsingResource Implements ICloseable~nField closed:Int~nMethod Close()~nclosed = 1~nEnd Method~nEnd Type~nFunction UseAndExit<T>:Int(resource:TUsingResource)~n#Outer~nWhile True~nUsing~nLocal owned:TUsingResource = resource~nDo~nExit Outer~nEnd Using~nWend~nReturn resource.closed~nEnd Function~nGlobal usingResource:TUsingResource = New TUsingResource~nGlobal usingResult:Int = UseAndExit<String>(usingResource)"
Local usingLoopTransferCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/test.mod/genericusing.mod/genericusing.bmx", usingLoopTransferSource, Null, compilerOptions)
Local usingLoopTransferImplementations:String
For Local usingLoopTransferUnit:TCompilerGenericUnit = EachIn usingLoopTransferCompilation.genericPlan.units
	usingLoopTransferImplementations :+ usingLoopTransferUnit.implementation
Next
Check(usingLoopTransferCompilation.Succeeded() And usingLoopTransferImplementations.Contains("bbExLeave();") And usingLoopTransferImplementations.Contains("goto bmx_loop0_exit;") And usingLoopTransferImplementations.Contains("bbObjectInterface(") And usingLoopTransferImplementations.Contains("((void **)") And Not usingLoopTransferImplementations.Contains(")))((void **)bbObjectInterface"), "generic Using retains resource ownership and emits a balanced ordinary Interface cleanup-slot cast before a loop transfer crossing the cleanup boundary: " + CompilationSummary(usingLoopTransferCompilation))
Local loopTargetSource:String = "SuperStrict~nType TLoopTargets<T>~nField cursor:Int~nField total:Int~nMethod Fill:Int(values:Int[], target:Int Var)~nFor cursor = 0 Until 2~nNext~nFor target = EachIn values~ntotal :+ target~nNext~nReturn total~nEnd Method~nEnd Type~nGlobal loopTargets:TLoopTargets<String>~nGlobal loopTargetValue:Int~nGlobal loopTargetResult:Int = loopTargets.Fill([20,22], loopTargetValue)"
Local loopTargetCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-loop-targets.bmx", loopTargetSource, Null, compilerOptions)
Local loopTargetImplementation:String = loopTargetCompilation.genericPlan.units[0].implementation
Check(loopTargetCompilation.Succeeded() And loopTargetImplementation.Contains("self->_") And loopTargetImplementation.Contains("(*target) = bmx_loop1_element;") And loopTargetImplementation.Contains("self->") And loopTargetImplementation.Contains(" += (*target);"), "generic range and EachIn loops accept Field and Var-parameter assignment targets: " + CompilationSummary(loopTargetCompilation))
Local globalLoopTargetSource:String = "SuperStrict~nModule Test.GenericGlobalTarget~nGlobal Cursor:Int~nFunction Count<T>:Int()~nFor Cursor = 0 Until 2~nNext~nReturn Cursor~nEnd Function~nGlobal Counted:Int = Count<String>()"
Local globalLoopTargetCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/test.mod/genericglobaltarget.mod/genericglobaltarget.bmx", globalLoopTargetSource, Null, compilerOptions)
Local globalLoopTargetImplementation:String = globalLoopTargetCompilation.genericPlan.units[0].implementation
Check(globalLoopTargetCompilation.Succeeded() And globalLoopTargetImplementation.Contains("extern BBINT test_genericglobaltarget_Cursor;") And globalLoopTargetImplementation.Contains("for (test_genericglobaltarget_Cursor ="), "generic range loops retain published module Global targets by stable ABI rather than a local C name: " + CompilationSummary(globalLoopTargetCompilation))
Local conditionalBodySource:String = "SuperStrict~nFunction ConditionalValue<T>:Int()~n?macos~nLocal result:Int = 42~n?Not macos~nLocal result:Int = 7~n?~nReturn result~nEnd Function~nGlobal conditionalValue:Int = ConditionalValue<String>()"
Local conditionalBodyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-conditional-body.bmx", conditionalBodySource, Null, compilerOptions)
Check(conditionalBodyCompilation.Succeeded() And Occurrences(conditionalBodyCompilation.genericPlan.units[0].implementation, "BBINT bmx_local_result =") = 1 And conditionalBodyCompilation.genericPlan.units[0].implementation.Contains("return bmx_local_result;"), "generic declarations publish only the source selected for the specialization configuration: " + CompilationSummary(conditionalBodyCompilation))
Local allBranchesGenericOptions:TCompilationSnapshotOptions = compilerOptions.SnapshotOptions()
allBranchesGenericOptions.parseConfiguredConditionals = False
Local allBranchesGenericAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("generic-all-branches-invariant.bmx", conditionalBodySource, New TGenericSnapshotResolver, allBranchesGenericOptions)
Local allBranchesGenericSymbol:TSymbol = allBranchesGenericAnalysis.model.globalScope.LookupLocal("ConditionalValue")[0]
Local allBranchesGenericDiagnostics:String[]
TCompilerGenericTemplateBuilder.Build(allBranchesGenericAnalysis.model, allBranchesGenericSymbol, "test.invariant", "bmx-language-1", allBranchesGenericDiagnostics)
Check(allBranchesGenericDiagnostics.length > 0 And allBranchesGenericDiagnostics[0].Contains("BMXC3074 conditional directives remained after source configuration was applied"), "generic template construction rejects an all-branches bound model instead of selecting conditionals again")
Local branchBodySource:String = "SuperStrict~nFunction Choose<T>:T(value:T, fallback:T, enabled:Int)~nLocal result:T = fallback~nIf enabled Then~nLocal branch:T = value~nresult = branch~nElse~nLocal branch:T = fallback~nresult = branch~nEnd If~nReturn result~nEnd Function~nGlobal chosen1:Int = Choose(42, 1, True)~nGlobal chosen2:Int = Choose(42, 1, False)"
Local branchBodyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-branch-body.bmx", branchBodySource, Null, compilerOptions)
Check(branchBodyCompilation.Succeeded() And branchBodyCompilation.genericPlan.units.length = 1, "generic routine retains a typed simple If/Else body: " + CompilationSummary(branchBodyCompilation))
Local branchBodyImplementation:String = branchBodyCompilation.genericPlan.units[0].implementation
Check(branchBodyImplementation.Contains("if (enabled) {") And branchBodyImplementation.Contains("BBINT bmx_local_branch = value;") And branchBodyImplementation.Contains("} else {") And branchBodyImplementation.Contains("BBINT bmx_local_branch = fallback;") And branchBodyImplementation.Contains("return bmx_local_result;"), "generic If/Else emits scoped branch locals and ordered assignments")
Local branchTypeBodySource:String = "SuperStrict~nType TBranchBox<T>~nMethod Choose:T(value:T, fallback:T, enabled:Int)~nIf enabled Then~nReturn value~nElse~nReturn fallback~nEnd If~nEnd Method~nEnd Type~nGlobal branchBox:TBranchBox<Int>"
Local branchTypeBodyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-type-branch-body.bmx", branchTypeBodySource, Null, compilerOptions)
Check(branchTypeBodyCompilation.Succeeded() And branchTypeBodyCompilation.genericPlan.units.length = 1 And branchTypeBodyCompilation.genericPlan.units[0].implementation.Contains("if (enabled) {") And branchTypeBodyCompilation.genericPlan.units[0].implementation.Contains("return fallback;"), "generic Type method units share simple If/Else lowering")
Local elseIfBodySource:String = "SuperStrict~nFunction ChooseMany<T>:T(first:T, second:T, third:T, selected:Int)~nIf selected = 1 Then~nReturn first~nElse If selected = 2 Then~nReturn second~nElse~nReturn third~nEnd If~nEnd Function~nGlobal chosenMany:Int = ChooseMany(1, 2, 3, 2)"
Local elseIfBodyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-else-if-body.bmx", elseIfBodySource, Null, compilerOptions)
Check(elseIfBodyCompilation.Succeeded() And elseIfBodyCompilation.genericPlan.units.length = 1 And elseIfBodyCompilation.genericPlan.units[0].implementation.Contains("} else if (selected == 2) {") And elseIfBodyCompilation.genericPlan.units[0].implementation.Contains("return third;"), "generic Else If retains ordered typed clauses and an optional final Else: " + CompilationSummary(elseIfBodyCompilation))
Local managedBranchSource:String = "SuperStrict~nFunction ChooseText<T>:T(value:T, fallback:T)~nIf value Then~nReturn value~nElse~nReturn fallback~nEnd If~nEnd Function~nGlobal chosenText:String = ChooseText(~qvalue~q, ~qfallback~q)"
Local managedBranchCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-managed-branch.bmx", managedBranchSource, Null, compilerOptions)
Check(managedBranchCompilation.Succeeded() And managedBranchCompilation.genericPlan.units[0].implementation.Contains("if (value != &bbEmptyString) {"), "managed generic String branch truth specializes against the runtime empty sentinel")
Local whileBodySource:String = "SuperStrict~nFunction RepeatAdd<T>:T(seed:T, count:Int)~nLocal result:T = seed~nLocal index:Int~nWhile index < count~nLocal current:T = seed~nresult = result + current~nindex = index + 1~nWend~nReturn result~nEnd Function~nGlobal repeated1:Int = RepeatAdd(7, 5)~nGlobal repeated2:Int = RepeatAdd<Int>(6, 6)"
Local whileBodyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-while-body.bmx", whileBodySource, Null, compilerOptions)
Check(whileBodyCompilation.Succeeded() And whileBodyCompilation.genericPlan.units.length = 1, "generic routine retains one canonical typed While body: " + CompilationSummary(whileBodyCompilation))
Local whileBodyImplementation:String = whileBodyCompilation.genericPlan.units[0].implementation
Check(whileBodyImplementation.Contains("while (bmx_local_index < count) {") And whileBodyImplementation.Contains("BBINT bmx_local_current = seed;") And whileBodyImplementation.Contains("bmx_local_result = (bmx_local_result + bmx_local_current);") And whileBodyImplementation.Contains("bmx_local_index = (bmx_local_index + 1);"), "generic While emits scoped loop locals and ordered outer assignments")
Local whileTypeBodySource:String = "SuperStrict~nType TWhileBox<T>~nMethod Last:T(value:T, count:Int)~nLocal result:T = value~nLocal index:Int~nWhile index < count~nresult = value~nindex = index + 1~nWend~nReturn result~nEnd Method~nEnd Type~nGlobal whileBox:TWhileBox<Int>"
Local whileTypeBodyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-type-while-body.bmx", whileTypeBodySource, Null, compilerOptions)
Check(whileTypeBodyCompilation.Succeeded() And whileTypeBodyCompilation.genericPlan.units.length = 1 And whileTypeBodyCompilation.genericPlan.units[0].implementation.Contains("while (bmx_local_index < count) {"), "generic Type method units share source-free While lowering")
Local managedWhileSource:String = "SuperStrict~nFunction WhileText<T>:T(value:T)~nWhile value~nReturn value~nWend~nReturn value~nEnd Function~nGlobal whileText:String = WhileText(~qvalue~q)"
Local managedWhileCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-managed-while.bmx", managedWhileSource, Null, compilerOptions)
Check(managedWhileCompilation.Succeeded() And managedWhileCompilation.genericPlan.units[0].implementation.Contains("while (value != &bbEmptyString) {"), "managed generic String While truth specializes against the runtime empty sentinel")
Local managedLogicalSource:String = "SuperStrict~nType TManagedLogical<T>~nField next:TManagedLogical<T>~nMethod Ready:Int()~nReturn next And next.next~nEnd Method~nMethod Empty:Int()~nReturn Not next~nEnd Method~nEnd Type~nGlobal managedLogical:TManagedLogical<String>"
Local managedLogicalCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-managed-logical.bmx", managedLogicalSource, Null, compilerOptions)
Local managedLogicalImplementation:String = managedLogicalCompilation.genericPlan.units[0].implementation
Check(managedLogicalCompilation.Succeeded() And managedLogicalImplementation.Contains("!= (BBOBJECT)&bbNullObject") And managedLogicalImplementation.Contains(" && ") And managedLogicalImplementation.Contains("return (!"), "managed-reference And/Not operands lower through BlitzMax null-sentinel truth rather than raw C pointer truth")
Local inlineLocalSource:String = "SuperStrict~nType TInlineLocal<T>~nField next:TInlineLocal<T>~nMethod Ready:Int()~nFunction Present:Int(value:TInlineLocal<T>) Inline~nReturn value <> Null~nEnd Function~nReturn Present(next)~nEnd Method~nEnd Type~nGlobal inlineLocal:TInlineLocal<String>"
Local inlineLocalCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-inline-local.bmx", inlineLocalSource, Null, compilerOptions)
Local inlineLocalImplementation:String = inlineLocalCompilation.genericPlan.units[0].implementation
Check(inlineLocalCompilation.Succeeded() And inlineLocalImplementation.Contains("static BBINT") And inlineLocalImplementation.Contains("_local_Present_") And inlineLocalImplementation.Contains("_obj *)&bbNullObject"), "Inline local routines retain source-free semantic helpers and typed managed sentinels inside their owning specialization")
Local varLocalSource:String = "SuperStrict~nType TVarLocal<T>~nMethod Update:Int(value:Int)~nFunction Replace:Int(target:Int Var, replacement:Int)~ntarget = replacement~nReturn target~nEnd Function~nReturn Replace(value, 7)~nEnd Method~nEnd Type~nGlobal varLocal:TVarLocal<String>"
Local varLocalCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-var-local.bmx", varLocalSource, Null, compilerOptions)
Local varLocalImplementation:String = varLocalCompilation.genericPlan.units[0].implementation
Check(varLocalCompilation.Succeeded() And varLocalImplementation.Contains("_local_Replace_") And varLocalImplementation.Contains("(BBINT * target, BBINT replacement)") And varLocalImplementation.Contains("(&(value)), 7") And varLocalImplementation.Contains("(*target) = replacement;"), "local routines inside generic bodies retain Var ABI, addressability, and dereference semantics")
Local sequentialLocalSource:String = "SuperStrict~nType TSequentialLocal<T>~nMethod Sum:Int(limit:Int)~nFunction Accumulate:Int(value:Int)~nLocal total:Int~nFor Local index:Int = 1 To value~ntotal :+ index~nNext~nReturn total~nEnd Function~nReturn Accumulate(limit)~nEnd Method~nEnd Type~nGlobal sequentialLocal:TSequentialLocal<String>"
Local sequentialLocalCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-sequential-local.bmx", sequentialLocalSource, Null, compilerOptions)
Local sequentialLocalImplementation:String = sequentialLocalCompilation.genericPlan.units[0].implementation
Check(sequentialLocalCompilation.Succeeded() And sequentialLocalImplementation.Contains("_local_Accumulate_") And sequentialLocalImplementation.Contains("bmx_local_total") And sequentialLocalImplementation.Contains("for ("), "multi-statement local routines retain sequential typed bodies and emit as deterministic static helpers")
Local recursiveInlineLocalSource:String = "SuperStrict~nType TRecursiveInlineLocal<T>~nMethod Read:Int(value:Int)~nFunction Again:Int(input:Int) Inline~nReturn Again(input)~nEnd Function~nReturn Again(value)~nEnd Method~nEnd Type~nGlobal recursiveInlineLocal:TRecursiveInlineLocal<String>"
Local recursiveInlineLocalCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-recursive-inline-local.bmx", recursiveInlineLocalSource, Null, compilerOptions)
Local recursiveInlineLocalImplementation:String = recursiveInlineLocalCompilation.genericPlan.units[0].implementation
Check(recursiveInlineLocalCompilation.Succeeded() And recursiveInlineLocalImplementation.Contains("_local_Again_"), "recursive local routines use a deterministic helper call rather than recursive artifact expansion")
Local mutualLocalSource:String = "SuperStrict~nType TMutualLocal<T>~nMethod IsEven:Int(value:Int)~nFunction Even:Int(input:Int)~nIf input = 0 Then Return True~nReturn Odd(input - 1)~nEnd Function~nFunction Odd:Int(input:Int)~nIf input = 0 Then Return False~nReturn Even(input - 1)~nEnd Function~nReturn Even(value)~nEnd Method~nEnd Type~nGlobal mutualLocal:TMutualLocal<String>"
Local mutualLocalCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-mutual-local.bmx", mutualLocalSource, Null, compilerOptions)
Local mutualLocalImplementation:String = mutualLocalCompilation.genericPlan.units[0].implementation
Check(mutualLocalCompilation.Succeeded() And mutualLocalImplementation.Contains("_local_Even_") And mutualLocalImplementation.Contains("_local_Odd_"), "mutually recursive local routines retain one canonical helper body apiece")
Local capturedLocalSource:String = "SuperStrict~nType TCapturedLocal<T>~nField value:Int~nMethod Read:Int()~nFunction Captured:Int()~nReturn value~nEnd Function~nReturn Captured()~nEnd Method~nEnd Type~nGlobal capturedLocal:TCapturedLocal<String>"
Local capturedLocalCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-captured-local.bmx", capturedLocalSource, Null, compilerOptions)
Check(capturedLocalCompilation.Succeeded() And capturedLocalCompilation.genericPlan.units[0].implementation.Contains(" self") And capturedLocalCompilation.genericPlan.units[0].implementation.Contains("_local_Captured_"), "local routines capture Self through a typed hidden receiver parameter: " + CompilationSummary(capturedLocalCompilation))
Local capturedOuterLocalSource:String = "SuperStrict~nType TCapturedOuterLocal<T>~nMethod Read:Int(value:Int)~nLocal adjustment:Int = 2~nFunction Captured:Int()~nvalue :+ 1~nReturn value + adjustment~nEnd Function~nReturn Captured()~nEnd Method~nEnd Type~nGlobal capturedOuterLocal:TCapturedOuterLocal<String>"
Local capturedOuterLocalCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-captured-outer-local.bmx", capturedOuterLocalSource, Null, compilerOptions)
Check(capturedOuterLocalCompilation.Succeeded() And capturedOuterLocalCompilation.genericPlan.units[0].implementation.Contains("BBINT * value") And capturedOuterLocalCompilation.genericPlan.units[0].implementation.Contains("BBINT * adjustment") And capturedOuterLocalCompilation.genericPlan.units[0].implementation.Contains("(&(value))") And capturedOuterLocalCompilation.genericPlan.units[0].implementation.Contains("(&(bmx_local_adjustment))"), "local routines capture containing parameters and outer Locals by address through their canonical helper environment: " + CompilationSummary(capturedOuterLocalCompilation))
Local optionalLocalSource:String = "SuperStrict~nFunction OptionalLocal<T>:Int(value:Int)~nFunction Add:Int(input:Int, amount:Int = 2)~nReturn input + amount~nEnd Function~nReturn Add(value)~nEnd Function~nGlobal optionalLocalValue:Int = OptionalLocal<String>(40)"
Local optionalLocalCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-optional-local.bmx", optionalLocalSource, Null, compilerOptions)
Check(optionalLocalCompilation.Succeeded() And optionalLocalCompilation.genericPlan.units[0].implementation.Contains("(value, 2)"), "local routine optional parameters retain and materialize their bound defaults without source reparsing: " + CompilationSummary(optionalLocalCompilation))
Local genericClosureCallSource:String = "SuperStrict~nFunction Apply<T,R>:R(value:T, operation:Closure<R(value:T)>)~nReturn operation(value)~nEnd Function~nGlobal increment:Closure<Int(value:Int)> = Function(value:Int)~nReturn value + 1~nEnd Function~nGlobal genericClosureResult:Int = Apply<Int,Int>(41, increment)"
Local genericClosureCallCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-closure-call.bmx", genericClosureCallSource, Null, compilerOptions)
Local genericClosureCallImplementation:String = genericClosureCallCompilation.genericPlan.units[0].implementation
Check(genericClosureCallCompilation.Succeeded() And genericClosureCallImplementation.Contains("BBClosure * operation") And genericClosureCallImplementation.Contains("bmx_closure_call_") And genericClosureCallImplementation.Contains("closure->environment") And genericClosureCallImplementation.Contains("brl_blitz_NullFunctionError"), "generic Closure contracts and invocation specialize from the structural source-free signature: " + CompilationSummary(genericClosureCallCompilation))
Local computedReceiverSource:String = "SuperStrict~nType TComputedReceiverTarget~nMethod Read:Int()~nReturn 42~nEnd Method~nEnd Type~nType TComputedReceiverProbe<T>~nMethod Read:Int(factory:Closure<TComputedReceiverTarget()>)~nReturn factory().Read()~nEnd Method~nEnd Type~nGlobal computedReceiverProbe:TComputedReceiverProbe<String>"
Local computedReceiverCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-computed-receiver.bmx", computedReceiverSource, Null, compilerOptions)
Local computedReceiverImplementation:String = computedReceiverCompilation.genericPlan.units[0].implementation
Check(computedReceiverCompilation.Succeeded() And computedReceiverImplementation.Contains("bmx_call_receiver_") And computedReceiverImplementation.Contains("bmx_call_receiver_materialized_receiver_") And Occurrences(computedReceiverImplementation, "bmx_closure_call_") >= 1, "generic virtual calls materialize a computed receiver before using it for class-slot lookup and the receiver argument: " + CompilationSummary(computedReceiverCompilation))
Local genericClosureArraySource:String = "SuperStrict~nFunction Bind<T,R>:Closure<R()>(value:T,operation:Closure<R(value:T)>)~nReturn Function()~nReturn operation(value)~nEnd Function~nEnd Function~nFunction BindAll<T,R>:Closure<R()>[](values:T[],operation:Closure<R(value:T)>)~nLocal result:Closure<R()>[]=New Closure<R()>[values.length]~nFor Local index:Int=0 Until values.length~nresult[index]=Bind<T,R>(values[index],operation)~nNext~nReturn result~nEnd Function~nGlobal render:Closure<String(value:Int)>=Function(value:Int)~nReturn value~nEnd Function~nGlobal actions:Closure<String()>[]=BindAll<Int,String>([1,2],render)"
Local genericClosureArrayCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-closure-array.bmx", genericClosureArraySource, Null, compilerOptions)
Local genericClosureArrayImplementations:String
For Local genericClosureArrayUnit:TCompilerGenericUnit = EachIn genericClosureArrayCompilation.genericPlan.units
	genericClosureArrayImplementations :+ genericClosureArrayUnit.implementation
Next
Check(genericClosureArrayCompilation.Succeeded() And genericClosureArrayCompilation.genericPlan.units.length = 2 And genericClosureArrayImplementations.Contains("BBARRAY") And genericClosureArrayImplementations.Contains("bbArrayNew1D(~q!()$~q") And genericClosureArrayImplementations.Contains("BBClosure **"), "generic Arrays of managed Closure values retain their pointer ABI and structural runtime element encoding: " + CompilationSummary(genericClosureArrayCompilation))
Local genericClosureLiteralSource:String = "SuperStrict~nFunction Identity<T>:Closure<T(value:T)>()~nReturn Function(value:T)~nReturn value~nEnd Function~nEnd Function~nGlobal genericIdentity:Closure<Int(value:Int)> = Identity<Int>()~nGlobal genericIdentityResult:Int = genericIdentity(42)"
Local genericClosureLiteralCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-closure-literal.bmx", genericClosureLiteralSource, Null, compilerOptions)
Local genericClosureLiteralImplementation:String = genericClosureLiteralCompilation.genericPlan.units[0].implementation
Check(genericClosureLiteralCompilation.Succeeded() And genericClosureLiteralImplementation.Contains("static BBClosure") And genericClosureLiteralImplementation.Contains("(BBOBJECT)&bbNullObject") And genericClosureLiteralImplementation.Contains("(void)environment") And genericClosureLiteralImplementation.Contains("return value;"), "non-capturing managed Closure literals in generic bodies lower to deterministic source-free invoke functions and singleton values: " + CompilationSummary(genericClosureLiteralCompilation))
Local genericClosureReflectionSource:String = "SuperStrict~nType TClosureReflectionBox<T>~nField callback:Closure<T(value:T)>~nEnd Type~nGlobal closureReflectionBox:TClosureReflectionBox<Int> = New TClosureReflectionBox<Int>"
Local genericClosureReflectionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-closure-reflection.bmx", genericClosureReflectionSource, Null, compilerOptions)
Local genericClosureReflectionImplementation:String = genericClosureReflectionCompilation.genericPlan.units[0].implementation
Check(genericClosureReflectionCompilation.Succeeded() And genericClosureReflectionImplementation.Contains("BBDEBUGDECL_FIELD, ~qcallback~q, ~q!(i)i~q"), "a closed generic Closure field publishes its substituted structural reflection type: " + CompilationSummary(genericClosureReflectionCompilation))
Local genericThinLiteralSource:String = "SuperStrict~nFunction NestedIdentity<T>:T(value:T)()~nReturn Function(value:T)~nLocal nested:T(item:T) = Function(item:T)~nReturn item~nEnd Function~nReturn nested(value)~nEnd Function~nEnd Function~nGlobal genericThinIdentity:Int(value:Int) = NestedIdentity<Int>()~nGlobal genericThinResult:Int = genericThinIdentity(42)"
Local genericThinLiteralCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-thin-function-literal.bmx", genericThinLiteralSource, Null, compilerOptions)
Local genericThinLiteralImplementation:String = genericThinLiteralCompilation.genericPlan.units[0].implementation
Check(genericThinLiteralCompilation.Succeeded() And Occurrences(genericThinLiteralImplementation, "_function_") >= 2 And genericThinLiteralImplementation.Contains("return item;") And genericThinLiteralImplementation.Contains("(value)") And Not genericThinLiteralImplementation.Contains("static BBClosure"), "nested non-capturing thin literals in generic bodies emit deterministic typed helpers without Closure values: " + CompilationSummary(genericThinLiteralCompilation))
Local capturedGenericThinLiteral:TCompilerResult = TBlitzMaxCompiler.Compile("captured-generic-thin-function-literal.bmx", "SuperStrict~nFunction Bad<T>:Int(value:Int)()~nLocal offset:Int = 1~nReturn Function(value:Int)~nReturn value + offset~nEnd Function~nEnd Function", Null, compilerOptions)
Check(HasLanguageDiagnostic(capturedGenericThinLiteral, "BMX3346"), "thin literals in generic bodies retain the ordinary strict no-capture diagnostic")
Local capturedGenericClosureLiteralSource:String = "SuperStrict~nFunction MakeAdder<T>:Closure<Int(value:Int)>(amount:Int)~nReturn Function(value:Int)~nReturn value + amount~nEnd Function~nEnd Function~nGlobal capturedGenericClosure:Closure<Int(value:Int)> = MakeAdder<String>(1)"
Local capturedGenericClosureLiteralCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-captured-closure-literal.bmx", capturedGenericClosureLiteralSource, Null, compilerOptions)
Local capturedGenericClosureLiteralImplementation:String = capturedGenericClosureLiteralCompilation.genericPlan.units[0].implementation
Check(capturedGenericClosureLiteralCompilation.Succeeded() And capturedGenericClosureLiteralCompilation.genericPlan.units[0].ir.routine.closureEnvironment And capturedGenericClosureLiteralCompilation.genericPlan.units[0].ir.routine.closureEnvironment.captures.length = 1 And capturedGenericClosureLiteralImplementation.Contains("_closure_environment") And capturedGenericClosureLiteralImplementation.Contains("_closure_new") And capturedGenericClosureLiteralImplementation.Contains("offsetof(BBClosure, environment)") And capturedGenericClosureLiteralImplementation.Contains("->capture_amount_"), "capturing managed Closure literals retain a typed environment plan and emit deterministic specialization-owned traced storage: " + CompilationSummary(capturedGenericClosureLiteralCompilation))
Local genericYieldClosureSource:String = "SuperStrict~nImport BRL.Blitz~nFunction CapturedValues<T>:ICloseableIterator<T>(first:T,second:T)~nLocal current:T=first~nLocal read:Closure<T()>=Function()~nReturn current~nEnd Function~nYield read()~ncurrent=second~nYield read()~nEnd Function~nGlobal capturedValues:ICloseableIterator<String>=CapturedValues<String>(~qfirst~q,~qsecond~q)"
Local genericYieldClosureCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-yield-closure.bmx", genericYieldClosureSource, Null, compilerOptions)
Local genericYieldClosureImplementation:String = genericYieldClosureCompilation.genericPlan.units[0].implementation
Check(genericYieldClosureCompilation.Succeeded() And genericYieldClosureImplementation.Contains("_iterator_obj") And genericYieldClosureImplementation.Contains("closure_environment_") And genericYieldClosureImplementation.Contains("state->closure_environment_") And genericYieldClosureImplementation.Contains("_closure_new"), "generic yielding routines retain capturing Closure environments in their iterator state: " + CompilationSummary(genericYieldClosureCompilation))
Local genericYieldingClosureLiteralSource:String = "SuperStrict~nImport BRL.Blitz~nFunction Factory<T>:Closure<ICloseableIterator<T>()>(value:T)~nReturn Function()~nYield value~nEnd Function~nEnd Function~nGlobal factory:Closure<ICloseableIterator<String>()>=Factory<String>(~qvalue~q)~nGlobal values:ICloseableIterator<String>=factory()"
Local genericYieldingClosureLiteralCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-yielding-closure-literal.bmx", genericYieldingClosureLiteralSource, Null, compilerOptions)
Local genericYieldingClosureLiteralImplementation:String = genericYieldingClosureLiteralCompilation.genericPlan.units[0].implementation
Check(genericYieldingClosureLiteralCompilation.Succeeded() And genericYieldingClosureLiteralImplementation.Contains("incoming_closure_environment") And genericYieldingClosureLiteralImplementation.Contains("_iterator_MoveNext") And genericYieldingClosureLiteralImplementation.Contains("state->incoming_closure_environment = environment"), "capturing generic Closure literal bodies lower Yield against their retained incoming environment: " + CompilationSummary(genericYieldingClosureLiteralCompilation))
Local catchClosureModuleSource:String = "SuperStrict~nModule Collections.CatchClosure~nFunction RememberCatch<T>:Closure<String()>(value:String)~nTry~nThrow value~nCatch problem:String~nReturn Function()~nReturn problem~nEnd Function~nEnd Try~nEnd Function"
Local catchClosureModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/catchclosure.mod/catchclosure.bmx", catchClosureModuleSource, Null, compilerOptions)
Local catchClosureArtifactDiagnostics:TCompilerDiagnostic[]
Local catchClosureOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(catchClosureModuleCompilation, catchClosureArtifactDiagnostics)
Local catchClosureInterfaceDiagnostics:TCompilerDiagnostic[]
Local catchClosureInterface:String = TBlitzMaxCompiler.EmitInterface(catchClosureModuleCompilation, catchClosureInterfaceDiagnostics)
Local catchClosureResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
catchClosureResolver.AddInterface("collections.catchclosure", "sdk/collections.catchclosure.i", catchClosureInterface)
For Local catchClosureOutput:TCompilerGenericTemplateOutput = EachIn catchClosureOutputs
	catchClosureResolver.AddGenericTemplate(catchClosureOutput.artifactReference, "sdk/" + catchClosureOutput.artifactReference, catchClosureOutput.content)
Next
Local catchClosureConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-imported-catch-closure.bmx", "SuperStrict~nImport Collections.CatchClosure~nGlobal callback:Closure<String()> = RememberCatch<Int>(~qretained~q)", catchClosureResolver, compilerOptions)
Local catchClosureImplementation:String
For Local catchClosureUnit:TCompilerGenericUnit = EachIn catchClosureConsumer.genericPlan.units
	catchClosureImplementation :+ catchClosureUnit.implementation
Next
Check(catchClosureModuleCompilation.Succeeded() And catchClosureArtifactDiagnostics.length = 0 And catchClosureInterfaceDiagnostics.length = 0 And catchClosureOutputs.length = 1 And catchClosureInterface.Contains("RememberCatch<T>:Closure<String()>(value$)"), "a generic Catch-capturing Closure publishes a compact signature and canonical artifact: outputs=" + catchClosureOutputs.length + " interface=" + catchClosureInterface + " compilation=" + CompilationSummary(catchClosureModuleCompilation))
Check(catchClosureConsumer.Succeeded() And catchClosureConsumer.genericPlan.units.length = 1 And catchClosureImplementation.Contains("_closure_environment_catch_") And catchClosureImplementation.Contains("capture_problem_") And catchClosureImplementation.Contains("bbExCatch()"), "an imported generic Catch capture specializes its fresh managed activation environment without defining source: " + CompilationSummary(catchClosureConsumer))
Local assertSource:String = "SuperStrict~nType TAssertBox<T>~nMethod Check(value:T)~nAssert value~nEnd Method~nEnd Type~nGlobal assertBox:TAssertBox<String>"
Local releaseAssertCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-assert.bmx", assertSource, Null, compilerOptions)
Check(releaseAssertCompilation.Succeeded() And Not releaseAssertCompilation.genericPlan.units[0].implementation.Contains("brl_blitz_RuntimeError"), "release generic specialization retains Assert semantically but does not emit or evaluate it")
compilerOptions.buildMode = "debug"
compilerOptions.debugInstrumentation = True
Local debugGenericClosureCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-captured-closure-debug.bmx", capturedGenericClosureLiteralSource, Null, compilerOptions)
Local debugGenericClosureImplementation:String = debugGenericClosureCompilation.genericPlan.units[0].implementation
Check(debugGenericClosureCompilation.Succeeded() And debugGenericClosureImplementation.Contains("BBDEBUGSCOPE_FUNCTION, ~qClosure in MakeAdder at line 3~q"), "a specialized managed Closure debugger frame identifies its generic source owner and literal line: " + CompilationSummary(debugGenericClosureCompilation))
Check(Occurrences(debugGenericClosureImplementation, "BBDEBUGDECL_LOCAL, ~qamount~q, ~qi~q") = 2 And Not debugGenericClosureImplementation.Contains("BBDEBUGDECL_LOCAL, ~qenvironment~q"), "a specialized managed Closure debugger scope exposes the captured source parameter and hides its erased environment parameter")
Local debugNestedGenericClosureSource:String = "SuperStrict~nFunction MakeNested<T>:Closure<Closure<Int()>()>(initial:Int)~nLocal outer:Int=initial~nReturn Function()~nLocal inner:Int=2~nReturn Function()~nReturn outer+inner~nEnd Function~nEnd Function~nEnd Function~nGlobal factory:Closure<Closure<Int()>()> = MakeNested<String>(40)"
Local debugNestedGenericClosureCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-nested-closure-debug.bmx", debugNestedGenericClosureSource, Null, compilerOptions)
Local debugNestedGenericClosureImplementation:String = debugNestedGenericClosureCompilation.genericPlan.units[0].implementation
Check(debugNestedGenericClosureCompilation.Succeeded() And debugNestedGenericClosureImplementation.Contains("BBDEBUGSCOPE_FUNCTION, ~qClosure in MakeNested at line 4~q") And debugNestedGenericClosureImplementation.Contains("BBDEBUGSCOPE_FUNCTION, ~qClosure in MakeNested at line 6~q"), "nested specialized Closure frames retain distinct source lines and the user-authored generic owner: " + CompilationSummary(debugNestedGenericClosureCompilation))
Check(Occurrences(debugNestedGenericClosureImplementation, "BBDEBUGDECL_LOCAL, ~qouter~q, ~qi~q") = 3 And Occurrences(debugNestedGenericClosureImplementation, "BBDEBUGDECL_LOCAL, ~qinner~q, ~qi~q") = 2, "nested specialized Closure debugger scopes traverse their canonical parent environments without duplicate source variables")
Local debugAssertCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-assert.bmx", assertSource, Null, compilerOptions)
Check(debugAssertCompilation.Succeeded() And debugAssertCompilation.genericPlan.units[0].implementation.Contains("brl_blitz_RuntimeError(bbStringFromCString(~qAssert failed~q))"), "debug generic specialization emits retained Assert instrumentation")
Check(releaseAssertCompilation.genericPlan.units[0].specialization.identityDigest = debugAssertCompilation.genericPlan.units[0].specialization.identityDigest And releaseAssertCompilation.genericPlan.units[0].specialization.generatedUnit <> debugAssertCompilation.genericPlan.units[0].specialization.generatedUnit, "release and debug requests retain one semantic ABI identity but use distinct code-generation-addressed C units")
Local debugConstructorEachInSource:String = "SuperStrict~nType TDebugConstructor<T>~nMethod New(values:T[])~nFor Local item:T = EachIn values~nNext~nEnd Method~nEnd Type~nGlobal debugConstructor:TDebugConstructor<Int> = New TDebugConstructor<Int>([1, 2])"
Local debugConstructorEachInCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-debug-constructor-eachin.bmx", debugConstructorEachInSource, Null, compilerOptions)
Local debugConstructorEachInImplementation:String = debugConstructorEachInCompilation.genericPlan.units[0].implementation
Check(debugConstructorEachInCompilation.Succeeded() And debugConstructorEachInImplementation.Contains("BBINT bmx_local_item_") And debugConstructorEachInImplementation.Contains(" = bmx_loop0_element;"), "debug generic constructors hoist addressable EachIn locals before assigning their loop values: " + CompilationSummary(debugConstructorEachInCompilation))
Local debugManagedArraySource:String = "SuperStrict~nFunction ProbeManagedArray<T>:Int(boxed:Object)~nLocal values:T[] = T[](boxed)~nLocal count:Int = values.length~nIf values Then count :+ 1~nFor Local value:T = EachIn values~ncount :+ 1~nNext~nReturn count~nEnd Function~nGlobal managedArrayCount:Int = ProbeManagedArray<String>(Null)"
Local debugManagedArrayCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-debug-managed-array.bmx", debugManagedArraySource, Null, compilerOptions)
Local debugManagedArrayImplementation:String = debugManagedArrayCompilation.genericPlan.units[0].implementation
Check(debugManagedArrayCompilation.Succeeded() And debugManagedArrayImplementation.Contains("bbArrayCastFromObject((BBOBJECT)") And Occurrences(debugManagedArrayImplementation, "bbManagedArrayAssert((BBARRAY)") >= 3, "debug generic Array casts validate their sentinel family at truth, length, and EachIn uses: " + CompilationSummary(debugManagedArrayCompilation))
compilerOptions.buildMode = "release"
compilerOptions.debugInstrumentation = False
Local whileFlowSource:String = "SuperStrict~nFunction StopWhile<T>:T(value:T, enabled:Int)~nWhile enabled~nExit~nWend~nReturn value~nEnd Function~nGlobal stopped:Int = StopWhile(1, True)"
Local whileFlowCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-while-flow.bmx", whileFlowSource, Null, compilerOptions)
Check(whileFlowCompilation.Succeeded() And whileFlowCompilation.genericPlan.units.length = 1 And whileFlowCompilation.genericPlan.units[0].implementation.Contains("goto bmx_loop0_exit;") And whileFlowCompilation.genericPlan.units[0].implementation.Contains("bmx_loop0_exit: ;"), "generic Exit retains and emits its canonical While target identity: " + CompilationSummary(whileFlowCompilation))
Local nestedLoopControlSource:String = "SuperStrict~nFunction NestedControl<T>:T(seed:T)~nLocal result:T = seed~nLocal outer:Int~n#Outer~nRepeat~nouter = outer + 1~nLocal inner:Int~nRepeat~ninner = inner + 1~nIf inner = 2 Then Continue~nIf outer = 2 Then Continue Outer~nIf inner = 4 Then Exit~nresult = result + seed~nForever~nIf outer = 3 Then Exit Outer~nUntil outer = 10~nReturn result~nEnd Function~nGlobal nestedControl:Int = NestedControl(8)"
Local nestedLoopControlCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-nested-loop-control.bmx", nestedLoopControlSource, Null, compilerOptions)
Check(nestedLoopControlCompilation.Succeeded() And nestedLoopControlCompilation.genericPlan.units.length = 1, "nested and labelled generic loop control resolves to canonical targets: " + CompilationSummary(nestedLoopControlCompilation))
Local nestedLoopControlImplementation:String = nestedLoopControlCompilation.genericPlan.units[0].implementation
Check(nestedLoopControlImplementation.Contains("goto bmx_loop1_continue;") And nestedLoopControlImplementation.Contains("goto bmx_loop0_continue;") And nestedLoopControlImplementation.Contains("goto bmx_loop1_exit;") And nestedLoopControlImplementation.Contains("goto bmx_loop0_exit;"), "nested generic loop control retains inner and labelled outer target identities")
Check(nestedLoopControlImplementation.Contains("bmx_loop1_continue: ;") And nestedLoopControlImplementation.Contains("bmx_loop0_continue: ;") And nestedLoopControlImplementation.Contains("bmx_loop1_exit: ;") And nestedLoopControlImplementation.Contains("bmx_loop0_exit: ;"), "generic loop owners emit each referenced deterministic control label")
Local repeatBodySource:String = "SuperStrict~nFunction RepeatUntilAdd<T>:T(seed:T, count:Int)~nLocal result:T = seed~nLocal index:Int~nRepeat~nLocal current:T = seed~nresult = result + current~nindex = index + 1~nUntil index = count~nReturn result~nEnd Function~nGlobal repeatedUntil1:Int = RepeatUntilAdd(7, 5)~nGlobal repeatedUntil2:Int = RepeatUntilAdd<Int>(6, 6)"
Local repeatBodyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-repeat-body.bmx", repeatBodySource, Null, compilerOptions)
Check(repeatBodyCompilation.Succeeded() And repeatBodyCompilation.genericPlan.units.length = 1, "generic routine retains one canonical typed Repeat Until body: " + CompilationSummary(repeatBodyCompilation))
Local repeatBodyImplementation:String = repeatBodyCompilation.genericPlan.units[0].implementation
Check(repeatBodyImplementation.Contains("do {") And repeatBodyImplementation.Contains("BBINT bmx_local_current = seed;") And repeatBodyImplementation.Contains("} while (!((bmx_local_index == count)));"), "generic Repeat Until emits a scoped body and post-body scalar condition")
Local repeatForeverSource:String = "SuperStrict~nFunction FirstForever<T>:T(value:T)~nRepeat~nReturn value~nForever~nEnd Function~nGlobal firstForever:Int = FirstForever(42)"
Local repeatForeverCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-repeat-forever.bmx", repeatForeverSource, Null, compilerOptions)
Check(repeatForeverCompilation.Succeeded() And repeatForeverCompilation.genericPlan.units.length = 1 And repeatForeverCompilation.genericPlan.units[0].implementation.Contains("for (;;) {") And repeatForeverCompilation.genericPlan.units[0].implementation.Contains("return value;"), "generic Repeat Forever retains a source-free loop body")
Local managedRepeatSource:String = "SuperStrict~nFunction RepeatText<T>:T(value:T)~nRepeat~nReturn value~nUntil value~nEnd Function~nGlobal repeatText:String = RepeatText(~qvalue~q)"
Local managedRepeatCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-managed-repeat.bmx", managedRepeatSource, Null, compilerOptions)
Check(managedRepeatCompilation.Succeeded() And managedRepeatCompilation.genericPlan.units[0].implementation.Contains("} while (!((value != &bbEmptyString)));"), "managed generic String Repeat Until truth specializes against the runtime empty sentinel")
Local forBodySource:String = "SuperStrict~nFunction ForAdd<T>:T(seed:T, count:Int)~nLocal result:T = seed~nFor Local index:Int = 0 Until count~nLocal current:T = seed~nresult = result + current~nNext~nReturn result~nEnd Function~nGlobal forAdded1:Int = ForAdd(7, 5)~nGlobal forAdded2:Int = ForAdd<Int>(6, 6)"
Local forBodyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-body.bmx", forBodySource, Null, compilerOptions)
Check(forBodyCompilation.Succeeded() And forBodyCompilation.genericPlan.units.length = 1, "generic routine retains one canonical typed range For body: " + CompilationSummary(forBodyCompilation))
Local forBodyImplementation:String = forBodyCompilation.genericPlan.units[0].implementation
Check(forBodyImplementation.Contains("for (BBINT bmx_local_index = ((BBINT)(0)); bmx_local_index < ((BBINT)(count)); bmx_local_index = bmx_local_index + ((BBINT)(1))) {") And forBodyImplementation.Contains("BBINT bmx_local_current = seed;") And forBodyImplementation.Contains("bmx_local_result = (bmx_local_result + bmx_local_current);"), "generic For Until emits a typed loop declaration, exclusive limit, default step, and scoped body")
Local forDescendingSource:String = "SuperStrict~nFunction ForDown<T>:T(value:T)~nLocal result:T = value~nFor Local index:Int = 3 To 1 Step -1~nresult = result + value~nNext~nReturn result~nEnd Function~nGlobal forDown:Int = ForDown(10)"
Local forDescendingCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-down.bmx", forDescendingSource, Null, compilerOptions)
Check(forDescendingCompilation.Succeeded() And forDescendingCompilation.genericPlan.units.length = 1 And forDescendingCompilation.genericPlan.units[0].implementation.Contains("bmx_local_index >= ((BBINT)(1))") And forDescendingCompilation.genericPlan.units[0].implementation.Contains("((BBINT)((-1)))"), "generic descending For To preserves inclusive comparison and explicit negative step")
Local forExistingTargetSource:String = "SuperStrict~nFunction ForExisting<T>:T(value:T)~nLocal index:Int~nFor index = 0 Until 1~nNext~nReturn value~nEnd Function~nGlobal forExisting:Int = ForExisting(1)"
Local forExistingTargetCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-existing-target.bmx", forExistingTargetSource, Null, compilerOptions)
Check(forExistingTargetCompilation.Succeeded() And forExistingTargetCompilation.genericPlan.units.length = 1 And forExistingTargetCompilation.genericPlan.units[0].implementation.Contains("for (bmx_local_index = ((BBINT)(0)); bmx_local_index < ((BBINT)(1));"), "generic range For retains an existing Local target without redeclaring it: " + CompilationSummary(forExistingTargetCompilation))
Local forParameterTargetSource:String = "SuperStrict~nFunction ForParameter<T>:T(value:T, index:Int)~nFor index = 1 To 2~nNext~nReturn value~nEnd Function~nGlobal forParameter:Int = ForParameter(1, 0)"
Local forParameterTargetCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-parameter-target.bmx", forParameterTargetSource, Null, compilerOptions)
Check(forParameterTargetCompilation.Succeeded() And forParameterTargetCompilation.genericPlan.units.length = 1 And forParameterTargetCompilation.genericPlan.units[0].implementation.Contains("for (index = ((BBINT)(1)); index <= ((BBINT)(2));"), "generic range For retains an existing value-parameter target")
Local forEachStringSource:String = "SuperStrict~nFunction ForEachText<T>:T(value:T, text:String)~nFor Local code:Int = EachIn text~nIf code = 32 Then Continue~nIf code = 33 Then Exit~nNext~nReturn value~nEnd Function~nGlobal forEachText:Int = ForEachText(1, ~qA B!~q)"
Local forEachStringCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-eachin-string.bmx", forEachStringSource, Null, compilerOptions)
Check(forEachStringCompilation.Succeeded() And forEachStringCompilation.genericPlan.units.length = 1, "generic String EachIn retains one canonical typed body: " + CompilationSummary(forEachStringCompilation))
Local forEachStringImplementation:String = forEachStringCompilation.genericPlan.units[0].implementation
Check(forEachStringImplementation.Contains("BBSTRING bmx_loop0_collection = text;") And forEachStringImplementation.Contains("bmx_loop0_collection->length") And forEachStringImplementation.Contains("bmx_loop0_collection->buf[bmx_loop0_index]") And forEachStringImplementation.Contains("BBINT bmx_local_code = ((BBINT)(bmx_loop0_element));"), "generic String EachIn evaluates its collection once and emits typed UTF-16 code-unit iteration")
Check(forEachStringImplementation.Contains("goto bmx_loop0_continue;") And forEachStringImplementation.Contains("bmx_loop0_continue: ;") And forEachStringImplementation.Contains("goto bmx_loop0_exit;") And forEachStringImplementation.Contains("bmx_loop0_exit: ;"), "generic String EachIn retains deterministic Continue and Exit targets")
Local forEachStringExistingSource:String = "SuperStrict~nFunction ForEachExisting<T>:T(value:T, text:String)~nLocal code:Short~nFor code = EachIn text~nNext~nReturn value~nEnd Function~nGlobal forEachExisting:Int = ForEachExisting(1, ~qab~q)"
Local forEachStringExistingCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-eachin-string-existing.bmx", forEachStringExistingSource, Null, compilerOptions)
Check(forEachStringExistingCompilation.Succeeded() And forEachStringExistingCompilation.genericPlan.units.length = 1 And forEachStringExistingCompilation.genericPlan.units[0].implementation.Contains("bmx_local_code = ((BBSHORT)(bmx_loop0_element));"), "generic String EachIn retains an existing scalar Local target")
Local forEachStringParameterSource:String = "SuperStrict~nFunction ForEachParameter<T>:T(value:T, text:String, code:UInt)~nFor code = EachIn text~nNext~nReturn value~nEnd Function~nGlobal forEachParameter:Int = ForEachParameter(1, ~qab~q, 0)"
Local forEachStringParameterCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-eachin-string-parameter.bmx", forEachStringParameterSource, Null, compilerOptions)
Check(forEachStringParameterCompilation.Succeeded() And forEachStringParameterCompilation.genericPlan.units.length = 1 And forEachStringParameterCompilation.genericPlan.units[0].implementation.Contains("code = ((BBUINT)(bmx_loop0_element));"), "generic String EachIn retains an existing scalar value-parameter target")
Local forEachArraySource:String = "SuperStrict~nFunction FirstArrayValue<T>:T(fallback:T, values:T[])~nFor Local item:T = EachIn values~nReturn item~nNext~nReturn fallback~nEnd Function~nGlobal firstArrayInt:Int = FirstArrayValue(0, [42])~nGlobal firstArrayString:String = FirstArrayValue<String>(~qnone~q, [~qvalue~q])"
Local forEachArrayCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-eachin-array.bmx", forEachArraySource, Null, compilerOptions)
Check(forEachArrayCompilation.Succeeded() And forEachArrayCompilation.genericPlan.units.length = 2, "generic managed Array EachIn closes scalar and String element specializations: " + CompilationSummary(forEachArrayCompilation))
Local forEachArrayIntImplementation:String
Local forEachArrayStringImplementation:String
For Local forEachArrayUnit:TCompilerGenericUnit = EachIn forEachArrayCompilation.genericPlan.units
	If forEachArrayUnit.ir.specialization.key.typeArguments[0].CanonicalName() = "int" Then forEachArrayIntImplementation = forEachArrayUnit.implementation
	If forEachArrayUnit.ir.specialization.key.typeArguments[0].CanonicalName() = "string" Then forEachArrayStringImplementation = forEachArrayUnit.implementation
Next
Check(forEachArrayIntImplementation.Contains("BBARRAY bmx_loop0_collection = values;") And forEachArrayIntImplementation.Contains("bmx_loop0_collection->scales[0]") And forEachArrayIntImplementation.Contains("((BBINT*)BBARRAYDATA(bmx_loop0_collection, 1))[bmx_loop0_index]") And forEachArrayIntImplementation.Contains("BBINT bmx_local_item = bmx_loop0_element;"), "generic scalar Array EachIn evaluates once and emits a closed typed element load")
Check(forEachArrayStringImplementation.Contains("((BBSTRING*)BBARRAYDATA(bmx_loop0_collection, 1))[bmx_loop0_index]") And forEachArrayStringImplementation.Contains("BBSTRING bmx_local_item = bmx_loop0_element;"), "generic String Array EachIn emits the closed managed element ABI")
Local forEachArrayExistingSource:String = "SuperStrict~nFunction LastArrayValue<T>:T(value:T, values:T[])~nFor value = EachIn values~nNext~nReturn value~nEnd Function~nGlobal lastArrayValue:Int = LastArrayValue(0, [1, 2])"
Local forEachArrayExistingCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-eachin-array-existing.bmx", forEachArrayExistingSource, Null, compilerOptions)
Check(forEachArrayExistingCompilation.Succeeded() And forEachArrayExistingCompilation.genericPlan.units.length = 1 And forEachArrayExistingCompilation.genericPlan.units[0].implementation.Contains("value = bmx_loop0_element;"), "generic managed Array EachIn retains an existing matching value-parameter target")
Local forEachStaticArraySource:String = "SuperStrict~nFunction ScanFixed<T>:T(value:T, StaticArray values:Int[2])~nFor Local item:Short = EachIn values~nIf item = 0 Then Continue~nExit~nNext~nReturn value~nEnd Function~nLocal StaticArray fixed:Int[2]~nfixed[0] = 42~nLocal scannedFixed:Int = ScanFixed(7, fixed)"
Local forEachStaticArrayCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-eachin-static-array.bmx", forEachStaticArraySource, Null, compilerOptions)
Check(forEachStaticArrayCompilation.Succeeded() And forEachStaticArrayCompilation.genericPlan.units.length = 1, "generic StaticArray EachIn closes an extent-bearing numeric specialization: " + CompilationSummary(forEachStaticArrayCompilation))
Local forEachStaticArrayImplementation:String = forEachStaticArrayCompilation.genericPlan.units[0].implementation
Check(forEachStaticArrayImplementation.Contains("BBINT * values") And forEachStaticArrayImplementation.Contains("BBINT *bmx_loop0_collection = values;") And forEachStaticArrayImplementation.Contains("< (BBUINT)2;") And forEachStaticArrayImplementation.Contains("BBINT bmx_loop0_element = bmx_loop0_collection[bmx_loop0_index];") And forEachStaticArrayImplementation.Contains("BBSHORT bmx_local_item = ((BBSHORT)(bmx_loop0_element));"), "generic StaticArray EachIn emits its pointer ABI, fixed extent, typed load, and numeric target conversion")
Check(forEachStaticArrayImplementation.Contains("goto bmx_loop0_continue;") And forEachStaticArrayImplementation.Contains("goto bmx_loop0_exit;"), "generic StaticArray EachIn shares canonical loop-control identities")
Local forEachInterfaceSource:String = "SuperStrict~nInterface IIterator<T>~nMethod Current:T()~nMethod MoveNext:Int()~nEnd Interface~nInterface IIterable<T>~nMethod GetIterator:IIterator<T>()~nEnd Interface~nType TCanonicalIterator<T> Implements IIterator<T>~nField value:T~nField remaining:Int~nMethod Current:T()~nReturn value~nEnd Method~nMethod MoveNext:Int()~nIf remaining Then~nremaining = 0~nReturn True~nEnd If~nReturn False~nEnd Method~nEnd Type~nType TCanonicalValues<T> Implements IIterable<T>~nField iterator:IIterator<T>~nMethod GetIterator:IIterator<T>()~nReturn iterator~nEnd Method~nEnd Type~nFunction FirstDirect<T>:T(fallback:T, iterator:IIterator<T>)~nFor Local item:T = EachIn iterator~nReturn item~nNext~nReturn fallback~nEnd Function~nFunction FirstIterable<T>:T(fallback:T, values:IIterable<T>)~nFor Local item:T = EachIn values~nReturn item~nNext~nReturn fallback~nEnd Function~nGlobal canonicalIterator:TCanonicalIterator<Int> = New TCanonicalIterator<Int>~ncanonicalIterator.value = 42~ncanonicalIterator.remaining = 1~nGlobal iteratorView:IIterator<Int> = canonicalIterator~nGlobal directEachIn:Int = FirstDirect(0, iteratorView)~ncanonicalIterator.remaining = 1~nGlobal canonicalValues:TCanonicalValues<Int> = New TCanonicalValues<Int>~ncanonicalValues.iterator = canonicalIterator~nGlobal iterableView:IIterable<Int> = canonicalValues~nGlobal iterableEachIn:Int = FirstIterable(0, iterableView)"
Local forEachInterfaceCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-eachin-interface.bmx", forEachInterfaceSource, Null, compilerOptions)
Check(forEachInterfaceCompilation.Succeeded(), "generic IIterator and IIterable EachIn close canonical Interface protocol graphs: " + CompilationSummary(forEachInterfaceCompilation))
Local directEachInImplementation:String
Local iterableEachInImplementation:String
For Local interfaceEachInUnit:TCompilerGenericUnit = EachIn forEachInterfaceCompilation.genericPlan.units
	If interfaceEachInUnit.ir.specialization.artifact.identity.qualifiedName = "FirstDirect" Then directEachInImplementation = interfaceEachInUnit.implementation
	If interfaceEachInUnit.ir.specialization.artifact.identity.qualifiedName = "FirstIterable" Then iterableEachInImplementation = interfaceEachInUnit.implementation
Next
Check(directEachInImplementation.Contains("BBOBJECT bmx_loop0_collection = (BBOBJECT)(iterator);") And directEachInImplementation.Contains("BBOBJECT bmx_loop0_iterator = bmx_loop0_collection;") And directEachInImplementation.Contains("bbObjectInterface((BBOBJECT)bmx_loop0_iterator") And directEachInImplementation.Contains("m_movenext_1") And directEachInImplementation.Contains("m_current_0"), "direct generic IIterator EachIn persists and emits canonical advance/current Interface slots")
Check(iterableEachInImplementation.Contains("BBOBJECT bmx_loop0_collection = (BBOBJECT)(values);") And iterableEachInImplementation.Contains("BBOBJECT bmx_loop0_iterator = ((struct ") And iterableEachInImplementation.Contains("m_getiterator_0") And iterableEachInImplementation.Contains("bbObjectInterface((BBOBJECT)bmx_loop0_iterator"), "generic IIterable EachIn persists and emits canonical factory plus iterator Interface dispatch")
Local forEachConcreteIteratorSource:String = "SuperStrict~nInterface IIterator<T>~nMethod Current:T()~nMethod MoveNext:Int()~nEnd Interface~nType TConcreteIterator<T> Implements IIterator<T>~nField value:T~nField remaining:Int~nMethod Current:T()~nReturn value~nEnd Method~nMethod MoveNext:Int()~nIf remaining Then~nremaining = 0~nReturn True~nEnd If~nReturn False~nEnd Method~nEnd Type~nFunction FirstConcrete<T>:T(fallback:T, iterator:TConcreteIterator<T>)~nFor Local item:T = EachIn iterator~nReturn item~nNext~nReturn fallback~nEnd Function~nGlobal concreteIterator:TConcreteIterator<String> = New TConcreteIterator<String>~nconcreteIterator.value = ~qvalue~q~nconcreteIterator.remaining = 1~nGlobal concreteFirst:String = FirstConcrete(~qfallback~q, concreteIterator)"
Local forEachConcreteIteratorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-eachin-concrete-iterator.bmx", forEachConcreteIteratorSource, Null, compilerOptions)
Local forEachConcreteIteratorImplementation:String
For Local concreteIteratorUnit:TCompilerGenericUnit = EachIn forEachConcreteIteratorCompilation.genericPlan.units
	If concreteIteratorUnit.ir.specialization.artifact.identity.qualifiedName = "FirstConcrete" Then forEachConcreteIteratorImplementation = concreteIteratorUnit.implementation; Exit
Next
Check(forEachConcreteIteratorCompilation.Succeeded() And forEachConcreteIteratorImplementation.Contains("bbObjectInterface((BBOBJECT)bmx_loop0_iterator") And forEachConcreteIteratorImplementation.Contains("m_movenext_1") And forEachConcreteIteratorImplementation.Contains("m_current_0"), "a concrete canonical Type implementing IIterator dispatches direct EachIn through its implemented Interface: " + CompilationSummary(forEachConcreteIteratorCompilation))
Local forEachSelfSource:String = "SuperStrict~nInterface IIterator<T>~nMethod Current:T()~nMethod MoveNext:Int()~nEnd Interface~nInterface IIterable<T>~nMethod GetIterator:IIterator<T>()~nEnd Interface~nType TSelfIterator<T> Implements IIterator<T>~nField value:T~nField remaining:Int~nMethod Current:T()~nReturn value~nEnd Method~nMethod MoveNext:Int()~nIf remaining Then~nremaining = 0~nReturn True~nEnd If~nReturn False~nEnd Method~nEnd Type~nType TSelfValues<T> Implements IIterable<T>~nField iterator:IIterator<T>~nMethod GetIterator:IIterator<T>()~nReturn iterator~nEnd Method~nMethod First:T(fallback:T)~nFor Local item:T = EachIn Self~nReturn item~nNext~nReturn fallback~nEnd Method~nEnd Type~nGlobal selfIterator:TSelfIterator<String> = New TSelfIterator<String>~nselfIterator.value = ~qvalue~q~nselfIterator.remaining = 1~nGlobal selfValues:TSelfValues<String> = New TSelfValues<String>~nselfValues.iterator = selfIterator~nGlobal selfFirst:String = selfValues.First(~qfallback~q)"
Local forEachSelfCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-eachin-self.bmx", forEachSelfSource, Null, compilerOptions)
Local forEachSelfImplementation:String
For Local forEachSelfUnit:TCompilerGenericUnit = EachIn forEachSelfCompilation.genericPlan.units
	If forEachSelfUnit.ir.specialization.artifact.identity.qualifiedName = "TSelfValues" Then forEachSelfImplementation = forEachSelfUnit.implementation; Exit
Next
Check(forEachSelfCompilation.Succeeded() And forEachSelfImplementation.Contains("BBOBJECT bmx_loop0_collection = (BBOBJECT)(((struct ") And forEachSelfImplementation.Contains("m_getiterator_0") And forEachSelfImplementation.Contains("bbObjectInterface((BBOBJECT)bmx_loop0_iterator"), "EachIn Self explicitly upcasts the canonical Type receiver before Interface dispatch: " + CompilationSummary(forEachSelfCompilation))
Local forEachLegacySource:String = "SuperStrict~nType TLegacyIterator<T>~nField value:Object~nField remaining:Int~nMethod HasNext:Int()~nIf remaining Then~nremaining = 0~nReturn True~nEnd If~nReturn False~nEnd Method~nMethod NextObject:Object()~nReturn value~nEnd Method~nEnd Type~nType TLegacyValues<T>~nField iterator:TLegacyIterator<T>~nMethod ObjectEnumerator:TLegacyIterator<T>()~nReturn iterator~nEnd Method~nEnd Type~nFunction ProbeEachIn<T>:T(value:T, legacy:TLegacyValues<T>)~nFor Local item:Object = EachIn legacy~nNext~nReturn value~nEnd Function~nGlobal legacyIterator:TLegacyIterator<Int> = New TLegacyIterator<Int>~nlegacyIterator.remaining = 1~nGlobal legacyValues:TLegacyValues<Int> = New TLegacyValues<Int>~nlegacyValues.iterator = legacyIterator~nGlobal probedEachIn:Int = ProbeEachIn(1, legacyValues)"
Local forEachLegacyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-eachin-object-enumerator.bmx", forEachLegacySource, Null, compilerOptions)
Check(forEachLegacyCompilation.Succeeded(), "generic ObjectEnumerator EachIn closes canonical generic Type protocol graphs: " + CompilationSummary(forEachLegacyCompilation))
Local legacyEachInImplementation:String
For Local legacyEachInUnit:TCompilerGenericUnit = EachIn forEachLegacyCompilation.genericPlan.units
	If legacyEachInUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeEachIn" Then legacyEachInImplementation = legacyEachInUnit.implementation
Next
Check(legacyEachInImplementation.Contains("->clas->m_objectenumerator_0") And legacyEachInImplementation.Contains("->clas->m_hasnext_0") And legacyEachInImplementation.Contains("->clas->m_nextobject_1") And legacyEachInImplementation.Contains("== (BBOBJECT)&bbNullObject") And legacyEachInImplementation.Contains("BBOBJECT bmx_local_item"), "generic ObjectEnumerator EachIn emits canonical virtual operations, explicit null filtering, and Object target adaptation")
Local inheritedGenericEachInSource:String = "SuperStrict~nType TGenericIteratorBase<T>~nField value:Object~nMethod HasNext:Int()~nReturn False~nEnd Method~nMethod NextObject:Object()~nReturn value~nEnd Method~nEnd Type~nType TGenericIteratorDerived<T> Extends TGenericIteratorBase<T>~nMethod HasNext:Int() Override~nReturn False~nEnd Method~nEnd Type~nType TGenericValuesBase<T>~nField iterator:TGenericIteratorDerived<T>~nMethod ObjectEnumerator:TGenericIteratorDerived<T>()~nReturn iterator~nEnd Method~nEnd Type~nType TGenericValuesDerived<T> Extends TGenericValuesBase<T>~nEnd Type~nFunction ProbeInheritedGeneric<T>:T(value:T, legacy:TGenericValuesDerived<T>)~nFor Local item:Object = EachIn legacy~nNext~nReturn value~nEnd Function~nGlobal inheritedGenericValues:TGenericValuesDerived<Int> = New TGenericValuesDerived<Int>~nGlobal inheritedGenericResult:Int = ProbeInheritedGeneric(1, inheritedGenericValues)"
Local inheritedGenericEachInCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-eachin-inherited-object-enumerator.bmx", inheritedGenericEachInSource, Null, compilerOptions)
Local inheritedGenericEachInImplementation:String
For Local inheritedGenericEachInUnit:TCompilerGenericUnit = EachIn inheritedGenericEachInCompilation.genericPlan.units
	If inheritedGenericEachInUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeInheritedGeneric" Then inheritedGenericEachInImplementation = inheritedGenericEachInUnit.implementation
Next
Check(inheritedGenericEachInCompilation.Succeeded(), "inherited and overridden canonical generic ObjectEnumerator slots lower without reparsing: " + CompilationSummary(inheritedGenericEachInCompilation))
Check(inheritedGenericEachInImplementation.Contains("->clas->m_objectenumerator_0") And inheritedGenericEachInImplementation.Contains("->clas->m_hasnext_0") And inheritedGenericEachInImplementation.Contains("->clas->m_nextobject_1"), "inherited generic ObjectEnumerator dispatch preserves base slot names across exact overrides")
Local inheritedGenericLayoutsUnique:Int = True
For Local inheritedLayoutUnit:TCompilerGenericUnit = EachIn inheritedGenericEachInCompilation.genericPlan.units
	If inheritedLayoutUnit.ir.isRoutine Or inheritedLayoutUnit.ir.isInterface Or inheritedLayoutUnit.ir.isStruct Then Continue
	Local inheritedLayoutDefinition:String = "struct " + inheritedLayoutUnit.specialization.readableAbiName + "_obj {"
	If inheritedGenericEachInImplementation.Split(inheritedLayoutDefinition).length - 1 > 1 Then inheritedGenericLayoutsUnique = False
Next
Check(inheritedGenericLayoutsUnique, "one routine C unit emits each transitive inherited generic object layout at most once")
Local forEachProtocolBoundarySource:String = "SuperStrict~nType TLegacyIterator~nMethod HasNext:Int()~nReturn False~nEnd Method~nMethod NextObject:Object()~nReturn Null~nEnd Method~nEnd Type~nType TLegacyValues~nMethod ObjectEnumerator:TLegacyIterator()~nReturn New TLegacyIterator~nEnd Method~nEnd Type~nFunction ProbeEachIn<T>:T(value:T, legacy:TLegacyValues)~nFor Local item:Object = EachIn legacy~nNext~nReturn value~nEnd Function~nGlobal probedEachIn:Int = ProbeEachIn(1, New TLegacyValues)"
Local forEachProtocolBoundaryCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-eachin-protocol-boundaries.bmx", forEachProtocolBoundarySource, Null, compilerOptions)
Local forEachProtocolBoundaryImplementation:String
For Local protocolBoundaryUnit:TCompilerGenericUnit = EachIn forEachProtocolBoundaryCompilation.genericPlan.units
	If protocolBoundaryUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeEachIn" Then forEachProtocolBoundaryImplementation = protocolBoundaryUnit.implementation
Next
Local forEachProtocolBoundaryImplementationLower:String = forEachProtocolBoundaryImplementation.ToLower()
Check(forEachProtocolBoundaryCompilation.Succeeded() And forEachProtocolBoundaryImplementationLower.Contains("bmx_direct_tlegacyvalues_") And forEachProtocolBoundaryImplementationLower.Contains("bmx_direct_tlegacyiterator_") And forEachProtocolBoundaryImplementationLower.Contains("->clas->vfns[0]") And forEachProtocolBoundaryImplementationLower.Contains("->clas->vfns[1]"), "generic ObjectEnumerator EachIn publishes stable ordinary receiver ABI records and protocol slots to the separate specialization unit: " + CompilationSummary(forEachProtocolBoundaryCompilation))
Local forEachLegacyCastSource:String = "SuperStrict~nInterface ILegacyItem<T>~nEnd Interface~nType TLegacyIterator<T> Implements ILegacyItem<T>~nField value:Object~nMethod HasNext:Int()~nReturn False~nEnd Method~nMethod NextObject:Object()~nReturn value~nEnd Method~nEnd Type~nType TLegacyValues<T>~nField iterator:TLegacyIterator<T>~nMethod ObjectEnumerator:TLegacyIterator<T>()~nReturn iterator~nEnd Method~nEnd Type~nFunction ProbeLegacyType<T>:T(value:T, legacy:TLegacyValues<T>)~nFor Local item:TLegacyIterator<T> = EachIn legacy~nNext~nReturn value~nEnd Function~nFunction ProbeLegacyInterface<T>:T(value:T, legacy:TLegacyValues<T>)~nFor Local item:ILegacyItem<T> = EachIn legacy~nNext~nReturn value~nEnd Function~nGlobal legacyValues:TLegacyValues<Int> = New TLegacyValues<Int>~nGlobal probedLegacyType:Int = ProbeLegacyType(1, legacyValues)~nGlobal probedLegacyInterface:Int = ProbeLegacyInterface(1, legacyValues)"
Local forEachLegacyCastCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-eachin-object-casts.bmx", forEachLegacyCastSource, Null, compilerOptions)
Check(forEachLegacyCastCompilation.Succeeded(), "generic ObjectEnumerator EachIn closes canonical Type and Interface cast targets: " + CompilationSummary(forEachLegacyCastCompilation))
Local legacyTypeCastImplementation:String
Local legacyInterfaceCastImplementation:String
For Local legacyCastUnit:TCompilerGenericUnit = EachIn forEachLegacyCastCompilation.genericPlan.units
	If legacyCastUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeLegacyType" Then legacyTypeCastImplementation = legacyCastUnit.implementation
	If legacyCastUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeLegacyInterface" Then legacyInterfaceCastImplementation = legacyCastUnit.implementation
Next
Check(legacyTypeCastImplementation.Contains("bbObjectDowncast") And legacyTypeCastImplementation.Contains("(BBClass *)&bmx_gen_") And legacyTypeCastImplementation.Contains("struct bmx_gen_") And legacyTypeCastImplementation.Contains("== (BBOBJECT)&bbNullObject"), "generic ObjectEnumerator Type target emits a checked canonical class-descriptor cast before filtering")
Check(legacyInterfaceCastImplementation.Contains("bbInterfaceDowncast") And legacyInterfaceCastImplementation.Contains("(BBINTERFACE)&bmx_gen_") And legacyInterfaceCastImplementation.Contains("_ifc") And legacyInterfaceCastImplementation.Contains("== (BBOBJECT)&bbNullObject"), "generic ObjectEnumerator Interface target emits a checked canonical Interface-descriptor cast before filtering")
Local forEachLegacyOrdinaryCastSource:String = "SuperStrict~nType TOrdinaryItem~nEnd Type~nType TLegacyIterator<T>~nMethod HasNext:Int()~nReturn False~nEnd Method~nMethod NextObject:Object()~nReturn Null~nEnd Method~nEnd Type~nType TLegacyValues<T>~nField iterator:TLegacyIterator<T>~nMethod ObjectEnumerator:TLegacyIterator<T>()~nReturn iterator~nEnd Method~nEnd Type~nFunction ProbeOrdinaryLegacyCast<T>:T(value:T, legacy:TLegacyValues<T>)~nFor Local item:TOrdinaryItem = EachIn legacy~nNext~nReturn value~nEnd Function~nGlobal legacyValues:TLegacyValues<Int> = New TLegacyValues<Int>~nGlobal probedOrdinaryLegacyCast:Int = ProbeOrdinaryLegacyCast(1, legacyValues)"
Local forEachLegacyOrdinaryCastCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-eachin-ordinary-object-cast.bmx", forEachLegacyOrdinaryCastSource, Null, compilerOptions)
Local forEachLegacyOrdinaryCastImplementation:String
For Local ordinaryCastUnit:TCompilerGenericUnit = EachIn forEachLegacyOrdinaryCastCompilation.genericPlan.units
	If ordinaryCastUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeOrdinaryLegacyCast" Then forEachLegacyOrdinaryCastImplementation = ordinaryCastUnit.implementation
Next
Check(forEachLegacyOrdinaryCastCompilation.Succeeded() And forEachLegacyOrdinaryCastImplementation.Contains("bbObjectDowncast") And forEachLegacyOrdinaryCastImplementation.Contains("(BBClass *)&bmx_direct_tordinaryitem_"), "generic ObjectEnumerator EachIn uses the stable application-local ordinary Type cast identity: " + CompilationSummary(forEachLegacyOrdinaryCastCompilation))
Local defaultedProtocolSource:String = "SuperStrict~nType TDefaultIterator<T>~nField value:Object~nMethod HasNext:Int(step:Int=1)~nReturn False~nEnd Method~nMethod NextObject:Object(index:Int=0)~nReturn value~nEnd Method~nEnd Type~nType TDefaultValues<T>~nField iterator:TDefaultIterator<T>~nMethod ObjectEnumerator:TDefaultIterator<T>(seed:Int=0)~nReturn iterator~nEnd Method~nEnd Type~nFunction ProbeDefaultString<T>:T(value:T, values:TDefaultValues<T>)~nFor Local item:String = EachIn values~nNext~nReturn value~nEnd Function~nFunction ProbeDefaultNumeric<T>:T(value:T, values:TDefaultValues<T>)~nFor Local item:Int = EachIn values~nNext~nReturn value~nEnd Function~nGlobal defaultValues:TDefaultValues<String> = New TDefaultValues<String>~nGlobal defaultString:String = ProbeDefaultString<String>(~qdefault~q, defaultValues)~nGlobal defaultNumeric:String = ProbeDefaultNumeric<String>(~qdefault~q, defaultValues)"
Local defaultedProtocolCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-defaulted-protocol.bmx", defaultedProtocolSource, Null, compilerOptions)
Check(defaultedProtocolCompilation.Succeeded(), "generic ObjectEnumerator protocol methods may satisfy every omitted argument from canonical defaults: " + CompilationSummary(defaultedProtocolCompilation))
Local defaultedProtocolImplementation:String
For Local defaultedProtocolUnit:TCompilerGenericUnit = EachIn defaultedProtocolCompilation.genericPlan.units
	defaultedProtocolImplementation :+ defaultedProtocolUnit.implementation
Next
Check(defaultedProtocolImplementation.Contains("m_objectenumerator_") And defaultedProtocolImplementation.Contains("m_hasnext_") And defaultedProtocolImplementation.Contains("m_nextobject_") And defaultedProtocolImplementation.Contains(", 0)") And defaultedProtocolImplementation.Contains(", 1)"), "defaulted ObjectEnumerator factory, advance, and current calls emit their retained constant arguments")
Check(defaultedProtocolImplementation.Contains("bbObjectIsString") And defaultedProtocolImplementation.Contains("bbObjectStringcast") And defaultedProtocolImplementation.Contains("bbObjectToFieldOffset"), "legacy ObjectEnumerator adapts Object elements to String and numeric targets with the production filter/unbox contracts")
Local transitiveRoutineSource:String = "SuperStrict~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nFunction Forward<T>:T(value:T)~nReturn Identity(value)~nEnd Function~nGlobal forwarded1:String = Forward(~qfirst~q)~nGlobal forwarded2:String = Forward<String>(~qsecond~q)"
Local transitiveRoutineCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-transitive-routine.bmx", transitiveRoutineSource, Null, compilerOptions)
Check(transitiveRoutineCompilation.Succeeded() And transitiveRoutineCompilation.genericPlan.registry.nodes.length = 2 And transitiveRoutineCompilation.genericPlan.units.length = 2, "generic routine body requests one canonical transitive callee specialization: " + CompilationSummary(transitiveRoutineCompilation))
Local forwardRoutineNode:TGenericSpecializationNode
Local identityRoutineNode:TGenericSpecializationNode
Local forwardRoutineUnit:TCompilerGenericUnit
For Local transitiveRoutineNode:TGenericSpecializationNode = EachIn transitiveRoutineCompilation.genericPlan.registry.nodes
	If transitiveRoutineNode.artifact.identity.qualifiedName = "Forward" Then forwardRoutineNode = transitiveRoutineNode
	If transitiveRoutineNode.artifact.identity.qualifiedName = "Identity" Then identityRoutineNode = transitiveRoutineNode
Next
For Local transitiveRoutineUnit:TCompilerGenericUnit = EachIn transitiveRoutineCompilation.genericPlan.units
	If transitiveRoutineUnit.specialization = forwardRoutineNode Then forwardRoutineUnit = transitiveRoutineUnit
Next
Check(forwardRoutineNode And identityRoutineNode And forwardRoutineNode.outgoing.length = 1 And forwardRoutineNode.outgoing[0].target = identityRoutineNode, "transitive generic routine request is an explicit caller-to-callee graph edge")
Check(forwardRoutineUnit And forwardRoutineUnit.implementation.Contains(identityRoutineNode.readableAbiName + "(value)") And forwardRoutineUnit.implementation.Contains("BBSTRING " + identityRoutineNode.readableAbiName + "(BBSTRING value);"), "caller unit declares and directly invokes the separately owned canonical callee ABI")
Local recursiveRoutineSource:String = "SuperStrict~nFunction Recursive<T>:T(value:T)~nReturn Recursive(value)~nEnd Function~nGlobal recursiveValue:String = Recursive(~qcycle~q)"
Local recursiveRoutineCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-recursive-routine.bmx", recursiveRoutineSource, Null, compilerOptions)
Check(recursiveRoutineCompilation.Succeeded() And recursiveRoutineCompilation.genericPlan.registry.nodes[0].referenceScc.length, "recursive generic routine specialization is retained as an explicit reference-safe SCC: " + CompilationSummary(recursiveRoutineCompilation))
Local overloadedRoutineSource:String = "SuperStrict~nFunction SelectValue<T>:T(value:T)~nReturn value~nEnd Function~nFunction SelectValue<T>:T(value:T, fallback:T)~nReturn value~nEnd Function~nGlobal selectedValue:String = SelectValue(~qselected~q)"
Local overloadedRoutineCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-overloaded-routine.bmx", overloadedRoutineSource, Null, compilerOptions)
Check(overloadedRoutineCompilation.Succeeded() And overloadedRoutineCompilation.genericPlan.registry.nodes.length = 1 And overloadedRoutineCompilation.genericPlan.templateOutputs.length = 2, "overloaded generic routines select and specialize one signature-qualified template: " + CompilationSummary(overloadedRoutineCompilation))
Check(overloadedRoutineCompilation.genericPlan.templateOutputs[0].artifact.identity.StableName() <> overloadedRoutineCompilation.genericPlan.templateOutputs[1].artifact.identity.StableName(), "overloaded generic routine templates have distinct open-signature identities")
Local overloadedRoutineModuleSource:String = "SuperStrict~nModule Collections.OverloadedRoutines~nFunction SelectValue<T>:T(value:T)~nReturn value~nEnd Function~nFunction SelectValue<T>:T(value:T, fallback:T)~nReturn fallback~nEnd Function"
Local overloadedRoutineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/overloadedroutines.mod/overloadedroutines.bmx", overloadedRoutineModuleSource, Null, compilerOptions)
Local overloadedRoutineModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local overloadedRoutineModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(overloadedRoutineModuleCompilation, overloadedRoutineModuleArtifactDiagnostics)
Local overloadedRoutineModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local overloadedRoutineModuleInterface:String = TBlitzMaxCompiler.EmitInterface(overloadedRoutineModuleCompilation, overloadedRoutineModuleInterfaceDiagnostics)
Check(overloadedRoutineModuleCompilation.Succeeded() And overloadedRoutineModuleOutputs.length = 2 And overloadedRoutineModuleArtifactDiagnostics.length = 0 And overloadedRoutineModuleInterfaceDiagnostics.length = 0, "module publishes both signature-qualified overload artifacts")
Local overloadedRoutineModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
overloadedRoutineModuleResolver.AddInterface("collections.overloadedroutines", "sdk/collections.overloadedroutines.i", overloadedRoutineModuleInterface)
For Local overloadedRoutineModuleOutput:TCompilerGenericTemplateOutput = EachIn overloadedRoutineModuleOutputs
	overloadedRoutineModuleResolver.AddGenericTemplate(overloadedRoutineModuleOutput.artifactReference, "sdk/" + overloadedRoutineModuleOutput.artifactReference, overloadedRoutineModuleOutput.content)
Next
Local overloadedRoutineConsumerSource:String = "SuperStrict~nImport Collections.OverloadedRoutines~nGlobal selectedOverload1:String = SelectValue(~qone~q)~nGlobal selectedOverload2:String = SelectValue(~qfirst~q, ~qsecond~q)"
Local overloadedRoutineConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-overloaded-routine-consumer.bmx", overloadedRoutineConsumerSource, overloadedRoutineModuleResolver, compilerOptions)
Check(overloadedRoutineConsumerCompilation.Succeeded() And overloadedRoutineConsumerCompilation.genericPlan.registry.nodes.length = 2 And overloadedRoutineConsumerCompilation.genericPlan.units.length = 2, "cross-module overload calls select two distinct source-free canonical specializations: " + CompilationSummary(overloadedRoutineConsumerCompilation))
Local genericMethodSource:String = "SuperStrict~nType TMethodBox<T>~nField value:T~nMethod Select<U>:T(input:U)~nReturn value~nEnd Method~nEnd Type~nGlobal methodBox:TMethodBox<String> = New TMethodBox<String>~nGlobal selectedMethodValue:String = methodBox.Select(7)"
Local genericMethodCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-method-owned-parameters.bmx", genericMethodSource, Null, compilerOptions)
Check(genericMethodCompilation.Succeeded() And genericMethodCompilation.genericPlan.registry.nodes.length = 2 And genericMethodCompilation.genericPlan.units.length = 2, "generic method keeps containing-Type and method-owned substitutions in separate canonical specializations: " + CompilationSummary(genericMethodCompilation))
Local genericMethodNode:TGenericSpecializationNode
Local genericMethodUnit:TCompilerGenericUnit
For Local methodOwnedNode:TGenericSpecializationNode = EachIn genericMethodCompilation.genericPlan.registry.nodes
	If methodOwnedNode.artifact.isMethod Then genericMethodNode = methodOwnedNode
Next
For Local methodOwnedUnit:TCompilerGenericUnit = EachIn genericMethodCompilation.genericPlan.units
	If methodOwnedUnit.specialization = genericMethodNode Then genericMethodUnit = methodOwnedUnit
Next
Check(genericMethodNode And genericMethodNode.key.containingTypeArguments.length = 1 And genericMethodNode.key.containingTypeArguments[0].CanonicalName() = "string" And genericMethodNode.key.typeArguments.length = 1 And genericMethodNode.key.typeArguments[0].CanonicalName() = "int", "generic method manifest identity distinguishes containing String from method Int")
Check(genericMethodUnit And genericMethodUnit.declarations.Contains(" self, BBINT input)") And genericMethodUnit.implementation.Contains("return self->"), "generic method emits a direct separate-unit implementation with independent containing-Type return/field and method-parameter substitutions")
Local genericMethodCollisionSource:String = "SuperStrict~nType TMethodCollisionBox<T>~nField value:T~nMethod Select<U>:T(input:U)~nReturn value~nEnd Method~nEnd Type~nGlobal stringMethodBox:TMethodCollisionBox<String> = New TMethodCollisionBox<String>~nGlobal intMethodBox:TMethodCollisionBox<Int> = New TMethodCollisionBox<Int>~nGlobal selectedString1:String = stringMethodBox.Select(1)~nGlobal selectedString2:String = stringMethodBox.Select(2)~nGlobal selectedInt:Int = intMethodBox.Select(3)"
Local genericMethodCollisionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-method-owner-collisions.bmx", genericMethodCollisionSource, Null, compilerOptions)
Local genericMethodSpecializationCount:Int
Local genericMethodSpecializationNames:TMap = New TMap
For Local collisionNode:TGenericSpecializationNode = EachIn genericMethodCollisionCompilation.genericPlan.registry.nodes
	If Not collisionNode.artifact.isMethod Then Continue
	genericMethodSpecializationCount :+ 1
	genericMethodSpecializationNames.Insert(collisionNode.key.CanonicalName(), collisionNode)
Next
Check(genericMethodCollisionCompilation.Succeeded() And genericMethodCollisionCompilation.genericPlan.registry.nodes.length = 4 And genericMethodSpecializationCount = 2, "identical method requests deduplicate while different containing-Type arguments retain collision-free identities: " + CompilationSummary(genericMethodCollisionCompilation))
Local genericMethodModuleSource:String = "SuperStrict~nModule Collections.GenericMethods~nType TMethodBox<T>~nField value:T~nMethod Select<U>:T(input:U)~nReturn value~nEnd Method~nEnd Type"
Local genericMethodModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/genericmethods.mod/genericmethods.bmx", genericMethodModuleSource, Null, compilerOptions)
Local genericMethodModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local genericMethodModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(genericMethodModuleCompilation, genericMethodModuleArtifactDiagnostics)
Local genericMethodModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local genericMethodModuleInterface:String = TBlitzMaxCompiler.EmitInterface(genericMethodModuleCompilation, genericMethodModuleInterfaceDiagnostics)
Check(genericMethodModuleCompilation.Succeeded() And genericMethodModuleOutputs.length = 2 And genericMethodModuleArtifactDiagnostics.length = 0 And genericMethodModuleInterfaceDiagnostics.length = 0, "module publishes source-free containing-Type and generic-method artifacts: " + CompilationSummary(genericMethodModuleCompilation))
Check(genericMethodModuleInterface.Contains("-Select<U>") And genericMethodModuleInterface.Contains("'@generic-template " + GENERIC_TEMPLATE_FORMAT_VERSION + ",") And Not genericMethodModuleInterface.Contains("Return input"), "compact generic Type record carries a generic method signature and artifact reference without source")
Local genericMethodModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
genericMethodModuleResolver.AddInterface("collections.genericmethods", "sdk/collections.genericmethods.i", genericMethodModuleInterface)
For Local genericMethodModuleOutput:TCompilerGenericTemplateOutput = EachIn genericMethodModuleOutputs
	genericMethodModuleResolver.AddGenericTemplate(genericMethodModuleOutput.artifactReference, "sdk/" + genericMethodModuleOutput.artifactReference, genericMethodModuleOutput.content)
Next
Local genericMethodConsumerSource:String = "SuperStrict~nImport Collections.GenericMethods~nGlobal importedMethodBox:TMethodBox<String> = New TMethodBox<String>~nGlobal importedSelectedMethod:String = importedMethodBox.Select(9)"
Local genericMethodConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-method-consumer.bmx", genericMethodConsumerSource, genericMethodModuleResolver, compilerOptions)
Check(genericMethodConsumerCompilation.Succeeded() And genericMethodConsumerCompilation.genericPlan.registry.nodes.length = 2 And genericMethodConsumerCompilation.genericPlan.units.length = 2, "cross-module generic method specializes from compact signature and source-free artifacts: " + CompilationSummary(genericMethodConsumerCompilation))
Local genericFactoryModuleSource:String = "SuperStrict~nModule Collections.GenericFactory~nType TFactory<T>~nField value:T~nFunction Create:TFactory<T>(value:T)~nLocal result:TFactory<T> = New TFactory<T>~nresult.value = value~nReturn result~nEnd Function~nFunction Identity:T(value:T)~nReturn value~nEnd Function~nEnd Type"
Local genericFactoryModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/genericfactory.mod/genericfactory.bmx", genericFactoryModuleSource, Null, compilerOptions)
Local genericFactoryArtifactDiagnostics:TCompilerDiagnostic[]
Local genericFactoryOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(genericFactoryModuleCompilation, genericFactoryArtifactDiagnostics)
Local genericFactoryInterfaceDiagnostics:TCompilerDiagnostic[]
Local genericFactoryInterface:String = TBlitzMaxCompiler.EmitInterface(genericFactoryModuleCompilation, genericFactoryInterfaceDiagnostics)
Check(genericFactoryModuleCompilation.Succeeded() And genericFactoryOutputs.length = 1 And genericFactoryArtifactDiagnostics.length = 0 And genericFactoryInterfaceDiagnostics.length = 0 And genericFactoryInterface.Contains("+Create:TFactory<T>") And genericFactoryInterface.Contains("+Identity:T"), "compact generic Type records publish Type Functions with their static lookup identity")
Local genericFactoryResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
genericFactoryResolver.AddInterface("collections.genericfactory", "sdk/collections.genericfactory.i", genericFactoryInterface)
For Local genericFactoryOutput:TCompilerGenericTemplateOutput = EachIn genericFactoryOutputs
	genericFactoryResolver.AddGenericTemplate(genericFactoryOutput.artifactReference, "sdk/" + genericFactoryOutput.artifactReference, genericFactoryOutput.content)
Next
Local genericFactoryConsumerSource:String = "SuperStrict~nImport Collections.GenericFactory~nGlobal tfactory:TFactory<Int> = TFactory<Int>.Create(7)~nGlobal secondFactory:TFactory<Int> = TFactory<Int>.Create(9)~nGlobal receiver:TFactory<Int> = New TFactory<Int>~nGlobal dynamicFactory:TFactory<Int> = receiver.Create(8)~nGlobal identity:Int(value:Int) = TFactory<Int>.Identity~nGlobal identityValue:Int = identity(42)"
Local genericFactoryConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-factory-consumer.bmx", genericFactoryConsumerSource, genericFactoryResolver, compilerOptions)
Local genericFactoryImplementation:String
If genericFactoryConsumer.genericPlan And genericFactoryConsumer.genericPlan.units.length Then genericFactoryImplementation = genericFactoryConsumer.genericPlan.units[0].implementation
Local genericFactoryRuntimeDiagnostics:TCompilerDiagnostic[]
Local genericFactoryRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(genericFactoryConsumer, genericFactoryRuntimeDiagnostics)
Check(genericFactoryConsumer.Succeeded() And genericFactoryRuntimeDiagnostics.length = 0 And genericFactoryConsumer.genericPlan.units.length = 1 And genericFactoryImplementation.Contains("_Create(BBINT value)") And genericFactoryImplementation.Contains("_Identity(BBINT value)") And Not genericFactoryImplementation.Contains("_Create(struct ") And genericFactoryRuntimeC.Contains("->clas->m_create_") And genericFactoryRuntimeC.Contains("_Identity"), "imported generic Type Functions remain resolvable as calls and closed callable references with a receiver-free ABI while object-qualified calls retain class-slot dispatch: " + CompilationSummary(genericFactoryConsumer))
Local genericTypeFunctionModuleSource:String = "SuperStrict~nModule Collections.GenericTypeFunctions~nType TFunctions~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nEnd Type~nFunction ApplyIdentity<T>:T(value:T)~nLocal callback:T(value:T) = TFunctions.Identity<T>~nReturn callback(value)~nEnd Function"
Local genericTypeFunctionModule:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/generictypefunctions.mod/generictypefunctions.bmx", genericTypeFunctionModuleSource, Null, compilerOptions)
Local genericTypeFunctionArtifactDiagnostics:TCompilerDiagnostic[]
Local genericTypeFunctionOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(genericTypeFunctionModule, genericTypeFunctionArtifactDiagnostics)
Local genericTypeFunctionInterfaceDiagnostics:TCompilerDiagnostic[]
Local genericTypeFunctionInterface:String = TBlitzMaxCompiler.EmitInterface(genericTypeFunctionModule, genericTypeFunctionInterfaceDiagnostics)
Check(genericTypeFunctionModule.Succeeded() And genericTypeFunctionOutputs.length = 2 And genericTypeFunctionArtifactDiagnostics.length = 0 And genericTypeFunctionInterfaceDiagnostics.length = 0 And genericTypeFunctionInterface.Contains("+Identity<T>:T(value:T)") And Not genericTypeFunctionInterface.Contains("~nIdentity<T>:T(value:T)"), "independently generic Type Functions are published inside their owner Type rather than as unqualified global routines: " + CompilationSummary(genericTypeFunctionModule))
Local genericTypeFunctionResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
genericTypeFunctionResolver.AddInterface("collections.generictypefunctions", "sdk/collections.generictypefunctions.i", genericTypeFunctionInterface)
For Local genericTypeFunctionOutput:TCompilerGenericTemplateOutput = EachIn genericTypeFunctionOutputs
	genericTypeFunctionResolver.AddGenericTemplate(genericTypeFunctionOutput.artifactReference, "sdk/" + genericTypeFunctionOutput.artifactReference, genericTypeFunctionOutput.content)
Next
Local genericTypeFunctionConsumerSource:String = "SuperStrict~nImport Collections.GenericTypeFunctions~nGlobal direct:Int(value:Int) = TFunctions.Identity<Int>~nGlobal directValue:Int = direct(41)~nGlobal transitiveValue:Double = ApplyIdentity<Double>(41.5)"
Local genericTypeFunctionConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-type-function-consumer.bmx", genericTypeFunctionConsumerSource, genericTypeFunctionResolver, compilerOptions)
Check(genericTypeFunctionConsumer.Succeeded() And genericTypeFunctionConsumer.genericPlan.registry.nodes.length = 3 And genericTypeFunctionConsumer.genericPlan.units.length = 3, "imported generic Type Function references remain indexed for direct and transitive specialization: " + CompilationSummary(genericTypeFunctionConsumer))
Local sequenceOptionalModuleSource:String = "SuperStrict~nModule BRL.Optional~nStruct Optional<T>~nField value:T~nFunction FromValue:Optional<T>(value:T)~nLocal result:Optional<T>~nresult.value=value~nReturn result~nEnd Function~nEnd Struct"
Local sequenceOptionalModule:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/brl.mod/optional.mod/optional.bmx", sequenceOptionalModuleSource, Null, compilerOptions)
Local sequenceOptionalArtifactDiagnostics:TCompilerDiagnostic[]
Local sequenceOptionalOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(sequenceOptionalModule, sequenceOptionalArtifactDiagnostics)
Local sequenceOptionalInterfaceDiagnostics:TCompilerDiagnostic[]
Local sequenceOptionalInterface:String = TBlitzMaxCompiler.EmitInterface(sequenceOptionalModule, sequenceOptionalInterfaceDiagnostics)
Local sequenceModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
sequenceModuleResolver.AddInterface("brl.optional", "sdk/brl.optional.i", sequenceOptionalInterface)
For Local sequenceOptionalOutput:TCompilerGenericTemplateOutput = EachIn sequenceOptionalOutputs
	sequenceModuleResolver.AddGenericTemplate(sequenceOptionalOutput.artifactReference, "sdk/" + sequenceOptionalOutput.artifactReference, sequenceOptionalOutput.content)
Next
Local sequenceFusionModuleSource:String = "SuperStrict~nModule BRL.Sequence~nImport BRL.Optional~nType Sequence<T>~nMethod New()~nEnd Method~nMethod New(values:T[])~nEnd Method~nFunction FromArray:Sequence<T>(values:T[])~nReturn New Sequence<T>(values)~nEnd Function~nMethod Filter:Sequence<T>(predicate:Closure<Int(value:T)>)~nReturn Self~nEnd Method~nMethod Filter:Sequence<T>(predicate:Int(value:T))~nReturn Self~nEnd Method~nMethod Map<U>:Sequence<U>(mapper:Closure<U(value:T)>)~nReturn New Sequence<U>~nEnd Method~nMethod Map<U>:Sequence<U>(mapper:U(value:T))~nReturn New Sequence<U>~nEnd Method~nMethod Take:Sequence<T>(count:Int)~nReturn Self~nEnd Method~nMethod Skip:Sequence<T>(count:Int)~nReturn Self~nEnd Method~nMethod Fold<U>:U(seed:U, folder:Closure<U(total:U,value:T)>)~nReturn seed~nEnd Method~nMethod Fold<U>:U(seed:U, folder:U(total:U,value:T))~nReturn seed~nEnd Method~nMethod Count:Int()~nReturn 0~nEnd Method~nMethod Count:Int(predicate:Closure<Int(value:T)>)~nReturn 0~nEnd Method~nMethod Count:Int(predicate:Int(value:T))~nReturn 0~nEnd Method~nMethod Any:Int()~nReturn False~nEnd Method~nMethod Any:Int(predicate:Closure<Int(value:T)>)~nReturn False~nEnd Method~nMethod Any:Int(predicate:Int(value:T))~nReturn False~nEnd Method~nMethod All:Int(predicate:Closure<Int(value:T)>)~nReturn True~nEnd Method~nMethod All:Int(predicate:Int(value:T))~nReturn True~nEnd Method~nMethod FirstOrNone:Optional<T>()~nLocal result:Optional<T>~nReturn result~nEnd Method~nMethod FirstOrNone:Optional<T>(predicate:Closure<Int(value:T)>)~nLocal result:Optional<T>~nReturn result~nEnd Method~nMethod FirstOrNone:Optional<T>(predicate:Int(value:T))~nLocal result:Optional<T>~nReturn result~nEnd Method~nMethod LastOrNone:Optional<T>()~nLocal result:Optional<T>~nReturn result~nEnd Method~nMethod ForEach(action:Closure<(value:T)>)~nEnd Method~nMethod ForEach(action:Void(value:T))~nEnd Method~nMethod ToArray:T[]()~nReturn New T[0]~nEnd Method~nEnd Type"
Local sequenceFusionModule:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/brl.mod/sequence.mod/sequence.bmx", sequenceFusionModuleSource, sequenceModuleResolver, compilerOptions)
Local sequenceFusionArtifactDiagnostics:TCompilerDiagnostic[]
Local sequenceFusionOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(sequenceFusionModule, sequenceFusionArtifactDiagnostics)
Local sequenceFusionInterfaceDiagnostics:TCompilerDiagnostic[]
Local sequenceFusionInterface:String = TBlitzMaxCompiler.EmitInterface(sequenceFusionModule, sequenceFusionInterfaceDiagnostics)
Check(sequenceFusionModule.Succeeded() And sequenceFusionOutputs.length >= 3 And sequenceFusionArtifactDiagnostics.length = 0 And sequenceFusionInterfaceDiagnostics.length = 0, "BRL.Sequence fusion fixture publishes its generic Type and generic terminal artifacts: " + CompilationSummary(sequenceFusionModule))
Local sequenceFusionResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
sequenceFusionResolver.AddInterface("brl.optional", "sdk/brl.optional.i", sequenceOptionalInterface)
For Local sequenceOptionalOutput:TCompilerGenericTemplateOutput = EachIn sequenceOptionalOutputs
	sequenceFusionResolver.AddGenericTemplate(sequenceOptionalOutput.artifactReference, "sdk/" + sequenceOptionalOutput.artifactReference, sequenceOptionalOutput.content)
Next
sequenceFusionResolver.AddInterface("brl.sequence", "sdk/brl.sequence.i", sequenceFusionInterface)
For Local sequenceFusionOutput:TCompilerGenericTemplateOutput = EachIn sequenceFusionOutputs
	sequenceFusionResolver.AddGenericTemplate(sequenceFusionOutput.artifactReference, "sdk/" + sequenceFusionOutput.artifactReference, sequenceFusionOutput.content)
Next
Local sequenceFusionConsumerSource:String = "SuperStrict~nImport BRL.Sequence~nGlobal visited:Int~nGlobal even:Closure<Int(value:Int)> = Function:Int(value:Int)~nReturn (value & 1) = 0~nEnd Function~nGlobal triple:Closure<Int(value:Int)> = Function:Int(value:Int)~nReturn value * 3~nEnd Function~nGlobal add:Closure<Int(total:Int,value:Int)> = Function:Int(total:Int,value:Int)~nReturn total + value~nEnd Function~nFunction SequenceDirectEven:Int(value:Int)~nReturn (value & 1) = 0~nEnd Function~nFunction SequenceDirectTriple:Int(value:Int)~nReturn value * 3~nEnd Function~nFunction SequenceDirectAdd:Int(total:Int,value:Int)~nReturn total + value~nEnd Function~nFunction SequenceVisit(value:Int)~nvisited:+value~nEnd Function~nGlobal values:Int[] = [1,2,3,4]~nGlobal fusedValue:Int = Sequence<Int>.FromArray(values).Filter(even).Map<Int>(triple).Take(2).Fold<Int>(0, add)~nGlobal directValue:Int = Sequence<Int>.FromArray(values).Filter(SequenceDirectEven).Map<Int>(SequenceDirectTriple).Take(2).Fold<Int>(0, SequenceDirectAdd)~nGlobal predicateCount:Int = Sequence<Int>.FromArray(values).Count(SequenceDirectEven)~nGlobal first:Optional<Int> = Sequence<Int>.FromArray(values).Filter(SequenceDirectEven).Skip(1).FirstOrNone()~nGlobal predicateFirst:Optional<Int> = Sequence<Int>.FromArray(values).FirstOrNone(SequenceDirectEven)~nGlobal last:Optional<Int> = Sequence<Int>.FromArray(values).Map<Int>(SequenceDirectTriple).LastOrNone()~nSequence<Int>.FromArray(values).Filter(SequenceDirectEven).Take(1).ForEach(SequenceVisit)~nGlobal materialized:Int[] = Sequence<Int>.FromArray(values).Filter(SequenceDirectEven).Skip(1).ToArray()~nGlobal query:Sequence<Int> = Sequence<Int>.FromArray(values).Filter(even)~nGlobal fallbackCount:Int = query.Count()"
Local sequenceFusionConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("sequence-fusion-consumer.bmx", sequenceFusionConsumerSource, sequenceFusionResolver, compilerOptions)
Check(sequenceFusionConsumer.Succeeded() And sequenceFusionConsumer.ir, "sequence fusion consumer compiles before IR inspection: " + CompilationSummary(sequenceFusionConsumer))
Local sequenceFusionHelper:TCompilerIrFunction
Local sequenceDirectFusionHelper:TCompilerIrFunction
Local sequenceFirstFusionHelper:TCompilerIrFunction
Local sequenceForEachFusionHelper:TCompilerIrFunction
Local sequenceToArrayFusionHelper:TCompilerIrFunction
Local sequenceFusionHelperCount:Int
Local sequenceOptionalFusionHelperCount:Int
For Local sequenceFusionFunction:TCompilerIrFunction = EachIn sequenceFusionConsumer.ir.functions
	If Not sequenceFusionFunction.name.StartsWith("$sequence_fused_") Then Continue
	sequenceFusionHelperCount :+ 1
	If Not sequenceFusionHelper Then
		sequenceFusionHelper = sequenceFusionFunction
	Else If Not sequenceDirectFusionHelper Then
		sequenceDirectFusionHelper = sequenceFusionFunction
	Else If sequenceFusionFunction.returnType.StartsWith("Optional<") Then
		sequenceOptionalFusionHelperCount :+ 1
		If Not sequenceFirstFusionHelper Then sequenceFirstFusionHelper = sequenceFusionFunction
	Else If sequenceFusionFunction.returnType = "Void" Then
		sequenceForEachFusionHelper = sequenceFusionFunction
	Else If sequenceFusionFunction.returnType = "Int[]" Then
		sequenceToArrayFusionHelper = sequenceFusionFunction
	End If
Next
Local sequenceFusionRuntimeDiagnostics:TCompilerDiagnostic[]
Local sequenceFusionRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(sequenceFusionConsumer, sequenceFusionRuntimeDiagnostics)
Check(sequenceFusionConsumer.Succeeded() And sequenceFusionRuntimeDiagnostics.length = 0 And sequenceFusionHelperCount = 8 And sequenceOptionalFusionHelperCount = 3 And sequenceFusionHelper And sequenceDirectFusionHelper And sequenceFirstFusionHelper And sequenceForEachFusionHelper And sequenceToArrayFusionHelper And sequenceFusionHelper.body And sequenceFusionHelper.body.statements.length, "direct imported BRL.Sequence terminals become typed internal fusion helpers: " + CompilationSummary(sequenceFusionConsumer))
Local sequenceFusionHasArrayLoop:Int
For Local sequenceFusionStatement:TCompilerIrStatement = EachIn sequenceFusionHelper.body.statements
	If TCompilerIrForEachArray(sequenceFusionStatement) Then sequenceFusionHasArrayLoop = True; Exit
Next
Check(sequenceFusionHasArrayLoop And sequenceFusionRuntimeC.Contains("_sequence_fused_") And sequenceFusionRuntimeC.Contains("Count"), "fusion lowers to ordinary array-loop IR while a pipeline hidden behind a variable retains the library fallback")
Local sequenceDirectCallCount:Int
For Local sequenceDirectStatement:TCompilerIrStatement = EachIn sequenceDirectFusionHelper.body.statements
	Local sequenceDirectLoop:TCompilerIrForEachArray = TCompilerIrForEachArray(sequenceDirectStatement)
	If Not sequenceDirectLoop Then Continue
	For Local sequenceDirectBodyStatement:TCompilerIrStatement = EachIn sequenceDirectLoop.body.statements
		Local sequenceDirectIf:TCompilerIrIf = TCompilerIrIf(sequenceDirectBodyStatement)
		If sequenceDirectIf Then
			Local sequenceDirectNot:TCompilerIrUnary = TCompilerIrUnary(sequenceDirectIf.condition)
			If sequenceDirectNot And TCompilerIrCall(sequenceDirectNot.operand) Then sequenceDirectCallCount :+ 1
		End If
		Local sequenceDirectVariable:TCompilerIrVariableDeclaration = TCompilerIrVariableDeclaration(sequenceDirectBodyStatement)
		If sequenceDirectVariable And TCompilerIrCall(sequenceDirectVariable.initializer) Then sequenceDirectCallCount :+ 1
		Local sequenceDirectAssignment:TCompilerIrAssignment = TCompilerIrAssignment(sequenceDirectBodyStatement)
		If sequenceDirectAssignment And TCompilerIrCall(sequenceDirectAssignment.value) Then sequenceDirectCallCount :+ 1
	Next
Next
Check(sequenceDirectCallCount = 3 And sequenceFusionRuntimeC.Contains("SequenceDirectEven") And sequenceFusionRuntimeC.Contains("SequenceDirectTriple") And sequenceFusionRuntimeC.Contains("SequenceDirectAdd"), "thin Sequence operators lower to direct calls while managed Closure operators retain their indirect ABI")
Check(sequenceFusionRuntimeC.Contains("Optional") And sequenceFusionRuntimeC.Contains("FromValue") And sequenceFusionRuntimeC.Contains("SequenceVisit") And sequenceFusionRuntimeC.Contains("bbArraySlice"), "predicate Count, FirstOrNone, LastOrNone, ForEach, and ToArray fusion retain typed calls and results")
Local directMethodModuleSource:String = "SuperStrict~nModule Collections.DirectMethods~nType TDirectOwner~nField value:String~nMethod Select<U>:String(input:U)~nReturn value~nEnd Method~nMethod Select<U>:U(input:U, fallback:U)~nReturn fallback~nEnd Method~nMethod Forward<U>:U(input:U)~nReturn Select(input, input)~nEnd Method~nEnd Type~nStruct SDirectOwner~nField value:Int~nMethod ReadAs<U>:Int(fallback:U)~nReturn value~nEnd Method~nEnd Struct"
Local directMethodModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/directmethods.mod/directmethods.bmx", directMethodModuleSource, Null, compilerOptions)
Local directMethodArtifactDiagnostics:TCompilerDiagnostic[]
Local directMethodOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(directMethodModuleCompilation, directMethodArtifactDiagnostics)
Local directMethodInterfaceDiagnostics:TCompilerDiagnostic[]
Local directMethodInterface:String = TBlitzMaxCompiler.EmitInterface(directMethodModuleCompilation, directMethodInterfaceDiagnostics)
Check(directMethodModuleCompilation.Succeeded() And directMethodOutputs.length = 4 And directMethodArtifactDiagnostics.length = 0 And directMethodInterfaceDiagnostics.length = 0, "ordinary Type and Struct owners publish all direct generic method artifacts: " + CompilationSummary(directMethodModuleCompilation))
Check(directMethodInterface.Contains("TDirectOwner^Object{") And directMethodInterface.Contains("-Select<U>") And directMethodInterface.Contains("SDirectOwner^Null{") And directMethodInterface.Contains("-ReadAs<U>") And Not directMethodInterface.Contains("Return value"), "ordinary owner compact records carry source-free generic method signatures and companion references")
Local directMethodResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
directMethodResolver.AddInterface("collections.directmethods", "sdk/collections.directmethods.i", directMethodInterface)
For Local directMethodOutput:TCompilerGenericTemplateOutput = EachIn directMethodOutputs
	directMethodResolver.AddGenericTemplate(directMethodOutput.artifactReference, "sdk/" + directMethodOutput.artifactReference, directMethodOutput.content)
Next
Local directMethodConsumerSource:String = "SuperStrict~nImport Collections.DirectMethods~nGlobal directOwner:TDirectOwner~nGlobal selectedDirect1:String = directOwner.Select(1)~nGlobal selectedDirect2:String = directOwner.Select(2)~nGlobal selectedDirectOverload:Int = directOwner.Select(3, 4)~nGlobal forwardedDirect:Int = directOwner.Forward(5)~nGlobal directStruct:SDirectOwner~nGlobal directStructValue:Int = directStruct.ReadAs(~qfallback~q)"
Local directMethodConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("direct-method-consumer.bmx", directMethodConsumerSource, directMethodResolver, compilerOptions)
Check(directMethodConsumerCompilation.Succeeded() And directMethodConsumerCompilation.genericPlan.registry.nodes.length = 4 And directMethodConsumerCompilation.genericPlan.units.length = 4, "source-free ordinary Type/Struct methods deduplicate repeated calls, separate overloads, and close transitive requests: " + CompilationSummary(directMethodConsumerCompilation))
Local directSelectCount:Int
Local directForwardNode:TGenericSpecializationNode
Local directStructUnit:TCompilerGenericUnit
For Local directMethodNode:TGenericSpecializationNode = EachIn directMethodConsumerCompilation.genericPlan.registry.nodes
	If directMethodNode.artifact.identity.qualifiedName.EndsWith(".Select") Then directSelectCount :+ 1
	If directMethodNode.artifact.identity.qualifiedName.EndsWith(".Forward") Then directForwardNode = directMethodNode
Next
For Local directMethodUnit:TCompilerGenericUnit = EachIn directMethodConsumerCompilation.genericPlan.units
	If directMethodUnit.ir.routine And directMethodUnit.ir.routine.receiverIsStruct Then directStructUnit = directMethodUnit
Next
Check(directSelectCount = 2 And directForwardNode And directForwardNode.outgoing.length = 1, "signature-qualified direct methods retain overload identity and method-to-method calls form an explicit request edge")
Check(directStructUnit And directStructUnit.declarations.Contains("struct collections_directmethods_SDirectOwner * self") And directStructUnit.implementation.Contains("self->_collections_directmethods_sdirectowner_value"), "ordinary Struct generic methods use the producer-compatible layout and explicit pointer receiver")
Local directRecursiveSource:String = "SuperStrict~nType TRecursiveDirect~nMethod Repeat<U>:U(value:U)~nReturn Repeat(value)~nEnd Method~nEnd Type~nGlobal recursiveDirect:TRecursiveDirect~nGlobal recursiveDirectValue:Int = recursiveDirect.Repeat(1)"
Local directRecursiveCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("recursive-direct-method.bmx", directRecursiveSource, Null, compilerOptions)
Check(directRecursiveCompilation.Succeeded() And directRecursiveCompilation.genericPlan.registry.nodes[0].referenceScc.length, "recursive direct generic method requests are retained as an explicit reference-safe SCC")
Local localDirectSource:String = "SuperStrict~nType TLocalDirectBase~nField baseValue:Int~nMethod Pick<U>:Int(value:U)~nReturn baseValue~nEnd Method~nEnd Type~nType TLocalDirectDerived Extends TLocalDirectBase~nField derivedValue:Int~nMethod Pick<U>:Int(value:U) Override~nReturn Super.Pick(value) + derivedValue~nEnd Method~nMethod Forward<U>:Int(value:U)~nReturn Self.Pick(value)~nEnd Method~nEnd Type~nStruct SLocalDirect~nField value:Int~nMethod Read<U>:Int(fallback:U)~nReturn value~nEnd Method~nEnd Struct~nGlobal localDirect:TLocalDirectDerived~nGlobal localDirectForward:Int = localDirect.Forward(1)~nGlobal localDirectBase:TLocalDirectBase = localDirect~nGlobal localDirectBasePick:Int = localDirectBase.Pick(2)~nGlobal localDirectStruct:SLocalDirect~nGlobal localDirectStructRead:Int = localDirectStruct.Read(~qfallback~q)"
Local localDirectCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("local-direct-methods.bmx", localDirectSource, Null, compilerOptions)
Local localDirectRepeatCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("local-direct-methods.bmx", localDirectSource, Null, compilerOptions)
Check(localDirectCompilation.Succeeded() And localDirectRepeatCompilation.Succeeded() And localDirectCompilation.genericPlan.registry.nodes.length = 4 And localDirectCompilation.genericPlan.units.length = 4, "source-local Type and Struct direct methods close Self, Super, and repeated base requests into four canonical units: " + CompilationSummary(localDirectCompilation))
Local localDirectBasePickUnit:TCompilerGenericUnit
Local localDirectDerivedPickUnit:TCompilerGenericUnit
Local localDirectForwardUnit:TCompilerGenericUnit
Local localDirectStructUnit:TCompilerGenericUnit
For Local localDirectUnit:TCompilerGenericUnit = EachIn localDirectCompilation.genericPlan.units
	If localDirectUnit.specialization.artifact.identity.qualifiedName.EndsWith("TLocalDirectBase.Pick") Then localDirectBasePickUnit = localDirectUnit
	If localDirectUnit.specialization.artifact.identity.qualifiedName.EndsWith("TLocalDirectDerived.Pick") Then localDirectDerivedPickUnit = localDirectUnit
	If localDirectUnit.specialization.artifact.identity.qualifiedName.EndsWith("TLocalDirectDerived.Forward") Then localDirectForwardUnit = localDirectUnit
	If localDirectUnit.specialization.artifact.identity.qualifiedName.EndsWith("SLocalDirect.Read") Then localDirectStructUnit = localDirectUnit
Next
Check(localDirectBasePickUnit And localDirectDerivedPickUnit And localDirectForwardUnit And localDirectStructUnit, "source-local direct method specializations retain distinct base, derived, forwarding, and Struct ownership")
Local localDirectBaseAbi:String = localDirectBasePickUnit.ir.routine.receiverType.runtimeAbiName
Local localDirectDerivedAbi:String = localDirectDerivedPickUnit.ir.routine.receiverType.runtimeAbiName
Local localDirectStructAbi:String = localDirectStructUnit.ir.routine.receiverType.runtimeAbiName
Check(localDirectBaseAbi.StartsWith("bmx_direct_") And localDirectDerivedAbi.StartsWith("bmx_direct_") And localDirectStructAbi.StartsWith("bmx_direct_") And localDirectBaseAbi <> localDirectDerivedAbi, "unpublished direct-method owners receive deterministic collision-resistant local ABI identities")
Check(localDirectDerivedPickUnit.implementation.Contains(localDirectBasePickUnit.specialization.readableAbiName + "(((struct " + localDirectBaseAbi + "_obj *)") And localDirectForwardUnit.implementation.Contains(localDirectDerivedPickUnit.specialization.readableAbiName + "(((struct " + localDirectDerivedAbi + "_obj *)") And Not localDirectForwardUnit.implementation.Contains("->clas->"), "generic Super and Self calls remain exact direct specialization edges with declaration-owner receiver casts")
Check(localDirectForwardUnit.implementation.Contains("struct " + localDirectBaseAbi + "_obj;"), "a forwarding direct-method unit declares the ordinary base receiver tag before repeated referenced-method prototypes")
Check(localDirectBasePickUnit.implementation.Contains("self->_" + localDirectBaseAbi + "_basevalue") And localDirectDerivedPickUnit.implementation.Contains("self->_" + localDirectDerivedAbi + "_derivedvalue") And localDirectStructUnit.implementation.Contains("self->_" + localDirectStructAbi + "_value"), "source-local separate units share deterministic field layout names with the application C unit")
Local localDirectRuntimeDiagnostics:TCompilerDiagnostic[]
Local localDirectRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(localDirectCompilation, localDirectRuntimeDiagnostics)
Local localDirectRepeatRuntimeDiagnostics:TCompilerDiagnostic[]
Local localDirectRepeatRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(localDirectRepeatCompilation, localDirectRepeatRuntimeDiagnostics)
Check(localDirectRuntimeDiagnostics.length = 0 And localDirectRepeatRuntimeDiagnostics.length = 0 And localDirectRuntimeC = localDirectRepeatRuntimeC And localDirectRuntimeC.Contains("struct " + localDirectBaseAbi + "_obj") And localDirectRuntimeC.Contains("struct " + localDirectStructAbi), "source-local owner layouts and application references are byte-deterministic across repeated compilation")
Local localDirectHeaderDiagnostics:TCompilerDiagnostic[]
Local localDirectHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(localDirectCompilation, localDirectHeaderDiagnostics)
Check(localDirectHeaderDiagnostics.length = 0 And AppearsBefore(localDirectHeader, "struct " + localDirectBaseAbi + "_obj;", localDirectBasePickUnit.specialization.readableAbiName + "("), "application headers declare stable local Type tags before application-owned generic method prototypes")
Local abstractDirectSource:String = "SuperStrict~nType TAbstractDirect Abstract~nMethod Pick<U>:U(value:U) Abstract~nEnd Type"
Local abstractDirectCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("abstract-direct-method.bmx", abstractDirectSource, Null, compilerOptions)
Check(abstractDirectCompilation.Succeeded(), "an unused abstract Type-owned generic method publishes a declaration-only source-free artifact: " + CompilationSummary(abstractDirectCompilation))
Local abstractDispatchSource:String = "SuperStrict~nType TAbstractGeneric Abstract~nMethod Pick<U>:U(value:U) Abstract~nEnd Type~nType TConcreteGeneric Extends TAbstractGeneric~nMethod Pick<U>:U(value:U)~nReturn value~nEnd Method~nEnd Type~nGlobal abstractGeneric:TAbstractGeneric = New TConcreteGeneric~nGlobal abstractPicked:String = abstractGeneric.Pick<String>(~qpicked~q)"
Local abstractDispatchCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("abstract-generic-dispatch.bmx", abstractDispatchSource, Null, compilerOptions)
Check(abstractDispatchCompilation.Succeeded() And abstractDispatchCompilation.genericPlan.registry.nodes.length = 2 And abstractDispatchCompilation.genericPlan.units[0].implementation.Contains("while (clas)"), "a closed abstract Type generic method dispatches to its application-visible concrete override: " + CompilationSummary(abstractDispatchCompilation))
Check(abstractDispatchCompilation.genericPlan.units[0].declarations.Contains("_dynamic_implementation") And abstractDispatchCompilation.genericPlan.units[0].declarations.Contains("_register_dynamic") And abstractDispatchCompilation.genericPlan.units[0].implementation.Contains("bbMemAlloc(sizeof(struct") And abstractDispatchCompilation.genericPlan.units[0].implementation.Contains("dynamic_implementation((BBOBJECT)self") And abstractDispatchCompilation.genericPlan.units[0].implementation.Contains("BB_LOCK") And abstractDispatchCompilation.genericPlan.units[0].implementation.Contains("BB_UNLOCK"), "abstract generic dispatch publishes a synchronized closed dynamic-registration ABI and consults registered overrides before its link-time closure")
Check(abstractDispatchCompilation.genericPlan.manifest.Contains("abstract-method-implementation"), "abstract Type-owned generic dispatch records a distinct canonical implementation edge in the specialization manifest")
Local interfaceDirectSource:String = "SuperStrict~nInterface IDirectGeneric~nMethod Pick<U>:U(value:U)~nEnd Interface~nType TDirectGenericOne Implements IDirectGeneric~nMethod Pick<U>:U(value:U)~nReturn value~nEnd Method~nEnd Type~nType TDirectGenericTwo Implements IDirectGeneric~nMethod Pick<U>:U(value:U)~nReturn value~nEnd Method~nEnd Type~nGlobal directGenericOne:IDirectGeneric = New TDirectGenericOne~nGlobal directGenericTwo:IDirectGeneric = New TDirectGenericTwo~nGlobal directGenericString:String = directGenericOne.Pick(~qone~q)~nGlobal directGenericInt:Int = directGenericTwo.Pick(2)"
Local interfaceDirectCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("interface-direct-method.bmx", interfaceDirectSource, Null, compilerOptions)
Check(interfaceDirectCompilation.Succeeded() And interfaceDirectCompilation.genericPlan.registry.nodes.length = 6, "Interface method-owned generics produce two canonical typed dispatchers and four closed concrete direct implementations: " + CompilationSummary(interfaceDirectCompilation))
Local interfaceDispatchCount:Int
Local interfaceImplementationCount:Int
For Local interfaceDirectNode:TGenericSpecializationNode = EachIn interfaceDirectCompilation.genericPlan.registry.nodes
	If interfaceDirectNode.artifact.typeDeclarationKind = GENERIC_TYPE_DECLARATION_INTERFACE Then
		interfaceDispatchCount :+ 1
		Check(interfaceDirectNode.outgoing.length = 2 And interfaceDirectNode.outgoing[0].request.reason = GENERIC_REQUEST_INTERFACE_METHOD_IMPLEMENTATION, "closed generic Interface dispatch retains explicit implementation ownership edges")
	Else If interfaceDirectNode.artifact.identity.declarationKind = GENERIC_DECLARATION_ROUTINE Then
		interfaceImplementationCount :+ 1
	End If
Next
Check(interfaceDispatchCount = 2 And interfaceImplementationCount = 4 And interfaceDirectCompilation.genericPlan.manifest.Contains("interface-method-implementation"), "String and Int Interface calls retain distinct dispatch identities and manifest edges while each concrete closed implementation is deduplicated")
Local interfaceDispatchUnitCount:Int
Local interfaceImplementationRegistrationCount:Int
For Local interfaceDirectUnit:TCompilerGenericUnit = EachIn interfaceDirectCompilation.genericPlan.units
	If interfaceDirectUnit.ir.dispatcherImplementations.length Then
		interfaceDispatchUnitCount :+ 1
		Check(interfaceDirectUnit.implementation.Contains("while (clas)") And interfaceDirectUnit.implementation.Contains("brl_blitz_NullMethodError") And interfaceDirectUnit.implementation.Contains("(BBClass *)&"), "typed generic Interface dispatcher walks runtime ancestry and fails explicitly when no implementation matches")
		Check(interfaceDirectUnit.declarations.Contains("_dynamic_implementation") And interfaceDirectUnit.declarations.Contains("_register_dynamic") And interfaceDirectUnit.implementation.Contains("dynamic_entry->owner == clas") And interfaceDirectUnit.implementation.Contains("entry->implementation = implementation") And interfaceDirectUnit.ir.Dump().Contains("dynamic-registration "), "each closed Interface dispatcher exports and records an idempotent dynamic implementor registration boundary")
	End If
	If interfaceDirectUnit.ir.dynamicDispatchers.length Then
		interfaceImplementationRegistrationCount :+ 1
		Check(interfaceDirectUnit.specialization.incoming.length = 1 And interfaceDirectUnit.implementation.Contains("_dynamic_adapter_") And interfaceDirectUnit.implementation.Contains("_register_implementation(void)") And interfaceDirectUnit.implementation.Contains("_register_dynamic((BBClass *)&") And interfaceDirectUnit.ir.Dump().Contains("dynamic-implementation "), "each concrete closed implementation owns a typed adapter and an explicit incoming dispatcher-registration edge")
	End If
Next
Check(interfaceDispatchUnitCount = 2, "each closed generic Interface signature owns one deterministic separate dispatch C unit")
Local interfaceDirectRuntimeDiagnostics:TCompilerDiagnostic[]
Local interfaceDirectRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(interfaceDirectCompilation, interfaceDirectRuntimeDiagnostics)
Local interfaceDirectIrDump:String = TCompilerIrDumper.Dump(interfaceDirectCompilation.ir)
Check(interfaceImplementationRegistrationCount = 4 And interfaceDirectRuntimeDiagnostics.length = 0 And interfaceDirectRuntimeC.Contains("extern void bmx_gen_") And interfaceDirectRuntimeC.Contains("_register_implementation(void);") And interfaceDirectRuntimeC.Contains("_register_implementation();") And interfaceDirectIrDump.Contains("register-generic-implementation "), "the ordinary source-unit registration plan invokes all specialization-owned dynamic implementation hooks")
Local interfaceMethodModuleSource:String = "SuperStrict~nModule Collections.GenericInterfaceMethods~nInterface IPublishedGenericMethod~nMethod Tag<T>:Int(value:T, delta:Int = 0)~nEnd Interface"
Local interfaceMethodModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/genericinterfacemethods.mod/genericinterfacemethods.bmx", interfaceMethodModuleSource, Null, compilerOptions)
Local interfaceMethodArtifactDiagnostics:TCompilerDiagnostic[]
Local interfaceMethodOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(interfaceMethodModuleCompilation, interfaceMethodArtifactDiagnostics)
Local interfaceMethodInterfaceDiagnostics:TCompilerDiagnostic[]
Local interfaceMethodInterface:String = TBlitzMaxCompiler.EmitInterface(interfaceMethodModuleCompilation, interfaceMethodInterfaceDiagnostics)
Check(interfaceMethodModuleCompilation.Succeeded() And interfaceMethodOutputs.length = 1 And interfaceMethodArtifactDiagnostics.length = 0 And interfaceMethodInterfaceDiagnostics.length = 0, "a body-free generic Interface method publishes one canonical source-free routine artifact: " + CompilationSummary(interfaceMethodModuleCompilation))
Check(interfaceMethodOutputs.length And Not interfaceMethodOutputs[0].content.Contains("Method Tag") And interfaceMethodOutputs[0].artifact.typeDeclarationKind = GENERIC_TYPE_DECLARATION_INTERFACE And Not interfaceMethodOutputs[0].artifact.members[0].body, "generic Interface method artifacts retain the bound signature and Interface ownership without copied BlitzMax source or a fabricated body")
Local interfaceMethodResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
interfaceMethodResolver.AddInterface("collections.genericinterfacemethods", "sdk/collections.genericinterfacemethods.i", interfaceMethodInterface)
If interfaceMethodOutputs.length Then interfaceMethodResolver.AddGenericTemplate(interfaceMethodOutputs[0].artifactReference, "sdk/" + interfaceMethodOutputs[0].artifactReference, interfaceMethodOutputs[0].content)
Local interfaceMethodConsumerSource:String = "SuperStrict~nImport Collections.GenericInterfaceMethods~nType TPublishedGenericMethod Implements IPublishedGenericMethod~nMethod Tag<T>:Int(value:T, delta:Int = 0)~nReturn 10 + delta~nEnd Method~nEnd Type~nGlobal publishedGenericMethod:IPublishedGenericMethod = New TPublishedGenericMethod~nGlobal publishedGenericMethodValue:Int = publishedGenericMethod.Tag(~qvalue~q, 2)"
Local interfaceMethodConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("published-generic-interface-method-consumer.bmx", interfaceMethodConsumerSource, interfaceMethodResolver, compilerOptions)
Check(interfaceMethodConsumerCompilation.Succeeded() And interfaceMethodConsumerCompilation.genericPlan.registry.nodes.length = 2 And interfaceMethodConsumerCompilation.genericPlan.units.length = 2, "an imported body-free generic Interface requirement closes against a source implementation without reparsing producer source: " + CompilationSummary(interfaceMethodConsumerCompilation))
Local importedInterfaceDispatcher:TGenericSpecializationNode
For Local interfaceMethodNode:TGenericSpecializationNode = EachIn interfaceMethodConsumerCompilation.genericPlan.registry.nodes
	If interfaceMethodNode.artifact.typeDeclarationKind = GENERIC_TYPE_DECLARATION_INTERFACE Then importedInterfaceDispatcher = interfaceMethodNode
Next
Check(importedInterfaceDispatcher And importedInterfaceDispatcher.artifact.identity.moduleName.ToLower() = "collections.genericinterfacemethods" And importedInterfaceDispatcher.outgoing.length = 1, "imported generic Interface dispatch preserves defining-module identity and one explicit concrete implementation edge")
Local importedInterfaceImplementationModuleSource:String = "SuperStrict~nModule Collections.ImportedGenericInterfaceImplementation~nInterface IImportedGenericMethod~nMethod Tag<T>:Int(value:T)~nEnd Interface~nType TImportedGenericMethod Implements IImportedGenericMethod~nMethod Tag<T>:Int(value:T)~nReturn 12~nEnd Method~nEnd Type"
Local importedInterfaceImplementationModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/importedgenericinterfaceimplementation.mod/importedgenericinterfaceimplementation.bmx", importedInterfaceImplementationModuleSource, Null, compilerOptions)
Local importedInterfaceImplementationArtifactDiagnostics:TCompilerDiagnostic[]
Local importedInterfaceImplementationOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(importedInterfaceImplementationModuleCompilation, importedInterfaceImplementationArtifactDiagnostics)
Local importedInterfaceImplementationInterfaceDiagnostics:TCompilerDiagnostic[]
Local importedInterfaceImplementationInterface:String = TBlitzMaxCompiler.EmitInterface(importedInterfaceImplementationModuleCompilation, importedInterfaceImplementationInterfaceDiagnostics)
Check(importedInterfaceImplementationModuleCompilation.Succeeded() And importedInterfaceImplementationOutputs.length = 2 And importedInterfaceImplementationArtifactDiagnostics.length = 0 And importedInterfaceImplementationInterfaceDiagnostics.length = 0, "a module publishes both sides of an imported generic Interface method dispatch without source blobs")
Local importedInterfaceImplementationResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
importedInterfaceImplementationResolver.AddInterface("collections.importedgenericinterfaceimplementation", "sdk/collections.importedgenericinterfaceimplementation.i", importedInterfaceImplementationInterface)
For Local importedInterfaceImplementationOutput:TCompilerGenericTemplateOutput = EachIn importedInterfaceImplementationOutputs
	importedInterfaceImplementationResolver.AddGenericTemplate(importedInterfaceImplementationOutput.artifactReference, "sdk/" + importedInterfaceImplementationOutput.artifactReference, importedInterfaceImplementationOutput.content)
Next
Local importedInterfaceImplementationConsumerSource:String = "SuperStrict~nImport Collections.ImportedGenericInterfaceImplementation~nGlobal importedGenericConcrete:TImportedGenericMethod = New TImportedGenericMethod~nGlobal importedGenericView:IImportedGenericMethod = importedGenericConcrete~nGlobal importedGenericValue:Int = importedGenericView.Tag(~qimported~q)"
Local importedInterfaceImplementationConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("imported-generic-interface-implementation-consumer.bmx", importedInterfaceImplementationConsumerSource, importedInterfaceImplementationResolver, compilerOptions)
Local importedInterfaceImplementationDispatcher:TCompilerGenericUnit
If importedInterfaceImplementationConsumerCompilation.genericPlan Then
	For Local importedImplementationUnit:TCompilerGenericUnit = EachIn importedInterfaceImplementationConsumerCompilation.genericPlan.units
		If importedImplementationUnit.ir.dispatcherImplementations.length Then importedInterfaceImplementationDispatcher = importedImplementationUnit
	Next
End If
Check(importedInterfaceImplementationConsumerCompilation.Succeeded() And importedInterfaceImplementationConsumerCompilation.genericPlan.registry.nodes.length = 2 And importedInterfaceImplementationDispatcher And importedInterfaceImplementationDispatcher.implementation.Contains("(BBClass *)&collections_importedgenericinterfaceimplementation_TImportedGenericMethod"), "an imported concrete generic method participates in the application dispatcher through its published class and template identities: " + CompilationSummary(importedInterfaceImplementationConsumerCompilation))
Local missingInterfaceMethodSource:String = "SuperStrict~nInterface IMissingGenericMethod~nMethod Tag<T>:Int(value:T)~nEnd Interface~nGlobal missingGenericMethod:IMissingGenericMethod~nGlobal missingGenericMethodValue:Int = missingGenericMethod.Tag(1)"
Local missingInterfaceMethodCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("missing-generic-interface-method.bmx", missingInterfaceMethodSource, Null, compilerOptions)
Check(HasCompilerDiagnostic(missingInterfaceMethodCompilation, "BMXC3083"), "a closed generic Interface method with no application-visible implementation or default receives an explicit AOT diagnostic")
Local defaultInterfaceMethodSource:String = "SuperStrict~nInterface IDefaultGenericMethod~nMethod Value<T>:Int(value:T) Default~nReturn 40~nEnd Method~nEnd Interface~nType TDefaultGenericMethod Implements IDefaultGenericMethod~nEnd Type~nGlobal defaultGenericMethod:IDefaultGenericMethod = New TDefaultGenericMethod~nGlobal defaultGenericMethodValue:Int = defaultGenericMethod.Value(~qdefault~q)"
Local defaultInterfaceMethodCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("default-generic-interface-method.bmx", defaultInterfaceMethodSource, Null, compilerOptions)
Local defaultInterfaceMethodUnit:TCompilerGenericUnit
If defaultInterfaceMethodCompilation.genericPlan Then
	For Local defaultGenericUnit:TCompilerGenericUnit = EachIn defaultInterfaceMethodCompilation.genericPlan.units
		If defaultGenericUnit.ir.dispatcherImplementations.length = 0 And defaultGenericUnit.specialization.artifact.typeDeclarationKind = GENERIC_TYPE_DECLARATION_INTERFACE Then defaultInterfaceMethodUnit = defaultGenericUnit
	Next
End If
Check(defaultInterfaceMethodCompilation.Succeeded() And defaultInterfaceMethodUnit And defaultInterfaceMethodUnit.implementation.Contains("return 40"), "a method-owned generic Interface Default body is the typed fallback when no concrete override exists: " + CompilationSummary(defaultInterfaceMethodCompilation))
Local inheritedDirectModuleSource:String = "SuperStrict~nModule Collections.InheritedDirectMethods~nType TDirectBase~nField baseValue:String~nMethod ReadBase<U>:String(input:U)~nReturn baseValue~nEnd Method~nMethod Pick<U>:U(input:U)~nReturn input~nEnd Method~nEnd Type~nType TDirectDerived Extends TDirectBase~nField baseValue:String~nMethod ReadBoth<U>:String(input:U)~nReturn baseValue~nEnd Method~nMethod Pick<U>:U(input:U) Override~nReturn input~nEnd Method~nEnd Type"
Local inheritedDirectModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/inheriteddirectmethods.mod/inheriteddirectmethods.bmx", inheritedDirectModuleSource, Null, compilerOptions)
Local inheritedDirectArtifactDiagnostics:TCompilerDiagnostic[]
Local inheritedDirectOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(inheritedDirectModuleCompilation, inheritedDirectArtifactDiagnostics)
Local inheritedDirectInterfaceDiagnostics:TCompilerDiagnostic[]
Local inheritedDirectInterface:String = TBlitzMaxCompiler.EmitInterface(inheritedDirectModuleCompilation, inheritedDirectInterfaceDiagnostics)
Check(inheritedDirectModuleCompilation.Succeeded() And inheritedDirectOutputs.length = 4 And inheritedDirectArtifactDiagnostics.length = 0 And inheritedDirectInterfaceDiagnostics.length = 0, "inherited ordinary owners publish declaring and overriding generic methods without source: " + CompilationSummary(inheritedDirectModuleCompilation))
Local inheritedReadBothArtifact:TGenericTemplateArtifact
For Local inheritedDirectOutput:TCompilerGenericTemplateOutput = EachIn inheritedDirectOutputs
	If inheritedDirectOutput.artifact.identity.qualifiedName.EndsWith(".ReadBoth") Then inheritedReadBothArtifact = inheritedDirectOutput.artifact
Next
Check(inheritedReadBothArtifact And inheritedReadBothArtifact.containingFields.length = 2 And inheritedReadBothArtifact.containingFields[0].linkageName = "_collections_inheriteddirectmethods_tdirectbase_basevalue" And inheritedReadBothArtifact.containingFields[1].linkageName = "_collections_inheriteddirectmethods_tdirectderived_basevalue", "derived generic method artifact retains same-name base/derived fields in base-first order with declaration-owned language linkage")
Local inheritedDirectResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
inheritedDirectResolver.AddInterface("collections.inheriteddirectmethods", "sdk/collections.inheriteddirectmethods.i", inheritedDirectInterface)
For Local inheritedDirectOutput:TCompilerGenericTemplateOutput = EachIn inheritedDirectOutputs
	inheritedDirectResolver.AddGenericTemplate(inheritedDirectOutput.artifactReference, "sdk/" + inheritedDirectOutput.artifactReference, inheritedDirectOutput.content)
Next
Local inheritedDirectConsumerSource:String = "SuperStrict~nImport Collections.InheritedDirectMethods~nGlobal inheritedDirect:TDirectDerived~nGlobal inheritedDirectBase:String = inheritedDirect.ReadBase(1)~nGlobal inheritedDirectField:String = inheritedDirect.ReadBoth(2)~nGlobal inheritedDirectOverride:String = inheritedDirect.Pick(~qderived~q)~nGlobal inheritedDirectAsBase:TDirectBase = inheritedDirect~nGlobal inheritedDirectBasePick:String = inheritedDirectAsBase.Pick(~qbase~q)"
Local inheritedDirectConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("inherited-direct-method-consumer.bmx", inheritedDirectConsumerSource, inheritedDirectResolver, compilerOptions)
Check(inheritedDirectConsumerCompilation.Succeeded() And inheritedDirectConsumerCompilation.genericPlan.registry.nodes.length = 4 And inheritedDirectConsumerCompilation.genericPlan.units.length = 4, "source-free inherited calls use declaring ownership while an exact derived override retains its own canonical identity: " + CompilationSummary(inheritedDirectConsumerCompilation))
Local inheritedBaseReadUnit:TCompilerGenericUnit
Local inheritedDerivedReadUnit:TCompilerGenericUnit
Local inheritedBasePickCount:Int
Local inheritedDerivedPickCount:Int
For Local inheritedDirectUnit:TCompilerGenericUnit = EachIn inheritedDirectConsumerCompilation.genericPlan.units
	If inheritedDirectUnit.specialization.artifact.identity.qualifiedName.EndsWith("TDirectBase.ReadBase") Then inheritedBaseReadUnit = inheritedDirectUnit
	If inheritedDirectUnit.specialization.artifact.identity.qualifiedName.EndsWith("TDirectDerived.ReadBoth") Then inheritedDerivedReadUnit = inheritedDirectUnit
	If inheritedDirectUnit.specialization.artifact.identity.qualifiedName.EndsWith("TDirectBase.Pick") Then inheritedBasePickCount :+ 1
	If inheritedDirectUnit.specialization.artifact.identity.qualifiedName.EndsWith("TDirectDerived.Pick") Then inheritedDerivedPickCount :+ 1
Next
Check(inheritedBaseReadUnit And inheritedDerivedReadUnit And inheritedBasePickCount = 1 And inheritedDerivedPickCount = 1, "inherited declaration and derived override specializations have unambiguous application-wide ownership")
Check(inheritedDerivedReadUnit.implementation.Contains("return self->_collections_inheriteddirectmethods_tdirectderived_basevalue;") And inheritedDerivedReadUnit.implementation.Find("_collections_inheriteddirectmethods_tdirectbase_basevalue") < inheritedDerivedReadUnit.implementation.Find("_collections_inheriteddirectmethods_tdirectderived_basevalue"), "derived separate unit reconstructs same-name field prefixes and binds field access by declaration identity rather than spelling")
Local inheritedDirectRuntimeDiagnostics:TCompilerDiagnostic[]
Local inheritedDirectRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(inheritedDirectConsumerCompilation, inheritedDirectRuntimeDiagnostics)
Check(inheritedDirectRuntimeDiagnostics.length = 0 And inheritedDirectRuntimeC.Contains("(struct collections_inheriteddirectmethods_TDirectBase_obj *)"), "direct inherited generic calls explicitly upcast a derived receiver to the declaration owner ABI")
Local mixedDirectModuleSource:String = "SuperStrict~nModule Collections.MixedDirectMethods~nType TGenericPrefix<T>~nField value:T~nField shadow:T~nMethod BaseGeneric<U>:T(input:U)~nReturn value~nEnd Method~nEnd Type~nType TMixedDirectOwner Extends TGenericPrefix<String>~nField shadow:String~nMethod ReadBase<U>:String(input:U)~nReturn value~nEnd Method~nMethod ReadShadow<U>:String(input:U)~nReturn shadow~nEnd Method~nMethod Forward<U>:String(input:U)~nReturn BaseGeneric(input)~nEnd Method~nEnd Type"
Local mixedDirectModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/mixeddirectmethods.mod/mixeddirectmethods.bmx", mixedDirectModuleSource, Null, compilerOptions)
Local mixedDirectArtifactDiagnostics:TCompilerDiagnostic[]
Local mixedDirectOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(mixedDirectModuleCompilation, mixedDirectArtifactDiagnostics)
Local mixedDirectInterfaceDiagnostics:TCompilerDiagnostic[]
Local mixedDirectInterface:String = TBlitzMaxCompiler.EmitInterface(mixedDirectModuleCompilation, mixedDirectInterfaceDiagnostics)
Check(mixedDirectModuleCompilation.Succeeded() And mixedDirectOutputs.length = 5 And mixedDirectArtifactDiagnostics.length = 0 And mixedDirectInterfaceDiagnostics.length = 0 And mixedDirectModuleCompilation.genericPlan.registry.nodes.length = 1, "ordinary generic-method owners close a canonical generic base layout during source-free publication: " + CompilationSummary(mixedDirectModuleCompilation))
Local mixedDirectBaseAbi:String = mixedDirectModuleCompilation.genericPlan.registry.nodes[0].readableAbiName
Local mixedReadBaseArtifact:TGenericTemplateArtifact
Local mixedReadShadowArtifact:TGenericTemplateArtifact
For Local mixedDirectOutput:TCompilerGenericTemplateOutput = EachIn mixedDirectOutputs
	If mixedDirectOutput.artifact.identity.qualifiedName.EndsWith("TMixedDirectOwner.ReadBase") Then mixedReadBaseArtifact = mixedDirectOutput.artifact
	If mixedDirectOutput.artifact.identity.qualifiedName.EndsWith("TMixedDirectOwner.ReadShadow") Then mixedReadShadowArtifact = mixedDirectOutput.artifact
Next
Check(mixedReadBaseArtifact And mixedReadShadowArtifact And mixedReadBaseArtifact.containingFields.length = 3 And mixedReadBaseArtifact.containingFields[0].linkageName = "_" + mixedDirectBaseAbi.ToLower() + "_value" And mixedReadBaseArtifact.containingFields[1].linkageName = "_" + mixedDirectBaseAbi.ToLower() + "_shadow" And mixedReadBaseArtifact.containingFields[2].linkageName = "_collections_mixeddirectmethods_tmixeddirectowner_shadow", "mixed owner artifacts flatten the closed generic prefix and retain separate same-name generic/ordinary field ownership")
Local mixedDirectResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
mixedDirectResolver.AddInterface("collections.mixeddirectmethods", "sdk/collections.mixeddirectmethods.i", mixedDirectInterface)
For Local mixedDirectOutput:TCompilerGenericTemplateOutput = EachIn mixedDirectOutputs
	mixedDirectResolver.AddGenericTemplate(mixedDirectOutput.artifactReference, "sdk/" + mixedDirectOutput.artifactReference, mixedDirectOutput.content)
Next
Local mixedDirectConsumerSource:String = "SuperStrict~nImport Collections.MixedDirectMethods~nGlobal mixedDirect:TMixedDirectOwner~nGlobal mixedDirectBase1:String = mixedDirect.ReadBase(1)~nGlobal mixedDirectBase2:String = mixedDirect.ReadBase(2)~nGlobal mixedDirectShadow:String = mixedDirect.ReadShadow(3)~nGlobal mixedInheritedGeneric:String = mixedDirect.BaseGeneric(4)~nGlobal mixedForward:String = mixedDirect.Forward(5)"
Local mixedDirectConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("mixed-direct-method-consumer.bmx", mixedDirectConsumerSource, mixedDirectResolver, compilerOptions)
Check(mixedDirectConsumerCompilation.Succeeded() And mixedDirectConsumerCompilation.genericPlan.registry.nodes.length = 5 And mixedDirectConsumerCompilation.genericPlan.units.length = 5, "source-free mixed inheritance deduplicates ordinary methods and closes direct/transitive inherited generic-base requests once: " + CompilationSummary(mixedDirectConsumerCompilation))
Local mixedReadBaseUnit:TCompilerGenericUnit
Local mixedReadShadowUnit:TCompilerGenericUnit
Local mixedForwardNode:TGenericSpecializationNode
For Local mixedDirectUnit:TCompilerGenericUnit = EachIn mixedDirectConsumerCompilation.genericPlan.units
	If mixedDirectUnit.specialization.artifact.identity.qualifiedName.EndsWith("TMixedDirectOwner.ReadBase") Then mixedReadBaseUnit = mixedDirectUnit
	If mixedDirectUnit.specialization.artifact.identity.qualifiedName.EndsWith("TMixedDirectOwner.ReadShadow") Then mixedReadShadowUnit = mixedDirectUnit
	If mixedDirectUnit.specialization.artifact.identity.qualifiedName.EndsWith("TMixedDirectOwner.Forward") Then mixedForwardNode = mixedDirectUnit.specialization
Next
Check(mixedReadBaseUnit And mixedReadShadowUnit And mixedReadBaseUnit.implementation.Contains("self->_" + mixedDirectBaseAbi.ToLower() + "_value") And mixedReadShadowUnit.implementation.Contains("self->_collections_mixeddirectmethods_tmixeddirectowner_shadow"), "mixed separate units bind generic-base and hidden derived fields by canonical declaration identity")
Check(mixedForwardNode And mixedForwardNode.outgoing.length = 2, "an ordinary derived generic method records explicit transitive edges to the inherited generic-base receiver and method specializations")
Local mixedDirectRuntimeDiagnostics:TCompilerDiagnostic[]
Local mixedDirectRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(mixedDirectConsumerCompilation, mixedDirectRuntimeDiagnostics)
Check(mixedDirectRuntimeDiagnostics.length = 0 And mixedDirectRuntimeC.Contains("(struct " + mixedDirectBaseAbi + "_obj *)"), "an inherited generic-base method call explicitly upcasts the ordinary derived receiver to the canonical specialization ABI")
Local mixedDirectCollisionSource:String = "SuperStrict~nModule Collisions.MixedDirect~nType TCollisionPrefix<T>~nField value:T~nEnd Type~nType TStringMixed Extends TCollisionPrefix<String>~nMethod Read<U>:String(input:U)~nReturn value~nEnd Method~nEnd Type~nType TIntMixed Extends TCollisionPrefix<Int>~nMethod Read<U>:Int(input:U)~nReturn value~nEnd Method~nEnd Type~nGlobal stringMixed:TStringMixed~nGlobal intMixed:TIntMixed~nGlobal stringMixedValue:String = stringMixed.Read(1)~nGlobal intMixedValue:Int = intMixed.Read(2)"
Local mixedDirectCollisionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collisions.mod/mixeddirect.mod/mixeddirect.bmx", mixedDirectCollisionSource, Null, compilerOptions)
Local mixedCollisionBaseAbis:String[]
Local mixedCollisionMethodAbis:String[]
For Local mixedCollisionNode:TGenericSpecializationNode = EachIn mixedDirectCollisionCompilation.genericPlan.registry.nodes
	If mixedCollisionNode.artifact.identity.qualifiedName = "TCollisionPrefix" Then mixedCollisionBaseAbis :+ [mixedCollisionNode.readableAbiName]
	If mixedCollisionNode.artifact.identity.qualifiedName.EndsWith(".Read") Then mixedCollisionMethodAbis :+ [mixedCollisionNode.readableAbiName]
Next
Check(mixedDirectCollisionCompilation.Succeeded() And mixedDirectCollisionCompilation.genericPlan.registry.nodes.length = 4 And mixedCollisionBaseAbis.length = 2 And mixedCollisionMethodAbis.length = 2 And mixedCollisionBaseAbis[0] <> mixedCollisionBaseAbis[1] And mixedCollisionMethodAbis[0] <> mixedCollisionMethodAbis[1], "different closed generic prefixes and same-name ordinary generic methods retain collision-resistant specialization identities: " + CompilationSummary(mixedDirectCollisionCompilation))
Local constrainedMethodSource:String = "SuperStrict~nModule Constraints.DirectMethod~nInterface IMethodMarker~nEnd Interface~nType TConstrainedMethodOwner<T> Where T Extends IMethodMarker~nMethod Convert<U>:U(value:T, fallback:U) Where U Extends IMethodMarker~nReturn fallback~nEnd Method~nEnd Type"
Local constrainedMethodCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/constraints.mod/directmethod.mod/directmethod.bmx", constrainedMethodSource, Null, compilerOptions)
Local constrainedMethodArtifact:TGenericTemplateArtifact
For Local constrainedMethodOutput:TCompilerGenericTemplateOutput = EachIn constrainedMethodCompilation.genericPlan.templateOutputs
	If constrainedMethodOutput.artifact.isMethod Then constrainedMethodArtifact = constrainedMethodOutput.artifact
Next
Check(constrainedMethodCompilation.Succeeded() And constrainedMethodArtifact And constrainedMethodArtifact.containingParameters[0].constraints.length = 1 And constrainedMethodArtifact.parameters[0].constraints.length = 1, "direct method artifacts preserve containing-Type and method-owned Where constraints independently: " + CompilationSummary(constrainedMethodCompilation))
Local routineModuleSource:String = "SuperStrict~nModule Collections.GenericRoutines~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function"
Local routineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/genericroutines.mod/genericroutines.bmx", routineModuleSource, Null, compilerOptions)
Local routineModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local routineModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(routineModuleCompilation, routineModuleArtifactDiagnostics)
Local routineModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local routineModuleInterface:String = TBlitzMaxCompiler.EmitInterface(routineModuleCompilation, routineModuleInterfaceDiagnostics)
Check(routineModuleCompilation.Succeeded() And routineModuleArtifactDiagnostics.length = 0 And routineModuleInterfaceDiagnostics.length = 0 And routineModuleOutputs.length = 1 And routineModuleOutputs[0].artifact.identity.declarationKind = GENERIC_DECLARATION_ROUTINE, "module publication emits one source-free canonical generic routine artifact: " + CompilationSummary(routineModuleCompilation))
Check(routineModuleInterface.Contains("Identity<T>") And routineModuleInterface.Contains("'@generic-template " + GENERIC_TEMPLATE_FORMAT_VERSION + ",") And Not routineModuleInterface.Contains("Return value"), "compact routine signature references its artifact without copied source")
Local otherRoutineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/other.mod/genericroutines.mod/genericroutines.bmx", routineModuleSource.Replace("Collections.GenericRoutines", "Other.GenericRoutines"), Null, compilerOptions)
Local otherRoutineModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local otherRoutineModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(otherRoutineModuleCompilation, otherRoutineModuleArtifactDiagnostics)
Check(otherRoutineModuleCompilation.Succeeded() And otherRoutineModuleOutputs.length = 1 And routineModuleOutputs[0].artifact.identity.StableName() <> otherRoutineModuleOutputs[0].artifact.identity.StableName(), "same-name generic routines in different modules retain distinct canonical template identities")
Local routineModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
routineModuleResolver.AddInterface("collections.genericroutines", "sdk/collections.genericroutines.i", routineModuleInterface)
routineModuleResolver.AddGenericTemplate(routineModuleOutputs[0].artifactReference, "sdk/" + routineModuleOutputs[0].artifactReference, routineModuleOutputs[0].content)
Local routineConsumerSource:String = "SuperStrict~nImport Collections.GenericRoutines~nGlobal importedIdentity1:String = Identity(~qfirst module call~q)~nGlobal importedIdentity2:String = Identity<String>(~qsecond module call~q)"
Local routineConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-routine-consumer.bmx", routineConsumerSource, routineModuleResolver, compilerOptions)
Check(routineConsumerCompilation.Succeeded() And routineConsumerCompilation.genericPlan.registry.nodes.length = 1 And routineConsumerCompilation.genericPlan.units.length = 1, "cross-module generic routine specializes entirely from compact signature and source-free artifact: " + CompilationSummary(routineConsumerCompilation))
Check(routineConsumerCompilation.genericPlan.units[0].implementation.Contains("return value;") And routineConsumerCompilation.genericPlan.registry.nodes[0].artifact.EffectiveContentRevision() = routineModuleOutputs[0].artifact.EffectiveContentRevision(), "cross-module routine implementation retains canonical content identity and bound body")
Local transitiveRoutineModuleSource:String = "SuperStrict~nModule Collections.Forwarding~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nFunction Forward<T>:T(value:T)~nReturn Identity(value)~nEnd Function"
Local transitiveRoutineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/forwarding.mod/forwarding.bmx", transitiveRoutineModuleSource, Null, compilerOptions)
Local transitiveRoutineModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local transitiveRoutineModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(transitiveRoutineModuleCompilation, transitiveRoutineModuleArtifactDiagnostics)
Local transitiveRoutineModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local transitiveRoutineModuleInterface:String = TBlitzMaxCompiler.EmitInterface(transitiveRoutineModuleCompilation, transitiveRoutineModuleInterfaceDiagnostics)
Check(transitiveRoutineModuleCompilation.Succeeded() And transitiveRoutineModuleArtifactDiagnostics.length = 0 And transitiveRoutineModuleInterfaceDiagnostics.length = 0 And transitiveRoutineModuleOutputs.length = 2, "module publishes both source-free artifacts required by a transitive generic routine call")
Local transitiveRoutineModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
transitiveRoutineModuleResolver.AddInterface("collections.forwarding", "sdk/collections.forwarding.i", transitiveRoutineModuleInterface)
For Local transitiveRoutineOutput:TCompilerGenericTemplateOutput = EachIn transitiveRoutineModuleOutputs
	transitiveRoutineModuleResolver.AddGenericTemplate(transitiveRoutineOutput.artifactReference, "sdk/" + transitiveRoutineOutput.artifactReference, transitiveRoutineOutput.content)
Next
Local transitiveRoutineConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-forwarding-consumer.bmx", "SuperStrict~nImport Collections.Forwarding~nGlobal forwardedModuleValue:String = Forward(~qsource free edge~q)", transitiveRoutineModuleResolver, compilerOptions)
Check(transitiveRoutineConsumerCompilation.Succeeded() And transitiveRoutineConsumerCompilation.genericPlan.registry.nodes.length = 2 And transitiveRoutineConsumerCompilation.genericPlan.units.length = 2, "source-free consumer reconstructs the transitive generic routine specialization graph: " + CompilationSummary(transitiveRoutineConsumerCompilation))
Local sourceFreeForwardUnit:TCompilerGenericUnit
For Local sourceFreeRoutineUnit:TCompilerGenericUnit = EachIn transitiveRoutineConsumerCompilation.genericPlan.units
	If sourceFreeRoutineUnit.specialization.artifact.identity.qualifiedName = "Forward" Then sourceFreeForwardUnit = sourceFreeRoutineUnit
Next
Check(sourceFreeForwardUnit And sourceFreeForwardUnit.specialization.outgoing.length = 1 And sourceFreeForwardUnit.implementation.Contains(sourceFreeForwardUnit.specialization.outgoing[0].target.readableAbiName + "(value)"), "source-free caller unit references its separately owned canonical callee")
Local scalarRoutineModuleSource:String = "SuperStrict~nModule Collections.ScalarExpressions~nFunction Transform<T>:T(left:T, right:T)~nReturn -(left + right * right)~nEnd Function"
Local scalarRoutineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/scalarexpressions.mod/scalarexpressions.bmx", scalarRoutineModuleSource, Null, compilerOptions)
Local scalarRoutineModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local scalarRoutineModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(scalarRoutineModuleCompilation, scalarRoutineModuleArtifactDiagnostics)
Local scalarRoutineModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local scalarRoutineModuleInterface:String = TBlitzMaxCompiler.EmitInterface(scalarRoutineModuleCompilation, scalarRoutineModuleInterfaceDiagnostics)
Check(scalarRoutineModuleCompilation.Succeeded() And scalarRoutineModuleArtifactDiagnostics.length = 0 And scalarRoutineModuleInterfaceDiagnostics.length = 0 And scalarRoutineModuleOutputs.length = 1, "module publishes a source-free generic scalar-expression artifact")
Local scalarRoutineModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
scalarRoutineModuleResolver.AddInterface("collections.scalarexpressions", "sdk/collections.scalarexpressions.i", scalarRoutineModuleInterface)
scalarRoutineModuleResolver.AddGenericTemplate(scalarRoutineModuleOutputs[0].artifactReference, "sdk/" + scalarRoutineModuleOutputs[0].artifactReference, scalarRoutineModuleOutputs[0].content)
Local scalarRoutineConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-scalar-expression-consumer.bmx", "SuperStrict~nImport Collections.ScalarExpressions~nGlobal transformedModuleValue:Int = Transform(2, 4)", scalarRoutineModuleResolver, compilerOptions)
Check(scalarRoutineConsumerCompilation.Succeeded() And scalarRoutineConsumerCompilation.genericPlan.units.length = 1 And scalarRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("return (-(left + (right * right)));"), "source-free imported generic scalar expressions specialize without reparsing source: " + CompilationSummary(scalarRoutineConsumerCompilation))
Local sequentialRoutineModuleSource:String = "SuperStrict~nModule Collections.SequentialBody~nFunction Accumulate<T>:T(first:T, second:T)~nLocal result:T = first~nresult = result + second~nReturn result~nEnd Function"
Local sequentialRoutineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/sequentialbody.mod/sequentialbody.bmx", sequentialRoutineModuleSource, Null, compilerOptions)
Local sequentialRoutineModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local sequentialRoutineModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(sequentialRoutineModuleCompilation, sequentialRoutineModuleArtifactDiagnostics)
Local sequentialRoutineModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local sequentialRoutineModuleInterface:String = TBlitzMaxCompiler.EmitInterface(sequentialRoutineModuleCompilation, sequentialRoutineModuleInterfaceDiagnostics)
Check(sequentialRoutineModuleCompilation.Succeeded() And sequentialRoutineModuleArtifactDiagnostics.length = 0 And sequentialRoutineModuleInterfaceDiagnostics.length = 0 And sequentialRoutineModuleOutputs.length = 1, "module publishes a source-free generic sequential-body artifact")
Local sequentialRoutineModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
sequentialRoutineModuleResolver.AddInterface("collections.sequentialbody", "sdk/collections.sequentialbody.i", sequentialRoutineModuleInterface)
sequentialRoutineModuleResolver.AddGenericTemplate(sequentialRoutineModuleOutputs[0].artifactReference, "sdk/" + sequentialRoutineModuleOutputs[0].artifactReference, sequentialRoutineModuleOutputs[0].content)
Local sequentialRoutineConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-sequential-body-consumer.bmx", "SuperStrict~nImport Collections.SequentialBody~nGlobal accumulatedModuleValue:Int = Accumulate(20, 22)", sequentialRoutineModuleResolver, compilerOptions)
Check(sequentialRoutineConsumerCompilation.Succeeded() And sequentialRoutineConsumerCompilation.genericPlan.units.length = 1 And sequentialRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("BBINT bmx_local_result = first;") And sequentialRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("bmx_local_result = (bmx_local_result + second);"), "source-free imported generic locals and assignments specialize without reparsing source: " + CompilationSummary(sequentialRoutineConsumerCompilation))
Local branchRoutineModuleSource:String = "SuperStrict~nModule Collections.BranchBody~nFunction Choose<T>:T(value:T, fallback:T, enabled:Int)~nIf enabled > 0 Then~nReturn value~nElse If enabled < 0 Then~nReturn fallback~nElse~nReturn value~nEnd If~nEnd Function"
Local branchRoutineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/branchbody.mod/branchbody.bmx", branchRoutineModuleSource, Null, compilerOptions)
Local branchRoutineModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local branchRoutineModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(branchRoutineModuleCompilation, branchRoutineModuleArtifactDiagnostics)
Local branchRoutineModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local branchRoutineModuleInterface:String = TBlitzMaxCompiler.EmitInterface(branchRoutineModuleCompilation, branchRoutineModuleInterfaceDiagnostics)
Check(branchRoutineModuleCompilation.Succeeded() And branchRoutineModuleArtifactDiagnostics.length = 0 And branchRoutineModuleInterfaceDiagnostics.length = 0 And branchRoutineModuleOutputs.length = 1, "module publishes a source-free generic If/Else artifact")
Local branchRoutineModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
branchRoutineModuleResolver.AddInterface("collections.branchbody", "sdk/collections.branchbody.i", branchRoutineModuleInterface)
branchRoutineModuleResolver.AddGenericTemplate(branchRoutineModuleOutputs[0].artifactReference, "sdk/" + branchRoutineModuleOutputs[0].artifactReference, branchRoutineModuleOutputs[0].content)
Local branchRoutineConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-branch-body-consumer.bmx", "SuperStrict~nImport Collections.BranchBody~nGlobal chosenModuleValue:Int = Choose(42, 1, True)", branchRoutineModuleResolver, compilerOptions)
Check(branchRoutineConsumerCompilation.Succeeded() And branchRoutineConsumerCompilation.genericPlan.units.length = 1 And branchRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("if (enabled > 0) {") And branchRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("} else if (enabled < 0) {") And branchRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("} else {"), "source-free imported generic Else If specializes without reparsing source: " + CompilationSummary(branchRoutineConsumerCompilation))
Local whileRoutineModuleSource:String = "SuperStrict~nModule Collections.WhileBody~nFunction RepeatAdd<T>:T(seed:T, count:Int)~nLocal result:T = seed~nLocal index:Int~nWhile index < count~nresult = result + seed~nindex = index + 1~nWend~nReturn result~nEnd Function"
Local whileRoutineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/whilebody.mod/whilebody.bmx", whileRoutineModuleSource, Null, compilerOptions)
Local whileRoutineModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local whileRoutineModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(whileRoutineModuleCompilation, whileRoutineModuleArtifactDiagnostics)
Local whileRoutineModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local whileRoutineModuleInterface:String = TBlitzMaxCompiler.EmitInterface(whileRoutineModuleCompilation, whileRoutineModuleInterfaceDiagnostics)
Check(whileRoutineModuleCompilation.Succeeded() And whileRoutineModuleArtifactDiagnostics.length = 0 And whileRoutineModuleInterfaceDiagnostics.length = 0 And whileRoutineModuleOutputs.length = 1, "module publishes a source-free generic While artifact")
Local whileRoutineModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
whileRoutineModuleResolver.AddInterface("collections.whilebody", "sdk/collections.whilebody.i", whileRoutineModuleInterface)
whileRoutineModuleResolver.AddGenericTemplate(whileRoutineModuleOutputs[0].artifactReference, "sdk/" + whileRoutineModuleOutputs[0].artifactReference, whileRoutineModuleOutputs[0].content)
Local whileRoutineConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-while-body-consumer.bmx", "SuperStrict~nImport Collections.WhileBody~nGlobal repeatedModuleValue:Int = RepeatAdd(7, 5)", whileRoutineModuleResolver, compilerOptions)
Check(whileRoutineConsumerCompilation.Succeeded() And whileRoutineConsumerCompilation.genericPlan.units.length = 1 And whileRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("while (bmx_local_index < count) {") And whileRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("bmx_local_result = (bmx_local_result + seed);"), "source-free imported generic While specializes without reparsing source: " + CompilationSummary(whileRoutineConsumerCompilation))
Local controlRoutineModuleSource:String = "SuperStrict~nModule Collections.ControlBody~nFunction ControlAdd<T>:T(seed:T, count:Int)~nLocal result:T = seed~nLocal index:Int~nWhile index < count~nindex = index + 1~nIf index = 2 Then Continue~nresult = result + seed~nIf index = 4 Then Exit~nWend~nReturn result~nEnd Function"
Local controlRoutineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/controlbody.mod/controlbody.bmx", controlRoutineModuleSource, Null, compilerOptions)
Local controlRoutineModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local controlRoutineModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(controlRoutineModuleCompilation, controlRoutineModuleArtifactDiagnostics)
Local controlRoutineModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local controlRoutineModuleInterface:String = TBlitzMaxCompiler.EmitInterface(controlRoutineModuleCompilation, controlRoutineModuleInterfaceDiagnostics)
Check(controlRoutineModuleCompilation.Succeeded() And controlRoutineModuleArtifactDiagnostics.length = 0 And controlRoutineModuleInterfaceDiagnostics.length = 0 And controlRoutineModuleOutputs.length = 1, "module publishes source-free canonical loop-control targets")
Local controlRoutineModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
controlRoutineModuleResolver.AddInterface("collections.controlbody", "sdk/collections.controlbody.i", controlRoutineModuleInterface)
controlRoutineModuleResolver.AddGenericTemplate(controlRoutineModuleOutputs[0].artifactReference, "sdk/" + controlRoutineModuleOutputs[0].artifactReference, controlRoutineModuleOutputs[0].content)
Local controlRoutineConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-control-body-consumer.bmx", "SuperStrict~nImport Collections.ControlBody~nGlobal controlledModuleValue:Int = ControlAdd(10, 10)", controlRoutineModuleResolver, compilerOptions)
Check(controlRoutineConsumerCompilation.Succeeded() And controlRoutineConsumerCompilation.genericPlan.units.length = 1 And controlRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("goto bmx_loop0_continue;") And controlRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("goto bmx_loop0_exit;"), "source-free imported generic loop control specializes without resolving labels or nesting again: " + CompilationSummary(controlRoutineConsumerCompilation))
Local repeatRoutineModuleSource:String = "SuperStrict~nModule Collections.RepeatBody~nFunction RepeatAdd<T>:T(seed:T, count:Int)~nLocal result:T = seed~nLocal index:Int~nRepeat~nresult = result + seed~nindex = index + 1~nUntil index = count~nReturn result~nEnd Function"
Local repeatRoutineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/repeatbody.mod/repeatbody.bmx", repeatRoutineModuleSource, Null, compilerOptions)
Local repeatRoutineModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local repeatRoutineModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(repeatRoutineModuleCompilation, repeatRoutineModuleArtifactDiagnostics)
Local repeatRoutineModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local repeatRoutineModuleInterface:String = TBlitzMaxCompiler.EmitInterface(repeatRoutineModuleCompilation, repeatRoutineModuleInterfaceDiagnostics)
Check(repeatRoutineModuleCompilation.Succeeded() And repeatRoutineModuleArtifactDiagnostics.length = 0 And repeatRoutineModuleInterfaceDiagnostics.length = 0 And repeatRoutineModuleOutputs.length = 1, "module publishes a source-free generic Repeat Until artifact")
Local repeatRoutineModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
repeatRoutineModuleResolver.AddInterface("collections.repeatbody", "sdk/collections.repeatbody.i", repeatRoutineModuleInterface)
repeatRoutineModuleResolver.AddGenericTemplate(repeatRoutineModuleOutputs[0].artifactReference, "sdk/" + repeatRoutineModuleOutputs[0].artifactReference, repeatRoutineModuleOutputs[0].content)
Local repeatRoutineConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-repeat-body-consumer.bmx", "SuperStrict~nImport Collections.RepeatBody~nGlobal repeatedModuleValue:Int = RepeatAdd(7, 5)", repeatRoutineModuleResolver, compilerOptions)
Check(repeatRoutineConsumerCompilation.Succeeded() And repeatRoutineConsumerCompilation.genericPlan.units.length = 1 And repeatRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("do {") And repeatRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("} while (!((bmx_local_index == count)));"), "source-free imported generic Repeat Until specializes without reparsing source: " + CompilationSummary(repeatRoutineConsumerCompilation))
Local forRoutineModuleSource:String = "SuperStrict~nModule Collections.ForBody~nFunction ForAdd<T>:T(seed:T, count:Int)~nLocal result:T = seed~nLocal index:Int~nFor index = 0 Until count~nresult = result + seed~nNext~nReturn result~nEnd Function"
Local forRoutineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/forbody.mod/forbody.bmx", forRoutineModuleSource, Null, compilerOptions)
Local forRoutineModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local forRoutineModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(forRoutineModuleCompilation, forRoutineModuleArtifactDiagnostics)
Local forRoutineModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local forRoutineModuleInterface:String = TBlitzMaxCompiler.EmitInterface(forRoutineModuleCompilation, forRoutineModuleInterfaceDiagnostics)
Check(forRoutineModuleCompilation.Succeeded() And forRoutineModuleArtifactDiagnostics.length = 0 And forRoutineModuleInterfaceDiagnostics.length = 0 And forRoutineModuleOutputs.length = 1, "module publishes a source-free generic range For artifact")
Local forRoutineModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
forRoutineModuleResolver.AddInterface("collections.forbody", "sdk/collections.forbody.i", forRoutineModuleInterface)
forRoutineModuleResolver.AddGenericTemplate(forRoutineModuleOutputs[0].artifactReference, "sdk/" + forRoutineModuleOutputs[0].artifactReference, forRoutineModuleOutputs[0].content)
Local forRoutineConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-for-body-consumer.bmx", "SuperStrict~nImport Collections.ForBody~nGlobal forModuleValue:Int = ForAdd(7, 5)", forRoutineModuleResolver, compilerOptions)
Check(forRoutineConsumerCompilation.Succeeded() And forRoutineConsumerCompilation.genericPlan.units.length = 1 And forRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("for (bmx_local_index = ((BBINT)(0));") And forRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("bmx_local_result = (bmx_local_result + seed);"), "source-free imported generic existing-target range For specializes without reparsing source: " + CompilationSummary(forRoutineConsumerCompilation))
Local eachInStringRoutineModuleSource:String = "SuperStrict~nModule Collections.EachInStringBody~nFunction FirstCodeOr<T>:T(fallback:T, text:String)~nFor Local code:Int = EachIn text~nIf code = 32 Then Continue~nExit~nNext~nReturn fallback~nEnd Function"
Local eachInStringRoutineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/eachinstringbody.mod/eachinstringbody.bmx", eachInStringRoutineModuleSource, Null, compilerOptions)
Local eachInStringRoutineModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local eachInStringRoutineModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(eachInStringRoutineModuleCompilation, eachInStringRoutineModuleArtifactDiagnostics)
Local eachInStringRoutineModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local eachInStringRoutineModuleInterface:String = TBlitzMaxCompiler.EmitInterface(eachInStringRoutineModuleCompilation, eachInStringRoutineModuleInterfaceDiagnostics)
Check(eachInStringRoutineModuleCompilation.Succeeded() And eachInStringRoutineModuleArtifactDiagnostics.length = 0 And eachInStringRoutineModuleInterfaceDiagnostics.length = 0 And eachInStringRoutineModuleOutputs.length = 1, "module publishes a source-free generic String EachIn artifact")
Check(Not eachInStringRoutineModuleOutputs[0].content.Contains("For Local code") And Not eachInStringRoutineModuleOutputs[0].content.Contains("EachIn text"), "generic String EachIn artifact contains bound records rather than copied source text")
Local eachInStringRoutineModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
eachInStringRoutineModuleResolver.AddInterface("collections.eachinstringbody", "sdk/collections.eachinstringbody.i", eachInStringRoutineModuleInterface)
eachInStringRoutineModuleResolver.AddGenericTemplate(eachInStringRoutineModuleOutputs[0].artifactReference, "sdk/" + eachInStringRoutineModuleOutputs[0].artifactReference, eachInStringRoutineModuleOutputs[0].content)
Local eachInStringRoutineConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-eachin-string-body-consumer.bmx", "SuperStrict~nImport Collections.EachInStringBody~nGlobal eachInStringModuleValue:Int = FirstCodeOr(7, ~q A~q)", eachInStringRoutineModuleResolver, compilerOptions)
Check(eachInStringRoutineConsumerCompilation.Succeeded() And eachInStringRoutineConsumerCompilation.genericPlan.units.length = 1 And eachInStringRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("BBSTRING bmx_loop0_collection = text;") And eachInStringRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("bmx_loop0_collection->buf[bmx_loop0_index]") And eachInStringRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("goto bmx_loop0_continue;") And eachInStringRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("goto bmx_loop0_exit;"), "source-free imported generic String EachIn specializes without reparsing source or resolving loop targets again: " + CompilationSummary(eachInStringRoutineConsumerCompilation))
Local eachInArrayRoutineModuleSource:String = "SuperStrict~nModule Collections.EachInArrayBody~nFunction FirstArrayOr<T>:T(fallback:T, values:T[])~nFor Local item:T = EachIn values~nReturn item~nNext~nReturn fallback~nEnd Function"
Local eachInArrayRoutineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/eachinarraybody.mod/eachinarraybody.bmx", eachInArrayRoutineModuleSource, Null, compilerOptions)
Local eachInArrayRoutineModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local eachInArrayRoutineModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(eachInArrayRoutineModuleCompilation, eachInArrayRoutineModuleArtifactDiagnostics)
Local eachInArrayRoutineModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local eachInArrayRoutineModuleInterface:String = TBlitzMaxCompiler.EmitInterface(eachInArrayRoutineModuleCompilation, eachInArrayRoutineModuleInterfaceDiagnostics)
Check(eachInArrayRoutineModuleCompilation.Succeeded() And eachInArrayRoutineModuleArtifactDiagnostics.length = 0 And eachInArrayRoutineModuleInterfaceDiagnostics.length = 0 And eachInArrayRoutineModuleOutputs.length = 1, "module publishes a source-free generic managed Array EachIn artifact")
Check(Not eachInArrayRoutineModuleOutputs[0].content.Contains("For Local item") And Not eachInArrayRoutineModuleOutputs[0].content.Contains("EachIn values"), "generic managed Array EachIn artifact contains closed-bound records rather than copied source text")
Local eachInArrayRoutineModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
eachInArrayRoutineModuleResolver.AddInterface("collections.eachinarraybody", "sdk/collections.eachinarraybody.i", eachInArrayRoutineModuleInterface)
eachInArrayRoutineModuleResolver.AddGenericTemplate(eachInArrayRoutineModuleOutputs[0].artifactReference, "sdk/" + eachInArrayRoutineModuleOutputs[0].artifactReference, eachInArrayRoutineModuleOutputs[0].content)
Local eachInArrayRoutineConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-eachin-array-body-consumer.bmx", "SuperStrict~nImport Collections.EachInArrayBody~nGlobal eachInArrayModuleValue:Int = FirstArrayOr(7, [42])", eachInArrayRoutineModuleResolver, compilerOptions)
Check(eachInArrayRoutineConsumerCompilation.Succeeded() And eachInArrayRoutineConsumerCompilation.genericPlan.units.length = 1 And eachInArrayRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("BBARRAY bmx_loop0_collection = values;") And eachInArrayRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("((BBINT*)BBARRAYDATA(bmx_loop0_collection, 1))[bmx_loop0_index]"), "source-free imported generic managed Array EachIn specializes from its element-type record without reparsing source: " + CompilationSummary(eachInArrayRoutineConsumerCompilation))
Local eachInStaticRoutineModuleSource:String = "SuperStrict~nModule Collections.EachInStaticBody~nFunction ScanFixed<T>:T(value:T, StaticArray values:Int[2])~nFor Local item:Short = EachIn values~nIf item = 0 Then Continue~nExit~nNext~nReturn value~nEnd Function"
Local eachInStaticRoutineModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/eachinstaticbody.mod/eachinstaticbody.bmx", eachInStaticRoutineModuleSource, Null, compilerOptions)
Local eachInStaticRoutineModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local eachInStaticRoutineModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(eachInStaticRoutineModuleCompilation, eachInStaticRoutineModuleArtifactDiagnostics)
Local eachInStaticRoutineModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local eachInStaticRoutineModuleInterface:String = TBlitzMaxCompiler.EmitInterface(eachInStaticRoutineModuleCompilation, eachInStaticRoutineModuleInterfaceDiagnostics)
Check(eachInStaticRoutineModuleCompilation.Succeeded() And eachInStaticRoutineModuleArtifactDiagnostics.length = 0 And eachInStaticRoutineModuleInterfaceDiagnostics.length = 0 And eachInStaticRoutineModuleOutputs.length = 1, "module publishes a source-free format-6 generic StaticArray EachIn artifact")
Check(Not eachInStaticRoutineModuleOutputs[0].content.Contains("For Local item") And Not eachInStaticRoutineModuleOutputs[0].content.Contains("EachIn values"), "generic StaticArray EachIn artifact contains extent-bearing bound records rather than copied source text")
Local eachInStaticRoutineModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
eachInStaticRoutineModuleResolver.AddInterface("collections.eachinstaticbody", "sdk/collections.eachinstaticbody.i", eachInStaticRoutineModuleInterface)
eachInStaticRoutineModuleResolver.AddGenericTemplate(eachInStaticRoutineModuleOutputs[0].artifactReference, "sdk/" + eachInStaticRoutineModuleOutputs[0].artifactReference, eachInStaticRoutineModuleOutputs[0].content)
Local eachInStaticRoutineConsumerSource:String = "SuperStrict~nImport Collections.EachInStaticBody~nLocal StaticArray fixed:Int[2]~nfixed[0] = 42~nLocal eachInStaticModuleValue:Int = ScanFixed(7, fixed)"
Local eachInStaticRoutineConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-eachin-static-body-consumer.bmx", eachInStaticRoutineConsumerSource, eachInStaticRoutineModuleResolver, compilerOptions)
Check(eachInStaticRoutineConsumerCompilation.Succeeded() And eachInStaticRoutineConsumerCompilation.genericPlan.units.length = 1 And eachInStaticRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("BBINT * values") And eachInStaticRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("< (BBUINT)2;") And eachInStaticRoutineConsumerCompilation.genericPlan.units[0].implementation.Contains("bmx_loop0_collection[bmx_loop0_index]"), "source-free imported generic StaticArray EachIn specializes from its fixed extent without reparsing source: " + CompilationSummary(eachInStaticRoutineConsumerCompilation))
Local eachInInterfaceModuleSource:String = "SuperStrict~nModule Collections.EachInInterfaceBody~nInterface IIterator<T>~nMethod Current:T()~nMethod MoveNext:Int()~nEnd Interface~nInterface IIterable<T>~nMethod GetIterator:IIterator<T>()~nEnd Interface~nType TCanonicalIterator<T> Implements IIterator<T>~nField value:T~nField remaining:Int~nMethod Current:T()~nReturn value~nEnd Method~nMethod MoveNext:Int()~nIf remaining Then~nremaining = 0~nReturn True~nEnd If~nReturn False~nEnd Method~nEnd Type~nType TCanonicalValues<T> Implements IIterable<T>~nField iterator:IIterator<T>~nMethod GetIterator:IIterator<T>()~nReturn iterator~nEnd Method~nEnd Type~nFunction FirstInterfaceValue<T>:T(fallback:T, values:IIterable<T>)~nFor Local item:T = EachIn values~nReturn item~nNext~nReturn fallback~nEnd Function"
Local eachInInterfaceModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/eachininterfacebody.mod/eachininterfacebody.bmx", eachInInterfaceModuleSource, Null, compilerOptions)
Local eachInInterfaceModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local eachInInterfaceModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(eachInInterfaceModuleCompilation, eachInInterfaceModuleArtifactDiagnostics)
Local eachInInterfaceModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local eachInInterfaceModuleInterface:String = TBlitzMaxCompiler.EmitInterface(eachInInterfaceModuleCompilation, eachInInterfaceModuleInterfaceDiagnostics)
Check(eachInInterfaceModuleCompilation.Succeeded() And eachInInterfaceModuleArtifactDiagnostics.length = 0 And eachInInterfaceModuleInterfaceDiagnostics.length = 0 And eachInInterfaceModuleOutputs.length = 5, "module publishes source-free canonical IIterable/IIterator protocol artifacts")
Local eachInInterfaceModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
eachInInterfaceModuleResolver.AddInterface("collections.eachininterfacebody", "sdk/collections.eachininterfacebody.i", eachInInterfaceModuleInterface)
For Local eachInInterfaceOutput:TCompilerGenericTemplateOutput = EachIn eachInInterfaceModuleOutputs
	eachInInterfaceModuleResolver.AddGenericTemplate(eachInInterfaceOutput.artifactReference, "sdk/" + eachInInterfaceOutput.artifactReference, eachInInterfaceOutput.content)
	Check(Not eachInInterfaceOutput.content.Contains("EachIn values") And Not eachInInterfaceOutput.content.Contains("For Local item"), "generic Interface protocol artifacts contain bound operation records rather than source")
Next
Local eachInInterfaceConsumerSource:String = "SuperStrict~nImport Collections.EachInInterfaceBody~nGlobal canonicalIterator:TCanonicalIterator<Int> = New TCanonicalIterator<Int>~ncanonicalIterator.value = 42~ncanonicalIterator.remaining = 1~nGlobal canonicalValues:TCanonicalValues<Int> = New TCanonicalValues<Int>~ncanonicalValues.iterator = canonicalIterator~nGlobal iterableView:IIterable<Int> = canonicalValues~nGlobal importedInterfaceValue:Int = FirstInterfaceValue(0, iterableView)"
Local eachInInterfaceConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-eachin-interface-body-consumer.bmx", eachInInterfaceConsumerSource, eachInInterfaceModuleResolver, compilerOptions)
Check(eachInInterfaceConsumerCompilation.Succeeded() And eachInInterfaceConsumerCompilation.genericPlan.units.length = 5, "source-free imported generic Interface EachIn closes its canonical protocol graph: " + CompilationSummary(eachInInterfaceConsumerCompilation))
Local importedInterfaceEachInImplementation:String
For Local importedInterfaceEachInUnit:TCompilerGenericUnit = EachIn eachInInterfaceConsumerCompilation.genericPlan.units
	If importedInterfaceEachInUnit.ir.specialization.artifact.identity.qualifiedName = "FirstInterfaceValue" Then importedInterfaceEachInImplementation = importedInterfaceEachInUnit.implementation
Next
Check(importedInterfaceEachInImplementation.Contains("m_getiterator_0") And importedInterfaceEachInImplementation.Contains("m_movenext_1") And importedInterfaceEachInImplementation.Contains("m_current_0") And importedInterfaceEachInImplementation.Contains("bbObjectInterface"), "source-free imported generic Interface EachIn restores symbolic factory, advance, and current slots")
Local eachInLegacyModuleSource:String = "SuperStrict~nModule Collections.EachInLegacyBody~nType TOrdinaryItem~nEnd Type~nInterface IOrdinaryItem~nEnd Interface~nType TOrdinaryIterator~nField value:Object~nMethod HasNext:Int()~nReturn False~nEnd Method~nMethod NextObject:Object()~nReturn value~nEnd Method~nEnd Type~nType TOrdinaryValues~nField iterator:TOrdinaryIterator~nMethod ObjectEnumerator:TOrdinaryIterator()~nReturn iterator~nEnd Method~nEnd Type~nInterface ILegacyItem<T>~nEnd Interface~nType TLegacyIterator<T> Implements ILegacyItem<T>~nField value:Object~nMethod HasNext:Int()~nReturn False~nEnd Method~nMethod NextObject:Object()~nReturn value~nEnd Method~nEnd Type~nType TLegacyValues<T>~nField iterator:TLegacyIterator<T>~nMethod ObjectEnumerator:TLegacyIterator<T>()~nReturn iterator~nEnd Method~nEnd Type~nFunction ProbeLegacyEachIn<T>:T(value:T, legacy:TLegacyValues<T>)~nFor Local item:Object = EachIn legacy~nNext~nReturn value~nEnd Function~nFunction ProbeLegacyType<T>:T(value:T, legacy:TLegacyValues<T>)~nFor Local item:TLegacyIterator<T> = EachIn legacy~nNext~nReturn value~nEnd Function~nFunction ProbeLegacyInterface<T>:T(value:T, legacy:TLegacyValues<T>)~nFor Local item:ILegacyItem<T> = EachIn legacy~nNext~nReturn value~nEnd Function~nFunction ProbeOrdinaryType<T>:T(value:T, legacy:TLegacyValues<T>)~nFor Local item:TOrdinaryItem = EachIn legacy~nNext~nReturn value~nEnd Function~nFunction ProbeOrdinaryInterface<T>:T(value:T, legacy:TLegacyValues<T>)~nFor Local item:IOrdinaryItem = EachIn legacy~nNext~nReturn value~nEnd Function~nFunction ProbeOrdinaryReceivers<T>:T(value:T, legacy:TOrdinaryValues)~nFor Local item:Object = EachIn legacy~nNext~nReturn value~nEnd Function"
Local eachInLegacyModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/eachinlegacybody.mod/eachinlegacybody.bmx", eachInLegacyModuleSource, Null, compilerOptions)
Local eachInLegacyModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local eachInLegacyModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(eachInLegacyModuleCompilation, eachInLegacyModuleArtifactDiagnostics)
Local eachInLegacyModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local eachInLegacyModuleInterface:String = TBlitzMaxCompiler.EmitInterface(eachInLegacyModuleCompilation, eachInLegacyModuleInterfaceDiagnostics)
Check(eachInLegacyModuleCompilation.Succeeded() And eachInLegacyModuleArtifactDiagnostics.length = 0 And eachInLegacyModuleInterfaceDiagnostics.length = 0 And eachInLegacyModuleOutputs.length = 9, "module publishes source-free canonical ObjectEnumerator protocol, ordinary receiver slots, and generic/ordinary cast-target artifacts")
Local eachInLegacyModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
eachInLegacyModuleResolver.AddInterface("collections.eachinlegacybody", "sdk/collections.eachinlegacybody.i", eachInLegacyModuleInterface)
For Local eachInLegacyOutput:TCompilerGenericTemplateOutput = EachIn eachInLegacyModuleOutputs
	eachInLegacyModuleResolver.AddGenericTemplate(eachInLegacyOutput.artifactReference, "sdk/" + eachInLegacyOutput.artifactReference, eachInLegacyOutput.content)
	Check(Not eachInLegacyOutput.content.Contains("ObjectEnumerator:TLegacyIterator") And Not eachInLegacyOutput.content.Contains("EachIn legacy"), "generic ObjectEnumerator artifacts contain symbolic operations rather than source declarations or bodies")
Next
Local eachInLegacyConsumerSource:String = "SuperStrict~nImport Collections.EachInLegacyBody~nGlobal legacyIterator:TLegacyIterator<Int> = New TLegacyIterator<Int>~nGlobal legacyValues:TLegacyValues<Int> = New TLegacyValues<Int>~nlegacyValues.iterator = legacyIterator~nGlobal ordinaryValues:TOrdinaryValues~nGlobal importedLegacyValue:Int = ProbeLegacyEachIn(1, legacyValues)~nGlobal importedLegacyType:Int = ProbeLegacyType(1, legacyValues)~nGlobal importedLegacyInterface:Int = ProbeLegacyInterface(1, legacyValues)~nGlobal importedOrdinaryType:Int = ProbeOrdinaryType(1, legacyValues)~nGlobal importedOrdinaryInterface:Int = ProbeOrdinaryInterface(1, legacyValues)~nGlobal importedOrdinaryReceivers1:Int = ProbeOrdinaryReceivers(1, ordinaryValues)~nGlobal importedOrdinaryReceivers2:Int = ProbeOrdinaryReceivers<Int>(2, ordinaryValues)"
Local eachInLegacyConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-eachin-legacy-body-consumer.bmx", eachInLegacyConsumerSource, eachInLegacyModuleResolver, compilerOptions)
Check(eachInLegacyConsumerCompilation.Succeeded() And eachInLegacyConsumerCompilation.genericPlan.units.length = 9, "source-free imported generic ObjectEnumerator EachIn closes canonical/published-ordinary receiver and cast-target graphs: " + CompilationSummary(eachInLegacyConsumerCompilation))
Local importedLegacyEachInImplementation:String
Local importedLegacyTypeImplementation:String
Local importedLegacyInterfaceImplementation:String
Local importedOrdinaryTypeImplementation:String
Local importedOrdinaryInterfaceImplementation:String
Local importedOrdinaryReceiverImplementation:String
For Local importedLegacyEachInUnit:TCompilerGenericUnit = EachIn eachInLegacyConsumerCompilation.genericPlan.units
	If importedLegacyEachInUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeLegacyEachIn" Then importedLegacyEachInImplementation = importedLegacyEachInUnit.implementation
	If importedLegacyEachInUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeLegacyType" Then importedLegacyTypeImplementation = importedLegacyEachInUnit.implementation
	If importedLegacyEachInUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeLegacyInterface" Then importedLegacyInterfaceImplementation = importedLegacyEachInUnit.implementation
	If importedLegacyEachInUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeOrdinaryType" Then importedOrdinaryTypeImplementation = importedLegacyEachInUnit.implementation
	If importedLegacyEachInUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeOrdinaryInterface" Then importedOrdinaryInterfaceImplementation = importedLegacyEachInUnit.implementation
	If importedLegacyEachInUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeOrdinaryReceivers" Then importedOrdinaryReceiverImplementation = importedLegacyEachInUnit.implementation
Next
Check(importedLegacyEachInImplementation.Contains("->clas->m_objectenumerator_0") And importedLegacyEachInImplementation.Contains("->clas->m_hasnext_0") And importedLegacyEachInImplementation.Contains("->clas->m_nextobject_1") And importedLegacyEachInImplementation.Contains("(BBOBJECT)&bbNullObject"), "source-free imported ObjectEnumerator EachIn restores virtual operations and explicit null filtering")
Check(importedLegacyTypeImplementation.Contains("bbObjectDowncast") And importedLegacyInterfaceImplementation.Contains("bbInterfaceDowncast"), "source-free imported ObjectEnumerator EachIn restores canonical Type and Interface adaptation records")
Check(importedOrdinaryTypeImplementation.Contains("extern struct BBClass_collections_eachinlegacybody_TOrdinaryItem collections_eachinlegacybody_TOrdinaryItem;") And importedOrdinaryTypeImplementation.Contains("(BBClass *)&collections_eachinlegacybody_TOrdinaryItem"), "source-free imported ObjectEnumerator EachIn restores a published ordinary Type runtime identity")
Check(importedOrdinaryInterfaceImplementation.Contains("extern const struct BBInterface collections_eachinlegacybody_IOrdinaryItem_ifc;") And importedOrdinaryInterfaceImplementation.Contains("(BBINTERFACE)&collections_eachinlegacybody_IOrdinaryItem_ifc"), "source-free imported ObjectEnumerator EachIn restores a published ordinary Interface runtime identity")
Check(importedOrdinaryReceiverImplementation.Contains("->clas->vfns[0]") And importedOrdinaryReceiverImplementation.Contains("->clas->vfns[1]") And importedOrdinaryReceiverImplementation.Contains("struct collections_eachinlegacybody_TOrdinaryValues_obj *") And importedOrdinaryReceiverImplementation.Contains("struct collections_eachinlegacybody_TOrdinaryIterator_obj *") And Not importedOrdinaryReceiverImplementation.Contains(")))((BBObject *)"), "source-free imported ObjectEnumerator EachIn restores source-public ordinary receiver slot ordinals with balanced function-pointer casts and without class layout source")

Local ordinaryRuntimeModuleSource:String = "SuperStrict~nModule Values.RuntimeIdentity~nType TImportedItem~nEnd Type~nInterface IImportedItem~nEnd Interface~nType TRuntimeIterator~nField value:Object~nMethod Padding:Int()~nReturn 0~nEnd Method~nMethod HasNext:Int()~nReturn False~nEnd Method~nMethod NextObject:Object()~nReturn value~nEnd Method~nEnd Type~nType TRuntimeValues~nField iterator:TRuntimeIterator~nMethod Padding:Int()~nReturn 0~nEnd Method~nMethod ObjectEnumerator:TRuntimeIterator()~nReturn iterator~nEnd Method~nEnd Type"
Local ordinaryRuntimeModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/values.mod/runtimeidentity.mod/runtimeidentity.bmx", ordinaryRuntimeModuleSource, Null, compilerOptions)
Local ordinaryRuntimeInterfaceDiagnostics:TCompilerDiagnostic[]
Local ordinaryRuntimeInterface:String = TBlitzMaxCompiler.EmitInterface(ordinaryRuntimeModuleCompilation, ordinaryRuntimeInterfaceDiagnostics)
Check(ordinaryRuntimeModuleCompilation.Succeeded() And ordinaryRuntimeInterfaceDiagnostics.length = 0 And ordinaryRuntimeInterface.Contains("values_runtimeidentity_TImportedItem") And ordinaryRuntimeInterface.Contains("values_runtimeidentity_IImportedItem"), "ordinary dependency interface publishes stable Type and Interface linkage identities")
Local importedTargetProducerResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
importedTargetProducerResolver.AddInterface("values.runtimeidentity", "sdk/values.runtimeidentity.i", ordinaryRuntimeInterface)
Local importedTargetProducerSource:String = "SuperStrict~nModule Collections.ImportedRuntimeTarget~nImport Values.RuntimeIdentity~nType TImportedTargetIterator<T>~nField value:Object~nMethod HasNext:Int()~nReturn False~nEnd Method~nMethod NextObject:Object()~nReturn value~nEnd Method~nEnd Type~nType TImportedTargetValues<T>~nField iterator:TImportedTargetIterator<T>~nMethod ObjectEnumerator:TImportedTargetIterator<T>()~nReturn iterator~nEnd Method~nEnd Type~nType TImportedTargetProbe<T>~nMethod Probe:T(value:T, legacy:TImportedTargetValues<T>)~nFor Local item:TImportedItem = EachIn legacy~nNext~nReturn value~nEnd Method~nEnd Type~nFunction ProbeImportedType<T>:T(value:T, legacy:TImportedTargetValues<T>)~nFor Local item:TImportedItem = EachIn legacy~nNext~nReturn value~nEnd Function~nFunction ProbeImportedInterface<T>:T(value:T, legacy:TImportedTargetValues<T>)~nFor Local item:IImportedItem = EachIn legacy~nNext~nReturn value~nEnd Function~nFunction ProbeImportedReceivers<T>:T(value:T, legacy:TRuntimeValues)~nFor Local item:Object = EachIn legacy~nNext~nReturn value~nEnd Function"
Local importedTargetProducerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/importedruntimetarget.mod/importedruntimetarget.bmx", importedTargetProducerSource, importedTargetProducerResolver, compilerOptions)
Local importedTargetArtifactDiagnostics:TCompilerDiagnostic[]
Local importedTargetOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(importedTargetProducerCompilation, importedTargetArtifactDiagnostics)
Local importedTargetInterfaceDiagnostics:TCompilerDiagnostic[]
Local importedTargetInterface:String = TBlitzMaxCompiler.EmitInterface(importedTargetProducerCompilation, importedTargetInterfaceDiagnostics)
Check(importedTargetProducerCompilation.Succeeded() And importedTargetArtifactDiagnostics.length = 0 And importedTargetInterfaceDiagnostics.length = 0 And importedTargetOutputs.length = 6, "generic producer captures ordinary runtime identities and receiver slots imported from a dependency interface")
Local importedTargetConsumerResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
importedTargetConsumerResolver.AddInterface("values.runtimeidentity", "sdk/values.runtimeidentity.i", ordinaryRuntimeInterface)
importedTargetConsumerResolver.AddInterface("collections.importedruntimetarget", "sdk/collections.importedruntimetarget.i", importedTargetInterface)
For Local importedTargetOutput:TCompilerGenericTemplateOutput = EachIn importedTargetOutputs
	importedTargetConsumerResolver.AddGenericTemplate(importedTargetOutput.artifactReference, "sdk/" + importedTargetOutput.artifactReference, importedTargetOutput.content)
Next
Local importedTargetConsumerSource:String = "SuperStrict~nImport Collections.ImportedRuntimeTarget~nGlobal importedValues:TImportedTargetValues<Int> = New TImportedTargetValues<Int>~nGlobal importedProbe:TImportedTargetProbe<Int> = New TImportedTargetProbe<Int>~nGlobal runtimeValues:TRuntimeValues~nGlobal importedTypeResult:Int = ProbeImportedType(1, importedValues)~nGlobal importedInterfaceResult:Int = ProbeImportedInterface(2, importedValues)~nGlobal importedReceiverResult:Int = ProbeImportedReceivers(3, runtimeValues)"
Local importedTargetConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-imported-runtime-target-consumer.bmx", importedTargetConsumerSource, importedTargetConsumerResolver, compilerOptions)
Check(importedTargetConsumerCompilation.Succeeded() And importedTargetConsumerCompilation.genericPlan.units.length = 6, "source-free consumer closes generic requests containing dependency-published ordinary runtime identities and receiver slots: " + CompilationSummary(importedTargetConsumerCompilation))
Local importedDependencyTypeImplementation:String
Local importedDependencyInterfaceImplementation:String
Local importedDependencyTypeMethodImplementation:String
Local importedDependencyReceiverImplementation:String
For Local importedTargetUnit:TCompilerGenericUnit = EachIn importedTargetConsumerCompilation.genericPlan.units
	If importedTargetUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeImportedType" Then importedDependencyTypeImplementation = importedTargetUnit.implementation
	If importedTargetUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeImportedInterface" Then importedDependencyInterfaceImplementation = importedTargetUnit.implementation
	If importedTargetUnit.ir.specialization.artifact.identity.qualifiedName = "TImportedTargetProbe" Then importedDependencyTypeMethodImplementation = importedTargetUnit.implementation
	If importedTargetUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeImportedReceivers" Then importedDependencyReceiverImplementation = importedTargetUnit.implementation
Next
Check(importedDependencyTypeImplementation.Contains("(BBClass *)&values_runtimeidentity_TImportedItem") And importedDependencyInterfaceImplementation.Contains("(BBINTERFACE)&values_runtimeidentity_IImportedItem_ifc"), "imported ordinary runtime casts retain the dependency ABI instead of being remangled as producer symbols")
Check(importedDependencyTypeMethodImplementation.Contains("extern struct BBClass_values_runtimeidentity_TImportedItem values_runtimeidentity_TImportedItem;") And importedDependencyTypeMethodImplementation.Contains("(BBClass *)&values_runtimeidentity_TImportedItem"), "generic Type method units declare and use imported ordinary runtime identities independently of routine units")
Check(Not importedDependencyReceiverImplementation.Contains("->clas->vfns[0]") And importedDependencyReceiverImplementation.Contains("->clas->vfns[1]") And importedDependencyReceiverImplementation.Contains("->clas->vfns[2]") And importedDependencyReceiverImplementation.Contains("values_runtimeidentity_TRuntimeValues_obj") And importedDependencyReceiverImplementation.Contains("values_runtimeidentity_TRuntimeIterator_obj"), "dependency-imported ordinary ObjectEnumerator receivers preserve defining-module slot ordinals instead of deriving dispatch from method names")
Local inheritedOrdinaryReceiverSource:String = "SuperStrict~nModule Collections.InheritedOrdinaryReceiver~nType TIteratorBase~nField value:Object~nMethod Padding:Int()~nReturn 0~nEnd Method~nMethod HasNext:Int()~nReturn False~nEnd Method~nMethod NextObject:Object()~nReturn value~nEnd Method~nEnd Type~nType TInheritedIterator Extends TIteratorBase~nMethod HasNext:Int() Override~nReturn False~nEnd Method~nEnd Type~nType TOrdinaryBase~nMethod Padding:Int()~nReturn 0~nEnd Method~nMethod ObjectEnumerator:TInheritedIterator()~nReturn New TInheritedIterator~nEnd Method~nEnd Type~nType TOrdinaryDerived Extends TOrdinaryBase~nMethod ObjectEnumerator:TInheritedIterator() Override~nReturn New TInheritedIterator~nEnd Method~nEnd Type~nFunction ProbeInheritedOrdinary<T>:T(value:T, legacy:TOrdinaryDerived)~nFor Local item:Object = EachIn legacy~nNext~nReturn value~nEnd Function"
Local inheritedOrdinaryReceiverCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/inheritedordinaryreceiver.mod/inheritedordinaryreceiver.bmx", inheritedOrdinaryReceiverSource, Null, compilerOptions)
Local inheritedOrdinaryArtifactDiagnostics:TCompilerDiagnostic[]
Local inheritedOrdinaryOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(inheritedOrdinaryReceiverCompilation, inheritedOrdinaryArtifactDiagnostics)
Local inheritedOrdinaryInterfaceDiagnostics:TCompilerDiagnostic[]
Local inheritedOrdinaryInterface:String = TBlitzMaxCompiler.EmitInterface(inheritedOrdinaryReceiverCompilation, inheritedOrdinaryInterfaceDiagnostics)
Local inheritedOrdinaryResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
inheritedOrdinaryResolver.AddInterface("collections.inheritedordinaryreceiver", "sdk/collections.inheritedordinaryreceiver.i", inheritedOrdinaryInterface)
For Local inheritedOrdinaryOutput:TCompilerGenericTemplateOutput = EachIn inheritedOrdinaryOutputs
	inheritedOrdinaryResolver.AddGenericTemplate(inheritedOrdinaryOutput.artifactReference, "sdk/" + inheritedOrdinaryOutput.artifactReference, inheritedOrdinaryOutput.content)
Next
Local inheritedOrdinaryConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("inherited-ordinary-receiver-consumer.bmx", "SuperStrict~nImport Collections.InheritedOrdinaryReceiver~nGlobal inheritedOrdinary:TOrdinaryDerived~nGlobal inheritedOrdinaryResult:Int = ProbeInheritedOrdinary(1, inheritedOrdinary)", inheritedOrdinaryResolver, compilerOptions)
Check(inheritedOrdinaryReceiverCompilation.Succeeded() And inheritedOrdinaryArtifactDiagnostics.length = 0 And inheritedOrdinaryInterfaceDiagnostics.length = 0 And inheritedOrdinaryConsumer.Succeeded(), "published inherited ordinary ObjectEnumerator receivers round-trip without source: module " + CompilationSummary(inheritedOrdinaryReceiverCompilation) + "; consumer " + CompilationSummary(inheritedOrdinaryConsumer))
Local inheritedOrdinaryImplementation:String
For Local inheritedOrdinaryUnit:TCompilerGenericUnit = EachIn inheritedOrdinaryConsumer.genericPlan.units
	If inheritedOrdinaryUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeInheritedOrdinary" Then inheritedOrdinaryImplementation = inheritedOrdinaryUnit.implementation
Next
Check(inheritedOrdinaryImplementation.Contains("->clas->vfns[1]") And inheritedOrdinaryImplementation.Contains("->clas->vfns[2]"), "inherited and overridden ordinary operations preserve base slot ordinals while new base slots retain their prefix")

Local genericSuperModuleSource:String = "SuperStrict~nModule Collections.GenericSuper~nType TSuperBase<T>~nMethod Read:T(value:T)~nReturn value~nEnd Method~nMethod Invoke:T(value:T)~nReturn Self.Read(value)~nEnd Method~nEnd Type~nType TSuperDerived<T> Extends TSuperBase<T>~nMethod Read:T(value:T) Override~nReturn Super.Read(value + value)~nEnd Method~nEnd Type"
Local genericSuperModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/genericsuper.mod/genericsuper.bmx", genericSuperModuleSource, Null, compilerOptions)
Local genericSuperArtifactDiagnostics:TCompilerDiagnostic[]
Local genericSuperOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(genericSuperModuleCompilation, genericSuperArtifactDiagnostics)
Local genericSuperInterfaceDiagnostics:TCompilerDiagnostic[]
Local genericSuperInterface:String = TBlitzMaxCompiler.EmitInterface(genericSuperModuleCompilation, genericSuperInterfaceDiagnostics)
Check(genericSuperModuleCompilation.Succeeded() And genericSuperArtifactDiagnostics.length = 0 And genericSuperInterfaceDiagnostics.length = 0 And genericSuperOutputs.length = 2, "generic inheritance publishes typed Super receiver artifacts: " + CompilationSummary(genericSuperModuleCompilation))
Local genericSuperBaseArtifact:TGenericTemplateArtifact
Local genericSuperDerivedArtifact:TGenericTemplateArtifact
For Local genericSuperOutput:TCompilerGenericTemplateOutput = EachIn genericSuperOutputs
	If genericSuperOutput.artifact.identity.qualifiedName = "TSuperBase" Then genericSuperBaseArtifact = genericSuperOutput.artifact
	If genericSuperOutput.artifact.identity.qualifiedName = "TSuperDerived" Then genericSuperDerivedArtifact = genericSuperOutput.artifact
Next
Local genericSelfReceiverNode:TGenericTemplateNode
If genericSuperBaseArtifact And genericSuperBaseArtifact.members.length = 2 Then
	genericSelfReceiverNode = genericSuperBaseArtifact.members[1].body.children[0].children[0].children[0]
End If
Local genericSuperReceiverNode:TGenericTemplateNode
If genericSuperDerivedArtifact And genericSuperDerivedArtifact.members.length Then
	genericSuperReceiverNode = genericSuperDerivedArtifact.members[0].body.children[0].children[0].children[0]
End If
Check(genericSelfReceiverNode And genericSelfReceiverNode.kind = TEMPLATE_NODE_SELF And genericSelfReceiverNode.valueText = "self" And genericSelfReceiverNode.semanticType.CanonicalName().Contains("tsuperbase<!type:0>"), "the source-free template retains explicit typed Self identity for virtual slot dispatch")
Check(genericSuperReceiverNode And genericSuperReceiverNode.kind = TEMPLATE_NODE_SELF And genericSuperReceiverNode.valueText = "super" And genericSuperReceiverNode.semanticType.CanonicalName().Contains("tsuperbase<!type:0>"), "the source-free template retains explicit Super identity and its declaring base type")
Local genericSuperResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
genericSuperResolver.AddInterface("collections.genericsuper", "sdk/collections.genericsuper.i", genericSuperInterface)
For Local genericSuperOutput:TCompilerGenericTemplateOutput = EachIn genericSuperOutputs
	genericSuperResolver.AddGenericTemplate(genericSuperOutput.artifactReference, "sdk/" + genericSuperOutput.artifactReference, genericSuperOutput.content)
Next
Local genericSuperConsumerSource:String = "SuperStrict~nImport Collections.GenericSuper~nGlobal superDerived1:TSuperDerived<Int> = New TSuperDerived<Int>~nGlobal superDerived2:TSuperDerived<Int> = New TSuperDerived<Int>~nGlobal superResult1:Int = superDerived1.Invoke(21)~nGlobal superResult2:Int = superDerived2.Invoke(20)"
Local genericSuperConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-super-consumer.bmx", genericSuperConsumerSource, genericSuperResolver, compilerOptions)
Check(genericSuperConsumerCompilation.Succeeded() And genericSuperConsumerCompilation.genericPlan.registry.nodes.length = 2 And genericSuperConsumerCompilation.genericPlan.units.length = 2, "source-free consumers intern repeated derived requests, avoid a false recursive Self edge, and close the canonical Super edge once: " + CompilationSummary(genericSuperConsumerCompilation))
Local genericSuperBaseAbi:String
Local genericSuperBaseImplementation:String
Local genericSuperDerivedImplementation:String
For Local genericSuperUnit:TCompilerGenericUnit = EachIn genericSuperConsumerCompilation.genericPlan.units
	If genericSuperUnit.ir.specialization.artifact.identity.qualifiedName = "TSuperBase" Then
		genericSuperBaseAbi = genericSuperUnit.ir.specialization.readableAbiName
		genericSuperBaseImplementation = genericSuperUnit.implementation
	End If
	If genericSuperUnit.ir.specialization.artifact.identity.qualifiedName = "TSuperDerived" Then genericSuperDerivedImplementation = genericSuperUnit.implementation
Next
Check(genericSuperBaseAbi.length And genericSuperBaseImplementation.Contains("self->clas->m_read_0((struct " + genericSuperBaseAbi + "_obj *)self"), "generic Self calls dispatch through the canonical virtual slot so a derived override remains authoritative")
Check(genericSuperBaseAbi.length And genericSuperDerivedImplementation.Contains(genericSuperBaseAbi + "_Read") And genericSuperDerivedImplementation.Contains("struct " + genericSuperBaseAbi + "_obj *)self"), "specialized Super calls use the canonical declaring-base function and an explicit compatible receiver cast")
Local genericSelfRuntimeDiagnostics:TCompilerDiagnostic[]
Local genericSelfRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(genericSuperConsumerCompilation, genericSelfRuntimeDiagnostics)
Check(genericSelfRuntimeDiagnostics.length = 0 And genericSelfRuntimeC.Contains("->clas->m_invoke_1") And genericSelfRuntimeC.Contains("#ifndef BMX_GENERIC_CLASS_" + genericSuperBaseAbi.ToUpper()), "application IR calls the inherited generic method through the compatible canonical derived class slot and guards canonical layouts shared with module headers")
Local genericSelfVarSource:String = "SuperStrict~nType TSelfVar<T>~nMethod Choose:T(value:T Var)~nReturn value~nEnd Method~nMethod Invoke:T(value:T)~nReturn Self.Choose(value)~nEnd Method~nEnd Type~nGlobal selfVar:TSelfVar<Int>"
Local genericSelfVarCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-self-var.bmx", genericSelfVarSource, Null, compilerOptions)
Local genericSelfVarImplementation:String = genericSelfVarCompilation.genericPlan.units[0].implementation
Check(genericSelfVarCompilation.Succeeded() And genericSelfVarImplementation.Contains("BBINT * value") And genericSelfVarImplementation.Contains("(&(value))") And genericSelfVarImplementation.Contains("return (*value);"), "generic Self calls preserve the selected Var slot ABI and pass a retained addressable argument")

Local mixedReceiverModuleSource:String = "SuperStrict~nModule Collections.MixedObjectEnumerator~nType TMixedOrdinaryIterator~nField value:Object~nMethod HasNext:Int()~nReturn False~nEnd Method~nMethod NextObject:Object()~nReturn value~nEnd Method~nEnd Type~nType TMixedGenericValues<T>~nMethod ObjectEnumerator:TMixedOrdinaryIterator()~nReturn Null~nEnd Method~nEnd Type~nType TMixedGenericIterator<T>~nMethod HasNext:Int()~nReturn False~nEnd Method~nMethod NextObject:Object()~nReturn Null~nEnd Method~nEnd Type~nType TMixedOrdinaryValues~nField iterator:TMixedGenericIterator<Int>~nMethod ObjectEnumerator:TMixedGenericIterator<Int>()~nReturn iterator~nEnd Method~nEnd Type~nFunction ProbeGenericCollection<T>:T(value:T, legacy:TMixedGenericValues<T>)~nFor Local item:Object = EachIn legacy~nNext~nReturn value~nEnd Function~nFunction ProbeOrdinaryCollection<T>:T(value:T, legacy:TMixedOrdinaryValues)~nFor Local item:Object = EachIn legacy~nNext~nReturn value~nEnd Function~nGlobal mixedOrdinaryValues:TMixedOrdinaryValues~nGlobal mixedOrdinaryResult:Int = ProbeOrdinaryCollection(2, mixedOrdinaryValues)"
Local mixedReceiverModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/mixedobjectenumerator.mod/mixedobjectenumerator.bmx", mixedReceiverModuleSource, Null, compilerOptions)
Local mixedReceiverArtifactDiagnostics:TCompilerDiagnostic[]
Local mixedReceiverOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(mixedReceiverModuleCompilation, mixedReceiverArtifactDiagnostics)
Local mixedReceiverInterfaceDiagnostics:TCompilerDiagnostic[]
Local mixedReceiverInterface:String = TBlitzMaxCompiler.EmitInterface(mixedReceiverModuleCompilation, mixedReceiverInterfaceDiagnostics)
Local mixedReceiverResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
mixedReceiverResolver.AddInterface("collections.mixedobjectenumerator", "sdk/collections.mixedobjectenumerator.i", mixedReceiverInterface)
For Local mixedReceiverOutput:TCompilerGenericTemplateOutput = EachIn mixedReceiverOutputs
	mixedReceiverResolver.AddGenericTemplate(mixedReceiverOutput.artifactReference, "sdk/" + mixedReceiverOutput.artifactReference, mixedReceiverOutput.content)
Next
Local mixedReceiverConsumerSource:String = "SuperStrict~nImport Collections.MixedObjectEnumerator~nGlobal mixedGenericValues:TMixedGenericValues<Int> = New TMixedGenericValues<Int>~nGlobal mixedGenericResult:Int = ProbeGenericCollection(1, mixedGenericValues)"
Local mixedReceiverConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("mixed-object-enumerator-consumer.bmx", mixedReceiverConsumerSource, mixedReceiverResolver, compilerOptions)
Check(mixedReceiverModuleCompilation.Succeeded() And mixedReceiverArtifactDiagnostics.length = 0 And mixedReceiverInterfaceDiagnostics.length = 0 And mixedReceiverConsumer.Succeeded(), "source-free ObjectEnumerator planning supports both mixed generic/ordinary receiver directions: module " + CompilationSummary(mixedReceiverModuleCompilation) + "; consumer " + CompilationSummary(mixedReceiverConsumer))
Local mixedGenericCollectionImplementation:String
Local mixedOrdinaryCollectionImplementation:String
For Local mixedReceiverUnit:TCompilerGenericUnit = EachIn mixedReceiverConsumer.genericPlan.units
	If mixedReceiverUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeGenericCollection" Then mixedGenericCollectionImplementation = mixedReceiverUnit.implementation
Next
For Local mixedReceiverModuleUnit:TCompilerGenericUnit = EachIn mixedReceiverModuleCompilation.genericPlan.units
	If mixedReceiverModuleUnit.ir.specialization.artifact.identity.qualifiedName = "ProbeOrdinaryCollection" Then mixedOrdinaryCollectionImplementation = mixedReceiverModuleUnit.implementation
Next
Check(mixedGenericCollectionImplementation.Contains("->clas->m_objectenumerator_0") And mixedGenericCollectionImplementation.Contains("->clas->vfns[0]") And mixedGenericCollectionImplementation.Contains("->clas->vfns[1]"), "canonical generic collection dispatch can hand off to a published ordinary iterator")
Check(mixedOrdinaryCollectionImplementation.Contains("->clas->vfns[0]") And mixedOrdinaryCollectionImplementation.Contains("->clas->m_hasnext_0") And mixedOrdinaryCollectionImplementation.Contains("->clas->m_nextobject_1"), "published ordinary collection dispatch can hand off to a canonical generic iterator")

Local ordinaryGenericMemberModuleSource:String = "SuperStrict~nModule Collections.OrdinaryGenericMembers~nType TBox<T>~nField value:T~nMethod Get:T()~nReturn value~nEnd Method~nEnd Type~nType THolder~nField box:TBox<Int>~nMethod GetBox:TBox<Int>()~nReturn box~nEnd Method~nMethod SetBox(value:TBox<Int>)~nbox = value~nEnd Method~nEnd Type"
Local ordinaryGenericMemberModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/ordinarygenericmembers.mod/ordinarygenericmembers.bmx", ordinaryGenericMemberModuleSource, Null, compilerOptions)
Local ordinaryGenericMemberArtifactDiagnostics:TCompilerDiagnostic[]
Local ordinaryGenericMemberOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(ordinaryGenericMemberModuleCompilation, ordinaryGenericMemberArtifactDiagnostics)
Local ordinaryGenericMemberInterfaceDiagnostics:TCompilerDiagnostic[]
Local ordinaryGenericMemberInterface:String = TBlitzMaxCompiler.EmitInterface(ordinaryGenericMemberModuleCompilation, ordinaryGenericMemberInterfaceDiagnostics)
Check(ordinaryGenericMemberModuleCompilation.Succeeded() And ordinaryGenericMemberArtifactDiagnostics.length = 0 And ordinaryGenericMemberInterfaceDiagnostics.length = 0 And ordinaryGenericMemberOutputs.length = 1, "ordinary Type members can publish closed canonical generic signatures: " + CompilationSummary(ordinaryGenericMemberModuleCompilation))
Check(ordinaryGenericMemberInterface.Contains(".box:TBox<Int>") And ordinaryGenericMemberInterface.Contains("GetBox:TBox<Int>()") And ordinaryGenericMemberInterface.Contains("SetBox(value:TBox<Int>)"), "compact interfaces preserve canonical generic arguments in ordinary field, return, and parameter signatures")
Local ordinaryGenericMemberResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
ordinaryGenericMemberResolver.AddInterface("collections.ordinarygenericmembers", "sdk/collections.ordinarygenericmembers.i", ordinaryGenericMemberInterface)
ordinaryGenericMemberResolver.AddGenericTemplate(ordinaryGenericMemberOutputs[0].artifactReference, "sdk/" + ordinaryGenericMemberOutputs[0].artifactReference, ordinaryGenericMemberOutputs[0].content)
Local ordinaryGenericMemberConsumerSource:String = "SuperStrict~nImport Collections.OrdinaryGenericMembers~nGlobal sharedBox:TBox<Int> = New TBox<Int>~nGlobal holder:THolder~nholder.box = sharedBox~nholder.SetBox(sharedBox)~nGlobal returnedBox:TBox<Int> = holder.GetBox()~nGlobal returnedValue:Int = returnedBox.Get()"
Local ordinaryGenericMemberConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("ordinary-generic-member-consumer.bmx", ordinaryGenericMemberConsumerSource, ordinaryGenericMemberResolver, compilerOptions)
Check(ordinaryGenericMemberConsumerCompilation.Succeeded() And ordinaryGenericMemberConsumerCompilation.genericPlan.registry.nodes.length = 1 And ordinaryGenericMemberConsumerCompilation.genericPlan.units.length = 1, "source-free imported ordinary fields, parameters, and returns share one canonical generic specialization: " + CompilationSummary(ordinaryGenericMemberConsumerCompilation))
Local ordinaryGenericMemberImportedHolder:TCompilerIrImportedClass
For Local ordinaryGenericMemberImportedClass:TCompilerIrImportedClass = EachIn ordinaryGenericMemberConsumerCompilation.ir.importedClasses
	If ordinaryGenericMemberImportedClass.name = "THolder" Then ordinaryGenericMemberImportedHolder = ordinaryGenericMemberImportedClass
Next
Check(ordinaryGenericMemberImportedHolder And ordinaryGenericMemberImportedHolder.fields.length = 1 And ordinaryGenericMemberImportedHolder.fields[0].semanticType = "TBox<Int>" And ordinaryGenericMemberImportedHolder.methods.length = 2 And ordinaryGenericMemberImportedHolder.methods[0].returnType = "TBox<Int>" And ordinaryGenericMemberImportedHolder.methods[1].parameters[0].semanticType = "TBox<Int>", "imported ordinary ABI records retain the canonical constructed type rather than an open nominal name")
Local ordinaryGenericMemberRuntimeDiagnostics:TCompilerDiagnostic[]
Local ordinaryGenericMemberRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(ordinaryGenericMemberConsumerCompilation, ordinaryGenericMemberRuntimeDiagnostics)
Local ordinaryGenericMemberAbiName:String = ordinaryGenericMemberConsumerCompilation.genericPlan.registry.nodes[0].readableAbiName
Check(ordinaryGenericMemberRuntimeDiagnostics.length = 0 And ordinaryGenericMemberRuntimeC.Contains("struct " + ordinaryGenericMemberAbiName + "_obj *"), "ordinary imported member declarations and calls use the canonical specialization C ABI")

Local nominalGenericSignatureModuleSource:String = "SuperStrict~nModule Collections.SignatureBox~nType TSignatureBox<T>~nField value:T~nMethod Get:T()~nReturn value~nEnd Method~nEnd Type"
Local nominalGenericSignatureModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/signaturebox.mod/signaturebox.bmx", nominalGenericSignatureModuleSource, Null, compilerOptions)
Local nominalGenericSignatureArtifactDiagnostics:TCompilerDiagnostic[]
Local nominalGenericSignatureOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(nominalGenericSignatureModuleCompilation, nominalGenericSignatureArtifactDiagnostics)
Local nominalGenericSignatureInterfaceDiagnostics:TCompilerDiagnostic[]
Local nominalGenericSignatureInterface:String = TBlitzMaxCompiler.EmitInterface(nominalGenericSignatureModuleCompilation, nominalGenericSignatureInterfaceDiagnostics)
Local nominalGenericSignatureResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
nominalGenericSignatureResolver.AddInterface("collections.signaturebox", "sdk/collections.signaturebox.i", nominalGenericSignatureInterface)
For Local nominalGenericSignatureOutput:TCompilerGenericTemplateOutput = EachIn nominalGenericSignatureOutputs
	nominalGenericSignatureResolver.AddGenericTemplate(nominalGenericSignatureOutput.artifactReference, "sdk/" + nominalGenericSignatureOutput.artifactReference, nominalGenericSignatureOutput.content)
Next
Local nominalGenericSignatureSourceOptions:TCompilerOptions = TCompilerOptions.CreateDefault()
nominalGenericSignatureSourceOptions.requireCoreInterface = False
nominalGenericSignatureSourceOptions.targetPlatform = "test"
nominalGenericSignatureSourceOptions.targetArchitecture = "x64"
nominalGenericSignatureSourceOptions.conditionalSymbols = ["bmxng", "ptr64"]
nominalGenericSignatureSourceOptions.sourceModuleName = "net.nominalgenericsignatures"
Local nominalGenericSignatureSource:String = "SuperStrict~nImport Collections.SignatureBox~nType TSignatureItem~nField value:Int~nEnd Type~nType TSignatureOwner~nMethod Ping:Int()~nReturn 42~nEnd Method~nMethod Items:TSignatureBox<TSignatureItem>()~nReturn Null~nEnd Method~nMethod Replace(value:TSignatureBox<TSignatureItem>)~nEnd Method~nEnd Type"
Local nominalGenericSignatureSourceCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/net.mod/nominalgenericsignatures.mod/signature_owner.bmx", nominalGenericSignatureSource, nominalGenericSignatureResolver, nominalGenericSignatureSourceOptions)
Local nominalGenericSignatureSourceInterfaceDiagnostics:TCompilerDiagnostic[]
Local nominalGenericSignatureSourceInterface:String = TBlitzMaxCompiler.EmitInterface(nominalGenericSignatureSourceCompilation, nominalGenericSignatureSourceInterfaceDiagnostics)
nominalGenericSignatureResolver.AddInterface("signature_owner.bmx", "sdk/mod/net.mod/nominalgenericsignatures.mod/.bmx/signature_owner.bmx.release.test.x64.i", nominalGenericSignatureSourceInterface)
nominalGenericSignatureResolver.AddInterface("net.nominalgenericsignatures", "sdk/net.nominalgenericsignatures.i", "SuperStrict~nImport ~qsignature_owner.bmx~q")
Local nominalGenericSignatureConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("nominal-generic-signature-consumer.bmx", "SuperStrict~nImport Net.NominalGenericSignatures~nLocal owner:TSignatureOwner = New TSignatureOwner~nLocal result:Int = owner.Ping()", nominalGenericSignatureResolver, compilerOptions)
Check(nominalGenericSignatureModuleCompilation.Succeeded() And nominalGenericSignatureSourceCompilation.Succeeded() And nominalGenericSignatureArtifactDiagnostics.length = 0 And nominalGenericSignatureInterfaceDiagnostics.length = 0 And nominalGenericSignatureSourceInterfaceDiagnostics.length = 0 And nominalGenericSignatureConsumer.Succeeded(), "an imported ordinary Type accepts closed generic method signatures whose argument belongs to a secondary source of the owning module, even when the consumer does not call those methods: template " + CompilationSummary(nominalGenericSignatureModuleCompilation) + "; owner " + CompilationSummary(nominalGenericSignatureSourceCompilation) + "; consumer " + CompilationSummary(nominalGenericSignatureConsumer))
Check(nominalGenericSignatureConsumer.genericPlan.registry.nodes.length = 1 And nominalGenericSignatureConsumer.genericPlan.registry.nodes[0].key.typeArguments[0].CanonicalName() = "net.nominalgenericsignatures::tsignatureitem", "a hidden source-interface scope does not create a second physical-file generic identity alongside its owning logical module")

Local ordinaryClosedBaseModuleSource:String = "SuperStrict~nModule Collections.OrdinaryClosedBase~nType TClosedBase<T>~nField value:T~nMethod Read:T()~nReturn value~nEnd Method~nMethod Marker:Int()~nReturn 1~nEnd Method~nEnd Type~nType TStringDerived Extends TClosedBase<String>~nField extra:String~nMethod Marker:Int() Override~nReturn 2~nEnd Method~nMethod ExtraValue:String()~nReturn extra~nEnd Method~nEnd Type"
Local ordinaryClosedBaseModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/ordinaryclosedbase.mod/ordinaryclosedbase.bmx", ordinaryClosedBaseModuleSource, Null, compilerOptions)
Local ordinaryClosedBaseArtifactDiagnostics:TCompilerDiagnostic[]
Local ordinaryClosedBaseOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(ordinaryClosedBaseModuleCompilation, ordinaryClosedBaseArtifactDiagnostics)
Local ordinaryClosedBaseInterfaceDiagnostics:TCompilerDiagnostic[]
Local ordinaryClosedBaseInterface:String = TBlitzMaxCompiler.EmitInterface(ordinaryClosedBaseModuleCompilation, ordinaryClosedBaseInterfaceDiagnostics)
Check(ordinaryClosedBaseModuleCompilation.Succeeded() And ordinaryClosedBaseArtifactDiagnostics.length = 0 And ordinaryClosedBaseInterfaceDiagnostics.length = 0 And ordinaryClosedBaseOutputs.length = 1, "ordinary Type inheritance can close a canonical generic base: " + CompilationSummary(ordinaryClosedBaseModuleCompilation))
Check(ordinaryClosedBaseInterface.Contains("TStringDerived^TClosedBase<String>{"), "compact ordinary Type headers preserve their closed canonical generic base")
Local ordinaryClosedBaseProducerRuntimeDiagnostics:TCompilerDiagnostic[]
Local ordinaryClosedBaseProducerRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(ordinaryClosedBaseModuleCompilation, ordinaryClosedBaseProducerRuntimeDiagnostics)
Local ordinaryClosedBaseAbiName:String = ordinaryClosedBaseModuleCompilation.genericPlan.registry.nodes[0].readableAbiName
Check(ordinaryClosedBaseProducerRuntimeDiagnostics.length = 0 And ordinaryClosedBaseProducerRuntimeC.Contains("(BBClass *)&" + ordinaryClosedBaseAbiName) And ordinaryClosedBaseProducerRuntimeC.Contains(ordinaryClosedBaseAbiName + ".ctor"), "ordinary derived C layout, descriptor, and construction delegate to the canonical generic base ABI")
Local ordinaryClosedBaseResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
ordinaryClosedBaseResolver.AddInterface("collections.ordinaryclosedbase", "sdk/collections.ordinaryclosedbase.i", ordinaryClosedBaseInterface)
ordinaryClosedBaseResolver.AddGenericTemplate(ordinaryClosedBaseOutputs[0].artifactReference, "sdk/" + ordinaryClosedBaseOutputs[0].artifactReference, ordinaryClosedBaseOutputs[0].content)
Local ordinaryClosedBaseConsumerSource:String = "SuperStrict~nImport Collections.OrdinaryClosedBase~nGlobal closedDerived:TStringDerived~nclosedDerived.value = ~qbase~q~nclosedDerived.extra = ~qextra~q~nGlobal closedInherited:String = closedDerived.Read()~nGlobal closedOverride:Int = closedDerived.Marker()~nGlobal closedExtra:String = closedDerived.ExtraValue()"
Local ordinaryClosedBaseConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("ordinary-closed-base-consumer.bmx", ordinaryClosedBaseConsumerSource, ordinaryClosedBaseResolver, compilerOptions)
Check(ordinaryClosedBaseConsumerCompilation.Succeeded() And ordinaryClosedBaseConsumerCompilation.genericPlan.registry.nodes.length = 1 And ordinaryClosedBaseConsumerCompilation.genericPlan.units.length = 1, "source-free ordinary derived Types reconnect to one canonical generic base specialization: " + CompilationSummary(ordinaryClosedBaseConsumerCompilation))
Local ordinaryClosedBaseImportedDerived:TCompilerIrImportedClass
For Local ordinaryClosedBaseImportedClass:TCompilerIrImportedClass = EachIn ordinaryClosedBaseConsumerCompilation.ir.importedClasses
	If ordinaryClosedBaseImportedClass.name = "TStringDerived" Then ordinaryClosedBaseImportedDerived = ordinaryClosedBaseImportedClass
Next
Check(ordinaryClosedBaseImportedDerived And ordinaryClosedBaseImportedDerived.baseImportedClassId.length And ordinaryClosedBaseImportedDerived.fields.length = 2 And ordinaryClosedBaseImportedDerived.functionSlots.length = 3, "source-free ordinary derived ABI reconstructs the generic base field and slot prefixes")
Check(ordinaryClosedBaseImportedDerived.functionSlots[0].slotName = "m_read_0" And ordinaryClosedBaseImportedDerived.functionSlots[1].slotName = "m_marker_1" And ordinaryClosedBaseImportedDerived.functionSlots[2].name = "ExtraValue", "exact ordinary override replaces its canonical generic base slot while new methods append")
Local ordinaryClosedBaseConsumerRuntimeDiagnostics:TCompilerDiagnostic[]
Local ordinaryClosedBaseConsumerRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(ordinaryClosedBaseConsumerCompilation, ordinaryClosedBaseConsumerRuntimeDiagnostics)
Check(ordinaryClosedBaseConsumerRuntimeDiagnostics.length = 0, "source-free closed-base consumer C emits without diagnostics")
Check(ordinaryClosedBaseConsumerRuntimeC.Contains("->clas->m_read_0"), "source-free consumers dispatch inherited methods through the canonical generic slot")
Check(ordinaryClosedBaseConsumerRuntimeC.Contains("->clas->m_marker_1"), "source-free consumers dispatch ordinary overrides through the replaced canonical generic slot")
Local ordinaryClosedBaseRepeatCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/ordinaryclosedbase.mod/ordinaryclosedbase.bmx", ordinaryClosedBaseModuleSource, Null, compilerOptions)
Local ordinaryClosedBaseRepeatInterfaceDiagnostics:TCompilerDiagnostic[]
Local ordinaryClosedBaseRepeatInterface:String = TBlitzMaxCompiler.EmitInterface(ordinaryClosedBaseRepeatCompilation, ordinaryClosedBaseRepeatInterfaceDiagnostics)
Check(ordinaryClosedBaseRepeatCompilation.Succeeded() And ordinaryClosedBaseRepeatInterfaceDiagnostics.length = 0 And ordinaryClosedBaseRepeatInterface = ordinaryClosedBaseInterface And ordinaryClosedBaseRepeatCompilation.genericPlan.registry.nodes[0].identityDigest = ordinaryClosedBaseModuleCompilation.genericPlan.registry.nodes[0].identityDigest, "closed generic ordinary inheritance is deterministic across repeated publication")
Local ordinaryClosedBaseCollisionSource:String = "SuperStrict~nType TCollisionBase<T>~nField value:T~nEnd Type~nType TStringCollision Extends TCollisionBase<String>~nEnd Type~nType TIntCollision Extends TCollisionBase<Int>~nEnd Type"
Local ordinaryClosedBaseCollisionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("ordinary-closed-base-collision.bmx", ordinaryClosedBaseCollisionSource, Null, compilerOptions)
Check(ordinaryClosedBaseCollisionCompilation.Succeeded() And ordinaryClosedBaseCollisionCompilation.genericPlan.registry.nodes.length = 2 And ordinaryClosedBaseCollisionCompilation.genericPlan.registry.nodes[0].identityDigest <> ordinaryClosedBaseCollisionCompilation.genericPlan.registry.nodes[1].identityDigest And ordinaryClosedBaseCollisionCompilation.genericPlan.registry.nodes[0].readableAbiName <> ordinaryClosedBaseCollisionCompilation.genericPlan.registry.nodes[1].readableAbiName, "ordinary bases closed over different arguments retain collision-resistant canonical identities")

Local ordinaryClosedInterfaceModuleSource:String = "SuperStrict~nModule Collections.OrdinaryClosedInterface~nInterface IClosedRoot<T>~nMethod Read:T()~nEnd Interface~nInterface IClosedExtended<T> Extends IClosedRoot<T>~nMethod Extra:T()~nEnd Interface~nType TStringValue Implements IClosedExtended<String>~nField value:String~nMethod Read:String()~nReturn value~nEnd Method~nMethod Extra:String()~nReturn value~nEnd Method~nEnd Type"
Local ordinaryClosedInterfaceModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/ordinaryclosedinterface.mod/ordinaryclosedinterface.bmx", ordinaryClosedInterfaceModuleSource, Null, compilerOptions)
Local ordinaryClosedInterfaceArtifactDiagnostics:TCompilerDiagnostic[]
Local ordinaryClosedInterfaceOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(ordinaryClosedInterfaceModuleCompilation, ordinaryClosedInterfaceArtifactDiagnostics)
Local ordinaryClosedInterfaceInterfaceDiagnostics:TCompilerDiagnostic[]
Local ordinaryClosedInterfaceInterface:String = TBlitzMaxCompiler.EmitInterface(ordinaryClosedInterfaceModuleCompilation, ordinaryClosedInterfaceInterfaceDiagnostics)
Check(ordinaryClosedInterfaceModuleCompilation.Succeeded() And ordinaryClosedInterfaceArtifactDiagnostics.length = 0 And ordinaryClosedInterfaceInterfaceDiagnostics.length = 0 And ordinaryClosedInterfaceOutputs.length = 2 And ordinaryClosedInterfaceModuleCompilation.genericPlan.registry.nodes.length = 2, "ordinary Types can implement a canonical generic Interface closure: " + CompilationSummary(ordinaryClosedInterfaceModuleCompilation))
Check(ordinaryClosedInterfaceInterface.Contains("TStringValue^Object@IClosedExtended<String>{"), "compact ordinary Type headers preserve their closed canonical Implements identity")
Local ordinaryClosedInterfaceSourceClass:TCompilerIrClass
For Local ordinaryClosedInterfaceClass:TCompilerIrClass = EachIn ordinaryClosedInterfaceModuleCompilation.ir.classes
	If ordinaryClosedInterfaceClass.name = "TStringValue" Then ordinaryClosedInterfaceSourceClass = ordinaryClosedInterfaceClass
Next
Check(ordinaryClosedInterfaceSourceClass And ordinaryClosedInterfaceSourceClass.interfaceImplementations.length = 2, "ordinary implementation IR owns separate tables for the canonical root and derived Interfaces")
Local ordinaryClosedInterfaceProducerRuntimeDiagnostics:TCompilerDiagnostic[]
Local ordinaryClosedInterfaceProducerRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(ordinaryClosedInterfaceModuleCompilation, ordinaryClosedInterfaceProducerRuntimeDiagnostics)
Check(ordinaryClosedInterfaceProducerRuntimeDiagnostics.length = 0 And ordinaryClosedInterfaceProducerRuntimeC.Contains(", 2 };") And ordinaryClosedInterfaceProducerRuntimeC.Contains("m_read_0") And ordinaryClosedInterfaceProducerRuntimeC.Contains("m_extra_1"), "ordinary class C emits the complete canonical generic Interface table closure")
Local ordinaryClosedInterfaceResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
ordinaryClosedInterfaceResolver.AddInterface("collections.ordinaryclosedinterface", "sdk/collections.ordinaryclosedinterface.i", ordinaryClosedInterfaceInterface)
For Local ordinaryClosedInterfaceOutput:TCompilerGenericTemplateOutput = EachIn ordinaryClosedInterfaceOutputs
	ordinaryClosedInterfaceResolver.AddGenericTemplate(ordinaryClosedInterfaceOutput.artifactReference, "sdk/" + ordinaryClosedInterfaceOutput.artifactReference, ordinaryClosedInterfaceOutput.content)
Next
Local ordinaryClosedInterfaceConsumerSource:String = "SuperStrict~nImport Collections.OrdinaryClosedInterface~nGlobal closedConcrete:TStringValue~nGlobal closedRoot:IClosedRoot<String> = closedConcrete~nGlobal closedExtended:IClosedExtended<String> = closedConcrete~nGlobal closedRead:String = closedRoot.Read()~nGlobal closedExtra:String = closedExtended.Extra()"
Local ordinaryClosedInterfaceConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("ordinary-closed-interface-consumer.bmx", ordinaryClosedInterfaceConsumerSource, ordinaryClosedInterfaceResolver, compilerOptions)
Check(ordinaryClosedInterfaceConsumerCompilation.Succeeded() And ordinaryClosedInterfaceConsumerCompilation.genericPlan.registry.nodes.length = 2 And ordinaryClosedInterfaceConsumerCompilation.genericPlan.units.length = 2, "source-free consumers reconnect ordinary implementations to canonical generic Interface identities: " + CompilationSummary(ordinaryClosedInterfaceConsumerCompilation))
Local ordinaryClosedInterfaceConsumerRuntimeDiagnostics:TCompilerDiagnostic[]
Local ordinaryClosedInterfaceConsumerRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(ordinaryClosedInterfaceConsumerCompilation, ordinaryClosedInterfaceConsumerRuntimeDiagnostics)
Check(ordinaryClosedInterfaceConsumerRuntimeDiagnostics.length = 0 And ordinaryClosedInterfaceConsumerRuntimeC.Contains("bbObjectInterface") And ordinaryClosedInterfaceConsumerRuntimeC.Contains("m_read_0") And ordinaryClosedInterfaceConsumerRuntimeC.Contains("m_extra_1"), "source-free ordinary values dispatch through canonical root and derived Interface descriptors")
Local ordinaryClosedInterfaceRepeatCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/ordinaryclosedinterface.mod/ordinaryclosedinterface.bmx", ordinaryClosedInterfaceModuleSource, Null, compilerOptions)
Local ordinaryClosedInterfaceRepeatDiagnostics:TCompilerDiagnostic[]
Local ordinaryClosedInterfaceRepeat:String = TBlitzMaxCompiler.EmitInterface(ordinaryClosedInterfaceRepeatCompilation, ordinaryClosedInterfaceRepeatDiagnostics)
Check(ordinaryClosedInterfaceRepeatCompilation.Succeeded() And ordinaryClosedInterfaceRepeatDiagnostics.length = 0 And ordinaryClosedInterfaceRepeat = ordinaryClosedInterfaceInterface, "ordinary closed generic Interface publication is deterministic")
Local ordinaryClosedInterfaceCollisionSource:String = "SuperStrict~nInterface IArgumentValue<T>~nMethod Read:T()~nEnd Interface~nType TStringArgumentValue Implements IArgumentValue<String>~nMethod Read:String()~nReturn ~qstring~q~nEnd Method~nEnd Type~nType TIntArgumentValue Implements IArgumentValue<Int>~nMethod Read:Int()~nReturn 1~nEnd Method~nEnd Type"
Local ordinaryClosedInterfaceCollisionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("ordinary-closed-interface-collision.bmx", ordinaryClosedInterfaceCollisionSource, Null, compilerOptions)
Check(ordinaryClosedInterfaceCollisionCompilation.Succeeded() And ordinaryClosedInterfaceCollisionCompilation.genericPlan.registry.nodes.length = 2 And ordinaryClosedInterfaceCollisionCompilation.genericPlan.registry.nodes[0].identityDigest <> ordinaryClosedInterfaceCollisionCompilation.genericPlan.registry.nodes[1].identityDigest, "ordinary implementations over different Interface arguments retain distinct canonical identities")
Local ordinaryClosedInterfaceMissingSource:String = "SuperStrict~nInterface IRequiredValue<T>~nMethod Read:T()~nEnd Interface~nType TMissingValue Implements IRequiredValue<String>~nEnd Type~nGlobal missingValue:TMissingValue"
Local ordinaryClosedInterfaceMissingCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("ordinary-closed-interface-missing.bmx", ordinaryClosedInterfaceMissingSource, Null, compilerOptions)
Check(HasCompilerDiagnostic(ordinaryClosedInterfaceMissingCompilation, "BMXC1164"), "ordinary closed generic Interface implementations diagnose missing methods instead of emitting an incomplete table")

Local transitiveSource:String = "SuperStrict~nType TLeaf<T>~nField value:T~nMethod First:T()~nReturn value~nEnd Method~nEnd Type~nType THolder<T>~nField leaf:TLeaf<T>~nMethod Get:TLeaf<T>()~nReturn leaf~nEnd Method~nEnd Type~nGlobal holder:THolder<String>"
Local transitiveCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("transitive-generics.bmx", transitiveSource, Null, compilerOptions)
Check(transitiveCompilation.Succeeded() And transitiveCompilation.genericPlan.registry.nodes.length = 2 And transitiveCompilation.genericPlan.units.length = 2, "a constructed generic field expands one transitive specialization without a source-level leaf request")
Local holderNode:TGenericSpecializationNode
Local leafNode:TGenericSpecializationNode
For Local candidate:TGenericSpecializationNode = EachIn transitiveCompilation.genericPlan.registry.nodes
	If candidate.artifact.identity.qualifiedName = "THolder" Then holderNode = candidate
	If candidate.artifact.identity.qualifiedName = "TLeaf" Then leafNode = candidate
Next
Check(holderNode And leafNode, "transitive planning retains both canonical specialization nodes")
Local canonicalTransitiveEdges:Int = holderNode.outgoing.length > 0
For Local edge:TGenericSpecializationEdge = EachIn holderNode.outgoing
	If edge.target <> leafNode Then canonicalTransitiveEdges = False
Next
Check(canonicalTransitiveEdges, "transitive planning records every field/signature/body request against one canonical holder-to-leaf target")
Local canonicalTransitiveRequests:Int = leafNode.requests.length > 0
For Local transitiveRequest:TGenericSpecializationRequestSite = EachIn leafNode.requests
	If (transitiveRequest.reason <> GENERIC_REQUEST_TRANSITIVE And transitiveRequest.reason <> GENERIC_REQUEST_ABI_REFERENCE) Or transitiveRequest.requestingUnit <> holderNode.generatedUnit Then canonicalTransitiveRequests = False
Next
Check(canonicalTransitiveRequests, "transitive requests retain deterministic implementation-unit ownership and provenance")
Local holderUnit:TCompilerGenericUnit
For Local unit:TCompilerGenericUnit = EachIn transitiveCompilation.genericPlan.units
	If unit.specialization = holderNode Then holderUnit = unit; Exit
Next
Check(holderUnit And holderUnit.ir.referencedSpecializations.length = 1 And holderUnit.ir.Dump().Contains("reference " + leafNode.identityDigest) And holderUnit.implementation.Contains("struct " + leafNode.readableAbiName + "_obj *"), "holder specialization IR dump and C use the canonical leaf ABI by reference")
Check(transitiveCompilation.genericPlan.manifest.Contains("edge " + leafNode.identityDigest), "the deterministic specialization manifest exposes the transitive request edge")

Local nestedSelfSignatureSource:String = "SuperStrict~nType TGList<T>~nMethod ToBatches:TGList<TGList<T>>()~nReturn Null~nEnd Method~nEnd Type~nGlobal list:TGList<String> = New TGList<String>"
Local nestedSelfSignatureCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("nested-self-signature.bmx", nestedSelfSignatureSource, Null, compilerOptions)
Local nestedSelfRoot:TGenericSpecializationNode
Local nestedSelfReference:TGenericSpecializationNode
For Local candidate:TGenericSpecializationNode = EachIn nestedSelfSignatureCompilation.genericPlan.registry.nodes
	If candidate.IsAbiReferenceOnly() Then nestedSelfReference = candidate Else nestedSelfRoot = candidate
Next
Check(nestedSelfSignatureCompilation.Succeeded() And nestedSelfSignatureCompilation.genericPlan.registry.nodes.length = 2 And nestedSelfSignatureCompilation.genericPlan.units.length = 1, "a recursively growing managed Type signature records one ABI reference without materializing an unbounded specialization family: " + CompilationSummary(nestedSelfSignatureCompilation))
Local nestedSelfAbiEdges:Int = nestedSelfRoot And nestedSelfReference And nestedSelfRoot.outgoing.length > 0
If nestedSelfRoot Then
	For Local edge:TGenericSpecializationEdge = EachIn nestedSelfRoot.outgoing
		If edge.target <> nestedSelfReference Or edge.request.reason <> GENERIC_REQUEST_ABI_REFERENCE Then nestedSelfAbiEdges = False
	Next
End If
Check(nestedSelfAbiEdges, "the nested self-signature edges are classified as declaration-only ABI provenance")
Check(nestedSelfSignatureCompilation.genericPlan.units[0].declarations.Contains("struct " + nestedSelfReference.readableAbiName + "_obj;") And nestedSelfSignatureCompilation.genericPlan.units[0].implementation.Contains("struct " + nestedSelfReference.readableAbiName + "_obj *"), "signature-only managed Type references retain a deterministic forward-declared C ABI")
Check(nestedSelfSignatureCompilation.ir.importedClasses.length = 2, "application IR retains both the materialized root and declaration-only nested managed Type identities")
Local nestedSelfRuntimeDiagnostics:TCompilerDiagnostic[]
Local nestedSelfRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(nestedSelfSignatureCompilation, nestedSelfRuntimeDiagnostics)
Check(nestedSelfRuntimeDiagnostics.length = 0 And nestedSelfRuntimeC.Contains("struct " + nestedSelfReference.readableAbiName + "_obj *"), "application C maps a declaration-only nested managed Type signature to its object-pointer ABI")

Local explicitNestedSelfSource:String = "SuperStrict~nType TGList<T>~nMethod ToBatches:TGList<TGList<T>>()~nReturn Null~nEnd Method~nEnd Type~nGlobal list:TGList<String> = New TGList<String>~nGlobal batches:TGList<TGList<String>> = list.ToBatches()"
Local explicitNestedSelfCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("explicit-nested-self-signature.bmx", explicitNestedSelfSource, Null, compilerOptions)
Local explicitNestedReferenceCount:Int
For Local candidate:TGenericSpecializationNode = EachIn explicitNestedSelfCompilation.genericPlan.registry.nodes
	If candidate.IsAbiReferenceOnly() Then explicitNestedReferenceCount :+ 1
Next
Check(explicitNestedSelfCompilation.Succeeded() And explicitNestedSelfCompilation.genericPlan.registry.nodes.length = 3 And explicitNestedSelfCompilation.genericPlan.units.length = 2 And explicitNestedReferenceCount = 1, "an explicit nested result use materializes exactly that depth and leaves only the next signature depth as an ABI reference: " + CompilationSummary(explicitNestedSelfCompilation))

Local structSignatureLayoutSource:String = "SuperStrict~nStruct SSignatureValue<T>~nField value:T~nEnd Struct~nType TSignatureProducer<T>~nMethod Produce:SSignatureValue<T>()~nEnd Method~nEnd Type~nGlobal producer:TSignatureProducer<Int> = New TSignatureProducer<Int>"
Local structSignatureLayoutCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("struct-signature-layout.bmx", structSignatureLayoutSource, Null, compilerOptions)
Check(structSignatureLayoutCompilation.Succeeded() And structSignatureLayoutCompilation.genericPlan.registry.nodes.length = 2 And structSignatureLayoutCompilation.genericPlan.units.length = 2, "a generic Struct used by value in a method signature remains a materialized layout dependency: " + CompilationSummary(structSignatureLayoutCompilation))

Local runawaySpecializationSource:String = "SuperStrict~nType TGrow<T>~nMethod Grow:TGrow<TGrow<T>>()~nReturn New TGrow<TGrow<T>>~nEnd Method~nEnd Type~nGlobal grow:TGrow<Int> = New TGrow<Int>"
Local runawaySpecializationCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("runaway-specialization.bmx", runawaySpecializationSource, Null, compilerOptions)
Check(runawaySpecializationCompilation.Succeeded() And runawaySpecializationCompilation.genericPlan.registry.nodes.length = 2 And runawaySpecializationCompilation.genericPlan.units.length = 1, "an unused polymorphic-recursive method retains its next ABI shape without expanding an infinite executable family: " + CompilationSummary(runawaySpecializationCompilation))
Check(runawaySpecializationCompilation.genericPlan.units[0].implementation.Contains("Compiler reached an unplanned polymorphic-recursive generic method body"), "an unrequested polymorphic-recursive virtual slot has a strict runtime guard rather than a missing or NULL implementation")

Local transformedGrowthSource:String = "SuperStrict~nType TNode<T>~nField value:T~nEnd Type~nType TTransform<T>~nMethod Grow:TTransform<TNode<T>>()~nReturn New TTransform<TNode<T>>~nEnd Method~nEnd Type~nGlobal root:TTransform<String> = New TTransform<String>"
Local transformedGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("transformed-growth-specialization.bmx", transformedGrowthSource, Null, compilerOptions)
Local transformedGrowthNodes:Int
Local transformedGrowthGuards:Int
For Local unit:TCompilerGenericUnit = EachIn transformedGrowthCompilation.genericPlan.units
	If unit.specialization.artifact.identity.qualifiedName = "TTransform" Then transformedGrowthNodes :+ 1
	If unit.implementation.Contains("Compiler reached an unplanned polymorphic-recursive generic method body") Then transformedGrowthGuards :+ 1
Next
Check(transformedGrowthCompilation.Succeeded() And transformedGrowthNodes = 1 And transformedGrowthGuards = 1, "a transformed-own-argument recursion is deferred before it grows an infinite specialization family: " + CompilationSummary(transformedGrowthCompilation))

Local demandedTransformedGrowthSource:String = transformedGrowthSource + "~nGlobal nested:TTransform<TNode<String>> = root.Grow()"
Local demandedTransformedGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("demanded-transformed-growth-specialization.bmx", demandedTransformedGrowthSource, Null, compilerOptions)
Local demandedTransformedGrowthNodes:Int
For Local unit:TCompilerGenericUnit = EachIn demandedTransformedGrowthCompilation.genericPlan.units
	If unit.specialization.artifact.identity.qualifiedName = "TTransform" Then demandedTransformedGrowthNodes :+ 1
Next
Check(demandedTransformedGrowthCompilation.Succeeded() And demandedTransformedGrowthNodes = 2 And demandedTransformedGrowthCompilation.genericPlan.manifest.Contains("required-method "), "one concrete transformed-argument call materializes exactly one executable depth: " + CompilationSummary(demandedTransformedGrowthCompilation))

Local demandedTypeFunctionGrowthSource:String = "SuperStrict~nType TNode<T>~nEnd Type~nType TFactoryGrow<T>~nFunction Make:TFactoryGrow<TNode<T>>()~nReturn New TFactoryGrow<TNode<T>>~nEnd Function~nEnd Type~nGlobal root:TFactoryGrow<String> = New TFactoryGrow<String>~nGlobal nested:TFactoryGrow<TNode<String>> = root.Make()"
Local demandedTypeFunctionGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("demanded-type-function-growth-specialization.bmx", demandedTypeFunctionGrowthSource, Null, compilerOptions)
Local demandedTypeFunctionGrowthNodes:Int
For Local unit:TCompilerGenericUnit = EachIn demandedTypeFunctionGrowthCompilation.genericPlan.units
	If unit.specialization.artifact.identity.qualifiedName = "TFactoryGrow" Then demandedTypeFunctionGrowthNodes :+ 1
Next
Check(demandedTypeFunctionGrowthCompilation.Succeeded() And demandedTypeFunctionGrowthNodes = 2 And demandedTypeFunctionGrowthCompilation.genericPlan.manifest.Contains("required-method "), "a directly called transformed Type Function materializes its deferred body just like an instance Method: " + CompilationSummary(demandedTypeFunctionGrowthCompilation))

Local crossArtifactGrowthSource:String = "SuperStrict~nType TNode<T>~nEnd Type~nInterface IView<T>~nEnd Interface~nType TAdapter<T> Implements IView<TNode<T>>~nEnd Type~nType TOuter<T>~nField adapter:TAdapter<T>~nMethod Grow:TOuter<TOuter<T>>()~nReturn New TOuter<TOuter<T>>~nEnd Method~nEnd Type~nGlobal root:TOuter<Int> = New TOuter<Int>~nGlobal nested:TOuter<TOuter<Int>> = root.Grow()"
Local crossArtifactGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("cross-artifact-growth-specialization.bmx", crossArtifactGrowthSource, Null, compilerOptions)
Check(crossArtifactGrowthCompilation.Succeeded(), "a larger Interface application reached through another generic artifact is not mistaken for direct recursive specialization: " + CompilationSummary(crossArtifactGrowthCompilation))

Local finiteMutualDependencySource:String = "SuperStrict~nType TLeft<T>~nField right:TRight<T>~nEnd Type~nType TRight<T>~nField left:TLeft<T>~nEnd Type~nGlobal root:TLeft<Int> = New TLeft<Int>"
Local finiteMutualDependencyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("finite-mutual-generic-dependency.bmx", finiteMutualDependencySource, Null, compilerOptions)
Check(finiteMutualDependencyCompilation.Succeeded() And finiteMutualDependencyCompilation.genericPlan.units.length = 2, "a same-argument mutual generic dependency converges normally: " + CompilationSummary(finiteMutualDependencyCompilation))

Local growingMutualDependencySource:String = "SuperStrict~nType TNode<T>~nEnd Type~nType TLeft<T>~nField right:TRight<TNode<T>>~nEnd Type~nType TRight<T>~nField left:TLeft<TNode<T>>~nEnd Type~nGlobal root:TLeft<Int> = New TLeft<Int>"
Local growingMutualDependencyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("growing-mutual-generic-dependency.bmx", growingMutualDependencySource, Null, compilerOptions)
Check(Not growingMutualDependencyCompilation.Succeeded() And HasCompilerDiagnostic(growingMutualDependencyCompilation, "BMXC3090") And growingMutualDependencyCompilation.genericPlan.registry.nodes.length <= 6, "a genuinely growing cycle through two generic declarations fails promptly: " + CompilationSummary(growingMutualDependencyCompilation))

Local diamondInterfaceGrowthSource:String = "SuperStrict~nType TNode<T>~nEnd Type~nInterface IView<T>~nEnd Interface~nType TLeftView<T> Implements IView<TNode<T>>~nEnd Type~nType TRightView<T> Implements IView<TNode<T>>~nEnd Type~nType TDiamond<T>~nField left:TLeftView<T>~nField right:TRightView<T>~nEnd Type~nGlobal root:TDiamond<Int> = New TDiamond<Int>~nGlobal nested:TDiamond<TDiamond<Int>> = New TDiamond<TDiamond<Int>>"
Local diamondInterfaceGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("diamond-interface-growth-specialization.bmx", diamondInterfaceGrowthSource, Null, compilerOptions)
Check(diamondInterfaceGrowthCompilation.Succeeded(), "parallel larger Interface applications in a diamond remain independent finite dependencies: " + CompilationSummary(diamondInterfaceGrowthCompilation))

Local finitePermutationSource:String = "SuperStrict~nType TSwap<A,B>~nMethod Swap:TSwap<B,A>()~nReturn New TSwap<B,A>~nEnd Method~nEnd Type~nGlobal root:TSwap<Int,String> = New TSwap<Int,String>"
Local finitePermutationCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("finite-permutation-specialization.bmx", finitePermutationSource, Null, compilerOptions)
Local finitePermutationNodes:Int
Local finitePermutationGuards:Int
For Local unit:TCompilerGenericUnit = EachIn finitePermutationCompilation.genericPlan.units
	If unit.specialization.artifact.identity.qualifiedName = "TSwap" Then finitePermutationNodes :+ 1
	If unit.implementation.Contains("Compiler reached an unplanned polymorphic-recursive generic method body") Then finitePermutationGuards :+ 1
Next
Check(finitePermutationCompilation.Succeeded() And finitePermutationNodes = 2 And finitePermutationGuards = 0, "an equal-complexity argument permutation converges normally without a deferred-method guard: " + CompilationSummary(finitePermutationCompilation))

Local localOnlyGrowthSource:String = "SuperStrict~nType TNode<T>~nEnd Type~nType TLocalGrow<T>~nMethod Touch()~nLocal child:TLocalGrow<TNode<T>>~nEnd Method~nEnd Type~nGlobal root:TLocalGrow<String> = New TLocalGrow<String>"
Local localOnlyGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("local-only-growth-specialization.bmx", localOnlyGrowthSource, Null, compilerOptions)
Check(localOnlyGrowthCompilation.Succeeded() And localOnlyGrowthCompilation.genericPlan.units.length = 1 And localOnlyGrowthCompilation.genericPlan.units[0].implementation.Contains("Compiler reached an unplanned polymorphic-recursive generic method body"), "a transformed local declaration defers its unused owning method without expanding an infinite family: " + CompilationSummary(localOnlyGrowthCompilation))

Local demandedLocalGrowthSource:String = localOnlyGrowthSource + "~nroot.Touch()"
Local demandedLocalGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("demanded-local-growth-specialization.bmx", demandedLocalGrowthSource, Null, compilerOptions)
Local demandedLocalGrowthNodes:Int
For Local unit:TCompilerGenericUnit = EachIn demandedLocalGrowthCompilation.genericPlan.units
	If unit.specialization.artifact.identity.qualifiedName = "TLocalGrow" Then demandedLocalGrowthNodes :+ 1
Next
Check(demandedLocalGrowthCompilation.Succeeded() And demandedLocalGrowthNodes = 2, "a demanded transformed local declaration materializes one bounded target depth: " + CompilationSummary(demandedLocalGrowthCompilation))

Local arrayLocalGrowthSource:String = "SuperStrict~nType TNode<T>~nEnd Type~nType TArrayGrow<T>~nMethod Touch()~nLocal children:TArrayGrow<TNode<T>>[]~nEnd Method~nEnd Type~nGlobal root:TArrayGrow<String> = New TArrayGrow<String>"
Local arrayLocalGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("array-local-growth-specialization.bmx", arrayLocalGrowthSource, Null, compilerOptions)
Check(arrayLocalGrowthCompilation.Succeeded() And arrayLocalGrowthCompilation.genericPlan.units.length = 1 And arrayLocalGrowthCompilation.genericPlan.units[0].implementation.Contains("Compiler reached an unplanned polymorphic-recursive generic method body"), "a transformed owning Type nested in an array local is also bounded: " + CompilationSummary(arrayLocalGrowthCompilation))

Local closureLocalGrowthSource:String = "SuperStrict~nType TNode<T>~nEnd Type~nType TClosureGrow<T>~nMethod Make:Closure<()>()~nReturn Function()~nLocal child:TClosureGrow<TNode<T>>~nEnd Function~nEnd Method~nEnd Type~nGlobal root:TClosureGrow<String> = New TClosureGrow<String>"
Local closureLocalGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("closure-local-growth-specialization.bmx", closureLocalGrowthSource, Null, compilerOptions)
Check(closureLocalGrowthCompilation.Succeeded() And closureLocalGrowthCompilation.genericPlan.units.length = 1 And closureLocalGrowthCompilation.genericPlan.units[0].implementation.Contains("Compiler reached an unplanned polymorphic-recursive generic method body"), "a transformed owning Type declared inside a Closure body participates in bounded method planning: " + CompilationSummary(closureLocalGrowthCompilation))

Local managedFieldGrowthSource:String = "SuperStrict~nType TNode<T>~nEnd Type~nType TFieldGrow<T>~nField child:TFieldGrow<TNode<T>>~nEnd Type~nGlobal root:TFieldGrow<String> = New TFieldGrow<String>"
Local managedFieldGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("managed-field-growth-specialization.bmx", managedFieldGrowthSource, Null, compilerOptions)
Local managedFieldAbiReferences:Int
For Local node:TGenericSpecializationNode = EachIn managedFieldGrowthCompilation.genericPlan.registry.nodes
	If node.artifact.identity.qualifiedName = "TFieldGrow" And node.IsAbiReferenceOnly() Then managedFieldAbiReferences :+ 1
Next
Check(managedFieldGrowthCompilation.Succeeded() And managedFieldGrowthCompilation.genericPlan.units.length = 1 And managedFieldAbiReferences = 1, "a managed field pointing at a transformed owning Type needs only a bounded ABI reference: " + CompilationSummary(managedFieldGrowthCompilation))

Local managedStaticFieldGrowthSource:String = "SuperStrict~nType TNode<T>~nEnd Type~nType TStaticFieldGrow<T>~nGlobal child:TStaticFieldGrow<TNode<T>>~nEnd Type~nGlobal root:TStaticFieldGrow<String> = New TStaticFieldGrow<String>"
Local managedStaticFieldGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("managed-static-field-growth-specialization.bmx", managedStaticFieldGrowthSource, Null, compilerOptions)
Local managedStaticFieldAbiReferences:Int
For Local node:TGenericSpecializationNode = EachIn managedStaticFieldGrowthCompilation.genericPlan.registry.nodes
	If node.artifact.identity.qualifiedName = "TStaticFieldGrow" And node.IsAbiReferenceOnly() Then managedStaticFieldAbiReferences :+ 1
Next
Check(managedStaticFieldGrowthCompilation.Succeeded() And managedStaticFieldGrowthCompilation.genericPlan.units.length = 1 And managedStaticFieldAbiReferences = 1, "a managed static field pointing at a transformed owning Type needs only a bounded ABI reference: " + CompilationSummary(managedStaticFieldGrowthCompilation))

Local managedArrayFieldGrowthSource:String = "SuperStrict~nType TNode<T>~nEnd Type~nType TArrayFieldGrow<T>~nField children:TArrayFieldGrow<TNode<T>>[]~nEnd Type~nGlobal root:TArrayFieldGrow<String> = New TArrayFieldGrow<String>"
Local managedArrayFieldGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("managed-array-field-growth-specialization.bmx", managedArrayFieldGrowthSource, Null, compilerOptions)
Local managedArrayFieldAbiReferences:Int
For Local node:TGenericSpecializationNode = EachIn managedArrayFieldGrowthCompilation.genericPlan.registry.nodes
	If node.artifact.identity.qualifiedName = "TArrayFieldGrow" And node.IsAbiReferenceOnly() Then managedArrayFieldAbiReferences :+ 1
Next
Check(managedArrayFieldGrowthCompilation.Succeeded() And managedArrayFieldGrowthCompilation.genericPlan.units.length = 1 And managedArrayFieldAbiReferences = 1, "a managed array field preserves declaration-only treatment for its transformed owning element Type: " + CompilationSummary(managedArrayFieldGrowthCompilation))

Local managedArraySignatureGrowthSource:String = "SuperStrict~nType TNode<T>~nEnd Type~nType TArraySignatureGrow<T>~nMethod Children:TArraySignatureGrow<TNode<T>>[]()~nReturn Null~nEnd Method~nEnd Type~nGlobal root:TArraySignatureGrow<String> = New TArraySignatureGrow<String>"
Local managedArraySignatureGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("managed-array-signature-growth-specialization.bmx", managedArraySignatureGrowthSource, Null, compilerOptions)
Local managedArraySignatureAbiReferences:Int
For Local node:TGenericSpecializationNode = EachIn managedArraySignatureGrowthCompilation.genericPlan.registry.nodes
	If node.artifact.identity.qualifiedName = "TArraySignatureGrow" And node.IsAbiReferenceOnly() Then managedArraySignatureAbiReferences :+ 1
Next
Check(managedArraySignatureGrowthCompilation.Succeeded() And managedArraySignatureGrowthCompilation.genericPlan.units.length = 1 And managedArraySignatureAbiReferences = 1, "a managed array method signature does not turn its transformed element Type into an executable recursion: " + CompilationSummary(managedArraySignatureGrowthCompilation))

Local structFieldGrowthSource:String = "SuperStrict~nType TNode<T>~nEnd Type~nStruct SFieldGrow<T>~nField child:SFieldGrow<TNode<T>>~nEnd Struct~nGlobal root:SFieldGrow<String>"
Local structFieldGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("struct-field-growth-specialization.bmx", structFieldGrowthSource, Null, compilerOptions)
Local structFieldGrowthNodes:Int
For Local node:TGenericSpecializationNode = EachIn structFieldGrowthCompilation.genericPlan.registry.nodes
	If node.artifact.identity.qualifiedName = "SFieldGrow" Then structFieldGrowthNodes :+ 1
Next
Check(Not structFieldGrowthCompilation.Succeeded() And HasCompilerDiagnostic(structFieldGrowthCompilation, "BMXC3090") And structFieldGrowthNodes <= 3, "a non-convergent transformed Struct field fails promptly because its by-value layout cannot be deferred: " + CompilationSummary(structFieldGrowthCompilation))

Local constructorGrowthSource:String = "SuperStrict~nType TNode<T>~nEnd Type~nType TCtorGrow<T>~nMethod New()~nLocal child:TCtorGrow<TNode<T>> = New TCtorGrow<TNode<T>>~nEnd Method~nEnd Type~nGlobal root:TCtorGrow<String> = New TCtorGrow<String>"
Local constructorGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("constructor-growth-specialization.bmx", constructorGrowthSource, Null, compilerOptions)
Local constructorGrowthNodes:Int
For Local node:TGenericSpecializationNode = EachIn constructorGrowthCompilation.genericPlan.registry.nodes
	If node.artifact.identity.qualifiedName = "TCtorGrow" Then constructorGrowthNodes :+ 1
Next
Check(Not constructorGrowthCompilation.Succeeded() And HasCompilerDiagnostic(constructorGrowthCompilation, "BMXC3090") And constructorGrowthNodes <= 3, "non-convergent transformed constructor recursion fails promptly and deterministically: " + CompilationSummary(constructorGrowthCompilation))

Local routineGrowthSource:String = "SuperStrict~nType TNode<T>~nEnd Type~nFunction Grow<T>()~nGrow<TNode<T>>()~nEnd Function~nGrow<String>()"
Local routineGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("routine-growth-specialization.bmx", routineGrowthSource, Null, compilerOptions)
Local routineGrowthNodes:Int
For Local node:TGenericSpecializationNode = EachIn routineGrowthCompilation.genericPlan.registry.nodes
	If node.artifact.identity.qualifiedName = "Grow" Then routineGrowthNodes :+ 1
Next
Check(Not routineGrowthCompilation.Succeeded() And HasCompilerDiagnostic(routineGrowthCompilation, "BMXC3090") And routineGrowthNodes <= 3, "non-convergent transformed generic-routine recursion fails promptly and deterministically: " + CompilationSummary(routineGrowthCompilation))

Local methodCallGrowthSource:String = "SuperStrict~nType TNode<T>~nEnd Type~nType TCallGrow<T>~nMethod Advance()~nLocal child:TCallGrow<TNode<T>> = New TCallGrow<TNode<T>>~nchild.Advance()~nEnd Method~nEnd Type~nGlobal root:TCallGrow<String> = New TCallGrow<String>~nroot.Advance()"
Local methodCallGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("method-call-growth-specialization.bmx", methodCallGrowthSource, Null, compilerOptions)
Local methodCallGrowthNodes:Int
For Local node:TGenericSpecializationNode = EachIn methodCallGrowthCompilation.genericPlan.registry.nodes
	If node.artifact.identity.qualifiedName = "TCallGrow" Then methodCallGrowthNodes :+ 1
Next
Check(Not methodCallGrowthCompilation.Succeeded() And HasCompilerDiagnostic(methodCallGrowthCompilation, "BMXC3090") And methodCallGrowthNodes <= 3, "non-convergent transformed method-call recursion fails promptly and deterministically: " + CompilationSummary(methodCallGrowthCompilation))

Local demandedGrowthSource:String = runawaySpecializationSource + "~nGlobal nested:TGrow<TGrow<Int>> = grow.Grow()"
Local demandedGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("demanded-growth-specialization.bmx", demandedGrowthSource, Null, compilerOptions)
Local demandedGrowthGuards:Int
For Local unit:TCompilerGenericUnit = EachIn demandedGrowthCompilation.genericPlan.units
	If unit.implementation.Contains("Compiler reached an unplanned polymorphic-recursive generic method body") Then demandedGrowthGuards :+ 1
Next
Check(demandedGrowthCompilation.Succeeded() And demandedGrowthCompilation.genericPlan.registry.nodes.length = 3 And demandedGrowthCompilation.genericPlan.units.length = 2 And demandedGrowthGuards = 1, "one concrete polymorphic-recursive call materializes exactly one executable depth and guards the next: " + CompilationSummary(demandedGrowthCompilation))
Check(demandedGrowthCompilation.genericPlan.manifest.Contains("required-method "), "the specialization manifest and cache identity retain demanded expansive method bodies")

Local forwardedGrowthSource:String = "SuperStrict~nType TGrow<T>~nMethod Grow:TGrow<TGrow<T>>()~nReturn New TGrow<TGrow<T>>~nEnd Method~nMethod Forward:TGrow<TGrow<T>>()~nReturn Grow()~nEnd Method~nEnd Type~nGlobal grow:TGrow<Int> = New TGrow<Int>~nGlobal nested:TGrow<TGrow<Int>> = grow.Forward()"
Local forwardedGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("forwarded-growth-specialization.bmx", forwardedGrowthSource, Null, compilerOptions)
Check(forwardedGrowthCompilation.Succeeded() And forwardedGrowthCompilation.genericPlan.registry.nodes.length = 3 And forwardedGrowthCompilation.genericPlan.units.length = 2 And forwardedGrowthCompilation.genericPlan.manifest.Contains("required-method "), "an active generic sibling method propagates its static call demand to an expansive method body: " + CompilationSummary(forwardedGrowthCompilation))

Local twiceDemandedGrowthSource:String = demandedGrowthSource + "~nGlobal deeper:TGrow<TGrow<TGrow<Int>>> = nested.Grow()"
Local twiceDemandedGrowthCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("twice-demanded-growth-specialization.bmx", twiceDemandedGrowthSource, Null, compilerOptions)
Local twiceDemandedGrowthGuards:Int
For Local unit:TCompilerGenericUnit = EachIn twiceDemandedGrowthCompilation.genericPlan.units
	If unit.implementation.Contains("Compiler reached an unplanned polymorphic-recursive generic method body") Then twiceDemandedGrowthGuards :+ 1
Next
Check(twiceDemandedGrowthCompilation.Succeeded() And twiceDemandedGrowthCompilation.genericPlan.registry.nodes.length = 4 And twiceDemandedGrowthCompilation.genericPlan.units.length = 3 And twiceDemandedGrowthGuards = 1, "two concrete polymorphic-recursive calls materialize exactly two executable depths and remain bounded: " + CompilationSummary(twiceDemandedGrowthCompilation))

Local expansiveModuleSource:String = "SuperStrict~nModule Collections.Expansive~nType TGrow<T>~nMethod Grow:TGrow<TGrow<T>>()~nReturn New TGrow<TGrow<T>>~nEnd Method~nEnd Type"
Local expansiveModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/expansive.mod/expansive.bmx", expansiveModuleSource, Null, compilerOptions)
Local expansiveArtifactDiagnostics:TCompilerDiagnostic[]
Local expansiveOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(expansiveModuleCompilation, expansiveArtifactDiagnostics)
Local expansiveInterfaceDiagnostics:TCompilerDiagnostic[]
Local expansiveInterface:String = TBlitzMaxCompiler.EmitInterface(expansiveModuleCompilation, expansiveInterfaceDiagnostics)
Local expansiveResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
expansiveResolver.AddInterface("collections.expansive", "sdk/collections.expansive.i", expansiveInterface)
For Local output:TCompilerGenericTemplateOutput = EachIn expansiveOutputs
	expansiveResolver.AddGenericTemplate(output.artifactReference, "sdk/" + output.artifactReference, output.content)
Next
Local expansiveConsumerSource:String = "SuperStrict~nImport Collections.Expansive~nGlobal root:TGrow<String> = New TGrow<String>~nGlobal nested:TGrow<TGrow<String>> = root.Grow()"
Local expansiveConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("expansive-consumer.bmx", expansiveConsumerSource, expansiveResolver, compilerOptions)
Check(expansiveModuleCompilation.Succeeded() And expansiveArtifactDiagnostics.length = 0 And expansiveInterfaceDiagnostics.length = 0 And expansiveOutputs.length = 1, "a module publishes an expansive generic method entirely through its compact interface and source-free artifact")
Check(expansiveConsumerCompilation.Succeeded() And expansiveConsumerCompilation.genericPlan.registry.nodes.length = 3 And expansiveConsumerCompilation.genericPlan.units.length = 2 And expansiveConsumerCompilation.genericPlan.manifest.Contains("required-method "), "a cross-module call demands exactly one expansive method body from the source-free artifact: " + CompilationSummary(expansiveConsumerCompilation))

Local runawayRoutineSource:String = "SuperStrict~nType TGrow<T>~nEnd Type~nFunction Expand<T>:Int(value:T)~nReturn Expand<TGrow<T>>(New TGrow<T>)~nEnd Function~nGlobal expanded:Int = Expand<Int>(0)"
Local runawayRoutineCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("runaway-routine-specialization.bmx", runawayRoutineSource, Null, compilerOptions)
Check(HasCompilerDiagnostic(runawayRoutineCompilation, "BMXC3090") And runawayRoutineCompilation.genericPlan.registry.nodes.length <= (GENERIC_SPECIALIZATION_MAX_EXPANSION_DEPTH + 1) * 2, "a genuinely non-converging generic routine graph still fails at a deterministic depth instead of hanging: " + CompilationSummary(runawayRoutineCompilation))

Local multiHopSource:String = "SuperStrict~nType TLeaf<T>~nField value:T~nEnd Type~nType TMiddle<T>~nField leaf:TLeaf<T>~nEnd Type~nType TTop<T>~nField middle:TMiddle<T>~nEnd Type~nGlobal top:TTop<String>"
Local multiHopCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("multi-hop-generics.bmx", multiHopSource, Null, compilerOptions)
Check(multiHopCompilation.Succeeded() And multiHopCompilation.genericPlan.registry.nodes.length = 3 And multiHopCompilation.genericPlan.units.length = 3, "fixed-point graph expansion discovers a transitive specialization requested only by another transitive specialization")
Local transitiveRuntimeSource:String = transitiveSource + "~nGlobal leaf:TLeaf<String> = New TLeaf<String>~nholder = New THolder<String>~nholder.leaf = leaf~nleaf.value = ~qnested~q~nGlobal observed:String~nobserved = holder.Get().First()"
Local transitiveRuntimeCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("transitive-generics-runtime.bmx", transitiveRuntimeSource, Null, compilerOptions)
Check(transitiveRuntimeCompilation.Succeeded() And transitiveRuntimeCompilation.ir.genericInstances.length = 2, "nested generic construction, field assignment, and method return lower through two canonical IR identities")
Local transitiveRuntimeDiagnostics:TCompilerDiagnostic[]
Local transitiveRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(transitiveRuntimeCompilation, transitiveRuntimeDiagnostics)
Check(transitiveRuntimeDiagnostics.length = 0 And transitiveRuntimeC.Contains("->clas->m_get_0") And transitiveRuntimeC.Contains("->clas->m_first_0"), "application C dispatches across holder and leaf canonical descriptor slots")
Local transitiveBuildDiagnostics:TCompilerDiagnostic[]
Local transitiveBuildPlan:TCompilerBuildOutputPlan = TBlitzMaxCompiler.PlanBuildOutputs(transitiveRuntimeCompilation, "transitive-application.c", "", "", transitiveBuildDiagnostics)
Check(transitiveBuildDiagnostics.length = 0 And transitiveBuildPlan.files.length = 3 And transitiveBuildPlan.linkInputs.length = 2, "transitive runtime build owns two separate cache-addressed specialization units and exact link inputs")
Local factorySource:String = "SuperStrict~nType TLeaf<T>~nField value:T~nMethod First:T()~nReturn value~nEnd Method~nEnd Type~nType TFactory<T>~nMethod Create:TLeaf<T>()~nReturn New TLeaf<T>~nEnd Method~nMethod Read:T(leaf:TLeaf<T>)~nReturn leaf.First()~nEnd Method~nEnd Type~nGlobal factory:TFactory<String> = New TFactory<String>~nGlobal made:TLeaf<String> = factory.Create()~nmade.value = ~qfactory~q~nGlobal factoryValue:String~nfactoryValue = factory.Read(made)"
Local factoryCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("factory-generics.bmx", factorySource, Null, compilerOptions)
Check(factoryCompilation.Succeeded() And factoryCompilation.genericPlan.registry.nodes.length = 2 And factoryCompilation.genericPlan.units.length = 2, "bound generic New and receiver calls expand and lower through one transitive leaf specialization")
Local factoryUnit:TCompilerGenericUnit
Local factoryLeafNode:TGenericSpecializationNode
For Local factoryCandidate:TCompilerGenericUnit = EachIn factoryCompilation.genericPlan.units
	If factoryCandidate.specialization.artifact.identity.qualifiedName = "TFactory" Then factoryUnit = factoryCandidate
	If factoryCandidate.specialization.artifact.identity.qualifiedName = "TLeaf" Then factoryLeafNode = factoryCandidate.specialization
Next
Check(factoryUnit And factoryLeafNode And factoryUnit.implementation.Contains(factoryLeafNode.readableAbiName + "_New((BBClass *)&" + factoryLeafNode.readableAbiName + ")") And factoryUnit.implementation.Contains(factoryLeafNode.readableAbiName + "_First("), "factory specialization unit directly references the canonical leaf allocation and non-inherited method ABIs")
Local factoryRuntimeDiagnostics:TCompilerDiagnostic[]
Local factoryRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(factoryCompilation, factoryRuntimeDiagnostics)
Check(factoryRuntimeDiagnostics.length = 0 And factoryRuntimeC.Contains("->clas->m_create_0") And factoryRuntimeC.Contains("->clas->m_read_1"), "application C dispatches factory methods while executable transitive work remains in the separate factory unit")

Local genericStructSource:String = "SuperStrict~nStruct TValueBox<T>~nField value:T~nMethod Read:T()~nReturn value~nEnd Method~nEnd Struct~nGlobal structBox1:TValueBox<String>~nGlobal structBox2:TValueBox<String>~nGlobal structBox3:TValueBox<String>~nGlobal structValue:String~nstructBox1.value = ~qstruct~q~nstructBox2 = structBox1~nstructBox3 = structBox2~nstructValue = structBox3.Read()"
Local genericStructCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-struct.bmx", genericStructSource, Null, compilerOptions)
Check(genericStructCompilation.Succeeded() And genericStructCompilation.genericPlan.registry.nodes.length = 1 And genericStructCompilation.genericPlan.units.length = 1, "independent value uses intern one canonical generic Struct specialization: " + CompilationSummary(genericStructCompilation))
Local genericStructUnit:TCompilerGenericUnit = genericStructCompilation.genericPlan.units[0]
Local genericStructAbi:String = genericStructUnit.specialization.readableAbiName
Check(genericStructUnit.ir.isStruct And genericStructUnit.ir.fields.length = 1 And genericStructUnit.ir.methods.length = 1, "generic Struct lowers to typed value-specialization IR with substituted field and method types")
Check(genericStructCompilation.ir.importedStructs.length = 1 And genericStructCompilation.ir.importedClasses.length = 0, "application IR represents the specialization as one imported value layout rather than a heap-object class")
Check(genericStructUnit.implementation.Contains("struct " + genericStructAbi + " " + genericStructAbi + "_New(void)") And Not genericStructUnit.implementation.Contains("BBClass ") And genericStructUnit.implementation.Contains("BBDEBUGSCOPE_USERSTRUCT") And genericStructUnit.implementation.Contains("void " + genericStructAbi + "_register(void)"), "separate generic Struct unit owns its value helper, method, reflection layout, and registration without an object descriptor")
Check(genericStructUnit.implementation.Contains("#ifndef BMX_GENERIC_STRUCT_" + genericStructAbi.ToUpper()), "specialization C shares the guarded canonical Struct layout published by a defining-module runtime header")
Local genericStructRuntimeDiagnostics:TCompilerDiagnostic[]
Local genericStructRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(genericStructCompilation, genericStructRuntimeDiagnostics)
Check(genericStructRuntimeDiagnostics.length = 0 And genericStructRuntimeC.Contains("#ifndef BMX_GENERIC_STRUCT_" + genericStructAbi.ToUpper()) And genericStructRuntimeC.Contains("struct " + genericStructAbi + " {") And genericStructRuntimeC.Contains(genericStructAbi + "_Read((&"), "application C uses the one guarded canonical Struct layout and pointer-receiver method ABI")
Check(genericStructCompilation.genericPlan.manifest.Contains("generated-unit .generics/units/") And genericStructCompilation.genericPlan.manifest.Contains("content-revision "), "generic Struct specialization participates in deterministic manifest and cache ownership")
Local wideStructSource:String = "SuperStrict~nExtern ~qC~q~nFunction ValidateWideStructReflection:Int() = ~qvalidate_wide_struct_reflection~q~nEnd Extern~nEnum EWideState~nIdle~nReady~nEnd Enum~nStruct SWidePoint~nField x:Int = 7~nEnd Struct~nType TWideReference~nEnd Type~nInterface IWideMarker~nEnd Interface~nStruct TWideValue<T>~nGlobal staticCount:Int = 4~nField marker:T~nField objectValue:Object~nField referenceValue:TWideReference~nField interfaceValue:IWideMarker~nField values:Int[]~nField point:SWidePoint~nField state:EWideState~nField address:Byte Ptr~nField StaticArray fixed:Int[2]~nMethod New(value:T, objectInput:Object, referenceInput:TWideReference, interfaceInput:IWideMarker, valuesInput:Int[], pointInput:SWidePoint, stateInput:EWideState, addressInput:Byte Ptr)~nmarker=value~nobjectValue=objectInput~nreferenceValue=referenceInput~ninterfaceValue=interfaceInput~nvalues=valuesInput~npoint=pointInput~nstate=stateInput~naddress=addressInput~nEnd Method~nMethod EchoPoint:SWidePoint(input:SWidePoint, valuesInput:Int[], objectInput:Object, addressInput:Byte Ptr, stateInput:EWideState)~nReturn input~nEnd Method~nMethod Apply:Int(callback:Int(value:Int), value:Int)~nReturn callback(value)~nEnd Method~nEnd Struct~nGlobal widePoint:SWidePoint~nGlobal wideValue:TWideValue<String> = New TWideValue<String>(~qwide~q, Null, Null, Null, [1,2], widePoint, EWideState.Ready, Null)~nGlobal wideValues:TWideValue<String>[] = New TWideValue<String>[2]~nGlobal echoedWidePoint:SWidePoint = wideValue.EchoPoint(widePoint, [3], Null, Null, EWideState.Idle)~nGlobal wideReflectionValid:Int = ValidateWideStructReflection()"
Local wideStructCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-wide-struct.bmx", wideStructSource, Null, compilerOptions)
Check(wideStructCompilation.Succeeded() And wideStructCompilation.genericPlan.units.length = 1 And wideStructCompilation.ir.importedStructs[0].containsManagedReferences, "generic Struct fields, constructors, and methods accept ordinary Struct, Enum, pointer, Array, Object, Type, Interface, String, and StaticArray ABIs: " + CompilationSummary(wideStructCompilation))
Local wideStructUnit:TCompilerGenericUnit = wideStructCompilation.genericPlan.units[0]
Local wideStructImplementation:String = wideStructUnit.implementation
Check(wideStructUnit.ir.staticFields.length = 1 And wideStructUnit.ir.staticFields[0].semanticType.CanonicalName() = "int" And wideStructUnit.ir.Dump().Contains("static staticCount:int"), "specialization IR distinguishes static storage from the C-compatible instance layout")
Check(wideStructImplementation.Contains("BBOBJECT") And wideStructImplementation.Contains("BBARRAY") And wideStructImplementation.Contains("struct bmx_direct_swidepoint_") And wideStructImplementation.Contains("BBBYTE *") And wideStructImplementation.Contains("[2]") And wideStructImplementation.Contains("_New_ObjectNew()"), "widened generic Struct storage and call signatures retain their concrete C-compatible representations and ordinary Struct default helper")
Check(wideStructImplementation.Contains("BBDEBUGSCOPE_USERSTRUCT") And wideStructImplementation.Contains("BBDEBUGDECL_FIELD") And wideStructImplementation.Contains("BBDEBUGDECL_GLOBAL") And wideStructImplementation.Contains(".field_offset = offsetof(struct " + wideStructUnit.specialization.readableAbiName) And wideStructImplementation.Contains(".struct_size = sizeof(struct " + wideStructUnit.specialization.readableAbiName) And wideStructImplementation.Contains("bbObjectRegisterStruct"), "a specialized Struct owns production-shaped field offsets, static metadata, size metadata, and reflection registration")
Local wideStructRuntimeDiagnostics:TCompilerDiagnostic[]
Local wideStructRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(wideStructCompilation, wideStructRuntimeDiagnostics)
Check(wideStructRuntimeDiagnostics.length = 0 And wideStructImplementation.Contains(wideStructUnit.specialization.readableAbiName + "_New_ObjectNew(void)") And wideStructImplementation.Contains("void bbStructElementInit_" + wideStructUnit.specialization.readableAbiName) And wideStructImplementation.Contains("bbArrayNew1DStruct(~q@TWideValue<string>~q") And wideStructRuntimeC.Contains("bbArrayNew1DStruct_" + wideStructUnit.specialization.readableAbiName), "managed specialized Struct Arrays use the specialization-owned value-default element initializer ABI")
Local wideStructHeaderDiagnostics:TCompilerDiagnostic[]
Local wideStructHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(wideStructCompilation, wideStructHeaderDiagnostics)
Check(wideStructHeaderDiagnostics.length = 0 And wideStructHeader.Contains("#ifndef BMX_GENERIC_STRUCT_" + wideStructUnit.specialization.readableAbiName.ToUpper()) And wideStructHeader.Contains("void " + wideStructUnit.specialization.readableAbiName + "_register(void);") And wideStructHeader.Contains("struct " + wideStructUnit.specialization.readableAbiName + " {") And wideStructHeader.Contains("extern BBINT " + wideStructUnit.ir.staticFields[0].abiName + ";"), "runtime headers publish the canonical specialized Struct layout, static storage declaration, and registration ABI for native consumers")
Local wideStructBuildDiagnostics:TCompilerDiagnostic[]
Local wideStructBuildPlan:TCompilerBuildOutputPlan = TBlitzMaxCompiler.PlanBuildOutputs(wideStructCompilation, "wide-struct.c", "wide-struct.h", "", wideStructBuildDiagnostics)
Local wideStructBuildUnit:TCompilerBuildOutputFile
For Local wideStructBuildFile:TCompilerBuildOutputFile = EachIn wideStructBuildPlan.files
	If wideStructBuildFile.role = "generic-specialization-c" Then wideStructBuildUnit = wideStructBuildFile
Next
Check(wideStructBuildDiagnostics.length = 0 And wideStructBuildUnit And wideStructBuildUnit.content.StartsWith("#include ~q../../wide-struct.h~q") And wideStructBuildPlan.linkInputs.length = 1 And wideStructBuildPlan.linkInputs[0].cacheKey <> wideStructCompilation.genericPlan.linkInputs[0].cacheKey, "separate Struct implementation includes its authoritative runtime layout header and couples that header revision into the object cache key")
Local moduleOwnedStructSource:String = "SuperStrict~nModule Acme.GenericLayoutOwner~nStruct SModulePoint~nField x:Int~nEnd Struct~nStruct TModuleValue<T>~nField marker:T~nField point:SModulePoint~nEnd Struct~nGlobal moduleValue:TModuleValue<String>"
Local moduleOwnedStructCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("acme.mod/genericlayoutowner.mod/genericlayoutowner.bmx", moduleOwnedStructSource, Null, compilerOptions)
Local moduleOwnedStructBuildDiagnostics:TCompilerDiagnostic[]
Local moduleOwnedStructBuildPlan:TCompilerBuildOutputPlan = TBlitzMaxCompiler.PlanBuildOutputs(moduleOwnedStructCompilation, "module.c", "module.h", "module.i", moduleOwnedStructBuildDiagnostics)
Local moduleOwnedStructBuildUnit:TCompilerBuildOutputFile
For Local moduleOwnedStructBuildFile:TCompilerBuildOutputFile = EachIn moduleOwnedStructBuildPlan.files
	If moduleOwnedStructBuildFile.role = "generic-specialization-c" Then moduleOwnedStructBuildUnit = moduleOwnedStructBuildFile
Next
Check(moduleOwnedStructCompilation.Succeeded() And moduleOwnedStructBuildDiagnostics.length = 0 And moduleOwnedStructBuildUnit And moduleOwnedStructBuildUnit.content.StartsWith("#include ~q../../module.h~q") And moduleOwnedStructBuildPlan.linkInputs[0].cacheKey <> moduleOwnedStructCompilation.genericPlan.linkInputs[0].cacheKey, "module-owned ordinary Struct layouts also couple the authoritative generated header revision into specialization caching")
Local callableStructSource:String = "SuperStrict~nFunction IncrementStructCallback:Int(value:Int) { nomangle }~nReturn value+1~nEnd Function~nStruct TCallableStruct<T>~nField marker:T~nField callback:Int(value:Int)~nMethod Apply:Int(input:Int(value:Int), value:Int)~ncallback=input~nReturn callback(value)~nEnd Method~nEnd Struct~nGlobal callableStruct:TCallableStruct<String>~nGlobal callableStructResult:Int = callableStruct.Apply(IncrementStructCallback, 41)"
Local callableStructCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-callable-struct.bmx", callableStructSource, Null, compilerOptions)
Local callableStructDiagnostics:TCompilerDiagnostic[]
Local callableStructRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(callableStructCompilation, callableStructDiagnostics)
Local callableStructImplementation:String
If callableStructCompilation.genericPlan And callableStructCompilation.genericPlan.units.length Then callableStructImplementation = callableStructCompilation.genericPlan.units[0].implementation
Local callableStructHeaderDiagnostics:TCompilerDiagnostic[]
Local callableStructHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(callableStructCompilation, callableStructHeaderDiagnostics)
Check(callableStructCompilation.Succeeded() And callableStructDiagnostics.length = 0 And callableStructHeaderDiagnostics.length = 0 And callableStructImplementation.Contains("(*_") And callableStructImplementation.Contains("(*input)(BBINT p0)") And callableStructImplementation.Contains("&brl_blitz_NullFunctionError") And callableStructHeader.Contains("(*_") And callableStructHeader.Contains("(BBINT)"), "generic Struct callable fields and parameters preserve exact function-pointer storage and published header ABIs: " + CompilationSummary(callableStructCompilation))
Check(callableStructImplementation.Contains("BBDEBUGDECL_TYPEMETHOD, ~qApply~q, ~q((i)i,i)i~q") And callableStructImplementation.Contains("_Apply_ReflectionWrapper") And callableStructImplementation.Contains("*((BBINT (**)(BBINT p0))"), "specialized Struct methods with callable parameters publish a typed reflection invocation wrapper")

Local staticStructSource:String = "SuperStrict~nStruct TStaticValue<T>~nGlobal count:Int = 1~nGlobal current:T~nField value:T~nMethod Store:T(input:T)~ncount :+ 1~ncurrent = input~nvalue = current~nReturn value~nEnd Method~nEnd Struct~nGlobal staticText:TStaticValue<String>~nGlobal staticNumber:TStaticValue<Int>~nGlobal storedText:String = staticText.Store(~qstatic~q)~nGlobal storedNumber:Int = staticNumber.Store(7)"
Local staticStructCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-static-struct.bmx", staticStructSource, Null, compilerOptions)
Check(staticStructCompilation.Succeeded() And staticStructCompilation.genericPlan.units.length = 2, "generic Struct Global members specialize into independent canonical storage for each closed argument: " + CompilationSummary(staticStructCompilation))
Local staticTextUnit:TCompilerGenericUnit
Local staticNumberUnit:TCompilerGenericUnit
For Local staticStructUnit:TCompilerGenericUnit = EachIn staticStructCompilation.genericPlan.units
	If staticStructUnit.specialization.key.typeArguments[0].CanonicalName() = "string" Then staticTextUnit = staticStructUnit
	If staticStructUnit.specialization.key.typeArguments[0].CanonicalName() = "int" Then staticNumberUnit = staticStructUnit
Next
Check(staticTextUnit And staticNumberUnit And staticTextUnit.ir.staticFields.length = 2 And staticNumberUnit.ir.staticFields.length = 2 And staticTextUnit.ir.staticFields[0].abiName <> staticNumberUnit.ir.staticFields[0].abiName, "static member ABI names include the canonical specialization identity and cannot collide across type arguments")
Check(staticTextUnit.implementation.Contains(staticTextUnit.ir.staticFields[0].abiName + " = 1;") And staticTextUnit.implementation.Contains(staticTextUnit.ir.staticFields[1].abiName + " = &bbEmptyString;"), "specialization unit owns static definitions and deterministic closed-type initialization without module-level duplicate storage")
Local staticStructRuntimeDiagnostics:TCompilerDiagnostic[]
Local staticStructRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(staticStructCompilation, staticStructRuntimeDiagnostics)
Check(staticStructRuntimeDiagnostics.length = 0 And staticStructRuntimeC.Contains(staticTextUnit.ir.staticFields[0].abiName) And staticStructRuntimeC.Contains(staticNumberUnit.ir.staticFields[0].abiName), "application C references each canonical specialization static through published extern declarations")
Local initializationModuleSource:String = "SuperStrict~nModule Collections.InitializationOrder~nType TInitializationProducer<T>~nGlobal Value:Int=41~nMethod Read:Int()~nReturn Value~nEnd Method~nEnd Type~nType TInitializationConsumer<T>~nGlobal Observed:Int=(New TInitializationProducer<T>).Read()+1~nMethod Read:Int()~nReturn Observed~nEnd Method~nEnd Type"
Local initializationModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/initializationorder.mod/initializationorder.bmx", initializationModuleSource, Null, compilerOptions)
Local initializationArtifactDiagnostics:TCompilerDiagnostic[]
Local initializationOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(initializationModuleCompilation, initializationArtifactDiagnostics)
Local initializationInterfaceDiagnostics:TCompilerDiagnostic[]
Local initializationInterface:String = TBlitzMaxCompiler.EmitInterface(initializationModuleCompilation, initializationInterfaceDiagnostics)
Local initializationResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
initializationResolver.AddInterface("collections.initializationorder", "sdk/collections.initializationorder.i", initializationInterface)
For Local initializationOutput:TCompilerGenericTemplateOutput = EachIn initializationOutputs
	initializationResolver.AddGenericTemplate(initializationOutput.artifactReference, "sdk/" + initializationOutput.artifactReference, initializationOutput.content)
Next
Local initializationConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("initialization-order-consumer.bmx", "SuperStrict~nImport Collections.InitializationOrder~nGlobal Consumer:TInitializationConsumer<String>=New TInitializationConsumer<String>", initializationResolver, compilerOptions)
Local initializationProducerUnit:TCompilerGenericUnit
Local initializationConsumerUnit:TCompilerGenericUnit
For Local initializationUnit:TCompilerGenericUnit = EachIn initializationConsumerCompilation.genericPlan.units
	Select initializationUnit.specialization.artifact.identity.qualifiedName.ToLower()
		Case "tinitializationproducer"
			initializationProducerUnit = initializationUnit
		Case "tinitializationconsumer"
			initializationConsumerUnit = initializationUnit
	End Select
Next
Local initializationEdgeFound:Int
If initializationConsumerUnit And initializationProducerUnit Then
	For Local initializationEdge:TGenericSpecializationEdge = EachIn initializationConsumerUnit.specialization.outgoing
		If initializationEdge.target = initializationProducerUnit.specialization And initializationEdge.request.reason = GENERIC_REQUEST_INITIALIZATION Then initializationEdgeFound = True
	Next
End If
Check(initializationModuleCompilation.Succeeded() And initializationArtifactDiagnostics.length = 0 And initializationInterfaceDiagnostics.length = 0 And initializationOutputs.length = 2 And initializationConsumerCompilation.Succeeded() And initializationProducerUnit And initializationConsumerUnit, "cross-module generic static initialization is reconstructed entirely from compact and source-free artifacts: " + CompilationSummary(initializationConsumerCompilation))
Check(initializationEdgeFound And AppearsBefore(initializationConsumerUnit.implementation, initializationProducerUnit.specialization.readableAbiName + "_register();", initializationConsumerUnit.ir.staticFields[0].abiName + " = "), "a source-free generic initializer registers its canonical dependency before evaluating static storage")
Local initializationCycleSource:String = "SuperStrict~nType TInitializationCycleA<T>~nGlobal Value:Int=(New TInitializationCycleB<T>).Read()+1~nMethod Read:Int()~nReturn Value~nEnd Method~nEnd Type~nType TInitializationCycleB<T>~nGlobal Value:Int=(New TInitializationCycleA<T>).Read()+1~nMethod Read:Int()~nReturn Value~nEnd Method~nEnd Type~nGlobal Cycle:TInitializationCycleA<String>=New TInitializationCycleA<String>"
Local initializationCycleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-initialization-cycle.bmx", initializationCycleSource, Null, compilerOptions)
Check(HasCompilerDiagnostic(initializationCycleCompilation, "BMXC3091"), "a cyclic generic static-initializer dependency is diagnosed instead of observing partially initialized default storage")
Local threadedStaticStructSource:String = "SuperStrict~nStruct TThreadedStatic<T>~nThreadedGlobal current:T~nEnd Struct~nGlobal threadedStatic:TThreadedStatic<Int>"
Local threadedStaticStructCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-threaded-static-struct.bmx", threadedStaticStructSource, Null, compilerOptions)
Local threadedStaticStructUnit:TCompilerGenericUnit = threadedStaticStructCompilation.genericPlan.units[0]
Local threadedStaticStructHeaderDiagnostics:TCompilerDiagnostic[]
Local threadedStaticStructHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(threadedStaticStructCompilation, threadedStaticStructHeaderDiagnostics)
Check(threadedStaticStructCompilation.Succeeded() And threadedStaticStructUnit.ir.staticFields[0].isThreadedGlobal And threadedStaticStructUnit.implementation.Contains("BBThreadLocal BBINT") And threadedStaticStructUnit.implementation.Contains("_thread_initialized") And threadedStaticStructUnit.implementation.Contains("_thread_init(void)"), "generic ThreadedGlobal storage owns a closed per-thread initialization guard: " + CompilationSummary(threadedStaticStructCompilation))
Check(threadedStaticStructHeaderDiagnostics.length = 0 And threadedStaticStructHeader.Contains("extern BBThreadLocal BBINT " + threadedStaticStructUnit.ir.staticFields[0].abiName), "the application runtime header publishes application-owned generic TLS with BBThreadLocal")
Local threadedModuleSource:String = "SuperStrict~nModule Collections.ThreadedState~nFunction InitialThreadValue:Int()~nReturn 7~nEnd Function~nType TThreadedState<T>~nThreadedGlobal Current:T~nThreadedGlobal Seed:Int=InitialThreadValue()~nMethod Read:T()~nReturn Current~nEnd Method~nEnd Type"
Local threadedModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/threadedstate.mod/threadedstate.bmx", threadedModuleSource, Null, compilerOptions)
Local threadedArtifactDiagnostics:TCompilerDiagnostic[]
Local threadedOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(threadedModuleCompilation, threadedArtifactDiagnostics)
Local threadedInterfaceDiagnostics:TCompilerDiagnostic[]
Local threadedInterface:String = TBlitzMaxCompiler.EmitInterface(threadedModuleCompilation, threadedInterfaceDiagnostics)
Local threadedResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
threadedResolver.AddInterface("collections.threadedstate", "sdk/collections.threadedstate.i", threadedInterface)
For Local threadedOutput:TCompilerGenericTemplateOutput = EachIn threadedOutputs
	threadedResolver.AddGenericTemplate(threadedOutput.artifactReference, "sdk/" + threadedOutput.artifactReference, threadedOutput.content)
Next
Local threadedConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("threaded-state-consumer.bmx", "SuperStrict~nImport Collections.ThreadedState~nGlobal State:TThreadedState<String>=New TThreadedState<String>~nGlobal Current:String=State.Read()", threadedResolver, compilerOptions)
Local threadedConsumerUnit:TCompilerGenericUnit = threadedConsumerCompilation.genericPlan.units[0]
Local threadedHeaderDiagnostics:TCompilerDiagnostic[]
Local threadedConsumerHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(threadedConsumerCompilation, threadedHeaderDiagnostics)
Local threadedExternalFound:Int
For Local threadedExternal:TCompilerIrExternalGlobal = EachIn threadedConsumerCompilation.ir.externalGlobals
	If threadedExternal.isThreadedGlobal Then threadedExternalFound = True; Exit
Next
Check(threadedModuleCompilation.Succeeded() And threadedArtifactDiagnostics.length = 0 And threadedInterfaceDiagnostics.length = 0 And threadedOutputs.length = 1 And threadedConsumerCompilation.Succeeded() And threadedConsumerUnit, "generic ThreadedGlobal specialization is reconstructed from compact and source-free artifacts: " + CompilationSummary(threadedConsumerCompilation))
Check(threadedConsumerUnit.implementation.Contains("static BBThreadLocal BBINT " + threadedConsumerUnit.specialization.readableAbiName + "_thread_initialized"), "source-free generic TLS owns the canonical per-thread guard")
Check(threadedConsumerUnit.implementation.Contains("BBINT collections_threadedstate_InitialThreadValue(void);") And threadedConsumerUnit.implementation.Contains("= collections_threadedstate_InitialThreadValue();"), "source-free dynamic TLS initialization retains its ordinary dependency declaration")
Check(threadedConsumerUnit.implementation.Contains(threadedConsumerUnit.specialization.readableAbiName + "_thread_init();"), "source-free generic methods enter the canonical per-thread initializer")
Check(threadedConsumerUnit.implementation.Contains("bbExTry {") And threadedConsumerUnit.implementation.Contains("registered = 0;") And threadedConsumerUnit.implementation.Contains(threadedConsumerUnit.specialization.readableAbiName + "_thread_initialized = 0;") And threadedConsumerUnit.implementation.Contains("bbExThrow((BBObject *)bmx_initialization_exception);"), "a throwing source-free generic TLS initializer restores registration and per-thread guards before rethrowing for a complete later retry")
Check(threadedHeaderDiagnostics.length = 0, "generic TLS runtime-header emission remains diagnostic-free")
Check(threadedExternalFound, "application IR retains the generic ThreadedGlobal storage class")
Local nestedGenericStructSource:String = "SuperStrict~nStruct TInnerValue<T>~nField value:T~nMethod Read:T()~nReturn value~nEnd Method~nEnd Struct~nStruct TOuterValue<T>~nField inner:TInnerValue<T>~nEnd Struct~nGlobal outerValue:TOuterValue<String>~nGlobal copiedOuter:TOuterValue<String>~nGlobal nestedValue:String~nouterValue.inner.value = ~qnested~q~ncopiedOuter = outerValue~nnestedValue = copiedOuter.inner.Read()"
Local nestedGenericStructCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("nested-generic-struct.bmx", nestedGenericStructSource, Null, compilerOptions)
Check(nestedGenericStructCompilation.Succeeded() And nestedGenericStructCompilation.genericPlan.registry.nodes.length = 2 And nestedGenericStructCompilation.genericPlan.units.length = 2, "nested generic Struct field expands one canonical transitive value-layout dependency: " + CompilationSummary(nestedGenericStructCompilation))
Local nestedInnerUnit:TCompilerGenericUnit
Local nestedOuterUnit:TCompilerGenericUnit
For Local nestedStructUnit:TCompilerGenericUnit = EachIn nestedGenericStructCompilation.genericPlan.units
	If nestedStructUnit.specialization.artifact.identity.qualifiedName = "TInnerValue" Then nestedInnerUnit = nestedStructUnit
	If nestedStructUnit.specialization.artifact.identity.qualifiedName = "TOuterValue" Then nestedOuterUnit = nestedStructUnit
Next
Check(nestedInnerUnit And nestedOuterUnit And nestedOuterUnit.ir.fields[0].semanticType.kind = TEMPLATE_TYPE_NAMED, "outer specialization IR retains the canonical nested Struct type rather than flattening it")
Check(nestedOuterUnit.implementation.Find("struct " + nestedInnerUnit.specialization.readableAbiName + " {") < nestedOuterUnit.implementation.Find("struct " + nestedOuterUnit.specialization.readableAbiName + " {"), "outer implementation unit defines the inner value layout before its by-value field")
Check(nestedOuterUnit.implementation.Contains(nestedInnerUnit.specialization.readableAbiName + "_New_ObjectNew()"), "outer default helper initializes its nested field through the inner specialization value-default helper")
Local nestedGenericStructRuntimeDiagnostics:TCompilerDiagnostic[]
Local nestedGenericStructRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(nestedGenericStructCompilation, nestedGenericStructRuntimeDiagnostics)
Check(nestedGenericStructRuntimeDiagnostics.length = 0 And nestedGenericStructRuntimeC.Find("struct " + nestedInnerUnit.specialization.readableAbiName + " {") < nestedGenericStructRuntimeC.Find("struct " + nestedOuterUnit.specialization.readableAbiName + " {"), "application C owns each nested layout once in deterministic dependency order")
Local nestedStructLayoutEdgeFound:Int
Local nestedStructManagedPropagationFound:Int
For Local nestedImportedStruct:TCompilerIrImportedStruct = EachIn nestedGenericStructCompilation.ir.importedStructs
	For Local nestedImportedField:TCompilerIrImportedField = EachIn nestedImportedStruct.fields
		If nestedImportedField.importedStructId.length Then
			nestedStructLayoutEdgeFound = True
			If nestedImportedStruct.containsManagedReferences Then nestedStructManagedPropagationFound = True
		End If
	Next
Next
Check(nestedGenericStructCompilation.ir.importedStructs.length = 2 And nestedStructLayoutEdgeFound And nestedStructManagedPropagationFound, "application IR records the nested imported-Struct layout edge and transitive managed-reference classification")
Local nestedStructCollisionSource:String = "SuperStrict~nStruct TCollisionInner<T>~nField value:T~nEnd Struct~nStruct TCollisionOuter<T>~nField inner:TCollisionInner<T>~nEnd Struct~nGlobal stringOuter:TCollisionOuter<String>~nGlobal intOuter:TCollisionOuter<Int>"
Local nestedStructCollisionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("nested-generic-struct-collisions.bmx", nestedStructCollisionSource, Null, compilerOptions)
Check(nestedStructCollisionCompilation.Succeeded() And nestedStructCollisionCompilation.genericPlan.registry.nodes.length = 4 And nestedStructCollisionCompilation.genericPlan.units.length = 4, "different nested generic Struct arguments own four distinct canonical layouts")
Local stringOuterAbi:String
Local intOuterAbi:String
For Local collisionStructNode:TGenericSpecializationNode = EachIn nestedStructCollisionCompilation.genericPlan.registry.nodes
	If collisionStructNode.artifact.identity.qualifiedName <> "TCollisionOuter" Then Continue
	If collisionStructNode.key.typeArguments[0].CanonicalName() = "string" Then stringOuterAbi = collisionStructNode.readableAbiName
	If collisionStructNode.key.typeArguments[0].CanonicalName() = "int" Then intOuterAbi = collisionStructNode.readableAbiName
Next
Check(stringOuterAbi.length And intOuterAbi.length And stringOuterAbi <> intOuterAbi, "nested generic Struct ABI names retain collision-resistant canonical argument identity")
Local recursiveStructSource:String = "SuperStrict~nStruct TRecursiveValue<T>~nField nextValue:TRecursiveValue<T>~nEnd Struct~nGlobal recursiveValue:TRecursiveValue<String>"
Local recursiveStructCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("recursive-generic-struct.bmx", recursiveStructSource, Null, compilerOptions)
Check(HasCompilerDiagnostic(recursiveStructCompilation, "BMXC3008"), "recursive generic Struct value layouts fail through the explicit specialization SCC diagnostic")
Local genericStructInterfaceRejectionSource:String = "SuperStrict~nInterface IStructMarker~nEnd Interface~nStruct TInvalidStruct<T> Implements IStructMarker~nEnd Struct~nGlobal invalidStruct:TInvalidStruct<Int>"
Local genericStructInterfaceRejection:TCompilerResult = TBlitzMaxCompiler.Compile("generic-struct-interface-rejection.bmx", genericStructInterfaceRejectionSource, Null, compilerOptions)
Check(HasLanguageDiagnostic(genericStructInterfaceRejection, "BMX3202"), "generic Structs retain the language-wide prohibition on inheritance and implemented Interfaces")

Local recursiveSource:String = "SuperStrict~nType TNode<T>~nField nextNode:TNode<T>~nEnd Type~nGlobal root:TNode<String>"
Local recursiveCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("recursive-generic.bmx", recursiveSource, Null, compilerOptions)
Check(recursiveCompilation.Succeeded() And recursiveCompilation.genericPlan.registry.nodes[0].referenceScc.length, "artifact-discovered recursive Type references form an explicit reference-safe SCC")

Local inheritedSource:String = "SuperStrict~nType TBase<T>~nField baseValue:T~nMethod GetBase:T()~nReturn baseValue~nEnd Method~nEnd Type~nType TDerived<T> Extends TBase<T>~nField derivedValue:T~nMethod GetDerived:T()~nReturn derivedValue~nEnd Method~nEnd Type~nGlobal derived:TDerived<String> = New TDerived<String>~nderived.baseValue = ~qbase~q~nderived.derivedValue = ~qderived~q~nGlobal inheritedBase:String = derived.GetBase()~nGlobal inheritedDerived:String = derived.GetDerived()"
Local inheritedCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-inheritance.bmx", inheritedSource, Null, compilerOptions)
Check(inheritedCompilation.Succeeded() And Not HasCompilerDiagnostic(inheritedCompilation, "BMXC3031") And Not HasCompilerDiagnostic(inheritedCompilation, "BMXC3018"), "simple non-overriding generic inheritance lowers through the canonical runtime-layout path")
Check(inheritedCompilation.genericPlan.registry.nodes.length = 2 And inheritedCompilation.genericPlan.units.length = 2, "generic base substitution adds one canonical base specialization and implementation unit to the application graph")
Local inheritanceEdgeFound:Int
Local derivedInheritanceNode:TGenericSpecializationNode
Local baseInheritanceNode:TGenericSpecializationNode
For Local inheritanceNode:TGenericSpecializationNode = EachIn inheritedCompilation.genericPlan.registry.nodes
	If inheritanceNode.artifact.identity.qualifiedName = "TBase" Then baseInheritanceNode = inheritanceNode
	If inheritanceNode.artifact.identity.qualifiedName <> "TDerived" Then Continue
	derivedInheritanceNode = inheritanceNode
	Check(inheritanceNode.artifact.baseType And inheritanceNode.artifact.baseType.semanticType.CanonicalName().Contains("tbase<!type:0>"), "source template artifact retains its bound parameterized base reference")
	For Local inheritanceEdge:TGenericSpecializationEdge = EachIn inheritanceNode.outgoing
		If inheritanceEdge.request.reason = GENERIC_REQUEST_INHERITANCE Then inheritanceEdgeFound = True
	Next
Next
Check(inheritanceEdgeFound And inheritedCompilation.genericPlan.manifest.Contains("|inheritance|"), "manifest distinguishes canonical inheritance request ownership from ordinary transitive use")
Local derivedInheritanceUnit:TCompilerGenericUnit
For Local inheritanceUnit:TCompilerGenericUnit = EachIn inheritedCompilation.genericPlan.units
	If inheritanceUnit.specialization = derivedInheritanceNode Then derivedInheritanceUnit = inheritanceUnit; Exit
Next
Check(derivedInheritanceUnit And derivedInheritanceUnit.ir.baseSpecialization = baseInheritanceNode And derivedInheritanceUnit.ir.fields.length = 2 And derivedInheritanceUnit.ir.methods.length = 2, "derived specialization IR flattens the canonical base field and method-slot prefixes")
Check(derivedInheritanceUnit.ir.fields[0].declaringSpecialization = baseInheritanceNode And derivedInheritanceUnit.ir.methods[0].declaringSpecialization = baseInheritanceNode, "flattened inherited members retain their canonical declaration owner")
Check(derivedInheritanceUnit.implementation.Contains("(BBClass *)&" + baseInheritanceNode.readableAbiName) And derivedInheritanceUnit.implementation.Contains(baseInheritanceNode.readableAbiName + "_register();"), "derived specialization descriptor links and registers its canonical base descriptor")
Local inheritedRuntimeDiagnostics:TCompilerDiagnostic[]
Local inheritedRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(inheritedCompilation, inheritedRuntimeDiagnostics)
Check(inheritedRuntimeDiagnostics.length = 0 And inheritedRuntimeC.Contains("->clas->m_getbase_0") And inheritedRuntimeC.Contains("->clas->m_getderived_1"), "application C dispatches inherited and declared slots through one compatible derived ABI")

Local hiddenFieldSource:String = "SuperStrict~nType THiddenBase<T>~nField value:T~nMethod SetBase(input:T)~nvalue = input~nEnd Method~nMethod ReadBase:T()~nReturn value~nEnd Method~nEnd Type~nType THiddenDerived<T> Extends THiddenBase<T>~nField value:T~nMethod SetDerived(input:T)~nvalue = input~nEnd Method~nMethod ReadDerived:T()~nReturn value~nEnd Method~nEnd Type~nGlobal hidden:THiddenDerived<String> = New THiddenDerived<String>~nhidden.SetBase(~qbase~q)~nhidden.SetDerived(~qderived~q)~nGlobal hiddenBaseValue:String = hidden.ReadBase()~nGlobal hiddenDerivedValue:String = hidden.ReadDerived()"
Local hiddenFieldCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-hidden-field.bmx", hiddenFieldSource, Null, compilerOptions)
Check(hiddenFieldCompilation.Succeeded(), "a derived generic Type may hide an inherited field while both declaration-owned storage locations remain available: " + CompilationSummary(hiddenFieldCompilation))
Local hiddenDerivedUnit:TCompilerGenericUnit
Local hiddenFieldImplementations:String
For Local hiddenUnit:TCompilerGenericUnit = EachIn hiddenFieldCompilation.genericPlan.units
	hiddenFieldImplementations :+ hiddenUnit.implementation
	If hiddenUnit.specialization.artifact.identity.qualifiedName = "THiddenDerived" Then hiddenDerivedUnit = hiddenUnit
Next
Check(hiddenDerivedUnit And hiddenDerivedUnit.ir.fields.length = 2 And hiddenDerivedUnit.ir.fields[0].name = "value" And hiddenDerivedUnit.ir.fields[1].name = "value", "hidden-field specialization IR preserves both inherited and declared fields")
Check(hiddenDerivedUnit And hiddenDerivedUnit.ir.fields[0].declaringSpecialization <> hiddenDerivedUnit.ir.fields[1].declaringSpecialization And hiddenDerivedUnit.ir.fields[0].abiName <> hiddenDerivedUnit.ir.fields[1].abiName, "same-name fields use their canonical declaration owner in the C ABI")
Check(hiddenDerivedUnit And hiddenFieldImplementations.Contains("return self->" + hiddenDerivedUnit.ir.fields[0].abiName + ";") And hiddenFieldImplementations.Contains("return self->" + hiddenDerivedUnit.ir.fields[1].abiName + ";"), "base and derived method bodies resolve the intended hidden field without name-only lookup")

Local inheritedReceiverSource:String = "SuperStrict~nType TDispatchBase<T>~nMethod Transform:T(value:T)~nReturn value~nEnd Method~nEnd Type~nType TDispatchDerived<T> Extends TDispatchBase<T>~nMethod Transform:T(value:T) Override~nReturn value~nEnd Method~nEnd Type~nType TDispatchHost<T>~nField target:TDispatchBase<T>~nMethod ViaField:T(value:T)~nReturn target.Transform(value)~nEnd Method~nMethod ViaParameter:T(receiver:TDispatchBase<T>, value:T)~nReturn receiver.Transform(value)~nEnd Method~nMethod ViaLocal:T(receiver:TDispatchBase<T>, value:T)~nLocal selected:TDispatchBase<T> = receiver~nReturn selected.Transform(value)~nEnd Method~nEnd Type~nGlobal dispatchDerived:TDispatchDerived<String> = New TDispatchDerived<String>~nGlobal dispatchHost:TDispatchHost<String> = New TDispatchHost<String>~ndispatchHost.target = dispatchDerived~nGlobal viaField:String = dispatchHost.ViaField(~qfield~q)~nGlobal viaParameter:String = dispatchHost.ViaParameter(dispatchDerived, ~qparameter~q)~nGlobal viaLocal:String = dispatchHost.ViaLocal(dispatchDerived, ~qlocal~q)"
Local inheritedReceiverCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-inherited-receiver-dispatch.bmx", inheritedReceiverSource, Null, compilerOptions)
Check(inheritedReceiverCompilation.Succeeded(), "generic calls through base-typed fields, parameters, and locals retain virtual dispatch: " + CompilationSummary(inheritedReceiverCompilation))
Local dispatchHostUnit:TCompilerGenericUnit
For Local dispatchUnit:TCompilerGenericUnit = EachIn inheritedReceiverCompilation.genericPlan.units
	If dispatchUnit.specialization.artifact.identity.qualifiedName = "TDispatchHost" Then dispatchHostUnit = dispatchUnit
Next
Check(dispatchHostUnit And Occurrences(dispatchHostUnit.implementation, "->clas->m_transform_0") = 3, "all three inherited receiver shapes dispatch through the canonical base slot")

Local interfaceSource:String = "SuperStrict~nInterface IValue<T>~nMethod Read:T()~nEnd Interface~nType TValue<T> Implements IValue<T>~nField value:T~nMethod Read:T()~nReturn value~nEnd Method~nEnd Type~nGlobal item:TValue<String> = New TValue<String>~nitem.value = ~qinterface~q~nGlobal view:IValue<String> = item~nGlobal interfaceValue:String = view.Read()"
Local interfaceCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-interface.bmx", interfaceSource, Null, compilerOptions)
Check(interfaceCompilation.Succeeded() And Not HasCompilerDiagnostic(interfaceCompilation, "BMXC3031") And Not HasCompilerDiagnostic(interfaceCompilation, "BMXC3017"), "one generic Interface implementation lowers through canonical descriptor and table ownership: " + CompilationSummary(interfaceCompilation))
Local interfaceArtifactFound:Int
Local interfaceTypeUnit:TCompilerGenericUnit
Local interfaceDescriptorUnit:TCompilerGenericUnit
For Local interfaceNode:TGenericSpecializationNode = EachIn interfaceCompilation.genericPlan.registry.nodes
	If interfaceNode.artifact.identity.qualifiedName = "TValue" And interfaceNode.artifact.interfaces.length = 1 Then interfaceArtifactFound = True
Next
For Local interfaceUnit:TCompilerGenericUnit = EachIn interfaceCompilation.genericPlan.units
	If interfaceUnit.ir.isInterface Then interfaceDescriptorUnit = interfaceUnit Else interfaceTypeUnit = interfaceUnit
Next
Check(interfaceArtifactFound And interfaceCompilation.genericPlan.registry.nodes.length = 2 And interfaceCompilation.genericPlan.units.length = 2, "source generic template retains one implemented Interface edge and one canonical descriptor specialization")
Check(interfaceDescriptorUnit.ir.specialization.artifact.typeDeclarationKind = GENERIC_TYPE_DECLARATION_INTERFACE And interfaceTypeUnit.ir.specialization.artifact.typeDeclarationKind = GENERIC_TYPE_DECLARATION_CLASS, "format-3 artifacts distinguish Interface and Type declarations without relying on generated names")
Check(interfaceDescriptorUnit And interfaceDescriptorUnit.implementation.Contains("bbObjectRegisterInterface") And interfaceDescriptorUnit.implementation.Contains("#ifndef BMX_GENERIC_INTERFACE_" + interfaceDescriptorUnit.specialization.readableAbiName.ToUpper() + "_METHODS") And interfaceTypeUnit And interfaceTypeUnit.implementation.Contains("_interface_vtable"), "separate Interface unit owns one guarded method table and descriptor registration while the implementing Type unit owns its table")
Check(interfaceDescriptorUnit And interfaceDescriptorUnit.implementation.Contains("BBDEBUGSCOPE_USERTYPE") And interfaceDescriptorUnit.implementation.Contains(".debug_scope = (BBDebugScope *)&" + interfaceDescriptorUnit.specialization.readableAbiName + "_ifc_debug_scope"), "closed generic Interface descriptor publishes a deterministic non-null runtime reflection identity")
Local interfaceRuntimeDiagnostics:TCompilerDiagnostic[]
Local interfaceRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(interfaceCompilation, interfaceRuntimeDiagnostics)
Check(interfaceRuntimeDiagnostics.length = 0 And interfaceRuntimeC.Contains("bbObjectInterface") And interfaceRuntimeC.Contains("_ifc"), "application C dispatches the closed generic Interface through its canonical descriptor")

Local multipleInterfaceSource:String = "SuperStrict~nInterface IRoot<T>~nMethod Read:T()~nEnd Interface~nInterface ILeft<T> Extends IRoot<T>~nMethod Left:T()~nEnd Interface~nInterface IRight<T> Extends IRoot<T>~nMethod Right:T()~nEnd Interface~nInterface IDiamond<T> Extends ILeft<T>, IRight<T>~nMethod Diamond:T()~nEnd Interface~nInterface IExtra<T>~nMethod Extra:T()~nEnd Interface~nType TMultiValue<T> Implements IDiamond<T>, IExtra<T>~nField value:T~nMethod Read:T()~nReturn value~nEnd Method~nMethod Left:T()~nReturn value~nEnd Method~nMethod Right:T()~nReturn value~nEnd Method~nMethod Diamond:T()~nReturn value~nEnd Method~nMethod Extra:T()~nReturn value~nEnd Method~nEnd Type~nGlobal multiConcrete:TMultiValue<String> = New TMultiValue<String>~nmultiConcrete.value = ~qmultiple~q~nGlobal multiRoot:IRoot<String> = multiConcrete~nGlobal multiLeft:ILeft<String> = multiConcrete~nGlobal multiRight:IRight<String> = multiConcrete~nGlobal multiDiamond:IDiamond<String> = multiConcrete~nGlobal multiExtra:IExtra<String> = multiConcrete~nGlobal multiRead:String = multiRoot.Read()~nGlobal multiLeftValue:String = multiLeft.Left()~nGlobal multiRightValue:String = multiRight.Right()~nGlobal multiDiamondValue:String = multiDiamond.Diamond()~nGlobal multiExtraValue:String = multiExtra.Extra()"
Local multipleInterfaceCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-multiple-interface.bmx", multipleInterfaceSource, Null, compilerOptions)
Check(multipleInterfaceCompilation.Succeeded(), "generic Interface inheritance and multiple implementation lower through canonical closure ownership: " + CompilationSummary(multipleInterfaceCompilation))
Local multipleTypeUnit:TCompilerGenericUnit
Local diamondInterfaceUnit:TCompilerGenericUnit
For Local multipleUnit:TCompilerGenericUnit = EachIn multipleInterfaceCompilation.genericPlan.units
	If multipleUnit.specialization.artifact.identity.qualifiedName = "TMultiValue" Then multipleTypeUnit = multipleUnit
	If multipleUnit.specialization.artifact.identity.qualifiedName = "IDiamond" Then diamondInterfaceUnit = multipleUnit
Next
Check(multipleInterfaceCompilation.genericPlan.registry.nodes.length = 6 And multipleInterfaceCompilation.genericPlan.units.length = 6, "diamond Interface graph interns one Type and five Interface specializations")
Check(diamondInterfaceUnit And diamondInterfaceUnit.ir.inheritedInterfaces.length = 2 And diamondInterfaceUnit.ir.methods.length = 4, "derived generic Interface flattens both parents with the shared root method deduplicated")
Check(multipleTypeUnit And multipleTypeUnit.ir.implementedInterfaces.length = 5 And multipleTypeUnit.implementation.Contains("offsetof(struct") And multipleTypeUnit.implementation.Contains(", 5 };"), "implementing Type owns one aggregate table with a separate offset entry for every effective Interface")
Local multipleInterfaceRuntimeDiagnostics:TCompilerDiagnostic[]
Local multipleInterfaceRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(multipleInterfaceCompilation, multipleInterfaceRuntimeDiagnostics)
Check(multipleInterfaceRuntimeDiagnostics.length = 0 And multipleInterfaceRuntimeC.Contains("bbObjectInterface") And multipleInterfaceRuntimeC.Contains("m_diamond_3") And multipleInterfaceRuntimeC.Contains("m_extra_0"), "application C dispatches through inherited and independently implemented generic Interface descriptors")
Local nestedInterfaceArgumentSource:String = "SuperStrict~nInterface INode<K,V>~nMethod Key:K()~nEnd Interface~nInterface IIterator<T>~nMethod Current:T()~nEnd Interface~nType TNestedIterator<K,V> Implements IIterator<INode<K,V>>~nMethod Current:INode<K,V>()~nReturn Null~nEnd Method~nEnd Type~nGlobal nestedIterator:TNestedIterator<String,Int>"
Local nestedInterfaceArgumentCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-nested-interface-argument.bmx", nestedInterfaceArgumentSource, Null, compilerOptions)
Local nestedIteratorUnit:TCompilerGenericUnit
For Local nestedArgumentUnit:TCompilerGenericUnit = EachIn nestedInterfaceArgumentCompilation.genericPlan.units
	If nestedArgumentUnit.specialization.artifact.identity.qualifiedName = "TNestedIterator" Then nestedIteratorUnit = nestedArgumentUnit
Next
Check(nestedInterfaceArgumentCompilation.Succeeded() And nestedInterfaceArgumentCompilation.genericPlan.registry.nodes.length = 3, "nested generic Interface arguments enter the canonical graph as transitive specialization dependencies")
Check(nestedIteratorUnit And nestedIteratorUnit.ir.implementedInterfaces.length = 1 And nestedIteratorUnit.ir.implementedInterfaces[0].artifact.identity.qualifiedName = "IIterator", "only the outer Implements target contributes an Interface table")
Local interfaceCollisionSource:String = "SuperStrict~nInterface IFirst<T>~nMethod Value:T()~nEnd Interface~nInterface ISecond<T>~nMethod Value:T(index:Int)~nEnd Interface~nInterface ICollision<T> Extends IFirst<T>, ISecond<T>~nEnd Interface~nType TCollision<T> Implements ICollision<T>~nField value:T~nMethod Value:T()~nReturn value~nEnd Method~nMethod Value:T(index:Int)~nReturn value~nEnd Method~nEnd Type~nGlobal collision:TCollision<String>"
Local interfaceCollisionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-interface-collision.bmx", interfaceCollisionSource, Null, compilerOptions)
Check(interfaceCollisionCompilation.Succeeded() And interfaceCollisionCompilation.genericPlan.registry.nodes.length = 4, "independent inherited generic Interface overloads retain distinct signature-qualified slots")
Local incompatibleInterfaceCollisionSource:String = "SuperStrict~nType TCollisionValue~nEnd Type~nInterface ICollisionText<T>~nMethod Value:String()~nEnd Interface~nInterface ICollisionNumber<T>~nMethod Value:Int()~nEnd Interface~nInterface IInvalidCollision<T> Extends ICollisionText<T>, ICollisionNumber<T>~nEnd Interface~nGlobal invalidCollision:IInvalidCollision<TCollisionValue>"
Local incompatibleInterfaceCollisionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-incompatible-interface-collision.bmx", incompatibleInterfaceCollisionSource, Null, compilerOptions)
Check(HasLanguageDiagnostic(incompatibleInterfaceCollisionCompilation, "BMX3216"), "argument-independent inherited Interface return collisions fail at the semantic boundary")
Local covariantInterfaceSource:String = "SuperStrict~nInterface ICovariantObject<T>~nMethod Value:Object()~nEnd Interface~nInterface ICovariantString<T>~nMethod Value:String()~nEnd Interface~nInterface ICovariantCombined<T> Extends ICovariantObject<T>, ICovariantString<T>~nEnd Interface~nType TCovariantValue<T> Implements ICovariantCombined<T>~nMethod Value:String()~nReturn ~qvalue~q~nEnd Method~nEnd Type~nGlobal covariantValue:TCovariantValue<Int>"
Local covariantInterfaceCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-covariant-interface-collision.bmx", covariantInterfaceSource, Null, compilerOptions)
Local covariantCombinedUnit:TCompilerGenericUnit
For Local covariantUnit:TCompilerGenericUnit = EachIn covariantInterfaceCompilation.genericPlan.units
	If covariantUnit.specialization.artifact.identity.qualifiedName = "ICovariantCombined" Then covariantCombinedUnit = covariantUnit
Next
Check(covariantInterfaceCompilation.Succeeded() And covariantCombinedUnit And covariantCombinedUnit.ir.methods.length = 1 And covariantCombinedUnit.ir.methods[0].returnType.CanonicalName() = "object", "compatible inherited Interface returns merge into one selector while preserving the first parent binding")
Local explicitCovariantInterfaceSource:String = "SuperStrict~nInterface IRefinedBase<T>~nMethod Value:Object()~nEnd Interface~nInterface IRefinedChild<T> Extends IRefinedBase<T>~nMethod Value:String()~nEnd Interface~nType TRefinedValue<T> Implements IRefinedChild<T>~nMethod Value:String()~nReturn ~qvalue~q~nEnd Method~nEnd Type~nGlobal refinedValue:TRefinedValue<Int>"
Local explicitCovariantInterfaceCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-explicit-covariant-interface.bmx", explicitCovariantInterfaceSource, Null, compilerOptions)
Local refinedChildUnit:TCompilerGenericUnit
For Local refinedUnit:TCompilerGenericUnit = EachIn explicitCovariantInterfaceCompilation.genericPlan.units
	If refinedUnit.specialization.artifact.identity.qualifiedName = "IRefinedChild" Then refinedChildUnit = refinedUnit
Next
Check(explicitCovariantInterfaceCompilation.Succeeded() And refinedChildUnit And refinedChildUnit.ir.methods.length = 1 And refinedChildUnit.ir.methods[0].declaringSpecialization = refinedChildUnit.specialization And refinedChildUnit.ir.methods[0].returnType.CanonicalName() = "string", "an explicit derived Interface declaration covariantly refines and owns its inherited selector")
Local defaultInterfaceBodySource:String = "SuperStrict~nInterface IDefaultBody<T>~nMethod Identity:T(value:T)~nMethod Value:T(value:T) Default~nReturn Self.Identity(value)~nEnd Method~nEnd Interface~nType TDefaultBody<T> Implements IDefaultBody<T>~nMethod Identity:T(value:T)~nReturn value~nEnd Method~nEnd Type~nGlobal defaultBody:TDefaultBody<String> = New TDefaultBody<String>~nGlobal defaultView:IDefaultBody<String> = defaultBody~nGlobal defaultResult:String = defaultView.Value(~qdefault~q)"
Local defaultInterfaceBodyCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-default-interface-body.bmx", defaultInterfaceBodySource, Null, compilerOptions)
Check(defaultInterfaceBodyCompilation.Succeeded(), "generic Interface Default bodies lower through canonical specialization ownership: " + CompilationSummary(defaultInterfaceBodyCompilation))
Local defaultInterfaceUnit:TCompilerGenericUnit
Local defaultTypeUnit:TCompilerGenericUnit
For Local defaultUnit:TCompilerGenericUnit = EachIn defaultInterfaceBodyCompilation.genericPlan.units
	If defaultUnit.ir.isInterface Then defaultInterfaceUnit = defaultUnit Else defaultTypeUnit = defaultUnit
Next
Check(defaultInterfaceUnit And defaultInterfaceUnit.ir.methods.length = 2 And defaultInterfaceUnit.ir.methods[1].interfaceMethodKind = TEMPLATE_INTERFACE_METHOD_DEFAULT And defaultInterfaceUnit.implementation.Contains(defaultInterfaceUnit.ir.methods[1].abiName + "(BBOBJECT self"), "the closed Interface specialization owns exactly one emitted default body")
Check(defaultTypeUnit And defaultTypeUnit.implementation.Contains(defaultInterfaceUnit.ir.methods[1].abiName), "an implementing generic Type table falls back to the Interface-owned default ABI")

Local publishedModuleSource:String = genericSource.Replace("SuperStrict~n", "SuperStrict~nModule Collections.Core~n")
Local publishedModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/core.mod/core.bmx", publishedModuleSource, Null, compilerOptions)
Check(publishedModuleCompilation.Succeeded() And publishedModuleCompilation.genericPlan.templateOutputs.length = 1, "module compilation publishes its open generic template without lowering it into the module object")
Local publishedArtifactDiagnostics:TCompilerDiagnostic[]
Local publishedArtifactOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(publishedModuleCompilation, publishedArtifactDiagnostics)
Local publishedInterfaceDiagnostics:TCompilerDiagnostic[]
Local crossModuleInterface:String = TBlitzMaxCompiler.EmitInterface(publishedModuleCompilation, publishedInterfaceDiagnostics)
Check(publishedArtifactDiagnostics.length = 0 And publishedInterfaceDiagnostics.length = 0 And publishedArtifactOutputs.length = 1 And publishedArtifactOutputs[0].isPublished, "compiler API publishes one canonical companion artifact beside the module interface")
Local publishedBuildPlanDiagnostics:TCompilerDiagnostic[]
Local publishedBuildPlan:TCompilerBuildOutputPlan = TBlitzMaxCompiler.PlanBuildOutputs(publishedModuleCompilation, "module.c", "module.h", "module.i", publishedBuildPlanDiagnostics)
Check(publishedBuildPlanDiagnostics.length = 0 And publishedBuildPlan.files.length = 4, "module build-output plan owns C, runtime header, compact interface, and source-free template companion")
Check(publishedBuildPlan.manifest.Contains("file runtime-header ") And publishedBuildPlan.manifest.Contains(TCompilerBuildOutputPlanner.Enc("module.h")), "module build manifest publishes its ordinary runtime ABI header as a checked output")
Check(publishedBuildPlan.manifest.Contains(TCompilerBuildOutputPlanner.Enc(publishedArtifactOutputs[0].artifactReference)) And publishedBuildPlan.manifest.Contains(publishedArtifactOutputs[0].artifact.EffectiveContentRevision()), "module build manifest records the content-addressed template path and revision")
Local nestedPublishedBuildPlanDiagnostics:TCompilerDiagnostic[]
Local nestedPublishedBuildPlan:TCompilerBuildOutputPlan = TBlitzMaxCompiler.PlanBuildOutputs(publishedModuleCompilation, ".bmx/module.c", ".bmx/module.h", ".bmx/module.i", nestedPublishedBuildPlanDiagnostics)
Check(nestedPublishedBuildPlanDiagnostics.length = 0 And nestedPublishedBuildPlan.manifest.Contains(TCompilerBuildOutputPlanner.Enc(".bmx/" + publishedArtifactOutputs[0].artifactReference)), "template companions materialize relative to the compact interface directory")
Check(crossModuleInterface.Contains("'@generic-template " + GENERIC_TEMPLATE_FORMAT_VERSION + ",") And Not crossModuleInterface.Contains("<?>") And Not crossModuleInterface.Contains("G<?>"), "new compact interface publishes an artifact reference and never a legacy generic source payload")
Local publishedInterfaceFile:TInterfaceFile = TBlitzMaxParser.ParseInterfaceText(crossModuleInterface, "sdk/collections.core.i")
Check(publishedInterfaceFile.diagnostics.length = 0 And publishedInterfaceFile.declarations[0].genericTemplateRevision = publishedArtifactOutputs[0].artifact.EffectiveContentRevision(), "emitted compact interface round-trips its template identity and content revision")
Local crossModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
crossModuleResolver.AddInterface("collections.core", "sdk/collections.core.i", crossModuleInterface)
crossModuleResolver.AddGenericTemplate(publishedArtifactOutputs[0].artifactReference, "sdk/" + publishedArtifactOutputs[0].artifactReference, publishedArtifactOutputs[0].content)
Local crossModuleSource:String = "SuperStrict~nImport Collections.Core~nGlobal externalList1:TArrayList<String>~nGlobal externalList2:TArrayList<String>~nLocal externalList:TArrayList<String> = externalList1"
Local crossModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("cross-module-application.bmx", crossModuleSource, crossModuleResolver, compilerOptions)
Check(crossModuleCompilation.Succeeded() And crossModuleCompilation.genericPlan.registry.nodes.length = 1, "compiler specializes a validated cross-module template artifact without reparsing source")
Local crossModuleNode:TGenericSpecializationNode = crossModuleCompilation.genericPlan.registry.nodes[0]
Check(crossModuleNode.artifact.storageKind = TEMPLATE_ARTIFACT_STORAGE_CANONICAL And crossModuleNode.artifact.EffectiveContentRevision() = publishedArtifactOutputs[0].artifact.EffectiveContentRevision(), "cross-module planning retains canonical storage and content identity")
Check(crossModuleCompilation.genericPlan.units.length = 1 And crossModuleCompilation.genericPlan.linkInputs.length = 1 And crossModuleCompilation.ir.genericInstances.length = 1, "cross-module requests produce one typed implementation unit, object input, and compiler IR identity")
Check(crossModuleNode.key.CanonicalName().StartsWith(publishedArtifactOutputs[0].artifact.identity.StableName()), "defining module template identity remains the specialization authority")

crossModuleResolver.AddInterface("common.bmx", "sdk/mod/text.mod/hbfreetypefont.mod/.bmx/common.bmx.release.test.x64.i", "superstrict~nSGlyphPosition^Null{ '@source ~q../common.bmx~q,42,0~n.glyphIndex%& '@source ~q../common.bmx~q,43,7~n}S=~qtext_hbfreetypefont_SGlyphPosition~q")
Local ownedArgumentOptions:TCompilerOptions = TCompilerOptions.CreateDefault()
ownedArgumentOptions.requireCoreInterface = False
ownedArgumentOptions.targetPlatform = "test"
ownedArgumentOptions.targetArchitecture = "x64"
ownedArgumentOptions.conditionalSymbols = ["bmxng", "ptr64"]
ownedArgumentOptions.sourceModuleName = "text.hbfreetypefont"
ownedArgumentOptions.sourceUnitPath = "hbfreetypefont.bmx"
Local ownedArgumentCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/text.mod/hbfreetypefont.mod/hbfreetypefont.bmx", "SuperStrict~nImport Collections.Core~nImport ~qcommon.bmx~q~nGlobal glyphs:TArrayList<SGlyphPosition>", crossModuleResolver, ownedArgumentOptions)
Local ownedArgumentImplementation:String = ownedArgumentCompilation.genericPlan.units[0].implementation
Local ownedArgumentSymbol:TSymbol = ownedArgumentCompilation.analysis.model.ImportedScope("common.bmx").LookupLocal("SGlyphPosition")[0]
Check(ownedArgumentCompilation.Succeeded() And ownedArgumentSymbol.originModule = "text.hbfreetypefont" And ownedArgumentSymbol.originPath.EndsWith("/common.bmx"), "a quoted-source Struct used as a canonical generic argument retains module ownership and source provenance: " + CompilationSummary(ownedArgumentCompilation))
Check(ownedArgumentImplementation.Contains("#include <text.mod/hbfreetypefont.mod/.bmx/hbfreetypefont.bmx.release.test.x64.h>") And Not ownedArgumentImplementation.Contains("common.mod/bmx.mod") And Not ownedArgumentImplementation.Contains("__STDC_VERSION__"), "specialization C selects the owning module header without rewriting compiler-owned standard macros")

Local legacyInterfaceResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
Local legacyInterfaceText:String = "superstrict~nILegacyContract^Null{~n}AIG=~qcollections_legacycontract~q,<?>{0,59,~qlegacycontract.bmx~q,~qeJzzzCtJLUpLTE5V8PRJTU9MrnTOzyspSkwusQmx4/JNLcnIT1EISk1MsQrR0ORyzUtR8IRp4AIAcwwUHg==~q}~n"
legacyInterfaceResolver.AddInterface("collections.legacycontract", "sdk/collections.legacycontract.i", legacyInterfaceText)
Local legacyInterfaceConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("legacy-interface-consumer.bmx", "SuperStrict~nImport Collections.LegacyContract~nGlobal legacyContract:ILegacyContract<String>", legacyInterfaceResolver, compilerOptions)
Check(legacyInterfaceConsumer.Succeeded() And legacyInterfaceConsumer.genericPlan.registry.nodes.length = 1 And legacyInterfaceConsumer.genericPlan.registry.nodes[0].artifact.typeDeclarationKind = GENERIC_TYPE_DECLARATION_INTERFACE, "bootstrap bridge derives a body-free canonical generic Interface contract from its legacy semantic member table: " + CompilationSummary(legacyInterfaceConsumer))
Local legacyTypeResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
Local legacyTypeText:String = "superstrict~nTLegacyType^Null{~n}G=~qcollections_legacytype~q,<?>{0,68,~qlegacytype.bmx~q,~qeJwLqSxIVQjxSU1PTK4MAbJtQuy4fFNLMvJTFIJSE1OsQjQ0uYJSS0qL8hT8SnNyuFzzUhQg8mAmSAsXABz8FpY=~q}~n"
legacyTypeResolver.AddInterface("collections.legacytype", "sdk/collections.legacytype.i", legacyTypeText)
Local legacyTypeConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("legacy-type-consumer.bmx", "SuperStrict~nImport Collections.LegacyType~nGlobal legacyType:TLegacyType<String>", legacyTypeResolver, compilerOptions)
Check(HasCompilerDiagnostic(legacyTypeConsumer, "BMXC3041"), "bootstrap bridge remains isolated to body-free generic Interfaces and requires legacy generic Types to be rebuilt")
Local collidingInterfaceResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
Local collidingLegacyInterfaceText:String = "superstrict~nIIterator^Null{~n}AIG=~qcore_legacyiterator~q,<?>{0,78,~qlegacyiterator.bmx~q,~qeJzzzCtJLUpLTE5V8PQEshJL8otsQuy4fFNLMvJTFJxLi4pS80qsQjQ0YUK++WWpfqkVJVaeeSVAUde8FAVPmBlcADeLGrM=~q}~n"
collidingInterfaceResolver.AddInterface("core.legacyiterator", "sdk/core.legacyiterator.i", collidingLegacyInterfaceText)
Local collidingInterfaceSource:String = "SuperStrict~nImport Core.LegacyIterator~nInterface IIterator<T>~nMethod Current:T()~nEnd Interface~nGlobal localIterator:IIterator<String>"
Local collidingInterfaceConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("colliding-interface-consumer.bmx", collidingInterfaceSource, collidingInterfaceResolver, compilerOptions)
Check(collidingInterfaceConsumer.Succeeded() And collidingInterfaceConsumer.genericPlan.registry.nodes.length = 1 And collidingInterfaceConsumer.genericPlan.registry.nodes[0].artifact.identity.moduleName <> "core.legacyiterator", "module-qualified imported template indexing cannot shadow an unrelated source-local generic Interface with the same name: " + CompilationSummary(collidingInterfaceConsumer))

Local operatorModuleSource:String = "SuperStrict~nModule Collections.OperatorContract~nType TOperatorContract<T>~nField value:T~nMethod Operator[]:T(index:Int)~nReturn value~nEnd Method~nMethod Operator[]=(index:Int, newValue:T)~nvalue = newValue~nEnd Method~nEnd Type"
Local operatorModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/operatorcontract.mod/operatorcontract.bmx", operatorModuleSource, Null, compilerOptions)
Local operatorInterfaceDiagnostics:TCompilerDiagnostic[]
Local operatorModuleInterface:String = TBlitzMaxCompiler.EmitInterface(operatorModuleCompilation, operatorInterfaceDiagnostics)
Local operatorInterfaceFile:TInterfaceFile = TBlitzMaxParser.ParseInterfaceText(operatorModuleInterface, "sdk/collections.operatorcontract.i")
Check(operatorModuleCompilation.Succeeded() And operatorInterfaceDiagnostics.length = 0 And operatorModuleInterface.Contains("-~q[]~q:T(index%)") And operatorModuleInterface.Contains("-~q[]=~q(index%,newValue:T)") And operatorInterfaceFile.diagnostics.length = 0, "compact interface publication quotes operator method names and round-trips them without losing callable identity")

Local structModuleSource:String = "SuperStrict~nModule Collections.Values~nStruct TValueBox<T>~nGlobal instances:Int = 3~nField value:T~nMethod Read:T()~ninstances :+ 1~nReturn value~nEnd Method~nEnd Struct"
Local structModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/values.mod/values.bmx", structModuleSource, Null, compilerOptions)
Local structModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local structModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(structModuleCompilation, structModuleArtifactDiagnostics)
Local structModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local structModuleInterface:String = TBlitzMaxCompiler.EmitInterface(structModuleCompilation, structModuleInterfaceDiagnostics)
Check(structModuleCompilation.Succeeded() And structModuleArtifactDiagnostics.length = 0 And structModuleInterfaceDiagnostics.length = 0 And structModuleOutputs.length = 1, "module publication emits one source-free generic Struct artifact")
Check(structModuleInterface.Contains("TValueBox<T>^Object{") And structModuleInterface.Contains("}SK") And Not structModuleInterface.Contains("G<?>"), "compact publication preserves generic Struct value flavor without a source blob")
Local publishedStructStaticFound:Int
For Local publishedStructMember:TGenericTemplateMember = EachIn structModuleOutputs[0].artifact.members
	If publishedStructMember.isStatic And publishedStructMember.name = "instances" Then publishedStructStaticFound = True
Next
Check(publishedStructStaticFound, "cross-module template artifact publishes static storage shape and initializer semantics without publishing its implementation")
Local structModuleInterfaceFile:TInterfaceFile = TBlitzMaxParser.ParseInterfaceText(structModuleInterface, "sdk/collections.values.i")
Check(structModuleInterfaceFile.diagnostics.length = 0 And structModuleInterfaceFile.declarations[0].flags.Contains("S"), "generic Struct compact record round-trips as a Struct declaration")
Local structModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
structModuleResolver.AddInterface("collections.values", "sdk/collections.values.i", structModuleInterface)
structModuleResolver.AddGenericTemplate(structModuleOutputs[0].artifactReference, "sdk/" + structModuleOutputs[0].artifactReference, structModuleOutputs[0].content)
Local structModuleConsumerSource:String = "SuperStrict~nImport Collections.Values~nGlobal externalBox1:TValueBox<String>~nGlobal externalBox2:TValueBox<String>~nGlobal externalValue:String~nexternalBox1.value = ~qmodule struct~q~nexternalBox2 = externalBox1~nexternalValue = externalBox2.Read()"
Local structModuleConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("struct-consumer.bmx", structModuleConsumerSource, structModuleResolver, compilerOptions)
Check(structModuleConsumerCompilation.Succeeded() And structModuleConsumerCompilation.genericPlan.registry.nodes.length = 1 And structModuleConsumerCompilation.genericPlan.units.length = 1, "cross-module generic Struct specializes from its bound artifact without reparsing source: " + CompilationSummary(structModuleConsumerCompilation))
Check(structModuleConsumerCompilation.ir.importedStructs.length = 1 And structModuleConsumerCompilation.ir.importedStructs[0].isGenericSpecialization, "cross-module consumer IR retains canonical value-layout ownership")
Check(structModuleConsumerCompilation.genericPlan.units[0].ir.staticFields.length = 1 And structModuleConsumerCompilation.genericPlan.units[0].implementation.Contains(" = 3;"), "cross-module consumer emits specialization-owned static storage from the versioned source-free artifact")
Local revisedStructModuleSource:String = structModuleSource.Replace("instances:Int = 3", "instances:Int = 4")
Local revisedStructModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/values.mod/values.bmx", revisedStructModuleSource, Null, compilerOptions)
Local revisedStructModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(revisedStructModuleCompilation, structModuleArtifactDiagnostics)
Local revisedStructModuleInterface:String = TBlitzMaxCompiler.EmitInterface(revisedStructModuleCompilation, structModuleInterfaceDiagnostics)
Local revisedStructModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
revisedStructModuleResolver.AddInterface("collections.values", "sdk/collections.values.i", revisedStructModuleInterface)
revisedStructModuleResolver.AddGenericTemplate(revisedStructModuleOutputs[0].artifactReference, "sdk/" + revisedStructModuleOutputs[0].artifactReference, revisedStructModuleOutputs[0].content)
Local revisedStructConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("struct-consumer.bmx", structModuleConsumerSource, revisedStructModuleResolver, compilerOptions)
Check(revisedStructModuleCompilation.Succeeded() And revisedStructConsumerCompilation.Succeeded() And revisedStructModuleOutputs[0].artifact.EffectiveContentRevision() <> structModuleOutputs[0].artifact.EffectiveContentRevision() And revisedStructConsumerCompilation.genericPlan.linkInputs[0].cacheKey <> structModuleConsumerCompilation.genericPlan.linkInputs[0].cacheKey, "a cross-module static initializer change revises the template identity and invalidates the specialization object cache key")

Local nestedStructModuleSource:String = "SuperStrict~nModule Collections.NestedValues~nStruct TInnerValue<T>~nField value:T~nMethod Read:T()~nReturn value~nEnd Method~nEnd Struct~nStruct TOuterValue<T>~nField inner:TInnerValue<T>~nEnd Struct"
Local nestedStructModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/nestedvalues.mod/nestedvalues.bmx", nestedStructModuleSource, Null, compilerOptions)
Local nestedStructModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local nestedStructModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(nestedStructModuleCompilation, nestedStructModuleArtifactDiagnostics)
Local nestedStructModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local nestedStructModuleInterface:String = TBlitzMaxCompiler.EmitInterface(nestedStructModuleCompilation, nestedStructModuleInterfaceDiagnostics)
Check(nestedStructModuleCompilation.Succeeded() And nestedStructModuleArtifactDiagnostics.length = 0 And nestedStructModuleInterfaceDiagnostics.length = 0 And nestedStructModuleOutputs.length = 2, "module publishes both source-free artifacts required by a nested generic Struct layout")
Local nestedStructModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
nestedStructModuleResolver.AddInterface("collections.nestedvalues", "sdk/collections.nestedvalues.i", nestedStructModuleInterface)
For Local nestedStructModuleOutput:TCompilerGenericTemplateOutput = EachIn nestedStructModuleOutputs
	nestedStructModuleResolver.AddGenericTemplate(nestedStructModuleOutput.artifactReference, "sdk/" + nestedStructModuleOutput.artifactReference, nestedStructModuleOutput.content)
Next
Local nestedStructConsumerSource:String = "SuperStrict~nImport Collections.NestedValues~nGlobal externalOuter:TOuterValue<String>~nGlobal externalOuterCopy:TOuterValue<String>~nGlobal externalNestedValue:String~nexternalOuter.inner.value = ~qsource free nested~q~nexternalOuterCopy = externalOuter~nexternalNestedValue = externalOuterCopy.inner.Read()"
Local nestedStructConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("nested-struct-consumer.bmx", nestedStructConsumerSource, nestedStructModuleResolver, compilerOptions)
Check(nestedStructConsumerCompilation.Succeeded() And nestedStructConsumerCompilation.genericPlan.registry.nodes.length = 2 And nestedStructConsumerCompilation.genericPlan.units.length = 2, "cross-module nested generic Struct graph specializes entirely from compact interface and artifacts: " + CompilationSummary(nestedStructConsumerCompilation))
Local nestedStructConsumerRuntimeDiagnostics:TCompilerDiagnostic[]
Local nestedStructConsumerRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(nestedStructConsumerCompilation, nestedStructConsumerRuntimeDiagnostics)
Check(nestedStructConsumerRuntimeDiagnostics.length = 0 And nestedStructConsumerRuntimeC.Contains("_Read((&"), "source-free nested generic Struct consumer retains compatible field and receiver ABIs")

Local constructorModuleSource:String = "SuperStrict~nModule Collections.ConstructedValues~nStruct TConstructedValue<T>~nField stored:T~nField count:Int~nMethod New()~nEnd Method~nMethod New(value:T)~nstored = value~nEnd Method~nMethod New(amount:Int)~ncount = amount~nEnd Method~nMethod New(value:T, amount:Int)~nNew(value)~ncount = amount~nEnd Method~nMethod Read:T()~nReturn stored~nEnd Method~nEnd Struct"
Local constructorModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/constructedvalues.mod/constructedvalues.bmx", constructorModuleSource, Null, compilerOptions)
Local constructorModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local constructorModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(constructorModuleCompilation, constructorModuleArtifactDiagnostics)
Local constructorModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local constructorModuleInterface:String = TBlitzMaxCompiler.EmitInterface(constructorModuleCompilation, constructorModuleInterfaceDiagnostics)
Check(constructorModuleCompilation.Succeeded() And constructorModuleArtifactDiagnostics.length = 0 And constructorModuleInterfaceDiagnostics.length = 0 And constructorModuleOutputs.length = 1, "module publishes a source-free generic Struct constructor body: " + CompilationSummary(constructorModuleCompilation) + ", artifacts=" + constructorModuleOutputs.length + ", artifact-diagnostics=" + constructorModuleArtifactDiagnostics.length + ", interface-diagnostics=" + constructorModuleInterfaceDiagnostics.length)
Local publishedConstructorIdentities:TMap = New TMap
Local publishedConstructorIdentityCount:Int
For Local publishedConstructorMember:TGenericTemplateMember = EachIn constructorModuleOutputs[0].artifact.members
	If publishedConstructorMember.name.ToLower() = "new" And Not publishedConstructorIdentities.Contains(publishedConstructorMember.identity) Then
		publishedConstructorIdentities.Insert(publishedConstructorMember.identity, publishedConstructorMember)
		publishedConstructorIdentityCount :+ 1
	End If
Next
Check(publishedConstructorIdentityCount = 4, "template artifact identity distinguishes zero-argument, same-arity, and delegating constructor signatures before specialization")
Local publishedDelegationNode:TGenericTemplateNode
For Local publishedConstructorMember:TGenericTemplateMember = EachIn constructorModuleOutputs[0].artifact.members
	If publishedConstructorMember.name.ToLower() = "new" And publishedConstructorMember.parameters.length = 2 And publishedConstructorMember.body And publishedConstructorMember.body.children.length Then publishedDelegationNode = publishedConstructorMember.body.children[0]
Next
Check(publishedDelegationNode And publishedDelegationNode.kind = TEMPLATE_NODE_CONSTRUCTOR_DELEGATION, "format-4 template artifact retains constructor delegation as an explicit semantic node")
Local constructorModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
constructorModuleResolver.AddInterface("collections.constructedvalues", "sdk/collections.constructedvalues.i", constructorModuleInterface)
constructorModuleResolver.AddGenericTemplate(constructorModuleOutputs[0].artifactReference, "sdk/" + constructorModuleOutputs[0].artifactReference, constructorModuleOutputs[0].content)
Local constructorConsumerSource:String = "SuperStrict~nImport Collections.ConstructedValues~nGlobal externalDefault:TConstructedValue<String> = New TConstructedValue<String>~nGlobal externalConstructed:TConstructedValue<String> = New TConstructedValue<String>(~qsource free constructor~q)~nGlobal externalCounted:TConstructedValue<String> = New TConstructedValue<String>(7)~nGlobal externalDelegated:TConstructedValue<String> = New TConstructedValue<String>(~qdelegated constructor~q, 9)~nGlobal externalConstructedValue:String = externalConstructed.Read()"
Local constructorConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("constructed-value-consumer.bmx", constructorConsumerSource, constructorModuleResolver, compilerOptions)
Check(constructorConsumerCompilation.Succeeded() And constructorConsumerCompilation.genericPlan.registry.nodes.length = 1 And constructorConsumerCompilation.genericPlan.units.length = 1, "cross-module generic Struct constructor specializes from its bound artifact without source text: " + CompilationSummary(constructorConsumerCompilation))
Check(constructorConsumerCompilation.genericPlan.units[0].ir.constructors.length = 4 And constructorConsumerCompilation.genericPlan.units[0].implementation.Contains("_New__A0(void)") And constructorConsumerCompilation.genericPlan.units[0].implementation.Contains("_New__A1_string_") And constructorConsumerCompilation.genericPlan.units[0].implementation.Contains("(BBSTRING bmx_ctor_value)") And constructorConsumerCompilation.genericPlan.units[0].implementation.Contains("_New__A1_int_") And constructorConsumerCompilation.genericPlan.units[0].implementation.Contains("(BBINT bmx_ctor_amount)") And constructorConsumerCompilation.genericPlan.units[0].implementation.Contains("_New__A2(BBSTRING bmx_ctor_value, BBINT bmx_ctor_amount)") And constructorConsumerCompilation.genericPlan.units[0].implementation.Contains("bmx_value = bmx_gen_") And constructorConsumerCompilation.genericPlan.units[0].implementation.Contains(" = bmx_ctor_value;"), "source-free constructor artifact retains canonical overload signatures, delegation ownership, and bound field assignments")
Local constructorDefaultCount:Int = constructorConsumerCompilation.genericPlan.units[0].implementation.Split("bbEmptyString").length - 1
Check(constructorDefaultCount = 4, "delegating helper reuses terminal constructor storage while the distinct value-default helper owns one additional initialization path")

Local typeConstructorModuleSource:String = "SuperStrict~nModule Collections.ConstructedTypes~nType TConstructedType<T>~nField stored:T~nMethod New(value:T)~nstored = value~nEnd Method~nMethod Read:T()~nReturn stored~nEnd Method~nEnd Type"
Local typeConstructorModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/constructedtypes.mod/constructedtypes.bmx", typeConstructorModuleSource, Null, compilerOptions)
Local typeConstructorArtifactDiagnostics:TCompilerDiagnostic[]
Local typeConstructorOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(typeConstructorModuleCompilation, typeConstructorArtifactDiagnostics)
Local typeConstructorInterfaceDiagnostics:TCompilerDiagnostic[]
Local typeConstructorInterface:String = TBlitzMaxCompiler.EmitInterface(typeConstructorModuleCompilation, typeConstructorInterfaceDiagnostics)
Check(typeConstructorModuleCompilation.Succeeded() And typeConstructorArtifactDiagnostics.length = 0 And typeConstructorInterfaceDiagnostics.length = 0 And typeConstructorOutputs.length = 1, "generic Type publishes one bound parameterized constructor without source text")
Local typeConstructorResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
typeConstructorResolver.AddInterface("collections.constructedtypes", "sdk/collections.constructedtypes.i", typeConstructorInterface)
typeConstructorResolver.AddGenericTemplate(typeConstructorOutputs[0].artifactReference, "sdk/" + typeConstructorOutputs[0].artifactReference, typeConstructorOutputs[0].content)
Local typeConstructorConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("constructed-type-consumer.bmx", "SuperStrict~nImport Collections.ConstructedTypes~nGlobal constructedType1:TConstructedType<String> = New TConstructedType<String>(~qfirst~q)~nGlobal constructedType2:TConstructedType<String> = New TConstructedType<String>(~qsecond~q)~nGlobal constructedTypeValue:String = constructedType1.Read()", typeConstructorResolver, compilerOptions)
Check(typeConstructorConsumer.Succeeded() And typeConstructorConsumer.genericPlan.registry.nodes.length = 1 And typeConstructorConsumer.genericPlan.units.length = 1 And typeConstructorConsumer.genericPlan.units[0].ir.constructors.length = 1, "source-free parameterized generic Type construction interns one canonical specialization: " + CompilationSummary(typeConstructorConsumer))
Local typeConstructorImplementation:String = typeConstructorConsumer.genericPlan.units[0].implementation
Check(typeConstructorImplementation.Contains("_New__A1_string_") And typeConstructorImplementation.Contains("bbObjectNew(clas)") And typeConstructorImplementation.Contains(" = value;"), "generic Type constructor helper uses GC-aware allocation and executes its bound field assignment")
Local typeConstructorRuntimeDiagnostics:TCompilerDiagnostic[]
Local typeConstructorRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(typeConstructorConsumer, typeConstructorRuntimeDiagnostics)
Check(typeConstructorRuntimeDiagnostics.length = 0 And typeConstructorRuntimeC.Contains("_New__A1_string_") And typeConstructorRuntimeC.Contains("(BBClass *)&"), "application C references the separate canonical parameterized Type constructor helper")

Local advancedTypeConstructorModuleSource:String = "SuperStrict~nModule Collections.AdvancedConstructedTypes~nType TAdvancedConstructedType<T>~nField stored:T~nField count:Int~nMethod New()~ncount = 1~nEnd Method~nMethod New(value:T)~nstored = value~nEnd Method~nMethod New(amount:Int)~ncount = amount~nEnd Method~nMethod New(value:T, amount:Int)~nNew(value)~ncount = amount~nEnd Method~nMethod Read:T()~nReturn stored~nEnd Method~nEnd Type"
Local advancedTypeConstructorModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/advancedconstructedtypes.mod/advancedconstructedtypes.bmx", advancedTypeConstructorModuleSource, Null, compilerOptions)
Local advancedTypeConstructorArtifactDiagnostics:TCompilerDiagnostic[]
Local advancedTypeConstructorOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(advancedTypeConstructorModuleCompilation, advancedTypeConstructorArtifactDiagnostics)
Local advancedTypeConstructorInterfaceDiagnostics:TCompilerDiagnostic[]
Local advancedTypeConstructorInterface:String = TBlitzMaxCompiler.EmitInterface(advancedTypeConstructorModuleCompilation, advancedTypeConstructorInterfaceDiagnostics)
Check(advancedTypeConstructorModuleCompilation.Succeeded() And advancedTypeConstructorArtifactDiagnostics.length = 0 And advancedTypeConstructorInterfaceDiagnostics.length = 0 And advancedTypeConstructorOutputs.length = 1, "generic Type publishes zero-argument, overloaded, and delegating constructors as bound artifact data")
Local advancedTypeConstructorResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
advancedTypeConstructorResolver.AddInterface("collections.advancedconstructedtypes", "sdk/collections.advancedconstructedtypes.i", advancedTypeConstructorInterface)
advancedTypeConstructorResolver.AddGenericTemplate(advancedTypeConstructorOutputs[0].artifactReference, "sdk/" + advancedTypeConstructorOutputs[0].artifactReference, advancedTypeConstructorOutputs[0].content)
Local advancedTypeConstructorConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("advanced-constructed-type-consumer.bmx", "SuperStrict~nImport Collections.AdvancedConstructedTypes~nGlobal advancedDefault:TAdvancedConstructedType<String> = New TAdvancedConstructedType<String>~nGlobal advancedValue:TAdvancedConstructedType<String> = New TAdvancedConstructedType<String>(~qvalue~q)~nGlobal advancedCount:TAdvancedConstructedType<String> = New TAdvancedConstructedType<String>(5)~nGlobal advancedDelegated:TAdvancedConstructedType<String> = New TAdvancedConstructedType<String>(~qdelegated~q, 7)~nGlobal advancedRead:String = advancedDelegated.Read()", advancedTypeConstructorResolver, compilerOptions)
Check(advancedTypeConstructorConsumer.Succeeded() And advancedTypeConstructorConsumer.genericPlan.registry.nodes.length = 1 And advancedTypeConstructorConsumer.genericPlan.units.length = 1 And advancedTypeConstructorConsumer.genericPlan.units[0].ir.constructors.length = 4, "source-free generic Type construction retains all overloads in one canonical specialization: " + CompilationSummary(advancedTypeConstructorConsumer))
Local advancedTypeConstructorImplementation:String = advancedTypeConstructorConsumer.genericPlan.units[0].implementation
Check(advancedTypeConstructorImplementation.Contains("_New__A0_void_") And advancedTypeConstructorImplementation.Contains("_New__A1_string_") And advancedTypeConstructorImplementation.Contains("_New__A1_int_") And advancedTypeConstructorImplementation.Contains("_New__A2_string_int_"), "generic Type constructor helpers use deterministic closed-signature ABI names, including same-arity overloads")
Check(advancedTypeConstructorImplementation.Contains("_init(self, value);") And advancedTypeConstructorImplementation.Split("bbObjectNew(clas)").length - 1 = 5, "delegating Type constructors initialize one allocated object and each public overload owns exactly one allocation path in addition to the ordinary allocation ABI")
Local advancedTypeConstructorRuntimeDiagnostics:TCompilerDiagnostic[]
Local advancedTypeConstructorRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(advancedTypeConstructorConsumer, advancedTypeConstructorRuntimeDiagnostics)
Check(advancedTypeConstructorRuntimeDiagnostics.length = 0 And advancedTypeConstructorRuntimeC.Contains("_New__A0_void_") And advancedTypeConstructorRuntimeC.Contains("_New__A1_string_") And advancedTypeConstructorRuntimeC.Contains("_New__A1_int_") And advancedTypeConstructorRuntimeC.Contains("_New__A2_string_int_"), "bound construction signatures select the exact separate generic Type constructor helpers")

Local bodyConstructionModuleSource:String = "SuperStrict~nModule Collections.BodyConstruction~nType TBodyConstructedLeaf<T>~nField value:T~nMethod New(input:T)~nvalue = input~nEnd Method~nMethod Read:T()~nReturn value~nEnd Method~nEnd Type~nType TBodyConstructedFactory<T>~nMethod Create:TBodyConstructedLeaf<T>(input:T)~nReturn New TBodyConstructedLeaf<T>(input)~nEnd Method~nEnd Type"
Local bodyConstructionModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/bodyconstruction.mod/bodyconstruction.bmx", bodyConstructionModuleSource, Null, compilerOptions)
Local bodyConstructionArtifactDiagnostics:TCompilerDiagnostic[]
Local bodyConstructionOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(bodyConstructionModuleCompilation, bodyConstructionArtifactDiagnostics)
Local bodyConstructionInterfaceDiagnostics:TCompilerDiagnostic[]
Local bodyConstructionInterface:String = TBlitzMaxCompiler.EmitInterface(bodyConstructionModuleCompilation, bodyConstructionInterfaceDiagnostics)
Check(bodyConstructionModuleCompilation.Succeeded() And bodyConstructionArtifactDiagnostics.length = 0 And bodyConstructionInterfaceDiagnostics.length = 0 And bodyConstructionOutputs.length = 2, "parameterized construction is retained as bound generic template IR without source text")
Local bodyConstructionResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
bodyConstructionResolver.AddInterface("collections.bodyconstruction", "sdk/collections.bodyconstruction.i", bodyConstructionInterface)
For Local bodyConstructionOutput:TCompilerGenericTemplateOutput = EachIn bodyConstructionOutputs
	bodyConstructionResolver.AddGenericTemplate(bodyConstructionOutput.artifactReference, "sdk/" + bodyConstructionOutput.artifactReference, bodyConstructionOutput.content)
Next
Local bodyConstructionConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("body-construction-consumer.bmx", "SuperStrict~nImport Collections.BodyConstruction~nGlobal bodyFactory:TBodyConstructedFactory<String> = New TBodyConstructedFactory<String>~nGlobal bodyLeaf:TBodyConstructedLeaf<String> = bodyFactory.Create(~qfrom generic body~q)~nGlobal bodyValue:String = bodyLeaf.Read()", bodyConstructionResolver, compilerOptions)
Check(bodyConstructionConsumer.Succeeded() And bodyConstructionConsumer.genericPlan.registry.nodes.length = 2 And bodyConstructionConsumer.genericPlan.units.length = 2, "source-free parameterized New expands a transitive canonical specialization request: " + CompilationSummary(bodyConstructionConsumer))
Local bodyFactoryUnit:TCompilerGenericUnit
Local bodyLeafUnit:TCompilerGenericUnit
For Local bodyConstructionUnit:TCompilerGenericUnit = EachIn bodyConstructionConsumer.genericPlan.units
	If bodyConstructionUnit.specialization.artifact.identity.qualifiedName = "TBodyConstructedFactory" Then bodyFactoryUnit = bodyConstructionUnit
	If bodyConstructionUnit.specialization.artifact.identity.qualifiedName = "TBodyConstructedLeaf" Then bodyLeafUnit = bodyConstructionUnit
Next
Check(bodyFactoryUnit And bodyLeafUnit And bodyFactoryUnit.implementation.Contains(bodyLeafUnit.specialization.readableAbiName + "_New__A1_string_") And bodyFactoryUnit.implementation.Contains("(BBClass *)&" + bodyLeafUnit.specialization.readableAbiName), "generic factory implementation calls the exact constructor helper owned by the leaf specialization unit")

Local bodyStructConstructionModuleSource:String = "SuperStrict~nModule Collections.BodyStructConstruction~nStruct TBodyConstructedValue<T>~nField value:T~nMethod New(input:T)~nvalue = input~nEnd Method~nMethod Read:T()~nReturn value~nEnd Method~nEnd Struct~nType TBodyConstructedValueFactory<T>~nMethod Create:TBodyConstructedValue<T>(input:T)~nReturn New TBodyConstructedValue<T>(input)~nEnd Method~nEnd Type"
Local bodyStructConstructionModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/bodystructconstruction.mod/bodystructconstruction.bmx", bodyStructConstructionModuleSource, Null, compilerOptions)
Local bodyStructConstructionArtifactDiagnostics:TCompilerDiagnostic[]
Local bodyStructConstructionOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(bodyStructConstructionModuleCompilation, bodyStructConstructionArtifactDiagnostics)
Local bodyStructConstructionInterfaceDiagnostics:TCompilerDiagnostic[]
Local bodyStructConstructionInterface:String = TBlitzMaxCompiler.EmitInterface(bodyStructConstructionModuleCompilation, bodyStructConstructionInterfaceDiagnostics)
Check(bodyStructConstructionModuleCompilation.Succeeded() And bodyStructConstructionArtifactDiagnostics.length = 0 And bodyStructConstructionInterfaceDiagnostics.length = 0 And bodyStructConstructionOutputs.length = 2, "generic Struct construction in a generic body is retained as bound artifact data")
Local bodyStructConstructionResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
bodyStructConstructionResolver.AddInterface("collections.bodystructconstruction", "sdk/collections.bodystructconstruction.i", bodyStructConstructionInterface)
For Local bodyStructConstructionOutput:TCompilerGenericTemplateOutput = EachIn bodyStructConstructionOutputs
	bodyStructConstructionResolver.AddGenericTemplate(bodyStructConstructionOutput.artifactReference, "sdk/" + bodyStructConstructionOutput.artifactReference, bodyStructConstructionOutput.content)
Next
Local bodyStructConstructionConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("body-struct-construction-consumer.bmx", "SuperStrict~nImport Collections.BodyStructConstruction~nGlobal bodyStructFactory:TBodyConstructedValueFactory<String> = New TBodyConstructedValueFactory<String>~nGlobal bodyStructValue:TBodyConstructedValue<String> = bodyStructFactory.Create(~qvalue from generic body~q)~nGlobal bodyStructRead:String = bodyStructValue.Read()", bodyStructConstructionResolver, compilerOptions)
Check(bodyStructConstructionConsumer.Succeeded() And bodyStructConstructionConsumer.genericPlan.registry.nodes.length = 2 And bodyStructConstructionConsumer.genericPlan.units.length = 2, "source-free generic Struct New expands a transitive canonical value-specialization request: " + CompilationSummary(bodyStructConstructionConsumer))
Local bodyStructFactoryUnit:TCompilerGenericUnit
Local bodyStructValueUnit:TCompilerGenericUnit
For Local bodyStructConstructionUnit:TCompilerGenericUnit = EachIn bodyStructConstructionConsumer.genericPlan.units
	If bodyStructConstructionUnit.specialization.artifact.identity.qualifiedName = "TBodyConstructedValueFactory" Then bodyStructFactoryUnit = bodyStructConstructionUnit
	If bodyStructConstructionUnit.specialization.artifact.identity.qualifiedName = "TBodyConstructedValue" Then bodyStructValueUnit = bodyStructConstructionUnit
Next
Check(bodyStructFactoryUnit And bodyStructValueUnit And bodyStructFactoryUnit.implementation.Contains(bodyStructValueUnit.specialization.readableAbiName + "_New("), "generic value factory calls the constructor helper owned by the separate Struct specialization unit")

Local nestedModuleSource:String = "SuperStrict~nModule Collections.Nested~nType TLeaf<T>~nField value:T~nMethod First:T()~nReturn value~nEnd Method~nEnd Type~nType TFactory<T>~nMethod Create:TLeaf<T>()~nReturn New TLeaf<T>~nEnd Method~nMethod Read:T(leaf:TLeaf<T>)~nReturn leaf.First()~nEnd Method~nEnd Type"
Local nestedModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/nested.mod/nested.bmx", nestedModuleSource, Null, compilerOptions)
Local nestedArtifactDiagnostics:TCompilerDiagnostic[]
Local nestedArtifactOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(nestedModuleCompilation, nestedArtifactDiagnostics)
Local nestedInterfaceDiagnostics:TCompilerDiagnostic[]
Local nestedInterface:String = TBlitzMaxCompiler.EmitInterface(nestedModuleCompilation, nestedInterfaceDiagnostics)
Check(nestedModuleCompilation.Succeeded() And nestedArtifactDiagnostics.length = 0 And nestedInterfaceDiagnostics.length = 0 And nestedArtifactOutputs.length = 2, "a module publishes both templates required by a transitive cross-module specialization")
Local nestedResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
nestedResolver.AddInterface("collections.nested", "sdk/collections.nested.i", nestedInterface)
For Local nestedOutput:TCompilerGenericTemplateOutput = EachIn nestedArtifactOutputs
	nestedResolver.AddGenericTemplate(nestedOutput.artifactReference, "sdk/" + nestedOutput.artifactReference, nestedOutput.content)
Next
Local nestedConsumerSource:String = "SuperStrict~nImport Collections.Nested~nGlobal factory:TFactory<String>"
Local nestedConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("nested-consumer.bmx", nestedConsumerSource, nestedResolver, compilerOptions)
Check(nestedConsumerCompilation.Succeeded() And nestedConsumerCompilation.genericPlan.registry.nodes.length = 2 And nestedConsumerCompilation.genericPlan.units.length = 2, "cross-module artifact ingestion expands and lowers executable factory-to-leaf bodies without source text")

Local inheritedModuleSource:String = "SuperStrict~nModule Collections.Inherited~nType TBase<T>~nField baseValue:T~nMethod GetBase:T()~nReturn baseValue~nEnd Method~nEnd Type~nType TDerived<T> Extends TBase<T>~nField derivedValue:T~nMethod GetDerived:T()~nReturn derivedValue~nEnd Method~nEnd Type"
Local inheritedModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/inherited.mod/inherited.bmx", inheritedModuleSource, Null, compilerOptions)
Local inheritedArtifactDiagnostics:TCompilerDiagnostic[]
Local inheritedArtifactOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(inheritedModuleCompilation, inheritedArtifactDiagnostics)
Local inheritedInterfaceDiagnostics:TCompilerDiagnostic[]
Local inheritedInterface:String = TBlitzMaxCompiler.EmitInterface(inheritedModuleCompilation, inheritedInterfaceDiagnostics)
Check(inheritedModuleCompilation.Succeeded() And inheritedArtifactDiagnostics.length = 0 And inheritedInterfaceDiagnostics.length = 0 And inheritedArtifactOutputs.length = 2, "module publication emits source-free versioned artifacts for both generic base and derived templates")
Check(inheritedInterface.Contains("TDerived<T>^TBase<T>{"), "compact generic declaration publishes its parameterized base signature instead of an Object placeholder")
Local inheritedPublishedBaseFound:Int
For Local inheritedOutput:TCompilerGenericTemplateOutput = EachIn inheritedArtifactOutputs
	Local inheritedDecoded:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(inheritedOutput.content, inheritedOutput.artifact.EffectiveContentRevision())
	If inheritedDecoded.Succeeded() And inheritedDecoded.artifact.identity.qualifiedName = "TDerived" And inheritedDecoded.artifact.baseType Then inheritedPublishedBaseFound = True
Next
Check(inheritedPublishedBaseFound, "published derived artifact round-trips its parameterized base reference without source text")
Local inheritedResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
inheritedResolver.AddInterface("collections.inherited", "sdk/collections.inherited.i", inheritedInterface)
For Local inheritedOutput:TCompilerGenericTemplateOutput = EachIn inheritedArtifactOutputs
	inheritedResolver.AddGenericTemplate(inheritedOutput.artifactReference, "sdk/" + inheritedOutput.artifactReference, inheritedOutput.content)
Next
Local inheritedConsumerSource:String = "SuperStrict~nImport Collections.Inherited~nGlobal item:TDerived<String> = New TDerived<String>~nitem.baseValue = ~qexternal-base~q~nitem.derivedValue = ~qexternal-derived~q~nGlobal externalBase:String = item.GetBase()~nGlobal externalDerived:String = item.GetDerived()"
Local inheritedConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("inherited-consumer.bmx", inheritedConsumerSource, inheritedResolver, compilerOptions)
Check(inheritedConsumerCompilation.Succeeded() And inheritedConsumerCompilation.genericPlan.registry.nodes.length = 2 And inheritedConsumerCompilation.genericPlan.units.length = 2, "cross-module generic inheritance specializes entirely from compact interface and versioned artifacts: " + CompilationSummary(inheritedConsumerCompilation))
Local inheritedConsumerDerivedUnit:TCompilerGenericUnit
Local inheritedConsumerBaseNode:TGenericSpecializationNode
For Local inheritedConsumerUnit:TCompilerGenericUnit = EachIn inheritedConsumerCompilation.genericPlan.units
	If inheritedConsumerUnit.specialization.artifact.identity.qualifiedName = "TBase" Then inheritedConsumerBaseNode = inheritedConsumerUnit.specialization
	If inheritedConsumerUnit.specialization.artifact.identity.qualifiedName = "TDerived" Then inheritedConsumerDerivedUnit = inheritedConsumerUnit
Next
Check(inheritedConsumerDerivedUnit And inheritedConsumerDerivedUnit.ir.baseSpecialization = inheritedConsumerBaseNode And inheritedConsumerDerivedUnit.ir.fields.length = 2 And inheritedConsumerDerivedUnit.ir.methods.length = 2, "source-free derived IR reconstructs inherited field and slot prefixes with canonical ownership")
Check(inheritedConsumerDerivedUnit.implementation.Contains(" - offsetof(struct " + inheritedConsumerDerivedUnit.specialization.readableAbiName + "_obj, " + inheritedConsumerDerivedUnit.ir.fields[0].abiName + ")"), "generic derived descriptor GC range begins at its inherited field rather than only its declared suffix")
Local inheritedConsumerRuntimeDiagnostics:TCompilerDiagnostic[]
Local inheritedConsumerRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(inheritedConsumerCompilation, inheritedConsumerRuntimeDiagnostics)
Check(inheritedConsumerRuntimeDiagnostics.length = 0 And inheritedConsumerRuntimeC.Contains("->clas->m_getbase_0") And inheritedConsumerRuntimeC.Contains("->clas->m_getderived_1"), "cross-module application C uses compatible inherited and declared dispatch slots")
Local inheritedConsumerHeaderDiagnostics:TCompilerDiagnostic[]
Local inheritedConsumerHeader:String = TBlitzMaxCompiler.EmitRuntimeHeader(inheritedConsumerCompilation, inheritedConsumerHeaderDiagnostics)
Check(inheritedConsumerHeaderDiagnostics.length = 0 And AppearsBefore(inheritedConsumerHeader, "struct " + inheritedConsumerBaseNode.readableAbiName + "_obj;", "struct " + inheritedConsumerBaseNode.readableAbiName + "_class {") And AppearsBefore(inheritedConsumerHeader, "struct " + inheritedConsumerDerivedUnit.specialization.readableAbiName + "_obj;", "struct " + inheritedConsumerBaseNode.readableAbiName + "_class {"), "application headers publish every generic Type tag before the first specialization class layout")

Local hiddenFieldModuleSource:String = "SuperStrict~nModule Collections.HiddenFields~nType THiddenBase<T>~nField value:T~nMethod SetBase(input:T)~nvalue = input~nEnd Method~nMethod ReadBase:T()~nReturn value~nEnd Method~nEnd Type~nType THiddenDerived<T> Extends THiddenBase<T>~nField value:T~nMethod SetDerived(input:T)~nvalue = input~nEnd Method~nMethod ReadDerived:T()~nReturn value~nEnd Method~nEnd Type"
Local hiddenFieldModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/hiddenfields.mod/hiddenfields.bmx", hiddenFieldModuleSource, Null, compilerOptions)
Local hiddenFieldArtifactDiagnostics:TCompilerDiagnostic[]
Local hiddenFieldOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(hiddenFieldModuleCompilation, hiddenFieldArtifactDiagnostics)
Local hiddenFieldInterfaceDiagnostics:TCompilerDiagnostic[]
Local hiddenFieldInterface:String = TBlitzMaxCompiler.EmitInterface(hiddenFieldModuleCompilation, hiddenFieldInterfaceDiagnostics)
Local hiddenFieldResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
hiddenFieldResolver.AddInterface("collections.hiddenfields", "sdk/collections.hiddenfields.i", hiddenFieldInterface)
For Local hiddenFieldOutput:TCompilerGenericTemplateOutput = EachIn hiddenFieldOutputs
	hiddenFieldResolver.AddGenericTemplate(hiddenFieldOutput.artifactReference, "sdk/" + hiddenFieldOutput.artifactReference, hiddenFieldOutput.content)
Next
Local hiddenFieldConsumerSource:String = "SuperStrict~nImport Collections.HiddenFields~nGlobal hidden:THiddenDerived<String> = New THiddenDerived<String>~nhidden.SetBase(~qbase~q)~nhidden.SetDerived(~qderived~q)~nGlobal baseValue:String = hidden.ReadBase()~nGlobal derivedValue:String = hidden.ReadDerived()"
Local hiddenFieldConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("hidden-field-consumer.bmx", hiddenFieldConsumerSource, hiddenFieldResolver, compilerOptions)
Local hiddenFieldConsumerDerived:TCompilerGenericUnit
For Local hiddenFieldConsumerUnit:TCompilerGenericUnit = EachIn hiddenFieldConsumer.genericPlan.units
	If hiddenFieldConsumerUnit.specialization.artifact.identity.qualifiedName = "THiddenDerived" Then hiddenFieldConsumerDerived = hiddenFieldConsumerUnit
Next
Check(hiddenFieldModuleCompilation.Succeeded() And hiddenFieldArtifactDiagnostics.length = 0 And hiddenFieldInterfaceDiagnostics.length = 0 And hiddenFieldConsumer.Succeeded(), "hidden inherited fields round-trip through source-free generic artifacts: " + CompilationSummary(hiddenFieldConsumer))
Check(hiddenFieldConsumerDerived And hiddenFieldConsumerDerived.ir.fields.length = 2 And hiddenFieldConsumerDerived.ir.fields[0].abiName <> hiddenFieldConsumerDerived.ir.fields[1].abiName, "cross-module specialization reconstructs both declaration-owned hidden field ABIs")

Local inheritedReceiverModuleSource:String = "SuperStrict~nModule Collections.InheritedReceivers~nType TReceiverBase<T>~nField value:T~nMethod Read:T()~nReturn value~nEnd Method~nEnd Type~nType TReceiverDerived<T> Extends TReceiverBase<T>~nField value:T~nField peer:TReceiverBase<T>~nMethod Read:T() Override~nReturn value~nEnd Method~nMethod FromParameter:T(other:TReceiverBase<T>)~nReturn other.Read()~nEnd Method~nMethod FromField:T()~nReturn peer.Read()~nEnd Method~nMethod FromLocal:T(other:TReceiverDerived<T>)~nLocal widened:TReceiverBase<T> = other~nReturn widened.Read()~nEnd Method~nMethod FromSelf:T()~nReturn Self.Read()~nEnd Method~nMethod FromSuper:T()~nReturn Super.Read()~nEnd Method~nEnd Type"
Local inheritedReceiverModule:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/inheritedreceivers.mod/inheritedreceivers.bmx", inheritedReceiverModuleSource, Null, compilerOptions)
Local inheritedReceiverArtifactDiagnostics:TCompilerDiagnostic[]
Local inheritedReceiverOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(inheritedReceiverModule, inheritedReceiverArtifactDiagnostics)
Local inheritedReceiverInterfaceDiagnostics:TCompilerDiagnostic[]
Local inheritedReceiverInterface:String = TBlitzMaxCompiler.EmitInterface(inheritedReceiverModule, inheritedReceiverInterfaceDiagnostics)
Local inheritedReceiverResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
inheritedReceiverResolver.AddInterface("collections.inheritedreceivers", "sdk/collections.inheritedreceivers.i", inheritedReceiverInterface)
For Local inheritedReceiverOutput:TCompilerGenericTemplateOutput = EachIn inheritedReceiverOutputs
	inheritedReceiverResolver.AddGenericTemplate(inheritedReceiverOutput.artifactReference, "sdk/" + inheritedReceiverOutput.artifactReference, inheritedReceiverOutput.content)
Next
Local inheritedReceiverConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("inherited-receiver-consumer.bmx", "SuperStrict~nImport Collections.InheritedReceivers~nGlobal item:TReceiverDerived<String>", inheritedReceiverResolver, compilerOptions)
Local inheritedReceiverBaseUnit:TCompilerGenericUnit
Local inheritedReceiverDerivedUnit:TCompilerGenericUnit
For Local inheritedReceiverUnit:TCompilerGenericUnit = EachIn inheritedReceiverConsumer.genericPlan.units
	If inheritedReceiverUnit.specialization.artifact.identity.qualifiedName = "TReceiverBase" Then inheritedReceiverBaseUnit = inheritedReceiverUnit
	If inheritedReceiverUnit.specialization.artifact.identity.qualifiedName = "TReceiverDerived" Then inheritedReceiverDerivedUnit = inheritedReceiverUnit
Next
Check(inheritedReceiverModule.Succeeded() And inheritedReceiverArtifactDiagnostics.length = 0 And inheritedReceiverInterfaceDiagnostics.length = 0 And inheritedReceiverConsumer.Succeeded(), "parameter, field, local, Self, and Super inherited receiver shapes round-trip without source text: " + CompilationSummary(inheritedReceiverConsumer))
Check(inheritedReceiverBaseUnit And inheritedReceiverDerivedUnit And inheritedReceiverDerivedUnit.implementation.Contains("struct " + inheritedReceiverBaseUnit.specialization.readableAbiName + "_class {") And inheritedReceiverDerivedUnit.implementation.Contains("->clas->m_read_0"), "a separate derived unit carries the complete referenced base class-table declaration required by virtual receiver dispatch")
Check(inheritedReceiverDerivedUnit.implementation.Contains(inheritedReceiverBaseUnit.ir.methods[0].abiName + "((struct " + inheritedReceiverBaseUnit.specialization.readableAbiName + "_obj *)") And inheritedReceiverDerivedUnit.implementation.Contains("self->clas->m_read_0"), "qualified Super remains direct while Self and widened receiver shapes remain virtual")

Local interfaceModuleSource:String = "SuperStrict~nModule Collections.InterfaceValue~nInterface IValue<T>~nMethod Read:T()~nMethod Echo:T(value:T)~nEnd Interface~nType TValue<T> Implements IValue<T>~nField value:T~nMethod Read:T()~nReturn value~nEnd Method~nMethod Echo:T(input:T)~nReturn input~nEnd Method~nEnd Type~nFunction ReadVia<T>:T(value:IValue<T>, fallback:T)~nReturn value.Echo(fallback)~nEnd Function"
Local interfaceModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/interfacevalue.mod/interfacevalue.bmx", interfaceModuleSource, Null, compilerOptions)
Local interfaceModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local interfaceModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(interfaceModuleCompilation, interfaceModuleArtifactDiagnostics)
Local interfaceModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local interfaceModuleInterface:String = TBlitzMaxCompiler.EmitInterface(interfaceModuleCompilation, interfaceModuleInterfaceDiagnostics)
Check(interfaceModuleCompilation.Succeeded() And interfaceModuleArtifactDiagnostics.length = 0 And interfaceModuleInterfaceDiagnostics.length = 0 And interfaceModuleOutputs.length = 3, "module publication emits separate source-free generic Interface, implementing-Type, and Interface-calling routine artifacts")
Check(interfaceModuleInterface.Contains("IValue<T>^Object{") And interfaceModuleInterface.Contains("}AIK") And interfaceModuleInterface.Contains("@IValue<T>"), "compact publication preserves generic Interface flavor and the implementing relationship")
Local interfaceModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
interfaceModuleResolver.AddInterface("collections.interfacevalue", "sdk/collections.interfacevalue.i", interfaceModuleInterface)
For Local interfaceModuleOutput:TCompilerGenericTemplateOutput = EachIn interfaceModuleOutputs
	interfaceModuleResolver.AddGenericTemplate(interfaceModuleOutput.artifactReference, "sdk/" + interfaceModuleOutput.artifactReference, interfaceModuleOutput.content)
Next
Local interfaceModuleConsumerSource:String = "SuperStrict~nImport Collections.InterfaceValue~nGlobal concrete:TValue<String> = New TValue<String>~nconcrete.value = ~qexternal-interface~q~nGlobal abstract:IValue<String> = concrete~nGlobal externalInterfaceValue:String = abstract.Read()~nGlobal externalInterfaceVia:String = ReadVia<String>(abstract, ~qsource-free-call~q)"
Local interfaceModuleConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("interface-value-consumer.bmx", interfaceModuleConsumerSource, interfaceModuleResolver, compilerOptions)
Check(interfaceModuleConsumerCompilation.Succeeded() And interfaceModuleConsumerCompilation.genericPlan.registry.nodes.length = 3 And interfaceModuleConsumerCompilation.genericPlan.units.length = 3, "cross-module generic Interface calls reconstruct descriptor, table, and routine ownership entirely from compact interface and artifacts: " + CompilationSummary(interfaceModuleConsumerCompilation))
Local interfaceModuleRoutineUnit:TCompilerGenericUnit
For Local interfaceModuleConsumerUnit:TCompilerGenericUnit = EachIn interfaceModuleConsumerCompilation.genericPlan.units
	If interfaceModuleConsumerUnit.ir.isRoutine Then interfaceModuleRoutineUnit = interfaceModuleConsumerUnit; Exit
Next
Check(interfaceModuleRoutineUnit And interfaceModuleRoutineUnit.implementation.Contains("bbObjectInterface") And interfaceModuleRoutineUnit.implementation.Contains("_call_m_echo_1((BBOBJECT)value, fallback)"), "source-free specialization restores the symbolic Interface call and closed argument signature")
Local interfaceModuleConsumerRuntimeDiagnostics:TCompilerDiagnostic[]
Local interfaceModuleConsumerRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(interfaceModuleConsumerCompilation, interfaceModuleConsumerRuntimeDiagnostics)
Check(interfaceModuleConsumerRuntimeDiagnostics.length = 0 And interfaceModuleConsumerRuntimeC.Contains("bbObjectInterface") And interfaceModuleConsumerRuntimeC.Contains("_ifc"), "cross-module application C performs canonical generic Interface conversion and dispatch")

Local defaultInterfaceModuleSource:String = "SuperStrict~nModule Collections.DefaultInterface~nInterface IDefaultValue<T>~nMethod Identity:T(value:T)~nMethod Describe:T(value:T) Default~nReturn Self.Identity(value)~nEnd Method~nEnd Interface~nType TDefaultValue<T> Implements IDefaultValue<T>~nMethod Identity:T(value:T)~nReturn value~nEnd Method~nEnd Type"
Local defaultInterfaceModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/defaultinterface.mod/defaultinterface.bmx", defaultInterfaceModuleSource, Null, compilerOptions)
Local defaultInterfaceModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local defaultInterfaceModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(defaultInterfaceModuleCompilation, defaultInterfaceModuleArtifactDiagnostics)
Local defaultInterfaceModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local defaultInterfaceModuleInterface:String = TBlitzMaxCompiler.EmitInterface(defaultInterfaceModuleCompilation, defaultInterfaceModuleInterfaceDiagnostics)
Check(defaultInterfaceModuleCompilation.Succeeded() And defaultInterfaceModuleArtifactDiagnostics.length = 0 And defaultInterfaceModuleInterfaceDiagnostics.length = 0 And defaultInterfaceModuleOutputs.length = 2 And Not defaultInterfaceModuleInterface.Contains("Return Self.Identity"), "module publication retains a generic Interface Default body only in its source-free template artifact")
Local defaultInterfaceModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
defaultInterfaceModuleResolver.AddInterface("collections.defaultinterface", "sdk/collections.defaultinterface.i", defaultInterfaceModuleInterface)
For Local defaultInterfaceModuleOutput:TCompilerGenericTemplateOutput = EachIn defaultInterfaceModuleOutputs
	defaultInterfaceModuleResolver.AddGenericTemplate(defaultInterfaceModuleOutput.artifactReference, "sdk/" + defaultInterfaceModuleOutput.artifactReference, defaultInterfaceModuleOutput.content)
Next
Local defaultInterfaceConsumerSource:String = "SuperStrict~nImport Collections.DefaultInterface~nGlobal concrete:TDefaultValue<String> = New TDefaultValue<String>~nGlobal abstract:IDefaultValue<String> = concrete~nGlobal described:String = abstract.Describe(~qsource-free-default~q)"
Local defaultInterfaceConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("default-interface-consumer.bmx", defaultInterfaceConsumerSource, defaultInterfaceModuleResolver, compilerOptions)
Local importedDefaultInterfaceUnit:TCompilerGenericUnit
Local importedDefaultTypeUnit:TCompilerGenericUnit
For Local importedDefaultUnit:TCompilerGenericUnit = EachIn defaultInterfaceConsumerCompilation.genericPlan.units
	If importedDefaultUnit.ir.isInterface Then importedDefaultInterfaceUnit = importedDefaultUnit Else importedDefaultTypeUnit = importedDefaultUnit
Next
Check(defaultInterfaceConsumerCompilation.Succeeded(), "a consumer reconstructs and specializes a published generic Interface Default without source text: " + CompilationSummary(defaultInterfaceConsumerCompilation))
Check(importedDefaultInterfaceUnit And importedDefaultInterfaceUnit.ir.methods[1].interfaceMethodKind = TEMPLATE_INTERFACE_METHOD_DEFAULT And importedDefaultInterfaceUnit.implementation.Contains(importedDefaultInterfaceUnit.ir.methods[1].abiName + "(BBOBJECT self"), "the imported closed Interface unit owns its reconstructed Default body")
Check(importedDefaultTypeUnit And importedDefaultTypeUnit.implementation.Contains(importedDefaultInterfaceUnit.ir.methods[1].abiName), "the imported implementing Type table references the one Interface-owned Default implementation")

Local multipleInterfaceModuleSource:String = "SuperStrict~nModule Collections.MultiInterface~nInterface IRoot<T>~nMethod Read:T()~nEnd Interface~nInterface ILeft<T> Extends IRoot<T>~nMethod Left:T()~nEnd Interface~nInterface IRight<T> Extends IRoot<T>~nMethod Right:T()~nEnd Interface~nInterface IDiamond<T> Extends ILeft<T>, IRight<T>~nMethod Diamond:T()~nEnd Interface~nInterface IExtra<T>~nMethod Extra:T()~nEnd Interface~nType TMultiValue<T> Implements IDiamond<T>, IExtra<T>~nField value:T~nMethod Read:T()~nReturn value~nEnd Method~nMethod Left:T()~nReturn value~nEnd Method~nMethod Right:T()~nReturn value~nEnd Method~nMethod Diamond:T()~nReturn value~nEnd Method~nMethod Extra:T()~nReturn value~nEnd Method~nEnd Type"
Local multipleInterfaceModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/multiinterface.mod/multiinterface.bmx", multipleInterfaceModuleSource, Null, compilerOptions)
Local multipleInterfaceModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local multipleInterfaceModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(multipleInterfaceModuleCompilation, multipleInterfaceModuleArtifactDiagnostics)
Local multipleInterfaceModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local multipleInterfaceModuleInterface:String = TBlitzMaxCompiler.EmitInterface(multipleInterfaceModuleCompilation, multipleInterfaceModuleInterfaceDiagnostics)
Check(multipleInterfaceModuleCompilation.Succeeded() And multipleInterfaceModuleArtifactDiagnostics.length = 0 And multipleInterfaceModuleInterfaceDiagnostics.length = 0 And multipleInterfaceModuleOutputs.length = 6, "module publication emits the complete source-free generic Interface inheritance graph")
Check(multipleInterfaceModuleInterface.Contains("IDiamond<T>^ILeft<T>@IRight<T>{") And multipleInterfaceModuleInterface.Contains("TMultiValue<T>^Object@IDiamond<T>,IExtra<T>{"), "compact publication preserves multiple Interface parents separately from Type implementations")
Local multipleInterfaceModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
multipleInterfaceModuleResolver.AddInterface("collections.multiinterface", "sdk/collections.multiinterface.i", multipleInterfaceModuleInterface)
For Local multipleInterfaceModuleOutput:TCompilerGenericTemplateOutput = EachIn multipleInterfaceModuleOutputs
	multipleInterfaceModuleResolver.AddGenericTemplate(multipleInterfaceModuleOutput.artifactReference, "sdk/" + multipleInterfaceModuleOutput.artifactReference, multipleInterfaceModuleOutput.content)
Next
Local multipleInterfaceConsumerSource:String = "SuperStrict~nImport Collections.MultiInterface~nGlobal externalMulti:TMultiValue<String> = New TMultiValue<String>~nexternalMulti.value = ~qexternal-multiple~q~nGlobal externalRoot:IRoot<String> = externalMulti~nGlobal externalDiamond:IDiamond<String> = externalMulti~nGlobal externalExtra:IExtra<String> = externalMulti~nGlobal externalRootValue:String = externalRoot.Read()~nGlobal externalDiamondValue:String = externalDiamond.Diamond()~nGlobal externalExtraValue:String = externalExtra.Extra()"
Local multipleInterfaceConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("multi-interface-consumer.bmx", multipleInterfaceConsumerSource, multipleInterfaceModuleResolver, compilerOptions)
Check(multipleInterfaceConsumerCompilation.Succeeded() And multipleInterfaceConsumerCompilation.genericPlan.registry.nodes.length = 6 And multipleInterfaceConsumerCompilation.genericPlan.units.length = 6, "source-free consumer reconstructs the canonical diamond and multiple-Interface ownership graph: " + CompilationSummary(multipleInterfaceConsumerCompilation))
Local multipleInterfaceConsumerTypeUnit:TCompilerGenericUnit
For Local multipleInterfaceConsumerUnit:TCompilerGenericUnit = EachIn multipleInterfaceConsumerCompilation.genericPlan.units
	If multipleInterfaceConsumerUnit.specialization.artifact.identity.qualifiedName = "TMultiValue" Then multipleInterfaceConsumerTypeUnit = multipleInterfaceConsumerUnit; Exit
Next
Check(multipleInterfaceConsumerTypeUnit And multipleInterfaceConsumerTypeUnit.ir.implementedInterfaces.length = 5 And multipleInterfaceConsumerTypeUnit.implementation.Contains(", 5 };"), "source-free implementing Type retains one table for every deduplicated effective Interface")
Local multipleInterfaceConsumerRuntimeDiagnostics:TCompilerDiagnostic[]
Local multipleInterfaceConsumerRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(multipleInterfaceConsumerCompilation, multipleInterfaceConsumerRuntimeDiagnostics)
Check(multipleInterfaceConsumerRuntimeDiagnostics.length = 0 And multipleInterfaceConsumerRuntimeC.Contains("m_read_0") And multipleInterfaceConsumerRuntimeC.Contains("m_diamond_3"), "source-free application C dispatches root and derived Interface slots through compatible ABIs")

Local covariantInterfaceModuleSource:String = "SuperStrict~nModule Collections.CovariantInterface~nInterface IObjectValue<T>~nMethod Value:Object()~nEnd Interface~nInterface IStringValue<T>~nMethod Value:String()~nEnd Interface~nInterface ICombinedValue<T> Extends IObjectValue<T>, IStringValue<T>~nEnd Interface~nType TStringValue<T> Implements ICombinedValue<T>~nMethod Value:String()~nReturn ~qvalue~q~nEnd Method~nEnd Type"
Local covariantInterfaceModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/covariantinterface.mod/covariantinterface.bmx", covariantInterfaceModuleSource, Null, compilerOptions)
Local covariantInterfaceArtifactDiagnostics:TCompilerDiagnostic[]
Local covariantInterfaceOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(covariantInterfaceModuleCompilation, covariantInterfaceArtifactDiagnostics)
Local covariantInterfacePublicationDiagnostics:TCompilerDiagnostic[]
Local covariantInterfacePublication:String = TBlitzMaxCompiler.EmitInterface(covariantInterfaceModuleCompilation, covariantInterfacePublicationDiagnostics)
Local covariantInterfaceResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
covariantInterfaceResolver.AddInterface("collections.covariantinterface", "sdk/collections.covariantinterface.i", covariantInterfacePublication)
For Local covariantInterfaceOutput:TCompilerGenericTemplateOutput = EachIn covariantInterfaceOutputs
	covariantInterfaceResolver.AddGenericTemplate(covariantInterfaceOutput.artifactReference, "sdk/" + covariantInterfaceOutput.artifactReference, covariantInterfaceOutput.content)
Next
Local covariantInterfaceConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("covariant-interface-consumer.bmx", "SuperStrict~nImport Collections.CovariantInterface~nGlobal concrete:TStringValue<Int> = New TStringValue<Int>~nGlobal combined:ICombinedValue<Int> = concrete~nGlobal value:Object = combined.Value()", covariantInterfaceResolver, compilerOptions)
Local covariantInterfaceConsumerCombined:TCompilerGenericUnit
If covariantInterfaceConsumer.genericPlan Then
	For Local covariantConsumerUnit:TCompilerGenericUnit = EachIn covariantInterfaceConsumer.genericPlan.units
		If covariantConsumerUnit.specialization.artifact.identity.qualifiedName = "ICombinedValue" Then covariantInterfaceConsumerCombined = covariantConsumerUnit
	Next
End If
Check(covariantInterfaceModuleCompilation.Succeeded() And covariantInterfaceArtifactDiagnostics.length = 0 And covariantInterfacePublicationDiagnostics.length = 0 And covariantInterfaceConsumer.Succeeded(), "covariant generic Interface selector refinement round-trips without source text: " + CompilationSummary(covariantInterfaceConsumer))
Check(covariantInterfaceConsumerCombined And covariantInterfaceConsumerCombined.ir.methods.length = 1 And covariantInterfaceConsumerCombined.ir.methods[0].returnType.CanonicalName() = "object", "source-free Interface closure reconstructs the production-compatible parent-ordered selector")

Local incompatibleInterfaceSource:String = "SuperStrict~nInterface IGenericNumber<T>~nMethod Value:T()~nEnd Interface~nInterface IGenericText<T>~nMethod Value:String()~nEnd Interface~nInterface IGenericCollision<T> Extends IGenericNumber<T>, IGenericText<T>~nEnd Interface~nGlobal invalidCollision:IGenericCollision<Int>"
Local incompatibleInterfaceCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("incompatible-generic-interface-slots.bmx", incompatibleInterfaceSource, Null, compilerOptions)
Check(HasCompilerDiagnostic(incompatibleInterfaceCompilation, "BMXC3081"), "closed generic Interface selectors reject incompatible canonical return ABIs explicitly")

Local compatibleClosedInterfaceSource:String = "SuperStrict~nInterface IGenericValue<T>~nMethod Value:T()~nEnd Interface~nInterface IGenericString<T>~nMethod Value:String()~nEnd Interface~nInterface IClosedCompatible<T> Extends IGenericValue<T>, IGenericString<T>~nEnd Interface~nGlobal compatibleCollision:IClosedCompatible<String>"
Local compatibleClosedInterfaceCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("compatible-generic-interface-slots.bmx", compatibleClosedInterfaceSource, Null, compilerOptions)
Local compatibleClosedInterfaceUnit:TCompilerGenericUnit
If compatibleClosedInterfaceCompilation.genericPlan Then
	For Local compatibleClosedUnit:TCompilerGenericUnit = EachIn compatibleClosedInterfaceCompilation.genericPlan.units
		If compatibleClosedUnit.specialization.artifact.identity.qualifiedName = "IClosedCompatible" Then compatibleClosedInterfaceUnit = compatibleClosedUnit
	Next
End If
Check(compatibleClosedInterfaceCompilation.Succeeded() And compatibleClosedInterfaceUnit And compatibleClosedInterfaceUnit.ir.methods.length = 1, "closed compatible generic Interface selectors deduplicate to one canonical slot")

Local constrainedSource:String = "SuperStrict~nModule Constraints.Local~nInterface IMarker~nEnd Interface~nType TMarked Implements IMarker~nEnd Type~nType TConstrained<T> Where T Extends IMarker~nField value:T~nMethod Read:T()~nReturn value~nEnd Method~nEnd Type~nGlobal constrained:TConstrained<TMarked>"
Local constrainedCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/constraints.mod/local.mod/local.bmx", constrainedSource, Null, compilerOptions)
Check(constrainedCompilation.Succeeded() And constrainedCompilation.genericPlan.registry.nodes.length = 1 And constrainedCompilation.genericPlan.units.length = 1, "a published named Type satisfying an Interface bound becomes one canonical specialization: " + CompilationSummary(constrainedCompilation))
Local constrainedArtifact:TGenericTemplateArtifact = constrainedCompilation.genericPlan.templateOutputs[0].artifact
For Local constrainedOutput:TCompilerGenericTemplateOutput = EachIn constrainedCompilation.genericPlan.templateOutputs
	If constrainedOutput.artifact.identity.qualifiedName = "TConstrained" Then constrainedArtifact = constrainedOutput.artifact; Exit
Next
Check(constrainedArtifact.parameters[0].constraints.length = 1 And constrainedArtifact.parameters[0].constraints[0].CanonicalName().Contains("imarker"), "source-free Type artifact publishes the ordered symbolic Interface bound")

Local constrainedRoutineSource:String = "SuperStrict~nModule Constraints.Routine~nInterface IMarker~nEnd Interface~nType TMarked Implements IMarker~nEnd Type~nFunction Keep<T>:T(value:T) Where T Extends IMarker~nReturn value~nEnd Function~nGlobal marked:TMarked = New TMarked~nGlobal retained:TMarked = Keep<TMarked>(marked)"
Local constrainedRoutineCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/constraints.mod/routine.mod/routine.bmx", constrainedRoutineSource, Null, compilerOptions)
Check(constrainedRoutineCompilation.Succeeded() And constrainedRoutineCompilation.genericPlan.registry.nodes.length = 1, "a generic routine with a satisfied Interface bound specializes from its bound body: " + CompilationSummary(constrainedRoutineCompilation))
Check(constrainedRoutineCompilation.genericPlan.templateOutputs[0].artifact.parameters[0].constraints.length = 1, "routine-owned constraints are published with routine-owned parameter references")

Local constraintModuleSource:String = "SuperStrict~nModule Constraints.Api~nInterface IMarker~nEnd Interface~nType TBase Implements IMarker~nEnd Type~nType TChild Extends TBase~nEnd Type~nType TBox<T> Where T Extends IMarker~nField value:T~nMethod Read:T()~nReturn value~nEnd Method~nEnd Type~nFunction Keep<T>:T(value:T) Where T Extends IMarker~nReturn value~nEnd Function"
Local constraintModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/constraints.mod/api.mod/api.bmx", constraintModuleSource, Null, compilerOptions)
Local constraintModuleArtifactDiagnostics:TCompilerDiagnostic[]
Local constraintModuleOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(constraintModuleCompilation, constraintModuleArtifactDiagnostics)
Local constraintModuleInterfaceDiagnostics:TCompilerDiagnostic[]
Local constraintModuleInterface:String = TBlitzMaxCompiler.EmitInterface(constraintModuleCompilation, constraintModuleInterfaceDiagnostics)
Check(constraintModuleCompilation.Succeeded() And constraintModuleArtifactDiagnostics.length = 0 And constraintModuleInterfaceDiagnostics.length = 0 And constraintModuleOutputs.length = 2, "constraint module publishes Type and routine companions without source text")
Check(constraintModuleInterface.Contains("TBox<T>") And constraintModuleInterface.Contains("Where T Extends IMarker") And Not constraintModuleInterface.Contains("@generic-source"), "ordinary compact signatures retain public bounds while companions remain source-free: " + constraintModuleInterface)
Local constraintModuleResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
constraintModuleResolver.AddInterface("constraints.api", "sdk/constraints.api.i", constraintModuleInterface)
For Local constraintModuleOutput:TCompilerGenericTemplateOutput = EachIn constraintModuleOutputs
	constraintModuleResolver.AddGenericTemplate(constraintModuleOutput.artifactReference, "sdk/" + constraintModuleOutput.artifactReference, constraintModuleOutput.content)
Next
Local constraintConsumerSource:String = "SuperStrict~nImport Constraints.Api~nGlobal child:TChild~nGlobal box:TBox<TChild> = New TBox<TChild>~nbox.value = child~nGlobal inherited:TChild = box.Read()~nGlobal kept:TChild = Keep<TChild>(child)"
Local constraintConsumerCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("constraint-consumer.bmx", constraintConsumerSource, constraintModuleResolver, compilerOptions)
Check(constraintConsumerCompilation.Succeeded() And constraintConsumerCompilation.genericPlan.registry.nodes.length = 2 And constraintConsumerCompilation.genericPlan.units.length = 2, "cross-module inherited Interface satisfaction produces canonical Type and routine specializations: " + CompilationSummary(constraintConsumerCompilation))
Local constraintManifestDiagnostics:TCompilerDiagnostic[]
Local constraintManifest:String = TBlitzMaxCompiler.EmitGenericManifest(constraintConsumerCompilation, constraintManifestDiagnostics)
Check(constraintManifestDiagnostics.length = 0 And constraintManifest.Contains("constraints.api::tbox#type/1") And constraintManifest.Contains("constraints.api::keep#routine/1"), "constraint specializations retain deterministic imported identities and ownership")
Local repeatedConstraintConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("constraint-consumer.bmx", constraintConsumerSource, constraintModuleResolver, compilerOptions)
Local repeatedConstraintManifestDiagnostics:TCompilerDiagnostic[]
Local repeatedConstraintManifest:String = TBlitzMaxCompiler.EmitGenericManifest(repeatedConstraintConsumer, repeatedConstraintManifestDiagnostics)
Check(repeatedConstraintConsumer.Succeeded() And repeatedConstraintManifestDiagnostics.length = 0 And repeatedConstraintManifest = constraintManifest, "constraint request identities, owners, units, and cache keys are deterministic across repeated planning")
Local invalidConstraintConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("constraint-invalid-consumer.bmx", "SuperStrict~nImport Constraints.Api~nGlobal invalid:TBox<String>", constraintModuleResolver, compilerOptions)
Check(Not invalidConstraintConsumer.Succeeded() And HasLanguageDiagnostic(invalidConstraintConsumer, "BMX3209"), "imported Type constraints reject an invalid closed argument at its consumer provenance: " + CompilationSummary(invalidConstraintConsumer))
Local invalidRoutineConstraintConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("constraint-invalid-routine-consumer.bmx", "SuperStrict~nImport Constraints.Api~nGlobal invalid:String = Keep<String>(~qinvalid~q)", constraintModuleResolver, compilerOptions)
Check(Not invalidRoutineConstraintConsumer.Succeeded() And HasLanguageDiagnostic(invalidRoutineConstraintConsumer, "BMX3302"), "imported routine constraints participate in overload applicability and reject invalid explicit arguments: " + CompilationSummary(invalidRoutineConstraintConsumer))
Local explicitConstructorSource:String = "SuperStrict~nStruct TConstructed<T>~nField stored:T~nField count:Int~nMethod New(value:T, amount:Int)~nstored = value~ncount = amount~nEnd Method~nMethod Read:T()~nReturn stored~nEnd Method~nEnd Struct~nGlobal constructed:TConstructed<String> = New TConstructed<String>(~qconstructor~q, 7)~nGlobal constructedValue:String = constructed.Read()"
Local explicitConstructorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-constructor.bmx", explicitConstructorSource, Null, compilerOptions)
Check(explicitConstructorCompilation.Succeeded() And explicitConstructorCompilation.genericPlan.registry.nodes.length = 1 And explicitConstructorCompilation.genericPlan.units.length = 1, "one bound generic Struct constructor specializes without reparsing source: " + CompilationSummary(explicitConstructorCompilation))
Local explicitConstructorUnit:TCompilerGenericUnit = explicitConstructorCompilation.genericPlan.units[0]
Check(explicitConstructorUnit.ir.constructor And explicitConstructorUnit.ir.constructor.parameters.length = 2, "typed specialization IR retains substituted constructor parameters")
Local firstConstructorAssignment:Int = explicitConstructorUnit.implementation.Find(" = bmx_ctor_value;")
Local secondConstructorAssignment:Int = explicitConstructorUnit.implementation.Find(" = bmx_ctor_amount;")
Check(explicitConstructorUnit.implementation.Contains("_New(BBSTRING bmx_ctor_value, BBINT bmx_ctor_amount)") And firstConstructorAssignment >= 0 And secondConstructorAssignment > firstConstructorAssignment, "specialization helper initializes storage and executes bound constructor assignments in source order")
Local explicitConstructorRuntimeDiagnostics:TCompilerDiagnostic[]
Local explicitConstructorRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(explicitConstructorCompilation, explicitConstructorRuntimeDiagnostics)
Check(explicitConstructorRuntimeDiagnostics.length = 0 And explicitConstructorRuntimeC.Contains("_New((BBString*)&"), "application C selects the canonical parameterized Struct helper")
Local nestedConstructorSource:String = "SuperStrict~nStruct TConstructorInner<T>~nField value:T~nEnd Struct~nStruct TConstructorOuter<T>~nField inner:TConstructorInner<T>~nField stored:T~nMethod New(input:T)~nstored = input~nEnd Method~nEnd Struct~nGlobal nestedConstructed:TConstructorOuter<String> = New TConstructorOuter<String>(~qnested constructor~q)"
Local nestedConstructorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-nested-constructor.bmx", nestedConstructorSource, Null, compilerOptions)
Check(nestedConstructorCompilation.Succeeded() And nestedConstructorCompilation.genericPlan.registry.nodes.length = 2, "generic Struct constructor composes with a canonical nested default layout: " + CompilationSummary(nestedConstructorCompilation))
Local nestedConstructorOuterUnit:TCompilerGenericUnit
For Local nestedConstructorUnit:TCompilerGenericUnit = EachIn nestedConstructorCompilation.genericPlan.units
	If nestedConstructorUnit.specialization.artifact.identity.qualifiedName = "TConstructorOuter" Then nestedConstructorOuterUnit = nestedConstructorUnit
Next
Check(nestedConstructorOuterUnit And nestedConstructorOuterUnit.implementation.Find("_New_ObjectNew();") < nestedConstructorOuterUnit.implementation.Find(" = bmx_ctor_input;"), "nested Struct defaults execute before constructor assignments in the specialization helper")
Local zeroConstructorSource:String = "SuperStrict~nStruct TZeroConstructed<T>~nField stored:T~nMethod New()~nEnd Method~nEnd Struct~nGlobal zeroConstructed:TZeroConstructed<Int>"
Local zeroConstructorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-zero-constructor.bmx", zeroConstructorSource, Null, compilerOptions)
Check(zeroConstructorCompilation.Succeeded() And zeroConstructorCompilation.genericPlan.units[0].implementation.Contains("_New(void)"), "zero-argument generic Struct constructor remains the default value helper: " + CompilationSummary(zeroConstructorCompilation))
Local missingDefaultConstructorSource:String = "SuperStrict~nStruct TRequiredConstructed<T>~nField stored:T~nMethod New(value:T)~nstored = value~nEnd Method~nEnd Struct~nGlobal missingRequired:TRequiredConstructed<String>"
Local missingDefaultConstructorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-required-constructor.bmx", missingDefaultConstructorSource, Null, compilerOptions)
Check(missingDefaultConstructorCompilation.Succeeded() And missingDefaultConstructorCompilation.genericPlan.units[0].implementation.Contains("_New_ObjectNew(void)"), "parameterized-only generic Struct retains the language value-default path independently of explicit New overloads")
Local overloadedConstructorSource:String = "SuperStrict~nStruct TOverloadedConstructed<T>~nField stored:T~nMethod New()~nEnd Method~nMethod New(value:T)~nstored = value~nEnd Method~nEnd Struct~nGlobal overloadedDefault:TOverloadedConstructed<String> = New TOverloadedConstructed<String>~nGlobal overloadedConstructed:TOverloadedConstructed<String> = New TOverloadedConstructed<String>(~qoverloaded~q)"
Local overloadedConstructorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-overloaded-constructor.bmx", overloadedConstructorSource, Null, compilerOptions)
Check(overloadedConstructorCompilation.Succeeded() And overloadedConstructorCompilation.genericPlan.units[0].ir.constructors.length = 2, "distinct-arity generic Struct constructors share one canonical specialization: " + CompilationSummary(overloadedConstructorCompilation))
Local overloadedConstructorUnit:TCompilerGenericUnit = overloadedConstructorCompilation.genericPlan.units[0]
Check(overloadedConstructorUnit.implementation.Contains("_New__A0(void)") And overloadedConstructorUnit.implementation.Contains("_New__A1(BBSTRING bmx_ctor_value)"), "distinct-arity generic Struct constructors own deterministic signature-qualified helpers")
Local overloadedConstructorRuntimeDiagnostics:TCompilerDiagnostic[]
Local overloadedConstructorRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(overloadedConstructorCompilation, overloadedConstructorRuntimeDiagnostics)
Check(overloadedConstructorRuntimeDiagnostics.length = 0 And overloadedConstructorRuntimeC.Contains("_New__A0()") And overloadedConstructorRuntimeC.Contains("_New__A1((BBString*)&"), "bound construction arity selects the matching canonical generic Struct helper")
Local sameArityConstructorSource:String = "SuperStrict~nStruct TSameArityConstructed<T>~nField stored:T~nField count:Int~nMethod New(value:T)~nstored = value~nEnd Method~nMethod New(amount:Int)~ncount = amount~nEnd Method~nEnd Struct~nGlobal sameArityText:TSameArityConstructed<String> = New TSameArityConstructed<String>(~qsame arity~q)~nGlobal sameArityCount:TSameArityConstructed<String> = New TSameArityConstructed<String>(7)"
Local sameArityConstructorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-same-arity-constructor.bmx", sameArityConstructorSource, Null, compilerOptions)
Check(sameArityConstructorCompilation.Succeeded() And sameArityConstructorCompilation.genericPlan.units[0].ir.constructors.length = 2, "same-arity generic Struct constructors retain distinct canonical specialized signatures: " + CompilationSummary(sameArityConstructorCompilation))
Local sameArityConstructorUnit:TCompilerGenericUnit = sameArityConstructorCompilation.genericPlan.units[0]
Check(sameArityConstructorUnit.implementation.Contains("_New__A1_string_") And sameArityConstructorUnit.implementation.Contains("_New__A1_int_"), "same-arity constructor helpers carry readable types and collision-resistant signature digests")
Local sameArityConstructorRuntimeDiagnostics:TCompilerDiagnostic[]
Local sameArityConstructorRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(sameArityConstructorCompilation, sameArityConstructorRuntimeDiagnostics)
Check(sameArityConstructorRuntimeDiagnostics.length = 0 And sameArityConstructorRuntimeC.Contains("_New__A1_string_") And sameArityConstructorRuntimeC.Contains("_New__A1_int_"), "bound closed parameter signatures select the exact same-arity helper")
Local collapsedConstructorSource:String = "SuperStrict~nStruct TCollapsedConstructed<T>~nMethod New(value:T)~nEnd Method~nMethod New(value:String)~nEnd Method~nEnd Struct~nFunction UseCollapsed(value:TCollapsedConstructed<String>)~nEnd Function"
Local collapsedConstructorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-collapsed-constructor.bmx", collapsedConstructorSource, Null, compilerOptions)
Check(HasCompilerDiagnostic(collapsedConstructorCompilation, "BMXC3015"), "constructor signatures that collapse after type substitution produce an explicit canonical collision diagnostic: " + CompilationSummary(collapsedConstructorCompilation))
Local collapsedTypeConstructorSource:String = "SuperStrict~nType TCollapsedTypeConstructed<T>~nMethod New(value:T)~nEnd Method~nMethod New(value:String)~nEnd Method~nEnd Type~nFunction UseCollapsedType(value:TCollapsedTypeConstructed<String>)~nEnd Function"
Local collapsedTypeConstructorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-collapsed-type-constructor.bmx", collapsedTypeConstructorSource, Null, compilerOptions)
Check(HasCompilerDiagnostic(collapsedTypeConstructorCompilation, "BMXC3015"), "generic Type constructor signatures that collapse after substitution produce an explicit canonical collision diagnostic: " + CompilationSummary(collapsedTypeConstructorCompilation))
Local recursiveDelegationSource:String = "SuperStrict~nStruct TRecursiveDelegation<T>~nField stored:T~nMethod New(value:T)~nNew(value, 0)~nEnd Method~nMethod New(value:T, amount:Int)~nNew(value)~nEnd Method~nEnd Struct~nGlobal recursiveDelegation:TRecursiveDelegation<String> = New TRecursiveDelegation<String>(~qcycle~q)"
Local recursiveDelegationCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-recursive-constructor-delegation.bmx", recursiveDelegationSource, Null, compilerOptions)
Check(HasCompilerDiagnostic(recursiveDelegationCompilation, "BMXC3015"), "indirect generic Struct constructor delegation cycles are diagnosed before C emission: " + CompilationSummary(recursiveDelegationCompilation))
Local recursiveTypeDelegationSource:String = "SuperStrict~nType TRecursiveTypeDelegation<T>~nField stored:T~nMethod New(value:T)~nNew(value, 0)~nEnd Method~nMethod New(value:T, amount:Int)~nNew(value)~nEnd Method~nEnd Type~nGlobal recursiveTypeDelegation:TRecursiveTypeDelegation<String> = New TRecursiveTypeDelegation<String>(~qcycle~q)"
Local recursiveTypeDelegationCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-recursive-type-constructor-delegation.bmx", recursiveTypeDelegationSource, Null, compilerOptions)
Check(HasCompilerDiagnostic(recursiveTypeDelegationCompilation, "BMXC3015"), "indirect generic Type constructor delegation cycles are diagnosed before C emission: " + CompilationSummary(recursiveTypeDelegationCompilation))
Local varConstructorSource:String = "SuperStrict~nStruct TVarConstructed<T>~nField stored:T~nMethod New(value:T Var)~nstored = value~nEnd Method~nEnd Struct~nGlobal varInput:Int = 1~nGlobal varConstructed:TVarConstructed<Int> = New TVarConstructed<Int>(varInput)"
Local varConstructorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-var-constructor.bmx", varConstructorSource, Null, compilerOptions)
Local varConstructorDiagnostics:TCompilerDiagnostic[]
Local varConstructorRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(varConstructorCompilation, varConstructorDiagnostics)
Check(varConstructorCompilation.Succeeded() And varConstructorCompilation.genericPlan.units[0].implementation.Contains("(BBINT * bmx_ctor_value)") And varConstructorCompilation.genericPlan.units[0].implementation.Contains(" = (*bmx_ctor_value);") And varConstructorDiagnostics.length = 0 And varConstructorRuntimeC.Contains("&bmx_"), "generic Struct constructors preserve Var pointer ABI from application call through field initialization: " + CompilationSummary(varConstructorCompilation))
Local varTypeConstructorSource:String = "SuperStrict~nType TVarTypeConstructed<T>~nField stored:T~nMethod New(value:T Var)~nstored = value~nEnd Method~nEnd Type~nGlobal varTypeInput:Int = 2~nGlobal varTypeConstructed:TVarTypeConstructed<Int> = New TVarTypeConstructed<Int>(varTypeInput)"
Local varTypeConstructorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-var-type-constructor.bmx", varTypeConstructorSource, Null, compilerOptions)
Local varTypeConstructorDiagnostics:TCompilerDiagnostic[]
Local varTypeConstructorRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(varTypeConstructorCompilation, varTypeConstructorDiagnostics)
Check(varTypeConstructorCompilation.Succeeded() And varTypeConstructorCompilation.genericPlan.units[0].implementation.Contains("BBINT * value") And varTypeConstructorCompilation.genericPlan.units[0].implementation.Contains(" = (*value);") And varTypeConstructorDiagnostics.length = 0 And varTypeConstructorRuntimeC.Contains("&bmx_"), "generic Type constructors retain Var ABI in their separate allocation/initializer unit")
Local optionalConstructorSource:String = "SuperStrict~nStruct TOptionalConstructed<T>~nField marker:T~nField stored:Int~nMethod New(value:Int = 1)~nstored = value~nEnd Method~nEnd Struct~nGlobal optionalConstructed:TOptionalConstructed<Int> = New TOptionalConstructed<Int>"
Local optionalConstructorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-optional-constructor.bmx", optionalConstructorSource, Null, compilerOptions)
Check(optionalConstructorCompilation.Succeeded() And optionalConstructorCompilation.genericPlan.units[0].ir.constructors[0].parameters[0].optional And optionalConstructorCompilation.genericPlan.units[0].ir.constructors[0].parameters[0].defaultValue.valueText = "1", "generic Struct constructor retains its bound optional parameter in specialization IR: " + CompilationSummary(optionalConstructorCompilation))
Local optionalConstructorRuntimeDiagnostics:TCompilerDiagnostic[]
Local optionalConstructorRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(optionalConstructorCompilation, optionalConstructorRuntimeDiagnostics)
Check(optionalConstructorRuntimeDiagnostics.length = 0 And optionalConstructorRuntimeC.Contains(optionalConstructorCompilation.genericPlan.units[0].ir.constructors[0].abiName + "(1)"), "application IR materializes the bound generic constructor default before calling the separately owned helper")
Local initializedFieldSource:String = "SuperStrict~nStruct TInitializedField<T>~nField marker:T~nField stored:Int = 1~nEnd Struct~nGlobal initializedField:TInitializedField<Int>"
Local initializedFieldCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-initialized-field.bmx", initializedFieldSource, Null, compilerOptions)
Check(initializedFieldCompilation.Succeeded() And initializedFieldCompilation.genericPlan.units.length = 1, "closed scalar generic Struct field initializers lower from the template artifact: " + CompilationSummary(initializedFieldCompilation))
Check(initializedFieldCompilation.genericPlan.units[0].ir.fields[1].initializer <> Null And initializedFieldCompilation.genericPlan.units[0].implementation.Contains(" = 1;"), "generic Struct field initializer survives substitution into deterministic specialization C")
Local initializedTypeFieldSource:String = "SuperStrict~nType TInitializedTypeField<T>~nField marker:T~nField index:Int = -1~nMethod Read:Int()~nReturn index~nEnd Method~nEnd Type~nGlobal initializedTypeField:TInitializedTypeField<String> = New TInitializedTypeField<String>"
Local initializedTypeFieldCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-initialized-type-field.bmx", initializedTypeFieldSource, Null, compilerOptions)
Check(initializedTypeFieldCompilation.Succeeded() And initializedTypeFieldCompilation.genericPlan.units[0].ir.fields[1].initializer <> Null, "closed scalar generic Type field initializers survive canonical lowering: " + CompilationSummary(initializedTypeFieldCompilation))
Check(initializedTypeFieldCompilation.genericPlan.units[0].implementation.Contains(" = (-1);"), "generic Type construction emits its retained scalar field initializer")
Local implicitGenericReturnSource:String = "SuperStrict~nType TImplicitReturn<T>~nMethod Put:T(found:Int, value:T)~nIf found Then Return value~nEnd Method~nEnd Type~nGlobal implicitReturn:TImplicitReturn<String> = New TImplicitReturn<String>"
Local implicitGenericReturnCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-implicit-return.bmx", implicitGenericReturnSource, Null, compilerOptions)
Check(implicitGenericReturnCompilation.Succeeded() And implicitGenericReturnCompilation.genericPlan.units.length = 1, "generic method with a fallthrough path retains BlitzMax implicit-return semantics: " + CompilationSummary(implicitGenericReturnCompilation))
Check(implicitGenericReturnCompilation.genericPlan.units[0].implementation.Contains("return &bbEmptyString;"), "generic managed return emits the declared type's deterministic default after its retained body")
Local bareGenericReturnSource:String = "SuperStrict~nType TBareReturn<T>~nMethod Read:T(available:Int, value:T)~nIf Not available Return~nReturn value~nEnd Method~nEnd Type~nGlobal bareReturn:TBareReturn<String> = New TBareReturn<String>"
Local bareGenericReturnCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-bare-return.bmx", bareGenericReturnSource, Null, compilerOptions)
Check(bareGenericReturnCompilation.Succeeded() And bareGenericReturnCompilation.genericPlan.units.length = 1, "bare Return in a non-Void generic method survives source-free specialization: " + CompilationSummary(bareGenericReturnCompilation))
Check(bareGenericReturnCompilation.genericPlan.units[0].implementation.Contains("return &bbEmptyString;") And Not bareGenericReturnCompilation.genericPlan.units[0].implementation.Contains("return;"), "bare generic Return emits the closed managed default rather than invalid C")
Local genericConstSource:String = "SuperStrict~nType TConstBox<T>~nConst EMPTY:Int = -1~nField marker:T~nField index:Int = EMPTY~nMethod Empty:Int()~nReturn EMPTY~nEnd Method~nEnd Type~nGlobal constBox:TConstBox<String> = New TConstBox<String>"
Local genericConstCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-type-const.bmx", genericConstSource, Null, compilerOptions)
Check(genericConstCompilation.Succeeded() And genericConstCompilation.genericPlan.units.length = 1 And genericConstCompilation.genericPlan.units[0].implementation.Contains(" = -1;") And genericConstCompilation.genericPlan.units[0].implementation.Contains("return -1;") And Not genericConstCompilation.genericPlan.units[0].implementation.Contains("EMPTY"), "scalar numeric generic Type Const uses are folded into source-free specialization bodies without acquiring storage: " + CompilationSummary(genericConstCompilation))
Local unsupportedInitializedFieldSource:String = "SuperStrict~nStruct TUnsupportedInitializedField<T>~nField marker:T~nField stored:String = ~qvalue~q~nEnd Struct~nGlobal unsupportedInitializedField:TUnsupportedInitializedField<Int>"
Local unsupportedInitializedFieldCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-unsupported-initialized-field.bmx", unsupportedInitializedFieldSource, Null, compilerOptions)
Check(unsupportedInitializedFieldCompilation.Succeeded() And unsupportedInitializedFieldCompilation.genericPlan.units[0].implementation.Contains("bbStringFromShorts"), "closed String generic field initializers lower from retained semantic literals without source reparsing: " + CompilationSummary(unsupportedInitializedFieldCompilation))
Local nestedRequiredSource:String = "SuperStrict~nStruct TNestedRequired<T>~nField stored:T~nMethod New(value:T)~nstored = value~nEnd Method~nEnd Struct~nStruct THoldsNestedRequired<T>~nField nested:TNestedRequired<T>~nEnd Struct~nGlobal holdsNestedRequired:THoldsNestedRequired<Int>"
Local nestedRequiredCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-nested-required-constructor.bmx", nestedRequiredSource, Null, compilerOptions)
Check(HasCompilerDiagnostic(nestedRequiredCompilation, "BMXC3015"), "nested generic Struct fields require an explicit zero-argument construction path: " + CompilationSummary(nestedRequiredCompilation))
Local nonFieldConstructorAssignmentSource:String = "SuperStrict~nStruct TNonFieldConstructorAssignment<T>~nField marker:T~nMethod New(value:Int)~nvalue = 2~nEnd Method~nEnd Struct~nGlobal nonFieldConstructorAssignment:TNonFieldConstructorAssignment<Int> = New TNonFieldConstructorAssignment<Int>(1)"
Local nonFieldConstructorAssignmentCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-non-field-constructor-assignment.bmx", nonFieldConstructorAssignmentSource, Null, compilerOptions)
Check(HasCompilerDiagnostic(nonFieldConstructorAssignmentCompilation, "BMXC3029"), "generic Struct constructor assignments remain restricted to direct fields: " + CompilationSummary(nonFieldConstructorAssignmentCompilation))
Local parameterizedBodyNewSource:String = "SuperStrict~nType TPlain~nMethod New(value:Int)~nEnd Method~nEnd Type~nType TBadFactory<T>~nMethod Create:TPlain()~nReturn New TPlain(1)~nEnd Method~nEnd Type~nGlobal badFactory:TBadFactory<Int>"
Local parameterizedBodyNewCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-body-constructor-arguments.bmx", parameterizedBodyNewSource, Null, compilerOptions)
Check(parameterizedBodyNewCompilation.Succeeded(), "parameterized construction of an ordinary unpublished Type uses a deterministic specialization dependency ABI: " + CompilationSummary(parameterizedBodyNewCompilation))
Check(parameterizedBodyNewCompilation.genericPlan.units[0].implementation.Contains("bmx_generic_dependency_tplain_new_") And parameterizedBodyNewCompilation.genericPlan.units[0].implementation.Contains("_ObjectNew((BBClass *)&bmx_direct_tplain_"), "unpublished ordinary construction is retained as an exact allocation-helper reference without source text")
Local stableFreeBodyCallSource:String = "SuperStrict~nFunction StablePlain:Int(value:Int) { nomangle }~nReturn value + 1~nEnd Function~nFunction ViaPlain<T>:Int(value:Int)~nReturn StablePlain(value)~nEnd Function~nGlobal stableCall:Int = ViaPlain<String>(41)"
Local stableFreeBodyCallCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-body-stable-free-call.bmx", stableFreeBodyCallSource, Null, compilerOptions)
Check(stableFreeBodyCallCompilation.Succeeded() And stableFreeBodyCallCompilation.genericPlan.units.length = 1, "NoMangle ordinary free call is retained as a stable generic-template dependency: " + CompilationSummary(stableFreeBodyCallCompilation))
Local stableFreeBodyCallImplementation:String = stableFreeBodyCallCompilation.genericPlan.units[0].implementation
Check(stableFreeBodyCallImplementation.Contains("BBINT _bb_main_StablePlain(BBINT);") And stableFreeBodyCallImplementation.Contains("return _bb_main_StablePlain(") And stableFreeBodyCallImplementation.Contains("((BBINT)value)"), "specialization unit declares and invokes the stable ordinary routine ABI directly")
Local stableTypeFreeBodyCallSource:String = "SuperStrict~nFunction StableTypePlain:Int(value:Int) { nomangle }~nReturn value + 1~nEnd Function~nType TStableCall<T>~nMethod Read:Int(value:Int)~nReturn StableTypePlain(value)~nEnd Method~nEnd Type~nGlobal stableTypeCall:TStableCall<String>"
Local stableTypeFreeBodyCallCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-type-stable-free-call.bmx", stableTypeFreeBodyCallSource, Null, compilerOptions)
Check(stableTypeFreeBodyCallCompilation.Succeeded() And stableTypeFreeBodyCallCompilation.genericPlan.units.length = 1 And stableTypeFreeBodyCallCompilation.genericPlan.units[0].implementation.Contains("BBINT _bb_main_StableTypePlain(BBINT);") And stableTypeFreeBodyCallCompilation.genericPlan.units[0].implementation.Contains("return _bb_main_StableTypePlain(") And stableTypeFreeBodyCallCompilation.genericPlan.units[0].implementation.Contains("((BBINT)value)"), "generic Type method units retain the same stable ordinary routine dependency")
Local ordinaryVirtualBodyCallSource:String = "SuperStrict~nModule Collections.OrdinaryVirtualBody~nType TFlag~nMethod Mark(index:Int)~nEnd Method~nMethod IsMarked:Int(index:Int)~nReturn False~nEnd Method~nEnd Type~nType TFlagProbe<T>~nMethod Probe:Int(flag:TFlag, index:Int)~nIf Not flag.IsMarked(index) Then flag.Mark(index)~nReturn 1~nEnd Method~nEnd Type~nGlobal flagProbe:TFlagProbe<Int> = New TFlagProbe<Int>"
Local ordinaryVirtualBodyCallCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/ordinaryvirtualbody.mod/ordinaryvirtualbody.bmx", ordinaryVirtualBodyCallSource, Null, compilerOptions)
Check(ordinaryVirtualBodyCallCompilation.Succeeded() And ordinaryVirtualBodyCallCompilation.genericPlan.units.length = 1, "generic Type body retains published ordinary virtual calls with arguments: " + CompilationSummary(ordinaryVirtualBodyCallCompilation))
Local ordinaryVirtualBodyImplementation:String = ordinaryVirtualBodyCallCompilation.genericPlan.units[0].implementation
Check(ordinaryVirtualBodyImplementation.Contains("->clas->vfns[0]") And ordinaryVirtualBodyImplementation.Contains("->clas->vfns[1]") And Not ordinaryVirtualBodyImplementation.Contains("bmx_local_index))"), "ordinary virtual call lowering emits one balanced invocation close for expression and statement calls")
Local declaredArrayAllocationSource:String = "SuperStrict~nType TDeclaredArray<T>~nMethod Make:T[](amount:Int)~nLocal result:T[amount]~nReturn result~nEnd Method~nEnd Type~nGlobal declaredArray:TDeclaredArray<String> = New TDeclaredArray<String>"
Local declaredArrayAllocationCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-declared-array-allocation.bmx", declaredArrayAllocationSource, Null, compilerOptions)
Check(declaredArrayAllocationCompilation.Succeeded() And declaredArrayAllocationCompilation.genericPlan.units.length = 1, "generic declaration-style heap Array allocation retains its bound runtime dimension: " + CompilationSummary(declaredArrayAllocationCompilation))
Check(declaredArrayAllocationCompilation.genericPlan.units[0].implementation.Contains("bbArrayNew1D(~q$~q, amount)"), "generic declaration-style heap Array allocation emits a managed Array with its substituted element ABI")
Local inheritedInterfaceOverrideSource:String = "SuperStrict~nInterface IInheritedReadable<T>~nMethod Read:T()~nEnd Interface~nType TInheritedReadableBase<T> Implements IInheritedReadable<T>~nField value:T~nMethod Read:T()~nReturn value~nEnd Method~nEnd Type~nType TInheritedReadableMiddle<T> Extends TInheritedReadableBase<T>~nEnd Type~nType TInheritedReadableDerived<T> Extends TInheritedReadableMiddle<T>~nField replacement:T~nMethod Read:T() Override~nReturn replacement~nEnd Method~nEnd Type~nGlobal inheritedReadable:TInheritedReadableDerived<String> = New TInheritedReadableDerived<String>"
Local inheritedInterfaceOverrideCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-inherited-interface-override.bmx", inheritedInterfaceOverrideSource, Null, compilerOptions)
Check(inheritedInterfaceOverrideCompilation.Succeeded() And inheritedInterfaceOverrideCompilation.genericPlan.registry.nodes.length = 4, "derived generic Type retains the Interface contract inherited through its canonical base-specialization chain: " + CompilationSummary(inheritedInterfaceOverrideCompilation))
Local inheritedReadableDerivedUnit:TCompilerGenericUnit
For Local inheritedReadableUnit:TCompilerGenericUnit = EachIn inheritedInterfaceOverrideCompilation.genericPlan.units
	If inheritedReadableUnit.specialization.artifact.identity.qualifiedName.ToLower() = "tinheritedreadablederived" Then inheritedReadableDerivedUnit = inheritedReadableUnit; Exit
Next
Local inheritedReadableOverride:TCompilerGenericMethodIr
If inheritedReadableDerivedUnit Then
	For Local inheritedReadableMethod:TCompilerGenericMethodIr = EachIn inheritedReadableDerivedUnit.ir.methods
		If inheritedReadableMethod.name.ToLower() = "read" And inheritedReadableMethod.declaringSpecialization = inheritedReadableDerivedUnit.specialization Then inheritedReadableOverride = inheritedReadableMethod; Exit
	Next
End If
Check(inheritedReadableDerivedUnit And inheritedReadableDerivedUnit.ir.implementedInterfaces.length = 1 And inheritedReadableOverride And inheritedReadableDerivedUnit.implementation.Contains("))" + inheritedReadableOverride.abiName), "derived specialization owns an inherited Interface table rebound to its override")
Local freeBodyCallSource:String = "SuperStrict~nFunction Plain:Int()~nReturn 1~nEnd Function~nType TBadCall<T>~nMethod Read:Int()~nReturn Plain()~nEnd Method~nEnd Type~nGlobal badCall:TBadCall<Int>"
Local freeBodyCallCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-body-free-call.bmx", freeBodyCallSource, Null, compilerOptions)
Check(freeBodyCallCompilation.Succeeded(), "source-private ordinary calls use a deterministic dependency ABI rather than a transient function ID: " + CompilationSummary(freeBodyCallCompilation))
Check(freeBodyCallCompilation.genericPlan.units[0].implementation.Contains("BBINT bmx_generic_dependency_plain_") And freeBodyCallCompilation.genericPlan.units[0].implementation.Contains("return bmx_generic_dependency_plain_"), "private helper declaration and call survive source-free specialization")
Local overloadedPrivateHelperSource:String = "SuperStrict~nPrivate~nFunction HiddenValue:Int(value:Int)~nReturn value + 1~nEnd Function~nFunction HiddenValue:String(value:String)~nReturn value~nEnd Function~nPublic~nFunction UseHiddenValue<T>:Int(value:Int)~nReturn HiddenValue(value)~nEnd Function~nGlobal overloadedPrivateResult:Int = UseHiddenValue<String>(41)"
Local overloadedPrivateHelperCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-overloaded-private-helper.bmx", overloadedPrivateHelperSource, Null, compilerOptions)
Local overloadedPrivateHelperRuntimeDiagnostics:TCompilerDiagnostic[]
Local overloadedPrivateHelperRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(overloadedPrivateHelperCompilation, overloadedPrivateHelperRuntimeDiagnostics)
Check(overloadedPrivateHelperCompilation.Succeeded() And overloadedPrivateHelperRuntimeDiagnostics.length = 0 And overloadedPrivateHelperCompilation.genericPlan.units[0].implementation.Contains("BBINT bmx_generic_dependency_hiddenvalue_") And overloadedPrivateHelperRuntimeC.Contains("BBINT bmx_generic_dependency_hiddenvalue_"), "private overload dependency matching uses the full deterministic ABI rather than the first same-name symbol: " + CompilationSummary(overloadedPrivateHelperCompilation))
Local containingTypeHelperSource:String = "SuperStrict~nType TOrdinaryHelpers~nInternal~nFunction Offset:Int(value:Int)~nReturn value + 1~nEnd Function~nEnd Type~nType TContainingHelperCall<T>~nMethod Read:Int(value:Int)~nReturn TOrdinaryHelpers.Offset(value)~nEnd Method~nEnd Type~nGlobal containingHelperCall:TContainingHelperCall<String>"
Local containingTypeHelperCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-containing-type-helper.bmx", containingTypeHelperSource, Null, compilerOptions)
Check(containingTypeHelperCompilation.Succeeded() And containingTypeHelperCompilation.genericPlan.units[0].implementation.Contains("BBINT bmx_generic_dependency_tordinaryhelpers_offset_") And containingTypeHelperCompilation.genericPlan.units[0].implementation.Contains("return bmx_generic_dependency_tordinaryhelpers_offset_"), "an internal containing-Type Function is retained as a stable direct ordinary dependency: " + CompilationSummary(containingTypeHelperCompilation))
Local ordinaryStructOperatorSource:String = "SuperStrict~nStruct SOrdinaryAmount~nField value:Int~nMethod Operator +:SOrdinaryAmount(delta:Int)~nSelf.value :+ delta~nReturn Self~nEnd Method~nEnd Struct~nType TOrdinaryOperatorCall<T>~nMethod Add:SOrdinaryAmount(value:SOrdinaryAmount)~nReturn value + 1~nEnd Method~nEnd Type~nGlobal ordinaryOperatorCall:TOrdinaryOperatorCall<String>"
Local ordinaryStructOperatorCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-ordinary-struct-operator.bmx", ordinaryStructOperatorSource, Null, compilerOptions)
Check(ordinaryStructOperatorCompilation.Succeeded() And ordinaryStructOperatorCompilation.genericPlan.units[0].implementation.Contains("bmx_generic_dependency_sordinaryamount__add_") And ordinaryStructOperatorCompilation.genericPlan.units[0].implementation.Contains("(&(value)), ((BBINT)1))"), "resolved ordinary Struct operators lower as direct pointer-receiver dependencies instead of falling into intrinsic C operator handling: " + CompilationSummary(ordinaryStructOperatorCompilation))
Local ordinaryStructOperatorBuildDiagnostics:TCompilerDiagnostic[]
Local ordinaryStructOperatorBuild:TCompilerBuildOutputPlan = TBlitzMaxCompiler.PlanBuildOutputs(ordinaryStructOperatorCompilation, "ordinary-operator.c", "", "", ordinaryStructOperatorBuildDiagnostics)
Local ordinaryStructOperatorHeader:TCompilerBuildOutputFile
Local ordinaryStructOperatorUnit:TCompilerBuildOutputFile
For Local ordinaryStructOperatorFile:TCompilerBuildOutputFile = EachIn ordinaryStructOperatorBuild.files
	If ordinaryStructOperatorFile.role = "runtime-header" Then ordinaryStructOperatorHeader = ordinaryStructOperatorFile
	If ordinaryStructOperatorFile.role = "generic-specialization-c" Then ordinaryStructOperatorUnit = ordinaryStructOperatorFile
Next
Check(ordinaryStructOperatorBuildDiagnostics.length = 0 And ordinaryStructOperatorHeader And ordinaryStructOperatorHeader.relativePath = "ordinary-operator.h" And ordinaryStructOperatorUnit And ordinaryStructOperatorUnit.content.StartsWith("#include ~q../../ordinary-operator.h~q"), "an application-owned by-value Struct dependency automatically materializes and cache-couples its authoritative runtime header")
Local directOrdinaryStructMethodSource:String = "SuperStrict~nStruct SDirectOwner~nField value:Int~nMethod Read<T>:Int(fallback:T)~nReturn value~nEnd Method~nEnd Struct~nGlobal directOwner:SDirectOwner~nGlobal directRead:Int = directOwner.Read<String>(~qfallback~q)"
Local directOrdinaryStructMethodCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-direct-ordinary-struct-method.bmx", directOrdinaryStructMethodSource, Null, compilerOptions)
Local directOrdinaryStructMethodBuildDiagnostics:TCompilerDiagnostic[]
Local directOrdinaryStructMethodBuild:TCompilerBuildOutputPlan = TBlitzMaxCompiler.PlanBuildOutputs(directOrdinaryStructMethodCompilation, "direct-ordinary-struct.c", "", "", directOrdinaryStructMethodBuildDiagnostics)
Local directOrdinaryStructMethodHeaderCount:Int
For Local directOrdinaryStructMethodFile:TCompilerBuildOutputFile = EachIn directOrdinaryStructMethodBuild.files
	If directOrdinaryStructMethodFile.role = "runtime-header" Then directOrdinaryStructMethodHeaderCount :+ 1
Next
Check(directOrdinaryStructMethodCompilation.Succeeded() And directOrdinaryStructMethodBuildDiagnostics.length = 0 And directOrdinaryStructMethodHeaderCount = 0, "a direct generic ordinary Struct method keeps its complete owner layout in its specialization unit without importing a duplicate application-header definition: " + CompilationSummary(directOrdinaryStructMethodCompilation))
Local ordinaryDependencyModuleSource:String = "SuperStrict~nModule Collections.OrdinaryDependency~nFunction Offset:Int(value:Int)~nReturn value + 1~nEnd Function~nFunction ApplyOffset<T>:Int(value:Int)~nReturn Offset(value)~nEnd Function"
Local ordinaryDependencyModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/ordinarydependency.mod/ordinarydependency.bmx", ordinaryDependencyModuleSource, Null, compilerOptions)
Local ordinaryDependencyArtifactDiagnostics:TCompilerDiagnostic[]
Local ordinaryDependencyOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(ordinaryDependencyModuleCompilation, ordinaryDependencyArtifactDiagnostics)
Local ordinaryDependencyInterfaceDiagnostics:TCompilerDiagnostic[]
Local ordinaryDependencyInterface:String = TBlitzMaxCompiler.EmitInterface(ordinaryDependencyModuleCompilation, ordinaryDependencyInterfaceDiagnostics)
Check(ordinaryDependencyModuleCompilation.Succeeded() And ordinaryDependencyArtifactDiagnostics.length = 0 And ordinaryDependencyInterfaceDiagnostics.length = 0 And ordinaryDependencyOutputs.length = 1, "module publishes an ordinary routine ABI and its source-free generic caller artifact")
Local ordinaryDependencyResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
ordinaryDependencyResolver.AddInterface("collections.ordinarydependency", "sdk/collections.ordinarydependency.i", ordinaryDependencyInterface)
ordinaryDependencyResolver.AddGenericTemplate(ordinaryDependencyOutputs[0].artifactReference, "sdk/" + ordinaryDependencyOutputs[0].artifactReference, ordinaryDependencyOutputs[0].content)
Local ordinaryDependencyConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-ordinary-dependency-consumer.bmx", "SuperStrict~nImport Collections.OrdinaryDependency~nGlobal offsetValue:Int = ApplyOffset<String>(41)", ordinaryDependencyResolver, compilerOptions)
Check(ordinaryDependencyConsumer.Succeeded() And ordinaryDependencyConsumer.genericPlan.units.length = 1, "imported generic caller specializes from its artifact and published ordinary routine signature: " + CompilationSummary(ordinaryDependencyConsumer))
Local ordinaryDependencyImplementation:String = ordinaryDependencyConsumer.genericPlan.units[0].implementation
Check(ordinaryDependencyImplementation.Contains("BBINT collections_ordinarydependency_Offset__Bint(BBINT);") And ordinaryDependencyImplementation.Contains("return collections_ordinarydependency_Offset__Bint(") And ordinaryDependencyImplementation.Contains("((BBINT)value)"), "source-free specialization preserves the producer-owned ordinary routine linkage identity")
Local privateDependencyModuleSource:String = "SuperStrict~nModule Collections.PrivateDependency~nPrivate~nFunction HiddenOffset:Int(value:Int)~nReturn value + 1~nEnd Function~nPublic~nFunction ApplyHiddenOffset<T>:Int(value:Int)~nReturn HiddenOffset(value)~nEnd Function"
Local privateDependencyModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/privatedependency.mod/privatedependency.bmx", privateDependencyModuleSource, Null, compilerOptions)
Local privateDependencyArtifactDiagnostics:TCompilerDiagnostic[]
Local privateDependencyOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(privateDependencyModuleCompilation, privateDependencyArtifactDiagnostics)
Local privateDependencyInterfaceDiagnostics:TCompilerDiagnostic[]
Local privateDependencyInterface:String = TBlitzMaxCompiler.EmitInterface(privateDependencyModuleCompilation, privateDependencyInterfaceDiagnostics)
Local privateDependencyRuntimeDiagnostics:TCompilerDiagnostic[]
Local privateDependencyRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(privateDependencyModuleCompilation, privateDependencyRuntimeDiagnostics)
Check(privateDependencyModuleCompilation.Succeeded() And privateDependencyOutputs.length = 1 And privateDependencyArtifactDiagnostics.length = 0 And privateDependencyInterfaceDiagnostics.length = 0 And privateDependencyRuntimeDiagnostics.length = 0 And privateDependencyRuntimeC.Contains("bmx_generic_dependency_hiddenoffset_"), "a module retains private visibility while exporting its deterministic C dependency linkage from the owning object: " + CompilationSummary(privateDependencyModuleCompilation))
Local privateDependencyResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
privateDependencyResolver.AddInterface("collections.privatedependency", "sdk/collections.privatedependency.i", privateDependencyInterface)
privateDependencyResolver.AddGenericTemplate(privateDependencyOutputs[0].artifactReference, "sdk/" + privateDependencyOutputs[0].artifactReference, privateDependencyOutputs[0].content)
Local privateDependencyConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-private-dependency-consumer.bmx", "SuperStrict~nImport Collections.PrivateDependency~nGlobal hiddenOffsetValue:Int = ApplyHiddenOffset<String>(41)", privateDependencyResolver, compilerOptions)
Check(privateDependencyConsumer.Succeeded() And privateDependencyConsumer.genericPlan.units[0].implementation.Contains("BBINT bmx_generic_dependency_hiddenoffset_") And privateDependencyConsumer.genericPlan.units[0].implementation.Contains("return bmx_generic_dependency_hiddenoffset_"), "an imported source-free generic artifact retains its private producer-owned helper dependency without publishing the helper in .i: " + CompilationSummary(privateDependencyConsumer))
Local ordinaryConstructionModuleSource:String = "SuperStrict~nModule Collections.OrdinaryConstruction~nType TOrdinaryConstructed~nField value:String~nMethod New(input:String)~nvalue = input~nEnd Method~nMethod Read:String()~nReturn value~nEnd Method~nEnd Type~nType TOrdinaryConstructionFactory<T>~nMethod Create:TOrdinaryConstructed(input:String)~nReturn New TOrdinaryConstructed(input)~nEnd Method~nEnd Type"
Local ordinaryConstructionModuleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/ordinaryconstruction.mod/ordinaryconstruction.bmx", ordinaryConstructionModuleSource, Null, compilerOptions)
Local ordinaryConstructionArtifactDiagnostics:TCompilerDiagnostic[]
Local ordinaryConstructionOutputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(ordinaryConstructionModuleCompilation, ordinaryConstructionArtifactDiagnostics)
Local ordinaryConstructionInterfaceDiagnostics:TCompilerDiagnostic[]
Local ordinaryConstructionInterface:String = TBlitzMaxCompiler.EmitInterface(ordinaryConstructionModuleCompilation, ordinaryConstructionInterfaceDiagnostics)
Check(ordinaryConstructionModuleCompilation.Succeeded() And ordinaryConstructionArtifactDiagnostics.length = 0 And ordinaryConstructionInterfaceDiagnostics.length = 0 And ordinaryConstructionOutputs.length = 1, "module publishes an ordinary constructor allocation ABI and its generic caller artifact: " + CompilationSummary(ordinaryConstructionModuleCompilation))
Local ordinaryConstructionResolver:TGenericSnapshotResolver = New TGenericSnapshotResolver
ordinaryConstructionResolver.AddInterface("collections.ordinaryconstruction", "sdk/collections.ordinaryconstruction.i", ordinaryConstructionInterface)
ordinaryConstructionResolver.AddGenericTemplate(ordinaryConstructionOutputs[0].artifactReference, "sdk/" + ordinaryConstructionOutputs[0].artifactReference, ordinaryConstructionOutputs[0].content)
Local ordinaryConstructionConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("generic-ordinary-construction-consumer.bmx", "SuperStrict~nImport Collections.OrdinaryConstruction~nGlobal ordinaryFactory:TOrdinaryConstructionFactory<String> = New TOrdinaryConstructionFactory<String>~nGlobal ordinaryConstructed:TOrdinaryConstructed = ordinaryFactory.Create(~qordinary construction~q)~nGlobal ordinaryConstructedValue:String = ordinaryConstructed.Read()", ordinaryConstructionResolver, compilerOptions)
Check(ordinaryConstructionConsumer.Succeeded() And ordinaryConstructionConsumer.genericPlan.units.length = 1, "imported generic factory specializes from its artifact and dependency-published ordinary constructor ABI: " + CompilationSummary(ordinaryConstructionConsumer))
Local ordinaryConstructionImplementation:String = ordinaryConstructionConsumer.genericPlan.units[0].implementation
Check(ordinaryConstructionImplementation.Contains("extern struct BBClass_collections_ordinaryconstruction_TOrdinaryConstructed collections_ordinaryconstruction_TOrdinaryConstructed;") And ordinaryConstructionImplementation.Contains("_collections_ordinaryconstruction_TOrdinaryConstructed_New__Bstring_ObjectNew(BBClass *clas, BBSTRING);") And ordinaryConstructionImplementation.Contains("return ((struct collections_ordinaryconstruction_TOrdinaryConstructed_obj *)_collections_ordinaryconstruction_TOrdinaryConstructed_New__Bstring_ObjectNew((BBClass *)&collections_ordinaryconstruction_TOrdinaryConstructed, input));"), "source-free specialization declares and calls the exact producer-owned ordinary object-allocation helper")
Local unsupportedOrdinaryConstructionSource:String = "SuperStrict~nModule Collections.UnsupportedOrdinaryConstruction~nType TOptionalOrdinaryConstructed~nMethod New(input:String = ~qdefault~q)~nEnd Method~nEnd Type~nType TUnsupportedOrdinaryFactory<T>~nMethod Create:TOptionalOrdinaryConstructed(input:String)~nReturn New TOptionalOrdinaryConstructed(input)~nEnd Method~nEnd Type~nGlobal unsupportedOrdinaryFactory:TUnsupportedOrdinaryFactory<Int>"
Local unsupportedOrdinaryConstructionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/collections.mod/unsupportedordinaryconstruction.mod/unsupportedordinaryconstruction.bmx", unsupportedOrdinaryConstructionSource, Null, compilerOptions)
Check(unsupportedOrdinaryConstructionCompilation.Succeeded(), "ordinary constructors retain optional parameters in their stable allocation contract: " + CompilationSummary(unsupportedOrdinaryConstructionCompilation))
Check(unsupportedOrdinaryConstructionCompilation.genericPlan.units.length = 1 And unsupportedOrdinaryConstructionCompilation.genericPlan.units[0].implementation.Contains("_collections_unsupportedordinaryconstruction_TOptionalOrdinaryConstructed_New__Bstring_ObjectNew") And unsupportedOrdinaryConstructionCompilation.genericPlan.units[0].implementation.Contains(", input)"), "ordinary optional constructor calls carry the bound explicit argument into the producer-owned helper: " + CompilationSummary(unsupportedOrdinaryConstructionCompilation))
Local omittedOrdinaryConstructionSource:String = "SuperStrict~nType TOptionalPlain~nField value:String~nMethod New(input:String = ~qdefault~q)~nvalue = input~nEnd Method~nEnd Type~nType TOmittedOrdinaryFactory<T>~nMethod Create:TOptionalPlain()~nReturn New TOptionalPlain()~nEnd Method~nEnd Type~nGlobal omittedOrdinaryFactory:TOmittedOrdinaryFactory<Int>"
Local omittedOrdinaryConstructionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-ordinary-omitted-constructor.bmx", omittedOrdinaryConstructionSource, Null, compilerOptions)
Check(omittedOrdinaryConstructionCompilation.Succeeded() And omittedOrdinaryConstructionCompilation.genericPlan.units[0].implementation.Contains("bbStringFromShorts") And omittedOrdinaryConstructionCompilation.genericPlan.units[0].implementation.Contains("_ObjectNew((BBClass *)&bmx_direct_toptionalplain_"), "an omitted ordinary constructor argument is materialized from its bound String default in specialization IR: " + CompilationSummary(omittedOrdinaryConstructionCompilation))
Local varOrdinaryConstructionSource:String = "SuperStrict~nType TVarPlain~nMethod New(value:Int Var)~nvalue :+ 1~nEnd Method~nEnd Type~nType TVarOrdinaryFactory<T>~nMethod Create:TVarPlain(value:Int Var)~nReturn New TVarPlain(value)~nEnd Method~nEnd Type~nGlobal varOrdinaryFactory:TVarOrdinaryFactory<Int>"
Local varOrdinaryConstructionCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-ordinary-var-constructor.bmx", varOrdinaryConstructionSource, Null, compilerOptions)
Check(varOrdinaryConstructionCompilation.Succeeded() And varOrdinaryConstructionCompilation.genericPlan.units[0].implementation.Contains("BBINT *") And varOrdinaryConstructionCompilation.genericPlan.units[0].implementation.Contains(", (&((*value)))))"), "ordinary constructor Var parameters preserve addressable-reference ABI through a generic body: " + CompilationSummary(varOrdinaryConstructionCompilation))

Local blockingStyleSource:String = "SuperStrict~nEnum EWaitUnit~nMilliseconds~nEnd Enum~nType TWaitBase<T>~nField value:T~nMethod New(input:T)~nvalue = input~nEnd Method~nMethod Dequeue:T()~nReturn value~nEnd Method~nEnd Type~nType TWaitQueue<T> Extends TWaitBase<T>~nMethod New(input:T)~nSuper.New(input)~nEnd Method~nMethod Dequeue:T(timeout:ULong, unit:EWaitUnit = EWaitUnit.Milliseconds)~nReturn Super.Dequeue()~nEnd Method~nMethod Dequeue:T()~nReturn Super.Dequeue()~nEnd Method~nMethod Choose:T(input:T)~nReturn input~nEnd Method~nMethod Choose:T(input:TWaitBase<T>)~nReturn input.value~nEnd Method~nEnd Type~nGlobal waitQueue:TWaitQueue<String> = New TWaitQueue<String>(~qready~q)~nGlobal waitedDefault:String = waitQueue.Dequeue(1)~nGlobal waitedImmediate:String = waitQueue.Dequeue()~nGlobal chosenWait:String = waitQueue.Choose(~qselected~q)"
Local blockingStyleCompilation:TCompilerResult = TBlitzMaxCompiler.Compile("generic-blocking-style.bmx", blockingStyleSource, Null, compilerOptions)
Check(blockingStyleCompilation.Succeeded() And blockingStyleCompilation.genericPlan.registry.nodes.length = 2, "BlockingQueue-shaped inheritance, enum defaults, and Super constructor delegation specialize without source reparsing: " + CompilationSummary(blockingStyleCompilation))
Local waitQueueUnit:TCompilerGenericUnit
For Local blockingStyleUnit:TCompilerGenericUnit = EachIn blockingStyleCompilation.genericPlan.units
	If blockingStyleUnit.specialization.artifact.identity.qualifiedName.ToLower() = "twaitqueue" Then waitQueueUnit = blockingStyleUnit; Exit
Next
Check(waitQueueUnit And waitQueueUnit.ir.constructors.length = 1 And waitQueueUnit.ir.constructors[0].delegatedConstructorSpecialization = waitQueueUnit.ir.baseSpecialization, "derived generic Type owns only its declared constructor and records Super.New as an explicit base-specialization edge")
Local waitDequeueCount:Int
Local firstWaitDequeueAbiName:String
Local distinctWaitDequeueAbiNames:Int = True
For Local waitMethod:TCompilerGenericMethodIr = EachIn waitQueueUnit.ir.methods
	If waitMethod.name.ToLower() <> "dequeue" Then Continue
	waitDequeueCount :+ 1
	If Not firstWaitDequeueAbiName.length Then
		firstWaitDequeueAbiName = waitMethod.abiName
	Else If firstWaitDequeueAbiName = waitMethod.abiName Then
		distinctWaitDequeueAbiNames = False
	End If
Next
Check(waitDequeueCount = 2 And distinctWaitDequeueAbiNames, "closed generic method overloads receive distinct deterministic signature-qualified C identities after override replacement")
Check(waitQueueUnit.implementation.Contains("BBULONG timeout") And waitQueueUnit.implementation.Contains("BBINT unit") And waitQueueUnit.implementation.Contains("_init((struct " + waitQueueUnit.ir.baseSpecialization.readableAbiName + "_obj *)self"), "specialization C carries the scalar enum ABI, optional-call closure, and separately owned base constructor initializer")
Local stringChooseSlot:String
Local objectChooseSlot:String
For Local waitMethod:TCompilerGenericMethodIr = EachIn waitQueueUnit.ir.methods
	If waitMethod.name.ToLower() <> "choose" Then Continue
	If waitMethod.parameters[0].semanticType.CanonicalName() = "string" Then stringChooseSlot = waitMethod.slotName Else objectChooseSlot = waitMethod.slotName
Next
Local blockingStyleRuntimeDiagnostics:TCompilerDiagnostic[]
Local blockingStyleRuntimeC:String = TBlitzMaxCompiler.EmitRuntimeC(blockingStyleCompilation, blockingStyleRuntimeDiagnostics)
Check(blockingStyleRuntimeDiagnostics.length = 0 And stringChooseSlot.length And objectChooseSlot.length And blockingStyleRuntimeC.Contains("->clas->" + stringChooseSlot + "(") And Not blockingStyleRuntimeC.Contains("->clas->" + objectChooseSlot + "("), "application IR selects a same-arity generic overload by its closed parameter signature rather than name and arity")

Local registry:TGenericSpecializationRegistry = TGenericSpecializationRegistry.Create(Configuration())
Local list1:TGenericSpecializationNode = registry.Request(artifact, [Builtin("String")], RequestSite("file1", GENERIC_REQUEST_TYPE_USE))
Local list2:TGenericSpecializationNode = registry.Request(artifact, [Builtin("String")], RequestSite("file2", GENERIC_REQUEST_ALLOCATION))
Local list3:TGenericSpecializationNode = registry.Request(artifact, [Builtin("String")], RequestSite("file3", GENERIC_REQUEST_SIGNATURE))
Check(list1 = list2 And list2 = list3, "independent requests intern one canonical specialization")
Check(registry.nodes.length = 1 And list1.requests.length = 3, "deduplicated specialization retains every request site")
Check(list1.identityDigest.length = 64 And list1.readableAbiName.ToLower().Contains("collections_core_tarraylist_string"), "readable ABI name carries a SHA-256 identity suffix")
Check(list1.generatedUnit = ".generics/units/" + list1.cacheKey + ".c", "implementation unit is deterministic, specialization-owned, and addressed by its identity-bearing code-generation key")

Local loweringDiagnostics:String[]
Local specializationIr:TCompilerGenericSpecializationIr = TCompilerGenericSpecializationLowerer.Lower(list1, loweringDiagnostics)
Check(loweringDiagnostics.length = 0 And specializationIr.fields.length = 1 And specializationIr.methods.length = 1, "simple generic Type lowers into typed specialization IR")
Check(specializationIr.fields[0].semanticType.CanonicalName() = "string" And specializationIr.methods[0].returnType.CanonicalName() = "string", "type parameter substitution reaches fields and method bodies without source parsing")
Local declarationDiagnostics:String[]
Local declarations:String = TCompilerGenericCUnitEmitter.EmitDeclarations(specializationIr, declarationDiagnostics)
Local unitDiagnostics:String[]
Local implementationUnit:String = TCompilerGenericCUnitEmitter.EmitImplementationUnit(specializationIr, unitDiagnostics)
Check(declarationDiagnostics.length = 0 And unitDiagnostics.length = 0, "specialization declaration and implementation units emit without diagnostics")
Check(declarations.Contains("struct " + list1.readableAbiName + "_obj {") And declarations.Contains("extern struct " + list1.readableAbiName + "_class " + list1.readableAbiName + ";"), "consumer declaration view exposes the specialization ABI layout without defining descriptor storage")
Check(implementationUnit.Contains("struct " + list1.readableAbiName + "_class " + list1.readableAbiName + " = {") And implementationUnit.Contains("return self->" + specializationIr.fields[0].abiName + ";"), "separate deterministic C unit owns the runtime descriptor and specialized method body")
Check(implementationUnit.Contains("bbObjectRegisterType((BBClass *)&" + list1.readableAbiName + ")") And implementationUnit.Contains("*)bbObjectNew(clas);"), "managed specialization emits explicit runtime registration and allocation through its generated helper")
Check(implementationUnit.Contains("BBDEBUGSCOPE_USERTYPE, ~qTArrayList<string>~q") And implementationUnit.Contains("bbObjectFree, (BBDebugScope *)&" + list1.readableAbiName + "_debug_scope"), "generic Type descriptor publishes a deterministic non-null runtime reflection identity")

Local sameNameOtherModule:TGenericSpecializationNode = registry.Request(ListArtifact("Other.Collections", "template-body-a"), [Builtin("String")], RequestSite("collision-module", GENERIC_REQUEST_TYPE_USE))
Local differentArgument:TGenericSpecializationNode = registry.Request(artifact, [Builtin("Int")], RequestSite("collision-argument", GENERIC_REQUEST_TYPE_USE))
Check(sameNameOtherModule <> list1 And sameNameOtherModule.identityDigest <> list1.identityDigest, "same-name generic declarations in different modules stay distinct")
Check(differentArgument <> list1 And differentArgument.identityDigest <> list1.identityDigest, "different canonical type arguments stay distinct")
Check(sameNameOtherModule.readableAbiName <> list1.readableAbiName And differentArgument.readableAbiName <> list1.readableAbiName, "ABI names cannot collide across module or argument identities")

Local reversed:TGenericSpecializationRegistry = TGenericSpecializationRegistry.Create(Configuration())
reversed.Request(artifact, [Builtin("Int")], RequestSite("collision-argument", GENERIC_REQUEST_TYPE_USE))
reversed.Request(ListArtifact("Other.Collections", "template-body-a"), [Builtin("String")], RequestSite("collision-module", GENERIC_REQUEST_TYPE_USE))
reversed.Request(artifact, [Builtin("String")], RequestSite("file3", GENERIC_REQUEST_SIGNATURE))
reversed.Request(artifact, [Builtin("String")], RequestSite("file1", GENERIC_REQUEST_TYPE_USE))
reversed.Request(artifact, [Builtin("String")], RequestSite("file2", GENERIC_REQUEST_ALLOCATION))
Check(registry.Manifest() = reversed.Manifest(), "manifest output is independent of request and import order")
Check(registry.Manifest().Contains("content-revision " + artifact.contentRevision) And registry.Manifest().Contains("generated-unit .generics/units/"), "manifest exposes content revision, requests, owner, identity, arguments, and generated unit")

Local otherTarget:TGenericSpecializationRegistry = TGenericSpecializationRegistry.Create(Configuration("linux", "x64"))
Local otherTargetNode:TGenericSpecializationNode = otherTarget.Request(artifact, [Builtin("String")], RequestSite("file1", GENERIC_REQUEST_TYPE_USE))
Check(otherTargetNode.key.CanonicalName() = list1.key.CanonicalName(), "target and build configuration do not change semantic specialization identity")
Check(otherTargetNode.cacheKey <> list1.cacheKey, "target and architecture participate in the implementation cache key")

Local applicationConfiguration:TCompilerGenericConfiguration = Configuration()
applicationConfiguration.applicationIdentity = "application.demo"
applicationConfiguration.threadingMode = "threaded"
applicationConfiguration.conditionalEnvironmentRevision = "conditions-console-threaded"
Local applicationRegistry:TGenericSpecializationRegistry = TGenericSpecializationRegistry.Create(applicationConfiguration)
Local applicationNode:TGenericSpecializationNode = applicationRegistry.Request(artifact, [Builtin("String")], RequestSite("application-options", GENERIC_REQUEST_TYPE_USE))
Check(applicationNode.key.CanonicalName() = list1.key.CanonicalName() And applicationNode.cacheKey <> list1.cacheKey, "application linkage identity, threading and conditional environments preserve semantic identity while invalidating specialization implementation caches")
Local applicationNodeInitialCacheKey:String = applicationNode.cacheKey
applicationNode.applicationSourceOwned = True
applicationNode.definingSourceUnitPath = "nested/types.bmx"
applicationRegistry.FinalizeCacheKeys()
Local applicationSourceUnitDiagnostics:String[]
Local applicationSourceUnitIr:TCompilerGenericSpecializationIr = TCompilerGenericSpecializationLowerer.Lower(applicationNode, applicationSourceUnitDiagnostics)
Local applicationSourceUnitC:String = TCompilerGenericCUnitEmitter.EmitImplementationUnit(applicationSourceUnitIr, applicationSourceUnitDiagnostics)
Check(applicationSourceUnitDiagnostics.length = 0 And applicationNode.cacheKey <> applicationNodeInitialCacheKey And applicationSourceUnitC.Contains("#include <nested/.bmx/types.bmx.release.macos.arm64.h>"), "application-owned quoted generic specializations use their defining source-unit header and cache identity rather than a synthetic module path")
applicationNode.definingSourceUnitPath = ""
Local primaryApplicationSourceC:String = TCompilerGenericCUnitEmitter.EmitImplementationUnit(applicationSourceUnitIr, applicationSourceUnitDiagnostics)
Check(Not primaryApplicationSourceC.Contains("#include <collections.mod/core.mod/"), "a generic declared in the primary application source does not invent a module header that the application build never publishes")

Local cycleRegistry:TGenericSpecializationRegistry = TGenericSpecializationRegistry.Create(Configuration())
Local cycleString:TGenericSpecializationNode = cycleRegistry.Request(artifact, [Builtin("String")], RequestSite("cycle-a", GENERIC_REQUEST_TRANSITIVE))
Local cycleInt:TGenericSpecializationNode = cycleRegistry.Request(artifact, [Builtin("Int")], RequestSite("cycle-b", GENERIC_REQUEST_TRANSITIVE))
cycleRegistry.AddEdge(cycleString, cycleInt, RequestSite("cycle-a", GENERIC_REQUEST_TRANSITIVE))
cycleRegistry.AddEdge(cycleInt, cycleString, RequestSite("cycle-b", GENERIC_REQUEST_TRANSITIVE))
Check(cycleRegistry.ValidateCycles() And cycleString.referenceScc.length And cycleString.referenceScc = cycleInt.referenceScc And cycleRegistry.Manifest().Contains("reference-scc " + cycleString.referenceScc), "reference-safe recursive specialization requests receive one explicit deterministic SCC identity")

Local interfaceCycleRegistry:TGenericSpecializationRegistry = TGenericSpecializationRegistry.Create(Configuration())
Local cycleInterfaceAArtifact:TGenericTemplateArtifact = ListArtifact("Cycle.InterfaceA", "cycle-interface-a")
Local cycleInterfaceBArtifact:TGenericTemplateArtifact = ListArtifact("Cycle.InterfaceB", "cycle-interface-b")
cycleInterfaceAArtifact.typeDeclarationKind = GENERIC_TYPE_DECLARATION_INTERFACE
cycleInterfaceBArtifact.typeDeclarationKind = GENERIC_TYPE_DECLARATION_INTERFACE
Local cycleInterfaceA:TGenericSpecializationNode = interfaceCycleRegistry.Request(cycleInterfaceAArtifact, [Builtin("String")], RequestSite("cycle-interface-a", GENERIC_REQUEST_INTERFACE))
Local cycleInterfaceB:TGenericSpecializationNode = interfaceCycleRegistry.Request(cycleInterfaceBArtifact, [Builtin("String")], RequestSite("cycle-interface-b", GENERIC_REQUEST_INTERFACE))
interfaceCycleRegistry.AddEdge(cycleInterfaceA, cycleInterfaceB, RequestSite("cycle-interface-a", GENERIC_REQUEST_INTERFACE))
interfaceCycleRegistry.AddEdge(cycleInterfaceB, cycleInterfaceA, RequestSite("cycle-interface-b", GENERIC_REQUEST_INTERFACE))
Check(interfaceCycleRegistry.ValidateCycles() And cycleInterfaceA.referenceScc.length And cycleInterfaceA.referenceScc = cycleInterfaceB.referenceScc, "recursive canonical generic Interface requests receive one explicit deterministic SCC identity before method-layout validation")

If AppArgs.length = 3 And AppArgs[1] = "--emit-unit" Then
	SaveText(implementationUnit, AppArgs[2])
End If
If AppArgs.length = 4 And AppArgs[1] = "--emit-eachin-units" Then
	SaveText(iterableEachInImplementation, AppArgs[2])
	SaveText(legacyEachInImplementation, AppArgs[3])
End If
If AppArgs.length = 4 And AppArgs[1] = "--emit-eachin-cast-units" Then
	SaveText(legacyTypeCastImplementation, AppArgs[2])
	SaveText(legacyInterfaceCastImplementation, AppArgs[3])
End If
If AppArgs.length = 3 And AppArgs[1] = "--emit-direct-method-units" Then
	For Local directOutputUnit:TCompilerGenericUnit = EachIn directMethodConsumerCompilation.genericPlan.units
		SaveText(directOutputUnit.implementation, AppArgs[2] + "/" + directOutputUnit.specialization.identityDigest + ".c")
	Next
	For Local inheritedDirectOutputUnit:TCompilerGenericUnit = EachIn inheritedDirectConsumerCompilation.genericPlan.units
		SaveText(inheritedDirectOutputUnit.implementation, AppArgs[2] + "/" + inheritedDirectOutputUnit.specialization.identityDigest + ".c")
	Next
	For Local mixedDirectOutputUnit:TCompilerGenericUnit = EachIn mixedDirectConsumerCompilation.genericPlan.units
		SaveText(mixedDirectOutputUnit.implementation, AppArgs[2] + "/" + mixedDirectOutputUnit.specialization.identityDigest + ".c")
	Next
	For Local mixedCollisionOutputUnit:TCompilerGenericUnit = EachIn mixedDirectCollisionCompilation.genericPlan.units
		SaveText(mixedCollisionOutputUnit.implementation, AppArgs[2] + "/" + mixedCollisionOutputUnit.specialization.identityDigest + ".c")
	Next
	For Local localDirectOutputUnit:TCompilerGenericUnit = EachIn localDirectCompilation.genericPlan.units
		SaveText(localDirectOutputUnit.implementation, AppArgs[2] + "/" + localDirectOutputUnit.specialization.identityDigest + ".c")
	Next
End If
If AppArgs.length = 3 And AppArgs[1] = "--emit-wide-struct-build" Then
	Local wideStructMaterializationDiagnostics:TCompilerDiagnostic[]
	TCompilerBuildOutputMaterializer.Materialize(wideStructBuildPlan, AppArgs[2], "wide-struct.manifest", wideStructMaterializationDiagnostics)
	Check(wideStructMaterializationDiagnostics.length = 0, "wide generic Struct build plan materializes for strict native validation")
End If

Print "bcc2 canonical generic-specialization tests passed"
