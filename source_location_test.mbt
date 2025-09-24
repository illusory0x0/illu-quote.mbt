///|
/// Test basic parsing of source location with single position
test "parse basic source location" {
  let result = @quote.SourceLocation::parse("main.mbt:5:10")
  @json.inspect(result, content={
    "path": [
      "UPath",
      {
        "directory": ["Directory", []],
        "file": { "base": ["UnixPathComponent", "main"], "extension": "mbt" },
      },
    ],
    "start": { "row": 5, "column": 10 },
    "end": { "row": 5, "column": 10 },
  })
}

///|
/// Test parsing source location with range on same line
test "parse source location with range same line" {
  let result = @quote.SourceLocation::parse("src/hello.mbt:12:5-12:15")
  @json.inspect(result, content={
    "path": [
      "UPath",
      {
        "directory": ["Directory", [["UnixPathComponent", "src"]]],
        "file": { "base": ["UnixPathComponent", "hello"], "extension": "mbt" },
      },
    ],
    "start": { "row": 12, "column": 5 },
    "end": { "row": 12, "column": 15 },
  })
}

///|
/// Test parsing source location with range across different rows
test "parse source location with range different rows" {
  let result = @quote.SourceLocation::parse("lib/utils.mbt:8:3-15:7")
  @json.inspect(result, content={
    "path": [
      "UPath",
      {
        "directory": ["Directory", [["UnixPathComponent", "lib"]]],
        "file": { "base": ["UnixPathComponent", "utils"], "extension": "mbt" },
      },
    ],
    "start": { "row": 8, "column": 3 },
    "end": { "row": 15, "column": 7 },
  })
}

///|
/// Test parsing source location with complex path containing colons
test "parse source location with complex path" {
  let result = @quote.SourceLocation::parse(
    "/home/user/project:name/src/main.mbt:1:1-1:5",
  )
  @json.inspect(result, content={
    "path": [
      "UPath",
      {
        "directory": [
          "Directory",
          [
            ["UnixPathComponent", "home"],
            ["UnixPathComponent", "user"],
            ["UnixPathComponent", "project:name"],
            ["UnixPathComponent", "src"],
          ],
        ],
        "file": { "base": ["UnixPathComponent", "main"], "extension": "mbt" },
      },
    ],
    "start": { "row": 1, "column": 1 },
    "end": { "row": 1, "column": 5 },
  })
}

///|
/// Test parsing source location with Windows-style path
test "parse source location with windows path" {
  let result = @quote.SourceLocation::parse(
    "C:\\Users\\dev\\project\\main.mbt:10:20",
  )
  @json.inspect(result, content={
    "path": [
      "WPath",
      {
        "disk": "C",
        "directory": [
          "Directory",
          [
            ["WindowsPathComponent", "Users"],
            ["WindowsPathComponent", "dev"],
            ["WindowsPathComponent", "project"],
          ],
        ],
        "file": { "base": ["WindowsPathComponent", "main"], "extension": "mbt" },
      },
    ],
    "start": { "row": 10, "column": 20 },
    "end": { "row": 10, "column": 20 },
  })
}

///|
/// Test parsing source location with relative path
test "parse source location with relative path" {
  let result = @quote.SourceLocation::parse("./test/../src/main.mbt:7:2-7:8")
  @json.inspect(result, content={
    "path": [
      "UPath",
      {
        "directory": [
          "Directory",
          [
            ["UnixPathComponent", "."],
            ["UnixPathComponent", "test"],
            ["UnixPathComponent", ".."],
            ["UnixPathComponent", "src"],
          ],
        ],
        "file": { "base": ["UnixPathComponent", "main"], "extension": "mbt" },
      },
    ],
    "start": { "row": 7, "column": 2 },
    "end": { "row": 7, "column": 8 },
  })
}

