SuperStrict

Framework BRL.StandardIO

Import BlitzMax.Language

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Function HasDiagnostic:Int(diagnostics:TDiagnostic[], code:String)
	For Local diagnostic:TDiagnostic = EachIn diagnostics
		If diagnostic.code = code Then Return True
	Next
	Return False
End Function

Function ValueSymbol:TSymbol(model:TSemanticModel, name:String)
	Local symbols:TSymbol[] = model.globalScope.LookupLocal(name)
	For Local symbol:TSymbol = EachIn symbols
		If symbol.NamespaceKind() = SYMBOL_NAMESPACE_VALUE Then Return symbol
	Next
	Return Null
End Function

Local source:String = "SuperStrict~nConst Base:Int = 2~nConst Forward:Int = Later + 1~nConst Later:Int = 4~nConst Hex:Int = $ff~nConst SignBit:Int = $80000000~nConst ShiftSignBit:Int = 1 Shl 31~nConst OverflowedInt:Int = 2147483647 + 1~nConst AllBits:Int = $ffffffff~nConst MaxByte:Byte = 255~nConst Mask:UInt = 255:UInt~nConst MidShort:Short = 40000~nConst MaxShort:Short = 65535~nConst MaxInt:Int = 2147483647~nConst MaxUInt:UInt = 4294967295~nConst MaxLong:Long = 9223372036854775807~nConst Greeting:String = ~qHi~q + ~q!~q~nConst CharacterA:Int = Asc(~qA~q)~nConst EmptyCharacter:Int = Asc(~q~q)~nConst NumericCharacter:Int = Asc(123)~nConst LetterB:String = Chr(66)~nConst Circle:Double = Pi~nEnum EOrdinal:Int~nZero~nTen = Base + 8~nEleven~nEnd Enum~nEnum EFlags:Byte Flags~nRead~nWrite~nBoth = Read | Write~nExecute~nEnd Enum~nDefData Forward, EOrdinal.Eleven, Greeting, Mask"
Local parsed:TParseResult = TBlitzMaxParser.ParseText(source, "constants.bmx")
Local model:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(parsed.syntaxTree)
TExpressionBinder.Bind(model)
TConstantEvaluator.Evaluate(model)
TDataFlowAnalyzer.Analyze(model)
Check(model.diagnostics.length = 0, "valid constant diagnostics")
Check(model.SymbolConstantValue(ValueSymbol(model, "Base")).integerValue = 2, "integer const value")
Check(model.SymbolConstantValue(ValueSymbol(model, "Forward")).integerValue = 5, "forward const reference")
Check(model.SymbolConstantValue(ValueSymbol(model, "Hex")).integerValue = 255, "radix literal value")
Check(model.SymbolConstantValue(ValueSymbol(model, "SignBit")).integerValue = -2147483648:Long, "Int radix sign bit uses its signed bit pattern")
Check(model.SymbolConstantValue(ValueSymbol(model, "ShiftSignBit")).integerValue = -2147483648:Long, "Int shifts retain their signed 32-bit result pattern")
Check(model.SymbolConstantValue(ValueSymbol(model, "OverflowedInt")).integerValue = -2147483648:Long, "Int constant arithmetic wraps in its bound 32-bit width")
Check(model.SymbolConstantValue(ValueSymbol(model, "AllBits")).integerValue = -1, "Int radix all-bits pattern is negative one")
Check(model.SymbolConstantValue(ValueSymbol(model, "MaxByte")).integerValue = 255, "Byte constant accepts the unsigned 8-bit maximum")
Check(model.SymbolConstantValue(ValueSymbol(model, "Mask")).integerValue = 255, "typed constant value")
Check(model.SymbolConstantValue(ValueSymbol(model, "MidShort")).integerValue = 40000, "Short constant accepts an unsigned value above the signed 16-bit range")
Check(model.SymbolConstantValue(ValueSymbol(model, "MaxShort")).integerValue = 65535, "Short constant accepts the unsigned 16-bit maximum")
Check(model.SymbolConstantValue(ValueSymbol(model, "MaxInt")).integerValue = 2147483647, "Int constant accepts the signed 32-bit maximum")
Check(model.SymbolConstantValue(ValueSymbol(model, "MaxUInt")).integerValue = 4294967295:Long, "UInt constant accepts the unsigned 32-bit maximum")
Check(model.SymbolConstantValue(ValueSymbol(model, "MaxLong")).integerValue = 9223372036854775807:Long, "Long constant accepts the signed 64-bit maximum")
Check(model.SymbolConstantValue(ValueSymbol(model, "Greeting")).stringValue = "Hi!", "string constant expression")
Check(model.SymbolConstantValue(ValueSymbol(model, "CharacterA")).integerValue = 65, "Asc constant string value")
Check(model.SymbolConstantValue(ValueSymbol(model, "EmptyCharacter")).integerValue = -1, "Asc empty string matches runtime value")
Check(model.SymbolConstantValue(ValueSymbol(model, "NumericCharacter")).integerValue = 49, "Asc constant operand uses its String conversion")
Check(model.SymbolConstantValue(ValueSymbol(model, "LetterB")).stringValue = "B", "Chr constant value")
Check(model.SymbolConstantValue(ValueSymbol(model, "Circle")).floatValue = Pi, "Pi constant value")

