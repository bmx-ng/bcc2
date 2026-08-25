SuperStrict

Framework BRL.StandardIO

Import BlitzMax.Language

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Function EncodeHistorical:String(artifact:TGenericTemplateArtifact, version:Int, diagnostics:String[] Var)
	Local originalVersion:Int = artifact.formatVersion
	artifact.formatVersion = version
	Local payload:String = TGenericTemplateArtifactCodec.CanonicalPayload(artifact, diagnostics)
	artifact.formatVersion = originalVersion
	If diagnostics.length Then Return ""
	Return "BMXGT " + version + "~nrevision " + TGenericTemplateArtifactCodec.Digest(payload) + "~n" + payload
End Function

Local identity:TGenericTemplateIdentity = New TGenericTemplateIdentity
identity.moduleName = "Collections.Queue"
identity.qualifiedName = "TQueue"
identity.arity = 1
identity.contentRevision = "body-revision-1"
Check(identity.StableName() = "collections.queue::tqueue#type/1", "stable generic template identity")

Local parameterType:TTemplateTypeReference = New TTemplateTypeReference
parameterType.kind = TEMPLATE_TYPE_PARAMETER
parameterType.parameterIndex = 0
Check(parameterType.CanonicalName() = "!type:0", "canonical template parameter type")

Local stringType:TTemplateTypeReference = New TTemplateTypeReference
stringType.kind = TEMPLATE_TYPE_BUILTIN
stringType.symbolName = "String"
Local intType:TTemplateTypeReference = New TTemplateTypeReference
intType.kind = TEMPLATE_TYPE_BUILTIN
intType.symbolName = "Int"

Local arrayType:TTemplateTypeReference = New TTemplateTypeReference
arrayType.kind = TEMPLATE_TYPE_ARRAY
arrayType.elementType = stringType
arrayType.rank = 1
Check(arrayType.CanonicalName() = "string[1]", "canonical constructed template type")
Local staticArrayOfParameter:TTemplateTypeReference = New TTemplateTypeReference
staticArrayOfParameter.kind = TEMPLATE_TYPE_STATIC_ARRAY
staticArrayOfParameter.elementType = parameterType
staticArrayOfParameter.staticArrayLength = 4
Check(staticArrayOfParameter.CanonicalName() = "staticarray !type:0[4]", "canonical StaticArray template type retains distinct element and extent identity")
Local substitutedStaticArray:TTemplateTypeReference = TTemplateTypeSubstitution.Apply(staticArrayOfParameter, [stringType])
Check(substitutedStaticArray.CanonicalName() = "staticarray string[4]", "StaticArray template substitution retains its fixed extent")

Local parameter:TGenericTemplateParameter = New TGenericTemplateParameter
parameter.name = "T"
parameter.ordinal = 0

Local body:TGenericTemplateNode = New TGenericTemplateNode
body.kind = TEMPLATE_NODE_BLOCK
Local resultNode:TGenericTemplateNode = New TGenericTemplateNode
resultNode.kind = TEMPLATE_NODE_RETURN
resultNode.semanticType = parameterType
body.AddChild(resultNode)

Local artifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
artifact.identity = identity
artifact.parameters = [parameter]
artifact.body = body
Check(artifact.InstanceKey([arrayType]) = "collections.queue::tqueue#type/1@body-revision-1<string[1]>", "canonical generic instance key")

Local catalog:TGenericTemplateCatalog = New TGenericTemplateCatalog
Check(catalog.Add(artifact), "add generic template artifact")
Check(Not catalog.Add(artifact), "reject duplicate generic template revision")
Check(catalog.Find(identity) = artifact, "find generic template artifact")

Local linkedListOfT:TTemplateTypeReference = New TTemplateTypeReference
linkedListOfT.kind = TEMPLATE_TYPE_NAMED
linkedListOfT.moduleName = "Collections.LinkedList"
linkedListOfT.symbolName = "TLinkedList"
linkedListOfT.arguments = [parameterType]
Local batchesType:TTemplateTypeReference = New TTemplateTypeReference
batchesType.kind = TEMPLATE_TYPE_NAMED
batchesType.moduleName = "Collections.LinkedList"
batchesType.symbolName = "TLinkedList"
batchesType.arguments = [linkedListOfT]
Local substitutedBatches:TTemplateTypeReference = TTemplateTypeSubstitution.Apply(batchesType, [stringType])
Check(substitutedBatches.CanonicalName() = "collections.linkedlist::tlinkedlist<collections.linkedlist::tlinkedlist<string>>", "nested self-reference substitution")
Local ordinaryType:TTemplateTypeReference = New TTemplateTypeReference
ordinaryType.kind = TEMPLATE_TYPE_NAMED
ordinaryType.moduleName = "Example.Values"
ordinaryType.symbolName = "TValue"
ordinaryType.runtimeKind = TEMPLATE_RUNTIME_CLASS
ordinaryType.runtimeAbiName = "example_values_TValue"
Local substitutedOrdinaryType:TTemplateTypeReference = TTemplateTypeSubstitution.Apply(ordinaryType, [stringType])
Check(substitutedOrdinaryType.runtimeKind = TEMPLATE_RUNTIME_CLASS And substitutedOrdinaryType.runtimeAbiName = ordinaryType.runtimeAbiName, "ordinary runtime identity survives template substitution")

Local instanceCatalog:TGenericInstanceCatalog = New TGenericInstanceCatalog
Local declaredInstance:TGenericInstanceRecord = instanceCatalog.GetOrDeclare(artifact, [stringType])
Check(declaredInstance.state = GENERIC_INSTANCE_DECLARED, "generic instance placeholder state")
Check(instanceCatalog.GetOrDeclare(artifact, [stringType]) = declaredInstance, "recursive generic instance returns canonical placeholder")