///|
/// Test parsing source location with large numbers
test "parse source location with large numbers" {
  let result = @quote.SourceLocation::parse("big_file.mbt:1000:500-1001:600")
  @json.inspect(result, content={
    "path": [
      "UPath",
      {
        "directory": ["Directory", []],
        "file": {
          "base": ["UnixPathComponent", "big_file"],
          "extension": "mbt",
        },
      },
    ],
    "start": { "row": 1000, "column": 500 },
    "end": { "row": 1001, "column": 600 },
  })
}

///|
/// Test parsing source location with single digit positions
test "parse source location with single digits" {
  let result = @quote.SourceLocation::parse("a.mbt:1:1-2:3")
  @json.inspect(result, content={
    "path": [
      "UPath",
      {
        "directory": ["Directory", []],
        "file": { "base": ["UnixPathComponent", "a"], "extension": "mbt" },
      },
    ],
    "start": { "row": 1, "column": 1 },
    "end": { "row": 2, "column": 3 },
  })
}

///|
/// Test parsing empty string should fail
test "parse empty string fails" {
  let result = try? @quote.SourceLocation::parse("")
  inspect(result, content="Err(ParseError(\"Empty source location string\"))")
}

///|
/// Test parsing string with no position information
test "parse no position information fails" {
  let result = try? @quote.SourceLocation::parse("just_a_filename.mbt")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: no position information found in 'just_a_filename.mbt'\"))",
  )
}

///|
/// Test parsing string with invalid row (zero)
test "parse zero row fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:0:5")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: row number must be positive, got 0 in 'file.mbt:0:5'\"))",
  )
}

///|
/// Test parsing string with invalid row (negative)
test "parse negative row fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:-1:5")
  inspect(
    result,
    content=(
      #|Err(ParseError("Invalid source location format: no position information found in 'file.mbt:-1:5'"))
    ),
  )
}

///|
/// Test parsing string with invalid column (zero)
test "parse zero column fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:5:0")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: column number must be positive, got 0 in 'file.mbt:5:0'\"))",
  )
}

///|
/// Test parsing string with invalid column (negative)
test "parse negative column fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:5:-3")
  inspect(
    result,
    content=(
      #|Err(ParseError("Invalid source location format: no position information found in 'file.mbt:5:-3'"))
    ),
  )
}

///|
/// Test parsing string with non-numeric row
test "parse non-numeric row fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:abc:5")
  inspect(
    result,
    content=(
      #|Err(ParseError("Invalid source location format: no position information found in 'file.mbt:abc:5'"))
    ),
  )
}

///|
/// Test parsing string with non-numeric column
test "parse non-numeric column fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:5:xyz")
  inspect(
    result,
    content=(
      #|Err(ParseError("Invalid source location format: no position information found in 'file.mbt:5:xyz'"))
    ),
  )
}

///|
/// Test parsing string with missing column
test "parse missing column fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:5")
  inspect(
    result,
    content=(
      #|Err(ParseError("Invalid source location format: no position information found in 'file.mbt:5'"))
    ),
  )
}

///|
/// Test parsing string with empty range part
test "parse empty range part fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:5:10-")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: empty range part in 'file.mbt:5:10-'\"))",
  )
}

///|
/// Test parsing string with invalid end row
test "parse invalid end row fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:5:10-abc")
  inspect(
    result,
    content=(
      #|Err(ParseError("Invalid source location format: no position information found in 'file.mbt:5:10-abc'"))
    ),
  )
}

///|
/// Test parsing string with invalid end row (zero)
test "parse zero end row fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:5:10-0")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: end row number must be positive, got 0 in 'file.mbt:5:10-0'\"))",
  )
}

///|
/// Test parsing string with invalid end column
test "parse invalid end column fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:5:10-6:def")
  inspect(
    result,
    content=(
      #|Err(ParseError("Invalid source location format: no position information found in 'file.mbt:5:10-6:def'"))
    ),
  )
}

///|
/// Test parsing string with invalid end column (zero)
test "parse zero end column fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:5:10-6:0")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: end column number must be positive, got 0 in 'file.mbt:5:10-6:0'\"))",
  )
}

