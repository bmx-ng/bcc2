' Copyright (c) 2026 Bruce A Henderson and contributors
' SPDX-License-Identifier: Zlib

SuperStrict
Framework BRL.StandardIO
Import BlitzMax.Format
Import BlitzMax.LSP
Import BRL.TextStream

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Function ObjectFrom:TJSONObject(value:String)
	Local error:TJSONError
	Return TJSONObject(TJSON.Load(value, 0, error))
End Function

Function SameTokens:Int(left:String, right:String)
	Local leftTokens:TSyntaxToken[] = TBlitzMaxLexer.Lex(left).tokens
	Local rightTokens:TSyntaxToken[] = TBlitzMaxLexer.Lex(right).tokens
	If leftTokens.length <> rightTokens.length Then Return False
	For Local index:Int = 0 Until leftTokens.length
		If leftTokens[index].kind <> rightTokens[index].kind Or leftTokens[index].text <> rightTokens[index].text Then Return False
	Next
	Return True
End Function

Function SameNonLayoutTokens:Int(left:String, right:String)
	Local leftTokens:TSyntaxToken[] = TBlitzMaxLexer.Lex(left).tokens
	Local rightTokens:TSyntaxToken[] = TBlitzMaxLexer.Lex(right).tokens
	Local leftIndex:Int
	Local rightIndex:Int
	While leftIndex < leftTokens.length And rightIndex < rightTokens.length
		While leftIndex < leftTokens.length And leftTokens[leftIndex].kind = TOKEN_NEWLINE; leftIndex :+ 1; Wend
		While rightIndex < rightTokens.length And rightTokens[rightIndex].kind = TOKEN_NEWLINE; rightIndex :+ 1; Wend
		If leftIndex = leftTokens.length Or rightIndex = rightTokens.length Then Exit
		If leftTokens[leftIndex].kind <> rightTokens[rightIndex].kind Or leftTokens[leftIndex].text <> rightTokens[rightIndex].text Then Return False
		leftIndex :+ 1
		rightIndex :+ 1
	Wend
	Return leftIndex = leftTokens.length And rightIndex = rightTokens.length
End Function

Function MultilineLiteral:String(value:String)
	For Local token:TSyntaxToken = EachIn TBlitzMaxLexer.Lex(value).tokens
		If token.kind = TOKEN_MULTILINE_STRING_LITERAL Then Return token.text
	Next
	Throw "expected a multiline string token"
End Function

Function Formatted:String(original:String, thenStyle:String = "preserve", endStyle:String = "preserve", inlineIfStyle:String = "preserve", tabSize:Int = 4, insertSpaces:Int = False, formatIndent:Int = False, spaceAfterComma:Int = True, caseIndent:String = "indented", metadataBraceSpacing:String = "preserve", callParenSpacing:String = "preserve", assignmentSpacing:String = "preserve", binarySpacing:String = "preserve", trimTrailingWhitespace:Int = True, declarationBlankLines:String = "preserve", controlBlankLines:String = "preserve")
	Local options:TBlitzMaxFormatOptions = New TBlitzMaxFormatOptions
	options.thenStyle = thenStyle
	options.endStyle = endStyle
	options.inlineIfStyle = inlineIfStyle
	options.tabSize = tabSize
	options.insertSpaces = insertSpaces
	options.indent = formatIndent
	options.spaceAfterComma = spaceAfterComma
	options.caseIndent = caseIndent
	options.metadataBraceSpacing = metadataBraceSpacing
	options.callParenSpacing = callParenSpacing
	options.assignmentSpacing = assignmentSpacing
	options.binarySpacing = binarySpacing
	options.trimTrailingWhitespace = trimTrailingWhitespace
	options.declarationBlankLines = declarationBlankLines
	options.controlBlankLines = controlBlankLines
	Return TBlitzMaxFormatter.Query(original, "format-test.bmx", options).Apply(original)
End Function

Local body:String = "SuperStrict~nFunction Probe:Int(value:Int)~nIf value > 0~nReturn value~nElseIf value < 0 Then~nReturn -value~nEnd If~nEnd Function~n"
Local added:String = "SuperStrict~nFunction Probe:Int(value:Int)~nIf value > 0 Then~nReturn value~nElseIf value < 0 Then~nReturn -value~nEnd If~nEnd Function~n"
Check(Formatted(body, "add") = added, "Then is added only to the multiline If header")
Check(Formatted(added, "remove") = "SuperStrict~nFunction Probe:Int(value:Int)~nIf value > 0~nReturn value~nElseIf value < 0~nReturn -value~nEnd If~nEnd Function~n", "Then is removed from If and ElseIf headers")
Check(TBlitzMaxParser.ParseText(Formatted(added, "remove")).syntaxTree.diagnostics.length = 0, "headers without Then still parse")
Check(Formatted(body) = body, "default style preserves existing headers")
Check(Formatted(added, "add") = added, "adding Then is idempotent")
Check(Formatted(Formatted(added, "remove"), "remove") = Formatted(added, "remove"), "removing Then is idempotent")
Check(Formatted("SuperStrict~nIf True ' reason~nPrint ~qyes~q~nEnd If~n", "add") = "SuperStrict~nIf True Then ' reason~nPrint ~qyes~q~nEnd If~n", "Then is inserted before a header comment")
Check(Formatted("SuperStrict~nIf ~q😀~q = ~q😀~q~nPrint ~qyes~q~nEnd If~n", "add") = "SuperStrict~nIf ~q😀~q = ~q😀~q Then~nPrint ~qyes~q~nEnd If~n", "edit positions account for UTF-16 characters")

Local endings:String = "SuperStrict~nFunction Probe()~nIf True Then~nPrint ~qEnd Function~q ' End If~nEnd If~nEnd Function~n"
Local combined:String = "SuperStrict~nFunction Probe()~nIf True Then~nPrint ~qEnd Function~q ' End If~nEndIf~nEndFunction~n"
Check(Formatted(endings, "preserve", "combined") = combined, "combined endings change syntax tokens without touching strings or comments")
Check(Formatted(combined, "preserve", "spaced") = endings, "spaced endings reverse combined endings")
Check(Formatted(combined, "preserve", "combined") = combined, "combined style is idempotent")
Check(Formatted("SuperStrict~nFunction Probe()~nEnd    Function~n", "preserve", "combined") = "SuperStrict~nFunction Probe()~nEndFunction~n", "combined style handles extra horizontal whitespace")
Check(Formatted("SuperStrict~nFunction Probe()~nEndFunction~n", "preserve", "spaced") = "SuperStrict~nFunction Probe()~nEnd Function~n", "spaced style splits a combined token")

