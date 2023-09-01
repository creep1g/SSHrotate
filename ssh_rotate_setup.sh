#!/bin/bash
#Author Þorgils Árni Hjálmarsson - HI
#

# Backup SSHD sshd_config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak && 
# Permit user environment
sed -i 's/#PermitUserEnvironment no/PermitUserEnvironment yes/g' /etc/ssh/sshd_config &&
# Update LogLevel to Verbose
sed '/^[^#]*LogLevel.*\(QUIET\|FATAL\|ERROR\|INFO\)/{s/^/# /;h;s/$/\nLogLevel VERBOSE/};${p;g;/./!{iLogLevel VERBOSE'$'\n;};D}'  -i /etc/ssh/sshd_config &&
# Get the hook script
curl -s 'https://raw.githubusercontent.com/creep1g/SSHrotate/main/ssh_rotate.sh' --output /etc/profile.d/ssh_rotate.sh &&
chmod 0555 /etc/profile.d/ssh_rotate.sh
# Restart SSH service
/usr/bin/systemctl restart sshd &&
# Make fingerprints user readable
echo ':msg, regex, "Found matching .* key:" -/var/log/sshdusers.log' > /etc/rsyslog.d/ssh_key_user.conf &&
echo ':msg, regex, "Accepted publickey for" -/var/log/sshdusers.log' >> /etc/rsyslog.d/ssh_key_user.conf &&
# Restar rsyslog
/usr/bin/systemctl restart rsyslog &&

# Make log file
touch /var/log/sshdusers.log &&
chmod 644 /var/log/sshdusers.log
# Get logrotate config
curl -s 'https://raw.githubusercontent.com/creep1g/SSHrotate/main/sshdusers' --output /etc/logrotate.d/sshdusers

