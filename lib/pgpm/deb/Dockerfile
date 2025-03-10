# syntax = docker/dockerfile:experimental

# IMPORTANT: build it this way to allow for privileged execution
#
# Docker daemon config should have the entitlement
# ```json
# { "builder": {"Entitlements": {"security-insecure": true }} }
# ```
# ```
# DOCKER_BUILDKIT=1 docker build --allow security.insecure -t IMAGE_NAME /path/to/pgpm
# ```

# This Dockerfile is used to build a Debian image, which includes pbuilder and
# pbuilder chroot image with basic dependendencies needed for building most
# packages already pre-installed.

FROM docker.io/library/debian

MAINTAINER PGPM Debian Maintainer debian.maintainer@postgres.pm

VOLUME /proc
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN apt install -y build-essential pbuilder fakeroot fakechroot
RUN echo 'MIRRORSITE=http://deb.debian.org/debian'  > /etc/pbuilderrc
RUN echo 'AUTO_DEBSIGN=${AUTO_DEBSIGN:-no}'         > /root/.pbuilderrc
RUN echo 'HOOKDIR=/var/cache/pbuilder/hooks'       >> /root/.pbuilderrc
RUN --security=insecure pbuilder create  # --components "main contrib-non-free"

COPY pbuilder_install_script.sh /root/pbuilder_install_script.sh
RUN --security=insecure pbuilder execute --save-after-exec /root/pbuilder_install_script.sh
