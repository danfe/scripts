#!/usr/bin/perl -w

#use warnings;
use strict;
no strict 'refs';

my %seen = ();
my $pf;

while (<>) {
	if (/^diff\s+\S+\s+.+?\/.+?\/(\S+)/) {
		$pf = $1;
		$pf =~ s/\//::/g;
		unless (exists $seen{"$pf"}) {
			open("$pf", ">patch-$pf");
			$seen{"$pf"} = 1;
		}
	} else {
		s/(^---\s).+?\/.+?\/(\S+)/$1$2.orig/;
		s/(^\+\+\+\s).+?\/.+?\/(\S+)/$1$2/;
		print {"$pf"} $_;
	}
}