Local inline:String = "SuperStrict~nIf True Then Print ~qhello~q~n"
Check(Formatted(inline, "remove") = inline, "inline If keeps required Then")
Local expanded:String = "SuperStrict~nIf True Then~n~tPrint ~qhello~q~nEnd If~n"
Check(Formatted(inline, "preserve", "preserve", "expand") = expanded, "simple inline If expands into a block")
Check(Formatted(inline, "remove", "combined", "expand", 2, True) = "SuperStrict~nIf True~n  Print ~qhello~q~nEndIf~n", "expansion follows Then, ending, and indentation choices")
Check(Formatted(expanded, "preserve", "preserve", "expand") = expanded, "expanded inline If is idempotent")
Check(TBlitzMaxParser.ParseText(expanded).syntaxTree.diagnostics.length = 0, "expanded inline If parses")
Local beforeAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(inline, "before.bmx")
Local afterAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(expanded, "after.bmx")
Check(beforeAnalysis.model.diagnostics.length = afterAnalysis.model.diagnostics.length, "inline expansion preserves the semantic diagnostic count")
For Local index:Int = 0 Until beforeAnalysis.model.diagnostics.length
	Check(beforeAnalysis.model.diagnostics[index].code = afterAnalysis.model.diagnostics[index].code, "inline expansion preserves semantic diagnostic codes")
Next
Check(Formatted("SuperStrict~nIf True Then Print ~qyes~q Else Print ~qno~q~n", "preserve", "preserve", "expand") = "SuperStrict~nIf True Then Print ~qyes~q Else Print ~qno~q~n", "inline Else stays unchanged")
Check(Formatted("SuperStrict~nIf True Then Print ~qyes~q ' comment~n", "preserve", "preserve", "expand") = "SuperStrict~nIf True Then Print ~qyes~q ' comment~n", "trailing comments block expansion")
Check(Formatted("SuperStrict~nIf True Then Print ~qyes~q; Print ~qmore~q~n", "preserve", "preserve", "expand") = "SuperStrict~nIf True Then Print ~qyes~q; Print ~qmore~q~n", "multiple inline statements stay unchanged")
Check(Formatted("SuperStrict~r~nIf True Then Print ~qyes~q~r~n", "preserve", "preserve", "expand") = "SuperStrict~r~nIf True Then~r~n~tPrint ~qyes~q~r~nEnd If~r~n", "inline expansion retains CRLF")
Local malformed:String = "SuperStrict~nFunction Broken:Int(~nEnd Function~n"
Check(Formatted(malformed, "remove", "combined") = malformed, "malformed source is left untouched")
Local crlf:String = "SuperStrict~r~nFunction Probe()~r~nIf True~r~nPrint ~qhello~q~r~nEnd If~r~nEnd Function~r~n"
Check(Formatted(crlf, "add", "combined") = "SuperStrict~r~nFunction Probe()~r~nIf True Then~r~nPrint ~qhello~q~r~nEndIf~r~nEndFunction~r~n", "CRLF is preserved")

