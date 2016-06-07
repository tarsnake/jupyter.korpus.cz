# Overview

This is a working setup of
[JupyterHub](https://github.com/jupyterhub/jupyterhub) for a public facing
server running Ubuntu 16.04, with Nginx as a reverse proxy and Python 3.
Currently, this README is more of a reminder to myself should the config on the
production server ever get nuked, but if you're interested in replicating it on
your own box, drop me a line, I'll be glad to help! Features include:

- encryption with letsencrypt
- controlling via systemd
- culling idle single user servers
- shared directory with the NLTK data packages
- possibility to run additional services (like RStudio) under subpaths (see
  `./jupyter.nginx`)

# Notes

This entire directory should be placed at `/opt/jupyter` on the server. A
Python 3 virtualenv is expected under `./venv`, and the NLTK data directory
under `./nltk_data`.

When installing in a virtualenv and running JupyterHub without root privileges
(see [JupyterHub wiki](https://github.com/jupyterhub/jupyterhub/wiki/Using-sudo-to-run-JupyterHub-without-root-privileges)),
it is **absolutely necessary** to add the virtualenv bin directory to the
`secure_path` in the sudoers file.

If run without a proxy (directly on port 80/443) and without sudo, node must be
allowed to listen on these ports:

```sh
sudo setcap 'cap_net_bind_service=+ep' /usr/bin/node
```

Node can probably make do without a proxy for smallish to medium loads and if
it's not necessary to run other services in parallel. But since we want to run
multiple services in parallel, we put JupyterHub behind Nginx, see
`jupyter.nginx` for a proxy config. (Nginx would also be great for serving
static files, but that's probably not where the bottleneck is with Jupyter,
plus this is all handled by the application, so I'd have to dig up the static
dir to point Nginx to and make sure it's the right one etc.)

Install both systemd units (`*.service`) [as specified in the JupyterHub
wiki](https://github.com/jupyterhub/jupyterhub/wiki/Run-jupyterhub-as-a-system-service)
and don't forget to `systemctl enable` them. Systemd cheatsheet:

```sh
systemctl restart <unit>
journalctl -u <unit>
```
