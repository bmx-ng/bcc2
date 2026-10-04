SuperStrict

Framework BRL.StandardIO
Import BlitzMax.Language

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Function SelectedParameterType:String(source:String, sourceName:String)
	Local analysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(source, sourceName)
	Check(analysis.Succeeded(), sourceName + " resolves without diagnostics")
	Local declaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(analysis.syntaxTree.root.members[analysis.syntaxTree.root.members.length - 1])
	Local call:TCallExpressionSyntax = TCallExpressionSyntax(declaration.declarators[0].initializer)
	Local resolved:TResolvedCall = analysis.model.ResolvedCall(call)
	Check(resolved <> Null, sourceName + " records its selected overload")
	Return resolved.parameterTypes[0].DisplayName()
End Function

Function BinaryResultType:String(leftType:String, rightType:String)
	Local source:String = "SuperStrict~nLocal left:" + leftType + "~nLocal right:" + rightType + "~nLocal result := left + right"
	Local analysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(source, "binary-" + leftType + "-" + rightType + ".bmx")
	Check(analysis.Succeeded(), leftType + " + " + rightType + " binds without diagnostics")
	Local declaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(analysis.syntaxTree.root.members[analysis.syntaxTree.root.members.length - 1])
	Return analysis.model.ExpressionType(declaration.declarators[0].initializer).DisplayName()
End Function

' Integral conversions preserve every source value on both 32- and 64-bit
' targets, apart from the established Size_T -> Long native-count exception.
' Integer -> floating follows BlitzMax's rank policy and can round large
' values. C long may be 32-bit on Win64; the x64 Float64/Int128/Float128/
' Double128 types are SIMD values, not scalar widths.
Local names:String[] = ["byte", "short", "int", "uint", "long", "ulong", "longint", "ulongint", "size_t", "wparam", "lparam", "float", "double", "float64", "int128", "float128", "double128"]
Local rows:String[] = [ ..
	"byte:short|int|uint|long|ulong|longint|ulongint|size_t|wparam|lparam|float|double", ..
	"short:int|uint|long|ulong|longint|ulongint|size_t|wparam|lparam|float|double", ..
	"int:long|longint|lparam|float|double", ..
	"uint:long|ulong|ulongint|size_t|wparam|float|double", ..
	"long:float|double", ..
	"ulong:float|double", ..
	"longint:long|lparam|float|double", ..
	"ulongint:ulong|size_t|wparam|float|double", ..
	"size_t:long|wparam|ulong|float|double", ..
	"wparam:size_t|ulong|float|double", ..
	"lparam:long|float|double", ..
	"float:double", ..
	"double:none", ..
	"float64:none", ..
	"int128:none", ..
	"float128:none", ..
	"double128:none" ..
]

Check(names.length = rows.length, "numeric conversion matrix has one row per built-in type")
For Local index:Int = 0 Until rows.length
	Local parts:String[] = rows[index].Split(":")
	Check(parts.length = 2 And parts[0] = names[index], "numeric conversion row matches its source type")
	For Local target:String = EachIn names
		Local expected:Int = ("|" + parts[1] + "|").Contains("|" + target + "|")
		Local actual:Int = TConversionClassifier.CanWidenNumeric(parts[0], target)
		Check(actual = expected, parts[0] + " -> " + target + " has the expected implicit-widening classification")
	Next
Next

Local mpackCall:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction WriteU64(value:ULong)~nEnd Function~nLocal count:Size_T~nWriteU64(count)", "size-t-to-ulong-call.bmx")
Check(mpackCall.Succeeded(), "Size_T passes to a ULong argument without a narrowing warning")
Local lossyCall:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction WriteSigned(value:Int)~nEnd Function~nLocal count:UInt~nWriteSigned(count)", "uint-to-int-call.bmx")
Check(Not lossyCall.Succeeded(), "UInt does not silently narrow to Int at an argument boundary")

