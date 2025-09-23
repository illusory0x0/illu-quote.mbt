///|
/// Helper function to create consistent parse error messages
fn create_parse_error(
  message : String,
  input : String,
) -> ParseSourceLocationError {
  ParseSourceLocationError::ParseError(
    "Invalid source location format: \{message} in '\{input}'",
  )
}

///|
/// Helper function to parse integer with error handling
fn parse_int_safe(
  value : String,
  name : String,
  input : String,
) -> Int raise ParseSourceLocationError {
  @strconv.parse_int(value) catch {
    _ => raise create_parse_error("invalid \{name} '\{value}'", input)
  }
}

///|
/// Helper function to validate positive integer
fn validate_positive(
  value : Int,
  name : String,
  input : String,
) -> Unit raise ParseSourceLocationError {
  if value <= 0 {
    raise create_parse_error("\{name} must be positive, got \{value}", input)
  }
}

///|
pub fn SourceLocation::parse(
  s : String,
) -> SourceLocation raise ParseSourceLocationError {
  // split two parts: path and position info
  // you should split this from the right, because paths may contain colons
  // e.g. `README.mbt.md:12:11-12:28`
  // e.g `/home/illu-quote.mbt/README.mbt.md:12:11-12:28`
  try {
    // Handle empty string
    if s.is_empty() {
      raise ParseSourceLocationError::ParseError("Empty source location string")
    }

    // We need to find the pattern :row:col-row:col at the end
    // Strategy: look for the last colon that's followed by a valid position pattern
    let mut position_start = -1
    let mut i = s.length() - 1

    // Work backwards to find a valid position pattern
    while i >= 0 {
      if s[i] == ':' {
        // Extract everything after this colon
        let candidate = s[i + 1:]

        // Check if this looks like a valid position (digits, colons, dashes only)
        let mut valid_position = true
        let mut has_content = false
        for j = 0; j < candidate.length(); j = j + 1 {
          let ch = candidate[j]
          if (ch >= '0' && ch <= '9') || ch == ':' || ch == '-' {
            has_content = true
          } else {
            valid_position = false
            break
          }
        }
        if valid_position && has_content {
          // Try to parse this as a position to see if it's valid
          let parts = candidate.split(":").collect()
          if parts.length() >= 2 {
            // Check if first part is all digits (row)
            let first_part = parts[0].to_string()
            let mut first_all_digits = true
            let mut first_has_digits = false
            for k = 0; k < first_part.length(); k = k + 1 {
              let ch = first_part[k]
              if ch >= '0' && ch <= '9' {
                first_has_digits = true
              } else {
                first_all_digits = false
                break
              }
            }
            if first_all_digits && first_has_digits {
              // Check if second part starts with digits (column)
              let second_part = parts[1].to_string()
              let dash_parts = second_part.split("-").collect()
              let col_part = dash_parts[0].to_string()
              let mut col_all_digits = true
              let mut col_has_digits = false
              for k = 0; k < col_part.length(); k = k + 1 {
                let ch = col_part[k]
                if ch >= '0' && ch <= '9' {
                  col_has_digits = true
                } else {
                  col_all_digits = false
                  break
                }
              }
              if col_all_digits && col_has_digits {
                position_start = i
                break
              }
            }
          }
        }
      }
      i = i - 1
    }
    if position_start == -1 {
      raise create_parse_error("no position information found", s)
    }

    // Extract path and position parts
    let path_str = s[0:position_start]
    let position_str = s[position_start + 1:]

    // Parse the path
    let path = @path.Path::parse(path_str)

    // Parse position string (format: row:column or row:column-endrow or row:column-endrow:endcol)
    let parts = position_str.split(":").collect()
    if parts.length() < 2 {
      raise create_parse_error("missing column information", s)
    }

    // Parse start row
    let start_row = parse_int_safe(parts[0].to_string(), "row number", s)
    validate_positive(start_row, "row number", s)

    // Parse start column (might include range)
    let col_part = parts[1].to_string()
    let dash_split = col_part.split("-").collect()
    let start_col = parse_int_safe(
      dash_split[0].to_string(),
      "column number",
      s,
    )
    validate_positive(start_col, "column number", s)
    let start_pos = Position::{ row: start_row, column: start_col }

    // Check for range
    if dash_split.length() == 1 {
      // No range, end is same as start
      SourceLocation::{ path, start: start_pos, end: start_pos }
    } else if dash_split.length() == 2 {
      let end_part = dash_split[1].to_string()
      if end_part.is_empty() {
        raise create_parse_error("empty range part", s)
      }

      // Check if we have more parts in the original split (for endrow:endcol case)
      if parts.length() == 2 {
        // Format is row:col-endrow
        let end_row = parse_int_safe(end_part, "end row number", s)
        validate_positive(end_row, "end row number", s)
        let end_pos = Position::{ row: end_row, column: start_col }
        SourceLocation::{ path, start: start_pos, end: end_pos }
      } else if parts.length() == 3 {
        // Format is row:col-endrow:endcol
        let end_row = parse_int_safe(end_part, "end row number", s)
        validate_positive(end_row, "end row number", s)
        let end_col = parse_int_safe(
          parts[2].to_string(),
          "end column number",
          s,
        )
        validate_positive(end_col, "end column number", s)
        let end_pos = Position::{ row: end_row, column: end_col }
        SourceLocation::{ path, start: start_pos, end: end_pos }
      } else {
        raise create_parse_error("invalid range format", s)
      }
    } else {
      raise create_parse_error("invalid range format", s)
    }
  } catch {
    ParseSourceLocationError::ParseError(_) as e => raise e
    _ as e =>
      raise ParseSourceLocationError::ParseError(
        "Unexpected error parsing source location '\{s}': \{e}",
      )
  }
}

///|
test {
  let s = "/home/illu-quote.mbt/README.mbt.md:12:11-12:28"
  let p = SourceLocation::parse(s)
  inspect(
    p,
    content="{path: /home/illu-quote.mbt/README.mbt.md, start: {row: 12, column: 11}, end: {row: 12, column: 28}}",
  )
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
