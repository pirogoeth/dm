#!/usr/bin/env bash

# assuming the dm is hopefully in the PATH.
export dmcore=`which dm`
dmcore=${dmcore%/*}

# colours
_bold='\033[1;37m'
_none='\033[0m'

if test ! -d ${HOME}/.dm ; then
    mkdir ${HOME}/.dm
fi

command=${1}
shift

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

for hook in $(ls ${dmcore}/hooks)
    do
        source ${dmcore}/hooks/${hook}
        result=`check ${command}`
        case $result in
            YES) if [[ `actionallowed ${command}` == "YES" ]] ; then
                     run ${*}
                     exit
                 else
                     echo -e "Action ${_bold}${command}${_none} is not allowed for this project."
                     exit
                 fi
            ;;
            NO) continue
            ;;
        esac
    done

# if you're this far, it means you fail at life.

echo "dm version 0.1 by pirogoeth <pirogoeth@me.com>"
echo 
echo "  dm is an extensible dependency and build manager for java projects."
echo "  list of hooked commands:"

for hook in $(ls ${dmcore}/hooks)
    do
        source ${dmcore}/hooks/${hook}
        for (( i=0; $i<${#hook_help[@]}; i++ ))
            do
                echo -e "    ${hook_help[${i}]}"
            done
    done

if [[ `projectdir` == "YES" ]] ; then
    source ${PWD}/.dm/config
    echo "  actions allowed on this project:"
    for (( i=0; $i<${#dm_allowed_actions[@]}; i++ ))
        do
            echo -e "    ${_bold}${dm_allowed_actions[${i}]}"
        done
fi