' Overload selection follows the natural promotion lane for the source type.
' In particular, unsigned Byte/Short/UInt values stay unsigned when equally
' wide signed and unsigned candidates are available, and 64-bit integers
' prefer Double over the lower-precision Float destination.
Check(SelectedParameterType("SuperStrict~nFunction Pick:Int(value:Short) Return 1 End Function~nFunction Pick:Int(value:Int) Return 2 End Function~nFunction Pick:Int(value:UInt) Return 3 End Function~nLocal value:Byte~nLocal result:Int=Pick(value)", "byte-nearest-overload.bmx") = "Short", "Byte selects the nearest Short widening overload")
Check(SelectedParameterType("SuperStrict~nFunction Pick:Int(value:Int) Return 1 End Function~nFunction Pick:Int(value:UInt) Return 2 End Function~nLocal value:Byte~nLocal result:Int=Pick(value)", "byte-signedness-overload.bmx") = "UInt", "Byte prefers UInt over equally wide signed Int")
Check(SelectedParameterType("SuperStrict~nFunction Pick:Int(value:Int) Return 1 End Function~nFunction Pick:Int(value:UInt) Return 2 End Function~nLocal value:Short~nLocal result:Int=Pick(value)", "short-signedness-overload.bmx") = "UInt", "Short prefers UInt over equally wide signed Int")
Check(SelectedParameterType("SuperStrict~nFunction Pick:Int(value:Long) Return 1 End Function~nFunction Pick:Int(value:Float) Return 2 End Function~nLocal value:Int~nLocal result:Int=Pick(value)", "int-nearest-overload.bmx") = "Long", "Int selects the nearest Long widening overload")
Check(SelectedParameterType("SuperStrict~nFunction Pick:Int(value:Long) Return 1 End Function~nFunction Pick:Int(value:ULong) Return 2 End Function~nLocal value:UInt~nLocal result:Int=Pick(value)", "uint-signedness-overload.bmx") = "ULong", "UInt prefers ULong over equally wide signed Long")
Check(SelectedParameterType("SuperStrict~nFunction Pick:Int(value:Float) Return 1 End Function~nFunction Pick:Int(value:Double) Return 2 End Function~nLocal value:Long~nLocal result:Int=Pick(value)", "long-real-overload.bmx") = "Double", "Long prefers Double over Float")
Check(SelectedParameterType("SuperStrict~nFunction Pick:Int(value:Float) Return 1 End Function~nFunction Pick:Int(value:Double) Return 2 End Function~nLocal value:ULong~nLocal result:Int=Pick(value)", "ulong-real-overload.bmx") = "Double", "ULong prefers Double over Float")
Check(SelectedParameterType("SuperStrict~nFunction Pick:Int(expected:Float, actual:Float, delta:Float=0) Return 1 End Function~nFunction Pick:Int(expected:Double, actual:Double, delta:Double=0) Return 2 End Function~nLocal index:Int=3~nLocal actual:ULong=9~nLocal result:Int=Pick(index*index, actual)", "mixed-int-ulong-real-overload.bmx") = "Double", "mixed Int and ULong arguments select the production-compatible Double overload")
Check(SelectedParameterType("SuperStrict~nFunction Pick:Int(value:Long) Return 1 End Function~nFunction Pick:Int(value:Double) Return 2 End Function~nLocal value:LongInt~nLocal result:Int=Pick(value)", "longint-widening-overload.bmx") = "Long", "LongInt prefers its integral Long destination")
Check(SelectedParameterType("SuperStrict~nFunction Pick:Int(value:ULong) Return 1 End Function~nFunction Pick:Int(value:Double) Return 2 End Function~nLocal value:ULongInt~nLocal result:Int=Pick(value)", "ulongint-widening-overload.bmx") = "ULong", "ULongInt prefers its integral ULong destination")
Check(SelectedParameterType("SuperStrict~nFunction Pick:Int(value:Long) Return 1 End Function~nFunction Pick:Int(value:ULong) Return 2 End Function~nLocal value:Size_T~nLocal result:Int=Pick(value)", "size-t-widening-overload.bmx") = "ULong", "Size_T prefers the unsigned ULong destination")
Check(SelectedParameterType("SuperStrict~nFunction Pick:Int(value:Long) Return 1 End Function~nFunction Pick:Int(value:Double) Return 2 End Function~nLocal value:LParam~nLocal result:Int=Pick(value)", "lparam-widening-overload.bmx") = "Long", "LParam prefers its integral Long destination")
Check(SelectedParameterType("SuperStrict~nFunction Pick:Int(value:Size_T) Return 1 End Function~nFunction Pick:Int(value:ULong) Return 2 End Function~nLocal value:WParam~nLocal result:Int=Pick(value)", "wparam-widening-overload.bmx") = "Size_T", "WParam prefers its pointer-sized unsigned destination")
Check(SelectedParameterType("SuperStrict~nFunction Pick:Int(value:Double) Return 1 End Function~nLocal value:Float~nLocal result:Int=Pick(value)", "float-widening-overload.bmx") = "Double", "Float widens to Double")

