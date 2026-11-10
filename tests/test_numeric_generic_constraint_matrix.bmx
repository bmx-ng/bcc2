SuperStrict

Framework BRL.StandardIO
Import BlitzMax.Compiler
Import BRL.Map

Type TMatrixResolver Extends TSnapshotResolver
	Field interfaces:TMap = New TMap
	Field templates:TMap = New TMap

	Method ResolveInclude:TSnapshotText(includingPath:String, includePath:String)
		Return Null
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

Type TMatrixOperation
	Field token:String
	Field unary:Int
	Field comparison:Int
	Field integralOnly:Int
End Type

Type TMatrixConversion
	Field name:String
	Field returnType:String
	Field body:String
	Field acceptedMask:Int
	Field specializedMask:Int
	Field rejectedCode:String
End Type

Function Conversion:TMatrixConversion(name:String, returnType:String, body:String, acceptedMask:Int, rejectedCode:String = "BMX3310", specializedMask:Int = -1)
	Local result:TMatrixConversion = New TMatrixConversion
	result.name = name
	result.returnType = returnType
	result.body = body
	result.acceptedMask = acceptedMask
	If specializedMask < 0 Then specializedMask = acceptedMask
	result.specializedMask = specializedMask
	result.rejectedCode = rejectedCode
	Return result
End Function

Function Operation:TMatrixOperation(token:String, unary:Int = False, comparison:Int = False, integralOnly:Int = False)
	Local result:TMatrixOperation = New TMatrixOperation
	result.token = token
	result.unary = unary
	result.comparison = comparison
	result.integralOnly = integralOnly
	Return result
End Function

Function HasDiagnostic:Int(result:TCompilerResult, code:String)
	If Not result Then Return False
	If result.analysis And result.analysis.model Then
		For Local diagnostic:TDiagnostic = EachIn result.analysis.model.diagnostics
			If diagnostic.code = code Then Return True
		Next
	End If
	For Local diagnostic:TCompilerDiagnostic = EachIn result.diagnostics
		If diagnostic.code = code Then Return True
	Next
	Return False
End Function

Function Diagnostics:String(result:TCompilerResult)
	Local message:String
	If result And result.analysis And result.analysis.model Then
		For Local diagnostic:TDiagnostic = EachIn result.analysis.model.diagnostics
			message :+ " " + diagnostic.code + ":" + diagnostic.message
		Next
	End If
	If result Then
		For Local diagnostic:TCompilerDiagnostic = EachIn result.diagnostics
			message :+ " " + diagnostic.code + ":" + diagnostic.message
		Next
	End If
	Return message
End Function

Global matrixChecked:Int
Global matrixKnownFailures:Int

Function Verify(label:String, source:String, expected:Int, code:String, resolver:TSnapshotResolver, options:TCompilerOptions)
	matrixChecked :+ 1
	Local result:TCompilerResult = TBlitzMaxCompiler.Compile("matrix-" + matrixChecked + ".bmx", source, resolver, options)
	If result.Succeeded() <> expected Then Throw label + ": expected success=" + expected + ", got=" + result.Succeeded() + Diagnostics(result)
	If Not expected And code.length And Not HasDiagnostic(result, code) Then Throw label + ": expected diagnostic " + code + Diagnostics(result)
End Function

Function VerifyWarning(label:String, source:String, code:String, resolver:TSnapshotResolver, options:TCompilerOptions)
	matrixChecked :+ 1
	Local result:TCompilerResult = TBlitzMaxCompiler.Compile("matrix-" + matrixChecked + ".bmx", source, resolver, options)
	If Not result.Succeeded() Or Not HasDiagnostic(result, code) Then Throw label + ": expected successful compilation with warning " + code + Diagnostics(result)
End Function

Function OperatorSource:String(capability:String, operation:TMatrixOperation, name:String)
	Local expression:String = "a " + operation.token + " b"
	If operation.unary Then expression = operation.token + " a"
	Local resultType:String = "T"
	If operation.comparison Then resultType = "Int"
	Return "Function " + name + "<T>:" + resultType + "(a:T, b:T) Where T Is " + capability + "~nReturn " + expression + "~nEnd Function~n"
End Function

Function ConversionSource:String(capability:String, prefix:String, conversion:TMatrixConversion, name:String)
	Return "Function " + name + "<T>:" + conversion.returnType + "(value:T) Where T Is " + capability + "~n" + conversion.body.Replace("$P", prefix) + "~nEnd Function~n"
