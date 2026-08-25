SuperStrict

Framework BRL.StandardIO

Import BRL.Map

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

Type TDataSnapshotResolver Extends TSnapshotResolver
	Field includes:TMap = New TMap

	Method AddInclude(path:String, source:String)
		includes.Insert(path.ToLower(), TSnapshotText.Create(path, source))
	End Method

	Method ResolveInclude:TSnapshotText(includingPath:String, includePath:String)
		Return TSnapshotText(includes.ValueForKey(includePath.ToLower()))
	End Method

	Method ResolveInterface:TSnapshotText(importingPath:String, target:String, isFileImport:Int, isFramework:Int)
		Return Null
	End Method

	Method ResolveCoreInterface:TSnapshotText(targetPlatform:String)
		Return Null
	End Method
End Type

Local source:String = "SuperStrict~nRestoreData PEOPLE~n#first~nDefData 1, 2~nDefData 1 + 2~n#People~nDefData ~qSimon~q, 37~nFunction Nested()~n#inside~nDefData 99~nEnd Function~nRestoreData inside"
Local parsed:TParseResult = TBlitzMaxParser.ParseText(source, "data-section.bmx")
Local model:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(parsed.syntaxTree)
TExpressionBinder.Bind(model)
TDataFlowAnalyzer.Analyze(model)
Check(model.diagnostics.length = 0, "valid data-flow diagnostics")
Check(model.dataSection <> Null And model.dataSection.definitions.length = 4, "ordered data definitions")
Check(model.dataSection.items.length = 6, "flattened application data items")
Check(model.dataSection.definitions[0].labelName = "first" And model.dataSection.definitions[0].startIndex = 0, "first label offset")
Check(model.dataSection.definitions[1].startIndex = 2, "unlabelled definition offset")
Check(model.dataSection.definitions[2].labelName = "People" And model.dataSection.definitions[2].startIndex = 3, "case-preserving data label")
Check(model.dataSection.definitions[3].labelName = "inside" And model.dataSection.definitions[3].startIndex = 5, "routine-nested DefData remains application-wide")
Check(model.dataSection.items[0].semanticType = model.BuiltinType("Int"), "data item retains semantic type")

Local firstRestore:TRestoreDataStatementSyntax = TRestoreDataStatementSyntax(parsed.syntaxTree.root.members[1])
Local lastRestore:TRestoreDataStatementSyntax = TRestoreDataStatementSyntax(parsed.syntaxTree.root.members[6])
Check(model.ResolvedDataRestore(firstRestore).itemIndex = 3, "forward RestoreData resolves case-insensitively")
Check(model.ResolvedDataRestore(lastRestore).itemIndex = 5, "RestoreData resolves nested definition label")
Check(model.DataDefinition(model.dataSection.definitions[2].syntax) = model.dataSection.definitions[2], "definition syntax query")
Check(TDataSectionDumper.Dump(model.dataSection).Contains("#People"), "data section can be dumped")

Local invalidSource:String = "SuperStrict~nFunction Make:Int()~nReturn 1~nEnd Function~n#same~nDefData 1~n#SAME~nDefData 2~nRestoreData missing~nRestoreData 1 + 2~nDefData Make()"
Local invalidParse:TParseResult = TBlitzMaxParser.ParseText(invalidSource, "invalid-data-section.bmx")
Local invalidModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidParse.syntaxTree)
TExpressionBinder.Bind(invalidModel)
TDataFlowAnalyzer.Analyze(invalidModel)
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3500"), "duplicate data label diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3501"), "invalid RestoreData label diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3502"), "missing data label diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3503"), "nonconstant DefData item diagnostic")

