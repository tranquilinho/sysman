#!/bin/bash

# ps-scripts project "common" library
# !!!! This file is shared/duplicated from ps scripts project - alternatives to duplication?

readonly     info="    "
readonly  warning="WARN"
readonly critical="CRIT"
readonly  success=" OK "

readonly log_hostname=$(hostname)
readonly log_format='${log_timestamp} ${log_hostname} "$(printf "%16s" ${log_facility})"'
readonly build_log=${log_dir}/build.log

# warning: appending logalize alters the value of $?, so you must use
# ${PIPESTATUS[0]} instead
logalize(){
	local logalize_file=$1
	[ -z "${log_facility}" ] && readonly log_facility=${service}-build

	cat - | while read line_to_log ; do
	    echo "${line_to_log}"
	    printf -v log_timestamp "%(%s %Y-%m-%d %H:%M:%S)T" -1
	    log_prefix=$(eval echo ${log_format})
	    printf "%s %s %s\n" "${log_prefix}" "${info}" "${line_to_log}"  >> ${logalize_file}
	done
}


log(){
    [ -z "${log_file}" ] && readonly log_file=${build_log}
    [ -z "${log_facility}" ] && readonly log_facility=${service}-build
    [ ! -d $(dirname ${log_file}) ] && mkdir -p $(dirname ${log_file})
    printf -v log_timestamp "%(%s %Y-%m-%d %H:%M:%S)T" -1
    echo "$(eval echo "${log_format}") $1" >> ${log_file}
}

log_status(){
    local my_status=$1
    local success_msg="$2"
    local fail_msg="$3"
    if [ ${my_status} -eq 0 ]; then
	log "${success} ${success_msg}"
    else
	log "${critical} ${fail_msg}"
    fi
}

download_pkg(){
    local status=0
    local downloaded=1

    [ -z "$(which wget)" ] && debian_install wget

    if [ -n "${mirror_base}" ]; then
	local download_url=${mirror_base}/${pkg}
	wget -c ${download_url}
	downloaded=$?
    fi
    if [ ${downloaded} -ne 0 ]; then
	local download_url=${url_base}/${pkg}
	wget -c ${download_url}
	downloaded=$?
    fi
    [ ${downloaded} -ne 0 ] && log "${critical} Could not download package ${download_url}" && exit 3

}

verify_pkg(){
    . ${scripts_base}/build/hashes

    local pkg_hash=$( ${hasher} ${pkg} | cut -d " " -f 1 )
    local key="${pkg_name},${pkg_version}"
    local expected_hash=${expected_hashes[${key}]}

    [ -z "${pkg_hash}" ] || [ -z "${expected_hash}" ] && log "${critical} Missing hash" && exit 5

    if [ ${pkg_hash} != ${expected_hash} ]; then
	log "${critical} Package integrity test failed (${pkg_hash})"
	exit 4
    fi
}

extract_pkg(){
    local pkg_file_info=$(file ${pkg})

    if echo ${pkg_file_info} | grep "tar\|tgz" > /dev/null 2>&1; then
	echo ${pkg_file_info} | grep bzip2 > /dev/null 2>&1 && local decompress_option="j"
	echo ${pkg_file_info} | grep gzip > /dev/null 2>&1 && local decompress_option="x"
	echo ${pkg_file_info} | grep XZ > /dev/null 2>&1 && local decompress_option="J"
	tar xf${decompress_option} ${pkg}
	if [ $? -ne 0 ]; then
	    log "${critical} Could not extract package"
	    exit 5
	fi
    else
	log "${warning} ${pkg} - unknown file type"
	return 11
    fi
}

common_build_vars(){
    [ -z "${pkg_name}" -o -z "${pkg_version}" ] && echo Package name undefined && exit 4
    [ -z "${pkg_dir}" ] && readonly pkg_dir=${pkg_name}-${pkg_version}
    [ -z "${pkg_ext}" ] && readonly pkg_ext=tar.gz
    [ -z "${pkg}" ] && readonly pkg=${pkg_dir}.${pkg_ext}
    [ -z "${prefix}" ] && readonly prefix=${usr_prefix}/${pkg_dir}
    [ -z "${hasher}" ] && readonly hasher=sha1sum
}

build_preconditions(){
    [ -z "${build_dir}" ] && echo build_dir undefined && exit 6

    ${scripts_base}/check_build_env || exit 3

    [ -d ${build_dir} ] || mkdir -p ${build_dir}

    cd ${build_dir}

    common_build_vars 
    log "${info} preconditions start ${pkg_name}"

    # by now, we asume url_base ending in .git is to be cloned
    # (instead of downloaded with wget)
    if [[ ${url_base} == *.git ]]; then
	# !!!! by default, git refuses to "overwrite" the target dir if it already exists...
	# (returning an error status, as opposed to wget in the same situation)
	# right now, we are ignoring git status code...
	git clone ${url_base} ${pkg_dir}
	cd ${pkg_dir}
    else
	download_pkg
	verify_pkg
	extract_pkg && cd ${pkg_dir}
    fi
    log "${success} preconditions finish ${pkg_name}"
}