' Exercise aggregate overload scores, not just isolated conversions. Every
' ordered pair of integral sources is checked because a regression in one
' argument can otherwise be hidden by a preference in the other. Fixed
' Long/ULong values force the Double family; the remaining integer sources use
' the less costly Float family.
Local realSources:String[] = ["Byte", "Short", "Int", "UInt", "Long", "ULong", "LongInt", "ULongInt", "Size_T", "WParam", "LParam"]
For Local left:String = EachIn realSources
	For Local right:String = EachIn realSources
		Local expected:String = "Float"
		If left = "Long" Or left = "ULong" Or right = "Long" Or right = "ULong" Then expected = "Double"
		Local pairSource:String = "SuperStrict~nFunction Pick:Int(first:Float, second:Float) Return 1 End Function~nFunction Pick:Int(first:Double, second:Double) Return 2 End Function~nLocal first:" + left + "~nLocal second:" + right + "~nLocal result:Int=Pick(first, second)"
		Check(SelectedParameterType(pairSource, "real-overload-" + left + "-" + right + ".bmx") = expected, left + " and " + right + " select the expected " + expected + " overload")
	Next
Next

Local wideningArgumentsSource:String = "SuperStrict~nFunction NeedShort(value:Short)~nEnd Function~nFunction NeedUInt(value:UInt)~nEnd Function~nFunction NeedLong(value:Long)~nEnd Function~nFunction NeedULong(value:ULong)~nEnd Function~nFunction NeedDouble(value:Double)~nEnd Function~nLocal byteValue:Byte~nLocal shortValue:Short~nLocal intValue:Int~nLocal uintValue:UInt~nLocal longValue:Long~nLocal ulongValue:ULong~nLocal floatValue:Float~nNeedShort(byteValue)~nNeedUInt(shortValue)~nNeedLong(intValue)~nNeedULong(uintValue)~nNeedDouble(longValue)~nNeedDouble(ulongValue)~nNeedDouble(floatValue)"
Check(TBlitzMaxLanguage.AnalyzeText(wideningArgumentsSource, "numeric-widening-arguments.bmx").Succeeded(), "every primary numeric type crosses its widening argument boundary without a cast")

