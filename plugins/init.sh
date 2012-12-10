#!/usr/bin/env bash
shopt -s extglob checkhash globstar

# this initialises a new dm project.
# it's quite simple really...

# source the dm custom environment
source ${dmcore}/static/dm_env.sh

# colour codes!

_bold='\033[1;37m'
_none=']033[0m'

if [[ $(projectdir) == "YES" ]] ; then
    projdir=`dirlocate .dm /`
    source ${projdir}/config
    echo "A project named '${name}' already exists in this directory!"
    exit
fi

# ask for project name
read -p "Project name? => " projname
projname=${projname/$'\n'/}
basedir=`pwd`
basedir=${basedir/$'\n'/}

# tell where the basedir is
echo "Project '${projname}' is '${basedir}'"

# create dm directories
mkdir -p .dm/{deps,hooks,plugins}

# load the configuration into a variable to make some substitutions
defconfig=`cat ${dmcore}/static/config.def`

# perform replacements
defconfig=`echo "${defconfig}" | sed -e 's/name=""/name="'${projname}'"/' | sed -e 's/basedir=""/basedir="'${basedir//\//\\\/}'"/'`

# write the new config into file
echo "${defconfig}" > .dm/config

echo "Project '${projname}' has been created!"

exit