Known podman issues
===================

"Unable to start container" error
---------------------------------
When you first build a package, podman downloads the base image and attempts
to create a local image with correct version PostgreSQL installed into it.
However on some systems, running podman may initially result in the following
error:

```
Error: unable to start container "[CONTAINER_ID]": container create failed (no logs from conmon): conmon bytes "": readObjectStart: expect { or n, but found , error found in #0 byte of ...||..., bigger context ...||...
```

To fix this issue the following steps need to be performed:

1. Wipe all podman runtime and configuration:

            pkill -9 -f 'conmon|podman'
            rm -rf ~/.local/share/containers/
            rm -rf ~/.config/containers/
            rm -rf /run/user/$(id -u)/libpod/
            podman system reset --force

2. Reinstall podman and its components:

            sudo apt reinstall podman conmon runc crun

3. Create storage settings conf file:

            mkdir -p ~/.config/containers/
            touch ~/.config/containers/storage.conf

            # Add the following lines to the newly
            # created ~/.config/containers/storage.conf:
            #
            [storage]
            driver = "overlay"
            graphroot = "/home/$USER/.local/share/containers/storage"
            runroot = "/run/user/$(id -u)/containers"

4. Restart the service (if applicable):

            service podman restart
