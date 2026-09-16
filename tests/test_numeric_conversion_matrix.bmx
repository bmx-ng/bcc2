SuperStrict

Framework BRL.StandardIO
Import BlitzMax.Language

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
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

Print "numeric conversion matrix tests passed"