Local persistedIdentity:TGenericTemplateIdentity = New TGenericTemplateIdentity
persistedIdentity.moduleName = "Collections.Queue"
persistedIdentity.qualifiedName = "TQueue"
persistedIdentity.arity = 1
Local persistedParameter:TGenericTemplateParameter = New TGenericTemplateParameter
persistedParameter.name = "T"
persistedParameter.ordinal = 0
persistedParameter.constraints = [stringType]
Local dependencyReference:TTemplateSymbolReference = New TTemplateSymbolReference
dependencyReference.moduleName = "BRL.Blitz"
dependencyReference.qualifiedName = "Object.ToString"
dependencyReference.namespaceKind = SYMBOL_ROUTINE
dependencyReference.overloadKey = "0"
Local sourceLocation:TTemplateSourceLocation = New TTemplateSourceLocation
sourceLocation.path = "collections/queue.bmx"
sourceLocation.start = 120
sourceLocation.length = 24
sourceLocation.line = 7
sourceLocation.column = 3
Local reflectedMetadata:TGenericTemplateMetadataEntry = New TGenericTemplateMetadataEntry
reflectedMetadata.key = "serializable"
reflectedMetadata.value = "queue"
reflectedMetadata.source = sourceLocation
Local valueParameter:TGenericTemplateValueParameter = New TGenericTemplateValueParameter
valueParameter.name = "value"
valueParameter.ordinal = 0
valueParameter.semanticType = parameterType
valueParameter.passingMode = PARAMETER_PASS_VALUE
valueParameter.source = sourceLocation
Local returnValue:TGenericTemplateNode = New TGenericTemplateNode
returnValue.kind = TEMPLATE_NODE_NAME
returnValue.semanticType = parameterType
returnValue.referencedSymbol = dependencyReference
returnValue.source = sourceLocation
returnValue.valueText = "value"
Local persistedReturn:TGenericTemplateNode = New TGenericTemplateNode
persistedReturn.kind = TEMPLATE_NODE_RETURN
persistedReturn.semanticType = parameterType
persistedReturn.source = sourceLocation
persistedReturn.children = [returnValue]
Local persistedBody:TGenericTemplateNode = New TGenericTemplateNode
persistedBody.kind = TEMPLATE_NODE_BLOCK
persistedBody.source = sourceLocation
Local persistedLoopControl:TGenericTemplateNode = New TGenericTemplateNode
persistedLoopControl.kind = TEMPLATE_NODE_LOOP_CONTROL
persistedLoopControl.identity = "loop0"
persistedLoopControl.valueText = "continue"
persistedLoopControl.source = sourceLocation
persistedBody.children = [persistedReturn, persistedLoopControl]
Local persistedMethod:TGenericTemplateMember = New TGenericTemplateMember
persistedMethod.kind = TEMPLATE_MEMBER_METHOD
persistedMethod.identity = "method:peek/1"
persistedMethod.name = "Peek"
persistedMethod.visibility = VISIBILITY_PUBLIC
persistedMethod.metadata = [reflectedMetadata]
persistedMethod.semanticType = parameterType
persistedMethod.parameters = [valueParameter]
persistedMethod.body = persistedBody
persistedMethod.source = sourceLocation
Local persistedStatic:TGenericTemplateMember = New TGenericTemplateMember
persistedStatic.kind = TEMPLATE_MEMBER_FIELD
persistedStatic.identity = "static:count"
persistedStatic.name = "Count"
persistedStatic.isStatic = True
persistedStatic.visibility = VISIBILITY_PUBLIC
persistedStatic.semanticType = intType
persistedStatic.source = sourceLocation
Local persistedArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
persistedArtifact.identity = persistedIdentity
persistedArtifact.languageLinkageRevision = "bmx-language-1"
persistedArtifact.visibility = VISIBILITY_PROTECTED
persistedArtifact.isAbstract = True
persistedArtifact.metadata = [reflectedMetadata]
persistedArtifact.parameters = [persistedParameter]
Local baseReference:TGenericTemplateInheritanceReference = New TGenericTemplateInheritanceReference
baseReference.semanticType = linkedListOfT
baseReference.source = sourceLocation
persistedArtifact.baseType = baseReference
Local interfaceReference:TGenericTemplateInheritanceReference = New TGenericTemplateInheritanceReference
interfaceReference.semanticType = batchesType
interfaceReference.source = sourceLocation
persistedArtifact.interfaces = [interfaceReference]
persistedArtifact.referencedApis = [dependencyReference]
persistedArtifact.members = [persistedMethod]
Local persistedDelegationSignature:TGenericTemplateNode = New TGenericTemplateNode
persistedDelegationSignature.kind = TEMPLATE_NODE_BLOCK
persistedDelegationSignature.valueText = "signature"
Local persistedDelegationParameter:TGenericTemplateNode = New TGenericTemplateNode
persistedDelegationParameter.kind = TEMPLATE_NODE_DECLARATION
persistedDelegationParameter.semanticType = parameterType
persistedDelegationSignature.children = [persistedDelegationParameter]
Local persistedDelegationArguments:TGenericTemplateNode = New TGenericTemplateNode
persistedDelegationArguments.kind = TEMPLATE_NODE_BLOCK
persistedDelegationArguments.valueText = "arguments"
persistedDelegationArguments.children = [returnValue]
Local persistedDelegation:TGenericTemplateNode = New TGenericTemplateNode
persistedDelegation.kind = TEMPLATE_NODE_CONSTRUCTOR_DELEGATION
persistedDelegation.referencedSymbol = dependencyReference
persistedDelegation.source = sourceLocation
persistedDelegation.children = [persistedDelegationSignature, persistedDelegationArguments]
persistedArtifact.body = persistedDelegation
Local revisionDiagnostics:String[]
persistedArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(persistedArtifact, revisionDiagnostics)
Check(revisionDiagnostics.length = 0 And persistedArtifact.contentRevision.length = 64, "canonical artifact payload has a stable SHA-256 content revision")
Local encodeDiagnostics:String[]
Local encodedArtifact:String = TGenericTemplateArtifactCodec.Encode(persistedArtifact, encodeDiagnostics)
Check(encodeDiagnostics.length = 0 And encodedArtifact.StartsWith("BMXGT " + GENERIC_TEMPLATE_FORMAT_VERSION + "~nrevision "), "versioned template artifact encoding")
Local expectedFinalizedRevision:String = persistedArtifact.contentRevision
persistedArtifact.contentRevision = ""
Local finalizeDiagnostics:String[]
Local finalizedArtifact:String = TGenericTemplateArtifactCodec.FinalizeAndEncode(persistedArtifact, finalizeDiagnostics)
Check(finalizeDiagnostics.length = 0 And persistedArtifact.contentRevision = expectedFinalizedRevision And finalizedArtifact = encodedArtifact, "source artifact finalization assigns its revision from the same canonical payload it emits")
Check(Not encodedArtifact.Contains("Type TQueue") And Not encodedArtifact.Contains("G<?>"), "canonical artifact contains records rather than copied or compressed BlitzMax source")
Local decodedResult:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(encodedArtifact, persistedArtifact.contentRevision)
Check(decodedResult.Succeeded(), "versioned template artifact validates and round-trips")
Check(decodedResult.artifact.identity.StableName() = persistedArtifact.identity.StableName(), "round-trip retains stable language identity")
Check(decodedResult.artifact.members.length = 1 And decodedResult.artifact.members[0].body.children[0].children[0].referencedSymbol.StableName() = dependencyReference.StableName(), "round-trip retains typed bodies and symbolic dependency references")
Check(decodedResult.artifact.body.kind = TEMPLATE_NODE_CONSTRUCTOR_DELEGATION And decodedResult.artifact.body.children[0].valueText = "signature" And decodedResult.artifact.body.children[1].valueText = "arguments", "format-4 round-trip retains explicit constructor delegation shape")
Check(decodedResult.artifact.members[0].body.children[1].kind = TEMPLATE_NODE_LOOP_CONTROL And decodedResult.artifact.members[0].body.children[1].identity = "loop0", "format-5 round-trip retains explicit semantic node identity and loop-control target")
Check(decodedResult.artifact.members[0].source.path = sourceLocation.path And decodedResult.artifact.members[0].parameters[0].source.start = sourceLocation.start, "round-trip retains source provenance")
Check(decodedResult.artifact.members[0].source.line = 7 And decodedResult.artifact.members[0].source.column = 3, "format-26 round-trip retains source line and column without consulting source text")
Check(decodedResult.artifact.visibility = VISIBILITY_PROTECTED And decodedResult.artifact.isAbstract And decodedResult.artifact.metadata.length = 1 And decodedResult.artifact.members[0].metadata[0].value = "queue", "format-26 round-trip retains reflected Type flags and declaration metadata")
Check(decodedResult.artifact.baseType.semanticType.CanonicalName() = linkedListOfT.CanonicalName() And decodedResult.artifact.interfaces[0].semanticType.CanonicalName() = batchesType.CanonicalName(), "round-trip retains generic base and Interface references")
Local reencodeDiagnostics:String[]
Check(TGenericTemplateArtifactCodec.Encode(decodedResult.artifact, reencodeDiagnostics) = encodedArtifact And reencodeDiagnostics.length = 0, "artifact bytes are deterministic after round-trip")

