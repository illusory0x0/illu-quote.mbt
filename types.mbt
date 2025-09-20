///|
pub(all) struct SourceLocation {
  path : AbsolutePath
  start : Position
  end : Position
} derive(Show, ToJson, @json.FromJson)

///|
struct AbsolutePath(FixedArray[String]) derive(ToJson, @json.FromJson)

///|
pub(all) struct Position {
  row : Int
  column : Int
} derive(Show, ToJson, @json.FromJson)

///|
pub fn AbsolutePath::op_get(self : Self, index : Int) -> String = "%fixedarray.get"

///|
pub fn AbsolutePath::op_set(self : Self, index : Int, value : String) -> Unit = "%fixedarray.set"

///|
pub fn AbsolutePath::length(self : Self) -> Int = "%fixedarray.length"

///|
pub impl Show for AbsolutePath with output(self, logger) {
  for s in self.0 {
    logger.write_char('/')
    logger.write_string(s)
  }
}

///|
pub fn AbsolutePath::from(components : Array[String]) -> AbsolutePath {
  AbsolutePath(components |> FixedArray::from_array)
}

///|
pub suberror ParseSourceLocationError {
  ParseError(String)
} derive(Show, ToJson, @json.FromJson)
