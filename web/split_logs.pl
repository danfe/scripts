#!/usr/bin/perl -w

use warnings;
use strict;

my %seen = ();
my $fd;

while (<>) {
	if (m|^([^"]+"\S+\s+)/([^/\s]+)|) {
		open $seen{"$2"}, ">>$2" unless exists $seen{"$2"};
		$fd = $seen{"$2"};
	print $fd "$1$'";
	}
}
