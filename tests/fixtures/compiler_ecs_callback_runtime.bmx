SuperStrict

Framework BRL.StandardIO
Import Ecs.Flecs

Struct SProbePosition
	Field x:Int
End Struct

Global probeWorld:TEcsWorld = TEcsWorld.Create()
Global probePosition:SEcsComponent = probeWorld.RegisterComponent("ProbePosition", SizeOf(SProbePosition), AlignOf(SProbePosition))
probeWorld.RegisterStructMeta("SProbePosition", probePosition.id)
Global probeCalls:Int
Global probeRows:Int
Global probeValue:Int

probeWorld.RegisterSystem("Probe", EcsOnUpdate, [probePosition.id], ProbeSystem)

Local probeEntity:ULong = probeWorld.NewEntity()
Local probe:SProbePosition
probe.x = 42
probeWorld.SetComponent(probeEntity, probePosition, Varptr probe)

For Local frame:Int = 0 Until 3
	Local progressed:Int = probeWorld.Progress(1.0 / 60.0)
	Print "frame=" + frame + " progressed=" + progressed + " calls=" + probeCalls + " rows=" + probeRows + " value=" + probeValue
Next

Function ProbeSystem(iter:TEcsIter)
	probeCalls :+ 1
	probeRows :+ iter.Count()
	Local values:SProbePosition Ptr
	iter.Component(probePosition, 0, Varptr values)
	If iter.Count() Then probeValue = values[0].x
End Function
