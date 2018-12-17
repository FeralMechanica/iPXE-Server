#/bin/bash

SSH(){
    local ip=$1
    shift
    sshpass -p ${Password} ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${ip} "$@"
}

SSH_AS() {
    local user=$1
    local ip=$2
    shift
    shift
    local tmo=15s
    _WithTimeout ${tmo} sshpass -p ${Password} ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@${ip} "$@"

}

SCP() {
    local ip=$1
    shift
    local args=("${@}")
    local len=${#args[@]}
    local src=${args[@]:0:${len}-1}
    local dst=${args[@]:${len}-1}
    sshpass -p ${Password} scp -q -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $src root@$ip:$dst
}

SCP_BACK() {
    local ip=$1
    local src=$2
    local dst=$3
    sshpass -p ${Password} scp -q -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip:$src $dst
}

RSYNC() {
    local ip=$1
    local src=$2
    local dst=$3
    sshpass -p ${Password} rsync -e "ssh -o PreferredAuthentications=password -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" -azh --stats $src root@$ip:$dst
}

_GetObjectRoot() {
    local ip=$1

    if [ "$HostOS" != "coreos" ]; then
        echo '' # returning empty root value in case of a non-containerized environments like standalone
        return
    fi

    local errors=()
    local tried=('emcvipr/object:latest' 'emcvipr/object:')
    local id
    local i

    for i in "${tried[@]}"; do
        local cmd='docker ps --no-trunc| grep '\'"$i"\''| awk '\''{print $1}'\''| tail -1'
        id="$(SSH $ip $cmd)"

        if [ -n "$id" ]; then
            break
        else
            errors=("${errors[@]}" "$ip: docker container id '$i' not found")
        fi
    done

    if [ -z "$id" ]; then
        local error
        for error in "${errors[@]}"; do
            echo "$error" 1>&2
        done

        echo "error: can't get object docker container id on $ip, tried '${tried[@]}'" 1>&2
        exit 1
    fi

    local prefix=''
    local suffix=''
    local backend="$(SSH $ip 'docker info 2>&1'| grep 'Storage Driver:'| awk '{print $3}')"
    case "$backend" in
        devicemapper)
            prefix='/var/lib/docker/devicemapper/mnt/'
            suffix='/rootfs'
            ;;
        btrfs)
            prefix='/var/lib/docker/btrfs/subvolumes/'
            ;;
        *)
            echo "Unsupported docker storage driver: '$backend'" 1>&2
            exit 1
            ;;
    esac
    echo "${prefix}${id}${suffix}"
}

_CheckMd5() {
    local file=$1

    test -f "$file" || return 1
    test -f "$file".md5 || return 1

    if [ $(md5sum "$file"| awk '{print $1}') = $(cat "$file".md5) ]; then
        return 0
    fi
    return 1
}

# downloads files md5, the file, checks md5 and retires if not match
_DownloadWithMd5() {
    local src=$1
    local dst=$2

    local srcmd5=${src}.md5
    local dstmd5=${dst}.md5

    {
        flock -x 42
        wget -q -O $dstmd5 $srcmd5
    } 42>"$Temp/.deployment.sh.md5_lock"

    if [ "$(du -b $dstmd5| awk '{print $1}')" -lt 32 ]; then
        echo "error: cant get md5 checksum for $src"
        exit 1
    fi

    local tries=5

    while [ $tries -gt 0 ]; do
        echo -n "downloading ... "
        {
            flock -x 42
            wget -q -O - $src | tee $dst | md5sum | awk '{print $1}' >${dstmd5}.downloaded
            if [ -f  ${dstmd5}.downloaded ] && [ "$(cat $dstmd5)" = "$(cat ${dstmd5}.downloaded)" ]; then
                echo "finished ok"
                break
            else
                let tries=$tries-1
                echo "md5 sum of $src mismatched while downloading, tries left - $tries"
            fi
        } 42>"$Temp/.deployment.sh.$(basename ${dst})_lock"
    done

    test -d ${dstmd5}.downloaded || rm -f ${dstmd5}.downloaded

    if [ $tries -le 0 ]; then
        echo "error: md5sum of $src keeps mismatching, cant download"
        exit 1
    fi
}

_Fatal() {
    local error_msg="$@"

    echo "[FATAL_ERROR] $error_msg"
    echo "Call Stack:"
    printf '    %s\n' "${FUNCNAME[@]}"
    exit 1
}

_EchoErrorWithFuncName() {
    local msg="$@"

    >&2 echo "[${FUNCNAME[1]:-main}] $msg"
}

_EchoWithFuncName() {
    local msg="$@"

    echo "[${FUNCNAME[1]:-main}] $msg"
}

_IsInteger() {
    local test_var="$1"

    if [[ ! $test_var =~ ^[0-9]+$ ]]; then
        return 1
    fi
    return 0
}

_WithTrap() {
    local sig="$1"
    local handler="$2"
    shift
    shift

    # save traps for given signal
    local saved_trap=$(trap -p $sig)

    # now set new handler
    trap "$handler" $sig

    "$@" <&0
    local ec=$?

    # restore previous traps
    trap - $sig
    eval "$saved_trap"

    return "$ec"
}

_WithUnSetE() {
    local old_flags="$-"

    [[ $old_flags =~ "e" ]] && set +e

    "$@" <&0
    local ec=$?

    # Any non-zero code in return with set -e will
    # immediately fail the script.
    [[ $old_flags =~ "e" ]] && set -e && return 0

    return "$ec"
}