End Function

Local options:TCompilerOptions = TCompilerOptions.CreateDefault()
options.requireCoreInterface = False
options.targetPlatform = "test"
options.targetArchitecture = "x64"
options.conditionalSymbols = ["bmxng", "ptr64"]

Local types:String[] = ["Byte", "Short", "Int", "UInt", "Long", "ULong", "LongInt", "ULongInt", "Size_T", "Float", "Double", "Bool", "String"]
Local capabilities:String[] = ["Numeric", "Integral", "Floating"]
Local prefixes:String[] = ["N", "I", "F"]
Local operations:TMatrixOperation[] = [ ..
	Operation("+", True), Operation("-", True), Operation("Not", True, True), Operation("~~", True, False, True), ..
	Operation("+"), Operation("-"), Operation("*"), Operation("/"), ..
	Operation("<", False, True), Operation("<=", False, True), Operation(">", False, True), Operation(">=", False, True), Operation("=", False, True), Operation("<>", False, True), ..
	Operation("Mod", False, False, True), Operation("Shl", False, False, True), Operation("Shr", False, False, True), Operation("Sar", False, False, True), ..
	Operation("|", False, False, True), Operation("&", False, False, True), Operation("~~", False, False, True), Operation("^", False, False, True), ..
	Operation("And", False, True, True), Operation("Or", False, True, True) ..
]

' Bit 0 = Numeric, bit 1 = Integral, bit 2 = Floating.
Local conversions:TMatrixConversion[] = [ ..
	Conversion("T to Double return", "Double", "Return value", 4), ..
	' Open binding defers this ordinary free call, but specialization currently
	' loses the canonical call target. Keep the failure visible until repaired.
	Conversion("T to Double argument", "Double", "Return MTakeDouble(value)", 7, "", 4), ..
	Conversion("Float to T return", "T", "Local amount:Float = 2.5~nReturn amount", 4), ..
	Conversion("Float to T assignment", "T", "Local amount:Float = 2.5~nLocal result:T = amount~nReturn result", 4), ..
	Conversion("Float to T argument", "T", "Local amount:Float = 2.5~nReturn M$PTake<T>(amount)", 4, "BMX3302"), ..
	Conversion("Double to T return", "T", "Local amount:Double = 2.5~nReturn amount", 4), ..
	Conversion("Double to T assignment", "T", "Local amount:Double = 2.5~nLocal result:T = amount~nReturn result", 4), ..
	Conversion("Double to T argument", "T", "Local amount:Double = 2.5~nReturn M$PTake<T>(amount)", 0, "BMX3302"), ..
	Conversion("integer literal argument", "T", "Return M$PTake<T>(2)", 7), ..
	Conversion("fractional literal argument", "T", "Return M$PTake<T>(2.5)", 4, "BMX3302"), ..
	Conversion("negative literal argument", "T", "Return M$PTake<T>(-1)", 4, "BMX3302"), ..
	Conversion("overflowing literal argument", "T", "Return M$PTake<T>(1e39)", 0, "BMX3302"), ..
	Conversion("explicit Double to T", "T", "Local amount:Double = 2.5~nReturn T(amount)", 7), ..
	Conversion("explicit T to Double", "Double", "Return Double(value)", 7), ..
	Conversion("cast Double argument", "T", "Local amount:Double = 2.5~nReturn M$PTake<T>(T(amount))", 7), ..
	Conversion("T to Float return", "Float", "Return value", 4) ..
]