Local unindented:String = "SuperStrict~nFunction Probe()~nIf True Then~nPrint ~qyes~q~nElse~nPrint ~qno~q~nEnd If~nEnd Function~n"
Local indented:String = "SuperStrict~nFunction Probe()~n~tIf True Then~n~t~tPrint ~qyes~q~n~tElse~n~t~tPrint ~qno~q~n~tEnd If~nEnd Function~n"
Check(Formatted(unindented, "preserve", "preserve", "preserve", 4, False, True) = indented, "nested If bodies, Else, and closing lines are indented from syntax")
Check(Formatted(indented, "preserve", "preserve", "preserve", 4, False, True) = indented, "indentation is idempotent")
Local spacesIndented:String = "SuperStrict~nFunction Probe()~n  If True Then~n    Print ~qyes~q~n  Else~n    Print ~qno~q~n  End If~nEnd Function~n"
Check(Formatted(unindented, "preserve", "preserve", "preserve", 2, True, True) = spacesIndented, "indentation follows space width")
Local typeSource:String = "SuperStrict~nType TProbe~nMethod Run()~nPrint ~qx~q~nEnd Method~nEnd Type~n"
Check(Formatted(typeSource, "preserve", "preserve", "preserve", 4, False, True) = "SuperStrict~nType TProbe~n~tMethod Run()~n~t~tPrint ~qx~q~n~tEnd Method~nEnd Type~n", "Type and Method nesting is indented")
Local selectSource:String = "SuperStrict~nSelect 1~nCase 1~nPrint ~qone~q~nDefault~nPrint ~qother~q~nEnd Select~n"
Check(Formatted(selectSource, "preserve", "preserve", "preserve", 4, False, True) = "SuperStrict~nSelect 1~n~tCase 1~n~t~tPrint ~qone~q~n~tDefault~n~t~tPrint ~qother~q~nEnd Select~n", "Select clauses and their bodies have separate levels")
Local alignedSelect:String = "SuperStrict~nSelect 1~nCase 1~n~tPrint ~qone~q~nDefault~n~tPrint ~qother~q~nEnd Select~n"
Check(Formatted(selectSource, "preserve", "preserve", "preserve", 4, False, True, True, "aligned") = alignedSelect, "aligned Case and Default share the Select level")
Check(Formatted(alignedSelect, "preserve", "preserve", "preserve", 4, False, True, True, "aligned") = alignedSelect, "aligned Select layout is idempotent")
Check(SameTokens(selectSource, alignedSelect), "aligned Select layout preserves all tokens")
Local nestedSelect:String = "SuperStrict~nFunction Probe()~nSelect 1~nCase 1~nSelect 2~nCase 2~nPrint ~qx~q~nDefault~nPrint ~qy~q~nEnd Select~nDefault~nPrint ~qz~q~nEnd Select~nEnd Function~n"
Local nestedIndented:String = "SuperStrict~nFunction Probe()~n~tSelect 1~n~t~tCase 1~n~t~t~tSelect 2~n~t~t~t~tCase 2~n~t~t~t~t~tPrint ~qx~q~n~t~t~t~tDefault~n~t~t~t~t~tPrint ~qy~q~n~t~t~tEnd Select~n~t~tDefault~n~t~t~tPrint ~qz~q~n~tEnd Select~nEnd Function~n"
Local nestedAligned:String = "SuperStrict~nFunction Probe()~n~tSelect 1~n~tCase 1~n~t~tSelect 2~n~t~tCase 2~n~t~t~tPrint ~qx~q~n~t~tDefault~n~t~t~tPrint ~qy~q~n~t~tEnd Select~n~tDefault~n~t~tPrint ~qz~q~n~tEnd Select~nEnd Function~n"
Check(Formatted(nestedSelect, "preserve", "preserve", "preserve", 4, False, True) = nestedIndented, "nested indented Select clauses count every case level")
Check(Formatted(nestedSelect, "preserve", "preserve", "preserve", 4, False, True, True, "aligned") = nestedAligned, "nested aligned Select clauses retain one body level")
Check(TBlitzMaxParser.ParseText(nestedAligned).syntaxTree.diagnostics.length = 0, "nested aligned Select still parses")
Check(SameTokens(nestedSelect, nestedAligned), "nested aligned Select preserves all tokens")
Check(Formatted(nestedAligned, "preserve", "preserve", "preserve", 4, False, True, True, "aligned") = nestedAligned, "nested aligned Select is idempotent")
Local caseInline:String = "SuperStrict~nSelect 1~nCase 1~nIf True Then Print ~qx~q~nEnd Select~n"
Local caseInlineExpanded:String = "SuperStrict~nSelect 1~nCase 1~n~tIf True Then~n~t~tPrint ~qx~q~n~tEnd If~nEnd Select~n"
Check(Formatted(caseInline, "preserve", "preserve", "expand", 4, False, True, True, "aligned") = caseInlineExpanded, "inline If expansion follows aligned Case indentation")
Check(Formatted(caseInlineExpanded, "preserve", "preserve", "expand", 4, False, True, True, "aligned") = caseInlineExpanded, "inline expansion within aligned Case is idempotent")
Local loopSource:String = "SuperStrict~nFunction Probe()~nFor Local index:Int = 0 Until 2~nWhile True~nExit~nWend~nNext~nEnd Function~n"
Check(Formatted(loopSource, "preserve", "preserve", "preserve", 4, False, True) = "SuperStrict~nFunction Probe()~n~tFor Local index:Int = 0 Until 2~n~t~tWhile True~n~t~t~tExit~n~t~tWend~n~tNext~nEnd Function~n", "nested For and While blocks indent and close at matching levels")
Local comments:String = "SuperStrict~nFunction Probe()~n' deliberate comment indent~nPrint ~qx~q~nEnd Function~n"
Check(Formatted(comments, "preserve", "preserve", "preserve", 4, False, True) = "SuperStrict~nFunction Probe()~n' deliberate comment indent~n~tPrint ~qx~q~nEnd Function~n", "comment-only lines are preserved")
Local blockComment:String = "SuperStrict~nFunction Probe()~nRem~n  comment body~nEnd Rem~nPrint ~qx~q~nEnd Function~n"
Check(Formatted(blockComment, "preserve", "preserve", "preserve", 4, False, True) = "SuperStrict~nFunction Probe()~nRem~n  comment body~nEnd Rem~n~tPrint ~qx~q~nEnd Function~n", "block comment layout is preserved")
Local nestedInline:String = "SuperStrict~nFunction Probe()~nIf True Then Print ~qx~q~nEnd Function~n"
Check(Formatted(nestedInline, "preserve", "preserve", "expand", 4, False, True) = "SuperStrict~nFunction Probe()~n~tIf True Then~n~t~tPrint ~qx~q~n~tEnd If~nEnd Function~n", "inline expansion and indentation produce non-overlapping edits")
Check(Formatted(Formatted(nestedInline, "preserve", "preserve", "expand", 4, False, True), "preserve", "preserve", "expand", 4, False, True) = Formatted(nestedInline, "preserve", "preserve", "expand", 4, False, True), "inline expansion and indentation are idempotent together")
Local crlfIndent:String = "SuperStrict~r~nFunction Probe()~r~nPrint ~qx~q~r~nEnd Function~r~n"
Check(Formatted(crlfIndent, "preserve", "preserve", "preserve", 4, False, True) = "SuperStrict~r~nFunction Probe()~r~n~tPrint ~qx~q~r~nEnd Function~r~n", "indentation preserves CRLF")

Local trailingSource:String = "SuperStrict  ~nFunction Probe() ~t~nPrint ~qx~q  ~t~n' comment ~t~n  ~t~nEnd Function~t~n"
Local trailingFormatted:String = "SuperStrict~nFunction Probe()~nPrint ~qx~q~n' comment~n~nEnd Function~n"
Check(Formatted(trailingSource) = trailingFormatted, "trailing spaces and tabs are removed from code, comments, and blank lines")
Check(Formatted(trailingSource, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "preserve", False) = trailingSource, "trailing whitespace trimming can be disabled")
Check(SameTokens(trailingSource, trailingFormatted), "trailing whitespace trimming preserves code tokens")
Check(Formatted(trailingFormatted) = trailingFormatted, "trailing whitespace trimming is idempotent")
Local trailingCrlf:String = "SuperStrict 	~r~nPrint ~qx~q ~t~r~n"
Check(Formatted(trailingCrlf) = "SuperStrict~r~nPrint ~qx~q~r~n", "trailing whitespace trimming preserves CRLF")
Local trailingThen:String = "SuperStrict~nIf True  ~t~nPrint ~qx~q~nEnd If~n"
Local trimmedThen:String = "SuperStrict~nIf True Then~nPrint ~qx~q~nEnd If~n"
Check(Formatted(trailingThen, "add") = trimmedThen, "Then insertion consumes trailing whitespace in one edit")
Check(Formatted(trimmedThen, "add") = trimmedThen, "Then insertion with trailing trimming is idempotent")
Check(Formatted("SuperStrict~nIf True Then Print ~qx~q  ~n", "preserve", "preserve", "expand") = "SuperStrict~nIf True Then~n~tPrint ~qx~q~nEnd If~n", "inline If expansion removes trailing whitespace without overlapping edits")
Local trailingBlockComment:String = "SuperStrict~nRem~n  preserve these spaces  ~nEnd Rem~nPrint ~qx~q  ~n"
Check(Formatted(trailingBlockComment) = "SuperStrict~nRem~n  preserve these spaces  ~nEnd Rem~nPrint ~qx~q~n", "block-comment layout is preserved while following code is trimmed")
Local trailingMultiline:String = "SuperStrict~nLocal message:String = ~q~q~q  ~n  value  ~n    ~q~q~q  ~nPrint message  ~n"
Local trailingMultilineFormatted:String = "SuperStrict~nLocal message:String = ~q~q~q  ~n  value  ~n    ~q~q~q  ~nPrint message~n"
Check(Formatted(trailingMultiline) = trailingMultilineFormatted, "all physical lines of a multiline string retain trailing whitespace")
Check(MultilineLiteral(Formatted(trailingMultiline)) = MultilineLiteral(trailingMultiline), "trailing trimming leaves multiline string bytes identical")
Local trailingPragma:String = "SuperStrict~n'@bmk addccopt -DKEEP  ~nPrint ~qx~q  ~n"
Check(TBlitzMaxParser.ParseText(trailingPragma).syntaxTree.diagnostics.length = 0, "pragma trailing-whitespace fixture parses")
Check(Formatted(trailingPragma) = "SuperStrict~n'@bmk addccopt -DKEEP  ~nPrint ~qx~q~n", "pragma token text is preserved while ordinary code is trimmed")