configure(){
    local configure_options="$1"
    log "${info} ./configure ${configure_options}"
    ./configure ${configure_options}
    if [ $? -ne 0 ]; then
	log "${critical} Problem configuring ${pkg_name}"
	exit 8
    fi
    log "${success} ${pkg_name} configured"
}


# Params:
# $1 make option
# $2 (noinstall)
standard_install(){
    log "${info} standard install start (${ps_paralel}) ${pkg_name}"
    
    # make clean &&  
    make $1 ${ps_paralel:--j 2} 2>&1 | logalize $(make_log)
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
	log "${critical} Problem building ${pkg_name}"
	exit 8
    fi

    if [ "a$2" != "anoinstall" ]; then
	make install ${ps_paralel} 2>&1 | logalize $(make_log)
	if [ ${PIPESTATUS[0]} -ne 0 ]; then
	    log "${warning} Issue installing ${pkg_name}. Check $(make_log)"
	    # exit 8
	fi
    fi

    if [ -d ${prefix} ]; then
    # make sure the symlink points to what it was just installed,
    # instead to some random version (for example, in a different but similar service...)
	rm ${usr_prefix}/${pkg_name}
	ln -s ${prefix} ${usr_prefix}/${pkg_name}
    fi

    if [ -d ${prefix}/lib/pkgconfig ]; then
	local have_pc_files=$(echo ${prefix}/lib/pkgconfig/*.pc)
	if [ -n "${have_pc_files}"  ]; then
        # collect pkg-config files into service pkg-config dir
	    [ ! -d ${usr_prefix}/pkg-config ] && mkdir -p ${usr_prefix}/pkg-config
	    ln -s ${usr_prefix}/${pkg_name}/lib/pkgconfig/*.pc ${usr_prefix}/pkg-config/
	fi
    fi
    log "${success} standard install finish ${pkg_name}"
}

install_prereq(){
    local prereq=$1
    local strength=$2
    local version=$3
    # by now, asume prereq is installed if both the directory and the symlink exist
    local installed=1
    link=${usr_prefix}/${prereq}
    if [ -s ${link} ];then
	ls  --dereference-command-line-symlink-to-dir ${link} > /dev/null
	[ $? -eq 0 ] && installed=0
    fi
    if [ ${installed} -ne 0 ]; then
	${scripts_base}/build/${prereq} ${version}
	if [ $? -ne 0 ]; then
	    log "${critical} Problem installing prereq ${prereq}"
	    [ "k${strength}" == "kmandatory" ] && exit 7
	fi
    else
	log "${warning} Prereq ${prereq} already installed"
    fi
}

debian_install(){
    local my_package=$1
    log "${info} installing ${my_package}"
    # http://www.microhowto.info/howto/perform_an_unattended_installation_of_a_debian_package.html
    export DEBIAN_FRONTEND="noninteractive"
    dpkg -s ${my_package} > /dev/null  && log "${warning} Package ${my_package} already installed" && return 0
    apt-get update -q
    apt-get install -y ${my_package} 2>&1 | logalize ${log_dir}/apt.log
    local my_status=${PIPESTATUS[0]}
    log_status ${my_status} "${my_package} installed" "Problem installing ${my_package}"
    return ${my_status}
}

check_params(){
    local parameters=$1
    local program=$2
    local spaces="${parameters//[^ ]/}"
    local number_of_parameters=$(( ${#spaces} + 1 ))
    shift
    shift
    if [ $# -ne ${number_of_parameters} ]; then
	echo "Wrong number of parameters parameter"
	echo "Syntax: ${program} ${parameters}"
	exit 2
    fi
}

# It expects "$@" as its 1st argument
parse_arguments(){
  if [ "$#" -gt 0 ]; then
    while getopts "u:k:b" options; do
      case "${options}" in
	b)
	  readonly hex_options="od -x -N 129"
	  ;;
	u)
	  readonly url="${OPTARG}"
	  ;;
	k)
	  readonly keyphrase="${OPTARG}"
	  ;;
        *)
          echo "Unknow option" 1>&2 
          print_usage
          ;;
       esac
     done
     shift $((OPTIND-1))
  else
      print_usage
  fi
}


watchdog(){
    local -r timeout=$1
    shift
    local -r delay=1
    local -r interval=1
    (
	$@ &
	pid=$!
	((t = timeout))

	while ((t > 0)); do
            sleep ${interval}
	    # -0 -> exit code indicates if a signal may be sent
            kill -0 ${pid} || exit
            ((t -= interval))
	done

	kill -s SIGTERM ${pid} && kill -0 $$ || exit 1
	sleep ${delay}
	kill -s SIGKILL ${pid}
	exit 2
    ) 2> /dev/null &

}


daemon_start(){
    local my_daemon=$1
    local options="$2"
    local my_pidfile=$3
    local run_as=$4
    local cmd="${my_daemon} ${options}"

    if [ -n "${run_as}" ]; then
	# specifying the shell is important for users with restricted shells, like /bin/false
	local run_as_cmd="su - ${run_as} -s /bin/bash -c "
	if [ -n "${my_pidfile}" ]; then
	    [ ! -d $(dirname ${my_pidfile}) ] && mkdir $(dirname ${my_pidfile})
	    cmd="${run_as_cmd} '${cmd} & echo \$! > ${my_pidfile}'"
	else
	    cmd="${run_as_cmd} '${cmd} &'"
	fi
    else
	if [ -n "${my_pidfile}" ]; then
	    [ ! -d $(dirname ${my_pidfile}) ] && mkdir $(dirname ${my_pidfile})
	    cmd="${cmd} & echo \$! > ${my_pidfile}" 
	else
	    cmd="${cmd} &" 
	fi
    fi
    
    log "${info} Starting daemon ${my_daemon}"

    if [ ! -f ${my_daemon} ]; then
        log "${critical} Daemon ${my_daemon} not found"
    fi

    if is_running ${my_daemon} ${my_pidfile}; then
	log "${warning} ${my_daemon} already running"
    else
	log "${info} ${cmd}"
	# If cmd starts in daemon mode, it is attached to init (PID 1) and $! points to this script itself
	# Hence, for proper pid-saving, the cmd must be started in foreground...
	eval "${cmd}" 
	status=$? 
	# pid=$!

	log_status ${status} "${my_daemon} started" "Problem starting ${my_daemon}"
	return ${status}
    fi
}


daemon_stop(){
    local my_pidfile=$1
    local daemon_name=$2
    if [ ! -f ${my_pidfile} ]; then
	log "${critical} PID file ${pid_file} missing"
	return 2
    fi
    log "${info} Stopping daemon ${daemon_name}"

    local pid=$(cat ${my_pidfile})

    if [ -z "${pid}" ]; then
	log "${critical} Empty PID"
	return 2
    else
    # In simple cases, it's enough to kill the daemon
    # When the daemon spawns lots of childs, it's safer
    # to kill all of them by pgid
    # su pgid is different from pgid of the child process, hence
    # it's safer to get the gpid of the child
	local pgid=$(ps --no-headers -o pgid --ppid ${pid})
	if [ -n "${pgid}" ]; then 
	    kill -- -${pgid// }
	    log_status $? "${pgid} killed" "${pgid} kill failed"
	fi
	
	ps -p ${pid} > /dev/null
	if [ $? -ne 0 ]; then
	    log "${critical} Daemon with pid ${pid} not found"
	else
	    local waited=0
	    kill -TERM ${pid}
	    while [ -n "$(ps -o pid= -o comm= -p ${pid} )" ]; do
		echo -n "."
		waited=$(( waited + 1 ))
		if [ ${waited} -gt 15 ]; then
		    log "S{warning} Timeout stopping daemon ${daemon_name}"
		    kill -9 ${pid}
		    break
		fi
		sleep 1
	    done
	    log "${success} Daemon ${daemon_name} stopped"
	fi
    fi
}


is_running(){
    local process_name=$1
    local my_pid_file=$2
    [ $# -ne 2 -o -z "${process_name}" ] && log "${warning} is_running: wrong parameters" && return 2

    if [ -f ${my_pid_file} ];then
	local pid=$(cat ${my_pid_file})
	if [ -z "${pid}" ]; then
	    log "${warning} Empty PID"
	    return 2
	fi

	local process_count=$(ps h ${pid} | wc -l)
	if [ ${process_count} -gt 0 ]; then
	    return 0
	fi
    fi

    process_count=$(ps h -C ${process_name} | wc -l)
    [ ${process_count} -gt 0 ] && log "${warning} There are other ${process_name} processes running"
    return 1
}

configure_log(){
    [ -z "${install_log_dir}" ] && local install_log_dir=${log_dir}/install
    [ ! -d ${install_log_dir} ] && mkdir ${install_log_dir}
    echo ${install_log_dir}/${pkg_name}_configure.log
}

make_log(){
    [ -z "${install_log_dir}" ] && local install_log_dir=${log_dir}/install
    [ ! -d ${install_log_dir} ] && mkdir ${install_log_dir}
    echo ${install_log_dir}/${pkg_name}_make.log
}

random_str(){
    # underscore might interfere with some sed regex...
    tr -dc A-H-J-N-P-Z-a-h-m-z-1-9 < /dev/urandom | head -c${1:-14}
}

cpu_count(){
    local cpus=$(( $(cat /sys/devices/system/cpu/online | cut -c 3-) + 1 ))
    echo ${cpus}
}

can_write(){
    local user=$1
    local file=$2
    if [ ! -f ${file} ]; then 
	log "${warning} File ${file} not found"
	return 1
    else
	su ${user} -c "[ -w ${file} ]"
	return $?
    fi
}

