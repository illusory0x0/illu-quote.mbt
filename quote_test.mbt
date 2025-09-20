///|
test "Position construction and access" {
  let pos = Position::{ row: 10, column: 5 }
  inspect(pos.row, content="10")
  inspect(pos.column, content="5")
  @json.inspect(pos, content={ "row": 10, "column": 5 })
}

///|
test "AbsolutePath construction and operations" {
  let components = ["home", "user", "project", "src", "main.mbt"]
  let path = AbsolutePath::from(components)
  inspect(path.length(), content="5")
  inspect(path[0], content="home")
  inspect(path[4], content="main.mbt")

  // Test Show implementation
  inspect(path, content="/home/user/project/src/main.mbt")
}

///|
test "AbsolutePath mutation" {
  let components = ["tmp", "file.mbt"]
  let path = AbsolutePath::from(components)
  path[0] = "home"
  inspect(path[0], content="home")
  inspect(path, content="/home/file.mbt")
}

///|
test "SourceLocation::parse - valid simple format" {
  let input = "/path/to/file.mbt:10:5"
  let result = try? SourceLocation::parse(input)
  match result {
    Ok(loc) =>
      // Test that we can serialize the whole SourceLocation to JSON
      @json.inspect(loc, content={
        "path": ["AbsolutePath", ["path", "to", "file.mbt"]],
        "start": { "row": 10, "column": 5 },
        "end": { "row": 10, "column": 5 },
      })
    Err(e) => fail("Expected successful parse, got error: \{e}")
  }
}

///|
test "SourceLocation::parse - valid range format" {
  let input = "/path/to/file.mbt:10:5-15:20"
  let result = try? SourceLocation::parse(input)
  match result {
    Ok(loc) =>
      @json.inspect(loc, content={
        "path": ["AbsolutePath", ["path", "to", "file.mbt"]],
        "start": { "row": 10, "column": 5 },
        "end": { "row": 15, "column": 20 },
      })
    Err(e) => fail("Expected successful parse, got error: \{e}")
  }
}

///|
test "SourceLocation::parse - range with only end row" {
  let input = "/project/src/file.mbt:8:3-12"
  let result = try? SourceLocation::parse(input)
  match result {
    Ok(loc) =>
      @json.inspect(loc, content={
        "path": ["AbsolutePath", ["project", "src", "file.mbt"]],
        "start": { "row": 8, "column": 3 },
        "end": { "row": 12, "column": 3 },
      })
    Err(e) => fail("Expected successful parse, got error: \{e}")
  }
}

///|
test "SourceLocation::parse - Windows-style paths" {
  let input = "C:\\Users\\user\\project\\file.mbt:5:10"
  let result = try? SourceLocation::parse(input)
  match result {
    Ok(loc) =>
      @json.inspect(loc, content={
        "path": ["AbsolutePath", ["C:", "Users", "user", "project", "file.mbt"]],
        "start": { "row": 5, "column": 10 },
        "end": { "row": 5, "column": 10 },
      })
    Err(e) => fail("Expected successful parse, got error: \{e}")
  }
}

///|
test "SourceLocation::parse - mixed path separators" {
  let input = "/home/user\\project/src\\file.mbt:1:1-2:10"
  let result = try? SourceLocation::parse(input)
  match result {
    Ok(loc) =>
      @json.inspect(loc, content={
        "path": ["AbsolutePath", ["home", "user", "project", "src", "file.mbt"]],
        "start": { "row": 1, "column": 1 },
        "end": { "row": 2, "column": 10 },
      })
    Err(e) => fail("Expected successful parse, got error: \{e}")
  }
}

///|
test "SourceLocation::parse - complex paths with colons" {
  let input = "/path/with:colon/file.mbt:10:5"
  let result = try? SourceLocation::parse(input)
  match result {
    Ok(loc) =>
      @json.inspect(loc, content={
        "path": ["AbsolutePath", ["path", "with:colon", "file.mbt"]],
        "start": { "row": 10, "column": 5 },
        "end": { "row": 10, "column": 5 },
      })
    Err(e) => fail("Expected successful parse, got error: \{e}")
  }
}

///|
test "SourceLocation::parse - error cases empty string" {
  let result = try? SourceLocation::parse("")
  inspect(result, content="Err(ParseError(\"Empty source location string\"))")
}

///|
test "SourceLocation::parse - error cases no position info" {
  let result = try? SourceLocation::parse("/path/to/file.mbt")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: no position information found in '/path/to/file.mbt'\"))",
  )
}

///|
test "SourceLocation::parse - error cases missing column" {
  let result = try? SourceLocation::parse("/path/file.mbt:10")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: missing column information in '/path/file.mbt:10'\"))",
  )
}

///|
test "SourceLocation::parse - error cases invalid row number" {
  let result = try? SourceLocation::parse("/path/file.mbt:abc:5")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: missing column information in '/path/file.mbt:abc:5'\"))",
  )
}

///|
test "SourceLocation::parse - error cases zero row" {
  let result = try? SourceLocation::parse("/path/file.mbt:0:5")
  inspect(
    result,
    content=(
      #|Err(ParseError("Invalid source location format: missing column information in '/path/file.mbt:0:5'"))
    ),
  )
}

///|
test "SourceLocation::parse - error cases negative row" {
  let result = try? SourceLocation::parse("/path/file.mbt:-1:5")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: missing column information in '/path/file.mbt:-1:5'\"))",
  )
}

///|
test "SourceLocation::parse - error cases zero column" {
  let result = try? SourceLocation::parse("/path/file.mbt:10:0")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: no position information found in '/path/file.mbt:10:0'\"))",
  )
}

