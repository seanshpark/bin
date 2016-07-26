#!/bin/bash
#
#   Copyright 2016 by Sung-Jae Lee (sjlee@mail.com)
#

#
# set default configuration
#
BUILD_ARM=
BUILD_SOFTFP=
BUILD_ARM64=
BUILD_HOST=
BUILD_NATIVE=YES
BUILD_MANAGED=YES
BUILD_TYPE=debug
BUILD_CORECLR=
BUILD_COREFX=
BUILD_CLI=
BUILD_ROSLYN=
CLEAN=
VERBOSE=
DISTCLEAN=
SKIPMSCORLIB=
SKIPTESTS=skiptests
SKIPBUILDTESTS=
EXTRA_OPTIONS=

COMMAND_LINE="$@"

function usage
{
    echo ''
    echo "Usage: [BASE_PATH=<git_base>] $(basename $0) {command|target} [module] [configuration] [mode] [option]"
    echo ''
    echo '      command : update | sync | distclean | version'
    echo '       target : default | all | complete | arm | arm-softfp | arm64 | host'
    echo '       module : (coreclr) | (corefx) | cli | roslyn'
    echo 'configuration : (debug) | release | checked'
    echo '         mode : quick'
    echo '       option : clean, verbose, skipmscorlib, skipbuildtests {(skiptests) | no-skiptests}, {native-only | managed-only}'
    echo ''
}

#
# print usage
#
if [ $# -eq 0 ]; then
    usage
    exit
fi

#
# etc.
#
if [ -z "$BASE_PATH" ]; then
    BASE_PATH=$(pwd)
fi

LOG_FILE="$BASE_PATH/$(basename ${0}).log"
TIME="time"

#
# define functions
#

function time_stamp
{
    date | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
}

function task_stamp
{
    BRANCH=$(git branch | grep '^*' | cut -d' ' -f2-)
    HASH=$(git log -1 --format=%H)

    echo "$1" | tee -a $LOG_FILE
    echo "BRANCH:$BRANCH" | tee -a $LOG_FILE
    echo "HASH:$HASH" | tee -a $LOG_FILE
}

function sync
{
    if [ -e "$1/.git" ]; then
        BRANCH=$(git -C $1 branch | grep '^*' | cut -d' ' -f2-)
        HASH=$(git -C $1 log -1 --format=%H)
        UPSTREAM=$(git -C $1 remote | grep -v origin)

        echo ">>>> sync [$1] to upstream <<<<"
        git -C $1 fetch --all
        git -C $1 merge $UPSTREAM/$BRANCH
        git -C $1 push
        git -C $1 pull --rebase
        echo "BRANCH:$BRANCH"
        echo "HASH:$HASH"
        echo ""
    fi
}

function sync_repo 
{
    case $# in
        0)
            for repo in $(ls $BASE_PATH)
            do
                sync $repo
            done
            ;;
        *)
            while [ -n "$1" ] && [ -e $1/.git ]
            do
                sync $1
                shift
            done
            ;;
    esac
}

function update
{
    if [ -e "$1/.git" ]; then
        BRANCH=$(git -C $1 branch | grep '*' | cut -d' ' -f2-)
        HASH=$(git -C $1 log -1 --format=%H)

        echo ">>>> update [$1] <<<<"
        git -C $1 pull --rebase
        echo "BRANCH:$BRANCH"
        echo "HASH:$HASH"
        echo ""
    fi
}

function update_repo 
{
    case $# in
        0)
            for repo in $(ls $BASE_PATH)
            do
                update $repo
            done
            ;;
        *)
            while [ -n "$1" ] && [ -e $1/.git ]
            do
                update $1
                shift
            done
            ;;
    esac
}

function distclean 
{
    for repo in $(ls $BASE_PATH)
    do
        if [ -e $repo/.git ]; then
            git -C $repo clean -xdf
        fi
    done
}

function version
{
    if [ -e "$1/.git" ]; then
        BRANCH=$(git -C $1 branch | grep '^*' | cut -d' ' -f2-)
        HASH=$(git -C $1 log -1 --format=%H)

        echo "[$1]"
        echo "BRANCH:$BRANCH"
        echo "HASH:$HASH"
        echo ""
    fi
}

function show_version 
{
    case $# in
        0)
            for repo in $(ls $BASE_PATH)
            do
                version $repo
            done
            ;;
        *)
            while [ -n "$1" ] && [ -e $1/.git ]
            do
                version $1
                shift
            done
            ;;
    esac
}