Local doubleHelper:String = "Function MTakeDouble:Double(value:Double)~nReturn value~nEnd Function~n"
Local provider:String = "SuperStrict~nModule ConstraintMatrix.Owner~n" + doubleHelper
For Local capabilityIndex:Int = 0 Until capabilities.length
	Local capability:String = capabilities[capabilityIndex]
	Local prefix:String = prefixes[capabilityIndex]
	Local box:String = "M" + prefix + "Box"
	Local declaration:String = "Struct " + box + "<T> Where T Is " + capability + "~nField value:T~nEnd Struct~n"
	provider :+ declaration
	Local takeHelper:String = "Function M" + prefix + "Take<T>:T(value:T) Where T Is " + capability + "~nReturn value~nEnd Function~n"
	provider :+ takeHelper
	For Local typeIndex:Int = 0 Until types.length
		Local typeName:String = types[typeIndex]
		Local integral:Int = typeIndex < 9
		Local floating:Int = typeIndex >= 9 And typeIndex < 11
		Local accepted:Int = typeIndex < 11 And (capabilityIndex = 0 Or (capabilityIndex = 1 And integral) Or (capabilityIndex = 2 And floating))
		Verify("local membership " + capability + " " + typeName, "SuperStrict~n" + declaration + "Local value:" + box + "<" + typeName + ">", accepted, "BMX3209", Null, options)
	Next
	For Local operationIndex:Int = 0 Until operations.length
		Local operation:TMatrixOperation = operations[operationIndex]
		Local valid:Int = capabilityIndex = 1 Or Not operation.integralOnly
		Local functionName:String = "M" + prefix + "Op" + operationIndex
		Local functionText:String = OperatorSource(capability, operation, functionName)
		Verify("open operator " + capability + " " + operation.token + " #" + operationIndex, "SuperStrict~n" + functionText, valid, "BMX3305", Null, options)
		If valid Then provider :+ functionText
	Next
	For Local conversionIndex:Int = 0 Until conversions.length
		Local conversion:TMatrixConversion = conversions[conversionIndex]
		Local valid:Int = (conversion.acceptedMask & (1 Shl capabilityIndex)) <> 0
		Local functionText:String = ConversionSource(capability, prefix, conversion, "M" + prefix + "Conv" + conversionIndex)
		Verify("open conversion " + capability + " " + conversion.name, "SuperStrict~n" + doubleHelper + takeHelper + functionText, valid, conversion.rejectedCode, Null, options)
		If valid Then provider :+ functionText
	Next
Next

Local published:TCompilerResult = TBlitzMaxCompiler.Compile("sdk/mod/constraintmatrix.mod/owner.mod/owner.bmx", provider, Null, options)
If Not published.Succeeded() Then Throw "operator matrix provider did not compile"
Local interfaceDiagnostics:TCompilerDiagnostic[]
Local interfaceText:String = TBlitzMaxCompiler.EmitInterface(published, interfaceDiagnostics)
If interfaceDiagnostics.length Or Not interfaceText.Contains("Where T Is Floating") Then Throw "constraint matrix interface lost capabilities"
Local artifactDiagnostics:TCompilerDiagnostic[]
Local outputs:TCompilerGenericTemplateOutput[] = TBlitzMaxCompiler.EmitGenericTemplateArtifacts(published, artifactDiagnostics)
If artifactDiagnostics.length Or Not outputs.length Then Throw "constraint matrix artifacts were not emitted"
Local resolver:TMatrixResolver = New TMatrixResolver
resolver.interfaces.Insert("constraintmatrix.owner", TSnapshotText.Create("sdk/constraintmatrix.owner.i", interfaceText))
For Local output:TCompilerGenericTemplateOutput = EachIn outputs
	resolver.templates.Insert(output.artifactReference.ToLower(), TSnapshotText.Create("sdk/" + output.artifactReference, output.content))
Next

