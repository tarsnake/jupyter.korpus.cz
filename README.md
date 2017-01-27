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
virtualenv is expected under `./.venv`, and the NLTK data directory under
`./nltk_data` (if it's not there, nothing catastrophic will happen, NLTK will
just complain if you try to load a resource).

## Add a user who will run JupyterHub

It's not a good idea to run JupyterHub as all-powerful root. Instead, create a
new user specifically for this task:

```sh
useradd -r jupyter
```

When installing in a virtualenv and running JupyterHub without root privileges
(see [JupyterHub wiki](https://github.com/jupyterhub/jupyterhub/wiki/Using-sudo-to-run-JupyterHub-without-root-privileges)),
it is **absolutely necessary** to add the virtualenv bin directory to the
`secure_path` in the sudoers file and make some additional configuration.
Either follow the linked tutorial on the JupyterHub wiki, or update your
`/etc/sudoers` based on the snippet in `./sudoers`.

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

# Python environments

The setup takes into account two types of Python environments: **server**
(where the Jupyter\* web apps run) and **kernel** (the Python environments
users interact with via notebooks, consoles etc.).

## Server

This is the environment in which the JupyterHub and single-user Jupyter servers
run. It is expected to be a virtualenv under `./.venv` set up using
`./server_requirements.txt`:

```sh
virtualenv .venv 
source .venv/bin/activate
pip install -r server_requirements.txt
```

This environment doesn't have to be the latest and greatest Python version
around, since users won't be interacting with this interpreter. Anything
packaged with your Linux distro should do, as long as JupyterHub et al. can run
on it. (Generally though, this guide assumes in certain places you'll be using
Python 3.x, so you'll need to be a it more careful when following along using
Python 2.x.)

If you want to allow users to use `ipywidgets`, run the following inside the
virtualenv:

```sh
jupyter nbextension enable --py --sys-prefix widgetsnbextension
```

You still need to install `ipywidgets` in the kernel environment as well
though; the provided `kernel_environment.yml` (see below) takes care of that.

Similarly for other Jupyter Notebook / JupyterLab extensions: they need to be
installed in the server environment (makes sense, it's where the web apps they
extend are) and additionally, if they provide hooks for user code, the
corresponding packages also need to be installed in the appropriate kernel
environment (otherwise the users can't import them).

**WARNING:** Update packages inside this environment only if you need some new
feature of the Jupyter\* web apps themselves. Be warned that since the
configuration may change between different versions of Jupyter, JupyterHub
etc., you may need to tweak it yourself after the update, which may result in
significant downtime for your users. If you want to treat your users to a newly
released version of Python, **update the default kernel instead** (see below).

Once you *do* decide to upgrade the server packages, be careful especially with
JupyterHub, as its user database schema might change between major versions
(remember that 0.x is major by semver rules). Run `jupyterhub upgrade-db` to
migrate.

## Kernels

These are the environments used to spawn the kernels users will interact with.
In principle, you can set up however many of these as you like, you just need
to install a version of Python (via Linuxbrew, Miniconda, from source etc.)
which is compatible with `ipykernel` and then (take care to specify the correct
path to your custom acquired `python` and `pip`):

```sh
path/to/pip install ipykernel
path/to/python -m ipykernel --prefix /opt/jupyter/.venv --name my-kernel-name --display-name 'My human-readable kernel name'
```

Kernel configuration is stored under `./.venv/share/jupyter/kernels`, so you
can also edit the appropriate `my-kernel-name/kernel.json` by hand and change
the path to a new Python installation if you want all users to automatically
start using a new kernel with their existing notebooks. **Be careful though:**
this may break your users' code! Language features change between versions, you
may forget to install some of the libraries that people got to rely on in the
previous environment etc.

In practice, it's very handy to use
[Miniconda](http://conda.pydata.org/miniconda.html) to set up the kernels.  It
allows you to install and manage multiple Python environments (including
multiple versions of Python) easily.  After installing Miniconda (I used
Miniconda for Python 3 and installed it to `/opt/miniconda3`), you can
replicate the kernel environment I suggest as a starting point with:

```sh
conda env create -f kernel_environment.yml
source activate python-3.6  # see `name` field in `kernel_environment.yml`
python -m ipykernel --prefix /opt/jupyter/.venv --name python3 --display-name 'Python 3'
```

This replaces the default Python 3 kernel (which would have been the one
corresponding to the Python **server** environment) with your shiny new conda
environment. This is the recommended setup, as it cleanly separates the server
and kernel environments and allows you to update the latter without touching
the former. If you wish to keep the original environment, just use a different
`--name` and `--display-name`

Here's a rough idea of the packages that were explicitly included in
`./kernel_environment.yml` for teaching and scientific Python purposes (the
rest were pulled in as dependencies):

- with `conda install`:
  - ipykernel
  - ipywidgets
  - lxml
  - matplotlib
  - nltk
  - numpy
  - scipy
  - scikit-learn
  - pandas
  - requests
- with `pip install`:
  - regex
  - git+https://github.com/dlukes/pymorphodita

### Updating kernel environments

Careful, this may break your users' code! On the other hand, it doesn't affect
the server, so they still will be able to use Jupyter to access and fix their
stuff, so it's not that bad. Again, for the value to pass as the `--name`
option, please consult the corresponding field at the top of
`./kernel_environment.yml`, or use the name of another environment you've
installed manually (see below on how to set up a Python 2 environment).

#### Updating Python to a new maintenance release

This is probably not controversial, do this whenever convenient:

```sh
conda update --name python-3.6 python
```

#### Upgrading Python to a new minor release

This may introduce more breakage:

```sh
conda install --name python-3.6 python=3.7
```

NOTE: in particular, does `conda` re-download all the packages for this new
version of Python, or do we lose the previously installed libraries and have to
re-install them by hand? If you're afraid of breaking your users' stuff, you're
probably better off just creating a new environment, setting it up as an
additional kernel and letting your users switch at will.

#### Updating packages

This may break stuff if some of the libraries have API changes (obviously).

```sh
conda --name python-3.6 update --all
```

To update pip packages, activate the environment, get the list of installed
packages with `pip freeze` and update using `pip install --upgrade`. (This is
really a chore, I hope a better way of "updating everything" is coming. Or
perhaps inside a conda environment, conda takes care of updating even pip
packages?)

### Installing a Python 2 kernel

```sh
conda create --name python-2 python=2
source activate python-2
conda install ipykernel
python -m ipykernel --prefix /opt/jupyter/.venv --name python2 --display-name 'Python 2'
```

Seriously though, switch to Python 3 already! It's gorgeous :)

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
