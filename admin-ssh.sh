#!/bin/bash
# Author Þorgils Árni Hjálmarsson	28.08.23

today=$(date '+%Y%m%d')
RU=$RANDOM

echo "Add new SSH key to a user"
echo "Enter the user name:"
read username

echo "Add SSH-key (format ssh-rsa xxxx comment):"
read newKey

echo $newKey >> $HOME/.tmpkey

if [ "$(ssh-keygen -l -f $HOME/.tmpkey)" == "" ]
then
	echo "Something went wrong when validating your SSH key, please make sure you entered the key in correctly and try again."
	rm $HOME/.tmpkey
	return -1
fi
rm $HOME/.tmpkey

file="/home/$username/.ssh/authorized_keys"

newExp=$(date -d "+60 days" '+$Y%m%d')
newLine="expiry-time=\"$newExp\",environment=\"REMOTEUSER=$RU\",environment=\"DATESET=$today\" $newKey"
echo "$newLine" >> "$file"

echo "Done verify in the output below that it is correct:" 
cat $file



