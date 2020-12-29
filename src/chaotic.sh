#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2164

pushd() { command pushd "$@" >/dev/null; }
popd() { command popd >/dev/null; }
stee() { command tee "$@" >/dev/null; }

pushd "$(dirname "$0")/.." || exit 2
CAUR_PREFIX="$(pwd -P)"
popd || exit 2

CAUR_DB_NAME='chaotic-aur'
CAUR_INTERFERE='/var/lib/chaotic/interfere'

CAUR_ENGINE="systemd-nspawn"
CAUR_ADD_DEST="builds.garudalinux.org:~/chaotic/queues/$(whoami)/"
CAUR_BASH_WIZARD='wizard.sh'
CAUR_CACHE_CC='/var/cache/chaotic/cc'
CAUR_CACHE_PKG='/var/cache/chaotic/packages'
CAUR_CACHE_SRC='/var/cache/chaotic/sources'
CAUR_DB_EXT='tar.zst'
CAUR_DB_LOCK='/var/cache/chaotic/db.lock'
CAUR_DEPLOY_DEST='builds.garudalinux.org'
CAUR_DEST_LAST="/srv/http/chaotic-aur/lastupdate"
CAUR_DEST_PKG="/srv/http/${CAUR_DB_NAME}/x86_64"
CAUR_GUEST="${CAUR_PREFIX}/lib/chaotic/guest"
CAUR_LIB="${CAUR_PREFIX}/lib/chaotic"
CAUR_HACK_USEOVERLAYDEST=1
CAUR_LOWER_DIR='/var/cache/chaotic/lower'
CAUR_LOWER_PKGS=(base base-devel)
CAUR_SANDBOX='/tmp/chaotic/sandbox'
CAUR_ROUTINES='/tmp/chaotic/routines'
CAUR_SIGN_KEY=''
CAUR_SIGN_USER='root' # who owns the key in gnupg's keyring.
CAUR_TYPE='primary'   # only the primary cluster manages the database.
CAUR_URL="http://localhost/${CAUR_DB_NAME}/x86_64"
CAUR_GPG_PATH="/usr/bin/gpg"
CAUR_OVERLAY_TYPE='fuse'

# shellcheck source=/dev/null
[[ -f '/etc/chaotic.conf' ]] && source '/etc/chaotic.conf'

# shellcheck source=/dev/null
[[ -f "$HOME/.chaotic/chaotic.conf" ]] && source "$HOME/.chaotic/chaotic.conf"

if [ "$EUID" -ne 0 ] && [ "$CAUR_ENGINE" != "singularity" ]; then
  echo 'This script must be run as root.'
  exit 255
fi

shopt -s extglob
for _LIB in "${CAUR_LIB}"/*.sh; do
  # shellcheck source=src/lib/*
  source "${_LIB}"
done

function main() {
  set -euo pipefail

  local _CMD _PARAMS

  _CMD="${1:-}"
  _PARAMS=("${@:2}")

  case "${_CMD}" in
  'prepare' | 'pr')
    prepare "${_PARAMS[@]+"${_PARAMS[@]}"}"
    ;;
  'lowerstrap' | 'lw')
    lowerstrap "${_PARAMS[@]+"${_PARAMS[@]}"}"
    ;;
  'makepkg' | 'mk')
    makepkg "${_PARAMS[@]+"${_PARAMS[@]}"}"
    ;;
  'makepwd' | 'mkd')
    makepwd "${_PARAMS[@]+"${_PARAMS[@]}"}"
    ;;
  'iterfere-sync' | 'si')
    iterfere-sync "${_PARAMS[@]+"${_PARAMS[@]}"}"
    ;;
  'deploy' | 'dp')
    deploy "${_PARAMS[@]+"${_PARAMS[@]}"}"
    ;;
  'db-bump' | 'dbb')
    db-bump "${_PARAMS[@]+"${_PARAMS[@]}"}"
    ;;
  'remove' | 'rm')
    remove "${_PARAMS[@]+"${_PARAMS[@]}"}"
    ;;
  'aur-download' | 'get')
    aur-download "${_PARAMS[@]+"${_PARAMS[@]}"}"
    ;;
  'cleanup' | 'cl')
    cleanup "${_PARAMS[@]+"${_PARAMS[@]}"}"
    ;;
  'help' | '?')
    help-mirror "${_PARAMS[@]+"${_PARAMS[@]}"}"
    ;;
  'routine')
    routine "${_PARAMS[@]+"${_PARAMS[@]}"}"
    ;;
  'clean-logs' | 'clg')
    clean-logs
    ;;
  *)
    echo 'Wrong usage, check https://github.com/chaotic-aur/toolbox/blob/main/README.md for details on how to use.'
    return 254
    ;;
  esac
}

main "$@"
