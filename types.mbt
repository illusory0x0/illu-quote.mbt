///|
pub typealias @path.Path

///|
pub(all) struct SourceLocation {
  path : Path
  start : Position
  end : Position
} derive(Show, ToJson)

///|
pub suberror ParseSourceLocationError {
  ParseError(String)
} derive(Show, ToJson)
