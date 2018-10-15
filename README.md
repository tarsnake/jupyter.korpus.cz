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

# Preliminaries

This entire directory should be placed at `/opt/jupyter` on the server. A
`pyenv` install is expected under `/opt/pyenv` (source the environment config
in `env.sh`), and the NLTK data directory under `./nltk_data` (if it's not
there, nothing catastrophic will happen, NLTK will just complain if you try to
load a resource).

## Permissions and owners

This whole setup is very finicky about having the correct file permissions and
owners set on some crucial files. Run `./fix_permissions.sh jupyter` if you
experience problems (or take a look at the script to identify potential pain
points).

## Systemd service files

Install and enable the `*.service` files. Optionally comment out the
`OnFailure` handler if you don't have a `notify-failed` service on your system.

## Securing your connection

Install Letsencrypt and get an SSL certificate. Optionally set up
`./letsencrypt-renew.sh` as a cron job for automatic renewal of the
certificate.

## Reverse proxy

You'll need Nginx. Use `./jupyter.nginx` as a template for the config, just
remove the `location` directives you won't be needing, change the URL patterns
to match your domain and set the correct path to the SSL certificates you
obtained in the previous step in the `ssl_certificate` and
`ssl_certificate_key` directives.

# Installation / upgrade

Run `install_jupyter.sh` for Jupyter/Python and `install_R.sh` for R. During a
first time setup, you'll probably hit some snags, because so far I've just used
these on a machine with an existing installation. And they're pretty brittle
even so, especially the R one.

# Installing / upgrading packages

## Python

Add package to `requirements.txt` and run:

```sh
pip3 install -r requirements.txt
```

The `requirements.txt` file is used to reinstall all packages when a new
version of Python is installed.

If you want to update installed packages, use the `-U` option to `pip`.

## R

Add an entry to `requirements.R`, which keeps track of which packages people
are using and how to get them, and run the script. The script is also
automatically run upon installation of a new version of R, after the previous
version's libraries have been purged.

If you want to just update the packages (without updating to a new version of
R), run `update.packages(ask=FALSE)` in R under `sudo -i`.

# Notes

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
