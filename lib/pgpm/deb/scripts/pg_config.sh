#! /usr/bin/env bash

# Ensure PG_CONFIG is set
if [[ -z "$PG_CONFIG" ]]; then
  echo "Error: PG_CONFIG is not set."
  exit 1
fi

# Wrapper function for pg_config
pg_config_wrapper() {
  "$PG_CONFIG" "$@" | while read -r line; do
    if [[ -n "$PGPM_REDIRECT_TO_BUILDROOT" && -f "$line" || -d "$line" ]]; then
      echo "$PGPM_INSTALL_ROOT$line"
    else
      echo "$line"
    fi
  done
}

# Call the wrapper function with the arguments passed to the script
pg_config_wrapper "$@"
