#!/usr/bin/env bash
shopt -s extglob checkhash globstar

# try to import the current configuration
if test ! -d .dm ; then
    if test "`dirlocate .dm /`" != "" ; then
        source `dirlocate .dm /`/config
    else
        echo "dm configuration directory does not exist, creating skeleton!"
        mkdir -p .dm/deps
        cat ${dmcore}/static/config.def >> .dm/config
        echo "exiting."
        exit 1
    fi
elif test -d .dm && test -e .dm/config ; then
    source .dm/config
fi

if [ ! -z ${BASEDIR} ] ; then
    basedir=${BASEDIR}
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
# context variables and statement

_WD=`pwd`
_EXITCODE=0
cd ${basedir}

version=`cat src/plugin.yml | grep "version" | awk '{print $2}'`
hashtag=`git log -n 1 | grep -m1 commit | awk '{ print $2 }' | cut -b 1-7`
resource="${name},${basedir}"
compiler_resources=${HOME}/.dm-resources/resources

# context vars/statement ENDS
#===============================================================================================================

function pass() {
    echo "" >/dev/null
} # pythonic function.

function exit() {
    if test -z $1 ; then
        _EXITCODE=0
    else
        _EXITCODE=$1
    fi
    builtin exit ${_EXITCODE}
}

# make sure this possible {up,down}stream is listed in compiler resources
if test ! -e ${compiler_resources} ; then
  touch ${compiler_resources}
fi
if (grep -Fxq "${resource};" ${compiler_resources}) ; then
  # nothing to do, we're already a resource, also need to fill in this conditional block >_>
  pass
else
  echo "${resource};" >> ${compiler_resources}
fi

while getopts "vhpkr:o:VH67?" flag
    do
        case $flag in
            V) echo -e "${_bc_y}Building for ${name}, version ${version}."
               exit 1
            ;;
            H) echo -e "${_bc_y}${name} committag ${hashtag}"
               exit 1
            ;;
            h) echo -e "${_bc_y}Adding git committag to archive name."
               export tagname="YES"
            ;;
            v) echo -e "${_bc_y}Being verbose..."
               export verbose="YES"
            ;;
            o) echo -e "${_bc_y}Output is now: ${OPTARG}"
               export outdir=${OPTARG}
            ;;
            p) echo -e "${_bc_y}Writing git committag to plugin.yml."
               export pct="YES"
            ;;
            k) echo -e "${_bc_y}Keeping logfiles."
               export keeplogs="YES"
            ;;
            r) echo -e "${_bc_r}Remote transfer enabled!"
               export remote=${OPTARG}
            ;;
            6) echo -e "${_bc_y}Forcing build with JDK 6."
               export jvmv="6"
            ;;
            7) echo -e "${_bc_y}Forcing build with JDK 7."
               export jvmv="7"
            ;;
            \?) echo "Usage: `basename $0` [-HVhv?] [-o outfile]"
               exit
            ;;
            *) exit
            ;;
        esac
    done

