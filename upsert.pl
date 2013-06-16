#!/usr/bin/perl -w

use strict;
use DBI;

my $dbh;

sub upsert($$$) {
    my ($query, $values, $condition) = @_;
    my ($table, $insert);
    my @fields;

    my $sth = $dbh->prepare($query);
    
    my $code = $sth->execute(@{$values}, @{$condition});

    if($sth->rows) {
	return $sth->rows;
    }

    $query =~ /^UPDATE\s+(\w+)\s+SET\s+(.*?)\s+WHERE\s+(.*)$/i;
    $table = $1;
    foreach (split('AND', $3)) {
	/\s*(\w+)\s*=\s*?\s*/;
	push @fields, $1;
    }
    $insert = "INSERT INTO $table (" . join(", ", @fields) . ") VALUES (?" . (", ?" x $#fields) . ")";

    $sth = $dbh->prepare($insert);
    $sth->execute(@{$condition});

    $sth = $dbh->prepare($query);
    $sth->execute(@{$values}, @{$condition});
    
    return $sth->rows;
}

# Log line fields
# 0 timestamp.millisec
# 1 duration
# 2 remotehost
# 3 code/status
# 4 bytes
# 5 method
# 6 URL
# 7 username
# 8 peerstatus/peerhost
# 9 type

my @line;

my ($timestamp, $duration, $userip, $status, $bytes, $method, $url, $username, $peerhost, $type, $date);

my $proxy = shift @ARGV;

$dbh = DBI->connect("DBI:mysql:database=$sqldatabase;host=$sqlhost", $sqluser, $sqlpass,
	{ AutoCommit => 0, RaiseError => 0, PrintError => 1 }) || die("Can't connect to SQL server");

while(<>) {
    @line = split;
    
    $timestamp	= int($line[0]);
    $duration	= $line[1] / 1000.0;
    $userip	= $line[2];
    $status	= $line[3];
    $bytes	= $line[4];
    $method	= $line[5];
    $url	= $line[6];
    $username	= $line[-3];
    $peerhost	= $line[-2];
    $type	= $line[-1];

    $peerhost	=~ s[^([\w_]+)/\d+\.\d+\.\d+\.\d+$][$1/ip-address];	# Suppress IP address
    @_		= localtime $timestamp;

    $date	= (1900 + $_[5]) . "-" . (1 + $_[4]) . "-" . $_[3] . " " . $_[2] . ":" . ($_[1] - ($_[1] % 15)) . ":00";
    upsert("UPDATE Traffic SET Hits = Hits + 1, Bytes = Bytes + ?, Duration = Duration + ? WHERE Source = ? AND Date = ? AND UserName = ? AND UserIP = ?", [$bytes, $duration], [$proxy, $date, $username, $userip]);

    $date	= (1900 + $_[5]) . "-" . (1 + $_[4]) . "-" . $_[3];
    upsert("UPDATE ContentTypes SET Hits = Hits + 1, Bytes = Bytes + ?, Duration = Duration + ? WHERE Source = ? AND Date = ? AND ContentType = ?", [$bytes, $duration], [$proxy, $date, $type]);
    upsert("UPDATE PeerHosts SET Hits = Hits + 1, Bytes = Bytes + ?, Duration = Duration + ? WHERE Source = ? AND Date = ? AND PeerHost = ?", [$bytes, $duration], [$proxy, $date, $peerhost]);
    
    if($url =~ m[^(ftp|http)://(\d+)\.(\d+)\.(\d+)\.(\d+)/]) {
	upsert("UPDATE Domains SET Hits = Hits + 1, Bytes = Bytes + ?, Duration = Duration + ? WHERE Source = ? AND Date = ? AND TopDomain = ? AND SecondDomain = ?", [$bytes, $duration], [$proxy, $date, $2, $3]);
    } else {
	if($url =~ m[^(ftp|http)://(\w+\.)*(\w+)\.(\w{2,4})/]) {
	    upsert("UPDATE Domains SET Hits = Hits + 1, Bytes = Bytes + ?, Duration = Duration + ? WHERE Source = ? AND Date = ? AND TopDomain = ? AND SecondDomain = ?", [$bytes, $duration], [$proxy, $date, $4, $3]);
	}
    }
    
    $dbh->commit;
}
