# Postgres.pm

**Postgres.pm** (aka **pgpm**) is a streamlined package manager designed to simplify the process of building and
distributing Postgres extensions and packages.

## Key objectives

<details>
<summary><b>Platform independence</b></summary>

Postgres.pm is designed to deliver Postgres extensions
in native packaging (such as RPM, DEB, OCI images, etc.)
to support the broad variety of usage patterns.

</details>

> [!NOTE]
> Early release is targeting RHEL-based distributions using
> official PGDG Postgres distributions with other options
> coming up.

<details>
<summary><b>Low-effort package maintenance</b></summary>

Postgres.pm embraces the concept of inferences: based
on given information, it'll figure out how to build the package
if it fits into a set of pre-defined rules.

New versions are automatically picked up and recognized.

Package definition can be as simple as this – with no routine
maintenace on new releases:

```ruby

class Pgvector < Pgpm::Package
  github "pgvector/pgvector"
end
```

</details>

<details>
<summary><b>Package definition flexibility</b></summary>

Packages definitions are defined in Ruby, allowing for near-infinite
flexibility of their definition when necessary.

This allows us to accomodate non-standard build and installation procedures
with ease.
</details>

---

### Current Status
 
We are preparing to start publishing RPM packages publicly soon. It's possible to build included packages manually.


### Development

To build the packages, use the [exe/pgpm](exe/pgpm) script.

Example:

```sh
./exe/pgpm build pgvector
```

## pgpm build command

```
Usage:
  pgpm build PACKAGES...

Arguments:
  PACKAGES  # Package names (can include version with @, e.g., pgvector@1.0.0)

Options:
  --pkgdir=VALUE    # Directory to load packages from (default: "packages" if directory exists)
  --os=VALUE        # OS name (default: auto-detected)
  --arch=VALUE      # Target architecture (default: host architecture)
  --pgdist=VALUE    # Target Postgres distribution (default: "pgdg")
  --pgver=VALUE     # Target Postgres version (default: latest supported version)
```

Examples:

```sh
# Build specific version
pgpm build pgvector@1.0.0

# Build for specific Postgres version
pgpm build pgvector --pgver=15

# Build multiple packages
pgpm build pgvector pg_cron

# Build from custom package directory
pgpm build pgvector --pkgdir=custom/packages
```

### Running pgpm build command via Official Docker Image

Pull the official Docker image:

```sh
docker pull ghcr.io/postgres-pm/pgpm:latest
```

You can use the following command to build the packages:

```sh
docker run --rm -it ghcr.io/postgres-pm/pgpm:latest pgpm build pgvector
```

If using the development version (pgpm-dev stage), you can mount the current directory to the container:

```sh
docker run --rm -it -v $(pwd):/pgpm ghcr.io/postgres-pm/pgpm:latest pgpm build pgvector
```

### Building the Docker Image

To build the Docker image, use the following command:

```sh
# Build and load the image into local Docker daemon
docker buildx build --load --allow security.insecure -t pgpm:local .
```

To use insecure builder, you can run the following commands:

```sh
docker buildx create --name insecure-builder --driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=-1 --buildkitd-flags '--allow-insecure-entitlement security.insecure'
docker buildx use insecure-builder
env DOCKER_BUILDKIT=1 docker build --allow security.insecure -t pgpm:local .
```

Later, you can use the builder by running:

```sh
env DOCKER_BUILDKIT=1 docker build --builder=insecure-builder --allow security.insecure -t pgpm:local .
```

To run the image, use the following command:

```sh
# If using the base pgpm image
docker run --rm -it pgpm:local pgpm build pgvector

# If using the development version (pgpm-dev stage)
docker run --rm -it -v $(pwd):/pgpm pgpm:local ./exe/pgpm build pgvector
```

To remove the builder, run the following command:

```sh
docker buildx rm insecure-builder
```

To remove the image, run the following command:

```sh
docker rmi pgpm:local
docker rmi ghcr.io/postgres-pm/pgpm:latest
```

### Troubleshooting

#### Podman invocations terminate with exit code 137

Make sure your machine has enough RAM. For `podman-machine` you might want to adjust it
with

```shell
podman machine stop
podman machine set -m 16384 # for 16GB
podman machine start
```
