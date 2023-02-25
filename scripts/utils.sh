#! /bin/bash
# Serene Programming Language
#
# Copyright (c) 2019-2023 Sameer Rahmani <lxsameer@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 2.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -e

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------
function fn-names() {
    grep -E '^function [0-9a-zA-Z_-]+\(\) \{ ## .*$$' "$0" | sed 's/^function \([a-zA-Z0-9_-]*\)() { ## \(.*\)/\1/'
}

function info() {
    if [ "$1" ]
    then
        echo -e "[\033[01;32mINFO\033[00m]: $*"
    fi
}

function error() {
    if [ "$1" ]
    then
        echo -e "[\033[01;31mERR\033[00m]: $*"
    fi
}

function warn() {
    if [ "$1" ]
    then
        echo -e "[\033[01;33mWARN\033[00m]: $*"
    fi
}

function yes_or_no {
    while true; do
        read -rp "$* [y/n]: " yn
        case $yn in
            [Yy]*) return 0  ;;
            [Nn]*) echo "Aborted" ; return  1 ;;
        esac
    done
}

function _push() {
    pushd "$1" > /dev/null || return
}


function _pop() {
    popd > /dev/null || return
}

function get_version() {
    # _push "$1"
    # git describe --abbrev=40
    # _pop

    git ls-tree HEAD "$1" | awk '{ print $3 }'
}

function http_push() {
    if [[ -z "$DEV_HEROES_TOKEN" ]]; then
        error "\$DEV_HEROES_TOKEN is not set."
        exit 1
    fi

    local pkg_name
    local version

    pkg_name="$1"
    version="$2"

    curl "$DEV_HEROES/api/packages/serene/generic/$pkg_name/$version/$pkg_name.$version.zstd" \
         --upload-file "$pkg_name.$version.zstd" \
         --progress-bar \
         -H "accept: application/json" \
         -H "Authorization: token $DEV_HEROES_TOKEN" \
         -H "Content-Type: application/json"
}

function http_pull() {
    local pkg_name
    local version
    local output
    local url

    pkg_name="$1"
    version="$2"
    output="$3"
    url="$DEV_HEROES/api/packages/serene/generic/$pkg_name/$version/$pkg_name.$version.zstd"

    info "Fetching '$url'..."

    if curl "$url" --fail --progress-bar -o "$output"; then
        return 0
    else
        return 4
    fi
}

function clone_dep() {
    local dest
    local repo
    local version
    repo="$1"
    version="$2"
    dest="$3"

    if [[ -d "$dest" ]]; then
        return
    fi

    #mkdir -p "$dest"

    #git init -b master
    git clone --depth=1 "$repo" "$dest"
    _push "$dest"
    #git remote add origin "$repo"
    git fetch --depth=1 --filter=tree:0 origin "$version"
    git reset --hard FETCH_HEAD
    _pop
}
