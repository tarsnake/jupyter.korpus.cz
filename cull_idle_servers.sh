#!/bin/sh

. .venv/bin/activate
export JPY_API_TOKEN=`jupyterhub token lukes 2>/dev/null`
./cull_idle_servers.py
