#!/usr/bin/env bash

function makepkg() {
  set -euo pipefail

  local _INPUTDIR="$(
    cd "$1"
    pwd -P
  )"
  local _PARAMS="${@:2}"

  if [[ ! -f "${_INPUTDIR}/PKGTAG" ]]; then
    echo "\"${_INPUTDIR}\" doesn't look like a valid input directory."
    return 14
  elif [[ $(cat ${_INPUTDIR}/PKGBUILD) ]]; then
    echo "\"${_INPUTDIR}\" was not prepared correctly."
    return 15
  elif [[ -f "${_INPUTDIR}/building.pid" ]]; then
    echo 'This package is already building.'
    return 16
  fi

  echo -n $$ >"${_INPUTDIR}/building.pid"

  if [[ ! -e "${CAUR_LOWER_DIR}/latest" ]]; then
    lowerstrap || return $?
  fi

  pushd "${_INPUTDIR}"
  [[ -e 'building.result' ]] && rm 'building.result'
  local _PKGTAG=$(cat PKGTAG)
  local _INTERFERE="${CAUR_INTERFERE}/${_PKGTAG}"
  local _LOWER="$(
    cd "${CAUR_LOWER_DIR}"
    cd $(readlink latest)
    pwd -P
  )"

  local _HOME="machine/root/home/${CAUR_GUEST_USER}"
  local _CCACHE="${CAUR_CACHE_CC}/${_PKGTAG}"
  local _SRCCACHE="${CAUR_CACHE_SRC}/${_PKGTAG}"
  local _PKGDEST="${_HOME}/pkgdest"
  local _CAUR_WIZARD="machine/root/home/${CAUR_GUEST_USER}/${CAUR_BASH_WIZARD}"

  mkdir -p machine/{up,work,root} dest{,.work} "${_CCACHE}" "${_SRCCACHE}" "${CAUR_CACHE_PKG}" "${CAUR_DEST_PKG}"
  mount overlay -t overlay -olowerdir=${_LOWER},upperdir=machine/up,workdir=machine/work machine/root
  chown ${CAUR_GUEST_UID}:${CAUR_GUEST_GID} "${_CCACHE}" "${_SRCCACHE}" "${CAUR_CACHE_PKG}" dest

  mount --bind 'pkgwork' "${_HOME}/pkgwork"
  mount --bind "${_CCACHE}" "${_HOME}/.ccache"
  mount --bind "${_SRCCACHE}" "${_HOME}/pkgsrc"
  mount --bind "${CAUR_CACHE_PKG}" 'machine/root/var/cache/pacman/pkg'
  if [[ "${CAUR_HACK_USEOVERLAYDEST}" == '1' ]]; then
    mount overlay -t overlay \
      -olowerdir=${CAUR_DEST_PKG},upperdir=./dest,workdir=./dest.work \
      "${_PKGDEST}"
  else
    mount --bind 'dest' "${_PKGDEST}"
  fi

  cp "${CAUR_BASH_WIZARD}" "${_CAUR_WIZARD}"
  chown ${CAUR_GUEST_UID}:${CAUR_GUEST_GID} -R "${_CAUR_WIZARD}" pkgwork
  chmod 755 "${_CAUR_WIZARD}"

  local _MECHA_NAME="pkg$(echo -n "$_PKGTAG" | sha256sum | cut -c1-11)"
  local _BUILD_FAILED=''
  systemd-nspawn -M ${_MECHA_NAME} \
    -u "${CAUR_GUEST_USER}" \
    --capability=CAP_IPC_LOCK,CAP_SYS_NICE \
    -D machine/root \
    "/home/${CAUR_GUEST_USER}/wizard.sh" ${_PARAMS} || local _BUILD_FAILED="$?"

  if [[ -z "${_BUILD_FAILED}" ]]; then
    echo 'success' >'building.result'
  elif [[ -f "${_INTERFERE}/on-failure.sh" ]]; then
    echo "${_BUILD_FAILED}" >'building.result'
    source "${_INTERFERE}/on-failure.sh"
  fi

  umount -Rv machine/root \
    && rm --one-file-system -rf machine

  rm 'building.pid'
  popd # "${_INPUTDIR}"
  [[ -n "${_BUILD_FAILED}" ]] \
    && return ${_BUILD_FAILED}
  return 0
}
