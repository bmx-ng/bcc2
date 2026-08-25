SuperStrict

Framework BRL.StandardIO

Import BlitzMax.Language
Import BRL.FileSystem
Import BRL.TextStream

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Local apiPath:String = "/sdk/mod/demo.mod/api.mod/api.release.test.x64.i"
Local api:TInterfaceFile = TBlitzMaxParser.ParseInterfaceText("superstrict~nimport demo.base~nIService^Null{ '@source ~qapi.bmx~q,1,0~n-Run:Int(value:Int) '@source ~qapi.bmx~q,2,0~n}AI=~qdemo_api_IService~q~nTService^Object@IService{ '@source ~qapi.bmx~q,5,0~n-Run:Int(amount:Int) '@source ~qapi.bmx~q,6,0~n-secret:Int()P=~qdemo_api_TService_secret~q '@source ~qapi.bmx~q,7,0~n}F=~qdemo_api_TService~q", apiPath)
Local otherPath:String = "/sdk/mod/other.mod/api.mod/api.release.test.x64.i"
Local other:TInterfaceFile = TBlitzMaxParser.ParseInterfaceText("TService^Object{ '@source ~qother.bmx~q,3,0~n}F=~qother_api_TService~q", otherPath)
Local catalogue:TModuleSymbolCatalogue = New TModuleSymbolCatalogue
catalogue.AddModules(["demo.api", "other.api"], [apiPath, otherPath], [api, other])
Local apiEntry:TModuleCatalogueEntry = catalogue.FindModule("demo.api")

Check(catalogue.ModuleCount() = 2, "catalogue preserves module boundaries")
Check(catalogue.TypeCount() = 3, "catalogue indexes Types and Interfaces")
Check(catalogue.FindModule("DEMO.API") = apiEntry And apiEntry.imports.length = 1 And apiEntry.imports[0] = "demo.base", "catalogue module lookup and imports are case insensitive")
Check(catalogue.TypesNamed("TService").length = 2, "simple-name index preserves symbols from different modules")
Local service:TModuleCatalogueSymbol = catalogue.SymbolsQualified("demo.api.TService")[0]
Check(service.moduleEntry = apiEntry And service.kind = SYMBOL_TYPE, "qualified lookup identifies the owning module and symbol kind")
Check(service.originPath = "/sdk/mod/demo.mod/api.mod/api.bmx" And service.originLine = 5, "catalogue resolves compiler-interface source provenance")
Local run:TModuleCatalogueSymbol = catalogue.SymbolsQualified("demo.api.TService.Run")[0]
Check(run.parent = service And run.kind = SYMBOL_ROUTINE, "catalogue recursively indexes members")
Local serviceInterface:TModuleCatalogueSymbol = catalogue.SymbolsQualified("demo.api.IService")[0]
Local interfaceRun:TModuleCatalogueSymbol = catalogue.SymbolsQualified("demo.api.IService.Run")[0]
Check(catalogue.Inherits(service, serviceInterface), "catalogue resolves interface implementation relationships")
Check(catalogue.RoutineSignatureShape(run) = catalogue.RoutineSignatureShape(interfaceRun), "catalogue routine shapes ignore parameter names")
Local secret:TModuleCatalogueSymbol = catalogue.SymbolsQualified("demo.api.TService.secret")[0]
Check(Not secret.isPublic, "catalogue retains private declarations without making a visibility decision for consumers")

Local bulkCount:Int = 40
Local bulkNames:String[] = New String[bulkCount]
Local bulkPaths:String[] = New String[bulkCount]
Local bulkInterfaces:TInterfaceFile[] = New TInterfaceFile[bulkCount]
For Local index:Int = 0 Until bulkCount
	bulkNames[index] = "bulk.module" + index
	bulkPaths[index] = "/sdk/mod/bulk.mod/module" + index + ".mod/module" + index + ".release.test.x64.i"
	bulkInterfaces[index] = TBlitzMaxParser.ParseInterfaceText("TItem^Object{~n}F=~qbulk_module" + index + "_TItem~q", bulkPaths[index])
Next
Local bulkCatalogue:TModuleSymbolCatalogue = New TModuleSymbolCatalogue
bulkCatalogue.AddModules(bulkNames, bulkPaths, bulkInterfaces)
Check(bulkCatalogue.ModuleCount() = bulkCount And bulkCatalogue.SymbolCount() = bulkCount And bulkCatalogue.TypeCount() = bulkCount, "bulk catalogue growth publishes exact module and symbol arrays")
Check(bulkCatalogue.TypesNamed("TItem").length = bulkCount And bulkCatalogue.FindModule("BULK.MODULE39") <> Null, "bulk catalogue growth retains complete case-insensitive indexes")
Check(catalogue.SymbolCount() = 6, "catalogue symbol count includes top-level and member declarations")

