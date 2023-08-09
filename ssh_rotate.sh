#!/bin/bash
# Author: Þorgils Árni Hjálmarsson 08.08.2023


prompt_new_key() {
	echo ""
	echo Following the steps outlined in https://irhpc.github.io/docs/connecting/connectingssh
	echo generate a new SSH key. 

	while true
	do
		echo Please paste your new public SSH key here:
		read newKey

		if [ "$newKey" == "$key" ] 
		then
		       echo ""
		       echo ""
		       echo You cannot reuse your old SSH key please generate a new one following the steps in
		       echo https://irhpc.github.io/docs/connecting/connectingssh	
		else
		       break
		fi
	done
}

prompt_key_name() {
	echo ""
	echo ""
	echo "Do you want to keep the name $REMOTEUSER for this key? (y/n)"
       	read keep
	if [ $keep == y ] || [ $keep == Y ] 
	then
		RU=$REMOTEUSER
	else
		while true
		do
			echo Enter a name for your SSH key here:
			read RU
			
			lines=$(grep -v "$key" $file | cut -d "=" -f 4 | cut -d "\"" -f 1)
			echo $lines
			
			flag=true
			for line in $lines
			do
				if [ "$line" == "$RU" ]
				then
					echo ""
					echo "The name $line is already in use please pick a new one"
					flag=false
					break
				fi
			done

 			if [ $flag == true ]
			then
				break
			fi
		done
	fi	
}

add_new_key() {
	# Remove old key from the file
	sed -i "\:$ssh:d" $file 
	newExp=$(date -d "+60 days" '+%Y%m%d')
	newLine="expiry-time=\"$newExp\",environment=\"REMOTEUSER=$RU\",environment=\"DATESET=$today\" $newKey"
	echo $newLine >> $file
	clear
	echo ""
	echo ""
	echo "Your new SSH key is valid until $(date -d "+60 days")"
	echo "If you encounter any problems do not hesitate to contact help@hi.is"
}

# file="/users/home/$USER/.ssh/authorized_keys"


# Find authorized_keys file
file="/$USER/.ssh/authorized_keys"

# Get current public key
ssh=$(grep "REMOTEUSER=$REMOTEUSER" $file | cut -d ' ' -f 3)
host=$(grep "REMOTEUSER=$REMOTEUSER" $file | cut -d ' ' -f 4)
key="ssh-rsa $ssh $host"

# Get line with current user
expiry=$(grep "REMOTEUSER=$REMOTEUSER"  $file | cut -b 14-21)

# Get current date
today=$(date '+%Y%m%d')

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
		# Prompt user for a new key will be available as the variable $newKey 
		prompt_new_key 
		# Prompt user for a $REMOTEUSER name. This variable is available as $RU
		prompt_key_name
		# Overwrite old key with new key, adds new expiry-time 60 days from now
		add_new_key

	else
		
		echo "" 
		echo Once your SSH key expires you will not have access to Elja 
		echo and will have to contact help@hi.is to update your SSH key.
	fi
fi

