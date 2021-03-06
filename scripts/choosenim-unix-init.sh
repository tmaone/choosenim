#!/bin/sh
# Copyright 2017 Dominik Picheta and Nim developers.
#
# Licensed under the MIT license.
#
# This script performs some platform detection, downloads the latest version
# of choosenim and initiates its installation.

set -u
set -e

url_prefix="https://github.com/dom96/choosenim/releases/download/"

install() {
  get_platform || return 1
  local platform=$RET_VAL
  local stable_version=`curl -sSfL https://nim-lang.org/choosenim/stable`
  local filename="choosenim-$stable_version"_"$platform"
  local url="$url_prefix"v"$stable_version/$filename"

  case $platform in
    *macosx_amd64* | *linux_amd64* )
      ;;
    * )
      say_err "Sorry, your platform ($platform) is not supported by choosenim."
      say_err "You will need to install Nim using an alternative method."
      say_err "See the following link for more info: https://nim-lang.org/install.html"
      exit 1
      ;;
  esac

  say "Downloading $filename"
  curl -sSfL "$url" -o "/tmp/$filename"
  chmod +x "/tmp/$filename"

  # The installer is going to want to ask for confirmation by
  # reading stdin.  This script was piped into `sh` though and
  # doesn't have stdin to pass to its children. Instead we're going
  # to explicitly connect /dev/tty to the installer's stdin.
  if [ ! -t 1 ]; then
    # TODO: Support `-y` flag.
    err "Unable to run interactively."
  fi

  # Install Nim from stable channel.
  "/tmp/$filename" stable < /dev/tty

  # Copy choosenim binary to Nimble bin.
  local nimbleBinDir=`"/tmp/$filename" --getNimbleBin`
  cp "/tmp/$filename" "$nimbleBinDir/choosenim"
  say "ChooseNim installed in $nimbleBinDir"
  say "You must now ensure that the Nimble bin dir is in your PATH."
  say "Place the following line in the ~/.profile or ~/.bashrc file."
  say "    export PATH=$nimbleBinDir:\$PATH"
}

get_platform() {
  # Get OS/CPU info and store in a `myos` and `mycpu` variable.
  local ucpu=`uname -m`
  local uos=`uname`
  local ucpu=`echo $ucpu | tr "[:upper:]" "[:lower:]"`
  local uos=`echo $uos | tr "[:upper:]" "[:lower:]"`

  case $uos in
    *linux* )
      local myos="linux"
      ;;
    *dragonfly* )
      local myos="freebsd"
      ;;
    *freebsd* )
      local myos="freebsd"
      ;;
    *openbsd* )
      local myos="openbsd"
      ;;
    *netbsd* )
      local myos="netbsd"
      ;;
    *darwin* )
      local myos="macosx"
      if [ "$HOSTTYPE" = "x86_64" ] ; then
        local ucpu="amd64"
      fi
      ;;
    *aix* )
      local myos="aix"
      ;;
    *solaris* | *sun* )
      local myos="solaris"
      ;;
    *haiku* )
      local myos="haiku"
      ;;
    *mingw* )
      local myos="windows"
      ;;
    *)
      err "unknown operating system: $uos"
      ;;
  esac

  case $ucpu in
    *i386* | *i486* | *i586* | *i686* | *bepc* | *i86pc* )
      local mycpu="i386" ;;
    *amd*64* | *x86-64* | *x86_64* )
      local mycpu="amd64" ;;
    *sparc*|*sun* )
      local mycpu="sparc"
      if [ "$(isainfo -b)" = "64" ]; then
        local mycpu="sparc64"
      fi
      ;;
    *ppc64* )
      local mycpu="powerpc64" ;;
    *power*|*ppc* )
      local mycpu="powerpc" ;;
    *mips* )
      local mycpu="mips" ;;
    *arm*|*armv6l* )
      local mycpu="arm" ;;
    *aarch64* )
      local mycpu="arm64" ;;
    *)
      err "unknown processor: $ucpu"
      ;;
  esac

  RET_VAL="$myos"_"$mycpu"
}

say() {
  echo "choosenim-init: $1"
}

say_err() {
  say "Error: $1" >&2
}

err() {
  say_err "$1"
  exit 1
}

install