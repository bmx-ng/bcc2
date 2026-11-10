SuperStrict

Framework BRL.StandardIO
Import BlitzMax.Compiler
Import BRL.Map

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Function HasDiagnostic:Int(result:TCompilerResult, code:String)
	If Not result Or Not result.analysis Then Return False
	For Local diagnostic:TDiagnostic = EachIn result.analysis.model.diagnostics
		If diagnostic.code = code Then Return True
	Next
	Return False
End Function

Type TConstraintResolver Extends TSnapshotResolver
	Field includes:TMap = New TMap
	Field interfaces:TMap = New TMap
	Field templates:TMap = New TMap

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
		Return TSnapshotText(templates.ValueForKey(artifactReference.ToLower()))
	End Method
End Type

Local options:TCompilerOptions = TCompilerOptions.CreateDefault()
options.requireCoreInterface = False
options.targetPlatform = "test"
options.targetArchitecture = "x64"
options.conditionalSymbols = ["bmxng", "ptr64"]

Local clamp:String = "Function Clamp<T>:T(value:T, low:T, high:T) Where T Is Numeric~nIf value < low Then Return low~nIf value > high Then Return high~nReturn value~nEnd Function"
Local primitiveNames:String[] = ["Byte", "Short", "Int", "UInt", "Long", "ULong", "LongInt", "ULongInt", "Size_T", "Float", "Double"]
For Local name:String = EachIn primitiveNames
	Local source:String = "SuperStrict~n" + clamp + "~nLocal n:" + name + " = 1~nLocal answer:" + name + " = Clamp(n, 0, 1)~nLocal explicit:" + name + " = Clamp<" + name + ">(n, 0, 1)"
	Local result:TCompilerResult = TBlitzMaxCompiler.Compile("numeric-" + name + ".bmx", source, Null, options)
	Check(result.Succeeded(), "Numeric inference and representable constants must support " + name)
Next

Local integral:String = "Function Combine<T>:T(a:T, b:T) Where T Is Integral~nReturn (a Mod b) Shl 1~nEnd Function"
For Local name:String = EachIn primitiveNames
	Local source:String = "SuperStrict~n" + integral + "~nLocal a:" + name + " = 3~nLocal result:" + name + " = Combine(a, 2)"
	Local result:TCompilerResult = TBlitzMaxCompiler.Compile("integral-" + name + ".bmx", source, Null, options)
	If name = "Float" Or name = "Double" Then
		Check(Not result.Succeeded() And HasDiagnostic(result, "BMX3302"), "Integral rejects " + name)
	Else
		Check(result.Succeeded(), "Integral arithmetic must support " + name)
	End If
Next

Local badStrings:String[] = [ ..
	"SuperStrict~n" + clamp + "~nLocal result:String = Clamp<String>(~qbad~q, ~qa~q, ~qz~q)", ..
	"SuperStrict~n" + clamp + "~nLocal result:Bool = Clamp<Bool>(True, False, True)", ..
	"SuperStrict~n" + clamp + "~nLocal n:Byte = 1~nLocal result:Byte = Clamp(n, 0, 256)", ..
	"SuperStrict~n" + clamp + "~nLocal n:UInt = 1~nLocal result:UInt = Clamp(n, -1, 1)", ..
	"SuperStrict~n" + clamp + "~nLocal n:Byte = 1~nLocal wide:Int = 1~nLocal result:Byte = Clamp(n, 0, wide)" ..
]
For Local index:Int = 0 Until badStrings.length
	Local result:TCompilerResult = TBlitzMaxCompiler.Compile("numeric-negative-" + index + ".bmx", badStrings[index], Null, options)
	Check(Not result.Succeeded() And HasDiagnostic(result, "BMX3302"), "Numeric rejects nonmembers, out-of-range constants and typed narrowing case " + index)
Next
Local unconstrained:TCompilerResult = TBlitzMaxCompiler.Compile("unconstrained-inference.bmx", "SuperStrict~nFunction Keep<T>:T(a:T,b:T)~nReturn a~nEnd Function~nLocal value:Byte = 1~nLocal result:Byte = Keep(value, 1)", Null, options)
Check(Not unconstrained.Succeeded() And HasDiagnostic(unconstrained, "BMX3302"), "unconstrained generic inference retains its existing argument matching")