Local typeFunctionIdentity:TGenericTemplateIdentity = New TGenericTemplateIdentity
typeFunctionIdentity.moduleName = "Collections.Factory"
typeFunctionIdentity.qualifiedName = "TFactory"
typeFunctionIdentity.arity = 1
Local typeFunctionMember:TGenericTemplateMember = New TGenericTemplateMember
typeFunctionMember.kind = TEMPLATE_MEMBER_METHOD
typeFunctionMember.identity = "method:create/0"
typeFunctionMember.name = "Create"
typeFunctionMember.isTypeFunction = True
typeFunctionMember.visibility = VISIBILITY_PUBLIC
typeFunctionMember.semanticType = parameterType
Local typeFunctionArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
typeFunctionArtifact.identity = typeFunctionIdentity
typeFunctionArtifact.parameters = [persistedParameter]
typeFunctionArtifact.members = [typeFunctionMember]
Local typeFunctionRevisionDiagnostics:String[]
typeFunctionArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(typeFunctionArtifact, typeFunctionRevisionDiagnostics)
Local typeFunctionEncodeDiagnostics:String[]
Local typeFunctionEncoding:String = TGenericTemplateArtifactCodec.Encode(typeFunctionArtifact, typeFunctionEncodeDiagnostics)
Local typeFunctionDecoded:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(typeFunctionEncoding, typeFunctionArtifact.contentRevision)
Check(typeFunctionRevisionDiagnostics.length = 0 And typeFunctionEncodeDiagnostics.length = 0 And typeFunctionDecoded.Succeeded() And typeFunctionDecoded.artifact.members[0].isTypeFunction, "format-30 round-trip retains generic Type Function identity separately from Struct-static ABI")
typeFunctionMember.isTypeFunction = 2
Local invalidTypeFunctionDiagnostics:String[]
TGenericTemplateArtifactCodec.ComputeContentRevision(typeFunctionArtifact, invalidTypeFunctionDiagnostics)
Check(invalidTypeFunctionDiagnostics.length And invalidTypeFunctionDiagnostics[0].StartsWith("BMXGT146"), "writer rejects an invalid Type Function template-member flag")
typeFunctionMember.isTypeFunction = True
Local typeFunctionHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(typeFunctionArtifact, 29, typeFunctionHistoricalDiagnostics).length And typeFunctionHistoricalDiagnostics[0].StartsWith("BMXGT146"), "format-29 cannot silently reinterpret a generic Type Function as an instance Method")
Local reflectionHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(persistedArtifact, 25, reflectionHistoricalDiagnostics).length And reflectionHistoricalDiagnostics[0].StartsWith("BMXGT145"), "format-25 publication cannot silently discard generic reflection metadata")
Local staticMemberArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
staticMemberArtifact.identity = persistedIdentity
staticMemberArtifact.members = [persistedStatic]
Local staticMemberRevisionDiagnostics:String[]
staticMemberArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(staticMemberArtifact, staticMemberRevisionDiagnostics)
Local staticMemberEncodeDiagnostics:String[]
Local staticMemberEncoded:String = TGenericTemplateArtifactCodec.Encode(staticMemberArtifact, staticMemberEncodeDiagnostics)
Local staticMemberDecoded:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(staticMemberEncoded, staticMemberArtifact.contentRevision)
Check(staticMemberRevisionDiagnostics.length = 0 And staticMemberEncodeDiagnostics.length = 0 And staticMemberDecoded.Succeeded() And staticMemberDecoded.artifact.members[0].isStatic And staticMemberDecoded.artifact.members[0].identity = "static:count", "format-23 round-trip retains specialization-owned static storage identity")
Local memberStaticHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(staticMemberArtifact, 22, memberStaticHistoricalDiagnostics).length And memberStaticHistoricalDiagnostics[0].StartsWith("BMXGT143"), "format-22 publication cannot silently discard specialization-owned static storage")
persistedStatic.kind = TEMPLATE_MEMBER_METHOD
persistedStatic.identity = "function:count/0"
Local staticRoutineRevisionDiagnostics:String[]
staticMemberArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(staticMemberArtifact, staticRoutineRevisionDiagnostics)
Local staticRoutineEncodeDiagnostics:String[]
Local staticRoutineEncoded:String = TGenericTemplateArtifactCodec.Encode(staticMemberArtifact, staticRoutineEncodeDiagnostics)
Local staticRoutineDecoded:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(staticRoutineEncoded, staticMemberArtifact.contentRevision)
Check(staticRoutineRevisionDiagnostics.length = 0 And staticRoutineEncodeDiagnostics.length = 0 And staticRoutineDecoded.Succeeded() And staticRoutineDecoded.artifact.members[0].kind = TEMPLATE_MEMBER_METHOD And staticRoutineDecoded.artifact.members[0].isStatic, "static generic-Struct functions round-trip as method-shaped template members")
persistedStatic.kind = TEMPLATE_MEMBER_FIELD
persistedStatic.identity = "static:count"
Local defaultInterfaceMethod:TGenericTemplateMember = New TGenericTemplateMember
defaultInterfaceMethod.kind = TEMPLATE_MEMBER_METHOD
defaultInterfaceMethod.interfaceMethodKind = TEMPLATE_INTERFACE_METHOD_DEFAULT
defaultInterfaceMethod.identity = "method:describe/0"
defaultInterfaceMethod.name = "Describe"
defaultInterfaceMethod.semanticType = intType
defaultInterfaceMethod.body = persistedBody
defaultInterfaceMethod.source = sourceLocation
Local defaultInterfaceArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
defaultInterfaceArtifact.identity = persistedIdentity
defaultInterfaceArtifact.typeDeclarationKind = GENERIC_TYPE_DECLARATION_INTERFACE
defaultInterfaceArtifact.members = [defaultInterfaceMethod]
Local defaultInterfaceRevisionDiagnostics:String[]
defaultInterfaceArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(defaultInterfaceArtifact, defaultInterfaceRevisionDiagnostics)
Local defaultInterfaceEncodeDiagnostics:String[]
Local defaultInterfaceEncoded:String = TGenericTemplateArtifactCodec.Encode(defaultInterfaceArtifact, defaultInterfaceEncodeDiagnostics)
Local defaultInterfaceDecoded:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(defaultInterfaceEncoded, defaultInterfaceArtifact.contentRevision)
Check(defaultInterfaceRevisionDiagnostics.length = 0 And defaultInterfaceEncodeDiagnostics.length = 0 And defaultInterfaceDecoded.Succeeded() And defaultInterfaceDecoded.artifact.members[0].interfaceMethodKind = TEMPLATE_INTERFACE_METHOD_DEFAULT And defaultInterfaceDecoded.artifact.members[0].body.kind = TEMPLATE_NODE_BLOCK, "format-24 round-trip retains an Interface Default method kind and its source-free bound body")
Local defaultInterfaceHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(defaultInterfaceArtifact, 23, defaultInterfaceHistoricalDiagnostics).length And defaultInterfaceHistoricalDiagnostics[0].StartsWith("BMXGT144"), "format-23 publication cannot silently discard Interface Default semantics")
Local methodIdentity:TGenericTemplateIdentity = New TGenericTemplateIdentity
methodIdentity.moduleName = "Collections.Box"
methodIdentity.qualifiedName = "TBox.Select"
methodIdentity.arity = 1
methodIdentity.declarationKind = GENERIC_DECLARATION_ROUTINE
methodIdentity.signatureKey = "result=!type:0;parameters=1:!routine:0"
Local routineParameterType:TTemplateTypeReference = New TTemplateTypeReference
routineParameterType.kind = TEMPLATE_TYPE_PARAMETER
routineParameterType.parameterOwner = TEMPLATE_PARAMETER_OWNER_ROUTINE
routineParameterType.parameterIndex = 0
Local methodParameter:TGenericTemplateParameter = New TGenericTemplateParameter
methodParameter.name = "U"
methodParameter.ordinal = 0
Local containingType:TTemplateTypeReference = New TTemplateTypeReference
containingType.kind = TEMPLATE_TYPE_NAMED
containingType.moduleName = "Collections.Box"
containingType.symbolName = "TBox"
containingType.arguments = [parameterType]
Local methodMember:TGenericTemplateMember = New TGenericTemplateMember
methodMember.kind = TEMPLATE_MEMBER_METHOD
methodMember.identity = "routine:select/1"
methodMember.name = "Select"
methodMember.semanticType = parameterType
Local methodValueParameter:TGenericTemplateValueParameter = New TGenericTemplateValueParameter
methodValueParameter.name = "input"
methodValueParameter.ordinal = 0
methodValueParameter.semanticType = routineParameterType
methodMember.parameters = [methodValueParameter]
Local methodArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
methodArtifact.identity = methodIdentity
methodArtifact.languageLinkageRevision = "bmx-language-1"
methodArtifact.isMethod = True
methodArtifact.containingParameters = [parameter]
methodArtifact.containingType = containingType
Local containingField:TGenericTemplateMember = New TGenericTemplateMember
containingField.kind = TEMPLATE_MEMBER_FIELD
containingField.identity = "field:value"
containingField.name = "value"
containingField.linkageName = "_collections_box_tbox_value"
containingField.semanticType = parameterType
methodArtifact.containingFields = [containingField]
methodArtifact.parameters = [methodParameter]
methodArtifact.members = [methodMember]
Local methodRevisionDiagnostics:String[]
methodArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(methodArtifact, methodRevisionDiagnostics)
Local methodEncodeDiagnostics:String[]
Local methodEncodedArtifact:String = TGenericTemplateArtifactCodec.Encode(methodArtifact, methodEncodeDiagnostics)
Local methodDecodedResult:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(methodEncodedArtifact, methodArtifact.contentRevision)
Check(methodRevisionDiagnostics.length = 0 And methodEncodeDiagnostics.length = 0 And methodDecodedResult.Succeeded(), "format-15 generic method artifact round-trips")
Check(methodDecodedResult.artifact.identity.signatureKey = methodIdentity.signatureKey And methodDecodedResult.artifact.isMethod And methodDecodedResult.artifact.containingParameters.length = 1 And methodDecodedResult.artifact.containingType.CanonicalName() = "collections.box::tbox<!type:0>", "format-15 retains open signature plus separate containing-Type ownership")
Check(methodDecodedResult.artifact.containingFields.length = 1 And methodDecodedResult.artifact.containingFields[0].semanticType.CanonicalName() = "!type:0" And methodDecodedResult.artifact.containingFields[0].linkageName = "_collections_box_tbox_value", "format-15 retains the target-independent containing-owner field layout and language-linkage ownership")
Check(methodDecodedResult.artifact.members[0].semanticType.CanonicalName() = "!type:0" And methodDecodedResult.artifact.members[0].parameters[0].semanticType.CanonicalName() = "!routine:0", "format-15 preserves distinct containing-Type and method-owned parameter references")
Local methodHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(methodArtifact, 13, methodHistoricalDiagnostics).length And methodHistoricalDiagnostics[0].StartsWith("BMXGT138"), "format-13 cannot silently discard the containing-owner field layout")
Local methodFormat14Diagnostics:String[]
Check(Not EncodeHistorical(methodArtifact, 14, methodFormat14Diagnostics).length And methodFormat14Diagnostics[0].StartsWith("BMXGT139"), "format-14 cannot silently discard member language-linkage ownership")
Local ordinaryStructType:TTemplateTypeReference = New TTemplateTypeReference
ordinaryStructType.kind = TEMPLATE_TYPE_NAMED
ordinaryStructType.moduleName = "Geometry.Shapes"
ordinaryStructType.symbolName = "SPoint"
ordinaryStructType.runtimeKind = TEMPLATE_RUNTIME_STRUCT
ordinaryStructType.runtimeAbiName = "geometry_shapes_SPoint"
Local ordinaryStructArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
ordinaryStructArtifact.identity = methodIdentity
ordinaryStructArtifact.languageLinkageRevision = "bmx-language-1"
ordinaryStructArtifact.isMethod = True
ordinaryStructArtifact.typeDeclarationKind = GENERIC_TYPE_DECLARATION_STRUCT
ordinaryStructArtifact.containingType = ordinaryStructType
ordinaryStructArtifact.parameters = [methodParameter]
ordinaryStructArtifact.members = [methodMember]
Local ordinaryStructRevisionDiagnostics:String[]
ordinaryStructArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(ordinaryStructArtifact, ordinaryStructRevisionDiagnostics)
Local ordinaryStructEncodeDiagnostics:String[]
Local ordinaryStructDecoded:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(TGenericTemplateArtifactCodec.Encode(ordinaryStructArtifact, ordinaryStructEncodeDiagnostics), ordinaryStructArtifact.contentRevision)
Check(ordinaryStructRevisionDiagnostics.length = 0 And ordinaryStructEncodeDiagnostics.length = 0 And ordinaryStructDecoded.Succeeded() And ordinaryStructDecoded.artifact.containingType.runtimeKind = TEMPLATE_RUNTIME_STRUCT, "format-15 round-trips an ordinary Struct owner identity without C lowering")
Local ordinaryStructHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(ordinaryStructArtifact, 13, ordinaryStructHistoricalDiagnostics).length And ordinaryStructHistoricalDiagnostics[0].StartsWith("BMXGT138"), "format-13 cannot silently publish an ordinary Struct owner identity")
Local staticIdentity:TGenericTemplateIdentity = New TGenericTemplateIdentity
staticIdentity.moduleName = "Collections.Fixed"
staticIdentity.qualifiedName = "TFixed"
staticIdentity.arity = 1
Local staticBody:TGenericTemplateNode = New TGenericTemplateNode
staticBody.kind = TEMPLATE_NODE_DECLARATION
staticBody.valueText = "fixed"
staticBody.semanticType = staticArrayOfParameter
Local staticArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
staticArtifact.identity = staticIdentity
staticArtifact.parameters = [parameter]
staticArtifact.body = staticBody
Local staticRevisionDiagnostics:String[]
staticArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(staticArtifact, staticRevisionDiagnostics)
Local staticEncodeDiagnostics:String[]
Local staticEncodedArtifact:String = TGenericTemplateArtifactCodec.Encode(staticArtifact, staticEncodeDiagnostics)
Local staticDecodedResult:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(staticEncodedArtifact, staticArtifact.contentRevision)
Check(staticRevisionDiagnostics.length = 0 And staticEncodeDiagnostics.length = 0 And staticDecodedResult.Succeeded() And staticDecodedResult.artifact.body.semanticType.CanonicalName() = "staticarray !type:0[4]", "format-6 round-trip retains StaticArray element and extent identity")
Local staticHistoricalDiagnostics:String[]
Local staticHistoricalText:String = EncodeHistorical(staticArtifact, 5, staticHistoricalDiagnostics)
Check(Not staticHistoricalText.length And staticHistoricalDiagnostics.length = 1 And staticHistoricalDiagnostics[0].StartsWith("BMXGT129"), "format-5 artifacts cannot silently encode a StaticArray without its extent record")
Local mismatchResult:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(encodedArtifact, "0000000000000000000000000000000000000000000000000000000000000000")
Check(Not mismatchResult.Succeeded() And mismatchResult.diagnostics[0].StartsWith("BMXGT106"), "interface content-revision mismatch invalidates an artifact")
Local corruptResult:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(encodedArtifact + "corrupt")
Check(Not corruptResult.Succeeded() And corruptResult.diagnostics[0].StartsWith("BMXGT105"), "payload corruption is rejected before record decoding")
Local runtimeIdentity:TGenericTemplateIdentity = New TGenericTemplateIdentity
runtimeIdentity.moduleName = "Example.Runtime"
runtimeIdentity.qualifiedName = "UseValue"
runtimeIdentity.arity = 1
runtimeIdentity.declarationKind = GENERIC_DECLARATION_ROUTINE
runtimeIdentity.signatureKey = "result=void;parameters="
Local runtimeBody:TGenericTemplateNode = New TGenericTemplateNode
runtimeBody.kind = TEMPLATE_NODE_CONVERSION
runtimeBody.semanticType = ordinaryType
runtimeBody.valueText = "object-checked-cast"
Local runtimeArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
runtimeArtifact.identity = runtimeIdentity
runtimeArtifact.body = runtimeBody
Local runtimeRevisionDiagnostics:String[]
runtimeArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(runtimeArtifact, runtimeRevisionDiagnostics)
Local runtimeEncodeDiagnostics:String[]
Local runtimeEncodedArtifact:String = TGenericTemplateArtifactCodec.Encode(runtimeArtifact, runtimeEncodeDiagnostics)
Local runtimeDecodedResult:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(runtimeEncodedArtifact, runtimeArtifact.contentRevision)
Check(runtimeRevisionDiagnostics.length = 0 And runtimeEncodeDiagnostics.length = 0 And runtimeDecodedResult.Succeeded(), "format-7 ordinary runtime identity round-trips without source or backend-specific lowering")
Check(runtimeDecodedResult.artifact.body.semanticType.runtimeKind = TEMPLATE_RUNTIME_CLASS And runtimeDecodedResult.artifact.body.semanticType.runtimeAbiName = ordinaryType.runtimeAbiName, "format-7 retains stable ordinary language-linkage identity")
Local runtimeHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(runtimeArtifact, 6, runtimeHistoricalDiagnostics).length And runtimeHistoricalDiagnostics[0].StartsWith("BMXGT130"), "format-6 cannot silently discard an ordinary runtime identity")
Local genericCategoryType:TTemplateTypeReference = New TTemplateTypeReference
genericCategoryType.kind = TEMPLATE_TYPE_NAMED
genericCategoryType.moduleName = "Collections.LinkedList"
genericCategoryType.symbolName = "TLinkedList"
genericCategoryType.arguments = [parameterType]
genericCategoryType.runtimeKind = TEMPLATE_RUNTIME_CLASS
Local categoryBody:TGenericTemplateNode = New TGenericTemplateNode
categoryBody.kind = TEMPLATE_NODE_RETURN
categoryBody.semanticType = genericCategoryType
Local categoryArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
categoryArtifact.identity = runtimeIdentity
categoryArtifact.parameters = [parameter]
categoryArtifact.body = categoryBody
Local categoryRevisionDiagnostics:String[]
categoryArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(categoryArtifact, categoryRevisionDiagnostics)
Local categoryEncodeDiagnostics:String[]
Local categoryEncodedArtifact:String = TGenericTemplateArtifactCodec.Encode(categoryArtifact, categoryEncodeDiagnostics)
Local categoryDecodedResult:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(categoryEncodedArtifact, categoryArtifact.contentRevision)
Check(categoryRevisionDiagnostics.length = 0 And categoryEncodeDiagnostics.length = 0 And categoryDecodedResult.Succeeded() And categoryDecodedResult.artifact.body.semanticType.runtimeKind = TEMPLATE_RUNTIME_CLASS And Not categoryDecodedResult.artifact.body.semanticType.runtimeAbiName.length, "format-28 retains a constructed generic runtime category while deferring its canonical specialization ABI")
Local categoryHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(categoryArtifact, 27, categoryHistoricalDiagnostics).length And categoryHistoricalDiagnostics[0].StartsWith("BMXGT130"), "format-27 cannot silently encode a constructed generic runtime category without an ordinary ABI")
Local dispatchReceiver:TGenericTemplateNode = New TGenericTemplateNode
dispatchReceiver.kind = TEMPLATE_NODE_DECLARATION
dispatchReceiver.semanticType = ordinaryType
dispatchReceiver.valueText = "eachin-protocol-receiver"
Local dispatchCall:TGenericTemplateNode = New TGenericTemplateNode
dispatchCall.kind = TEMPLATE_NODE_CALL
dispatchCall.semanticType = ordinaryType
dispatchCall.valueText = "ObjectEnumerator"
dispatchCall.runtimeDispatchKind = TEMPLATE_DISPATCH_ORDINARY_CLASS
dispatchCall.runtimeDispatchIndex = 7
dispatchCall.children = [dispatchReceiver]
Local dispatchArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
dispatchArtifact.identity = runtimeIdentity
dispatchArtifact.body = dispatchCall
Local dispatchRevisionDiagnostics:String[]
dispatchArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(dispatchArtifact, dispatchRevisionDiagnostics)
Local dispatchEncodeDiagnostics:String[]
Local dispatchEncodedArtifact:String = TGenericTemplateArtifactCodec.Encode(dispatchArtifact, dispatchEncodeDiagnostics)
Local dispatchDecodedResult:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(dispatchEncodedArtifact, dispatchArtifact.contentRevision)
Check(dispatchRevisionDiagnostics.length = 0 And dispatchEncodeDiagnostics.length = 0 And dispatchDecodedResult.Succeeded() And dispatchDecodedResult.artifact.body.runtimeDispatchIndex = 7, "format-8 ordinary virtual dispatch ordinal round-trips without a class layout or C body")
Local dispatchHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(dispatchArtifact, 7, dispatchHistoricalDiagnostics).length And dispatchHistoricalDiagnostics[0].StartsWith("BMXGT131"), "format-7 cannot silently discard an ordinary virtual dispatch ordinal")
Local superReceiver:TGenericTemplateNode = New TGenericTemplateNode
superReceiver.kind = TEMPLATE_NODE_SELF
superReceiver.semanticType = linkedListOfT
superReceiver.valueText = "super"
superReceiver.source = sourceLocation
Local superArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
superArtifact.identity = runtimeIdentity
superArtifact.body = superReceiver
Local superRevisionDiagnostics:String[]
superArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(superArtifact, superRevisionDiagnostics)
Local superEncodeDiagnostics:String[]
Local superEncodedArtifact:String = TGenericTemplateArtifactCodec.Encode(superArtifact, superEncodeDiagnostics)
Local superDecodedResult:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(superEncodedArtifact, superArtifact.contentRevision)
Check(superRevisionDiagnostics.length = 0 And superEncodeDiagnostics.length = 0 And superDecodedResult.Succeeded() And superDecodedResult.artifact.body.kind = TEMPLATE_NODE_SELF And superDecodedResult.artifact.body.valueText = "super" And superDecodedResult.artifact.body.semanticType.CanonicalName() = linkedListOfT.CanonicalName(), "format-9 round-trip retains an explicit typed Super receiver without source")
Local superHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(superArtifact, 8, superHistoricalDiagnostics).length And superHistoricalDiagnostics[0].StartsWith("BMXGT132"), "format-8 cannot silently publish an unrepresented Self/Super receiver identity")
Local arrayReceiver:TGenericTemplateNode = New TGenericTemplateNode
arrayReceiver.kind = TEMPLATE_NODE_NAME
arrayReceiver.semanticType = arrayType
arrayReceiver.valueText = "values"
Local arrayLength:TGenericTemplateNode = New TGenericTemplateNode
arrayLength.kind = TEMPLATE_NODE_ARRAY_LENGTH
arrayLength.semanticType = intType
arrayLength.children = [arrayReceiver]
Local arrayIndex:TGenericTemplateNode = New TGenericTemplateNode
arrayIndex.kind = TEMPLATE_NODE_LITERAL
arrayIndex.semanticType = intType
arrayIndex.valueText = "0"
Local arrayElement:TGenericTemplateNode = New TGenericTemplateNode
arrayElement.kind = TEMPLATE_NODE_ARRAY_ELEMENT
arrayElement.semanticType = stringType
arrayElement.children = [arrayReceiver, arrayIndex]
Local arraySlice:TGenericTemplateNode = New TGenericTemplateNode
arraySlice.kind = TEMPLATE_NODE_ARRAY_SLICE
arraySlice.semanticType = arrayType
arraySlice.children = [arrayReceiver, arrayIndex, arrayLength]
Local arrayExpressionStatement:TGenericTemplateNode = New TGenericTemplateNode
arrayExpressionStatement.kind = TEMPLATE_NODE_EXPRESSION_STATEMENT
arrayExpressionStatement.semanticType = stringType
arrayExpressionStatement.children = [arrayElement]
Local throwValue:TGenericTemplateNode = New TGenericTemplateNode
throwValue.kind = TEMPLATE_NODE_NAME
throwValue.semanticType = ordinaryType
throwValue.valueText = "failure"
Local throwStatement:TGenericTemplateNode = New TGenericTemplateNode
throwStatement.kind = TEMPLATE_NODE_THROW
throwStatement.semanticType = ordinaryType
throwStatement.children = [throwValue]
Local assertStatement:TGenericTemplateNode = New TGenericTemplateNode
assertStatement.kind = TEMPLATE_NODE_ASSERT
assertStatement.semanticType = intType
assertStatement.children = [arrayLength]
Local localRoutineReturn:TGenericTemplateNode = New TGenericTemplateNode
localRoutineReturn.kind = TEMPLATE_NODE_RETURN
localRoutineReturn.semanticType = intType
localRoutineReturn.children = [arrayLength]
Local localRoutineBody:TGenericTemplateNode = New TGenericTemplateNode
localRoutineBody.kind = TEMPLATE_NODE_BLOCK
localRoutineBody.children = [localRoutineReturn]
Local localRoutineSignature:TGenericTemplateNode = New TGenericTemplateNode
localRoutineSignature.kind = TEMPLATE_NODE_BLOCK
localRoutineSignature.valueText = "local-routine-signature"
localRoutineSignature.identity = "length/result=builtin:int;parameters="
localRoutineSignature.semanticType = intType
localRoutineSignature.children = [localRoutineBody]
Local arrayBody:TGenericTemplateNode = New TGenericTemplateNode
arrayBody.kind = TEMPLATE_NODE_BLOCK
arrayBody.children = [arrayLength, arrayElement, arraySlice, arrayExpressionStatement, throwStatement, assertStatement, localRoutineSignature]
Local arrayArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
arrayArtifact.identity = runtimeIdentity
arrayArtifact.body = arrayBody
Local arrayRevisionDiagnostics:String[]
arrayArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(arrayArtifact, arrayRevisionDiagnostics)
Local arrayEncodeDiagnostics:String[]
Local arrayEncodedArtifact:String = TGenericTemplateArtifactCodec.Encode(arrayArtifact, arrayEncodeDiagnostics)
Local arrayDecodedResult:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(arrayEncodedArtifact, arrayArtifact.contentRevision)
Check(arrayRevisionDiagnostics.length = 0 And arrayEncodeDiagnostics.length = 0 And arrayDecodedResult.Succeeded() And arrayDecodedResult.artifact.body.children[0].kind = TEMPLATE_NODE_ARRAY_LENGTH And arrayDecodedResult.artifact.body.children[1].kind = TEMPLATE_NODE_ARRAY_ELEMENT And arrayDecodedResult.artifact.body.children[2].kind = TEMPLATE_NODE_ARRAY_SLICE And arrayDecodedResult.artifact.body.children[3].kind = TEMPLATE_NODE_EXPRESSION_STATEMENT And arrayDecodedResult.artifact.body.children[4].kind = TEMPLATE_NODE_THROW And arrayDecodedResult.artifact.body.children[5].kind = TEMPLATE_NODE_ASSERT And arrayDecodedResult.artifact.body.children[6].valueText = "local-routine-signature", "format-17 round-trip retains target-independent managed Array operations, expression statements, Throw, Assert, and local routine records")
arrayType.rank = 2
arrayElement.children = [arrayReceiver, arrayIndex, arrayIndex]
Local multidimensionalRevisionDiagnostics:String[]
arrayArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(arrayArtifact, multidimensionalRevisionDiagnostics)
Local multidimensionalEncodeDiagnostics:String[]
Local multidimensionalEncoded:String = TGenericTemplateArtifactCodec.Encode(arrayArtifact, multidimensionalEncodeDiagnostics)
Local multidimensionalDecoded:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(multidimensionalEncoded, arrayArtifact.contentRevision)
Check(multidimensionalRevisionDiagnostics.length = 0 And multidimensionalEncodeDiagnostics.length = 0 And multidimensionalDecoded.Succeeded() And multidimensionalDecoded.artifact.body.children[1].children.length = 3 And multidimensionalDecoded.artifact.body.children[1].children[0].semanticType.rank = 2, "format-22 round-trip retains a rank-aware receiver plus every multidimensional Array index")
Local multidimensionalHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(arrayArtifact, 21, multidimensionalHistoricalDiagnostics).length And multidimensionalHistoricalDiagnostics[0].StartsWith("BMXGT133"), "format-21 publication cannot silently collapse multidimensional Array indexes")
arrayType.rank = 1
arrayElement.children = [arrayReceiver, arrayIndex]
Local restoredArrayRevisionDiagnostics:String[]
arrayArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(arrayArtifact, restoredArrayRevisionDiagnostics)
Local selectNode:TGenericTemplateNode = New TGenericTemplateNode
selectNode.kind = TEMPLATE_NODE_SELECT
selectNode.identity = "select0"
selectNode.semanticType = intType
selectNode.children = [arrayIndex]
Local arrayLiteralNode:TGenericTemplateNode = New TGenericTemplateNode
arrayLiteralNode.kind = TEMPLATE_NODE_ARRAY_LITERAL
arrayLiteralNode.semanticType = arrayType
arrayLiteralNode.children = [arrayElement]
Local protectedBody:TGenericTemplateNode = New TGenericTemplateNode
protectedBody.kind = TEMPLATE_NODE_BLOCK
Local finallyBody:TGenericTemplateNode = New TGenericTemplateNode
finallyBody.kind = TEMPLATE_NODE_BLOCK
Local tryNode:TGenericTemplateNode = New TGenericTemplateNode
tryNode.kind = TEMPLATE_NODE_TRY
tryNode.valueText = "finally"
tryNode.children = [protectedBody, finallyBody]
Local usingResourceNode:TGenericTemplateNode = New TGenericTemplateNode
usingResourceNode.kind = TEMPLATE_NODE_BLOCK
usingResourceNode.valueText = "using-resource"
Local usingBody:TGenericTemplateNode = New TGenericTemplateNode
usingBody.kind = TEMPLATE_NODE_BLOCK
Local usingNode:TGenericTemplateNode = New TGenericTemplateNode
usingNode.kind = TEMPLATE_NODE_USING
usingNode.children = [usingResourceNode, usingBody]
Local format20Body:TGenericTemplateNode = New TGenericTemplateNode
format20Body.kind = TEMPLATE_NODE_BLOCK
format20Body.children = [selectNode, arrayLiteralNode, tryNode, usingNode]
Local format20Artifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
format20Artifact.identity = runtimeIdentity
format20Artifact.body = format20Body
Local format20RevisionDiagnostics:String[]
format20Artifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(format20Artifact, format20RevisionDiagnostics)
Local format20EncodeDiagnostics:String[]
Local format20Encoded:String = TGenericTemplateArtifactCodec.Encode(format20Artifact, format20EncodeDiagnostics)
Local format20Decoded:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(format20Encoded, format20Artifact.contentRevision)
Check(format20RevisionDiagnostics.length = 0 And format20EncodeDiagnostics.length = 0 And format20Decoded.Succeeded() And format20Decoded.artifact.body.children[0].kind = TEMPLATE_NODE_SELECT And format20Decoded.artifact.body.children[1].kind = TEMPLATE_NODE_ARRAY_LITERAL And format20Decoded.artifact.body.children[2].kind = TEMPLATE_NODE_TRY And format20Decoded.artifact.body.children[3].kind = TEMPLATE_NODE_USING, "format-20 round-trip retains Select, managed Array literal, Try/Finally, and Using records without source or backend lowering")
Local format20HistoricalDiagnostics:String[]
Check(Not EncodeHistorical(format20Artifact, 19, format20HistoricalDiagnostics).length And format20HistoricalDiagnostics[0].StartsWith("BMXGT139"), "format-19 publication cannot silently discard format-20 executable template records")
Local callableType:TTemplateTypeReference = New TTemplateTypeReference
callableType.kind = TEMPLATE_TYPE_CALLABLE
callableType.elementType = intType
callableType.arguments = [intType]
callableType.callableParameterModes = [GENERIC_TEMPLATE_PARAMETER_PASS_VAR]
Check(callableType.CanonicalName() = "callable int(var:int)", "callable template type identity retains its return, ordered parameters, and Var modes")
Local callableDeclaration:TGenericTemplateNode = New TGenericTemplateNode
callableDeclaration.kind = TEMPLATE_NODE_DECLARATION
callableDeclaration.semanticType = callableType
callableDeclaration.identity = "local"
callableDeclaration.valueText = "callback"
Local dataValue:TGenericTemplateNode = New TGenericTemplateNode
dataValue.kind = TEMPLATE_NODE_LITERAL
dataValue.semanticType = intType
dataValue.valueText = "42"
Local dataDefinition:TGenericTemplateNode = New TGenericTemplateNode
dataDefinition.kind = TEMPLATE_NODE_DATA
dataDefinition.identity = "define"
dataDefinition.valueText = "120"
dataDefinition.children = [dataValue]
Local dataTargetName:TGenericTemplateNode = New TGenericTemplateNode
dataTargetName.kind = TEMPLATE_NODE_NAME
dataTargetName.semanticType = intType
dataTargetName.valueText = "value"
Local dataTarget:TGenericTemplateNode = New TGenericTemplateNode
dataTarget.kind = TEMPLATE_NODE_BLOCK
dataTarget.valueText = "1"
dataTarget.semanticType = intType
dataTarget.children = [dataTargetName]
Local dataRead:TGenericTemplateNode = New TGenericTemplateNode
dataRead.kind = TEMPLATE_NODE_DATA
dataRead.identity = "read"
dataRead.children = [dataTarget]
Local dataRestore:TGenericTemplateNode = New TGenericTemplateNode
dataRestore.kind = TEMPLATE_NODE_DATA
dataRestore.identity = "restore"
dataRestore.valueText = "120"
Local catchParameter:TGenericTemplateNode = New TGenericTemplateNode
catchParameter.kind = TEMPLATE_NODE_DECLARATION
catchParameter.identity = "catch-parameter"
catchParameter.valueText = "problem"
catchParameter.semanticType = stringType
Local catchBody:TGenericTemplateNode = New TGenericTemplateNode
catchBody.kind = TEMPLATE_NODE_BLOCK
Local catchClause:TGenericTemplateNode = New TGenericTemplateNode
catchClause.kind = TEMPLATE_NODE_BLOCK
catchClause.valueText = "catch-clause"
catchClause.children = [catchParameter, catchBody]
Local wrappedFinally:TGenericTemplateNode = New TGenericTemplateNode
wrappedFinally.kind = TEMPLATE_NODE_BLOCK
wrappedFinally.valueText = "finally-body"
wrappedFinally.children = [finallyBody]
Local catchFinally:TGenericTemplateNode = New TGenericTemplateNode
catchFinally.kind = TEMPLATE_NODE_TRY
catchFinally.valueText = "catch-finally"
catchFinally.children = [protectedBody, catchClause, wrappedFinally]
Local format21Body:TGenericTemplateNode = New TGenericTemplateNode
format21Body.kind = TEMPLATE_NODE_BLOCK
format21Body.children = [callableDeclaration, dataDefinition, dataRestore, dataRead, catchFinally]
Local format21Artifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
format21Artifact.identity = runtimeIdentity
format21Artifact.body = format21Body
Local format21RevisionDiagnostics:String[]
format21Artifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(format21Artifact, format21RevisionDiagnostics)
Local format21EncodeDiagnostics:String[]
Local format21Encoded:String = TGenericTemplateArtifactCodec.Encode(format21Artifact, format21EncodeDiagnostics)
Local format21Decoded:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(format21Encoded, format21Artifact.contentRevision)
Check(format21RevisionDiagnostics.length = 0 And format21EncodeDiagnostics.length = 0 And format21Decoded.Succeeded() And format21Decoded.artifact.body.children[0].semanticType.callableParameterModes[0] = GENERIC_TEMPLATE_PARAMETER_PASS_VAR And format21Decoded.artifact.body.children[1].kind = TEMPLATE_NODE_DATA And format21Decoded.artifact.body.children[4].valueText = "catch-finally", "format-21 round-trip retains callable types, Data operations, and explicit Catch/Finally routing without source or backend lowering")
Local callableHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(format21Artifact, 20, callableHistoricalDiagnostics).length And callableHistoricalDiagnostics[0].StartsWith("BMXGT141"), "format-20 publication cannot silently discard callable, Data, or Catch routing records")
Local arrayHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(arrayArtifact, 10, arrayHistoricalDiagnostics).length And arrayHistoricalDiagnostics[0].StartsWith("BMXGT134"), "format-10 cannot silently discard managed Array slice identity")
Local expressionStatementHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(arrayArtifact, 11, expressionStatementHistoricalDiagnostics).length And expressionStatementHistoricalDiagnostics[0].StartsWith("BMXGT135"), "format-11 cannot silently discard expression-statement identity")
Local assertHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(arrayArtifact, 15, assertHistoricalDiagnostics).length And assertHistoricalDiagnostics[0].StartsWith("BMXGT137"), "format-15 cannot silently discard Assert identity")
Local localRoutineHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(arrayArtifact, 16, localRoutineHistoricalDiagnostics).length And localRoutineHistoricalDiagnostics[0].StartsWith("BMXGT138"), "format-16 cannot silently reinterpret local routine records as ordinary blocks")