Local multiline:String = "SuperStrict~nFunction Probe()~nLocal message:String = ~q~q~q~n      If True Then~n    End Function~n  ' literal, comment~n      ~q~q~q~nPrint message~nEnd Function~n"
Local multilineFormatted:String = "SuperStrict~nFunction Probe()~nLocal message:String = ~q~q~q~n      If True Then~n    End Function~n  ' literal, comment~n      ~q~q~q~n~tPrint message~nEndFunction~n"
Local multilineResult:String = Formatted(multiline, "add", "combined", "expand", 4, False, True)
Check(multilineResult = multilineFormatted, "formatting leaves all multiline string lines untouched while formatting later code")
Check(MultilineLiteral(multilineResult) = MultilineLiteral(multiline), "multiline string token bytes stay identical")
Check(TBlitzMaxParser.ParseText(multilineResult).syntaxTree.diagnostics.length = 0, "formatted multiline string still parses")
Check(Formatted(multilineResult, "add", "combined", "expand", 4, False, True) = multilineResult, "formatting around a multiline string is idempotent")
Local multilineCrlf:String = "SuperStrict~r~nFunction Probe()~r~nLocal message:String = ~q~q~q~r~n  text~r~n    ~q~q~q~r~nPrint message~r~nEnd Function~r~n"
Local multilineCrlfResult:String = Formatted(multilineCrlf, "preserve", "preserve", "preserve", 4, False, True)
Check(MultilineLiteral(multilineCrlfResult) = MultilineLiteral(multilineCrlf), "CRLF multiline string token bytes stay identical")
Check(multilineCrlfResult = "SuperStrict~r~nFunction Probe()~r~nLocal message:String = ~q~q~q~r~n  text~r~n    ~q~q~q~r~n~tPrint message~r~nEnd Function~r~n", "CRLF multiline string lines remain untouched")

' A trailing .. continues the same statement, while the same characters in
' a slice expression have a different meaning. Preserve both token streams.
Local continued:String = "SuperStrict~nFunction Probe()~nIf True And ..~n    True Then~nPrint ~qyes~q~nEnd If~nEnd Function~n"
Local continuedFormatted:String = Formatted(continued, "preserve", "preserve", "preserve", 4, False, True)
Check(continuedFormatted = "SuperStrict~nFunction Probe()~n~tIf True And ..~n    True Then~n~t~tPrint ~qyes~q~n~tEnd If~nEnd Function~n", "continuation line layout is preserved while surrounding blocks are indented")
Check(SameTokens(continued, continuedFormatted), "line continuation token stream is unchanged")
Check(TBlitzMaxParser.ParseText(continuedFormatted).syntaxTree.diagnostics.length = 0, "formatted line continuation still parses")
Check(Formatted(continuedFormatted, "preserve", "preserve", "preserve", 4, False, True) = continuedFormatted, "line continuation formatting is idempotent")
Local tightContinuation:String = continued.Replace("And ..", "And..")
Check(TBlitzMaxParser.ParseText(tightContinuation).syntaxTree.diagnostics.length = 0, "tight line continuation fixture parses")
Check(Formatted(tightContinuation, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "spaced") = tightContinuation, "binary spacing leaves the trailing continuation marker untouched")
Local sliceExpression:String = "SuperStrict~nFunction Probe:String(value:String)~nReturn value[..1]~nEnd Function~n"
Local sliceFormatted:String = Formatted(sliceExpression, "preserve", "preserve", "preserve", 4, False, True)
Check(sliceFormatted = "SuperStrict~nFunction Probe:String(value:String)~n~tReturn value[..1]~nEnd Function~n", "slice punctuation is not treated as a line continuation")
Check(SameTokens(sliceExpression, sliceFormatted), "slice expression token stream is unchanged")

Local commaSource:String = "SuperStrict~nFunction Pair:Int(first:Int,second:Int)~nReturn first + second~nEnd Function~nLocal result:Int = Pair(1,  2)~nPrint ~qa,b~q ' comma, in comment~n"
Local commaFormatted:String = "SuperStrict~nFunction Pair:Int(first:Int, second:Int)~nReturn first + second~nEnd Function~nLocal result:Int = Pair(1, 2)~nPrint ~qa,b~q ' comma, in comment~n"
Check(Formatted(commaSource) = commaFormatted, "commas in parameter and argument lists get one following space")
Check(SameTokens(commaSource, commaFormatted), "comma spacing preserves the token stream, including string literals")
Check(Formatted(commaSource, "preserve", "preserve", "preserve", 4, False, False, False) = commaSource, "comma spacing can be disabled")
Check(Formatted(commaFormatted) = commaFormatted, "comma spacing is idempotent")
Local wrappedArguments:String = "SuperStrict~nFunction Pair:Int(first:Int, second:Int)~nReturn first + second~nEnd Function~nLocal result:Int = Pair(1,~n  2)~n"
Check(Formatted(wrappedArguments) = wrappedArguments, "comma spacing leaves wrapped argument indentation unchanged")
Check(TBlitzMaxParser.ParseText(wrappedArguments).syntaxTree.diagnostics.length = 0, "wrapped argument fixture parses")
Local inlineComma:String = "SuperStrict~nIf True Then Print String.FromInt(1,2)~n"
Local expandedComma:String = "SuperStrict~nIf True Then~n~tPrint String.FromInt(1, 2)~nEnd If~n"
Check(Formatted(inlineComma, "preserve", "preserve", "expand") = expandedComma, "inline If expansion includes comma spacing in its single edit")
Check(Formatted(expandedComma, "preserve", "preserve", "expand") = expandedComma, "inline expansion with comma spacing is idempotent")