///|
test "SourceLocation::parse - error cases invalid column" {
  let result = try? SourceLocation::parse("/path/file.mbt:10:abc")
  inspect(
    result,
    content=(
      #|Err(ParseError("Invalid source location format: no position information found in '/path/file.mbt:10:abc'"))
    ),
  )
}

///|
test "SourceLocation::parse - error cases empty range" {
  let result = try? SourceLocation::parse("/path/file.mbt:10:5-")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: empty range part in '/path/file.mbt:10:5-'\"))",
  )
}

///|
test "SourceLocation::parse - error cases invalid end row" {
  let result = try? SourceLocation::parse("/path/file.mbt:10:5-abc:10")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: invalid end row number 'abc' in '/path/file.mbt:10:5-abc:10'\"))",
  )
}

///|
test "SourceLocation::parse - error cases zero end row" {
  let result = try? SourceLocation::parse("/path/file.mbt:10:5-0:10")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: end row number must be positive, got 0 in '/path/file.mbt:10:5-0:10'\"))",
  )
}

///|
test "SourceLocation::parse - error cases invalid end column" {
  let result = try? SourceLocation::parse("/path/file.mbt:10:5-15:abc")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: invalid end column number 'abc' in '/path/file.mbt:10:5-15:abc'\"))",
  )
}

///|
test "SourceLocation::parse - error cases zero end column" {
  let result = try? SourceLocation::parse("/path/file.mbt:10:5-15:0")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: end column number must be positive, got 0 in '/path/file.mbt:10:5-15:0'\"))",
  )
}

///|
test "SourceLocation::split_file - single line extraction" {
  let file_content = "line1\nhello world!\nline3\nline4\nline5"
  let loc = try! SourceLocation::parse("/test.mbt:2:7-2:12")
  let results = SourceLocation::split_file(file_content, [loc])
  inspect(results.length(), content="1")
  inspect(results[0].to_string(), content="world")
}

///|
test "SourceLocation::split_file - multi line extraction" {
  let file_content = "first line\nsecond line\nthird line\nfourth line"
  let loc = try! SourceLocation::parse("/test.mbt:2:3-4:6")
  let results = SourceLocation::split_file(file_content, [loc])
  inspect(results.length(), content="1")
  inspect(results[0].to_string(), content="cond line\nthird line\nfourt")
}

///|
test "SourceLocation::split_file - multiple locations" {
  let file_content = "abc\ndef\nghi\njkl"
  let loc1 = try! SourceLocation::parse("/test.mbt:1:1-1:3")
  let loc2 = try! SourceLocation::parse("/test.mbt:3:1-3:3")
  let results = SourceLocation::split_file(file_content, [loc1, loc2])
  inspect(results.length(), content="2")
  inspect(results[0].to_string(), content="ab")
  inspect(results[1].to_string(), content="gh")
}

///|
test "SourceLocation::split_file - out of bounds handling" {
  let file_content = "line1\nline2"
  let loc = try! SourceLocation::parse("/test.mbt:5:1-5:5") // Line doesn't exist
  let results = SourceLocation::split_file(file_content, [loc])
  inspect(results.length(), content="1")
  inspect(results[0].to_string(), content="")
}

///|
test "SourceLocation::split_file - column out of bounds" {
  let file_content = "short\nlonger line"
  let loc = try! SourceLocation::parse("/test.mbt:1:10-1:20") // Column beyond line length
  let results = SourceLocation::split_file(file_content, [loc])
  inspect(results.length(), content="1")
  inspect(results[0].to_string(), content="")
}

///|
test "SourceLocation::split_file - edge cases empty file" {
  let file_content = ""
  let loc = try! SourceLocation::parse("/test.mbt:1:1-1:1")
  let results = SourceLocation::split_file(file_content, [loc])
  inspect(results.length(), content="1")
  inspect(results[0].to_string(), content="")
}

///|
test "SourceLocation::split_file - whole line" {
  let file_content = "hello world\nsecond line"
  let loc = try! SourceLocation::parse("/test.mbt:1:1-1:12")
  let results = SourceLocation::split_file(file_content, [loc])
  inspect(results.length(), content="1")
  inspect(results[0].to_string(), content="hello world")
}

///|
test "ParseSourceLocationError - Show implementation via parse error" {
  let result = try? SourceLocation::parse("")
  match result {
    Err(error) =>
      inspect(error, content="ParseError(\"Empty source location string\")")
    Ok(_) => fail("Expected parse error")
  }
}

///|
test "ParseSourceLocationError - JSON serialization via parse error" {
  let result = try? SourceLocation::parse("")
  match result {
    Err(error) =>
      @json.inspect(error, content=[
        "ParseError", "Empty source location string",
      ])
    Ok(_) => fail("Expected parse error")
  }
}

///|
test "SourceLocation - Show trait implementation" {
  let loc = try! SourceLocation::parse("/complex/path/file.mbt:10:5-15:20")
  // Test Show implementation (can't access fields directly, so just ensure it doesn't crash)
  let string_repr = loc.to_string()
  inspect(string_repr.length() > 0, content="true")
}

///|
test "AbsolutePath - edge cases empty components" {
  let empty_components : Array[String] = []
  let path = AbsolutePath::from(empty_components)
  inspect(path.length(), content="0")
  inspect(path, content="")
}

///|
test "AbsolutePath - single component" {
  let single_component = ["file.mbt"]
  let path = AbsolutePath::from(single_component)
  inspect(path.length(), content="1")
  inspect(path[0], content="file.mbt")
  inspect(path, content="/file.mbt")
}
