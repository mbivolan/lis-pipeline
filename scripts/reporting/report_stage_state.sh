#!/bin/bash
set -xe -o pipefail
BASEDIR=$(dirname $0)

function main {
    TEMP=$(getopt -o n:s:i:k:b:d:c:a --long pipeline_name:,pipeline_build_number:,pipeline_stage_status:,pipeline_stage_name:,kernel_info:,kernel_source:,kernel_branch:,distro_version:,db_config: -n 'report_stage_state.sh' -- "$@")
    if [[ $? -ne 0 ]]; then
        exit 1
    fi

    echo $TEMP

    eval set -- "$TEMP"
    
    while true ; do
        case "$1" in
            --pipeline_name)
                case "$2" in
                    "") shift 2 ;;
                    *) PIPELINE_NAME="$2" ; shift 2 ;;
                esac ;;
            --pipeline_build_number)
                case "$2" in
                    "") shift 2 ;;
                    *) PIPELINE_BUILD_NUMBER="$2" ; shift 2 ;;
                esac ;;
            --pipeline_stage_status)
                case "$2" in
                    "") shift 2 ;;
                    *) PIPELINE_STAGE_STATUS="$2" ; shift 2 ;;
                esac ;;
            --pipeline_stage_name)
                case "$2" in
                    "") shift 2 ;;
                    *) PIPELINE_STAGE_NAME="$2" ; shift 2 ;;
                esac ;;
            --kernel_info)
                case "$2" in
                    "") shift 2 ;;
                    *) KERNEL_INFO="$2" ; shift 2 ;;
                esac ;;
            --kernel_source)
                case "$2" in
                    "") shift 2 ;;
                    *) KERNEL_SOURCE="$2" ; shift 2 ;;
                esac ;;
            --kernel_branch)
                case "$2" in
                    "") shift 2 ;;
                    *) KERNEL_BRANCH="$2" ; shift 2 ;;
                esac ;;
            --distro_version)
                case "$2" in
                    "") shift 2 ;;
                    *) DISTRO_VERSION="$2" ; shift 2 ;;
                esac ;;
            --db_config)
                case "$2" in
                    "") shift 2 ;;
                    *) DB_CONFIG="$2" ; shift 2 ;;
                esac ;;
            --) shift ; break ;;
            *) echo "Wrong parameters!" ; exit 1 ;;
        esac
    done

    kernel_version="unknown"
    kernel_commit_id="unknown"
    kernel_folder="unknown"
    test_date=`date '+%m/%d/%Y %H:%M:%S'`;

    if [[ -e "${KERNEL_INFO}" ]];then
        kernel_version=$(crudini --get $KERNEL_INFO KERNEL_BUILT version \
                         || echo $kernel_version)
        kernel_commit_id=$(crudini --get $KERNEL_INFO KERNEL_BUILT git_tag \
                           || echo $kernel_commit_id)
        kernel_folder=$(crudini --get $KERNEL_INFO KERNEL_BUILT folder \
                           || echo $kernel_folder)
    else
        echo "${KERNEL_INFO} file does not exist."
    fi

    cat << EOF > "./tests.json"
    [
    {
        "TestDate": "${test_date}",
        "KernelSource": "${KERNEL_SOURCE}",
        "KernelBranch": "${KERNEL_BRANCH}",
        "DistroVersion": "${DISTRO_VERSION}",
        "PipelineName": "${PIPELINE_NAME}",
        "PipelineBuildNumber": ${PIPELINE_BUILD_NUMBER},
        "KernelVersion": "${kernel_version}",
        "KernelFolder": "${kernel_folder}",
        "KernelCommitId": "${kernel_commit_id}",
        "${PIPELINE_STAGE_NAME}": ${PIPELINE_STAGE_STATUS}
    }
]
EOF

    cat ./tests.json
    cp -f "${BASEDIR}/parser.py" "./parser.py"
    cp -f "${DB_CONFIG}" "./db.config"
    python parser.py --test_results "./tests.json" --db_config "./db.config" \
        --composite_keys 'PipelineName,PipelineBuildNumber'
}

main $@
