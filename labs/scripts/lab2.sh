#!/bin/bash

username="$(id -un)"
mid="$(hostnamectl |grep -i machine)"

echo "
======= LAB 02 ========
Report for $mid by $username
$(date)
$(hostname -I)
=======================
"

score=0

## Check there are logs being stored in MySQL database
mysqlrecordcount=$(sudo mysql -u root  <<< 'select count(*) from Syslog.SystemEvents;'|tail -1)
if [ "$mysqlrecordcount" ] && [ "$mysqlrecordcount" -gt 0 ]; then
  echo "- mysql db has $mysqlrecordcount SystemEvents records"
  ((score+=3))
else
    echo "Problem: SystemEvents table is empty"
fi

## Check to see if syslogd is listening on port 514
if sudo ss -tulpn |grep -q 'udp.*0.0.0.0:514.*0.0.0.0:.*syslogd' ; then
  echo "- rsyslog is listening to the network on port 514/udp"
  ((score+=3))
else
  echo "Problem: rsyslog is not listening to port 514 for syslog on the network"
fi

## Check UFW firewall to see if it is allowing traffic to port 514
if sudo ufw status 2>&1 |grep '514.*ALLOW'>NULL; then
        echo "- ufw allows port 514"
  ((score+=2))
else
  echo "Problem: UFW is not allowing syslog traffic on 514/udp"
fi

## Check for unique hosts in syslog text and MySQL
## At this point we should have opnsense and loghost
hostsinsyslog="$(sudo awk '{print $2}' /var/log/syslog|sort|uniq -c)"
hostsindb="$(sudo mysql -u root <<< 'select distinct FromHost, count(*) from Syslog.SystemEvents group by FromHost;')"
for host in loghost opnsense; do
  if sudo grep -aicwq $host /var/log/syslog; then 
    echo "- $host found in /var/log/syslog"
    ((score++))
  else
    echo "Problem: $host not found in /var/log/syslog"
  fi
  if echo "$hostsindb" |grep -qw $host ; then
    echo "- $host has records in the SystemEvents table"
    ((score+=3))
  else
        echo "Problem: $host not found in the SystemEvents table"
  fi
done
echo "
==========
Total Score: $score
"
