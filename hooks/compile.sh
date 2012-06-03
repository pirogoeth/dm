#!/usr/bin/env bash

# basically, this just checks if what is passed to the check function is whatever and if so, it gets run

_bold='\033[1;37m'
_none='\033[0m'

function help.get() {
    echo "${_bold}compile${_none}: compile using a normal java build script."
    echo "    ${_bold}c${_none}: alias for ${_bold}compile${_none}."
}

function check() {
    if [[ ${1} == "compile" ]] || [[ ${1} == "c" ]] ; then
        echo "YES"
    else
        echo "NO"
    fi
}

function run() {
    # this shouldve been provided everything after the main args of dm have been shifted once.
    # basically, what couldve been `dm compile -ph` will now appear as `-ph` to me :)
    bash ${dmcore}/plugins/compile.sh ${*}
}