Local delimiterSource:String = "SuperStrict~nFunction Probe:Int( value:Int ) {nomangle}~nReturn value~nEnd Function~nLocal result:Int = Probe( 1 )~nPrint ~qProbe( 1 ), {nomangle}~q~n"
Local delimiterCompact:String = "SuperStrict~nFunction Probe:Int( value:Int ) {nomangle}~nReturn value~nEnd Function~nLocal result:Int = Probe(1)~nPrint ~qProbe( 1 ), {nomangle}~q~n"
Local delimiterSpaced:String = "SuperStrict~nFunction Probe:Int( value:Int ) { nomangle }~nReturn value~nEnd Function~nLocal result:Int = Probe( 1 )~nPrint ~qProbe( 1 ), {nomangle}~q~n"
Check(Formatted(delimiterSource) = delimiterSource, "delimiter styles preserve existing layout by default")
Check(Formatted(delimiterSource, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "compact") = delimiterCompact, "compact call style excludes declaration parentheses")
Check(Formatted(delimiterSource, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "spaced", "preserve") = delimiterSpaced, "spaced metadata style excludes strings and calls")
Check(Formatted(delimiterCompact, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "spaced", "spaced") = delimiterSpaced, "spaced call style restores inner call spaces")
Check(SameTokens(delimiterSource, delimiterCompact) And SameTokens(delimiterSource, delimiterSpaced), "delimiter spacing preserves all tokens")
Check(TBlitzMaxParser.ParseText(delimiterCompact).syntaxTree.diagnostics.length = 0, "compact delimiter layout parses")
Check(Formatted(delimiterSpaced, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "spaced", "spaced") = delimiterSpaced, "delimiter spacing is idempotent")
Local emptyCall:String = "SuperStrict~nFunction Probe()~nEnd Function~nProbe()~n"
Check(Formatted(emptyCall, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "spaced") = emptyCall, "empty call parentheses remain compact")
Local wrappedCall:String = "SuperStrict~nFunction Probe:Int(value:Int)~nReturn value~nEnd Function~nLocal result:Int = Probe(~n  1)~n"
Check(Formatted(wrappedCall, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "spaced") = wrappedCall, "wrapped call parentheses retain line layout")
Local inlineDelimiter:String = "SuperStrict~nFunction Probe:Int(value:Int)~nReturn value~nEnd Function~nIf Probe( 1 ) = 1 Then Print Probe( 2 )~n"
Local inlineDelimiterExpanded:String = "SuperStrict~nFunction Probe:Int(value:Int)~nReturn value~nEnd Function~nIf Probe(1) = 1 Then~n~tPrint Probe(2)~nEnd If~n"
Check(Formatted(inlineDelimiter, "preserve", "preserve", "expand", 4, False, False, True, "indented", "preserve", "compact") = inlineDelimiterExpanded, "inline If expansion includes delimiter spacing in header and body")
Check(Formatted(inlineDelimiterExpanded, "preserve", "preserve", "expand", 4, False, False, True, "indented", "preserve", "compact") = inlineDelimiterExpanded, "inline expansion with delimiter spacing is idempotent")
Local constructorSource:String = "SuperStrict~nType TCell~nField value:Int~nMethod New(value:Int)~nSelf.value = value~nEnd Method~nEnd Type~nLocal cell:TCell = New TCell( 1 )~n"
Local constructorCompact:String = "SuperStrict~nType TCell~nField value:Int~nMethod New(value:Int)~nSelf.value = value~nEnd Method~nEnd Type~nLocal cell:TCell = New TCell(1)~n"
Check(Formatted(constructorSource, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "compact") = constructorCompact, "constructor parentheses use call spacing style")
Check(SameTokens(constructorSource, constructorCompact), "constructor spacing preserves tokens")
Check(MultilineLiteral(Formatted(multiline, "add", "combined", "expand", 4, False, True, True, "indented", "spaced", "compact")) = MultilineLiteral(multiline), "delimiter styles leave multiline string bytes untouched")

