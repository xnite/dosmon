#!/usr/bin/perl
use strict;
use warnings;
use Net::Server::Daemonize qw(daemonize);

## CONFIGURATION ##
my $device                                      = 'enp2s0';
my $send_threshold                              = 25*125000;                   # 25 Mbit outgoing.
my $recv_threshold                              = 25*125000;                   # 25 Mbit incoming.
my $pps_threshold                               = 10000;                         # 10000 packets per second.
my $logging_path                                = '/var/log/dosmon';            # No trailing /!
my $sample_size                                 = 100000;                        # How many packets should be logged in a bandwidth attack?
my $daemon                                      = 1;                            # Run as a daemon?
## END OF CONFIGURATION - DO NOT EDIT BEYOND THIS POINT!! ##
my ( $action ) = @ARGV;
sub get_transfer_rate
{
		my ( $dev )                             = @_;
		open ( FILE, '/sys/class/net/'.$dev.'/statistics/tx_bytes' );
		my $tx_bytes_before             = <FILE>;
		chomp($tx_bytes_before);
		sleep 1;
		open ( FILE, '/sys/class/net/'.$dev.'/statistics/tx_bytes' );
		my $tx_bytes_after              = <FILE>;
		chomp($tx_bytes_after);
		return $tx_bytes_after-$tx_bytes_before;
}

sub get_recieve_rate
{
		my ( $dev )                             = @_;
		open ( FILE, '/sys/class/net/'.$dev.'/statistics/rx_bytes' );
		my $rx_bytes_before             = <FILE>;
		chomp($rx_bytes_before);
		sleep 1;
		open ( FILE, '/sys/class/net/'.$dev.'/statistics/rx_bytes' );
		my $rx_bytes_after              = <FILE>;
		chomp($rx_bytes_after);
		return $rx_bytes_after-$rx_bytes_before;
}

sub get_transfer_packets
{
		my ( $dev )                             = @_;
		open ( FILE, '/sys/class/net/'.$dev.'/statistics/tx_packets' );
		my $tx_packets_before           = <FILE>;
		chomp($tx_packets_before);
		sleep 1;
		open ( FILE, '/sys/class/net/'.$dev.'/statistics/tx_packets' );
		my $tx_packets_after            = <FILE>;
		chomp($tx_packets_after);
		return $tx_packets_after-$tx_packets_before;
}

sub get_recieve_packets
{
		my ( $dev )                             = @_;
		open ( FILE, '/sys/class/net/'.$dev.'/statistics/rx_packets' );
		my $rx_packets_before           = <FILE>;
		chomp($rx_packets_before);
		sleep 1;
		open ( FILE, '/sys/class/net/'.$dev.'/statistics/rx_packets' );
		my $rx_packets_after            = <FILE>;
		chomp($rx_packets_after);
		return $rx_packets_after-$rx_packets_before;
}

if(!defined $action)
{
		die("USAGE: dosmon [START|STOP|STATUS]\n");
}

if( $action =~ /start/i )
{
		if( $daemon > 0 )
		{
				daemonize(
						'root',                                 # User
						'root',                                 # Group
						'/var/run/dosmon.pid'   # Path to PID file - optional
				);
		}
		while( 1 )
		{
				my $send                        = get_transfer_rate($device);
				my $recv                        = get_recieve_rate($device);
				my $recv_pps            = get_recieve_packets($device);
				my $send_pps            = get_transfer_packets($device);
				my $total_pps           = $send_pps+$recv_pps;
				my $total                       = $send+$recv;

				print "SEND: ".($send/125000)."Mbit | RECV: ".($recv/125000)."Mbit | Total: ".($total/125000)."Mbit\n";
				print "PPS Send: ".$send_pps." | PPS RECV: ".$recv_pps." | Total: ".$total_pps."\n";

				if( $send >= $send_threshold )
				{
						my $rate                = $send/125000;
						my $filename    = time()."-outgoing-".$rate."Mbps.pcap";
						print "Logging possible outgoing DDoS attack to ".$filename."\n";
						system('/usr/sbin/tcpdump -nn -i '.$device.' -s 0 -c '.$sample_size.' -w '.$logging_path."/".$filename);
						print "Finished logging to ".$filename."\n";
						sleep 120;
				} elsif( $recv >= $recv_threshold )
				{
						my $rate                = $recv/125000;
						my $filename    = time()."-incoming-".$rate."Mbps.pcap";
						print "Logging possible incoming DDoS attack to ".$filename."\n";
						system('/usr/sbin/tcpdump -nn -i '.$device.' -s 0 -c '.$sample_size.' -w '.$logging_path."/".$filename);
						print "Finished logging to ".$filename."\n";
						sleep 120;
				} elsif( $total_pps >= $pps_threshold )
				{
						my $filename    = time()."-".$total_pps."pps.pcap";
						print "Logging possible DoS attack to ".$filename."\n";
						system('/usr/sbin/tcpdump -nn -i '.$device.' -s 0 -c '.$sample_size.' -w '.$logging_path."/".$filename);
						print "Finished logging to ".$filename."\n";
						sleep 120;
				}
		}
		exit;
}

if( $action =~ /stop/i ) {
		open( FILE, '/var/run/dosmon.pid' );
		my $pid = <FILE>;
		chomp($pid);
		if( $pid > 0 ) {
				print "Stopping DoS Monitor Daemon.\n";
				system("kill -9 ".$pid);
				print "Killed process with ID ".$pid."\n";
				exit;
		} else {
				print "Could not find process ID for the DoS Monitor Daemon\n";
				print "If you are certain it is running, check your process tree for the correct PID and issue a TERM signal\n";
				exit;
		}
}