Local enumRuntimeType:TTemplateTypeReference = New TTemplateTypeReference
enumRuntimeType.kind = TEMPLATE_TYPE_NAMED
enumRuntimeType.moduleName = "BRL.Time"
enumRuntimeType.symbolName = "ETimeUnit"
enumRuntimeType.runtimeKind = TEMPLATE_RUNTIME_ENUM
enumRuntimeType.runtimeAbiName = "brl_time_ETimeUnit"
enumRuntimeType.runtimeValueType = "Int"
Local enumDefaultValue:TGenericTemplateNode = New TGenericTemplateNode
enumDefaultValue.kind = TEMPLATE_NODE_LITERAL
enumDefaultValue.semanticType = enumRuntimeType
enumDefaultValue.valueText = "2"
Local optionalTimeoutUnit:TGenericTemplateValueParameter = New TGenericTemplateValueParameter
optionalTimeoutUnit.name = "unit"
optionalTimeoutUnit.ordinal = 0
optionalTimeoutUnit.semanticType = enumRuntimeType
optionalTimeoutUnit.passingMode = PARAMETER_PASS_VALUE
optionalTimeoutUnit.optional = True
optionalTimeoutUnit.defaultValue = enumDefaultValue
Local optionalMethod:TGenericTemplateMember = New TGenericTemplateMember
optionalMethod.kind = TEMPLATE_MEMBER_METHOD
optionalMethod.identity = "method:wait/1"
optionalMethod.name = "Wait"
optionalMethod.semanticType = intType
optionalMethod.parameters = [optionalTimeoutUnit]
Local optionalArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
optionalArtifact.identity = runtimeIdentity
optionalArtifact.members = [optionalMethod]
Local optionalRevisionDiagnostics:String[]
optionalArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(optionalArtifact, optionalRevisionDiagnostics)
Local optionalEncodeDiagnostics:String[]
Local optionalEncodedArtifact:String = TGenericTemplateArtifactCodec.Encode(optionalArtifact, optionalEncodeDiagnostics)
Local optionalDecodedResult:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(optionalEncodedArtifact, optionalArtifact.contentRevision)
Check(optionalRevisionDiagnostics.length = 0 And optionalEncodeDiagnostics.length = 0 And optionalDecodedResult.Succeeded(), "format-18 optional parameter defaults and ordinary Enum identities round-trip without source")
Local decodedOptionalParameter:TGenericTemplateValueParameter = optionalDecodedResult.artifact.members[0].parameters[0]
Check(decodedOptionalParameter.optional And decodedOptionalParameter.defaultValue.valueText = "2" And decodedOptionalParameter.semanticType.runtimeKind = TEMPLATE_RUNTIME_ENUM And decodedOptionalParameter.semanticType.runtimeValueType = "Int", "format-18 retains the bound enum default and its target-independent integral representation")
Local optionalHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(optionalArtifact, 17, optionalHistoricalDiagnostics).length And optionalHistoricalDiagnostics[0].StartsWith("BMXGT140"), "format-17 cannot silently discard optional parameter defaults")
Local enumOnlyArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
enumOnlyArtifact.identity = runtimeIdentity
enumOnlyArtifact.body = enumDefaultValue
Local enumHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(enumOnlyArtifact, 17, enumHistoricalDiagnostics).length And enumHistoricalDiagnostics[0].StartsWith("BMXGT140"), "format-17 cannot silently discard an ordinary Enum runtime identity")