Local escapePrefix:String = Chr(126)
Local documentedEscapeLiteral:String = Chr(34) + escapePrefix + "0" + escapePrefix + "t" + escapePrefix + "r" + escapePrefix + "n" + escapePrefix + "q" + escapePrefix + escapePrefix + escapePrefix + "65" + escapePrefix + escapePrefix + "$41" + escapePrefix + escapePrefix + "%1000001" + escapePrefix + Chr(34)
Local documentedEscapeSource:String = "SuperStrict~nConst Escaped:String = " + documentedEscapeLiteral
Local documentedEscapeParse:TParseResult = TBlitzMaxParser.ParseText(documentedEscapeSource, "documented-escapes.bmx")
Local documentedEscapeModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(documentedEscapeParse.syntaxTree)
TExpressionBinder.Bind(documentedEscapeModel)
TConstantEvaluator.Evaluate(documentedEscapeModel)
Local documentedEscapeValue:String = documentedEscapeModel.SymbolConstantValue(ValueSymbol(documentedEscapeModel, "Escaped")).stringValue
Check(documentedEscapeModel.diagnostics.length = 0, "documented String escape constant diagnostics")
Check(documentedEscapeValue.length = 9, "documented String escapes each produce one character")
Check(documentedEscapeValue[0] = 0 And documentedEscapeValue[1] = 9 And documentedEscapeValue[2] = 13 And documentedEscapeValue[3] = 10, "named control-character String escapes decode")
Check(documentedEscapeValue[4] = 34 And documentedEscapeValue[5] = 126, "quote and tilde String escapes decode")
Check(documentedEscapeValue[6] = 65 And documentedEscapeValue[7] = 65 And documentedEscapeValue[8] = 65, "decimal, hexadecimal and binary String escapes decode")

Local ordinal:TSymbol = model.globalScope.LookupLocal("EOrdinal")[0]
Local flags:TSymbol = model.globalScope.LookupLocal("EFlags")[0]
Check(model.SymbolConstantValue(ordinal.memberScope.LookupLocal("Zero")[0]).integerValue = 0, "ordinary enum starts at zero")
Check(model.SymbolConstantValue(ordinal.memberScope.LookupLocal("Ten")[0]).integerValue = 10, "explicit enum expression")
Check(model.SymbolConstantValue(ordinal.memberScope.LookupLocal("Eleven")[0]).integerValue = 11, "ordinary enum progression")
Check(model.SymbolConstantValue(flags.memberScope.LookupLocal("Read")[0]).integerValue = 1, "Flags enum starts at one")
Check(model.SymbolConstantValue(flags.memberScope.LookupLocal("Write")[0]).integerValue = 2, "Flags enum power-of-two progression")
Check(model.SymbolConstantValue(flags.memberScope.LookupLocal("Both")[0]).integerValue = 3, "Flags enum composite expression")
Check(model.SymbolConstantValue(flags.memberScope.LookupLocal("Execute")[0]).integerValue = 4, "Flags enum resumes at next power of two")
Check(model.dataSection.items[0].semanticType = model.BuiltinType("Int"), "DefData retains constant semantic type")
Check(model.dataSection.items[1].constantValue.integerValue = 11, "qualified enum member is a data constant")
Check(TDataSectionDumper.Dump(model.dataSection).Contains("= 11"), "data dump includes evaluated values")

Local externalConstantsSource:String = "SuperStrict~nExtern~nConst MASK_COLOR:Int = 2~nConst MASK_ALPHA:Int = 4~nConst TYPE_RGBA:Int = MASK_COLOR | MASK_ALPHA~nConst TYPE_ALIAS:Int = TYPE_RGBA~nEnd Extern"
Local externalConstantsParse:TParseResult = TBlitzMaxParser.ParseText(externalConstantsSource, "external-constants.bmx")
Local externalConstantsModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(externalConstantsParse.syntaxTree)
TExpressionBinder.Bind(externalConstantsModel)
TConstantEvaluator.Evaluate(externalConstantsModel)
Check(externalConstantsModel.diagnostics.length = 0, "Extern Const expressions bind as compile-time values")
Check(externalConstantsModel.SymbolConstantValue(ValueSymbol(externalConstantsModel, "TYPE_RGBA")).integerValue = 6, "Extern Const bitwise expression value")
Check(externalConstantsModel.SymbolConstantValue(ValueSymbol(externalConstantsModel, "TYPE_ALIAS")).integerValue = 6, "Extern Const alias value")

Local tripleQuote:String = Chr(34) + Chr(34) + Chr(34)
Local multilineSource:String = "SuperStrict~nConst Text:String = " + tripleQuote + "~n~t~talpha  ~n~t~t~tbeta\~n~t~tgamma~n~t~t" + tripleQuote
Local multilineParse:TParseResult = TBlitzMaxParser.ParseText(multilineSource, "multiline-constant.bmx")
Local multilineModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(multilineParse.syntaxTree)
TExpressionBinder.Bind(multilineModel)
TConstantEvaluator.Evaluate(multilineModel)
Check(multilineModel.diagnostics.length = 0, "valid production-shaped multiline string diagnostics")
Check(multilineModel.SymbolConstantValue(ValueSymbol(multilineModel, "Text")).stringValue = "alpha~n~tbetagamma", "multiline strings strip the closing-delimiter margin, trim line ends and honor soft wrapping")

Local invalidSource:String = "SuperStrict~nConst A:Int = B~nConst B:Int = A~nConst TooBig:Byte = 256~nConst TooBigShort:Short = 65536~nFunction RuntimeValue:Int()~nReturn 1~nEnd Function~nConst Bad:Int = RuntimeValue()~nEnum ESmall:Byte~nLarge = 300~nEnd Enum~nConst Zero:Int = 1 / 0"
Local invalidParsed:TParseResult = TBlitzMaxParser.ParseText(invalidSource, "invalid-constants.bmx")
Local invalidModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidParsed.syntaxTree)
TExpressionBinder.Bind(invalidModel)
TConstantEvaluator.Evaluate(invalidModel)
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3600"), "constant cycle diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3601"), "nonconstant Const diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3603"), "constant range diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3604"), "constant division-by-zero diagnostic")

Print "bcc2 constant evaluation tests passed"
