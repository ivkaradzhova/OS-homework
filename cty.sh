#!/bin/bash


#comparing only call signs starting with '='
function first_rule_comparison {
	if [[ "${1}" == =* ]]
	then 
		[[ "${1}" == ="${2}"  ||  "${1}" == ="${2}"[\(\[]* ]] && matching=1 || matching=0
	else
		matching=0
	fi

}

#comparing all other call signs
function second_rule_comparison {
	if [[ "${1}" == =* ]]
	then
		substring_matching=0
	else
		if [[ "${1}" == *[\(]* ]] 
		then
			sign_without_zones=$(echo "${1}" |  cut -d "(" -f 1)
		else
			sign_without_zones="${1}"
		fi
		[[ "${2}" == "${sign_without_zones}"* ]] && substring_matching=1 || substring_matching=0
	fi

}

#find in which line there is a rule which the given call sign follows
function find_line {
	file=$1
	while read -r line
	do
        	area_signs=$(echo "${line}" | cut -d "," -f 10 | cut -d ";" -f 1)
		for sign in ${area_signs}
	        do
        	        first_rule_comparison "${sign}" "${2}"
              		second_rule_comparison "${sign}" "${2}"
              	 	if [[ "${matching}" -eq 1 ]]
                	then
                        	saved_line="${line}"
				saved_sign="${sign}"
				break
	                fi
        	        if [[ "${substring_matching}" -eq 1 && "${sign}" == "${last_matching_substring}"* ]]
                	then
                        	last_matching_substring="${sign_without_zones}"
	                        saved_line="${line}"
        	                saved_sign="${sign}"
                	fi
	        done
		[[ $matching -eq 1 ]] && break
	done <"${file}"
}

#-----------A----------
function country {
	find_line $1 $2
	if [[ "${saved_line}" != "" ]]
	then
		echo "${saved_line}"| cut -d ',' -f 2	
	else
	       	echo "No country or region is found" >&2
		exit 2
	fi
}

#---------B------------
function get_zones {
	WAZ=-1
	ITU=-1
	all_info="${2}"
	if [[ "${1}" == *[\(]* ]]
	then
		WAZ=$(echo "${1}" | tr ')' '(' | cut -d '(' -f 2)
	fi
	if [[ "${1}" == *[\[]* ]]
	then
		ITU=$(echo "${1}" | tr ']' '[' | cut -d '[' -f 2)
	fi	

	[[ "${ITU}" -eq -1 ]] && ITU=$(echo "${all_info}" | cut -d ',' -f 6)
	[[ "${WAZ}" -eq -1 ]] && WAZ=$(echo "${all_info}" | cut -d ',' -f 5)

	echo ""${ITU}" "${WAZ}""
}                         

function zones {
	find_line $1 $2
	if [[ "${saved_line}" != "" ]] 
	then 
		get_zones "${saved_sign}" "${saved_line}"
	else
		echo "Invalid call sign" >&2
		exit 2
	fi
}
#---------C---------
function get_distance {
	echo $1 $2 $3 $4 | 	
		awk "BEGIN {pi=3.14; R=6371;
			lat1=($1*pi)/180; long1=($2*pi)/180;
			lat2=($3*pi)/180; long2=($4*pi)/180;
		}	
			
		{
			sinLat=sin((lat1-lat2)/2);
			sinLong=sin((long1-long2)/2);
			a=sinLat^2 + cos(lat1)*cos(lat2) * sinLong^2;
			c=2*atan2(sqrt(a), sqrt(1-a));
			distance=int(R*c);
		}
		END {print distance}"
}

function distance {
	find_line $1 $2
	if [[ "${saved_line}" != "" ]] 
	then
		lat1=$(echo $saved_line | cut -d ',' -f 7)
		long1=$(echo $saved_line | cut -d ',' -f 8)
	else
		echo "First sign is invalid" >&2
		exit 2
	fi
	unset saved_line
	unset last_matching_substring
	find_line $1 $3
	if [[ "${saved_line}" != " " ]]
	then	
		lat2=$(echo $saved_line | cut -d ',' -f 7)
		long2=$(echo $saved_line | cut -d ',' -f 8)
	else 
		echo "Second call sign is invalid" >&2
		exit 2
	fi
	get_distance $lat1 $long1 $lat2 $long2
}

case $2 in 
	"country")
		country $1 $3;;
	"zones")
		zones $1 $3;;
	"distance")
		distance $1 $3 $4;;
	*)
		echo "Invalid command" >&2
		exit 1
esac	