#
# parse command-line options
#
while [ -n "$1" ]
do
    case $1 in
        default)
            BUILD_ARM=YES
            BUILD_ARM64=
            BUILD_SOFTFP=
            BUILD_HOST=YES
            BUILD_CORECLR=YES
            BUILD_COREFX=YES
            BUILD_CLI=
            BUILD_ROSLYN=
            SKIPBUILDTESTS=
            SKIPTESTS=skiptests
            ;;
        all)
            BUILD_ARM=YES
            BUILD_ARM64=
            BUILD_SOFTFP=YES
            BUILD_HOST=YES
            BUILD_CORECLR=YES
            BUILD_COREFX=YES
            BUILD_CLI=YES
            BUILD_ROSLYN=YES
            SKIPBUILDTESTS=
            SKIPTESTS=skiptests
            ;;
        complete)
            CLEAN=clean
            BUILD_ARM=YES
            BUILD_ARM64=
            BUILD_SOFTFP=YES
            BUILD_HOST=YES
            BUILD_CORECLR=YES
            BUILD_COREFX=YES
            BUILD_CLI=YES
            BUILD_ROSLYN=YES
            SKIPBUILDTESTS=
            SKIPTESTS=
            ;;
        quick)
            CLEAN=
            SKIPMSCORLIB=
            SKIPTESTS=skiptests
            SKIPBUILDTESTS=skiptests
            ;;
        coreclr)
            BUILD_CORECLR=YES
            ;;
        corefx)
            BUILD_COREFX=YES
            ;;
        cli)
            BUILD_CLI=YES
            ;;
        roslyn)
            BUILD_ROSLYN=YES
            ;;
        arm)
            BUILD_ARM=YES
            ;;
        arm-softfp)
            BUILD_SOFTFP=YES
            ;;
        arm64)
            BUILD_ARM64=YES
            ;;
        host)
            BUILD_HOST=YES
            ;;
        skipmscorlib)
            SKIPMSCORLIB=$1
            ;;
        skipbuildtests)
            SKIPBUILDTESTS=skiptests
            ;;
        skiptests)
            SKIPTESTS=$1
            ;;
        no-skiptests)
            SKIPTESTS=
            ;;
        debug|release|checked)
            BUILD_TYPE=$1
            ;;
        native-only)
            BUILD_MANAGED=
            ;;
        managed-only)
            BUILD_NATIVE=
            ;;
        clean)
            CLEAN=$1
            ;;
        verbose)
            VERBOSE=$1
            ;;
        distclean)
            distclean | tee -a $LOG_FILE
            exit
            ;;
        sync)
            shift
            sync_repo $@
            exit
            ;;
        update)
            shift
            update_repo $@
            exit
            ;;
        version)
            shift
            show_version $@
            exit
            ;;
        *)
            EXTRA_OPTIONS="${EXTRA_OPTIONS} $1"
            ;;
    esac
    shift
done

STRIPPED_EXTRA_OPTIONS="$(echo $EXTRA_OPTIONS | sed 's/makeargs //g' - )"
echo $EXTRA_OPTIONS
echo $STRIPPED_EXTRA_OPTIONS

if [ -z "$BUILD_CORECLR" -a -z "$BUILD_COREFX" -a -z "$BUILD_CLI" -a -z "$BUILD_ROSLYN" ]; then
    BUILD_CORECLR=YES
    BUILD_COREFX=YES
    BUILD_CLI=
    BUILD_ROSLYN=
fi

#
# check log file
#
if [ -e $LOG_FILE ]; then
    rm -f $LOG_FILE
fi

echo $COMMAND_LINE | tee -a $LOG_FILE
date | tee -a $LOG_FILE

if [ "$BUILD_NATIVE" = "YES" ]; then
    #
    # build arm native
    #
    if [ "$BUILD_ARM" = "YES" ]; then
        if [ "$BUILD_CORECLR" = "YES" ]; then
            cd $BASE_PATH/coreclr
            task_stamp "[CORECLR - cross arm native]"

            ROOTFS_DIR=~/arm-rootfs-coreclr/ $TIME ./build.sh $BUILD_TYPE $CLEAN arm cross $VERBOSE $SKIPMSCORLIB $SKIPBUILDTESTS $STRIPPED_EXTRA_OPTIONS
            echo "CORECLR CROSS ARM NATIVE build result $?" | tee -a $LOG_FILE
            time_stamp
        fi

        if [ "$BUILD_COREFX" = "YES" ]; then
            cd $BASE_PATH/corefx
            task_stamp "[COREFX - cross arm native]"

            ROOTFS_DIR=~/arm-rootfs-corefx/ $TIME ./build.sh native $BUILD_TYPE $CLEAN arm cross $VERBOSE $SKIPTESTS $EXTRA_OPTIONS /p:TestWithoutNativeImages=true
            echo "COREFX CROSS ARM NATIVE build result $?" | tee -a $LOG_FILE
            time_stamp
        fi
    fi

    #
    # build arm-softfp native
    #
    if [ "$BUILD_SOFTFP" = "YES" ]; then
        if [ "$BUILD_CORECLR" = "YES" ]; then
            cd $BASE_PATH/coreclr
            task_stamp "[CORECLR - cross arm-softfp native]"

            ROOTFS_DIR=~/arm-softfp-rootfs-coreclr/ $TIME ./build.sh $BUILD_TYPE $CLEAN arm-softfp cross $VERBOSE $SKIPMSCORLIB $SKIPBUILDTESTS $STRIPPED_EXTRA_OPTIONS
            echo "CORECLR CROSS ARM-SOFTFP NATIVE build result $?" | tee -a $LOG_FILE
            time_stamp
        fi

        if [ "$BUILD_COREFX" = "YES" ]; then
            cd $BASE_PATH/corefx
            task_stamp "[COREFX - cross arm-softfp native]"
            
            ROOTFS_DIR=~/arm-softfp-rootfs-corefx/ $TIME ./build.sh native $BUILD_TYPE $CLEAN arm-softfp cross $VERBOSE $SKIPTESTS $EXTRA_OPTIONS /p:TestWithoutNativeImages=true
            echo "COREFX CROSS ARM-SOFTFP NATIVE build result $?" | tee -a $LOG_FILE
            time_stamp
        fi
    fi

    #
    # build arm64 native
    #
    if [ "$BUILD_ARM64" = "YES" ]; then
        if [ "$BUILD_CORECLR" = "YES" ]; then
            cd $BASE_PATH/coreclr
            task_stamp "[CORECLR - cross arm64 native]"

            ROOTFS_DIR=~/arm64-rootfs-coreclr/ $TIME ./build.sh $BUILD_TYPE $CLEAN arm64 cross $VERBOSE $SKIPMSCORLIB $SKIPBUILDTESTS $STRIPPED_EXTRA_OPTIONS
            echo "CORECLR CROSS ARM64 NATIVE build result $?" | tee -a $LOG_FILE
            time_stamp
        fi

