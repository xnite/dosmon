# dosmon
A simple network monitoring tool that detects and logs (D)DoS attacks with tcpdump. You can read more about this tool [here](https://xnite.me/tech/infosec/2016/07/29/ddos-monitoring-and-logging)

# Usage
You can start dosmon with `dosmon.pl start` & stop it by running `dosmon.pl stop`.

Configuration files are read from `/etc/dosmon/*.conf`

# Install
On **debian** you should install perl ofcourse and one necessary module:

`apt-get install perl cpan && cpan install Net::Server::Daemonize`
