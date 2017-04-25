#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($length, $count, $exit, $fh) = (0, 0);
$SIG{'INT'} = sub {
	if ($exit) {
		printf ("%d %d %d", $length, $count, $length / $count) unless $count == 0;
		close ($fh);
		exit 0;
	}
	warn "Double Ctrl+C for exit";
	$exit = 1;
};
my $file;
GetOptions ("file=s" => \$file);
die unless defined $file;
open($fh, '>', $file) or die $!;
print "Get ready\n";
while (<>) {
	$exit = 0;
	$count++;
	print $fh $_;
	chomp;
	$length += length $_;
}
$exit = 1;
$SIG{'INT'}->();
