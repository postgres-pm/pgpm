#!/usr/bin/env bash

ext_dir="$PGPM_INSTALL_ROOT/$(pg_config --sharedir)/extension"
control_fn="$ext_dir/$PGPM_EXTENSION_NAME.control"

echo "Creating extension dir: $ext_dir"
mkdir -p "$ext_dir"

echo "Creating control file: $control_fn"
cp "$PGPM_BUILDROOT/$PGPM_EXTENSION_NAME.control" "$ext_dir/"
echo >> "$control_fn"
echo "default_version = '$PGPM_EXTENSION_VERSION'" >> "$control_fn"
