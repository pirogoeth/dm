#!/usr/bin/env bash

# assuming the dm is hopefully in the PATH.
export dmcore=`which dm`
dmcore=${dmcore%/*}

if test ! -d ${HOME}/.dm ; then
    mkdir ${HOME}/.dm
fi

command=${1}

shift

for hook in $(ls ${dmcore}/hooks)
    do
        source ${dmcore}/hooks/${hook}
        result=`check ${command}`
        case $result in
            YES) run ${*}
                 exit
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
        echo -e "    `help.get`"
    done