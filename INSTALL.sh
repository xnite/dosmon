#!/bin/sh
cp dosmon.conf /etc/dosmon.conf
cp dosmon.pl /usr/sbin/dosmon.pl
chmod +x /usr/sbin/dosmon.pl
#cpan Net::Server::Daemonize
mkdir /var/log/dosmon
echo "Add the following line into crontab for the root user to start dosmon after boot:"
echo "@reboot /usr/sbin/dosmon.pl start"
echo "---"
echo "Don't forget to configure dosmon by editing the configuration file at `/etc/dosmon.conf`"
echo "Before you can use dosmon you will also need to make sure that tcpdump is installed on your system."
echo "Be sure to install perl dependencies for this program `cpan Net::Server::Damonize`"
echo "Start dosmon by typing `/usr/sbin/dosmon.pl start`"