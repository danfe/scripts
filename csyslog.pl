#!/usr/bin/perl

$dc = "\033[33m";
$fc = "\033[35m";
$lc = "\033[32m";
$lwc = "\033[31m";
$whoc = "\033[36m";
$nc = "\033[m";

open(LOGFILE, "tail -f /var/log/messages |");

while (<LOGFILE>)
{
	#if (/^(\w{3}\s\d{1,2}\s\d\d:\d\d:\d\d)\s<(\w+).(\w+)>\s(\w+)\s(.+?)\[(\d+)\]:\s/)
	if (/^(\w{3}\s+\d{1,2}\s\d\d:\d\d:\d\d)\s<(\w+).(\w+)>\s(\w+)\s(.+?):\s/)
	{
		($date, $facility, $level, $host, $who, $whatever) = ($1, $2, $3, $4, $5, $');

		print $dc . $date . $nc;
		print  " <" . $fc . $facility . $nc . ".";

		if ($level eq "info" || $level eq "notice") {
			print $lc;
		} else {
			print $lwc;
		}

		print $level . $nc . "> " . $host . " ";
		print $whoc . $who . $nc . ": ";
		print $whatever;
	}
}