For Local capabilityIndex:Int = 0 Until capabilities.length
	Local capability:String = capabilities[capabilityIndex]
	Local prefix:String = prefixes[capabilityIndex]
	Local box:String = "M" + prefix + "Box"
	For Local typeIndex:Int = 0 Until types.length
		Local typeName:String = types[typeIndex]
		Local integral:Int = typeIndex < 9
		Local floating:Int = typeIndex >= 9 And typeIndex < 11
		Local accepted:Int = typeIndex < 11 And (capabilityIndex = 0 Or (capabilityIndex = 1 And integral) Or (capabilityIndex = 2 And floating))
		Verify("imported membership " + capability + " " + typeName, "SuperStrict~nImport ConstraintMatrix.Owner~nLocal value:" + box + "<" + typeName + ">", accepted, "BMX3209", resolver, options)
		If Not accepted Then Continue
		For Local operationIndex:Int = 0 Until operations.length
			Local operation:TMatrixOperation = operations[operationIndex]
			If capabilityIndex <> 1 And operation.integralOnly Then Continue
			Local functionName:String = "M" + prefix + "Op" + operationIndex
			Local resultType:String = typeName
			If operation.comparison Then resultType = "Int"
			Local declaration:String = OperatorSource(capability, operation, functionName)
			Local body:String = "Local a:" + typeName + " = 2~nLocal result:" + resultType + " = " + functionName + "<" + typeName + ">(a, a)"
			Verify("local specialization " + capability + " " + typeName + " " + operation.token + " #" + operationIndex, "SuperStrict~n" + declaration + body, True, "", Null, options)
			Verify("imported specialization " + capability + " " + typeName + " " + operation.token + " #" + operationIndex, "SuperStrict~nImport ConstraintMatrix.Owner~n" + body, True, "", resolver, options)
		Next
		For Local conversionIndex:Int = 0 Until conversions.length
			Local conversion:TMatrixConversion = conversions[conversionIndex]
			If (conversion.acceptedMask & (1 Shl capabilityIndex)) = 0 Then Continue
			Local functionName:String = "M" + prefix + "Conv" + conversionIndex
			Local returnType:String = conversion.returnType
			If returnType = "T" Then returnType = typeName
			Local body:String = "Local seed:" + typeName + " = 2~nLocal result:" + returnType + " = " + functionName + "<" + typeName + ">(seed)"
			Local localSource:String = "SuperStrict~n" + doubleHelper + "Function M" + prefix + "Take<T>:T(value:T) Where T Is " + capability + "~nReturn value~nEnd Function~n" + ConversionSource(capability, prefix, conversion, functionName) + body
			Local specialized:Int = (conversion.specializedMask & (1 Shl capabilityIndex)) <> 0
			If conversion.name = "T to Double argument" And typeName = "Double" Then specialized = True
			Local specializedCode:String
			If Not specialized Then
				specializedCode = "BMXC3027"
				matrixKnownFailures :+ 2
			End If
			Verify("local conversion " + capability + " " + typeName + " " + conversion.name, localSource, specialized, specializedCode, Null, options)
			Verify("imported conversion " + capability + " " + typeName + " " + conversion.name, "SuperStrict~nImport ConstraintMatrix.Owner~n" + body, specialized, specializedCode, resolver, options)
		Next
		Local callExpressions:String[] = ["2", "2.5", "typedFloat", "typedDouble", "1e39"]
		Local callNames:String[] = ["integer literal", "fractional literal", "typed Float", "typed Double", "large Double literal"]
		For Local callIndex:Int = 0 Until callExpressions.length
			Local callSetup:String = "Local typedFloat:Float = 2.5~nLocal typedDouble:Double = 2.5~n"
			Local callBody:String = callSetup + "Local result:" + typeName + " = M" + prefix + "Take<" + typeName + ">(" + callExpressions[callIndex] + ")"
			Local callExpected:Int
			Select callIndex
				Case 0 callExpected = True
				Case 1, 2 callExpected = floating
				Case 3, 4 callExpected = typeName = "Double"
			End Select
			Local callCode:String
			If Not callExpected Then callCode = "BMX3302"
			Verify("local call " + capability + " " + typeName + " " + callNames[callIndex], "SuperStrict~nFunction M" + prefix + "Take<T>:T(value:T) Where T Is " + capability + "~nReturn value~nEnd Function~n" + callBody, callExpected, callCode, Null, options)
			Verify("imported call " + capability + " " + typeName + " " + callNames[callIndex], "SuperStrict~nImport ConstraintMatrix.Owner~n" + callBody, callExpected, callCode, resolver, options)
		Next
	Next
Next

Local warningOptions:TCompilerOptions = TCompilerOptions.CreateDefault()
warningOptions.requireCoreInterface = False
warningOptions.targetPlatform = "test"
warningOptions.targetArchitecture = "x64"
warningOptions.conditionalSymbols = ["bmxng", "ptr64"]
warningOptions.warnArgumentCasts = True
Local warnedCall:String = "Local amount:Double = 2.5~nLocal result:Float = MFTake<Float>(amount)"
VerifyWarning("local warning-mode narrowing", "SuperStrict~nFunction MFTake<T>:T(value:T) Where T Is Floating~nReturn value~nEnd Function~n" + warnedCall, "BMX3412", Null, warningOptions)
VerifyWarning("imported warning-mode narrowing", "SuperStrict~nImport ConstraintMatrix.Owner~n" + warnedCall, "BMX3412", resolver, warningOptions)

Print "numeric generic constraint matrix passed: " + matrixChecked + " cases (" + matrixKnownFailures + " known deferred-call failures)"
