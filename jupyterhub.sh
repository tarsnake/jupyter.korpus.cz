#!/bin/sh

. .venv/bin/activate
rm debug
which jupyterhub >debug
which python >>debug
which python3 >>debug
jupyterhub