///|
/// Test parsing string with too many colons
test "parse too many colons fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:5:10-6:7:8")
  inspect(
    result,
    content="Ok({path: /file.mbt:5:10-6, start: {row: 7, column: 8}, end: {row: 7, column: 8}})",
  )
}

///|
/// Test parsing with just path and colon
test "parse path with trailing colon fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: no position information found in 'file.mbt:'\"))",
  )
}

///|
/// Test parsing with multiple dashes
test "parse multiple dashes fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:5:10-15-20")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: invalid range format in 'file.mbt:5:10-15-20'\"))",
  )
}

///|
/// Test parsing with letters in position
test "parse letters in position fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:5a:10")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: no position information found in 'file.mbt:5a:10'\"))",
  )
}

///|
/// Test parsing with spaces in position
test "parse spaces in position fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:5 :10")
  inspect(
    result,
    content="Err(ParseError(\"Invalid source location format: no position information found in 'file.mbt:5 :10'\"))",
  )
}

///|
/// Test parsing very long path with position
test "parse very long path" {
  let long_path = "/very/long/path/to/some/deeply/nested/directory/structure/with/many/levels/file.mbt"
  let input = "\{long_path}:42:13-42:25"
  let result = @quote.SourceLocation::parse(input)
  @json.inspect(result, content={
    "path": [
      "UPath",
      {
        "directory": [
          "Directory",
          [
            ["UnixPathComponent", "very"],
            ["UnixPathComponent", "long"],
            ["UnixPathComponent", "path"],
            ["UnixPathComponent", "to"],
            ["UnixPathComponent", "some"],
            ["UnixPathComponent", "deeply"],
            ["UnixPathComponent", "nested"],
            ["UnixPathComponent", "directory"],
            ["UnixPathComponent", "structure"],
            ["UnixPathComponent", "with"],
            ["UnixPathComponent", "many"],
            ["UnixPathComponent", "levels"],
          ],
        ],
        "file": { "base": ["UnixPathComponent", "file"], "extension": "mbt" },
      },
    ],
    "start": { "row": 42, "column": 13 },
    "end": { "row": 42, "column": 25 },
  })
}

///|
/// Test parsing file with special characters in name
test "parse file with special characters" {
  let result = @quote.SourceLocation::parse("my-file_test (v2.1).mbt:3:7")
  @json.inspect(result, content={
    "path": [
      "UPath",
      {
        "directory": ["Directory", []],
        "file": {
          "base": ["UnixPathComponent", "my-file_test (v2.1)"],
          "extension": "mbt",
        },
      },
    ],
    "start": { "row": 3, "column": 7 },
    "end": { "row": 3, "column": 7 },
  })
}

///|
/// Test parsing with range that ends on same column as start
test "parse range same column" {
  let result = @quote.SourceLocation::parse("file.mbt:5:10-7:10")
  @json.inspect(result, content={
    "path": [
      "UPath",
      {
        "directory": ["Directory", []],
        "file": { "base": ["UnixPathComponent", "file"], "extension": "mbt" },
      },
    ],
    "start": { "row": 5, "column": 10 },
    "end": { "row": 7, "column": 10 },
  })
}

///|
/// Test parsing with maximum typical values
test "parse maximum typical values" {
  let result = @quote.SourceLocation::parse("file.mbt:99999:999-99999:9999")
  @json.inspect(result, content={
    "path": [
      "UPath",
      {
        "directory": ["Directory", []],
        "file": { "base": ["UnixPathComponent", "file"], "extension": "mbt" },
      },
    ],
    "start": { "row": 99999, "column": 999 },
    "end": { "row": 99999, "column": 9999 },
  })
}

///|
/// Test parsing edge case from original test
test "parse original test case" {
  let s = "/home/illu-quote.mbt/README.mbt.md:12:11-12:28"
  let result = @quote.SourceLocation::parse(s)
  @json.inspect(result, content={
    "path": [
      "UPath",
      {
        "directory": [
          "Directory",
          [
            ["UnixPathComponent", "home"],
            ["UnixPathComponent", "illu-quote.mbt"],
          ],
        ],
        "file": {
          "base": ["UnixPathComponent", "README.mbt"],
          "extension": "md",
        },
      },
    ],
    "start": { "row": 12, "column": 11 },
    "end": { "row": 12, "column": 28 },
  })
}

