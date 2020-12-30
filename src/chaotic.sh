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
CAUR_DEPLOY_HOST='builds.garudalinux.org'
CAUR_DEPLOY_PATH='/srv/http/repos/chaotic-aur/x86_64/'
CAUR_SCP_STREAMS=1
CAUR_BASH_WIZARD='wizard.sh'
CAUR_CACHE_CC='/var/cache/chaotic/cc'
CAUR_CACHE_PKG='/var/cache/chaotic/packages'
CAUR_CACHE_SRC='/var/cache/chaotic/sources'
CAUR_DB_EXT='tar.zst'
CAUR_DB_LOCK='/var/cache/chaotic/db.lock'
CAUR_DEST_LAST="/srv/http/chaotic-aur/lastupdate"
CAUR_DEST_PKG="/srv/http/${CAUR_DB_NAME}/x86_64"
CAUR_FILL_DEST='https://builds.garudalinux.org/repos/chaotic-aur/pkgs.files.txt'
CAUR_GUEST="${CAUR_PREFIX}/lib/chaotic/guest"
CAUR_LIB="${CAUR_PREFIX}/lib/chaotic"
CAUR_LOWER_DIR='/var/cache/chaotic/lower'
CAUR_LOWER_PKGS=(base base-devel)
CAUR_ROUTINES='/tmp/chaotic/routines'
CAUR_SANDBOX='/tmp/chaotic/sandbox'
CAUR_SIGN_KEY=''
CAUR_SIGN_USER='root' # who owns the key in gnupg's keyring.
CAUR_TYPE='primary'   # only the primary cluster manages the database.
CAUR_URL="http://localhost/${CAUR_DB_NAME}/x86_64"
CAUR_GPG_PATH="/usr/bin/gpg"
CAUR_OVERLAY_TYPE='kernel'
CAUR_DOCKER_ALPINE="docker://registry.gitlab.com/jitesoft/dockerfiles/alpine"

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

  local _CMD

  _CMD="${1:-}"
  # Note: there is usage of "${@:2}" below.

  case "${_CMD}" in
  '--jobs' | '-j')
    optional-parallel "${2:-}"
    main "${@:3}"
    ;;
  'prepare' | 'pr')
    prepare "${@:2}"
    ;;
  'lowerstrap' | 'lw')
    lowerstrap "${@:2}"
    ;;
  'makepkg' | 'mk')
    makepkg "${@:2}"
    ;;
  'makepwd' | 'mkd')
    makepwd "${@:2}"
    ;;
  'iterfere-sync' | 'si')
    iterfere-sync "${@:2}"
    ;;
  'deploy' | 'dp')
    deploy "${@:2}"
    ;;
  'db-bump' | 'dbb')
    db-bump "${@:2}"
    ;;
  'remove' | 'rm')
    remove "${@:2}"
    ;;
  'aur-download' | 'get')
    aur-download "${@:2}"
    ;;
  'cleanup' | 'cl')
    cleanup "${@:2}"
    ;;
  'help' | '?')
    help-mirror "${@:2}"
    ;;
  'routine')
    routine "${@:2}"
    ;;
  'clean-logs' | 'clg')
    clean-logs
    ;;
  'reset-fakeroot-chown' | 'rfc')
    reset-fakeroot-chown "${@:2}"
    ;;
  *)
    echo 'Wrong usage, check https://github.com/chaotic-aur/toolbox/blob/main/README.md for details on how to use.'
    return 254
    ;;
  esac
}

main "$@"
