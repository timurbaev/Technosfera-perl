# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Local-Stats.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 15;
BEGIN { use_ok('Local::Stats') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @fields = qw(avg cnt max min sum);

sub getter {
	my $name = shift;
	map {return ($_) if $name eq $_} @fields;
	return @fields;
}

my $stats = Local::Stats->new(\&getter);
for my $i (0..6) {
	for my $j (10 * $i  + 1..10 * $i + 10) {
		map {$stats->add($_, $i * $j)} @fields;
	}
	is_deeply($stats->stat, {avg => {avg => $i * (20 * $i + 11) / 2}, cnt => {cnt => 10}, max => {max => 10 * $i * ($i + 1)}, min => {min => $i * ($i * 10 + 1)}, sum => {sum => 5 * $i * (20 * $i + 11)}}, 'fields');
	is_deeply($stats->stat, {avg => {avg => undef}, cnt => {cnt => undef}, max => {max => undef}, min => {min => undef}, sum => {sum => undef}}, 'reset');
}