# Call any cmd with given number of tries and timeout for each retry.
# try_count should be >= 1.
# Example:
#     _DoWithRetries 5 ls -lahtr -R /root
_WithRetries() {
    _WithUnSetE __WithRetries "$@"
}

# Call any cmd with given number of tries and timeout for each retry.
# try_count should be >= 1.
# Example:
#     _DoWithRetries 5 ls -lahtr -R /root
_WithRetries() {
    _WithUnSetE __WithRetries "$@"
}

__WithRetries() {
    local try_count="$1"
    shift

    _EchoWithFuncName "I am going to execute within '$try_count' tries a command '$@'"

    _IsInteger $try_count && test $try_count -ge 1 \
        || _Fatal "Try count parameter should be an integer value and >= 1. Actual value: '$try_count'"

    local i=1
    while [ "$i" -le "$try_count" ]; do
        _EchoWithFuncName "Try #${i}..."

        "$@"
        local ec=$?
        if [ $ec -eq 0 ] ; then
            _EchoWithFuncName "Command has finished successfully."
            return 0
        fi

        _EchoWithFuncName "Command has returned non-zero exit code: $ec."
        ((i++))
    done

    _EchoWithFuncName "Ran out of tries (try_count=$try_count). All command executions have failed."
    return 1
}

# Wraps a a given command to execute within a given DURATION and kills -TERM it if timed out.
# DURATION should be of the same format as in "man timeout".
# DURATION=0 is for infinite timeout.
# Example:
#     _DoWithTimeout 3 "ping -w 5 localhost"
_WithTimeout() {
    _WithUnSetE __WithTimeout "$@"
}

__HandleSigInt_DoWithTimeout() {
    local pid=$1
    echo "[TRAP] SIGINT was received. Will exit in 3 seconds..."
    kill -INT -$pid
    sleep 3
    echo "[TRAP] Now exiting..."
    exit 1
}

__WithTimeout() {
    local timeout="$1"
    shift

    # smhd are supported suffices
    local n=${timeout%%[smhd]}
    _IsInteger $n && test $n -ge 1 \
        || _Fatal "Timeout parameter should be an integer value and >= 1. " \
                  "Actual value: '$n'. Allowed suffices: 's', 'm', 'h', 'd'"

    timeout -k 1m $timeout "$@" <&0 &
    local pid=$!
    _WithTrap INT "__HandleSigInt_DoWithTimeout $pid" wait $pid
    local ec=$?

    # see "info coreutils 'timeout invocation'"
    if [ $ec -eq 0 ]; then
        return 0
    elif [ $ec -eq 124 ]; then
        _EchoErrorWithFuncName "Command execution timed out. Timeout value: $timeout. Command: '$@'."
    elif [ $ec -eq 125 ]; then
        _EchoErrorWithFuncName "Timeout utility has failed. Command: '$@'"
    elif [ $ec -eq 126 ]; then
        _EchoErrorWithFuncName "Command cannot be executed. Command: '$@'"
    elif [ $ec -eq 127 ]; then
        _EchoErrorWithFuncName "Command cannot be found. Command: '$@'"
    fi
    return "$ec"
}

# Function calculates number of bit in a netmask
mask2cidr() {
    local nbits=0
    OLDIFS="$IFS"
    IFS=.
    for dec in $1 ; do
        case $dec in
            255) let nbits+=8;;
            254) let nbits+=7;;
            252) let nbits+=6;;
            248) let nbits+=5;;
            240) let nbits+=4;;
            224) let nbits+=3;;
            192) let nbits+=2;;
            128) let nbits+=1;;
            0);;
            *) echo "Error: $dec is not recognised"; exit 1
        esac
    done
    echo "$nbits"
    IFS="$OLDIFS"
}

MakeNodeName() {

    echo $1 | sed -e 's/10.247.66\.\([0-9][0-9][0-9]\)/lglap\1/g' -e 's/10.247.66\.\([0-9][0-9]\)/lglap0\1/g' -e 's/10.247.179\.\([0-9][0-9][0-9]\)/lrmk\1/g' -e 's/10.247.179\.\([0-9][0-9]\)/lrmk0\1/g' -e 's/10.247.165\.\([0-9][0-9][0-9]\)/lglaz\1/g' -e 's/10.247.165\.\([0-9][0-9]\)/lglaz0\1/g' -e 's/10.247.165\.\([0-9]\)/lglaz00\1/g' -e 's/10.247.78\.\([0-9][0-9][0-9]\)/lglbg\1/g' -e 's/10.247.78\.\([0-9][0-9]\)/lglbg0\1/g' -e 's/10.247.84\.\([0-9][0-9][0-9]\)/lgly4\1/g' -e 's/10.247.84\.\([0-9][0-9]\)/lgly40\1/g' -e 's/10.247.87\.\([0-9][0-9][0-9]\)/lgly7\1/g' -e 's/10.247.87\.\([0-9][0-9]\)/lgly70\1/g' -e 's/10.247.86\.\([0-9][0-9][0-9]\)/lgly6\1/g' -e 's/10.247.86\.\([0-9][0-9]\)/lgly60\1/g' -e 's/10.247.64\.\([0-9][0-9][0-9]\)/lglan\1/g' -e 's/10.247.142\.\([0-9][0-9][0-9]\)/lglbv\1/g' -e 's/10.247.[0-9].*\([0-9]\)\.\([0-9].*\)/lglw\1\2/g'

}
