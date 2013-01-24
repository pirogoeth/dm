#!/usr/bin/env bash

declare -a hook_help

# basically, this just checks if what is passed to the check function is whatever and if so, it gets run

_bold='\033[1;37m'
_none='\033[0m'

hook_help=(
    "${_bold}compile${_none}: compile using a normal java build script."
    "${_bold}c${_none}: alias for ${_bold}compile${_none}."
)

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
    if [ "${DM_DEBUG}" == "YES" ] ; then
        export plopts="-x"
    fi

    if [ "${DM_PROFILING}" == "YES" ] ; then
        time bash ${plopts} ${dmcore}/plugins/compile.sh ${@}
    else
        bash ${plopts} ${dmcore}/plugins/compile.sh ${@}
    fi
}