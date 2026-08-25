SuperStrict

Framework BRL.StandardIO

Function ConditionalMode<T>:Int()
?debug
	Return 100
?Not debug
	Return 200
?
End Function

Function ConditionalThreading<T>:Int()
?threaded
	Return 1
?Not threaded
	Return 2
?
End Function

Function ConditionalFeature<T>:Int()
?feature
	Return 10
?Not feature
	Return 20
?
End Function

Function ConditionalTarget<T>:Int()
?macos
	Return 1000
?linux
	Return 2000
?win32
	Return 3000
?
End Function

Print ConditionalMode<String>() + ConditionalThreading<String>() + ConditionalFeature<String>() + ConditionalTarget<String>()