///|
/// Test parsing string with valid digits then invalid character in column position
test "parse valid digits then invalid in column" {
  let result = try? @quote.SourceLocation::parse("file.mbt:5:10a")
  inspect(
    result,
    content=(
      #|Err(ParseError("Invalid source location format: no position information found in 'file.mbt:5:10a'"))
    ),
  )
}

///|
/// Test parsing range with four parts (too many)
test "parse range with four parts fails" {
  let result = try? @quote.SourceLocation::parse("file.mbt:5:10-6:7:8:9")
  inspect(
    result,
    content="Ok({path: /file.mbt:5:10-6:7, start: {row: 8, column: 9}, end: {row: 8, column: 9}})",
  )
}

///|
/// Test parsing that triggers missing column info path (should be unreachable but let's test)
test "parse internal missing column" {
  // This should be impossible to reach with current logic, but let's try edge cases
  let result = try? @quote.SourceLocation::parse("file.mbt:5:")
  inspect(
    result,
    content=(
      #|Err(ParseError("Invalid source location format: no position information found in 'file.mbt:5:'"))
    ),
  )
}

///|
/// Test edge case that could trigger the @strconv.parse_int error path
test "parse extremely large number" {
  // This should trigger parse_int error for values too large for Int
  let very_large = "99999999999999999999999999999999999999999999999"
  let input = "file.mbt:\{very_large}:10"
  let result = try? @quote.SourceLocation::parse(input)
  inspect(
    result,
    content=(
      #|Err(ParseError("Invalid source location format: invalid row number '99999999999999999999999999999999999999999999999' in 'file.mbt:99999999999999999999999999999999999999999999999:10'"))
    ),
  )
}

///|
/// Test another edge case for parse_int error with column
test "parse extremely large column number" {
  let very_large = "99999999999999999999999999999999999999999999999"
  let input = "file.mbt:5:\{very_large}"
  let result = try? @quote.SourceLocation::parse(input)
  inspect(
    result,
    content=(
      #|Err(ParseError("Invalid source location format: invalid column number '99999999999999999999999999999999999999999999999' in 'file.mbt:5:99999999999999999999999999999999999999999999999'"))
    ),
  )
}

///|
/// Test split_file with single line extraction
test "split_file single line basic" {
  let file_content = "hello world\nthis is line 2\nand line 3"
  let loc = @quote.SourceLocation::parse("test.mbt:1:7-1:12")
  let result = @quote.SourceLocation::split_file(file_content, [loc])
  inspect(result.length(), content="1")
  inspect(result[0].to_string(), content="world")
}

///|
/// Test split_file with multi-line extraction
test "split_file multi line basic" {
  let file_content = "line one\nline two\nline three\nline four"
  let loc = @quote.SourceLocation::parse("test.mbt:2:6-4:5")
  let result = @quote.SourceLocation::split_file(file_content, [loc])
  inspect(result.length(), content="1")
  inspect(result[0].to_string(), content="two\nline three\nline")
}

///|
/// Test split_file with multiple locations
test "split_file multiple locations" {
  let file_content = "first line\nsecond line\nthird line"
  let loc1 = @quote.SourceLocation::parse("test.mbt:1:1-1:5")
  let loc2 = @quote.SourceLocation::parse("test.mbt:3:7-3:11")
  let result = @quote.SourceLocation::split_file(file_content, [loc1, loc2])
  inspect(result.length(), content="2")
  inspect(result[0].to_string(), content="firs")
  inspect(result[1].to_string(), content="line")
}

