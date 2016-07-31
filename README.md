# dosmon
A simple network monitoring tool that detects and logs (D)DoS attacks with tcpdump. You can read more about this tool [here](https://xnite.me/tech/infosec/2016/07/29/ddos-monitoring-and-logging)

# Usage
You can start dosmon with `dosmon.pl start` & stop it by running `dosmon.pl stop`.
If you would need verbosity simply set `my $daemon = 0` and type `dosmon.pl start` and the script will not fork into the background.
