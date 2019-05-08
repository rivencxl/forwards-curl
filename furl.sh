#! /bin/bash
CONFIG=`eval echo "~$different_user"`"/.furl"
PREFIX="@@"
FORWARDS_URL=

function seturl() {
	if [ ! -f $CONFIG ];then
		touch $CONFIG
	fi
	src=$2
	dest=$3
	total=`awk 'END{print NR}' $CONFIG`
	if [ $total -eq 0 ];then
		echo "${src}	${dest}" >> $CONFIG
	else
		i=1
		for line_src in `cat $CONFIG | awk '{print $1}'`
		do
			[[ $src == $line_src ]] && break
			let i+=1
		done
		if [ $i -gt $total ];then
			echo "${src}	${dest}" >> $CONFIG
		else
			sed -i '' "${i}s/^.*$/${src}	${dest}/" $CONFIG
		fi
	fi
}

function geturl() {
	src=$2
	url_line=`awk '{print $1}' $CONFIG | grep -n $src $CONFIG | cut -d: -f1`
	sed -n "${url_line}p" $CONFIG | awk '{print $2}'
}

function forwards() {
	src_url=${1:2}
	src="${src_url%%/*}"
  	dest_line=`awk '{print $1}' $CONFIG | grep -n $src $CONFIG | cut -d: -f1`
	dest=`sed -n "${dest_line}p" $CONFIG | awk '{print $2}'`
  	if [ -n $dest ];then
  		FORWARDS_URL=${src_url/$src/$dest}
  	else
  		FORWARDS_URL=$src_url
  	fi
}

if [ $1 == "set" ]; then
	seturl $@
elif [ $1 == "get" ];then
	geturl $@
elif [ $1 == "list" ]; then
	cat $CONFIG
else
	content_type=
	post_or_put=
	params=("$@")
	for ((i=0; i<$#; i++)) {
		[[ ${params[i]} == Content-type:* ]] && content_type=${params[i]}

		if [[ ${params[i]} == $PREFIX* ]]; then
			forwards ${params[i]}
			params[i]=$FORWARDS_URL
		elif [[ ${params[i]} == *\ * ]]; then
        	params[i]="'${params[i]}'"
        elif [[ ${params[i]} =~ ^-X(POST|PUT)$ ]]; then
        	post_or_put=${params[i]}
		fi
	}

	[ -z "$content_type" ] && [ -n "$post_or_put" ] && params=("${params[@]}" '-H Content-type:application/json')
	
	curl ${params[@]}
fi
