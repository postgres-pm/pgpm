#! /usr/bin/env bash

#set -xe

new_extension_so=

echo $PGPM_BUILDROOT
echo $PGPM_EXTENSION_NAME
echo $PGPM_EXTENSION_VERSION
PG_CONFIG="pg_config"
echo "pg_config: $(which pg_config)"
echo "pg_config sharedir: $(pg_config --sharedir)"

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

extdir=$PGPM_BUILDDEB$($PG_CONFIG --sharedir)/extension

# control files
default_control=$extdir/$PGPM_EXTENSION_NAME.control
versioned_control=$extdir/$PGPM_EXTENSION_NAME--$PGPM_EXTENSION_VERSION.control
controls=("$default_control" "$versioned_control")

echo "PWD: $(pwd)"

echo "----------------------"
echo "extension_dirname: $extension_dirname"
echo "new_extension_so: $new_extension_so"
echo "default_control: $default_control"
echo "versioned_control: $versioned_control"
echo "extension_so: $extension_so"
echo "extdir: $extdir"
echo "PGPM_BUILDDEB: $PGPM_BUILDDEB"
echo "----------------------"

echo "CONTROLS CONTENTS"
echo "-----------------"
echo "DEFAULT CONTROL:"
cat $default_control
echo "\nVERSIONED CONTROL:"
cat $versioned_control
echo "-----------------"

if [[ -n "$new_extension_so" ]]; then

  mv "$PGPM_BUILDDEB$extension_dirname/$extension_so" "$PGPM_BUILDDEB$extension_dirname/$new_extension_so"

  echo "CHANGING EXTENSION NAME IN CONTROLS"
  echo "-----------------------------------"
  # Change the extension name in controls
  for control in "${controls[@]}"; do
    if [[ -f "$control" ]]; then
      echo "$control"
      # extension.so
      sed -i "s|${extension_so}'|${new_extension_so}'|g" "$control"
      # extension
      sed -i "s|${extension_so%".so"}'|${new_extension_so%".so"}'|g" "$control"
    fi
  done
  echo "-----------------------------------"

  # sql files
  echo "SQL FILES"
  echo "---------"
  for sql_file in $(find $PGPM_BUILDDEB -name '*.sql' -type f); do
    echo "$sql_file"
    # extension.so
    sed -i "s|/${extension_so}'|/${new_extension_so}'|g" "$sql_file"
    # extension
    sed -i "s|/${extension_so%".so"}'|/${new_extension_so}'|g" "$sql_file"
  done
  echo "---------"

  # bitcode

  pkglibdir=$PGPM_BUILDDEB$($PG_CONFIG --pkglibdir)

  bitcode_extension=$pkglibdir/bitcode/${extension_so%".so"}
  bitcode_index=$pkglibdir/bitcode/${extension_so%".so"}.index.bc

  echo "BITCODE"
  echo "-------"
  if [[ -d "${bitcode_extension}" ]]; then
    echo "$bitcode_extension"
    mv "$bitcode_extension" "$pkglibdir/bitcode/${new_extension_so%".so"}"
  fi

  if [[ -f "${bitcode_index}" ]]; then
    echo "$bitcode_index"
    mv "${bitcode_index}" "$pkglibdir/bitcode/${new_extension_so%".so"}.index.bc"
  fi
  echo "-------"

  # includes
  includedir=$PGPM_BUILDDEB$($PG_CONFIG --includedir-server)

  echo "INCLUDES"
  echo "--------"
  if [[ -d "${includedir}/extension/$PGPM_EXTENSION_NAME" ]]; then
    echo "$includedir"
    versioned_dir=${includedir}/extension/$PGPM_EXTENSION_NAME--$PGPM_EXTENSION_VERSION
    mkdir -p "$versioned_dir"
    mv "${includedir}/extension/$PGPM_EXTENSION_NAME" "$versioned_dir"
  fi
  echo "--------"

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
