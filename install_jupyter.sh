#!/usr/bin/env zsh

set -e
cd ${0:a:h}

## We expect a pyenv Python under /opt/pyenv

python=$( command -v python )
if [[ $( command -v python ) != /opt/pyenv/shims/python ]]; then
  cat <<'EOF' >&2
This script is designed to work with a Python installed by pyenv under
/opt/pyenv. Please do that first.

Refer to <https://github.com/pyenv/pyenv> for instructions and make sure that
env.sh is sourced by the system-wide shell runcoms (/etc/bash.bashrc,
/etc/zsh/zshenv).
EOF
exit 1
fi

## JupyterHub runs under the user jupyter; make sure it exists

if ! getent passwd jupyter >/dev/null; then
  >&2 echo 'User jupyter not found, creating it...'
  sudo useradd -r -s /bin/false jupyter
fi

## Download new Python version, if available

pushd $( pyenv root )
git pull >/dev/null
current_version=$( pyenv version-name )
newest_version=$(
  pyenv install -l |
    sed 's/^ *//' |
    grep -P '^3\.\d+\.\d+$' |
    tail -n1
)
if [[ $current_version != $newest_version ]]; then
  >&2 read -q "YN?Install newer Python version $newest_version to replace $current_version?"
  >&2 echo
  # from Python 3.7 on, pip requires ctypes, which in turn requires
  # libffi-dev[el]
  sudo apt-get install -y libffi-dev
  # `PYTHON_CONFIGURE_OPTS=--enable-shared` is important for libraries which
  # use the Python shared library (e.g. MorphoDiTa SWIG bindings) to work.
  # `CFLAGS=-O2` is a safe optimization level which will make the interpreter a
  # little faster.
  PYTHON_CONFIGURE_OPTS=--enable-shared CFLAGS=-O2 pyenv install $newest_version
  pyenv global $newest_version
fi
popd

## (Re)install Jupyter-related stuff

>&2 echo '(Re)installing Jupyter-related stuff...'
# JupyterHub pre-reqs: <https://github.com/jupyterhub/jupyterhub#installation>
sudo apt-get install -y nodejs
sudo npm install -g configurable-http-proxy
pip3 install --upgrade --requirement requirements.txt

## Post-install operations

prefix=$( pyenv prefix )
version=$( pyenv version-name | grep -oP '^\d+\.\d+' )

>&2 echo 'Updating sudo config...'
sudoers=/etc/sudoers.d/jupyterhub
cat <<EOF | sudo tee $sudoers >/dev/null
Defaults	secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:$prefix/bin"
Cmnd_Alias JUPYTER_CMD=$prefix/bin/sudospawner
jupyter ALL=(ALL) NOPASSWD:JUPYTER_CMD
EOF
sudo chmod 440 $sudoers

>&2 echo 'Migrating jupyter db...'
sudo -u jupyter jupyterhub upgrade-db

>&2 echo 'Patching static assets...'
patch-if-not-patched () {
  # if the patch can't be reversed, it probably hasn't been applied yet, so try
  # to apply it
  if ! patch --dry-run --reverse --silent --force $1 $2 >/dev/null; then
    patch $1 $2
  fi
}
patch-if-not-patched $prefix/share/jupyterhub/templates/login.html login.html.patch
patch-if-not-patched $prefix/lib/python$version/site-packages/notebook/static/components/codemirror/lib/codemirror.css codemirror.css.patch

# Maybe additional kernels...? But it's a bit of a hassle, and no one uses them
# anyway. For R, there's RStudio; Julia doesn't have a good solution for global
# package libraries yet; and no one should use Python 2 if 3 is available.

>&2 echo 'Configuring nbgrader...'

# install and enable all extensions for everyone
jupyter nbextension install --sys-prefix --py nbgrader --overwrite
jupyter nbextension enable --sys-prefix --py nbgrader
jupyter serverextension enable --sys-prefix --py nbgrader

# disable teacher extensions for everyone
jupyter nbextension disable --sys-prefix create_assignment/main
jupyter nbextension disable --sys-prefix --section=tree formgrader/main
jupyter serverextension disable --sys-prefix nbgrader.server_extensions.formgrader

# enable teacher extensions for current user
jupyter nbextension enable --user create_assignment/main
jupyter nbextension enable --user --section=tree formgrader/main
jupyter serverextension enable --user nbgrader.server_extensions.formgrader

# nbgrader config should be in one of the config directories listed by `jupyter
# --paths`
sudo mkdir -p /etc/jupyter
sudo cp nbgrader_config.py /etc/jupyter

## Restart services

>&2 echo 'Restarting services...'
sudo systemctl restart jupyterhub
sudo systemctl status jupyterhub
sudo systemctl restart jupyterhub_cull
sudo systemctl status jupyterhub_cull

## Final suggestions

cat <<'EOF' >&2

All done. If stuff is not working, then...

systemctl status jupyterhub
systemctl status jupyterhub_cull
journalctl -xeu jupyterhub
journalctl -xeu jupyterhub_cull

... and figure it out. You might also try generating a new config and starting
from there.
EOF
