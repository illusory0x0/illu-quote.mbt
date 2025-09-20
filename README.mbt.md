# illusory0x0/quote 

The `quote` utility allows you to select code snippets from source files and returns a `SourceLocation`.

You can use this to read files and extract code snippets from them.

After that, you can manipulate the code snippets like Rust procedure macros.

```mbt
///|
test {
  let s = quote(x => x + 1)
  inspect(s.path[s.path.length() - 1], content="README.mbt.md")
  inspect(s.start, content="{row: 12, column: 11}")
  inspect(s.end, content="{row: 12, column: 28}")
  let s = current_source_location()
  inspect(s.path[s.path.length() - 1], content="README.mbt.md")
  inspect(s.start, content="{row: 16, column: 11}")
  inspect(s.end, content="{row: 16, column: 36}")
}
```