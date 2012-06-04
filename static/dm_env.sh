#!/usr/bin/env bash
shopt -s extglob checkhash globstar

declare -a startup

# this environment is for special purposes, like setting up a new
# dm environment.

startup=( "${HOME}/.bashrc" "${HOME}/.profile" "${HOME}/.smartcd_config" )

for (( i=0; $i<${#startup[@]}; i++ ))
    do
        if test -e ${startup[${i}]}; then
            source ${startup[${i}]}
        fi
    done

function dmplugindir() {
    # $1: name of the plugin (plugin names and plugin dir name
    #     is coordinated
    # $2: force (return where the directory WOULD be.)
    if test ! -z ${2} ; then
        echo "${dmcore}/${1}"
        return
    fi
    if test -d ${dmcore}/${1} ; then
        echo "${dmcore}/${1}"
    else
        mkdir -p ${dmcore}/${1}/{hooks,plugins,data}
        echo "${dmcore}/${1}"
    fi
}

function projectdir() {
    # tells if current dir is a project dir
    if test -d ${PWD}/.dm && test -e ${PWD}/.dm/config ; then
        echo "YES"
    else
        echo "NO"
    fi
}

function actionallowed() {
    if [[ `projectdir` == YES ]] ; then
        source ${PWD}/.dm/config
        # tells if the action/command is allowed in the current project.
        for (( i=0; $i<${#dm_allowed_actions[@]}; i++ ))
            do
                if [[ ${dm_allowed_actions[${i}]} == ${1} ]] ; then
                    echo "YES"
                    return
                else
                    continue
                fi
            done
        echo "NO"
    else
        echo "YES"
    fi
}