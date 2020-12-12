#!/usr/bin/env bash
function interference-apply() {
  set -euo pipefail

  local _INTERFERE="$1"

  interference-generic "${_PKGTAG}"

  [[ -f "${_INTERFERE}/prepare" ]] \
    && source "${_INTERFERE}/prepare"

  if [[ -f "${_INTERFERE}/PKGBUILD.prepend" ]]; then
    # The worst one, but KISS and easier to maintain
    local _PREPEND="$(cat "${_INTERFERE}/PKGBUILD.prepend")"
    local _PKGBUILD="$(cat PKGBUILD)"
    echo "$_PREPEND" >PKGBUILD
    echo "$_PKGBUILD" >>PKGBUILD
  fi

  [[ -f "${_INTERFERE}/PKGBUILD.append" ]] \
    && cat "${_INTERFERE}/PKGBUILD.append" >>PKGBUILD

  return 0
}

function interference-generic() {
  set -euo pipefail

  local _PKGTAG="$1"

  # * CHROOT Update
  $CAUR_PUSH sudo pacman -Syu --noconfirm

  # * Treats VCs
  if [[ ! -z "$(echo "$_PKGTAG" | grep -P '\-git$')" ]]; then
    $CAUR_PUSH sudo pacman -S --needed --noconfirm git
  fi
  if [[ ! -z "$(echo "$_PKGTAG" | grep -P '\-svn$')" ]]; then
    $CAUR_PUSH sudo pacman -S --needed --noconfirm subversion
  fi
  if [[ ! -z "$(echo "$_PKGTAG" | grep -P '\-bzr$')" ]]; then
    $CAUR_PUSH sudo pacman -S --needed --noconfirm breezy
  fi
  if [[ ! -z "$(echo "$_PKGTAG" | grep -P '\-hg$')" ]]; then
    $CAUR_PUSH sudo pacman -S --needed --noconfirm mercurial
  fi

  # * Read options
  if [[ ! -z $(grep -Po "^options=\([a-z! \"']*(?<!!)ccache[ '\"\)]" PKGBUILD) ]]; then
    $CAUR_PUSH sudo pacman -S --needed --noconfirm ccache
  fi

  # * People who think they're smart
  if [[ ! -z "$(grep -P '^PKGEXT=' PKGBUILD)" ]]; then
    sed -i'' 's/^PKGEXT=.*$//g' PKGBUILD
  fi

  return 0
}

function interference-makepkg() {
  set -euo pipefail

  $CAUR_PUSH exec /usr/local/bin/internal-makepkg -s --noprogressbar $@ \$\@

  return 0
}
