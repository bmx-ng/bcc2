SuperStrict

Framework BRL.StandardIO

Import BlitzMax.Language

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Local source:String = "superstrict~nModuleInfo ~qVersion: 1.0~q~nimport brl.blitz~nimport ~qcommon.bmx~q~n#pragma ~qcalling convention~q~nANSWER%=42% '@source ~qanswer.bmx~q,6,0~nCreate:TThing(value%,name$=$~q~q)=~qexample_Create~q~nSwap<T>(a:T Var,b:T Var) Where T Extends Object~ncounter%&=mem:p(~qexample_counter~q)~nEState\%{~nReady=0~nBusy=1~n}F=~qexample_EState~q~nTThing^Object@IRunnable{ '@source ~qthing.bmx~q,20,0~nVERSION$=$~q1~q~n.count%&~n.callback(arg:TThing)~n@name$&`~n+Create:TThing(value%)=~qexample_TThing_Create~q~n-Run%(arg:TThing)AF=~qexample_TThing_Run~q '@source ~qthing.bmx~q,27,1~n~~buffer@&[16]&~n.protectedValue%&``~n-InternalOnly%()I=~qexample_TThing_InternalOnly~q~n}AF=~qexample_TThing~q"
Local file:TInterfaceFile = TInterfaceFileParser.Parse(source, "example.i")
Check(file.diagnostics.length = 0, "interface parser diagnostics")
Check(file.isSuperStrict, "interface SuperStrict")
Check(file.metadata.length = 1 And file.metadata[0] = "Version: 1.0", "module info")
Check(file.pragmas.length = 1, "interface pragma")
Check(file.imports.length = 2, "interface imports")
Check(file.imports[0].name = "brl.blitz" And Not file.imports[0].isFileImport, "module import")
Check(file.imports[1].name = "common.bmx" And file.imports[1].isFileImport, "file import")
Check(file.declarations.length = 6, "top-level interface declarations")
Check(file.declarations[0].kind = INTERFACE_RECORD_CONST And file.declarations[0].name = "ANSWER", "interface const")
Check(file.declarations[0].valueText = "42%" And file.declarations[0].valueSyntax <> Null, "interface const value")
Check(file.declarations[0].originPath = "answer.bmx" And file.declarations[0].originLine = 6, "interface const source provenance")
Check(file.declarations[1].kind = INTERFACE_RECORD_FUNCTION And file.declarations[1].externalName = "example_Create", "interface function")
Check(file.declarations[1].routineSignature.returnType.nameTokens[0].text = "TThing", "decoded interface function return")
Check(file.declarations[1].routineSignature.parameters.length = 2, "decoded interface function parameters")
Check(file.declarations[1].routineSignature.parameters[0].declaredType.markerToken.text = "%", "decoded compact parameter type")
Check(TLiteralExpressionSyntax(file.declarations[1].routineSignature.parameters[1].defaultValue) <> Null, "decoded compact parameter default")
Check(file.declarations[2].kind = INTERFACE_RECORD_FUNCTION And file.declarations[2].routineSignature.genericParameters.length = 1, "decoded generic interface function")
Check(file.declarations[2].routineSignature.constraints.length = 1 And file.declarations[2].routineSignature.parameters[0].varToken <> Null, "decoded generic interface function constraint and Var parameter")
Check(file.declarations[3].kind = INTERFACE_RECORD_GLOBAL And file.declarations[3].name = "counter", "interface global")
Check(file.declarations[3].declaredTypeSyntax.markerToken.text = "%", "decoded interface global type")

