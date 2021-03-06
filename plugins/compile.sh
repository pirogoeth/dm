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

hashtag=`git log -n 1 | grep -m1 commit | awk '{ print $2 }' | cut -b 1-7`
resource="${name},${basedir}"
compiler_resources=${HOME}/.dm-resources/resources

# context vars/statement ENDS
#===============================================================================================================

function pass() {
    echo "" >/dev/null
} # pythonic function.

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

while getopts "vhtr:o:m:HT67kC?" flag
    do
        case $flag in
            H) echo -e "${_bc_y}${name} committag ${hashtag}"
               exit 1
            ;;
            T) echo -e "${_bc_r}Skipping tests..."
               skiptest="YES"
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
            r) echo -e "${_bc_y}Remote transfer enabled!"
               export remote=${OPTARG}
            ;;
            m) export mcattr="-m ${OPTARG}"
            ;;
            t) echo -e "${_bc_y}Writing commit tag to hash file."
               export wtag="YES"
            ;;
            6) echo -e "${_bc_y}Forcing build with JDK 6."
               export jvmv="6"
            ;;
            7) echo -e "${_bc_y}Forcing build with JDK 7."
               export jvmv="7"
            ;;
            k) echo -e "${_bc_y}Keeping logfiles."
               export keeplogs="YES"
            ;;
            C) echo -e "${_bc_y}Cleaning .class files."
               export clean="YES"
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
                echo -en "[${_bc_y}Building upstream project ${upstream[$i]}...${_bc_nc}]"
                $workdir=${PWD}
                cd ${!upstream[$i]} && dm compile -po ${incdir}/${upstream[$i]}.jar
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

function exit() {
    if test -z $1 ; then
        _EXITCODE=0
    else
        _EXITCODE=$1
    fi
    builtin exit ${_EXITCODE}
}

function cleanup() {
    if [ "${keeplogs}" != "YES" ] ; then
        rm -f ./{archive,compile,scp,upstream}_log.txt
        echo -e "${_bc_y}Cleaned up logfiles!${_bc_nc}"
        cd ${_WD}
    fi
    if [ "${clean}" == "YES" ] ; then
        if [ ! -z "${targetdir}" ] ; then
            cd ${targetdir}
        else
            cd ${basedir}
        fi
        if [ "${verbose}" == "YES" ] ; then
            rm -v `find . | grep ".class"`
        else
            rm `find . | grep ".class"`
        fi
        echo -e "${_bc_r}Cleaned up compiled classes!${_bc_nc}"
        cd ${_WD}
    fi
}

trap cleanup EXIT

# first, build any upstreams.
if ((${#upstream[@]} > 0)) ; then # we have upstreams to parse and build
    parse_upstreams
fi

echo -en "${_bc_y}[${name}(${hashtag})] building.]${_bc_nc}"

if test "${jvmv}" == "6" || test "${java7_disable}" == "YES" ; then
    if [ ! -z "${targetdir}" ] ; then
        ${java6_path} -Xstdout compile_log.txt -sourcepath src/ -d ${targetdir} -g -cp ${javac_includes} ${javac_src}
    else
        ${java6_path} -Xstdout compile_log.txt -sourcepath src/ -g -cp ${javac_includes} ${javac_src}
    fi
elif test "${jvmv}" == "7" && test "${java7_disable}" == "NO" ; then
    if [ ! -z "${targetdir}" ] ; then
        ${java7_path} -Xstdout compile_log.txt -sourcepath src/ -d ${targetdir} -g -cp ${javac_includes} ${javac_src}
    else
        ${java7_path} -Xstdout compile_log.txt -sourcepath src/ -g -cp ${javac_includes} ${javac_src}
    fi
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

if [ "${wtag}" == "YES" ] ; then
    echo -n "${hashtag}" > ${hashtag_file}
fi

echo -en "${_bc_y}[${name}(${hashtag})] packing.]${_bc_nc}"

if [ "${tagname}" == "YES" ] ; then
    OUTFILENAME="${name}-${hashtag}.jar"
else
    OUTFILENAME="${name}.jar"
fi

jar cvf ${OUTFILENAME} ${mcattr} -C ${srcdir} . 2>&1 1>archive_log.txt

if [ ! -z "${resdir}" ] ; then
    jar uvf ${OUTFILENAME} -C ${resdir} . 2>&1 1>>archive_log.txt
fi

echo -e "            [ ${_bc_g} OK ${_bc_nc} ]"

if [ "${verbose}" == "YES" ] ; then
    echo "$(cat archive_log.txt)"
fi

if [ "${testcmd}" != "" ] && [ -z "${skiptest}" ] ; then
    echo -e "${_bc_y}[Running tests..]${_bc_nc}"
    PACKAGE=${OUTFILENAME} eval $testcmd
    testexit=$?
    if [ ${testexit} == 1 ] ; then
        echo -e "[ ${_bc_r} FAILED ${_bc_nc} ]"
        exit 1
    fi
    echo -e "[ ${_bc_g} OK ${_bc_nc} ]"
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
elif [ -z $outdir ] ; then
    mv ${OUTFILENAME} ${basedir}
fi

echo -e "${_bc_g}Successfully built ${name} ${hashtag}!${_bc_nc}"
exit 0