///|
/// Test split_file with invalid row numbers (out of bounds)
test "split_file invalid row out of bounds" {
  let file_content = "line 1\nline 2\nline 3"
  // Create location manually for row 5 which is out of bounds
  let simple_path = @path.Path::parse("test.mbt")
  let loc = @quote.SourceLocation::{
    path: simple_path,
    start: @quote.Position::{ row: 5, column: 1 },
    end: @quote.Position::{ row: 5, column: 5 },
  }
  let result = @quote.SourceLocation::split_file(file_content, [loc])
  inspect(result.length(), content="1")
  inspect(result[0].to_string(), content="")
}

///|
/// Test split_file with zero or negative row
test "split_file invalid row zero or negative" {
  let file_content = "line 1\nline 2"
  let simple_path = @path.Path::parse("test.mbt")
  let loc1 = @quote.SourceLocation::{
    path: simple_path,
    start: @quote.Position::{ row: 0, column: 1 },
    end: @quote.Position::{ row: 1, column: 5 },
  }
  let loc2 = @quote.SourceLocation::{
    path: simple_path,
    start: @quote.Position::{ row: 1, column: 1 },
    end: @quote.Position::{ row: -1, column: 5 },
  }
  let result = @quote.SourceLocation::split_file(file_content, [loc1, loc2])
  inspect(result.length(), content="2")
  inspect(result[0].to_string(), content="")
  inspect(result[1].to_string(), content="")
}

///|
/// Test split_file with start row greater than end row
test "split_file start row greater than end row" {
  let file_content = "line 1\nline 2\nline 3"
  let simple_path = @path.Path::parse("test.mbt")
  let loc = @quote.SourceLocation::{
    path: simple_path,
    start: @quote.Position::{ row: 3, column: 1 },
    end: @quote.Position::{ row: 1, column: 5 },
  }
  let result = @quote.SourceLocation::split_file(file_content, [loc])
  inspect(result.length(), content="1")
  inspect(result[0].to_string(), content="")
}

///|
/// Test split_file with column out of bounds
test "split_file column out of bounds" {
  let file_content = "short\nlonger line\nshort"
  let loc = @quote.SourceLocation::parse("test.mbt:1:10-1:15")
  let result = @quote.SourceLocation::split_file(file_content, [loc])
  inspect(result.length(), content="1")
  inspect(result[0].to_string(), content="")
}

///|
/// Test split_file with start column greater than end column on same line
test "split_file start column greater than end column" {
  let file_content = "hello world"
  let simple_path = @path.Path::parse("test.mbt")
  let loc = @quote.SourceLocation::{
    path: simple_path,
    start: @quote.Position::{ row: 1, column: 8 },
    end: @quote.Position::{ row: 1, column: 5 },
  }
  let result = @quote.SourceLocation::split_file(file_content, [loc])
  inspect(result.length(), content="1")
  inspect(result[0].to_string(), content="")
}

///|
/// Test split_file with negative or zero column numbers
test "split_file negative or zero columns" {
  let file_content = "hello world\nsecond line"
  let simple_path = @path.Path::parse("test.mbt")
  let loc1 = @quote.SourceLocation::{
    path: simple_path,
    start: @quote.Position::{ row: 1, column: 0 },
    end: @quote.Position::{ row: 1, column: 5 },
  }
  let loc2 = @quote.SourceLocation::{
    path: simple_path,
    start: @quote.Position::{ row: 2, column: 3 },
    end: @quote.Position::{ row: 2, column: -1 },
  }
  let result = @quote.SourceLocation::split_file(file_content, [loc1, loc2])
  inspect(result.length(), content="2")
  // For start column 0, it should default to 1
  inspect(result[0].to_string(), content="hell")
  // For end column -1, it should default to end of line
  inspect(result[1].to_string(), content="cond line")
}

///|
/// Test split_file with end column beyond line length
test "split_file end column beyond line length" {
  let file_content = "short\nmiddle length\nvery long line here"
  let loc = @quote.SourceLocation::parse("test.mbt:1:2-1:100")
  let result = @quote.SourceLocation::split_file(file_content, [loc])
  inspect(result.length(), content="1")
  inspect(result[0].to_string(), content="hort")
}