Local operatorSource:String = "SuperStrict~nConst Limit:Int=10~nFunction Probe:Int(value:Int=1)~nLocal result:Int=1+2~nresult:+value*2~nIf result>=0 And result<Limit Then~nReturn -result~nEnd If~nEnd Function~n"
Local operatorSpaced:String = "SuperStrict~nConst Limit:Int = 10~nFunction Probe:Int(value:Int = 1)~nLocal result:Int = 1 + 2~nresult :+ value * 2~nIf result >= 0 And result < Limit Then~nReturn -result~nEnd If~nEnd Function~n"
Check(Formatted(operatorSource) = operatorSource, "operator spacing preserves source by default")
Check(Formatted(operatorSource, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "spaced", "spaced") = operatorSpaced, "assignment and binary operator spacing applies only to parsed operators")
Check(SameTokens(operatorSource, operatorSpaced), "operator spacing preserves the token stream")
Check(TBlitzMaxParser.ParseText(operatorSpaced).syntaxTree.diagnostics.length = 0, "spaced operators still parse")
Check(Formatted(operatorSpaced, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "spaced", "spaced") = operatorSpaced, "operator spacing is idempotent")
Check(Formatted(operatorSpaced, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "compact", "compact") = operatorSource, "compact assignment and binary spacing removes optional spaces")
Check(Formatted(operatorSource, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "compact", "compact") = operatorSource, "compact operator spacing is idempotent")
Local wordOperators:String = "SuperStrict~nIf True   And   False Then~nPrint 4   Mod   2~nEnd If~n"
Local compactWords:String = "SuperStrict~nIf True And False Then~nPrint 4 Mod 2~nEnd If~n"
Check(Formatted(wordOperators, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "compact") = compactWords, "compact style retains required spaces around word operators")
Check(SameTokens(wordOperators, compactWords), "word operator compaction preserves tokens")
Local independentOperators:String = "SuperStrict~nLocal value:Int=1+2~n"
Check(Formatted(independentOperators, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "spaced", "preserve") = "SuperStrict~nLocal value:Int = 1+2~n", "assignment spacing can be enabled independently")
Check(Formatted(independentOperators, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "spaced") = "SuperStrict~nLocal value:Int=1 + 2~n", "binary spacing can be enabled independently")
Local operatorHeader:String = "SuperStrict~nIf 1+2=3~nPrint ~qyes~q~nEnd If~n"
Check(Formatted(operatorHeader, "add", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "spaced") = "SuperStrict~nIf 1 + 2 = 3 Then~nPrint ~qyes~q~nEnd If~n", "Then insertion and binary spacing produce separate edits")
Local inlineOperator:String = "SuperStrict~nIf 1+2=3 Then Print 4*5~n"
Local expandedOperator:String = "SuperStrict~nIf 1 + 2 = 3 Then~n~tPrint 4 * 5~nEnd If~n"
Check(Formatted(inlineOperator, "preserve", "preserve", "expand", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "spaced") = expandedOperator, "inline If expansion includes binary spacing in header and body")
Check(Formatted(expandedOperator, "preserve", "preserve", "expand", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "spaced") = expandedOperator, "inline If operator spacing is idempotent")
Local compactInlineOperator:String = "SuperStrict~nIf 1+2=3 Then~n~tPrint 4*5~nEnd If~n"
Check(Formatted(expandedOperator, "preserve", "preserve", "expand", 4, False, False, True, "indented", "preserve", "preserve", "compact", "compact") = compactInlineOperator, "compact operators apply inside an expanded inline If")
Local combinedSpacing:String = "SuperStrict~nFunction Pair:Int(a:Int,b:Int)~nReturn a+b~nEnd Function~nIf Pair( 1+2,3 )=6 Then Print Pair( 4+5,6 )~n"
Local combinedSpacingExpanded:String = "SuperStrict~nFunction Pair:Int(a:Int, b:Int)~nReturn a + b~nEnd Function~nIf Pair(1 + 2, 3) = 6 Then~n~tPrint Pair(4 + 5, 6)~nEnd If~n"
Check(Formatted(combinedSpacing, "preserve", "preserve", "expand", 4, False, False, True, "indented", "preserve", "compact", "preserve", "spaced") = combinedSpacingExpanded, "comma, call, and binary spacing combine within an inline If expansion")
Check(Formatted(combinedSpacingExpanded, "preserve", "preserve", "expand", 4, False, False, True, "indented", "preserve", "compact", "preserve", "spaced") = combinedSpacingExpanded, "combined spacing and expansion are idempotent")
Check(MultilineLiteral(Formatted(multiline, "add", "combined", "expand", 4, False, True, True, "indented", "preserve", "preserve", "spaced", "spaced")) = MultilineLiteral(multiline), "operator spacing leaves multiline string bytes untouched")

Local declarationSource:String = "SuperStrict~nType TSample~nMethod First()~nEnd Method~nMethod Second()~nEnd Method~nEnd Type~nFunction Tail()~nEnd Function~nPrint ~qdone~q~n"
Local declarationOne:String = "SuperStrict~nType TSample~nMethod First()~nEnd Method~n~nMethod Second()~nEnd Method~nEnd Type~n~nFunction Tail()~nEnd Function~n~nPrint ~qdone~q~n"
Check(Formatted(declarationSource, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "one") = declarationOne, "one blank line follows completed declarations at the same level")
Check(Formatted(declarationOne, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "none") = declarationSource, "none removes blank lines after declarations")
Check(SameNonLayoutTokens(declarationSource, declarationOne), "declaration blank lines preserve non-layout tokens")
Check(Formatted(declarationOne, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "one") = declarationOne, "declaration blank lines are idempotent")
Local declarationWhitespace:String = "SuperStrict~nFunction First()~nEnd Function~n  ~t~nFunction Second()~nEnd Function~n"
Check(Formatted(declarationWhitespace, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "one") = "SuperStrict~nFunction First()~nEnd Function~n~nFunction Second()~nEnd Function~n", "blank line normalization and trailing whitespace removal do not overlap")
Local declarationMany:String = "SuperStrict~nFunction First()~nEnd Function~n~n~nFunction Second()~nEnd Function~n"
Check(Formatted(declarationMany, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "one") = "SuperStrict~nFunction First()~nEnd Function~n~nFunction Second()~nEnd Function~n", "one collapses multiple blank lines after declarations")
Local declarationComment:String = "SuperStrict~nFunction First()~nEnd Function~n' description of Second~nFunction Second()~nEnd Function~n"
Check(Formatted(declarationComment, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "one") = declarationComment, "comments between declarations keep their layout")
Local declarationCrLf:String = "SuperStrict~r~nFunction First()~r~nEnd Function~r~nFunction Second()~r~nEnd Function~r~n"
Check(Formatted(declarationCrLf, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "one") = "SuperStrict~r~nFunction First()~r~nEnd Function~r~n~r~nFunction Second()~r~nEnd Function~r~n", "declaration blank lines retain CRLF")

