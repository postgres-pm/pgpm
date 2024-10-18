#! /usr/bin/env bash

script_dir=$(dirname "$0")

BUILD_TYPE=${BUILD_TYPE:=RelWithDebInfo}
DEST_DIR=${DESTDIR:=$script_dir}

PG_CONFIG=${PG_CONFIG:=pg_config}
PG_BINDIR=$($PG_CONFIG --bindir)
PG_LIBDIR=$($PG_CONFIG --pkglibdir)
PGSHAREDIR=$($PG_CONFIG --sharedir)

set -xe

ext_name=$1
old_ver=$2
old_ver_path=$3
new_ver=$4
new_ver_path=$5

new_ver_omni_ver=$(cat ${new_ver_path}/versions.txt | grep "^omni=" | cut -d "=" -f 2)
old_ver_omni_ver=$(cat ${old_ver_path}/versions.txt | grep "^omni=" | cut -d "=" -f 2)

# Build the old extension
if [[ -f ${old_ver_path}/cmake/dependencies/CMakeLists.txt ]]; then
   PIP_CONFIG_FILE=${new_ver_path}/deps-prev/pip.conf cmake -S "${old_ver_path}/extensions/${ext_name}" -B "${old_ver_path}/build" -DCPM_SOURCE_CACHE=$new_ver_path/deps-prev/_deps -DPG_CONFIG=$PG_CONFIG -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DOPENSSL_CONFIGURED=1
else
   cmake -S "${old_ver_path}/extensions/${ext_name}" -B "${old_ver_path}/build" -DPG_CONFIG=$PG_CONFIG -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DOPENSSL_CONFIGURED=1
fi
cmake --build "${old_ver_path}/build" --parallel --target inja
cmake --build "${old_ver_path}/build" --parallel --target package_omni_extension --target package_omni_migrations --target package_extensions
#

file $old_ver_path/build/packaged/omni--$old_ver_omni_ver.so
file $new_ver_path/build/packaged/omni--$new_ver_omni_ver.so

# Determine the path to the extension in the new version
extpath=$(cat ${new_ver_path}/build/paths.txt | grep "^$ext_name " | cut -d " " -f 2)

# List migrations in new version
new_migrations=()
new_migrate_path=$new_ver_path/$extpath/migrate
if [ -d "$new_migrate_path/$ext_name" ]; then
   # Extension that shares a folder with another extension
   new_migrate_path="$new_migrate_path/$ext_name"
