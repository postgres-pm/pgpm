# syntax = docker/dockerfile:experimental

# IMPORTANT: build it this way to allow for privileged execution
#
# Docker daemon config should have the entitlement
# ```json
# { "builder": {"Entitlements": {"security-insecure": true }} }
# ```
# ```
# DOCKER_BUILDKIT=1 docker build --allow security.insecure -t IMAGE_NAME .
# ```

# This Dockerfile is used to build a Debian image, which includes pbuilder and
# pbuilder chroot image with basic dependendencies needed for building most
# packages already pre-installed.

FROM docker.io/library/debian

MAINTAINER PGPM Debian Maintainer debian.maintainer@postgres.pm

VOLUME /proc
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN apt install -y build-essential pbuilder fakeroot fakechroot vim ripgrep
RUN echo 'MIRRORSITE=http://deb.debian.org/debian'  > /etc/pbuilderrc
RUN echo 'AUTO_DEBSIGN=${AUTO_DEBSIGN:-no}'         > /root/.pbuilderrc
RUN echo 'HOOKDIR=/var/cache/pbuilder/hooks'       >> /root/.pbuilderrc
COPY scripts/faketar /usr/bin/
RUN chmod +x /usr/bin/faketar
RUN sed -E -i "s/local TAR=tar/local TAR=faketar/" /usr/lib/pbuilder/pbuilder-modules
RUN sed -E -i "s/if [!] tar -c --use-compress-program/if ! faketar -c --use-compress-program/" /usr/lib/pbuilder/pbuilder-modules
RUN --security=insecure fakeroot pbuilder create
