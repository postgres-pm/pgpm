#! /usr/bin/env bash

set -xe

new_extension_so=

for file in $(find $PGPM_INSTALL_ROOT -name '*.so'); do
  filename=$(basename "$file")
  if [[ "$filename" == "${PGPM_EXTENSION_NAME}.so" ]]; then
    extension_so=$filename
    dir=$(dirname "$file")
    extension_dirname=${dir#"$PGPM_INSTALL_ROOT"}
    new_extension_so=$PGPM_EXTENSION_NAME--$PGPM_EXTENSION_VERSION.so
  fi
done

extdir=$PGPM_INSTALL_ROOT$($PG_CONFIG --sharedir)/extension

# control files
default_control=$extdir/$PGPM_EXTENSION_NAME.control
versioned_control=$extdir/$PGPM_EXTENSION_NAME--$PGPM_EXTENSION_VERSION.control
controls=("$default_control" "$versioned_control")


if [[ -n "$new_extension_so" ]]; then

  mv "$PGPM_INSTALL_ROOT$extension_dirname/$extension_so" "$PGPM_INSTALL_ROOT$extension_dirname/$new_extension_so"

  # Change the extension name in controls
  for control in "${controls[@]}"; do
    if [[ -f "$control" ]]; then
      # extension.so
      sed -i "s|${extension_so}'|${new_extension_so}'|g" "$control"
      # extension
      sed -i "s|${extension_so%".so"}'|${new_extension_so%".so"}'|g" "$control"
    fi
  done

  # sql files
  for sql_file in $(find $PGPM_INSTALL_ROOT -name '*.sql' -type f); do
    # extension.so
    sed -i "s|/${extension_so}'|/${new_extension_so}'|g" "$sql_file"
    # extension
    sed -i "s|/${extension_so%".so"}'|/${new_extension_so}'|g" "$sql_file"
  done

  # bitcode

  pkglibdir=$PGPM_INSTALL_ROOT$($PG_CONFIG --pkglibdir)

  bitcode_extension=$pkglibdir/bitcode/${extension_so%".so"}
  bitcode_index=$pkglibdir/bitcode/${extension_so%".so"}.index.bc

  if [[ -d "${bitcode_extension}" ]]; then
    mv "${bitcode_extension}" "$pkglibdir/bitcode/${new_extension_so%".so"}"
  fi

  if [[ -f "${bitcode_index}" ]]; then
    mv "${bitcode_index}" "$pkglibdir/bitcode/${new_extension_so%".so"}.index.bc"
  fi

  # includes
  includedir=$PGPM_INSTALL_ROOT$($PG_CONFIG --includedir-server)

  if [[ -d "${includedir}/extension/$PGPM_EXTENSION_NAME" ]]; then
    versioned_dir=${includedir}/extension/$PGPM_EXTENSION_NAME--$PGPM_EXTENSION_VERSION
    mkdir -p "$versioned_dir"
    mv "${includedir}/extension/$PGPM_EXTENSION_NAME" "$versioned_dir"
  fi

  # TODO: share, docs, etc.

fi


# Make sure we don't build a default control as it belongs
# to another package
if [[ -f "$default_control" ]]; then
  if [[ -f "$versioned_control" ]]; then
    # We don't need default control if versioned is present
    rm -f "$default_control"
  else
    # Default becomes versioned
    mv "$default_control" "$versioned_control"
    # Don't need default_version
    sed -i '/default_version/d' "$versioned_control"
  fi
fi