Local controlSource:String = "SuperStrict~nFunction Probe()~nIf True Then~nFor Local i:Int = 0 Until 1~nNext~nEnd If~nPrint ~qdone~q~nEnd Function~n"
Local controlOne:String = "SuperStrict~nFunction Probe()~nIf True Then~nFor Local i:Int = 0 Until 1~nNext~nEnd If~n~nPrint ~qdone~q~nEnd Function~n"
Check(Formatted(controlSource, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "preserve", "one") = controlOne, "control blank line separates next sibling but not nested closing lines")
Check(Formatted(controlOne, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "preserve", "none") = controlSource, "none removes blank lines after control blocks")
Check(Formatted(controlOne, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "preserve", "one") = controlOne, "control blank lines are idempotent")
Check(SameNonLayoutTokens(controlSource, controlOne), "control blank lines preserve non-layout tokens")
Local controlComment:String = "SuperStrict~nIf True Then~nPrint ~qx~q~nEnd If~n' keep with following statement~nPrint ~qy~q~n"
Check(Formatted(controlComment, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "preserve", "one") = controlComment, "comments after control blocks keep their layout")
Local controlTrailingComment:String = "SuperStrict~nIf True Then~nPrint ~qx~q~nEnd If ' finished~nPrint ~qy~q~n"
Check(Formatted(controlTrailingComment, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "preserve", "one") = "SuperStrict~nIf True Then~nPrint ~qx~q~nEnd If ' finished~n~nPrint ~qy~q~n", "blank line follows a closing line with a trailing comment")
Local controlCrLf:String = "SuperStrict~r~nIf True Then~r~nPrint ~qx~q~r~nEnd If~r~nPrint ~qy~q~r~n"
Check(Formatted(controlCrLf, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "preserve", "one") = "SuperStrict~r~nIf True Then~r~nPrint ~qx~q~r~nEnd If~r~n~r~nPrint ~qy~q~r~n", "control blank lines retain CRLF")
Local controlString:String = "SuperStrict~nIf True Then~nPrint ~qx~q~nEnd If~nLocal message:String = ~q~q~q~n~n  keep this blank line~n~q~q~q~n"
Local controlStringFormatted:String = Formatted(controlString, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "preserve", "one")
Check(MultilineLiteral(controlStringFormatted) = MultilineLiteral(controlString), "control blank lines leave multiline strings intact")
Check(controlStringFormatted = "SuperStrict~nIf True Then~nPrint ~qx~q~nEnd If~n~nLocal message:String = ~q~q~q~n~n  keep this blank line~n~q~q~q~n", "control blank line may precede a multiline string without changing it")
Local controlEndings:String[] = ["If True Then~nPrint ~qx~q~nEnd If", "For Local i:Int = 0 Until 1~nPrint i~nNext", "While True~nExit~nWend", "Repeat~nExit~nForever", "Select 1~nCase 1~nPrint ~qx~q~nEnd Select"]
For Local ending:String = EachIn controlEndings
	Local originalBlock:String = "SuperStrict~n" + ending + "~nPrint ~qafter~q~n"
	Local formattedBlock:String = Formatted(originalBlock, "preserve", "preserve", "preserve", 4, False, False, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "preserve", "one")
	Check(formattedBlock = "SuperStrict~n" + ending + "~n~nPrint ~qafter~q~n", "control blank line follows each supported ending: " + ending)
	Check(TBlitzMaxParser.ParseText(formattedBlock).syntaxTree.diagnostics.length = 0, "control ending still parses: " + ending)
Next

