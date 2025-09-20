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

///|
pub fn SourceLocation::parse(
  s : String,
) -> SourceLocation raise ParseSourceLocationError {
  // Parse strings like "/path/to/file.mbt:14:5-16:68" or "/path/to/file.mbt:14:5"
  // Raise error if format is not standard

  // Helper function to find the colon that separates path from line:col
  fn find_path_colon(str : String) -> Int {
    // Look for patterns like ":14:5" or ":14:5-" from the end
    // We want the first colon in such a pattern
    let mut i = 0
    while i < str.length() {
      if str[i] == ':' {
        // Check if this looks like ":line:col" pattern
        let mut j = i + 1
        let mut first_num = 0
        // Parse first number (line)
        while j < str.length() && str[j] >= '0' && str[j] <= '9' {
          first_num = first_num * 10 + (str[j] - '0')
          j += 1
        }
        if first_num > 0 && j < str.length() && str[j] == ':' {
          // We have ":number:", now check for second number (column)
          j += 1
          let mut second_num = 0
          while j < str.length() && str[j] >= '0' && str[j] <= '9' {
            second_num = second_num * 10 + (str[j] - '0')
            j += 1
          }
          if second_num > 0 && (j == str.length() || str[j] == '-') {
            // Found ":line:col" or ":line:col-", this is our path colon
            return i
          }
        } else if first_num > 0 && (j == str.length() || str[j] == '-') {
          // Found ":line" or ":line-", this is our path colon
          return i
        }
      }
      i += 1
    }
    -1
  }

  // Helper function to find first occurrence of a character in StringView
  fn find_char_view(str : StringView, ch : Char) -> Int {
    let mut i = 0
    while i < str.length() {
      if str.get_char(i) == Some(ch) {
        return i
      }
      i += 1
    }
    -1
  }

  // Helper function to split path by '/' or '\\' using Array as buffer
  fn split_path(path : String) -> Array[String] {
    let buffer : Array[String] = []
    let current : Array[Char] = []
    for char in path {
      if char == '/' || char == '\\' {
        if current.length() > 0 {
          buffer.push(String::from_iter(current.iter()))
          current.clear()
        }
      } else {
        current.push(char)
      }
    }

    // Add the last component if exists
    if current.length() > 0 {
      buffer.push(String::from_iter(current.iter()))
    }
    buffer
  }

  // Check if string is empty or only whitespace
  if s.length() == 0 {
    raise ParseSourceLocationError::ParseError("Empty source location string")
  }
  let last_colon_pos = find_path_colon(s)
  if last_colon_pos == -1 {
    // Not in standard format - no position information found
    raise ParseSourceLocationError::ParseError(
      "Invalid source location format: no position information found in '\{s}'",
    )
  }

  // Extract path and position parts
  let path_result = s[0:last_colon_pos] catch {
    _ =>
      raise ParseSourceLocationError::ParseError(
        "Invalid source location format: failed to extract path from '\{s}'",
      )
  }
  let path = path_result.to_string()
  if path.length() == 0 {
    raise ParseSourceLocationError::ParseError(
      "Invalid source location format: empty path in '\{s}'",
    )
  }
  let path_components = split_path(path)
  let position_part_result = s[last_colon_pos + 1:] catch {
    _ =>
      raise ParseSourceLocationError::ParseError(
        "Invalid source location format: failed to extract position from '\{s}'",
      )
  }
  let position_part = position_part_result

  // Find the first ':' in position part for row:col separation
  let colon_pos = find_char_view(position_part, ':')
  if colon_pos == -1 {
    // Only row number, no column - this should have column for standard format
    let row_result = @strconv.parse_int(position_part) catch {
      _ =>
        raise ParseSourceLocationError::ParseError(
          "Invalid source location format: invalid row number '\{position_part}' in '\{s}'",
        )
    }
    let row = row_result
    if row <= 0 {
      raise ParseSourceLocationError::ParseError(
        "Invalid source location format: row number must be positive, got \{row} in '\{s}'",
      )
    }
    // For standard format, we expect both row and column
    raise ParseSourceLocationError::ParseError(
      "Invalid source location format: missing column information in '\{s}'",
    )
  }
  let start_row_str_result = position_part[0:colon_pos] catch {
    _ =>
      raise ParseSourceLocationError::ParseError(
        "Invalid source location format: failed to extract row from '\{s}'",
      )
  }
  let start_row_str = start_row_str_result
  let rest_result = position_part[colon_pos + 1:] catch {
    _ =>
      raise ParseSourceLocationError::ParseError(
        "Invalid source location format: failed to extract column from '\{s}'",
      )
  }
  let rest = rest_result

  // Find start column part (before '-' if present)
  let dash_pos = find_char_view(rest, '-')
  let start_col_str = if dash_pos == -1 {
    rest
  } else {
    let col_result = rest[0:dash_pos] catch {
      _ =>
        raise ParseSourceLocationError::ParseError(
          "Invalid source location format: failed to extract start column from '\{s}'",
        )
    }
    col_result
  }
  let start_row_result = @strconv.parse_int(start_row_str) catch {
    _ =>
      raise ParseSourceLocationError::ParseError(
        "Invalid source location format: invalid row number '\{start_row_str}' in '\{s}'",
      )
  }
  let start_row = start_row_result
  let start_col_result = @strconv.parse_int(start_col_str) catch {
    _ =>
      raise ParseSourceLocationError::ParseError(
        "Invalid source location format: invalid column number '\{start_col_str}' in '\{s}'",
      )
  }
  let start_col = start_col_result
  if start_row <= 0 {
    raise ParseSourceLocationError::ParseError(
      "Invalid source location format: row number must be positive, got \{start_row} in '\{s}'",
    )
  }
  if start_col <= 0 {
    raise ParseSourceLocationError::ParseError(
      "Invalid source location format: column number must be positive, got \{start_col} in '\{s}'",
    )
  }
  if dash_pos == -1 {
    // No range, end position same as start position
    return SourceLocation::{
      path: AbsolutePath::from(path_components),
      start: Position::{ row: start_row, column: start_col },
      end: Position::{ row: start_row, column: start_col },
    }
  }

  // Parse end position from range part
  let range_part_result = rest[dash_pos + 1:] catch {
    _ =>
      raise ParseSourceLocationError::ParseError(
        "Invalid source location format: failed to extract range part from '\{s}'",
      )
  }
  let range_part = range_part_result
  if range_part.length() == 0 {
    raise ParseSourceLocationError::ParseError(
      "Invalid source location format: empty range part in '\{s}'",
    )
  }
  let end_colon_pos = find_char_view(range_part, ':')
  if end_colon_pos == -1 {
    // Only end row, assume same column as start
    let end_row_result = @strconv.parse_int(range_part) catch {
      _ =>
        raise ParseSourceLocationError::ParseError(
          "Invalid source location format: invalid end row number '\{range_part}' in '\{s}'",
        )
    }
    let end_row = end_row_result
    if end_row <= 0 {
      raise ParseSourceLocationError::ParseError(
        "Invalid source location format: end row number must be positive, got \{end_row} in '\{s}'",
      )
    }
    return SourceLocation::{
      path: AbsolutePath::from(path_components),
      start: Position::{ row: start_row, column: start_col },
      end: Position::{ row: end_row, column: start_col },
    }
  }
  let end_row_str_result = range_part[0:end_colon_pos] catch {
    _ =>
      raise ParseSourceLocationError::ParseError(
        "Invalid source location format: failed to extract end row from '\{s}'",
      )
  }
  let end_row_str = end_row_str_result
  let end_col_str_result = range_part[end_colon_pos + 1:] catch {
    _ =>
      raise ParseSourceLocationError::ParseError(
        "Invalid source location format: failed to extract end column from '\{s}'",
      )
  }
  let end_col_str = end_col_str_result
  let end_row_result = @strconv.parse_int(end_row_str) catch {
    _ =>
      raise ParseSourceLocationError::ParseError(
        "Invalid source location format: invalid end row number '\{end_row_str}' in '\{s}'",
      )
  }
  let end_row = end_row_result
  let end_col_result = @strconv.parse_int(end_col_str) catch {
    _ =>
      raise ParseSourceLocationError::ParseError(
        "Invalid source location format: invalid end column number '\{end_col_str}' in '\{s}'",
      )
  }
  let end_col = end_col_result
  if end_row <= 0 {
    raise ParseSourceLocationError::ParseError(
      "Invalid source location format: end row number must be positive, got \{end_row} in '\{s}'",
    )
  }
  if end_col <= 0 {
    raise ParseSourceLocationError::ParseError(
      "Invalid source location format: end column number must be positive, got \{end_col} in '\{s}'",
    )
  }
  SourceLocation::{
    path: AbsolutePath::from(path_components),
    start: Position::{ row: start_row, column: start_col },
    end: Position::{ row: end_row, column: end_col },
  }
}