Local versionResult:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(encodedArtifact.Replace("BMXGT " + GENERIC_TEMPLATE_FORMAT_VERSION, "BMXGT " + (GENERIC_TEMPLATE_FORMAT_VERSION + 1)))
Check(Not versionResult.Succeeded() And versionResult.diagnostics[0].StartsWith("BMXGT103"), "unknown required artifact version is rejected")

' Format 2 is a read-only migration path with inheritance but no explicit
' Type/Interface/Struct declaration flavor.
Local canonicalBody:TGenericTemplateNode = persistedArtifact.body
Local canonicalMemberBodyChildren:TGenericTemplateNode[] = persistedBody.children
Local canonicalRevision:String = persistedArtifact.contentRevision
Local canonicalVisibility:Int = persistedArtifact.visibility
Local canonicalAbstract:Int = persistedArtifact.isAbstract
Local canonicalMetadata:TGenericTemplateMetadataEntry[] = persistedArtifact.metadata
Local canonicalMemberMetadata:TGenericTemplateMetadataEntry[] = persistedMethod.metadata
persistedArtifact.body = Null
persistedBody.children = [persistedReturn]
persistedArtifact.contentRevision = ""
persistedArtifact.visibility = 0
persistedArtifact.isAbstract = False
persistedArtifact.metadata = New TGenericTemplateMetadataEntry[0]
persistedMethod.metadata = New TGenericTemplateMetadataEntry[0]
Local migrationSourceEncodeDiagnostics:String[]
Local migrationSourceArtifact:String = EncodeHistorical(persistedArtifact, 4, migrationSourceEncodeDiagnostics)
persistedArtifact.body = canonicalBody
persistedBody.children = canonicalMemberBodyChildren
persistedArtifact.contentRevision = canonicalRevision
persistedArtifact.visibility = canonicalVisibility
persistedArtifact.isAbstract = canonicalAbstract
persistedArtifact.metadata = canonicalMetadata
persistedMethod.metadata = canonicalMemberMetadata
Check(migrationSourceEncodeDiagnostics.length = 0, "migration fixture uses a format-4 pre-delegation canonical body")
Local version2Lines:String[] = migrationSourceArtifact.Split(Chr(10))
Local version3Payload:String
For Local lineIndex:Int = 2 Until version2Lines.length
	Local line:String = version2Lines[lineIndex]
	If lineIndex = 3 Then line = "i 3"
	If version3Payload.length Then version3Payload :+ "~n"
	version3Payload :+ line
