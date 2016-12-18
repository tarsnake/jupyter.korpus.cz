#!/usr/bin/env zsh

export NLTK_DATA=/opt/jupyter/nltk_data
source venv/bin/activate
jupyter lab --port 1993 --notebook-dir $HOME --no-browser