///|
pub fn SourceLocation::split_file(
  file : String,
  locs : Array[SourceLocation],
) -> Array[StringView] {
  // Split file content into lines
  let lines = file.split("\n").collect()
  let result : Array[StringView] = []
  for loc in locs {
    // Validate line numbers (1-indexed)
    if loc.start.row < 1 ||
      loc.start.row > lines.length() ||
      loc.end.row < 1 ||
      loc.end.row > lines.length() ||
      loc.start.row > loc.end.row {
      // Skip invalid locations, add empty StringView
      result.push("".to_string()[:])
      continue
    }

    // Handle single line case
    if loc.start.row == loc.end.row {
      let line = lines[loc.start.row - 1] // Convert to 0-indexed
      let start_col = if loc.start.column < 1 { 1 } else { loc.start.column }
      let end_col = if loc.end.column < 1 {
        line.length() + 1
      } else {
        loc.end.column
      }

      // Validate column bounds
      if start_col > line.length() + 1 {
        result.push("".to_string()[:])
        continue
      }
      let actual_end = if end_col > line.length() + 1 {
        line.length() + 1
      } else {
        end_col
      }
      let actual_start = start_col - 1 // Convert to 0-indexed
      let actual_end_idx = actual_end - 1 // Convert to 0-indexed
      if actual_start >= actual_end_idx {
        result.push("".to_string()[:])
      } else {
        result.push(try! line[actual_start:actual_end_idx])
      }
      continue
    }

    // Handle multi-line case
    let parts : Array[String] = []

    // First line: from start_col to end of line
    let first_line = lines[loc.start.row - 1]
    let start_col = if loc.start.column < 1 { 1 } else { loc.start.column }
    if start_col <= first_line.length() + 1 {
      let start_idx = start_col - 1 // Convert to 0-indexed
      let first_part = if start_idx < first_line.length() {
        (try! first_line[start_idx:]).to_string()
      } else {
        ""
      }
      parts.push(first_part)
    }

    // Middle lines: entire lines
    for i = loc.start.row + 1; i < loc.end.row; i = i + 1 {
      parts.push(lines[i - 1].to_string()) // Convert to 0-indexed and to String
    }

    // Last line: from beginning to end_col
    if loc.end.row > loc.start.row {
      let last_line = lines[loc.end.row - 1]
      let end_col = if loc.end.column < 1 {
        last_line.length() + 1
      } else {
        loc.end.column
      }
      let end_idx = if end_col > last_line.length() + 1 {
        last_line.length()
      } else {
        end_col - 1
      }
      let last_part = if end_idx > 0 {
        (try! last_line[0:end_idx]).to_string()
      } else {
        ""
      }
      parts.push(last_part)
    }

    // Join parts with newlines and convert to StringView
    let combined_content = parts.join("\n")
    result.push(combined_content[:])
  }
  result
}