Local callableGlobalFile:TInterfaceFile = TInterfaceFileParser.Parse("Compare%(left:Object,right:Object)&=mem:p(~qexample_Compare~q)", "callable-global.i")
Check(callableGlobalFile.diagnostics.length = 0 And callableGlobalFile.declarations.length = 1, "callable Global interface parser diagnostics")
Local callableGlobalRecord:TInterfaceRecord = callableGlobalFile.declarations[0]
Check(callableGlobalRecord.kind = INTERFACE_RECORD_GLOBAL And callableGlobalRecord.name = "Compare" And callableGlobalRecord.externalName = "example_Compare", "callable Global is storage rather than a routine record")
Check(callableGlobalRecord.callableTypeSyntax <> Null And callableGlobalRecord.callableTypeSyntax.returnType.markerToken.text = "%" And callableGlobalRecord.callableTypeSyntax.parameters.length = 2, "decoded callable Global signature")
Local closureGlobalFile:TInterfaceFile = TInterfaceFileParser.Parse("callback:Closure<Int(value:Int)>&=mem:p(~qexample_callback~q)~nnotify:Closure<()>&=mem:p(~qexample_notify~q)~nfactory:Closure<Closure<Int()>()>&=mem:p(~qexample_factory~q)", "closure-global.i")
Check(closureGlobalFile.diagnostics.length = 0 And closureGlobalFile.declarations.length = 3, "managed Closure Global interface parser diagnostics")
Check(Not closureGlobalFile.declarations[0].callableTypeSyntax And closureGlobalFile.declarations[0].declaredTypeSyntax And closureGlobalFile.declarations[0].declaredTypeSyntax.closureSignature And closureGlobalFile.declarations[0].declaredTypeSyntax.closureSignature.parameters.length = 1, "Closure Global parentheses remain nested inside the declared managed type")
Check(Not closureGlobalFile.declarations[1].callableTypeSyntax And closureGlobalFile.declarations[1].declaredTypeSyntax And closureGlobalFile.declarations[1].declaredTypeSyntax.closureSignature And Not closureGlobalFile.declarations[1].declaredTypeSyntax.closureSignature.returnType, "Closure<()> Global retains its implicit no-return signature")
Check(closureGlobalFile.declarations[2].declaredTypeSyntax.closureSignature.returnType.closureSignature <> Null, "compact Closure storage recursively decodes a Closure-valued return type")
Local closureFieldFile:TInterfaceFile = TInterfaceFileParser.Parse("TClosureHolder^Object{~n.callback:Closure<Int(value:Int)>&~n}=~qexample_TClosureHolder~q", "closure-field.i")
Check(closureFieldFile.diagnostics.length = 0 And closureFieldFile.declarations[0].members.length = 1 And Not closureFieldFile.declarations[0].members[0].callableTypeSyntax And closureFieldFile.declarations[0].members[0].declaredTypeSyntax.closureSignature, "managed Closure field parentheses remain nested inside the declared managed type")
Local rankedCallableGlobalFile:TInterfaceFile = TInterfaceFileParser.Parse("MatrixCallbacks%(values$&[,])&[,]&=mem:p(~qexample_MatrixCallbacks~q)", "ranked-callable-global.i")
Check(rankedCallableGlobalFile.diagnostics.length = 0 And rankedCallableGlobalFile.declarations.length = 1, "ranked callable Global interface parser diagnostics")
Local rankedCallableGlobal:TCallableTypeSyntax = rankedCallableGlobalFile.declarations[0].callableTypeSyntax
Check(rankedCallableGlobal <> Null And rankedCallableGlobal.parameters.length = 1 And rankedCallableGlobal.parameters[0].staticArrayBound = Null, "ranked callable Global does not reinterpret a nested dynamic array as StaticArray")
Check(rankedCallableGlobal.parameters[0].declaredType.suffixes.length = 1 And rankedCallableGlobal.parameters[0].declaredType.suffixes[0].rank = 2, "ranked callable Global retains its nested array rank")
Check(rankedCallableGlobal.suffixes.length = 1 And rankedCallableGlobal.suffixes[0].rank = 2, "ranked callable Global retains its outer array rank")
Local stdcallGlobalFile:TInterfaceFile = TInterfaceFileParser.Parse("Compare%(left:Object,right:Object)W&=mem:p(~qexample_Compare~q)", "stdcall-global.i")
Check(stdcallGlobalFile.diagnostics.length = 0 And stdcallGlobalFile.declarations[0].callableTypeSyntax.callingConventionToken.text = "W", "compact callable Global retains its stdcall ABI marker")
Local callableStaticStorageFile:TInterfaceFile = TInterfaceFileParser.Parse("Active%(cells:SCell&[2])&=mem:p(~qexample_Active~q)~nTCallbackHolder^Object{~n.callback%(cells:SCell&[2])&~n}=~qexample_TCallbackHolder~q", "callable-static-storage.i")
Check(callableStaticStorageFile.diagnostics.length = 0 And callableStaticStorageFile.declarations.length = 2, "callable StaticArray storage interface parser diagnostics")
Check(callableStaticStorageFile.declarations[0].callableTypeSyntax.parameters[0].staticArrayBound <> Null, "callable Global retains its nested StaticArray bound")
Check(callableStaticStorageFile.declarations[1].members[0].callableTypeSyntax.parameters[0].staticArrayBound <> Null, "callable field retains its nested StaticArray bound")
Local callableVarStorageFile:TInterfaceFile = TInterfaceFileParser.Parse("Active%(value% Var)&=mem:p(~qexample_ActiveVar~q)~nTVarHolder^Object{~n.callback%(value% Var)&~n}=~qexample_TVarHolder~q", "callable-var-storage.i")
Check(callableVarStorageFile.diagnostics.length = 0 And callableVarStorageFile.declarations.length = 2, "callable Var storage interface parser diagnostics")
Check(callableVarStorageFile.declarations[0].callableTypeSyntax.parameters[0].varToken <> Null, "callable Global retains its nested Var mode")
Check(callableVarStorageFile.declarations[1].members[0].callableTypeSyntax.parameters[0].varToken <> Null, "callable field retains its nested Var mode")
Local callableReturnFile:TInterfaceFile = TInterfaceFileParser.Parse("Choose%(value% Var)(enabled%)=~qexample_Choose__Bint~q", "callable-return.i")
Check(callableReturnFile.diagnostics.length = 0 And callableReturnFile.declarations.length = 1, "callable return interface parser diagnostics")
Check(callableReturnFile.declarations[0].routineSignature.callableReturnType.parameters[0].varToken <> Null, "interface routine retains its callable return signature")
Check(callableReturnFile.declarations[0].routineSignature.parameters.length = 1 And callableReturnFile.declarations[0].routineSignature.parameters[0].nameToken.text = "enabled", "interface routine separates callable return and invocation parameters")
Local stdcallReturnFile:TInterfaceFile = TInterfaceFileParser.Parse("Choose%(value% Var)W(enabled%)W=~qexample_Choose__Bint~q", "stdcall-return.i")
Check(stdcallReturnFile.diagnostics.length = 0 And stdcallReturnFile.declarations.length = 1, "stdcall callable-return interface parser diagnostics")
Check(stdcallReturnFile.declarations[0].routineSignature.callableReturnType.callingConventionToken.text = "W" And stdcallReturnFile.declarations[0].flags.Contains("W"), "compact routine separates returned-callable stdcall from the routine's own stdcall ABI")
Local unboundRoutineFlagsFile:TInterfaceFile = TInterfaceFileParser.Parse("IDefault<T>^Object{~n-Describe:T(value:T)D~n}AIK~nKeep<T>:T(value:T) Where T Extends Object", "unbound-routine-flags.i")
Check(unboundRoutineFlagsFile.diagnostics.length = 0 And unboundRoutineFlagsFile.declarations.length = 2, "generic compact routines without external assignments parse")
Check(unboundRoutineFlagsFile.declarations[0].members[0].flags = "D", "generic Interface Default methods retain their suffix flag without an external assignment")
Check(unboundRoutineFlagsFile.declarations[1].flags.length = 0 And unboundRoutineFlagsFile.declarations[1].routineSignature.constraints.length = 1, "a generic routine constraint is not mistaken for routine flags")

