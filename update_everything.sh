#!/usr/bin/env zsh

pip=/opt/jupyter/.venv/bin/pip
conda_env=python-3.6
python=/opt/miniconda3/envs/$conda_env/bin/python

>&2 echo 'Updating server packages in 5s... (this might require migrating the JupyterHub schema)'
sleep 5s
$pip freeze |
  cut -f1 -d= |
  xargs $pip install --upgrade
$pip freeze >server_requirements.txt

# restore Conda Python 3 kernel (it might have been clobbered and overwritten
# by the system Python 3 used by the server)
>&2 echo 'Restoring Conda Python 3 kernel...'
$python -m ipykernel install --prefix /opt/jupyter/.venv --name python3 --display-name 'Python 3'

>&2 echo 'Updating Conda packages...'
conda update --all
conda env export --name $conda_env >kernel_environment.yml

# restart services
>&2 echo 'Restarting services...'
sudo systemctl restart jupyterhub
sudo systemctl restart jupyterhub_cull