#        if [ "$BUILD_COREFX" = "YES" ]; then
#            cd $BASE_PATH/corefx
#            task_stamp "[COREFX - cross arm64 native]"
#    
#            ROOTFS_DIR=~/arm64-rootfs-corefx/ $TIME ./build.sh native $BUILD_TYPE $CLEAN arm64 cross $VERBOSE $SKIPTESTS $EXTRA_OPTIONS /p:TestWithoutNativeImages=true
#            echo "COREFX CROSS ARM64 NATIVE build result $?" | tee -a $LOG_FILE
#            time_stamp
#        fi
    fi

    #
    # build host native
    #
    if [ "$BUILD_HOST" = "YES" ]; then
        if [ "$BUILD_CORECLR" = "YES" ]; then
            cd $BASE_PATH/coreclr
            task_stamp "[CORECLR - host native]"

            $TIME ./build.sh $BUILD_TYPE $CLEAN $VERBOSE $SKIPBUILDTESTS $STRIPPED_EXTRA_OPTIONS
            echo "CORECLR HOST NATIVE build result $?" | tee -a $LOG_FILE
            time_stamp
        fi

        if [ "$BUILD_COREFX" = "YES" ]; then
            cd $BASE_PATH/corefx
            task_stamp "[COREFX - host native]"

            $TIME ./build.sh native $BUILD_TYPE $CLEAN $VERBOSE $SKIPTESTS $EXTRA_OPTIONS
            echo "COREFX HOST NATIVE build result $?" | tee -a $LOG_FILE
            time_stamp
        fi
    fi
fi

#
# build managed assembly
#
if [ "$BUILD_MANAGED" = "YES" ]; then
    if [ "$BUILD_COREFX" = "YES" ]; then
        cd $BASE_PATH/corefx
        task_stamp "[COREFX - managed]"

        if [ "$BUILD_ARM" = "YES" ] || [ "$BUILD_SOFTFP" = "YES" ] || [ "$BUILD_ARM64" = "YES" ]; then
            $TIME ./build.sh managed $BUILD_TYPE $CLEAN $VERBOSE $SKIPTESTS $EXTRA_OPTIONS /p:TestWithoutNativeImages=true
        else
            $TIME ./build.sh managed $BUILD_TYPE $CLEAN $VERBOSE $SKIPTESTS $EXTRA_OPTIONS
        fi
        echo "COREFX MANAGED build result $?" | tee -a $LOG_FILE
        time_stamp
    fi
fi

#
# build cli
#
if [ "$BUILD_CLI" = "YES" ]; then
    cd $BASE_PATH/cli
    task_stamp "[CLI]"

    $TIME ./build.sh $BUILD_TYPE
    echo "CLI build result $?" | tee -a $LOG_FILE
    time_stamp
fi

#
# build roslyn
#
if [ "$BUILD_ROSLYN" = "YES" ]; then
    cd $BASE_PATH/roslyn
    task_stamp "[ROSLYN]"

    $TIME make
    echo "ROSLYN build result $?" | tee -a $LOG_FILE
    time_stamp
fi

date | tee -a $LOG_FILE
if [ -n "$NOTIFY" ]; then
    echo "$NOTIFY \"$(hostname -s): $(basename $0) $COMMAND_LINE complete with $? - $(date)\""
    $NOTIFY "$(hostname -s): $(basename $0) $COMMAND_LINE complete with $? - $(date)"
fi