Local externalInterfaceText:String = "IUnknown_^Null{~n-QueryInterface%(riid@*,value??IUnknown_ Var)WA=~qQueryInterface~q~n-AddRef%()WA=~qAddRef~q~n}EI=0"
Local externalInterfaceFile:TInterfaceFile = TInterfaceFileParser.Parse(externalInterfaceText, "native-interface.i")
Check(externalInterfaceFile.diagnostics.length = 0 And externalInterfaceFile.declarations.length = 1, "native external Interface compact record parses")
Local externalInterfaceRecord:TInterfaceRecord = externalInterfaceFile.declarations[0]
Check(externalInterfaceRecord.flags.Contains("E") And externalInterfaceRecord.flags.Contains("I"), "native external Interface retains its distinct type flags")
Check(externalInterfaceRecord.members[0].routineSignature.parameters[1].declaredType.nameTokens[0].text = "IUnknown_", "native external Interface references decode from compact signatures")
Check(externalInterfaceRecord.members[0].flags.Contains("W"), "native external Interface stdcall slots decode from compact signatures")

Local externalSourceOptions:TCompilationSnapshotOptions = New TCompilationSnapshotOptions
externalSourceOptions.targetPlatform = "win32"
Local externalSourceFile:TInterfaceFile = TBlitzMaxSourceInterfaceBuilder.Build("src/native-interface.bmx", "SuperStrict~nExtern ~qWin32~q~nInterface IUnknown_~nMethod AddRef:Int()~nEnd Interface~nEnd Extern", Null, externalSourceOptions)
Check(externalSourceFile.declarations.length = 1 And externalSourceFile.declarations[0].flags = "EI", "source interface builder identifies native external Interfaces")
Check(externalSourceFile.declarations[0].members[0].flags.Contains("W"), "source interface builder retains the target-specific external Interface method convention")

