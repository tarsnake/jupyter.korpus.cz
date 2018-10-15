#!/usr/bin/env zsh

set -e
cd ${0:a:h}

## Check system and R version

>&2 echo 'Your system is:'
lsb_release -a
>&2 echo

>&2 echo 'Your current version of R is:'
if ! R --version; then
  >&2 echo -e 'NO VERSION OF R FOUND\n'
  no_r=1
fi

## Add repo

cat <<'EOF' >&2
Go to <https://cran.r-project.org/bin/linux/ubuntu/> and check if a new version
of R is available for your system. If so, modify your /etc/apt/sources.list
file to include its repo.
EOF
read -q 'YN?Proceed?'
>&2 echo

## Backup list of packages

wipe-R-lib () {
  sudo rm -rf $1
  sudo mkdir -p $1
}

if [[ -z $no_r ]]; then
  >&2 echo 'Backing up list of installed packages...'
  ./backup_R_package_list.R
  sudo apt-get purge -y 'r-cran.*'
  wipe-R-lib /usr/lib/R/library
  wipe-R-lib /usr/lib/R/site-library
  wipe-R-lib /usr/local/lib/R/site-library
fi

## Install R

>&2 echo 'Installing R...'

sudo apt-get update
sudo apt-get install -y r-base r-base-dev

## Restore packages from list

if [[ -z $no_r ]]; then
  >&2 echo 'Restoring previously installed packages...'
  sudo ./reinstall_R_package_list.R packages.RData
  # rm -f packages.RData
fi
