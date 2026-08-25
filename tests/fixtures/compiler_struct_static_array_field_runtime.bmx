SuperStrict

Struct SFieldCell
	Field number:Int = 5
	Field text:String

	Method Add(delta:Int)
		number = number + delta
	End Method
End Struct

Struct SFieldGrid
	Field StaticArray cells:SFieldCell[2]
	Field StaticArray counts:Int[3]
End Struct

Type TGridHolder
	Field grid:SFieldGrid
End Type

Function Mutate(value:SFieldCell Var, delta:Int)
	value.number = value.number + delta
End Function

Local grid:SFieldGrid
Local holder:TGridHolder = New TGridHolder
grid.cells[0].number = 20
grid.cells[0].Add(2)
Mutate(grid.cells[1], 3)
grid.counts[2] = grid.cells[0].number
holder.grid = grid
Local first:SFieldCell = grid.cells[0]
Local total:Int = first.number + grid.cells.length + grid.counts.length + holder.grid.cells[0].number

For Local item:SFieldCell = EachIn grid.cells
	total = total + item.number
Next