Local ulongConstantFile:TInterfaceFile = TInterfaceFileParser.Parse("CHARSFORMAT_SCIENTIFIC||=1||", "blitz.i")
Check(ulongConstantFile.diagnostics.length = 0 And ulongConstantFile.declarations.length = 1, "ULong interface constant parser diagnostics")
Local ulongConstantRecord:TInterfaceRecord = ulongConstantFile.declarations[0]
Check(ulongConstantRecord.kind = INTERFACE_RECORD_CONST And ulongConstantRecord.declaredTypeSyntax.markerToken.text = "||", "ULong compact interface type marker")
Local ulongConstantLiteral:TLiteralExpressionSyntax = TLiteralExpressionSyntax(ulongConstantRecord.valueSyntax)
Check(ulongConstantLiteral <> Null And ulongConstantLiteral.literalToken.text = "1", "ULong compact value suffix is removed before expression decoding")

Local sentinelDefaultsFile:TInterfaceFile = TInterfaceFileParser.Parse("Use(value:Object=~qbbNullObject~q,items:Int[]=~qbbEmptyArray~q)=~qexample_Use~q", "sentinel-defaults.i")
Check(sentinelDefaultsFile.diagnostics.length = 0 And sentinelDefaultsFile.declarations.length = 1, "managed sentinel default interface parser diagnostics")
Local sentinelRoutine:TRoutineSignatureSyntax = sentinelDefaultsFile.declarations[0].routineSignature
Check(sentinelRoutine <> Null And sentinelRoutine.parameters.length = 2, "managed sentinel default routine signature")
Local objectDefault:TLiteralExpressionSyntax = TLiteralExpressionSyntax(sentinelRoutine.parameters[0].defaultValue)
Local arrayDefault:TLiteralExpressionSyntax = TLiteralExpressionSyntax(sentinelRoutine.parameters[1].defaultValue)
Check(objectDefault <> Null And objectDefault.literalToken.text.ToLower() = "null", "bbNullObject interface default becomes semantic Null syntax")
Check(arrayDefault <> Null And arrayDefault.literalToken.text.ToLower() = "null", "bbEmptyArray interface default becomes semantic Null syntax")

Local staticParameterFile:TInterfaceFile = TInterfaceFileParser.Parse("Fill%(values%&[4],cells:SCell&[2])=~qexample_Fill~q~nTStaticOwner^Object{~n-Size%(values%&[4])=~qexample_TStaticOwner_Size~q~n}=~qexample_TStaticOwner~q", "static-parameters.i")
Check(staticParameterFile.diagnostics.length = 0 And staticParameterFile.declarations.length = 2, "StaticArray parameter interface parser diagnostics")
Local staticParameterRoutine:TRoutineSignatureSyntax = staticParameterFile.declarations[0].routineSignature
Check(staticParameterRoutine.parameters[0].declaredType.markerToken.text = "%" And staticParameterRoutine.parameters[0].staticArrayBound <> Null, "compact numeric StaticArray parameter retains its element type and bound")
Check(staticParameterRoutine.parameters[1].declaredType.nameTokens[0].text = "SCell" And staticParameterRoutine.parameters[1].staticArrayBound <> Null, "compact named StaticArray parameter retains its element type and bound")
Local staticParameterMethod:TRoutineSignatureSyntax = staticParameterFile.declarations[1].members[0].routineSignature
Check(staticParameterMethod.parameters[0].staticArrayBound <> Null, "compact method StaticArray parameter retains its bound")
Local callableStaticParameterFile:TInterfaceFile = TInterfaceFileParser.Parse("ApplyFixed%(callback%(values%&[4]),values%&[4])=~qexample_ApplyFixed~q", "callable-static-parameter.i")
Check(callableStaticParameterFile.diagnostics.length = 0 And callableStaticParameterFile.declarations.length = 1, "nested callable StaticArray parameter interface parser diagnostics")
Local callableStaticParameterRoutine:TRoutineSignatureSyntax = callableStaticParameterFile.declarations[0].routineSignature
Check(callableStaticParameterRoutine.parameters[0].callableType <> Null And callableStaticParameterRoutine.parameters[0].callableType.parameters[0].staticArrayBound <> Null, "compact callable signature retains its nested StaticArray bound")
Check(callableStaticParameterRoutine.parameters[1].staticArrayBound <> Null, "top-level StaticArray decoding remains intact beside a nested callable signature")

