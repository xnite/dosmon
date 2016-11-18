# dosmon
A simple network monitoring tool that detects and logs (D)DoS attacks with tcpdump. You can read more about this tool [here](https://xnite.me/tech/infosec/2016/07/29/ddos-monitoring-and-logging)

# Usage
You can start dosmon with `dosmon.pl start` & stop it by running `dosmon.pl stop`.

Configuration files are read from `/etc/dosmon/*.conf`

# Warning!
This script has been tested on Perl v5.12 and works fine. It has been discovered that with Perl versions 5.20 and 5.22 (and assuming in between) the program takes up 100% CPU. It is recommended that if you only need to monitor 1 interface then you should `git checkout 1.0` until this issue has been resolved. You can keep track of the status of this issue here: https://github.com/xnite/dosmon/issues/4