#!/bin/bash
# Author: Þorgils Árni Hjálmarsson 08.08.2023

RED='\033[0;31m'
NC='\033[0m'

prompt_new_key() {
	echo ""
	echo Following the steps outlined in https://irhpc.github.io/docs/connecting/connectingssh
	echo -e  "generate a new SSH key. ${RED}Plase make sure that the key in a single line that starts with \"ssh-rsa\" ${NC} "
       	

	while true
	do
		echo -e "Please paste your new public SSH key here and press ${RED}CTRL-d${NC} when you are done:"
		newKey=$(</dev/stdin)
		echo $newKey >> $HOME/.tmpkey
	
		spaces=$(echo $newKey | tr -d -c ' ' | wc -m)
		
		# Check if key starts with "ssh-rsa"
		if [ "$(echo $newKey | cut -d ' ' -f 1)" == "ssh-rsa" ]
		then
			hasSSH=true
		else
			hasSSH=false
		fi
		echo $hasSSH

		# Check if key has more whitespace than we want
		if [ $spaces -gt 3 ]
		then
			myVar=$(echo $newKey | tr -d '[:blank:]')
		fi

		# Add ssh-rsa if it was missing
		if [ $hasSSH == false ]
		then
			newKey="ssh-rsa $newKey"
		fi
		
		# Check if key is valid
		if [ "$(ssh-keygen -l -f $HOME/.tmpkey)" != "" ]
		then
			fpt=$(ssh-keygen -l -E sha256 -f $HOME/.tmpkey | cut -d ' ' -f 2)
			if [ "$newKey" == "$key" ] || [ "$fpt" == "$curr_fpt" ] 
			then
			       echo ""
			       echo ""
			       echo You cannot reuse your old SSH key please generate a new one following the steps in
			       echo https://irhpc.github.io/docs/connecting/connectingssh	
			else
			       break
			fi
		else
			echo ""
			echo ""
			echo -e "${RED}Something went wrong when validating your SSH key, please make sure you entered the key correctly and try again.${NC}"
		fi
		rm .tmpkey
	done
	rm .tmpkey
}

prompt_key_name() {
	echo ""
	echo ""
	if [ "$REMOTEUSER" != "" ] 
	then

		echo "Do you want to keep the name $REMOTEUSER for this key? (y/n)"
		read keep

		if [ $keep == y ] || [ $keep == Y ] 
		then
			RU=$REMOTEUSER
			return
		fi
	fi

	while true
	do
		echo "Enter a name for your SSH key here (if this is left empty a random number will be used):"
		read RU
		
		if [ "$RU" == "" ]
		then
			RU=$RANDOM
		fi

		lines=$(grep -v "$key" $file | cut -d "=" -f 4 | cut -d "\"" -f 1)
		
		flag=true

		for line in $lines
		do
			if [ "$line" == "$RU" ]
			then
				echo ""
				echo "The name $line is already in use please pick a new one"
				flag=false
				break

			elif [ "$RU" == "" ]
			then
				RU=$RANDOM
				flag=true

			fi
		done

		if [ $flag == true ]
		then
			break
		fi
	done
}

remove_old() {
	# Remove old key from the file
	sed -i "\:$ssh:d" $file 

}

remove_update() {
	# Remove old key at $key_pos
	sed -i "${key_pos}d" $file
}

add_new_key() {
	newExp=$(date -d "+60 days" '+%Y%m%d')
	newLine="expiry-time=\"$newExp\",environment=\"REMOTEUSER=$RU\",environment=\"DATESET=$today\" $newKey"
	echo "$newLine" >> "$file"
	clear
	echo ""
	echo ""
	echo "Your new SSH key is valid until $(date -d "+60 days")"
	echo "If you encounter any problems do not hesitate to contact help@hi.is"
}

gather_info() {
	# Prompt user for a new key will be available as the variable $newKey 
	prompt_new_key 
	# Prompt user for a $REMOTEUSER name. This variable is available as $RU
	prompt_key_name
}



# User ID
# Find authorized_keys file
# file="/users/home/$USER/.ssh/authorized_keys"
file="$HOME/.ssh/authorized_keys"

# Get current date
today=$(date '+%Y%m%d')

# If a user connects using an older SSH key that has not been updated with the new format 
# we prompt them to update their SSH key immediately
if [ "$REMOTEUSER" == "" ] 
then
	clear -x
	#TODO better prompt
	echo Your SSH key needs to be updated
	sleep 0.5
			
	# Get footprint of current SSH session
	curr_fpt=$(sed -ne "/sshd.\($((($(ps ho ppid $PPID))))\|$PPID\).:.*\(Accepted publickey\|matching .SA key\)/{s/^.* //g;h};\${x;p}" /var/log/sshdusers.log)
	# Gets footprints of all user stored stored public keys
	fpts=$(ssh-keygen -l -E sha256 -f $file | cut -d ' ' -f 2)
 	lineno=1

	if [ "$curr_fpt" == "" ] 
	then
		echo "Could not distinguish your SSH footprint, please contact help@hi.is"
		return 1
	fi
	
	for fpt in $fpts 
	do
		if [ "$fpt" == "$curr_fpt" ]
		then
			key_pos=$lineno
			break
		fi	
		lineno=$(( lineno+1 ))
	done
	
	if [ $key_pos -lt 0 ] 
	then
		echo "Could not find a matching SSH footprint, please contact help@hi.is"
		return 1
	fi
		gather_info
	remove_update
	add_new_key
	cat /etc/motd
else 
	# Get current public key
	ssh=$(grep "REMOTEUSER=$REMOTEUSER" $file | cut -d ' ' -f 3)
	host=$(grep "REMOTEUSER=$REMOTEUSER" $file | cut -d ' ' -f 4)
	key="ssh-rsa $ssh $host"
		
  	# Get line with current user
	expiry=$(grep "REMOTEUSER=$REMOTEUSER"  $file | cut -b 14-21)

	# Check expiry-date
	days=$(( ($(date --date=$expiry +%s) - $(date --date=$today +%s) )/(60*60*24) ))

	if [ $days -lt 8 ]
	then
		clear -x
		echo Your SSH key will expire in $days day\(s\)
		echo Would you like to update your SSH key now?\(y/n\)
		read updt
		if [ $updt == y ] || [ $updt == Y ]
		then
			gather_info
			remove_old
			# Overwrite old key with new key, adds new expiry-time 60 days from now
			add_new_key
		else
			
			echo "" 
			echo -e "${RED}Once your SSH key expires you will not have access to Elja" 
			echo -e "and will have to contact help@hi.is to update your SSH key.${NC}"
		fi
	fi

  	cat /etc/motd
fi
