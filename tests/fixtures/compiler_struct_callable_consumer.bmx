SuperStrict
Framework BRL.Blitz

Import acme.structcallbacks

Local StaticArray cells:SBoundaryCell[2]
cells[0].value = 20
cells[1].value = 22

Local holder:TBoundaryBase = CreateBoundary()
Local callbackInterface:IBoundaryCallback = CreateBoundaryImplementation()

ActiveCells = OffsetCells
holder.callback = OffsetCells

Local total:Int = ActiveCells(cells)
total = total + holder.callback(cells)
total = total + holder.Apply(SumCells, cells)
total = total + callbackInterface.Apply(OffsetCells, cells)

If total = 215
	WriteStdout("bcc2 public Struct callable runtime ok~n")
End If