Next
Local version3Text:String = "BMXGT 3~nrevision " + TGenericTemplateArtifactCodec.Digest(version3Payload) + "~n" + version3Payload
Local version3Result:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(version3Text)
Check(version3Result.Succeeded() And version3Result.artifact.formatVersion = 3, "format-3 source-free artifacts remain readable during migration")
Local version3RepublishDiagnostics:String[]
Check(TGenericTemplateArtifactCodec.Encode(version3Result.artifact, version3RepublishDiagnostics) = "" And version3RepublishDiagnostics[0].StartsWith("BMXGT101"), "the migration reader never republishes format 3 as canonical output")
Local version2ParametersIndex:Int = -1
For Local lineIndex:Int = 2 Until version2Lines.length
	If version2Lines[lineIndex].StartsWith("parameters ") Then version2ParametersIndex = lineIndex; Exit
Next
Local version2Payload:String
For Local lineIndex:Int = 2 Until version2Lines.length
	If lineIndex = version2ParametersIndex - 1 Then Continue
	Local line:String = version2Lines[lineIndex]
	If lineIndex = 3 Then line = "i 2"
	If version2Payload.length Then version2Payload :+ "~n"
	version2Payload :+ line
Next
Local version2Text:String = "BMXGT 2~nrevision " + TGenericTemplateArtifactCodec.Digest(version2Payload) + "~n" + version2Payload
Local version2Result:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(version2Text)
Check(version2ParametersIndex > 0 And version2Result.Succeeded() And version2Result.artifact.formatVersion = 2, "format-2 source-free artifacts remain readable during migration")
Check(version2Result.artifact.typeDeclarationKind = GENERIC_TYPE_DECLARATION_CLASS And version2Result.artifact.baseType And version2Result.artifact.interfaces.length = 1, "format-2 ingestion defaults its absent declaration flavor while retaining inheritance")
Local version2RepublishDiagnostics:String[]
Check(TGenericTemplateArtifactCodec.Encode(version2Result.artifact, version2RepublishDiagnostics) = "" And version2RepublishDiagnostics[0].StartsWith("BMXGT101"), "the migration reader never republishes format 2 as canonical output")