Local provenanceDirectory:String = "/tmp/bcc2-interface-provenance-chain"
DeleteDir(provenanceDirectory, True)
CreateDir(provenanceDirectory + "/.bmx", True)
SaveText("SuperStrict~nType TDriver~nEnd Type", provenanceDirectory + "/driver.bmx")
Local intermediatePath:String = provenanceDirectory + "/.bmx/driver.bmx.release.test.x64.i"
SaveText("superstrict~nimport brl.blitz~nTDriver^Object{ '@source ~qdriver.bmx~q,4,0~n}=~qdemo_TDriver~q", intermediatePath)
Local aggregatePath:String = provenanceDirectory + "/demo.release.test.x64.i"
Local aggregateFile:TInterfaceFile = TBlitzMaxParser.ParseInterfaceText("TDriver^Object{ '@source ~q.bmx/driver.bmx.release.test.x64.i~q,3,0~n}=~qdemo_TDriver~q", aggregatePath)
Local provenanceCatalogue:TModuleSymbolCatalogue = New TModuleSymbolCatalogue
provenanceCatalogue.AddModule("demo.chain", aggregatePath, aggregateFile)
Local chainedDriver:TModuleCatalogueSymbol = provenanceCatalogue.SymbolsQualified("demo.chain.TDriver")[0]
Check(chainedDriver.originPath = RealPath(provenanceDirectory + "/driver.bmx").Replace("\", "/") And chainedDriver.originLine = 4, "catalogue follows generated interface provenance to the original source")

Local missingFile:TInterfaceFile = TBlitzMaxParser.ParseInterfaceText("TMissing^Object{ '@source ~q.bmx/missing.release.test.x64.i~q,3,0~n}=~qdemo_TMissing~q", aggregatePath)
provenanceCatalogue.AddModule("demo.missing", aggregatePath + ".missing", missingFile)
Check(provenanceCatalogue.SymbolsQualified("demo.missing.TMissing")[0].originPath.ToLower().EndsWith(".i"), "missing provenance hops retain a generated location instead of guessing source")

Local cycleA:String = provenanceDirectory + "/cycle-a.i"
Local cycleB:String = provenanceDirectory + "/cycle-b.i"
SaveText("TCycle^Object{ '@source ~qcycle-b.i~q,1,0", cycleA)
SaveText("TCycle^Object{ '@source ~qcycle-a.i~q,1,0", cycleB)
Local cycleRecord:TInterfaceRecord = New TInterfaceRecord
cycleRecord.kind = INTERFACE_RECORD_TYPE
cycleRecord.name = "TCycle"
cycleRecord.originPath = "cycle-a.i"
cycleRecord.originLine = 1
Local cycleResolver:TInterfaceSourceResolver = New TInterfaceSourceResolver
Local cycleLocation:TInterfaceSourceLocation = cycleResolver.Resolve(provenanceDirectory + "/cycle-root.i", cycleRecord)
Check(cycleLocation <> Null And TInterfaceSourceResolver.IsInterfacePath(cycleLocation.path), "cyclic provenance chains terminate at a generated location")
Local cachedSource:TSourceText = cycleResolver.LoadInterfaceSource(cycleA)
Check(cachedSource <> Null And cachedSource = cycleResolver.LoadInterfaceSource(cycleA), "interface provenance source text and line maps are cached per resolver")
Check(TInterfaceSourceResolver.LineAtSource(cachedSource, 1).Find("TCycle") = 0, "cached interface provenance sources preserve line lookup")
DeleteDir(provenanceDirectory, True)

Local genericFile:TInterfaceFile = New TInterfaceFile
genericFile.path = "/sdk/mod/demo.mod/generic.mod/generic.release.test.x64.i"
Local genericRecord:TInterfaceRecord = New TInterfaceRecord
genericRecord.kind = INTERFACE_RECORD_TYPE
genericRecord.name = "TBox"
genericRecord.flags = "G"
genericRecord.genericSourcePath = "/sdk/mod/demo.mod/generic.mod/generic.bmx"
genericRecord.genericSource = "SuperStrict~nType TBox<T>~nMethod Value:T()~nEnd Method~nEnd Type"
genericFile.AddDeclaration(genericRecord)
catalogue.AddModule("demo.generic", genericFile.path, genericFile)
Local genericSymbol:TModuleCatalogueSymbol = catalogue.SymbolsQualified("demo.generic.TBox")[0]
Check(Not genericSymbol.membersIndexed And genericSymbol.members.length = 0, "generic template members remain lazy during initial indexing")
Local genericMembers:TModuleCatalogueSymbol[] = catalogue.EnsureMembers(genericSymbol)
Check(genericSymbol.membersIndexed And genericMembers.length = 1 And genericMembers[0].name = "Value", "generic template members expand on demand")

Print "bcc2 symbol-catalogue tests passed"
