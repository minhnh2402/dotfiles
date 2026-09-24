return {
  cmd = { "clangd", "--background-index", "--clang-tidy", "--compile-commands-dir=build"},
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  root_markers = {
    "compile_commands.json",
    "compile_flags.txt",
    ".clangd",
    ".git",
  },
}
