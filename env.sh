# Site specific shell setup. Gives all users access to pyenv, so that they can
# use a different Python version than the system one by default, and switch
# between Python versions if they want.

export PYENV_ROOT=/opt/pyenv
export PATH=$PYENV_ROOT/bin:$PATH

if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

export NLTK_DATA=/opt/jupyter/nltk_data