Local readSource:String = "SuperStrict~nStruct SReadTarget~nField value:Int~nEnd Struct~nLocal byteValue:Byte~nLocal uintValue:UInt~nLocal floatValue:Float~nLocal doubleValue:Double~nLocal longValue:Long~nLocal ulongValue:ULong~nLocal sizeValue:Size_T~nLocal longIntValue:LongInt~nLocal ulongIntValue:ULongInt~nLocal textValue:String~nLocal arrayValue:Int[] = New Int[2]~nLocal record:SReadTarget~nReadData byteValue, uintValue, floatValue, doubleValue, longValue, ulongValue, sizeValue, longIntValue, ulongIntValue, textValue, arrayValue[0], record.value"
Local readParse:TParseResult = TBlitzMaxParser.ParseText(readSource, "read-data.bmx")
Local readModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(readParse.syntaxTree)
TExpressionBinder.Bind(readModel)
TDataFlowAnalyzer.Analyze(readModel)
Check(readModel.diagnostics.length = 0, "valid ReadData diagnostics")
Check(readModel.dataSection.reads.length = 1, "data section retains ReadData operation")
Local readSyntax:TReadDataStatementSyntax = TReadDataStatementSyntax(readParse.syntaxTree.root.members[14])
Local readOperation:TDataReadOperation = readModel.DataReadOperation(readSyntax)
Check(readOperation <> Null And readOperation.cursorAdvance = 12 And readOperation.targets.length = 12, "ReadData cursor advance matches target count")
Check(readOperation.mayRaiseOutOfData, "ReadData records runtime exhaustion behavior")
Check(readOperation.targets[0].conversionKind = DATA_READ_CONVERSION_INT, "Byte target uses integer data conversion")
Check(readOperation.targets[1].conversionKind = DATA_READ_CONVERSION_UINT, "UInt target conversion")
Check(readOperation.targets[2].conversionKind = DATA_READ_CONVERSION_FLOAT And readOperation.targets[3].conversionKind = DATA_READ_CONVERSION_DOUBLE, "floating point target conversions")
Check(readOperation.targets[6].conversionKind = DATA_READ_CONVERSION_SIZET, "Size_T target conversion")
Check(readOperation.targets[7].conversionKind = DATA_READ_CONVERSION_LONGINT And readOperation.targets[8].conversionKind = DATA_READ_CONVERSION_ULONGINT, "platform integer target conversions")
Check(readOperation.targets[9].conversionKind = DATA_READ_CONVERSION_STRING, "String target conversion")
Check(readOperation.targets[10].cursorOffset = 10 And readOperation.targets[11].cursorOffset = 11, "indexed and member targets consume ordered cursor slots")
Check(TDataSectionDumper.Dump(readModel.dataSection).Contains("out-of-data-check"), "data dump exposes runtime bounds check")

Local invalidReadSource:String = "SuperStrict~nType TUnsupportedRead~nEnd Type~nConst fixedValue:Int = 1~nLocal objectValue:TUnsupportedRead = New TUnsupportedRead~nReadData 1 + 2, fixedValue, objectValue~nReadData , objectValue"
Local invalidReadParse:TParseResult = TBlitzMaxParser.ParseText(invalidReadSource, "invalid-read-data.bmx")
Local invalidReadModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidReadParse.syntaxTree)
TExpressionBinder.Bind(invalidReadModel)
TDataFlowAnalyzer.Analyze(invalidReadModel)
Check(HasDiagnostic(invalidReadModel.diagnostics, "BMX3510"), "non-writable or missing ReadData target diagnostic")
Check(HasDiagnostic(invalidReadModel.diagnostics, "BMX3511"), "unsupported ReadData target type diagnostic")

Local resolver:TDataSnapshotResolver = New TDataSnapshotResolver
resolver.AddInclude("before.bmx", "#before~nDefData 10")
resolver.AddInclude("after.bmx", "#after~nDefData 30")
Local options:TCompilationSnapshotOptions = New TCompilationSnapshotOptions
options.requireCoreInterface = False
options.targetPlatform = "win32"
options.conditionalSymbols = ["win32"]
Local rootSource:String = "SuperStrict~nInclude ~qbefore.bmx~q~n#root~nDefData 20~nInclude ~qafter.bmx~q~n?win32~n#platform~nDefData 40~n?not win32~n#platform~nDefData 50~n?~nRestoreData platform"
Local snapshot:TCompilationSnapshot = TCompilationSnapshotBuilder.Build("root.bmx", rootSource, resolver, options)
Check(snapshot.succeeded, "data snapshot succeeds")
Local snapshotModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.AnalyzeSnapshot(snapshot)
TExpressionBinder.Bind(snapshotModel)
TDataFlowAnalyzer.Analyze(snapshotModel)
Check(snapshotModel.diagnostics.length = 0, "snapshot data-flow diagnostics")
Check(snapshotModel.dataSection.definitions.length = 4 And snapshotModel.dataSection.items.length = 4, "only active conditional data branch is selected")
Check(snapshotModel.dataSection.definitions[0].labelName = "before" And snapshotModel.dataSection.definitions[0].startIndex = 0, "included data occupies textual include position")
Check(snapshotModel.dataSection.definitions[1].labelName = "root" And snapshotModel.dataSection.definitions[1].startIndex = 1, "root data follows first include")
Check(snapshotModel.dataSection.definitions[2].labelName = "after" And snapshotModel.dataSection.definitions[2].startIndex = 2, "second include retains textual order")
Check(snapshotModel.dataSection.definitions[3].labelName = "platform" And snapshotModel.dataSection.definitions[3].startIndex = 3, "active platform label offset")
Check(snapshotModel.dataSection.items[0].semanticType = snapshotModel.BuiltinType("Int") And snapshotModel.dataSection.items[2].semanticType = snapshotModel.BuiltinType("Int"), "included data expressions are semantically bound")
Local snapshotRestore:TRestoreDataStatementSyntax = TRestoreDataStatementSyntax(snapshot.rootDocument.tree.root.members[5])
Check(snapshotModel.ResolvedDataRestore(snapshotRestore).itemIndex = 3, "snapshot RestoreData resolves active platform label")

Print "bcc2 data-flow analysis tests passed"
