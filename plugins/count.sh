#!/usr/bin/env bash
shopt -s extglob checkhash globstar

# try to import the current configuration
if test ! -d .dm ; then
    if test "`dirlocate .dm /`" != "" ; then
        source `dirlocate .dm /`/config
        break
    fi
    echo "dm configuration directory does not exist, creating skeleton!"
    mkdir -p .dm/deps
    cat ${dmcore}/static/config.def >> .dm/config
    echo "exiting."
    exit 1
elif test -d .dm && test -e .dm/config ; then
    source .dm/config
fi

# ==============================================================================================================
# bash colour codes
#
# green => 0;32
# yellow => 1;33
# red => 0;31
# no colour => 0

_bc_g='\033[1;32m'
_bc_y='\033[1;33m'
_bc_r='\033[0;31m'
_bc_nc='\033[0m'

# colour codes END
#===============================================================================================================

echo `wc -l ${javac_src}`