Local narrowingArgumentsSource:String = "SuperStrict~nFunction NeedByte(value:Byte)~nEnd Function~nFunction NeedShort(value:Short)~nEnd Function~nFunction NeedInt(value:Int)~nEnd Function~nFunction NeedUInt(value:UInt)~nEnd Function~nFunction NeedLong(value:Long)~nEnd Function~nFunction NeedFloat(value:Float)~nEnd Function~nLocal shortValue:Short~nLocal intValue:Int~nLocal uintValue:UInt~nLocal longValue:Long~nLocal ulongValue:ULong~nLocal doubleValue:Double~nNeedByte(shortValue)~nNeedShort(intValue)~nNeedInt(uintValue)~nNeedUInt(longValue)~nNeedLong(ulongValue)~nNeedFloat(doubleValue)"
Local strictNarrowing:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(narrowingArgumentsSource, "numeric-narrowing-arguments.bmx")
Check(strictNarrowing.model.diagnostics.length = 6, "every primary numeric narrowing argument boundary requires a cast")
Local warningOptions:TLanguageAnalysisOptions = TLanguageAnalysisOptions.Create()
warningOptions.warnArgumentCasts = True
Local warnedNarrowing:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(narrowingArgumentsSource, "warned-numeric-narrowing-arguments.bmx", warningOptions)
Check(warnedNarrowing.Succeeded() And warnedNarrowing.model.diagnostics.length = 6, "warning mode consistently admits and diagnoses every primary numeric narrowing argument")

Local explicitNarrowingSource:String = narrowingArgumentsSource.Replace("NeedByte(shortValue)", "NeedByte(Byte(shortValue))").Replace("NeedShort(intValue)", "NeedShort(Short(intValue))").Replace("NeedInt(uintValue)", "NeedInt(Int(uintValue))").Replace("NeedUInt(longValue)", "NeedUInt(UInt(longValue))").Replace("NeedLong(ulongValue)", "NeedLong(Long(ulongValue))").Replace("NeedFloat(doubleValue)", "NeedFloat(Float(doubleValue))")
Check(TBlitzMaxLanguage.AnalyzeText(explicitNarrowingSource, "explicit-numeric-narrowing-arguments.bmx").Succeeded(), "explicit casts satisfy every primary numeric narrowing argument boundary")

Check(BinaryResultType("Byte", "Short") = "Short" And BinaryResultType("Short", "Byte") = "Short", "Byte and Short arithmetic promotes to Short independently of operand order")
Check(BinaryResultType("Short", "Int") = "Int" And BinaryResultType("Int", "Short") = "Int", "Short and Int arithmetic promotes to Int independently of operand order")
Check(BinaryResultType("Short", "UInt") = "UInt" And BinaryResultType("UInt", "Short") = "UInt", "Short and UInt arithmetic promotes to UInt independently of operand order")
Check(BinaryResultType("Int", "UInt") = "UInt" And BinaryResultType("UInt", "Int") = "UInt", "Int and UInt arithmetic has a stable UInt result")
Check(BinaryResultType("Long", "UInt") = "ULong" And BinaryResultType("UInt", "Long") = "ULong", "Long and UInt arithmetic promotes to ULong without signed truncation")
Check(BinaryResultType("Long", "ULong") = "ULong" And BinaryResultType("ULong", "Long") = "ULong", "Long and ULong arithmetic has a stable ULong result")
Check(BinaryResultType("Long", "Float") = "Float" And BinaryResultType("Float", "Long") = "Float", "Long and Float arithmetic has a stable Float result")
Check(BinaryResultType("ULong", "Double") = "Double" And BinaryResultType("Double", "ULong") = "Double", "ULong and Double arithmetic has a stable Double result")

Local balancedBinary:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nLocal signedValue:Long~nLocal unsignedValue:UInt~nLocal result := signedValue + unsignedValue", "balanced-binary-operands.bmx")
Local balancedDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(balancedBinary.syntaxTree.root.members[balancedBinary.syntaxTree.root.members.length - 1])
Local balancedExpression:TBoundBinaryExpression = TBoundBinaryExpression(balancedBinary.model.BoundExpression(balancedDeclaration.declarators[0].initializer))
Check(balancedExpression <> Null And TBoundConversionExpression(balancedExpression.left).semanticType.DisplayName() = "ULong" And TBoundConversionExpression(balancedExpression.right).semanticType.DisplayName() = "ULong", "mixed numeric binary operands retain explicit conversions to their balanced result type")

Print "numeric conversion matrix tests passed"