' Format 1 is a read-only migration path. New producers cannot request it,
' but existing source-free artifacts remain ingestible until their modules
' are rebuilt and republished as the current canonical format.
Local legacyArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
legacyArtifact.identity = persistedIdentity
legacyArtifact.languageLinkageRevision = "bmx-language-1"
legacyArtifact.parameters = [persistedParameter]
Local legacyEncodeDiagnostics:String[]
Local canonicalLegacyInput:String = EncodeHistorical(legacyArtifact, 4, legacyEncodeDiagnostics)
Local legacyLines:String[] = canonicalLegacyInput.Split(Chr(10))
Local legacyApisIndex:Int = -1
Local legacyParametersIndex:Int = -1
For Local lineIndex:Int = 2 Until legacyLines.length
	If legacyLines[lineIndex].StartsWith("parameters ") Then legacyParametersIndex = lineIndex
	If legacyLines[lineIndex].StartsWith("apis ") Then legacyApisIndex = lineIndex; Exit
Next
Local legacyPayload:String
For Local lineIndex:Int = 2 Until legacyLines.length
	If lineIndex = legacyParametersIndex - 1 Or lineIndex = legacyApisIndex - 2 Or lineIndex = legacyApisIndex - 1 Then Continue
	Local line:String = legacyLines[lineIndex]
	If lineIndex = 3 Then line = "i 1"
	If legacyPayload.length Then legacyPayload :+ "~n"
	legacyPayload :+ line
Next
Local legacyText:String = "BMXGT 1~nrevision " + TGenericTemplateArtifactCodec.Digest(legacyPayload) + "~n" + legacyPayload
Local legacyResult:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(legacyText)
Check(legacyEncodeDiagnostics.length = 0 And legacyParametersIndex > 0 And legacyApisIndex > 0 And legacyResult.Succeeded(), "format-1 source-free artifacts remain readable during migration")
Check(legacyResult.artifact.formatVersion = 1 And Not legacyResult.artifact.baseType And legacyResult.artifact.interfaces.length = 0, "legacy ingestion defaults absent inheritance records without inventing source")
legacyResult.artifact.formatVersion = 1
Local legacyRepublishDiagnostics:String[]
Check(TGenericTemplateArtifactCodec.Encode(legacyResult.artifact, legacyRepublishDiagnostics) = "" And legacyRepublishDiagnostics[0].StartsWith("BMXGT101"), "the migration reader never republishes format 1 as canonical output")

