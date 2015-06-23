#!/usr/bin/perl
use strict;
use warnings;
use DB_File;
use File::Tail ;
use Proc::Daemon;
use Proc::PID::File;
use Getopt::Long;
use Config::Simple;
use Log::Log4perl;
my $debug = 0;
my $config;

Getopt::Long::Configure('bundling');
GetOptions(
        "d|debug" => \$debug,
        "c|config=s"       => \$config);

die("Couldn't find config $config\n") if ( ! -e $config);

my $cfg = new Config::Simple($config);
#Config::Simple->import_from($config, \%cc) or die Config::Simple->error();

my $global = $cfg->param(-block=>'global');
my $patterns = $cfg->param(-block=>'patterns');

MAIN:
{
Proc::Daemon::Init();
if (Proc::PID::File->running()) {
	print "another prog is running\n";
	exit(0);
}
my %stats;
my $relay;
$SIG{'HUP'} = 'handler';

my $log_conf = "
    log4perl.rootLogger=".$global->{'loglevel'}.", Logfile
    log4perl.appender.Logfile=Log::Log4perl::Appender::File
    log4perl.appender.Logfile.filename=".$global->{'logfile'}."
    log4perl.appender.Logfile.mode=append
    log4perl.appender.Logfile.layout=PatternLayout
    log4perl.appender.Logfile.layout.ConversionPattern=[%d] [%r] %F %L %c - %m%n
  ";

Log::Log4perl->init(\$log_conf);
our $logger = Log::Log4perl->get_logger();

my $db = tie(%stats, "DB_File", "$global->{statsdb}", O_CREAT|O_RDWR, 0666, $DB_HASH)
        || die ("Cannot open $global->{statsdb}");

our $logref=tie(*LOG,"File::Tail",(name=>$global->{monitor_log},debug=>$debug));

$logger->info("Started $0...");

while (<LOG>) {
    foreach my $pp (keys %$patterns) {
        if(/$patterns->{$pp}/) {
            $logger->debug("got line $pp: $_");
            $stats{$pp} += 1;
            $db->sync;
        }
    }
} ;


sub handler {
	my $signal = shift;
	$SIG{'HUP'} = 'handler';
	print "Signal: SIG$signal caught!\n";
	if ($signal eq "HUP" ) {
		untie $logref;
		untie %stats;
		$logger->info("Stopped mailstats....");
		exit 0;
	}
}
}
