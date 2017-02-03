# Base library (misc functions)
# !!!! Refactor into smaller, purpose specific libs?

[ -z "${sysman_scripts_dir}" ] && readonly sysman_scripts_dir=$(dirname ${BASH_SOURCE[@]})

# log_file should be responsability of each script
#readonly log_dir=${sysman_scripts_dir}/log
# [ -z "${log_file}" ] && readonly log_file=${log_dir}/sysman.log

. ${sysman_scripts_dir}/psscripts_common.sh

readonly nas_scripts_dir=${sysman_scripts_dir}/nas
readonly remote_nas_scripts_dir=/etc/sysman/nas
readonly user_db=${SYSMAN_ETC}/users
readonly group_db=${SYSMAN_ETC}/groups

error(){
    echo "$1"
    exit 2
}

# @act
add_new_user(){
    # can't be local because an external function needs it...
    log_facility="accounting"
    local server=$1
    local shell=${3:-/bin/bash}
    # default: 2 months
    [ -z "${duration}" ] && local duration=5184000
    local expire=$(date --date "@$(( $(date +%s) + duration ))" +%Y-%m-%d)
    local result=0
    local homes_dir=${home_base:-/home}
    log "${info} Creating user account ${user}@${server} (${uid},${gid}) (${expire})"
    ssh  ${SSH_USER}${server} "grep ^${user}: /etc/passwd || useradd -u ${uid} -g ${gid} -s ${shell} ${create_home} -e ${expire} -d ${homes_dir}/${user} ${user}"
    result=$?
    if [ ${result} -eq 0 ]; then
	log "${success} Account ${user}@${server} available"
    else
	log "${critical} Problem creating account ${user}"
    fi
    return ${result}
}

# @act
add_new_group(){
    log_facility="accounting"
    local server=$1
    ssh  ${SSH_USER}${server} "grep ${group} /etc/group || groupadd -g ${gid} ${group}"
    return $?
}

# @act
set_quota(){
    log_facility="quota"
    local server=$1
    local result=0
    local cmd="setquota ${user} ${quota} ${quota} 0 0 /home"
    ssh  ${SSH_USER}${server} "${cmd}"
    result=$?
    if [ ${result} -eq 0 ]; then
	log "${success} Quota for ${user} set to ${quota}"
    else
	log "${critical} Problem setting up quota for ${user} (${cmd})"
    fi
    return ${result}
}

# @act
set_passwd(){
    readonly passwd=$(random_str)
    local result=0
    ssh  ${SSH_USER}${host} "echo ${user}:${passwd} | chpasswd"
    result=$?
    if [ ${result} -eq 0 ]; then
	log "${success} Password set for ${user}"
    else
	log "${critical} Problem setting up password for ${user}"
    fi
    echo "New password for ${user}: ${passwd}"
    return ${result}
}

# @act
search_user_db(){
    line=$(grep ${user} ${user_db})
    if [ $? -eq 0 ]; then
	[ -z "${uid}" ] && get_column 2 uid ${line}
    else
	echo "User not found"
	sort -n -k 2 ${user_db}
    fi
}

# @act
search_group_db(){
    line=$(grep ${group} ${group_db})
    if [ $? -eq 0 ]; then
	[ -z "${gid}" ] && get_column 2 gid ${line}
    else
	echo "Group not found"
	sort -n -k 2 ${group_db}
    fi
}

eval_and_log(){
    local step=$1
    eval ${step} | logalize ${log_file}
    local err_code=${PIPESTATUS[0]}
    if [ ${err_code} -eq 0 ]; then
	log "${success} ${step}"
    else 
	log "${critical} ${step}"
    fi
    return ${err_code}
}


# little hack to extract the nth word of a string and save it in the specified variable
# An alternative could be using bash arrays
# Example:
# get_column 3 uid John   Doe   44
# uid -> 44
get_column(){
    local column=$1
    local var=$2
    shift
    shift
    eval export $var=\$${column}
}

random_str(){
    tr -dc _A-H-J-N-P-Z-a-h-m-z-1-9 < /dev/urandom | head -c${1:-14}
}

readonly black='\E[30;47m'
readonly red='\E[31;47m'
readonly green='\E[32;47m'
readonly yellow='\E[33;47m'
readonly blue='\E[34;47m'
readonly magenta='\E[35;47m'
readonly cyan='\E[36;47m'
readonly white='\E[37;47m'


cecho(){
    local message=$1
    local color=${2:-$black} 
    echo -ne "${color}"
    echo -n "${message}"
    #  tput sgr0
    echo -e "\E[0m"
}

wait_for_docker(){
	running=1
	trials=0
	while [ ${running} -ne 0 -a ${trials} -lt 5 ]; do
		docker info > /dev/null
		running=$?
		trials=$(( trials + 1))
		logger "Waiting for docker (${trials})..."
		sleep 5
	done
}
