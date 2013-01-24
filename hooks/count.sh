#!/usr/bin/env bash

declare -a hook_help

# basically, this just checks if what is passed to the check function is whatever and if so, it gets run

_bold='\033[1;37m'
_none='\033[0m'

hook_help=(
    "${_bold}count${_none}: counts the number of lines in a project."
)

function check() {
    if [[ ${1} == "count" ]] ; then
        echo "YES"
    else
        echo "NO"
    fi
}

function run() {
    # this shouldve been provided everything after the main args of dm have been shifted once.
    if [ "${DM_DEBUG}" == "YES" ] ; then
        export plopts="-x"
    fi

    if [ "${DM_PROFILING}" == "YES" ] ; then
        time bash ${plopts} ${dmcore}/plugins/count.sh ${@}
    else
        bash ${plopts} ${dmcore}/plugins/count.sh ${@}
    fi
}