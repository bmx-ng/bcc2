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

Function FindRecord:TInterfaceRecord(records:TInterfaceRecord[], name:String)
	For Local record:TInterfaceRecord = EachIn records
		If record.name.ToLower() = name.ToLower() Then Return record
	Next
	Return Null
End Function

Local source:String = "SuperStrict~nType TTagged { serializable version=2 label=~qthing~q }~nField Value:Int = 1 { reflect category=~qstate~q }~nEnd Type~nFunction Callback:Int(value:Int) { nomangle role=~qcallback~q }~nReturn value~nEnd Function~nGlobal Counter:Int = 1 { reflect category=~qglobal~q }"
Local analysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(source, "metadata.bmx")
Check(analysis.Succeeded(), "normalized declaration metadata analysis succeeds")

Local tagged:TSymbol = analysis.model.globalScope.LookupLocal("TTagged")[0]
Check(tagged.metadata <> Null And tagged.metadata.Has("SERIALIZABLE"), "metadata keys are case-insensitive")
Check(tagged.metadata.Value("version") = "2" And tagged.metadata.Value("label") = "thing", "literal metadata values are normalized")
Local fieldSymbol:TSymbol = tagged.memberScope.LookupLocal("Value")[0]
Check(fieldSymbol.metadata.Has("reflect") And fieldSymbol.metadata.Value("category") = "state", "field metadata is attached to its symbol")
Local callback:TSymbol = analysis.model.globalScope.LookupLocal("Callback")[0]
Check(callback.metadata.Has("nomangle") And callback.metadata.Value("role") = "callback" And Not callback.isExternal, "valued routine metadata is attached without being mistaken for an external binding")
Local counter:TSymbol = analysis.model.globalScope.LookupLocal("Counter")[0]
Check(counter.metadata.Has("reflect") And counter.metadata.Value("category") = "global", "global metadata is attached to its symbol")

Local sourceInterface:TInterfaceFile = TBlitzMaxSourceInterfaceBuilder.Build("metadata.bmx", source)
Local typeRecord:TInterfaceRecord = FindRecord(sourceInterface.declarations, "TTagged")
Check(typeRecord <> Null And typeRecord.metadata.Has("serializable") And typeRecord.metadata.Value("version") = "2", "source interfaces preserve type metadata")
Check(FindRecord(typeRecord.members, "Value").metadata.Value("category") = "state", "source interfaces preserve field metadata")
Check(FindRecord(sourceInterface.declarations, "Callback").metadata.Has("nomangle"), "source interfaces preserve routine metadata")
Check(FindRecord(sourceInterface.declarations, "Counter").metadata.Value("category") = "global", "source interfaces preserve global metadata")

Local externalBinding:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nExtern~nFunction Native:Int(value:Int) { role=~qnative~q } = ~qnative_symbol~q~nEnd Extern", "external-metadata.bmx")
Local nativeSymbol:TSymbol = externalBinding.model.globalScope.LookupLocal("Native")[0]
Check(externalBinding.Succeeded() And nativeSymbol.isExternal And nativeSymbol.externalName = "native_symbol" And nativeSymbol.metadata.Value("role") = "native", "top-level linkage assignment remains distinct from valued declaration metadata")

Local duplicate:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction Duplicate() { nomangle NOMANGLE }~nEnd Function", "duplicate-metadata.bmx")
Check(Not duplicate.Succeeded() And HasDiagnostic(duplicate.model.diagnostics, "BMX3012"), "duplicate metadata keys are rejected case-insensitively")

Local nonLiteral:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nGlobal Value:Int { tag=Other }", "nonliteral-metadata.bmx")
Check(Not nonLiteral.Succeeded() And HasDiagnostic(nonLiteral.model.diagnostics, "BMX3011"), "metadata values must be literal constants")

Local methodNoMangle:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TBad~nMethod Run() { nomangle }~nEnd Method~nEnd Type", "method-nomangle.bmx")
Check(Not methodNoMangle.Succeeded() And HasDiagnostic(methodNoMangle.model.diagnostics, "BMX3014"), "methods cannot specify NoMangle")

Local overloadNoMangle:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction Clash()~nEnd Function~nFunction Clash(value:Int) { nomangle }~nEnd Function", "overload-nomangle.bmx")
Check(Not overloadNoMangle.Succeeded() And HasDiagnostic(overloadNoMangle.model.diagnostics, "BMX3015"), "NoMangle rejects a conflicting zero-argument overload")

Local reverseOverload:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction Clash(value:Int) { nomangle }~nEnd Function~nFunction Clash()~nEnd Function", "reverse-overload-nomangle.bmx")
Check(Not reverseOverload.Succeeded() And HasDiagnostic(reverseOverload.model.diagnostics, "BMX3015"), "NoMangle overload validation is declaration-order independent")

Print "BlitzMax.Language declaration metadata tests passed"
