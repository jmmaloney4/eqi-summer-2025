# Shell aliases for direnv
# This script creates executable wrappers in .direnv/aliases/ for command aliases
# since direnv doesn't support shell aliases directly.

export_function() {
  local name=$1
  local alias_dir=$PWD/.direnv/aliases
  mkdir -p "$alias_dir"
  PATH_add "$alias_dir"
  echo '#!/bin/bash
just "$@"' > "$alias_dir/$name"
  chmod +x "$alias_dir/$name"
}

# Create comma alias for just command
export_function "," 