Local invalidOperator:TCompilerResult = TBlitzMaxCompiler.Compile("numeric-mod.bmx", "SuperStrict~nFunction Modulo<T>:T(a:T,b:T) Where T Is Numeric~nReturn a Mod b~nEnd Function", Null, options)
Check(Not invalidOperator.Succeeded() And HasDiagnostic(invalidOperator, "BMX3305"), "Numeric excludes Mod during open body checking")
Local invalidUnary:TCompilerResult = TBlitzMaxCompiler.Compile("numeric-complement.bmx", "SuperStrict~nFunction Complement<T>:T(a:T) Where T Is Numeric~nReturn ~~a~nEnd Function", Null, options)
Check(Not invalidUnary.Succeeded() And HasDiagnostic(invalidUnary, "BMX3305"), "Numeric excludes bitwise complement during open body checking")
Local integralOnlyOperators:String[] = ["Mod", "Shl", "Shr", "Sar", "&", "|", "~~"]
For Local operatorText:String = EachIn integralOnlyOperators
	Local invalidBody:TCompilerResult = TBlitzMaxCompiler.Compile("numeric-operator-" + operatorText + ".bmx", "SuperStrict~nFunction Apply<T>:T(a:T,b:T) Where T Is Numeric~nReturn a " + operatorText + " b~nEnd Function", Null, options)
	Check(Not invalidBody.Succeeded() And HasDiagnostic(invalidBody, "BMX3305"), "Numeric excludes integral-only operator " + operatorText)
Next
Local invalidCompound:TCompilerResult = TBlitzMaxCompiler.Compile("numeric-compound.bmx", "SuperStrict~nFunction Apply<T>:T(a:T,b:T) Where T Is Numeric~na :Mod b~nReturn a~nEnd Function", Null, options)
Check(Not invalidCompound.Succeeded() And HasDiagnostic(invalidCompound, "BMX3305"), "Numeric excludes integral compound assignment")
Local unknownCapability:TCompilerResult = TBlitzMaxCompiler.Compile("numeric-unknown-capability.bmx", "SuperStrict~nFunction Apply<T>:T(a:T) Where T Is Geometry~nReturn a~nEnd Function", Null, options)
Check(Not unknownCapability.Succeeded() And HasDiagnostic(unknownCapability, "BMX3210"), "unknown capability is diagnosed at its declaration")
Local multipleCapabilities:TCompilerResult = TBlitzMaxCompiler.Compile("numeric-multiple-capabilities.bmx", "SuperStrict~nFunction Combine<T,U>:T(a:T,b:U) Where T Is Numeric, U Is Integral~nReturn a~nEnd Function~nLocal n:Double = 0.5~nLocal i:Int = 1~nLocal result:Double = Combine(n,i)", Null, options)
Check(multipleCapabilities.Succeeded(), "comma-separated capability clauses bind to their own parameters")

