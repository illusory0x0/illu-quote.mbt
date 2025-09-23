///|
#callsite(autofill(loc))
pub fn[Code] quote(
  code : Code,
  loc~ : SourceLoc,
) -> SourceLocation raise ParseSourceLocationError {
  ignore(code)
  SourceLocation::parse(loc.to_string())
}

///|
#callsite(autofill(loc))
pub fn current_source_location(
  loc~ : SourceLoc,
) -> SourceLocation raise ParseSourceLocationError {
  SourceLocation::parse(loc.to_string())
}
