#!/usr/bin/perl -w
#-
# Copyright (c) 2000 Max Khon <fjoe@iclub.nsu.ru>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

#
# $Id: ssh-agent.pl,v 1.1 2003/05/20 19:29:51 fjoe Exp $
#
# sample usage for [ba]sh:
#
# if [ x$SSH_AUTH_SOCK = x ]; then
#	eval `ssh-agent.pl`
#	if [ x$SSH_AUTH_FOUND = x ]; then
#		ssh-add
#	fi
# fi
#
# or (for [t]csh):
#
# if (! $?SSH_AGENT_SOCK) then
#	eval `ssh-agent.pl -c`
#	if (! $?SSH_AUTH_FOUND) then
#		ssh-add
#	endif
# endif
#

use strict;
use Socket;
use File::stat;
use Getopt::Std;
use vars qw/ $opt_c $opt_s /;

my $ssh_agent = '/usr/bin/ssh-agent';

sub check_socket
{
	my $authsock = shift;

	socket(SOCK, PF_UNIX, SOCK_STREAM, 0) || return 0;
	if (!connect(SOCK, sockaddr_un($authsock))) {
		close(SOCK);
		return 0;
	}
	close(SOCK);
	return 1;
}

getopts('cs');

my @authsockets = `/bin/sh -c 'find /tmp/ -name agent.* -maxdepth 2 2>/dev/null'`;
foreach my $i (@authsockets) {
	chomp $i;
	my $path = $i;

	$path =~ s|(.*)/[\w.]+|$1/|;
#	print "\$path = $path\n";

	$_ = $path;
	next if (! m:^/tmp/ssh-\w+/$: || ! -O $path || ! -S $i);

	my $sb = stat($path);
#	printf "\$sb->mode = %o\n", $sb->mode;
	next if $sb->mode != 040700;

	if (check_socket($i)) {
		if ($opt_c && !$opt_s) {
			print "setenv SSH_AUTH_SOCK $i;\n";
			print "setenv SSH_AUTH_FOUND yes;\n";
		} else {
			print "export SSH_AUTH_SOCK=$i;\n";
			print "SSH_AUTH_FOUND=yes;\n";
		}
		print "echo Found ssh-agent sock $i;\n";
		exit(0);
	}
}

#print "no agents found\n";
exec $ssh_agent || die "exec: $!\n";
