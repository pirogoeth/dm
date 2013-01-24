#!/usr/bin/env bash

declare -a hook_help

# bash colour codes for pretty printing :)

_bold='\033[1;37m'
_none='\033[0m'

# help data for the hook

hook_help=(
    "${_bold}init${_none}: initialises a new dm project in the current directory."
    "${_bold}initialise${_none}: alias for ${_bold}init${_none}."
)

# this checks if the first arg (the command) passed to dm matches this hook.

function check() {
    if [[ ${1} == "init" ]] || [[ ${1} == "initialise" ]] || [[ ${1} == "initialize" ]] ; then
        echo "YES"
    else
        echo "NO"
    fi
}

function run() {
    # run the plugin, like a bau5
    if [ "${DM_DEBUG}" == "YES" ] ; then
        export plopts="-x"
    fi

    if [ "${DM_PROFILING}" == "YES" ] ; then
        time bash ${plopts} ${dmcore}/plugins/init.sh ${@}
    else
        bash ${plopts} ${dmcore}/plugins/init.sh ${@}
    fi
}