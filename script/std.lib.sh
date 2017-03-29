#!/bin/sh


# std: logging and dealing with the shell's stdio decriptors

stdio_type()
{
  local io= pid=
  test -n "$1" && io=$1 || io=1
  test -n "$uname" || uname=$(uname)
  test -x "$(which file)" || error "file util required for stdio-type" 1
  case "$uname" in

    Linux )
        test -n "$2" && pid=$2 || pid=$$
        test -e /proc/$pid/fd/${io} || error "No $uname FD $io"
        if readlink /proc/$pid/fd/$io | grep -q "^pipe:"; then
          export stdio_${io}_type=p
        elif file $( readlink /proc/$pid/fd/$io ) | grep -q 'character.special'; then
          export stdio_${io}_type=t
        else
          export stdio_${io}_type=f
        fi
      ;;

    Darwin )

        test -e /dev/fd/${io} || error "No $uname FD $io"
        if file /dev/fd/$io | grep -q 'named.pipe'; then
          export stdio_${io}_type=p
        elif file /dev/fd/$io | grep -q 'character.special'; then
          export stdio_${io}_type=t
        else
          export stdio_${io}_type=f
        fi
      ;;

  esac
}

var_log_key()
{
  test -n "$log_key" || {
    test -n "$log" && {
      log_key="$log"
    } || {
      test -n "$base" && {
        log_key=$base.sh
      }
    }
    # add stdin/out/err type symbol
    log_key=$log_key:$stdio_0_type/$stdio_1_type/$stdio_2_type
  }
}

# stdio helper functions
log()
{
  var_log_key
  printf -- "[$log_key] $1\n"
  unset log_key
}

err()
{
  # TODO: turn this on and fix tests warn "err() is deprecated, see stderr()"
  log "$1" 1>&2
  test -z "$2" || exit $2
}

stderr()
{
  case "$(echo $1 | tr 'A-Z' 'a-z')" in
    warn*|err*|notice ) err "$1: $2" "$3" ;;
    * ) err "$2" "$3" ;;
  esac
}

# std-v <level>
# if verbosity is defined, return non-zero if <level> is below verbosity treshold
std_v()
{
  test -z "$verbosity" && return || {
    test $verbosity -ge $1 && return || return 1
  }
}

std_exit()
{
  test "$1" != "0" -a -z "$1" && return 1 || exit $1
}

emerg()
{
  std_v 1 || std_exit $2 || return 0
  stderr "Emerg" "$1" $2
}
crit()
{
  std_v 2 || std_exit $2 || return 0
  stderr "Crit" "$1" $2
}
error()
{
  std_v 3 || std_exit $2 || return 0
  stderr "Error" "$1" $2
}
warn()
{
  std_v 4 || std_exit $2 || return 0
  stderr "Warning" "$1" $2
}
note()
{
  std_v 5 || std_exit $2 || return 0
  stderr "Notice" "$1" $2
}
# FIXME: core tool name
info()
{
  std_v 6 || std_exit $2 || return 0
  stderr "Info" "$1" $2
}
debug()
{
  std_v 7 || std_exit $2 || return 0
  stderr "Debug" "$1" $2
}


