///|
pub(all) struct Position {
  row : Int
  column : Int
} derive(Show, ToJson, @json.FromJson)

///|
test "Position construction and access" {
  let pos = Position::{ row: 10, column: 5 }
  inspect(pos.row, content="10")
  inspect(pos.column, content="5")
  @json.inspect(pos, content={ "row": 10, "column": 5 })
}