///|
test "path splitting works correctly" {
  // Test Unix-style path
  let unix_path = "/home/user/project/src/main.mbt:10:5-15:20"
  let unix_loc = SourceLocation::parse(unix_path)
  inspect(unix_loc.path, content="/home/user/project/src/main.mbt")

  // Test Windows-style path
  let windows_path = "C:\\Users\\user\\project\\src\\main.mbt:10:5"
  let windows_loc = SourceLocation::parse(windows_path)
  inspect(windows_loc.path, content="/C:/Users/user/project/src/main.mbt")

  // Test mixed separators
  let mixed_path = "/home/user\\project/src\\main.mbt:10:5"
  let mixed_loc = SourceLocation::parse(mixed_path)
  inspect(mixed_loc.path, content="/home/user/project/src/main.mbt")
}

///|
test "parse error handling" {
  // Test empty string
  let empty_result = try? SourceLocation::parse("")
  inspect(
    empty_result,
    content="Err(ParseError(\"Empty source location string\"))",
  )

  // Test string without position information
  let no_pos_result = try? SourceLocation::parse("/path/to/file.mbt")
  inspect(
    no_pos_result,
    content="Err(ParseError(\"Invalid source location format: no position information found in '/path/to/file.mbt'\"))",
  )

  // Test string with invalid row number
  let invalid_row_result = try? SourceLocation::parse("/path/file.mbt:abc:5")
  inspect(
    invalid_row_result,
    content=(
      #|Err(ParseError("Invalid source location format: missing column information in '/path/file.mbt:abc:5'"))
    ),
  )

  // Test string with negative row number
  let negative_row_result = try? SourceLocation::parse("/path/file.mbt:-1:5")
  inspect(
    negative_row_result,
    content=(
      #|Err(ParseError("Invalid source location format: missing column information in '/path/file.mbt:-1:5'"))
    ),
  )

  // Test string with zero column number
  let zero_col_result = try? SourceLocation::parse("/path/file.mbt:10:0")
  inspect(
    zero_col_result,
    content=(
      #|Err(ParseError("Invalid source location format: no position information found in '/path/file.mbt:10:0'"))
    ),
  )

  // Test string missing column information
  let missing_col_result = try? SourceLocation::parse("/path/file.mbt:10")
  inspect(
    missing_col_result,
    content="Err(ParseError(\"Invalid source location format: missing column information in '/path/file.mbt:10'\"))",
  )

  // Test string with invalid range end
  let invalid_range_result = try? SourceLocation::parse(
      "/path/file.mbt:10:5-abc:10",
    )
  inspect(
    invalid_range_result,
    content="Err(ParseError(\"Invalid source location format: invalid end row number 'abc' in '/path/file.mbt:10:5-abc:10'\"))",
  )

  // Test string with empty range part
  let empty_range_result = try? SourceLocation::parse("/path/file.mbt:10:5-")
  inspect(
    empty_range_result,
    content="Err(ParseError(\"Invalid source location format: empty range part in '/path/file.mbt:10:5-'\"))",
  )
}

///|
test "parse valid formats" {
  // Test simple format (no range)
  let simple_result = try? SourceLocation::parse("/path/to/file.mbt:10:5")
  inspect(
    simple_result,
    content="Ok({path: /path/to/file.mbt, start: {row: 10, column: 5}, end: {row: 10, column: 5}})",
  )

  // Test range format with both row and column
  let range_result = try? SourceLocation::parse("/path/to/file.mbt:10:5-15:20")
  inspect(
    range_result,
    content="Ok({path: /path/to/file.mbt, start: {row: 10, column: 5}, end: {row: 15, column: 20}})",
  )

  // Test range format with only end row
  let row_range_result = try? SourceLocation::parse("/path/to/file.mbt:10:5-15")
  inspect(
    row_range_result,
    content="Ok({path: /path/to/file.mbt, start: {row: 10, column: 5}, end: {row: 15, column: 5}})",
  )
}
