#! /bin/bash

function find_files() {
  local filenames=("$@")  # Accept filenames as arguments
  local current_dir="$PWD"

  while [[ "$current_dir" != "/" ]]; do
    for filename in "${filenames[@]}"; do
      if [[ -f "$current_dir/$filename" ]]; then
        echo "$current_dir"  # Return the directory name
        return 0  # Success
      fi
    done
    current_dir=$(dirname "$current_dir")
  done

  return 1  # Failure (files not found)
}

filenames=("WORKSPACE")

readonly _detected="$(find_files ${filenames[@]})"
echo "detected: ${_detected}"
