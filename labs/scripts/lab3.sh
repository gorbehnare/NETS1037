!#/bin/bash

username="$(id -un)"
mid="$(hostnamectl |grep -i machine)"

echo "
======= LAB 03 ========
Report for $mid by $username
$(date)
$(hostname -I)
=======================
"

score=0
# Get the local IP address for the system:
# IP_Addr=$(hostname -I)
# ip -o -4 addr show | awk '/global/ {print $4}'

#  Check to make sure we are running on "webhost":
# local_ip=$(hostname -I | awk '{print $1}')
echo "Checking to see if we are running on webhost:"
domain_ip=$(dig +short webhost)
if [ "$domain_ip" == '127.0.1.1' ] || [ "$domain_ip" == $(hostname -I | awk '{print $1}') ]; then
    echo " - The \"webhost\" name resolves to $domain_ip"
else
    echo "Problem: webhost does not resolve to local IP Address. This script should be executed on \"webhost\"."
    exit 1
fi


echo "Checking to see if Apache2 and MySQL server are active:"
if systemctl is-active --quiet apache2; then
    echo " - Apache Service is running"
   ((score+=2))
else
    echo "Problem: Apache Service is not running"
fi
if systemctl is-active --quiet mysql; then
    echo " - MySQL Service is running"
   ((score+=2))
else
    echo "Problem: Service is not running"
fi

echo "Check if local MySQL is configured to host at least 1 loganalyzer user:"
loganalyzer_user_count=$(sudo mysql <<< 'select count(*) from loganalyzer.logcon_users;'|tail -1)
if [ "$loganalyzer_user_count" ] && [ "$loganalyzer_user_count" -gt 0 ]; then
  echo " - Local MySQL db contains $loganalyzer_user_count user(s) for LogAnalyzer"
  ((score+=4))
else
    echo "Problem: No user accounts are created for LogAnlyzer. Is it configured?"
fi

echo "Checking UFW firewall configuration:"
if sudo ufw status 2>&1 |grep -e '80.*ALLOW' -e '22.*ALLOW'>NULL; then
        echo " - ufw allows ports 80 and 22"
  ((score+=2))
else
  echo "Problem: UFW is not allowing HTTP and/or SSH traffic"
fi

echo "
=====================
Total Score: $score
"