fi
for file in $new_migrate_path/*.sql; do
  new_migrations+=($(basename "$file"))
done

# Determine the path to the extension in the old version
extpath=$(cat ${old_ver_path}/build/paths.txt | grep "^$ext_name " | cut -d " " -f 2)
# List migrations in old version
old_migrations=()
old_migrate_path=$old_ver_path/$extpath/migrate
if [ -d "$old_migrate_path/$ext_name" ]; then
   # Extension that shares a folder with another extension
   old_migrate_path="$old_migrate_path/$ext_name"
fi
for file in $old_migrate_path/*.sql; do
  old_migrations+=($(basename "$file"))
done

for mig in ${new_migrations[@]}; do
  if [ ! -f "$old_migrate_path/$mig" ]; then
     $new_ver_path/build/inja/inja "$new_migrate_path/$mig" >> "$DEST_DIR/$ext_name--$old_ver--$new_ver.sql"
     # Ensure a new line
     echo >> "$DEST_DIR/$ext_name--$old_ver--$new_ver.sql"
  fi
done

cat "$DEST_DIR/$ext_name--$old_ver--$new_ver.sql"

# Now, we need to replace functions that have changed
# For this, we'll:
# * prepare a database
db="$DEST_DIR/db_$ext_name-$old_ver-$new_ver"
rm -rf "$db"
chown -R postgres "$DEST_DIR"
sudo -u postgres "$PG_BINDIR/initdb" -D "$db" --no-clean --no-sync --locale=C --encoding=UTF8
sockdir=$(sudo -u postgres mktemp -d)
# * install the extension in this revision, snapshot pg_proc, drop the extension
# We copy all scripts because there are dependencies
cp -v "$old_ver_path"/build/packaged/extension/*.sql "$old_ver_path"/build/packaged/extension/*.control "$PGSHAREDIR/extension"
cp -v "$old_ver_path"/build/packaged/*.so "$PG_LIBDIR"
sudo -u postgres "$PG_BINDIR/pg_ctl" start -D "$db" -o "-c max_worker_processes=64" -o "-c listen_addresses=''" -o "-k $sockdir" -o "-c shared_preload_libraries='$PG_LIBDIR/omni--$old_ver_omni_ver.so'"
sudo -u postgres "$PG_BINDIR/createdb" -h "$sockdir" "$ext_name"
cat <<EOF | sudo -u postgres "$PG_BINDIR/psql" -h "$sockdir" $ext_name -v ON_ERROR_STOP=1
     create table procs0 as (select * from pg_proc);
     create extension $ext_name version '$old_ver' cascade;
     create table procs as (select pg_proc.*, pg_get_functiondef(pg_proc.oid) as src, pg_get_function_identity_arguments(pg_proc.oid) as identity_args from pg_proc left outer join procs0 on pg_proc.oid = procs0.oid
     inner join pg_language on pg_language.oid = pg_proc.prolang
     inner join pg_namespace on pg_namespace.oid = pg_proc.pronamespace and pg_namespace.nspname = '$ext_name'
     left outer join pg_aggregate on pg_aggregate.aggfnoid = pg_proc.oid
     where procs0.oid is null and aggfnoid is null and lanname not in ('c', 'internal'));
     drop extension $ext_name cascade;
EOF
sudo -u postgres "$PG_BINDIR/pg_ctl" stop -D  "$db" -m smart
# We copy all scripts because there are dependencies
cp -v "$new_ver_path"/build/packaged/extension/*.sql "$new_ver_path"/build/packaged/extension/*.control "$PGSHAREDIR/extension"
cp -v "$new_ver_path"/build/packaged/*.so "$PG_LIBDIR"
sudo -u postgres "$PG_BINDIR/pg_ctl" start -D "$db" -o "-c max_worker_processes=64" -o "-c listen_addresses=''" -o "-k $sockdir"  -o "-c shared_preload_libraries='$PG_LIBDIR/omni--$new_ver_omni_ver.so'"
# * install the extension from the head revision
echo "create extension $ext_name version '$new_ver' cascade;" | sudo -u postgres "$PG_BINDIR/psql" -h "$sockdir" -v ON_ERROR_STOP=1 $ext_name
# get changed functions
cat <<EOF | sudo -u postgres "$PG_BINDIR/psql" -h "$sockdir" $ext_name -v ON_ERROR_STOP=1 -t -A -F "," -X >> "$DEST_DIR/$ext_name--$old_ver--$new_ver.sql"
    -- Changed code
    select pg_get_functiondef(pg_proc.oid) || ';' from (select * from pg_proc where oid not in (select aggfnoid from pg_aggregate)) as pg_proc
    inner join pg_language on pg_language.oid = pg_proc.prolang and pg_language.lanname not in ('c', 'internal')
    inner join pg_namespace on pg_namespace.oid = pg_proc.pronamespace and pg_namespace.nspname = '$ext_name'
    inner join procs on
    ((procs.proname::text = pg_proc.proname::text) and procs.pronamespace = pg_proc.pronamespace and
      pg_get_function_identity_arguments(pg_proc.oid) = identity_args and pg_get_functiondef(pg_proc.oid) != procs.src);
EOF
# test the upgrade
# first, let's stop current database to load older extension again
sudo -u postgres "$PG_BINDIR/pg_ctl" stop -D  "$db" -m smart
cp "$DEST_DIR/$ext_name--$old_ver--$new_ver.sql" "$old_ver_path/build/packaged/extension/$ext_name--$old_ver.control" "$old_ver_path/build/packaged/extension/$ext_name--$old_ver.sql" "$PGSHAREDIR/extension"
sudo -u postgres "$PG_BINDIR/pg_ctl" start -D "$db" -o "-c max_worker_processes=64" -o "-c listen_addresses=''" -o "-k $sockdir" -o "-c shared_preload_libraries='$PG_LIBDIR/omni--$old_ver_omni_ver.so'"
cat <<EOF | sudo -u postgres "$PG_BINDIR/psql" -h "$sockdir" $ext_name -v ON_ERROR_STOP=1
        drop extension $ext_name;
        create extension $ext_name version '$old_ver' cascade;
EOF
sudo -u postgres "$PG_BINDIR/pg_ctl" stop -D  "$db" -m smart
sudo -u postgres "$PG_BINDIR/pg_ctl" start -D "$db" -o "-c max_worker_processes=64" -o "-c listen_addresses=''" -o "-k $sockdir"  -o "-c shared_preload_libraries='$PG_LIBDIR/omni--$new_ver_omni_ver.so'"
    cat <<EOF | sudo -u postgres "$PG_BINDIR/psql" -h "$sockdir" $ext_name -v ON_ERROR_STOP=1
    alter extension $ext_name update to '$new_ver';
EOF
# * shut down the database
sudo -u postgres "$PG_BINDIR/pg_ctl" stop -D  "$db" -m smart
# * remove it
rm -rf "$db"
# * copy upgrade script files
cp -f "$DEST_DIR/$ext_name--$old_ver--$new_ver.sql" "$new_ver_path/build/packaged/extension"