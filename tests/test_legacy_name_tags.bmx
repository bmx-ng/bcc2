' Copyright (c) 2026 Bruce A Henderson and contributors
' SPDX-License-Identifier: Zlib

SuperStrict

Framework BRL.StandardIO

Import BlitzMax.Language

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Local source:String = "Strict~nConst FileTypes$=~qbmx,txt~q~nConst FileTypeFilters$=~qCode Files:~q+FileTypes$+~q;All Files:*~q~nConst FileTypesCopy$=FileTypes$~nType THolder~nField value$~nEnd Type~nLocal holder:THolder = New THolder~nLocal member$ = holder.value$~nLocal number:Int = 12~nLocal ignoredStringSuffix:Int = number$~nLocal ignoredNumericSuffix:String = FileTypes%"
Local parsed:TParseResult = TBlitzMaxParser.ParseText(source, "legacy-name-tags.bmx")
Local model:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(parsed.syntaxTree)
TExpressionBinder.Bind(model)
Check(model.diagnostics.length = 0, "legacy type tags on name references parse and bind without diagnostics")

Local filterDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(parsed.syntaxTree.root.members[2])
Local filterSymbol:TSymbol = model.DeclaredSymbol(filterDeclaration.declarators[0])
Check(filterSymbol.declaredType = model.BuiltinType("String"), "legacy String tag supplies the declaration type")

Local copyDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(parsed.syntaxTree.root.members[3])
Local taggedName:TNameExpressionSyntax = TNameExpressionSyntax(copyDeclaration.declarators[0].initializer)
Check(taggedName <> Null And taggedName.nameToken.text = "FileTypes" And taggedName.legacyTypeTagToken.text = "$", "legacy name type tag is retained separately from the symbol name")
Check(taggedName.span.length = taggedName.nameToken.span.length + 1, "legacy name type tag participates in the expression span")
Check(model.ReferencedSymbol(taggedName).name = "FileTypes", "legacy name type tag resolves the base symbol")

Local memberDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(parsed.syntaxTree.root.members[6])
Local taggedMember:TMemberAccessExpressionSyntax = TMemberAccessExpressionSyntax(memberDeclaration.declarators[0].initializer)
Check(taggedMember <> Null And taggedMember.nameToken.text = "value" And taggedMember.legacyTypeTagToken.text = "$", "legacy member type tag is retained separately from the member name")
Check(model.ReferencedSymbol(taggedMember).name = "value", "legacy member type tag resolves the base member")

Local ignoredStringSuffixDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(parsed.syntaxTree.root.members[8])
Local ignoredStringSuffixName:TNameExpressionSyntax = TNameExpressionSyntax(ignoredStringSuffixDeclaration.declarators[0].initializer)
Check(ignoredStringSuffixName.legacyTypeTagToken.text = "$" And model.ExpressionType(ignoredStringSuffixName) = model.BuiltinType("Int"), "a legacy suffix on a reference does not change the referenced symbol type")
Local ignoredNumericSuffixDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(parsed.syntaxTree.root.members[9])
Local ignoredNumericSuffixName:TNameExpressionSyntax = TNameExpressionSyntax(ignoredNumericSuffixDeclaration.declarators[0].initializer)
Check(ignoredNumericSuffixName.legacyTypeTagToken.text = "%" And model.ExpressionType(ignoredNumericSuffixName) = model.BuiltinType("String"), "a mismatched legacy reference suffix remains semantically ignored")

Print "bcc2 legacy-name-tag tests passed"
