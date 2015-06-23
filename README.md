logstats
========
This is a log monitoring daemon. It will count matched lines of 
monitored log file.

Prerequisite
============
	Config::Simple
	Getopt::Long
	Proc::PID::File
	Proc::Daemon
	File::Tail
	Log::Log4perl

Configuration
=============
	statsdb				file to store the counters
	monitor_log		log file to monitor
	logfile				log file of the daemon
	loglevel			log level for the daemon


Usage
=====
Start logstats daemon

	logstats.pl -c <config file>

Check counters with logstatsctl

	logstatsctl -c <config file> -l <pattern> [-k]
		-l <pattern>	list counter of pattern
		-k						list all pattern
