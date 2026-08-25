SuperStrict

Framework BRL.StandardIO

Import Bcc2GenericInheritedMethod.Types

Type TConsumerStringClosureDerived Extends TPublishedGenericClosureBase<String>
	Method Transform:String(value:String) Override
		Return value + "-consumer"
	End Method
End Type

Local published:TPublishedStringClosureDerived = New TPublishedStringClosureDerived
published.stored = "published"
Local publishedCallback:Closure<String(value:String)> = published.Bind()
If publishedCallback("bound") <> "bound-published" Then Throw "module-owned derived Type lost inherited generic Method dispatch"
Local publishedInterface:IPublishedGenericClosureTransform<String> = published
If publishedInterface.Transform("interface") <> "interface-published" Then Throw "module-owned derived Interface table retained generic base implementation"

Local consumer:TConsumerStringClosureDerived = New TConsumerStringClosureDerived
consumer.stored = "consumer"
Local consumerCallback:Closure<String(value:String)> = consumer.Bind()
If consumerCallback("bound") <> "bound-consumer" Then Throw "consumer-owned derived Type lost imported generic Method dispatch"
Local consumerInterface:IPublishedGenericClosureTransform<String> = consumer
If consumerInterface.Transform("interface") <> "interface-consumer" Then Throw "consumer-owned derived Interface table retained generic base implementation"

Print "generic-inherited-closure-method-module-ok"
