#!/bin/sh
cp -r dosmon /etc/dosmon
cp dosmon.pl /usr/sbin/dosmon.pl
chmod +x /usr/sbin/dosmon.pl
mkdir /var/log/dosmon
echo "Add the following line into crontab for the root user to start dosmon after boot:"
echo "@reboot /usr/sbin/dosmon.pl start"
echo "---"
echo "Don't forget to configure DOSMon by editing the configuration files in `/etc/dosmon/`"
echo "Before you can use DOSMon you will also need to make sure that tcpdump is installed on your system."
echo "Be sure to install perl dependencies for this program `cpan Net::Server::Damonize`"
echo "Start dosmon by typing `/usr/sbin/dosmon.pl start`"