Local server:TBlitzMaxLspServer = New TBlitzMaxLspServer
Local initialize:TJSONObject = TJSONObject(ObjectFrom(server.HandlePayload("{~qjsonrpc~q:~q2.0~q,~qid~q:1,~qmethod~q:~qinitialize~q,~qparams~q:{}}")[0]).Get("result"))
Check(TJSONObject(initialize.Get("capabilities")).GetBool("documentFormattingProvider"), "server advertises document formatting")
Check(TJSONObject(initialize.Get("capabilities")).GetBool("documentRangeFormattingProvider"), "server advertises range formatting")
Local uri:String = "file:///tmp/format-test.bmx"
Local textDocument:TJSONObject = JsonObject()
textDocument.Set("uri", uri)
textDocument.Set("languageId", "blitzmax")
textDocument.Set("version", 1)
textDocument.Set("text", body)
Local openParams:TJSONObject = JsonObject()
openParams.Set("textDocument", textDocument)
Local openRequest:TJSONObject = JsonObject()
openRequest.Set("jsonrpc", "2.0")
openRequest.Set("method", "textDocument/didOpen")
openRequest.Set("params", openParams)
server.HandlePayload(openRequest.SaveString(JSON_COMPACT))
Local formatSettings:TJSONObject = JsonObject()
formatSettings.Set("formatThenStyle", "add")
formatSettings.Set("formatIndent", False)
formatSettings.Set("formatSpaceAfterComma", False)
formatSettings.Set("formatCaseIndent", "aligned")
formatSettings.Set("formatMetadataBraceSpacing", "spaced")
formatSettings.Set("formatCallParenSpacing", "compact")
formatSettings.Set("formatAssignmentSpacing", "spaced")
formatSettings.Set("formatBinarySpacing", "spaced")
formatSettings.Set("formatTrimTrailingWhitespace", False)
formatSettings.Set("formatDeclarationBlankLines", "one")
formatSettings.Set("formatControlBlankLines", "none")
Local settingsRoot:TJSONObject = JsonObject()
settingsRoot.Set("blitzmax", formatSettings)
Local changeParams:TJSONObject = JsonObject()
changeParams.Set("settings", settingsRoot)
Local changeRequest:TJSONObject = JsonObject()
changeRequest.Set("jsonrpc", "2.0")
changeRequest.Set("method", "workspace/didChangeConfiguration")
changeRequest.Set("params", changeParams)
server.HandlePayload(changeRequest.SaveString(JSON_COMPACT))
Check(server.workspaces.adHoc.configuration.formatOptions.thenStyle = "add", "workspace settings reach the formatter")
Check(Not server.workspaces.adHoc.configuration.formatOptions.spaceAfterComma, "comma spacing setting reaches the formatter")
Check(server.workspaces.adHoc.configuration.formatOptions.caseIndent = "aligned", "Select indentation setting reaches the formatter")
Check(server.workspaces.adHoc.configuration.formatOptions.metadataBraceSpacing = "spaced", "metadata brace setting reaches the formatter")
Check(server.workspaces.adHoc.configuration.formatOptions.callParenSpacing = "compact", "call parentheses setting reaches the formatter")
Check(server.workspaces.adHoc.configuration.formatOptions.assignmentSpacing = "spaced", "assignment spacing setting reaches the formatter")
Check(server.workspaces.adHoc.configuration.formatOptions.binarySpacing = "spaced", "binary spacing setting reaches the formatter")
Check(Not server.workspaces.adHoc.configuration.formatOptions.trimTrailingWhitespace, "trailing whitespace setting reaches the formatter")
Check(server.workspaces.adHoc.configuration.formatOptions.declarationBlankLines = "one", "declaration blank-line setting reaches the formatter")
Check(server.workspaces.adHoc.configuration.formatOptions.controlBlankLines = "none", "control blank-line setting reaches the formatter")
Local copiedConfiguration:TLspWorkspaceConfiguration = server.workspaces.adHoc.configuration.Copy()
copiedConfiguration.formatOptions.thenStyle = "remove"
Check(server.workspaces.adHoc.configuration.formatOptions.thenStyle = "add", "workspace copies own their formatter options")
Local formatDocument:TJSONObject = JsonObject()
formatDocument.Set("uri", uri)
Local formatParams:TJSONObject = JsonObject()
formatParams.Set("textDocument", formatDocument)
Local formatOptions:TJSONObject = JsonObject()
formatOptions.Set("tabSize", 4)
formatOptions.Set("insertSpaces", False)
formatParams.Set("options", formatOptions)
Local formatRequest:TJSONObject = JsonObject()
formatRequest.Set("jsonrpc", "2.0")
formatRequest.Set("id", 2)
formatRequest.Set("method", "textDocument/formatting")
formatRequest.Set("params", formatParams)
Local formatResponse:TJSONObject = ObjectFrom(server.HandlePayload(formatRequest.SaveString(JSON_COMPACT))[0])
Check(TJSONArray(formatResponse.Get("result")).Size() = 1, "format request returns one Then insertion")
Local rangeStart:TJSONObject = JsonObject()
rangeStart.Set("line", 2)
rangeStart.Set("character", 0)
Local rangeEnd:TJSONObject = JsonObject()
rangeEnd.Set("line", 3)
rangeEnd.Set("character", 0)
Local formatRange:TJSONObject = JsonObject()
formatRange.Set("start", rangeStart)
formatRange.Set("end", rangeEnd)
formatParams.Set("range", formatRange)
formatRequest.Set("method", "textDocument/rangeFormatting")
formatRequest.Set("id", 3)
Local rangeResponse:TJSONObject = ObjectFrom(server.HandlePayload(formatRequest.SaveString(JSON_COMPACT))[0])
Check(TJSONArray(rangeResponse.Get("result")).Size() = 1, "selected If line receives its formatting edit")
rangeStart.Set("line", 0)
rangeEnd.Set("line", 1)
formatRequest.Set("id", 4)
rangeResponse = ObjectFrom(server.HandlePayload(formatRequest.SaveString(JSON_COMPACT))[0])
Check(TJSONArray(rangeResponse.Get("result")).Size() = 0, "range formatting leaves edits outside the selection alone")
Check(server.documents.Get(uri).text = body, "formatting does not mutate the open document")
Local delimiterUri:String = "file:///tmp/format-delimiter.bmx"
Local delimiterDocument:TJSONObject = JsonObject()
delimiterDocument.Set("uri", delimiterUri)
delimiterDocument.Set("languageId", "blitzmax")
delimiterDocument.Set("version", 1)
delimiterDocument.Set("text", delimiterSource)
Local delimiterOpenParams:TJSONObject = JsonObject()
delimiterOpenParams.Set("textDocument", delimiterDocument)
openRequest.Set("params", delimiterOpenParams)
server.HandlePayload(openRequest.SaveString(JSON_COMPACT))
formatDocument.Set("uri", delimiterUri)
formatRequest.Set("method", "textDocument/formatting")
formatRequest.Set("id", 5)
Local delimiterResponse:TJSONObject = ObjectFrom(server.HandlePayload(formatRequest.SaveString(JSON_COMPACT))[0])
Check(TJSONArray(delimiterResponse.Get("result")).Size() = 5, "LSP request applies configured brace, call, and declaration blank-line spacing")
Local corpusCount:Int
For Local index:Int = 1 Until AppArgs.length
	Local path:String = AppArgs[index]
	Local original:String = LoadText(path)
	Local before:TParseResult = TBlitzMaxParser.ParseText(original, path)
	If before.syntaxTree.diagnostics.length Then Continue
	Local rewritten:String = Formatted(original, "preserve", "preserve", "preserve", 4, False, True)
	Local after:TParseResult = TBlitzMaxParser.ParseText(rewritten, path)
	Check(after.syntaxTree.diagnostics.length = 0, "formatted corpus source still parses: " + path)
	Check(SameTokens(original, rewritten), "indentation preserves the complete token stream: " + path)
	Check(Formatted(rewritten, "preserve", "preserve", "preserve", 4, False, True) = rewritten, "corpus formatting is idempotent: " + path)
	For Local style:Int = 0 To 1
		Local braceStyle:String = "spaced"
		Local callStyle:String = "compact"
		If style Then braceStyle = "compact"; callStyle = "spaced"
		Local delimited:String = Formatted(original, "preserve", "preserve", "preserve", 4, False, True, True, "indented", braceStyle, callStyle)
		Check(TBlitzMaxParser.ParseText(delimited, path).syntaxTree.diagnostics.length = 0, "delimiter-formatted corpus source still parses: " + path)
		Check(SameTokens(original, delimited), "delimiter spacing preserves corpus tokens: " + path)
		Check(Formatted(delimited, "preserve", "preserve", "preserve", 4, False, True, True, "indented", braceStyle, callStyle) = delimited, "delimiter-formatted corpus is idempotent: " + path)
	Next
	Local operators:String = Formatted(original, "preserve", "preserve", "preserve", 4, False, True, True, "indented", "preserve", "preserve", "spaced", "spaced")
	Check(TBlitzMaxParser.ParseText(operators, path).syntaxTree.diagnostics.length = 0, "operator-formatted corpus source still parses: " + path)
	Check(SameTokens(original, operators), "operator spacing preserves corpus tokens: " + path)
	Check(Formatted(operators, "preserve", "preserve", "preserve", 4, False, True, True, "indented", "preserve", "preserve", "spaced", "spaced") = operators, "operator-formatted corpus is idempotent: " + path)
	Local blankLines:String = Formatted(original, "preserve", "preserve", "preserve", 4, False, True, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "one", "one")
	Check(TBlitzMaxParser.ParseText(blankLines, path).syntaxTree.diagnostics.length = 0, "blank-line formatted corpus source still parses: " + path)
	Check(SameNonLayoutTokens(original, blankLines), "blank-line formatting preserves non-layout tokens: " + path)
	Check(Formatted(blankLines, "preserve", "preserve", "preserve", 4, False, True, True, "indented", "preserve", "preserve", "preserve", "preserve", True, "one", "one") = blankLines, "blank-line formatted corpus is idempotent: " + path)
	Local compactOperators:String = Formatted(operators, "preserve", "preserve", "preserve", 4, False, True, True, "indented", "preserve", "preserve", "compact", "compact")
	Check(TBlitzMaxParser.ParseText(compactOperators, path).syntaxTree.diagnostics.length = 0, "compact operator corpus source still parses: " + path)
	Check(SameTokens(original, compactOperators), "compact operators preserve corpus tokens: " + path)
	Check(Formatted(compactOperators, "preserve", "preserve", "preserve", 4, False, True, True, "indented", "preserve", "preserve", "compact", "compact") = compactOperators, "compact operator corpus is idempotent: " + path)
	corpusCount :+ 1
Next
If AppArgs.length > 1 Then Check(corpusCount > 0, "corpus contains at least one parseable source")
Print "LSP formatting tests passed (" + corpusCount + " corpus files)"