function parse_upstreams() {
    local workdir

    function getKey() {
        echo ${1//','/ } | awk '{print $1};'
    }
    function getValue() {
        echo ${1//','/ } | awk '{print $2};'
    }
    function clearUpstreamLog() {
        echo "" > ./upstream_log.txt
    }
    resources=`cat ${compiler_resources}`
    resources=${resources//$'\n'/}
    resources=${resources//";"/ }

    res_ar=( ${resources} )

    for (( i=0; $i<${#res_ar[@]}; i++ ))
        do
            key=$(getKey ${res_ar[$i]})
            value=$(getValue ${res_ar[$i]})
            export "${key}"="${value}"
        done

    # build upstreams

    for (( i=0; $i<${#upstream[$i]}; i++ ))
        do
            if test -z ${!upstream[$i]} ; then # the upstream doesnt exist
                echo "${_bc_r}[FATAL! Upstream project ${upstream[$i]} can not be found! Aborting!]${_bc_nc}"
                exit 1
            elif test ! -z ${!upstream[$i]} ; then # the upstream exists
                echo -e "[${_bc_y}Building upstream project ${upstream[$i]}...${_bc_nc}]"
                workdir=${PWD}
                cd ${!upstream[${i}]} && dm bukkit -po ${incdir}/${upstream[$i]}.jar
                upstream_status=$?
                if ((${upstream_status} != 0)) ; then
                    echo -e "           [ ${_bc_r} FAILED {${upstream_status}}. $_bc_nc} ]"
                    cat ./upstream_log.txt
                    exit 1
                elif ((${upstream_status} == 0)) ; then
                    echo -e "           [ ${_bc_g} OK. ${_bc_nc} ]"
                    clearUpstreamLog
                    continue
                fi
            fi
        done

    # back to working directory!
    cd ${basedir}
}

function cleanup() {
    if [ "${keeplogs}" != "YES" ] ; then
        rm -f ./{archive,compile,scp,upstream}_log.txt
        echo -e "${_bc_y}Cleaned up logfiles!${_bc_nc}"
        cd ${_WD}
    fi
    builtin exit ${_EXITCODE}
}

trap cleanup EXIT

# FIRST FIRST, clean up all .class files in the source directory
rm -f `find ${javac_src} -name *.class`

# first, build any upstreams.
if ((${#upstream[@]} > 0)) ; then # we have upstreams to parse and build
    parse_upstreams
fi

echo -en "${_bc_y}[${name}(${version}-${hashtag})] building.]${_bc_nc}"

if test "${jvmv}" == "6" || test "${java7_disable}" == "YES" ; then
    "${java6_path}" -Xstdout compile_log.txt -sourcepath ${srcdir} -g -cp ${javac_includes} ${javac_src}
elif test "${jvmv}" == "7" && test "${java7_disable}" == "NO" ; then
    "${java7_path}" -Xstdout compile_log.txt -sourcepath ${srcdir} -g -cp ${javac_includes} ${javac_src}
fi

errors=`cat "./compile_log.txt" | tail -n 1`
errors_t=`echo ${errors} | tr -d "[[:space:]]"`
end=`tail -n -1 ./compile_log.txt | cut -b 1-5`

if (test "${end}" != "Note:" && test "${end}" != "") && (test ! -z "${errors}" && test ! -z "${errors_t}") ; then
    echo -e "           [ ${_bc_r} FAIL ${_bc_nc} ]"
    echo -e "${_bc_y}$(cat compile_log.txt)"
    exit 1
else
    echo -e "           [ ${_bc_g} OK ${_bc_nc} ]"
fi

if [ "${verbose}" == "YES" ] ; then
    echo -e "${_bc_y}$(cat compile_log.txt)"
fi

if [ "${testcmd}" != "" ] ; then
    echo -en "${_bc_y}[Running tests..]${_bc_nc}"
    eval $testcmd
    testexit=$?
    if [ "${testexit}" == 1 ] ; then
        echo -e "[ ${_bc_r} FAILED ${_bc_nc} ]"
        exit 1
    fi
    echo -e "[ ${_bc_g} OK ${_bc_nc} ]"
fi

echo -en "${_bc_y}[${name}(${version}-${hashtag})] packing.]${_bc_nc}"

if [ "${tagname}" == "YES" ] ; then
    OUTFILENAME="${name}-${version}-${hashtag}.jar"
else
    OUTFILENAME="${name}-${version}.jar"
fi

if [ "${pct}" == "YES" ] ; then
    pd=`cat ${plugin_datafile}`
    _pd=`echo -en "${pd}"; echo -en "\nhashtag: ${hashtag}"`
    echo -n "${_pd}" >${plugin_datafile}
fi

jar cvf ${OUTFILENAME} -C ${srcdir} . 2>&1 1>archive_log.txt

echo -e "            [ ${_bc_g} OK ${_bc_nc} ]"

if [ "${pct}" == "YES" ] ; then
    echo -n "${pd}" >${plugin_datafile}
fi

if [ "${verbose}" == "YES" ] ; then
    echo "$(cat archive_log.txt)"
fi

if [ ! -z $remote ] ; then
    echo -e "${_bc_y}[Uploading ${name}(${version}-${hashtag}) to ${remote}...]${_bc_nc}"
    scp -p ${OUTFILENAME} ${remote} 2>&1 1>scp_log.txt
    status=$?
    if [ ! ${status} == 0 ] ; then
        echo -e "[ ${_bc_r} TRANSFER FAIL ${_bc_nc} ]"
        exit 1
    elif [ ${status} == 0 ] ; then
        echo -e "[ ${_bc_g} TRANSFER OK ${_bc_nc} ]"
    fi
elif [ ! -z $outdir ] ; then
    mv ${OUTFILENAME} ${outdir}
elif [ `pwd` != ${_WD} ] && [ -z $outdir ] ; then
    mv ${OUTFILENAME} ${_WD}
fi

echo -e "${_bc_g}Successfully built ${name} ${version}-${hashtag}!${_bc_nc}"
exit 0