Local closureType:TTemplateTypeReference = New TTemplateTypeReference
closureType.kind = TEMPLATE_TYPE_CLOSURE
closureType.elementType = intType
closureType.arguments = [intType]
closureType.callableParameterModes = [GENERIC_TEMPLATE_PARAMETER_PASS_VALUE]
closureType.callableParameterNames = ["value"]
Check(closureType.CanonicalName() = "closure int(int)", "Closure template identity is structural and excludes source-only parameter names")
Local closureSignature:TGenericTemplateNode = New TGenericTemplateNode
closureSignature.kind = TEMPLATE_NODE_BLOCK
closureSignature.valueText = "closure-literal-signature"
Local closureParameter:TGenericTemplateNode = New TGenericTemplateNode
closureParameter.kind = TEMPLATE_NODE_DECLARATION
closureParameter.identity = GENERIC_TEMPLATE_PARAMETER_PASS_VALUE
closureParameter.valueText = "value"
closureParameter.semanticType = intType
closureSignature.children = [closureParameter]
Local closureBody:TGenericTemplateNode = New TGenericTemplateNode
closureBody.kind = TEMPLATE_NODE_BLOCK
Local closureCaptures:TGenericTemplateNode = New TGenericTemplateNode
closureCaptures.kind = TEMPLATE_NODE_BLOCK
closureCaptures.valueText = "closure-literal-captures"
Local closureCapture:TGenericTemplateNode = New TGenericTemplateNode
closureCapture.kind = TEMPLATE_NODE_DECLARATION
closureCapture.identity = "closure-capture-parameter"
closureCapture.valueText = "remembered"
closureCapture.semanticType = intType
Local closureSelfCapture:TGenericTemplateNode = New TGenericTemplateNode
closureSelfCapture.kind = TEMPLATE_NODE_DECLARATION
closureSelfCapture.identity = "closure-capture-self"
closureSelfCapture.valueText = "Self"
Local closureSelfType:TTemplateTypeReference = New TTemplateTypeReference
closureSelfType.kind = TEMPLATE_TYPE_NAMED
closureSelfType.moduleName = "Acme"
closureSelfType.symbolName = "Owner"
closureSelfType.runtimeKind = TEMPLATE_RUNTIME_CLASS
closureSelfType.runtimeAbiName = "acme_owner_TOwner"
closureSelfCapture.semanticType = closureSelfType
closureCaptures.children = [closureCapture, closureSelfCapture]
Local closureLiteral:TGenericTemplateNode = New TGenericTemplateNode
closureLiteral.kind = TEMPLATE_NODE_FUNCTION_LITERAL
closureLiteral.identity = "closure-literal:42"
closureLiteral.semanticType = closureType
closureLiteral.children = [closureSignature, closureCaptures, closureBody]
Local closureArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
closureArtifact.identity = runtimeIdentity
closureArtifact.body = closureLiteral
Local closureRevisionDiagnostics:String[]
closureArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(closureArtifact, closureRevisionDiagnostics)
Local closureEncodeDiagnostics:String[]
Local closureEncoded:String = TGenericTemplateArtifactCodec.Encode(closureArtifact, closureEncodeDiagnostics)
Local closureDecoded:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(closureEncoded, closureArtifact.contentRevision)
Check(closureRevisionDiagnostics.length = 0 And closureEncodeDiagnostics.length = 0 And closureDecoded.Succeeded() And closureDecoded.artifact.body.kind = TEMPLATE_NODE_FUNCTION_LITERAL And closureDecoded.artifact.body.semanticType.callableParameterNames[0] = "value" And closureDecoded.artifact.body.children.length = 3 And closureDecoded.artifact.body.children[1].children[0].identity = "closure-capture-parameter" And closureDecoded.artifact.body.children[1].children[1].identity = "closure-capture-self", "format-27 round-trip retains structural Closure types, source parameter names, lexical and Self capture records, and managed literal bodies")
Local closureHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(closureArtifact, 26, closureHistoricalDiagnostics).length And closureHistoricalDiagnostics[0].StartsWith("BMXGT142"), "format-26 publication cannot silently discard Closure types or literal bodies")

Local functionType:TTemplateTypeReference = New TTemplateTypeReference
functionType.kind = TEMPLATE_TYPE_CALLABLE
functionType.elementType = intType
functionType.arguments = [intType]
functionType.callableParameterModes = [GENERIC_TEMPLATE_PARAMETER_PASS_VAR]
Local functionSignature:TGenericTemplateNode = New TGenericTemplateNode
functionSignature.kind = TEMPLATE_NODE_BLOCK
functionSignature.valueText = "function-literal-signature"
Local functionParameter:TGenericTemplateNode = New TGenericTemplateNode
functionParameter.kind = TEMPLATE_NODE_DECLARATION
functionParameter.identity = GENERIC_TEMPLATE_PARAMETER_PASS_VAR
functionParameter.valueText = "value"
functionParameter.semanticType = intType
functionSignature.children = [functionParameter]
Local functionBody:TGenericTemplateNode = New TGenericTemplateNode
functionBody.kind = TEMPLATE_NODE_BLOCK
Local functionLiteral:TGenericTemplateNode = New TGenericTemplateNode
functionLiteral.kind = TEMPLATE_NODE_FUNCTION_LITERAL
functionLiteral.identity = "function-literal:84"
functionLiteral.semanticType = functionType
functionLiteral.children = [functionSignature, functionBody]
Local functionArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
functionArtifact.identity = runtimeIdentity
functionArtifact.body = functionLiteral
Local functionRevisionDiagnostics:String[]
functionArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(functionArtifact, functionRevisionDiagnostics)
Local functionEncodeDiagnostics:String[]
Local functionEncoded:String = TGenericTemplateArtifactCodec.Encode(functionArtifact, functionEncodeDiagnostics)
Local functionDecoded:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(functionEncoded, functionArtifact.contentRevision)
Check(functionRevisionDiagnostics.length = 0 And functionEncodeDiagnostics.length = 0 And functionDecoded.Succeeded() And functionDecoded.artifact.body.kind = TEMPLATE_NODE_FUNCTION_LITERAL And functionDecoded.artifact.body.identity = "function-literal:84" And functionDecoded.artifact.body.semanticType.kind = TEMPLATE_TYPE_CALLABLE And functionDecoded.artifact.body.children.length = 2 And functionDecoded.artifact.body.children[0].valueText = "function-literal-signature" And functionDecoded.artifact.body.children[0].children[0].identity = GENERIC_TEMPLATE_PARAMETER_PASS_VAR And functionDecoded.artifact.body.children[0].children[0].valueText = "value", "format-27 round-trip retains thin callable types, Var parameter modes and non-capturing Function literal bodies")
Local functionHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(functionArtifact, 26, functionHistoricalDiagnostics).length And functionHistoricalDiagnostics[0].StartsWith("BMXGT142"), "format-26 publication cannot silently discard thin Function literal bodies")

Local sizeType:TTemplateTypeReference = New TTemplateTypeReference
sizeType.kind = TEMPLATE_TYPE_BUILTIN
sizeType.symbolName = "Size_T"
Local releaseValue:TGenericTemplateNode = New TGenericTemplateNode
releaseValue.kind = TEMPLATE_NODE_NAME
releaseValue.valueText = "handle"
releaseValue.semanticType = sizeType
Local releaseStatement:TGenericTemplateNode = New TGenericTemplateNode
releaseStatement.kind = TEMPLATE_NODE_RELEASE
releaseStatement.semanticType = sizeType
releaseStatement.children = [releaseValue]
Local releaseArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
releaseArtifact.identity = runtimeIdentity
releaseArtifact.body = releaseStatement
Local releaseRevisionDiagnostics:String[]
releaseArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(releaseArtifact, releaseRevisionDiagnostics)
Local releaseEncodeDiagnostics:String[]
Local releaseEncoded:String = TGenericTemplateArtifactCodec.Encode(releaseArtifact, releaseEncodeDiagnostics)
Local releaseDecoded:TGenericTemplateArtifactDecodeResult = TGenericTemplateArtifactCodec.Decode(releaseEncoded, releaseArtifact.contentRevision)
Check(releaseRevisionDiagnostics.length = 0 And releaseEncodeDiagnostics.length = 0 And releaseDecoded.Succeeded() And releaseDecoded.artifact.body.kind = TEMPLATE_NODE_RELEASE And releaseDecoded.artifact.body.children.length = 1 And releaseDecoded.artifact.body.children[0].semanticType.symbolName = "Size_T", "format-29 round-trip retains a source-free Release statement and its addressable integer operand")
Local releaseHistoricalDiagnostics:String[]
Check(Not EncodeHistorical(releaseArtifact, 28, releaseHistoricalDiagnostics).length And releaseHistoricalDiagnostics[0].StartsWith("BMXGT143"), "format-28 publication cannot silently discard Release statements")

persistedReturn.kind = 999
Local unknownNodeDiagnostics:String[]
TGenericTemplateArtifactCodec.ComputeContentRevision(persistedArtifact, unknownNodeDiagnostics)
Check(unknownNodeDiagnostics.length = 1 And unknownNodeDiagnostics[0].StartsWith("BMXGT124"), "unknown required semantic node kind cannot be published")
persistedReturn.kind = TEMPLATE_NODE_RETURN

persistedLoopControl.identity = ""
Local missingControlIdentityDiagnostics:String[]
TGenericTemplateArtifactCodec.ComputeContentRevision(persistedArtifact, missingControlIdentityDiagnostics)
Check(missingControlIdentityDiagnostics.length = 1 And missingControlIdentityDiagnostics[0].StartsWith("BMXGT124"), "format-5 loop control cannot be published without semantic target identity")
persistedLoopControl.identity = "loop0"

Print "bcc2 generic-template-model tests passed"