///|
/// Test split_file with empty file content
test "split_file empty file" {
  let file_content = ""
  let loc = @quote.SourceLocation::parse("test.mbt:1:1-1:5")
  let result = @quote.SourceLocation::split_file(file_content, [loc])
  inspect(result.length(), content="1")
  inspect(result[0].to_string(), content="")
}

///|
/// Test split_file with empty locations array
test "split_file empty locations" {
  let file_content = "hello world\nsecond line"
  let result = @quote.SourceLocation::split_file(file_content, [])
  inspect(result.length(), content="0")
}

///|
/// Test split_file with single character extraction
test "split_file single character" {
  let file_content = "abcdef\nghijkl"
  let loc = @quote.SourceLocation::parse("test.mbt:1:3")
  let result = @quote.SourceLocation::split_file(file_content, [loc])
  inspect(result.length(), content="1")
  inspect(result[0].to_string(), content="")
}

///|
/// Test split_file extracting full lines
test "split_file full lines" {
  let file_content = "first line\nsecond line\nthird line"
  let loc = @quote.SourceLocation::parse("test.mbt:1:1-3:11")
  let result = @quote.SourceLocation::split_file(file_content, [loc])
  inspect(result.length(), content="1")
  inspect(result[0].to_string(), content="first line\nsecond line\nthird line")
}

///|
/// Test split_file with lines that have different lengths
test "split_file different line lengths" {
  let file_content = "a\nvery long line here\nc"
  let loc = @quote.SourceLocation::parse("test.mbt:1:1-3:1")
  let result = @quote.SourceLocation::split_file(file_content, [loc])
  inspect(result.length(), content="1")
  inspect(
    result[0].to_string(),
    content=(
      #|a
      #|very long line here
      #|
    ),
  )
}

///|
/// Test split_file with trailing newlines
test "split_file with trailing newlines" {
  let file_content = "line 1\nline 2\n\n"
  let loc = @quote.SourceLocation::parse("test.mbt:2:1-4:1")
  let result = @quote.SourceLocation::split_file(file_content, [loc])
  inspect(result.length(), content="1")
  inspect(result[0].to_string(), content="line 2\n\n")
}

///|
/// Test split_file with empty lines in the middle
test "split_file with empty lines" {
  let file_content = "line 1\n\nline 3\n\nline 5"
  let loc = @quote.SourceLocation::parse("test.mbt:1:5-5:3")
  let result = @quote.SourceLocation::split_file(file_content, [loc])
  inspect(result.length(), content="1")
  inspect(
    result[0].to_string(),
    content=(
      #| 1
      #|
      #|line 3
      #|
      #|li
    ),
  )
}

///|
/// Test split_file at exact line boundaries
test "split_file exact line boundaries" {
  let file_content = "hello\nworld\ntest"
  let loc1 = @quote.SourceLocation::parse("test.mbt:1:6-2:1")
  let loc2 = @quote.SourceLocation::parse("test.mbt:2:5-3:1")
  let result = @quote.SourceLocation::split_file(file_content, [loc1, loc2])
  inspect(result.length(), content="2")
  inspect(
    result[0].to_string(),
    content=(
      #|
      #|
    ),
  )
  inspect(
    result[1].to_string(),
    content=(
      #|d
      #|
    ),
  )
}

///|
/// Test split_file with complex multi-line scenario
test "split_file complex multi-line" {
  let file_content = "function test() {\n  let x = 5;\n  let y = 10;\n  return x + y;\n}"
  let loc = @quote.SourceLocation::parse("test.mbt:2:3-4:9")
  let result = @quote.SourceLocation::split_file(file_content, [loc])
  inspect(result.length(), content="1")
  inspect(result[0].to_string(), content="let x = 5;\n  let y = 10;\n  return")
}

///|
/// Test split_file edge case with start at line end
test "split_file start at line end" {
  let file_content = "hello\nworld"
  let loc = @quote.SourceLocation::parse("test.mbt:1:6-2:3")
  let result = @quote.SourceLocation::split_file(file_content, [loc])
  inspect(result.length(), content="1")
  inspect(result[0].to_string(), content="\nwo")
}
