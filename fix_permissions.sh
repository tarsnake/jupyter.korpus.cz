#!/bin/sh

if [ $# -ne 1 ]; then
  >&2 echo "Usage: $0 <name-of-user-under-whom-jupyterhub-will-be-running>"
  exit 1
fi

files=". jupyterhub.sqlite jupyterhub_cookie_secret debug"

for file in $files; do
  chown "$1"."$1" "$file"
done

chmod 755 .
chmod 644 jupyterhub.sqlite
chmod 644 debug
chmod 600 jupyterhub_cookie_secret

