package Local::Row::JSON;

use strict;
use warnings;
use JSON;

sub new {
	my ($class, %parameters) = @_;
	my $ret = eval {decode_json($parameters{str})};
	return undef if not defined $ret or ref $ret eq "ARRAY";
	$ret = {} unless $ret;
	bless $ret, $class;
}

1;
