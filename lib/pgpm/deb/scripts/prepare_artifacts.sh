#! /usr/bin/env bash

#set -xe

new_extension_so=

PG_CONFIG="${PG_CONFIG:-"pg_config"}"

install_root=$PGPM_INSTALL_ROOT

for file in $(find $PGPM_BUILDROOT -name '*.so'); do
  filename=$(basename "$file")
  if [[ "$filename" == "${PGPM_EXTENSION_NAME}.so" ]]; then
    extension_so=$filename
    dir=$(dirname "$file")
    extension_dirname=${dir#"$PGPM_BUILDROOT"}
    new_extension_so=$PGPM_EXTENSION_NAME--$PGPM_EXTENSION_VERSION.so
    break
  fi
done

extdir=$install_root$($PG_CONFIG --sharedir)/extension

# control files
default_control=$extdir/$PGPM_EXTENSION_NAME.control
versioned_control=$extdir/$PGPM_EXTENSION_NAME--$PGPM_EXTENSION_VERSION.control
controls=("$default_control" "$versioned_control")

function rename_so() {
  mv "$install_root$extension_dirname/$extension_so" \
     "$install_root$extension_dirname/$new_extension_so"
}

function change_name_in_controls() {
  echo "CHANGING EXTENSION NAME IN CONTROL FILES"
  echo "----------------------------------------"
  for control in "${controls[@]}"; do
    if [[ -f "$control" ]]; then
      echo "$control"
      # extension.so
      sed -i "s|${extension_so}'|${new_extension_so}'|g" "$control"
      # extension
      sed -i "s|${extension_so%".so"}'|${new_extension_so%".so"}'|g" "$control"
    fi
  done
}

function rename_sql_files() {
  echo "RENAMING EXTENSION SQL FILES"
  echo "----------------------------"
  for sql_file in $(find $install_root -name '*.sql' -type f); do
    echo "$sql_file"
    # extension.so
    sed -i "s|/${extension_so}'|/${new_extension_so}'|g" "$sql_file"
    # extension
    sed -i "s|/${extension_so%".so"}'|/${new_extension_so}'|g" "$sql_file"
  done
}

function rename_bitcode() {
  echo "RENAMING BITCODE"
  echo "----------------"

  pkglibdir=$install_root$($PG_CONFIG --pkglibdir)
  bitcode_extension=$pkglibdir/bitcode/${extension_so%".so"}
  bitcode_index=$pkglibdir/bitcode/${extension_so%".so"}.index.bc

  if [[ -d "${bitcode_extension}" ]]; then
    echo "$bitcode_extension"
    mv "$bitcode_extension" "$pkglibdir/bitcode/${new_extension_so%".so"}"
  fi

  if [[ -f "${bitcode_index}" ]]; then
    echo "$bitcode_index"
    mv "${bitcode_index}" "$pkglibdir/bitcode/${new_extension_so%".so"}.index.bc"
  fi
}

function rename_includes() {
  includedir=$install_root$($PG_CONFIG --includedir-server)
  echo "RENAMING INCLUDES"
  echo "-----------------"
  if [[ -d "${includedir}/extension/$PGPM_EXTENSION_NAME" ]]; then
    echo "$includedir"
    versioned_dir=${includedir}/extension/$PGPM_EXTENSION_NAME--$PGPM_EXTENSION_VERSION
    mkdir -p "$versioned_dir"
    mv "${includedir}/extension/$PGPM_EXTENSION_NAME" "$versioned_dir"
  fi
}

# Make sure we don't build a default control as it belongs
# to another package
function handle_default_control() {
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
}

if [[ -n "$new_extension_so" ]]; then
  rename_so
  change_name_in_controls
  rename_sql_files
  rename_bitcode
  rename_incluides
fi

handle_default_control
