#!/usr/bin/env bash

set -e

test -z "$Build_Debug" || set -x

test -z "$Build_Deps_Default_Paths" || {
  test -n "$SRC_PREFIX" || SRC_PREFIX=$HOME/build
  test -n "$PREFIX" || PREFIX=$HOME/.local
}

test -n "$sudo" || sudo=

test -n "$SRC_PREFIX" || {
  echo "Not sure where checkout"
  exit 1
}

test -n "$PREFIX" || {
  echo "Not sure where to install"
  exit 1
}

test -d $SRC_PREFIX || ${sudo} mkdir -vp $SRC_PREFIX
test -d $PREFIX || ${sudo} mkdir -vp $PREFIX


install_bats()
{
  echo "Installing bats"
  local pwd=$(pwd)
  mkdir -vp $SRC_PREFIX
  cd $SRC_PREFIX
  git clone https://github.com/dotmpe/bats.git
  cd bats
  ${sudo} ./install.sh $PREFIX
  cd $pwd
}

install_git_versioning()
{
  git clone https://github.com/dotmpe/git-versioning.git $SRC_PREFIX/git-versioning
  ( cd $SRC_PREFIX/git-versioning && ./configure.sh $PREFIX && ENV=production ./install.sh )
}

install_docopt()
{
  test -n "$sudo" || install_f="--user"
  git clone https://github.com/dotmpe/docopt-mpe.git $SRC_PREFIX/docopt-mpe
  ( cd $SRC_PREFIX/docopt-mpe \
      && git checkout 0.6.x \
      && $sudo python ./setup.py install $install_f )
}

install_apenwarr_redo()
{
  test -n "$global" || {
    test -n "$sudo" && global=1 || global=0
  }

  test $global -eq 1 && {

    test -d /usr/local/lib/python2.7/site-packages/redo \
      || {

        $sudo git clone https://github.com/apenwarr/redo.git \
            /usr/local/lib/python2.7/site-packages/redo || return 1
      }

    test -h /usr/local/bin/redo \
      || {

        $sudo ln -s /usr/local/lib/python2.7/site-packages/redo/redo \
            /usr/local/bin/redo || return 1
      }

  } || {

    which basher 2>/dev/null >&2 && {

      basher install apenwarr/redo
    } || {

      echo "Need basher to install apenwarr/redo locally" >&2
      return 1
    }
  }
}


main_entry()
{
  test -n "$1" || set -- '-'

  case "$1" in '-'|project|git )
      git --version >/dev/null || {
        echo "Sorry, GIT is a pre-requisite"; exit 1; }
      which pip >/dev/null || {
        cd /tmp/ && wget https://bootstrap.pypa.io/get-pip.py && python get-pip.py; }
      pip install setuptools objectpath \
        || exit $?
    ;; esac

  case "$1" in '-'|build|test|sh-test|bats )
      test -x "$(which bats)" || { install_bats || return $?; }
    ;; esac

  case "$1" in '-'|dev|build|check|test|git-versioning )
      test -x "$(which git-versioning)" || {
        install_git_versioning || return $?; }
    ;; esac

  case "$1" in '-'|python|project|docopt)
      # Using import seems more robust than scanning pip list
      python -c 'import docopt' || { install_docopt || return $?; }
    ;; esac

  case "$1" in '-'|redo )
      install_apenwarr_redo || return $?
    ;; esac

  echo "OK. All pre-requisites for '$1' checked"
}

test "$(basename $0)" = "install-dependencies.sh" && {
  while test -n "$1"
  do
    main_entry "$1" || exit $?
    shift
  done
} || printf ""

# Id: user-conf-mpe
