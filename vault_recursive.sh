#!/bin/bash -e

DO_PURGE=${DO_PURGE:-no}
DO_FORCE=${DO_FORCE:-no}

function recursive_list() {
	local basepath=$1
	while read line; do
		if grep -q '/$' <(echo $line); then
			recursive_list ${basepath}${line}
		else
			echo ${basepath}${line}
		fi
	done < <(vault kv list -format json $basepath | jq -r '.[]')
}

function recursive_delete_check() {
	local basepath=$1

	echo "You are about to do the following:" >&2
	while read line; do
		echo vault kv delete $line
		if [ $DO_PURGE = 'yes' ]; then
			echo vault kv metadata delete $line
		fi
	done < <(recursive_list $basepath) | sed 's/^/  /' >&2
	echo -n "Do you wish to continue? Yes/[No]: " >&2
	read response
	if [ "$(echo $response | tr 'A-Z' 'a-z')" = 'yes' ]; then
		echo "Proceeding..."
	else
		echo "Aborting." >&2
		exit
	fi
}

function recursive_delete_actual() {
	local basepath=$1
	while read line; do
		vault kv delete $line
		if [ $DO_PURGE = 'yes' ]; then
			vault kv metadata delete $line
		fi
	done < <(recursive_list $basepath)
}

function recursive_delete() {
	if [ ! $DO_FORCE = 'yes' ]; then
		recursive_delete_check $1
	fi
	recursive_delete_actual $1
}

function recursive_dump() {
	local basepath=$1
	while read line; do
		echo = $line
		vault kv get -format json $line | jq .data.data | sed 's/^/  /'
	done < <(recursive_list $basepath)
}

function recursive_copy_actual() {
	local basepath=$1
	local destpath=$2
	while read line; do
		basename=$(echo $line | sed "s#^${basepath}##")
		echo "= $line >> ${destpath}${basename}"
		vault kv put ${destpath}${basename} @<(vault kv get -format json $line | jq .data.data)
	done < <(recursive_list $basepath)
}

function recursive_copy_check() {
	local basepath=$1
	local destpath=$2
	echo "You are about to do the following:" >&2
	while read line; do
		basename=$(echo $line | sed "s#^${basepath}##")
		echo "$line >> ${destpath}${basename}"
	done < <(recursive_list $basepath) | column -t | sed 's/^/  /'
	echo -n "Do you wish to continue? Yes/[No]: " >&2
	read response
	if [ "$(echo $response | tr 'A-Z' 'a-z')" = 'yes' ]; then
		echo "Proceeding..."
	else
		echo "Aborting." >&2
		exit
	fi
}

function recursive_copy() {
	if [ ! $DO_FORCE = 'yes' ]; then
		recursive_copy_check $1 $2
	fi
	recursive_copy_actual $1 $2
}


do=$1
path=$2
if ! grep -q '/$' <(echo $path); then
	path=${path}/
fi

if [ $# -eq 3 ]; then
	dest=$3
	if ! grep -q '/$' <(echo $dest); then
		dest=${dest}/
	fi
fi

case $do in
	list)
		recursive_list $path ;;
	dump)
		recursive_dump $path ;;
	delete)
		recursive_delete $path ;;
	copy)
		recursive_copy $path $dest ;;
	*)
		echo "unrecognized command: $do" >&2
		exit 1 ;;
esac
