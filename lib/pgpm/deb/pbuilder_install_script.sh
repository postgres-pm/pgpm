#!/usr/bin/env bash
apt update
DEBIAN_FRONTEND=noninteractive apt -y install build-essential curl lsb-release ca-certificates

### PostgreSQL installation
#
install -d /usr/share/postgresql-common/pgdg
curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc

# Create the repository configuration file:
sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Update the package lists:
apt update

# Install the latest version of PostgreSQL:
# If you want a specific version, use 'postgresql-16' or similar instead of 'postgresql'
apt -y install postgresql-17 postgresql-server-dev-17 postgresql-common
#
### END OF PostgreSQL installation