Local enumRecord:TInterfaceRecord = file.declarations[4]
Check(enumRecord.kind = INTERFACE_RECORD_ENUM And enumRecord.name = "EState", "interface enum")
Check(enumRecord.baseTypeText = "%" And enumRecord.members.length = 2, "enum underlying type and values")
Check(enumRecord.baseTypeSyntax.markerToken.text = "%", "decoded enum underlying type")
Check(enumRecord.members[0].valueText = "0" And enumRecord.members[0].valueSyntax <> Null, "interface enum value")
Check(enumRecord.flags = "F" And enumRecord.externalName = "example_EState", "enum trailer")

Local typeRecord:TInterfaceRecord = file.declarations[5]
Check(typeRecord.kind = INTERFACE_RECORD_TYPE And typeRecord.name = "TThing", "interface type")
Check(typeRecord.originPath = "thing.bmx" And typeRecord.originLine = 20, "interface type source provenance")
Check(typeRecord.baseTypeText = "Object", "interface base type")
Check(typeRecord.baseTypeSyntax.nameTokens[0].text = "Object", "decoded interface base type")
Check(typeRecord.implementedTypeTexts.length = 1 And typeRecord.implementedTypeTexts[0] = "IRunnable", "interface implemented type")
Check(typeRecord.implementedTypeSyntax[0].nameTokens[0].text = "IRunnable", "decoded implemented type")
Check(typeRecord.flags = "AF" And typeRecord.externalName = "example_TThing", "type trailer")
Check(typeRecord.members.length = 9, "interface type members")
Check(typeRecord.members[1].kind = INTERFACE_RECORD_FIELD And typeRecord.members[1].name = "count", "interface field")
Check(typeRecord.members[1].declaredTypeSyntax.markerToken.text = "%", "decoded interface field type")
Check(typeRecord.members[2].callableTypeSyntax <> Null And typeRecord.members[2].callableTypeSyntax.parameters[0].declaredType.nameTokens[0].text = "TThing", "decoded callable interface field")
Check(typeRecord.members[3].kind = INTERFACE_RECORD_FIELD And typeRecord.members[3].flags.Contains("R"), "decoded ReadOnly interface field")
Check(typeRecord.members[3].visibility = VISIBILITY_PRIVATE, "decoded private field visibility")
Check(typeRecord.members[4].kind = INTERFACE_RECORD_TYPE_FUNCTION, "interface type function")
Check(typeRecord.members[5].kind = INTERFACE_RECORD_METHOD And typeRecord.members[5].flags = "AF", "interface method flags")
Check(typeRecord.members[5].originPath = "thing.bmx" And typeRecord.members[5].originLine = 27 And typeRecord.members[5].originColumn = 1, "interface member source provenance")
Check(typeRecord.members[5].routineSignature.returnType.markerToken.text = "%", "decoded interface method return")
Check(typeRecord.members[5].routineSignature.parameters[0].declaredType.nameTokens[0].text = "TThing", "decoded interface method parameter")
Check(typeRecord.members[6].isStaticArray And typeRecord.members[6].declaredTypeSyntax.markerToken.text = "@", "decoded interface StaticArray field")
Check(typeRecord.members[6].staticArrayBound <> Null, "decoded interface StaticArray bound")
Check(typeRecord.members[7].visibility = VISIBILITY_PROTECTED, "decoded protected field visibility")
Check(typeRecord.members[8].visibility = VISIBILITY_INTERNAL, "decoded internal method visibility")

