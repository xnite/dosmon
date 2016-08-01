#!/usr/bin/perl
# DOSMon v2.0
# Author:       Robert Whitney <xnite@xnite.me>
# Homepage:     https://xnite.me/
use strict;
use warnings;
use threads;
use Net::Server::Daemonize qw(daemonize);
use POSIX;

sub Main
{
        my @workers = ();
        my @configs = </etc/dosmon/*.conf>;
        foreach my $conf (@configs)
        {
        		print "Found config file: ".$conf."\n";
                push( @workers, threads->create( \&deviceLoop, $conf ) );
                sleep 2; # Give time for threads to print before daemonizing
        }
        foreach ( @workers )
        {
                if( $_->is_joinable() ) {
                        $_->join();
                }
        } 
        print "Started all threads\n";
        daemonize(
                'root',                 # User
                'root',                 # Group
                '/var/run/dosmon.pid'   # Path to PID file
        );
        # Wait until all threads finish.
        my @threads = threads->list(threads::running);
        while($#threads > 0)
        {
                my @threads = threads->list(threads::running);
        }
        print "All threads have shut down\nexiting...";
}
 
sub deviceLoop
{
        my ($config_file) = @_;
        ## CONFIGURATION ##
        my ($device, $send_threshold, $recv_threshold, $pps_threshold, $logging_path, $sample_size, $timeout_after_attack);
        if (open(my $fh, '<:encoding(UTF-8)', $config_file))
        {
                while (my $row = <$fh>)
                {
                        chomp($row);
                        if($row =~ /DEVICE="(.*?)";/i)
                        {
                                $device = $1;
                        }
                        if( $row =~ /SEND_THRESHOLD="(.*?)";/i)
                        {
                                $send_threshold = $1;
                        }
                        if( $row =~ /RECV_THRESHOLD="(.*?)";/i)
                        {
                                $recv_threshold = $1;
                        }
                        if( $row =~ /PPS_THRESHOLD="(.*?)";/i)
                        {
                                $pps_threshold = $1;
                        }
                        if( $row =~ /LOG_PATH="(.*?)";/i)
                        {
                                $logging_path=$1;
                        }
                        if( $row =~ /SAMPLE_SIZE="(.*?)";/i)
                        {
                                $sample_size=$1;
                        }
                        if( $row =~ /COOL_DOWN="(.*?)";/i)
                        {
                                $timeout_after_attack=$1;
                        }
                }
        } else {
          warn "Could not open configuration file at ".$config_file."! Closing thread.\n";
          threads->exit();
        }
        if ( -e "/sys/class/net/".$device."/address" )
        { 
	        print "Started listening on interface ".$device."\n";
	    } else {
	    	warn "Could not find device ".$device.". Please make sure that it exists in `ifconfig`\n";
	    	threads->exit();
	    }

        while( 1 )
        {
                my $send                = get_transfer_rate($device);
                my $recv                = get_recieve_rate($device);
                my $recv_pps            = get_recieve_packets($device);
                my $send_pps            = get_transfer_packets($device);
                my $total_pps           = $send_pps+$recv_pps;
                my $total               = $send+$recv;

                print "[".$device."]\tSEND: ".($send/125000)."Mbit | RECV: ".($recv/125000)."Mbit | Total: ".($total/125000)."Mbit\n";
                print "[".$device."]\tPPS Send: ".$send_pps." | PPS RECV: ".$recv_pps." | Total: ".$total_pps."\n";

                if( $send >= $send_threshold*125000 )
                {
                        my $rate                = $send/125000;
                        my $filename    = strftime("%F_%H-%M", localtime())."_".$device."-outgoing-".$rate."Mbps.pcap";
                        print "Logging possible outgoing DDoS attack to ".$filename."\n";
                        system('/usr/sbin/tcpdump -X -nn -i '.$device.' -s 0 -c '.$sample_size.' -w '.$logging_path."/".$filename);
                        print "Finished logging to ".$filename."\n";
                        sleep $timeout_after_attack;
                } elsif( $recv >= $recv_threshold*125000 )
                {
                        my $rate                = $recv/125000;
                        my $filename    = strftime("%F_%H-%M", localtime())."_".$device."-incoming-".$rate."Mbps.pcap";
                        print "Logging possible incoming DDoS attack to ".$filename."\n";
                        system('/usr/sbin/tcpdump -X -nn -i '.$device.' -s 0 -c '.$sample_size.' -w '.$logging_path."/".$filename);
                        print "Finished logging to ".$filename."\n";
                        sleep $timeout_after_attack;
                } elsif( $total_pps >= $pps_threshold )
                {
                        my $filename    = strftime("%F_%H-%M", localtime())."_".$device."-".$total_pps."pps.pcap";
                        print "Logging possible DoS attack to ".$filename."\n";
                        system('/usr/sbin/tcpdump -X -nn -i '.$device.' -s 0 -c '.$sample_size.' -w '.$logging_path."/".$filename);
                        print "Finished logging to ".$filename."\n";
                        sleep $timeout_after_attack;
                }
        }
        threads->exit();
}

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

my ( $action ) = @ARGV;

if(!defined $action)
{
        die("USAGE: dosmon [START|STOP|STATUS]\n");
}

if( $action =~ /start/i )
{
        Main();
}

if( $action =~ /stop/i )
{
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