Local typeSource:String = "SuperStrict~nStruct SBox<T> Where T Is Integral~nField value:T~nEnd Struct~nStruct SWrapped<U> Where U Is Integral~nField inner:SBox<U>~nEnd Struct~nLocal box:SWrapped<Int>"
Check(TBlitzMaxCompiler.Compile("numeric-types.bmx", typeSource, Null, options).Succeeded(), "Integral capability flows through open generic types")
Local invalidType:TCompilerResult = TBlitzMaxCompiler.Compile("numeric-type-invalid.bmx", "SuperStrict~nStruct SBox<T> Where T Is Integral~nField value:T~nEnd Struct~nLocal box:SBox<Float>", Null, options)
Check(Not invalidType.Succeeded() And HasDiagnostic(invalidType, "BMX3209"), "closed type arguments enforce Integral")
Local inheritedType:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TBase~nEnd Type~nType TChild<T> Where T Is Numeric Extends TBase~nEnd Type~nLocal child:TChild<Int>", "numeric-inherited-type.bmx")
Check(inheritedType.Succeeded(), "capability clause leaves a following Extends declaration clause intact")
Local methodSource:String = "SuperStrict~nStruct SCalculator<T> Where T Is Numeric~nMethod Clip:T(value:T, low:T, high:T)~nIf value < low Then Return low~nIf value > high Then Return high~nReturn value~nEnd Method~nEnd Struct~nLocal calculator:SCalculator<Double>~nLocal n:Double = 0.5~nLocal result:Double = calculator.Clip(n, 0, 1)"
Check(TBlitzMaxCompiler.Compile("numeric-method.bmx", methodSource, Null, options).Succeeded(), "constrained Type method checks and specializes numeric operators")
Local scalarCastSource:String = "SuperStrict~nStruct SScalar<T> Where T Is Numeric~nField value:T~nMethod Scale:T()~nReturn value * T(2.0)~nEnd Method~nMethod ToDouble:Double()~nReturn Double(value)~nEnd Method~nMethod Literal:T()~nReturn value * 2.0~nEnd Method~nEnd Struct~nLocal value:SScalar<Float>"
Check(TBlitzMaxCompiler.Compile("numeric-scalar-casts.bmx", scalarCastSource, Null, options).Succeeded(), "Numeric type parameters support explicit scalar casts and universally representable literals")
Local fractionalLiteral:TCompilerResult = TBlitzMaxCompiler.Compile("numeric-fractional-literal.bmx", "SuperStrict~nStruct SScale<T> Where T Is Numeric~nMethod Operator*:SScale<T>(amount:T)~nReturn Self~nEnd Method~nMethod Scale:SScale<T>()~nReturn Self * 2.5~nEnd Method~nEnd Struct", Null, options)
Check(Not fractionalLiteral.Succeeded() And HasDiagnostic(fractionalLiteral, "BMX3302"), "fractional literal cannot implicitly become every Numeric type")
Local implicitNarrowing:TCompilerResult = TBlitzMaxCompiler.Compile("numeric-implicit-double-to-t.bmx", "SuperStrict~nStruct SScale<T> Where T Is Numeric~nMethod Value:T()~nLocal amount:Double = 2.0~nReturn amount~nEnd Method~nEnd Struct", Null, options)
Check(Not implicitNarrowing.Succeeded() And HasDiagnostic(implicitNarrowing, "BMX3310"), "typed Double cannot implicitly become every Numeric type")
Local implicitWidening:TCompilerResult = TBlitzMaxCompiler.Compile("numeric-implicit-t-to-double.bmx", "SuperStrict~nStruct SScale<T> Where T Is Numeric~nField amount:T~nMethod Value:Double()~nReturn amount~nEnd Method~nEnd Struct", Null, options)
Check(Not implicitWidening.Succeeded() And HasDiagnostic(implicitWidening, "BMX3310"), "Numeric T to Double requires an explicit cast")
Local negativeLiteral:TCompilerResult = TBlitzMaxCompiler.Compile("numeric-negative-literal.bmx", "SuperStrict~nStruct SScale<T> Where T Is Numeric~nMethod Operator*:SScale<T>(amount:T)~nReturn Self~nEnd Method~nMethod Scale:SScale<T>()~nReturn Self * -1~nEnd Method~nEnd Struct", Null, options)
Check(Not negativeLiteral.Succeeded() And HasDiagnostic(negativeLiteral, "BMX3302"), "negative literal cannot implicitly become every Numeric type")
Local genericMethodSource:String = "SuperStrict~nStruct SMath~nMethod Twice<U>:U(value:U) Where U Is Numeric~nReturn value + value~nEnd Method~nEnd Struct~nLocal math:SMath~nLocal n:Double = 0.5~nLocal result:Double = math.Twice(n)"
Check(TBlitzMaxCompiler.Compile("numeric-generic-method.bmx", genericMethodSource, Null, options).Succeeded(), "method-owned numeric capability specializes")
Local overloadSource:String = "SuperStrict~nFunction Choose<T>:Int(value:T) Where T Is Numeric~nReturn 1~nEnd Function~nFunction Choose:Int(value:String)~nReturn 2~nEnd Function~nLocal number:Int = Choose(1)~nLocal text:Int = Choose(~qtext~q)"
Check(TBlitzMaxCompiler.Compile("numeric-overloads.bmx", overloadSource, Null, options).Succeeded(), "capability filters generic overload applicability")

Local includeResolver:TConstraintResolver = New TConstraintResolver
includeResolver.includes.Insert("numeric-declarations.bmx", TSnapshotText.Create("numeric-declarations.bmx", clamp))
Local includeConsumer:String = "SuperStrict~nInclude ~qnumeric-declarations.bmx~q~nLocal value:Double = 0.5~nLocal result:Double = Clamp(value, 0, 1)"
Check(TBlitzMaxCompiler.Compile("numeric-include.bmx", includeConsumer, includeResolver, options).Succeeded(), "Include preserves capability inference")