Local combinedVisibilityFile:TInterfaceFile = TInterfaceFileParser.Parse("TCombined^Object{~n.family%&````~n.shared%&`````~n-FamilyOnly%()PI=~qfamily~q~n-Shared%()RI=~qshared~q~n}=~qexample_TCombined~q", "combined-visibility.i")
Check(combinedVisibilityFile.diagnostics.length = 0, "combined visibility interface diagnostics")
Local combinedVisibilityRecord:TInterfaceRecord = combinedVisibilityFile.declarations[0]
Check(combinedVisibilityRecord.members[0].visibility = VISIBILITY_PRIVATE_INTERNAL, "decoded Private Internal field visibility")
Check(combinedVisibilityRecord.members[1].visibility = VISIBILITY_PROTECTED_INTERNAL, "decoded Protected Internal field visibility")
Check(combinedVisibilityRecord.members[2].visibility = VISIBILITY_PRIVATE_INTERNAL, "decoded Private Internal routine flags")
Check(combinedVisibilityRecord.members[3].visibility = VISIBILITY_PROTECTED_INTERNAL, "decoded Protected Internal routine flags")

Local dump:String = TInterfaceDumper.Dump(file)
Check(dump.Contains("Type TThing Extends Object Implements IRunnable"), "interface dump type")
Check(dump.Contains("Enum EState : %"), "interface dump enum")

Local unterminated:TInterfaceFile = TInterfaceFileParser.Parse("TBroken^Object{~n.value%", "broken.i")
Check(unterminated.diagnostics.length = 1 And unterminated.diagnostics[0].code = "BMXI100", "unterminated interface record diagnostic")

Local liveSource:String = "SuperStrict~nImport brl.blitz~nConst PublicValue:Int = 1~nPrivate~nConst HiddenValue:Int = 2~nPublic~nType TLive~nField ReadOnly Value:String~nPrivate~nField HiddenField:Int~nInternal~nMethod ModuleOnly:Int()~nReturn HiddenField~nEnd Method~nPublic~nMethod Read:String()~nReturn Value~nEnd Method~nEnd Type"
Local liveFile:TInterfaceFile = TBlitzMaxSourceInterfaceBuilder.Build("src/live.bmx", liveSource)
Check(liveFile.imports.length = 1 And liveFile.imports[0].name = "brl.blitz", "source interface retains imports")
Check(liveFile.declarations.length = 3, "source interface retains declarations with visibility")
Check(liveFile.declarations[0].kind = INTERFACE_RECORD_CONST And liveFile.declarations[0].name = "PublicValue", "source interface constant")
Check(liveFile.declarations[0].originPath = "src/live.bmx", "source interface records declaration provenance")
Check(liveFile.declarations[0].originLine = 3 And liveFile.declarations[0].originColumn = 6, "source interface records declaration coordinates")
Check(liveFile.declarations[1].name = "HiddenValue" And liveFile.declarations[1].visibility = VISIBILITY_PRIVATE, "source interface retains private declaration visibility")
Local liveType:TInterfaceRecord = liveFile.declarations[2]
Check(liveType.kind = INTERFACE_RECORD_TYPE And liveType.name = "TLive", "source interface type")
Check(liveType.originLine = 7 And liveType.originColumn = 5, "source-built type provenance is ready for interface serialization")
Check(liveType.members.length = 4 And liveType.members[0].name = "Value" And liveType.members[3].name = "Read", "source interface retains type members")
Check(liveType.members[0].flags.Contains("R"), "source interface retains ReadOnly field metadata")
Check(liveType.members[1].visibility = VISIBILITY_PRIVATE And liveType.members[2].visibility = VISIBILITY_INTERNAL, "source interface retains member visibility")
Check(liveType.members[3].routineSignature.returnType.nameTokens[0].text = "String", "source interface retains routine signature syntax")

Local liveCombinedFile:TInterfaceFile = TBlitzMaxSourceInterfaceBuilder.Build("src/combined.bmx", "SuperStrict~nType TCombined~nPrivate Internal~nField family:Int~nProtected Internal~nField shared:Int~nEnd Type")
Local liveCombinedType:TInterfaceRecord = liveCombinedFile.declarations[0]
Check(liveCombinedType.members[0].visibility = VISIBILITY_PRIVATE_INTERNAL And liveCombinedType.members[1].visibility = VISIBILITY_PROTECTED_INTERNAL, "source interface retains combined visibility")

