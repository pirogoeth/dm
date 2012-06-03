#!/usr/bin/env bash

declare -a hook_help

# basically, this just checks if what is passed to the check function is whatever and if so, it gets run

_bold='\033[1;37m'
_none='\033[0m'

hook_help=(
    "${_bold}bukkit-compile${_none}: compile using a bukkit build script."
    "${_bold}bukkit${_none}: alias for ${_bold}bukkit-compile${_none}."
)

function check() {
    if [[ ${1} == "bukkit-compile" ]] || [[ ${1} == "bukkit" ]] ; then
        echo "YES"
    else
        echo "NO"
    fi
}

function run() {
    # this shouldve been provided everything after the main args of dm have been shifted once.
    # basically, what couldve been `dm bukkit-compile -ph` will now appear as `-ph` to me :)
    bash ${dmcore}/plugins/bukkit-compile.sh ${*}
}