Local provider:String = "SuperStrict~nModule Constraints.NumericApi~n" + clamp + "~nStruct SBox<T> Where T Is Integral~nField value:T~nEnd Struct"
Local published:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/constraints.mod/numericapi.mod/numericapi.bmx", provider, Null, options)
Check(published.Succeeded(), "constrained module compiles")
Local outputs:TCompilerGenericTemplateOutput[]
Local artifactDiagnostics:TCompilerDiagnostic[]
outputs = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(published, artifactDiagnostics)
Check(artifactDiagnostics.length = 0 And outputs.length = 2, "constrained module emits two generic companions")
Local interfaceDiagnostics:TCompilerDiagnostic[]
Local interfaceText:String = TBlitzMaxCompiler.EmitInterface(published, interfaceDiagnostics)
Check(interfaceDiagnostics.length = 0 And interfaceText.Contains("Where T Is Numeric") And interfaceText.Contains("Where T Is Integral"), "compact interface preserves capability clauses")
Local resolver:TConstraintResolver = New TConstraintResolver
resolver.interfaces.Insert("constraints.numericapi", TSnapshotText.Create("sdk/constraints.numericapi.i", interfaceText))
For Local output:TCompilerGenericTemplateOutput = EachIn outputs
	resolver.templates.Insert(output.artifactReference.ToLower(), TSnapshotText.Create("sdk/" + output.artifactReference, output.content))
	Local decoded:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(output.content)
	Check(decoded.Succeeded() And decoded.artifact.parameters[0].capability > 0, "artifact round trip retains capability")
	If output.artifact.identity.qualifiedName = "SBox" Then
		Local floatType:TTemplateTypeReference = New TTemplateTypeReference
		floatType.kind = TEMPLATE_TYPE_BUILTIN
		floatType.symbolName = "Float"
		Local registry:TGenericSpecializationRegistry = TGenericSpecializationRegistry.Create(Null)
		Check(Not registry.Request(decoded.artifact, [floatType], Null) And registry.diagnostics.length = 1 And registry.diagnostics[0].Contains("BMXC3093"), "closed specialization validates artifact capabilities independently")
	End If
Next
Local consumer:String = "SuperStrict~nImport Constraints.NumericApi~nLocal n:Float = 0.5~nLocal result:Float = Clamp(n, 0, 1)~nLocal box:SBox<Int>"
Check(TBlitzMaxCompiler.Compile("numeric-consumer.bmx", consumer, resolver, options).Succeeded(), "compiled interface consumer resolves inferred Numeric and Integral type")
Local rejectedConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("numeric-rejected-consumer.bmx", "SuperStrict~nImport Constraints.NumericApi~nLocal box:SBox<Float>", resolver, options)
Check(Not rejectedConsumer.Succeeded() And HasDiagnostic(rejectedConsumer, "BMX3209"), "compiled interface retains Integral rejection")
Local rejectedRoutineConsumer:TCompilerResult = TBlitzMaxCompiler.Compile("numeric-rejected-routine-consumer.bmx", "SuperStrict~nImport Constraints.NumericApi~nLocal result:String = Clamp<String>(~qa~q, ~qa~q, ~qz~q)", resolver, options)
Check(Not rejectedRoutineConsumer.Succeeded() And HasDiagnostic(rejectedRoutineConsumer, "BMX3302"), "compiled interface retains routine applicability")

Local quotedResolver:TConstraintResolver = New TConstraintResolver
quotedResolver.interfaces.Insert("numeric-provider.bmx", TSnapshotText.Create("sdk/.bmx/numeric-provider.bmx.release.test.x64.i", interfaceText))
For Local output:TCompilerGenericTemplateOutput = EachIn outputs
	quotedResolver.templates.Insert(output.artifactReference.ToLower(), TSnapshotText.Create("sdk/" + output.artifactReference, output.content))
Next
Local quotedConsumer:String = "SuperStrict~nImport ~qnumeric-provider.bmx~q~nLocal n:Double = 0.5~nLocal result:Double = Clamp(n, 0, 1)"
Check(TBlitzMaxCompiler.Compile("numeric-quoted-consumer.bmx", quotedConsumer, quotedResolver, options).Succeeded(), "direct quoted source import resolves the constrained source interface")

Print "Numeric generic constraint tests passed"