Local documentedInterface:TInterfaceFile = TInterfaceFileParser.Parse("'@docs ~qapi.docs.bmx~q~nTThing^Object{~n-Read$(value%)=~qread_int~q~n-Read$(value$)=~qread_string~q~n}=~qexample_TThing~q", "api.i")
Check(documentedInterface.documentationSource = "api.docs.bmx", "interface documentation companion directive")
Local documentationSource:String = "SuperStrict~nRem~nbbdoc: A documented thing.~nEnd Rem~nType TThing~nRem~nbbdoc: Reads an integer value.~nEnd Rem~nMethod Read:String(value:Int)~nEnd Method~nRem~nbbdoc: Reads a string value.~nEnd Rem~nMethod Read:String(value:String)~nEnd Method~nEnd Type"
Local documentationMatches:Int = TInterfaceDocumentationMerger.Apply(documentedInterface, "src/api.docs.bmx", documentationSource)
Check(documentationMatches = 3, "companion documentation matches types and overloaded members by signature: " + documentationMatches)
Local documentedType:TInterfaceRecord = documentedInterface.declarations[0]
Check(documentedType.documentation <> Null And documentedType.documentation.summary = "A documented thing.", "companion type documentation")
Check(documentedType.members[0].documentation <> Null And documentedType.members[0].documentation.summary = "Reads an integer value.", "companion overload documentation uses parameter signature")
Check(documentedType.members[1].documentation <> Null And documentedType.members[1].documentation.summary = "Reads a string value.", "companion overload documentation remains distinct")
Check(documentedType.members[0].documentationPath = "src/api.docs.bmx" And documentedType.members[0].documentationLine > 0, "companion documentation provenance is retained separately")
TInterfaceDocumentationMerger.Apply(documentedInterface, "src/api.docs.bmx", "SuperStrict~nRem~nbbdoc: Updated thing documentation.~nEnd Rem~nType TThing~nEnd Type")
Check(documentedType.documentation.summary = "Updated thing documentation." And documentedType.members[0].documentation = Null, "refreshing a companion clears documentation removed from its source")

Local genericRoutineInterface:TInterfaceFile = TInterfaceFileParser.Parse("superstrict~nIdentity<T>:T(value:T)~n'@generic-template 4,~qcollections.generic::identity#routine/1~q,~q0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef~q,~q.generics/templates/identity.bmxgt~q,~qbmx-language-1~q", "generic-routine.i")
Check(genericRoutineInterface.diagnostics.length = 0 And genericRoutineInterface.declarations.length = 1 And genericRoutineInterface.declarations[0].kind = INTERFACE_RECORD_FUNCTION And genericRoutineInterface.declarations[0].genericTemplateFormat = 4, "generic template references attach to compact Function records")

Local genericTypeFunctionInterface:TInterfaceFile = TInterfaceFileParser.Parse("superstrict~nTFunctions^Object{~n+Identity<T>:T(value:T)~n'@generic-template 4,~qcollections.generic::tfunctions.identity#routine/1~q,~q0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef~q,~q.generics/templates/type-identity.bmxgt~q,~qbmx-language-1~q~n}", "generic-type-function.i")
Check(genericTypeFunctionInterface.diagnostics.length = 0 And genericTypeFunctionInterface.declarations.length = 1 And genericTypeFunctionInterface.declarations[0].members.length = 1 And genericTypeFunctionInterface.declarations[0].members[0].kind = INTERFACE_RECORD_TYPE_FUNCTION And genericTypeFunctionInterface.declarations[0].members[0].genericTemplateFormat = 4, "generic template references attach to compact Type Function records")

Local aggregateInterface:TInterfaceFile = TInterfaceFileParser.Parse("superstrict~n'@source-aggregate 1~nimport ~qcommon.bmx~q~nSharedValue%()=~qacme_shared_value~q", "aggregate.i")
Check(aggregateInterface.hasSourceAggregate And aggregateInterface.declarations.length = 1 And aggregateInterface.declarations[0].name = "SharedValue", "source aggregate marker is interface metadata rather than a declaration")

Print "bcc2 interface-model tests passed"
