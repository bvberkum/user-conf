
test_init()
{
  test -n "$uname" || uname=$(uname)
  hostname_vid="$(hostname -s | tr 'a-z.-' 'A-Z__')"
  local val=$(eval echo "\$${hostname_vid}_SKIP")
  test -n "$val" || export ${hostname_vid}_SKIP=1
}

init_bin()
{
  test_init
#  test -z "$PREFIX" && bin=$base || bin=$PREFIX/bin/$base
}

init_lib()
{
  test_init
  # XXX path to shared script files
  test -z "$PROJ_DIR" && lib=./script || lib=$PROJ_DIR/script
}

init()
{
  test -x $base && {
    init_bin
  }
  init_lib
}

is_skipped()
{
  local key=$(echo $1 | tr 'a-z' 'A-Z')
  local skipped=$(echo $(eval echo \$${key}_SKIP))
  test -n "$skipped" && return
  return 1
}

current_test_env()
{
  case $(hostname -s) in
    simza | vs1 ) hostname -s;;
    * ) whoami ;;
  esac
}

check_skipped_envs()
{
  # XXX hardcoded envs
  local skipped=0
  test -n "$1" && envs="$*" || envs="$(hostname -s) $(whoami)"
  cur_env=$(current_test_env)
  for env in $envs
  do
    is_skipped $env && {
        test "$cur_env" = "$env" && {
            skipped=1
        }
    } || continue
  done
  return $skipped
}

next_temp_file()
{
  test -n "$pref" || pref=script-mpe-test-
  local cnt=$(echo $(echo /tmp/${pref}* | wc -l) | cut -d ' ' -f 1)
  next_temp_file=/tmp/$pref$cnt
}

lines_to_file()
{
  echo "status=${status}"
  echo "#lines=${#lines[@]}"
  echo "lines=${lines[*]}"
  test -n "$1" && file=$1
  test -n "$file" || { next_temp_file; file=$next_temp_file; }
  echo file=$file
  local line_out
  echo "# test/helper.bash $(date)" > $file
  for line_out in "${lines[@]}"
  do
    echo $line_out >> $file
  done
}

tmpf()
{
  tmpd || return $?
  tmpf=$tmpd/$BATS_TEST_NAME-$BATS_TEST_NUMBER
  test -z "$1" || tmpf="$tmpf-$1"
}

tmpd()
{
  tmpd=$BATS_TMPDIR/bats-tempd
  mkdir -vp $tmpd
}

