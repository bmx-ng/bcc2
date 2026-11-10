SuperStrict

Framework BRL.StandardIO

Global observedPath:String
Global observedAnchor:String
Global observedArgumentCount:Int
Global generatedCalls:Int
Global observedFirst:Int

Type TResult
End Type

Function Load<T>:T(url:String) Where T Extends Object
	Local result:T = New T
	Local path:String, arguments:String[], anchor:String
	Local separator:Int = url.Find("#")
	If separator <> -1
		anchor = url[separator + 1..]
		url = url[..separator]
	End If
	separator = url.Find("?")
	If separator = -1
		path = url
		arguments = New String[0]
	Else
		path = url[..separator]
		arguments = url[separator + 1..].Split("&")
	End If
	observedFirst = path[0]
	observedPath = path
	observedAnchor = anchor
	observedArgumentCount = arguments.Length
	Return result
End Function

Function GeneratedText:String()
	generatedCalls :+ 1
	Return "value"
End Function

Function SliceGenerated<T>:String()
	Return GeneratedText()[1..]
End Function

Local loaded:TResult = Load<TResult>("root?one&two#tail")
If Not loaded Then Throw "generic construction failed"
Local middle:String = SliceGenerated<Object>()
Print observedPath + "|" + observedAnchor + "|" + observedArgumentCount + "|" + observedFirst + "|" + middle + "|" + generatedCalls
